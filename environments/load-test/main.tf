# dev environment: instantiates the shared substrate from the modules, wiring in the
# org-wide CMKs published by baseline/ (read via remote state).
data "terraform_remote_state" "baseline" {
  backend = "s3"
  config = {
    bucket = "unero-terraform-state"
    key    = "baseline/terraform.tfstate"
    region = "af-south-1"
  }
}

locals {
  tags = { Environment = var.environment }
}

# Flow-log role + group are small; kept inline per env to avoid a cross-env dependency.
resource "aws_cloudwatch_log_group" "flow" {
  name              = "/unero/${var.environment}/vpc-flow"
  retention_in_days = 30
  kms_key_id        = data.terraform_remote_state.baseline.outputs.kms_logs_key_arn
  tags              = local.tags
}
resource "aws_iam_role" "flow" {
  name               = "unero-${var.environment}-vpc-flow"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = local.tags
}
resource "aws_iam_role_policy" "flow" {
  name   = "write-flow-logs"
  role   = aws_iam_role.flow.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.flow.arn}:*" }]
  })
}

module "vpc" {
  source             = "../../modules/vpc"
  environment        = var.environment
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = true
  flow_log_group_arn = aws_cloudwatch_log_group.flow.arn
  flow_log_role_arn  = aws_iam_role.flow.arn
  tags               = local.tags
}

module "ecs" {
  source           = "../../modules/ecs-cluster"
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  logs_kms_key_arn = data.terraform_remote_state.baseline.outputs.kms_logs_key_arn
  tags             = local.tags
}

module "aurora" {
  source                 = "../../modules/aurora"
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  data_subnet_ids        = module.vpc.data_subnet_ids
  app_security_group_ids = [module.ecs.app_security_group_id]
  data_kms_key_arn       = data.terraform_remote_state.baseline.outputs.kms_data_key_arn
  secrets_kms_key_arn    = data.terraform_remote_state.baseline.outputs.kms_secrets_key_arn
  min_acu                = 0.5
  max_acu                = 32
  instance_count         = 1
  deletion_protection    = false
  tags                   = local.tags
}

module "redis" {
  source                 = "../../modules/elasticache"
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  data_subnet_ids        = module.vpc.data_subnet_ids
  app_security_group_ids = [module.ecs.app_security_group_id]
  replicas               = 0
  auth_token             = var.redis_auth_token
  data_kms_key_arn       = data.terraform_remote_state.baseline.outputs.kms_data_key_arn
  tags                   = local.tags
}

module "events" {
  source      = "../../modules/eventbridge-bus"
  environment = var.environment
  tags        = local.tags
}
