module "dynasty_ff_frontend" {
  source  = "cloudposse/repository/github"
  version = "0.2.1"

  name        = "dynasty-ff-frontend"
  description = "Frontend application for the Dynasty FF platform"

  visibility = "public"

  default_branch = "main"

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  delete_branch_on_merge = true

  allow_merge_commit = false
  allow_rebase_merge = true
  allow_squash_merge = true

  enable_vulnerability_alerts = true
  squash_merge_commit_message = "COMMIT_MESSAGES"

  variables = {
    NEXT_PUBLIC_OIDC_ISSUER    = "https://auth.k8s.749rmw.com/application/o/dynasty-ff/"
    NEXT_PUBLIC_OIDC_CLIENT_ID = "dynasty-ff-frontend"
    NEXT_PUBLIC_API_BASE_URL   = "https://5y8s0du210.execute-api.us-west-2.amazonaws.com"
    NEXT_PUBLIC_LEAGUE_SEASON  = "2026"
    NEXT_PUBLIC_LEAGUE_ID      = "79286"
    NEXT_PUBLIC_FRANCHISE_ID   = "0005"
  }

  topics = [
    "typescript",
    "nextjs",
    "docker",
    "github-actions",
  ]

  rulesets = local.default_repository_rulesets
}