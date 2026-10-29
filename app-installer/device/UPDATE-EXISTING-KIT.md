# Update the public setup kit without losing data

Use [Public kit quick start](PUBLIC-QUICK-START.md) first. **No current download size/hash or compatible installed source is pinned here yet.** The local updater is [update-public-kit.py](update-public-kit.py); wait for the actual reviewed public kit receipt and the assistant's exact source-bound invocation. Do not execute a placeholder or reuse old download pins.

## Before downloading

Give advance notice of Mac and selected internet use: the exact **AppInstaller-native-bootstrap-kit.zip** asset, verified bytes and SHA-256, and its reviewed source revision. Routine approval already granted persists; no repeated approval is needed for the same authorized task. This advance notice remains mandatory before Wi-Fi/hotspot traffic. A substantially larger Xcode install or Apple credential/certificate change requires its separate approval.

Download the small kit once from **mcantua/dokkan-offline-public**, draft **app-installer-public-review**. Do not fetch the full repository, corresponding-source archive, Rust toolchain or crate dependencies onto the Mac for setup. Keep the complete source companion available in the cloud; the needed Rust library and helper are already built in the kit.

## Verified chooser and overlay

The updater defaults to a plan: it reads no kit or destination, invokes no chooser/tool and changes nothing. Execution requires all three actual reviewed pins through `--expected-sha256`, `--expected-bytes` and `--source-commit`, plus `--execute`. Supply the selected paths using `--kit` and `--destination`, or use `--choose` to open local macOS file/folder choosers for missing paths. There are no download or API options.

The assistant must bind the updater source itself to the reviewed ZIP before invoking it. Do not execute a script extracted from an unverified download. The exact invocation with real pins comes with the delivery receipt, rather than a command containing guessed values here.

The updater:

- Lets Tin choose the downloaded ZIP and the intended **new public** project folder, avoiding a guessed home or nested path.
- Verifies the exact delivered ZIP bytes/hash **before extraction** and checks its manifest's public project, source revision and file closure. The archive may contain only the reviewed `AI-Workspace/dokkan-offline-public` payload.
- Rejects traversal, symlinks, unexpected payloads and a selected old-backup folder. It never reads or writes the frozen backup and never “repairs” an old manifest to make it pass.
- Checks the native/library/helper source and dependency-graph bindings, complete managed file closure and zero-gap notice reports. Before replacing managed files, it verifies the helper's real macOS signature seal for both architectures and requires the reviewed ad-hoc identity. It does not run the helper.
- Overlays only the manifest-listed managed files into **AI-Workspace/dokkan-offline-public**. It preserves unlisted local private outputs in that folder, phone data and the app's existing identity. It does not replace the whole folder or create another backup/rollback.
- Stops before managed replacement if any existing managed file matches neither its old manifest hash nor the reviewed new hash. It removes an obsolete managed public file only when its old hash still matches, and never removes an obsolete private file.
- Ensures the replaced managed Rust library is relinked despite deterministic ZIP timestamps, then leaves normal kit integrity/source checks in force. It does not alter the reviewed binary bytes to bypass a check.

Each file replacement is atomic and the manifest is committed last; the entire overlay is not one atomic transaction. An interrupted run may leave a mix of old and new managed files. Do not launch setup from that mixture. A rerun with the same reviewed ZIP accepts only its pinned new bytes or unchanged old-manifest bytes and completes the overlay. Run only one updater at a time. No rollback copies are created.

The tool exists, but its real delivery pins and a successful actual-kit Mac execution are still pending. Do not improvise an extraction command while the pins are missing. If only the old folder exists, create the new public folder without opening or copying from the backup.

The overlay itself is local filesystem work: no planned Apple request, app signing, installation, Keychain change or Rust compilation. Announce this local Mac use before it starts. macOS may still perform unrelated background network traffic; do not promise zero total internet use.

## After the overlay

Review the new kit's plan and its managed payload checks. If an app update is actually required for strict version-2 compatibility, keep the **same physical phone, development team and bundle identity**. The supplied setup uses Xcode and the cloud-built Rust library/helper. Apple provisioning traffic can be needed and is not a known fixed amount; announce that internet use before starting it. Keep reserved credential/certificate changes separate.

Never uninstall, clear phone data, remove Keychain records, reset trust or create a second installer identity as an update shortcut. An automatic launch failure alone does not justify reinstalling. Confirm manual launch and the installed source/version locally.

If the compatible app is already installed and only pairing failed, use the verified **pairing-only** action. Do not rerun the full setup/build/install. Creating or transferring a private version-2 export does not prove an on-phone authenticated connection; preserve needed private outputs until that connection succeeds.

If an overlay is interrupted or a hash/source check fails, stop before setup and review the exact selected public ZIP/folder. Do not run a mixed kit or disable integrity/security checks. After a successful verified update, delete the obsolete downloaded ZIP, keeping only the newest kit and no extra rollback copies.

## Retired history

The former executable update block and its fixed hashes described a historical private-repository kit. They have been removed from active instructions so they cannot accidentally target the frozen backup. Old source/kit receipts remain historical evidence only; they are not pins for this public delivery.
