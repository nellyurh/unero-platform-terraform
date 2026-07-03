# Deployer roles for SERVICE repositories. The platform apply roles trust only this repo;
# each service repo that deploys via CI gets its own least-privilege deployer role,
# trusting repo:<org>/<service>:environment:<env>. Same gate stack as the platform:
# workflow_dispatch in the service repo + that repo's GitHub Environment protection.
#
# First consumer: identity-service -> staging.

locals {
  service_deployers = {
    identity-service-staging = {
      repo        = "identity-service"
      environment = "staging"
      service     = "identity-service"
    }
  }
}

module "service_deployer" {
  source   = "../modules/github-oidc-role"
  for_each = local.service_deployers

  role_name            = "unero-${each.value.environment}-${each.value.service}-deploy"
  github_org           = var.github_org
  github_repo          = each.value.repo
  create_oidc_provider = false
  oidc_provider_arn    = module.plan.oidc_provider_arn
  subject_claims = [
    "repo:${var.github_org}/${each.value.repo}:environment:${each.value.environment}",
  ]
  inline_policies = {
    deploy = data.aws_iam_policy_document.service_deploy[each.key].json
  }
  tags = { Environment = each.value.environment, Service = each.value.service }
}

data "aws_iam_policy_document" "service_deploy" {
  for_each = local.service_deployers

  # ECR: full lifecycle on the service's own repository only.
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid    = "EcrRepo"
    effect = "Allow"
    actions = [
      "ecr:CreateRepository", "ecr:DescribeRepositories", "ecr:ListTagsForResource",
      "ecr:TagResource", "ecr:PutLifecyclePolicy", "ecr:GetLifecyclePolicy",
      "ecr:SetRepositoryPolicy", "ecr:GetRepositoryPolicy",
      "ecr:PutImageScanningConfiguration", "ecr:PutImageTagMutability",
      "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart",
      "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer", "ecr:DescribeImages",
    ]
    resources = [
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/unero/${each.value.service}",
    ]
  }

  # Terraform state backend for the service's own state key.
  statement {
    sid     = "StateBucket"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.state_bucket_name}",
      "arn:aws:s3:::${var.state_bucket_name}/services/${each.value.service}/*",
      "arn:aws:s3:::${var.state_bucket_name}/environments/${each.value.environment}/terraform.tfstate",
    ]
  }
  statement {
    sid       = "StateLock"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"]
  }

  # ECS + ALB + the networking the service infra manages. Staging-pragmatic breadth on
  # elbv2/ecs describe+mutate; PassRole is tightly scoped to this service's roles.
  statement {
    sid    = "EcsDeploy"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition", "ecs:DeregisterTaskDefinition", "ecs:DescribeTaskDefinition",
      "ecs:CreateService", "ecs:UpdateService", "ecs:DeleteService", "ecs:DescribeServices",
      "ecs:DescribeClusters", "ecs:ListTasks", "ecs:DescribeTasks", "ecs:TagResource",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "Alb"
    effect    = "Allow"
    actions   = ["elasticloadbalancing:*"]
    resources = ["*"]
  }
  statement {
    sid    = "NetworkRead"
    effect = "Allow"
    actions = [
      "ec2:DescribeSecurityGroups", "ec2:DescribeSubnets", "ec2:DescribeVpcs",
      "ec2:DescribeNetworkInterfaces", "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress", "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress", "ec2:CreateTags",
    ]
    resources = ["*"]
  }
  statement {
    sid     = "PassOnlyIdentityRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/unero-${each.value.environment}-${each.value.service}-task",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/unero-${each.value.environment}-${each.value.service}-exec",
    ]
  }
  statement {
    sid       = "LogsAndSecretsRead"
    effect    = "Allow"
    actions   = ["logs:DescribeLogGroups", "secretsmanager:DescribeSecret", "secretsmanager:ListSecrets"]
    resources = ["*"]
  }
}
