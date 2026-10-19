import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('refresh', Path(__file__).resolve().parents[1] / 'scripts/validate-refresh-plan.py')
refresh = importlib.util.module_from_spec(spec)
spec.loader.exec_module(refresh)


class RefreshPlanTests(unittest.TestCase):
    def setUp(self):
        self.inventory = {'repositories': {'pilot': {'name': 'pilot', 'visibility': 'public'}}}
        self.before = {'id': 'pilot', 'repo_id': 123, 'name': 'pilot', 'visibility': 'private', 'archived': False}
        self.after = dict(self.before, visibility='public')
        self.plan = {'format_version': '1.2', 'complete': True, 'errored': False,
                     'resource_changes': [], 'resource_drift': [{
                         'address': 'module.repositories["pilot"].github_repository.this',
                         'provider_name': 'registry.terraform.io/integrations/github',
                         'change': {'actions': ['update'], 'before': self.before, 'after': self.after}}]}

    def test_accepts_intended_public_visibility_and_scanning(self):
        self.after['security_and_analysis'] = [{'secret_scanning': [{'status': 'enabled'}]}]
        self.assertIn('security_and_analysis', refresh.validate(self.plan, self.inventory))

    def test_rejects_resource_mutations(self):
        for action in ['create', 'update', 'delete']:
            with self.subTest(action=action), self.assertRaises(ValueError):
                plan = copy.deepcopy(self.plan)
                plan['resource_changes'] = [{'change': {'actions': [action]}}]
                refresh.validate(plan, self.inventory)

    def test_rejects_deletion(self):
        self.plan['resource_drift'][0]['change']['actions'] = ['delete']
        with self.assertRaises(ValueError):
            refresh.validate(self.plan, self.inventory)

    def test_rejects_visibility_conflicting_with_inventory(self):
        self.inventory['repositories']['pilot']['visibility'] = 'private'
        with self.assertRaises(ValueError):
            refresh.validate(self.plan, self.inventory)

    def test_rejects_identity_change(self):
        self.after['repo_id'] = 456
        with self.assertRaises(ValueError):
            refresh.validate(self.plan, self.inventory)

    def test_rejects_unknown_owner(self):
        self.inventory['repositories'] = {}
        with self.assertRaises(ValueError):
            refresh.validate(self.plan, self.inventory)

    def test_rejects_import_even_with_noop_action(self):
        self.plan['resource_changes'] = [{'change': {'actions': ['no-op'], 'importing': {'id': 'pilot'}}}]
        with self.assertRaises(ValueError):
            refresh.validate(self.plan, self.inventory)

    def test_rejects_incomplete_plan(self):
        self.plan['complete'] = False
        with self.assertRaises(ValueError):
            refresh.validate(self.plan, self.inventory)

    def test_no_drift_is_safe(self):
        self.plan['resource_drift'] = []
        self.assertIn('No resource drift', refresh.validate(self.plan, self.inventory))


if __name__ == '__main__':
    unittest.main()
