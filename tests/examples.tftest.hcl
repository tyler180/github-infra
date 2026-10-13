mock_provider "github" {}
mock_provider "aws" {}

run "basic" {
  command = plan
  variables { inventory_file = "examples/basic/repositories.json" }
  assert {
    condition     = module.repositories["example_basic"].name == "example-basic-pilot" && module.repositories["example_basic"].managed_ruleset_id == null && length(module.repositories["example_basic"].managed_components.team_grants) == 0
    error_message = "Example must create the selected repository without protection or team grants."
  }
}

run "go_pilot" {
  command = plan
  variables { inventory_file = "examples/go-pilot/repositories.json" }
  assert {
    condition     = module.repositories["example_go_pilot"].name == "example-go-pilot" && module.repositories["example_go_pilot"].managed_ruleset_id == null && length(module.repositories["example_go_pilot"].managed_components.team_grants) == 0
    error_message = "Example must create the selected repository without protection or team grants."
  }
}

run "from_template" {
  command = plan
  variables { inventory_file = "examples/from-template/repositories.json" }
  assert {
    condition     = module.repositories["example_from_template"].name == "example-template-pilot" && module.repositories["example_from_template"].managed_ruleset_id == null && length(module.repositories["example_from_template"].managed_components.team_grants) == 0
    error_message = "Example must create the selected repository without protection or team grants."
  }
}

run "empty" {
  command = plan
  variables { inventory_file = "examples/empty/repositories.json" }
  assert {
    condition     = module.repositories["example_empty"].name == "example-empty-pilot" && module.repositories["example_empty"].managed_ruleset_id == null && length(module.repositories["example_empty"].managed_components.team_grants) == 0
    error_message = "Example must create the selected repository without protection or team grants."
  }
}

