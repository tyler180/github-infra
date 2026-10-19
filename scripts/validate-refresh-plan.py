#!/usr/bin/env python3
"""Validate state-only reconciliation and print a bounded review summary."""
import json
import re
import sys


REPOSITORY = re.compile(r'^module\.repositories\["([^"\\]+)"\]\.github_repository\.this$')
BRANCH = re.compile(r'^module\.repositories\["([^"\\]+)"\]\.github_branch_default\.this\["managed"\]$')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(plan, inventory):
    require(plan.get('format_version') == '1.2' and plan.get('complete') is True
            and plan.get('errored') is False, 'A complete, error-free plan is required.')
    require(not plan.get('deferred_changes'), 'Deferred changes are unsupported.')
    require(all(r.get('change', {}).get('actions') == ['no-op']
                and not r.get('change', {}).get('importing')
                for r in plan.get('resource_changes', [])),
            'State reconciliation cannot create, update, delete, or import resources.')
    repos = inventory['repositories']
    summary = ['## Repository state reconciliation', '',
               'This saved plan updates Terraform state only. Repository creation and bootstrap are skipped.', '']
    for resource in plan.get('resource_drift', []):
        address = resource['address']
        change = resource['change']
        require(change.get('actions') == ['update'], 'Deleted or replaced resources require separate recovery.')
        require(not change.get('importing'), 'Imports require separate adoption.')
        require(resource.get('provider_name') == 'registry.terraform.io/integrations/github',
                'Unexpected drift provider.')
        match = REPOSITORY.fullmatch(address) or BRANCH.fullmatch(address)
        require(match is not None and match[1] in repos, 'Drift must belong to a configured repository.')
        before, after = change['before'], change['after']
        require(before.get('id') == after.get('id'), 'Resource identity changed.')
        if REPOSITORY.fullmatch(address):
            repo = repos[match[1]]
            require(before.get('repo_id') == after.get('repo_id') and after.get('repo_id') is not None,
                    'Repository identity changed or is missing.')
            require(after.get('name') == repo['name'], 'Observed name differs from inventory.')
            require(after.get('visibility') == repo.get('visibility', 'private'),
                    'Observed visibility differs from inventory; review the intended visibility first.')
            require(after.get('archived') is False, 'Archived repositories require separate review.')
        else:
            require(after.get('branch') == repos[match[1]].get('default_branch'),
                    'Observed default branch differs from inventory.')
        fields = sorted(k for k in before.keys() | after.keys() if before.get(k) != after.get(k))
        # JSON in inline code prevents repository-controlled Markdown from becoming markup.
        summary.append('- `' + json.dumps(address).replace('`', '\\u0060') + '`: ' +
                       ', '.join('`' + json.dumps(k).replace('`', '\\u0060') + '`' for k in fields))
    if not plan.get('resource_drift'):
        summary.append('No resource drift was observed.')
    summary.extend(['', 'Review the full before/after values in the Terraform plan job log before approving production.'])
    return '\n'.join(summary)


if __name__ == '__main__':
    try:
        with open(sys.argv[1]) as source:
            plan = json.load(source)
        with open(sys.argv[2]) as source:
            inventory = json.load(source)
        print(validate(plan, inventory))
    except (ValueError, KeyError, TypeError, IndexError) as error:
        sys.exit('Refresh plan rejected: ' + str(error))
