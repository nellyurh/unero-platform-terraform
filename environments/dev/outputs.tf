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
