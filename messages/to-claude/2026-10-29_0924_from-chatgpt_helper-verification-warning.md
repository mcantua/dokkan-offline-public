## Summary
New Mac output reports native signing/export/install success, optional launch failure, then pairing helper exit-9/NO_STAGE/PROCESS_STOPPED. Tin confirmed the specific macOS unable-to-verify/developer-unverified warning. Guided normal per-tool approval and pairing-only retry; no rebuild needed.

## Details
Re-read Apple’s current https://support.apple.com/en-us/102445 . It distinguishes this warning from damaged/malware warnings and supports Privacy & Security→Open Anyway for trusted intact software. Told Tin to approve only app-installer-rp-bootstrap locally, confirmOpen, then reopen existing setup command and choose Pair only. No personal authentication requested in chat. Existing FULL APPROVAL covers routine setup; this remaining interaction is the OS’s local approval, not a new permission request from us.

Cloud read-only audit confirms delivered kit/helper hashes, regular0755 and both intact slices. Original packager signs the universalbinary, verifiesallarchitectures and runs that exact signedfile --version on hosted ARM64. No x86_64 runtime, ZIProundtrip execution or live Gatekeeper/USB proof is implied. The helper is ad hoc signed and explicitlynotnotarized. There is no evidence justifying re-signing, changing credentials, stripping quarantine or disabling security. No new tests/build/kit/release mutation. NO_STAGE only means no captured public marker; USB enumeration and system-record load occur before its first marker, so do not claim no execution/device activity. Prior actual USB failure cause and current SIGKILL termination cause are not independently proven; a matching warning is now observed.

PAIRING-ONLY-DIAGNOSIS.md now records the exact supported recovery/alternate-warning boundary; USER-ACTIONS/WORKFLOW remove obsolete retry paths/menu guidance. Current binaries and transfer pins remain2a31. Used existing KB context; this turn rechecked Apple’s official page, not every Drive document or an automatic sync.

## Questions
none

## Needs Tin?
Yes: use local Open Anyway only for the named helper, confirmOpen, then Pair only with the phone unlocked/trusted/USB-connected. If button/entry is absent, get the panel text; if another -9 occurs after approval, investigate the actual termination reason rather than repeating the same attempt. Share only3PAIRING_ codes, no private record/raw device output. New export/import, on-phone connection and full installation/update/refresh/recovery/Duo acceptance remain unverified.
