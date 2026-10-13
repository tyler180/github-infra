# Repository creation examples

These are inventory examples for this consuming root, which calls the published
`github-module`. No Terraform root or sibling module checkout is needed inside
an example directory. Example inventories are not deployed automatically.

| Example | Result | Source bootstrap |
| --- | --- | --- |
| [Basic](basic/repositories.json) | Private repository initialized with a README and `main` | Add your own files in a PR |
| [Go](go-pilot/repositories.json) | Private repository with Go topics, initialized with a README and `main` | Automatic reviewed bootstrap PR for profile=go |
| [GitHub template](from-template/repositories.json) | Private repository copied from a GitHub template | Template supplies the initial files |
| [Empty](empty/repositories.json) | Private repository with no initial commit | Push the first commit before opening a source PR |

## Use an example with the existing deployment workflow

1. Choose a unique repository name. For the template example, replace the template
   owner and repository with an accessible GitHub repository marked as a template.
2. Copy only the chosen entry from the example's `repositories` map into the root
   `repositories.json` map. Preserve all existing entries and their stable keys.
   Do not replace the root inventory with an example file: existing repositories
   would disappear from the configuration.
3. Open a PR in github-infra and run its validation checks. Review and merge it.
4. On main, manually run **Deploy repository pilot**, review the full-root plan,
   and approve production. The workflow uses the root inventory, creates the new
   repository, verifies settings, and conditionally advances the accepted record.
5. For the Go profile, approve the bootstrap job and review its source PR. Other examples follow their manual source instructions.

All examples stay at `create` with no team grants or required checks. The current
live adapter supports create stage only. Adding code does not itself authorize
moving the inventory to bootstrap/protect/grant. A language topic does not install
language tooling or upload source code; the explicit Go profile requests the automatic bootstrap PR.

For offline validation of an individual inventory, run from the github-infra root:

```sh
terraform init -backend=false -input=false -lockfile=readonly
terraform validate
terraform test -filter=tests/examples.tftest.hcl
```

These are mocked plans. Do not apply an example inventory against the production
backend using `-var=inventory_file=...`; merge its entry into the complete root
inventory and use the deployment workflow.

## Existing repositories

Adoption is a separate import and review operation. The creation workflow rejects
implicit adoption, so these examples all use new repository names. Match existing
settings and import resources through a separately reviewed adoption process;
see the module's [adoption example](https://github.com/tyler180/github-module/tree/main/examples/adoption).
