terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
  # Applied once per workload account with THAT account's credentials/backend.
  # State key is namespaced by environment; bucket is provided at init time
  # (-backend-config) so no account-specific value is committed.
  backend "s3" {
    key     = "oidc/terraform.tfstate"
    encrypt = true
  }
}
