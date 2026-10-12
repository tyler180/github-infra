terraform {
  required_version = ">= 1.15.0"
  backend "s3" {
    region       = "us-west-2"
    bucket       = "749rmw-tf-backends"
    key          = "github/github-infra.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}