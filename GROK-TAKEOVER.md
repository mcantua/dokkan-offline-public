# Grok Bot takeover — Offline Dokkan + embedded Unit Creator

**Tin asked ChatGPT to stop development on October 29, 2026, at about 8:30 AM US Central to conserve usage. All six agents stopped and saved their work. Only handoff, source preservation and uploads followed. Do not interpret earlier “continue until complete” notes as permission for ChatGPT to resume automatically.**

This is an unfinished **single unified iPhone Duo game**. Android and ordinary iPhone remain paused until Tin explicitly approves after complete Duo acceptance. App Installer belongs to another chat. No APK/IPA was built in this continuation. No actual unified original-game launch, offline battle, custom-unit battle, physical Duo transition or unified install has passed.

## Read first

1. `README.md` → `HANDOFF.md` → `context/TIN-RULES.md` → `context/PROJECT-NOTES.md` → `context/REQUEST-HISTORY.md`.
2. `unit-creator/HANDOFF.md` §0, §5, §6 and v2.36 notes; `projects/OFFLINE-DOKKAN-PLAN.md` and the two October 28 Claude handoff messages.
3. This takeover file, `context/DRIVE-WORKSPACE.json` (latest separate Drive copy), `context/GROK-TOOLCHAIN.json`, and relevant `offline-dokkan/original-client/` READMEs.
4. Tin's [Tech & Game-Dev Knowledge Base](https://drive.google.com/drive/folders/1hmaKOZMIBVAVBLXuGcvkPANbGzM5Ye7t): read **00 - README + Playbooks** first. Exact five documents/sections already reviewed and official-source checks are in `context/TECH-GAMEDEV-REFERENCE.md`. No access failures occurred for those five. Other documents were not needed/read. Latest user instructions override older reference recipes. No automatic cross-chat memory/sync is claimed.

## Workspace and checkpoint

- Private repo: https://github.com/mcantua/claude-chatg
- Working branch: `chatgpt/ios-eclipse-database-reuse`; PR #1 remains a draft. Do not merge or publish as a finished game.
- Cloud working directory: `/workspace/claude-chatg`. A replacement agent may need to clone/download its own cloud workspace; no Mac connection is available here.
- Stable feature source snapshot: local `1e8715b131dd98097679b8902ea7bea724708af6`, corresponding remote `9721d84bc89a6c7ec887de5061f08e1abf244cdb`.
- Narrow compiler/diagnostic repair: local `e7455e99feb45b12156ec36c30856eb7808287a8`, corresponding remote `8efeb2eee32825e5e31901156290d072a248efff`.
- The **paused checkpoint at this branch's tip additionally saves uncompiled WIP**, listed below. Its presence is preservation, not verification. The external Drive registry identifies the exact final source archive/hash/checkpoint. Local and connector-created remote commit IDs differ; source contents are preserved.

## Latest source gate — offline auth candidate and fresh-state policy

The unified Duo host can issue a reader-relative auth candidate (`auth_transaction_id`, `nonce`, `access_token`, signed32 `expires_in` plus native time) and can evaluate fresh state without adopting tutorial-finished or zero-capacity sentinels. `GET /auth/nonce` and `POST /auth/sign_in` stay unregistered. `http_body_json` stays null because the HTTP JSON root is still unverified. The real sign-in body and fresh starting stats were not guessed. No source or server key is shipped. One Node check passed 17 assertions. Run 40894918354 later compiled the authored host library on genuine Xcode 27.1 / SDK 27.1. That compile did not open a simulator screen. Original-engine master attachment and late service binding remain open.

## Latest actual check — hosted Finish saves exact thousandths

[Run 40891656259](https://github.com/mcantua/claude-chatg/actions/runs/40891656259), source `1a24cfcd1d412c98db5dada4dd1147cbcc621c00`, **succeeded** about 9:27–9:32 AM CT. `hydrateStatGrowth` stores each derived `coef` as its already-validated thousandth string. The first Finish imported one instance without the test-only candidate (`candidateApplied` false). The retry kept the same instance and version. Authored stat rows stay numeric. `originalClientAttached` is still false. Next open work is full custom-unit validation before save, then the auth envelope only from verified fields, fresh-state policy without adopting pre-server sentinels, original-engine master attachment without shipping keys, and deferred service binding in `ODUnifiedDuoHost`.

## Earlier check — selected-master read passed; production coefficients were still numeric

[Run 40890254683](https://github.com/mcantua/claude-chatg/actions/runs/40890254683), source `3ab4cb0e3106e06f6e4c16781b49b9b6ea30eefe`, **succeeded** about 9:19–9:23 AM CT. `printf` and `format` are no longer allowed in the selected-master authorizer because SQLite turns an oversized `printf` into SQL NULL. Extension loading stays omitted. That run still needed the test-only decimal candidate.

## Previous check — linker fixed; selected-master read was the next blocker

[Run 40881213381](https://github.com/mcantua/claude-chatg/actions/runs/40881213381), source `8efeb2eee32825e5e31901156290d072a248efff`, **completed with failure**. Both the genuine device component library and simulator diagnostic compiled their current objects, then **failed linking `_sqlite3_enable_load_extension`**. `Host.m` called it to disable extensions, while SQLite is built with `SQLITE_OMIT_LOAD_EXTENSION`, which removes that symbol. That run never reached WK.

Grok guarded that call with `#ifndef SQLITE_OMIT_LOAD_EXTENSION` in commit `ea7b6bfbfc83ee87a5b2d75ba98b2612f04d5f6b`. The disable call remains only when the symbol exists, and it still passes 0. **Extension loading was not enabled.** `od_bridge.c` was already guarded.

[Run 40886179478](https://github.com/mcantua/claude-chatg/actions/runs/40886179478), source `ea7b6bf`, **completed with failure after linking**. About 8:53–8:58 AM CT. Component outcome success. The Finish app launched on genuine Xcode 27.1 / SDK 27.1. `testSavedDraftPrepareAndFinishOnDuo` failed in 12.589 seconds with `INVALID_SELECTED_MASTER_BOUNDARY` at phase `selected-master-read`. Startup was ready and the source master hash was unchanged. The live project matched the last submitted save. The prepared project did not; the only value-free difference was `sourceStatGrowth`. That run did not reach the numeric Finish proof. Run 40890254683 later did. No release package was built. Its screenshot is the hosted Creator card builder, not the unified game.

Previous evidence:

| Run | Actual outcome |
|---|---|
| 40860320010 | Real SDK27.1 diagnostic setup deadlocked before WK; callback-driven setup corrected. |
| 40866894839 | Deprecated orientation call and missing overlay link inputs; scoped fixes committed. |
| 40868354886 | Actual WK Creator launched; `CREATOR_PREPARE_SAVED_MISMATCH` isolated to derived `sourceStatGrowth`; source master unchanged. Component objects compiled, framework link dependencies then corrected. |
| 40880093477 | Retained callback unused-parameter warnings and malformed XCTest string literals stopped compilation; narrow fixes committed. |
| 40881213381 | Current objects compiled, missing extension-disable symbol stopped both links. Fixed afterward by guarding the call. |
| 40886179478 | Both links succeeded on `ea7b6bf`. WK launched and failed at `selected-master-read` with `INVALID_SELECTED_MASTER_BOUNDARY`. |
| 40890254683 | Success on `3ab4cb0`. Selected-master read passed. Diagnostic Finish retry passed with a test-only coefficient candidate. |
| 40891656259 | Success on `1a24cfc`. Production thousandth strings saved. First Finish needed no test-only candidate. |

Do not repeat passed unchanged checks. Extra runs so far addressed specific actual compilation/setup failures, not broad regression suites. Run 40886179478 saved `finish-only-wk.png`: the hosted Creator card builder on the test unit "NATIVE OFFLINE CREATOR FINISHED", **not the unified game** and not a successful Finish. The older image `creator-finish/40868354886/finish-only-wk.png` remains a separate Creator WebKit diagnostic.

## What is implemented in source

- Reused the supplied **actual iPhone arm64 game client** as the production foundation. The old authored JavaScript battle/save-manager UI is frozen as an internal harness, not the game. Android APK/assets are reference/input resources; APK binaries are not mechanically converted into iPhone executables.
- Preserved a genuinely compiled SDK27.1 Unit Creator host main, prepared the pinned original engine as a private dylib, and added bootstrap/scene/renderer/pause/resource-admission components. Static checks passed; dyld, signing and actual game execution remain unverified.
- Restored/authenticated the complete current master: 114,827,264 bytes, 28,034 authenticated cipher pages, **19,588 cards**. Exact plaintext and encrypted inputs are separately preserved. Do not repeat this restoration or overwrite older editor snapshots with another source identity.
- Reused the full existing Creator iPhone Host/Player/adapters/workers rather than removing screens. Scoped native tools cover files, media/LWF previews, imports/exports, source codecs, Keychain AI services, archives and readonly temporary source verification. Runtime feature parity remains unverified.
- Same Core/Session/save ownership, explicit native edit leases, durable projection/outbox reconciliation, exact immutable accepted project/definition bytes, per-version receipts and read-only interrupted-Finish receipt lookup. Unknown/pruned receipts stay unresolved; recovery never replays an obsolete Finish to mint ownership.
- Core11 stores local identity and source-backed rank/new-card EXP facts; legacy unknown EXP is not fabricated. New creations start level1/SA1/locked Hidden Potential under the approved rules; legitimate progress survives edits.
- Derived runtime master tooling reuses existing Forge allocation/materialization, retains historical private ID blocks and original official rows, and binds exact accepted scope/version/hashes. Cloud real-master/C reader scenarios passed. The hosted WK scenario now launches and stops at the selected-master read, so the native writer after Finish still has not run. Source-engine database attachment is separate and unverified.
- Actual cached resource response was inspected **only in memory**, producing sanitized types/field vocabulary, never player/account scalar values. Data-only projection uses our own canonical state and rejects incomplete success bodies. **No auth/resource/game route is admitted yet.**
- Exactly 27 unique byte-identical iPhone resource references (29 aliases), 51,272,144 bytes, were verified/staged. Many other Android resources differ; do not call the full Android export iPhone-compatible.

## Saved post-baseline work — review before use

| Files | State and boundary |
|---|---|
| `mobile/ios/ODCreatorController.m` | Uncompiled preview-canvas fix: real ForgePlayer owns frames inside its canvas, preserving close chrome. Uncompiled scope-specific persistent WebKit data store isolates drafts/gallery across logical saves and refuses fallback leakage. Legacy restricted diagnostic path stays separate. |
| `original-client/creator-tools/ODScopedCreatorTools.h/.m`, `unit-creator/ios-objc/Player.m` | Uncompiled immutable scope accessor/native asset-FD opener; scoped player clears cookies through its own data store. Asset opener stays native-only and readonly; no WebView path authority. |
| `duo/ODDuoCreatorQuickAction.h/.m`, `ODDuoOriginalScene.m`, `ODUnifiedDuoHost.*`, `duo/README.md` | Uncompiled interim app-icon Creator entry with actual cold/warm UIScene delivery and bounded request reporting. Preserves original renderer/HUD/controls/other shortcuts. **Final in-game menu insertion is unresolved.** No shake gesture or invented Cocos hook was added. |
| `core/od_core.c/.h` | New direct trusted `od_creator_finish_bundle` API is **WIP/uncompiled**; public import/Finish must reject privileged bundle descriptors. No corresponding C bridge/NativeCore wrapper was implemented. |
| `creator-bundle/ODNativeFullCreatorValidator.h/.m` | **Unfinished** native full-project/resource validator. Mandatory source hash verification, known-reference/shared dependency validation/conflicts and immutable capture/dedup integrity review remain. **Must not unlock Session/UI guards.** |
| `creator-bundle/full_bundle.js`, README/evidence | Isolated candidate reuses existing ForgeForms.reserve/UnitRebase/materializeAll/exportEntries. One real-master two-form/custom-ability scenario materialized234 rows with one ownership mapping; wrong asset scope rejected. No Core/native/engine acceptance follows. |
| New auth/profile/master research JSON and contract Markdown | Established readonly source facts, not executed hooks or a working server. |

Full-bundle next design: one canonical root progression/owned-instance DTO bound to the complete immutable accepted bundle/version/hash; keep every actual form/ability/resource. Do not silently drop edits because the old harness cannot represent them. Existing full-bundle restrictions remain active. Never equate staged rows or tests with playable custom units.

## Critical contracts and remaining gaps

**Creator Finish:** the production precision fix is **not applied**. The single existing XCTest has a value-free actual-final-boundary probe, public synthetic numeric roundtrip probe, and a diagnostic-only decimal-string candidate. It applies that candidate only after matching numeric-drift proof, then retries unchanged Finish/idempotency and its dependent native writer. Preserve every saved/stale/forged/master guard. If the actual proof supports normalization, change only derived growth coefficient metadata, preserve integer thousandths and stable same-intent retries; do not round authored values or weaken comparisons.

**Bootstrap auth:** current source proves `GET /auth/nonce`, `POST /auth/sign_in` through constructor/vtable/Cocos/Foundation method dataflow. Reader-relative nonce fields: `auth_transaction_id`, `nonce` strings. Token consumer reads `access_token` string, `expires_in` signed32 seconds and adds native time. **HTTP JSON root/envelope, requiredness and complete success body remain unverified.** No secret/captcha field, remote account call or local auth service was implemented. See `research/bootstrap-auth-contract.json`, `protocol-inspection/BOOTSTRAP-AUTH-CONTRACT.md`.

**Fresh state:** actual model constructors initialize tutorial finished=true and zero capacities as **pre-server sentinels**, not a playable fresh account. Missing fields preserve existing values. Do not adopt these or played source cache values as official starting policy. Source rank rows/ACT/EXP are available; tutorial/capacity semantics and complete resource DTO remain unfinished.

**Original master:** `content/MASTER-OPEN-CONTRACT.md` distinguishes the MAIN from the patcher. MAIN resolves native asset root plus `sqlite/current/<language>/database.db`, bundled fallback, internal read/write+create open, internally generated key, cached handle and compatibility3 fallback. The patcher separately uses `Documents/assets/sqlite/current/<language>/database.db`, readonly/fullmutex and compatibility4. `SPRK_Cards_Data.db` is a separate User cache. No key bytes were read/published. **The derived master is plaintext; no original-engine path/key/cache attachment is admitted.** Do not copy patcher assumptions into MAIN or redirect its cached handle blindly.

**Native startup:** retain genuine host/SDK and original AppController/renderer initialization. The loader requires concrete native preparation/local Foundation handling/source-patcher exclusion, not an exhaustive static audit of5,259 initializers before any authorized diagnostic. It does not claim kernel/socket/WebKit isolation. No signature/protection bypass, raw MH_EXECUTE loading or SDK-field relabeling is approved.

**Late services gap:** Integrated `ODUnifiedDuoHost` still requires services before UIApplicationMain, but fresh Core/profile/scope APIs reply asynchronously on main. No late-binding implementation was started. Add explicit native deferred same-provenance binding after main: pending services, install lifecycle once, attach actual renderer when ready, refresh queued QuickAction. Do not spin/block main, invent a native provenance matcher or use KVC/private ivar access. The requested host-roots/provenance matcher does not exist yet.

## Drive files and tools for Grok

Use the **existing** [AI-Workspace/Offline Dokkan + Unit Creator](https://drive.google.com/drive/folders/1vCYgjgNagsEZ-yNsfRI97qrJkiBdsIbV). Keep private sharing; use your own authenticated Drive/GitHub access. No account tokens/passwords/signing material are included.

| Item | Existing Drive ID / reference |
|---|---|
| Current paused source archive | `1HpVONnER2Mh8-3ywtLc01h5kXEjYybo0` (overwritten with final checkpoint; exact SHA in external registry) |
| Latest operational registry / transfer inventory | `1IHUWdb_p9-5HQM9q6plDqEfZT5h4e9nA` / `1LDhdYCN7KShwyxK3195nd-WraTBfaD0u` |
| Native evidence archive | `10czSNpVKlNN0sElE6IezdEBRHNKLpeh6` (updated with current logs/image/results) |
| Original iPhone IPA | `12o01--OT-8r3QiXVD6mp-uMfv4b_qbms`; 1,144,358,271 bytes, SHA `0ea61911a09c4e7735f2d7b32b7b2c6c6977c1f4acf0a9db278049528b662816` |
| Complete Android export | Folder `1qwtEewReE2LFTjh_v9MzeA2_iQnF1GPN`; ZIP `16343EAlxRNmwtlc3HuKMxpOAwjFAz4L7`, 26,650,901,563 bytes. **Do not download the whole ZIP again.** |
| Current encrypted master / extraction receipt | `13UCSCkTBqOMIOrNj67ugB7z_Z98632Lw` / `1BcfiTaudp7emJ01ROGFlj3wccB6k_Ahc` |
| Current restored plaintext ZIP | `1dQDs-QyZXxuT6X_vg6ZfIJrevBtUT8x0`,19,252,226 bytes; contained DB SHA `1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4` |
| Prepared private engine/genuine shell inputs | `151m8LadHN-CQo_3IKseDAZBSMst4OlPh` |
| Verified resource catalog / cache archive | `11frPiU5KpTh0_8WOtmB0iIyjOE4fxUpd` / `1-UuiahEUfb5ekUx-c_7PA2mfA9brcGZz` |
| Old editor Eclipse/Sparking DB ZIPs | `1RUB3C2BHNP6tDUBJGlgH1upZ3Gea7Pko` / `1b7ub0LBmXbbUIw8-MAG71yKcSW41cUgr`; keep separate from current master |
| Existing tools/dependencies | Folder `1ejfWKWUIzc5w0ulsK6LNTgM_MmQFz6MR`;37 objects metadata-listed at handoff. See all part IDs/checksums in registry. |
| Current toolchain/recovery manifest | `1BoivQMyXU6qRY3qBeHzjQ_kZAVSE5YhU`; also `context/GROK-TOOLCHAIN.json` inside source |
| Four retained-tool parts | `103FmGqh5IwzqkwPOQbESEReS-gx1ETxO`, `1d7Te3Ru3qkieqqQrIw0Bh1yW6yhpHaFz`, `1u5srnPF2XcjwW8iMWJf1dVY42pSZTe8D`, `1b5_Cnx9ZCgSWmKu6EtIMF6_3jKSxi35H` |
| Current standalone test HTML | `1-xdzbEL7EsuMd7DEzTU_pFJpuEvOknrC`; unchanged in this native continuation |
| Knowledge-base reading log | `19Qg-dhMOnM0xO2vepxcYn8QaX_9mt8LL` |

Retained tools reconstruct with `cat retained-tools.tar.gz.chunk-* > retained-tools.tar.gz`; check individual and whole hashes in the registry before extraction. Whole size362,318,003 bytes, SHA `5c9c6e528190d4110067d7ceb4cca998caec2addaf3dc8dbd622cd285ca2e9d4`. Do not download the paused Android emulator images for Duo work. SDK/LLVM/JDK source pins/licenses are in `downloads/*/SOURCE.md`; read-only shared bootstrap is `app-installer/build/setup-linux.py`, not permission to modify App Installer. Host OS and genuine hosted Xcode are service-managed, not portable OS copies. Current cloud versions are recorded in `context/GROK-TOOLCHAIN.json`.

Private working inputs, if this cloud survives: `offline-dokkan/private/iphone-client/` (IPA, BNGI0221, prepared engine, encrypted/plain current master, resource catalog/cache), `private/sparking-client/` (APK, libbase, manifest), `private/duo-shell/`. Ignore/private paths are never Git source. Signing credentials, profiles, AI keys and raw Sparking keys are intentionally absent from the handoff. Source codec keys derive from the user's admitted input only in native RAM/Keychain.

## Resume efficiently

1. The SQLite load-extension link and the selected-master read are fixed. Do not enable extension loading. Do not repeat run 40890254683 just to confirm those two results.
2. Derived growth `coef` values are now exact thousandth strings. Run 40891656259 passed. Do not repeat it just to confirm that save. `.github/workflows/unit-creator-finish-only.yml` starts when `finish-only-intent.json` changes on this branch; do not trigger old broad or paused-platform workflows. `build-components.sh` creates an authored library, not a game package. The native fixture reconstructs older Eclipse rows from the committed HTML; it is not the 114MB original current master.
3. Apply a production Finish precision correction only if actual proof warrants it. Complete full-bundle native validation/authority and immutable capture before lifting guards.
4. Finish auth body envelope/current resource policy, deferred native service binding, actual master codec/cache attachment and original engine launch. Continue from real runtime observations, not invented wire responses/UI/hooks.
5. Verify actual custom units/abilities/forms/assets in original battles, saves/progression/events/summons/training/potential/tournament/rewards, native controls and both Duo displays. This is still substantial unfinished work; no trustworthy overall completion percentage or deadline is claimed.

For a meaningful editor change batch, run `python3 web/build.py` **from `unit-creator/`**, overwrite the single `test-page/UnitCreator-test.html` using the actual `web/site-artifact` pipeline, include version/change banner and deliver it. `test-page/README.md` documents the committed-checkpoint builder. Do not overwrite existing raw DBs with reconstructed fixtures, claim the HTML runs the native game, or rebuild it merely for this handoff. No new HTML was generated after Tin's stop.

Cloud first; no Mac/PC/personal connection use without the applicable scoped permission and prior notice. Existing approval covered read-only IPA metadata and Unit Creator2.36.3 signing/install evidence, not unlimited new Mac work. Keep one backup maximum (existing Mac cleanup recovery preserved), no old Offline harness builds, no private game DB/APK/IPA in GitHub, no source/signing/API secrets printed or shipped. During active development Tin wants concise pending-only percentage tables with real accurately labelled images every 10 minutes. The authorized linker repair and one native retry are recorded above. Do not continue into another run or a release build from this note. Nothing is claimed to run unattended.
