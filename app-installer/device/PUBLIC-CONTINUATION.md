# App Installer public-source continuation

Updated: October 29, 2026, 2:10 PM US Central. Active repository: `mcantua/dokkan-offline-public`; branch: `chatgpt/app-installer-pairing-repair`, draft PR #7. Tin authorized cloud builds with **“make the builds.”** No base/main merge is authorized. The private backup is frozen and untouched. This chat handles App Installer only.

## Implemented current path

The old public snapshot was Lockdown-only. Its missing modern path was independently implemented here: authenticated SRP/TLV/Ed25519 setup and pinned verify; strict version-2 records; trusted-USB export helper; protected asynchronous native import and authenticated Bonjour selection; authenticated TLS-PSK userspace tunnel/RSD; app installation, management and cleanup. Legacy Lockdown remains separate. No guessed address/port, accept-all TLS, silent re-pair after pin failure, security bypass or account/private-record logging.

Current source also retains failed-first-install retry inputs, shuts down adapter-owned sockets on timeout/abort, continues only typed local per-app refresh errors, preserves uncertain installation journals and running-installer signing/Keychain identity, and reports per-app outcomes. Native UI uses usable content width, a pinned accessible task HUD, fresh refresh-result ownership and coherent Home-view display reports.

The minimal updater verifies an externally pinned ZIP, source/library/helper/notice bindings and genuine Mac helper signatures before managed replacement. It preserves private files, refuses frozen folders case-insensitively, syncs data/directories and publishes its manifest last. Pair-only skips Apple identity discovery and app build/install. A launch timeout remains explicitly unconfirmed.

## Actual public evidence

| Area | Verified result and scope |
|---|---|
| Pairing vendor/helper | Vendor8 + helper2 passed on hosted SDK27.1 in40916969403, source24f2809; unchanged exact production/context proofs reused, never silently retested |
| Current transport/recovery/self guard | Transport2 + recovery2 passed in40926780346, source80f5e35, zero failures0.27s/0.06s. Real cloud-loopback TLS/adapter teardown plus synthetic durable recovery/team/Keychain cases; no phone |
| First sign-in / legacy TLS | Fresh-process account-client constructor1 and standalone strict-TLS2 passed once on cloud Linux at source80f5;0.02s/0.01s,191 exact source hashes unchanged. No HTTP send, Apple account or credentials |
| Native app | Job123646285756 in40930198240, source142293c, compiled production Rust/Objective-C and launched Xcode-managed test host. Selected Files/schema/responsive methods3/0 passed in9.518s. Compiler SDK27.1, actual regular-iPhone component runtime27.0; no Duo27.1/physical/fold claim |
| Native visuals | Three original UIKit fixture PNGs retained (outer, inner, maximum accessibility text), with all8 original attachment refs/hashes. Sizes, rail and task state are explicitly test-only;42% is synthetic progress, not a real install |
| Existing baseline | Earlier real cloud baseline19/19 passed, including original8 requirements, before subsequent recovery/self-guard edits. Its189-input receipt/raw log retain that source scope; no blanket current-suite claim |
| Python boundaries | Migration2, workflow/kit2, publisher negative2 and updater filesystem2 passed in their respective focused tasks. Updater's affected rerun followed two concrete review fixes. Transcribed outputs are explicitly distinguished from raw/pre-run evidence |
| Licensing |408 union packages, zero notice gaps. siphasher notice fixed from its checksum-matched published COPYING/source and official terms. Actual matching final source/relink delivery remains required |

Exact logs, before/after receipts, downloaded artifact hashes and source provenance are in `downloads/completion-verification/public-pairing/`. Historical private-repository results are not proof for this public tree. No aggregate completion percentage is reliably measurable yet; `release_ready=false`.

## Actual package success and delivery review

Package job123646286192 in40930198240 completed both genuine Mac helper release targets/signature steps and the iOS release core, then failed the strict corresponding-source check: `nskeyedarchiver_converter0.1.3` publishes both `README.MD` and `README.md`; macOS Cargo vendor retained only the canonical spelling. No candidate/kit upload or final helper seal completed.

The fix preserves missing case aliases as bounded tar members using exact checksum-matched immutable bytes, includes them in the full manifest and writes the canonical Cargo entry last. Strict publication and Cargo checksum verification is unchanged. Two focused source-delivery methods passed; an independent review found no blocker. Both real upstream README files are2398 bytes with the same SHA; synthetic regression aliases deliberately have different bytes and exercise tamper rejection.

**Package-only run40934237282 succeeded**, source `4c09a35bd30e5b39c229e3f9f401ffdc5cd143a8`. It reused all14 Rust and3 native checks without any repeated app tests. Both genuine SDK27.1 unsigned IPAs, the universal Mac helper, strict corresponding source and minimal native kit were produced. Actual downloaded outer artifacts match GitHub SHA-256/byte pins. Independent source/IPA and kit checks passed. Hosted Mac signature/draft delivery40936908790 then succeeded, with all seven final server hashes/sizes independently read back. The actual seven-file contract is `app-installer/cloud-ui/public-delivery-contract.json`; source154,020,324bytes, kit44,120,569bytes (SHA-256 `4b8edb314c20b44789edb16c0b37b6c86e5c42ee677853883425ff2c8afc81a7`). The draft is unpublished; no signed release or phone success is claimed. Exact download pins and the minimal local overlay are in [PUBLIC-DELIVERY.md](PUBLIC-DELIVERY.md).

## Environment findings

Early native attempts stopped on optional headless OS metadata before app tests. Those probes are removed from component verification; Xcode manages startup. One superseded run reached simulator Rust compilation before cancellation; cancellation was not a test failure. The successful native run above supersedes those preflight failures for its specific component scope.

Read-only official `macos-latest` inventory40925957648 found Xcode26.x, SDKs through26.5 and Simulator.app, with no27.1 runtime/Duo type. It cannot replace the genuine27.1 target requirement. No SDK/toolchain was downloaded to Tin's Mac.

## Next actions without stopping at a milestone

1. Cloud artifact review/delivery is complete for this revision. Sole current distribution is `app-installer/build/work/latest-reviewed/`; outer ZIP duplicates removed. Preserve necessary source/build inputs.
2. Actual seven-file contract, successful source/delivery runs and final server readback are saved. No publish/base merge is authorized. Use the source-bound download/update guide; do not rebuild/retest unchanged inputs.
3. Once a real compatible kit is available, explain the exact Mac/network/USB step, connection known/unknown and verified download bytes before personal use. Earlier routine setup approval persists; no repeated approval request. Larger Xcode or Apple-credential/certificate changes retain separate approval.
4. Guide the minimal same-identity update and private trusted-USB export/import. Never request pairing records, keys, credentials, real device IDs, private addresses or raw device output in chat. No uninstall/reset/data-clearing shortcut.
5. Continue actual Apple sign-in/signing/install/update/refresh/recovery and both physical Duo displays/touch/fold acceptance. These remain unverified for this revision and require authorized device/account access; neither cloud tests nor a build establishes them.

All current actions are cloud-only. No operation is running on Tin's Mac, phone, home Wi-Fi, hotspot or cellular connection. No save folders, signing keys, private local config or frozen-backup contents are accessed. Drive synchronization is explicit per session, never automatic across chats.
