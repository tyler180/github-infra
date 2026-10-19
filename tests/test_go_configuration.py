import importlib.util
from pathlib import Path
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/render-go-configuration.py'
spec = importlib.util.spec_from_file_location('render_go_configuration', SCRIPT)
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)


class ConfigurationRendererTests(unittest.TestCase):
    def setUp(self):
        self.inventory = {'repositories': {'app': {'name': 'example-app', 'profile': 'go',
                                                  'bootstrap': {'go_version': '1.26.5'}}}}

    def test_pins_caller_and_tooling_to_same_revision(self):
        content = renderer.render(self.inventory, 'app', 'a' * 40, True, 'explicit-model')
        self.assertIn('repository-go-configure.yml@' + 'a' * 40, content)
        self.assertIn('automation-ref: "' + 'a' * 40 + '"', content)
        self.assertIn('ai: true', content)
        self.assertIn('model: "explicit-model"', content)
        self.assertIn('go-version: "1.26.5"', content)
        self.assertIn('workflow_dispatch:', content)
        self.assertNotIn('pull_request:', content)

    def test_rejects_unpinned_tooling_and_missing_model(self):
        for ref in ('main', 'v2', 'bad\nvalue'):
            with self.subTest(ref=ref), self.assertRaises(ValueError):
                renderer.render(self.inventory, 'app', ref)
        with self.assertRaises(ValueError):
            renderer.render(self.inventory, 'app', 'a' * 40, True)

    def test_requires_go_profile(self):
        self.inventory['repositories']['app']['profile'] = 'generic'
        with self.assertRaises(ValueError):
            renderer.render(self.inventory, 'app', 'a' * 40)


if __name__ == '__main__':
    unittest.main()
