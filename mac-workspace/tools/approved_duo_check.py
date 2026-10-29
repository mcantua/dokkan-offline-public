#!/usr/bin/env python3
"""Approved Unit Creator signing/install/display check; never prints raw signing/device logs.

Run on Tin's Mac. Pure validation helpers also support one cloud synthetic check.
"""
import argparse
import datetime
import fnmatch
import hashlib
import json
import math
import os
import pathlib
import platform
import plistlib
import re
import shutil
import signal
import stat
import subprocess
import tempfile
import time
import zipfile

VERSION = "2.36.3"
BUILD = "128"
SOURCE_SHA256 = "1b3fa2ae1526c83afdd8acd98b12c9e35b699a086f7011bf5a389f41cd857d60"
TEAM = "P4NRE7Q8ZT"
BUNDLE = "com.dokkanunitcreator.ios." + TEAM
def _configured_device():
    value = os.environ.get("DUO_UDID", "").strip()
    if value:
        return value
    here = pathlib.Path(__file__).resolve()
    candidates = [here.parents[2] / "config" / "private.local", pathlib.Path.cwd() / "config" / "private.local"]
    for candidate in candidates:
        if candidate.is_file():
            for line in candidate.read_text(encoding="utf-8", errors="replace").splitlines():
                line = line.strip()
                if line.startswith("DUO_UDID="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    return "00000000-0000000000000000"

DEFAULT_DEVICE = _configured_device()



class CheckFailure(Exception):
    pass


def digest(path):
    h = hashlib.sha256()
    with pathlib.Path(path).open("rb") as stream:
        for data in iter(lambda: stream.read(1024 * 1024), b""): h.update(data)
    return h.hexdigest()


def verify_source_ipa(path, expected=SOURCE_SHA256):
    if digest(path) != expected: raise CheckFailure("IPA_HASH_MISMATCH")
    with zipfile.ZipFile(path) as archive:
        infos = archive.infolist()
        if len(infos) > 20000 or sum(x.file_size for x in infos) > 1024 * 1024 * 1024:
            raise CheckFailure("IPA_SIZE_INVALID")
        for entry in infos:
            parts = pathlib.PurePosixPath(entry.filename).parts
            if not parts or parts[0] != "Payload" or ".." in parts or "\\" in entry.filename:
                raise CheckFailure("IPA_PATH_INVALID")
            if stat.S_ISLNK(entry.external_attr >> 16): raise CheckFailure("IPA_SYMLINK_NOT_ALLOWED")
        plist_entries = [x for x in infos if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", x.filename)]
        if len(plist_entries) != 1 or plist_entries[0].filename != "Payload/App.app/Info.plist":
            raise CheckFailure("IPA_APPLICATION_INVALID")
        info = plistlib.loads(archive.read(plist_entries[0]))
        if str(info.get("CFBundleShortVersionString")) != VERSION or str(info.get("CFBundleVersion")) != BUILD:
            raise CheckFailure("IPA_VERSION_MISMATCH")
        if info.get("CFBundleIdentifier") != "com.dokkanunitcreator.ios" or info.get("CFBundleExecutable") != "App":
            raise CheckFailure("IPA_IDENTIFIER_MISMATCH")
        if archive.testzip() is not None: raise CheckFailure("IPA_CRC_FAILED")
    return info


def profile_selection(profile, identities, device, now=None):
    now = now or datetime.datetime.now(datetime.timezone.utc)
    expires = profile.get("ExpirationDate")
    if not isinstance(expires, datetime.datetime): raise CheckFailure("PROFILE_EXPIRATION_INVALID")
    if expires.tzinfo is None: expires = expires.replace(tzinfo=datetime.timezone.utc)
    if expires <= now: raise CheckFailure("PROFILE_EXPIRED")
    if TEAM not in profile.get("TeamIdentifier", []) or device not in profile.get("ProvisionedDevices", []):
        raise CheckFailure("PROFILE_TEAM_OR_DEVICE_MISMATCH")
    ent = profile.get("Entitlements", {})
    appid = ent.get("application-identifier", "")
    prefixes = profile.get("ApplicationIdentifierPrefix", [])
    if not any(appid == str(prefix) + "." + BUNDLE for prefix in prefixes):
        raise CheckFailure("PROFILE_APPLICATION_MISMATCH")
    if ent.get("com.apple.developer.team-identifier") != TEAM or ent.get("get-task-allow") is not True:
        raise CheckFailure("PROFILE_NOT_EXPECTED_DEVELOPMENT_PROFILE")
    certificates = profile.get("DeveloperCertificates", [])
    allowed = {hashlib.sha1(x).hexdigest().upper() for x in certificates if isinstance(x, bytes)}
    available = []
    for line in identities.splitlines():
        if "Apple Development" not in line and "iPhone Developer" not in line: continue
        match = re.search(r"\b([A-Fa-f0-9]{40})\b", line)
        if match and match[1].upper() in allowed: available.append(match[1].upper())
    if not available: raise CheckFailure("NO_MATCHING_PROFILE_IDENTITY")
    # Only app-required baseline entitlements, all checked against the selected profile.
    result = {"application-identifier": appid, "com.apple.developer.team-identifier": TEAM, "get-task-allow": True}
    groups = ent.get("keychain-access-groups", [])
    if groups:
        if not any(isinstance(group, str) and fnmatch.fnmatchcase(appid, group) for group in groups):
            raise CheckFailure("PROFILE_KEYCHAIN_GROUP_MISMATCH")
        result["keychain-access-groups"] = [appid]
    return available[0], result


def records(path):
    if pathlib.Path(path).stat().st_size > 2 * 1024 * 1024: raise CheckFailure("DISPLAY_LOG_TOO_LARGE")
    out = []
    for line in pathlib.Path(path).read_text(errors="replace").splitlines():
        try: row = json.loads(line)
        except json.JSONDecodeError: continue
        t = row.get("time") if isinstance(row, dict) else None
        if isinstance(t, (int, float)) and math.isfinite(t): out.append(row)
    return out


def display_sample(path, since, after=None):
    rows = [r for r in records(path) if r["time"] >= since and (after is None or r["time"] > after)]
    if not rows: raise CheckFailure("NO_FRESH_DISPLAY_RECORD")
    row = max(rows, key=lambda x: x["time"])
    page, screen = row.get("page"), row.get("screen")
    if not isinstance(page, dict) or page.get("startup") != "ready": raise CheckFailure("APP_STARTUP_NOT_READY")
    if not isinstance(screen, dict): raise CheckFailure("SCREEN_GEOMETRY_MISSING")
    def number(value):
        if not isinstance(value, (int, float)) or not math.isfinite(value) or value <= 0: raise CheckFailure("DISPLAY_GEOMETRY_INVALID")
        return float(value)
    w, h = number(row.get("width")), number(row.get("height"))
    pw, iw, ih = number(page.get("pageWidth")), number(page.get("innerWidth")), number(page.get("innerHeight"))
    sw, sh = number(screen.get("width")), number(screen.get("height"))
    if max(abs(pw-w), abs(iw-w), abs(sw-w), abs(sh-h), abs(ih-h)) > 1:
        raise CheckFailure("PAGE_WINDOW_SCREEN_GEOMETRY_MISMATCH")
    return {"time": row["time"], "startup": "ready", "window_width": w, "window_height": h,
            "page_width": pw, "inner_width": iw, "inner_height": ih, "screen_width": sw, "screen_height": sh,
            "dpr": number(page.get("dpr")), "widths_agree": True, "height_fills_screen": True}


def missing_log(text):
    # This is inspected privately. Do not emit the raw error, which can contain private paths/device data.
    return bool(re.search(r"no such file or directory|NSCocoaErrorDomain[^\n]{0,100}(?:Code[=: ]+260\b)|NSPOSIXErrorDomain[^\n]{0,100}(?:Code[=: ]+2\b)", text, re.I))


def verify_fold_shapes(outer, inner, returned):
    a=sorted([outer["window_width"],outer["window_height"]])
    b=sorted([inner["window_width"],inner["window_height"]])
    if all(abs(x-y)<=1 for x,y in zip(a,b)): raise CheckFailure("FOLD_GEOMETRY_DID_NOT_CHANGE")
    if abs(outer["window_width"]-returned["window_width"])>1 or abs(outer["window_height"]-returned["window_height"])>1:
        raise CheckFailure("OUTER_RETURN_GEOMETRY_MISMATCH")


def atomic_json(path, value):
    path = pathlib.Path(path); path.parent.mkdir(parents=True, exist_ok=True)
    part = path.with_suffix(".part")
    try:
        part.write_text(json.dumps(value, indent=2) + "\n")
        part.replace(path)
    finally: part.unlink(missing_ok=True)


def run(args):
    if platform.system() != "Darwin": raise CheckFailure("MAC_REQUIRED")
    os.umask(0o077)
    workspace = pathlib.Path(os.environ.get("DOKKAN_WORKSPACE", str(pathlib.Path.home() / "AI-Workspace/Dokkan-Unit-Creator"))).expanduser().resolve()
    device = DEFAULT_DEVICE
    if os.environ.get("DUO_UDID",device) != device: raise CheckFailure("APPROVED_DEVICE_MISMATCH")
    output = workspace / "evidence/approved-duo/result.json"
    state = {"version": VERSION, "build": BUILD, "source_sha256": SOURCE_SHA256,
             "status": "RUNNING", "stages": [], "install_operation_performed": False,
             "not_tested": ["touch controls", "keyboard input", "scrolling", "file import/export", "saved-data persistence", "fold animation smoothness", "screenshots"]}
    def stage(name):
        state["current_stage"] = name
        state["stages"].append({"stage": name, "time": datetime.datetime.now().astimezone().isoformat(timespec="seconds")})
        atomic_json(output, state)
        print(time.strftime("%I:%M %p") + "  " + name.replace("_", " "), flush=True)
    workspace.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".approved-duo-",dir=workspace) as temp:
        private = pathlib.Path(temp)
        def command(argv, name, target=None, timeout=180):
            dest = target or private / "private-command.log"
            with dest.open("wb") as stream:
                result = subprocess.run(argv, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
            if result.returncode: raise CheckFailure(name)
        def copy_log(dest):
            dest.unlink(missing_ok=True)
            command(["xcrun","devicectl","device","copy","from","--device",device,"--domain-type","appDataContainer","--domain-identifier",BUNDLE,
                     "--source","Library/display-log.jsonl","--destination",str(dest),"--timeout","30"], "DISPLAY_LOG_COPY_FAILED")
        def capture(label, since, after):
            latest = "NO_FRESH_DISPLAY_RECORD"
            for _ in range(10):
                time.sleep(3)
                try:
                    path = private / (label + ".jsonl")
                    copy_log(path)
                    return display_sample(path, since, after)
                except CheckFailure as error: latest = str(error)
            raise CheckFailure(latest)
        try:
            stage("checking_tools_and_device")
            for tool in ["xcrun", "xcodebuild", "codesign", "security", "zip", "osascript"]:
                if not shutil.which(tool): raise CheckFailure("REQUIRED_MAC_TOOL_MISSING")
            command(["xcrun","devicectl","device","info","details","--device",device,"--timeout","30"], "DEVICE_NOT_READY")
            app = None
            if not args.check_installed:
                stage("verifying_exact_source_ipa")
                source = args.ipa
                if source is None:
                    bundle = pathlib.Path(__file__).resolve().parent.parent
                    candidates = [bundle / "UnitCreator-2.36.3.ipa", bundle.parent / "UnitCreator-2.36.3.ipa", pathlib.Path.home() / "Downloads/UnitCreator-2.36.3.ipa"]
                    source = next((p for p in candidates if p.is_file() and digest(p) == SOURCE_SHA256), None)
                    if source is None:
                        result = subprocess.run(["osascript","-e",'POSIX path of (choose file with prompt "Choose the downloaded UnitCreator-2.36.3.ipa")'],capture_output=True,text=True)
                        if result.returncode: raise CheckFailure("OPERATOR_CANCELLED")
                        source = pathlib.Path(result.stdout.strip())
                verify_source_ipa(source)
                if pathlib.Path(source).resolve() == (workspace/"build/UnitCreator-approved-device.ipa").resolve():
                    raise CheckFailure("SOURCE_EQUALS_MANAGED_OUTPUT")
                project = workspace / "signing/DokkanSigning.xcodeproj"
                if not (project / "project.pbxproj").is_file(): raise CheckFailure("SIGNING_PROJECT_MISSING")
                stage("provisioning_existing_signing_project")
                command(["xcodebuild","-project",str(project),"-scheme","DokkanSigning","-configuration","Debug","-sdk","iphoneos","-destination","id="+device,
                         "-derivedDataPath",str(private/"DerivedData"),"-allowProvisioningUpdates","-allowProvisioningDeviceRegistration","CODE_SIGN_STYLE=Automatic",
                         "DEVELOPMENT_TEAM="+TEAM,"PRODUCT_BUNDLE_IDENTIFIER="+BUNDLE,"build","-quiet"],"PROVISIONING_FAILED",timeout=900)
                profile = private / "DerivedData/Build/Products/Debug-iphoneos/DokkanSigning.app/embedded.mobileprovision"
                if not profile.is_file(): raise CheckFailure("GENERATED_PROFILE_MISSING")
                command(["security","cms","-D","-i",str(profile)],"PROFILE_DECODE_FAILED",private/"profile.plist")
                command(["security","find-identity","-v","-p","codesigning"],"IDENTITY_LOOKUP_FAILED",private/"identities.txt")
                identity, entitlements = profile_selection(plistlib.loads((private/"profile.plist").read_bytes()),(private/"identities.txt").read_text(),device)
                (private/"entitlements.plist").write_bytes(plistlib.dumps(entitlements))
                stage("signing_private_candidate")
                unpacked = private / "unpacked"
                with zipfile.ZipFile(source) as archive: archive.extractall(unpacked)
                app = unpacked / "Payload/App.app"
                info_path = app/"Info.plist"; info=plistlib.loads(info_path.read_bytes()); info["CFBundleIdentifier"]=BUNDLE; info_path.write_bytes(plistlib.dumps(info,fmt=plistlib.FMT_BINARY))
                shutil.copy2(profile,app/"embedded.mobileprovision")
                shutil.rmtree(app/"_CodeSignature",ignore_errors=True)
                for item in app.rglob("*"):
                    item.chmod(0o755 if item.is_dir() else 0o644)
                app.chmod(0o755)
                (app/"App").chmod(0o755)
                command(["codesign","--force","--sign",identity,"--entitlements",str(private/"entitlements.plist"),"--generate-entitlement-der",str(app)],"SIGNING_FAILED")
                command(["codesign","--verify","--strict",str(app)],"SIGNATURE_VERIFY_FAILED")
                command(["codesign","-d","--entitlements",":-",str(app)],"SIGNED_ENTITLEMENTS_READ_FAILED",private/"signed-entitlements.plist")
                # codesign diagnostic output may surround XML; only parse its plist section privately.
                raw=(private/"signed-entitlements.plist").read_bytes(); start=raw.find(b'<?xml'); end=raw.find(b'</plist>',start)
                if start<0 or end<0: raise CheckFailure("SIGNED_ENTITLEMENTS_INVALID")
                signed_ent=plistlib.loads(raw[start:end+8])
                if signed_ent.get("application-identifier")!=entitlements["application-identifier"] or signed_ent.get("com.apple.developer.team-identifier")!=TEAM:
                    raise CheckFailure("SIGNED_ENTITLEMENTS_MISMATCH")
                stage("installing_verified_candidate")
                command(["xcrun","devicectl","device","install","app","--device",device,str(app),"--timeout","600"],"INSTALL_FAILED",timeout=660)
                state["install_operation_performed"]=True
            else:
                state["installed_version_verified"]=False
                print("Display-check mode: installed app version is not asserted.",flush=True)
            stage("recording_prelaunch_log_baseline")
            before=private/"before.jsonl"
            try:
                copy_log(before)
                rows=records(before); baseline=max((r["time"] for r in rows),default=None)
                if before.stat().st_size and not rows: raise CheckFailure("EXISTING_DISPLAY_LOG_INVALID")
            except CheckFailure as error:
                if str(error)!="DISPLAY_LOG_COPY_FAILED" or not missing_log((private/"private-command.log").read_text(errors="replace")): raise
                baseline=None
            input("Keep the phone closed on its outer portrait display, unlocked. Press Return to launch Unit Creator. ")
            stage("launching_outer_display")
            launched=int(time.time())
            command(["xcrun","devicectl","device","process","launch","--device",device,"--terminate-existing",BUNDLE,"--timeout","30"],"LAUNCH_FAILED")
            print("Wait for Home. If needed, rotate sideways then upright once to refresh the display record.",flush=True)
            outer=capture("outer",launched,baseline)
            inner_start=int(time.time())
            input("Open the phone to its inner display, wait for Home, then press Return. ")
            stage("checking_inner_display")
            inner=capture("inner",inner_start,outer["time"])
            return_start=int(time.time())
            input("Fold closed to the outer portrait display again, wait for Home, then press Return. ")
            stage("checking_return_to_outer_display")
            returned=capture("outer_return",return_start,inner["time"])
            verify_fold_shapes(outer,inner,returned)
            state["display_samples"]={"outer":outer,"inner":inner,"outer_after_fold":returned}
            state["fresh_startup_ready"]=True
            state["fold_geometry_observed"]=True
            if app is not None:
                stage("saving_verified_signed_package")
                candidate=private/"UnitCreator-approved-device.ipa"
                # Run zip from the private candidate tree; no original or old working IPA is modified.
                with (private/"private-command.log").open("wb") as log:
                    result=subprocess.run(["zip","-qry",str(candidate),"Payload"],cwd=app.parent.parent,stdout=log,stderr=subprocess.STDOUT)
                if result.returncode: raise CheckFailure("SIGNED_PACKAGE_FAILED")
                with zipfile.ZipFile(candidate) as archive:
                    if archive.testzip() is not None: raise CheckFailure("SIGNED_PACKAGE_CRC_FAILED")
                destination=workspace/"build/UnitCreator-approved-device.ipa"; destination.parent.mkdir(parents=True,exist_ok=True)
                # Atomic same-filesystem promotion; keep the former helper-managed package until replacement succeeds.
                fd,part_name=tempfile.mkstemp(prefix=".approved-duo-",dir=destination.parent)
                os.close(fd); part=pathlib.Path(part_name)
                try:
                    shutil.copy2(candidate,part)
                    with part.open("rb") as stream: os.fsync(stream.fileno())
                    os.replace(part,destination)
                finally: part.unlink(missing_ok=True)
                state["signed_package_sha256"]=digest(destination)
                state["installed_version_verified"]=True
                state["status"]="INSTALLED_LAUNCHED_DISPLAY_CHECKED"
            else: state["status"]="DISPLAY_CHECKED_ONLY"
            stage("checks_recorded")
            print("Sanitized result saved under evidence/approved-duo/result.json. Attach only that JSON in chat.",flush=True)
            return 0
        except KeyboardInterrupt:
            state.update(status="FAILED",failure="OPERATOR_CANCELLED"); atomic_json(output,state)
            print("Stopped; no success recorded. Private temporary files are removed.",flush=True)
            return 130
        except Exception as error:
            code=str(error) if isinstance(error,CheckFailure) else "MAC_OPERATION_FAILED"
            state.update(status="FAILED",failure=code); atomic_json(output,state)
            print("Check stopped: "+code+". No success recorded. Attach only evidence/approved-duo/result.json.",flush=True)
            return 1


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa",type=pathlib.Path,nargs="?")
    parser.add_argument("--check-installed",action="store_true",help="display-only check; does not claim an installed version")
    args=parser.parse_args()
    def cancelled(signum, frame): raise KeyboardInterrupt
    for sig in [signal.SIGHUP, signal.SIGTERM]: signal.signal(sig,cancelled)
    try: return run(args)
    except Exception:
        print("Check could not start. Use the approved bundle on the Mac with Xcode and the selected phone.")
        return 1


if __name__=="__main__": raise SystemExit(main())
