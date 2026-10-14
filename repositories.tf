locals {
  inventory = jsondecode(file("${path.module}/${var.inventory_file}"))
  stages    = ["create", "bootstrap", "verify", "protect", "grant", "adopt"]
  bootstrap_refs = { for key, repo in local.inventory.repositories : key => {
    source   = try(repo.bootstrap.source_ref, repo.bootstrap.source_sha, null)
    workflow = try(repo.bootstrap.workflow_ref, repo.bootstrap.workflow_sha, null)
    hook     = try(repo.bootstrap.hook_ref, repo.bootstrap.hook_sha, null)
  } }
  bootstrap_ref_pattern = "^([0-9a-f]{40}|v(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(-[A-Za-z0-9]+([.-][A-Za-z0-9]+)*)?)$"
}

# No provider operations: this is a structural guard, not historical proof.
resource "terraform_data" "contract" {
  input = local.inventory
  lifecycle {
    precondition {
      condition = alltrue([for repo in values(local.inventory.repositories) :
        try(repo.developer_hooks, null) == null ? true : try(
          repo.stage != "adopt" &&
          toset(keys(repo.developer_hooks)) == toset(["hook_ref", "ai_review"]) &&
          repo.developer_hooks.hook_ref == "v2.3.0-rc.8" &&
        contains(["true", "false"], jsonencode(repo.developer_hooks.ai_review)), false)
      ])
      error_message = "Developer hooks require the approved immutable release, a boolean ai_review, and an accepted non-adoption repository."
    }
    precondition {
      condition = alltrue([for repo in values(local.inventory.repositories) :
        try(repo.terraform_starter, null) == null ? true : try(
          toset(keys(repo.terraform_starter)) == toset(["terraform_version", "workflow_ref", "working_directory"]) &&
          can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", repo.terraform_starter.terraform_version)) &&
          can(regex(local.bootstrap_ref_pattern, repo.terraform_starter.workflow_ref)) &&
        can(regex("^[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)*$", repo.terraform_starter.working_directory)), false)
      ])
      error_message = "Terraform starter requires an explicit patch version, exact immutable workflow release version or full SHA and relative directory without traversal."
    }
    precondition {
      condition = alltrue([for repo in values(local.inventory.repositories) :
        repo.stage != "adopt" ? true : try(
          repo.initialization == "none" && try(repo.profile, null) == null &&
          alltrue([for field in ["description", "homepage_url", "topics", "visibility", "merge_methods", "delete_branch_on_merge", "allow_auto_merge", "allow_update_branch", "archived", "features"] : contains(keys(repo), field)]) &&
          toset(keys(repo.features)) == toset(["issues", "discussions", "wiki", "projects"]) &&
          try(repo.default_branch, null) == null &&
          try(repo.actions_policy, null) == null && try(repo.workflow_permissions, null) == null &&
          length(try(repo.provisioning_teams, {})) == 0 && length(try(repo.developer_teams, {})) == 0,
        false)
      ])
      error_message = "Adoption starts with repository settings only: initialization none, explicit observed settings and all feature flags, no profile, subordinate resources or grants."
    }
    precondition {
      condition = alltrue([for repo in values(local.inventory.repositories) :
        try(repo.profile, null) == null ? true : try(repo.profile == "go" && repo.stage == "create" && repo.initialization == "basic" && repo.visibility == "private" && repo.default_branch == "main", false)
      ])
      error_message = "The Go profile currently requires create stage, basic initialization, private visibility and main."
    }
    precondition {
      condition = alltrue([for key, repo in local.inventory.repositories :
        try(repo.profile, null) == null ? true : try(
          (toset(keys(repo.bootstrap)) == toset(["source_ref", "workflow_ref", "hook_ref", "go_version", "code_owner", "go_module"]) ||
          toset(keys(repo.bootstrap)) == toset(["source_sha", "workflow_sha", "hook_sha", "go_version", "code_owner", "go_module"])) &&
          alltrue([for ref in values(local.bootstrap_refs[key]) : can(regex(local.bootstrap_ref_pattern, ref))]) &&
          (can(regex("^v", local.bootstrap_refs[key].source)) || local.bootstrap_refs[key].source == "6ec3d0adb8de698830e5a40f5bdb1f7cf6372d32") &&
          (can(regex("^v", local.bootstrap_refs[key].workflow)) || local.bootstrap_refs[key].workflow == "0ecbb0fcaea1deb8a8617a51d719b821500e873f") &&
          (can(regex("^v", local.bootstrap_refs[key].hook)) || local.bootstrap_refs[key].hook == "0ecbb0fcaea1deb8a8617a51d719b821500e873f") &&
          (contains(keys(repo.bootstrap), "source_ref") || alltrue([for ref in values(local.bootstrap_refs[key]) : can(regex("^[0-9a-f]{40}$", ref))])) &&
          can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", repo.bootstrap.go_version)) &&
          can(regex("^[A-Za-z0-9_-]+(/[A-Za-z0-9_-]+)?$", repo.bootstrap.code_owner)) &&
        repo.bootstrap.go_module == "github.com/${var.github_owner}/${repo.name}", false)
      ])
      error_message = "Go bootstrap requires exact release refs or approved SHAs (without mixed aliases), an explicit Go patch version, authorized code owner and matching module path."
    }
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
  source   = "git::https://github.com/tyler180/github-module.git?ref=v0.1.0-rc.2"

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
