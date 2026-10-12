locals {
  name            = data.context_label.this.rendered
  deployment_name = "${local.name}-deploy"

  github_username = "tyler180@15354990"

  github_actions_repositories = {
    dynasty-ff-backend = {
      repository_id = "1330281987"
    }

    dynasty-ff-models = {
      repository_id = "1331226573"
    }
  }

  deployment_accounts = {
    dev  = "138013422358"
    prod = "168076893860"
  }

  deployment_role_arns = [
    for account_id in values(local.deployment_accounts) :
    "arn:aws:iam::${account_id}:role/${local.deployment_name}"
  ]

  default_repository_rulesets = {
    main = {
      name        = "main"
      target      = "branch"
      enforcement = "active"

      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"]
          exclude = []
        }
      }

      rules = {
        deletion         = true
        non_fast_forward = true

        pull_request = {
          required_approving_review_count   = 0
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = false
          require_last_push_approval        = false
          required_review_thread_resolution = true
        }
      }
    }
  }

  tags = data.context_tags.this.tags
}