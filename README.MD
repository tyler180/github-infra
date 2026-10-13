# GitHub infrastructure

This is the consuming Terraform root for tyler180/github-module. Repository
intent lives in repositories.json; shared automation lives in github-workflows.
The first repository is github-module-pilot, private and at create stage. No
repository has been created by this local configuration work.

## Local development and validation

repositories.tf calls git::https://github.com/tyler180/github-module.git at immutable
release v0.1.0-rc.2. Local validation and CI
use that same immutable source; no sibling checkout is required. Review and update
the module ref when publishing a new version. Uncommitted module edits are not
included in this pin.

Run bash scripts/validate-local.sh. It initializes with backend=false, validates,
and runs provider-mocked plan-only tests without infrastructure credentials.
Commit .terraform.lock.hcl; cache directories, state, and plans remain ignored.
The existing AWS provider is preserved, although this root currently manages only
GitHub repositories. S3 backend access does not itself need an AWS provider resource.

## Manual pilot deployment

.github/workflows/deploy-repositories.yml calls the create-stage shared workflow
at immutable release v2.1.0-rc.4. It must be reviewed
and published on main before manual dispatch. Planning reads the S3 backend and
uses TF_GITHUB_PLAN_TOKEN. Apply requires production approval and uses the
production TF_GITHUB_APPLY_TOKEN. It then verifies GitHub settings and advances
accepted.json using the separate record-writer role and a conditional S3 write.

The backend was cleaned up by the owner. The live plan still rejects destruction,
replacement and implicit adoption. Failed/partial applies do not advance the
accepted record and need explicit recovery. Do not simply delete the record.

This adapter supports create stage only. Personal accounts do not support team
grants; protection and later onboarding transitions need additional live evidence
and integration. Production approval does not override those restrictions.

The separate verify-deployment-access workflow tests OIDC and S3 permissions,
retaining a small access-test probe. It performs no Terraform apply. Access-test
success does not establish permission to create repositories with the apply PAT.

## Version names

| Component | Release | Resolved commit |
| --- | --- | --- |
| Module | [v0.1.0-rc.2](https://github.com/tyler180/github-module/releases/tag/v0.1.0-rc.2) | `5bc0ee4d295f5f85fa4b5f25788240b7ae6df8a3` |
| Workflows and trusted policy | [v2.1.0-rc.4](https://github.com/tyler180/github-workflows/releases/tag/v2.1.0-rc.4) | `c4dd516bd13a7e6948322fafddcc6682c45f953c` |

Configuration uses these actual version tags. GitHub marks both releases immutable,
so published tags cannot be moved. The policy runner resolves the workflow release
to its commit and records both values in deployment receipts. For upgrades, review
the release and update the workflow and trusted-policy versions together. These
releases remain candidates until the live pilot completes.

## Provider checksums across platforms

The committed provider lock file includes verified package hashes for both
linux_amd64 (Actions) and darwin_arm64 (local development). Validation and
deployment initialize with -lockfile=readonly so CI cannot silently repair an
incomplete lock file. When intentionally updating providers, regenerate the
platform hashes with:

```sh
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
```

Review and commit the resulting lock-file change before running deployment.

## Recover the completed pilot apply

Run Recover pilot accepted record on main and approve production. This one-time
workflow verifies successful apply run 38320705436, repository ID 1416221483, the
original source and persisted state, and actual GitHub settings before creating
the missing initial accepted record. It runs no Terraform commands and does not
overwrite an existing accepted record. Run it before another pilot deployment;
ordinary deployment intentionally rejects adoption of an unrecorded repository.

## Repository creation examples

See [examples](examples/README.md) for basic, Go, GitHub-template, and empty
repository inventory entries and instructions for using this root and its
deployment workflow. Example entries are not part of the deployed inventory.
