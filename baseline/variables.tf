variable "region" {
  type    = string
  default = "af-south-1"
}

variable "dr_region" {
  description = "Disaster-recovery region for the state replica (ADR-018)."
  type        = string
  default     = "eu-west-1"
}
