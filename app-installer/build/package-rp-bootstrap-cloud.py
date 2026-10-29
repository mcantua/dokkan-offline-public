#!/usr/bin/env python3
"""Package a source-bound, ad-hoc signed universal Mac RP helper in the cloud."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tomllib
# This module is also loaded by file path from device/ entrypoints. Resolve
# its own fixed sibling imports instead of depending on the caller directory.
sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from licensing import ROOT, load_graph_union, sha

HELPER=ROOT/'app-installer/device/secure-rp-bootstrap/Cargo.toml'
DIRECTORY=ROOT/'app-installer/cloud-ui/work/rp-bootstrap'
BINARY='app-installer-rp-bootstrap'
MANIFEST='RPBootstrapBuildManifest.json'
NOTICES='RPBootstrapThirdPartyNotices.txt'
REPORT='RPBootstrapThirdPartyNoticeReport.json'
TARGETS={'aarch64-apple-darwin':'arm64','x86_64-apple-darwin':'x86_64'}


def command(*args):
    try:
        return subprocess.check_output(list(map(str,args)),cwd=ROOT,text=True,stderr=subprocess.STDOUT).strip()
    except subprocess.CalledProcessError as error:
        # These commands inspect public toolchain/source/dependency metadata.
        # Preserve the actual bounded dependency cause rather than only its exit.
        print((error.output or '')[-6000:],file=sys.stderr)
        raise


def verify_outputs(directory,commit,fingerprint):
    directory=Path(directory).resolve();directory.relative_to(ROOT)
    manifest=json.loads((directory/MANIFEST).read_text())
    if (manifest.get('schema_version')!=1 or manifest.get('test_fixture') is not False
        or manifest.get('tool')!=BINARY or manifest.get('source_commit')!=commit
        or manifest.get('source_tree_sha256')!=fingerprint or manifest.get('build_succeeded') is not True
        or manifest.get('protocol_record_version')!=2 or manifest.get('architectures')!=['arm64','x86_64']
        or manifest.get('ad_hoc_signed') is not True or manifest.get('notarized') is not False
        or manifest.get('rustc_version','').split(' ')[0:2]!=['rustc','1.99.1']):
        raise ValueError('Universal RP helper source/platform/compiler receipt is incomplete or mismatched')
    expected={BINARY:manifest.get('binary'),NOTICES:manifest.get('notices'),REPORT:manifest.get('notice_report')}
    for filename,record in expected.items():
        path=directory/filename
        if (not isinstance(record,dict) or record.get('file')!=filename or path.is_symlink() or not path.is_file()
            or record.get('bytes')!=path.stat().st_size or record.get('sha256')!=sha(path.read_bytes())):
            raise ValueError('Universal RP helper payload integrity mismatch: '+filename)
    if not (directory/BINARY).stat().st_mode&0o111:raise ValueError('RP helper executable permissions missing')
    report=json.loads((directory/REPORT).read_text())
    if (report.get('notice_obligations_satisfied') is not True or report.get('notice_gap_count')!=0
        or report.get('locked_dependency_graph_hash')!=manifest.get('locked_dependency_graph_hash')
        or report.get('target_graph_hashes')!=manifest.get('target_graph_hashes')
        or report.get('targets')!=list(TARGETS)):
        raise ValueError('Universal RP helper exact Mac-target license graph is unresolved')
    return manifest


def main():
    if sys.platform!='darwin' or os.environ.get('GITHUB_ACTIONS')!='true':
        raise ValueError('Universal RP helper compilation is restricted to the hosted Mac cloud job')
    rustc=command('rustc','--version')
    if not rustc.startswith('rustc 1.99.1 '):raise ValueError('Pinned Rust 1.99.1 required for runtime source/notices')
    commit=command('git','rev-parse','HEAD')
    # Reused unit evidence intentionally performs no cargo build. A fresh hosted
    # CARGO_HOME therefore needs both immutable locked source graphs fetched
    # before source fingerprinting/notices invoke metadata in offline mode.
    for manifest in [ROOT/'app-installer/core/Cargo.toml',HELPER]:
        subprocess.run(['cargo','fetch','--locked','--manifest-path',str(manifest)],cwd=ROOT,check=True)
    fingerprint=command(sys.executable,ROOT/'app-installer/build/source-fingerprint.py')
    sdk=Path(command('xcrun','--sdk','macosx','--show-sdk-path'))
    if sdk.resolve()!=Path(os.environ['SDKROOT']).resolve():raise ValueError('Helper compilation requires the actual macOS SDK')
    if os.environ.get('MACOSX_DEPLOYMENT_TARGET')!='12.0':raise ValueError('Helper deployment target differs from pinned recipe')
    dirty=subprocess.check_output(['git','status','--porcelain','--untracked-files=normal','--','app-installer','downloads','.gitignore',':!app-installer/build/work',':!app-installer/cloud-ui/work'],cwd=ROOT)
    if dirty.strip():raise ValueError('Helper source must be committed and clean before compilation')
    _,_,_,graph_hash,target_graphs=load_graph_union(HELPER,list(TARGETS))
    version=tomllib.loads(HELPER.read_text())['package']['version']
    target_root=Path(os.environ.get('CARGO_TARGET_DIR',ROOT/'app-installer/core/target')).resolve();target_root.relative_to(ROOT)
    # Mandatory build in this entrypoint also prevents direct invocation from
    # relabelling foreign/stale target files with the current source identity.
    for target in TARGETS:
        subprocess.run(['cargo','build','--manifest-path',str(HELPER),'--locked','--release','--target',target],cwd=ROOT,check=True)
    DIRECTORY.mkdir(parents=True,exist_ok=True)
    binary=DIRECTORY/BINARY
    thin=[target_root/target/'release'/BINARY for target in TARGETS]
    if any(path.is_symlink() or not path.is_file() for path in thin):raise ValueError('Both freshly built target helper binaries are required')
    subprocess.run(['xcrun','lipo','-create',*map(str,thin),'-output',str(binary)],cwd=ROOT,check=True)
    binary.chmod(0o755)
    subprocess.run(['codesign','--force','--sign','-','--timestamp=none',str(binary)],cwd=ROOT,check=True)
    if sorted(command('xcrun','lipo','-archs',binary).split())!=['arm64','x86_64']:
        raise ValueError('Universal helper must contain exactly arm64 and x86_64')
    marks={}
    for arch in TARGETS.values():
        mark=command('xcrun','vtool','-arch',arch,'-show-build',binary)
        if not re.search(r'\bplatform\s+MACOS\b',mark) or not re.search(r'\bminos\s+12\.0(?:\s|$)',mark):
            raise ValueError('Helper architecture has an unexpected Mach-O platform/deployment target')
        sdk_version=command('xcrun','--sdk','macosx','--show-sdk-version')
        found=re.search(r'\bsdk\s+(\d+(?:\.\d+){1,2})',mark)
        if not found or tuple(map(int,found[1].split('.')))[:2]!=tuple(map(int,sdk_version.split('.')))[:2]:
            raise ValueError('Helper Mach-O does not match the genuine macOS SDK')
        marks[arch]=mark
    subprocess.run(['codesign','--verify','--strict','--all-architectures',str(binary)],cwd=ROOT,check=True)
    # --version is the helper's explicitly side-effect-free early return. No USB,
    # system pairing record, account, service connection or personal resource is used.
    version_output=command(binary,'--version')
    if version_output!=BINARY+' '+version:raise ValueError('Helper version-only receipt does not match locked source')
    subprocess.run([sys.executable,str(ROOT/'app-installer/build/third-party-notices.py'),str(DIRECTORY/NOTICES),str(DIRECTORY/REPORT),
        '--require-licenses','--manifest-path',str(HELPER),*[part for target in TARGETS for part in ['--target',target]]],cwd=ROOT,check=True)
    settings=sdk/'SDKSettings.plist'
    if not settings.is_file():settings=sdk/'SDKSettings.json'
    def record(path):return {'file':path.name,'bytes':path.stat().st_size,'sha256':sha(path.read_bytes())}
    manifest={'schema_version':1,'test_fixture':False,'tool':BINARY,'version':version,
        'build_succeeded':True,'source_commit':commit,'source_tree_sha256':fingerprint,
        'locked_dependency_graph_hash':graph_hash,'target_graph_hashes':target_graphs,
        'cargo_lock_sha256':sha((HELPER.parent/'Cargo.lock').read_bytes()),'targets':list(TARGETS),
        'architectures':['arm64','x86_64'],'protocol_record_version':2,
        'binary':record(binary),'notices':record(DIRECTORY/NOTICES),'notice_report':record(DIRECTORY/REPORT),
        'rustc_version':rustc,'genuine_toolchain':{'xcode':command('xcodebuild','-version'),
        'macos_sdk':sdk_version,'sdk_settings_sha256':sha(settings.read_bytes()),'clang':command('xcrun','clang','--version').splitlines()[0]},
        'minimum_macos':'12.0','macho_architecture_observations':marks,
        'thin_builds':[{'target':target,'sha256':sha(path.read_bytes()),'bytes':path.stat().st_size} for target,path in zip(TARGETS,thin)],
        'ad_hoc_signed':True,'notarized':False,'apple_developer_identity_used':False,
        'version_only_executed':True,'version_only_architecture':os.uname().machine,'version_output':version_output,'other_architecture_execution_verified':False,'usb_or_pairing_executed':False,
        'personal_resources_used':False,'corresponding_source_delivery_pending':True}
    if command(sys.executable,ROOT/'app-installer/build/source-fingerprint.py')!=fingerprint:
        raise ValueError('Source changed during universal helper compilation')
    (DIRECTORY/MANIFEST).write_text(json.dumps(manifest,indent=2)+'\n')
    verify_outputs(DIRECTORY,commit,fingerprint)
    print('Universal Mac RP helper built and integrity/notices verified in hosted cloud; no USB pairing/account action performed.')


if __name__=='__main__':main()
