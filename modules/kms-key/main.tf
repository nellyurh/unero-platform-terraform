# Customer-managed KMS key with rotation, for a single purpose (data, secrets, logs...).
resource "aws_kms_key" "this" {
  description             = "unero-${var.purpose}-${var.environment}"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  multi_region            = var.multi_region
  policy                  = var.policy_json != "" ? var.policy_json : data.aws_iam_policy_document.default.json
  tags                    = merge(var.tags, { Name = "unero-${var.purpose}-${var.environment}", Purpose = var.purpose })
}

resource "aws_kms_alias" "this" {
  name          = "alias/unero-${var.purpose}-${var.environment}"
  target_key_id = aws_kms_key.this.key_id
}

data "aws_caller_identity" "current" {}

# Default policy: root account admin + allow the listed service principals to use the key.
data "aws_iam_policy_document" "default" {
  statement {
    sid       = "RootAccountAdmin"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = length(var.service_principals) > 0 ? [1] : []
    content {
      sid       = "AllowServiceUse"
      effect    = "Allow"
      actions   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = var.service_principals
      }
    }
  }
}
