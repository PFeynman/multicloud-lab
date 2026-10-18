provider "aws" {
  profile = "multicloud-lab"
  region  = "eu-west-2"

  default_tags {
    tags = {
      Environment = "lab"
      ManagedBy   = "Terraform"
      Project     = "multicloud-connectivity-lab"
    }
  }
}

provider "google" {
  project = "multicloud-lab-prp"
  region  = "europe-west2"

  billing_project       = "multicloud-lab-prp"
  user_project_override = true
}

# Enable bootstrap APIs without requiring quota APIs in the lab project first.
provider "google" {
  alias   = "bootstrap"
  project = "multicloud-lab-prp"
  region  = "europe-west2"

  user_project_override = false
}

data "aws_region" "current" {}

data "google_project" "current" {}
