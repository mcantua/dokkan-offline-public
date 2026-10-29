#!/usr/bin/env python3
"""Two account-free boundary checks; never query a Mac, device, or network."""
import importlib.util
import pathlib
import tempfile
import unittest
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[2]


def module(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


class PublicRepositoryBoundary(unittest.TestCase):
    def test_legacy_publisher_stops_before_network_or_token_handling(self):
        publisher = module('retired_publisher', 'app-installer/cloud-ui/upload-draft-assets.py')
        with patch.object(publisher.urllib.request, 'build_opener', side_effect=AssertionError('network setup forbidden')):
            with self.assertRaisesRegex(ValueError, 'retired'):
                publisher.GitHub(None)

    def test_mac_execution_rejects_the_old_folder_before_tool_actions(self):
        workflow = module('public_device_workflow', 'app-installer/device/device-workflow.py')
        with tempfile.TemporaryDirectory() as temporary:
            workspace = pathlib.Path(temporary) / 'AI-Workspace'
            # Only test-local paths: no real backup, account, save, or key access.
            with patch.object(workflow.sys, 'platform', 'darwin'), patch.object(workflow.shutil, 'which', return_value='/test/tool') as lookup:
                with patch.object(workflow, 'ROOT', workspace / 'claude-chatg'):
                    with self.assertRaisesRegex(workflow.WorkflowError, 'backup is frozen'):
                        workflow.mac_only()
                lookup.assert_not_called()
                with patch.object(workflow, 'ROOT', workspace / 'dokkan-offline-public'):
                    workflow.mac_only()
                self.assertEqual(lookup.call_count, 2)


if __name__ == '__main__':
    unittest.main()
