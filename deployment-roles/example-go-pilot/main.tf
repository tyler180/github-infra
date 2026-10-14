terraform {
  required_version = ">= 1.15, < 2.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "6.68.0" }
    github = { source = "integrations/github", version = "6.13.0" }
  }
  backend "s3" {
    bucket       = "749rmw-tf-backends"
    key          = "github-infra/example-go-pilot-deployment-roles.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region              = "us-west-2"
  allowed_account_ids = ["138013422358"]
}
data "aws_caller_identity" "current" {}
provider "github" { owner = "tyler180" }

locals {
  account     = data.aws_caller_identity.current.account_id
  repository  = "tyler180/example-go-pilot"
  identity    = "tyler180@15354990/example-go-pilot@1416571064"
  environment = "terraform-production"
  function    = "arn:aws:lambda:us-west-2:${local.account}:function:example-go-pilot"
  ecr         = "arn:aws:ecr:us-west-2:${local.account}:repository/example-go-pilot"
  log_group   = "arn:aws:logs:us-west-2:${local.account}:log-group:/aws/lambda/example-go-pilot"
  lambda_role = "arn:aws:iam::${local.account}:role/example-go-pilot-lambda"
  state       = "arn:aws:s3:::749rmw-tf-backends/example-go-pilot/backend.tfstate"
  tags        = { ManagedBy = "github-infra", Repository = local.repository }
  plan_subjects = flatten([for repo in [local.identity, local.repository] : [
    "repo:${repo}:pull_request", "repo:${repo}:ref:refs/heads/main"
  ]])
  apply_subjects = [for repo in [local.identity, local.repository] : "repo:${repo}:environment:${local.environment}"]
}

resource "aws_iam_policy" "lambda_boundary" {
  name = "example-go-pilot-lambda-boundary"
  tags = local.tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = [local.log_group, "${local.log_group}:*"]
    }]
  })
}

resource "aws_iam_role" "deployment" {
  for_each = { plan = local.plan_subjects, apply = local.apply_subjects }
  name     = "example-go-pilot-terraform-${each.key}"
  tags     = local.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = "arn:aws:iam::${local.account}:oidc-provider/token.actions.githubusercontent.com" }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        "token.actions.githubusercontent.com:sub" = each.value
      } }
    }]
  })
}

resource "aws_iam_role_policy" "deployment" {
  for_each = aws_iam_role.deployment
  name     = "scoped-pilot-terraform"
  role     = each.value.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      { Effect = "Allow", Action = ["s3:ListBucket", "s3:GetBucketLocation"], Resource = "arn:aws:s3:::749rmw-tf-backends" },
      { Effect = "Allow", Action = each.key == "apply" ? ["s3:GetObject", "s3:PutObject"] : ["s3:GetObject"], Resource = local.state },
      { Effect = "Allow", Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], Resource = "${local.state}.tflock" },
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      { Effect = "Allow", Action = each.key == "apply" ? ["ecr:*"] : ["ecr:Describe*", "ecr:Get*", "ecr:List*", "ecr:BatchGetImage", "ecr:BatchCheckLayerAvailability"], Resource = local.ecr },
      { Effect = "Allow", Action = each.key == "apply" ? ["lambda:*"] : ["lambda:Get*", "lambda:List*"], Resource = [local.function, "${local.function}:*"] },
      { Effect = "Allow", Action = ["iam:Get*", "iam:List*"], Resource = [local.lambda_role, aws_iam_policy.lambda_boundary.arn] },
      { Effect = "Allow", Action = each.key == "apply" ? ["logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:PutRetentionPolicy", "logs:DeleteRetentionPolicy", "logs:TagResource", "logs:UntagResource", "logs:ListTagsForResource"] : ["logs:ListTagsForResource"], Resource = [local.log_group, "${local.log_group}:*"] },
      { Effect = "Allow", Action = ["logs:DescribeLogGroups"], Resource = "*" }
      ], [for statement in [
        { Effect = "Allow", Action = ["iam:CreateRole"], Resource = local.lambda_role, Condition = { StringEquals = { "iam:PermissionsBoundary" = aws_iam_policy.lambda_boundary.arn } } },
        { Effect = "Allow", Action = ["iam:DeleteRole", "iam:UpdateAssumeRolePolicy", "iam:TagRole", "iam:UntagRole"], Resource = local.lambda_role },
        { Effect = "Allow", Action = ["iam:PutRolePolicy", "iam:DeleteRolePolicy"], Resource = local.lambda_role },
        { Effect = "Allow", Action = ["iam:PassRole"], Resource = local.lambda_role, Condition = { StringEquals = { "iam:PassedToService" = "lambda.amazonaws.com" } } }
    ] : statement if each.key == "apply"])
  })
}

output "plan_role_arn" { value = aws_iam_role.deployment["plan"].arn }
output "apply_role_arn" { value = aws_iam_role.deployment["apply"].arn }
output "lambda_boundary_arn" { value = aws_iam_policy.lambda_boundary.arn }

resource "github_repository_environment" "deployment" {
  repository          = "example-go-pilot"
  environment         = local.environment
  prevent_self_review = false
  dynamic "reviewers" {
    for_each = var.require_environment_review ? [true] : []
    content { users = [15354990] }
  }
  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

variable "require_environment_review" {
  description = "Enable required reviewers only when the GitHub billing plan supports them for this private repository. Deployment remains manual and main-only."
  type        = bool
  default     = false
}

resource "github_repository_environment_deployment_policy" "main" {
  repository     = "example-go-pilot"
  environment    = github_repository_environment.deployment.environment
  branch_pattern = "main"
}

resource "github_actions_variable" "deployment" {
  for_each = {
    TERRAFORM_PLAN_ROLE_ARN  = aws_iam_role.deployment["plan"].arn
    TERRAFORM_APPLY_ROLE_ARN = aws_iam_role.deployment["apply"].arn
    TERRAFORM_STATE_ID       = "example-go-pilot"
    TERRAFORM_ENVIRONMENT    = github_repository_environment.deployment.environment
    TERRAFORM_AWS_REGION     = "us-west-2"
    TERRAFORM_ECR_REGISTRY   = "${local.account}.dkr.ecr.us-west-2.amazonaws.com"
    TERRAFORM_ENABLED        = "true"
    TERRAFORM_DEPLOY_ENABLED = "true"
  }
  repository    = "example-go-pilot"
  variable_name = each.key
  value         = each.value
  depends_on    = [github_repository_environment_deployment_policy.main, aws_iam_role_policy.deployment]
}
