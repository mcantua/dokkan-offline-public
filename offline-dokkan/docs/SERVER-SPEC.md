# Offline Dokkan Battle — own local core and content spec

Current direction: Tin's Oct 28 clarification. Our original game calls our local core directly. Eclipse and Sparking are database/asset/website-download sources, not selectable modes or two different player games. This supersedes the original patched-client transport proposal. Historical path research below is retained for reference only.

## 1. Scope and evidence

One own-game identity, canonical player save and Creator workspace. The local core owns progression, inventory, currencies, teams, summons, schedules and settlement. Our own interface/board/battle implementation consumes imported read-only content. Explicit setup/download and optional updates may use the internet; normal play does not.

Source data adapters preserve provider/version/hash as provenance. Main-game screens must not show Eclipse/Sparking mode selectors. One active validated master is the initial storage boundary; do not silently compose conflicting source IDs or open a new player when switching content. Preserve existing saves and reject incompatible updates until validated migration exists.

This document defines our internal contracts. It does not require the original games' HTTP protocol or claim our core is a playable battle engine. Original-client research is optional technical reference, not a current acceptance gate. Verified data handling, actual gameplay and physical platform checks are still required.

Evidence labels:

| Label | Meaning |
|---|---|
| OBSERVED-PATH | Path listed in Claude's IPA findings; strings can corroborate some paths |
| MASTER-SCHEMA | Table/column inspected in the user-supplied SQLite snapshots; no game rows copied here |
| DESIGN | Our proposed internal contract, storage or behavior |
| WIRE-TBD | Game method, field names, types, envelopes and completion behavior still need evidence |

Sources, in descending authority:

1. Tin's current authorization and `projects/OFFLINE-DOKKAN-PLAN.md`, including the IPA findings section. These define product rules, not a complete wire protocol.
2. `messages/to-chatgpt/2026-10-28_1210_from-claude_offline-dokkan-start.md`.
3. `mac-workspace/research/eclipse-ios-patcher-strings.txt` and `sparking-ios-patcher-strings.txt`: route/hook names. Examples include Eclipse `/resources/login`, `/sugoroku_maps/start`, `/auth/nonce`, `/user/mydata`; Sparking `HttpAsynConnection` completion/response hooks. Raw string adjacency is not proof of JSON nesting.
4. The two databases supplied in this chat from the base APK: each has 233 tables and passed `PRAGMA quick_check`. Eclipse has 17,786 cards; Sparking has 19,308. These are snapshots, not evidence of current online content.
5. `unit-creator/decomp/specs/core.md` and `sparking-ai.md` describe the **Unit Creator bridge** and game-data formats. Their `Native.call` methods are not the game's server API.

No app, original IPA, extracted master database, game assets, proprietary key or account credential belongs in this project's source tree or distribution.

## 2. Architecture and compatibility boundary

```text
our own game screens / board / battle / Creator
       ↓
restricted typed local commands and queries
       ↓
serial executor → one canonical player SQLite save
                → validated read-only content + created-unit overlay
                → verified local assets and saved schedule

explicit data setup/update → Eclipse/Sparking source adapters → validated staged import
```

Native callers use our direct JNI/Objective-C bridge, not a guessed remote-game response envelope. One command UUID identifies each intent across retries; the local core durably commits the result once. Rendering stays off the storage worker. Normal callers cannot supply reward amounts, arbitrary SQL, filesystem roots or an `assets_ready` assertion.

Data source adapters accept only known public HTTPS providers/paths or user-selected files, validate sizes/hashes and database structure, and publish atomically. TLS verification stays enabled. No source game login, source account, embedded Sparking keys or remote gameplay service is required. Unknown/encrypted/unavailable data fails clearly and preserves working content/progress.

## 3. Historical source-client endpoint inventory (optional research)

These paths are not required by our own direct API and do not block development. All 35 paths below are OBSERVED-PATH from the IPA findings. **Methods, precise request fields, response keys/types, status codes, error formats and authentication/encryption details are WIRE-TBD for every row.** “Input” and “result” below describe semantic requirements for our core, not captured game payloads. R = read; M = mutation; B = bootstrap; A = local content/asset lookup. Classification is DESIGN, to be confirmed in the adapter. A path ending in `/` is retained exactly as reported; no unobserved subroute is asserted.

| # | Reported path | Core role and input to resolve | Local result the adapter must represent | Persistence and unresolved contract detail |
|---|---|---|---|---|
| 1 | `/auth/nonce` | B: offline profile/session bootstrap | Fresh local challenge, if required by the client's login flow | Session-scoped expiry/replay state; challenge algorithm/encoding unknown |
| 2 | `/auth/sign_in` | B/M: offline identity plus preceding bootstrap material | Stable local player identity and local session | Create a profile once; original login/crypto schema and required tutorial state unknown |
| 3 | `/resources/login` | B/R: profile, selected master/content version | Consistent login snapshot: account, owned cards, inventory, teams, progress and schedule references | One read snapshot; exact sections, defaults and required asset/version fields unknown |
| 4 | `/resources/home` | R: session and current local schedule | Home state, notices, available activities and counters | Read local state; timestamps and reset signals unknown |
| 5 | `/user/mydata` | R: session and any requested sections | Player summary and authoritative current balances/progression | Never construct balances independently of the save; full versus delta format unknown |
| 6 | `/user_areas` | R/M: player and area/stage progress intent | Unlock, clear and progression state | Writes only through validated progression commands; verb and update behavior unknown |
| 7 | `/user_cards/` | R/M: owned-card instance selection and operation intent | Owned-card collection or committed card change | Distinguish instance IDs from master IDs; paging, filters and mutation subroutes unknown |
| 8 | `/cards` | R: master/created-card definitions or client lookup intent | Effective card definitions for the selected content version | Whether this route serves master cards, owned cards or both needs capture |
| 9 | `/teams` | R/M: team slot and ordered owned-card instance IDs | Saved team with legal roster and revision | Validate ownership, slot/order, costs and restrictions; client team size/empty-slot encoding unknown |
| 10 | `/events` | R: local time, progress and selected schedule | Activities currently available, including local recurring content | Versioned local schedule; live schedule is only as recent as the last optional update |
| 11 | `/quests` | R: area/quest selection and difficulty/progress | Quest availability and master references | Validate actual master IDs; response grouping and difficulty encoding unknown |
| 12 | `/sugoroku_maps/start` | M: quest/map, difficulty, team and support selection | Unique persisted run, resolved board/enemy inputs and any entry costs | Commit once before response; seed/board format and client-generated versus server-generated fields unknown |
| 13 | `/sugoroku_maps/finish` | M: persisted run identity, battle outcome and allowed progress summary | One committed completion with XP, currency, drops, missions and unlock changes | Exactly-once settlement per run; reward and result envelope unknown |
| 14 | `/missions` | R: player progress and mission selection | Mission progress and claimability, including repeatable opportunities | Conditions come from master data but their evaluator semantics need verification |
| 15 | `/missions/put_forward` | M: mission/progress or claim intent | Committed progress/claim result and resulting rewards | Name alone does not establish whether this is progress, claim or both; capture required |
| 16 | `/potentials` | R: owned-card instance and board selection | Hidden Potential board and opened routes/squares | Use imported board references plus player state; wire flag values unknown |
| 17 | `/potentials/release` | M: selected owned card, route/square and materials/dupe choice | Updated board, consumed resources and remaining balances | Validate eligibility and ownership atomically; actual unlock payload unknown |
| 18 | `/equip` | R/M: owned card, slot and equipment-item instance | Equipment state or committed equip/unequip operation | Validate slot limits and master restrictions; exact operation variants unknown |
| 19 | `/dragonball_sets` | R/M: collection/set and progression or wish intent | Local collection, completed-set and wish state | No table of this exact name exists in these master snapshots; source mapping and wish payload unknown |
| 20 | `/db_stories` | R: story selection and player progression | Dragon Ball Story listing and unlock/clear state | `db_stories` master table exists; chapter/quest mapping and wire wrapper unknown |
| 21 | `/genkai_battles` | R/M: mode/stage and progress intent | Local mode listing, run/progress or completion result | No exact-name master table here; do not equate blindly with `z_battle_stages` |
| 22 | `/joint_campaigns` | R/M: campaign and participation intent | Local campaign status/progress/rewards if the client requires them | Multiplayer semantics must be mapped to explicit offline rules; empty-result compatibility unverified |
| 23 | `/cooperation_campaigns` | R/M: cooperative-content intent | Localized campaign view and any permitted local progress | Do not invent remote players or remote success; required empty/disabled representation unknown |
| 24 | `/announcements` | R: locale and notice selection | Local notices/help, with only locally available images/content | Empty list versus required notice records must be observed |
| 25 | `/briefing` | R/B: client startup/version/status intent | Local startup/status content needed to enter the game | Whether mandatory notices, maintenance or version fields are expected is unknown |
| 26 | `/support_leaders` | R: stage/team restrictions and support selection | Usable local support candidates and stable local candidate IDs | Choose from permitted locally defined content; no friend-service dependency; list shape unknown |
| 27 | `/client_assets` | A: imported content identity and asset queries | Manifest/version metadata pointing only to imported local content | Not proof that the response is raw binary; hash/manifest format unknown |
| 28 | `/ondemand_assets` | A: requested packs/files/content version | Availability and local resolution of user-imported files | Missing content must be explicit, with no automatic online fallback; wire delivery form unknown |
| 29 | `/assets/database` | A: selected game/content database version | Local master-data delivery/update information the client expects | Response may be manifest, redirect or data; exact packaging/encryption must be verified |
| 30 | `/sd/battle` | A/R/M: client SD-mode battle intent | Version-appropriate local mode/battle data | “SD” semantics and any mutation behavior are unknown; path is not enough evidence |
| 31 | `/sd/characters` | A/R: client SD-mode character lookup | Locally supported SD character data | Do not substitute the normal card catalog until actual mapping is confirmed |
| 32 | `/sd/packs` | A/R: client SD-mode pack lookup | Local pack metadata/content if available | Pack schema and required resources unknown |
| 33 | `/unrelease` | R: client release/content-gating intent | Consistent local content-gating information | Must not expose unusable content; true meaning and response shape unknown |
| 34 | `/item_reverse_resolutions` | R/M: reverse/restore operation and owned-card/item identities | Validated reverse-awakening/restoration state or committed result | Confirm master route/material semantics and which operation this route performs |
| 35 | `/iap_rails` | R: client purchase-catalog intent | Compatible empty/disabled purchase capability; no real purchases | Never credit stones for a simulated purchase; safe disabled shape/status is WIRE-TBD |

Coverage does not imply that this list is complete. Summon/banner draw, training, selling, awakening, EZA, save import/export and World Tournament routes are **not established by the findings list**. Implement their domain services behind the core, then map only observed client routes or our own Creator UI commands. Do not invent `/gasha` or other official-looking routes as fact.

Research update: some reported strings are route fragments rather than full paths. Historical public implementations use `/quests/{id}/sugoroku_maps/start` and `/finish`, `/user_cards/{id}/potentials`, and `/cards/{id}/equip`. They are historical candidates, not verified current 6.6 contracts. See `../research/route-evidence.json`, `historical-response-shapes.json` and the research README; never dispatch a fragment as a verified complete game URL.

## 4. Imported master data and local storage

MASTER-SCHEMA observations from the supplied snapshots:

| Content | Inspected table/key or column relationships | Eclipse / Sparking row counts |
|---|---|---|
| Card definitions | `cards.id`, `character_id`, `resource_id`, `lv_max`, `skill_lv_max`, `grow_type`, `potential_board_id` | 17,786 / 19,308 |
| Level growth | `card_growths(grow_type, lv, coef)` | 1,310 / 1,310 |
| Awakening | `card_awakening_routes(card_id, awaked_card_id, card_awakening_set_id, type)` | 7,042 / 7,447 |
| Areas → quests → maps | `quests.area_id`, `sugoroku_maps.quest_id`, `difficulty`, `act`, `user_exp`, `zeni` | Areas 704 / 751; quests 3,222 / 3,490; maps 5,640 / 5,914 |
| Enemy configuration | `sugoroku_map_enemy_informations(sugoroku_map_id, enemy_info)` | 5,478 / 5,567 |
| Boss reward references | `sugoroku_map_boss_drop_items(sugoroku_map_id, quest_id, item_id, item_type, drop_type)` | 15,598 / 15,795 |
| Missions → rewards | `missions.id`, `conditions`, `target_value`; `mission_rewards.mission_id`, `item_id`, `item_type`, `quantity` | Missions 27,545 / 27,677; rewards 49,011 / 49,210 |
| Hidden Potential | `potential_boards.id`; `potential_squares(potential_board_id, event_id, condition_set_id, is_locked, route)` | Boards 45 / 45; squares 15,030 / 15,030 |
| Equipment | `equipment_skill_items.id` and `equipment_skill_limitation_set_id` | 8,857 / 8,926 |
| Training / medals / support items | `training_items`, `awakening_items`, `support_items` | Training 75 / 80; medals 2,323 / 2,430; support 79 / 79 |
| EZA master stages | `z_battle_stages.id`, `unlock_conditions`, schedule fields | 240 / 241 |
| World Tournament master configuration | `budokais.id`; `budokai_ranks.budokai_id` | 64 / 64; ranks 768 / 768 |
| Stories / Domains | `db_stories.id`; `dokkan_fields.id` | Stories 4 / 4; Domains 13 / 19 |

These are column-level associations, not a claim that SQLite declares/enforces all foreign keys. Integer `item_type`, rarity, condition and reward-type enums require evidence from client/Creator code before mapping. Table counts alone cannot reveal their semantics. `users`, `user_cards`, `teams`, `user_areas`, `events` and `gashas` are absent as exact table names in both snapshots: our save/schedule services supply player-owned state and banner definitions.

Keep imported masters read-only and pin a master content hash/version per profile and active run. Never combine Eclipse IDs with Sparking definitions silently. Preserve a master reference for any active save/run across an optional content update, or perform an explicit validated migration first. A created-card overlay resolves against the selected master without modifying the imported file.

Proposed **own** save schema, not copied from the game:

| Local table/group | Key state and constraints |
|---|---|
| `profiles` | Local UUID, schema version, content reference, tutorial/rank/XP, save revision, schedule policy |
| `wallet` and `inventory` | Per-profile balances and typed quantities; integers, nonnegative; typed resource mapping independent of wire enum |
| `owned_cards` | Unique instance UUID plus master/created-definition key, level/XP, SA level, lock, Hidden Potential and growth state |
| `teams`, `team_members` | Per-profile team slot and ordered owned-card references; no dangling or cross-profile members |
| `card_potential`, `equipment_instances`, `card_equipment` | Player unlock/material/equipment state with referential validation |
| `area_progress`, `quest_progress`, `mission_progress`, `reward_claims` | Unlocks, completion counters and reward opportunities; repeatable claims keyed by opportunity/run, not just mission ID |
| `runs` | Run UUID, content hash, selected team snapshot, mode/map/seed, entry-cost settlement, started/finished state, immutable finish result |
| `commands` and `reward_ledger` | Command UUID, operation/input digest, outcome/revision and unique settlement source; bounded retained retry history |
| `banner_definitions`, `featured_history`, `pity` | Versioned banner membership/rates, ordered featured definitions, main-feature epoch and counters |
| `created_definitions` | Stable creator/unit identity and revision/hash, settings-only patch, origin credit and selected master dependencies |
| `schedule_snapshots`, `tournament_state` | Explicit schedule source/version/time zone, weekend identity and deterministic local ranking state |

Official owned-card duplicates from summons are valid separate instances, needed for Hidden Potential. “No duplicates” for catalog/import means deduplicate character definitions, not delete legitimately owned copies. Re-importing the same created definition must not create another banner entry; a newer revision replaces its definition while keeping valid owned-instance progress.

## 5. Core command/query contract (DESIGN)

Core calls receive typed `profile`, `command_id` for mutations, `content_version`, operation and validated arguments. Results contain an internal outcome, save revision and typed result. These internal names are our own game contract; native/UI callers consume their typed results directly. Stable internal failures include `PROFILE_MISSING`, `CONTENT_MISSING`, `CONTENT_MISMATCH`, `INVALID_ARGUMENT`, `NOT_UNLOCKED`, `INSUFFICIENT_RESOURCE`, `RUN_ALREADY_SETTLED`, `REVISION_CONFLICT`, `UNSUPPORTED_CAPABILITY` and `SAVE_INVALID`. No HTTP mapping is required for our own in-process game.

Validate IDs as the correct kind (definition versus owned instance), ownership, range, quantities, entry costs and prerequisites before changing anything. Use parameterized SQL and checked integer arithmetic. Reject negative quantities/overflow; never accept arbitrary SQL, file paths or remote URLs from a client body. Size limits are per operation and must be documented before an adapter accepts data.

One serialized mutation executor owns each save. A command transaction includes validation, all resource/card/progress changes, updated save revision and persisted command outcome. Return success only after durable commit. A read spanning several tables must see one consistent revision. Main-thread game rendering must not perform database, compression or file-copy work.

Retries reuse the same command UUID and return the same committed result. Reusing a UUID with different input is an error. **A request-body hash alone is not an idempotency key:** two intentional identical summons or purchases are distinct commands. Our own UI/native intent coordinator assigns a UUID and retains it across retries. A canceled UI request does not undo an already committed command; the next query must show the committed result.

Fresh offline login creates a profile once and follows the game's required first-run/tutorial flow. Initial resources and starter-card requirements must come from verified initial-state behavior or Tin's explicit decision, not invented free stones/unlocked events. No online identity/account fields are required by the core; adapter-only placeholders must not contain real account information.

## 6. Battle runs, progression and reward settlement

Start validates unlocked content, imported assets, roster legality and resources, then stores a run and any entry-cost deduction together. A second start retry returns the same run. Keep pending run state through restart so a crash is not another entry charge. Abandon/resume/refund rules are WIRE-TBD and must not be guessed from a missing finish response.

Our own game/battle engine must compute the actual battle. Finish resolves an existing run, validates a compatible outcome and permitted result inputs, then settles exactly once. Do not trust arbitrary client-provided item IDs/stone quantities: use run/master rules to compute rewards. Store the result used by every finish retry. A crash before commit changes nothing; a crash after commit must replay the committed result without another award.

Tin's multipliers apply to granted progression rewards, across Story, Events and missions:

| Reward category | Multiplier |
|---|---:|
| Items | 3× |
| Awakening Medals | 6× |
| Dragon Stones | 10× |

Categories are mutually exclusive: Awakening Medals receive 6× total, not 3× then 6×; Dragon Stones receive 10× total. Multiply once at the reward ledger boundary, with base quantity and applied multiplier recorded. Do not multiply costs, existing balances, refunds, save imports or replayed results. Resource enum mapping and whether a non-item reward such as Zeni/XP counts as “items” remain explicit policy gaps; do not silently assign multipliers to them.

Start like a fresh official account; progress unlocks content. Everything must remain farmable and rewards re-earnable. This requires new legitimate completion/claim opportunities after replay, while preventing replay of the **same** command/run from granting twice. Exact repeat eligibility for one-time account/tutorial rewards must be reconciled with the fresh-account flow before implementing those rewards.

## 7. Summons, created units and upgrades: fixed rules

These invariants constrain our own domain modules and summon screens.

| Rule | Required value |
|---|---|
| Single / multi prices | 5 / 50 Dragon Stones |
| Official banners | Last explicitly imported/refreshed official schedule; internet update optional |
| Weekly rotators | 2 random official banners from the last 9 months only |
| Elder Kai banner | Weekends only; Elder Kais only, each raises Super Attack level by 1 |
| Unit Creator pool | Eligible non-Carnival/non-Dokkan Fest/non-Rising-exclusive officials plus all created/imported characters |
| Featured slots | 5; newest is main featured; oldest leaves featured for the ordinary pool, never leaves the banner |
| Starting rarity probabilities | LR 1%; SLR 0.1%; GR 0.01%; lower rarities at normal rates |
| Main-feature pity | GR multi #50; SLR #25; LR #10; UR #5 |
| Pity reset | Natural or guaranteed main-feature pull; also when a new main featured arrives |
| Custom EZA / Custom Super EZA / Enhance | 500 / 700 / 300 Dragon Stones respectively |

Probability implementation should use integer weights (for example LR 10,000, SLR 1,000, GR 100 per million), with a validated full pool and explicit remaining lower-rarity weights. These rarity totals do **not** define the chance of a particular featured card. Featured-versus-unfeatured distribution, lower-rarity weights, multi slot guarantees, additional rarity pity and schedule boundary details are not specified: record them as unresolved rather than change Tin's numbers.

A multi's debit, all resulting owned instances, pity transition and command result commit together. The main-feature epoch is part of the pity key. Count eligible multis since the last reset; guarantee by the specified multi if no natural main-feature pull occurs. A natural main-feature single resets the counter; a single does not advance a multi counter. Preserve the last result on retry, not a fresh RNG draw. Use operating-system randomness in production; deterministic test randomness stays test-only. Persist resolved draws, not a production seed that enables unrelated future draws to be replayed.

Created characters enter summons fully awakened, level 1, Hidden Potential locked, Super Attack level 1 and no add-ons. Stats grow toward the Creator's maximum stats. Super / Godly Exclusive bonuses for SLR / GR apply at every level. They are created-unit definitions, not already maxed owned instances.

Custom EZA is for officials without an EZA; Custom Super EZA is for officials without a Super EZA. Enhanced upgrades apply to officials with an EZA/Super EZA, using a pinned meta policy and no manual editing. The card's animated label must identify Custom EZA, Custom Super EZA or Enhanced. Do not apply an upgrade until its price, eligibility and new definition are committed atomically.

World Tournament runs on weekends with local simulated rankings, exclusive ranking rewards and competitors whose points progress through the weekend. Persist weekend identity, ranking state and reward settlement; closing/reopening must not reroll ranks or grant rewards twice. Exact weekend boundaries/time zone, tie-breaks and AI progression parameters are DESIGN decisions still to be pinned. Do not report simulated competitors as live humans.

## 8. Scheduling, updates and assets

Persist a calendar/time-zone policy and schedule snapshot. “Live official banners” while offline means the last explicitly obtained official schedule, advanced locally through its known dates. Do not pretend to know new online banners after the snapshot expires. Retain the last valid local content and show that a schedule refresh is optional. Validate weekly rotators against the rolling nine-month window and prevent launch-based rerolls. Behavior when no eligible imported history exists must be explicit rather than invent official history.

Resolve game files only from the user's imported game content. Validate manifest sizes/hashes using the relevant game profile; do not distribute the files or secrets with our code. Unknown/missing assets return a controlled local error before a run or feature needs them. Do not request external content in the background. Stage optional content updates, verify them, migrate references if necessary and atomically activate them; keep saves and previously available events usable.

Imported created-unit files contain settings/identity/dependency references, not game artwork, animation files or keys. Only created units are shareable; reject sharing/importing Custom EZA, Custom Super EZA and Enhanced official modifications through that channel. Credit the creator and deduplicate stable creator/unit identity. A newer revision updates the definition; an identical import is a no-op. A genuinely new definition becomes main featured and resets the corresponding pity epoch. The behavior of revising an already featured unit's pity is unresolved and must be explicit before enabling updates.

## 9. Durability, save export/import and migrations

The master data and player save are separate files. Our player save is a transactional SQLite database with a schema version, profile and content identity. Use a supported SQLite durability configuration, checked commits and file protection appropriate to the chosen app access state. Choose journal mode explicitly in stage 2; a transient SQLite journal is not an extra user backup. Never copy only the main file while a live WAL contains uncheckpointed state.

Export a consistent snapshot using the SQLite backup API or an equivalent coordinated snapshot, then package our player state with schema/content references and an integrity hash. Exclude imported master databases, original app files, game assets, device/account credentials and all keys. A hash detects corruption; it is not authentication or encryption. No automatic multi-backup history: keep at most one emergency backup, only when needed.

Import to a staging location; validate format/size/schema, SQLite integrity, foreign references, nonnegative balances, content compatibility and created-unit references before activation. Unsupported/newer schemas or absent required content must leave the current save intact. Atomically replace only after all checks succeed. Never award “import rewards” or apply drop multipliers to saved inventory. Database migrations are transactional and versioned, with exactly one emergency recovery copy if needed and no accumulating old saves.

## 10. Optional historical wire research (not a completion gate)

For each adapter/profile, capture or statically establish:

1. Exact path including query/trailing slash, HTTP method, body serialization and content type.
2. Redacted request/response examples, status, headers, compression and envelope transformations.
3. Field names, integer/string distinctions, null/empty/omitted requirements, enum meanings and pagination.
4. Required bootstrap call order and the smallest fresh-profile response that reaches Home.
5. A successful and failing mutation, plus its retry/cancellation behavior and the game's completion queue.
6. Map start/finish identifiers, board/result serialization, reward categories and missing-content behavior.

Do not upload IPAs or keys. If cloud evidence remains insufficient, prepare a narrowly scoped Mac collection script for Tin to approve separately. It must inspect a user-selected IPA read-only, keep originals unchanged, skip secret values/account tokens, and output only needed structure/metadata in a small text file. Permission to write this spec is not permission to run anything on his Mac or use his connection. No Mac action is needed to implement the isolated domain/save core.

## 11. Current deliverables and acceptance

Finish our own game using the local typed API. The existing portable C/SQLite core and real JNI/Objective-C wrappers are functioning components. Native development packaging is authorized; an unsigned candidate is not a release.

The focused acceptance boundaries are:

- One original-game identity/player/Creator workspace; source choice appears only in data setup.
- Validated database/assets imported or downloaded explicitly; source changes preserve active progress and fail safely until migration exists.
- Actual own-game home, box, teams, summons, Story/Events, board and battle scenes, character training/Hidden Potential/equipment, missions and World Tournament.
- In-game shared Creator Finish and our own drawable banner with all agreed prices/rates/pity, not just settings registration.
- Restart-safe saves, atomic resources/rewards, exactly-once settlement and safe import/export/update migrations.
- Duo-first design on both displays, equal iPhone/Android features, essential physical signing/install/input compatibility.

Only targeted checks for changed boundaries are needed. Unchanged passed checks should be reused with exact source/hash provenance. Historical source-client protocol fixtures are optional research, not a completion gate.

## Current implementation checkpoint (Oct 28, 2026)

The portable schema7 core implements profiles/inventory/cards/teams, run entry/settlement, 3×/6×/10× rewards, saves/migrations, summons/pity, Creator definitions/newest-five state, source-normalized stats/EXP, schedules/tournament policies, upgrades and guaranteed Elder Kai training. Read-only Training/Hidden Potential previews expose actual source facts and owned balances. The rooted asset resolver and SQLite/ZIP master import validate local content without changing originals.

Real native wrappers and the data-free embedded Creator are being integrated. The current host/save manager is not the completed playable game. Our own game scenes, complete progression/data dependencies, fully configured player-facing banners and final native/device acceptance remain unfinished. No fabricated rewards, remote responses or physical-device proof are permitted.
