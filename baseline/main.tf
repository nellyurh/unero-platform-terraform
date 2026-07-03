# Org-wide roots that exist once and are referenced by every environment: the CMKs,
# the CloudTrail log archive, and the IAM baseline for the Terraform automation role.
locals {
  tags = { Platform = "unero", Scope = "baseline" }
}

# --- Root CMKs (multi-region for DR readability) ---
module "kms_data" {
  source       = "../modules/kms-key"
  purpose      = "data"
  environment  = "baseline"
  multi_region = true
  tags         = local.tags
}

module "kms_secrets" {
  source       = "../modules/kms-key"
  purpose      = "secrets"
  environment  = "baseline"
  multi_region = true
  tags         = local.tags
}

module "kms_logs" {
  source             = "../modules/kms-key"
  purpose            = "logs"
  environment        = "baseline"
  service_principals = ["logs.amazonaws.com", "cloudtrail.amazonaws.com"]
  tags               = local.tags
}

# --- Remote state store (created out-of-band on first bootstrap, imported thereafter) ---
resource "aws_s3_bucket" "state" {
  bucket = "unero-terraform-state"
  tags   = local.tags
}
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.kms_data.key_arn
    }
    bucket_key_enabled = true
  }
}
resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_dynamodb_table" "locks" {
  name         = "unero-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = local.tags
}

# --- Account-wide audit trail (single-account model, ARB 2026-07-03) ---
# Standard (non-organization) trail: there is no AWS Organization. Logs land in a DEDICATED
# audit bucket (audit.tf) — never the state bucket — with the CloudTrail bucket policy the
# service requires. Multi-region so eu-west-1 (DR) activity is captured too.
resource "aws_cloudtrail" "account" {
  name                          = "unero-account-trail"
  s3_bucket_name                = aws_s3_bucket.audit.id
  include_global_service_events = true
  is_multi_region_trail         = true
  kms_key_id                    = module.kms_logs.key_arn
  enable_log_file_validation    = true
  tags                          = local.tags

  # The bucket policy must exist before CloudTrail validates the destination.
  depends_on = [aws_s3_bucket_policy.audit]
}
