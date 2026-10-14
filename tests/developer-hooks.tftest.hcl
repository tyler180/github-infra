mock_provider "github" {}
mock_provider "aws" {}
run "managed_hooks_configuration" {
  command = plan
  assert {
    condition     = terraform_data.contract.input.repositories.pilot.developer_hooks.ai_review == true
    error_message = "Managed hook selection must survive inventory loading."
  }
}
run "reject_non_boolean_ai_opt_in" {
  command = plan
  variables { inventory_file = "tests/invalid-developer-hooks.json" }
  expect_failures = [terraform_data.contract]
}
