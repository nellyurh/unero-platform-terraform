terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
  # First (bootstrap) apply runs with `terraform init -backend=false` because this config
  # creates the roles CI needs and may precede the backend itself. After the backend exists,
  # re-init WITHOUT -backend=false and approve the state migration. See docs/BOOTSTRAP.md.
  backend "s3" {
    bucket         = "unero-terraform-state"
    key            = "oidc/terraform.tfstate"
    region         = "af-south-1"
    dynamodb_table = "unero-terraform-locks"
    encrypt        = true
  }
}
