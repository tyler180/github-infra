mock_provider "github" {}
mock_provider "aws" {}

run "adoption_preserves_explicit_settings_and_owns_no_components" {
  command = plan
  variables { inventory_file = "examples/adoption/repositories.json" }
  assert {
    condition = (
      terraform_data.contract.input.repositories.example_existing_go.initialization == "none" &&
      !module.repositories["example_existing_go"].managed_components.default_branch &&
      !module.repositories["example_existing_go"].managed_components.actions_policy &&
      !module.repositories["example_existing_go"].managed_components.workflow_permissions &&
      module.repositories["example_existing_go"].managed_ruleset_id == null &&
      length(module.repositories["example_existing_go"].managed_components.team_grants) == 0
    )
    error_message = "Adoption must select repository-only management without bootstrap or grants."
  }
}

run "starter_rejects_floating_workflow_ref" {
  command = plan
  variables { inventory_file = "tests/invalid-terraform-starter.json" }
  expect_failures = [terraform_data.contract]
}

run "adoption_requires_observed_settings" {
  command = plan
  variables { inventory_file = "tests/invalid-adoption-settings.json" }
  expect_failures = [terraform_data.contract]
}
