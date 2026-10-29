#!/usr/bin/env python3
"""Two targeted cloud-only mocked checks; never inspects Tin's Mac or accounts."""
import contextlib,importlib.util,io,os,pathlib,tempfile,unittest
from unittest.mock import patch
HERE=pathlib.Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('wizard',HERE/'setup-wizard.py')
wizard=importlib.util.module_from_spec(spec);spec.loader.exec_module(wizard)
workflow=wizard.workflow

class LocalPreflight(unittest.TestCase):
    def test_complete_xcode_real_sdk_and_tool_checks_precede_device_and_account_steps(self):
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='preflight-fixture-',dir=base) as temporary:
            developer=pathlib.Path(temporary)/'Xcode.app/Contents/Developer';developer.mkdir(parents=True)
            calls=[]
            def command(argv,*,step):
                calls.append(argv)
                return {('xcode-select','--print-path'):str(developer).encode(),('xcodebuild','-version'):b'Xcode 27.1\nBuild version FIXTURE',('xcrun','--sdk','iphoneos','--show-sdk-version'):b'27.1'}.get(tuple(argv),b'/fixture/tool')
            with patch.object(workflow.sys,'version_info',(3,9,0)),patch.dict(os.environ,{},clear=True),patch.object(workflow,'command',side_effect=command),patch.object(workflow.shutil,'which',return_value='/fixture/tool'):
                self.assertTrue(workflow.local_preflight()['preflight_passed'])
                self.assertFalse(any('security' in argv or 'list' in argv for argv in calls))
            out=io.StringIO()
            with patch.object(workflow,'mac_only'),patch.object(workflow,'private_directory'),patch.object(workflow,'bootstrap_kit',return_value={'fixture':True}),patch.object(workflow,'local_preflight',side_effect=workflow.WorkflowError('SDK 27.1 preflight fixture blocked')),patch.object(wizard,'choose_device',side_effect=AssertionError('device discovery before passing preflight')),patch.object(wizard,'teams_with_signing_keys',side_effect=AssertionError('account discovery before passing preflight')),contextlib.redirect_stderr(out):
                self.assertEqual(wizard.main(['--execute']),1)
            self.assertIn('SDK 27.1',out.getvalue())

    def test_missing_cli_only_old_sdk_and_first_launch_fail_without_changes_or_downloads(self):
        with patch.object(workflow.sys,'version_info',(3,8,20)),patch.object(workflow,'command',side_effect=AssertionError('unsupported Python must stop before tool use')):
            with self.assertRaisesRegex(workflow.WorkflowError,'Python 3.9'):workflow.local_preflight()
            out=io.StringIO()
            with patch.object(workflow,'mac_only',side_effect=AssertionError('unsupported Python must stop before local inspection')),contextlib.redirect_stderr(out):
                self.assertEqual(wizard.main(['--execute']),1)
            self.assertIn('already approved dependency setup scope',out.getvalue())
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='preflight-negative-',dir=base) as temporary:
            developer=pathlib.Path(temporary)/'Xcode.app/Contents/Developer';developer.mkdir(parents=True)
            for mode,expected in [('cli','Command Line Tools'),('missing','full Xcode'),('old','27.1'),('license','license')]:
                calls=[]
                def command(argv,*,step):
                    calls.append(argv)
                    if argv==['xcode-select','--print-path']:return str(developer if mode not in {'cli','missing'} else pathlib.Path(temporary)/('CommandLineTools' if mode=='cli' else 'Missing.app/Contents/Developer')).encode()
                    if argv==['xcodebuild','-version']:
                        if mode=='license':raise workflow.WorkflowError('Xcode first-launch fixture')
                        return b'Xcode 26.4\nBuild version FIXTURE'
                    if argv==['xcrun','--sdk','iphoneos','--show-sdk-version']:return b'26.4'
                    raise AssertionError('Unexpected operation after preflight failure')
                with patch.dict(os.environ,{},clear=True),patch.object(workflow,'command',side_effect=command),patch.object(workflow.shutil,'which',return_value='/fixture/tool'):
                    with self.assertRaisesRegex(workflow.WorkflowError,expected) as caught:workflow.local_preflight()
                    if mode=='license':
                        self.assertIn('complete its normal first-launch/license screen',str(caught.exception))
                        self.assertNotIn('approval before accepting',str(caught.exception))
                self.assertTrue(all(argv in [['xcode-select','--print-path'],['xcodebuild','-version'],['xcrun','--sdk','iphoneos','--show-sdk-version']] for argv in calls))

if __name__=='__main__':unittest.main()
