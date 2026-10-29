#!/usr/bin/env python3
"""Two grouped regressions using TEST-ONLY files and mocked OS/device operations."""
import argparse
import copy
import importlib.util
import json
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('device_receipt_workflow',Path(__file__).with_name('device-workflow.py'))
workflow=importlib.util.module_from_spec(spec);spec.loader.exec_module(workflow)

SOURCE={'source_commit':'a'*40,'source_tree_sha256':'b'*64,'bootstrap_tool_commit':'c'*40}
DEVICE='00000000-0000000000000000'  # TEST-ONLY format fixture, never a queried phone.


class DeviceReceiptTests(unittest.TestCase):
    def test_stable_canonical_identity_and_checked_source_receipts(self):
        args=argparse.Namespace(team='TESTTEAM01',bundle_id=workflow.BUNDLE_PREFIX,variant='iphone',device='TEST-ONLY-ALIAS')
        self.assertEqual(workflow.team_and_bundle(args)[1],workflow.BUNDLE_PREFIX)
        args.bundle_id=workflow.BUNDLE_PREFIX+'.ttestteam01'
        self.assertEqual(workflow.team_and_bundle(args)[1],args.bundle_id)
        args.bundle_id='org.other.app'
        with self.assertRaises(workflow.WorkflowError):workflow.team_and_bundle(args)
        args.bundle_id=workflow.BUNDLE_PREFIX
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='receipt-fixture-',dir=base) as temporary:
            private=Path(temporary);app=private/'DerivedData/Build/Products/Release-iphoneos/AppInstaller.app';app.mkdir(parents=True)
            info={'CFBundleIdentifier':args.bundle_id,'BGTaskSchedulerPermittedIdentifiers':[args.bundle_id+'.refresh'],
                  'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False},'CFBundleExecutable':'AppInstaller',
                  'CFBundleShortVersionString':'1.0','CFBundleVersion':'1','DTSDKName':'iphoneos27.1'}
            (app/'Info.plist').write_bytes(plistlib.dumps(info));(app/'AppInstaller').write_bytes(b'TEST-ONLY binary bytes')
            metadata={**SOURCE,'variant':'iphone','unsigned':False}
            (app/'BuildMetadata.json').write_text(json.dumps(metadata))
            def fake_command(argv,*,step):
                if argv[0]=='codesign' and '--entitlements' in argv:return plistlib.dumps({})
                if argv[0]=='security':return plistlib.dumps({})
                if 'vtool' in argv:return b'platform IOS\nsdk 27.1\n'
                if '--show-sdk-version' in argv:return b'27.1\n'
                return b''
            details={'result':{'hardwareProperties':{'udid':DEVICE}}}
            with patch.object(workflow,'PRIVATE',private),patch.object(workflow,'bootstrap_kit',return_value=SOURCE),patch.object(workflow,'command',side_effect=fake_command),patch.object(workflow,'device_json',return_value=details),patch.object(workflow,'verify_profile',return_value={}),patch.object(workflow,'verify_signing_certificate',return_value={}):
                result=workflow.verify_app(args)
                for key,value in SOURCE.items():self.assertEqual(result[key],value)
                self.assertTrue(result['source_identity_matches_reviewed_kit'])
                self.assertNotIn(DEVICE,json.dumps(result));self.assertNotIn(args.team,json.dumps(result))
                for key in SOURCE:
                    altered={**metadata,key:'d'*len(SOURCE[key])}
                    (app/'BuildMetadata.json').write_text(json.dumps(altered))
                    with self.assertRaises(workflow.WorkflowError):workflow.verify_app(args)
                (app/'BuildMetadata.json').write_text(json.dumps(metadata))

    def test_install_and_launch_receipts_bind_actual_device_and_build_and_keep_failures(self):
        args=argparse.Namespace(team='TESTTEAM01',bundle_id=workflow.BUNDLE_PREFIX,variant='iphone',device='TEST-ONLY-ALIAS')
        state={'device':DEVICE,'fail':None}
        verified={**SOURCE,'local_binary_sha256':'e'*64,'development_signature':True}
        def diagnose(_):args.physical_udid=state['device'];return {'device_install_attempted':False,'variant':args.variant}
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='receipt-lifecycle-fixture-',dir=base) as temporary:
            private=Path(temporary);calls=[]
            def fake_device(_, *pieces):
                receipt=json.loads((private/'device-evidence.json').read_text())
                calls.append(pieces)
                if 'install' in pieces:self.assertEqual(receipt['install_outcome'],'in_progress')
                if 'launch' in pieces:self.assertEqual(receipt['launch_outcome'],'in_progress')
                for key,value in SOURCE.items():self.assertEqual(receipt[key],value)
                if state['fail'] in pieces:raise workflow.WorkflowError('TEST-ONLY device command failure')
                return {'result':{}}
            with patch.object(workflow,'PRIVATE',private),patch.object(workflow,'diagnose',side_effect=diagnose),patch.object(workflow,'verify_app',side_effect=lambda _:copy.deepcopy(verified)),patch.object(workflow,'device_json',side_effect=fake_device):
                with self.assertRaises(workflow.WorkflowError):workflow.launch(args)
                self.assertEqual(calls,[])
                installed=workflow.install(args)
                self.assertTrue(installed['install_command_succeeded']);self.assertEqual(installed['install_outcome'],'succeeded')
                launched=workflow.launch(args)
                self.assertTrue(launched['launch_command_succeeded']);self.assertTrue(launched['install_command_succeeded'])
                before=len(calls)
                for key in ['local_binary_sha256','source_commit']:
                    original=verified[key];verified[key]='f'*len(original)
                    with self.assertRaises(workflow.WorkflowError):workflow.launch(args)
                    verified[key]=original
                state['device']='11111111-1111111111111111'
                with self.assertRaises(workflow.WorkflowError):workflow.launch(args)
                state['device']=DEVICE;self.assertEqual(len(calls),before)
                state['fail']='launch'
                with self.assertRaises(workflow.WorkflowError):workflow.launch(args)
                failed=json.loads((private/'device-evidence.json').read_text())
                self.assertEqual(failed['launch_outcome'],'failed_or_unknown');self.assertFalse(failed['launch_command_succeeded']);self.assertTrue(failed['install_command_succeeded'])
                state['fail']=None;self.assertTrue(workflow.launch(args)['launch_command_succeeded'])
                state['fail']='install'
                with self.assertRaises(workflow.WorkflowError):workflow.install(args)
                failed=json.loads((private/'device-evidence.json').read_text())
                self.assertTrue(failed['device_install_attempted']);self.assertFalse(failed['install_command_succeeded']);self.assertFalse(failed['launch_command_succeeded'])
                self.assertEqual(failed['install_outcome'],'failed_or_unknown')
                with self.assertRaises(workflow.WorkflowError):workflow.launch(args)
                text=json.dumps(failed)
                for private_value in [DEVICE,args.device,args.bundle_id,args.team]:self.assertNotIn(private_value,text)
                self.assertFalse((private/'device-evidence.json.pending').exists())


if __name__=='__main__':unittest.main()
