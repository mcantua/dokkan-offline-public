#!/usr/bin/env python3
"""Reviewed physical-device workflow. Default dry-run; --execute requires prior Tin approval.

Never run on Tin's Mac/personal connection before explicit approval. Apple credentials
stay in Xcode's UI/OS Keychain. Every private runtime product is ignored beneath private/.
"""
from __future__ import annotations
import argparse, datetime as dt, hashlib, json, os, pathlib, plistlib, re, selectors, shutil, subprocess, sys, tempfile, time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PRIVATE = HERE / "private"
BUNDLE_PREFIX = "org.tin.appinstaller"
PAIR_URL = "https://github.com/jkcoxson/idevice_pair/releases/download/v1.1.0/idevice_pair--macos-universal.dmg"
DUO_MODELS = frozenset({"iPhone19,4"})  # Root verified current specs/hosted device enumeration.
PAIR_BYTES = 57690695
PAIR_SHA256 = "9ff54171dccdb0a9b0e72ec89e43a479823c53ee54c2121fe9f053cc2cb940ce"
ALLOWED_ENTITLEMENTS = {"application-identifier", "com.apple.developer.team-identifier", "keychain-access-groups", "get-task-allow"}

class WorkflowError(Exception): pass

def contained(path: pathlib.Path, base: pathlib.Path = ROOT) -> pathlib.Path:
    resolved = path.expanduser().resolve()
    if not resolved.is_relative_to(base.resolve()):
        raise WorkflowError("All project files must stay inside this repository.")
    return resolved

def checked_file(path: pathlib.Path) -> pathlib.Path:
    if path.expanduser().is_symlink(): raise WorkflowError("Required project input must not be a symbolic link.")
    path = contained(path)
    if not path.is_file(): raise WorkflowError("Required project input is missing or is not a regular file.")
    return path

def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""): digest.update(block)
    return digest.hexdigest()

def command(argv: list[str], *, step: str) -> bytes:
    # Capture output instead of exposing identifiers, account labels, certificate names,
    # profiles or Xcode's raw diagnostics in chat/repo logs. No shell or trace mode.
    result = subprocess.run(argv, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise WorkflowError(f"{step} did not finish. Review it in Xcode on the approved Mac; no raw account/device output was saved.")
    return result.stdout

def mac_only() -> None:
    if sys.platform != "darwin": raise WorkflowError("Execution requires the approved Mac with Xcode. Dry-run works in the cloud.")
    if ROOT.name!="claude-chatg" or ROOT.parent.name!="AI-Workspace":
        raise WorkflowError("Keep this single project inside AI-Workspace/claude-chatg before approved execution.")
    if not shutil.which("xcrun") or not shutil.which("xcodebuild"):
        raise WorkflowError("Open the existing full Xcode app, then Xcode → Settings → Locations → Command Line Tools and select that Xcode. Command Line Tools alone cannot build this app. If full Xcode is missing, stop for separate approval before a large download.")

def local_preflight() -> dict:
    """Read-only tool/SDK checks, before any device or account discovery."""
    if sys.version_info < (3,9):
        raise WorkflowError("Python 3.9 or newer is required. Use a compatible existing local Python or install trusted Python within the already approved dependency setup scope.")
    full_xcode="Open the existing full Xcode app, then Xcode → Settings → Locations → Command Line Tools and select that Xcode. Command Line Tools alone are insufficient. If Xcode is missing, stop for separate approval before a large download."
    blocked_xcode="Xcode could not report its version/SDK. Open the selected Xcode locally, complete its normal first-launch/license screen, then rerun setup. A large Xcode/SDK download still needs separate approval. This read-only preflight accepts no license and changes no tools."
    try:
        selected=os.environ.get("DEVELOPER_DIR") or command(["xcode-select","--print-path"],step="Selected Xcode discovery").decode().strip()
        developer=pathlib.Path(selected)
        if developer.suffix==".app":developer=developer/"Contents/Developer"
        if not developer.is_dir() or developer.name!="Developer" or developer.parent.name!="Contents" or developer.parent.parent.suffix!=".app":
            raise WorkflowError(full_xcode)
        xcode=command(["xcodebuild","-version"],step="Read-only Xcode version discovery").decode().strip()
        if not re.search(r"(?m)^Xcode \d+(?:\.\d+)*$",xcode):raise WorkflowError(blocked_xcode)
        sdk=command(["xcrun","--sdk","iphoneos","--show-sdk-version"],step="Read-only iPhoneOS SDK discovery").decode().strip()
    except (OSError,UnicodeError,WorkflowError) as error:
        if isinstance(error,WorkflowError) and str(error) in {full_xcode,blocked_xcode}:raise
        raise WorkflowError(blocked_xcode) from None
    if (version(sdk)+(0,))[:2] < (27,1):
        raise WorkflowError("This Duo setup needs an actual iPhoneOS SDK 27.1 or newer. In Xcode → Settings → Locations → Command Line Tools select an already installed compatible full Xcode. If none is installed, stop: a large Xcode/SDK download needs separate approval. Nothing was downloaded or changed.")
    try:
        for tool in ["devicectl","vtool","lipo"]:
            command(["xcrun","--find",tool],step="Read-only Xcode tool availability check")
    except (OSError,WorkflowError):raise WorkflowError(full_xcode) from None
    for tool in ["security","codesign","osascript","open"]:
        if not shutil.which(tool):raise WorkflowError("Required built-in macOS setup tools are unavailable. Review the selected full Xcode/macOS installation locally; no tool download or account change was attempted.")
    return {"xcode":xcode,"iphoneos_sdk":sdk,"preflight_passed":True,"device_queried":False,"account_queried":False}

def safe_relative(value: str) -> pathlib.PurePosixPath:
    if not isinstance(value,str) or not value or "\\" in value or "\x00" in value:
        raise WorkflowError("Bootstrap kit contains an unsupported path.")
    path=pathlib.PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or str(path)!=value:
        raise WorkflowError("Bootstrap kit path escapes its single project folder.")
    return path

def bootstrap_kit() -> dict | None:
    manifest_path=ROOT/"BootstrapKitManifest.json"
    if not manifest_path.exists(): return None
    try: manifest=json.loads(checked_file(manifest_path).read_text())
    except (ValueError,OSError): raise WorkflowError("Bootstrap kit manifest is unreadable.") from None
    if (not isinstance(manifest,dict) or type(manifest.get("schema_version")) is not int or manifest["schema_version"]!=1 or manifest.get("test_fixture") is not False or manifest.get("project")!="claude-chatg"
        or not re.fullmatch(r"[0-9a-f]{40}",str(manifest.get("source_commit","")))
        or not re.fullmatch(r"[0-9a-f]{40}",str(manifest.get("bootstrap_tool_commit","")))
        or not re.fullmatch(r"[0-9a-f]{64}",str(manifest.get("source_tree_sha256","")))
        or not isinstance(manifest.get("files"),list) or not manifest["files"]):
        raise WorkflowError("Bootstrap kit source identity is incomplete.")
    seen=set()
    for entry in manifest["files"]:
        if not isinstance(entry,dict) or "path" not in entry:
            raise WorkflowError("Bootstrap kit file identities are incomplete.")
        relative=str(safe_relative(entry["path"]))
        if relative in seen: raise WorkflowError("Bootstrap kit has duplicate file identities.")
        if pathlib.PurePosixPath(relative).suffix.lower() in {".p12",".p8",".key",".pem",".mobileprovision",".mobiledevicepairing"} or pathlib.PurePosixPath(relative).name==".env":
            raise WorkflowError("Credentials, profiles and pairing exports cannot be bootstrap kit payloads, even under private paths.")
        seen.add(relative);file=checked_file(ROOT/relative)
        if type(entry.get("bytes")) is not int or file.stat().st_size!=entry["bytes"] or sha256(file)!=entry.get("sha256"):
            raise WorkflowError("Bootstrap kit content changed from the reviewed cloud transfer.")
    required={"README.md","app-installer/LICENSE","app-installer/licensing-signing.md","app-installer/device/.gitignore","app-installer/device/device-workflow.py","app-installer/ios/Info.plist","app-installer/core/app_installer.h","app-installer/core/secure_storage.h",manifest.get("rust_library"),manifest.get("library_manifest")}
    if not required<=seen or not set(manifest.get("native_sources",[]))<=seen or not manifest.get("native_sources"):
        raise WorkflowError("Bootstrap kit omits a required native build input.")
    expected_ios={path for path in seen if path.startswith("app-installer/ios/")}
    actual_ios={str(path.relative_to(ROOT)) for path in (ROOT/"app-installer/ios").rglob("*")
                if path.is_file() and path.suffix in {".m",".h",".plist",".png"}}
    if actual_ios!=expected_ios:
        raise WorkflowError("Native source/resources include files outside the reviewed kit. Reconcile them before signing; nothing was deleted.")
    marker=(ROOT/"app-installer/device/.gitignore").read_text().splitlines()
    if "/private/" not in marker: raise WorkflowError("Bootstrap private runtime area must remain excluded from git.")
    source=manifest.get("corresponding_source",{})
    if (not isinstance(source,dict) or not re.fullmatch(r"[0-9a-f]{64}",str(source.get("sha256","")))
        or type(source.get("bytes")) is not int or source["bytes"]<=0
        or not isinstance(source.get("file"),str) or not source["file"] or len(safe_relative(source["file"]).parts)!=1
        or source.get("delivery")!="separate-cloud-companion-artifact"
        or source.get("artifact")!="app-installer-cloud-ui-latest"
        or source.get("path")!="candidates/"+source["file"]):
        raise WorkflowError("Matching complete source/relink delivery is not identified alongside this minimal kit.")
    if manifest.get("secure_rp_tool") is not None:
        validate_remote_pairing_tool(manifest, seen)
    return manifest

def validate_remote_pairing_tool(kit: dict, payload_paths: set[str] | None = None) -> pathlib.Path:
    """Bind the executable to this kit's reviewed source and complete notices.

    Hashes establish transfer integrity, not notarization or a device result. The
    executable is also checked by macOS immediately before approved execution.
    """
    tool=kit.get("secure_rp_tool")
    paths={"binary":"app-installer/device/tools/app-installer-rp-bootstrap",
           "manifest":"app-installer/device/tools/RPBootstrapBuildManifest.json",
           "notices":"app-installer/device/tools/RPBootstrapThirdPartyNotices.txt",
           "notice_report":"app-installer/device/tools/RPBootstrapThirdPartyNoticeReport.json"}
    error="The authenticated remote-pairing helper is missing or differs from this reviewed kit. Use the matching new kit; no pairing action was started."
    if not isinstance(tool,dict): raise WorkflowError(error)
    if (any(tool.get(k)!=v for k,v in paths.items())
        or tool.get("source_commit")!=kit.get("source_commit")
        or tool.get("source_tree_sha256")!=kit.get("source_tree_sha256")
        or tool.get("version")!="0.1.0" or tool.get("architectures")!=["arm64","x86_64"]
        or type(tool.get("protocol_record_version")) is not int or tool["protocol_record_version"]!=2
        or tool.get("ad_hoc_signed") is not True or tool.get("notarized") is not False):
        raise WorkflowError(error)
    entries={entry["path"]:entry for entry in kit.get("files",[]) if isinstance(entry,dict) and isinstance(entry.get("path"),str)}
    for relative in paths.values():
        if relative not in entries or (payload_paths is not None and relative not in payload_paths): raise WorkflowError(error)
        path=checked_file(ROOT/relative);entry=entries[relative]
        if type(entry.get("bytes")) is not int or path.stat().st_size!=entry["bytes"] or sha256(path)!=entry.get("sha256"):
            raise WorkflowError(error)
    try:
        receipt=json.loads((ROOT/paths["manifest"]).read_text())
        notices=json.loads((ROOT/paths["notice_report"]).read_text())
    except (OSError,ValueError): raise WorkflowError(error) from None
    source=kit.get("corresponding_source",{})
    if (not isinstance(receipt,dict) or receipt.get("schema_version")!=1 or receipt.get("test_fixture") is not False
        or receipt.get("tool")!="app-installer-rp-bootstrap" or receipt.get("build_succeeded") is not True
        or any(receipt.get(k)!=tool[k] for k in ["source_commit","source_tree_sha256","version","architectures","protocol_record_version","ad_hoc_signed","notarized"])
        or receipt.get("targets")!=["aarch64-apple-darwin","x86_64-apple-darwin"]
        or receipt.get("minimum_macos")!="12.0" or receipt.get("apple_developer_identity_used") is not False
        or receipt.get("version_only_executed") is not True or receipt.get("usb_or_pairing_executed") is not False
        or receipt.get("personal_resources_used") is not False or receipt.get("corresponding_source_delivery_pending") is not False
        or receipt.get("source_bundle_sha256")!=source.get("sha256")
        or receipt.get("source_bundle_file")!=source.get("file") or receipt.get("source_bundle_bytes")!=source.get("bytes")
        or receipt.get("source_bundle_delivery")!="separate-cloud-companion-artifact"
        or not re.fullmatch(r"[0-9a-f]{64}",str(receipt.get("locked_dependency_graph_hash","")))
        or not isinstance(notices,dict) or notices.get("notice_obligations_satisfied") is not True
        or type(notices.get("notice_gap_count")) is not int or notices["notice_gap_count"]!=0
        or notices.get("locked_dependency_graph_hash")!=receipt.get("locked_dependency_graph_hash")
        or notices.get("target_graph_hashes")!=receipt.get("target_graph_hashes")
        or notices.get("targets")!=receipt.get("targets")):
        raise WorkflowError(error)
    for field in ["binary","notices","notice_report"]:
        record=receipt.get(field);entry=entries[paths[field]]
        if (not isinstance(record,dict) or record.get("file")!=pathlib.PurePosixPath(paths[field]).name
            or record.get("bytes")!=entry["bytes"] or record.get("sha256")!=entry["sha256"]):
            raise WorkflowError(error)
    return checked_file(ROOT/paths["binary"])

REMOTE_PAIRING_FAILURES = {
    "use the reviewed wizard arguments and explicit consent.": "The pairing helper did not receive its reviewed setup arguments.",
    "this helper requires the approved Mac USB connection.": "The pairing helper requires the approved Mac USB connection.",
    "the existing reviewed setup project could not be verified.": "The pairing helper could not verify the existing setup folder.",
    "the private export folder must be owned by this user, private and free of symlinks.": "The private pairing folder has unsafe ownership, permissions or a symbolic link. Existing files were preserved.",
    "a private export or interrupted export already exists; it was preserved.": "An existing private pairing export could not be reused safely. It was preserved; do not delete or overwrite it blindly.",
    "the system USB device service is unavailable.": "The Mac USB device service could not be reached.",
    "the selected physical USB iPhone could not be verified.": "The helper could not find and verify the selected iPhone over USB. Xcode Wi-Fi visibility alone is insufficient for this USB step.",
    "existing system USB trust is unavailable; use the normal Apple Trust UI first.": "The Mac could not load existing USB trust. Unlock the phone and complete its normal Trust prompt.",
    "the authenticated USB identity or session could not be verified.": "The trusted USB session or remote-pairing service could not be verified. No security check was bypassed.",
    "explicit remote pairing was cancelled or could not be authenticated; no new export was committed.": "The remote-pairing authentication did not finish. No new private export was committed.",
    "newly paired identity could not be verified on a fresh USB connection; no new export was committed.": "The new pairing identity could not reconnect securely over USB. No new private export was committed; existing files were preserved.",
    "the authenticated version-2 device pin could not be verified.": "The new pairing record did not pass its device-identity checks. It was not exported.",
    "private export could not finish; keep any existing export for reviewed recovery.": "The private pairing export could not be saved safely. Existing exports were preserved.",
    "secure operation interrupted; preserve existing private exports.": "The private pairing helper was interrupted. Existing exports were preserved.",
}

REMOTE_PAIRING_REASON_CODES = dict(zip(REMOTE_PAIRING_FAILURES, (
    "ARGUMENTS", "PLATFORM", "PROJECT", "PRIVATE_FOLDER", "EXISTING_EXPORT",
    "USB_SERVICE", "USB_SELECTION", "USB_TRUST", "USB_SECURE_SESSION_OR_SERVICE",
    "PAIR_AUTHENTICATION", "NEW_RECORD_VERIFICATION", "DEVICE_PIN", "SAVE_EXPORT", "INTERRUPTED")))
for text,code,message in (
    ("remote-pairing authentication timed out; no new export was committed.","PAIR_TIMEOUT","The iPhone pairing exchange timed out before a new export was committed."),
    ("the device rejected trusted USB remote pairing; no new export was committed.","PAIR_REJECTED","The iPhone rejected the new USB pairing request. No new private export was committed."),
    ("remote-pairing SRP proof could not be authenticated; no new export was committed.","PAIR_SRP_PROOF","The pairing proof could not be authenticated. No new private export was committed."),
    ("remote-pairing protocol data could not be decoded safely; no new export was committed.","PAIR_PROTOCOL","The pairing exchange returned unsupported protocol data. No new private export was committed."),
    ("remote-pairing USB transport failed; no new export was committed.","PAIR_TRANSPORT","The USB connection failed during pairing. No new private export was committed."),
    ("remote-pairing peer identity could not be authenticated; no new export was committed.","PAIR_PEER_IDENTITY","The iPhone pairing identity could not be authenticated. No new private export was committed."),
    ("the pairing helper exceeded its time limit; preserve existing exports for review.","HELPER_WALL_TIMEOUT","The pairing helper exceeded its time limit. Keep existing exports for review before retrying."),
    ("the pairing helper returned unsupported diagnostic output; preserve existing exports for review.","HELPER_OUTPUT_LIMIT","The pairing helper returned unsupported diagnostics. Keep existing exports for review; private output was not shown."),
):
    REMOTE_PAIRING_FAILURES[text]=message
    REMOTE_PAIRING_REASON_CODES[text]=code
REMOTE_PAIRING_PROGRESS = {
    "RP_BOOTSTRAP_STARTED":"Pairing helper started.",
    "RP_BOOTSTRAP_USB_SELECTED":"USB iPhone selected. Verifying trust…",
    "RP_BOOTSTRAP_USB_TRUST_VERIFIED":"USB trust verified. Starting remote pairing…",
    "RP_BOOTSTRAP_AUTHENTICATED_PAIRING_PENDING":"Beginning pairing authentication…",
    "RP_BOOTSTRAP_PAIR_CONSENT_PENDING":"Waiting for the iPhone’s pairing response…",
    "RP_BOOTSTRAP_PAIR_SRP_PROOF_PENDING":"Authenticating the pairing proof…",
    "RP_BOOTSTRAP_PAIR_PEER_RECORD_PENDING":"Exchanging the encrypted pairing record…",
    "RP_BOOTSTRAP_PAIR_PEER_IDENTITY_PENDING":"Verifying the iPhone’s pairing identity…",
    "RP_BOOTSTRAP_NEW_RECORD_VERIFY_PENDING":"Checking new pairing on a fresh USB connection…",
    "RP_BOOTSTRAP_NEW_RECORD_VERIFIED":"New pairing verified over USB.",
    "RP_BOOTSTRAP_EXISTING_VERIFIED":"Existing pairing verified over USB.",
    "RP_BOOTSTRAP_READY":"Private pairing export ready.",
}
REMOTE_PAIRING_STAGES = frozenset(REMOTE_PAIRING_PROGRESS)
REMOTE_PAIRING_WALL_SECONDS = 600

def run_remote_pairing(argv: list[str]) -> subprocess.CompletedProcess:
    """Drain both pipes with bounded memory; print only exact reviewed stages.

    No raw output, identifiers or record bytes reach Terminal. The deadline
    bounds the owned child after Popen returns; OS launch assessment can precede
    that boundary. An interrupted/expired operation is never called successful.
    """
    print("Starting verified USB pairing checks…",flush=True)
    process=subprocess.Popen(argv,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.PIPE,bufsize=0)
    selector=selectors.DefaultSelector()
    captured={"stdout":bytearray(),"stderr":bytearray()}
    line=bytearray();discard_line=False;seen=set();outcome=None
    deadline=time.monotonic()+REMOTE_PAIRING_WALL_SECONDS
    try:
        for name,stream in (("stdout",process.stdout),("stderr",process.stderr)):
            os.set_blocking(stream.fileno(),False)
            selector.register(stream,selectors.EVENT_READ,name)
        while selector.get_map():
            remaining=deadline-time.monotonic()
            if remaining<=0:outcome="the pairing helper exceeded its time limit; preserve existing exports for review.";break
            for key,_ in selector.select(min(remaining,0.2)):
                try:chunk=os.read(key.fd,4096)
                except BlockingIOError:continue
                if not chunk:
                    selector.unregister(key.fileobj);continue
                buffer=captured[key.data]
                if len(buffer)+len(chunk)>8192:
                    outcome="the pairing helper returned unsupported diagnostic output; preserve existing exports for review.";break
                buffer.extend(chunk)
                if key.data!="stdout":continue
                for byte in chunk:
                    if byte==10:
                        if not discard_line:
                            stage=bytes(line).removesuffix(b"\r").decode("ascii",errors="replace")
                            if stage in REMOTE_PAIRING_PROGRESS and stage not in seen:
                                print(REMOTE_PAIRING_PROGRESS[stage],flush=True);seen.add(stage)
                        line.clear();discard_line=False
                    elif len(line)<128 and not discard_line:line.append(byte)
                    else:line.clear();discard_line=True
            if outcome:break
        if not outcome:
            try:process.wait(timeout=max(0.001,deadline-time.monotonic()))
            except subprocess.TimeoutExpired:outcome="the pairing helper exceeded its time limit; preserve existing exports for review."
        if outcome:
            stderr=("RP_BOOTSTRAP_STOPPED: "+outcome+"\n").encode()
            return subprocess.CompletedProcess(argv,124 if "time limit" in outcome else 125,bytes(captured["stdout"]),stderr)
        return subprocess.CompletedProcess(argv,process.returncode,bytes(captured["stdout"]),bytes(captured["stderr"]))
    finally:
        # Own only this one helper process. Do not stop other apps, pairing
        # services, user sessions or trust records. Atomic export guards remain.
        if process.poll() is None:
            process.terminate()
            try:process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                try:process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    print("The pairing helper is still stopping. Keep existing exports and do not start another attempt yet.",flush=True)
        selector.close()
        process.stdout.close();process.stderr.close()

def remote_pairing_codes(returncode: int, stdout: bytes, stderr: bytes) -> tuple[str, str]:
    """Public troubleshooting codes only; never forward captured helper output."""
    def lines(raw):
        if not isinstance(raw,bytes) or len(raw)>8192:return []
        try:return raw.decode("utf-8").splitlines()
        except UnicodeError:return []
    stages=[line for line in lines(stdout) if line in REMOTE_PAIRING_STAGES]
    errors=[line[len("RP_BOOTSTRAP_STOPPED: "):] for line in lines(stderr)
            if line.startswith("RP_BOOTSTRAP_STOPPED: ")]
    reason=("PROCESS_STOPPED" if returncode<0 else
            REMOTE_PAIRING_REASON_CODES.get(errors[0],"UNCLASSIFIED") if len(errors)==1 else "UNCLASSIFIED")
    if returncode==0:reason="NONE"
    return (stages[-1] if stages else "NO_STAGE"),reason

def remote_pairing_failure(returncode: int, output: bytes) -> str:
    # Never forward arbitrary stderr, even from the hash-verified helper. Only
    # exact, reviewed public failure strings can select a fixed user message.
    if returncode < 0:
        return "The pairing helper was stopped before returning a result. Check the Mac for a normal security prompt; do not disable macOS security."
    try: lines=output[:8192].decode("utf-8").splitlines()
    except UnicodeError: lines=[]
    selected=[REMOTE_PAIRING_FAILURES[line.removeprefix("RP_BOOTSTRAP_STOPPED: ")]
              for line in lines if line.startswith("RP_BOOTSTRAP_STOPPED: ") and line.removeprefix("RP_BOOTSTRAP_STOPPED: ") in REMOTE_PAIRING_FAILURES]
    return selected[0] if len(selected)==1 else "Trusted USB remote pairing did not finish. Its failure was not recognized safely; no private output was shown."

def create_remote_pairing(args: argparse.Namespace) -> None:
    kit=bootstrap_kit()
    if kit is None:raise WorkflowError("Use the reviewed native kit containing the source-bound remote-pairing helper before this step.")
    binary=validate_remote_pairing_tool(kit)
    # Do not remove quarantine or bypass Gatekeeper. Hash-bound ad-hoc signing
    # checks file integrity; ordinary macOS security approval remains local.
    if not binary.stat().st_mode&0o111:raise WorkflowError("The reviewed pairing helper is not executable. Re-extract the verified kit with its permissions intact.")
    command(["codesign","--verify","--strict","--all-architectures",str(binary)],step="Remote-pairing helper signature integrity check")
    architectures=command(["xcrun","lipo","-archs",str(binary)],step="Remote-pairing helper architecture check").decode().split()
    if sorted(architectures)!=["arm64","x86_64"]:raise WorkflowError("The reviewed pairing helper must contain both verified Mac architectures.")
    diagnose(args)
    result=run_remote_pairing([str(binary),"--repo-root",str(ROOT),"--device-udid",args.physical_udid,"--consent"])
    stage,reason=remote_pairing_codes(result.returncode,result.stdout,result.stderr)
    print(f"PAIRING_EXIT: {result.returncode}")
    print(f"PAIRING_STAGE: {stage}")
    print(f"PAIRING_REASON: {reason}")
    if result.returncode:
        raise WorkflowError(remote_pairing_failure(result.returncode,result.stderr)+" Retry pairing only; the installed app does not need reinstalling. Do not paste private pairing data or raw device output.")
    export=private_path(PRIVATE/"secure-rp/pairing.mobiledevicepairing")
    if not export.is_file() or export.stat().st_size==0 or export.stat().st_size>128*1024 or export.stat().st_mode&0o077:
        raise WorkflowError("The private authenticated pairing export was not confirmed. Nothing was marked connected.")
    print("Authenticated pairing file saved privately. Transfer that file directly to this iPhone and replace its old pairing import. Do not upload its contents to chat or GitHub. On-phone connection is still unverified.")

def private_directory() -> None:
    if PRIVATE.is_symlink() or not PRIVATE.resolve().is_relative_to(ROOT.resolve()):
        raise WorkflowError("Private runtime area must not redirect outside this repository.")
    kit=bootstrap_kit()
    if kit is None or (ROOT/".git").exists():
        # An existing checkout must never track credential/profile-bearing runtime data.
        ignored=subprocess.run(["git","check-ignore","-q",str(PRIVATE/"sentinel")],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        tracked=subprocess.run(["git","ls-files","--",str(PRIVATE)],cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        if ignored.returncode or tracked.returncode or tracked.stdout:
            raise WorkflowError("Private runtime directory must be ignored and untracked.")
    # A verified native kit needs no Git history, Cargo, registry tree or Unit Creator copy.
    PRIVATE.mkdir(mode=0o700,parents=True,exist_ok=True)
    os.chmod(PRIVATE,0o700)


def private_path(path: pathlib.Path) -> pathlib.Path:
    raw=path.absolute()
    try: relative=raw.relative_to(PRIVATE.absolute())
    except ValueError: raise WorkflowError("Private output must stay in the protected runtime area.") from None
    cursor=PRIVATE
    for part in relative.parts:
        cursor=cursor/part
        if cursor.is_symlink(): raise WorkflowError("Private runtime paths must not be symbolic links.")
    resolved=contained(raw)
    if not resolved.is_relative_to(PRIVATE.resolve()): raise WorkflowError("Private output escaped the protected runtime area.")
    return resolved

def load_handoff(manifest_path: pathlib.Path, library_path: pathlib.Path, *, private_only: bool = True) -> dict:
    manifest_path, library_path = checked_file(manifest_path), checked_file(library_path)
    if private_only and not library_path.is_relative_to(PRIVATE.resolve()):
        raise WorkflowError("Received Rust archive must be in the ignored private runtime area.")
    try: manifest = json.loads(manifest_path.read_text())
    except (ValueError, OSError): raise WorkflowError("The cloud handoff manifest is unreadable.") from None
    if (not isinstance(manifest,dict) or type(manifest.get("schema_version")) is not int or manifest["schema_version"] != 1 or manifest.get("target") != "aarch64-apple-ios"
        or manifest.get("file") != library_path.name or manifest.get("bytes") != library_path.stat().st_size
        or not re.fullmatch(r"[0-9a-f]{64}", str(manifest.get("sha256", "")))
        or not re.fullmatch(r"[0-9a-f]{40}", str(manifest.get("source_commit", "")))
        or not re.fullmatch(r"[0-9a-f]{64}", str(manifest.get("source_tree_sha256", "")))):
        raise WorkflowError("The cloud handoff metadata does not match the selected iOS archive.")
    if sha256(library_path) != manifest["sha256"]:
        raise WorkflowError("Rust archive checksum differs from the reviewed cloud handoff.")
    return manifest

def team_and_bundle(args: argparse.Namespace) -> tuple[str, str]:
    team = args.team or ""
    if not re.fullmatch(r"[A-Z0-9]{10}", team):
        raise WorkflowError("Choose the development team in Xcode; provide its 10-character team ID to the operator locally.")
    bundle = args.bundle_id or f"{BUNDLE_PREFIX}.t{team.lower()}"
    if (not (bundle == BUNDLE_PREFIX or bundle.startswith(BUNDLE_PREFIX + ".")) or len(bundle) > 255
        or not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle)):
        raise WorkflowError("Use this project's stable installed bundle ID; keep it identical for future updates.")
    return team, bundle

def device_json(args: argparse.Namespace, *pieces: str) -> dict:
    if not args.device or not re.fullmatch(r"[A-Za-z0-9-]{8,80}", args.device):
        raise WorkflowError("Select this iPhone in Xcode Device Hub and provide its identifier locally.")
    with tempfile.TemporaryDirectory(prefix="device-output-", dir=PRIVATE) as temporary:
        output = pathlib.Path(temporary) / "device.json"
        command(["xcrun", "devicectl", *pieces, "--device", args.device, "--json-output", str(output)], step="Device query")
        try: return json.loads(output.read_text())
        except (OSError, ValueError): raise WorkflowError("Xcode returned an unsupported device response. Review the device in Xcode.") from None

def version(value: str) -> tuple[int, ...]:
    if not re.fullmatch(r"\d+(?:\.\d+){0,3}", value): raise WorkflowError("A supported numeric iOS/SDK version was not reported.")
    return tuple(map(int, value.split(".")))

def hardware_udid(hardware: dict) -> str:
    udid=hardware.get("udid")
    if not isinstance(udid,str) or not re.fullmatch(r"(?:[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}|[0-9A-Fa-f]{40})",udid):
        raise WorkflowError("The physical iPhone hardware UDID was not reported. Review the selected device in Xcode; a CoreDevice alias cannot authorize provisioning.")
    return udid

def diagnose(args: argparse.Namespace) -> dict:
    sdk = command(["xcrun", "--sdk", "iphoneos", "--show-sdk-version"], step="iPhoneOS SDK discovery").decode().strip()
    xcode = command(["xcodebuild", "-version"], step="Xcode version discovery").decode().strip()
    response = device_json(args, "device", "info", "details")
    result = response.get("result", {})
    properties = result.get("deviceProperties", {})
    hardware = result.get("hardwareProperties", {})
    # CoreDevice's identifier is an alias UUID, not a provisioning device ID.
    # Keep the hardware UDID only in memory; never add it to the redacted report.
    args.physical_udid=hardware_udid(hardware)
    os_version = properties.get("osVersionNumber") or properties.get("osVersion")
    model = hardware.get("productType") or hardware.get("model")
    if not isinstance(os_version,str) or not isinstance(model,str) or not re.fullmatch(r"iPhone[0-9]+,[0-9]+",model):
        raise WorkflowError("A supported physical iPhone model/OS was not reported; no install was attempted.")
    if args.variant=="duo" and model not in DUO_MODELS:
        raise WorkflowError("This phone is not the confirmed supported iPhone Duo model. Do not label its checks as Duo verification.")
    sdk_version, phone_version = version(sdk), version(os_version)
    if phone_version[0] > sdk_version[0]:
        raise WorkflowError("The installed iPhoneOS SDK is older than this phone's OS generation. Select a compatible Xcode before installation.")
    if args.variant == "duo" and (sdk_version + (0,))[:2] < (27, 1):
        raise WorkflowError("The requested Duo path requires an actual iOS 27.1+ SDK. A synthetic SDK mark is not accepted here.")
    if phone_version < (16, 4): raise WorkflowError("This app requires iOS 16.4 or later.")
    report = {"schema_version": 1, "checked_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "xcode": xcode, "iphoneos_sdk": sdk, "phone_os": os_version, "phone_model": model,
              "variant": args.variant, "scope": "Approved physical-device diagnosis; no Apple ID, name, serial number, UDID or pairing material included.",
              "sdk_version_is_genuine": True, "device_install_attempted": False}
    (PRIVATE / "diagnosis.json").write_text(json.dumps(report, indent=2) + "\n")
    return report

def plist_write(path: pathlib.Path, obj: dict) -> None:
    path.write_bytes(plistlib.dumps(obj, fmt=plistlib.FMT_XML))

def openstep(value, indent=0) -> str:
    if isinstance(value, dict):
        return "{\n" + "".join("\t" * (indent+1) + json.dumps(str(k)) + " = " + openstep(v, indent+1) + ";\n" for k,v in value.items()) + "\t" * indent + "}"
    if isinstance(value, list): return "(\n" + "".join("\t"*(indent+1) + openstep(v,indent+1) + ",\n" for v in value) + "\t"*indent + ")"
    return json.dumps(str(value))

def generate_project(team: str, bundle: str, variant: str, library: pathlib.Path, *, unsigned_validation: bool = False, review_ipa: pathlib.Path | None = None, actual_sdk: str | None = None, review_resources: pathlib.Path | None = None, bootstrap_tool_commit: str | None = None) -> pathlib.Path:
    directory = private_path(PRIVATE / "project")
    if directory.exists(): shutil.rmtree(directory)
    directory.mkdir(mode=0o700)
    resources = directory / "Resources"; resources.mkdir()
    info = plistlib.loads((ROOT / "app-installer/ios/Info.plist").read_bytes())
    for key in list(info):
        if key.startswith("DT") or key in {"BuildMachineOSBuild", "CFBundleSupportedPlatforms"}: info.pop(key)
    info.update(CFBundleIdentifier=bundle, CFBundleExecutable="AppInstaller", CFBundleDisplayName="App Installer" + (" Duo" if variant == "duo" else ""),
                BGTaskSchedulerPermittedIdentifiers=[bundle + ".refresh"])
    plist_write(directory / "Info.plist", info)
    plist_write(directory / "AppInstaller.entitlements", {"keychain-access-groups": ["$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)"]})
    for size,scale in [(120,2),(180,3)]:
        shutil.copy2(ROOT / f"app-installer/ios/assets/AppIcon{size}.png", resources / f"AppIcon60x60@{scale}x.png")
    shutil.copy2(ROOT / "app-installer/LICENSE", resources / "LICENSE.txt")
    # Notices come from the reviewed unsigned artifact; they contain no signing material.
    import zipfile
    names=["ThirdPartyNotices.txt","ThirdPartyNoticeReport.json","BuildMetadata.json"]
    if review_resources:
        for name in names: shutil.copy2(checked_file(review_resources/name),resources/name)
    else:
        review_ipa=review_ipa or ROOT/f"builds/AppInstaller-{variant}-preview.ipa"
        if not review_ipa.is_file(): raise WorkflowError("The reviewed cloud IPA is missing; keep its notices with the bootstrap build.")
        with zipfile.ZipFile(review_ipa) as archive:
            for name in names: (resources/name).write_bytes(archive.read("Payload/AppInstaller.app/"+name))
    # Preserve verified source/archive/dependency bindings from the matching review input.
    # Only the execution classification and actual native build SDK differ here.
    metadata=json.loads((resources/"BuildMetadata.json").read_text())
    metadata.update(unsigned=unsigned_validation,scope="Unsigned cloud native project validation" if unsigned_validation else "Native Xcode bootstrap; profile and actual SDK are verified before install.",variant=variant)
    metadata["bootstrap_tool_commit"]=bootstrap_tool_commit or metadata.get("source_commit")
    if actual_sdk:
        version(actual_sdk)
        metadata.update(compilation_sdk=actual_sdk,requested_sdk_mark=actual_sdk)
    (resources/"BuildMetadata.json").write_text(json.dumps(metadata,indent=2)+"\n")
    objects = {}
    def ident(label): return hashlib.sha1(label.encode()).hexdigest()[:24].upper()
    def add(label, value): key = ident(label); objects[key] = value; return key
    def ref(path, kind, tree="<group>"):
        return add("ref:" + str(path), {"isa":"PBXFileReference", "lastKnownFileType":kind, "path":os.path.relpath(path,directory) if tree=="<group>" else str(path), "sourceTree":tree})
    source_refs = [ref(p,"sourcecode.c.objc") for p in sorted((ROOT / "app-installer/ios").glob("*.m"))]
    library_ref = ref(library, "archive.ar")
    framework_refs = [ref(pathlib.Path("System/Library/Frameworks") / (name+".framework"), "wrapper.framework", "SDKROOT") for name in ["UIKit","Foundation","Security","LocalAuthentication","UniformTypeIdentifiers","BackgroundTasks","UserNotifications","CoreFoundation","SystemConfiguration","QuartzCore"]]
    resource_refs = [ref(p, "text" if p.suffix in {".txt", ".json"} else "image.png") for p in sorted(resources.iterdir())]
    def phase(label, isa, refs):
        build_refs = [add("build:" + label + ":" + r, {"isa":"PBXBuildFile", "fileRef":r}) for r in refs]
        return add(label,{"isa":isa,"buildActionMask":"2147483647","files":build_refs,"runOnlyForDeploymentPostprocessing":"0"})
    sources = phase("sources", "PBXSourcesBuildPhase", source_refs)
    frameworks = phase("frameworks", "PBXFrameworksBuildPhase", [library_ref]+framework_refs)
    resources_phase = phase("resources", "PBXResourcesBuildPhase", resource_refs)
    product = add("product",{"isa":"PBXFileReference","explicitFileType":"wrapper.application","includeInIndex":"0","path":"AppInstaller.app","sourceTree":"BUILT_PRODUCTS_DIR"})
    products = add("products",{"isa":"PBXGroup","children":[product],"name":"Products","sourceTree":"<group>"})
    group = add("main",{"isa":"PBXGroup","children":source_refs+[library_ref]+framework_refs+resource_refs+[products],"sourceTree":"<group>"})
    common={"CLANG_ENABLE_OBJC_ARC":"YES","CLANG_ENABLE_MODULES":"YES","SDKROOT":"iphoneos","IPHONEOS_DEPLOYMENT_TARGET":"16.4","TARGETED_DEVICE_FAMILY":"1","ARCHS":"arm64","ONLY_ACTIVE_ARCH":"YES","ENABLE_USER_SCRIPT_SANDBOXING":"YES","OTHER_LDFLAGS":["-lz","-liconv"],"LIBRARY_SEARCH_PATHS":[str(library.parent)]}
    target_settings={**common,"PRODUCT_NAME":"AppInstaller","PRODUCT_BUNDLE_IDENTIFIER":bundle,"INFOPLIST_FILE":"Info.plist","CODE_SIGN_STYLE":"Automatic","DEVELOPMENT_TEAM":team,"CODE_SIGN_ENTITLEMENTS":"AppInstaller.entitlements","CODE_SIGN_IDENTITY":"Apple Development","ENABLE_BITCODE":"NO","GENERATE_INFOPLIST_FILE":"NO","DEBUG_INFORMATION_FORMAT":"dwarf","GCC_OPTIMIZATION_LEVEL":"s","SWIFT_VERSION":"5.0"}
    config = add("target-config",{"isa":"XCBuildConfiguration","buildSettings":target_settings,"name":"Release"})
    configs = add("target-configs",{"isa":"XCConfigurationList","buildConfigurations":[config],"defaultConfigurationIsVisible":"0","defaultConfigurationName":"Release"})
    project_config=add("project-config",{"isa":"XCBuildConfiguration","buildSettings":common,"name":"Release"})
    project_configs=add("project-configs",{"isa":"XCConfigurationList","buildConfigurations":[project_config],"defaultConfigurationIsVisible":"0","defaultConfigurationName":"Release"})
    target=add("target",{"isa":"PBXNativeTarget","buildConfigurationList":configs,"buildPhases":[sources,frameworks,resources_phase],"buildRules":[],"dependencies":[],"name":"AppInstaller","productName":"AppInstaller","productReference":product,"productType":"com.apple.product-type.application"})
    project=add("project",{"isa":"PBXProject","attributes":{"LastUpgradeCheck":"1600","TargetAttributes":{target:{"DevelopmentTeam":team,"ProvisioningStyle":"Automatic"}}},"buildConfigurationList":project_configs,"compatibilityVersion":"Xcode 14.0","developmentRegion":"en","hasScannedForEncodings":"0","knownRegions":["en","Base"],"mainGroup":group,"productRefGroup":products,"projectDirPath":"","projectRoot":"","targets":[target]})
    wrapper=directory / "AppInstallerDevice.xcodeproj"; wrapper.mkdir()
    (wrapper / "project.pbxproj").write_text("// !$*UTF8*$!\n" + openstep({"archiveVersion":"1","classes":{},"objectVersion":"56","objects":objects,"rootObject":project}) + "\n")
    import xml.etree.ElementTree as ET
    scheme = ET.Element("Scheme", LastUpgradeVersion="1600", version="1.3")
    action = ET.SubElement(scheme,"BuildAction",parallelizeBuildables="YES",buildImplicitDependencies="YES")
    entries = ET.SubElement(action,"BuildActionEntries")
    entry = ET.SubElement(entries,"BuildActionEntry",buildForTesting="NO",buildForRunning="YES",buildForProfiling="YES",buildForArchiving="YES",buildForAnalyzing="YES")
    ET.SubElement(entry,"BuildableReference",BuildableIdentifier="primary",BlueprintIdentifier=target,BuildableName="AppInstaller.app",BlueprintName="AppInstaller",ReferencedContainer="container:AppInstallerDevice.xcodeproj")
    schemes = wrapper / "xcshareddata/xcschemes"; schemes.mkdir(parents=True)
    ET.ElementTree(scheme).write(schemes / "AppInstaller.xcscheme",encoding="utf-8",xml_declaration=True)
    return wrapper

def verify_review_ipa(path: pathlib.Path, manifest: dict, variant: str) -> pathlib.Path:
    import zipfile
    path=checked_file(path)
    try:
        with zipfile.ZipFile(path) as archive:
            metadata_name="Payload/AppInstaller.app/BuildMetadata.json"
            notice_name="Payload/AppInstaller.app/ThirdPartyNoticeReport.json"
            if archive.getinfo(metadata_name).file_size>64*1024 or archive.getinfo(notice_name).file_size>4*1024*1024:
                raise WorkflowError("Review metadata exceeds its supported bound.")
            if archive.getinfo("Payload/AppInstaller.app/ThirdPartyNotices.txt").file_size>16*1024*1024:
                raise WorkflowError("Review notice text exceeds its supported bound.")
            if "Payload/AppInstaller.app/embedded.mobileprovision" in archive.namelist():
                raise WorkflowError("Bootstrap review input must remain unsigned and contain no provisioning profile.")
            metadata=json.loads(archive.read(metadata_name))
            notices=json.loads(archive.read(notice_name))
        if (metadata.get("unsigned") is not True or metadata.get("source_commit")!=manifest["source_commit"]
            or metadata.get("source_tree_sha256")!=manifest["source_tree_sha256"]
            or metadata.get("variant")!=variant):
            raise WorkflowError("Unsigned review IPA and Rust archive do not share the same reviewed source/variant.")
        if notices.get("notice_gap_count")!=0 or notices.get("notice_obligations_satisfied") is not True:
            raise WorkflowError("Fresh review IPA still has unresolved third-party notice obligations.")
    except (zipfile.BadZipFile,KeyError,ValueError):
        raise WorkflowError("The unsigned review IPA lacks supported source/notice metadata.") from None
    return path

def verify_profile(profile: dict, entitlements: dict, *, team: str, bundle: str, device: str, now: dt.datetime | None = None) -> dict:
    now = now or dt.datetime.now(dt.timezone.utc)
    expiry = profile.get("ExpirationDate")
    if isinstance(expiry, dt.datetime) and expiry.tzinfo is None: expiry = expiry.replace(tzinfo=dt.timezone.utc)
    profile_entitlements = profile.get("Entitlements", {})
    if not isinstance(profile_entitlements, dict) or not isinstance(entitlements, dict):
        raise WorkflowError("Development profile or entitlements have an unsupported format.")
    appid = entitlements.get("application-identifier", "")
    prefix = profile.get("ApplicationIdentifierPrefix", [])
    def allows(pattern, identity):
        return isinstance(pattern, str) and isinstance(identity, str) and (pattern == identity or (pattern.endswith(".*") and "*" not in pattern[:-1] and identity.startswith(pattern[:-1])))
    profile_groups = profile_entitlements.get("keychain-access-groups", [])
    team_ids, devices = profile.get("TeamIdentifier", []), profile.get("ProvisionedDevices", [])
    if (not isinstance(team_ids,list) or not isinstance(devices,list) or not isinstance(prefix,list)
        or not isinstance(profile_groups,list) or team not in team_ids or device not in devices
        or not isinstance(expiry,dt.datetime) or expiry <= now or not isinstance(appid,str)
        or not any(appid == p + "." + bundle for p in prefix if isinstance(p,str))
        or entitlements.get("com.apple.developer.team-identifier") != team
        or ("get-task-allow" in entitlements and type(entitlements["get-task-allow"]) is not bool)
        or entitlements.get("keychain-access-groups") != [appid]
        or set(entitlements) - ALLOWED_ENTITLEMENTS
        or profile_entitlements.get("get-task-allow") is not True
        or profile_entitlements.get("com.apple.developer.team-identifier") != team
        or not allows(profile_entitlements.get("application-identifier"), appid)
        or not any(allows(group,appid) for group in profile_groups)):
        raise WorkflowError("Development profile/entitlements do not match this device, team, stable app identity or minimal capabilities.")
    # Return no names, team IDs, device IDs, profile UUID, certificate bytes or full entitlements.
    return {"profile_expiry": expiry.isoformat(), "profile_covers_selected_device":True,
            "stable_bundle_and_keychain_group_verified":True, "development_profile_capabilities_verified":True,
            "extra_capabilities":False}

def verify_signing_certificate(app: pathlib.Path, profile: dict) -> dict:
    # Extract public certificates only. Never export a private identity/key, and never
    # retain the certificate chain outside this protected, automatically removed area.
    certificates=profile.get("DeveloperCertificates")
    if not isinstance(certificates,list) or not certificates or any(type(value) is not bytes or not value for value in certificates):
        raise WorkflowError("Development profile lacks a supported public signing-certificate allowlist.")
    with tempfile.TemporaryDirectory(prefix="signature-certificates-",dir=private_path(PRIVATE)) as temporary:
        directory=pathlib.Path(temporary);directory.chmod(0o700);prefix=directory/"signer"
        command(["codesign","--display","--extract-certificates="+str(prefix),str(app)],step="Public signing certificate extraction")
        chain=[]
        for index in range(16):
            certificate=directory/f"signer{index}"
            if not certificate.exists():break
            if certificate.is_symlink() or not certificate.is_file() or not certificate.stat().st_size:
                raise WorkflowError("Extracted public signing certificate chain has an unsupported format.")
            certificate.chmod(0o600);chain.append(certificate)
        if not chain or chain[0].read_bytes() not in certificates:
            raise WorkflowError("The actual code-signing leaf is not authorized by this development profile.")
        # macOS Security checks code-signing trust, validity and the supplied chain;
        # codesign's Apple anchor requirement separately rejects non-Apple issuers.
        # Failure is fatal: CMS decoding is never a substitute for certificate trust.
        command(["security","verify-cert","-p","codeSign",*[part for certificate in chain for part in ["-c",str(certificate)]]],step="OS code-signing certificate trust verification")
    return {"signing_leaf_matches_profile":True,"os_code_signing_chain_verified":True}

def verify_app(args: argparse.Namespace) -> dict:
    team,bundle=team_and_bundle(args)
    app=private_path(PRIVATE / "DerivedData/Build/Products/Release-iphoneos/AppInstaller.app")
    if not app.is_dir(): raise WorkflowError("The native signed app has not been built yet.")
    info=plistlib.loads((app / "Info.plist").read_bytes())
    metadata=json.loads((app/"BuildMetadata.json").read_text())
    kit=bootstrap_kit()
    if kit and any(metadata.get(key)!=kit[key] for key in ["source_commit","source_tree_sha256","bootstrap_tool_commit"]):
        raise WorkflowError("Signed app provenance does not match the reviewed compiled source and bootstrap-tool revision.")
    for key,pattern in [("source_commit",r"[0-9a-f]{40}"),("source_tree_sha256",r"[0-9a-f]{64}"),("bootstrap_tool_commit",r"[0-9a-f]{40}")]:
        if not re.fullmatch(pattern,str(metadata.get(key,""))):
            raise WorkflowError("Signed app source provenance is incomplete.")
    if metadata.get("variant")!=args.variant or metadata.get("unsigned") is not False:
        raise WorkflowError("Native signed app provenance does not match the chosen variant/signing path.")
    if info.get("CFBundleIdentifier") != bundle or info.get("BGTaskSchedulerPermittedIdentifiers") != [bundle+".refresh"]:
        raise WorkflowError("Signed artifact identity/background task identifier does not match the chosen stable identity.")
    if "UIRequiresFullScreen" in info or not info.get("UIApplicationSceneManifest"):
        raise WorkflowError("Signed artifact lost required scene/window configuration.")
    command(["codesign","--verify","--deep","--strict","-R=anchor apple generic",str(app)], step="Apple-issued development signature verification")
    raw=command(["codesign","--display","--entitlements",":-",str(app)], step="Signed entitlement inspection")
    profile=plistlib.loads(command(["security","cms","-D","-i",str(app/"embedded.mobileprovision")],step="Development profile inspection"))
    try: entitlements=plistlib.loads(raw)
    except plistlib.InvalidFileException: raise WorkflowError("Signed entitlements were not returned as a supported plist.") from None
    details=device_json(args,"device","info","details")
    udid=hardware_udid(details.get("result",{}).get("hardwareProperties",{}))
    report=verify_profile(profile,entitlements,team=team,bundle=bundle,device=udid)
    report.update(verify_signing_certificate(app,profile))
    # Automatic Xcode provisioning is the only build path. Decoding an embedded CMS
    # does not prove that Apple's profile signer/authority was independently checked.
    report.update(development_signature=True,apple_profile_authority_verified=False,
                  physical_signature_acceptance_verified=False)
    binary = app / str(info.get("CFBundleExecutable", "AppInstaller"))
    marks = command(["xcrun", "vtool", "-show-build", str(binary)], step="Actual Mach-O SDK inspection").decode()
    sdk = command(["xcrun", "--sdk", "iphoneos", "--show-sdk-version"], step="Installed SDK verification").decode().strip()
    found = re.search(r"\bsdk\s+(\d+(?:\.\d+){1,2})", marks)
    if not re.search(r"\bplatform\s+IOS\b", marks) or not found or version(found.group(1))[:2] != version(sdk)[:2]:
        raise WorkflowError("Mach-O SDK metadata differs from the actual installed iPhoneOS SDK.")
    report.update({key:metadata[key] for key in ["source_commit","source_tree_sha256","bootstrap_tool_commit"]})
    report["source_identity_matches_reviewed_kit"]=kit is not None
    report.update(source_version=str(info.get("CFBundleShortVersionString","")),build_version=str(info.get("CFBundleVersion","")),actual_sdk=str(info.get("DTSDKName","")),macho_sdk_matches_installed_xcode=True,local_binary_sha256=sha256(binary))
    return report

def export_signed_ipa(args: argparse.Namespace, verified: dict) -> dict:
    import stat,zipfile
    app=private_path(PRIVATE/"DerivedData/Build/Products/Release-iphoneos/AppInstaller.app")
    output_dir=private_path(PRIVATE/"builds");output_dir.mkdir(mode=0o700,exist_ok=True)
    output=output_dir/f"AppInstaller-{args.variant}-signed.ipa"
    pending=output.with_suffix(".ipa.pending")
    if pending.is_symlink() or (pending.exists() and not pending.is_file()):
        raise WorkflowError("Signed IPA staging path is not an owned regular file.")
    if pending.exists():pending.unlink()
    expected={}
    try:
        with zipfile.ZipFile(pending,"x",zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
            for file in sorted(app.rglob("*")):
                if file.is_symlink():raise WorkflowError("A signed bundle symlink needs explicit platform review before packaging.")
                if file.is_file():
                    name="Payload/AppInstaller.app/"+str(file.relative_to(app))
                    expected[name]=sha256(file);archive.write(file,name)
        with zipfile.ZipFile(pending) as archive:
            names=archive.namelist()
            executable="Payload/AppInstaller.app/AppInstaller"
            if (set(names)!=set(expected) or len(names)!=len(set(names)) or archive.testzip() is not None
                or not (archive.getinfo(executable).external_attr>>16)&stat.S_IXUSR
                or "Payload/AppInstaller.app/embedded.mobileprovision" not in names
                or "Payload/AppInstaller.app/_CodeSignature/CodeResources" not in names):
                raise WorkflowError("Signed IPA payload/integrity/executable permissions did not verify.")
            for name,digest in expected.items():
                if hashlib.sha256(archive.read(name)).hexdigest()!=digest:
                    raise WorkflowError("Signed bundle bytes changed while packaging the IPA.")
        pending.replace(output)
    finally:
        pending.unlink(missing_ok=True)
    receipt={**verified,"signed_ipa_file":output.name,"signed_ipa_bytes":output.stat().st_size,
             "signed_ipa_sha256":sha256(output),"payload_bytes_verified":True,
             "executable_permissions_preserved":True,"device_install_attempted":False,
             "scope":"Private signed IPA export. Do not upload its profile/device identifiers to GitHub. Physical functionality remains separately verified."}
    (output_dir/f"AppInstaller-{args.variant}-signed.json").write_text(json.dumps(receipt,indent=2)+"\n")
    return receipt

def prepare(args: argparse.Namespace) -> pathlib.Path:
    team,bundle=team_and_bundle(args)
    kit=bootstrap_kit()
    if kit:
        args.manifest=args.manifest or ROOT/kit["library_manifest"]
        args.rust_library=args.rust_library or ROOT/kit["rust_library"]
    if not args.manifest or not args.rust_library:
        raise WorkflowError("The operator must provide the reviewed cloud Rust archive and its exact size/checksum manifest.")
    manifest=load_handoff(args.manifest,args.rust_library)
    if kit:
        if (kit["source_commit"]!=manifest["source_commit"] or kit["source_tree_sha256"]!=manifest["source_tree_sha256"]
            or kit["corresponding_source"]["sha256"]!=manifest.get("source_bundle_sha256")):
            raise WorkflowError("Native kit, cloud library and complete source/relink delivery do not match.")
        resources=contained(ROOT/str(safe_relative(kit["review_resources"])))
        metadata=json.loads((resources/"BuildMetadata.json").read_text())
        notices=json.loads((resources/"ThirdPartyNoticeReport.json").read_text())
        if (metadata.get("source_commit")!=manifest["source_commit"] or metadata.get("source_tree_sha256")!=manifest["source_tree_sha256"]
            or metadata.get("source_bundle_sha256")!=manifest.get("source_bundle_sha256") or metadata.get("variant")!=args.variant
            or notices.get("notice_gap_count")!=0 or notices.get("notice_obligations_satisfied") is not True):
            raise WorkflowError("Native kit notice/source resources do not match the selected cloud library/variant.")
        # No Cargo/Git required: every native input and archive was independently hashed in the kit.
        compatibility=diagnose(args)
        command(["xcrun","lipo","-verify_arch","arm64",str(args.rust_library)],step="Rust iOS architecture check")
        return generate_project(team,bundle,args.variant,checked_file(args.rust_library),review_resources=resources,actual_sdk=compatibility["iphoneos_sdk"],bootstrap_tool_commit=kit["bootstrap_tool_commit"])
    head=command(["git","rev-parse","HEAD"],step="Source identity check").decode().strip()
    if head!=manifest["source_commit"]: raise WorkflowError("Mac checkout differs from the reviewed cloud handoff commit.")
    source_hash=command([sys.executable,str(ROOT/"app-installer/build/source-fingerprint.py")],step="Source fingerprint verification").decode().strip()
    if source_hash!=manifest["source_tree_sha256"]: raise WorkflowError("Mac production source differs from the reviewed cloud archive inputs.")
    dirty=command(["git","status","--porcelain","--","app-installer/ios","app-installer/core","downloads/isideload","downloads/idevice"],step="Source cleanliness check")
    if dirty.strip(): raise WorkflowError("Production source has local changes. Reconcile them before signing.")
    compatibility=diagnose(args)
    command(["xcrun","lipo","-verify_arch","arm64",str(args.rust_library)],step="Rust iOS architecture check")
    review=verify_review_ipa(args.review_ipa or ROOT/f"builds/AppInstaller-{args.variant}-candidate.ipa",manifest,args.variant)
    return generate_project(team,bundle,args.variant,checked_file(args.rust_library),review_ipa=review,actual_sdk=compatibility["iphoneos_sdk"])


def installation_binding(args: argparse.Namespace, report: dict) -> str:
    _,bundle=team_and_bundle(args)
    # Private opaque binding, never a raw phone ID, account/team label or bundle ID.
    # diagnose() obtains the actual hardware UDID even if selection used an alias.
    values=[args.physical_udid,bundle,args.variant,report["local_binary_sha256"],
            report["source_commit"],report["source_tree_sha256"],report["bootstrap_tool_commit"]]
    return hashlib.sha256(json.dumps(values,separators=(",",":"),ensure_ascii=True).encode()).hexdigest()


def save_device_evidence(report: dict) -> None:
    output=private_path(PRIVATE/"device-evidence.json")
    pending=private_path(PRIVATE/"device-evidence.json.pending")
    try:
        with pending.open("w") as stream:
            json.dump(report,stream,indent=2);stream.write("\n");stream.flush();os.fsync(stream.fileno())
        pending.replace(output)
    finally:
        pending.unlink(missing_ok=True)


def install(args: argparse.Namespace) -> dict:
    report=diagnose(args);report.update(verify_app(args))
    app=private_path(PRIVATE / "DerivedData/Build/Products/Release-iphoneos/AppInstaller.app")
    report.update(device_install_attempted=True,install_command_succeeded=False,
                  install_outcome="in_progress",launch_command_succeeded=False,
                  installation_binding_sha256=installation_binding(args,report))
    # Persist intent before a device-changing command. A disconnect/partial install
    # must never leave an older successful receipt masquerading as this attempt.
    save_device_evidence(report)
    try:
        device_json(args,"device","install","app",str(app))
    except Exception:
        report["install_outcome"]="failed_or_unknown";save_device_evidence(report);raise
    report.update(install_command_succeeded=True,install_outcome="succeeded")
    save_device_evidence(report)
    return report


def launch(args: argparse.Namespace) -> dict:
    _,bundle=team_and_bundle(args)
    report=diagnose(args);report.update(verify_app(args))
    binding=installation_binding(args,report)
    try:
        prior=json.loads(private_path(PRIVATE/"device-evidence.json").read_text())
    except (OSError,ValueError):
        raise WorkflowError("Install this exact verified build successfully on the selected iPhone before recording its launch.") from None
    if (not isinstance(prior,dict) or prior.get("install_command_succeeded") is not True
        or prior.get("install_outcome")!="succeeded" or prior.get("installation_binding_sha256")!=binding):
        raise WorkflowError("The successful installation receipt does not match this iPhone and exact verified build. Install it before recording its launch.")
    report.update(device_install_attempted=True,install_command_succeeded=True,
                  install_outcome="succeeded",installation_binding_sha256=binding,
                  launch_command_succeeded=False,launch_outcome="in_progress",
                  ui_or_signing_functionality_verified=False)
    save_device_evidence(report)
    try:
        device_json(args,"device","process","launch",bundle)
    except Exception:
        report["launch_outcome"]="failed_or_unknown";save_device_evidence(report);raise
    report.update(launch_command_succeeded=True,launch_outcome="succeeded")
    save_device_evidence(report)
    return report


def parser() -> argparse.ArgumentParser:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("step",choices=["diagnose","prepare","build","export","install","launch","create-remote-pairing","fetch-pairing-tool","remove-pairing-export"])
    p.add_argument("--execute",action="store_true",help="Run only AFTER Tin explicitly approves the exact Mac/network/device scope. Omit for a dry-run.")
    p.add_argument("--device",help="Local Xcode device identifier; never paste it into chat or a repo file.")
    p.add_argument("--team",help="Local Xcode development-team ID (free or paid).")
    p.add_argument("--bundle-id",help="Existing stable installer bundle ID, if previously installed; otherwise deterministic per-team ID.")
    p.add_argument("--variant",choices=["iphone","duo"],default="iphone")
    p.add_argument("--manifest",type=pathlib.Path)
    p.add_argument("--review-ipa",type=pathlib.Path,help="Fresh unsigned same-source candidate IPA for complete notice/resources; no signed profile or keys.")
    p.add_argument("--rust-library",type=pathlib.Path)
    return p

def main(argv: list[str] | None = None) -> int:
    args=parser().parse_args(argv)
    if not args.execute:
        print("DRY RUN: no Mac, network, account, device or filesystem action performed.")
        print({"diagnose":"Would inspect the selected phone's actual OS/model and installed Xcode SDK.","prepare":"Would verify the exact reviewed cloud Rust archive, inspect device compatibility, and generate a native automatic-signing Xcode project.","build":"Would let signed-in Xcode register/provision this device and build this app with the actual installed SDK; Apple account stays in Xcode/Keychain.","export":"Would export the actually verified signed app as one private IPA, preserving executable permissions and verifying every ZIP payload byte.","install":"Would verify signature/profile/device/identity and install this one app over USB.","launch":"Would launch this one installed app and save only sanitized non-secret evidence.","create-remote-pairing":"Would verify the matching cloud Mac helper and create a peer-pinned version-2 record over trusted physical USB, without changing Apple accounts or installing/removing any app.","fetch-pairing-tool":f"Would download the official idevice_pair v1.1.0 DMG ({PAIR_BYTES:,} bytes), checking SHA-256 before use.","remove-pairing-export":"Would remove the single temporary pairing export after confirmed encrypted in-app import."}[args.step])
        print("Execution requires prior explicit Tin approval for the exact Mac/personal-network/device step, then --execute. No approval is inferred from this flag.")
        return 0
    os.umask(0o077)
    try:
        mac_only();private_directory()
        if args.step=="diagnose": report=diagnose(args);print(json.dumps(report,indent=2))
        elif args.step=="prepare": prepare(args);print("Native automatic-signing project prepared in the ignored private area.")
        elif args.step=="build":
            project=PRIVATE/"project/AppInstallerDevice.xcodeproj"
            if not project.is_dir(): raise WorkflowError("Prepare the reviewed native project first.")
            team_and_bundle(args);diagnose(args)
            command(["xcodebuild","-project",str(project),"-scheme","AppInstaller","-configuration","Release","-sdk","iphoneos","-destination","id="+args.physical_udid,"-derivedDataPath",str(PRIVATE/"DerivedData"),"-allowProvisioningUpdates","-allowProvisioningDeviceRegistration","build"],step="Xcode automatic provisioning/build")
            report=verify_app(args);(PRIVATE/"signature-evidence.json").write_text(json.dumps(report,indent=2)+"\n");export_signed_ipa(args,report);print("Native Xcode build/signature and private signed IPA export verified. Not installed yet.")
        elif args.step=="export": export_signed_ipa(args,verify_app(args));print("Verified private signed IPA exported. No device install performed by this step.")
        elif args.step=="install": install(args);print("Install command succeeded for the verified app. Launch and in-app device checks remain.")
        elif args.step=="launch": launch(args);print("Launch command succeeded. Actual account, pairing, update and refresh behavior still require the in-app checks.")
        elif args.step=="create-remote-pairing": create_remote_pairing(args)
        elif args.step=="fetch-pairing-tool":
            import urllib.request
            tools=contained(ROOT/"downloads/idevice-pair-macos");tools.mkdir(parents=True,exist_ok=True)
            dest=tools/"idevice_pair--macos-universal.dmg";temporary=tools/"idevice_pair--macos-universal.dmg.pending"
            if temporary.is_symlink() or (temporary.exists() and not temporary.is_file()):
                raise WorkflowError("Pairing-tool partial download path is not a safe owned file.")
            if temporary.is_file(): temporary.unlink()
            if dest.is_file() and not dest.is_symlink() and dest.stat().st_size==PAIR_BYTES and sha256(dest)==PAIR_SHA256:
                print("Verified pairing tool is already present; no network download needed.");return 0
            try:
                with urllib.request.urlopen(PAIR_URL) as response, temporary.open("xb") as out:
                    shutil.copyfileobj(response,out,1024*1024)
                if temporary.stat().st_size != PAIR_BYTES or sha256(temporary) != PAIR_SHA256: raise WorkflowError("Pairing tool release checksum differs; file will not be opened.")
                temporary.replace(dest)
            finally:
                temporary.unlink(missing_ok=True)
            print("Verified idevice_pair DMG saved in downloads/idevice-pair-macos. Open it locally only within the approved setup scope.")
        else:
            for relative in ["pairing.mobiledevicepairing","secure-rp/pairing.mobiledevicepairing"]:
                pairing=private_path(PRIVATE/relative)
                if pairing.exists() and not pairing.is_file():raise WorkflowError("The private pairing export path is not a regular file; nothing was removed from that path.")
                pairing.unlink(missing_ok=True)
            print("The designated temporary pairing exports were removed. OS-managed pairing and the encrypted in-app backup remain. Any earlier differently named export must be reviewed locally.")
        return 0
    except (WorkflowError,OSError,ValueError,KeyError,TypeError,AttributeError,plistlib.InvalidFileException):
        # Exceptions can contain paths/identifiers; expose only reviewed WorkflowError text.
        error=sys.exc_info()[1]
        print(str(error) if isinstance(error,WorkflowError) else "This step could not finish safely. Review it locally; no raw private output was saved.",file=sys.stderr)
        return 1

if __name__=="__main__": raise SystemExit(main())
