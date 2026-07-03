variable "environment" {
  description = "Which account this is being applied to: dev | staging | production | load-test."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production", "load-test"], var.environment)
    error_message = "environment must be one of dev, staging, production, load-test."
  }
}

variable "region" {
  type    = string
  default = "af-south-1"
}

variable "github_org" {
  description = "GitHub owner. No account IDs are committed; this is the org name only."
  type        = string
  default     = "nellyurh"
}

variable "github_repo" {
  type    = string
  default = "unero-platform-terraform"
}

variable "create_oidc_provider" {
  description = "Create the OIDC provider in this account (false if one already exists)."
  type        = bool
  default     = true
}

variable "state_bucket_arn" {
  description = "ARN of the Terraform state bucket this account's roles must read/write for init+lock."
  type        = string
}

variable "lock_table_arn" {
  description = "ARN of the DynamoDB state-lock table."
  type        = string
}

variable "apply_policy_arns" {
  description = "Managed policies for the APPLY role. Default AdministratorAccess is the sole TF automation role, gated by tight OIDC trust; swap for a scoped policy + boundary in regulated accounts."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "apply_permissions_boundary_arn" {
  description = "Optional boundary to cap the apply role (recommended in production)."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
