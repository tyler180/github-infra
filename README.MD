# GitHub infrastructure

This is the consuming Terraform root for tyler180/github-module. Repository
intent lives in repositories.json; shared automation lives in github-workflows.
The first repository is github-module-pilot, private and at create stage. No
repository has been created by this local configuration work.

## Local development and validation

repositories.tf calls git::https://github.com/tyler180/github-module.git at verified
published commit 5bc0ee4d295f5f85fa4b5f25788240b7ae6df8a3. Local validation and CI
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
at immutable commit f5bf6fc59f8954d357e3081ae888ce03a1cec63f. It must be reviewed
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

| Component | Release | Pinned commit |
| --- | --- | --- |
| Module | [v0.1.0-rc.1](https://github.com/tyler180/github-module/releases/tag/v0.1.0-rc.1) | `5bc0ee4d295f5f85fa4b5f25788240b7ae6df8a3` |
| Workflows and trusted policy | [v2.1.0-rc.1](https://github.com/tyler180/github-workflows/releases/tag/v2.1.0-rc.1) | `f5bf6fc59f8954d357e3081ae888ce03a1cec63f` |

Configuration comments identify the readable version; execution remains pinned
to its commit. For upgrades, review the release, update the SHA and label together,
and keep the workflow and trusted-policy revisions identical. These releases are
candidates until the live pilot completes.
