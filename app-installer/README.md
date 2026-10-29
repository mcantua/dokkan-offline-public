# App Installer

**Current public-source continuation (October 29):** App Installer is resumed on `chatgpt/app-installer-pairing-repair` in `mcantua/dokkan-offline-public`. The private backup stays untouched. No builds or compilation until Tin says "make the builds". Read [device/PUBLIC-CONTINUATION.md](device/PUBLIC-CONTINUATION.md): this clean copy predates the installed app's newer helper/RP transport; old download pins and private-release commands below are historical and must not be used for the current repair.


A separate iPhone app using Objective-C/UIKit and a Rust signing/device core. Source is AGPL-3.0-only. Both build variants keep the same stable app identity; the approved native bootstrap uses a deterministic developer-team-qualified identity when needed.

**Not a verified final release yet.** Live Apple sign-in, signing, installation, refresh and physical Duo behavior require actual device verification. A build or simulator pass cannot establish them. Tin’s latest instruction allows first-install work once specific Mac/network/device access is approved; Monday review is not a development stop.

## Development and testing rule

Prioritize completing features and fixing concrete bugs. Batch related changes and compatible builds. Use the smallest essential checks for the changed feature; repeat passing checks only when subsequent changes could affect them. Expand testing for a real failure, regression or critical functionality change. After development, perform one focused final verification of the essential install/update/signing/error/stability/release workflow. Passing checks and documents are milestones, not completion.

## Implemented

- Apple account login, saved-session unlock, trusted-device/SMS/resend 2FA, developer-team selection and optional biometrics after genuine device-owner first-use authentication.
- Real pinned isideload0.5.0/idevice0.1.68 integration. Account/session/certificate keys stay in device-only Keychain; passwords are not saved for session restoration.
- Bounded IPA validation, stable update identities, profile-authorized required capabilities and independent code/CMS/profile/resource verification before installation. No silent removal of required capabilities or foreign-resource ownership bypass.
- Confirmed-install source retention, one durable interrupted-install intent, installed-only refresh, actual minimum main/extension expiry and self-refresh reconstruction.
- Pairing checks that distinguish saved files from verified device connectivity, one encrypted pairing backup, bounded continuation of approved work, expiry alerts and due-refresh on daily Open App with genuine foreground approval.
- Responsive scene-based Duo layouts, display diagnostics, state-preserving transient inactivity and clear progress/cancellation/errors.

See CAPABILITY-MATRIX.md for supported target capabilities and genuine service/ownership limits; DECISIONS.md, TASKLIST.md and VERIFICATION.md distinguish implementation from verified acceptance.

## Genuine SDK cloud verification and candidates

Run GitHub Actions → **App Installer cloud verification and candidates**, enabling `package_candidates` for the grouped release-candidate check. It uses genuine hosted Xcode/iOS SDK27.1+, the actual Duo simulator, production source and focused native/Keychain/lifecycle checks. It never signs in to Apple or accesses Tin’s hardware.

After all checks succeed, delivery includes unsigned iPhone/Duo candidates, their exact complete source/relink companion and a small native bootstrap kit. Candidate and source hashes are bound together; unsigned artifacts remain candidates. Failed diagnostics cannot replace the last complete kit/source pair. `release/verify-release.py` refuses final classification without the required live and physical acceptance evidence.

## Linux development build

```sh
python3 app-installer/build/setup-linux.py
bash app-installer/build/build-ipa.sh iphone
bash app-installer/build/build-ipa.sh duo
```

This retained development/reproducibility path uses pinned Rust1.99.1, LLVM19.1.7 and16.5 headers, with declared compatible Debian13 host prerequisites. Its synthetic newer SDK metadata is not native Duo release proof. Use the genuine Apple SDK cloud path for release candidates. Tools and caches stay under this repository; see build-notes.md and downloads/*/SOURCE.md.

## First device setup

Use device/USER-ACTIONS.md and the source-bound minimal native kit. Explain the exact transfer size and signing/install steps, then ask Tin and wait before any MacBook/personal-network use. A connected Mac is not approval. The one-click helper starts with a plan; actual execution requires the already approved scope, Apple UI sign-in, phone trust/Developer Mode and USB access. It does not need a full Unit Creator checkout or Cargo installation.

Signing keys, profiles and pairing exports stay in ignored local private storage/OS Keychain. The actual verified signed IPA is exported only to device/private/builds/; never upload its personal profile/device identifiers to GitHub. Complete on-phone sign-in, pairing, install/update, refresh and display checks before recording acceptance.

iOS can delay background work and cannot unlock biometric Keychain items unattended. Daily Open App plus foreground approval is a mitigation. Recovery after actual installer expiry can require a computer; no perpetual unattended or unconditional computer-free recovery guarantee is made.
