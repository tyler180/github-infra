terraform {
  required_version = ">= 1.15.0"
  backend "s3" {
    region       = "us-west-2"
    bucket       = "749rmw-tf-backends"
    key          = "github/github-infra.tfstate"
    encrypt      = true
    use_lockfile = true
  }

  #   required_providers {
  #     aws = {
  #       source  = "hashicorp/aws"
  #       version = ">= 6.5.0"
  #     }
  #     local = {
  #       source  = "hashicorp/local"
  #       version = ">= 1.3"
  #     }
  #     context = {
  #       source  = "registry.terraform.io/cloudposse/context"
  #       version = "0.5.0"
  #     }
  #     github = {
  #       source  = "integrations/github"
  #       version = ">=6.13.0"
  #     }
  #   }
}