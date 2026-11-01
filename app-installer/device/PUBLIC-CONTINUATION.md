# App Installer public-source continuation

Updated: 2026-10-31 11:14 PM US Central. Active public repository `mcantua/dokkan-offline-public`, branch `chatgpt/app-installer-pairing-repair`, draft PR #7. Tin resumed development and authorized necessary cloud builds. No base/main merge or publication is authorized. The private backup remains frozen and untouched. This chat owns App Installer only.

## Latest completed development

Application build source **f941208e77ed37405cd9fbb109e87ed56f81fb45** contains four new fixes, following production source0648612:

- **Actual Pair only launcher:** Cancel / Pair only / Full setup, default Cancel; explicit plan/help. Pair-only skips Apple-team discovery, app building, installation and launch. Full setup rejects a kit/physical-phone variant mismatch before account discovery.
- **Bounded AFC upload:** both legacy and remote-pairing installation paths reuse a bounded buffer, move native reads off the async executor, await write acknowledgements and reject shortened/growing input. The prior code allocated each entire accepted multi-GB resource. This is an implementation/mocked-I/O result, not a real large-IPA phone result.
- **Actionable incomplete-record handling:** generic strict RPv2 may omit altIRK, but this app needs it for authenticated discovery. App-specific status8 rejects missing metadata before replacing primary/backup credentials; restored records show a fixed re-export message. Values0–7 and legacy Lockdown/vendor schema remain unchanged. The trusted USB helper already includes this key, so this does not establish why an intact helper export failed on Tin’s phone.
- **Clear setup guidance:** exact external delivery pins, separate pairing retry and same-identity app update, no unnecessary regeneration of a working compatible record, and no stale no-pins-yet wording. Guides embedded in the kit link to the external current receipt.

The previous authenticated SRP/TLV/Ed25519 setup, pinned verification, strict version2 export/import, authenticated Bonjour, TLS-PSK userspace tunnel/RSD installation, durable source recovery, refresh per-app results and running-installer team/Keychain protections remain implemented. No guessed ports, peer/TLS bypass, silent re-pair or private-record logging.

## Exact verification and delivery

| Area | Actual result and limit |
|---|---|
| Setup retry and variant boundary | One focused Python invocation2/0 in0.054s; inert launcher substitutions/mocked device/account calls, not actual Mac UI |
| AFC uploader | One actual locked/offline Rust test execution2/0 in0.22s; bounded synthetic reader/partial sink, backpressure, errors/EOF and cancellation. Earlier invalid Cargo feature-selection attempt ran0tests.172 input hashes unchanged |
| Current core/native | Hosted41269237340/source0648612 SUCCESS: transport2/0 in0.27s, recovery2/0 in0.04s, native3/0 in8.869s. Genuine compilerSDK27.1, actual regular-iPhone component runtime27.0(24A434), not Duo/physical |
| Unchanged vendor/helper | Original vendor8/helper2 from40916969403 reused with exact production/features/context proof; no repeated suites |
| Visual evidence | Three untouched original current UIKit fixture PNGs and all8 attachment refs/hashes retained. Viewport/rail and42% task progress are explicitly test-only, not physical display or installation results |
| Replacement package |41270305394/sourcef941208 SUCCESS: both genuine-SDK unsigned iPhone/Duo candidates, universal Mac USB helper, complete corresponding source and minimal kit. Zero new app tests; all matching proofs reused |
| Source/licensing/integrity | Independent strict source/IPA and kit reviews passed;408 dependency packages,0notice gaps, exact graph/relink/source/library/helper/mode closure. Actual hosted Mac helper ad-hoc signature verification passed; helper is not Developer ID notarized |
| Public delivery | Final41271986054/source452e2e9 SUCCESS through every safe phase; same sole draft430349496 and7asset IDs reused. Independent final server sizes/SHA-256 values match actual contract. Unpublished, unsigned, release_ready=false |
| Earlier baseline/startup | Prior19/19 baseline (original8 included) and fresh-account/TLS3 retain older exact source scopes. Do not call them a newly executed complete suite or a live account success |

Evidence: `downloads/completion-verification/public-pairing/resume-20261101/`. Current 7-file pins: `app-installer/cloud-ui/public-delivery-contract.json`. Only current local distribution: `app-installer/build/work/latest-reviewed/`. Its obsolete baseline and duplicate outer ZIPs were removed only after verified replacement. One current compressed native test artifact plus compact logs/receipts and original PNGs remain for reproducibility.

## Delivery defect investigated and fixed

GitHub’s tag endpoint omitted an existing unpublished draft. Initial delivery41271081854 created a second managed review draft. Both old and replacement7asset sets were checked against their exact saved contracts before only obsolete draft428285659 was removed. Corrected discovery scans the bounded complete release list, reuses exactly one matching draft and refuses ambiguous or published matches before writes. Focused publisher2/0 passed; diagnostic2/0 passed.

One full reuse probe41271403913 returned an opaque exception after124seconds. Its exact cause is **unproven**; readback found the sole current draft and7pins unchanged. Fixed safe phase markers and exception-type-only diagnostics avoid raw URLs/tokens/payloads. Live read-only production discovery selected430349496; subsequent full instrumented41271986054 passed all phases and produced the real receipt. No application rebuild/test repeat was needed for delivery repairs. Never infer stable untagged URLs: use actual latest server readback.

## Next actual work

1. Use [the current exact delivery/overlay guide](https://github.com/mcantua/dokkan-offline-public/blob/chatgpt/app-installer-pairing-repair/app-installer/device/PUBLIC-DELIVERY.md). Kit **44149993bytes**, SHA-256 **b3c190cdb04e7ae73a4b67ec6e5b8c7c0b0bdb4e83be1150389eb5ca39a27661**. No need for Mac Rust/Cargo/full-repository/source-archive downloads.
2. Before personal use, state the exact Mac/USB/network step, connection known/unknown and expected bytes. Existing scoped approval persists; no repeated request for routine approved work. Large Xcode or Apple credential/certificate changes retain separate approval.
3. Update in place with the same existing development team/bundle identity. Never uninstall, reset trust, clear data or copy from the frozen backup. Use Pair only for an actual pairing retry after compatible app update. Transfer the private version2 export only locally to that phone; never request it in chat/GitHub/Drive.
4. Verify real sign-in/2FA, authenticated phone session, installation/update/refresh, protected-storage/restart/recovery and both Duo displays/touch/folding. These remain unverified for this revision. The prior optional question about whether Tin installed the October29 kit has no reply yet; do not infer results.
5. Current managed environment is cloud Linux with no Mac/USB capability, VPN or configured personal endpoint. Permission alone does not create computer control. A precise manual action or available authorized computer connection is now needed for physical/account checks. Keep known external Apple/profile/layout limitations explicit in CAPABILITY-MATRIX.md; no100%/final-release claim.

No personal MacBook, phone, home Wi-Fi/hotspot/cellular connection, Apple credentials, save folders, signing keys, private config or frozen-backup content was accessed. Drive updates are explicit per-session, never automatic across chats.
