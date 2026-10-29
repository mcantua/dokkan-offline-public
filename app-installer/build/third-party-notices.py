#!/usr/bin/env python3
"""Collect available third-party copyright/license texts from the locked iOS Cargo graph.

Missing license files are reported explicitly; this tool is not a legal-compatibility
validator. It never downloads dependencies or guesses missing copyright notices.
"""
import argparse
import sys
sys.dont_write_bytecode = True
from licensing import load_graph, load_graph_union, assess
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
CORE = ROOT/'app-installer/core/Cargo.toml'
PATTERNS = ('LICENSE*', 'LICENCE*', 'COPYING*', 'NOTICE*', 'COPYRIGHT*')


def source_label(package):
    source = package.get('source')
    if source and source.startswith('registry+'):
        return f'https://crates.io/crates/{package["name"]}/{package["version"]}'
    if source:
        # Cargo git source is identity/provenance, never an authenticated URL in a notice.
        return re.sub(r'(?<=://)[^/@]+@', '[redacted]@', source).split('?', 1)[0]
    manifest = Path(package['manifest_path']).resolve()
    try: return 'repository path: ' + str(manifest.parent.relative_to(ROOT))
    except ValueError: return 'local path dependency: ' + package['name']


def find_texts(package):
    base = Path(package['manifest_path']).resolve().parent
    files = {p for pattern in PATTERNS for p in base.glob(pattern) if p.is_file()}
    # Some source crates place the exact notices in a dedicated licenses directory.
    for sub in ('license', 'licenses', 'LICENSES'):
        directory = base/sub
        if directory.is_dir():
            files.update(p for p in directory.rglob('*') if p.is_file())
    # openssl-src wraps a second, statically linked distribution. Its actual
    # OpenSSL terms must travel with the wrapper's Rust-crate license texts.
    if package['name']=='openssl-src':
        upstream=base/'openssl'
        files.update(p for pattern in PATTERNS for p in upstream.glob(pattern) if p.is_file())
    if package.get('license_file'):
        path = base/package['license_file']
        try:
            path.resolve().relative_to(base)
            if path.is_file(): files.add(path)
        except ValueError:
            pass  # Do not follow manifest paths out of this dependency's source directory.
    texts = []
    for path in sorted(files):
        try:
            resolved = path.resolve()
            resolved.relative_to(base)
            content = path.read_bytes()
            if len(content) > 2 * 1024 * 1024 or b'\x00' in content:
                continue
            texts.append((str(path.relative_to(base)), content.decode('utf-8', errors='replace')))
        except (OSError, ValueError):
            continue
    return texts


def generate(output, report, require_licenses=False, manifest_path=CORE, targets=('aarch64-apple-ios',)):
    manifest_path=Path(manifest_path).resolve();manifest_path.relative_to(ROOT)
    if len(targets)==1:
        metadata,selected,checksums,graph_hash=load_graph(targets[0],manifest_path);target_graphs={targets[0]:graph_hash}
    else:
        metadata,selected,checksums,graph_hash,target_graphs=load_graph_union(manifest_path,targets)
    packages = {p['id']: p for p in selected}
    root_id = metadata['resolve']['root']
    needed = set(packages)
    sections = ['Third-party source notices — App Installer\n',
                'Generated from the locked Cargo dependency graph for '+', '.join(targets)+'.\n'
                'Available upstream notice texts follow verbatim after each package heading.\n'
                'SPDX declarations are upstream metadata, not a compatibility certification.\n'
                'A license filename is not required when a published grant and its actual preservation obligations are fulfilled.\n'
                'Any unresolved grant/terms/notice obligation is reported and blocks compliance-required builds.\n'
                'App Installer and the RP helper are AGPL-3.0-only; the full license is LICENSE.txt in the app bundle and app-installer/LICENSE in the bootstrap kit/source distribution.\n']
    missing = []
    declarations = []
    distribution_requirements = []
    for item in sorted(needed - {root_id}, key=lambda i: (packages[i]['name'], packages[i]['version'])):
        package = packages[item]
        spdx = package.get('license') or 'NOT DECLARED'
        source = source_label(package)
        texts = find_texts(package)
        assessment = assess(package,texts,checksums.get((package['name'],package['version'])))
        evidence = assessment['evidence']
        for filename,content,record in assessment['supplements']:
            texts.append(('supplement/'+filename,'Supplement provenance: '+record['url']+'\nSHA-256: '+record['sha256']+'\n\n'+content))
        for requirement in assessment['distribution_requirements']:
            distribution_requirements.append({'package':package['name'],'version':package['version'],'requirement':requirement})
        label = f'{package["name"]} {package["version"]}'
        sections.extend(['\n' + '=' * 78 + '\n', label + '\n', 'Declared license: ' + spdx + '\n', 'Distribution selection: '+assessment['selected_license']+'\n', 'Source: ' + source + '\n', 'Package authors (upstream metadata, not an invented ownership claim): '+', '.join(package.get('authors',[]))+'\n'])
        declarations.append({'name':package['name'],'version':package['version'],'license':spdx,'source':source,
                             'notice_files':[name for name,_ in texts],'selected_license':assessment['selected_license'],
                             'published_checksum':assessment['published_checksum'],'distribution_requirements':assessment['distribution_requirements'],
                             'recipient_modified_local_source':assessment['recipient_modified_local_source']})
        if assessment['gaps']:
            gap={'name':package['name'],'version':package['version'],'license':spdx,'source':source,
                 'reason':'; '.join(assessment['gaps'])}
            missing.append(gap)
            sections.append('UNRESOLVED OBLIGATION: '+gap['reason']+'\n')
        for name, text in texts:
            sections.extend(['\n--- ' + name + ' ---\n', text, '\n'])
        if spdx == 'NOT DECLARED' and not any(g['name']==package['name'] and g['version']==package['version'] for g in missing):
            missing.append({'name':package['name'],'version':package['version'],'license':spdx,'source':source,
                            'reason':'No SPDX license declaration in Cargo metadata; review attached notice text.'})
    runtime_root=ROOT/'downloads/license-notices/rust-runtime-1.99.1'
    runtime_info=json.loads((runtime_root/'SOURCE.json').read_text())
    runtime_files=[]
    sections.append('\n'+'='*78+'\nRust standard library/runtime1.99.1 — selected Apache-2.0 alternative\n')
    for entry in runtime_info['notice_files']:
        data=(runtime_root/entry['path']).read_bytes()
        if hashlib.sha256(data).hexdigest()!=entry['sha256']:raise ValueError('Rust runtime notice integrity mismatch')
        runtime_files.append(entry['path']);sections.extend(['\n--- '+entry['path']+' ---\n',data.decode(errors='replace'),'\n'])
    if not {'LICENSE-APACHE','LICENSE-MIT','COPYRIGHT'}<=set(runtime_files):raise ValueError('Incomplete Rust runtime notices')
    summary={'schema_version':2,'target':targets[0] if len(targets)==1 else 'universal-macos','targets':list(targets),'target_graph_hashes':target_graphs,'manifest':str(Path(manifest_path).relative_to(ROOT)),'locked_dependency_graph_hash':graph_hash,
             'rust_runtime':{'version':'1.99.1','selected_license':'Apache-2.0','notice_files':runtime_files,'source_archive_sha256':runtime_info['source_archive_sha256']},
             'notice_obligations_satisfied':not missing,'distribution_requirements':distribution_requirements,
             'distribution_requirements_satisfied':not distribution_requirements,'dependency_count':len(declarations),'notice_gap_count':len(missing),
             'missing_notices':missing,'packages':declarations,
             'scope':'Exact locked target-specific Cargo graph. Distribution readiness additionally requires the matching corresponding-source/relink artifact; generic license text alone does not satisfy that delivery obligation.'}
    output.write_text(''.join(sections))
    report.write_text(json.dumps(summary, indent=2)+'\n')
    print(f'Collected notices for {len(declarations)} Cargo packages; {len(missing)} unresolved license obligations; {len(distribution_requirements)} source/relink delivery conditions.')
    if require_licenses and missing: raise ValueError('Release license gate: unresolved grant/terms/notice obligations')


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output',type=Path)
    parser.add_argument('report',type=Path)
    parser.add_argument('--require-licenses',action='store_true',help='fail unresolved grant/terms/notice obligations; source delivery is separately verified')
    parser.add_argument('--manifest-path',type=Path,default=CORE)
    parser.add_argument('--target',action='append',dest='targets')
    args=parser.parse_args()
    generate(args.output,args.report,args.require_licenses,args.manifest_path,args.targets or ('aarch64-apple-ios',))
