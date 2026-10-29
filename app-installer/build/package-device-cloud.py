#!/usr/bin/env python3
"""Package genuinely compiled device candidates plus matching source/relink delivery."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import zipfile
sys.dont_write_bytecode=True
from licensing import ROOT,load_graph,sha


def load_module(name,file):
    spec=importlib.util.spec_from_file_location(name,Path(__file__).with_name(file));module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module


def command(*args):return subprocess.check_output([str(a) for a in args],text=True).strip()
def version(text):return tuple(int(p) for p in text.split('.'))


def verify_core_receipt(receipt,library,expected,allow_test_fixture=False):
    if receipt.get('test_fixture') and not allow_test_fixture:raise ValueError('Test-only library fixture is not compilation evidence')
    if receipt.get('schema_version')!=1 or receipt.get('build_succeeded') is not True or receipt.get('target')!='aarch64-apple-ios':
        raise ValueError('Mandatory actual device-library build receipt missing')
    if receipt.get('file')!=library.name or receipt.get('bytes')!=library.stat().st_size or receipt.get('sha256')!=sha(library.read_bytes()):
        raise ValueError('Rust library content does not match completed build receipt')
    for field,value in expected.items():
        if receipt.get(field)!=value:raise ValueError('Rust library build receipt differs: '+field)


def main():
    if sys.platform!='darwin' or os.environ.get('GITHUB_ACTIONS')!='true':raise ValueError('Device candidate entrypoint requires hosted macOS GitHub Actions; no local Mac permission is implied')
    rustc=command('rustc','--version')
    if not rustc.startswith('rustc 1.99.1 '):raise ValueError('Pinned Rust1.99.1 must match the delivered runtime source/notices')
    sdk=command('xcrun','--sdk','iphoneos','--show-sdk-version')
    if version(sdk)<(27,1):raise ValueError('A genuine installed iPhoneOS SDK27.1 or newer is required')
    sdk_path=Path(command('xcrun','--sdk','iphoneos','--show-sdk-path'))
    if sdk_path.resolve()!=Path(os.environ['SDKROOT']).resolve():raise ValueError('Rust/native SDK selection differs')
    clang=command('xcrun','--sdk','iphoneos','--find','clang')
    commit=command('git','rev-parse','HEAD');fingerprint=command(sys.executable,ROOT/'app-installer/build/source-fingerprint.py')
    _,_,_,graph_hash=load_graph()
    dirty=bool(subprocess.check_output(['git','status','--porcelain','--untracked-files=normal','--','app-installer','downloads','.gitignore',':!app-installer/build/work',':!app-installer/cloud-ui/work'],cwd=ROOT))
    if dirty:raise ValueError('Source must be committed/clean before source-bound candidate builds')
    library=Path(os.environ.get('CARGO_TARGET_DIR',ROOT/'app-installer/core/target'))/'aarch64-apple-ios/release/libapp_installer_core.a'
    if not library.is_file():raise ValueError('Mandatory device Rust static library missing')
    sdk_settings=sdk_path/'SDKSettings.plist'
    if not sdk_settings.is_file():sdk_settings=sdk_path/'SDKSettings.json'
    build_receipt=library.parent/'AppInstaller-device-build-receipt.json'
    if not build_receipt.is_file():raise ValueError('Invoke the shell entrypoint: completed device library build receipt is required')
    verify_core_receipt(json.loads(build_receipt.read_text()),library,{'source_commit':commit,'source_tree_sha256':fingerprint,
        'locked_dependency_graph_hash':graph_hash,'sdk_version':sdk,'sdk_settings_sha256':sha(sdk_settings.read_bytes()),'rustc_version':rustc})
    work=ROOT/'app-installer/build/work';work.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='genuine-device-',dir=work) as temporary:
        stage=Path(temporary);notices=stage/'ThirdPartyNotices.txt';report_path=stage/'ThirdPartyNoticeReport.json'
        subprocess.run([sys.executable,str(ROOT/'app-installer/build/third-party-notices.py'),str(notices),str(report_path),'--require-licenses'],check=True)
        source_module=load_module('source_bundle','source-bundle.py')
        source_archive=stage/'AppInstaller-corresponding-source.tar.xz'
        source_receipt=source_module.create(source_archive,notices,report_path)
        source_module.verify(source_archive,fingerprint,graph_hash)
        report=json.loads(report_path.read_text());report['distribution_requirements_satisfied']=True
        report['corresponding_source']=source_receipt;report['release_license_ready']=True
        report_path.write_text(json.dumps(report,indent=2)+'\n')
        toolchain={'sdk_version':sdk,'sdk_path':str(sdk_path),'sdk_settings_sha256':sha(sdk_settings.read_bytes()),
                   'xcode':command('xcodebuild','-version'),'clang':command(clang,'--version').splitlines()[0],
                   'rustc':command('rustc','--version')}
        artifacts=[]
        for variant in ['iphone','duo']:
            container=stage/variant;app=container/'Payload/AppInstaller.app';app.mkdir(parents=True)
            plist=plistlib.loads((ROOT/'app-installer/ios/Info.plist').read_bytes())
            plist.update(DTPlatformName='iphoneos',DTPlatformVersion=sdk,DTSDKName='iphoneos'+sdk)
            plist['CFBundleDisplayName']='App Installer'+(' Duo' if variant=='duo' else '')
            (app/'Info.plist').write_bytes(plistlib.dumps(plist))
            for size,scale in [(120,2),(180,3)]:shutil.copy2(ROOT/f'app-installer/ios/assets/AppIcon{size}.png',app/f'AppIcon60x60@{scale}x.png')
            for path in [notices,report_path]:shutil.copy2(path,app/path.name)
            shutil.copy2(ROOT/'app-installer/LICENSE',app/'LICENSE.txt')
            shutil.copy2(ROOT/'app-installer/licensing-signing.md',app/'SourceAndRelink.md')
            metadata={'source_commit':commit,'source_has_uncommitted_changes':False,'source_tree_sha256':fingerprint,
                'locked_dependency_graph_hash':graph_hash,'source_bundle_sha256':source_receipt['sha256'],
                'source_bundle_file':source_receipt['file'],'variant':variant,'unsigned':True,
                'designation':'unsigned-candidate','compilation_sdk':sdk,'requested_sdk_mark':sdk,
                'synthetic_sdk_marker':False,'genuine_toolchain':toolchain,
                'phone_install_attempted':False,'duo_device_layout_verified':False,
                'license_obligations_satisfied':True,'corresponding_source_verified':True}
            (app/'BuildMetadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
            native=sorted((ROOT/'app-installer/ios').glob('*.m'))
            args=[clang,'-target','arm64-apple-ios16.4','-isysroot',str(sdk_path),'-fobjc-arc','-fmodules',
                  '-fmodules-cache-path='+str(stage/'modules'),'-Werror=return-type','-Werror=implicit-function-declaration',*map(str,native),str(library)]
            for framework in ['UIKit','Foundation','Security','LocalAuthentication','UniformTypeIdentifiers','BackgroundTasks','UserNotifications','CoreFoundation','SystemConfiguration']:
                args+=['-framework',framework]
            args+=['-liconv','-lSystem','-lobjc','-lz','-o',str(app/'AppInstaller')]
            subprocess.run(args,check=True);(app/'AppInstaller').chmod(0o755)
            output=stage/f'AppInstaller-{variant}-candidate.ipa'
            with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as archive:
                for path in sorted((container/'Payload').rglob('*')):
                    if path.is_file():archive.write(path,path.relative_to(container))
            gate=load_module('artifact_check','check-artifact.py');gate.check(output,variant,ROOT)
            artifacts.append({'variant':variant,'file':output.name,'bytes':output.stat().st_size,'sha256':sha(output.read_bytes())})
        if command(sys.executable,ROOT/'app-installer/build/source-fingerprint.py')!=fingerprint:raise ValueError('Source changed during device candidate packaging')
        manifest={'schema_version':1,'classification':'unsigned-candidate','release_ready':False,
            'source_commit':commit,'source_tree_sha256':fingerprint,'locked_dependency_graph_hash':graph_hash,
            'genuine_toolchain':toolchain,'ipa_artifacts':artifacts,'source_bundle':source_receipt,
            'licensing':{'notices_verified':True,'unresolved_notice_cases':0,'corresponding_source_verified':True,
                         'relink_instructions_verified':True},
            'unverified_release_requirements':['native simulator functionality is verified separately from candidate integrity','live Apple authentication/profile/signature/install/launch/refresh','physical Duo outer/inner/native-resolution/safe-area/touch/fold/state/crash checks']}
        candidate_manifest=stage/'AppInstaller-candidate-manifest.json';candidate_manifest.write_text(json.dumps(manifest,indent=2)+'\n')
        validator=load_module('candidate_validation','verify-candidate.py');validator.verify(candidate_manifest,stage)
        evidence=ROOT/'app-installer/cloud-ui/work/evidence/candidates';evidence.mkdir(parents=True,exist_ok=True)
        builds=ROOT/'builds';builds.mkdir(exist_ok=True)
        for path in [source_archive,candidate_manifest,*[stage/a['file'] for a in artifacts]]:
            shutil.copy2(path,evidence/path.name);os.replace(path,builds/path.name)
        # Dedicated bootstrap payload stays in cloud evidence, never in tracked source.
        shutil.copy2(library,evidence/'libapp_installer_core.a')
        core_manifest={'schema_version':1,'target':'aarch64-apple-ios','file':'libapp_installer_core.a',
            'bytes':library.stat().st_size,'sha256':sha(library.read_bytes()),'source_commit':commit,
            'source_tree_sha256':fingerprint,'locked_dependency_graph_hash':graph_hash,
            'source_bundle_sha256':source_receipt['sha256'],'source_bundle_file':source_receipt['file'],
            'source_bundle_bytes':source_receipt['bytes'],'source_bundle_location':'same-artifact/candidates/'+source_receipt['file'],
            'source_bundle':source_receipt,'compilation_sdk':sdk,'unsigned':True}
        (evidence/'cloud-device-library-manifest.json').write_text(json.dumps(core_manifest,indent=2)+'\n')
        for variant in ['iphone','duo']:(builds/f'AppInstaller-{variant}-preview.ipa').unlink(missing_ok=True)
        print(json.dumps(manifest,indent=2))
    try:work.rmdir()
    except OSError:pass


if __name__=='__main__':main()
