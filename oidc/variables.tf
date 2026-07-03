variable "github_org" {
  description = "GitHub owner allowed to assume the roles."
  type        = string
  default     = "nellyurh"
}

variable "github_repo" {
  type    = string
  default = "unero-platform-terraform"
}

variable "environments" {
  description = "Environments that get an apply role. Load-test included when it deploys via CI."
  type        = list(string)
  default     = ["dev", "staging", "production"]
}

variable "state_bucket_name" {
  description = "Terraform state bucket name in this account."
  type        = string
  default     = "unero-terraform-state"
}

variable "lock_table_name" {
  description = "DynamoDB state-lock table name in this account."
  type        = string
  default     = "unero-terraform-locks"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false + oidc_provider_arn if one already exists in the account."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN when create_oidc_provider = false."
  type        = string
  default     = ""
}

variable "apply_policy_arns" {
  description = "Managed policies for the apply roles. Default AdministratorAccess: sole TF automation identity, gated by OIDC trust + Environment approvals; scope down + add a boundary when the platform stabilizes."
  type        = list(string)
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "apply_permissions_boundary_arn" {
  description = "Optional permissions boundary for the apply roles."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
