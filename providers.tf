provider "github" {
  owner = "tyler180"
}

terraform {
  required_version = ">= 1.15.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.11"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.50.0"
    }
    context = {
      source  = "registry.terraform.io/cloudposse/context"
      version = "0.5.0"
    }
  }
}