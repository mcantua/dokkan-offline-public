#!/usr/bin/env python3
"""Verify exact signing-dependency evidence; not a replacement for source-bundle gate."""
import hashlib,json,pathlib,sys,tomllib
root=pathlib.Path(__file__).resolve().parents[3]
lock=tomllib.loads((root/'app-installer/core/Cargo.lock').read_text())['package']
for name,version in [('apple-codesign-quick','0.1.0'),('isideload-p12-keystore','0.3.0-rc4'),('isideload-vfs','0.0.1')]:
    base=root/'downloads/license-notices'/f'{name}-{version}'
    evidence=json.loads((base/'SOURCE.json').read_text())
    packages=[p for p in lock if p['name']==name and p['version']==version]
    if len(packages)!=1 or packages[0].get('checksum')!=evidence['package_checksum']:
        raise SystemExit(f'{name}: locked publication checksum mismatch')
    manifest=tomllib.loads((base/'PUBLISHED-Cargo.toml.orig').read_text())['package']
    if manifest['name']!=name or manifest['version']!=version or manifest['license']!=evidence['declared_license']:
        raise SystemExit(f'{name}: published package/grant mismatch')
    for item in evidence['notice_files']:
        path=base/item['path']
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=item['sha256']:
            raise SystemExit(f'{name}: altered/missing evidence {item["path"]}')
    if name=='apple-codesign-quick':
        if evidence['declared_license']!='LGPL-2.1-or-later' or evidence['selected_license']!='LGPL-3.0-or-later':
            raise SystemExit('apple-codesign-quick: unsupported license election')
        files=json.loads((base/'SOURCE-FILES.json').read_text())
        if files['package_checksum']!=evidence['package_checksum']:raise SystemExit('library source checksum identity mismatch')
        expected={f['path'] for f in files['files']}
        actual={str(p.relative_to(base/'source')) for p in (base/'source').rglob('*') if p.is_file()}
        if expected!=actual:raise SystemExit('library corresponding-source file-set mismatch')
        for f in files['files']:
            if hashlib.sha256((base/'source'/f['path']).read_bytes()).hexdigest()!=f['sha256']:
                raise SystemExit('library corresponding-source content mismatch')
        requirements=json.loads((base/'DISTRIBUTION-REQUIREMENTS.json').read_text())
        if requirements.get('required_distribution_artifacts')!=['corresponding-source/relink-bundle']:
            raise SystemExit('missing mandatory LGPL source/relink artifact condition')
    else:
        if evidence['selected_license']!='Apache-2.0' or not evidence['release_requirements_satisfied']:
            raise SystemExit(f'{name}: Apache2 obligations not accounted for')
    print(f'{name} {version}: exact published grant, terms and source/attribution evidence verified')
print('Three supplements verified. Matching source/relink artifact delivery remains mandatory at the global release gate.')
