# Create a Go repository

Use the inventory entry in [repositories.json](repositories.json), choose a unique
name, and set its matching bootstrap.go_module and authorized bootstrap.code_owner.
Merge the entry into the full root inventory through a reviewed PR. Run **Deploy
repository pilot** on main: successful creation/acceptance is followed by the
production-approved Go bootstrap job, which opens a source PR and verifies CI.
Review and merge that source PR. A retry reuses it; existing application files
are never overwritten.

For an already created repository such as example-go-pilot, run **Bootstrap
existing repository profiles** on main. It opens the same bootstrap PR without
Terraform apply. The production environment requires TF_GITHUB_BOOTSTRAP_TOKEN
with Contents, Workflows and Pull requests write and Administration and Actions read.

The profile pins exact reviewed starter/workflow/hook revisions. Other language
profiles are not supported yet. Leave stage=create until later live stage
authorization exists. Developers install pre-commit and Gitleaks 8.30.1 and run
`pre-commit install` to activate the generated local hooks.

Bootstrap version fields are `source_ref`, `workflow_ref` and `hook_ref`. Use exact
immutable published release versions or approved full commit SHAs. Legacy `_sha`
fields still accept full SHAs, but must not be mixed with `_ref` aliases. Runtime
resolution verifies release immutability, unwraps annotated tags and requires the
resolved commit to match this automation version's approved sources. Terraform
validates syntax offline; it cannot attest release immutability.

The current workflow/hook refs use `v2.2.0-rc.1`. The approved source commit has no
published release, so source_ref retains its SHA until that revision receives an
immutable release. No release is created by configuration validation. Provenance
records requested refs and resolved commits. Changing a SHA to an equivalent
release preserves the existing bootstrap fingerprint and developer files.
