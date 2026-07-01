output "task_role_arn" {
  value = module.iam.task_role_arn
}
output "execution_role_arn" {
  value = module.iam.execution_role_arn
}
output "log_group_name" {
  value = aws_cloudwatch_log_group.service.name
}
output "queue_arns" {
  value = { for k, q in module.queue : k => q.queue_arn }
}
output "queue_urls" {
  value = { for k, q in module.queue : k => q.queue_url }
}
