# Terraform CI onboarding

This caller uses the shared workflows in `tyler180/github-workflows`, pinned to the commit containing this implementation. Start by merging the shared workflow PR, then this caller PR. If you squash-merge the shared PR, update both pinned references to the resulting reviewed main-branch commit.

The existing S3 backend is `749rmw-tf-backends`, key `github/github-infra.tfstate`, region `us-west-2`, with S3 locking. The committed configuration uses the GitHub provider, so AWS credentials alone are insufficient.

## Setup

1. Bootstrap separate AWS OIDC plan/apply roles. Scope them to this state key and its `.tflock` object. Plan: bucket listing, state GetObject, lock GetObject/PutObject/DeleteObject. Apply: those permissions plus state PutObject. Scope bucket listing by prefix. Include KMS permissions if applicable. The committed configuration currently manages GitHub resources, so these roles only need backend access; broaden resource permissions only when adding AWS-managed resources.
2. Set Actions variables `TERRAFORM_PLAN_ROLE_ARN` and `TERRAFORM_APPLY_ROLE_ARN` in this repository. Trust PR and main-branch OIDC subjects on the plan role, and the `terraform-production` environment subject on the apply role. Match the live subject format, including immutable IDs if present.
3. Provide `TERRAFORM_GITHUB_PLAN_TOKEN` with read access to the GitHub resources managed here and `TERRAFORM_GITHUB_APPLY_TOKEN` with management access. Prefer appropriately scoped GitHub App credentials where compatible; the optional shared-workflow secret interface can be extended to generate installation tokens. An ordinary repo `GITHUB_TOKEN` cannot necessarily manage the other repositories in this configuration. Store actual values through GitHub settings, never in Terraform files or workflow YAML.
4. Create GitHub environment `terraform-production`, restrict deployments to `main`, and configure deployment reviewers where supported. Verify approvals pause the apply job. GitHub will create a missing environment without protection, so create and protect it before enabling CI.
5. Set `TERRAFORM_CI_ENABLED=true`. Same-repo PRs now run checks and a preview plan. Missing configuration fails rather than falling back to another credential.
6. Keep `TERRAFORM_AUTO_DEPLOY` unset initially. From Actions, manually run **Terraform** on `main`, review the new plan in the planning job logs, approve the environment, and observe the saved-plan apply. A no-change plan skips apply.
7. Once the first run succeeds and environment protection is verified, optionally set `TERRAFORM_AUTO_DEPLOY=true` to start deployments on main pushes. Approval still gates apply.

The workflow uses Terraform 1.15.8, compatible with the committed backend's minimum 1.15.0. Caller changes do not include local uncommitted Terraform/IAM edits. Those need their own review before inclusion.

## Follow-up

The existing `.gitignore` ignores `.terraform.lock.hcl`. Remove that ignore entry and commit a generated lock file after initializing with your intended provider versions. The deployment bundle preserves the generated lock file across jobs in the meantime.

Make the PR plan job a required branch check after enabling it and confirming it runs successfully. Do not make the credentialed plan a required check for fork contributions unless you provide a separate trusted review process.

Plans and deployment bundles may contain secrets. Both repositories are public; review whether this is appropriate for infrastructure plans and GitHub metadata. Do not enable public planning for sensitive infrastructure.
