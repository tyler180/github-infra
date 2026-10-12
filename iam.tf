data "aws_caller_identity" "current" {}
data "aws_secretsmanager_secrets" "mfl" {
  filter {
    name   = "name"
    values = ["mfl"]
  }
}

################################################################################
# OIDC Provider
# Note: This is one provider URL per AWS account
################################################################################

module "github_oidc_iam_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"
  version = "~> 6.8.0"

  tags = data.context_tags.this.tags
}

################################################################################
# GitHub OIDC IAM Role
################################################################################

module "github_actions_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.0"

  name               = local.deployment_name
  use_name_prefix    = false
  enable_github_oidc = true

  oidc_subjects = flatten([
    for repo_name, repo in local.github_actions_repositories : [
      "${local.github_username}/${repo_name}@${repo.repository_id}:ref:refs/heads/main",
      "${local.github_username}/${repo_name}@${repo.repository_id}:pull_request",
    ]

  ])

  policies = {
    S3 = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    # ecr_push     = aws_iam_policy.github_actions_ecr.arn
    GithubDeploy = aws_iam_policy.github_deploy.arn
  }

}

module "github_actions_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> 6.0"

  name               = local.deployment_name
  use_name_prefix    = false
  enable_github_oidc = true

  oidc_subjects = flatten([
    for repo_name, repo in local.github_actions_repositories : [
      "${local.github_username}/${repo_name}@${repo.repository_id}:ref:refs/heads/main",
      "${local.github_username}/${repo_name}@${repo.repository_id}:pull_request",
    ]

  ])

  permissions_boundary = aws_iam_policy.github_deploy_boundary.arn

  policies = {
    S3 = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    # ecr_push     = aws_iam_policy.github_actions_ecr.arn
    GithubDeploy = aws_iam_policy.github_deploy.arn
  }

}

resource "aws_iam_policy" "github_deploy" {
  name   = "github-actions-deploy"
  policy = data.aws_iam_policy_document.github_deploy.json

}

data "aws_iam_policy_document" "github_deploy" {

  statement {
    sid    = "ManageTerraformStateLock"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "arn:aws:s3:::749rmw-tf-backends/*",
    ]
  }

  statement {
    sid    = "AuthenticateToECR"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ManageBackendECRRepository"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchDeleteImage",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:CreateRepository",
      "ecr:DeleteLifecyclePolicy",
      "ecr:DeleteRepository",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:PutLifecyclePolicy",
      "ecr:SetRepositoryPolicy",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:UploadLayerPart",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ManageBackendLambda"
    effect = "Allow"

    actions = ["lambda:*"]

    resources = ["*"]
  }

  statement {
    sid    = "ManageLambdaExecutionRole"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
    ]

    resources = [
      "arn:aws:iam::138013422358:role/dynasty-ff-backend-dev",
    ]
  }

  statement {
    sid    = "PassExecutionRoleOnlyToLambda"
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      "arn:aws:iam::138013422358:role/dynasty-ff-backend-dev",
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "lambda.amazonaws.com",
      ]
    }
  }

  statement {
    sid    = "InspectLogGroups"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ManageBackendLogGroup"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DeleteRetentionPolicy",
      "logs:ListTagsForResource",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
    ]

    resources = [
      "arn:aws:logs:us-west-2:138013422358:log-group:/aws/lambda/dynasty-ff-backend-dev",
      "arn:aws:logs:us-west-2:138013422358:log-group:/aws/lambda/dynasty-ff-backend-dev:*",
    ]
  }

  statement {
    sid    = "GetSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      one(data.aws_secretsmanager_secrets.mfl.arns)
    ]
  }
}

resource "aws_iam_policy" "github_deploy_boundary" {
  name   = "${local.name}-deploy-boundary"
  policy = data.aws_iam_policy_document.github_deploy_boundary.json
}

data "aws_iam_policy_document" "github_deploy_boundary" {
  statement {
    sid    = "DeployS3"
    effect = "Allow"
    actions = [

    ]
  }
}

# data "aws_iam_policy_document" "github_actions_ecr" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "ecr:GetAuthorizationToken"
#     ]

#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"

#     actions = [
#       "ecr:BatchCheckLayerAvailability",
#       "ecr:CompleteLayerUpload",
#       "ecr:InitiateLayerUpload",
#       "ecr:PutImage",
#       "ecr:UploadLayerPart"
#     ]

#     resources = [
#       #   aws_ecr_repository.app.arn
#       # temporary workaround
#       "*"
#     ]
#   }
# }

# resource "aws_iam_policy" "github_actions_ecr" {
#   name   = local.deployment_name
#   policy = data.aws_iam_policy_document.github_actions_ecr.json
# }

# data "aws_iam_policy_document" "github_assume_deployment_roles" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "sts:AssumeRole",
#     ]

#     resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.deployment_name}"]
#   }
# }

# resource "aws_iam_policy" "github_assume_deployment_roles" {
#   name   = "github-actions-assume-deployment-roles"
#   policy = data.aws_iam_policy_document.github_assume_deployment_roles.json

# }