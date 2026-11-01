# App Installer — complete transfer to Claude

Prepared November 1, 2026, at Tin's explicit request: “give me a complete hands off. this pojec is being moved to claude”. **Claude is the next owner. ChatGPT development is paused; this transfer performs documentation and preservation only.** No new application build, development test, phone operation, merge or publication was performed for this handoff.

## 1. Start here; do not restart completed work

Read README.md first, then this document, context/TIN-RULES.md, STATUS.md, app-installer/device/PUBLIC-DELIVERY.md and app-installer/CAPABILITY-MATRIX.md. The detailed chronological record is device/PUBLIC-CONTINUATION.md; task acceptance is TASKLIST.md. The latest owner-transfer message is messages/to-claude/2026-11-01_1212_from-chatgpt_app-installer-claude-takeover.md.

The app is **not 100% complete or release-ready**. The current cloud implementation, focused checks and corresponding-source/kit delivery are verified. Real account/phone workflows and physical Duo acceptance are not. Do not repeat cloud checks or rebuild merely to establish that you have taken over. Investigate new defects or the next necessary acceptance step.

| Location or identity | Exact state |
|---|---|
| Active repository | https://github.com/mcantua/dokkan-offline-public |
| Working branch | chatgpt/app-installer-pairing-repair |
| Draft PR | https://github.com/mcantua/dokkan-offline-public/pull/7 — open, draft |
| Protected base | chatgpt/ios-eclipse-database-reuse — no merge without Tin's OK |
| Last clean source/docs HEAD before this handoff | 5756b237a5e6cbeacd5986b7fee6bcee06352c1b |
| Source used for current binary distribution | ed931b9cff9c047e5de6a21d8d25db3a3154f471 |
| Current package run | https://github.com/mcantua/dokkan-offline-public/actions/runs/41322933617 — SUCCESS |
| Actual hosted Mac signature/delivery run | https://github.com/mcantua/dokkan-offline-public/actions/runs/41324387393 — SUCCESS |
| Existing review release | 430349496; tag app-installer-public-review; draft=true, published_at=null |
| Source tree fingerprint | f62721b5b9bbdcee73b127ce8b6189d4c2e041f30c3876d7b22753b1a3e8199c |
| Locked distribution graph | 073cbb40839821536762df4491e1a5807a290c9fd9f8fce0776f579a40777fd7 |
| Authoritative seven-file contract | app-installer/cloud-ui/public-delivery-contract.json |

The handoff commit follows the pre-transfer HEAD above and changes documentation only. Use the latest working branch for the handoff, but retain the immutable **ed931b9** build/source/receipt relationship. Do not relabel existing binaries as built from the later documentation commit.

This cloud workspace is /workspace/AI-Workspace/dokkan-offline-public. A new Claude environment may not inherit it, tool credentials, GitHub access, ignored working files or computer control. Recover public source from the branch and binary assets from the existing draft. Do not make a new repository or publish the draft as an access workaround.

## 2. Rules and authorization that remain in force

- App Installer only, for iPhone and iPhone Duo. Offline Dokkan/Unit Creator belong to other conversations/owners. Preserve their concurrent work; do not modify their save folders, keys or builds.
- Work cloud-first. Keep source, messages, downloads and build work organized inside the active AI-Workspace public project. At most one emergency backup; the current distribution has **no retained backup**. Keep only the latest verified working distribution and necessary source/configuration/tools/evidence.
- Use useful independent agents when authorized; never duplicate work or tests merely to fill slots. Every delegated filesystem command must explicitly select and verify the active public root. Never trust an inherited working directory.
- The old mcantua/claude-chatg repository and its old local checkout are frozen. **Do not open, read, query Git history, audit, modify, merge, copy configuration from or delete them.** Older README paragraphs, old pasted commands and some historical workflow notes mention that destination; those instructions are superseded.
- No personal names/emails, device identifiers, addresses, passwords, Apple codes, profiles, signing keys or pairing exports in public files, chat, source commits or shared Drive. Use approved local private configuration/Keychain only. Never request the contents of a pairing record.
- Keep tests minimal: normally 1–2 focused invocations for an affected task; expand only for an actual defect/regression or critical security/compatibility requirement. Group changes before builds. Retain passing unchanged source-bound proof. Do not repeatedly rerun the 20/22 historical checks or native suites without a relevant change.
- Cloud builds were authorized by “make the builds”. This is not an instruction to rebuild after every minor change. No base/main merge or release publication without Tin's OK.
- Continue actual implementation/acceptance rather than stopping at a spec, build or handoff milestone. Do not claim 100% while required features, critical bugs, live workflows or physical acceptance remain unverified. Do not invent an overall percentage.
- Speak simply, use 12-hour AM/PM times, and provide concise pending-only progress tables with percentages about every10minutes while actively working. Label actual component/test screenshots honestly; never present them as physical phone results. Never imply unattended background work when nothing is executing.
- At session end update STATUS.md, your own Claude/ChatGPT outbox and the existing shared Drive records with explicit readback. Do not edit the other AI's messages or claim automatic cross-chat synchronization.

**Existing personal-resource approval persists.** Tin explicitly approved use of his MacBook, USB-connected iPhone Duo, internet connection, the setup kit/pairing components and necessary trusted dependencies for App Installer setup and verification. Later instructions superseded the original “stop before the first install” restriction. Do not request routine approval again for this already approved scope.

Before each actual personal-resource step, explain the exact action, resources, selected connection if known, expected transfer bytes or a genuine unknown. A substantially larger Xcode installation or Apple account/credential/certificate changes retain separate approval. Authentication prompts, Touch ID/Face ID, passcodes and 2FA stay in the appropriate local UI; never ask for them in chat. The last user availability answer was **“Not now; continue cloud work.”** Do not assume the Mac is currently available or repeatedly ask while it remains unavailable.

This ChatGPT environment exposes connected cloud Linux/GitHub hosted Mac jobs, not personal Mac/USB control. Its current runtime reports no computer capability, no configured VPN or device endpoint. Permission is not a connection. Claude must inspect its own supported tools before claiming screen viewing or Mac control.

## 3. Current deliverable and exact pins

The existing unpublished draft is the only current distribution. Its seven server asset names, sizes and SHA-256 values matched the reviewed contract after delivery. The two IPAs are **unsigned candidates**, not final installable releases. Native signing happens later through the approved Mac/Xcode workflow.

**The minimal setup kit is the `duo` variant.** It contains a cloud-built Rust static library and universal Mac pairing helper. The broader distribution has both iPhone and Duo IPA candidates, but do not assume this Duo kit can build the ordinary-iPhone variant. Its physical-variant gate deliberately refuses an incompatible selection before account discovery/build/install. Pair-only is independent of the app variant, after a compatible importer is installed.

Observed current kit URL (read back after the final draft mutation; not a guessed URL):
https://github.com/mcantua/dokkan-offline-public/releases/download/untagged-adbb5d3025308a87b412/AppInstaller-native-bootstrap-kit.zip

Observed draft page:
https://github.com/mcantua/dokkan-offline-public/releases/tag/untagged-adbb5d3025308a87b412

Draft access may require the repository owner's authenticated GitHub account even though the repository is public. Configure Claude's legitimate repository access if needed; do not publish for convenience. GitHub may change unpublished untagged URLs when release metadata is patched. Prefer the final observed URL and verify the contract before use; do not patch the draft after issuing final download pins.

| File | Bytes | SHA-256 |
|---|---:|---|
| AppInstaller-corresponding-source.tar.xz | 154038676 | `79b559810f28fc05383659b143313ef42253527e4b6027085081e13ff06cc8a4` |
| AppInstaller-candidate-manifest.json | 2207 | `69145e698ad3bb3a118325edf89facee99e4663c1f5a698ee82973dcc56b7e38` |
| AppInstaller-duo-candidate.ipa | 8480400 | `c489d6657a8489a3f390312d84fb30fd6b859fc5ccb9feb501ae98286f4169c9` |
| AppInstaller-iphone-candidate.ipa | 8480396 | `d7c09818ff6bd17f8f62e0199eba794c491ef8498e5f16ea43dbb142a62155d8` |
| cloud-device-library-manifest.json | 1334 | `bb43d500694ef3a890c348f8823f6c1489103b0907d97b07554733de50f35d19` |
| AppInstaller-native-bootstrap-kit.zip | 44231197 | `895f0017ae526a63cb1144499a61c190b2142d3800e2f78baa97ad6b8bc96c3b` |
| AppInstaller-native-bootstrap-kit.json | 893 | `ca79236970577d3d744543c13929c2b39cb8e867f728aa23fba9fb173b2f1c35` |

Kit download is **44,231,197 bytes** (44.2 MB decimal). The ZIP has39members: its manifest and38managed payloads, totalling130,356,771uncompressed bytes before Xcode build/private outputs. Additional local Xcode storage and Apple provisioning traffic are not a known fixed amount. The contained device library is112,274,928bytes, SHA25684af85cf1131a2bc93741d4803d8b597c26f6920a1b6f9f39f34c7322e3e8d2e.

The corresponding-source archive is154,038,676bytes. It is available for source/relink obligations, **not required on Tin's Mac for setup**. Do not clone the full repo, install Rust/Cargo or fetch all crate/runtime source on the Mac just to install the app. The kit already contains the compiled pieces.

The helper's universal arm64/x86_64 ad-hoc signature seal was checked by actual hosted macOS codesign. It is **not Developer ID notarized**. A normal unidentified-developer warning is not evidence of malware, but a damaged/malware warning must not be bypassed. Follow Apple's supported per-app review process when appropriate; never globally disable Gatekeeper, strip quarantine recursively, re-sign a failing artifact to force acceptance or weaken pin/signature checks.

Local cloud distribution, if this workspace is retained: app-installer/build/work/latest-reviewed/ contains exactly the seven current files. It is ignored, so it may not exist in a fresh clone. Old b45distribution, redundant outer ZIPs, the7MB temporary source-manifest capture and obsolete diagnostic ZIPs were removed only after verified replacements. Essential source/tools, compact records and original reached screenshots remain. Current compressed native diagnostics are retained with run41321551443; no full extracted XCResult tree is needed.

## 4. What is implemented

Read the code and source-specific records before changing behavior. These are implementation/cloud-check claims, not successful physical acceptance.

- Native UIKit account/setup/pairing/install/refresh interface with system colors, typography, Dynamic Type, scrollable forms, safe areas, keyboard handling and display diagnostics. The task HUD uses a deliberate two-line ellipsis preview and full native scrolling Task details/Done. Progress and Cancel remain pinned; compact nonnumeric work shows a visible spinner. No task cancellation, credential action or state reset occurs merely by opening/closing details.
- Account client startup initializes the Rust TLS crypto provider defensively. This fixes a genuine fresh-process constructor defect that could panic after the secure-account prompt. The actual old-phone crash cause/resolution was not confirmed from a physical backtrace/retest.
- Device-only protected account/Keychain handling, authentication generations, cancellation and five-minute continuous-monotonic authorization leases. A no-UI ai_secure_session_authorized() bridge enforces expiry from core work even if the main queue is delayed; an active-install monitor checks independently about100ms. A real successful biometric unlock/five-minute timer remains unverified.
- Strict authenticated version-2 peer-pinned trusted-USB export/import. Old unpinned/legacy plist records do not become trusted by being saved. Discovery metadata is bounded; missing/ambiguous metadata cannot replace a working saved record. PSK/CDTunnel/RSD transport, peer checks, bounded AFC upload/backpressure and owned staging cleanup are implemented. No guessed ports or security bypass.
- Pair-only and full setup are distinct launcher modes. The helper emits fixed whitelisted stage/reason tokens live, with bounded output and owned-child timeout/cancellation. The outer workflow prints PAIRING_STAGE/PAIRING_REASON/PAIRING_EXIT rather than raw sensitive output. Old RP_BOOTSTRAP diagnostic snippets belong to earlier helper versions; do not inject them into the current workflow.
- IPA structure validation; selected-team main/extension identities and exact profile-entitlement reconciliation; independent signed-output verification. Preserve an owned original App ID when possible. Installer self-updates require the same team, bundle and exact Keychain identity. Do not strip required features or privilege checks to make an IPA sign.
- Durable install intents/recovery and latest-source retention across interrupted/failed first installs, refresh and self-update. Source promotion syncs its containing directory before installed metadata/journal cleanup. Sync failure keeps recovery input and old metadata. A launch-query timeout alone does not justify reinstalling.
- Resource SHA1/SHA256 hashing runs together in64KiB chunks. Signing and independent verification check cancellation, authorization generation and the operation deadline at resource/chunk, bundle, executable-page and final-success boundaries. Existing signer API entry points remain compatible; no detached write worker is used.
- Executable file rewriting has128MiB input/output and4MiB signature limits, fallible bounded reads and one cancellable file-signing lease. FAT/page work is sequential to avoid nested Rayon lease deadlocks. Too-large/changed inputs and memory errors fail clearly rather than truncating or allocating a multi-GB file.
- Per-app refresh results, expiry/reminder logic and foreground recovery. iOS background scheduling and biometric requirements cannot guarantee unattended daily refresh.

## 5. Source map

| Area | Files |
|---|---|
| Native UI and task details | app-installer/ios/main.m |
| UI/core async operations | app-installer/ios/InstallerService.m |
| Secure unlock/lease bridge | app-installer/ios/SecureStore.m; core/secure_storage.h |
| Strict import/discovery | app-installer/ios/PairingStore.m |
| Background refresh policy | app-installer/ios/RefreshCoordinator.m |
| Display/safe-region report | app-installer/ios/DisplayDiagnostics.m; ios/display-evidence.md |
| Core C interface | app-installer/core/src/lib.rs; core/app_installer.h |
| Install, refresh and recovery | core/src/engine.rs; core/src/transport.rs; core/src/install_journal.rs; core/src/cleanup.rs |
| IPA/identity/entitlements/verifier | core/src/archive.rs; core/src/identity.rs; core/src/capabilities.rs; core/src/entitlement_policy.rs; core/src/signed_verification.rs |
| Patched device protocol/helper | downloads/idevice/idevice-0.1.68/ |
| Apple/provisioning/signing integration | downloads/isideload/isideload-0.5.0/ |
| Patched bounded/cancellable signer | downloads/apple-codesign-quick/apple-codesign-quick-0.1.0/; selected by core/Cargo.toml patch |
| Local verified overlay/setup | device/update-public-kit.py; device/Run-App-Installer-Setup.command; device/setup-wizard.py; device/device-workflow.py |
| Source/license/IPA recipes | build/source-bundle.py; build/source-fingerprint.py; build/licensing.py; build/verify-candidate.py; build/check-artifact.py |
| CI/proof/public delivery | cloud-ui/run.sh; cloud-ui/pairing-public-proof.py; cloud-ui/public-delivery.py; cloud-ui/public-delivery-contract.json |

Paths beginning downloads/ are relative to the repository root. Short core/, ios/, device/, build/ and cloud-ui/ paths are relative to app-installer/. Actual file names are authoritative; do not reconstruct paths from old pasted commands.

## 6. Verified evidence and its limits

Evidence root: downloads/completion-verification/public-pairing/resume-20261101/.

| Evidence | Actual result and source scope |
|---|---|
| Backend41310143960, source8e9b43ce | Fresh transport2/0 in0.37s, recovery2/0 in0.04s, native4/0 in5.952s. Original vendor8/helper2 reused with source/feature/context proof. |
| Signer regressions | Three justified focused invocations, each2/0, after distinct resource, executable-cancellation and oversized-allocation defects. Final2/0 in0.25s with27input hashes unchanged. Exact recipe/input/log records in signer/, signer-executable/, signer-memory/. |
| Synthetic sign/profile/verify | Earlier2/0 in9.34s, before final executable-budget/native-lease additions. See core-signing/. Never relabel it as a fresh final-bridge test. |
| Official SDK API41319227481 | Genuine installed Xcode27.1/build27A9275 and SDK27.1; actual UIKit declaration excerpts/hash pins and syntax-only clang probe passed with no diagnostics. This was not a runtime or application test. |
| Final UI41321551443, sourceda1a36a | Exactly test02ResponsiveMainUsesLabelledTestOnlyFixture passed1/0 in12.518s. All232before/after source hashes match. Regular iPhone18ProMax component runtime27.0 with genuine compilerSDK27.1.14unchanged Rust checks reused. |
| Package41322933617, sourceed931b9 |15matching passes reused (vendor8/helper2/transport2/recovery2/native1), **0fresh test executions**. Genuine deviceSDK27.1, Apple clang21 and Rust1.99.1; both unsigned candidates, source/relink and Duo kit built successfully. |
| Independent package reviews | Stock complete corresponding-source/IPA review passed10.06s. Independent portable kit review passed0.967s:38payloads,24required source rows, graphs, modes, library/helper and notices. The original source verifier return was observed unmodified; no success was injected and the large source archive was not rescanned for the second portable review. |
| Actual Mac delivery41324387393 | Real hosted codesign --verify --strict --all-architectures gate and full delivery checks succeeded. Final independent server GET confirmed sole existing unpublished draft430349496 and all7actual asset sizes/digests matching the contract. No personal Mac/phone action. |
| Original eight offline requirements | Older baseline/TASKLIST records retain their original source scope. The entire original suite was not freshly rerun for this revision; do not claim it was. Select additional checks only for affected risks/final acceptance. |

Raw source before/after maps, actual logs, receipts and original reached PNGs live in their run directories. Final native input proof is run41321551443/pairing-proof/native.json. Package pins/provenance/reviews are in run41322933617/. Actual delivery receipt/server readback are in run41324387393-delivery/. Current artifact cleanup records explain removed duplicate ZIPs; original provenance is historical, not a promise that every temporary file still exists.

The native PNGs are labelled **TEST-ONLY geometry/progress/maximum-accessibility fixtures**. They contain no real account/install data and are not physical Duo screenshots. They prove actual UIKit rendering/assertions within the stated component environment, not folding, real Touch ID/Face ID, a successful Apple sign-in or installation.

Do not hide the failed attempts:41316177182 ran one method with4failures in40.539s (modal font/scroll and hidden spinner);41319375823 failed an unset trait-override getter precondition in5.102s before later checks;41320431373 reached all checks but failed4unjustified absolute28pt icon caps in8.713s. The actual32.667pt icon was intact inside its44pt target. The final test removed only that implementation-specific cap, keeping actual image containment, hit targets, full-text scrolling, progress, Done/Cancel and spinner assertions. Those failed runs remain failed. The final12.518s pass is separate.

Known bad Duo simulator runtime27.1/build24A94425 caused pre-app OS startup failures. The reviewed current responsive/component path truthfully used regular runtime27.0 with genuine compilerSDK27.1. Do not repeatedly retry the same bad runtime, invent hinge commands, fake SDK fields or call these fixtures physical Duo acceptance. Other historical runs had different simulator scopes; retain each run's own evidence.

## 7. Licenses and required source delivery

The former six upstream notice cases are not unresolved in the current distribution: the verified408-package union graph reports **zero notice gaps**. Exact current source, notices, graph and relink obligations were checked together. Older307-package/six-gap reports are historical; do not treat them as the current report or invent a new audit from memory.

Keep the modified LGPL-selected signing library's original grant/lineage, full legal texts, matching modified source, runtime source and relink/installation instructions with redistributed binaries. See app-installer/licensing-signing.md and downloads/license-notices/. The current signer is a modified path dependency; do not replace its source with the pristine registry crate and accidentally lose cancellation/memory repairs. Do not change versions/features or notice choices casually.

No Apple SDK/compiler binaries, personal signing identity, private game keys or account material belong in the corresponding-source archive. The full source companion is separately downloadable/relinkable without the original private signing key. Source recipients may modify/relink under applicable terms; source/provenance integrity checks are not a ban on library replacement.

## 8. Genuine remaining limits — not just “needs testing”

- **All live acceptance below is0% for the current revision.** Historical user reports of an older Mac sign/export/install/manual launch do not establish current in-app auth/pairing/update/refresh success.
- Resource streaming does not imply unlimited executables: the native file signer caps input/output executables at128MiB and signatures at4MiB. Multi-GB executable rewriting needs a future file-backed backend. This is not an IPA archive-size limit; large resources are a separate path.
- Cancellation is cooperative across OS/crypto operations and the final check/write race; it is not hard realtime or atomic rollback. An install accepted by iOS may finish after cancellation. Retain durable intent until later confirmation instead of claiming it was undone.
- Daily unattended self-refresh cannot be guaranteed by iOS background scheduling or biometric policy. Foreground unlock may be necessary; expired provisioning can require computer recovery. Do not bypass user presence or promise computer-free recovery.
- Development profiles do not implement a general production distribution/APNs-production mode. Do not silently turn a production push request into development.
- Exact existing iCloud/merchant bindings and some enablement operations require a legitimate Apple developer web-session/CSRF adapter that is not implemented in the current GSA/Xcode session. Existing correctly granted selected-team profiles can be preserved. Do not invent endpoints, translate unrelated sessions, send credentials to a relay or pretend generic automatic enablement exists.
- Existing App IDs missing increased-memory grants require a merge-aware adapter or legitimate portal configuration; do not blindly replace capability relationships and disable other grants.
- Arbitrary new automatic service-specific adapters for Sign in with Apple/App Attest/managed entitlements are not all implemented. Exact actual-profile preservation is supported, subject to Apple/service ownership.
- Nested Watch/Clip or unusual signed layouts are rejected pending recursive provisioning/architecture support. Direct audited iPhone extensions are current scope.
- Foreign App Groups/shared Keychain, domain AASA, merchant/pass, Game Center and similar backend identities cannot be acquired by re-signing. Apple/team ownership and service/backend support remain necessary.
- FairPlay-encrypted executables, store receipts and platform-only authority cannot be recreated by re-signing. No decryption, receipt bypass or entitlement/security bypass is implemented or permitted.
- Known Installer/Unit Creator source does not request a currently missing special-capability adapter, but the **actual required IPA** still needs legitimate metadata/profile/device acceptance. Do not claim universal IPA support.

Live acceptance must also cover actual SRP/2FA (including SMS/resend and team selection), anisette/session restoration, actual free/paid quotas including self/extensions/other installers, safe existing-certificate reuse without automatic revocation, and profile-backed entitlement output. Protected-storage checks include a real five-minute lease, sign-out, enrollment/lock changes, migration errors and one encrypted-backup/recovery path without weakening protection. Refresh checks include self-replacement interruption, exact latest source retention, restart recovery, background-task expiration/cancellation and notification permission/two-day reminder behavior. Cloud fixtures do not close those checks. Physical UI checks include actual keyboard and VoiceOver/touch behavior as well as both panels and folding.

CAPABILITY-MATRIX.md is the detailed per-capability source of truth. If a required IPA hits an implementation limit, investigate a legitimate solution and test only the changed path; do not simply delete the feature or mark the whole project done.

## 9. Prior user-visible problems to avoid repeating

1. An older setup reported native signing/export/install success but automatic launch could not be confirmed. Launch/query timeout alone is not proof of a failed install and is not a reason to uninstall/reinstall.
2. The user reported a crash after the secure-account Touch ID prompt. A real fresh-process TLS-provider initialization defect was fixed and targeted constructor/TLS checks passed; the latest physical retest is still required.
3. A legacy private plist could be saved/imported while the actual device session failed. Saving a file is not authenticated pairing. The current strict RPv2 helper/importer must be used together.
4. Mac Gatekeeper stopped an earlier helper. Review the precise ordinary unverified-developer warning and the actual artifact pins; never disable macOS security or proceed through a malware/damage warning.
5. Older Pair-only attempts hung/failed at authentication with no new export. Current code has safe live whitelisted progress and bounded owned-child handling. Do not repeat old diagnostic monkeypatches, print raw stderr, scan ports or upload a pairing record.
6. An older pasted command used an obsolete nested/frozen path and could not find setup-wizard.py. Do not inspect or repair that folder. Use the new public kit/path only.
7. The user reported incomplete outer/inner display use and requested an Apple-style native HUD. Cloud responsive/maximum-text fixes are verified; physical resolution, rail behavior, touch and fold transitions still need the phone.

## 10. Exact next workflow when Tin is ready

No personal step is requested while his Mac remains unavailable. When he confirms readiness and a supported authorized tool/interactive route is available:

1. Give the advance resource notice: download only the reviewed44,231,197-byte Duo kit, plus normal HTTPS overhead, over the intended connection. If you cannot determine Wi-Fi versus hotspot/cellular, state that unknown and let Tin choose the connection. No whole-repo/Rust/source download is required.
2. Use device/PUBLIC-DELIVERY.md's exact pinned chooser/overlay block. It verifies the whole ZIP, updater29186bytes/SHA48b878b87b90e6d3a4977c73418e703bbc3715293c1cbfbd8f0e3782c2a0e913 and managed payloads/helper seal before replacement. The destination is the **new** AI-Workspace/dokkan-offline-public folder, never the frozen backup. Preserve unlisted private files already in the new folder. Per-file updates are atomic, not a whole-folder transaction; after interruption do not launch a mixed kit. Complete the same pinned overlay safely.
3. Check existing Xcode/SDK and physical phone locally. Do not confuse a simulator labelled iPhone Duo with the physical device or use a CoreDevice alias as a hardware provisioning identifier. Keep the selected phone unlocked/trusted; handle Apple Trust/Developer Mode prompts locally. Existing Xcode was reported historically, not inventoried on the personal Mac this cloud pass. A large new Xcode install needs its reserved approval.
4. Preserve the existing installed development team, bundle identity, Keychain groups and app data. Determine whether the installed source/importer is compatible. A strict RPv2 update may require **Full setup** once, using existing signing identity and reviewed cloud library. Announce Mac/Xcode/USB and unknown Apple provisioning traffic first. Credential/certificate changes outside existing scope need separate approval. Do not uninstall/reset data/trust or create a second installer identity.
5. For a compatible app and pairing retry, choose **Pair only**. It does not discover an Apple team, rebuild/install/launch the app or download dependencies. Keep the physical phone unlocked and trusted by USB. Preserve a working compatible record until a replacement actually authenticates.
6. Transfer the new private version-2 peer-pinned export directly to that phone through the approved local method, then import in the compatible App Installer. Keep LocalDevVPN configured. Any numeric local/VPN address stays local; keep the host setting separate from automatically discovered service-port metadata.
7. Choose **Unlock and check connection**. Require real saved-peer authentication and device lookup; a saved file/advertisement is not success. Collect only the fixed safe PAIRING_STAGE/PAIRING_REASON/PAIRING_EXIT outputs or privacy-safe display report when necessary. Never request credentials/private records/raw logs.
8. Work through real signing/install, launch, same-identity update, refresh/renewal, source retention and interruption/restart/expiry recovery on the required legitimate test IPA. Protect existing apps/data; do not create a failure by destructive deletion or a system-wide reset. Record the actual outcomes separately from cloud proof.
9. Check outer and inner displays, native resolution/aspect/fullscreen root bounds, safe regions/rail, scaling, real touch/scroll/keyboard, repeated fold/unfold and retained navigation/task state. Use actual phone results/screenshots without private identifiers. Simulated view sizes cannot close this requirement.
10. Complete one focused final essential acceptance and retain a properly signed installable release plus matching source/docs only after actual success. No100% claim while any required feature or verification remains missing.

Supported launcher examples, **not executed by this handoff**, only for the verified new public folder within existing authorization:

```bash
"$HOME/AI-Workspace/dokkan-offline-public/app-installer/device/Run-App-Installer-Setup.command" --plan
```

```bash
"$HOME/AI-Workspace/dokkan-offline-public/app-installer/device/Run-App-Installer-Setup.command" --execute --pairing-only
```

A no-argument launch shows the plan and the Cancel/Pair only/Full setup chooser. --execute without --pairing-only is full setup and can build/sign/install; it must not become a routine pairing retry. Use the guide rather than an old pasted private-path command.

## 11. Development/CI instructions only if source changes require them

Preserve current passing evidence. The relevant registered workflows are:

| Workflow | Purpose |
|---|---|
| .github/workflows/app-installer-cloud-ui.yml, ID400819284 | Genuine-SDK native checks and/or unsigned candidates/source/kit; xcode-27 runner |
| .github/workflows/app-installer-promote-draft.yml, ID400819288 | Current **public-delivery.py** reviewed-contract and actual hostedMac signature gate; replaces only this existing unpublished draft's seven assets |
| .github/workflows/cloud-sdk-discovery.yml, ID400819292 | Read-only installed SDK inventory; optional trait_api_only=true uses the small genuine header/clang syntax probe |

Some legacy script/workflow titles still say “private draft”, and cloud-ui/README.md retains historical behavior. **Do not run upload-draft-assets.py, promote-draft-candidate.py, legacy private promotion/refresh contracts or old private-repository workflows.** Follow the actual current public-delivery.py guard, current contract and this handoff. A new standalone workflow filename was once unregistered/404; the existing registered SDK workflow was used successfully instead. Do not merge into a protected branch just to register a helper workflow.

For a future UI-only source change, this example selects the single responsive method and reuses only unchanged backend groups. It is documentation, not a request to run now:

```bash
gh workflow run app-installer-cloud-ui.yml \
  --repo mcantua/dokkan-offline-public \
  --ref chatgpt/app-installer-pairing-repair \
  -f package_candidates=false -f native_checks=true \
  -f native_test_scope=responsive -f rust_test_scope=pairing-public \
  -f reuse_pairing_vendor_run=40916969403 \
  -f reuse_pairing_helper_run=40916969403 \
  -f reuse_pairing_transport_run=41310143960 \
  -f reuse_pairing_recovery_run=41310143960
```

If a group’s production inputs/features/compiler context changed, omit its stale reuse input and run only its necessary focused check. Do not weaken recipe/input comparisons to force a green result. Existing reviewed COMMON-only harness migration is not permission to reuse changed production source; native proof never gets that exception.

After necessary checks pass, make **one** matching package: package_candidates=true, native_checks=false, native_test_scope=responsive for the matching current native proof, and reuse_pairing_native_run set to the actual matching successful native run. Update all affected group run IDs from actual evidence; do not blindly reuse41321551443 after changing its inputs. Current unchanged package41322933617 already did this, so no rebuild is needed just to take over.

For a newly downloaded/new candidate requiring integrity review, the stock source/IPA verifier is build/verify-candidate.py. The current successful full review must not be repeated without cause. Do not monkeypatch the Mac signature gate or pretend Linux can execute codesign. Root's temporary observation/portable-review scripts were removed after their compact results were preserved; the production validators and actual Mac delivery implementation remain.

Before any later draft replacement, populate public-delivery-contract.json only from reviewed actual artifacts and seven exact file hashes/source/graph pins, then use the registered public delivery workflow. Preserve the existing verified distribution until the new source/IPA/kit, real Mac signature gate and final server readback pass. Keep the existing draft and never publish/merge without Tin's OK.

GitHub Actions artifacts have limited retention. Original vendor/helper proof40916969403 may expire earlier than current Nov1 artifacts; recheck availability before reuse. Durable repo logs/input maps/receipts and release assets remain, but do not bypass validation if an original Actions artifact is unavailable. Regenerate only the necessary focused proof then. Some big files are intentionally GitHub release assets/ignored local work, not committed Git blobs.

## 12. Boundary incident and known access limits

One supplementary reviewer used the wrong inherited frozen cloud checkout for source/docs/Git-history reads. That violated Tin's no-access rule. No writes, tests/builds or private-config/key/pairing/save-file access were reported. Root disclosed the error, stopped/excluded that review and independently checked relevant public source. The exact metadata is downloads/completion-verification/public-pairing/resume-20261101/review-boundary-incident.json. Do not reopen the backup to audit this incident. Build/test provenance is independently bound to the active public source.

The old b45embedded memo incorrectly claimed no frozen read had happened because it predates discovery. Current docs correct it. Do not repeat that absolute no-access claim for the entire prior session; state the actual recorded limits.

The active public checkout does not contain projects/OVERVIEW.md or projects/APP-INSTALLER-BRIEF.md, nor the earlier Tech-reference log files linked by some old notes. They were not fetched from the frozen backup. This handoff uses the retained public implementation, manifests, current continuation, capability matrix, task list and saved raw evidence. Do not invent missing original brief text or pretend the unavailable documents were read in this transfer.

Tin's Tech & Game-Dev Knowledge Base reference is https://drive.google.com/drive/folders/1hmaKOZMIBVAVBLXuGcvkPANbGzM5Ye7t. When using it, read “00 README + Playbooks” first, then relevant sections, report the exact documents actually read and what failed, and verify changing facts against current official sources. No fresh KB content was fetched for this transfer. Three prior Apple documentation JSON requests failed; actual installed official UIKit headers/compiler provided the recorded SDK evidence. No automatic cross-chat memory/synchronization is claimed.

## 13. Shared Drive and handoff acceptance

Existing shared records, not new dated copies:

- STATUS.md: https://drive.google.com/file/d/1DGvilOgQ8P5exf_q8Ccj-_KNde02XZze/view
- Existing AppInstaller continuation record, updated to carry this complete Claude handoff: https://drive.google.com/file/d/1QhqGf0XueByisrD6T4kzq_3mXPcWg8dS/view
- Shared project workspace/registry: context/DRIVE-WORKSPACE.md and .json. Do not overwrite Offline/Grok/UnitCreator source or build asset IDs with App Installer files. Preserve other projects' STATUS sections when updating the shared record.

GitHub is the source/evidence collaboration location; current binary assets are in the existing draft. Drive updates are explicit writes with readback, not a mounted build filesystem or automatic synchronization. If Claude cannot access either service, report that exact access failure and configure supported legitimate access; never request passwords/tokens in chat or substitute the frozen backup.

At transfer, ChatGPT's agents have finished, recent build/delivery jobs are complete, and no application-code WIP is left uncommitted. The transfer is documentation-only; its final save/readback state is recorded in the transfer receipt. Check the latest branch state rather than assuming this cloud workspace was inherited. ChatGPT will not resume development unless Tin explicitly asks. Claude should acknowledge the current source, tests/reuse limits, known unsupported capabilities, resource authorization and next physical blocker before making changes.

### Pending acceptance — not an overall completion estimate

| Requirement | Actual acceptance for current revision |
|---|---:|
| Live Apple sign-in, trusted pairing, signing, install/update/refresh |0% |
| Real-phone security, expired-session/signature and interrupted-operation recovery |0% |
| Physical Duo outer/inner displays, touch, folding and state preservation |0% |
| Final signed usable release and all required IPA capabilities |0% |

Do not turn this handoff, a passing simulator check, a prepared kit or an unsupported-feature inventory into a completion claim. Continue from the actual saved state, preserve data, solve independent development gaps when required, and involve Tin only for genuine access, credentials, hardware prompts or decisions outside existing authorization.
