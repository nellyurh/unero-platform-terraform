# Shared version constraints. Symlinked/duplicated into each environment via -chdir.
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}
