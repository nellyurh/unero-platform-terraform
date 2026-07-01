variable "environment" {
  type = string
}
variable "service_name" {
  type = string
}
variable "secrets_kms_key_arn" {
  type = string
}
variable "sqs_queue_arns" {
  type    = list(string)
  default = []
}
variable "event_bus_arn" {
  type    = string
  default = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
