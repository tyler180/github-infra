#!/usr/bin/env python3
"""Stage a pinned Go configuration workflow from inventory; never publish it."""
import argparse
import json
from pathlib import Path
import re


def render(inventory, key, ref, ai=False, model=''):
    if not re.fullmatch(r'[0-9a-f]{40}|v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?', ref):
        raise ValueError('Use a full reviewed github-workflows SHA or immutable release')
    entry = inventory['repositories'][key]
    if entry.get('profile') != 'go':
        raise ValueError('Select a Go inventory entry')
    name = entry['name']
    version = entry['bootstrap']['go_version']
    if not re.fullmatch(r'[A-Za-z0-9_-][A-Za-z0-9_.-]*', name):
        raise ValueError('Invalid repository name')
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version):
        raise ValueError('Pin Go patch version')
    if ai and not model:
        raise ValueError('AI requires an explicit model')
    quote = json.dumps
    return f'''# Generated from repositories.json; review before committing.
name: Configure Go application ({name})
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  configure:
    uses: tyler180/github-workflows/.github/workflows/repository-go-configure.yml@{ref}
    with:
      repository-name: {quote(name)}
      automation-ref: {quote(ref)}
      go-version: {quote(version)}
      ai: {str(ai).lower()}
      model: {quote(model)}
    secrets:
      TF_GITHUB_BOOTSTRAP_TOKEN: ${{{{ secrets.TF_GITHUB_BOOTSTRAP_TOKEN }}}}
      OPENAI_API_KEY: ${{{{ secrets.OPENAI_API_KEY }}}}
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inventory', type=Path, default=Path(__file__).resolve().parents[1] / 'repositories.json')
    parser.add_argument('--repository', required=True, help='inventory key')
    parser.add_argument('--automation-ref', required=True)
    parser.add_argument('--ai', action='store_true')
    parser.add_argument('--model', default='')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        content = render(json.loads(args.inventory.read_text()), args.repository,
                         args.automation_ref, args.ai, args.model)
        # Exclusive creation also refuses dangling symlinks and existing files.
        with args.output.open('x') as output:
            output.write(content)
    except (OSError, ValueError, KeyError) as error:
        parser.error(str(error))


if __name__ == '__main__':
    main()
