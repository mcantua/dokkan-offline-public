"""TEST-ONLY mocked GitHub API; never contacts a network or uses credentials."""
import copy
import importlib.util
from pathlib import Path
import unittest

SPEC = importlib.util.spec_from_file_location('retention', Path(__file__).parents[1] / 'prune-artifacts.py')
retention = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(retention)
C, K, D = retention.CANDIDATE, retention.KIT, retention.DIAGNOSTIC


def artifact(identity, name, run):
    return {'id': identity, 'name': name, 'expired': False, 'workflow_run': {'id': run}}


class MockAPI:
    def __init__(self):
        self.items = [artifact(100, C, 10), artifact(101, K, 10), artifact(102, D, 10),
                      artifact(90, C, 9), artifact(91, K, 9), artifact(92, D, 9),
                      artifact(80, C, 8), artifact(81, K, 8),
                      artifact(110, C, 11), artifact(111, K, 11),
                      artifact(93, 'unrelated-artifact', 9)]
        self.runs = {identity: {'id': identity, 'workflow_id': 55 if identity != 8 else 99,
                               'run_number': identity} for identity in (8, 9, 10, 11)}
        self.deleted = []
        self.reads = []

    def get(self, path):
        self.reads.append(path)
        if path.startswith('/runs/'):
            return copy.deepcopy(self.runs[int(path.rsplit('/', 1)[1])])
        if path.startswith('/artifacts?'):
            return {'artifacts': copy.deepcopy(self.items)}
        return copy.deepcopy(next(item for item in self.items if item['id'] == int(path.rsplit('/', 1)[1])))

    def delete(self, identity):
        self.deleted.append(identity)


class RetentionTests(unittest.TestCase):
    def test_complete_pair_and_diagnostics_are_workflow_scoped(self):
        api = MockAPI()
        self.assertEqual(retention.prune(api, '10', {C: '100', K: '101'}), 2)
        self.assertEqual(api.deleted, [91, 90])
        self.assertEqual(api.reads.count('/runs/9'), 1)
        self.assertEqual(api.reads.count('/runs/8'), 1)
        self.assertEqual(api.reads.count('/runs/11'), 1)
        api = MockAPI()
        def fail_kit(identity):
            self.assertEqual(identity, 91)
            raise RuntimeError('TEST-ONLY GitHub failure')
        api.delete = fail_kit
        with self.assertRaises(RuntimeError):
            retention.prune(api, 10, {C: '100', K: '101'})
        self.assertEqual(api.deleted, [])
        api = MockAPI()
        retention.prune(api, 10, {D: '102'})
        self.assertEqual(api.deleted, [92])
        api = MockAPI()
        retention.prune(api, 10, {C: '', K: ''})
        self.assertEqual(api.deleted, [])

    def test_incomplete_pair_preserves_previous_and_invalid_ids_never_delete(self):
        for provided, expected in (({C: '100', K: ''}, [100]), ({C: '', K: '101'}, [101])):
            with self.subTest(provided=provided):
                api = MockAPI()
                retention.prune(api, 10, provided)
                self.assertEqual(api.deleted, expected)
                self.assertFalse(any('/artifacts?' in path for path in api.reads))
        for provided in ({C: '90', K: '101'}, {C: '100', K: '102'}, {C: '100', K: '81'},
                         {C: '100', K: 'not-an-id'}, {'other-name': '100'}):
            with self.subTest(provided=provided):
                api = MockAPI()
                with self.assertRaises(ValueError):
                    retention.prune(api, 10, provided)
                self.assertEqual(api.deleted, [])
        api = MockAPI()
        api.items[1]['expired'] = True
        with self.assertRaises(ValueError):
            retention.prune(api, 10, {C: '100', K: '101'})
        self.assertEqual(api.deleted, [])


if __name__ == '__main__':
    unittest.main()
