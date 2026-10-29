# Persisted own-app native bridge

This is a functional bridge to `od_core`, not a game HTTP imitation. It performs real player/Creator SQLite operations and returns the committed core results. It explicitly rejects `/resources/login` and other unverified game paths with `GAME_WIRE_UNVERIFIED`. Exact current game contracts and hooks remain separate work.

## C API and capability boundary

`od_bridge.h/.c` opens host-pinned save/master/content paths and serializes core work. Every returned result/error is an owned string freed with `od_bridge_free`. The host stops outstanding work before closing.

Client execution permits `profile.create` (empty args only), `profile.snapshot`, `team.set`, `card.lock/stats`, `card.potential.preview`, `card.training.preview`, `card.sa.train`, `banner.snapshot`, `summon.draw`, `creator.import/export/library`, `upgrade.status/apply/edit` and `tournament.exclusive.library`. It validates root JSON object shape, allowed root fields, duplicate keys and byte budgets before calling the actual core, which validates detailed ownership/types/references and commits transactionally. Unknown operation names fail explicitly.

No client entry point exposes `inventory.grant`, `card.add`, `card.experience.grant`, `banner.configure`, `run.start`, `upgrade.policy.install`, `tournament.exclusive.register`, host paths or client assertions of resource readiness/rewards. Trusted native policy/content evaluators use the separate `od_bridge_execute_policy` / `executePolicy` methods with original fixed arguments retained across retries. Never select that capability from a WebView flag or forward arbitrary game/client arguments to it. Save export/import have separate host-only APIs whose paths must come from native UI/file selection; no JSON message can supply them.

Client `schedule.rotate`, `tournament.snapshot/enroll_run/record_run/claim` and `elder_kai.draw` omit all clock/score/config/reward fields. The bridge supplies the native system clock separately through `od_execute_clocked`; the core checks original arguments against the durable receipt before pinning the first clock in the same transaction. Retrying the same intent replays its first committed result even across a clock boundary. The bridge never adds a fresh time to persisted original arguments.

## Actual Creator project projection

`creator-project.js` reads the real `dokkan-unit-forge` v1 project, merges original card data with `cardOverrides`, preserves supported settings tables, and returns the exact settings-only definition format persisted by the core. `importProject(execute, project, host, profile, command)` calls the native core's `creator.import` operation; it is not a stand-in in-memory store.

The host must provide `contentId`, `sourceDatabase`, positive definition `version`, and declared `rarity`. Optional `definitionId` overrides the stable project patch UUID/key. UR maps to the existing card rarity 4; LR/SLR/GR map to 5, with SLR level 180 / GR level 200 as the current Creator UI defines. The core independently checks master-backed fully-awakened eligibility and definition validation.

Optional host-configured `creatorId` and `creatorName` preserve credit. Do not fabricate a creator identity or trust an arbitrary project author's account identity. Version/credit immutability is enforced by the core.

For card caps above level 150, projection pins `progression_policy: "creator-lr-extended-v1"`, the existing Creator extension defined in `unit-creator/v2/ui/core.js` (LR base curve then the existing 3.5% integer continuation). It does not invent an official game's curve or silently change an older stored definition.

`projectToOfficialUpgrade` handles the separate real Creator `project.awaken` channel. It requires the complete seven-step EZA or eight-step Super EZA growth graph with one common grow type, then derives the final caps/leader/passive from its terminal stage, preserving authored negative private skill-set IDs. `applyOfficialUpgrade` sends that document to the actual `upgrade.apply` operation for an owned instance. It never puts official upgrades in Creator sharing. The core independently validates source eligibility, complete routes/medals/references, fees, immutable source settings, progress consistency and editing rules. Enhanced policies require the native-only frozen-policy installer; arbitrary project JSON cannot supply Enhanced behavior.

Forms, custom assets (including packed/generated files), animation assignments, battle-pose bindings, runtime hooks and unsupported modified tables fail explicitly instead of being silently dropped. Baseline unsupported master-only metadata can be omitted only when a trusted `isUnchangedMasterRows(table, rows)` callback actually proves every row unchanged against the pinned master. Without that proof it rejects the project. This means some advanced projects remain blocked until their integration is implemented; no claim of full Creator/game feature parity is made.

The real-file CLI performs that baseline proof against a read-only standalone master and invokes this same JavaScript projection:

```sh
python3 offline-dokkan/adapter/project-file.py path/to/forge-project.json path/to/reference.db --database eclipse --rarity LR --version 1
```

Default output is the single overwritten, ignored `adapter/build/normalized-unit.json`, ready for the native hosts' **Import Offline Creator unit** file picker. The master SHA-256 pins `content_id` to the native host's `sha256:<digest>` format. Explicit `--creator-id/--creator-name` preserve trusted credit; `--official-upgrade` emits the separate upgrade document instead, for `upgrade.apply`. The command accepts no scripts, keys or SQL and never modifies the source database. It is a settings projection; the real core validates it again on import/apply.

Optional host `statPolicy` / CLI `--stat-policy` pins either `master-coefficient-linear-floor-v1` or `creator-cap-normalized-v1` into the authored document. These are explicit internal rules, not verified original-game rounding. No policy is silently invented during projection. `card.stats` accepts only an owned `instance_id`; the core supplies saved level and effective settings. Its base stats exclude bonuses and its separate final-exclusive descriptor must be applied once after other boosts by a future battle evaluator.

The Creator's explicit saved `project.statPolicy` is also preserved; a contradictory host policy fails instead of silently replacing it. `sourceStatGrowth` is a derivable Creator snapshot, never an authority over the content-pinned master used by the offline core.

`card.sa.train` is only **Guaranteed Kai SA training**: callers identify target/material owned instances and a host-installed Kai banner/version. The core derives all guaranteed roles and the effective SA cap, consumes distinct eligible teachers transactionally and retains provenance. Client quantity/chance/XP/Zeni or invented training rules are not accepted.

`card.potential.preview` is a read-only **Hidden Potential preview**, not an unlock operation. The client supplies an owned `instance_id` and may include `requests` (at most 512 `{node_id, selected_event_id}` entries) and `released_node_ids` (at most 4096 distinct IDs). Use `selected_event_id: 0` for an ordinary node and an actual allowed event ID from the source graph for a selection node. Omit/empty `requests` to inspect the graph alone. The core supplies same-profile, unconsumed ownership, effective source board and current Super Attack level. Client master/board IDs, level/SA, balances, prices or a commit flag are rejected; the argument budget is 256 KiB.

The response includes the resolved instance/master/level/SA, `graph`, and `plan` (`null` for graph-only reads). Released-node inputs describe a hypothetical preview, never trusted saved unlock state: `released_state_is_hypothetical: true` and `owned_potential_state_verified: false`. `potential_locked` preserves authored metadata; `null` for an ordinary source does not claim that Hidden Potential is unlocked.

Source adjacency/selection events, raw Potential Orb costs and explicit SA requirements do not establish route/duplicate/level eligibility or a spend/reset policy. Inspect `orb_balance_verified` and `missing_policy`; when balances are unverified, plan `materials_satisfied` and each cost's `available`/`shortfall` are `null`, not invented zero balances. Even satisfied source facts never authorize spending: every response/plan remains `can_commit: false`. Native callers must not turn the preview into an unlock action or game HTTP payload. No player revision, command receipt, materials or unlock state changes.

`card.training.preview` accepts only an owned `instance_id`, one to 128 distinct `items` (`{item_id,quantity}` positive integers), and optional `field_id` (zero means no selected field). The core supplies saved level/SA, effective cap, recorded EXP or its honest partial range, actual training-item balance and raw selected-field facts. Client EXP, level, inventory, Zeni, chance or cap overrides are rejected. This reports source base EXP/Zeni subtotals and inventory deficits; unknown Zeni/bonuses/final outcome remain explicit, missing curves remain unavailable, and `can_commit: false` authorizes no consumption or EXP grant. This is separate from guaranteed Kai SA training.

## iPhone and Android hosts

- `ios/ODNativeCore.h/.m` is a Foundation host with serial background work, lazy off-main SQLite open, and main-queue replies for our Creator UI. It receives trusted file URLs at construction. It is not a swizzle of the original game's completion callback.
- `android/com/personal/offlinedokkan/OfflineCore.java` is an `AutoCloseable` serialized native host API; `android/od_jni.c` calls the same C bridge. It converts real UTF-8 byte arrays instead of JNI modified UTF-8, preserving supplementary characters in unit names. Handles and paths must remain private to native code, not arbitrary WebView messages.
- Actual native app hosts/build targets are under `../mobile/`. Android must link the pinned public SQLite amalgamation, not Android's private SQLite system library. The Linux Makefile uses system SQLite only for cloud development.

`make check` compiles JNI/C with warnings as errors and Java 8 API compatibility using the pinned development JDK. One combined synthetic scenario exercises JS project projection → Java/JNI → real C/SQLite, exact UTF-8/settings round trip, restart persistence, player-only export/import, trusted-operation rejection, native policy grants, client card locking, clock/score injection rejection, official growth projection, closed handles and unchanged master bytes. iPhone wrapper compilation/device behavior and Android NDK packaging/device behavior are separate checks; do not call the Linux JNI pass an installed mobile application.

The final schema7 combined JNI scenario passed, including actual native-only Kai policy → ordinary guaranteed SA feeding, reordered-object command replay and same-version Creator sharing. A separate actual-file batch also loaded real templates through the existing `Forge.loadTemplate` from both restored Eclipse/Sparking masters, projected settings through this CLI and exactly round-tripped them through JNI/core import/export, restart and player-save import. Owned source stats returned explicit internal-policy provenance; both master hashes stayed unchanged. Those temporary source-backed fixtures/backups were removed, and no game data was committed.
