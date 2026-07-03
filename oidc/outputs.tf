output "plan_role_arn" {
  value = module.plan.role_arn
}
output "apply_role_arn" {
  value = module.apply.role_arn
}
output "oidc_provider_arn" {
  value = module.plan.oidc_provider_arn
}
