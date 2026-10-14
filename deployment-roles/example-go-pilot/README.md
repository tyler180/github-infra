# example-go-pilot deployment roles

This separately bootstrapped Terraform root manages the application plan/apply OIDC
roles and a CloudWatch-only permissions boundary for its Lambda execution role.
State is separate from repository inventory and application state. It uses the
existing GitHub OIDC provider; it does not modify shared roles or dynasty resources.

Trust is restricted to exact owner/repository IDs and the exact legacy repo subject,
with PR/main contexts for planning and `terraform-production` for apply. Permissions
are scoped to the pilot Lambda, ECR repository, log group, execution role and logs
policy. ECR authorization and listing log groups require service-wide resources.
Only apply can write application state or create resources. Creating the execution
role requires its boundary; attachment and PassRole stay scoped to that role.

Initialize, review a saved plan, then apply it with the bootstrap AWS identity.
The application workflows use the resulting role ARNs through repository variables.
Do not point another application at this backend key or reuse these identities.

The same root manages the `terraform-production` environment, main-only deployment policy and application
Actions variables. GitHub returned HTTP 422 when adding required reviewers because
the account plan does not support them for this private repository. The pilot
therefore uses manual, main-only dispatch without an environment reviewer gate.
Set `require_environment_review=true` when the account supports that rule.
Automatic deployment is not configured.

Use `python3 ../run-pilot.py init`, `plan -out=/tmp/pilot-bootstrap.tfplan`, then
`apply /tmp/pilot-bootstrap.tfplan` from this directory. The wrapper passes an
existing GitHub CLI token to Terraform through the child environment without
printing it. It never reads AWS secret values. CI validates with mocked providers.
