provider "aws" {
  profile = local.aws_profile
  region  = local.aws_region

  default_tags {
    tags = {
      Environment = "lab"
      ManagedBy   = "Terraform"
      Project     = "multicloud-connectivity-lab"
    }
  }
}

provider "google" {
  project = local.gcp_project
  region  = local.gcp_region

  billing_project       = local.gcp_project
  user_project_override = true
}

# Enable bootstrap APIs without requiring quota APIs in the lab project first.
provider "google" {
  alias   = "bootstrap"
  project = local.gcp_project
  region  = local.gcp_region

  user_project_override = false
}
