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

run "public_go_profile_is_supported" {
  command = plan
  variables { inventory_file = "tests/go-profile-public.json" }
  assert {
    condition     = terraform_data.contract.input.repositories.example_go_pilot.visibility == "public" && module.repositories["example_go_pilot"].managed_ruleset_id == null
    error_message = "The Go profile must preserve public visibility without enabling protection during creation."
  }
}

run "private_go_profile_is_supported" {
  command = plan
  variables { inventory_file = "examples/go-pilot/repositories.json" }
  assert {
    condition     = terraform_data.contract.input.repositories.example_go_pilot.visibility == "private"
    error_message = "Private Go profile repositories must remain supported."
  }
}

run "internal_go_profile_is_rejected" {
  command = plan
  variables { inventory_file = "tests/go-profile-internal.json" }
  expect_failures = [terraform_data.contract]
}

run "new_go_starter_release_refs_are_supported" {
  command = plan
  variables { inventory_file = "examples/go-pilot/repositories.json" }
  assert {
    condition     = terraform_data.contract.input.repositories.example_go_pilot.bootstrap.source_ref == "v0.1.0-rc.7"
    error_message = "The new Go example must select the published cmd-layout starter."
  }
}
