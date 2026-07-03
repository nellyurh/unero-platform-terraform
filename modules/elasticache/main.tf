# ElastiCache for Redis (ADR-009): cache, rate-limit counters, idempotency keys.
# Encryption in transit + at rest; auth token in Secrets Manager.
resource "aws_elasticache_subnet_group" "this" {
  name       = "unero-${var.environment}"
  subnet_ids = var.data_subnet_ids
}

resource "aws_security_group" "this" {
  name        = "unero-${var.environment}-redis"
  description = "Redis access from the app tier only."
  vpc_id      = var.vpc_id
  ingress {
    description     = "Redis from app tier"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.app_security_group_ids
  }
  egress {
    description = "Outbound to AWS APIs (ElastiCache-managed operations); no inbound path from data tier"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "unero-${var.environment}-redis" })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "unero-${var.environment}"
  description                = "Unero ${var.environment} Redis (cache/rate-limit/idempotency)."
  engine                     = "redis"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_node_groups            = 1
  replicas_per_node_group    = var.replicas
  automatic_failover_enabled = var.replicas > 0
  multi_az_enabled           = var.replicas > 0
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.auth_token
  kms_key_id                 = var.data_kms_key_arn
  snapshot_retention_limit   = var.environment == "production" ? 7 : 1
  tags                       = var.tags
}
