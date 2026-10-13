mock_provider "github" {}
mock_provider "aws" {}

run "go_profile_preserves_settings_ownership" {
  command = plan
  assert {
    condition     = terraform_data.contract.input.repositories.example_go_pilot.profile == "go" && module.repositories["example_go_pilot"].managed_ruleset_id == null
    error_message = "The Go profile must select source bootstrap without activating a ruleset or owning source files."
  }
}

run "unsupported_profile_is_rejected" {
  command = plan
  variables { inventory_file = "tests/unsupported-profile.json" }
  expect_failures = [terraform_data.contract]
}

run "missing_bootstrap_pins_are_rejected" {
  command = plan
  variables { inventory_file = "tests/missing-bootstrap-pins.json" }
  expect_failures = [terraform_data.contract]
}

run "unapproved_source_pin_is_rejected" {
  command = plan
  variables { inventory_file = "tests/unapproved-bootstrap-pin.json" }
  expect_failures = [terraform_data.contract]
}

run "floating_bootstrap_ref_is_rejected" {
  command = plan
  variables { inventory_file = "tests/floating-bootstrap-ref.json" }
  expect_failures = [terraform_data.contract]
}

run "mixed_bootstrap_aliases_are_rejected" {
  command = plan
  variables { inventory_file = "tests/mixed-bootstrap-aliases.json" }
  expect_failures = [terraform_data.contract]
}
