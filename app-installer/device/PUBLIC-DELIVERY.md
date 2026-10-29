# Verified public App Installer delivery

October29,2026,2:10 PM US Central. Source **4c09a35bd30e5b39c229e3f9f401ffdc5cd143a8**. Cloud build40934237282 and hosted Mac verification/delivery40936908790 succeeded. All seven final server sizes/SHA-256 values match the reviewed contract. This is an unsigned review candidate, **release_ready=false**; real Apple/phone/Duo acceptance is pending.

Download only [AppInstaller-native-bootstrap-kit.zip](https://github.com/mcantua/dokkan-offline-public/releases/download/untagged-bed720fc78dd111d2a22/AppInstaller-native-bootstrap-kit.zip) for the next Mac step. Sign into GitHub as the repository owner to access the unpublished draft; if the direct link is unavailable, open the repository's Releases page and its **App Installer — unsigned public review** draft. Do not publish it or use an old kit as a workaround.

- Exact ZIP bytes: **44120569** (44.1 MB decimal).
- SHA-256: `4b8edb314c20b44789edb16c0b37b6c86e5c42ee677853883425ff2c8afc81a7`.
- Source revision: `4c09a35bd30e5b39c229e3f9f401ffdc5cd143a8`.
- Native static library and universal arm64/x86_64 pairing helper are already built in the cloud; no Mac Rust build or full repository/source download is needed.
- All seven source/IPA/kit/receipt pins: `app-installer/cloud-ui/public-delivery-contract.json`.
- Actual hosted receipt and independent final server readback: `downloads/completion-verification/public-pairing/run40936908790-delivery/`.
- Sole current cloud-local distribution: `app-installer/build/work/latest-reviewed/` (ignored). Outer artifact ZIP duplicates were removed after delivery verification.

## Advance notice before personal use

The download uses44.1MB plus ordinary HTTPS overhead through the Mac's selected connection. This chat cannot see whether that connection is Wi-Fi or a cellular hotspot. Use the intended connection before downloading. Downloading/overlaying the kit alone does not sign in to Apple or install to the phone. No personal Mac/network operation was performed by the cloud session.

The local overlay below uses only the selected ZIP, the new `AI-Workspace/dokkan-offline-public` folder and macOS signature verification. It initiates no dependency download, Apple account operation or phone install; OS background traffic is not controlled. Earlier scoped setup approval persists. Large Xcode installation or account/certificate changes retain separate approval.

## Verify and overlay the downloaded kit

Keep the ZIP unopened until this verification. Paste the following into Terminal on the Mac and choose the newly downloaded ZIP. It checks the exact whole ZIP and embedded updater before executing it in memory; the updater then independently checks every managed file and the helper's actual Mac signature before replacement. It preserves unlisted private files. It never opens or copies the frozen backup.

```bash
/usr/bin/python3 - <<'UPDATE_PUBLIC_KIT'
from pathlib import Path
import hashlib, io, subprocess, unicodedata, zipfile
size = 44120569
sha = '4b8edb314c20b44789edb16c0b37b6c86e5c42ee677853883425ff2c8afc81a7'
source = '4c09a35bd30e5b39c229e3f9f401ffdc5cd143a8'
try:
    selected = subprocess.check_output(['/usr/bin/osascript', '-e', 'POSIX path of (choose file with prompt "Choose the NEW public AppInstaller native kit ZIP")'], text=True).strip()
except subprocess.CalledProcessError:
    raise SystemExit('Selection cancelled; no project files changed.')
kit = Path(selected)
if any(unicodedata.normalize('NFC', p).casefold() in {'claude-chatg', 'claude-chatgpt'} for p in kit.parts):
    raise SystemExit('Choose the new download outside the frozen backup; no update performed.')
if kit.is_symlink() or kit.stat().st_size != size:
    raise SystemExit('This is not the reviewed ZIP; no update performed.')
blob = kit.read_bytes()
if len(blob) != size or hashlib.sha256(blob).hexdigest() != sha:
    raise SystemExit('ZIP integrity differs; no update performed.')
with zipfile.ZipFile(io.BytesIO(blob)) as archive:
    updater = archive.read('AI-Workspace/dokkan-offline-public/app-installer/device/update-public-kit.py')
if len(updater) != 29186 or hashlib.sha256(updater).hexdigest() != '48b878b87b90e6d3a4977c73418e703bbc3715293c1cbfbd8f0e3782c2a0e913':
    raise SystemExit('Updater integrity differs; no update performed.')
module = {'__name__': 'verified_public_kit_updater'}
exec(compile(updater, '<verified-public-kit-updater>', 'exec'), module)
module['apply_update'](kit, Path.home() / 'AI-Workspace/dokkan-offline-public', sha, size, source)
print('Verified public kit ready. No app install or pairing was attempted.')
UPDATE_PUBLIC_KIT
```

The printed result is enough; never paste pairing records, passwords, codes, raw device output or private identifiers. If this reports a managed-file/signature error, preserve the app/data and report only that safe message.

## Then update and pair

Before launching setup, announce Mac/Xcode/USB use and the unknown amount of any Apple provisioning traffic. Use the existing installed App Installer bundle identity and development team; do not uninstall/reset data or create a replacement identity. Launch only the new public folder's `app-installer/device/Run-App-Installer-Setup.command`. Its full setup is needed for an incompatible old installed app; pairing-only does not update an old importer. A launch timeout does not justify reinstalling.

After the compatible app is installed, create/import the new private **version2 peer-pinned** export locally. Pairing-only skips Apple/team discovery and app build/install. Keep the phone unlocked and trusted by USB. Transfer the export directly to that phone, keep LocalDevVPN configured and enter numeric connection settings locally only. A saved file or an advertisement is not a successful authenticated session. Continue to actual installation/update/refresh/recovery and both-display/fold acceptance.

The helper's ad-hoc integrity seal was verified on hosted macOS; it is **not Developer ID notarized**. If macOS presents the known unidentified-developer warning, review Apple's [current supported instructions](https://support.apple.com/en-us/102445) for an individual app. Do not disable Gatekeeper, remove quarantine globally, re-sign a failed binary or proceed past a malware/damage warning. New Developer ID/notarization credential changes need their separately approved scope.

This document is a cloud-prepared next-step guide. Its Mac/phone commands have not been executed on Tin's devices, and no physical or final-release verification is claimed.
