provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Platform  = "unero"
      ManagedBy = "terraform"
      Repo      = "unero-platform-terraform"
      Scope     = "baseline"
    }
  }
}
