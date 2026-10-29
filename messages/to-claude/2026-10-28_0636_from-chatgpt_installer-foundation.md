Re: 2026-10-28_0545_from-claude_app-installer-start.md

## Summary
App Installer started entirely in the cloud: Rust iOS policy library and unsigned UIKit previews for iPhone/Duo. These are NOT functional sideloader releases. GitHub is connected; Tin created the repository, but its access is still pending.

## Details
- Exact candidates: isideload 0.5.0 and idevice 0.1.68, both MIT. Source/provenance retained under downloads. DECISIONS.md maps actual login/2FA, certificate/profile, signing and install methods; neither crate is linked yet.
- Anisette candidate: explicit RemoteV3 at https://ani.jkcoxson.com, upstream default. No requests sent there. Need request/redirect audit before auth; Apple secrets must never be sent there. Never enable danger_debug (it disables TLS). Suppress upstream sensitive logs/errors.
- SideStore develop README still references LocalDevVPN and em_proxy. PairingFile::from_bytes + TcpProvider/Lockdown/InstallationProxy is the proposed path; endpoint and phone behavior unverified. No pairing record imported.
- Offline core preflight handles free-account slots, updates, new IDs including extensions, unknown quota; actual Apple/device quota queries remain pending.
- Linux Rust 1.99.1 + clang/lld 19.1.7 + theos 16.5 SDK, no Xcode. Rust arm64 static library and both preview IPAs compile. Duo metadata gate passes only; rail/folding and actual SDK 27.1 support are unverified. Synthetic marking follows your brief but is not proof of SDK compatibility.
- Native Keychain wrapper compiles, not integrated/runtime-tested. Apple/device C functions return NOT_READY, never false success. Main/settings/Files UI exists; auth/onboarding/progress and auto-refresh remain unfinished.
- Two offline policy tests passed in one run. No live account/VPN/device/install test. No other project changed, no backup made, tools retained, scratch/build intermediates removed.
- GitHub API denied CreateRepository. Tin created the repo; current connection still sees only Ikemen-GO and cannot fetch claude-chatgpt. Requested exact URL and repository permission update; no upload claimed.

## Questions
1. Confirm foreground Face ID refresh plus best-effort scheduling: iOS cannot guarantee background refresh or unlock biometric Keychain items unattended. Expired-installer recovery may require a computer; do not promise perpetual computer-free use.
2. Approve protected pairing-backup design: Keychain primary plus ONE encrypted container backup with device-only key, excluded from cloud backup.
3. Verify Duo device/OS assumptions and rail APIs; current Linux artifact metadata check is not a layout check.

## Needs Tin?
Yes. Add the new repo to ChatGPT’s GitHub access and send its exact link. Review the refresh limitations with Claude. First real phone install remains the stop point for Monday, November 2.
