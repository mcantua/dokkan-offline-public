"""Auditable license-policy checks for the exact locked Cargo graph.

This implements explicit distribution requirements. It does not invent copyright
notices, infer ownership from authors, or equate a missing filename with no grant.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tomllib

ROOT = Path(__file__).resolve().parents[2]
ALLOWED = {'0BSD','Apache-2.0','MIT','ISC','BSD-2-Clause','BSD-3-Clause','Unicode-3.0',
           'Unicode-DFS-2016','CDLA-Permissive-2.0','Zlib','Unlicense','LGPL-3.0-or-later'}
ORDER = ['0BSD','Apache-2.0','ISC','MIT','BSD-2-Clause','BSD-3-Clause','Zlib','Unlicense',
         'Unicode-3.0','Unicode-DFS-2016','CDLA-Permissive-2.0','LGPL-3.0-or-later']


def sha(data): return hashlib.sha256(data).hexdigest()


def load_graph(target='aarch64-apple-ios',manifest_path=None):
    cargo=Path(os.environ.get('CARGO_HOME',str(ROOT/'downloads/rust-toolchain/cargo')))/'bin/cargo'
    manifest_path=Path(manifest_path or ROOT/'app-installer/core/Cargo.toml').resolve();manifest_path.relative_to(ROOT)
    graph=json.loads(subprocess.check_output([str(cargo),'metadata','--manifest-path',str(manifest_path),
        '--format-version','1','--locked','--offline','--filter-platform',target],cwd=ROOT))
    packages={p['id']:p for p in graph['packages']};nodes={n['id']:n for n in graph['resolve']['nodes']}
    required=set();queue=[graph['resolve']['root']]
    while queue:
        item=queue.pop()
        if item in required:continue
        required.add(item);queue.extend(d['pkg'] for d in nodes[item]['deps'])
    selected=[packages[i] for i in sorted(required)]
    lock=tomllib.loads((manifest_path.parent/'Cargo.lock').read_text())
    checksums={(p['name'],p['version']):p.get('checksum') for p in lock['package']}
    identities=[{'name':p['name'],'version':p['version'],'source':p.get('source'),
                 'checksum':checksums.get((p['name'],p['version']))} for p in selected]
    graph_hash=sha(json.dumps(sorted(identities,key=lambda x:(x['name'],x['version'],x['source'] or '')),
                              sort_keys=True,separators=(',',':')).encode())
    return graph,selected,checksums,graph_hash


def load_graph_union(manifest_path,targets):
    packages={};checksums={};graphs={};metadata=None
    for target in targets:
        metadata,selected,locked,graph_hash=load_graph(target,manifest_path)
        packages.update({package['id']:package for package in selected});graphs[target]=graph_hash
        for identity,checksum in locked.items():
            if identity in checksums and checksums[identity]!=checksum:raise ValueError('Conflicting immutable package checksums')
            checksums[identity]=checksum
    if metadata is None:raise ValueError('At least one actual compilation target is required')
    combined=sha(json.dumps(graphs,sort_keys=True,separators=(',',':')).encode())
    return metadata,[packages[key] for key in sorted(packages)],checksums,combined,graphs


def clauses(expression):
    """Expand the small SPDX AND/OR grammar; legacy Cargo slash denotes an alternative."""
    tokens=re.findall(r'\(|\)|\bAND\b|\bOR\b|[A-Za-z0-9.+-]+',expression.replace('/',' OR '))
    index=0
    def atom():
        nonlocal index
        if index>=len(tokens):raise ValueError('Incomplete SPDX expression')
        token=tokens[index];index+=1
        if token=='(':
            value=either()
            if index>=len(tokens) or tokens[index]!=')':raise ValueError('Unbalanced SPDX expression')
            index+=1;return value
        if token in {'AND','OR',')'}:raise ValueError('Invalid SPDX expression')
        return [{token}]
    def both():
        nonlocal index
        value=atom()
        while index<len(tokens) and tokens[index]=='AND':
            index+=1;right=atom();value=[a|b for a in value for b in right]
        return value
    def either():
        nonlocal index
        value=both()
        while index<len(tokens) and tokens[index]=='OR':index+=1;value+=both()
        return value
    result=either()
    if index!=len(tokens):raise ValueError('Unsupported SPDX expression')
    return result


def covered(identifier,text):
    value=' '.join(text.lower().replace('’',"'").split())
    markers={
      'Apache-2.0':['apache license','version 2.0','grant of copyright license','limitation of liability'],
      'MIT':['permission is hereby granted, free of charge','the software is provided'],
      'ISC':['permission to use, copy, modify','the software is provided'],
      'BSD-2-Clause':['redistribution and use in source and binary forms','redistributions in binary form must reproduce'],
      'BSD-3-Clause':['redistribution and use in source and binary forms','redistributions in binary form must reproduce','neither'],
      '0BSD':['permission to use, copy, modify','for any purpose with or without fee'],
      'Unicode-3.0':['unicode license v3','permission is hereby granted'],
      'Unicode-DFS-2016':['unicode, inc. license agreement','data files','permission is hereby granted'],
      'CDLA-Permissive-2.0':['community data license agreement','permissive','2.0'],
      'Zlib':['origin of this software must not be misrepresented','altered source versions'],
      'Unlicense':['free and unencumbered software released into the public domain','anyone is free to copy'],
      'LGPL-3.0-or-later':['gnu lesser general public license','version 3','gnu general public license','conveying modified source versions'],
    }
    return identifier in markers and all(marker in value for marker in markers[identifier])


def verified_supplement(package):
    base=ROOT/'downloads/license-notices'/f'{package["name"]}-{package["version"]}'
    source=base/'SOURCE.json'
    if not source.is_file():return None,[]
    info=json.loads(source.read_text());records=[]
    if (info.get('crate'),info.get('version'))!=(package['name'],package['version']):raise ValueError('Supplement identity mismatch')
    for item in info.get('notice_files',[]):
        path=(base/item['path']).resolve();path.relative_to(base.resolve());data=path.read_bytes()
        if sha(data)!=item['sha256']:raise ValueError('Supplement content hash mismatch: '+item['path'])
        records.append((item['path'],data.decode(errors='replace'),item))
    for obligation in info.get('obligations',[]):
        for name in obligation.get('evidence',[]):
            path=(base/name).resolve();path.relative_to(ROOT.resolve())
            if not path.is_file():raise ValueError('Missing obligation evidence: '+name)
    return info,records


def assess(package,texts,checksum):
    declared=package.get('license') or ''
    gaps=[];info,supplements=verified_supplement(package)
    full='\n'.join(t for _,t in texts)+'\n'+'\n'.join(t for _,t,_ in supplements)
    allowed_clauses=clauses(declared) if declared else []
    requirements=[];selected=None
    if info and info.get('selected_license'):
        selected=clauses(info['selected_license'])[0]
        additional=set(info.get('additional_licenses',[]))
        grant_selected=selected-additional
        if 'LGPL-3.0-or-later' in grant_selected and 'LGPL-2.1-or-later' in declared:
            grant_selected=(grant_selected-{'LGPL-3.0-or-later'})|{'LGPL-2.1-or-later'}
        if not any(choice<=grant_selected for choice in allowed_clauses):gaps.append('Selected license is not an alternative authorized by published declaration')
        # Registry source must match immutable publication. A recipient local replacement is allowed.
        if package.get('source') and info.get('package_checksum')!=checksum:gaps.append('Published package checksum changed; license evidence must be audited for this version')
        for obligation in info.get('obligations',[]):
            if obligation.get('status')!='satisfied':
                conditional=(obligation.get('status')=='conditional' and obligation.get('id')=='LGPL3-combined-work-source-relink' and info.get('required_distribution_artifacts')==['corresponding-source/relink-bundle'])
                if not conditional:gaps.append('Unfulfilled obligation: '+obligation.get('id','unknown'))
        requirements=list(info.get('required_distribution_artifacts',[]))
        if not info.get('release_requirements_satisfied') and not requirements:gaps.append('Supplement obligations remain unresolved')
    else:
        candidates=[c for c in allowed_clauses if c<=ALLOWED and all(covered(i,full) for i in c)]
        if candidates:selected=min(candidates,key=lambda c:(sum(ORDER.index(i) for i in c),len(c)))
    if not selected:gaps.append('No authorized compatible branch has complete required license text');selected=set()
    for identifier in selected:
        if identifier not in ALLOWED:gaps.append('Unreviewed license identifier: '+identifier)
        elif not covered(identifier,full):gaps.append('Required license terms missing: '+identifier)
    if package.get('source') and package['source'].startswith('registry+') and not checksum:
        gaps.append('Registry package has no pinned checksum')
    if info and info.get('source_audit'):
        base=ROOT/'downloads/license-notices'/f'{package["name"]}-{package["version"]}'
        audit=json.loads((base/info['source_audit']).read_text())
        if package.get('source') and audit.get('archive_sha256')!=checksum:gaps.append('Source notice audit does not match pinned publication')
    return {'selected_license':' AND '.join(sorted(selected)),'gaps':gaps,'distribution_requirements':requirements,
            'evidence':info,'supplements':supplements,'published_checksum':checksum,
            'recipient_modified_local_source':bool(not package.get('source') and package['name']=='apple-codesign-quick')}
