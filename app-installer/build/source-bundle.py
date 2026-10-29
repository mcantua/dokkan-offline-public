#!/usr/bin/env python3
"""Build and verify the actual corresponding-source/relink distribution artifact."""
import argparse
import hashlib
import io
import importlib.util
import struct
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import tarfile
import tempfile
import tomllib
import urllib.request
sys.dont_write_bytecode=True
from licensing import ROOT, load_graph, sha

BUNDLE_ROOT='AppInstaller-source'
MANIFEST='SourceBundleManifest.json'
REQUIRED_COMPONENTS=['corresponding-application-source','complete-library-source','exact-locked-transitive-source',
    'modified-path-dependency-source','build-relink-recipes','recipient-installation-information','complete-licenses-and-notices']


def safe_relative(path):
    value=PurePosixPath(path)
    if value.is_absolute() or '..' in value.parts or '\\' in str(value):raise ValueError('Unsafe source bundle path')
    return str(value)


def copy_sources(base,dest,exclude=()):
    base=base.resolve();base.relative_to(ROOT)
    for path in sorted(base.rglob('*')):
        rel=path.relative_to(base)
        if any(part in {'.git','target','work','__pycache__'} for part in rel.parts):continue
        if any(str(rel)==name or str(rel).startswith(name+'/') for name in exclude):continue
        if path.is_symlink():raise ValueError('Source symlink must be materialized before distribution: '+str(path.relative_to(ROOT)))
        if not path.is_file():continue
        if path.name=='.env' or path.suffix in {'.p12','.p8','.key','.mobileprovision','.mobiledevicepairing'}:
            raise ValueError('Private credential-shaped file cannot enter application/path source bundle')
        out=dest/rel;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,out)


def file_manifest(base):
    return [{'path':str(p.relative_to(base)),'bytes':p.stat().st_size,'sha256':sha(p.read_bytes())}
            for p in sorted(base.rglob('*')) if p.is_file() and p.name!=MANIFEST]


def fingerprint_recipe():
    spec=importlib.util.spec_from_file_location('source_fingerprint',ROOT/'app-installer/build/source-fingerprint.py')
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module


def fingerprint_paths(paths,path_sources):
    recipe=fingerprint_recipe()
    prefixes=[str(p.relative_to(ROOT)) for p in recipe.SOURCE_ROOTS]
    prefixes.extend(safe_relative(p['path']) for p in path_sources)
    explicit={'app-installer/LICENSE','app-installer/licensing-signing.md'}
    selected=[]
    for name in paths:
        path=PurePosixPath(safe_relative(name))
        if any(part in {'target','work','__pycache__'} for part in path.parts):continue
        if name in explicit or (any(name==prefix or name.startswith(prefix+'/') for prefix in prefixes)
             and (path.suffix in recipe.SUFFIXES or path.name.startswith(('LICENSE','LICENCE','COPYING','NOTICE','COPYRIGHT')))):
            selected.append(name)
    return sorted(selected)


def payload_fingerprint(payload,inputs):
    h=hashlib.sha256(b'AppInstaller source fingerprint v1\n')
    for name in inputs:
        label=name.encode();data=payload[name]
        h.update(struct.pack('>Q',len(label)));h.update(label)
        h.update(struct.pack('>Q',len(data)));h.update(data)
    return h.hexdigest()


def published_files(data,name,version,restore_missing_metadata=None):
    files={};total=0
    prefix=name+'-'+version+'/'
    with tarfile.open(fileobj=io.BytesIO(data),mode='r|gz') as archive:
        for member in archive:
            if member.isdir():continue
            total+=member.size
            if not member.isfile() or member.size<0 or member.size>256*1024*1024 or total>512*1024*1024 or len(files)>=250000:
                raise ValueError('Published crate source structure/size limit exceeded')
            if not member.name.startswith(prefix):raise ValueError('Published crate root identity mismatch')
            relative=safe_relative(member.name[len(prefix):])
            if relative in files:raise ValueError('Duplicate published crate file')
            content=archive.extractfile(member).read(member.size+1)
            if len(content)!=member.size:raise ValueError('Truncated published crate source file')
            files[relative]=sha(content)
            # Cargo vendor deliberately excludes these Git-only metadata files.
            # Restore their exact published bytes for full-source delivery rather
            # than weakening the immutable-publication comparison below. Keep
            # the Cargo-generated checksum map unchanged: it describes vendor's
            # build inputs, while this verifier also checks all original files.
            if restore_missing_metadata is not None and PurePosixPath(relative).name in {'.gitignore','.gitattributes'}:
                destination=restore_missing_metadata/relative
                if not destination.exists():
                    destination.parent.mkdir(parents=True,exist_ok=True)
                    destination.write_bytes(content)
    return files


def create(output,notice_text,notice_report):
    graph,packages,checksums,graph_hash=load_graph()
    report=json.loads(notice_report.read_text())
    if not report.get('notice_obligations_satisfied') or report.get('notice_gap_count')!=0:
        raise ValueError('Source/relink distribution cannot clear unresolved license obligations')
    if report['locked_dependency_graph_hash']!=graph_hash:raise ValueError('Notice graph does not match locked source')
    commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
    fingerprint=subprocess.check_output([sys.executable,str(ROOT/'app-installer/build/source-fingerprint.py')],cwd=ROOT,text=True).strip()
    work=ROOT/'app-installer/build/work';work.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='source-bundle-',dir=work) as temporary:
        stage=Path(temporary)/BUNDLE_ROOT;stage.mkdir()
        shutil.copy2(ROOT/'.gitignore',stage/'.gitignore')
        copy_sources(ROOT/'app-installer',stage/'app-installer',exclude=('device/private',))
        # Generated source notices replace any stale review artifacts; no IPA/tool/cache enters source closure.
        for file in list((stage/'app-installer').rglob('*')):
            if file.is_file() and file.suffix in {'.ipa','.a','.xcresult','.tar','.xz'}:file.unlink()
        for name in ['README.md','STATUS.md','WORKLOG.md','TODO.md']:
            (stage/'app-installer'/name).unlink(missing_ok=True)
        copy_sources(ROOT/'downloads/license-notices',stage/'downloads/license-notices')
        # Public Apple trust anchors are include_bytes! inputs, not signing credentials.
        copy_sources(ROOT/'downloads/apple-trust',stage/'downloads/apple-trust')
        for component in ['rust-toolchain','llvm','apple-sdk','cloud-ui-tools']:
            provenance=ROOT/'downloads'/component/'SOURCE.md'
            if provenance.is_file():
                out=stage/'downloads'/component/'SOURCE.md';out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(provenance,out)
        path_sources=[]
        for package in packages:
            if package.get('source'):continue
            base=Path(package['manifest_path']).resolve().parent;base.relative_to(ROOT)
            relative=str(base.relative_to(ROOT))
            if not (stage/relative/'Cargo.toml').is_file():copy_sources(base,stage/relative)
            path_sources.append({'name':package['name'],'version':package['version'],'path':relative})
        cargo=Path(os.environ.get('CARGO_HOME',str(ROOT/'downloads/rust-toolchain/cargo')))/'bin/cargo'
        # Materialize exact complete Cargo sources, including host/alternate-platform build dependencies.
        vendor=stage/'vendor'
        vendor_log=Path(temporary)/'vendor.log'
        with vendor_log.open('wb') as log:
            result=subprocess.run([str(cargo),'vendor','--locked','--versioned-dirs','--manifest-path',str(ROOT/'app-installer/core/Cargo.toml'),str(vendor)],cwd=ROOT,stdout=subprocess.DEVNULL,stderr=log)
        if result.returncode:
            raise ValueError('Locked Cargo source vendoring failed: '+vendor_log.read_text(errors='replace')[-2000:])
        config=stage/'.cargo/config.toml';config.parent.mkdir()
        config.write_text('[source.crates-io]\nreplace-with = "vendored-sources"\n\n[source.vendored-sources]\ndirectory = "vendor"\n')
        registry_sources=[]
        cache=Path(os.environ.get('CARGO_HOME',str(ROOT/'downloads/rust-toolchain/cargo')))/'registry/cache'
        for directory in sorted(vendor.iterdir()):
            if not directory.is_dir():continue
            manifest=tomllib.loads((directory/'Cargo.toml').read_text())['package']
            checksum=json.loads((directory/'.cargo-checksum.json').read_text())['package']
            record={'name':manifest['name'],'version':manifest['version'],'checksum':checksum,'path':str(directory.relative_to(stage))}
            if checksum:
                archives=list(cache.glob(f'*/{manifest["name"]}-{manifest["version"]}.crate'))
                archive=next((a for a in archives if sha(a.read_bytes())==checksum),None)
                if archive is None:raise ValueError('Exact published crate archive missing for source/test audit: '+manifest['name'])
                published_files(archive.read_bytes(),manifest['name'],manifest['version'],restore_missing_metadata=directory)
                out=stage/'downloads/rust-toolchain/cargo/registry/cache/bundled-archives'/archive.name
                out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(archive,out);record['archive_path']=str(out.relative_to(stage))
            registry_sources.append(record)
        runtime=ROOT/'downloads/license-notices/rust-runtime-1.99.1/SOURCE.json'
        runtime_info=json.loads(runtime.read_text());runtime_cache=Path(os.environ.get('CARGO_HOME',str(ROOT/'downloads/rust-toolchain/cargo'))).parent/'runtime-source'
        runtime_cache.mkdir(parents=True,exist_ok=True);runtime_archive=runtime_cache/'rust-src-1.99.1.tar.xz'
        if (ROOT/'runtime/rust-src-1.99.1.tar.xz').is_file():runtime_archive=ROOT/'runtime/rust-src-1.99.1.tar.xz'
        if not runtime_archive.is_file():
            request=urllib.request.Request(runtime_info['source_archive_url'],headers={'User-Agent':'AppInstaller-source-relink'})
            with urllib.request.urlopen(request) as response,runtime_archive.open('wb') as stream:shutil.copyfileobj(response,stream)
        if sha(runtime_archive.read_bytes())!=runtime_info['source_archive_sha256']:raise ValueError('Rust runtime source checksum mismatch')
        runtime_dest=stage/'runtime/rust-src-1.99.1.tar.xz';runtime_dest.parent.mkdir();shutil.copy2(runtime_archive,runtime_dest)
        (stage/'ThirdPartyNotices.txt').write_bytes(notice_text.read_bytes())
        (stage/'ThirdPartyNoticeReport.json').write_bytes(notice_report.read_bytes())
        (stage/'README.md').write_text('''# Matching App Installer source/relink distribution

This artifact accompanies the unsigned IPA candidates. Application source is AGPL-3.0-only; the corresponding LGPL signing library and all exact Cargo sources/build recipes are included. Preserve each component’s licenses and notices.

The archive intentionally omits the original `.git` history. Before using build scripts that record Git metadata, initialize your own local repository from this directory: `git init`, `git add .`, then `git -c user.name="Source recipient" -c user.email="recipient@localhost" commit -m "Imported corresponding source"`. The supplied root `.gitignore` excludes tools, caches and private material. After modifying a library or recipe, commit your changed source locally before packaging. These are your own commits; no original GitHub account, remote, token or original commit hash is needed.

Run Cargo commands from this directory. `.cargo/config.toml` selects the provided offline `vendor/` tree. Path dependencies retain their repository-relative layout. Use `cargo tree --offline -i apple-codesign-quick` to identify the signing library actually selected.

Read `app-installer/licensing-signing.md` for LGPL replacement, relinking and installation information. You may modify the library, point `[patch.crates-io]` to your modified source, update the lock offline and rebuild/relink the application. There is no original-library-only hash or runtime restriction preventing this. Provide matching modified source and notices if redistributing your modification. Reverse engineering for debugging modifications to the LGPL component is not prohibited by this project.

Build tools are acquired by the supplied pinned Linux recipe or a compatible genuine Xcode toolchain. Apple SDK/compiler binaries and signing secrets are not redistributed. The exact Rust runtime source archive and its notices are included in runtime/. Recipients sign/re-sign with their own lawful identity; no project authorization token or original private key is required.

See SourceBundleManifest.json for exact source/file/lock/graph bindings. The external candidate manifest and IPA bind this archive’s SHA-256; no self-referential archive hash is claimed inside this archive. Unsigned candidates are not final release evidence and do not claim physical phone verification.
''')
        manifest={'schema_version':1,'test_fixture':False,'source_commit':commit,
          'source_has_uncommitted_changes':bool(subprocess.check_output(['git','status','--porcelain','--untracked-files=normal','--','app-installer','downloads','.gitignore',':!app-installer/build/work',':!app-installer/cloud-ui/work'],cwd=ROOT)),'source_tree_sha256':fingerprint,
          'locked_dependency_graph_hash':graph_hash,'cargo_lock_sha256':sha((ROOT/'app-installer/core/Cargo.lock').read_bytes()),
          'required_components':REQUIRED_COMPONENTS,'path_sources':path_sources,'registry_sources':registry_sources,
          'runtime_source':{'path':str(runtime_dest.relative_to(stage)),'sha256':runtime_info['source_archive_sha256']},
          'notice_obligations_satisfied':True,'notice_gap_count':0,'recipient_library_modifications_permitted':True,
          'relink_instructions':'app-installer/licensing-signing.md','files':file_manifest(stage)}
        manifest['source_fingerprint_inputs']=[str(p.relative_to(ROOT)) for p in fingerprint_recipe().source_files()]
        if set(manifest['source_fingerprint_inputs'])-set(f['path'] for f in manifest['files']):raise ValueError('Compiled source fingerprint input missing from delivery')
        manifest_bytes=(json.dumps(manifest,indent=2)+'\n').encode()
        (stage/MANIFEST).write_bytes(manifest_bytes)
        output.parent.mkdir(parents=True,exist_ok=True);temporary_archive=Path(temporary)/'bundle.tar.xz'
        with tarfile.open(temporary_archive,'w:xz',preset=1) as archive:
            first=tarfile.TarInfo(BUNDLE_ROOT+'/'+MANIFEST);first.size=len(manifest_bytes);first.mode=0o644;first.mtime=0;archive.addfile(first,io.BytesIO(manifest_bytes))
            for entry in manifest['files']:
                archive.add(stage/entry['path'],arcname=BUNDLE_ROOT+'/'+entry['path'],recursive=False)
        verify(temporary_archive,expected_fingerprint=fingerprint,expected_graph=graph_hash)
        after=subprocess.check_output([sys.executable,str(ROOT/'app-installer/build/source-fingerprint.py')],cwd=ROOT,text=True).strip()
        if after!=fingerprint:raise ValueError('Source changed while creating corresponding-source bundle')
        os.replace(temporary_archive,output)
    try:work.rmdir()
    except OSError:pass
    return {'file':output.name,'sha256':sha(output.read_bytes()),'bytes':output.stat().st_size,
            'source_commit':commit,'source_tree_sha256':fingerprint,'locked_dependency_graph_hash':graph_hash,
            'corresponding_source_verified':True,'relink_instructions_verified':True}


def verify(archive_path,expected_fingerprint=None,expected_graph=None,allow_test_fixture=False):
    seen=set();critical={};manifest=None;expected={};actual={};fingerprint_bytes={};total=0;fp_total=0;critical_total=0;count=0;published_sources={};published_count=0
    with tarfile.open(archive_path,'r|xz') as archive:
        for member in archive:
            count+=1;total+=member.size
            if count>250000 or member.size<0 or member.size>256*1024*1024 or total>4*1024*1024*1024:
                raise ValueError('Source archive count/member/total size limit exceeded')
            if not member.isfile():raise ValueError('Only regular source files are permitted in source archive')
            name=safe_relative(member.name)
            if not name.startswith(BUNDLE_ROOT+'/'):raise ValueError('Unexpected source root')
            relative=name[len(BUNDLE_ROOT)+1:]
            if relative in seen:raise ValueError('Duplicate corresponding-source member')
            seen.add(relative)
            if manifest is None:
                if relative!=MANIFEST:raise ValueError('Source manifest must be first')
                if member.size>32*1024*1024:raise ValueError('Source manifest size limit exceeded')
                data=archive.extractfile(member).read(member.size+1)
                manifest=json.loads(data)
                if manifest.get('test_fixture') and not allow_test_fixture:raise ValueError('Test-only source fixture is not distribution evidence')
                expected={f['path']:f for f in manifest['files']}
                if len(expected)!=len(manifest['files']) or len(expected)>250000:raise ValueError('Duplicate/excessive source manifest paths')
                for entry in expected.values():
                    safe_relative(entry['path'])
                    if not isinstance(entry.get('bytes'),int) or not 0<=entry['bytes']<=256*1024*1024:raise ValueError('Invalid source manifest member size')
                continue
            if relative not in expected:raise ValueError('Unlisted source bundle member')
            entry=expected[relative]
            if member.size!=entry['bytes']:raise ValueError('Listed source member size mismatch before read')
            if relative in manifest.get('source_fingerprint_inputs',[]):
                fp_total+=member.size
                if fp_total>256*1024*1024:raise ValueError('Source fingerprint payload size limit exceeded')
            is_critical=(relative=='downloads/license-notices/rust-runtime-1.99.1/SOURCE.json' or relative.endswith(('Cargo.toml','Cargo.lock','.cargo-checksum.json')) or relative in {manifest.get('relink_instructions'),'.cargo/config.toml'})
            if is_critical:
                critical_total+=member.size
                if critical_total>128*1024*1024:raise ValueError('Retained source metadata size limit exceeded')
            data=archive.extractfile(member).read(member.size+1)
            if sha(data)!=entry['sha256'] or len(data)!=entry['bytes']:raise ValueError('Source file checksum/size mismatch')
            actual[relative]=sha(data)
            if relative in manifest.get('source_fingerprint_inputs',[]):fingerprint_bytes[relative]=data
            package=next((p for p in manifest.get('registry_sources',[]) if p.get('archive_path')==relative),None)
            if package:
                original=published_files(data,package['name'],package['version']);published_count+=len(original)
                if published_count>250000:raise ValueError('Published source file-count limit exceeded')
                published_sources[relative]=original
            if relative=='downloads/license-notices/rust-runtime-1.99.1/SOURCE.json':critical[relative]=data
            if relative.endswith(('Cargo.toml','Cargo.lock','.cargo-checksum.json')) or relative in {manifest.get('relink_instructions'),'.cargo/config.toml'}:
                critical[relative]=data
    if manifest is None or set(actual)!=set(expected):raise ValueError('Incomplete corresponding-source payload')
    inputs=manifest.get('source_fingerprint_inputs',[])
    if inputs!=fingerprint_paths(expected.keys(),manifest.get('path_sources',[])):raise ValueError('Source fingerprint input closure differs from supported recipe')
    if payload_fingerprint(fingerprint_bytes,inputs)!=manifest['source_tree_sha256']:raise ValueError('Delivered source bytes do not match claimed source fingerprint')
    if expected_fingerprint and manifest['source_tree_sha256']!=expected_fingerprint:raise ValueError('Source fingerprint mismatch')
    if expected_graph and manifest['locked_dependency_graph_hash']!=expected_graph:raise ValueError('Locked dependency graph mismatch')
    if not manifest.get('recipient_library_modifications_permitted'):raise ValueError('Recipient library replacement must be permitted')
    if not set(REQUIRED_COMPONENTS)<=set(manifest.get('required_components',[])):raise ValueError('Source/relink delivery component missing')
    lock_path='app-installer/core/Cargo.lock';lock=tomllib.loads(critical[lock_path].decode())
    if sha(critical[lock_path])!=manifest['cargo_lock_sha256']:raise ValueError('Cargo.lock binding mismatch')
    required_paths={(p['name'],p['version']) for p in lock['package'] if not p.get('source')}
    delivered_paths={(p['name'],p['version']) for p in manifest.get('path_sources',[])}
    if not required_paths<=delivered_paths:raise ValueError('Locked application/path dependency source missing')
    required_registry={(p['name'],p['version'],p.get('checksum')) for p in lock['package'] if p.get('source','').startswith('registry+')}
    delivered_registry={(p['name'],p['version'],p['checksum']) for p in manifest['registry_sources']}
    if not required_registry<=delivered_registry:raise ValueError('Locked transitive registry source missing')
    for package in manifest['registry_sources']:
        base=safe_relative(package['path']);cargo=tomllib.loads(critical[base+'/Cargo.toml'].decode())['package']
        if (cargo['name'],cargo['version'])!=(package['name'],package['version']):raise ValueError('Vendored package identity mismatch')
        checksum=json.loads(critical[base+'/.cargo-checksum.json'])
        if checksum['package']!=package['checksum']:raise ValueError('Vendored publication checksum mismatch')
        if package.get('checksum') and actual.get(package.get('archive_path'))!=package['checksum']:raise ValueError('Published crate archive delivery mismatch')
        if package.get('checksum'):
            original=published_sources.get(package['archive_path'])
            if original is None:raise ValueError('Published source archive could not be inspected')
            for name,digest in original.items():
                if actual.get(base+'/'+name)!=digest:
                    difference='missing' if base+'/'+name not in actual else 'different bytes'
                    raise ValueError(f'Offline vendored source differs from delivered immutable publication: {package["name"]}@{package["version"]} {name!r} ({difference})')
        for name,digest in checksum['files'].items():
            if actual.get(base+'/'+safe_relative(name))!=digest:raise ValueError('Vendored source content differs from pinned publication')
    for package in manifest['path_sources']:
        base=safe_relative(package['path']);cargo=tomllib.loads(critical[base+'/Cargo.toml'].decode())['package']
        if (cargo['name'],cargo['version'])!=(package['name'],package['version']):raise ValueError('Modified path source identity mismatch')
    runtime=manifest['runtime_source']
    runtime_grant=json.loads(critical['downloads/license-notices/rust-runtime-1.99.1/SOURCE.json'])
    if runtime['sha256']!=runtime_grant['source_archive_sha256']:raise ValueError('Runtime archive does not match its pinned distribution provenance')
    if actual.get(runtime['path'])!=runtime['sha256']:raise ValueError('Exact Rust runtime source missing')
    instructions=critical.get(manifest['relink_instructions'],b'').decode().lower()
    if not instructions or 'relink' not in instructions or 'reverse' not in instructions:raise ValueError('Recipient relink/rights instructions missing')
    if '.cargo/config.toml' not in critical:raise ValueError('Offline vendor build configuration missing')
    return manifest


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);sub=parser.add_subparsers(dest='command',required=True)
    make=sub.add_parser('create');make.add_argument('--output',type=Path,required=True);make.add_argument('--notices',type=Path,required=True);make.add_argument('--notice-report',type=Path,required=True)
    check=sub.add_parser('verify');check.add_argument('archive',type=Path);check.add_argument('--source-fingerprint');check.add_argument('--graph-hash')
    args=parser.parse_args()
    if args.command=='create':print(json.dumps(create(args.output,args.notices,args.notice_report),indent=2))
    else:
        manifest=verify(args.archive,args.source_fingerprint,args.graph_hash);print(json.dumps({'corresponding_source_verified':True,'source_commit':manifest['source_commit'],'source_tree_sha256':manifest['source_tree_sha256'],'locked_dependency_graph_hash':manifest['locked_dependency_graph_hash']},indent=2))
