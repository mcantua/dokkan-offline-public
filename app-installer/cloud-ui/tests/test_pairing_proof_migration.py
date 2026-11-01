"""Actual retained public proof inputs; never execute Apple/device actions."""
import base64,copy,importlib.util,json,os,pathlib,subprocess,unittest
from unittest import mock
ROOT=pathlib.Path(__file__).resolve().parents[3]
with mock.patch.dict(os.environ,{'AI_NATIVE_TEST_SCOPE':'responsive'}):
    spec=importlib.util.spec_from_file_location('pairing_proof',ROOT/'app-installer/cloud-ui/pairing-public-proof.py')
    proof=importlib.util.module_from_spec(spec);spec.loader.exec_module(proof)
class ReviewedProofMigration(unittest.TestCase):
    def setUp(self):
        self.record=json.loads((ROOT/'downloads/completion-verification/public-pairing/resume-20261101/run41310143960/pairing-proof/transport.json').read_text())
        self.current=proof.inputs('transport')
    def public_source(self,url):
        name,ref=url.removeprefix('/contents/').split('?ref=')
        self.assertIn(name,proof.COMMON);self.assertEqual(ref,self.record['source_commit'])
        data=subprocess.check_output(['git','show',ref+':'+name],cwd=ROOT)
        return {'type':'file','encoding':'base64','size':len(data),'content':base64.b64encode(data).decode()}
    def test_reviewed_recipe_only_change_accepts_actual_public_bytes_but_rejects_core_drift(self):
        with mock.patch.object(proof,'api',side_effect=self.public_source):
            changes=proof.compare_inputs(self.record,'transport',self.current)
        self.assertTrue(changes);self.assertLessEqual({x['path'] for x in changes},set(proof.COMMON))
        drift=dict(self.current);drift['app-installer/core/src/engine.rs']='0'*64
        with self.assertRaisesRegex(ValueError,'Production source'):
            proof.compare_inputs(self.record,'transport',drift)
        missing=dict(self.current);missing.pop('app-installer/core/src/engine.rs')
        with self.assertRaisesRegex(ValueError,'inventory'):
            proof.compare_inputs(self.record,'transport',missing)
    def test_wrong_run_or_original_recipe_or_native_method_set_is_not_relabelled(self):
        changed=copy.deepcopy(self.record);changed['run_id']+=1
        with self.assertRaisesRegex(ValueError,'Source changes'):
            proof.compare_inputs(changed,'transport',self.current)
        def wrong_public_source(url):
            data=self.public_source(url);data['content']=base64.b64encode(b'changed original recipe').decode();data['size']=len(b'changed original recipe');return data
        with mock.patch.object(proof,'api',side_effect=wrong_public_source),self.assertRaisesRegex(ValueError,'actual public run source'):
            proof.compare_inputs(self.record,'transport',self.current)
        # A real previous four-method log must not be accepted as the new single
        # responsive method, even though that method appears among its passes.
        native=(ROOT/'downloads/completion-verification/public-pairing/resume-20261101/run41310143960/pairing-proof/native.log').read_bytes()
        with self.assertRaisesRegex(ValueError,'Wrong native'):
            proof.verify_logs('native',{'native.log':native})
if __name__=='__main__':unittest.main()
