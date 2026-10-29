# Pairing-only recovery

**Latest actual result:** Tin's run reached `RP_BOOTSTRAP_AUTHENTICATED_PAIRING_PENDING` then returned `PAIR_AUTHENTICATION`. This is past the earlier macOS verification-warning block. A real TLV message-fragmentation fix is committed in8e602da and its5 focused cloud checks passed, but **it is not yet in a downloadable kit**: GitHub refused the Mac builder before any job steps because of account billing/spending restrictions. The currently delivered2a31 kit does not contain this newer fix; downloading/retrying it again will not apply that fix. See [the precise continuation](PAIRING-HANDSHAKE-CONTINUATION.md). Keep the installed app and private files.

## Updated2a31 kit — built-in diagnostics

Cloud run40884961768 passed for source2a31f6eed1256daacb5d0bed844f5839bce63f20. Private-draft transfer40887996440 verified the replacement delivery; use the exact kit pins in [UPDATE-EXISTING-KIT.md](UPDATE-EXISTING-KIT.md), not a similarly named older download.

After that one app update, double-click **Run-App-Installer-Setup.command** in the actual existing folder and choose **Pair only**. Keep the selected physical iPhone unlocked, trusted and USB-connected. No account lookup, build, signing or reinstall occurs in this mode. The verified helper validates new pairing on a fresh authenticated USB connection before saving the private file. It does not overwrite an existing export or bypass a trust/signature check.

If pairing fails, share only the three **PAIRING_EXIT**, **PAIRING_STAGE**, and **PAIRING_REASON** lines. These are built-in fixed public codes; no custom Terminal patch is needed. Keep private records and raw device logs out of chat/GitHub. A successful export opens its private folder for direct AirDrop/import; it does not prove the phone's VPN connection, signing or refresh.

### Mac verification warning and PROCESS_STOPPED

Tin's latest run reports successful native signing/export/install, then `PAIRING_EXIT: -9`, `PAIRING_STAGE: NO_STAGE`, `PAIRING_REASON: PROCESS_STOPPED`. Exit -9 means SIGKILL, not a diagnosis of its cause; NO_STAGE only means no whitelisted stage was captured. Tin separately confirmed that macOS displayed **Apple could not verify it is free of malware / developer cannot be verified**, specifically the verification-warning category rather than a damaged/malware warning.

The source-bound helper has an ad hoc signature and is **not notarized by Apple**. The wizard checks its delivered hash, signature and architectures before execution; those checks do not substitute for macOS Gatekeeper approval. For this confirmed warning, use Apple's supported per-tool UI:

1. On the approved Mac, open **System Settings → Privacy & Security**.
2. Find **app-installer-rp-bootstrap**, choose **Open Anyway**, then confirm **Open**. Use only the entry for this reviewed helper. Keep any macOS authentication in its own local prompt.
3. Reopen **Run-App-Installer-Setup.command** in the same existing folder and choose **Pair only**. Do not rebuild or reinstall the already updated iPhone app.

If that helper entry or Open Anyway is absent, report what the panel says before another attempt. If the message instead says **damaged**, **will damage your computer**, or names detected malware, stop for that different diagnosis; these instructions do not apply. If the approved retry still returns -9, investigate the actual termination reason rather than repeatedly retrying. No quarantine-removal command, global security change, local re-signing or new certificate is part of this recovery.

Official source checked October 29, 2026: [Apple — Safely open apps on your Mac](https://support.apple.com/en-us/102445). No physical approval/retry or successful pairing is claimed from this documentation.

## Unchanged5855 kit — chooser fallback

This older-kit recipe remains available to diagnose the already installed5855 setup without another download. It deliberately accepts only its exact original script hashes. Updated2a31 scripts use the built-in **Pair only** flow above and will be rejected by this older fallback.

The reported Mac run completed native signing/export/install. Automatic launch was not confirmed; the helper continued pairing as intended, but its generic wrapper discarded the private CLI’s safe stage/failure messages. The root cause is not yet known. Keep the installed app and existing private files.

Tin already approved this Mac/USB pairing scope. The following one-off Terminal recipe imports the existing unchanged wizard and retains all kit/hash/architecture/signature/physical-device checks. It runs only its pairing-only mode: no build, signing, installation, Apple account discovery or new download. The current kit remains byte-identical. The temporary in-memory wrapper prints only a numeric exit code and fixed public stage/reason codes; raw stdout/stderr/device identifiers/records remain captured. It never prints a private file. The source workflow now separately supports exact allowlisted safe errors; that fix is committed for future kit delivery, not silently patched into Tin’s verified kit.

Open a new Terminal window, keep the iPhone unlocked and USB-connected, and paste the complete block. A file chooser appears: select **Run-App-Installer-Setup.command** in the existing App Installer folder you used. The check verifies the two loaded scripts against the released5855 kit before importing them; it no longer assumes the old nested folder path. Choose the physical phone if asked. Share only the three PAIRING_ lines, not raw private logs.

```bash
/usr/bin/python3 - <<'PAIR_CHECK'
import hashlib, importlib.util, pathlib, subprocess
try:
    selected = subprocess.check_output(['/usr/bin/osascript', '-e', 'POSIX path of (choose file with prompt "Choose Run-App-Installer-Setup.command from the App Installer folder you used")'], text=True).strip()
except subprocess.CalledProcessError:
    raise SystemExit('File selection cancelled. No pairing step ran.')
entry = pathlib.Path(selected)
if entry.name != 'Run-App-Installer-Setup.command' or not entry.is_file():
    raise SystemExit('Choose the App Installer setup command file. No pairing step ran.')
expected = {
    'setup-wizard.py': 'f008b3a014fbfb39048e5c2465031859d74c8f083e430651ed39aa57d5d91ed1',
    'device-workflow.py': '9425301390024eb2c68d36389ea89b17c266eee746ea04366e4d30bab9fddbaf'
}
for name, digest in expected.items():
    source = entry.parent / name
    if source.is_symlink() or not source.is_file() or source.stat().st_size > 256*1024 or hashlib.sha256(source.read_bytes()).hexdigest() != digest:
        raise SystemExit('This is not the verified current setup folder. No pairing step ran.')
p = entry.parent / 'setup-wizard.py'
s = importlib.util.spec_from_file_location('paircheck', p)
m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
original = m.workflow.subprocess.run
reasons = {
    'private export folder must': 'PRIVATE_FOLDER',
    'private export or interrupted export': 'EXISTING_EXPORT',
    'system USB device service': 'USB_SERVICE',
    'selected physical USB iPhone': 'USB_SELECTION',
    'existing system USB trust': 'USB_TRUST',
    'authenticated USB identity or session': 'USB_SECURE_SESSION_OR_SERVICE',
    'explicit remote pairing': 'PAIR_AUTHENTICATION',
    'version-2 device pin': 'DEVICE_PIN',
    'private export could not finish': 'SAVE_EXPORT'
}
stages = {'RP_BOOTSTRAP_USB_SELECTED', 'RP_BOOTSTRAP_USB_TRUST_VERIFIED', 'RP_BOOTSTRAP_AUTHENTICATED_PAIRING_PENDING', 'RP_BOOTSTRAP_EXISTING_VERIFIED', 'RP_BOOTSTRAP_READY'}
def checked_run(argv, **kwargs):
    result = original(argv, **kwargs)
    if pathlib.Path(str(argv[0])).name == 'app-installer-rp-bootstrap':
        text = (result.stderr or b'').decode('utf-8', errors='replace')
        seen = [line for line in (result.stdout or b'').decode('utf-8', errors='replace').splitlines() if line in stages]
        reason = next((label for words, label in reasons.items() if words in text), 'UNCLASSIFIED')
        print('PAIRING_EXIT:', result.returncode)
        print('PAIRING_STAGE:', seen[-1] if seen else 'NO_STAGE')
        print('PAIRING_REASON:', reason)
    return result
m.workflow.subprocess.run = checked_run
m.main(['--execute', '--pairing-only'])
PAIR_CHECK
```

If exit0 and stageRP_BOOTSTRAP_READY appear, the export step completed; this does not verify the phone connection. Use the private folder opened by the wizard to AirDrop pairing.mobiledevicepairing directly to this iPhone and import it. Otherwise the fixed stage/reason localizes the next safe repair. Do not reset trust, overwrite private exports or disable security blindly.
