"""Mechanical source closure tests use explicit TEST-ONLY archives, never release evidence."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
from unittest import mock
sys.dont_write_bytecode=True
BUILD=Path(__file__).resolve().parents[1];sys.path.insert(0,str(BUILD))
spec=importlib.util.spec_from_file_location('source_bundle',BUILD/'source-bundle.py');source=importlib.util.module_from_spec(spec);spec.loader.exec_module(source)


def digest(data):return hashlib.sha256(data).hexdigest()


def fixture(path,changed=False,omit=None,corrupt=None,forge_omitted_source=False,omit_path_metadata=False,forge_runtime=False,forge_vendor=False,case_aliases=False,forge_alias=False,tamper_canonical=False):
    code=b'// TEST-ONLY offline dependency source\n'
    archive_bytes=io.BytesIO()
    published=[('Cargo.toml',b'[package]\nname="example"\nversion="1.0.0"\n'),('src/lib.rs',code)]
    if case_aliases:published += [('README.MD',b'TEST-ONLY distinct published uppercase alias\n'),('README.md',b'TEST-ONLY canonical Cargo README\n')]
    with tarfile.open(fileobj=archive_bytes,mode='w:gz') as original:
      for name,data in published:
       entry=tarfile.TarInfo('example-1.0.0/'+name);entry.size=len(data);original.addfile(entry,io.BytesIO(data))
    raw=archive_bytes.getvalue();pubsha=digest(raw)
    files={'app-installer/core/Cargo.toml':b'[package]\nname="app-installer-core"\nversion="0.1.0"\n',
      'app-installer/core/Cargo.lock':('version = 4\n[[package]]\nname="app-installer-core"\nversion="0.1.0"\n[[package]]\nname="example"\nversion="1.0.0"\nsource="registry+https://github.com/rust-lang/crates.io-index"\nchecksum="'+pubsha+'"\n').encode(),
      'app-installer/core/src/engine.rs':b'// TEST-ONLY engine source\n',
      'vendor/example-1.0.0/Cargo.toml':b'[package]\nname="example"\nversion="1.0.0"\n',
      'vendor/example-1.0.0/src/lib.rs':code,
      'archives/example-1.0.0.crate':raw,
      '.cargo/config.toml':b'[source.crates-io]\nreplace-with="vendored-sources"\n[source.vendored-sources]\ndirectory="vendor"\n',
      'app-installer/licensing-signing.md':b'TEST-ONLY fixture: recipient may replace/relink the library; reverse engineering is not prohibited.\n',
      'runtime/rust-src.tar.xz':b'TEST-ONLY runtime source fixture'}
    files['downloads/license-notices/rust-runtime-1.99.1/SOURCE.json']=json.dumps({'source_archive_sha256':digest(files['runtime/rust-src.tar.xz'])}).encode()
    checksum={'package':pubsha,'files':{'Cargo.toml':digest(files['vendor/example-1.0.0/Cargo.toml']),'src/lib.rs':digest(code)}}
    if case_aliases:
      files['vendor/example-1.0.0/README.md']=dict(published)['README.md']
      checksum['files']['README.md']=digest(dict(published)['README.md'])
    files['vendor/example-1.0.0/.cargo-checksum.json']=json.dumps(checksum).encode()
    paths=[{'name':'app-installer-core','version':'0.1.0','path':'app-installer/core'}]
    if changed:
      files['downloads/modified-lgpl/Cargo.toml']=b'[package]\nname="apple-codesign-quick"\nversion="0.1.0"\nlicense="LGPL-2.1-or-later"\n'
      files['downloads/modified-lgpl/src/lib.rs']=b'// TEST-ONLY recipient modification; original library binary is not enforced\n'
      paths.append({'name':'apple-codesign-quick','version':'0.1.0','path':'downloads/modified-lgpl'})
    virtual_files={}
    if case_aliases:
      with tempfile.TemporaryDirectory(prefix='case-alias-stage-',dir=path.parent) as directory:
       vendor=Path(directory)
       for name in ['Cargo.toml','src/lib.rs','README.md','.cargo-checksum.json']:
        target=vendor/name;target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(files['vendor/example-1.0.0/'+name])
       if tamper_canonical:(vendor/'README.md').write_bytes(b'TEST-ONLY tampered canonical Cargo input')
       aliases={}
       source.published_files(raw,'example','1.0.0',restore_missing_metadata=vendor,virtual_aliases=aliases)
       self_check=set(aliases)=={'README.MD'}
       if not self_check:raise AssertionError('Only the exact missing case alias may be virtual')
       virtual_files={'vendor/example-1.0.0/'+name:data for name,data in aliases.items()}
       files.update(virtual_files)
    manifest={'schema_version':1,'test_fixture':True,'source_commit':'1'*40,'source_tree_sha256':'2'*64,
      'locked_dependency_graph_hash':'3'*64,'cargo_lock_sha256':digest(files['app-installer/core/Cargo.lock']),
      'required_components':source.REQUIRED_COMPONENTS,'recipient_library_modifications_permitted':True,
      'relink_instructions':'app-installer/licensing-signing.md','path_sources':[] if omit_path_metadata else paths,
      'registry_sources':[{'name':'example','version':'1.0.0','path':'vendor/example-1.0.0','checksum':pubsha,'archive_path':'archives/example-1.0.0.crate'}],
      'runtime_source':{'path':'runtime/rust-src.tar.xz','sha256':digest(files['runtime/rust-src.tar.xz'])},
      'files':[{'path':name,'bytes':len(data),'sha256':digest(data)} for name,data in sorted(files.items())]}
    manifest['source_fingerprint_inputs']=source.fingerprint_paths(files.keys(),paths)
    manifest['source_tree_sha256']=source.payload_fingerprint(files,manifest['source_fingerprint_inputs'])
    original_fp=manifest['source_tree_sha256']
    if forge_omitted_source:
      del files['app-installer/core/src/engine.rs']
      manifest['source_fingerprint_inputs']=source.fingerprint_paths(files.keys(),paths)
      manifest['files']=[f for f in manifest['files'] if f['path']!='app-installer/core/src/engine.rs']
    if forge_runtime:
      files['runtime/rust-src.tar.xz']=b'TEST-ONLY unrelated runtime with self-asserted new hash'
      manifest['runtime_source']['sha256']=digest(files['runtime/rust-src.tar.xz'])
      for entry in manifest['files']:
        if entry['path']=='runtime/rust-src.tar.xz':entry.update(bytes=len(files[entry['path']]),sha256=digest(files[entry['path']]))
    if forge_vendor:
      files['vendor/example-1.0.0/src/lib.rs']=b'// TEST-ONLY forged vendor source\n'
      checksum['files']['src/lib.rs']=digest(files['vendor/example-1.0.0/src/lib.rs'])
      files['vendor/example-1.0.0/.cargo-checksum.json']=json.dumps(checksum).encode()
      for entry in manifest['files']:
        if entry['path'].startswith('vendor/'):
          entry.update(bytes=len(files[entry['path']]),sha256=digest(files[entry['path']]))
    if forge_alias:
      files['vendor/example-1.0.0/README.MD']=b'TEST-ONLY forged alias with self-asserted manifest hash'
      virtual_files['vendor/example-1.0.0/README.MD']=files['vendor/example-1.0.0/README.MD']
      for entry in manifest['files']:
       if entry['path']=='vendor/example-1.0.0/README.MD':entry.update(bytes=len(files[entry['path']]),sha256=digest(files[entry['path']]))
    if corrupt:files[corrupt]+=b'CORRUPTION'
    if case_aliases:
      with tempfile.TemporaryDirectory(prefix='case-alias-delivery-',dir=path.parent) as directory:
       stage=Path(directory)
       for name,data in files.items():
        if name in virtual_files:continue
        target=stage/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
       # Exercise the production case-sensitive manifest and tar-member path,
       # while only the canonical README.md exists on the staging filesystem.
       manifest['files']=source.file_manifest(stage,virtual_files)
       with tarfile.open(path,'w:xz') as archive:
        data=(json.dumps(manifest)+'\n').encode();entry=tarfile.TarInfo(source.BUNDLE_ROOT+'/'+source.MANIFEST);entry.size=len(data);archive.addfile(entry,io.BytesIO(data))
        for entry in manifest['files']:
         if entry['path']!=omit:source.add_source_member(archive,stage,entry,virtual_files)
    else:
      with tarfile.open(path,'w:xz') as archive:
       for name,data in [(source.MANIFEST,(json.dumps(manifest)+'\n').encode()),*sorted(files.items())]:
        if name==omit:continue
        entry=tarfile.TarInfo(source.BUNDLE_ROOT+'/'+name);entry.size=len(data);archive.addfile(entry,io.BytesIO(data))
    return original_fp


class SourceDeliveryTests(unittest.TestCase):
    def test_complete_locked_source_and_recipient_modified_library_are_supported(self):
      work=BUILD/'work';work.mkdir(exist_ok=True)
      with tempfile.TemporaryDirectory(prefix='delivery-test-',dir=work) as directory:
       archive=Path(directory)/'TEST-ONLY-source.tar.xz'
       for modified in [False,True]:
        fp=fixture(archive,changed=modified)
        result=source.verify(archive,fp,'3'*64,allow_test_fixture=True)
        self.assertTrue(result['recipient_library_modifications_permitted'])
        with self.assertRaises(ValueError):source.verify(archive,fp,'3'*64)
       # Simulate APFS/Cargo retaining only the canonical spelling. The other
       # published alias has DIFFERENT bytes and must survive as an exact member.
       fp=fixture(archive,case_aliases=True)
       result=source.verify(archive,fp,'3'*64,allow_test_fixture=True)
       with tarfile.open(archive,'r:xz') as delivered:
        names=delivered.getnames();upper=source.BUNDLE_ROOT+'/vendor/example-1.0.0/README.MD';lower=source.BUNDLE_ROOT+'/vendor/example-1.0.0/README.md'
        self.assertIn(upper,names);self.assertIn(lower,names)
        self.assertLess(names.index(upper),names.index(lower),'Canonical Cargo input must be the final case-insensitive extraction winner')
        self.assertEqual(delivered.extractfile(upper).read(),b'TEST-ONLY distinct published uppercase alias\n')
        self.assertEqual(delivered.extractfile(lower).read(),b'TEST-ONLY canonical Cargo README\n')
        collapsed={source.case_alias_key(member.name):delivered.extractfile(member).read() for member in delivered if member.isfile()}
        self.assertEqual(collapsed[source.case_alias_key(lower)],b'TEST-ONLY canonical Cargo README\n')
       self.assertTrue({'vendor/example-1.0.0/README.MD','vendor/example-1.0.0/README.md'} <= {entry['path'] for entry in result['files']})
       # Cargo vendor excludes Git metadata, not source. Distribution restores
       # the exact immutable bytes without allowing arbitrary source omissions.
       published=io.BytesIO()
       entries={'.gitignore':b'TEST-ONLY target/\n','.gitattributes':b'TEST-ONLY * text=auto\n',
                'src/lib.rs':b'// TEST-ONLY published source\n'}
       with tarfile.open(fileobj=published,mode='w:gz') as original:
        for name,data in entries.items():
         entry=tarfile.TarInfo('example-1.0.0/'+name);entry.size=len(data);original.addfile(entry,io.BytesIO(data))
       vendor=Path(directory)/'vendor';vendor.mkdir()
       original=source.published_files(published.getvalue(),'example','1.0.0',restore_missing_metadata=vendor)
       for name in ('.gitignore','.gitattributes'):
        self.assertEqual((vendor/name).read_bytes(),entries[name])
        self.assertEqual(original[name],digest(entries[name]))
       self.assertFalse((vendor/'src/lib.rs').exists())
       (vendor/'.gitignore').write_bytes(b'TEST-ONLY tampered metadata')
       source.published_files(published.getvalue(),'example','1.0.0',restore_missing_metadata=vendor)
       self.assertNotEqual(digest((vendor/'.gitignore').read_bytes()),original['.gitignore'])
      try:work.rmdir()
      except OSError:pass

    def test_missing_source_tampering_and_mismatched_graph_are_rejected(self):
      work=BUILD/'work';work.mkdir(exist_ok=True)
      with tempfile.TemporaryDirectory(prefix='delivery-test-',dir=work) as directory:
       archive=Path(directory)/'TEST-ONLY-source.tar.xz'
       fp=fixture(archive,omit='vendor/example-1.0.0/src/lib.rs')
       with self.assertRaises(ValueError):source.verify(archive,fp,'3'*64,allow_test_fixture=True)
       fp=fixture(archive,corrupt='app-installer/licensing-signing.md')
       with self.assertRaises(ValueError):source.verify(archive,fp,'3'*64,allow_test_fixture=True)
       fp=fixture(archive)
       with self.assertRaises(ValueError):source.verify(archive,fp,'f'*64,allow_test_fixture=True)
       for changes in [{'forge_omitted_source':True},{'forge_runtime':True},{'omit_path_metadata':True},{'forge_vendor':True}]:
        fp=fixture(archive,**changes)
        with self.assertRaises(ValueError):source.verify(archive,fp,'3'*64,allow_test_fixture=True)
       # A virtual alias with a forged self-consistent file-manifest digest
       # must still fail the unchanged immutable-publication comparison.
       with self.assertRaisesRegex(ValueError,'Canonical Cargo source alias'):
        fixture(archive,case_aliases=True,tamper_canonical=True)
       fp=fixture(archive,case_aliases=True,forge_alias=True)
       with self.assertRaisesRegex(ValueError,'immutable publication'):source.verify(archive,fp,'3'*64,allow_test_fixture=True)
       fp=fixture(archive,case_aliases=True,omit='vendor/example-1.0.0/src/lib.rs')
       with self.assertRaises(ValueError):source.verify(archive,fp,'3'*64,allow_test_fixture=True)
       # Reject oversized metadata before any payload read/allocation; no huge fixture file is created.
       huge=tarfile.TarInfo(source.BUNDLE_ROOT+'/'+source.MANIFEST);huge.size=32*1024*1024+1
       class HeaderOnly:
        def __enter__(self):return self
        def __exit__(self,*args):return False
        def __iter__(self):return iter([huge])
        def extractfile(self,*args):raise AssertionError('Oversized payload must not be read')
       with mock.patch.object(source.tarfile,'open',return_value=HeaderOnly()):
        with self.assertRaises(ValueError):source.verify(archive,allow_test_fixture=True)

      try:work.rmdir()
      except OSError:pass


if __name__=='__main__':unittest.main()
