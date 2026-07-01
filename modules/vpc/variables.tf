variable "environment" {
  type = string
}
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
variable "availability_zones" {
  description = "AZs to span (>= 2). af-south-1 has 3."
  type        = list(string)
}
variable "single_nat_gateway" {
  description = "One NAT for the whole VPC (lower envs) vs one per AZ (production)."
  type        = bool
  default     = true
}
variable "flow_log_group_arn" {
  type = string
}
variable "flow_log_role_arn" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
