variable "name" {
  type = string
}
variable "kms_key_id" {
  type = string
}
variable "visibility_timeout_seconds" {
  type    = number
  default = 60
}
variable "retention_seconds" {
  type    = number
  default = 345600 # 4 days
}
variable "dlq_retention_seconds" {
  type    = number
  default = 1209600 # 14 days
}
variable "max_receive_count" {
  type    = number
  default = 5
}
variable "alarm_sns_topic_arns" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
