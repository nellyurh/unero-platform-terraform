# A work queue plus its dead-letter queue, both KMS-encrypted. DLQ is mandatory
# (AI_RULES: "Never mask a poison message. Let it DLQ; runbook resolves.")
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-dlq"
  kms_master_key_id         = var.kms_key_id
  message_retention_seconds = var.dlq_retention_seconds
  tags                      = merge(var.tags, { Name = "${var.name}-dlq", Role = "dlq" })
}

resource "aws_sqs_queue" "main" {
  name                       = var.name
  kms_master_key_id          = var.kms_key_id
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.retention_seconds
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
  tags = merge(var.tags, { Name = var.name, Role = "work" })
}

# Alarm when anything lands in the DLQ — a poison message needs a human (Volume 12).
resource "aws_cloudwatch_metric_alarm" "dlq_not_empty" {
  alarm_name          = "${var.name}-dlq-not-empty"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { QueueName = aws_sqs_queue.dlq.name }
  alarm_actions       = var.alarm_sns_topic_arns
  tags                = var.tags
}
