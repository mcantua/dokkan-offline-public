#!/usr/bin/env python3
"""Two focused mocked device-selection regressions; no Mac/device/account access."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.dont_write_bytecode=True
spec=importlib.util.spec_from_file_location('selection_wizard',Path(__file__).with_name('setup-wizard.py'))
wizard=importlib.util.module_from_spec(spec);spec.loader.exec_module(wizard)
workflow=wizard.workflow
ALIAS='11111111-2222-3333-4444-555555555555'
SIMULATOR='22222222-2222-3333-4444-555555555555'
OFFLINE='33333333-2222-3333-4444-555555555555'
UDID='00000000-0000000000000000'  # TEST-ONLY format fixture, never a queried phone.


def row(alias,name,hardware=None):
    return {'identifier':alias,'hardwareProperties':hardware or {'productType':'iPhone19,4'},'deviceProperties':{'name':name}}


def details(udid=UDID,model='iPhone19,4'):
    return {'result':{'hardwareProperties':{'productType':model,'udid':udid}}}


class DeviceSelection(unittest.TestCase):
    def fixtures(self,temporary,devices,resolve):
        self.calls=[]
        def command(argv,*,step):
            self.calls.append(('list',))
            self.assertEqual(argv[:4],['xcrun','devicectl','list','devices'])
            Path(argv[argv.index('--json-output')+1]).write_text(json.dumps({'result':{'devices':devices}}))
            return b''
        def device_json(args,*pieces):
            self.calls.append(('details',args.device))
            self.assertEqual(pieces,('device','info','details'))
            return resolve(args.device)
        return patch.multiple(workflow,PRIVATE=Path(temporary),command=command,device_json=device_json)

    def test_simulator_and_offline_rows_are_excluded_before_choosing_the_physical_phone(self):
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        devices=[row(SIMULATOR,'TEST ONLY — simulator'),row(ALIAS,'TEST ONLY — physical'),row(OFFLINE,'TEST ONLY — offline')]
        def resolve(alias):
            if alias==OFFLINE:raise workflow.WorkflowError('TEST ONLY offline')
            return details(SIMULATOR if alias==SIMULATOR else UDID)
        def choose(message,choices):
            self.calls.append(('choose',))
            self.assertEqual(len(choices),1)
            self.assertIn('physical',choices[0]);self.assertNotIn('simulator',choices[0]);self.assertNotIn('offline',choices[0])
            return choices[0]
        with tempfile.TemporaryDirectory(prefix='selection-fixture-',dir=base) as temporary:
            with self.fixtures(temporary,devices,resolve),patch.object(wizard,'choose',side_effect=choose),patch.object(wizard,'teams_with_signing_keys',side_effect=AssertionError('Selection must not query an account')):
                self.assertEqual(wizard.choose_device(),(UDID,'duo'))
            self.assertEqual(self.calls,[('list',),('details',SIMULATOR),('details',ALIAS),('details',OFFLINE),('choose',),('details',ALIAS)])

    def test_ambiguous_identity_model_and_changed_selected_hardware_fail_before_account_access(self):
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        invalid=[{}, {'result':{}}, {'result':{'hardwareProperties':'unsupported'}},
                 {'result':{'hardwareProperties':{'productType':'iPhone19,4'}}},details(ALIAS),details(UDID,'iPhone18,1')]
        with tempfile.TemporaryDirectory(prefix='selection-negative-',dir=base) as temporary:
            for response in invalid:
                with self.subTest(response=response),self.fixtures(temporary,[row(ALIAS,'TEST ONLY')],lambda _:response),patch.object(wizard,'choose',side_effect=AssertionError('Invalid candidates must never be offered')),patch.object(wizard,'teams_with_signing_keys',side_effect=AssertionError('No account query')):
                    with self.assertRaises(workflow.WorkflowError):wizard.choose_device()
            # A validated list entry still needs a same-identity check after choosing.
            for response in [details('11111111-1111111111111111'),details(UDID,'iPhone18,1'),details(ALIAS)]:
                listed=row(ALIAS,'TEST ONLY',{'productType':'iPhone19,4','udid':UDID})
                with self.subTest(changed=response),self.fixtures(temporary,[listed],lambda _:response),patch.object(wizard,'teams_with_signing_keys',side_effect=AssertionError('No account query')):
                    with self.assertRaises(workflow.WorkflowError):wizard.choose_device()
                self.assertEqual(self.calls,[('list',),('details',ALIAS)])


if __name__=='__main__':unittest.main()
