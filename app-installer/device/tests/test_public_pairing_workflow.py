"""Two grouped account/device-free regressions; all helper bytes are TEST-ONLY."""
import contextlib, copy, hashlib, importlib.util, io, json, pathlib, sys, tempfile, unittest
from unittest import mock
sys.dont_write_bytecode=True
DEVICE=pathlib.Path(__file__).resolve().parents[1]
ROOT=DEVICE.parents[1]
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    value=importlib.util.module_from_spec(spec);spec.loader.exec_module(value);return value
workflow=module('public_pairing_workflow_test',DEVICE/'device-workflow.py')
wizard=module('public_pairing_wizard_test',DEVICE/'setup-wizard.py')

def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()

class PublicPairingWorkflow(unittest.TestCase):
    def test_helper_seal_source_hash_graph_and_mode_are_required(self):
        work=ROOT/'app-installer/cloud-ui/work';work.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='TEST-ONLY-helper-gate-',dir=work) as temporary:
            base=pathlib.Path(temporary)
            graphs={'aarch64-apple-darwin':'a'*64,'x86_64-apple-darwin':'b'*64}
            paths={key:base/value for key,value in workflow.RP_HELPER_PATHS.items()}
            for path in paths.values():path.parent.mkdir(parents=True,exist_ok=True)
            paths['binary'].write_bytes(b'TEST-ONLY not a Mach-O binary; hash gate only')
            paths['binary'].chmod(0o755)
            paths['notices'].write_text('TEST-ONLY synthetic notice text\n')
            report={'notice_obligations_satisfied':True,'notice_gap_count':0,'target_graph_hashes':graphs}
            paths['notice_report'].write_text(json.dumps(report))
            source={'file':'TEST-ONLY-source.tar.xz','bytes':123,'sha256':'c'*64}
            receipt={'schema_version':1,'project':'dokkan-offline-public','test_fixture':False,
                'tool':'app-installer-rp-bootstrap','version':'0.1.68','source_commit':'d'*40,
                'source_tree_sha256':'e'*64,'targets':['aarch64-apple-darwin','x86_64-apple-darwin'],
                'architectures':['arm64','x86_64'],'minimum_macos':'12.0','ad_hoc_signed':True,'notarized':False,
                'build_succeeded':True,'version_output':'app-installer-rp-bootstrap 0.1.68','version_only_executed':True,
                'usb_or_pairing_executed':False,'personal_resources_used':False,
                'notice_delivery_pending':False,'corresponding_source_delivery_pending':False,
                'corresponding_source':source,'target_graph_hashes':graphs}
            for key in ['binary','notices','notice_report']:
                receipt[key]={'file':paths[key].name,'bytes':paths[key].stat().st_size,'sha256':digest(paths[key])}
            receipt['binary']['mode']=0o755
            tool={**workflow.RP_HELPER_PATHS,'source_commit':'d'*40,'source_tree_sha256':'e'*64,
                'version':'0.1.68','format_key':'format_version','protocol_record_version':2,'peer_pin_required':True}
            def fixture(value):
                paths['manifest'].write_text(json.dumps(value))
                files=[{'path':relative,'bytes':paths[key].stat().st_size,'sha256':digest(paths[key]),
                        **({'mode':0o755} if key=='binary' else {})} for key,relative in workflow.RP_HELPER_PATHS.items()]
                return {'bootstrap_tool_commit':'d'*40,'source_tree_sha256':'e'*64,
                        'files':files,'secure_rp_tool':tool,'corresponding_source':source}
            # This is only the byte/source gate; no signature, version command or
            # executable is run, and no synthetic receipt is distributed.
            self.assertEqual(workflow.validate_remote_pairing_tool(fixture(receipt),base=base),paths['binary'])
            mutations=[('notice_delivery_pending',True),('corresponding_source_delivery_pending',True),
                       ('source_commit','f'*40),('test_fixture',True),('version_only_executed',False),
                       ('target_graph_hashes',{'aarch64-apple-darwin':'0'*64,'x86_64-apple-darwin':'b'*64}),
                       ('corresponding_source',{**source,'sha256':'0'*64})]
            for key,value in mutations:
                with self.subTest(key=key):
                    changed=copy.deepcopy(receipt);changed[key]=value
                    with self.assertRaises(workflow.WorkflowError):workflow.validate_remote_pairing_tool(fixture(changed),base=base)
            kit=fixture(receipt)
            paths['binary'].write_bytes(b'TEST-ONLY changed executable')
            with self.assertRaises(workflow.WorkflowError):workflow.validate_remote_pairing_tool(kit,base=base)
            paths['binary'].write_bytes(b'TEST-ONLY not a Mach-O binary; hash gate only');paths['binary'].chmod(0o644)
            with self.assertRaises(workflow.WorkflowError):workflow.validate_remote_pairing_tool(fixture(receipt),base=base)

    def test_pair_only_skips_accounts_and_owned_capture_never_forwards_private_text(self):
        with contextlib.redirect_stdout(io.StringIO()),mock.patch.object(wizard.workflow,'mac_only'), \
             mock.patch.object(wizard.workflow,'private_directory'),mock.patch.object(wizard.workflow,'bootstrap_kit',return_value={'TEST-ONLY':True}), \
             mock.patch.object(wizard.workflow,'local_preflight') as preflight, \
             mock.patch.object(wizard,'choose_device',return_value=('TEST-ONLY-local-selection','duo')), \
             mock.patch.object(wizard,'teams_with_signing_keys',side_effect=AssertionError('account discovery forbidden')), \
             mock.patch.object(wizard.workflow,'main',return_value=0) as operation, \
             mock.patch.object(wizard,'pairing_export_instructions'):
            self.assertEqual(wizard.main(['--execute','--pairing-only']),0)
            preflight.assert_called_once_with(pairing_only=True)
            self.assertEqual(operation.call_args.args[0][0],'create-remote-pairing')
            self.assertEqual(operation.call_count,1)
        secret='TEST-ONLY PRIVATE PAYLOAD MUST NEVER ESCAPE'
        class Child:
            def __init__(self,code=0,error=False):
                self.stdout=io.BytesIO(b'RP_EXPORT_STAGE: STARTED\nRP_EXPORT_STAGE: EXPORTED_PRIVATE_V2\n'+secret.encode()+b'\n')
                self.stderr=io.BytesIO((secret+'\nRP_EXPORT_ERROR: '+secret+'\n').encode()
                    +(b'RP_EXPORT_ERROR: PAIR_AUTHENTICATION_NO_EXPORT\n' if error else b''))
                self.code=code;self.terminated=False
            def wait(self,timeout=None):return self.code
            def poll(self):return None if self.code is None else self.code
            def terminate(self):self.terminated=True;self.code=-15
            def kill(self):self.terminated=True;self.code=-9
        for code,error in [(0,False),(1,True),(0,True)]:
            child=Child(code,error);output=io.StringIO()
            with contextlib.redirect_stdout(output),mock.patch.object(workflow.subprocess,'Popen',return_value=child):
                if code or error:
                    with self.assertRaises(workflow.WorkflowError):workflow.run_pairing_child(pathlib.Path('/TEST-ONLY-helper'),'TEST-ONLY-selection')
                else:workflow.run_pairing_child(pathlib.Path('/TEST-ONLY-helper'),'TEST-ONLY-selection')
            self.assertNotIn(secret,output.getvalue())
            self.assertIn('PAIRING_STAGE: STARTED',output.getvalue())
        child=Child(None);output=io.StringIO()
        with contextlib.redirect_stdout(output),mock.patch.object(workflow.subprocess,'Popen',return_value=child), \
             mock.patch.object(workflow.time,'monotonic',side_effect=[0,601]):
            with self.assertRaises(workflow.WorkflowError):workflow.run_pairing_child(pathlib.Path('/TEST-ONLY-helper'),'TEST-ONLY-selection')
        self.assertTrue(child.terminated)
        self.assertIn('HELPER_WALL_TIMEOUT_OUTCOME_UNKNOWN',output.getvalue())
        self.assertNotIn(secret,output.getvalue())

if __name__=='__main__':unittest.main()
