variable "environment" {
  type    = string
  default = "dev"
}
variable "region" {
  type    = string
  default = "af-south-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "availability_zones" {
  type    = list(string)
  default = ["af-south-1a", "af-south-1b", "af-south-1c"]
}
variable "redis_auth_token" {
  description = "Sourced from Secrets Manager at apply time via TF_VAR / CI, never committed."
  type        = string
  sensitive   = true
}
