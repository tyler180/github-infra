# Configure Go application entry points

After a Go repository has its application source, use the shared Go configuration
workflow to discover and validate its executable and open a configuration PR.
This is a separate, manual source operation; it does not run Terraform or alter
accepted deployment records. New Go starters rendered from the updated module
use `cmd/<module-name>/main.go` and a tracked `.go-main.mk`.

Published immutable releases are `github-module@v0.1.0-rc.7` for new source,
`github-workflows@v2.3.0-rc.10` for Go validation, and
`github-workflows@v2.3.0-rc.11` for configuration PRs and bootstrap approvals.
The committed callers cover every Go inventory entry:

- **Configure Go application (nl2tf)**
- **Configure Go application (example-go-pilot)**

Run the applicable caller manually from main after the application's intended
source has reached its default branch. The job uses the protected `production`
environment. To stage a caller for another inventory entry:

```sh
python3 scripts/render-go-configuration.py --repository nl2tf \
  --automation-ref v2.3.0-rc.11 \
  --output /tmp/configure-nl2tf.yml
```

For ambiguous projects, append `--ai --model YOUR_MODEL`; supply the
`OPENAI_API_KEY` Actions secret. One executable needs no AI key. Review the
rendered caller and commit it under `.github/workflows/`, then run it manually
from the default branch. The existing `TF_GITHUB_BOOTSTRAP_TOKEN` must have
contents/PR write access to the target repo. Review and merge the resulting PR
normally; the workflow never merges it automatically.

The renderer takes the target name and Go version from the selected Go inventory
entry. It refuses floating refs and existing output files. Existing inventory bootstrap pins stay unchanged because their provenance is
bound to the original generated source. The new-repo example uses the updated
source and validation releases. Do not rerun bootstrap as a source upgrade.

For a local checkout, run the shared tool directly before publishing:

```sh
python3 -I ../github-workflows/scripts/configure-go.py --repository ../nl2tf
python3 -I ../github-workflows/scripts/configure-go.py --repository ../nl2tf --write
```

See `github-workflows/GO-CONFIGURATION.md` for the selection, build and credential
boundaries. Libraries keep using generic CI without a main package. Workspaces,
custom Makefiles and custom validation scripts require explicit reconciliation.
