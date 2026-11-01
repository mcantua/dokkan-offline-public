#!/usr/bin/env python3
"""Assemble one minimal, source-bound native bootstrap kit in the cloud, never on Tin's Mac.

Default dry-run. The separate complete source/relink archive stays alongside this
kit in the cloud distribution; no Unit Creator, Git history, Cargo toolchain or
private signing/pairing material enters this minimal transfer.
"""
import argparse, hashlib, importlib.util, json, os, pathlib, re, shutil, stat, sys, tempfile, zipfile
sys.dont_write_bytecode=True
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[1]
spec=importlib.util.spec_from_file_location('workflow',HERE/'device-workflow.py')
workflow=importlib.util.module_from_spec(spec);spec.loader.exec_module(workflow)

def verify_source_revision(manifest,head,fingerprint):
    if not re.fullmatch(r'[0-9a-f]{40}',head) or fingerprint!=manifest['source_tree_sha256']:
        raise workflow.WorkflowError('Minimal kit production inputs differ from the reviewed cloud source fingerprint.')
    if head!=manifest['source_commit']:
        # No fetch: absent/shallow/unrelated history fails closed. Helper-only updates
        # may follow the compiled source while the exact app/Rust fingerprint stays fixed.
        workflow.command(['git','merge-base','--is-ancestor',manifest['source_commit'],head],step='Compiled source ancestry verification (local history only)')


def build_kit(library,manifest_path,review_ipa,source_bundle,output,variant,rp_helper_directory=None):
    manifest=workflow.load_handoff(manifest_path,library,private_only=False)
    review=workflow.verify_review_ipa(review_ipa,manifest,variant)
    source_bundle=workflow.checked_file(source_bundle)
    source_hash=workflow.sha256(source_bundle)
    if source_hash!=manifest.get('source_bundle_sha256'):
        raise workflow.WorkflowError('Minimal kit and complete source/relink distribution do not share the same cloud binding.')
    head=workflow.command(['git','rev-parse','HEAD'],step='Cloud kit source commit verification').decode().strip()
    dirty=workflow.command(['git','status','--porcelain','--untracked-files=normal','--','README.md','app-installer/device','app-installer/ios','app-installer/core/app_installer.h','app-installer/core/secure_storage.h','app-installer/LICENSE','app-installer/licensing-signing.md','downloads/idevice/idevice-0.1.68/examples/app-installer-rp-bootstrap.rs'],step='Cloud kit source cleanliness check')
    if dirty.strip():raise workflow.WorkflowError('Bootstrap source must be committed before it is labeled with the cloud handoff commit.')
    fingerprint=workflow.command([sys.executable,str(ROOT/'app-installer/build/source-fingerprint.py')],step='Cloud kit source fingerprint verification').decode().strip()
    verify_source_revision(manifest,head,fingerprint)
    output=workflow.contained(output)
    work=ROOT/'app-installer/build/work';work.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='bootstrap-kit-',dir=work) as temporary:
        stage=pathlib.Path(temporary)/'dokkan-offline-public';stage.mkdir()
        files=['README.md','app-installer/LICENSE','app-installer/licensing-signing.md',
               'app-installer/core/app_installer.h','app-installer/core/secure_storage.h',
               'app-installer/device/.gitignore','app-installer/device/device-workflow.py',
               'app-installer/device/setup-wizard.py','app-installer/device/Run-App-Installer-Setup.command',
               'app-installer/device/update-public-kit.py','app-installer/device/PUBLIC-QUICK-START.md',
               'app-installer/device/UPDATE-EXISTING-KIT.md','app-installer/device/USER-ACTIONS.md',
               'app-installer/device/PUBLIC-CONTINUATION.md']
        files += [str(p.relative_to(ROOT)) for p in (ROOT/'app-installer/ios').rglob('*')
                  if p.is_file() and p.suffix in {'.m','.h','.plist','.png'}]
        for relative in sorted(set(files)):
            source=workflow.checked_file(ROOT/relative);target=stage/relative
            target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
        helper_directory=workflow.contained(rp_helper_directory or ROOT/'app-installer/cloud-ui/work/public-rp-helper')
        if not helper_directory.is_dir() or helper_directory.is_symlink():
            raise workflow.WorkflowError('The new public source-bound Mac helper has not been built and sealed.')
        for key,relative in workflow.RP_HELPER_PATHS.items():
            source=workflow.checked_file(helper_directory/pathlib.PurePosixPath(relative).name)
            if key=='binary' and stat.S_IMODE(source.stat().st_mode)!=0o755:
                raise workflow.WorkflowError('The verified universal Mac helper must retain its executable0755 mode.')
            target=stage/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
        inputs=stage/'app-installer/device/private/input';inputs.mkdir(parents=True,mode=0o700)
        library_target=inputs/'libapp_installer_core.a';shutil.copy2(workflow.checked_file(library),library_target)
        manifest_target=inputs/'cloud-device-library-manifest.json';shutil.copy2(workflow.checked_file(manifest_path),manifest_target)
        resources=inputs/'review-resources';resources.mkdir()
        with zipfile.ZipFile(review) as archive:
            for name in ['ThirdPartyNotices.txt','ThirdPartyNoticeReport.json','BuildMetadata.json']:
                (resources/name).write_bytes(archive.read('Payload/AppInstaller.app/'+name))
        payload=[]
        for path in sorted(stage.rglob('*')):
            if path.is_file():
                entry={'path':str(path.relative_to(stage)),'bytes':path.stat().st_size,'sha256':workflow.sha256(path)}
                if str(path.relative_to(stage))==workflow.RP_HELPER_PATHS['binary']:entry['mode']=0o755
                payload.append(entry)
        kit={'schema_version':1,'test_fixture':False,'project':'dokkan-offline-public','source_commit':manifest['source_commit'],'bootstrap_tool_commit':head,'source_tree_sha256':fingerprint,
             'variant':variant,'files':payload,'rust_library':str(library_target.relative_to(stage)),
             'library_manifest':str(manifest_target.relative_to(stage)),'review_resources':str(resources.relative_to(stage)),
             'native_sources':[p['path'] for p in payload if p['path'].startswith('app-installer/ios/') and p['path'].endswith(('.m','.h'))],
             'corresponding_source':{'file':source_bundle.name,'sha256':source_hash,'bytes':source_bundle.stat().st_size,'delivery':'separate-cloud-companion-artifact','artifact':'app-installer-cloud-ui-latest','path':'candidates/'+source_bundle.name},
             'secure_rp_tool':{**workflow.RP_HELPER_PATHS,'source_commit':head,'source_tree_sha256':fingerprint,
                               'version':'0.1.68','format_key':'format_version','protocol_record_version':2,'peer_pin_required':True},
             'source_repository':'mcantua/dokkan-offline-public',
             'scope':'Native bootstrap source/resources, verified universal Mac RP helper+notices and exact cloud Rust archive only. No Git history, Unit Creator, Cargo installation, accounts, profiles, pairing exports or signing keys.',
             'personal_resources_used':False,'device_install_attempted':False}
        workflow.validate_remote_pairing_tool(kit,base=stage)
        (stage/'BootstrapKitManifest.json').write_text(json.dumps(kit,indent=2)+'\n')
        output.parent.mkdir(parents=True,exist_ok=True);temp_zip=pathlib.Path(temporary)/'native-kit.zip'
        with zipfile.ZipFile(temp_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
            for path in sorted(stage.rglob('*')):
                if not path.is_file():continue
                relative=path.relative_to(stage)
                info=zipfile.ZipInfo('AI-Workspace/dokkan-offline-public/'+str(relative),date_time=(2026,1,1,0,0,0))
                info.compress_type=zipfile.ZIP_DEFLATED
                info.external_attr=((stat.S_IFREG | (0o755 if path.suffix=='.command' or str(relative)==workflow.RP_HELPER_PATHS['binary'] else 0o600))<<16)
                archive.writestr(info,path.read_bytes())
        os.replace(temp_zip,output)
    receipt={'schema_version':1,'file':output.name,'bytes':output.stat().st_size,'sha256':workflow.sha256(output),
             'source_commit':manifest['source_commit'],'bootstrap_tool_commit':head,'source_tree_sha256':fingerprint,'variant':variant,
             'corresponding_source':kit['corresponding_source'],'minimal_bootstrap_kit':True,
             'personal_resources_used':False,'device_install_attempted':False}
    output.with_suffix('.json').write_text(json.dumps(receipt,indent=2)+'\n')
    return receipt


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--execute',action='store_true');p.add_argument('--rust-library',type=pathlib.Path)
    p.add_argument('--manifest',type=pathlib.Path);p.add_argument('--review-ipa',type=pathlib.Path)
    p.add_argument('--source-bundle',type=pathlib.Path);p.add_argument('--output',type=pathlib.Path)
    p.add_argument('--rp-helper-directory',type=pathlib.Path,help='Sealed genuine universal Mac helper, source receipt and exact notices; defaults to cloud work/public-rp-helper.')
    p.add_argument('--variant',choices=['iphone','duo'],default='duo');args=p.parse_args()
    if not args.execute:
        print('DRY RUN: would assemble one minimal native bootstrap transfer in the cloud. No Mac, personal connection, account or device action.');return 0
    if sys.platform=='darwin' and os.environ.get('GITHUB_ACTIONS')!='true':
        print('Assemble this kit in the cloud, not on Tin\'s Mac.',file=sys.stderr);return 1
    if not all([args.rust_library,args.manifest,args.review_ipa,args.source_bundle,args.output]):
        print('Exact cloud archive/manifest, fresh unsigned review IPA, complete source bundle and output are required.',file=sys.stderr);return 1
    try:
        print(json.dumps(build_kit(args.rust_library,args.manifest,args.review_ipa,args.source_bundle,args.output,args.variant,args.rp_helper_directory),indent=2));return 0
    except (workflow.WorkflowError,OSError,ValueError,KeyError,zipfile.BadZipFile):
        error=sys.exc_info()[1];print(str(error) if isinstance(error,workflow.WorkflowError) else 'Minimal cloud kit could not be assembled safely.',file=sys.stderr);return 1

if __name__=='__main__':raise SystemExit(main())
