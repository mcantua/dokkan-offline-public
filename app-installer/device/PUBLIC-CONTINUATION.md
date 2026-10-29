# App Installer public-source continuation

Updated: October 29, 2026, 12:40 PM US Central. Active repository: `mcantua/dokkan-offline-public`; work branch: `chatgpt/app-installer-pairing-repair`, draft PR #7. Tin explicitly authorized cloud builds with **“make the builds.”** No base/main merge is authorized. The private backup is frozen and has not been accessed. This chat handles App Installer only.

## Current implementation

The initial public snapshot was older and Lockdown-only. The missing modern path was independently implemented here, without copying the frozen backup: strict pinned version-2 remote records; authenticated SRP/TLV/Ed25519 setup/verify; trusted-USB export helper; native protected asynchronous import and authenticated Bonjour service selection; authenticated TLS-PSK userspace tunnel/RSD; app installation, management and cleanup through that transport. Legacy Lockdown remains a separate supported route. No guessed device address or port, accept-all TLS verifier, automatic re-pair after pin failure, account/password logging or security bypass is used.

The universal Mac helper, corresponding-source/notice closure and minimal setup kit are source/hash/signature bound. Pair-only does not discover an Apple identity or build/install the app. A launch timeout is explicitly unconfirmed and does not require reinstalling. New public delivery/update tooling rejects old project roots and unverified or modified inputs, preserves private files and never follows historical private release IDs. The actual helper/kit distribution has not yet been produced.

The current source batch additionally repairs cancellation ownership of the userspace tunnel, failed-first-install retry retention, per-app refresh recovery, available-width layout selection, a pinned accessible progress/Cancel HUD, and coherent Home-view display diagnostics. Those changed paths await their targeted verification; source implementation is not a successful phone result.

## Verified evidence for this public tree

- Hosted run [40916969403](https://github.com/mcantua/dokkan-offline-public/actions/runs/40916969403), source `24f2809c3001c474d0ea885afc1aef00aa388fd0`: genuine arm64 Xcode27.1/SDK27.1; vendor8, helper2 and then-current transport2 passed, zero failures. New tunnel teardown changes require the transport2 group again. Unchanged vendor/helper proofs are eligible for exact production-input/context reuse with the reviewed harness changes explicitly recorded.
- The original eight offline requirements are included in a real cloud Linux baseline: **19/19 passed**, zero failures, two new transport methods filtered. The first compile attempt ran zero tests because sparse checkout had omitted the public Apple trust files; materializing those tracked public assets fixed that environment issue. Final raw log and 189-input before/after proof are saved under `downloads/completion-verification/public-pairing/`. Later recovery edits require their own targeted proof; the old baseline is not asserted to cover new behavior.
- Python migration guards2, workflow/kit regressions2 and public-delivery negative groups2 passed once per respective task. Updater verification is pending. No repetitive full-suite claim.
- Notices now cover **408 union packages with zero notice gaps**, including the new helper/platform closures. The discovered siphasher notice gap was resolved from its exact published COPYING/source and official terms. Final regenerated source/relink delivery bindings remain required.
- Hosted run [40919528305](https://github.com/mcantua/dokkan-offline-public/actions/runs/40919528305), source `8446a7ac1e81956952c2eea27c22ec26cbab5f45`, reused unchanged Rust proofs. Native verification did not run: an extra headless shell-appearance query timed out even on the supported regular iOS27.0 runtime. The earlier Duo27.1 runtime had failed OS data migration before any app. Neither run compiled/launched the native app or produced an App Installer screenshot.

Exact downloaded log/artifact hashes and source provenance accompany each run under `downloads/completion-verification/public-pairing/`. Historical private-repo builds/tests are not proof for this public revision.

## Active next steps

1. Freeze the combined source fixes. Run fresh transport2 and recovery2 methods and native3 selected methods, reusing unchanged vendor8/helper2. Native checks use Xcode-managed test-host launch instead of repeating the failed shell heuristic. Regular27.0 component/labelled geometry fixtures are explicitly not Duo runtime or physical folding proof.
2. Fix actual failures without repeating unaffected groups. If Xcode-managed launch also fails at the OS layer, investigate the separately prepared official macOS-hosted inventory route rather than repeat the same failed preflight.
3. Once required matching proofs pass, compile genuine-SDK unsigned iPhone/Duo review candidates, universal ad-hoc Mac helper, complete corresponding source/relink archive and minimal native kit. Verify exact graphs, notices, signatures, archive closure and seven real asset hashes before staging the public draft. No publication or release-ready claim is implied.
4. Only after actual kit bytes/source/SHA are known, offer the exact small transfer/update and pairing-only export/import step. Explain Mac/network purpose, known/unknown Wi-Fi/hotspot and expected bytes before any personal operation. Never request private pairing records, credentials, keys or raw device output in chat.
5. Real Apple sign-in, signing, install/update/refresh, interruption recovery and both physical Duo display/touch/fold acceptance remain unverified for this revision. `release_ready=false`. No reliable aggregate completion percentage can be calculated yet; passing builds/tests alone do not establish completion.

## Scope and resources

All current actions use cloud infrastructure. No operation is being run on Tin’s Mac, phone, home Wi-Fi, hotspot or cellular connection. Earlier scoped setup approval persists; larger Xcode installations or credential/certificate changes still need separate approval. Essential targeted checks only, normally1–2 runs per task. No save folders, signing keys, private local configuration or personal identifiers are accessed. No extra backup copies are created.

`STATUS.md`, the Claude outbox and the existing private shared Drive Documentation log record progress; synchronization is explicit per session, never automatic across chats.
