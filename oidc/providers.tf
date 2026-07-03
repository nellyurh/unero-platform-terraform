provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Platform  = "unero"
      ManagedBy = "terraform"
      Repo      = "unero-platform-terraform"
      Scope     = "oidc"
    }
  }
}

variable "region" {
  type    = string
  default = "af-south-1"
}
