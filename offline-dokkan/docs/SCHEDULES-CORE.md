# Persisted offline schedules and World Tournament

These are our **internal trusted-host operations**, not verified Dokkan HTTP payloads. The game adapter must not forward arbitrary client configuration, clock values, scores, reward amounts or classification flags into them. Exact game wire mapping remains separate.

`schedules_store.c` runs on the core's player-save SQLite connection, inside the existing command transaction. The core provides secure randomness and a final-quantity credit callback; the store never opens another save or commits on its own. Core command UUID replay covers costs/draws. The tournament claim key additionally prevents a second award under a new command UUID.

## Calendar policy

- Zone `0`: UTC. Zone `1`: America/Chicago using the US rules effective since 2007. The chosen zone/policy is persisted; this is a documented internal game-design choice, not evidence of official event reset times.
- Weeks start Monday at 12:00 AM local time. Weekend activities run Saturday at 12:00 AM through Monday at 12:00 AM, end exclusive. Spring/fall transition weekends are 47/49 hours.
- The history window subtracts **nine calendar months**, retaining local wall time and clamping an invalid day to the destination month's final day. For a repeated fall hour, choose the earlier occurrence; a nonexistent spring hour shifts forward one hour.
- Rotation eligibility is pinned at the stored selection instant. Two distinct eligible banners are selected without replacement. Choices survive restart and remain until the next Monday; a backward clock does not reroll a completed week.
- A trusted catalog must contain real verified official history and usable local content, with explicit previously installed banner versions. This module does not fabricate lineups, official dates, exclusive-character classifications, summon rates or downloaded game files.

## Operations

All calls use the normal core profile and command UUID. IDs are bounded internal identifiers. Examples below are shapes; replace uppercase references with actual validated imported data.

### `schedule.catalog.install`

```json
{"catalog_id":"official-history-v1","zone":1,"history":[
  {"banner_id":"EXISTING_BANNER_A","version":1,"first_open_utc":1790000000,"verified_official":true,"usable_local_content":true},
  {"banner_id":"EXISTING_BANNER_B","version":1,"first_open_utc":1790100000,"verified_official":true,"usable_local_content":true}
]}
```

The referenced banner versions must already exist for the profile. Catalog IDs are immutable: importing identical content is a no-op; changing content under the same ID fails. Unverified, unusable, future or too-old entries cannot be selected.

`schedule.rotate` takes `{"catalog_id":"official-history-v1","now_utc":TRUSTED_POSIX_SECONDS}`. It persists the week ID, selection time, catalog and selected banner IDs. A same-week query uses the pinned catalog and does not call RNG again. Insufficient eligible history is an explicit failure, not an invented official lineup.

### `tournament.configure`

```json
{"tournament_id":"local-wt","version":1,"zone":1,"seed":"000000000000002a","tie_policy":0,
 "competitors":[{"id":"simulated-one","points_per_hour":100,"extra_points_per_hour_max":20}],
 "maps":[{"map_id":VALID_IMPORTED_MAP_ID,"points":1000}],
 "reward_tiers":[{"from_rank":1,"to_rank":100,
   "rewards":[{"kind":"stone","id":0,"quantity":1}]}]}
```

The example pace, points and reward contents are explicit configurable **internal design inputs**, not claimed official or user-agreed balancing constants. Do not silently install the illustrative values as a final game balance policy. `seed` is an explicit persisted 16-character lowercase hexadecimal simulation seed; production should generate it securely when creating the policy. It is separate from gacha randomness.

Configuration versions are immutable and pinned when a weekend starts. A competitor's progress is deterministic for its persisted ID, seed, weekend and configured pace. Restart/replay does not reroll competitors, backward clock movement does not reduce or re-award progress, and catch-up ends at the local Monday cutoff. Tie policy `0` shares a rank among equal scores; `1` puts the player after equally scoring competitors. No simulated opponent is represented as a live human.

Rank tiers cannot overlap. Supported inventory reward kinds are `stone` (ID 0), `medal`, `training`, `support`, `equipment` and `act`, validated against imported master tables. Base quantities are configuration inputs; the reward planner applies the agreed mutually exclusive 10×/6×/3× multipliers once. Our own World Tournament-exclusive created cards use the separate versioned registry described below. Ordinary master cards are not represented as these authored rewards.

### Gameplay and claims

`tournament.snapshot` takes `tournament_id`, `version` and host-trusted `now_utc`. During an active weekend it creates/advances persisted simulated competitors and returns their local scores and the player's rank. Outside an active weekend it returns `TOURNAMENT_NOT_ACTIVE`; the host can use the pure calendar API to display the next opening. This is a command because advancing persisted clock/score state is a mutation.

1. Start a legitimate core run on a configured map.
2. Call `tournament.enroll_run` with `tournament_id`, `version`, `now_utc`, and `run_id` **while that same-profile run is still started and the weekend is active**. This pins its weekend, map and configured score.
3. Finish the actual run through the core.
4. Call `tournament.record_run` with the same identifiers. Only a persisted clear, matching enrollment and still-open weekend earns points. The store never accepts a score from the client. A run can be enrolled only once per profile, including across weekends/tournaments. Repeated recording cannot add points again.
5. Once the weekend ends, call `tournament.claim` with `tournament_id`, `version`, `now_utc` and the stored `weekend_id` (the Saturday's local `YYYYMMDD`). This lets Monday claim the previous weekend rather than selecting the upcoming one.

Claim advances AI scores to the cutoff, derives the final rank from persisted player/AI state, chooses the configured tier, and credits final quantities in the **same** transaction as the unique claim row. A failed credit rolls the entire command back. Core credits must not multiply the returned quantities again. The claim stores its original save revision, trusted host timestamp and final reward receipt; a later retry/new UUID returns that receipt without granting again.

No run timestamps or World Tournament game-wire behavior are invented. The pre-finish enrollment boundary is necessary because the current core run record alone does not prove when an old clear occurred. Finishing after the weekend cutoff earns no new tournament points; changing this rule requires an explicit versioned policy.

### Our World Tournament-exclusive created rewards

`tournament.exclusive.register` accepts `{"definition":STANDARD_CREATOR_SETTINGS_DOCUMENT}` through the trusted host. It uses the same strict settings/master-reference validator as ordinary created definitions, requires a creator ID, and reserves a nonempty `tournament-exclusive:` identity. The definition must reference actual user-owned source content; it describes **our authored custom reward**, never an alleged official reward or unavailable artwork.

The registry and its active-version pointer are separate from ordinary Creator definitions and the Creator summon pool. Normal Creator imports, shares and banners reject the reserved identity namespace even on a fresh profile. Registering does not grant a card or add a summon entry. Versions are immutable: an identical current version is a no-op, conflicting/stale versions fail, and subsequent versions retain the original creator, source content/master ID and logical rarity. Previously earned instances retain their original version.

The host-side `tools/author_tournament_unit.py` can author a settings document from a user-selected real master source. It opens the master read-only, rejects unfinished awakening routes, retains source skill/art references, requires our own name/creator and explicit HP/ATK/DEF maximums, and only writes inside ignored `offline-dokkan/private/`. The default content ID is the supplied master's SHA-256; `--content-id` can match an already pinned host identifier. This helper creates no reward registration, claim, art or inventory grant; the shared trusted core validator still decides whether the document is usable.

```sh
python3 offline-dokkan/tools/author_tournament_unit.py \
  --master /path/to/your/reference.db --source-id YOUR_REAL_CARD_ID \
  --definition-id tournament-exclusive:your-own-id \
  --creator-id your-id --creator-name "Your name" --name "Your original reward name" \
  --rarity LR --stat-policy creator-cap-normalized-v1 \
  --hp-max YOUR_HP --atk-max YOUR_ATK --def-max YOUR_DEF \
  --output offline-dokkan/private/tournament-reward.json
```

After registration, an explicit rank tier can include:

```json
{"kind":"tournament_created","definition_id":"tournament-exclusive:YOUR_AUTHORED_ID",
 "definition_version":1,"multiplier_category":"item","quantity":1}
```

This is a base quantity of one, resulting in three separate owned instances through the item reward multiplier exactly once. The category must explicitly be `item`; each tier is bounded to 1,000 total exclusive instances and cannot repeat the same definition/version reward. No authored character or balancing data is silently installed by the module.

Only a settled, unclaimed tournament rank payout grants these instances. Each receives level 1, Super Attack level 1, fully awakened definition, locked Hidden Potential, no add-ons, and always-active Super LR/Godly LR exclusive flags when applicable. The saved ownership row pins definition/version, tournament/weekend, reward ordinal and unit ordinal. The same claim transaction contains inventory payouts, every new instance, provenance rows and receipt; failure rolls everything back. `created_cards` in the immutable receipt identifies each earned instance. A new command UUID cannot grant the same rank payout again.

`tournament.exclusive.library` lists the profile's latest registered authored definitions with origin `world_tournament_exclusive`; the core resolves earned instances against their pinned historical documents. Save import revalidates definitions, cross-version identity, source references, instance flags/caps, exact settled-rank reward quantities and contiguous provenance ordinals against the original receipt. A forged registry, imported Creator duplicate, extra earned instance or altered receipt is rejected.

### `elder_kai.configure` / `elder_kai.draw`

```json
{"banner_id":"weekend-kai","version":1,"zone":1,"multi_count":10,
 "pool":[{"master_id":VERIFIED_ELDER_KAI_MASTER_ID,"verified_elder_kai":true,
          "super_attack_levels":1,"weight_ppm":1000000}]}
```

The caller must establish Elder Kai classification from trusted imported content; a name match or an arbitrary client boolean is not proof. Every permitted entry must raise Super Attack level by exactly one and have a valid master-card reference. Weights sum to one million; multi size is explicit. No extra pity or guaranteed rarity slot is invented.

Draw takes `banner_id`, `version`, `now_utc` and `kind` (`single`/`multi`). It is available only within the persisted calendar policy's weekend. A single costs 5 stones; a multi costs 50. The planner resolves actual material-card IDs, then core atomically debits and grants owned cards initialized at level 1/Super Attack level 1. Command retries return their stored draw rather than draw/debit again. It does not touch the Unit Creator banner's pity.

## Import validation

Core handles schema versioning, exact schema/FK/integrity checks and transactional import. The module additionally validates immutable configurations and master references; rotation membership/eligibility and dates; weekend/zone/config consistency; exact configured competitor set; deterministic recomputed score/hash/seed/version/time; enrolled map-to-score mappings; credited-run ownership/clear status; player totals derived from credited runs; and the original final claim receipt. A corrupted AI score or mismatched schedule must not become active through save import.

These implemented domain operations do not prove that the original game UI currently calls them. Native adapter/request-format verification and actual device gameplay remain required.
