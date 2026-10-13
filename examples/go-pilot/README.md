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
with Contents, Workflows and Pull requests write and Administration read.

The profile pins exact reviewed starter/workflow/hook revisions. Other language
profiles are not supported yet. Leave stage=create until later live stage
authorization exists. Developers install pre-commit and Gitleaks 8.30.1 and run
`pre-commit install` to activate the generated local hooks.
