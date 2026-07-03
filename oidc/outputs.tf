output "oidc_provider_arn" {
  value = module.plan.oidc_provider_arn
}
output "plan_role_arn" {
  value = module.plan.role_arn
}
output "apply_role_arns" {
  value = { for env, m in module.apply : env => m.role_arn }
}
output "account_id" {
  description = "Set this as the AWS_ACCOUNT_ID GitHub secret."
  value       = data.aws_caller_identity.current.account_id
}
output "service_deployer_role_arns" {
  value = { for k, m in module.service_deployer : k => m.role_arn }
}
