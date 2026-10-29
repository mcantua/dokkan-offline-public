# Original iPhone battle request boundary

This work targets the supplied original iPhone client. No replacement combat,
map or animation system is introduced. Nothing here proves a successful battle.

## Exact current source facts

The 556-byte start constructor and 584-byte finish constructor contain these
relative path format strings:

- `quests/{0}/sugoroku_maps/start`
- `quests/{0}/sugoroku_maps/finish`

Both pass method kind 1 to the shared request base and inherit the same method
getter (slot 17) and 1284-byte materializer (slot 2) as the reviewed bootstrap
requests. The established Foundation mapping makes kind 1 `POST`. The runtime
origin, substitution value, complete resulting URL and successful transport are
not observed here.

The request-family slot 25 points to a 1596-byte start body builder and a 3380-byte
finish body builder. These are actual current-client builders, rather than
historical public-server examples. Both construct a local JSON object, serialize
it, invoke the existing native signing interface and assign the resulting string
to an outer object under `sign`. The body is then handed to the existing shared
request path. The signing implementation and its private inputs were not read,
recreated or exported. An offline handler must establish a legitimate semantic
boundary for these requests; it cannot assume raw transport bytes contain the
unwrapped options/statistics object.

The start builder references `difficulty`, `selected_team_num`, `support_items`,
`support_memory_id`, `cpu_friend_id`, `friend_id`, `support_user_card_id`,
`support_leader`, `is_playing_script`, `eventkagi_item_id`, `boost_schedule_id`,
`genkai_battle_id`, `genkai_battle_schedule_id`,
`selected_genkai_gimmick_ids`, `bgm_filename` and `stone_navi_usage_status`.
Several branches depend on supplied friend/item/memory/event objects. Their
conditional presence cannot be replaced with universal default values.

The finish builder references `difficulty`, `token`, `steps`, `actual_steps`,
`used_items`, `used_support_memory_id`, `elapsed_time`, `is_cleared`, `reason`,
`is_cheat_user`, `quest_started_at_ms`, `quest_finished_at_ms`,
`has_player_been_taken_damage`, `max_damage_to_boss`,
`min_turn_in_boss_battle`, `energy_ball_counts_in_boss_battle`,
`is_player_special_attack_only`, `is_defeated_boss`, `passed_round_ids`,
`total_damage_to_enemy`, `total_damage_to_player`, `used_special_views`,
`dodge_count`, `guard_count`, `critical_count`, `additional_attack_count`,
`genkai_battle_id`, `genkai_battle_schedule_id` and `bgm_filename`.
This is an observed vocabulary, not a complete admitted typed DTO. Nested
member keys, scalar signedness, callback ownership, retry behavior, server
results and requiredness still need their exact source/dataflow evidence.

The shared 960-byte slot 26 candidate was inspected and is a **request header
builder**, not a response parser. Its early candidate filename does not confer
a response contract. Two exact direct callers of the start/finish constructors
are retained for the next callback-consumer step.

## Evidence and limits

- Prepared original-engine SHA-256:
  `efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222`.
- Start constructor556B:
  `85b1c335794f7394ca93c54d2c07d071c5e0ece8893f78077c25167ff9a8928d`.
- Finish constructor584B:
  `ddc34bed0e1e8d21f9a8ab93123e120e437dc0ee642dc1f648ec9eb37b3f5597`.
- Start body1596B:
  `07e8bed5be4eda28c95689d36c1971a70e7ea58f07026243e55dbafef6696a42`.
- Finish body3380B:
  `caada19b4d49112908ce7c4e44678cb9765317f55e26e78ddd5d7a7eae5d8d15`.

Source pins/actual high-pcode footprint receipts, detailed private coordinates
and decompiler output stay in ignored private research. The body builders and
constructors have no observed high-pcode sites outside their declared bodies.
Decompiled types must still be checked against ARM64 calling conventions.
No request/response route is enabled by this document. No client execution,
server request, app build, battle, save or reward result was verified.


## Actual response consumers now identified

The original start and finish success lambdas have exact RTTI signature
`void(HttpResponse*, Json::Value&)`. Their direct root field observations are
retained in `response-consumer-evidence.json`. The finish lambda is the same
1152-byte function previously labeled `profile_direct_caller_7`, now bound to
the actual quest-finish request lifecycle. It must not be cited as a home/login
reader merely because it refreshes the shared user profile.

The start lambda passes the entire `sugoroku` JSON value to a 92-byte original
state method that resets caches and copies/swaps that value. This establishes
reuse of the original map-state path, but supplies no map schema or valid enemy
payload. Downstream original map/encounter readers remain the next requirement.
The finish lambda forwards the result to the original result-model factory;
its constructor/reader must establish rewards and progression requirements.
No fabricated response/default values are admitted from these observations.


The finish result's ARM64 path now proves that the same callback JSON root is
passed through the 112-byte shared-owner factory and 76-byte owner constructor
to a 4-byte alias of the 1244-byte actual result reader. The hidden result is in
X8, not an extra ordinary input. The reader directly consumes root `exp`,
`zeni`, `user_exp`, `gasha_point` as signed 32-bit integers; `boosted` as boolean;
`friend_status` and `continue_count` as unsigned 32-bit integers (friend status additionally
passes through an enum mapper); and `prev_record_time_ms` as signed 64-bit integers.
`clear_time_ms` is explicitly checked for null, producing native sentinel -1
when null and a signed 64-bit read otherwise. Those are source behaviors, not new
server starting values. It iterates `quest_clear_rewards`,
`cleared_difficulties` and `dragonballs`, with further original nested/reward
readers. Thus a complete finish response is still unverified, and no reward or
persistent save is claimed from this DTO evidence.
