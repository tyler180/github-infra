locals {
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
}