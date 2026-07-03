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

# DR region (eu-west-1, ADR-018) — used only for the cross-region replica of the state bucket.
provider "aws" {
  alias  = "dr"
  region = var.dr_region
  default_tags {
    tags = {
      Platform  = "unero"
      ManagedBy = "terraform"
      Repo      = "unero-platform-terraform"
      Scope     = "baseline"
    }
  }
}
