# identity-service — staging wiring (Milestone 3A vertical slice).
#
# identity-service (identity-v1.0.0-rc1) is the platform reference implementation and the
# platform Identity Provider. Its GA is blocked on "staging wiring from
# unero-platform-terraform": until this file existed, no environment composed
# service-baseline and identity had nowhere to deploy. This slice stands up identity's
# platform-side substrate in staging so its own repo's ECS service/task-definition can be
# applied on top, consuming the outputs below.
#
# What lives HERE (platform layer): task + execution IAM roles, log group, standard alarms
# + dashboard, and the Secrets Manager containers identity reads at boot (ADR-017).
# What lives in identity-service/infra/terraform (service layer): the ECS service, task
# definition, ALB target group / listener rule. It wires in module.identity.* outputs.
#
# identity is producer-only on the bus today (Outbox relay -> EventBridge PutEvents, ADR-003);
# it consumes no SQS queue yet, so queues = []. When a consumer arrives, add the suffix here
# and provision an SQS-usable CMK (the baseline data key does not grant sqs.amazonaws.com).

locals {
  identity_service_name = "identity-service"

  # Secret containers identity reads at boot. Values are populated out-of-band by the
  # deploy/rotation step (RS256 signing material per ADR-ID-001, DB DSN scoped to identity's
  # schema, Redis auth for the jti denylist per ADR-ID-003). No secret material in Terraform.
  identity_secrets = [
    "database",         # DSN for identity's own PG role, scoped to its schema in the shared cluster
    "redis",            # Redis AUTH token for denylist / rate-limit counters (ADR-ID-003)
    "jwt-signing-keys", # RS256 private key material + kid set (ADR-ID-001)
    "app-key",          # Laravel APP_KEY
  ]
}

module "identity" {
  source = "../../modules/service-baseline"

  environment  = var.environment
  service_name = local.identity_service_name
  region       = var.region
  cluster_name = module.ecs.cluster_name

  # Producer-only for now; the task role gains no SQS grant while this is empty.
  queues        = []
  event_bus_arn = module.events.bus_arn

  secrets_kms_key_arn = data.terraform_remote_state.baseline.outputs.kms_secrets_key_arn
  sqs_kms_key_arn     = data.terraform_remote_state.baseline.outputs.kms_data_key_arn
  logs_kms_key_arn    = data.terraform_remote_state.baseline.outputs.kms_logs_key_arn

  log_retention_days   = 90
  min_healthy_tasks    = 1
  alarm_sns_topic_arns = [] # wire to the platform alerting topic when it exists

  tags = merge(local.tags, { Service = local.identity_service_name })
}

# Secret CONTAINERS only (no versions => no secret material in state/code). The task role
# from service-baseline already grants GetSecretValue on unero/${env}/${service}/* and
# kms:Decrypt on the secrets CMK, so identity can read these once populated.
resource "aws_secretsmanager_secret" "identity" {
  for_each = toset(local.identity_secrets)

  name        = "unero/${var.environment}/${local.identity_service_name}/${each.value}"
  description = "identity-service (${var.environment}) — ${each.value}; value set by deploy/rotation, never Terraform"
  kms_key_id  = data.terraform_remote_state.baseline.outputs.kms_secrets_key_arn

  recovery_window_in_days = 7

  tags = merge(local.tags, { Service = local.identity_service_name, Secret = each.value })
}
