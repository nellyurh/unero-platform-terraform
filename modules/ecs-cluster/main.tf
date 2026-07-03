# Shared ECS Fargate cluster (ADR-010). Services deploy as ECS services into this cluster
# via the service-baseline module. Container Insights on for observability.
resource "aws_ecs_cluster" "this" {
  name = "unero-${var.environment}"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.exec.name
      }
    }
  }
  tags = merge(var.tags, { Name = "unero-${var.environment}" })
}

resource "aws_cloudwatch_log_group" "exec" {
  name              = "/unero/${var.environment}/ecs-exec"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn
  tags              = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = var.environment == "production" ? 1 : 0
    base              = var.environment == "production" ? 1 : 0
  }
  dynamic "default_capacity_provider_strategy" {
    for_each = var.environment == "production" ? [] : [1]
    content {
      capacity_provider = "FARGATE_SPOT"
      weight            = 1
    }
  }
}

# App-tier security group shared by all services (task-level SGs may narrow further).
resource "aws_security_group" "app" {
  name        = "unero-${var.environment}-app"
  description = "App tier: ECS tasks. Egress open; ingress from ALB only."
  vpc_id      = var.vpc_id
  egress {
    description = "Outbound to AWS APIs, Aurora, Redis, and NAT (via route table); ingress from ALB only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "unero-${var.environment}-app", Tier = "app" })
}
