# Update Tin’s existing App Installer setup

For compiled source **2a31f6eed1256daacb5d0bed844f5839bce63f20**. Cloud run40884961768 passed the package, source, native project, private-pairing helper and kit gates, plus the one affected native import method. **Private-draft transfer40887996440 succeeded. This exact kit is verified and available.** This merge preserves unlisted private setup/signing files. It does not access Keychain, contact Apple, sign or install anything. Tin’s existing approval covers this routine update; large Xcode installations and Apple-account changes remain separate.

Download **AppInstaller-native-bootstrap-kit.zip** from the existing [private releases](https://github.com/mcantua/claude-chatg/releases). Size **43,111,535 bytes**; SHA-256 **1cda0defbcf540ffd68d8eb743be9f9e618da01e4ed2e4f9f359aa81779cfe93**. Use the ZIP itself in the chooser. Keep the existing app and project folder. The first chooser asks for the setup command in your actual existing folder; the next asks for the ZIP. No assumed Mac path, folder move or second project copy is needed.

Paste this block into Terminal on the approved Mac:

```bash
/usr/bin/python3 - <<'UPDATE_KIT'
import hashlib, json, pathlib, subprocess
try:
    selected = pathlib.Path(subprocess.check_output(['/usr/bin/osascript', '-e', 'POSIX path of (choose file with prompt "Choose Run-App-Installer-Setup.command from your existing App Installer folder")'], text=True).strip())
except subprocess.CalledProcessError:
    raise SystemExit('Folder selection cancelled. No update performed.')
if selected.name != 'Run-App-Installer-Setup.command' or selected.is_symlink() or not selected.is_file() or len(selected.parents) < 3:
    raise SystemExit('Choose the existing App Installer setup command. No update performed.')
root = selected.parents[2]
if root.is_symlink() or root.name != 'claude-chatg' or root.parent.name != 'AI-Workspace' or not (root / 'BootstrapKitManifest.json').is_file():
    raise SystemExit('Existing setup folder not found safely; no update performed.')
try:
    chosen = subprocess.check_output(['/usr/bin/osascript', '-e', 'POSIX path of (choose file with prompt "Choose the NEW AppInstaller native setup kit ZIP")'], text=True).strip()
except subprocess.CalledProcessError:
    raise SystemExit('File selection cancelled. No project files were changed.')
kit = pathlib.Path(chosen)
if kit.stat().st_size != 43111535 or hashlib.sha256(kit.read_bytes()).hexdigest() != '1cda0defbcf540ffd68d8eb743be9f9e618da01e4ed2e4f9f359aa81779cfe93':
    raise SystemExit('This is not the new verified kit. No project files were changed.')
subprocess.run(['/usr/bin/ditto', '-x', '-k', str(kit), str(root.parent.parent)], check=True)
manifest = json.loads((root / 'BootstrapKitManifest.json').read_text())
if manifest.get('bootstrap_tool_commit') != '2a31f6eed1256daacb5d0bed844f5839bce63f20' or manifest.get('secure_rp_tool', {}).get('protocol_record_version') != 2:
    raise SystemExit('Updated setup identity did not match. Stop before running setup.')
for relative in manifest['native_sources'] + [manifest['rust_library'], 'app-installer/ios/Info.plist']:
    path = root / relative
    if path.is_symlink() or not path.resolve().is_relative_to(root.resolve()) or not path.is_file():
        raise SystemExit('A reviewed input path is unsafe. Stop before setup.')
    path.touch()
print('Updated kit verified. Existing private files preserved. Run the setup helper for the same-identity app update and private USB pairing.')
UPDATE_KIT
```

Touching the reviewed native inputs and library changes only timestamps. It ensures Xcode recompiles/relinks the new source despite deterministic ZIP dates; all content hashes remain unchanged. The normal helper checks the managed payload hashes before building/signing. If extraction is interrupted, repeat this exact verified merge before running setup. No rollback copy is created.

Then open `app-installer/device/Run-App-Installer-Setup.command` in the existing folder and choose **Install/update app** once to apply this changed native import code. Keep the physical iPhone unlocked/trusted, choose its existing app identity and the same development team. An automatic-launch failure after a successful install does not require another reinstall: open the app manually and let pairing continue. Apple passwords/codes stay in Apple’s UI or on the phone.

The new helper creates the **version-2 peer-pinned** file under `app-installer/device/private/secure-rp/`. AirDrop that file directly to this iPhone and choose **Replace pairing file** in App Installer. Do not upload it to chat or GitHub. Keep LocalDevVPN connected and the iPhone on Wi-Fi, then unlock and check the connection. A standard unpinned Remote export cannot substitute for this file.

If this app update is already complete, reopen the same command and choose **Pair only**. That choice skips build, signing, installation and Apple account lookup. The three built-in `PAIRING_` lines can be shared if pairing fails. See [pairing-only recovery](PAIRING-ONLY-DIAGNOSIS.md) for details and a hash-pinned chooser fallback for the unchanged older5855 kit. Do not assume an older nested Mac path still exists.

Keep the old private Lockdown export and the new Mac pairing copy until the actual phone connection succeeds. Then remove obsolete temporary exports/downloads, retaining the app’s protected primary and single encrypted backup. Do not uninstall the app, delete personal data, remove OS-managed trust or disable macOS security.

This update fixes coordinated pairing import, validates newly created USB pairing on a fresh pinned connection before export, rejects malformed discovery/error fields and adds pairing-only recovery. Earlier authenticated Remote Pairing/RSD, adaptive native UI and safe partial refresh remain present. On-phone connection, IPA signing/install/update/refresh, security recovery and real outer/inner/folding acceptance are still separate unverified requirements. The cloud IPAs remain unsigned candidates; the setup helper uses the existing local Xcode identity.
