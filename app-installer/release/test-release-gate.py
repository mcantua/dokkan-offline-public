#!/usr/bin/env python3
"""Two grouped release-boundary regressions; fixtures never claim real readiness."""
import contextlib
import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec=importlib.util.spec_from_file_location('gate',Path(__file__).with_name('verify-release.py'))
gate=importlib.util.module_from_spec(spec);spec.loader.exec_module(gate)
IPA_HASH='1'*64
SOURCE_HASH='2'*64
FINGERPRINT='3'*64
GRAPH='4'*64

class ReleaseBoundary(unittest.TestCase):
    def report(self):
        r={'schema_version':1,'artifact_sha256':IPA_HASH,'source_bundle_sha256':SOURCE_HASH,
           'source_commit':'a'*40,'source_tree_sha256':FINGERPRINT,'test_fixture':False}
        for area,fields in gate.REQUIRED.items():r[area]={field:True for field in fields}
        r['licensing']['unresolved_notice_cases']=0
        r['apple']['simulator']=False;r['duo']['simulator']=False
        r['features']['missing_required_capabilities']=[]
        return r

    def test_all_required_fields_are_explicit_strict_and_artifact_bound(self):
        self.assertEqual(gate.evaluate(self.report(),IPA_HASH,SOURCE_HASH),[])
        for key in ['schema_version','test_fixture','artifact_sha256','source_bundle_sha256','source_commit','source_tree_sha256']:
            r=self.report();r.pop(key);self.assertTrue(gate.evaluate(r,IPA_HASH,SOURCE_HASH),key)
        for area,fields in gate.REQUIRED.items():
            for field in fields:
                for wrong in ['true',1,None]:
                    r=self.report();r[area][field]=wrong
                    self.assertIn(area+'.'+field,gate.evaluate(r,IPA_HASH,SOURCE_HASH))
                r=self.report();r[area].pop(field)
                self.assertIn(area+'.'+field,gate.evaluate(r,IPA_HASH,SOURCE_HASH))
            r=self.report();r[area]=[];self.assertTrue(gate.evaluate(r,IPA_HASH,SOURCE_HASH))
        for key,value in [('schema_version',True),('test_fixture',True),('source_commit','z'*40),('source_tree_sha256','z'*64)]:
            r=self.report();r[key]=value;self.assertTrue(gate.evaluate(r,IPA_HASH,SOURCE_HASH))
        r=self.report();r['licensing']['unresolved_notice_cases']=False
        self.assertIn('unresolved license notices',gate.evaluate(r,IPA_HASH,SOURCE_HASH))
        r=self.report();r['apple']['simulator']=True;self.assertTrue(gate.evaluate(r,IPA_HASH,SOURCE_HASH))
        r=self.report();r['duo']['simulator']=True;self.assertTrue(gate.evaluate(r,IPA_HASH,SOURCE_HASH))
        self.assertTrue(gate.evaluate(self.report(),'9'*64,SOURCE_HASH))
        self.assertTrue(gate.evaluate(self.report(),IPA_HASH,'9'*64))
        with self.assertRaises(ValueError):gate.json_object('{"test_fixture":true,"test_fixture":false}')
        self.assertTrue(gate.evaluate({},IPA_HASH,SOURCE_HASH))

    def test_primary_signed_artifact_and_delivered_source_content_cannot_be_faked_by_names(self):
        base=gate.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='release-gate-',dir=base) as temporary:
            work=Path(temporary);ipa=work/'fixture.ipa';source=work/'source.tar.xz'
            report=self.report()
            metadata={'source_commit':report['source_commit'],'source_tree_sha256':FINGERPRINT,
                      'source_has_uncommitted_changes':False,'unsigned':False,'source_bundle_sha256':SOURCE_HASH}
            notices={'notice_gap_count':0,'notice_obligations_satisfied':True,'missing_notices':[],
                     'locked_dependency_graph_hash':GRAPH}
            def make_ipa(meta=None,signature_root='Payload/App.app/',notice=None):
                with zipfile.ZipFile(ipa,'w') as z:
                    z.writestr('Payload/App.app/BuildMetadata.json',json.dumps(metadata if meta is None else meta))
                    z.writestr('Payload/App.app/ThirdPartyNoticeReport.json',json.dumps(notices if notice is None else notice))
                    z.writestr(signature_root+'embedded.mobileprovision',b'UNIT TEST ONLY; not real provisioning')
                    z.writestr(signature_root+'_CodeSignature/CodeResources',b'UNIT TEST ONLY; not a real signature')
            manifest={'schema_version':1,'source_commit':report['source_commit'],'source_tree_sha256':FINGERPRINT}
            with patch.object(gate,'verify_source_bundle',return_value=manifest),patch.object(gate,'archive_fingerprint',return_value=FINGERPRINT):
                make_ipa({**metadata,'unsigned':True})
                self.assertIn('unsigned candidate cannot be a final release',gate.inspect_artifacts(report,ipa,source,SOURCE_HASH))
                make_ipa({**metadata,'source_tree_sha256':'9'*64})
                self.assertIn('compiled source/evidence fingerprint mismatch',gate.inspect_artifacts(report,ipa,source,SOURCE_HASH))
                make_ipa(signature_root='Payload/App.app/PlugIns/Extension.appex/')
                failures=gate.inspect_artifacts(report,ipa,source,SOURCE_HASH)
                self.assertIn('signed provisioning profile absent from primary app',failures)
                self.assertIn('bundle signature resources absent from primary app',failures)
                make_ipa(notice={'notice_gap_count':0})
                self.assertIn('packaged notice report has unresolved or unspecified obligations',gate.inspect_artifacts(report,ipa,source,SOURCE_HASH))
            make_ipa()
            with patch.object(gate,'verify_source_bundle',side_effect=ValueError('source closure invalid')):
                with self.assertRaises(ValueError):gate.inspect_artifacts(report,ipa,source,SOURCE_HASH)
            # Fingerprint binding is computed from delivered source bytes, not its manifest claim.
            recipe=(gate.ROOT/'app-installer/build/source-fingerprint.py').read_bytes()
            def make_source(payload):
                with tarfile.open(source,'w:xz') as archive:
                    for name,data in [('app-installer/build/source-fingerprint.py',recipe),('app-installer/ios/Fixture.m',payload)]:
                        member=tarfile.TarInfo('AppInstaller-source/'+name);member.size=len(data);archive.addfile(member,io.BytesIO(data))
            make_source(b'old source');before=gate.archive_fingerprint(source)
            make_source(b'changed source');self.assertNotEqual(before,gate.archive_fingerprint(source))
            # Even fabricated profile/signature names plus an all-true completeness report
            # cannot classify this invalid source closure/test fixture as a final release.
            report['test_fixture']=True;report['artifact_sha256']=gate.sha(ipa);report['source_bundle_sha256']=gate.sha(source)
            evidence=work/'evidence.json';evidence.write_text(json.dumps(report))
            output=io.StringIO()
            with contextlib.redirect_stdout(output):code=gate.main(['--ipa',str(ipa),'--source-bundle',str(source),'--evidence',str(evidence)])
            self.assertEqual(code,1);self.assertIs(json.loads(output.getvalue())['release_ready'],False)

if __name__=='__main__':unittest.main()
