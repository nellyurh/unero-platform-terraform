# Per-account GitHub OIDC roles. Apply once in each workload account with that account's
# credentials (account IDs are never committed — they live only in GitHub secrets used by
# the workflows). Produces two roles:
#   unero-<env>-terraform-plan  : read-only, assumable from any PR + main (used by CI plan)
#   unero-<env>-terraform       : write, assumable only from main (dev/load-test) or from a
#                                 protected GitHub Environment (staging/production approvals)

locals {
  repo_sub = "repo:${var.github_org}/${var.github_repo}"

  # Apply trust: prod/staging bind to the GitHub Environment (so environment approvals gate
  # the assume); dev/load-test bind to the main branch.
  apply_subject_claims = contains(["production", "staging"], var.environment) ? [
    "${local.repo_sub}:environment:${var.environment}"
    ] : [
    "${local.repo_sub}:ref:refs/heads/main"
  ]

  tags = merge(var.tags, { Environment = var.environment })

  # Plan is read-only for describing resources, but terraform init/plan still needs to read
  # state and take the DynamoDB lock — grant exactly the state backend, nothing else writable.
  plan_state_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StateBucketRW"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
        Resource = [var.state_bucket_arn, "${var.state_bucket_arn}/*"]
      },
      {
        Sid      = "StateLock"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
        Resource = [var.lock_table_arn]
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

  role_name            = "unero-${var.environment}-terraform-plan"
  github_org           = var.github_org
  github_repo          = var.github_repo
  create_oidc_provider = var.create_oidc_provider
  subject_claims = [
    "${local.repo_sub}:pull_request",
    "${local.repo_sub}:ref:refs/heads/main",
  ]
  policy_arns     = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  inline_policies = { state-backend = local.plan_state_policy }
  tags            = local.tags
}

module "apply" {
  source = "../modules/github-oidc-role"

  role_name = "unero-${var.environment}-terraform"
  # Reuse the provider the plan module created in this account.
  create_oidc_provider     = false
  oidc_provider_arn        = module.plan.oidc_provider_arn
  github_org               = var.github_org
  github_repo              = var.github_repo
  subject_claims           = local.apply_subject_claims
  policy_arns              = var.apply_policy_arns
  permissions_boundary_arn = var.apply_permissions_boundary_arn
  tags                     = local.tags
}
