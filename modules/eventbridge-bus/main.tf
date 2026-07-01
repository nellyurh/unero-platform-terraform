# The platform event bus. Producers publish via the Outbox relay (ADR-003); consumers
# subscribe with rules. Archive enables replay; schema discovery aids contract tooling.
resource "aws_cloudwatch_event_bus" "this" {
  name = "unero-${var.environment}"
  tags = merge(var.tags, { Name = "unero-${var.environment}" })
}

resource "aws_cloudwatch_event_archive" "this" {
  name             = "unero-${var.environment}-archive"
  event_source_arn = aws_cloudwatch_event_bus.this.arn
  retention_days   = var.archive_retention_days
  description      = "Replayable archive of all platform events (ADR-003)."
}

resource "aws_schemas_discoverer" "this" {
  count       = var.enable_schema_discovery ? 1 : 0
  source_arn  = aws_cloudwatch_event_bus.this.arn
  description = "Auto-discovers event schemas for client generation (ADR-022)."
  tags        = var.tags
}
