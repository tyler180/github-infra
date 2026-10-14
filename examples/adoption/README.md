# Existing Go + Terraform repositories

Copy only the chosen entry from this example into the complete root inventory.
The values are fixtures, not observations of any actual repository. Replace every
owned repository setting with its current remote value. `stage: adopt` and
`initialization: none` prepare a repository-only import target without bootstrapping
application files, changing protections, adding teams, or managing the default
branch. Do not attach `profile: go`: that bootstrap expects an empty/basic repo.

Inventory remote merge settings, features, topics, visibility, grants, protections,
Actions policy, default branch and installed Apps first. Preserve externally owned
resources. Import is a separate reviewed state operation, for example:

```sh
terraform import 'module.repositories["example_existing_go"].github_repository.this' example-existing-go
terraform plan
```

These commands write state/read live resources and are not run by the starter.
Require a complete no-change plan before adding new defaults or managing subordinate
resources. The ordinary live onboarding policy does **not** accept the new `adopt`
stage or imports: adoption acceptance/identity-baseline integration is a separate
reviewed operation. Do not run the normal deployment workflow for an adoption entry
or relabel it `create` to bypass this boundary. Local mocked plans prove only wiring.
See `github-module/docs/adoption.md` for subordinate import addresses and IDs.

## Add Terraform workflows to an existing repo

`terraform_starter` is opt-in source metadata; it grants no AWS permissions and
does not enable deployment. `workflow_ref` must be a reviewed full shared-workflow
commit SHA. Review that revision's caller contracts before using it.

```sh
python3 scripts/render-terraform-starter.py \
  --inventory examples/adoption/repositories.json \
  --repository example_existing_go \
  --destination /tmp/example-existing-go-terraform
```

The default renderer comes from the sibling local `github-module` checkout; use
`--module-source /path/to/reviewed/checkout` to select it explicitly. Record its
actual source commit and diff in the PR. This is a local render operation, separate
from the published automatic Go bootstrap. Add the generated two workflow files
and `TERRAFORM-STARTER.md` through a PR; reconcile filename conflicts manually.
Existing application CI, Terraform, hooks and CODEOWNERS stay in place. Follow the
generated guide to configure OIDC, state access, repository variables and a protected
environment before enabling plans or manual deploys.

The same `terraform_starter` object can accompany a new `profile: go` inventory
entry. Run the existing Go bootstrap, then render this additive overlay. The Terraform starter job follows Go bootstrap and consumes this metadata through the immutable shared automation release. To render both in one local
starter operation, use `github-module/scripts/render-template.py` with
`--go-version`, `--terraform-version` and `--terraform-workflow-ref`.
