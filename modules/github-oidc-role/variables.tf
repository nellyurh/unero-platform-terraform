variable "role_name" {
  description = "IAM role name, e.g. unero-dev-terraform or unero-dev-terraform-plan."
  type        = string
}

variable "github_org" {
  description = "GitHub org/owner that may assume the role."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository that may assume the role (without owner)."
  type        = string
}

variable "subject_claims" {
  description = "Allowed token.actions.githubusercontent.com:sub values (StringLike). e.g. repo:owner/repo:ref:refs/heads/main"
  type        = list(string)
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider in this account. Set false if it already exists and pass oidc_provider_arn."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN, used when create_oidc_provider = false."
  type        = string
  default     = ""
}

variable "policy_arns" {
  description = "Managed policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of name => policy JSON attached inline to the role."
  type        = map(string)
  default     = {}
}

variable "permissions_boundary_arn" {
  description = "Optional permissions boundary ARN to cap the role (recommended for the apply role)."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Max STS session seconds."
  type        = number
  default     = 3600
}

variable "tags" {
  type    = map(string)
  default = {}
}
