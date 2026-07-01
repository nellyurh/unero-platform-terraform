variable "environment" {
  type = string
}
variable "service_name" {
  description = "kebab-case, e.g. config-service."
  type        = string
}
variable "region" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "queues" {
  description = "Logical queue suffixes for this service, e.g. [\"events\", \"outbox-retry\"]."
  type        = list(string)
  default     = []
}
variable "event_bus_arn" {
  type    = string
  default = ""
}
variable "secrets_kms_key_arn" {
  type = string
}
variable "sqs_kms_key_arn" {
  type = string
}
variable "logs_kms_key_arn" {
  type = string
}
variable "log_retention_days" {
  type    = number
  default = 90
}
variable "min_healthy_tasks" {
  type    = number
  default = 1
}
variable "alarm_sns_topic_arns" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
