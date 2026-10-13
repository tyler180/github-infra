# Create a Go repository

Start with [repositories.json](repositories.json) and follow the
[parent instructions](../README.md) to merge its entry into the root inventory
and create the repository through github-infra's deployment workflow.

This entry provisions the repository, not a Go application. After creation,
prepare the Go starter from the github-module example containing the complete
starter ([Go example PR #1](https://github.com/tyler180/github-module/pull/1)
must be merged first):

```sh
python3 scripts/render-template.py \
  --destination /tmp/go-pilot-starter \
  --code-owner YOUR_GITHUB_OWNER \
  --workflow-ref v2.2.0-rc.1 \
  --hook-ref v2.2.0-rc.1 \
  --go-version 1.26.5 \
  --go-module github.com/YOUR_GITHUB_OWNER/example-go-pilot
```

Run that renderer from a github-module checkout, then clone the newly created
repository into a different directory. Create a bootstrap branch, copy the
contents of `/tmp/go-pilot-starter/` (including hidden files) into the clone,
run `bash scripts/validate.sh`, and submit a PR. The renderer excludes Terraform
provisioning files. Merge after Go CI passes and retain the bootstrap PR as
provenance. Go source, CI and hooks live in the created repository; repository
intent and state stay in github-infra.

The shared workflow and hook version is the published immutable
`v2.2.0-rc.1`. Confirm the actual aggregate check name on the bootstrap PR before
planning later branch protection. Leave the inventory at `create` until later
stage authorization is implemented.
