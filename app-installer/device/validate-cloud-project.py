#!/usr/bin/env python3
"""Validate the generated physical-bootstrap project on a hosted cloud Mac, unsigned.

Default dry-run. No Apple account, provisioning, trust/pairing, MacBook access or
physical device command exists in this check. Root's cloud workflow invokes it once
against the same-commit, fingerprint-bound genuine-SDK arm64 library handoff.
"""
import argparse, hashlib, importlib.util, json, os, pathlib, plistlib, re, shutil, subprocess, sys

HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[1]
spec=importlib.util.spec_from_file_location("device_workflow",HERE/"device-workflow.py")
workflow=importlib.util.module_from_spec(spec);spec.loader.exec_module(workflow)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--execute",action="store_true")
    parser.add_argument("--rust-library",type=pathlib.Path)
    parser.add_argument("--manifest",type=pathlib.Path)
    parser.add_argument("--review-ipa",type=pathlib.Path)
    args=parser.parse_args()
    if not args.execute:
        print("DRY RUN: would validate the generated native .xcodeproj on a hosted cloud Mac with CODE_SIGNING_ALLOWED=NO; no device/account/provisioning actions.")
        return 0
    if sys.platform!="darwin" or os.environ.get("GITHUB_ACTIONS")!="true":
        print("Execution is restricted to the explicitly selected macOS GitHub Actions cloud job; do not run this on Tin's Mac.",file=sys.stderr);return 1
    if not args.manifest or not args.rust_library:
        print("The exact cloud arm64 archive and manifest are required.",file=sys.stderr);return 1
    report_path=ROOT/"app-installer/cloud-ui/work/evidence/bootstrap-project-check.json"
    report_path.parent.mkdir(parents=True,exist_ok=True)
    report={"scope":"Generated native bootstrap project: unsigned hosted-cloud compilation only; no account/provisioning/phone installation.","passed":False,"device_install_attempted":False,"apple_account_used":False}
    staging=HERE/"private/cloud-project-validation"
    try:
        manifest=workflow.load_handoff(args.manifest,args.rust_library,private_only=False)
        head=workflow.command(["git","rev-parse","HEAD"],step="Cloud source commit verification").decode().strip()
        source_hash=workflow.command([sys.executable,str(ROOT/"app-installer/build/source-fingerprint.py")],step="Cloud source fingerprint verification").decode().strip()
        if manifest["source_commit"]!=head or manifest["source_tree_sha256"]!=source_hash:
            raise workflow.WorkflowError("Cloud project and Rust archive do not share the same reviewed commit/source fingerprint.")
        sdk=workflow.command(["xcrun","--sdk","iphoneos","--show-sdk-version"],step="Genuine cloud SDK discovery").decode().strip()
        if (workflow.version(sdk)+(0,))[:2]<(27,1): raise workflow.WorkflowError("An actual iPhoneOS SDK 27.1+ is required for this cloud project check.")
        workflow.command(["xcrun","lipo","-verify_arch","arm64",str(args.rust_library)],step="Cloud arm64 archive verification")
        review=workflow.verify_review_ipa(args.review_ipa or args.manifest.parent/"AppInstaller-duo-candidate.ipa",manifest,"duo")
        if staging.is_symlink() or not staging.resolve().is_relative_to(ROOT.resolve()):
            raise workflow.WorkflowError("Cloud project work must stay in its owned repository directory.")
        workflow.PRIVATE=staging;staging.mkdir(parents=True,exist_ok=True)
        project=workflow.generate_project("CLOUD00000","org.tin.appinstaller.cloudbootstrap","duo",workflow.checked_file(args.rust_library),unsigned_validation=True,review_ipa=review,actual_sdk=sdk)
        # There is deliberately no allowProvisioningUpdates/registration option and no device identifier.
        result=subprocess.run(["xcodebuild","-quiet","-project",str(project),"-scheme","AppInstaller","-configuration","Release","-sdk","iphoneos","-destination","generic/platform=iOS","-derivedDataPath",str(staging/"DerivedData"),"CODE_SIGNING_ALLOWED=NO","CODE_SIGNING_REQUIRED=NO","build"],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        # Safe only in this account-free cloud job: no real team/device/account or signing material.
        (report_path.parent/"bootstrap-project-build.log").write_bytes(result.stdout)
        if result.returncode: raise workflow.WorkflowError("The generated native Xcode project failed unsigned cloud compilation; inspect its cloud-only build log.")
        app=staging/"DerivedData/Build/Products/Release-iphoneos/AppInstaller.app"
        info=plistlib.loads((app/"Info.plist").read_bytes())
        binary=app/str(info.get("CFBundleExecutable","AppInstaller"))
        marks=workflow.command(["xcrun","vtool","-show-build",str(binary)],step="Cloud native Mach-O SDK verification").decode()
        found=re.search(r"\bsdk\s+(\d+(?:\.\d+){1,2})",marks)
        if not re.search(r"\bplatform\s+IOS\b",marks) or not found or workflow.version(found.group(1))[:2]!=workflow.version(sdk)[:2]:
            raise workflow.WorkflowError("Cloud native binary does not identify the actual selected iPhoneOS SDK.")
        if (info.get("CFBundleIdentifier")!="org.tin.appinstaller.cloudbootstrap"
            or info.get("BGTaskSchedulerPermittedIdentifiers")!=["org.tin.appinstaller.cloudbootstrap.refresh"]
            or not info.get("UIApplicationSceneManifest") or "UIRequiresFullScreen" in info
            or (app/"embedded.mobileprovision").exists()):
            raise workflow.WorkflowError("Unsigned cloud bootstrap bundle lost required identity/scene/background metadata or gained an unexpected provisioning profile.")
        actual=workflow.command([sys.executable,str(ROOT/"app-installer/build/source-fingerprint.py")],step="Final cloud source fingerprint verification").decode().strip()
        if actual!=source_hash: raise workflow.WorkflowError("Production source changed during native cloud compilation.")
        report.update(passed=True,source_commit=head,source_tree_sha256=source_hash,rust_archive_sha256=manifest["sha256"],rust_archive_bytes=manifest["bytes"],actual_iphoneos_sdk=sdk,compiled_binary_sha256=workflow.sha256(binary),codesigning_allowed=False,profile_present=False,generated_shared_scheme_compiled=True)
        print("Generated native bootstrap .xcodeproj compiled with genuine iPhoneOS SDK; signing/accounts/device installation stayed disabled.")
        return 0
    except (workflow.WorkflowError,OSError,ValueError) as error:
        report["error"]=str(error) if isinstance(error,workflow.WorkflowError) else "Cloud project verification could not finish safely."
        print(report["error"],file=sys.stderr);return 1
    finally:
        report_path.write_text(json.dumps(report,indent=2)+"\n")
        # Only this owned cloud project/DerivedData tree is disposable; keep its report/log.
        if staging.exists() and not staging.is_symlink() and staging.resolve().is_relative_to(ROOT.resolve()): shutil.rmtree(staging)

if __name__=="__main__": raise SystemExit(main())
