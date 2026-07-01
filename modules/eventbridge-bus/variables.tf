variable "environment" {
  type = string
}
variable "archive_retention_days" {
  type    = number
  default = 90
}
variable "enable_schema_discovery" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
