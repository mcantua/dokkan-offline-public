#!/usr/bin/env python3
"""Future authorized cloud-only unsigned original-client diagnostic assembler.

Source is intentionally not executed during no-build development. No compiler,
network, signing material, existing app/container, or save data is used.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import stat
import subprocess
import sys
import uuid

import inject_shell
import stage_original_resources as resource

CONTRACT = Path(__file__).with_name("diagnostic-package-source.json")
ENGINE = (55697728, "efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222")
SHELL = (332320, inject_shell.SOURCE_SHA256)
ACTIVE_SHA = "2c72eb794389e994fe3b793445c56678a1b8670198282518597a96ec0f5ef0ec"
CRITICAL_COMPONENT_SOURCES = (
    "offline-dokkan/original-client/loader/ODOriginalDuoStartupDiagnostic.m",
    "offline-dokkan/original-client/loader/ODPreparedEngineLoader.m",
    "offline-dokkan/original-client/ios/ODOriginalClientBootstrap.m",
    "offline-dokkan/original-client/ios/ODLocalURLProtocol.m",
    "offline-dokkan/original-client/ios/ODOfflineBootstrapAuth.m",
    "offline-dokkan/original-client/duo/ODUnifiedDuoHost.m",
    "offline-dokkan/original-client/duo/ODDuoOriginalScene.m",
    "offline-dokkan/original-client/content/resource_preload.c",
    "offline-dokkan/original-client/content/iphone_resources.c",
)


def admit_current_component_sources(component):
    """Compare fixed public source paths, never open receipt-controlled paths."""
    environment = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
    def git(*arguments):
        return subprocess.check_output(["git",*arguments],cwd=resource.ROOT,env=environment)
    head = git("rev-parse","--verify","HEAD").decode("ascii").strip()
    if not re.fullmatch(r"[0-9a-f]{40}",head) or component.get("source_commit") != head:
        raise ValueError("Component must come from the currently reviewed source commit")
    # Headers matter even though the compiler manifest lists translation units.
    # Limit inspection to authored/public compilation inputs, not private data,
    # user trees, saves, signing material or a receipt-provided path.
    scopes = ("offline-dokkan/core","offline-dokkan/adapter","offline-dokkan/content",
        "offline-dokkan/mobile/ios","offline-dokkan/original-client")
    relevant = [f":(glob){scope}/**/*.{suffix}" for scope in scopes for suffix in ("c","m","h")]
    relevant += ["offline-dokkan/original-client/build-components.sh",
        "offline-dokkan/original-client/creator-tools/build-source.json",
        "offline-dokkan/original-client/loader/startup-diagnostic-source.json",
        "unit-creator/ios-objc/Host.m","unit-creator/ios-objc/Host.h",
        "unit-creator/ios-objc/Player.m","unit-creator/ios-objc/Player.h"]
    if git("status","--porcelain=v1","-z","--untracked-files=all","--",*relevant):
        raise ValueError("Relevant component sources and headers must be committed and clean")
    sources = component.get("sources")
    if not isinstance(sources,list) or not 1 <= len(sources) <= 4096:
        raise ValueError("Component source manifest required")
    declared = {}
    for item in sources:
        if (not isinstance(item,dict) or not isinstance(item.get("source"),str) or
                item["source"] in declared or not resource.digest(item.get("sha256"))):
            raise ValueError("Malformed component source manifest")
        declared[item["source"]] = item["sha256"]
    for fixed in CRITICAL_COMPONENT_SOURCES:
        # Only this literal allowlist reaches file I/O. No source path from
        # the receipt is ever resolved or opened.
        actual = hashlib.sha256((resource.ROOT/fixed).read_bytes()).hexdigest()
        if declared.get(fixed) != actual:
            raise ValueError("Critical diagnostic component source is stale or missing")
    return head


def admit_argument(path):
    path = Path(path)
    forbidden = {"user", "save", "saves"}
    signing = {".p12", ".p8", ".pem", ".key", ".keystore", ".jks", ".mobileprovision", ".provisionprofile"}
    if (not path.is_absolute() or any(p.casefold() in forbidden or p in (".", "..") for p in path.parts)
            or path.suffix.casefold() in signing):
        raise ValueError("Private source preparation paths required")
    return path


def bounded_json(path, expected, limit=2*1024*1024):
    return json.loads(resource.read_pinned(path, limit, expected))


def inventory(root, expected):
    """List names before reading files; unknown/private payloads never get read."""
    found = set()
    directories = {"/".join(path.split("/")[:i])
        for path in expected for i in range(1,len(path.split("/")))}
    def visit(fd, prefix):
        for name in os.listdir(fd):
            if name.casefold() in ("user", "save", "saves"):
                raise ValueError("Protected tree is not a package input")
            relative = prefix+name
            if relative not in expected and relative not in directories:
                raise ValueError("Unlisted resource payload is not opened")
            info = os.stat(name, dir_fd=fd, follow_symlinks=False)
            if stat.S_ISDIR(info.st_mode):
                if relative not in directories:
                    raise ValueError("Unexpected resource directory")
                child = os.open(name, os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW|os.O_CLOEXEC, dir_fd=fd)
                try:
                    visit(child, relative+"/")
                finally:
                    os.close(child)
            elif stat.S_ISREG(info.st_mode) and relative in expected:
                found.add(relative)
            else:
                raise ValueError("Only regular resource members are admitted")
    visit(root, "")
    return found


def copy_member(source_root, source_path, target_root, target_path, expected, current):
    current()
    fd = resource.relative_readonly(source_root, source_path)
    try:
        before = os.fstat(fd)
        if before.st_size != expected[0] or before.st_mode & 0o222:
            raise ValueError("Immutable exact source member required")
        def chunks():
            at = 0
            while at < before.st_size:
                current()
                data = os.pread(fd, min(1024*1024, before.st_size-at), at)
                if not data:
                    raise ValueError("Source member changed")
                yield data
                at += len(data)
        resource.write_member(target_root, target_path, chunks(), *expected)
        again = resource.relative_readonly(source_root, source_path)
        try:
            if (resource.identity(before) != resource.identity(os.fstat(fd)) or
                    resource.identity(before) != resource.identity(os.fstat(again))):
                raise ValueError("Source member identity changed")
        finally:
            os.close(again)
    finally:
        os.close(fd)


def assemble(args):
    # Reject protected/signing arguments before any input or output I/O.
    for name in ("staged", "manifest", "shell", "engine", "component", "component_receipt", "output"):
        setattr(args, name, admit_argument(getattr(args, name)))
    if (sys.platform != "linux" or args.make_the_builds is not True or
            args.output.suffix != ".app" or
            not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", args.version) or
            not re.fullmatch(r"[1-9][0-9]*", args.build)):
        raise ValueError("Explicit authorized Linux diagnostic package inputs required")
    # No path resolution of untrusted descendants: directory() uses NOFOLLOW.
    try:
        args.output.relative_to(resource.PRIVATE)
    except ValueError:
        raise ValueError("New diagnostic app must be below ignored private cloud workspace") from None
    contract = json.loads(CONTRACT.read_bytes())
    if (contract["purpose"] != "original-startup-diagnostic" or
            contract["bundle_identifier"] != "org.offlinedokkan.startupdiagnostic.duo"):
        raise ValueError("Wrong diagnostic package contract")
    manifest, members = resource.admit_manifest(resource.read_pinned(args.manifest, 4*1024*1024, args.manifest_sha256))
    receipt = bounded_json(args.staged/"staging-receipt.json", args.staging_receipt_sha256)
    catalog = args.staged/"bundle/OriginalClient/byte-identical-assets.sqlite3"
    aliases, _ = resource.compatible_aliases(catalog, members)
    if (receipt.get("format") != "od-original-resource-source-staging-v1" or
            receipt.get("source_ipa_sha256") != resource.SOURCE_SHA256 or
            receipt.get("extraction_manifest_sha256") != args.manifest_sha256 or
            receipt.get("compatible_catalog_sha256") != resource.CATALOG_SHA256 or
            receipt.get("original_bundle_members") != 1070 or
            receipt.get("canonical_documents_aliases") != aliases or
            receipt.get("preferred_master_or_user_state_staged") is not False or
            receipt.get("actual_app_documents_written") is not False):
        raise ValueError("Wrong reviewed source staging receipt")
    component = bounded_json(args.component_receipt, args.component_receipt_sha256)
    component_commit = admit_current_component_sources(component)
    for key, expected in contract["additional_inputs"][3]["required_receipt_flags"].items():
        if type(component.get(key)) is not type(expected) or component.get(key) != expected:
            raise ValueError("The library must have the diagnostic entry, not integrated or inert entry")
    component_size, component_sha = component.get("dylib_bytes"), component.get("dylib_sha256")
    if (type(component_size) is not int or not 0 < component_size <= 128*1024*1024 or
            not resource.digest(component_sha) or component.get("original_game_launch_verified") is not False):
        raise ValueError("Invalid authorized diagnostic component receipt")
    expected = {p:(m["size"],m["sha256"]) for p,m in members.items()}
    expected.update(resource.STARTUP_INPUTS)
    expected["OriginalClient/byte-identical-assets.sqlite3"] = (resource.CATALOG_BYTES,resource.CATALOG_SHA256)
    for alias in aliases:
        path = "OriginalClient/CompatibleResourceCache/"+alias["sha256"]
        if path in expected:
            raise ValueError("Duplicate compatible source payload")
        expected[path] = (alias["size"],alias["sha256"])
    additions = {
        "OriginalClient/OriginalGenuineDuoShell": (args.shell,SHELL),
        "Frameworks/OriginalDokkanEngine.dylib": (args.engine,ENGINE),
        "Frameworks/OfflineDokkanHost.dylib": (args.component,(component_size,component_sha))}
    reserved = set(additions)|{"OfflineDokkanStartupDiagnostic","Info.plist","package-receipt.json"}
    if reserved.intersection(expected):
        raise ValueError("Original resource collides with authored app member")
    source = parent = stage = -1
    opened = []
    stage_name = None
    stage_identity = None
    try:
        source = resource.directory(args.staged/"bundle")
        if inventory(source,set(expected)) != set(expected):
            raise ValueError("Source bundle contains an unlisted or missing payload")
        source_info = os.fstat(source)
        # Admission happens before any destination is created.
        for target,(path,pin) in additions.items():
            fd = resource.readonly(path)
            opened.append((fd,path,os.fstat(fd),target,pin))
            if os.fstat(fd).st_size != pin[0] or resource.hash_fd(fd,pin[0]) != pin[1]:
                raise ValueError("Exact original/component source pin mismatch")
        parent = resource.directory(args.output.parent)
        parent_info = os.fstat(parent)
        def current():
            for path,fd,before in ((args.output.parent,parent,parent_info),(args.staged/"bundle",source,source_info)):
                now = os.stat(path,follow_symlinks=False)
                held = os.fstat(fd)
                if (not stat.S_ISDIR(now.st_mode) or (now.st_dev,now.st_ino) != (before.st_dev,before.st_ino) or
                        (held.st_dev,held.st_ino) != (before.st_dev,before.st_ino)):
                    raise ValueError("Source/destination parent changed")
            if stage >= 0:
                now = os.stat(stage_name,dir_fd=parent,follow_symlinks=False)
                if (now.st_dev,now.st_ino) != (stage_identity.st_dev,stage_identity.st_ino):
                    raise ValueError("Owned assembly stage changed")
        try:
            os.stat(args.output.name,dir_fd=parent,follow_symlinks=False)
        except FileNotFoundError:
            pass
        else:
            raise ValueError("Existing app output preserved")
        stage_name = ".original-diagnostic-app-"+uuid.uuid4().hex
        os.mkdir(stage_name,mode=0o700,dir_fd=parent)
        stage = os.open(stage_name,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW|os.O_CLOEXEC,dir_fd=parent)
        stage_identity = os.fstat(stage)
        for path,pin in expected.items():
            copy_member(source,path,stage,path,pin,current)
        for fd,path,before,target,pin in opened:
            current()
            def chunks(fd=fd,size=pin[0]):
                at = 0
                while at < size:
                    current()
                    data = os.pread(fd,min(1024*1024,size-at),at)
                    if not data:
                        raise ValueError("Pinned executable input changed")
                    yield data
                    at += len(data)
            resource.write_member(stage,target,chunks(),*pin)
            if resource.identity(before) != resource.identity(os.fstat(fd)):
                raise ValueError("Executable source identity changed")
        # Existing reviewed Mach-O API; /proc/self/fd keeps all output writes
        # attached to our held private stage even if an ancestor is renamed.
        current()
        baseline_parent,name = resource.relative_parent(stage,"OriginalClient/OriginalGenuineDuoShell")
        try:
            injected = inject_shell.inject(Path(f"/proc/self/fd/{baseline_parent}")/name,
                Path(f"/proc/self/fd/{stage}")/"OfflineDokkanStartupDiagnostic")
        finally:
            os.close(baseline_parent)
        current()
        if injected["prepared_sha256"] != ACTIVE_SHA or injected["compiled_sdk_unchanged"] is not True:
            raise ValueError("Unexpected active genuine shell")
        # Only active embedded executable images need execute permission. The
        # unchanged baseline/opaque seed remain read-only resource data.
        for target in ("OfflineDokkanStartupDiagnostic","Frameworks/OriginalDokkanEngine.dylib",
                "Frameworks/OfflineDokkanHost.dylib","Frameworks/AdjustSigSdk.framework/AdjustSigSdk"):
            fd = resource.relative_readonly(stage,target)
            try:
                os.fchmod(fd,0o500)
            finally:
                os.close(fd)
        info = dict(contract["authored_app_info"])
        info.update(CFBundleShortVersionString=args.version,CFBundleVersion=args.build)
        raw = plistlib.dumps(info,sort_keys=True)
        resource.write_member(stage,"Info.plist",(raw,),len(raw),hashlib.sha256(raw).hexdigest())
        result = {"format":"od-original-duo-unsigned-diagnostic-app-v1","purpose":contract["purpose"],
            "source_ipa_sha256":resource.SOURCE_SHA256,"extraction_manifest_sha256":args.manifest_sha256,
            "source_staging_receipt_sha256":args.staging_receipt_sha256,
            "component_receipt_sha256":args.component_receipt_sha256,
            "component_source_commit":component_commit,
            "bundle_identifier":contract["bundle_identifier"],"version":args.version,"build":args.build,
            "resource_members":len(expected),"active_shell_sha256_before_signing":ACTIVE_SHA,
            "original_bundle_aliases_preserved":True,"code_signed":False,"device_installed":False,
            "original_client_rendering_verified":False,"offline_login_verified":False,"playable_build":False}
        raw = (json.dumps(result,indent=2,sort_keys=True)+"\n").encode()
        resource.write_member(stage,"package-receipt.json",(raw,),len(raw),hashlib.sha256(raw).hexdigest())
        current()
        resource.publish_new_directory(parent,stage_name,args.output.name)
        stage_name = None
        os.fsync(parent)
        now = os.stat(args.output.parent,follow_symlinks=False)
        if (now.st_dev,now.st_ino) != (parent_info.st_dev,parent_info.st_ino):
            raise ValueError("Destination changed at publication; owned output preserved for review")
        return result
    finally:
        try:
            for fd,_,_,_,_ in opened:
                os.close(fd)
            if source >= 0:
                os.close(source)
            if stage >= 0:
                os.close(stage)
            if stage_name is not None and stage_identity is not None:
                try:
                    now = os.stat(stage_name,dir_fd=parent,follow_symlinks=False)
                except FileNotFoundError:
                    now = None
                if now is not None and (now.st_dev,now.st_ino) == (stage_identity.st_dev,stage_identity.st_ino):
                    if not shutil.rmtree.avoids_symlink_attacks:
                        raise ValueError("FD-relative rollback unavailable; owned stage preserved")
                    shutil.rmtree(stage_name,dir_fd=parent)
        finally:
            if parent >= 0:
                os.close(parent)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("staged","manifest","shell","engine","component","component-receipt","output"):
        parser.add_argument("--"+name,required=True,type=Path)
    for name in ("manifest-sha256","staging-receipt-sha256","component-receipt-sha256","version","build"):
        parser.add_argument("--"+name,required=True)
    parser.add_argument("--make-the-builds",action="store_true",help="Operator records explicit current build authorization")
    args = parser.parse_args()
    try:
        result = assemble(args)
    except (OSError,ValueError,KeyError,TypeError,AttributeError,json.JSONDecodeError,subprocess.SubprocessError):
        raise SystemExit("Diagnostic assembly stopped; original inputs and existing outputs preserved.")
    print(json.dumps({"scope":"Unsigned original-client diagnostic app only; not playable",
        "resource_members":result["resource_members"],"code_signed":False,"playable_build":False}))


if __name__ == "__main__":
    main()
