variable "environment" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "data_subnet_ids" {
  type = list(string)
}
variable "app_security_group_ids" {
  type = list(string)
}
variable "engine_version" {
  type    = string
  default = "7.1"
}
variable "node_type" {
  type    = string
  default = "cache.t4g.small"
}
variable "replicas" {
  description = "Replicas per shard. 0 in dev; >=1 in production for failover."
  type        = number
  default     = 0
}
variable "auth_token" {
  description = "Redis AUTH token, injected from Secrets Manager at plan time via data source (never a literal)."
  type        = string
  sensitive   = true
}
variable "data_kms_key_arn" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
