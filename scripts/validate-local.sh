#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# No backend initialization, credentialed plans, or apply.
export GITHUB_TOKEN='' GH_TOKEN='' AWS_ACCESS_KEY_ID='' AWS_SECRET_ACCESS_KEY='' AWS_SESSION_TOKEN=''
export AWS_EC2_METADATA_DISABLED=true
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate -no-color
terraform test -no-color
