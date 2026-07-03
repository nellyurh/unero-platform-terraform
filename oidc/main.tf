# GitHub Actions OIDC — SINGLE-ACCOUNT model (ARB decision 2026-07-03: one AWS account,
# environment separation via per-env Terraform state keys + per-env resources + GitHub
# Environment approvals; no AWS Organization for now).
#
# Applied ONCE in the Unero account. Creates:
#   1x GitHub OIDC provider
#   1x unero-terraform-plan            read-only; assumable from any PR and main.
#                                      PR code can trigger plan, so this role MUST NOT
#                                      be able to mutate infra or read secrets.
#   1x unero-<env>-terraform per env   apply; identical permissions, DIFFERENT TRUST:
#        dev, load-test  -> ref:refs/heads/main
#        staging, prod   -> environment:<env>  (GitHub Environment approval == IAM gate)
#
# Multi-account evolution path: each apply role's name and trust are already per-env; to
# split later, re-create the same role in the new account and repoint the env's backend.
# Nothing in CI renames.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  repo_sub     = "repo:${var.github_org}/${var.github_repo}"
  environments = var.environments

  # Trust claim per env: prod/staging bind to the protected GitHub Environment.
  apply_subject_claims = {
    for env in local.environments : env => (
      contains(["production", "staging"], env)
      ? ["${local.repo_sub}:environment:${env}"]
      : ["${local.repo_sub}:ref:refs/heads/main"]
    )
  }

  state_bucket_arn = "arn:aws:s3:::${var.state_bucket_name}"
  lock_table_arn   = "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.lock_table_name}"

  # plan needs the state backend (read state, take/release lock) but nothing mutable else;
  # explicitly deny secret reads so a hostile PR can't exfiltrate via plan.
  plan_state_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StateBucketRW"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [local.state_bucket_arn, "${local.state_bucket_arn}/*"]
      },
      {
        Sid      = "StateLock"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
        Resource = [local.lock_table_arn]
      },
      {
        Sid      = "NoSecretReadsDuringPlan"
        Effect   = "Deny"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = ["*"]
      }
    ]
  })
}

module "plan" {
  source = "../modules/github-oidc-role"

  role_name            = "unero-terraform-plan"
  github_org           = var.github_org
  github_repo          = var.github_repo
  create_oidc_provider = var.create_oidc_provider
  oidc_provider_arn    = var.oidc_provider_arn
  subject_claims = [
    "${local.repo_sub}:pull_request",
    "${local.repo_sub}:ref:refs/heads/main",
  ]
  policy_arns     = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  inline_policies = { state-backend = local.plan_state_policy }
  tags            = var.tags
}

module "apply" {
  source   = "../modules/github-oidc-role"
  for_each = toset(local.environments)

  role_name                = "unero-${each.value}-terraform"
  github_org               = var.github_org
  github_repo              = var.github_repo
  create_oidc_provider     = false
  oidc_provider_arn        = module.plan.oidc_provider_arn
  subject_claims           = local.apply_subject_claims[each.value]
  policy_arns              = var.apply_policy_arns
  permissions_boundary_arn = var.apply_permissions_boundary_arn
  tags                     = merge(var.tags, { Environment = each.value })
}
