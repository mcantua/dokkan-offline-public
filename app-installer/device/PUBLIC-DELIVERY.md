# Verified App Installer cloud update

November 1, 2026. **The corrected UI and backend update is ready for later authorized Mac setup.** Source`ed931b9cff9c047e5de6a21d8d25db3a3154f471`, package41322933617 and actual hostedMac signature/draft delivery41324387393 all passed their scoped checks. The existing unpublished draft430349496 contains exactly seven assets with verified server sizes/hashes. Candidates remain unsigned/`release_ready=false`; live account/phone and physical Duo acceptance are unverified.

Current verified [AppInstaller-native-bootstrap-kit.zip](https://github.com/mcantua/dokkan-offline-public/releases/download/untagged-adbb5d3025308a87b412/AppInstaller-native-bootstrap-kit.zip). Tin's Mac is unavailable, so no download or local action is requested now. When ready, sign into GitHub as the repository owner to access the unpublished **App Installer — unsigned public review** draft. Do not publish it or use an old kit.

- ZIP bytes: **44231197** (44.2 MB decimal).
- SHA-256: `895f0017ae526a63cb1144499a61c190b2142d3800e2f78baa97ad6b8bc96c3b`.
- Source revision: `ed931b9cff9c047e5de6a21d8d25db3a3154f471`.
- Native static library and universal arm64/x86_64 pairing helper are already cloud-built; no Mac Rust build, full repository or154MB source download is needed.
- Exact seven-file pins: `app-installer/cloud-ui/public-delivery-contract.json`.
- Actual delivery receipt/server readback: `downloads/completion-verification/public-pairing/resume-20261101/run41324387393-delivery/`.
- Sole cloud-local distribution: `app-installer/build/work/latest-reviewed/`. Old build/outer archive duplicates were removed after verification; no backup retained.

## Advance notice before personal use

The download uses44.2MB plus ordinary HTTPS overhead through the Mac's selected connection. This chat cannot see whether that connection is Wi-Fi or a cellular hotspot. Use the intended connection before downloading. Downloading/overlaying the kit alone does not sign in to Apple or install to the phone. No personal Mac/network operation was performed by the cloud session.

The local overlay below uses only the selected ZIP, the new `AI-Workspace/dokkan-offline-public` folder and macOS signature verification. It initiates no dependency download, Apple account operation or phone install; OS background traffic is not controlled. Earlier scoped setup approval persists. Large Xcode installation or account/certificate changes retain separate approval.

## Verify and overlay the downloaded kit

Keep the ZIP unopened until this verification. Paste the following into Terminal on the Mac and choose the newly downloaded ZIP. It checks the exact whole ZIP and embedded updater before executing it in memory; the updater then independently checks every managed file and the helper's actual Mac signature before replacement. It preserves unlisted private files. It never opens or copies the frozen backup.

```bash
/usr/bin/python3 - <<'UPDATE_PUBLIC_KIT'
from pathlib import Path
import hashlib, io, subprocess, unicodedata, zipfile
size = 44231197
sha = '895f0017ae526a63cb1144499a61c190b2142d3800e2f78baa97ad6b8bc96c3b'
source = 'ed931b9cff9c047e5de6a21d8d25db3a3154f471'
try:
    selected = subprocess.check_output(['/usr/bin/osascript', '-e', 'POSIX path of (choose file with prompt "Choose the NEW public AppInstaller native kit ZIP")'], text=True).strip()
except subprocess.CalledProcessError:
    raise SystemExit('Selection cancelled; no project files changed.')
kit = Path(selected)
if any(unicodedata.normalize('NFC', p).casefold() in {'claude-chatg', 'claude-chatgpt'} for p in kit.parts):
    raise SystemExit('Choose the new download outside the frozen backup; no update performed.')
if not kit.is_absolute() or '..' in kit.parts or any(part.is_symlink() for part in (kit, *kit.parents)):
    raise SystemExit('Choose a regular ZIP outside linked/frozen folders; no update performed.')
if not kit.is_file() or kit.stat().st_size != size:
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

## Included fixes and actual verification

The update contains bounded resource signing, cooperative signing/verifier cancellation, a128MiB executable/4MiB signature budget, durable source-directory promotion and direct five-minute authorization-lease checks. Core/transport/recovery checks keep their exact source scope. The native HUD has a readable two-line preview, full scrolling Task details/Done, preserved progress/Cancel and visible compact activity. Actual responsive41321551443 passed1method/0failures in12.518s on genuine compilerSDK27.1 and regular simulator runtime27.0; no physical-Duo claim.

Package41322933617 reused15matching passes and ran0fresh tests. Independent full corresponding-source/IPA review and38-payload/24-required-source kit review passed, with408 dependency packages/zero notice gaps. Delivery41324387393 verified the helper seal using actual hostedMac codesign, then all seven final server assets. This does not verify personal-device authentication, installation, refresh or folding.

A supplementary read-only reviewer previously opened the frozen checkout by mistake. No writes were reported; its findings were excluded and public source rechecked. The current kit contains the corrected continuation; the old b45memo's no-frozen-read statement is historical and incorrect. The incident ledger and STATUS preserve the record. Never reopen the frozen checkout for an audit.

## Then update and pair

Before launching setup, announce Mac/Xcode/USB use and the unknown amount of any Apple provisioning traffic. Use the existing installed App Installer bundle identity and development team; do not uninstall/reset data or create a replacement identity. Launch only the new public folder's `app-installer/device/Run-App-Installer-Setup.command`. Its full setup is needed for an incompatible old installed app; pairing-only does not update an old importer. A launch timeout does not justify reinstalling.

After the compatible app is installed, create/import the new private **version2 peer-pinned** export locally. Pairing-only skips Apple/team discovery and app build/install. Keep the phone unlocked and trusted by USB. Transfer the export directly to that phone, keep LocalDevVPN configured and enter numeric connection settings locally only. A saved file or an advertisement is not a successful authenticated session. Continue to actual installation/update/refresh/recovery and both-display/fold acceptance.

The helper's ad-hoc integrity seal was verified on hosted macOS; it is **not Developer ID notarized**. If macOS presents the known unidentified-developer warning, review Apple's [current supported instructions](https://support.apple.com/en-us/102445) for an individual app. Do not disable Gatekeeper, remove quarantine globally, re-sign a failed binary or proceed past a malware/damage warning. New Developer ID/notarization credential changes need their separately approved scope.

This document is a cloud-prepared next-step guide. Its Mac/phone commands have not been executed on Tin's devices, and no physical or final-release verification is claimed.
