# Claude takeover — Offline Dokkan + embedded Unit Creator

Prepared October 29, 2026, 6:21 PM CT at Tin's explicit request to stop ChatGPT development and upload the full handoff. This is the current entry point; older Grok/Hayate notes and earlier active-worker reports are historical where they disagree. No background development remains active.

## Latest agreed branding direction — October 29, 2026, 06:52 PM CT

Tin clarified that this is a private, fan-made, noncommercial passion project for personal offline enjoyment. He does not intend to sell it or claim ownership of the original game. He accepted an unofficial rebrand along these lines:

- Working name: **Dokkan Freedom**; custom icon, splash screen and project-facing menu branding. Preserve the original gameplay/presentation requirements; this is not permission to replace the client with a generic game.
- Disable store/purchase flows, external account linking and publisher-service connections in the working offline application. Implement actual behavior changes; renamed labels alone do not disable requests. Do not remove the approved ability to obtain compatible game data through controlled, explicit downloads where still required by the project plan.
- Retain original attribution and applicable third-party notices in a **Credits / Licenses** screen. Present the project as unofficial and fan-made. This supersedes earlier requests to hide all traces of the original publisher.
- **Devices, backups and saves are explicitly excluded from cleanup.** Do not delete or rewrite these, original recovery archives, signing material, or historical provenance to make the working app look rebranded.
- Do not blindly replace package IDs, symbols, ABI names, database identifiers or file hashes. Change technical references only as part of a compatible implementation. Preserve exact original input pins; record any derived resources separately.

Suggested short About text: “Dokkan Freedom is an unofficial fan-made project for personal offline play. It is noncommercial and is not affiliated with or endorsed by the original rights holders. Original characters, artwork, music and game components belong to their respective owners. See Credits / Licenses.”

**Implementation status:** This records the approved direction for Claude, who retains development ownership. No game file, Drive source asset, account connection, purchase flow or executable was changed by this clarification. The limited read-only audit found publisher names in the Android-export English localization, copyright HTML, account-linking labels, legal/store links and retained technical identifiers. No comprehensive scan of packed assets/binaries was performed. No runtime feature-disabling or rebranding verification is claimed. No tests or builds are needed for this documentation change.

## Read first and repository boundaries

Read README.md → this file → STATUS.md → context/TIN-RULES.md → HANDOFF.md and HAYATE-HANDOFF.md for retained history. Then read the specific source/evidence documents linked below. The full planned feature set remains in projects/OFFLINE-DOKKAN-PLAN.md and the Creator handoff; this document prioritizes the first real playable path, not a reduced final scope.

- Active repo: https://github.com/mcantua/dokkan-offline-public
- Current topic: `chatgpt/duo-source-integration`; draft PR: https://github.com/mcantua/dokkan-offline-public/pull/8
- Protected base: `chatgpt/ios-eclipse-database-reuse`. Do not merge without Tin's explicit OK. Preserve draft PRs #1–#4 and their source work.
- Old `mcantua/claude-chatg` is an untouched private backup. Do not work there.
- Goal: the supplied original Sparking/Dokkan native client running offline with approved modifications and Unit Creator embedded, sharing real data, assets and saves. Eclipse/Sparking are development sources, never selectable game modes. No substitute browser game or simulated battle counts as delivery.
- iPhone Duo only. Android and ordinary iPhone remain paused. Preserve original client presentation, animation and mechanics; evaluate both Duo displays through actual device evidence.
- New own profiles skip the intro tutorial. Preserve existing progress; do not invent starter units or tutorial rewards.
- Meaningful Duo builds are authorized: the former no-build rule was permanently revoked. Label Diagnostic/Playable truthfully. Do not rebuild merely to produce another checkpoint.
- Normally 1–2 targeted checks per task; reuse passing evidence. Prioritize implementation. Never claim tests/source imports are completed gameplay.
- Never touch user `save/` folders or the signing key. No secrets, keys, private identifiers, original game binaries or databases in public GitHub. Private inputs stay in existing Drive. One backup maximum.
- Cloud first; explain concrete personal network/device use before using it. Current environment has no Mac, physical iPhone or VPN access. Do not imply it does.
- Plain language, Central time in 12-hour AM/PM. Pending-only progress tables with grounded percentages; no invented overall percentage/ETA. Images must be actual in-app captures; none are available.

## Truthful state at takeover

**The original client is not verified playable.** No original Home screen, actual native battle, device installation, persistent native gameplay loop, or physical Duo display transition has been demonstrated. No reliable completion ETA or overall gameplay percentage exists. The application must not be called complete.

There is substantial authored offline adapter/Core/Creator source, retained native reverse-engineering evidence, genuine Apple SDK compilation, original resources and diagnostic IPAs. These are different acceptance levels. The largest immediate blocker is actual original-master open/schema/readiness and its connection to the real client startup. `ODUnifiedDuoHost.originalGameDataAdmitted` still returns NO intentionally. Setting it true without native evidence would fabricate readiness.

The newest successfully compiled source is **`457588ce135bc2704237d8b14a3936e60fa1819d`**. Genuine Xcode 27.1 / device SDK 27.1 / arm64 compiled and linked **77 native units**, first attempt, in https://github.com/mcantua/dokkan-offline-public/actions/runs/40968955778 . Component artifact `12938734918` was downloaded and verified, then its library and receipt preserved privately. The GitHub artifact expires quickly; use the private takeover kit if expired.

**No IPA was assembled from 457588c.** The handoff commit also preserves later optional native resource-probe source and master-observer tooling that are NOT part of that successful compilation. Do not describe current branch HEAD as fully compiled. These `.mm` files are automatically discovered by the next native build, so compilation is still needed after integration.

## Latest completed source cohort (457588c)

1. **In-game Creator/tools entry:** `original-client/duo/ODDuoInGameActions.*` adds one compact safe-area menu to the actual original UIWindow. Actions: Unit Creator, Practice Battle and optional Share diagnostic report. Real UIKit menu-dismissal completion precedes invoking existing owners. Touch passthrough, activity/generation guards, and explicit Retry Save are implemented. This is source/compile evidence, not a screenshot or launch claim.
2. **Private diagnostic sharing:** `ODDuoDiagnosticReport.*` and `ODDuoDiagnosticExport.*` export a fixed allowlist of booleans/enums/counts/source identity and fixed route templates, via in-memory NSItemProvider/UIActivityItemsConfiguration. No raw reports, arbitrary paths, player IDs, keys, NSError descriptions or automatic uploads. Real UI sharing remains unverified.
3. **First native team:** `resources-projector.js` permits an exact empty team list and persists an actually submitted valid first formation with owned positions and explicit no-custom-music empty string. Existing null/string BGM preserved. No invented teams, collection, units or selected slots. Projector SHA256 `272b92e38ecfa92ce43b5eb659b3619b125b48f8c6661d69d2c58d9787c09602`, 27,184 bytes. One focused JS scenario passed.
4. **Startup/login/home race:** `ODOriginalPlayerResourcesAdapter` has the fifth preparation-waiter argument. It waits once for actual Host service binding, bounds pending requests at eight, retains deadlines/activity checks, and does not poll or open another Core. Native auth always obtains a nonce; only ping is optional. No invented persisted token/renewal route.
5. **Practice save lifecycle:** Core schema **15**, `core/practice.c/.h`, native-only `practice.begin`/`practice.finish`, `ODOriginalPracticeSession.*`, and bound original finish callback. Source-fixed phase 3, profile/scope/revision/session identity, same Core, durable finish before cleanup/Home. Unknown commit retries preserve command identity; known precommit revision conflict permits a new explicit retry intent. Late callbacks cannot settle a newer session. No normal quest rewards, ACT, tutorial progress or ordinary quest completion is invented. One actual C scenario passed migration, replay, scope/revision rejection, unchanged normal gameplay state and reopen persistence. Native combat-to-save is still unverified.

Seven older migration-check files now expect schema 15 rather than 14; they were not rerun just to regenerate evidence. The assembly critical-source list adds ODOriginalPracticeSession.m after the compiled commit. This is a packaging bookkeeping change, not another native execution result.

## Optional native master observer: unfinished integration

Read `offline-dokkan/original-client/content/native-master-observer/README.md`, `FORMAT.md`, `recipe-manifest.json`, `check-evidence.json`, `witness-evidence.json`, `recipe.py`, `probes.py`, and `probe-format.h`.

This is an optional reversible derived-image recipe; the original engine and working package remain untouched. No extracted key, foreign SQLite-handle call, guessed callback or gate override is used.

- Final private derived engine: `offline-dokkan/private/source-client/instrumented-master-observer/OriginalDokkanEngine.dylib`
- 55,779,656 bytes; SHA256 **`92fee997a655cfc40f09f342ddf51e26c3da3082ce67c2d4bd3062365aa132b3`**. Earlier intermediate hash `6e794743…` is obsolete.
- Original exact engine: 55,697,728 bytes; SHA256 `efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222`.
- Five MOV-to-leaf-branch sites: four in the exact 316-byte cached-open wrapper at `0x10044fa50`, one in the 248-byte path/key wrapper at `0x1004318c4`. Original instructions replayed. B/B-back preserves live X30. Scratch registers, LR, flags and stack restored. Key argument/provider/body are never read.
- Success is fresh-open wrapper result 0; cached fast-return 1 does not prove a fresh schema check. Schema failure 16 stays failure.
- Separate 1,112-byte success witness at RW offset 36,864; publication ticket at 40,960. Survives ring reuse, invalidates before a new empty-cache open, pairs exact manager/cache identity. Reader must use acquire publication/stable copy plus trusted own-file identity, never SQLite-handle dereference.
- Unsigned 86 commands / sizeofcmds 11,368; first section remains 16,384. RX VM `0x1031dc000`, file 50,839,552, size 16,384. RW VM `0x1031e0000`, file 50,855,936, size 65,536. LINKEDIT VM `0x1031f0000`, file 50,921,472, filesize 4,858,184, vmsize 4,866,048. Chained segment count 4→6 with exact offset adjustments; original data VMs and section ordinals unchanged.
- Exact inverse/deterministic generation and synthetic two-slide control-flow/register checks passed; retained-witness behavior checked. These execute synthetic probe code, not the original game. An initial high-address ADR encoding issue was fixed. Source peer reviews completed.
- **Unresolved:** signed-image normalization/admission, loader capability, live witness reader, trusted staged-file matching and actual original startup. Async unwind from an island PC while SP is temporarily -96 is unproved; original unwind tables were preserved, not extended.

Next implementation: accept only this explicit derived variant, normalize its allowed signature tail to the exact final unsigned hash, then inverse it to the exact original snapshot. Do not simply raise the loader's old 11,224-byte command cap or disable image hashes. Normal 16-byte signature alignment introduces an eight-byte gap; signed sizeofcmds is 11,384. Preserve strict __LINKEDIT/signature normalization. Existing HTTP/codec/practice/origin function bodies remain unchanged, but old ODNativeMasterObservation's full 316-byte runtime hash deliberately rejects the modified wrapper; introduce a separately validated capability. Only bind readiness after actual native success and matching own staged file. No such acceptance changes have been made yet.

## Optional resource observation: source only

Read `content/NATIVE-RESOURCE-LOOKUP-OBSERVATION.md`, `PRACTICE-RESOURCE-INVENTORY.md`, `ODOriginalResourceLookupProbe.h/.mm`, and their source-evidence JSON files.

The optional probe uses the already existing FileUtils singleton/vtable, never constructs a native global, and runs only on the main thread in the actual initialized scene. It honors the original Apple libc++ 24-byte string/indirect return ABI and runtime pins. Twelve fixed lookups cover four retained original candidate files. Outputs are booleans only. No arbitrary native-returned path stat, keys, user saves, per-frame polling or gate activation. Foundation anchor canonicalization followed by appended assets and O_NOFOLLOW fixes a peer-found symlink-boundary issue. Not wired into the factory or compiled/run yet.

Source proved the actual bundle helper returns `<app bundle>/tutorial0/`, and the download helper builds `Documents/assets/tutorial0/<filename>`. The restored original packs are already in the correct bundle/tutorial0 location. **Do not add guessed resource aliases or replace original iPhone packs with Android copies.** Actual phase-3 branch selection still needs runtime observation. Ordinary sugoroku TMX is not required for the direct practice path. BGM149 AWB is already among 27 aliases; a small Android ACB is only a conditional candidate, not staged.

## Build/delivery inventory — all diagnostic and unsigned

| State | Source | Bytes | Location / verification limit |
|---|---|---:|---|
| Latest compiled component, no new IPA | 457588c | 2,725,160 dylib | Private takeover kit + Actions run 40968955778; 77 units compiled |
| Latest assembled integrated IPA | 20fd1d0641a63e52fdeb3af0809b14a2eb01d2a6 | 944,841,989 | Local cloud integrated-current; recoverable in Drive as baseline + delta |
| Existing single integrated IPA in Drive | 8be14517dd4bd00e3da747b07a87a26f4493d136 | 929,647,581 | Drive `1INd1U3aa7eFRsb2h3YwOMNguXU8zzzLo`; earlier 71-unit version, no later Creator site/POST codec |
| Earlier startup-only IPA | 5b695bd | 795,503,162 | Drive `1TjyV9-OJYT1aaiQQAKzxRLFfVnW5HHj-`; historical, not latest |

Latest full 20fd IPA SHA256: `f8d9deddddffb2c1571fa62905c325c37920c32d0b4e291cd907ad975f3b3c43` (version 2.36.3/code 128). Local cloud path: `/workspace/dokkan-duo-build/offline-dokkan/private/integrated-current/OfflineDokkan-Duo-Integrated-Diagnostic-2.36.3.ipa`. It contains 286 Creator UI files and 1,395 archive members. Do not advertise it as playable.

Drive 8be baseline SHA256: `9c2dec628ad80a8e0c0f075d92c1ec4f3b64a91dbc108ed446a7d794bd12bbc2`.
20fd delta: Drive **`1qq7ehVeBqxpYeqb0A9VpdHlotghRA8qK`**, 16,641,867 bytes, SHA256 `a42a364f5dc8dbc0e9c64d339857ea791e3008464fa0038321539fffac30ebde`.
Existing reviewed restore notebook: https://colab.research.google.com/drive/1yS8bl2XMSK5bo0BFKpgsqi7ZHkh-LWFr . Latest update reconstructs the 20fd IPA inside Google cloud, preserving its baseline, with mandatory hashes. That newest notebook revision has NOT been confirmed run. Do not claim a single 20fd Drive IPA exists just because the older notebook runs completed. Source helper: `tools/diagnostic-download/apply_integrated_diagnostic.py`.

The separate `/workspace/dokkan-duo-build` worktree is detached at 457588c with that Creator site staged, but its retained `integrated-current/assembly-inputs.json` is still for 20fd. Update component/source/site pins together before another assembly; never mix receipts. Native build entry: `offline-dokkan/original-client/build-components.sh`; manual workflow ID 400826915 (`unit-creator-finish-only.yml` → original-client components). Pin exact approved source commit and entry mode integrated-development. No app build was run for this handoff.

## Private recovery and tools

Primary Drive: https://drive.google.com/drive/folders/1vCYgjgNagsEZ-yNsfRI97qrJkiBdsIbV . Use existing folders; do not duplicate AI-Workspace. The definitive inventory, Drive IDs and checksums are in `context/DRIVE-WORKSPACE.json`. The archive excludes that operational registry to avoid recursive hash bookkeeping; fetch the registry separately.

- Source mirror: `1HpVONnER2Mh8-3ywtLc01h5kXEjYybo0` (updated in place at handoff).
- Private source-analysis archive: `1-BDN6S3NZm3E330vyHEd7mgkEgb0WNyu` (updated in place; read retained exact source findings before rerunning Ghidra).
- New private takeover kit: Drive **`1NrRRCJ4wmZCq1anulVtOqCSJUrx60FRJ`**, 40,475,733 bytes, SHA256 `eefb06b4d58e305f8ee5bba4b18c509e0aec3e357ad122b146c759f19a397fb1`; also recorded in the **claude_handoff** registry entry. Contains the latest compiled library/receipt, optional derived engine and recipe receipts, pinned native-probe wheels/licenses/reference source and SQLite archive. `CLAUDE-PRIVATE-RESTORE.json` inside lists each relative path/hash. Restore only inside a private cloud checkout, never push this archive to public GitHub.
- Existing original IPA: `12o01--OT-8r3QiXVD6mp-uMfv4b_qbms`; original Android export remains in Drive. Do not re-download the full 26.65 GB export merely to retrieve a known smaller input.
- Local engine: `offline-dokkan/private/source-client/OriginalDokkanEngine.dylib`, original hash above.
- Genuine shell: `source-client/OriginalGenuineDuoShell`, 332,320 bytes, SHA256 `18db225cd578fcfc724b1dbf6c0b89eb2213fb05d6113cd52fbc1a1ce006218a`.
- Original resource manifest: `source-client/original-resource-parts/Private-iPhone-original-resources-manifest.json`, SHA256 `d0a887ef235f35aa54f5ac35de9c0cd867bcbfb7026ef214232fd635e0b48f2f`.
- Original staging: `source-client/original-resource-staging`, receipt SHA256 `c7b5e675ab320977de0abddf9ecc44151bffc8092d550f9a546a1cb441e23c4f`; 1,067 resources plus metadata/27 aliases, 1,098-member inventory.
- Core plaintext `fresh-master/reference.db`, 114,827,264 bytes, SHA256 `1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4`. **Not a substitute for encrypted native MAIN.**
- Opaque Android candidate `source-client/opaque-android-master/Current-export-master.db`, same size, SHA256 `f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d`. Export label en; native key/schema compatibility and runtime language unverified.
- Original bundled seed: 535,552 bytes, SHA256 `667e554a9cfb8c4765f05a1d85f0fdf707ade61562b50e3e5cd98ac52f997ba3`.
- Ghidra 12.1.4, Capstone and older tooling are already inventoried in Drive. New authored bounded lookup: `downloads/ghidra/scripts/QueryExistingLiteralReferences.java`.
- `downloads/native-probe/SOURCE.md` and manifest pin Keystone/Unicorn. Wheels are private; reconstruct runtime from them if needed rather than saving redundant installed environments.
- SQLite 3.50.4 official archive SHA256 `1d3049dd0f830a025a53105fc79fd2ab9431aea99e137809d064d8ee8356b032`; restored via `offline-dokkan/mobile/setup-sqlite.py`. Canonical headers/source: `downloads/sqlite-amalgamation/source`; Core/adapter Makefiles now agree.
- Platform-hosted Xcode/OS images and account-bound credentials cannot be copied into a handoff. Recreate the documented genuine hosted CI environment; no signing material was accessed or uploaded.
- Historical unused tutorial checkpoint code is preserved unchanged at `handoff/paused-tutorial-checkpoint/`, outside native autodiscovery. It has stale relative includes, is uncompiled, and must not restore the intro sequence. Read its INACTIVE.md.

## Concrete next work, in order

1. Recover exact current source and private inputs. Confirm the source/build distinction above, without repeating already passed generic tests. Review the pinned master-observer recipe and final private evidence.
2. Finish strict derived-image signed normalization, capability and live witness reader. Bind actual original open/schema success to the own staged master identity. Resolve any real native compatibility failure; never extract or ship keys or assert success from ciphertext presence alone.
3. Wire the optional bounded resource observation only where useful for the actual original startup/practice path. Keep original bundle layout. Batch related integration, compile once with genuine SDK, assemble with matching receipts; investigate only concrete failures.
4. Obtain actual original launch/login/Home evidence using an available authorized iOS execution path. This cloud cannot install on Tin's phone. Signing/install remain a real external dependency; do not call an unsigned IPA install-ready.
5. Prove an actual owned team can enter the original battle, play and finish; persist the actual result and relaunch. The fixed rewardless phase-3 practice bridge is a diagnostic path, not proof of ordinary quests/rewards/progression.
6. Prove a created custom unit is admitted into the same native data/runtime and actually works in that battle, including applicable assets/skills/forms. Existing Creator source is not that proof. Finish other agreed combat/progression/event features against real client contracts after the first loop works.
7. Verify both Duo display layouts/transitions and essential save/security/install integrity. Share real in-app images and a correctly labeled newest download. Keep other platforms paused.

No starting collection, complete ordinary quest/result protocol, server-equivalent progression/rewards, original-master compatibility, custom-unit live gameplay or physical display behavior should be assumed from existing source. Use documented evidence rather than guessing missing envelopes/ABIs/values.

## Agent work and preservation

All six workers were stopped/completed for this takeover: auth_first_path (auth/menu/share integration and peer review), ghidra_battle (practice ledger/finish), master_lifecycle (derived observer), player_home_team (team/preparation), restore_startup_inputs (resources/probe), startup_factory (integration and source review). Their completed findings are incorporated above and in the corresponding checked-in source/evidence. There is no supported background development process left running.

The latest meaningful checks are the formation scenario, Core ledger scenario, genuine 77-unit compile and focused optional observer checks described above. Handoff verification is limited to Git privacy/whitespace and upload size/checksum metadata; it does not rerun the game or build another IPA.

Technical reference: Tin's Knowledge Base folder `1hmaKOZMIBVAVBLXuGcvkPANbGzM5Ye7t`. Read its “00 README + Playbooks” before relevant sections if doing new research. Existing access/read log is `context/TECH-GAMEDEV-REFERENCE.md`; do not claim automatic cross-chat synchronization. This preservation-only handoff does not re-read the entire reference collection.

Private source-analysis handoff snapshot: 1,055 files, 2,896,197 bytes, SHA256 `b95a96c58b527f5a20270762bda049465d0f9819a2c88b1943883364ce9e1568`. Upload metadata verifies size/parent; this handoff does not claim a re-download byte verification. The private kit has 17 entries including its restore manifest.
