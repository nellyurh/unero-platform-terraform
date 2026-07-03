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
  default = "16.4"
}
variable "master_username" {
  type    = string
  default = "unero_admin"
}
variable "data_kms_key_arn" {
  type = string
}
variable "secrets_kms_key_arn" {
  type = string
}
variable "min_acu" {
  description = "Minimum Aurora Capacity Units (0.5 increments)."
  type        = number
  default     = 0.5
}
variable "max_acu" {
  type    = number
  default = 4
}
variable "instance_count" {
  description = "1 writer for lower envs; 2+ (writer + reader) in production."
  type        = number
  default     = 1
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "deletion_protection" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_data_api" {
  description = "Enable the RDS Data API (HTTP endpoint) for keyless SQL bootstrap (role/schema creation). Off by default."
  type        = bool
  default     = false
}
