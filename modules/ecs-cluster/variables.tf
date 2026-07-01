variable "environment" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "log_retention_days" {
  type    = number
  default = 90
}
variable "logs_kms_key_arn" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
