# dynasty-ff-backend adoption preparation

Observed GitHub settings on October 13, 2026 (America/Denver). This directory holds
a complete candidate inventory that preserves the current root entries and adds
`dynasty_ff_backend`. The active root inventory has not enrolled this repository.
`observed-settings.json` is a read-only snapshot, not an accepted deployment record.

The repository is public, uses `main`, permits merge/squash/rebase, does not delete
merged branches, and has auto-merge and update-branch disabled. Issues and projects
are enabled; discussions and wiki are disabled. Rulesets and team associations were
empty, and the branch-protection endpoint returned "Branch not protected". Actions
and workflow-permission settings are recorded but remain externally owned.
Refresh observations before adoption; collaborator inheritance and installed Apps
still require inspection.

## Review/import sequence

1. Review the candidate entry against refreshed remote settings. It uses `adopt`
   and `initialization: none`, without default-branch management, grants, new
   protections, or source bootstrap.
2. In a separately reviewed adoption operation, import the existing repository
   into the stable map-key address using the **complete** candidate inventory:

   ```sh
   terraform import \
     -var=inventory_file=adoption/dynasty-ff-backend/repositories.json \
     'module.repositories["dynasty_ff_backend"].github_repository.this' \
     dynasty-ff-backend
   terraform plan \
     -var=inventory_file=adoption/dynasty-ff-backend/repositories.json
   ```

   These are proposed state-writing/read-only commands, respectively; neither was
   run. Require no changes to any GitHub resources. Root `terraform_data.contract`
   metadata can reflect the inventory addition; review that bookkeeping separately
   from remote settings. Never accept create/replacement for this repository.
3. Establish the reviewed adopted identity baseline and the live policy integration
   before merging the entry into the active inventory. Normal create onboarding
   currently rejects the adoption stage; do not relabel it `create` to bypass that.

## Existing Terraform deployment

The remote `pr.yml` and `merge.yml` already implement Terraform planning and applying
a PR plan. Their build context includes sibling `dynasty-ff-models` and
`mfl/mfl-mcp` checkouts, whose revisions are carried in the plan artifact. The
Dockerfile and Terraform paths require that multi-repository workspace layout.
These files were compared with the remote blobs before preparing this inventory.

The generic Go + Terraform starter checks out only the caller repository and does
not yet pass this application's required `TF_VAR_*` secret inputs. It is therefore
not a deployment replacement for this repository. Keep its workflows intact during
settings adoption; no additive generic deployment callers are installed here.

A later shared-workflow migration needs typed dependency checkout inputs, exact
dependency revisions preserved across plan/apply, the existing workspace layout,
explicit Terraform secret input plumbing, and a reviewed plan demonstrating the
same resources and image build. It must also preserve the private Go module access
used by application CI. Do not enable both old and new apply routes for the same
state.

Backend: S3 `749rmw-tf-backends`, key `dynasty-ff/backend.tfstate`, region
`us-west-2`, lock files enabled. No backend state or secret values were read.
The existing `dev` environment has no protection rules or branch restriction;
configure the intended approval protections before enabling shared deployment.
