"""Two pure negative groups; no API, tokens, builds or artifact downloads."""
import copy
import importlib.util
import io
import hashlib
import json
import tarfile
import tempfile
from pathlib import Path
import stat
import unittest
import zipfile

spec = importlib.util.spec_from_file_location('public_delivery', Path(__file__).with_name('public-delivery.py'))
delivery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(delivery)


class PublicDeliveryGuards(unittest.TestCase):
    def test_contract_rejects_wrong_destination_and_incomplete_review_pins(self):
        value = {'schema_version': 1, 'reviewed': True, 'repository': delivery.REPO, 'branch': delivery.BRANCH,
            'source_run_id': 123, 'source_commit': '1' * 40, 'source_tree_sha256': '2' * 64,
            'locked_dependency_graph_hash': '3' * 64,
            'artifacts': {kind: {'id': index + 1, 'name': name, 'bytes': 100, 'sha256': '4' * 64}
                          for index, (kind, name) in enumerate(delivery.ARTIFACT_NAMES.items())},
            'files': {name: {'bytes': 10, 'sha256': '5' * 64} for name in delivery.FILES}}
        self.assertIs(delivery.validate_contract(value), value)
        changed = []
        for key, wrong in [('repository', 'someone/another-project'), ('branch', 'main'), ('reviewed', False),
                           ('source_commit', 'not-a-source-revision'), ('schema_version', True)]:
            bad = copy.deepcopy(value); bad[key] = wrong; changed.append(bad)
        bad = copy.deepcopy(value); del bad['files'][delivery.SOURCE]; changed.append(bad)
        bad = copy.deepcopy(value); bad['artifacts']['kit']['id'] = bad['artifacts']['candidate']['id']; changed.append(bad)
        bad = copy.deepcopy(value); bad['artifacts']['candidate']['name'] = 'unreviewed-payload'; changed.append(bad)
        for bad in changed:
            with self.assertRaises(delivery.DeliveryError):
                delivery.validate_contract(bad)
        # Declaring secure_rp_tool is insufficient without the four fixed files.
        # Fail before importing/executing any artifact-provided Python or binary.
        with self.assertRaises(delivery.DeliveryError):
            delivery.verify_helper_payload({'secure_rp_tool':{'format_key':'format_version','protocol_record_version':2}},
                {}, {}, None, value, {'files':[]}, Path('/TEST-ONLY-unused'))
        with self.assertRaises(delivery.DeliveryError):
            delivery.verify_helper_macho(b'TEST-ONLY not a universal executable',{
                'genuine_toolchain':{'rustc':'rustc 1.99.1 TEST-ONLY','xcode':'Xcode 27.1',
                    'clang':'TEST-ONLY Apple clang','macos_sdk':'27.1','sdk_settings_sha256':'0'*64}})

    def test_archive_guards_reject_escape_links_aliases_and_expansion(self):
        cases = [[('../outside', b'bad', None)], [('/absolute', b'bad', None)],
                 [('folder\\outside', b'bad', None)], [('link', b'target', stat.S_IFLNK | 0o777)],
                 [('Source.md', b'a', None), ('source.md', b'b', None)],
                 [('parent/child', b'a', None), ('parent', b'b', None)]]
        for entries in cases:
            stream = io.BytesIO()
            with zipfile.ZipFile(stream, 'w') as archive:
                for name, payload, mode in entries:
                    item = zipfile.ZipInfo(name)
                    if mode is not None: item.external_attr = mode << 16
                    archive.writestr(item, payload)
            stream.seek(0)
            with zipfile.ZipFile(stream) as archive, self.assertRaises(delivery.DeliveryError):
                delivery.zip_index(archive)
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, 'w') as archive:
            archive.writestr('bounded', b'four')
        stream.seek(0)
        with zipfile.ZipFile(stream) as archive, self.assertRaises(delivery.DeliveryError):
            delivery.zip_index(archive, max_member=3)

        work=delivery.ROOT/'app-installer/cloud-ui/work';work.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='TEST-ONLY-delivery-negative-',dir=work) as temporary:
            base=Path(temporary)
            # Metadata claiming a genuine build cannot replace Info.plist/Mach-O.
            ipa=base/'TEST-ONLY-resources.ipa'
            metadata={'synthetic_sdk_marker':False,'designation':'unsigned-candidate',
                      'compilation_sdk':'27.1','requested_sdk_mark':'27.1'}
            with zipfile.ZipFile(ipa,'w') as archive:
                for name,data in [('BuildMetadata.json',json.dumps(metadata).encode()),
                                  ('ThirdPartyNoticeReport.json',b'{}'),('ThirdPartyNotices.txt',b'TEST-ONLY')]:
                    archive.writestr('Payload/AppInstaller.app/'+name,data)
            with self.assertRaises(delivery.DeliveryError):
                delivery.verify_ipa_integrity(ipa,'duo',metadata,{})

            # Every listed byte/hash and component flag is internally consistent,
            # but actual helper/registry/runtime/production source is omitted.
            # The existing complete-source verifier must reject that omission.
            graphs=[{'manifest':'app-installer/core/Cargo.toml','target':'aarch64-apple-ios','TEST-ONLY':True}]
            graph_hash=hashlib.sha256(json.dumps(graphs,sort_keys=True,separators=(',',':')).encode()).hexdigest()
            payload={'app-installer/licensing-signing.md':b'TEST-ONLY relink reverse',
                'ThirdPartyNotices.txt':b'TEST-ONLY notice', 'ThirdPartyNoticeReport.json':b'{}',
                'app-installer/core/Cargo.lock':b'version = 4\n'}
            manifest={'test_fixture':False,'source_has_uncommitted_changes':False,
                'source_commit':'1'*40,'source_tree_sha256':'2'*64,'locked_dependency_graph_hash':graph_hash,
                'notice_obligations_satisfied':True,'notice_gap_count':0,'recipient_library_modifications_permitted':True,
                'required_components':sorted(delivery.SOURCE_COMPONENTS),'distribution_graphs':graphs,
                'relink_instructions':'app-installer/licensing-signing.md',
                'cargo_lock_sha256':hashlib.sha256(payload['app-installer/core/Cargo.lock']).hexdigest(),
                'source_fingerprint_inputs':[],'path_sources':[],
                'files':[{'path':name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()} for name,data in payload.items()]}
            source=base/'TEST-ONLY-incomplete-source.tar.xz'
            with tarfile.open(source,'w:xz') as archive:
                for name,data in [('SourceBundleManifest.json',json.dumps(manifest).encode()),*payload.items()]:
                    entry=tarfile.TarInfo('AppInstaller-source/'+name);entry.size=len(data)
                    archive.addfile(entry,io.BytesIO(data))
            contract={'source_commit':'1'*40,'source_tree_sha256':'2'*64,'locked_dependency_graph_hash':graph_hash}
            with self.assertRaises(delivery.DeliveryError):delivery.source_manifest(source,contract)


if __name__ == '__main__':
    unittest.main()
