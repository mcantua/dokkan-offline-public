# Approved Mac / iPhone Duo checks

Tin explicitly approved both scopes on Oct 28, 2026: read-only metadata from his Eclipse/Sparking IPAs, and signing/installing Unit Creator 2.36.3 / code 128 on his iPhone Duo with fresh launch/display evidence. Apple provisioning may use his Mac's internet. This approval does not cover unrelated private files, other devices/apps, key exports or later unrequested actions. There is no repeat permission dialog.

This source is prepared/reviewed in the cloud; no Mac/device action has been run here. The user must run the helper because this chat has no direct Mac tool.

## Unit Creator install and Duo check

Double-click **run/approved-duo-check.command** in the downloaded source bundle. Put the exact `UnitCreator-2.36.3.ipa` beside the bundle's `run` and `tools` folders, or select that file when prompted. It must have SHA-256 `1b3fa2ae1526c83afdd8acd98b12c9e35b699a086f7011bf5a389f41cd857d60`, version 2.36.3 and code 128. The original IPA is read-only.

Needs macOS, Xcode / command-line tools, an existing signed-in Apple development account and Python 3. The existing signing project must be at `~/AI-Workspace/Dokkan-Unit-Creator/signing/DokkanSigning.xcodeproj`. The phone must be plugged in, unlocked and trusted. The intended team and device are the same ones configured by the existing project; the helper does not choose the first unrelated identity or uninstall any app to free a signing slot.

The helper generates a fresh profile into a private temporary directory, verifies its expiry, explicit app ID, team, device and development entitlement, then selects a valid local signing identity whose certificate is actually in that profile. It signs a private copy with only checked baseline entitlements and verifies the signature. No password, email, key, raw profile or raw Xcode/device log is printed or retained. OS Keychain/Xcode prompts may appear; enter credentials only into Apple's UI.

Install, launch and display-log copy failures stop the run. A prelaunch baseline and timestamp filter reject old log entries. Each accepted sample must show `startup=ready`, page/inner/window widths agreeing, and the window/page filling the reported screen. Follow the outer → inner → outer prompts; rotating the same screen does not qualify as a changed fold shape. If no fresh ready sample appears, the helper fails rather than claiming success. A real time mismatch or missing diagnostic record may therefore require investigation.

Only after all checks pass does the helper atomically replace its own `build/UnitCreator-approved-device.ipa`. Existing original/working IPAs and unrelated files are left alone. A failed run cannot replace that working package; an already performed device installation is not automatically rolled back. The workflow never erases the app's data or uninstalls other apps.

Attach only `~/AI-Workspace/Dokkan-Unit-Creator/evidence/approved-duo/result.json`. It contains sanitized stages and measured geometry, not raw device/profile information. `INSTALLED_LAUNCHED_DISPLAY_CHECKED` means exactly those checks, not project completion. Touch, keyboard, scrolling, file import/export, saved-data persistence, screenshot capture and fold-animation smoothness remain explicitly untested. `--check-installed` is a display-only mode and does not assert which app version is installed.

Legacy `run/device-install.command`, `run/device-check.command` and `tools/duo-device-test.sh` in this updated source all forward to the reviewed helper. Older copies on the Mac are not automatically updated; use the downloaded new helper rather than an old installed script.

## Offline Dokkan read-only IPA metadata

Double-click **run/approved-ipa-metadata.command**. Choose the Eclipse IPA, then the Sparking IPA. This invokes the reviewed collector directly, without another Continue dialog. It reads allowlisted metadata/hook names only, never modifies either IPA, extracts keys, launches a game or contacts a server.

Attach only these two small files under `~/AI-Workspace/Offline Dokkan Battle/evidence/`:

- `eclipse-ipa-metadata.json`
- `sparking-ipa-metadata.json`

The collector also reads bounded Mach-O headers: architecture, recorded SDK/minimum OS, encryption status, chained-fixup presence and an allowlist of library basenames. It reports no arbitrary install paths, binary bytes, keys, hook addresses or guessed runtime signatures. An encrypted binary is reported as encrypted; the collector does not decrypt it. SDK metadata describes the binary and is not proof that it runs on a particular device.

The metadata does not include request/response payloads and cannot by itself prove all game-wire contracts. The portable source bundle needs `tools/approved_duo_check.py`, `tools/collect_protocol_evidence.py`, **`tools/macho_metadata.py` beside the collector**, both `run/approved-*.command` wrappers and this document. Copy both collector modules from `offline-dokkan/tools/` without changes. The existing older approved install bundle remains pinned to its original candidate; use the current repository collector when these new static facts are needed. No Mac execution has occurred in this chat.
