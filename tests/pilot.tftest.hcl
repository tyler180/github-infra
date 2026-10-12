mock_provider "github" {}
mock_provider "aws" {}

run "pilot_is_private_and_unprotected_during_create" {
  command = plan
  assert {
    condition     = module.repositories["pilot"].name == "github-module-pilot"
    error_message = "Pilot must use the selected disposable repository name."
  }
  assert {
    condition     = length(module.repositories["pilot"].managed_components.team_grants) == 0 && module.repositories["pilot"].managed_ruleset_id == null
    error_message = "Create stage must grant no team access or activate protection."
  }
  assert {
    condition     = terraform_data.contract.input.repositories.pilot.visibility == "private"
    error_message = "Pilot must start private."
  }
}

run "unknown_stage_is_rejected" {
  command = plan
  variables { inventory_file = "tests/invalid.json" }
  expect_failures = [terraform_data.contract]
}

run "protect_requires_observed_check_contract" {
  command = plan
  variables { inventory_file = "tests/protect-without-checks.json" }
  expect_failures = [terraform_data.contract]
}
