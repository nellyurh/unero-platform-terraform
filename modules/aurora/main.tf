# Aurora Serverless v2 PostgreSQL (ADR-008). One cluster per environment; each service
# owns a schema within it (data-ownership is enforced by IAM + schema grants, not shared
# tables). Encrypted with the data CMK; credentials live in Secrets Manager (ADR-017).
resource "aws_db_subnet_group" "this" {
  name       = "unero-${var.environment}"
  subnet_ids = var.data_subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name        = "unero-${var.environment}-aurora"
  description = "Aurora access from the app tier only."
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from app tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.app_security_group_ids
  }
  egress {
    description = "Outbound to AWS APIs (RDS-managed operations); no inbound path from data tier"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "unero-${var.environment}-aurora" })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier              = "unero-${var.environment}"
  engine                          = "aurora-postgresql"
  engine_mode                     = "provisioned"
  engine_version                  = var.engine_version
  database_name                   = "unero"
  master_username                 = var.master_username
  manage_master_user_password     = true
  master_user_secret_kms_key_id   = var.secrets_kms_key_arn
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  storage_encrypted               = true
  kms_key_id                      = var.data_kms_key_arn
  backup_retention_period         = var.backup_retention_days
  preferred_backup_window         = "02:00-03:00"
  deletion_protection             = var.deletion_protection
  skip_final_snapshot             = var.environment == "production" ? false : true
  final_snapshot_identifier       = var.environment == "production" ? "unero-${var.environment}-final" : null
  enabled_cloudwatch_logs_exports = ["postgresql"]

  serverlessv2_scaling_configuration {
    min_capacity = var.min_acu
    max_capacity = var.max_acu
  }
  tags = var.tags
}

resource "aws_rds_cluster_instance" "this" {
  count                = var.instance_count
  identifier           = "unero-${var.environment}-${count.index}"
  cluster_identifier   = aws_rds_cluster.this.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.this.engine
  engine_version       = aws_rds_cluster.this.engine_version
  performance_insights_enabled = true
  tags                 = var.tags
}
