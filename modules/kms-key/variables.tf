variable "purpose" {
  description = "Single purpose for this key: data | secrets | logs | rds | sqs | eventbridge."
  type        = string
}
variable "environment" {
  description = "dev | staging | production | load-test."
  type        = string
}
variable "deletion_window_in_days" {
  type    = number
  default = 30
}
variable "multi_region" {
  description = "True for keys that must replicate to the DR region (eu-west-1)."
  type        = bool
  default     = false
}
variable "service_principals" {
  description = "AWS service principals permitted to use the key (e.g. logs.amazonaws.com)."
  type        = list(string)
  default     = []
}
variable "policy_json" {
  description = "Override key policy. Empty string uses the module default."
  type        = string
  default     = ""
}
variable "tags" {
  type    = map(string)
  default = {}
}
