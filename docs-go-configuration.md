# Configure Go application entry points

After a Go repository has its application source, use the shared Go configuration
workflow to discover and validate its executable and open a configuration PR.
This is a separate, manual source operation; it does not run Terraform or alter
accepted deployment records. New Go starters rendered from the updated module
use `cmd/<module-name>/main.go` and a tracked `.go-main.mk`.

First publish the reviewed `github-workflows` changes containing
`repository-go-configure.yml` and `scripts/configure-go.py`. Then stage a caller
from the current inventory using that release's actual full SHA or immutable
release tag:

```sh
python3 scripts/render-go-configuration.py --repository nl2tf \
  --automation-ref FULL_REVIEWED_WORKFLOWS_SHA \
  --output /tmp/configure-nl2tf.yml
```

For ambiguous projects, append `--ai --model YOUR_MODEL`; supply the
`OPENAI_API_KEY` Actions secret. One executable needs no AI key. Review the
rendered caller and commit it under `.github/workflows/`, then run it manually
from the default branch. The existing `TF_GITHUB_BOOTSTRAP_TOKEN` must have
contents/PR write access to the target repo. Review and merge the resulting PR
normally; the workflow never merges it automatically.

The renderer takes the target name and Go version from the selected Go inventory
entry. It refuses floating refs and existing output files. It does not change
inventory source/workflow pins: upgrade those separately after publishing the
updated `github-module` starter and `github-workflows` validation releases.

For a local checkout, run the shared tool directly before publishing:

```sh
python3 -I ../github-workflows/scripts/configure-go.py --repository ../nl2tf
python3 -I ../github-workflows/scripts/configure-go.py --repository ../nl2tf --write
```

See `github-workflows/GO-CONFIGURATION.md` for the selection, build and credential
boundaries. Libraries keep using generic CI without a main package. Workspaces,
custom Makefiles and custom validation scripts require explicit reconciliation.
