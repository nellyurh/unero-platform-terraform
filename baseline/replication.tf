# Cross-region replication of the Terraform state bucket to the DR region (eu-west-1,
# ADR-018). Satisfies the CKV_AWS_144 invariant the platform enforces on state
# (policies/checkov.yaml). The state bucket already has versioning + KMS SSE; replication
# adds an offsite, versioned copy encrypted with a DR-region replica of the data CMK.

# DR-region replica of the multi-region data CMK, so the replica bucket encrypts with a
# key that physically exists in eu-west-1 (multi-region key => region-local ARN).
resource "aws_kms_replica_key" "data_dr" {
  provider                = aws.dr
  description             = "unero-data-baseline (eu-west-1 replica) — state-bucket SSE"
  primary_key_arn         = module.kms_data.key_arn
  deletion_window_in_days = 30
  tags                    = local.tags
}

# Destination bucket in the DR region.
resource "aws_s3_bucket" "state_replica" {
  #checkov:skip=CKV_AWS_144:This bucket IS the cross-region replica destination; it does not itself replicate.
  provider = aws.dr
  bucket   = "unero-terraform-state-dr"
  tags     = local.tags
}
resource "aws_s3_bucket_versioning" "state_replica" {
  provider = aws.dr
  bucket   = aws_s3_bucket.state_replica.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "state_replica" {
  provider = aws.dr
  bucket   = aws_s3_bucket.state_replica.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_replica_key.data_dr.arn
    }
    bucket_key_enabled = true
  }
}
resource "aws_s3_bucket_public_access_block" "state_replica" {
  provider                = aws.dr
  bucket                  = aws_s3_bucket.state_replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role S3 assumes to perform replication.
data "aws_iam_policy_document" "replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "replication" {
  name               = "unero-terraform-state-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
  tags               = local.tags
}
data "aws_iam_policy_document" "replication" {
  statement {
    sid       = "SourceList"
    actions   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }
  statement {
    sid       = "SourceRead"
    actions   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
    resources = ["${aws_s3_bucket.state.arn}/*"]
  }
  statement {
    sid       = "DestWrite"
    actions   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
    resources = ["${aws_s3_bucket.state_replica.arn}/*"]
  }
  statement {
    sid       = "DecryptSource"
    actions   = ["kms:Decrypt"]
    resources = [module.kms_data.key_arn]
  }
  statement {
    sid       = "EncryptDest"
    actions   = ["kms:Encrypt"]
    resources = [aws_kms_replica_key.data_dr.arn]
  }
}
resource "aws_iam_role_policy" "replication" {
  name   = "replication"
  role   = aws_iam_role.replication.id
  policy = data.aws_iam_policy_document.replication.json
}

# Replication rule on the source state bucket.
resource "aws_s3_bucket_replication_configuration" "state" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "state-to-dr"
    status = "Enabled"

    filter {}
    delete_marker_replication {
      status = "Enabled"
    }
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
    destination {
      bucket        = aws_s3_bucket.state_replica.arn
      storage_class = "STANDARD"
      encryption_configuration {
        replica_kms_key_id = aws_kms_replica_key.data_dr.arn
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}
