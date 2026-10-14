mock_provider "github" {}
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "138013422358" }
  }
}

override_resource {
  target          = aws_iam_policy.lambda_boundary
  override_during = plan
  values          = { arn = "arn:aws:iam::138013422358:policy/example-go-pilot-lambda-boundary" }
}

run "protected_environment_and_exact_oidc_trust" {
  command = plan
  assert {
    condition = (
      jsondecode(aws_iam_role.deployment["apply"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == local.apply_subjects &&
      jsondecode(aws_iam_role.deployment["plan"].assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == local.plan_subjects &&
      github_repository_environment_deployment_policy.main.branch_pattern == "main"
    )
    error_message = "Deployment must require the exact pilot/environment identity and protected main branch."
  }
  assert {
    condition = (
      one([for statement in jsondecode(aws_iam_role_policy.deployment["apply"].policy).Statement : statement if contains(statement.Action, "iam:CreateRole")]).Condition.StringEquals["iam:PermissionsBoundary"] == aws_iam_policy.lambda_boundary.arn &&
      one([for statement in jsondecode(aws_iam_role_policy.deployment["apply"].policy).Statement : statement if contains(statement.Action, "iam:PassRole")]).Resource == local.lambda_role &&
      length([for statement in jsondecode(aws_iam_role_policy.deployment["plan"].policy).Statement : statement if contains(statement.Action, "iam:CreateRole")]) == 0
    )
    error_message = "Only apply can create/pass the bounded pilot execution role."
  }
}
