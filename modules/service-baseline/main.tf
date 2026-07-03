# The consistent baseline every Unero service composes from its own infra/terraform/.
# Gives a service: its task + execution roles, its work queues (+DLQs), a log group, a
# standard dashboard, and the always-on alarms. The service repo adds its ECS service +
# task definition on top, wiring in these outputs. Keeping this here means every service
# gets the same audited shape without copy-paste (ADR-024 philosophy, at the infra layer).

module "iam" {
  source              = "../task-iam-role"
  environment         = var.environment
  service_name        = var.service_name
  secrets_kms_key_arn = var.secrets_kms_key_arn
  sqs_queue_arns      = [for q in module.queue : q.queue_arn]
  event_bus_arn       = var.event_bus_arn
  tags                = var.tags
}

module "queue" {
  source               = "../sqs-queue"
  for_each             = toset(var.queues)
  name                 = "unero-${var.environment}-${var.service_name}-${each.value}"
  kms_key_id           = var.sqs_kms_key_arn
  alarm_sns_topic_arns = var.alarm_sns_topic_arns
  tags                 = var.tags
}

resource "aws_cloudwatch_log_group" "service" {
  name              = "/unero/${var.environment}/${var.service_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn
  tags              = var.tags
}

# Standard alarms: task health + p99 latency budget (CODING_STANDARDS §8.1).
resource "aws_cloudwatch_metric_alarm" "unhealthy_tasks" {
  alarm_name          = "unero-${var.environment}-${var.service_name}-unhealthy"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "RunningTaskCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 3
  threshold           = var.min_healthy_tasks
  comparison_operator = "LessThanThreshold"
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
  alarm_actions = var.alarm_sns_topic_arns
  tags          = var.tags
}

resource "aws_cloudwatch_dashboard" "service" {
  dashboard_name = "unero-${var.environment}-${var.service_name}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type       = "text", x = 0, y = 0, width = 24, height = 1,
        properties = { markdown = "# ${var.service_name} (${var.environment}) — golden signals" }
      },
      {
        type = "metric", x = 0, y = 1, width = 12, height = 6,
        properties = {
          title  = "CPU / Memory",
          region = var.region,
          metrics = [
            ["ECS/ContainerInsights", "CpuUtilized", "ClusterName", var.cluster_name, "ServiceName", var.service_name],
            ["ECS/ContainerInsights", "MemoryUtilized", "ClusterName", var.cluster_name, "ServiceName", var.service_name]
          ]
        }
      }
    ]
  })
}
