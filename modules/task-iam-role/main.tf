# ECS-Fargate equivalent of ADR-017 "IRSA": each service gets a task role (its runtime
# identity) and a task execution role (image pull + secret injection). Least privilege:
# a service may read ONLY its own secrets and use ONLY the keys it needs.
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- Task execution role: ECS agent pulls image + injects secrets into the container ---
resource "aws_iam_role" "execution" {
  name               = "unero-${var.environment}-${var.service_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  name   = "read-service-secrets"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.secrets.json
}

# --- Task role: the service's own runtime identity (SQS, EventBridge, its secrets) ---
resource "aws_iam_role" "task" {
  name               = "unero-${var.environment}-${var.service_name}-task"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "task_runtime" {
  name   = "runtime"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.runtime.json
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Secret access is scoped by name prefix: unero/<env>/<service>/*
data "aws_iam_policy_document" "secrets" {
  statement {
    sid       = "ReadOwnSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:unero/${var.environment}/${var.service_name}/*"]
  }
  statement {
    sid       = "DecryptSecrets"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.secrets_kms_key_arn]
  }
}

data "aws_iam_policy_document" "runtime" {
  dynamic "statement" {
    for_each = length(var.sqs_queue_arns) > 0 ? [1] : []
    content {
      sid       = "OwnQueues"
      effect    = "Allow"
      actions   = ["sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      resources = var.sqs_queue_arns
    }
  }
  dynamic "statement" {
    for_each = var.event_bus_arn != "" ? [1] : []
    content {
      sid       = "PublishEvents"
      effect    = "Allow"
      actions   = ["events:PutEvents"]
      resources = [var.event_bus_arn]
    }
  }
  statement {
    sid       = "ReadOwnSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:unero/${var.environment}/${var.service_name}/*"]
  }
}
