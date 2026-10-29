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


def build_kit(library,manifest_path,review_ipa,source_bundle,output,variant):
    manifest=workflow.load_handoff(manifest_path,library,private_only=False)
    review=workflow.verify_review_ipa(review_ipa,manifest,variant)
    source_bundle=workflow.checked_file(source_bundle)
    source_hash=workflow.sha256(source_bundle)
    if source_hash!=manifest.get('source_bundle_sha256'):
        raise workflow.WorkflowError('Minimal kit and complete source/relink distribution do not share the same cloud binding.')
    head=workflow.command(['git','rev-parse','HEAD'],step='Cloud kit source commit verification').decode().strip()
    dirty=workflow.command(['git','status','--porcelain','--untracked-files=normal','--','README.md','app-installer/device','app-installer/ios','app-installer/core/app_installer.h','app-installer/core/secure_storage.h','app-installer/LICENSE','app-installer/licensing-signing.md','downloads/idevice-pair-macos/SOURCE.md','downloads/idevice-pair-macos/.gitignore'],step='Cloud kit source cleanliness check')
    if dirty.strip():raise workflow.WorkflowError('Bootstrap source must be committed before it is labeled with the cloud handoff commit.')
    fingerprint=workflow.command([sys.executable,str(ROOT/'app-installer/build/source-fingerprint.py')],step='Cloud kit source fingerprint verification').decode().strip()
    verify_source_revision(manifest,head,fingerprint)
    output=workflow.contained(output)
    helper=None;helper_receipt=None
    if (ROOT/'app-installer/device/secure-rp-bootstrap/Cargo.toml').is_file():
        spec=importlib.util.spec_from_file_location('rp_package',ROOT/'app-installer/build/package-rp-bootstrap-cloud.py')
        helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
        helper_receipt=helper.verify_outputs(helper.DIRECTORY,manifest['source_commit'],fingerprint)
        # The full source archive has already passed candidate verification. Check
        # its bounded first manifest here to prevent an app-only source companion
        # being offered as the Mac helper's source/relink delivery.
        import tarfile
        with tarfile.open(source_bundle,'r|xz') as archive:
            first=next(iter(archive))
            if not first.isfile() or first.name!='AppInstaller-source/SourceBundleManifest.json' or first.size>32*1024*1024:
                raise workflow.WorkflowError('Matching helper source manifest is missing or exceeds its supported bound.')
            source_manifest=json.loads(archive.extractfile(first).read(first.size+1))
        matching=next((root for root in source_manifest.get('additional_cargo_roots',[]) if root.get('manifest')=='app-installer/device/secure-rp-bootstrap/Cargo.toml'),None)
        if (not matching or matching.get('locked_dependency_graph_hash')!=helper_receipt['locked_dependency_graph_hash']
            or matching.get('lock_sha256')!=helper_receipt['cargo_lock_sha256']
            or source_manifest.get('source_tree_sha256')!=fingerprint or source_manifest.get('source_commit')!=manifest['source_commit']):
            raise workflow.WorkflowError('Complete companion source does not cover this exact Mac helper lock/source graph.')
    work=ROOT/'app-installer/build/work';work.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='bootstrap-kit-',dir=work) as temporary:
        stage=pathlib.Path(temporary)/'claude-chatg';stage.mkdir()
        files=['README.md','app-installer/LICENSE','app-installer/licensing-signing.md',
               'app-installer/core/app_installer.h','app-installer/core/secure_storage.h',
               'app-installer/device/.gitignore','app-installer/device/device-workflow.py',
               'app-installer/device/setup-wizard.py','app-installer/device/Run-App-Installer-Setup.command',
               'app-installer/device/USER-ACTIONS.md','app-installer/device/WORKFLOW.md',
               'downloads/idevice-pair-macos/SOURCE.md','downloads/idevice-pair-macos/.gitignore']
        files += [str(p.relative_to(ROOT)) for p in (ROOT/'app-installer/ios').rglob('*')
                  if p.is_file() and p.suffix in {'.m','.h','.plist','.png'}]
        for relative in sorted(set(files)):
            source=workflow.checked_file(ROOT/relative);target=stage/relative
            target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
        inputs=stage/'app-installer/device/private/input';inputs.mkdir(parents=True,mode=0o700)
        library_target=inputs/'libapp_installer_core.a';shutil.copy2(workflow.checked_file(library),library_target)
        manifest_target=inputs/'cloud-device-library-manifest.json';shutil.copy2(workflow.checked_file(manifest_path),manifest_target)
        resources=inputs/'review-resources';resources.mkdir()
        with zipfile.ZipFile(review) as archive:
            for name in ['ThirdPartyNotices.txt','ThirdPartyNoticeReport.json','BuildMetadata.json']:
                (resources/name).write_bytes(archive.read('Payload/AppInstaller.app/'+name))
        tool_payload=None
        if helper:
            tool_dir=stage/'app-installer/device/tools';tool_dir.mkdir(parents=True)
            for filename in [helper.BINARY,helper.NOTICES,helper.REPORT]:shutil.copy2(helper.DIRECTORY/filename,tool_dir/filename)
            tool= dict(helper_receipt)
            tool.update(corresponding_source_delivery_pending=False,source_bundle_sha256=source_hash,
                        source_bundle_file=source_bundle.name,source_bundle_bytes=source_bundle.stat().st_size,
                        source_bundle_delivery='separate-cloud-companion-artifact')
            (tool_dir/helper.MANIFEST).write_text(json.dumps(tool,indent=2)+'\n')
            (tool_dir/helper.BINARY).chmod(0o755)
            tool_payload={'binary':'app-installer/device/tools/'+helper.BINARY,
                'manifest':'app-installer/device/tools/'+helper.MANIFEST,
                'notices':'app-installer/device/tools/'+helper.NOTICES,
                'notice_report':'app-installer/device/tools/'+helper.REPORT,
                'source_commit':tool['source_commit'],'source_tree_sha256':tool['source_tree_sha256'],
                'version':tool['version'],'architectures':tool['architectures'],
                'protocol_record_version':2,'ad_hoc_signed':True,'notarized':False}
        payload=[]
        for path in sorted(stage.rglob('*')):
            if path.is_file():payload.append({'path':str(path.relative_to(stage)),'bytes':path.stat().st_size,'sha256':workflow.sha256(path)})
        kit={'schema_version':1,'test_fixture':False,'project':'claude-chatg','source_commit':manifest['source_commit'],'bootstrap_tool_commit':head,'source_tree_sha256':fingerprint,
             'variant':variant,'secure_rp_tool':tool_payload,'files':payload,'rust_library':str(library_target.relative_to(stage)),
             'library_manifest':str(manifest_target.relative_to(stage)),'review_resources':str(resources.relative_to(stage)),
             'native_sources':[p['path'] for p in payload if p['path'].startswith('app-installer/ios/') and p['path'].endswith(('.m','.h'))],
             'corresponding_source':{'file':source_bundle.name,'sha256':source_hash,'bytes':source_bundle.stat().st_size,'delivery':'separate-cloud-companion-artifact','artifact':'app-installer-cloud-ui-latest','path':'candidates/'+source_bundle.name},
             'scope':'Native bootstrap source/resources + exact cloud Rust archive and optional source-bound universal Mac RP helper. No Git history, Unit Creator, Cargo installation, accounts, profiles, pairing exports or signing keys.',
             'personal_resources_used':False,'device_install_attempted':False}
        (stage/'BootstrapKitManifest.json').write_text(json.dumps(kit,indent=2)+'\n')
        output.parent.mkdir(parents=True,exist_ok=True);temp_zip=pathlib.Path(temporary)/'native-kit.zip'
        with zipfile.ZipFile(temp_zip,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
            for path in sorted(stage.rglob('*')):
                if not path.is_file():continue
                relative=path.relative_to(stage)
                info=zipfile.ZipInfo('AI-Workspace/claude-chatg/'+str(relative),date_time=(2026,1,1,0,0,0))
                info.compress_type=zipfile.ZIP_DEFLATED
                info.external_attr=((stat.S_IFREG | (0o755 if path.suffix=='.command' or (tool_payload and str(relative)==tool_payload['binary']) else 0o600))<<16)
                archive.writestr(info,path.read_bytes())
        os.replace(temp_zip,output)
    receipt={'schema_version':1,'file':output.name,'bytes':output.stat().st_size,'sha256':workflow.sha256(output),
             'source_commit':manifest['source_commit'],'bootstrap_tool_commit':head,'source_tree_sha256':fingerprint,'variant':variant,
             'corresponding_source':kit['corresponding_source'],'secure_rp_tool':kit['secure_rp_tool'],'minimal_bootstrap_kit':True,
             'personal_resources_used':False,'device_install_attempted':False}
    output.with_suffix('.json').write_text(json.dumps(receipt,indent=2)+'\n')
    return receipt


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--execute',action='store_true');p.add_argument('--rust-library',type=pathlib.Path)
    p.add_argument('--manifest',type=pathlib.Path);p.add_argument('--review-ipa',type=pathlib.Path)
    p.add_argument('--source-bundle',type=pathlib.Path);p.add_argument('--output',type=pathlib.Path)
    p.add_argument('--variant',choices=['iphone','duo'],default='duo');args=p.parse_args()
    if not args.execute:
        print('DRY RUN: would assemble one minimal native bootstrap transfer in the cloud. No Mac, personal connection, account or device action.');return 0
    if sys.platform=='darwin' and os.environ.get('GITHUB_ACTIONS')!='true':
        print('Assemble this kit in the cloud, not on Tin\'s Mac.',file=sys.stderr);return 1
    if not all([args.rust_library,args.manifest,args.review_ipa,args.source_bundle,args.output]):
        print('Exact cloud archive/manifest, fresh unsigned review IPA, complete source bundle and output are required.',file=sys.stderr);return 1
    try:
        print(json.dumps(build_kit(args.rust_library,args.manifest,args.review_ipa,args.source_bundle,args.output,args.variant),indent=2));return 0
    except (workflow.WorkflowError,OSError,ValueError,KeyError,zipfile.BadZipFile):
        error=sys.exc_info()[1];print(str(error) if isinstance(error,workflow.WorkflowError) else 'Minimal cloud kit could not be assembled safely.',file=sys.stderr);return 1

if __name__=='__main__':raise SystemExit(main())
