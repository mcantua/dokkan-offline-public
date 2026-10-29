# Offline domain/save core

`od_core.h` is a portable C interface to our own SQLite player save. It has **no networking, game hooks or fabricated game HTTP responses**. The original-client adapter and native Creator use this trusted data API; its standalone behavior does not establish actual original-client wire compatibility, gameplay or presentation.

Build on Linux with `make all`; `make check` runs one combined integrity scenario harness against small synthetic masters. `make check-summons` checks only persisted summons, retention and migration. The local SQLite header is downloaded separately under ignored `downloads/sqlite-header/`; provenance is recorded there. iOS uses the SDK's SQLite interface/library and Security framework. The CLI and shared library are disposable `build/` outputs.

Runtime requires SQLite **3.38 or newer with JSON support** (`STRICT` tables and the JSON `->` operator are used). A successful arm64 iOS object compile does not establish runtime SQL compatibility. Production Android must bundle a suitable public SQLite implementation; older Android system SQLite versions and the non-public system library must not be assumed compatible or linked through unsupported NDK interfaces. The current Linux harness links the available system SQLite 3.40 runtime only for cloud development.

```text
od-cli SAVE MASTER CONTENT PROFILE OPERATION COMMAND JSON
```

`CONTENT` identifies the exact imported master snapshot (the importer should supply its verified SHA-256). Masters open read-only and cannot be the same physical file as the mutable save. Player data binds to this content ID, schema version 13 and the exact save schema. Valid version1–12 saves migrate transactionally; importing an older save upgrades a transient candidate without modifying its source. The frozen migration fixture is our own schema, not game data. New profiles have zero inventory/cards. With a supported source `rank_statuses` table, our explicit `offline-rank1-act-v1` bootstrap initializes rank1/EXP0 and its exact ACT capacity (20 in both supplied masters). This is our own start policy, not a claimed verified original login. Older balances are preserved; masters without rank data retain the legacy trusted bootstrap behavior.

Internal operations:

| Operation | Arguments |
|---|---|
| `profile.create` | `{}` through the native trusted-clock bridge; initial ACT derives from source rank1. Internal trusted fixture callers retain explicit `initial_stamina` support |
| `profile.refresh` | `{}` with a command ID through the trusted-clock bridge; recover elapsed ACT without changing inventory/cards |
| `profile.snapshot` | `{}`; no command ID needed |
| `inventory.grant` | `source`, `rewards:[{kind,id,quantity}]`; **trusted reward evaluator only**, never client-claimed awards |
| `card.lock` | `instance_id`, JSON boolean `locked`; player-instance lock only |
| `card.experience.grant` | Trusted `source`, `instance_id`, positive integer `quantity`; exact imported EXP curve, described below |
| `card.add` | `master_id`; grants one owned instance at level 1, SA level 1, empty Hidden Potential state |
| `team.set` | `slot` 0–19, `members` array of up to six distinct owned-instance IDs from this profile |
| `run.start` | `run_id`, `map_id`, `team_slot`, `assets_ready:true`, `rewards` resolved by the trusted local evaluator before start |
| `run.finish` | `run_id`, `outcome:"clear"` or `"failed"`; does not accept replacement rewards |
| `banner.configure` | Trusted immutable versioned pool/configuration, described below |
| `banner.snapshot` | `banner_id`; read-only active pool/policy/main feature/pity state |
| `creator.import` | `{definition: document}`; strict settings-only definition described below |
| `creator.export` | `definition_id`, optional `version`; read-only exact sharing document |
| `creator.library` | `{}`; active identities/versions, newest-five FIFO and main epoch |
| `summon.draw` | Only `banner_id` and `kind:"single"` or `"multi"`; configuration is loaded from storage |

Reward categories are our own strings: `stone` uses ID 0; `medal`, `training`, `support`, `equipment`, `act` and `potential` validate IDs against their corresponding imported master tables. The policy module applies 10× Dragon Stones, 6× medals and 3× other supported items exactly once. Unsupported categories fail explicitly; XP/Zeni semantics are not guessed. Positive integer base quantities and checked totals are required; JSON booleans do not count as integers.

Mutations require a stable per-intent command ID. Identical command retries return the stored response; changing arguments for the same ID rejects the command. Reward-source IDs prevent a second grant under another command. Run settlements have a separate namespace, retain the original committed result and cannot advance revision or award twice. Profile state, entry debit, rewards, quest clear state and command results commit in one transaction with `synchronous=FULL`. This API must be called serially per core instance.

## Original-client tutorial and team storage

Schema13 adds native tutorial checkpoints and persistent original-team metadata.
Only an actually inserted new profile receives tutorial progress0 and
is_finished=false, matching the original TitleLoadingLayer's start-sequence
control flow. This is our source-compatible fresh policy, not a claim about
the original Sparking server's exact defaults. Older profiles migrate without a tutorial row and remain an
explicit recovery/policy gap. No unit, item, capacity, contents level, reward or
tutorial-finished grant is created. The original tutorial remains responsible
for its actual scripted scenes and temporary combat.

`od_original_client_apply` is a separate native-only entry. Its normalized
operations are `tutorial.progress` and `teams.apply`; their internal command
names are refused by ordinary `od_execute`/WebView paths. It checks the current
save/profile/content scope inside the same transaction before any command
replay, then checks the expected profile revision for a new command. Identical
command retries retain their committed result. Tutorial writes store a positive
signed32 checkpoint, without interpreting it as a raw master ID, completion,
reward or clock. A repeated unchanged checkpoint need not advance revision.

Original team numbers are opaque positive keys with an explicit persistent
Core-slot association. Exact names/BGM and all six card positions are retained;
every nonzero member must be owned and unconsumed. A new observed number takes
the lowest free Core slot; an existing number retains its slot. Unlisted teams
and omitted selections are preserved. No initial team/selection is invented.
Complete observed team references retain signed32 map/stage/card fields;
unknown references remain null. The three observed UInt32 advisory context
fields are metadata only and never grant quest progress, items or units.
Omitted/null references and omitted context retain prior metadata.
Generic compact `team.set` edits that conflict with a bound formation roll
back, preserving an openable save and its original six positions.

`od_offline_player_snapshot` adds `original_client_tutorial` and
`original_client_teams` from the actual canonical transaction. Native bridge
writes reject while Creator holds its lease; they return a current after-commit
player snapshot/admission separately from the retained command receipt. The
fresh-state gate uses only this native tutorial record and keeps contents level
and storage limits unresolved. HTTP response/codec gates remain closed.

One combined extracted-SQL/actual-JavaScript scenario is recorded in
`original-player-state-evidence.json`. It verifies migration rollback, preserved
legacy state, checkpoint SQL and actual projection of gapped formations. It
does **not** execute C command/scope control flow, Objective-C, an original game
or a build. Existing unrelated suites were not repeated.
The one subsequent changed-metadata-only SQL-to-JavaScript-to-SQL check is in
`original-team-metadata-evidence.json`; it reuses the first migration evidence
and verifies typed references/context, preservation and the actual GET/POST
candidate normalizer. Both receipts pin their source at verification time.

Keep at most the last 128 full command responses and 128 full run responses per profile. Older results become a JSON-null tombstone, while command IDs, original inputs, settled outcome and reward ledger remain. An old command retry returns `COMMAND_RESULT_EXPIRED`; an old run retry returns `RUN_RESULT_EXPIRED`. Neither re-executes, rolls RNG, grants, debits or advances revision. The caller can query the current snapshot. This bounds historical full-snapshot growth while preserving exactly-once behavior; original command input history is retained.

## Persisted banner and summon transactions

`banner.configure` takes this explicit internal model:

```json
{
  "banner_id": "chosen-stable-id",
  "version": 1,
  "epoch": 1,
  "main_id": "definition-id-from-pool",
  "policy": {"lr_ppm": 10000, "slr_ppm": 1000, "gr_ppm": 100, "multi_count": 10},
  "pool": [
    {"definition_id": "stable-definition-id", "master_id": 123, "rarity": "UR", "weight_ppm": 500}
  ]
}
```

This is a structural example, **not a valid complete pool**: the caller must supply every eligible definition and all weights. No lower-rarity/featured allocation or multi count is guessed. Integer weights must sum to one million and match the explicitly configured LR/SLR/GR totals; definitions must be unique, positive-weight and reference real master cards. The supported pool limit is the policy engine's 65,536 entries, with a 16 MiB `banner.configure` input budget. `creator.import` also has a 16 MiB settings-document budget; other operations remain capped at 1 MiB. Oversized input fails explicitly.

Rarity names here are our **declared internal probability categories**, not evidence of a game's wire enum or a transformed custom card. An entry without `definition_version` resolves to the original master. A created entry includes the exact immutable `definition_version`; its full validated settings resolve through the overlay described below. Declaring `GR` alone never transforms an original card. The game rendering/battle adapter still needs to consume the effective settings and exclusive flags.

Configuration versions and their entry catalogs are immutable. An existing definition identity cannot silently change its master mapping/category. A newer version may change explicit weights but cannot change the main-feature epoch unless the main identity changes; a new main must advance the epoch. The old version remains for provenance of previously granted cards. Each owned draw stores its resolved definition ID and banner version in `card_sources`.

`summon.draw` loads the saved active configuration, stone balance and pity inside its transaction. Production uses Linux `getrandom`, Apple `SecRandomCopyBytes`, or a full-read `/dev/urandom` fallback on other supported POSIX systems. It then debits exactly 5/50 stones, grants the resolved master-backed owned cards at level 1 / SA level 1 / empty Hidden Potential, saves pity and the immutable command result together. A failed transaction changes none of these; a retry never draws again. The pure policy engine applies GR/SLR/LR/UR multi pity at 50/25/10/5 and resets on a main pull or a new main epoch. Pool injection at draw time is rejected.

The focused store scenario verified durable debit/grants/pity/replay across restart, multi-50 main-feature settlement, immutable configuration, main reset, insufficient-funds/ad-hoc-pool rejection, source provenance, response tombstones, and both v1 open/import migration. A fixture correction removed an invalid zero-weight pool; the production RNG was never replaced by a deterministic test generator. The retention check uses synthetic historical rows and never claims to have played real battles.

Runs check imported map/quest references, the previous quest clear, a nonempty saved team, explicit local asset readiness and master `act` entry cost against stamina. The saved team roster and reward plan remain pinned for the run. A failed outcome settles without grants. Missing asset readiness, locked prerequisites, insufficient stamina or conflicting outcomes fail locally. The real asset resolver, board/battle serializer, rank/stamina regeneration, all game-specific unlock conditions and authoritative master reward evaluator are still integration work; the `rewards`/`assets_ready` arguments are trusted core inputs, **not verification that the game client may choose its own rewards**.

`od_export_save` uses SQLite's backup API to create a consistent player-only database, protected with mode 0600 and atomically published without replacing an existing unrelated file. `od_import_save` reads one stable source snapshot and rejects incompatible schema/content, injected triggers, integrity/foreign-key errors, invalid team references and owned levels beyond master caps. The backup API applies the accepted source to the active player database transactionally; failed validation leaves the active save intact. No master data, assets, keys, account credentials or backup history is exported. Export destination and import source are trusted host paths, not accepted from game request bodies.

Export and import currently share a 256 MiB file budget. Export checks the completed
SQLite snapshot's page count/size and its final file before reporting success;
an oversized candidate returns `SAVE_EXPORT_TOO_LARGE`. Only the newly created
candidate is removed on refusal, while canonical state and existing backups
remain intact. This does not cap live-save mutations. Large valid saves,
including retained full-Creator histories, still need a streaming restore path
before their backups are supported; this guard prevents an unrestorable export
from appearing successful and does not establish full save acceptance.

The focused suite passed five grouped scenarios: restart/idempotency; multiplier and atomic rejection; owned-card/team constraints; entry costs/content gating/immutable settlement; consistent save export/import with hostile/incompatible/team/level rejection. A first base pass was followed by one integrity-focused pass after review found type/replay/import gaps. Builds use warnings as errors. Cross-compilation/device execution is a separate check.

The independent `summons.h/.c` and `progression.h/.c` modules implement policy planning; banners and draws are now persisted as above. Created-definition settings are persisted and resolved into owned snapshots; general training/equipment mechanics and the game request adapter remain separate work. Do not label this a complete offline game server.

## Creator definition overlay and sharing

Save schema v3 adds immutable settings documents, active versions, first-import order/main epoch, exact banner-version bindings and owned-definition provenance. V1/v2 open and player-save import migrate to v3; source imports remain unchanged. Imported masters are never edited. `make check-creator` is one focused overlay/share/summon/migration scenario; it does not rerun earlier suites.

`creator.import` receives `{ "definition": DOCUMENT }`. `creator.export` returns that exact document, suitable for another profile with the same pinned content. No account, art, source files, scripts, executable SQL or keys are part of the format:

```json
{
  "format": "offline-dokkan-definition",
  "schema_version": 1,
  "definition_id": "stable-creator-project-key",
  "version": 1,
  "source": {"content_id": "verified-master-content-id", "master_id": 123},
  "rarity": "GR",
  "fully_awakened": true,
  "creator": {"id": "tin-owner", "name": "Tin"},
  "progression_policy": "creator-lr-extended-v1",
  "card": {},
  "tables": {}
}
```

The empty card above is structural only: supply the complete effective Creator card (`tables.cards[0]` merged with `cardOverrides`). Its ID remains the real source master ID inside this isolated definition namespace. Its nonnull master-shaped fields, maximum/initial HP/ATK/DEF, level/SA caps, numeric class/type, source rarity, leader/passive references and every supplied column/type are checked against the pinned master schema. Normal outgoing Z/Dokkan awakening routes reject an unawakened source. UR uses source card rarity 4, and LR/SLR/GR use source card rarity 5; these follow Creator's existing mapping, while SLR/GR are our extra declared categories. The maximum scalar stat/cap budget is signed 32-bit, an internal safe serialization bound, not an invented official stat limit.

`tables` accepts only settings rows for leader/passive/special/active/standby/finish skills and sets/relations, categories, Link Skills and Domains. The exact whitelist lives in `definition_table`. Each row is scalar, master-schema typed, has a distinct nonzero integer ID within its table and complete nonnull fields. Known references must resolve within this definition or its source master. Negative private row IDs are preserved within the definition namespace. Nested objects, unknown columns/tables, duplicate JSON keys, unresolved known references and resource/script/SQL containers fail. Efficacy/condition strings retain their original game syntax; saving these settings does not prove every embedded effect is supported by a future battle adapter. The separate Creator bridge rejects unsupported forms/awakening/art/action hooks rather than discarding them.

Same identity/version with the same normalized document deduplicates without advancing save revision; changed settings at that version fail. An update requires a strictly greater version, keeps the original master/category binding, updates owned effective settings while preserving progression, and retains the immutable original grant version. Caps cannot invalidate owned progress. Updating a definition used by a started run fails with `DEFINITION_IN_USE` so the running kit cannot change. Old definitions remain exportable by version.

First imports enter a persistent FIFO: `creator.library.featured` returns newest first, at most five, and `main_id` is the newest. Updating an existing identity does not reorder it or reset the main. Each new identity advances the Creator main epoch. A banner using created entries must pin `creator_epoch`, use that exact current main/epoch and bind each created entry to its active version. Changed definitions or a newer main make the prior banner `CREATED_BANNER_STALE` until the trusted catalog provides its next explicit complete weighted configuration. Main reconfiguration advances the banner epoch and resets pity. No unknown featured/lower-rarity weight allocation is invented.

Created summon grants start at level 1 / SA level 1, Hidden Potential locked and no add-ons. The configured maximum stats and complete skill settings stay in the definition; SLR/GR preserve always-on Super/Godly exclusive flags from the portable policy. These flags are returned as internal typed state, not fabricated game-wire objects. The focused scenario covers durable sharing/update/origin versions, defaults, source/type rejection, FIFO/main epoch, stale configuration, hostile save rejection and v1/v2 migration. Two implementation defects found during this scenario (a missing duplicate-import revision and a numbered bind collision) were corrected before its passing run.

## Earned card EXP and locks

Schema v4 persists per-owned-card EXP and lock state. Old cards without recorded EXP expose `experience:null`: the first trusted EXP grant establishes the exact imported threshold of their existing level; no unknown partial progress is invented. `card.lock` stores a real boolean selection and preserves earned EXP. Snapshots expose both fields; the lock will be enforced by future card-consumption operations.

`card.experience.grant` is a trusted earned-EXP evaluator operation, not permission for game request bodies to choose EXP. It accepts `instance_id`, stable `source` and positive integer `quantity`. It resolves the source/effective definition's `exp_type` and level cap, validates a complete strictly increasing `card_exps(lv,exp_type,exp_total)` curve beginning at zero, adds EXP with checked arithmetic and sets the exact resulting level. Curves exceeding 10,000 rows fail as an explicit import budget. Missing curves fail `EXPERIENCE_CURVE_UNAVAILABLE`; unsupported formulas are never interpolated. EXP does not receive the item/medal/stone multipliers.

The trusted evaluator must resolve capped earnings before calling: an amount beyond the maximum level's threshold fails `EXPERIENCE_CAP_EXCEEDED`, rather than silently discarding earned EXP. The card, source ledger, revised level/EXP and command outcome commit together. Same-source retries cannot add EXP again. Cross-profile targets and changes to a started run's team fail locally. Definition updates must also preserve consistency with recorded EXP and cannot change an in-use kit. Import rechecks EXP against the exact master/effective curve and rejects a level/EXP mismatch before replacing the active save.

`make check-experience` passed one focused scenario for curve thresholds, positive/type/overflow checks, stable source replay, ownership, locks, started-run protection, hostile EXP-save rejection and v3 migration/import. Earlier base/Creator/summon suites were not repeated for this independent change.

This is real persisted owned-card progression, but not a claim of the complete training mechanic. The supplied master establishes training-item base EXP and Zeni cost; its descriptions say “or more”. Matching-type bonuses, success chances, training-field modifiers, general material-card consumption and SA upgrade probability still need verified policy before a training transaction can safely charge resources. Equipment master grades/condition records are present, while slot unlock/restriction combination/replacement rules also need verification. The core does not fabricate those rules from column names.

## Persisted local schedules, tournaments and weekend material summons

Schema v5 includes `schedules_store.h/.c` in the same player database and transaction. Every operation below requires a stable command ID; clocks/catalogs/configuration come from the trusted host, not arbitrary game bodies. The module never commits independently. The core provides OS secure randomness and final-quantity credits; rank payouts have already received 3×/6×/10× and must not be multiplied again.

| Internal operation | Arguments and behavior |
|---|---|
| `schedule.catalog.install` | Immutable `catalog_id`, explicit `zone` (0 UTC, 1 Chicago policy), `history:[{banner_id,version,first_open_utc,verified_official,usable_local_content}]`; every banner version must already exist locally |
| `schedule.rotate` | `catalog_id`, trusted `now_utc`; two distinct eligible historical banners from the last nine calendar months, persisted for the week without a launch reroll |
| `tournament.configure` | Immutable `tournament_id`, `version`, `zone`, 16-character hex `seed`, explicit `tie_policy`, competitor paces, verified map→points policy and rank reward tiers |
| `tournament.snapshot` | `tournament_id`, `version`, trusted `now_utc`; persists deterministic simulated AI catch-up during the active weekend |
| `tournament.enroll_run` | Same plus `run_id`; pins a same-profile started run/map to the active weekend before completion |
| `tournament.record_run` | Same plus `run_id`; only that enrolled run's persisted clear can earn its pinned points once; arbitrary client scores and historical completed runs are not accepted |
| `tournament.claim` | `tournament_id`, `version`, `weekend_id`, trusted `now_utc`; requires the weekend to have ended, settles final rank and all rewards atomically, retains one exact receipt across retries/later commands |
| `elder_kai.configure` | Immutable `banner_id`, `version`, `zone`, explicit `multi_count` and pool of verified material master IDs, each granting exactly one SA level with explicit weights |
| `elder_kai.draw` | `banner_id`, `version`, trusted `now_utc`, `kind`; weekend-only OS-random material-card grants, exact 5/50-stone debit and immutable command replay |

Example tournament configuration uses `competitors:[{id,points_per_hour,extra_points_per_hour_max}]`, `maps:[{map_id,points}]`, `reward_tiers:[{from_rank,to_rank,rewards:[{kind,id,quantity}]}]`. `tie_policy:0` shares ranks; `1` puts the player after equal scores. These are explicit local game policies, not a claimed official ranking algorithm. There is no invented default official banner history, tournament scoring map, reward table or Elder Kai identity. Missing verified configuration fails explicitly.

Import checks reconstruct rotation eligibility and calendar period, exact tournament boundaries/configuration, the configured competitor set and deterministic AI state at its saved time, enrolled map/point policy, player total from credited runs and the original claimed receipt. Corrupt state cannot silently become a fresh payout. Core import also checks every saved run roster's integer/unique/same-profile owned references and content binding, and validates all inventory kinds/IDs against the read-only master.

The integrated store scenario checks durable rotations/replay, run enrollment/clear scoring, deterministic catch-up/restart, weekend material draws/debits/replay, rank reward multipliers once, partial-credit/clock rollback on wallet overflow, old claim receipt replay after later mutations, hostile save rejection and source-preserving v4 migration. Source/schema development checks are separate from actual game-client/device execution.

## Definition response size, attribution and extended levels

Owned cards reference their effective created identity/version and immutable original grant version. A snapshot's top-level `created_definitions` array carries each effective referenced document once, so duplicate owned copies do not repeat a large skill graph. `creator.export` still returns the complete original settings document for sharing.

New exports can preserve `creator:{id,name}` (for example Tin) as bounded attribution. Established credit is immutable across later versions and sharing; older saves without credit remain unknown until their author adds it in a new version. This local attribution is not an online account assertion. Additional allowed settings tables cover Creator's causalities, sub-target types and transformation descriptions. Typed known references, unique Link Skills and JSON-encoded efficacy/conditions are checked before persistence. Unsupported modified forms/runtime/art data still fail explicitly.

SLR and GR preserve Creator's existing level180/200 tier identity. Their bonus metadata describes the authored always-on effect: a game adapter must not add another copy if the authored passive already implements it. High-level settings may explicitly pin `progression_policy:"creator-lr-extended-v1"`, the existing policy in Unit Creator `core.js`'s `extendLevels`: selected master LR EXP curve (type25, levels1–150), followed by integer-rounded per-level increments growing by3.5% through200. The supplied snapshot's first150 entries match Creator's existing curve, and the recurrence reproduces its50 extended totals exactly; no new master data is copied into this repository. This enables persisted created-card EXP up to its configured180/200 cap while keeping maxima/skills unchanged. A legacy high-cap definition without the tag retains its settings but cannot earn EXP until a newer version explicitly pins the policy. Current-stat/battle calculation remains the native engine adapter's separate responsibility.

## Official Custom EZA / Custom Super EZA / Enhanced channel

Schema v6 keeps official modifications outside the shareable Creator catalog. `upgrade.status {instance_id}` resolves the actual owned source and reports official EZA/Super EZA, prior custom flags and fixed prices. Source eligibility follows existing Creator `card-versions.js`: an Optimal step1 route or positive optimal growth type establishes EZA; Optimal type2/step8 or growthstep8 establishes Super EZA. Normal forward Z/Dokkan routes still reject unfinished sources. Created and tournament-exclusive owned instances cannot use this official channel.

`upgrade.apply` receives `instance_id`, `kind:"custom_eza"` or `"custom_super_eza"`, and `definition`. The settings document format is:

```json
{
  "format": "offline-dokkan-official-upgrade",
  "schema_version": 1,
  "version": 1,
  "source": {"content_id": "verified-master-content-id", "master_id": 123},
  "kind": "custom_eza",
  "card": {},
  "tables": {}
}
```

Empty card/tables are structural only. The Creator awakening bridge projects the complete source card with terminal stage7/8 level/SA/leader/passive fields, and the structured skill/growth/medal-route rows. The core validates exact source identity, schema/types/references, contiguous stages1–7/8, a matching self-targeting Optimal route per stage, real medal set references and terminal caps/skills matching the effective card. Negative private skill IDs remain isolated and supported. No SQL, artwork, files or keys are accepted. Source identity/resource fields cannot be replaced. A paid change must alter actual caps/stats or skill mechanics; names/descriptions/row IDs are removed from the mechanics comparison, so a label-only change cannot charge stones.

Custom EZA costs500 and Custom Super EZA costs700 Dragon Stones. The profile's official-definition overlay applies to its ordinary owned copies of that master and future ordinary grants; progression/locks remain per owned instance. The source master is read-only. Active-run mutation, incompatible recorded EXP/level/SA, insufficient stones, source mismatch or failed persistence rolls back the whole debit/overlay/revision/outcome transaction. Previous graph versions remain immutable. `upgrade.edit` takes the same arguments with a newer document revision and edits an already applied custom upgrade without charging again. A Custom Super EZA cannot be downgraded through the EZA channel.

Enhanced is a separate trusted generated-policy application, not an invented automatic meta-strength formula. Only the native policy service may call `upgrade.policy.install {definition}` with an `enhanced` settings document, additional stable `policy_id` and positive `policy_version`. Policy/source/version documents are immutable. Ordinary application is only `upgrade.apply {instance_id,kind:"enhanced",policy_id,policy_version}` and loads that stored graph; supplying a replacement document fails. The source must already have official EZA/Super EZA. A new explicitly selected higher policy costs300 stones; the same/older policy cannot charge again. Every installed policy must carry a real validated settings transformation before application. There is no shipped “today's meta” generator unless a verified generator is provided separately. Enhanced cards reject manual edits, including attempts to hand-edit them through Custom Super EZA. This prevents a settings file from bypassing the generated-policy channel.

Owned snapshots expose official labels/flags/version and one `official_upgrades` settings entry per effective definition. These are internal domain values, not evidence of animated card banners or working game-client serialization. Save import reconstructs upgrade eligibility/cost/history, active versions and generated-policy bindings before applying the file. Registry data is a local save format, not authenticated online identity or an anti-cheat system.

## Ordinary host-clock intents and tournament-exclusive definitions

`od_execute_clocked(core,op,profile,command,original_args_json,host_now_utc,out)` is the client-intent entrypoint for schedule rotation, tournament snapshot/enrollment/record/claim and weekend material draws. It accepts only each operation's ID/version/run/kind fields, rejects caller clocks/config/rewards/scores, and compares/replays the ORIGINAL input inside the transaction before injecting the trusted host clock for a new execution. The command cache stores original intent, result, revision and pinned execution clock together. Retrying the same UUID on another day cannot change the command input, reroll, debit again or hit `COMMAND_CONFLICT` merely because time moved. Explicit-clock `od_execute` remains available only to trusted policy/evaluator services.

Tournament reward definitions live in a separate immutable registry and reserve `tournament-exclusive:` identities. A native-authored definition uses the ordinary strict settings document, explicit source and creator credit, but never enters Created units, ordinary banner pools or their sharing/export channel. The reserved namespace is rejected even in another fresh profile without that registry entry. A rank tier explicitly identifies its definition/version and multiplier category; successful ended-period claim grants actual level1/SA1 instances, locked Hidden Potential/no add-ons, exact authored maxima/skills and immutable claim/ordinal provenance. No ordinary official master is mislabeled as an exclusive reward. Claimed copies resolve their own pinned settings/EXP cap independently of any official overlay on the same source master. Registry and grant API details are in `SCHEDULES-STORE.md`.

`make check-upgrades` passed one combined new-batch scenario covering verified status, full awakening graphs, fixed prices and free custom edits, immutable generated policies/manual restrictions, replay and post-debit rollback, in-run protection, original-input clock retries, actual exclusive rank grants/provenance/EXP, hostile upgrade/registry save rejection and source-preserving v5 migration. Compiler warnings are errors. Two defects found in the new paths (late named/numbered bind overlap and eligibility checked after no-change detection) were corrected; only this affected scenario was repeated. Earlier suites were not repeated. SQL helpers now reserve named slots before numbered payloads, independent of clause order.

## Owned-card base stat queries

`card.stats {instance_id}` is read-only and resolves the same profile's actual persisted level plus the effective original/Created/tournament-exclusive/official-upgrade document. The caller cannot choose a level, master, curve, result or policy. It returns HP/ATK/DEF, exact coefficient numerator/denominator, source curve metadata and policy labels; it does not advance revision or grant resources.

The two explicit internal policies are `master-coefficient-linear-floor-v1` and `creator-cap-normalized-v1`. Both use the selected read-only master `card_growths`; neither claims verified original-game rounding. The master policy uses only an available coefficient and integer-floor composition. Missing/out-of-range coefficients fail instead of extrapolating. Normalized Creator growth is our approved model: its settings document must explicitly pin `stat_policy:"creator-cap-normalized-v1"`; it rescales the selected complete source curve to that declared cap and preserves configured initial/max endpoints, including180/200. No existing definition silently receives normalized growth. The native settings projection/author tool must make its choice explicit.

A present stat policy cannot change or disappear in a later same-identity revision; older documents without it may pin it once in a new revision. Export/sharing and the separate official/exclusive registries preserve the property and import validates its history. This requires no new save tables/schema version. Current unsupported Hidden Potential/add-on states on locked created/exclusive copies are rejected until real board/add-on transactions exist.

Base stats exclude leader/passive/Hidden Potential/equipment/exclusive boosts. `final_exclusive` reports the authored SLR10% or GR20% descriptor separately, always on, excluded from base. A future combat adapter must apply the authored effect once and must not duplicate rows already present in the passive. The result labels `internal_policy:true` and `original_game_rounding_verified:false` make that scope explicit.

`make check-stats` runs the helper's focused arithmetic/curve/precision/overflow fixture, including initial/mid/max and180/200. `make check-stats-store` checks only core ownership, actual saved level, no client level injection/no revision, resolved authored GR maxima after real summon/EXP, policy immutability/sharing and hostile locked-potential import. Each passed independently; older suites were not repeated. The integration fixture's initially invalid one-slot multi configuration was corrected to the existing minimum of two; production summon policy was unchanged.


## Guaranteed Elder Kai Super Attack training (schema 7)

`card.sa.train` accepts exactly `target_instance_id`, `material_instance_ids`, `kai_banner_id` and `kai_banner_version`. The native host must first install a verified immutable `elder_kai.configure` policy for that profile. Every material must be an owned ordinary master-backed card listed in that policy with `verified_elder_kai:true` and `super_attack_levels:1`. This operation is **guaranteed Kai training only**, not the complete training system: no name matching, inferred chances, guessed type/field bonuses, Zeni charges or EXP rewards.

Each distinct material grants exactly +1 Super Attack level. The whole intent rejects excess materials beyond the target's actual effective cap; it never spends a partial batch. Created, tournament-exclusive and official-upgraded targets resolve their retained settings. The receipt pins the exact immutable definition channel/version and cap used at settlement. Materials reject self-feeding, foreign ownership, prior consumption, player locks, saved teams, active runs and authored/official-overlay modifications. Targets in an active run cannot change.

The core writes the target's original SA baseline, ordered training event, material-consumption tombstones, SA increase, revision and stable command result in one transaction. Consumption hides owned instances from the active box and blocks subsequent use, while retaining physical rows, immutable summon/tournament provenance and historical finished-run team snapshots. IDs are never reused. Save validation reconstructs SA history, command intent/receipt, role policy, material ordinals, pinned caps and consumption chronology, and rejects spent instances in current teams/active runs. Schema 1–6 migration preserves pre-existing SA levels; importing an older save does not change its source file.

Immutable documents, policy/config documents, fixed reward sources and stable command intents compare JSON semantically: object key order is ignored, array order and boolean/string distinctions remain meaningful, and equal numeric values such as 1 and 1.0 compare equally. Duplicate object keys and NUL-containing keys/strings are rejected at command input. This supports real iPhone dictionary serialization without permitting changed intents to replay.

`make check-kai` is one combined focused scenario covering exact +1/effective caps, role/ownership/lock/team/run guards, a forced mid-write database failure and same-ID retry, historical tombstones, later Created cap revisions, reordered documents/intents, hostile save changes and v6 migration. Existing unaffected suites were not repeated for this batch.


## Read-only owned Hidden Potential preview

`card.potential.preview` accepts `instance_id` and optional `requests` and `released_node_ids`. Each request has exactly two integer fields: `node_id` (>0) and `selected_event_id` (0 for a non-selection node, otherwise an actual choice from that node). Requests are distinct and bounded to 512; released IDs are distinct and bounded to 4096. All nodes must belong to the resolved board. Empty/omitted requests return the graph alone. Callers cannot supply a master ID, board ID, SA level, orb inventory or eligibility roots.

The operation resolves an actual same-profile, unconsumed owned card, current level/SA and its effective retained settings before loading the source master board. The response includes `graph` (source adjacency, locked-route metadata, events, choices, raw orb costs and explicit minimum SA) and optional `plan` (selected effects, aggregate raw costs and actual-SA comparison). It preserves the master's cyclic adjacency without inventing an activation rule. `potential_locked` reports the pinned authored/exclusive lock when one exists; ordinary-card lock eligibility is unknown (`null`).

Released-node state remains hypothetical: `released_state_is_hypothetical:true`, `owned_potential_state_verified:false` and `can_commit:false`. Orb balances are authoritative within this profile: `orb_balance_verified:true`; plan `materials_satisfied` and each cost's `available` and `shortfall` use the actual stored Orb inventory. `missing_policy` still names owned eligibility, graph activation, duplicate-route unlock and owned board state. The operation never unlocks a node, consumes duplicates/items, changes revision, stores a command or changes schema 7.

`make check-potential-store` runs one targeted scenario against the ignored supplied Eclipse and Sparking masters, selecting owned source records dynamically without embedding extracted records in Git. It checks actual/effective boards, source choices/costs/SA, rejected foreign/type/duplicate arguments, advisory labels and unchanged saves/revisions. It does not repeat the earlier core7 checks or build native packages.


`potential` is an internal inventory category for Hidden Potential Orbs, with each ID validated against the read-only master's actual `potential_items.id`. Its table has scalar name/description/rarity/exclusivity metadata; no numeric wire enum or unlock rule is inferred. Only native-trusted `inventory.grant` can credit this category. General run rewards and client-selected preview inputs cannot credit it. Reward quantities receive the existing 3× item multiplier once, atomically with the source ledger and stable command outcome; balances are never multiplied again at preview, replay, import or migration.

Existing STRICT inventory storage already supports validated category strings, checked nonnegative quantities and source IDs, so this vocabulary addition changes no tables or schema version. Snapshots and exports retain real balances; import rejects absent-master Orb IDs. The focused supplied-master scenario verifies 3× credit, same-ID and fixed-source replay, mixed-invalid-grant rollback, actual insufficiency/sufficiency, cross-profile binding, hostile import and unchanged-source v6 migration preserving exact balances. Node unlock remains unavailable.

## Read-only owned Training preview

`card.training.preview` accepts exactly `instance_id`, `items` and optional `field_id`. Items are 1–128 distinct objects with exactly positive integer `item_id` and `quantity`; a zero/omitted field selects no Training Location. The core binds the same-profile unconsumed owned card, current level/SA, effective retained cap/settings, actual stored training-item balances and recorded EXP. Clients cannot provide these values, Zeni, master identity or results.

The response reports exact source base EXP and item Zeni subtotals, selected field metadata, actual item availability/shortfalls, and a **base-items-only** level projection. Recorded EXP gives an exact projection; an unrecorded partial level gives an honest lower/upper range. The current core has no authoritative Zeni balance, so affordability remains unknown. Source curves that do not cover an authored extended cap return `base_experience_projection:{available:false,reason:"TRAINING_CURVE_UNAVAILABLE"}`. This preview does not silently apply a separate Creator curve extension.

`instance_id`, `sa_level`, `effective_level_cap`, `inventory_verified:true` and `selected_field` supplement the source planner's facts. Every result keeps `final_exp:null`, `final_zeni_cost:null` and `can_commit:false`: target eligibility, matching-type bonuses, field/success combination, complete Zeni costs and cap-overflow handling still need verified rules. No item, field, card, EXP, Zeni, revision, command ledger or schema is changed.

`make check-training-store` is one focused supplied Eclipse/Sparking integration scenario for owned identity/actual level/SA/effective cap, inventory, exact/unknown EXP, selected source field, strict override rejection, explicit authored missing-curve limits and unchanged state. It does not repeat the independent planner tests or earlier core suites, and makes no native package.

## Local Creator Finish and immediate collection (schema 8)

`creator.finish` takes `{definition}` after the native embedded-Creator coordinator validates the exact saved project/projection. It atomically registers the strict definition and grants **one direct local collection instance per definition**. This implements Tin's latest unified-game requirement: a saved local creation immediately appears in the collection and can be assigned through `team.set`. `creator.import` retains its existing settings-sharing/banner-registration semantics and does not grant an owned copy. Neither operation grants ordinary official characters or currency.

A full Creator packet is not accepted through public `creator.import` or `creator.finish`. The native `od_creator_finish_bundle` call checks the validator packet hash and fields, then uses the same one-copy collection grant on the saved `local-player` profile. A mismatched hash or a public descriptor does not create a card.

The result is `{instance_id, definition_id, version, newly_owned, available, library, revision}`. `library` has the ordinary Creator library/FIFO/main-feature state and the committed revision. New copies are fully awakened, level1, Super Attack level1, Hidden Potential locked, with no add-ons; SLR/GR defaults preserve their always-on exclusive metadata. Later valid edits update the same owned instance and all effective created copies, preserving levels/EXP/locks/teams and rejecting incompatible caps or edits during active runs. Retries, including a new command after response expiry, never mint another direct copy. Consumed direct copies remain permanently bound and return `available:false`, rather than being reminted. Banner-summoned duplicate instances remain distinct and valid.

The schema8 `creator_collection` mapping proves direct-copy origin independently of banner pulls; import validation rejects inconsistent bindings and preserves the active save. Valid schema1–7 saves migrate transactionally. Native coordinators should derive a stable `:collection-v1` intent command when upgrading an older `creator.import` receipt; an old settings receipt must never be mistaken for ownership. Projection checking stays before this operation, and client pages do not receive arbitrary core/SQL authority.

One supplied-real-master scenario is `python3 check_creator_finish.py /private/path/reference.db`: Finish, actual collection/team use, progress-preserving edit, retries/expired replies, save/reopen, invalid-binding rollback and the changed migration boundary. It is a local-core check, not proof of native rendering, custom assets or playable battles. No unchanged suites were rerun for this change.

## Source-backed initial ACT and trusted local recovery (schema 9)

`player_progress` persists our own rank1/EXP0 bootstrap metadata, exact source `rank_statuses.act_max`, recovery anchor and named policy. **The 300-second-per-ACT interval is an explicitly authored Offline Dokkan rule, not a newly discovered source value or earlier user agreement.** Both supplied source masters have rank1/EXP0/ACT20. Invalid source rank data fails; absent rank data does not invent a capacity. No cards, Dragon Stones or event unlocks are awarded by bootstrap/recovery.

Normal native `profile.create` and `profile.refresh` accept only `{}`. The JNI/Objective-C wrapper captures the system clock; caller-supplied time/initial amounts are rejected. `profile.snapshot` remains read-only. A fresh stable command identifies a refresh intent, and retries replay its original result/time. Trusted native policy `run.start` also captures the clock and recovers elapsed ACT in the same transaction as its source-derived entry debit. Normal client pages still cannot call privileged `run.start` or supply asset readiness/rewards.

Recovery carries partial intervals while below capacity, discards idle time accumulated at full ACT, never goes above the cap, and ignores backward clocks. Legitimate legacy over-cap balances are preserved. Old saves attach metadata/clock lazily without resetting/refilling their existing balance; schema migration itself never grants ACT. The existing rank1 policy deliberately does not pretend that rank-EXP earning/rank-up progression is already complete.

A trusted encounter may use `rewards:[]` for an actual rewardless/practice encounter. Entry still validates its source map/team/assets and debits ACT. Clearing records progress and its once-only reward-source settlement with no awards; replays cannot settle it twice. Ordinary `inventory.grant` still rejects empty reward lists. This is not permission to omit rewards from a source stage that has known rewards.

One focused real-master check is `python3 check_player_act.py /private/path/reference.db`: source-capacity bootstrap, real first-map ACT debit, rewardless settlement/replay, trusted-clock recovery, no full-cap banking/overfill, rollback on failed entry, unchanged legacy-zero/over-cap balances, schema8 import/reopen and the actual native clock/amount capability filter. Prior unchanged checks are not rerun. Game rendering and physical-device installation remain separate acceptance work.


## Trusted native Creator projection outbox

Schema10 adds a durable per-profile projection generation and private save identity. Relevant Creator definition/owned-binding changes enqueue through SQLite triggers in the same core transaction. This generation is separate from `profiles.revision`: ordinary XP/lock mutations leave an unchanged Creator mirror valid. Failed mutations and exact command retries do not create another intent.

`od_projection_snapshot`, `od_projection_definition` and `od_projection_ack` are direct native APIs, never string-selectable `od_execute` operations. The existing native owner queue fetches a generation-pinned snapshot/documents, commits its private sidecar, reads back the exact persisted state, then acknowledges it. Stale/altered state rejects; restart retains unacknowledged intent. Save imports requeue above source/current epochs before replacing the live database. No ownership or progression is stored in the sidecar as an authority.

The implemented native callback writer/readback contract and focused actual-source evidence are in [the original-client master bridge](../original-client/master/README.md). This completes the trusted core-to-sidecar handoff boundary; original-engine lookup/cache binding, full runtime Creator support and Duo gameplay remain separate unfinished work.


Schema11 gives each own offline profile a persistent positive local wire ID and
`Offline Player` name. This is a technical identity for the local save, never an
online-account import. Native-only `od_offline_identity` and
`od_offline_player_snapshot` read on the existing core connection/transaction;
they are outside all WebView operation tables. The direct snapshot carries
`wire_identity`, projection clocks and `source_rank` from the exact selected
immutable master (`rank`, `exp_total`, `act_max`, `friends_capacity`; null if
unsupported). Ordinary snapshots include identity but not acknowledgement clocks.

New owned-card INSERTs are captured only on this connection and receive their
effective source curve's level1 EXP after final Creator binding, in the same
mutation transaction. Current source curves establish0 for new grants. Legacy
missing totals remain unknown at every level; restart/import never guesses them.
Exact command retries preserve earned progress. `../original-client/master/bootstrap-evidence.json`
records the focused real-master bootstrap/migration/grant/retry scenario.
Tutorial enums and initial card/support capacities remain unverified.

## Exact native full-bundle retention and readback

Schema12 stores the exact validator packet as a bounded BLOB in
`created_full_bundles`, keyed by immutable profile/definition/version, with its
SHA-256 and save scope. Native full Finish inserts those bytes inside the SAME
existing transaction as definition registration, owned identity and command
receipt. Retry checks the existing scope/hash/byte sequence before returning a
cached result; it cannot replace a packet or grant another owned copy.
Public `creator.import`/`creator.finish` descriptor guards stay closed.

Version11 descriptors whose bytes were discarded remain preserved through
migration. They do not get a fabricated payload. Native retrieval returns
`FULL_BUNDLE_PAYLOAD_MISSING_RECOVERY_REQUIRED` until a separately justified
recovery exists. This is different from rejecting or deleting the whole save.

`od_creator_accepted_bundle` and its native bridge read exact packet/definition
bytes plus `od-accepted-full-bundle-receipt-v1` from one read transaction. Scope
is the existing compact ASCII hash of `[save_identity,profile,content]`. The
requested owned instance must still exist, be unconsumed and use the requested
active version. The receipt includes profile revision, projection generation,
member count, all identities and project/definition/full-packet hashes. It is
snapshot evidence, not perpetual liveness or gameplay authority; activation
must still reconcile the current projection and source-engine contracts.

Session's native accepted-project API retains its simple packet unchanged.
Full units add `full_bundle_bytes` (immutable NSData), `full_bundle_sha256` and
`full_bundle_receipt` after Core readback matches the immutable accepted project
and definition. No WebView operation, arbitrary file path, ownership grant,
original-engine attachment or runtime-readiness flag is added.

Source changed without a C/Objective-C compile or actual save access. The one
focused in-memory SQLite migration/atomicity check is recorded separately;
it does not establish compiled native behavior or original-engine gameplay.
