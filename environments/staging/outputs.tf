output "vpc_id" {
  value = module.vpc.vpc_id
}
output "aurora_endpoint" {
  value = module.aurora.cluster_endpoint
}
output "aurora_secret_arn" {
  value = module.aurora.master_user_secret_arn
}
output "redis_endpoint" {
  value = module.redis.primary_endpoint
}
output "event_bus_name" {
  value = module.events.bus_name
}
output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

# --- Networking primitives the identity-service ECS service needs for its task network config ---
output "app_subnet_ids" {
  description = "Private app-tier subnets; identity's ECS service places tasks here."
  value       = module.vpc.app_subnet_ids
}
output "app_security_group_id" {
  description = "Shared app-tier security group for ECS tasks."
  value       = module.ecs.app_security_group_id
}
output "event_bus_arn" {
  value = module.events.bus_arn
}

# --- identity-service staging wiring (consumed by identity-service/infra/terraform) ---
output "identity_task_role_arn" {
  value = module.identity.task_role_arn
}
output "identity_execution_role_arn" {
  value = module.identity.execution_role_arn
}
output "identity_log_group_name" {
  value = module.identity.log_group_name
}
output "identity_secret_arns" {
  description = "Map of secret suffix => ARN for identity-service; referenced by the ECS task definition."
  value       = { for k, s in aws_secretsmanager_secret.identity : k => s.arn }
}
output "public_subnet_ids" {
  description = "Public subnets for internet-facing load balancers (service ALBs)."
  value       = module.vpc.public_subnet_ids
}
