#!/usr/bin/env python3
"""Verify unsigned candidate/source/relink bindings; never designate a final release."""
import argparse
import importlib.util
import json
from pathlib import Path
import sys
import zipfile
sys.dont_write_bytecode=True
from licensing import sha


def module(name,file):
    spec=importlib.util.spec_from_file_location(name,Path(__file__).with_name(file));result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result);return result


def require_genuine(metadata,manifest_toolchain):
    if metadata.get('synthetic_sdk_marker') is not False or metadata.get('designation')!='unsigned-candidate':
        raise ValueError('Synthetic Linux previews cannot be promoted as genuine device candidates')
    try:version=tuple(int(n) for n in metadata.get('compilation_sdk','').split('.'))
    except ValueError:raise ValueError('Candidate actual SDK version is invalid')
    if version<(27,1):raise ValueError('Actual installed SDK27.1 or newer is required')
    if metadata.get('requested_sdk_mark')!=metadata.get('compilation_sdk'):raise ValueError('Actual SDK marker mismatch')
    if not isinstance(manifest_toolchain,dict):raise ValueError('Actual toolchain receipt missing')
    required=('sdk_version','sdk_settings_sha256','sdk_path','xcode','clang','rustc')
    if any(not isinstance(manifest_toolchain.get(k),str) or not manifest_toolchain[k] for k in required):raise ValueError('Incomplete actual toolchain provenance')
    if manifest_toolchain['sdk_version']!=metadata['compilation_sdk']:raise ValueError('Toolchain and compilation SDK versions differ')
    import re
    if not re.fullmatch(r'[0-9a-f]{64}',manifest_toolchain['sdk_settings_sha256']):raise ValueError('SDK settings receipt hash invalid')
    if not re.search(r'(?:^|\s)rustc 1\.99\.1(?:\s|$)',manifest_toolchain['rustc']):raise ValueError('Actual Rust compiler differs from delivered runtime1.99.1 source/notices')
    if metadata.get('genuine_toolchain')!=manifest_toolchain:raise ValueError('Manifest and IPA actual toolchain receipts differ')


def verify(manifest_path,directory=None):
    manifest_path=Path(manifest_path);directory=Path(directory or manifest_path.parent)
    manifest=json.loads(manifest_path.read_text())
    if manifest.get('schema_version')!=1 or manifest.get('classification')!='unsigned-candidate' or manifest.get('release_ready') is not False:
        raise ValueError('Unsigned artifacts must remain candidates')
    if manifest.get('test_fixture'):raise ValueError('Test-only evidence is not candidate distribution evidence')
    source=manifest['source_bundle'];bundle=directory/source['file']
    if sha(bundle.read_bytes())!=source['sha256'] or bundle.stat().st_size!=source['bytes']:raise ValueError('Corresponding-source archive hash/size mismatch')
    source_manifest=module('source_bundle','source-bundle.py').verify(bundle,manifest['source_tree_sha256'],manifest['locked_dependency_graph_hash'])
    if source_manifest['source_commit']!=manifest['source_commit']:raise ValueError('Source commit mismatch')
    if source_manifest.get('source_has_uncommitted_changes') is not False:raise ValueError('Candidate source/relink bundle must come from a clean committed source tree')
    source_files={f['path']:f['sha256'] for f in source_manifest['files']}
    if len(manifest['ipa_artifacts'])!=2 or {p['variant'] for p in manifest['ipa_artifacts']}!={'iphone','duo'}:raise ValueError('Both current candidate variants are required')
    checker=module('artifact_check','check-artifact.py')
    for artifact in manifest['ipa_artifacts']:
        path=directory/artifact['file']
        if sha(path.read_bytes())!=artifact['sha256'] or path.stat().st_size!=artifact['bytes']:raise ValueError('IPA hash/size mismatch')
        checker.check(path,artifact['variant'])
        with zipfile.ZipFile(path) as ipa:
            metadata=json.loads(ipa.read('Payload/AppInstaller.app/BuildMetadata.json'))
            report=json.loads(ipa.read('Payload/AppInstaller.app/ThirdPartyNoticeReport.json'))
            notices=ipa.read('Payload/AppInstaller.app/ThirdPartyNotices.txt')
        require_genuine(metadata,manifest.get('genuine_toolchain'))
        for name in ['source_commit','source_tree_sha256','locked_dependency_graph_hash']:
            if metadata[name]!=manifest[name]:raise ValueError('Candidate metadata/source '+name+' mismatch')
        if metadata['source_bundle_sha256']!=source['sha256']:raise ValueError('Candidate must name its actually delivered source')
        if sha(notices)!=source_files['ThirdPartyNotices.txt']:raise ValueError('Shipped notices differ from the matching source bundle')
        if not report.get('release_license_ready') or not report.get('notice_obligations_satisfied') or report.get('notice_gap_count')!=0:
            raise ValueError('License distribution requirements are not fulfilled')
        if report['locked_dependency_graph_hash']!=manifest['locked_dependency_graph_hash']:raise ValueError('License report graph mismatch')
    return {'classification':'unsigned-candidate','candidate_integrity_verified':True,'notices_verified':True,
            'corresponding_source_verified':True,'relink_instructions_verified':True,'unresolved_notice_cases':0,
            'release_ready':False,'source_commit':manifest['source_commit'],'source_bundle_sha256':source['sha256'],
            'source_tree_sha256':manifest['source_tree_sha256'],'locked_dependency_graph_hash':manifest['locked_dependency_graph_hash']}


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('manifest',type=Path);parser.add_argument('--directory',type=Path)
    args=parser.parse_args();print(json.dumps(verify(args.manifest,args.directory),indent=2))
