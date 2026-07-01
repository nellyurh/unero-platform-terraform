provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Platform    = "unero"
      Environment = var.environment
      ManagedBy   = "terraform"
      Repo        = "unero-platform-terraform"
    }
  }
}
