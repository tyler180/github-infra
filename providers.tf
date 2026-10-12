provider "github" {
  owner = var.github_owner
}

provider "aws" {
  region = "us-west-2"
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.5.0"
    }
    github = {
      source  = "integrations/github"
      version = ">=6.13.0"
    }
  }
}