"""Published-package license obligations, integrity and recipient replacement regressions."""
import hashlib
import io
import json
import os
from pathlib import Path
import shutil
import sys
import tarfile
import tempfile
import tomllib
import unittest
sys.dont_write_bytecode=True
BUILD=Path(__file__).resolve().parents[1];sys.path.insert(0,str(BUILD))
import licensing
ROOT=BUILD.parents[1]
CARGO_HOME=Path(os.environ.get('CARGO_HOME',str(ROOT/'downloads/rust-toolchain/cargo')))


class PublishedLicensingTests(unittest.TestCase):
    def package(self,name,version,local=False):
        manifests=list((CARGO_HOME/'registry/src').glob(f'*/{name}-{version}/Cargo.toml'))
        if not manifests:manifests=list((ROOT/'vendor').glob(f'{name}-{version}/Cargo.toml'))
        manifest=manifests[0]
        data=tomllib.loads(manifest.read_text())['package']
        return dict(name=name,version=version,license=data['license'],authors=data.get('authors',[]),
                    manifest_path=str(manifest),source=None if local else 'registry+https://github.com/rust-lang/crates.io-index')

    def test_exact_published_grants_notice_texts_and_unicode_data(self):
        for name,version,selection in [('cms','0.2.3','Apache-2.0'),('plist-macro','0.1.6','MIT'),
                                       ('unicode-casefold','0.2.0','Apache-2.0 AND Unicode-DFS-2016')]:
            with self.subTest(package=name):
                base=ROOT/'downloads/license-notices'/f'{name}-{version}'
                evidence=json.loads((base/'SOURCE.json').read_text())
                archives=list((CARGO_HOME/'registry/cache').glob(f'*/{name}-{version}.crate'))
                if not archives:archives=list((ROOT/'downloads/rust-toolchain/cargo/registry/cache').glob(f'*/{name}-{version}.crate'))
                archive=archives[0]
                self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(),evidence['package_checksum'])
                assessed=licensing.assess(self.package(name,version),[],evidence['package_checksum'])
                self.assertEqual(assessed['gaps'],[])
                self.assertEqual(assessed['selected_license'],selection)
                audit=json.loads((base/'SOURCE-AUDIT.json').read_text())
                with tarfile.open(fileobj=io.BytesIO(archive.read_bytes()),mode='r:gz') as source:
                    files={m.name.split('/',1)[1]:source.extractfile(m).read() for m in source.getmembers() if m.isfile() and '/' in m.name}
                self.assertEqual(audit['published_file_count'],len(files))
                for item in audit['published_files']:
                    self.assertEqual(hashlib.sha256(files[item['path']]).hexdigest(),item['sha256'])
                self.assertEqual(audit['copyright_matches'],[]) # Factual absence is not filled with an invented holder.
                if name=='plist-macro':
                    self.assertIn('Jackson Coxson',(base/'ATTRIBUTION.txt').read_text())
                    self.assertNotIn('<copyright holders>',(base/'LICENSE-MIT.txt').read_text())
                    self.assertIn('above copyright notice',(base/'LICENSE-MIT.txt').read_text())
                if name=='unicode-casefold':
                    self.assertTrue(audit['unicode_data']['generated_tables_match_published_source'])
                    self.assertIn('© 2016 Unicode',(base/'UNICODE-CaseFolding-9.0.0.txt').read_text())
                    self.assertTrue(licensing.covered('Unicode-DFS-2016',(base/'LICENSE-UNICODE-DFS-2016.txt').read_text()))

    def test_tampered_evidence_version_drift_and_recipient_path_replacement(self):
        original=licensing.ROOT
        work=ROOT/'app-installer/build/work';work.mkdir(parents=True,exist_ok=True)
        try:
            with tempfile.TemporaryDirectory(prefix='license-test-',dir=work) as directory:
                fixture=Path(directory);destination=fixture/'downloads/license-notices/cms-0.2.3'
                shutil.copytree(ROOT/'downloads/license-notices/cms-0.2.3',destination)
                licensing.ROOT=fixture
                package=self.package('cms','0.2.3');evidence=json.loads((destination/'SOURCE.json').read_text())
                self.assertEqual(licensing.assess(package,[],evidence['package_checksum'])['gaps'],[])
                self.assertTrue(licensing.assess(package,[],'0'*64)['gaps'])
                (destination/'LICENSE-APACHE-2.0.txt').write_text('Removed essential license terms')
                with self.assertRaises(ValueError):licensing.assess(package,[],evidence['package_checksum'])
                drift=dict(package,version='0.2.4')
                self.assertTrue(licensing.assess(drift,[],None)['gaps'])
            licensing.ROOT=original
            # LGPL permits a recipient's actual modified local library; original binary enforcement is forbidden.
            local=self.package('apple-codesign-quick','0.1.0',local=True)
            result=licensing.assess(local,[],None)
            self.assertEqual(result['gaps'],[])
            self.assertTrue(result['recipient_modified_local_source'])
            self.assertEqual(result['distribution_requirements'],['corresponding-source/relink-bundle'])
        finally:
            licensing.ROOT=original
            try:work.rmdir()
            except OSError:pass


if __name__=='__main__':unittest.main()
