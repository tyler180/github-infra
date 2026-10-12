locals {
  inventory = jsondecode(file("${path.module}/${var.inventory_file}"))
  stages    = ["create", "bootstrap", "verify", "protect", "grant"]
}

# No provider operations: this is a structural guard, not historical proof.
resource "terraform_data" "contract" {
  input = local.inventory
  lifecycle {
    precondition {
      condition     = local.inventory.schema_version == 1 && alltrue([for repo in values(local.inventory.repositories) : contains(local.stages, repo.stage)])
      error_message = "Use inventory schema 1 and a recognized onboarding stage."
    }
    precondition {
      condition = alltrue([for repo in values(local.inventory.repositories) :
        !contains(["protect", "grant"], repo.stage) || try(length(repo.required_checks) > 0, false)
      ])
      error_message = "Protect/grant requires a configured deterministic check contract."
    }
    precondition {
      condition = alltrue([for repo in values(local.inventory.repositories) :
        length(setintersection(toset(keys(try(repo.provisioning_teams, {}))), toset(keys(try(repo.developer_teams, {}))))) == 0
      ])
      error_message = "Provisioning and developer team identities must be disjoint."
    }
  }
}

module "repositories" {
  for_each = local.inventory.repositories
  # github-module v0.1.0-rc.1 (immutable release commit)
  source = "git::https://github.com/tyler180/github-module.git?ref=5bc0ee4d295f5f85fa4b5f25788240b7ae6df8a3"

  name                   = each.value.name
  initialization         = try(each.value.initialization, "basic")
  template               = try(each.value.template, null)
  description            = try(each.value.description, "")
  homepage_url           = try(each.value.homepage_url, "")
  topics                 = try(each.value.topics, [])
  visibility             = try(each.value.visibility, "private")
  merge_methods          = try(each.value.merge_methods, ["squash"])
  delete_branch_on_merge = try(each.value.delete_branch_on_merge, true)
  allow_auto_merge       = try(each.value.allow_auto_merge, false)
  allow_update_branch    = try(each.value.allow_update_branch, true)
  features               = try(each.value.features, {})
  archived               = try(each.value.archived, false)
  default_branch         = try(each.value.default_branch, null)
  rename_default_branch  = try(each.value.rename_default_branch, false)
  actions_policy         = try(each.value.actions_policy, null)
  workflow_permissions   = try(each.value.workflow_permissions, null)
  team_permissions = merge(
    try(each.value.provisioning_teams, {}),
    each.value.stage == "grant" ? try(each.value.developer_teams, {}) : {}
  )
  # Do not require private-repository ruleset entitlement during initial creation.
  # Protection is an explicit later stage after account capability verification.
  repository_ruleset = contains(["protect", "grant"], each.value.stage) ? {
    enforcement     = "active"
    required_checks = try(each.value.required_checks, {})
  } : null
  depends_on = [terraform_data.contract]
}

output "repositories" {
  value = { for key, repo in module.repositories : key => {
    repository_id = repo.repository_id
    full_name     = repo.full_name
    html_url      = repo.html_url
  } }
}
