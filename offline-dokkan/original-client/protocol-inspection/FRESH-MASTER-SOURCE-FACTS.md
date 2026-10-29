# Actual master facts for a fresh offline account

The current private source master was restored in the cloud from Drive object
`1dQDs-QyZXxuT6X_vg6ZfIJrevBtUT8x0` (19,252,226-byte ZIP; SHA-256
`7c07bc6f12a29b71f4ccc7b563ba3d40b217cc9e28e50a902324bdcd51413901`). Only its exact `database.db` member was restored to the
ignored, readonly `offline-dokkan/private/fresh-master/reference.db`.
The database is114,827,264bytes, SHA-256
`1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4`.
No source cache, player state, signing material, key or private configuration
was read. No Mac/device/personal connection was used.

`inspect_fresh_state_master.py` is a reusable hash-pinned, readonly inspector.
It emits only reviewed schema names, counts and admission booleans. Its one
focused data scenario produced
`research/fresh-master-structural-contract.json`. This is source analysis,
not an application test, native compile or game launch.

## Established source facts

- The master contains exactly one fresh-rank row with integral fields,
  zero starting rank EXP, positive ACT capacity and nonnegative friends
  capacity. Those four fields are already projected by Core's
  `od_offline_player_snapshot`; no replacement constants or new game rows are
  needed. This report does not export the scalar source values.
- Tutorial content has16 phase definitions,17 step definitions and73 process
  definitions. Every step points to an existing phase, every process to an
  existing step, and ordering numbers do not collide inside their owners.
- No phase has number0. The native initializer's `contents_lv=0` and
  `progress=0` therefore do not establish a direct phase-number mapping or
  justify selecting a phase by treating those sentinel fields as row IDs.
- None of the seven unresolved tutorial/capacity user-state names occur as
  columns anywhere in this master. Tutorial tables describe content;
  they are not initial player-state records.
- The only relevant client-setting keys are
  `shop_expand_card_capacity_max` and `shop_expand_card_capacity_use_stone`.
  They describe shop expansion limits/prices, not a fresh player's starting
  card capacity. No setting values were exported or adopted.

## What remains unresolved

The source data does not establish fresh server values or the original
client's mapping for `tutorial.progress`, `tutorial.contents_lv`,
`tutorial.is_finished`, `card_capacity`, `total_card_capacity`,
`support_item_capacity`, or `is_support_item_capacity_extended`.
A complete local first-run payload needs the original tutorial-state consumer
and phase-transition contract, or equivalent actual fresh-response structure
and policy evidence. Played-account cache values and model constructor
sentinels are unsuitable replacements. Do not use shop maximums as starting
capacities or mark the tutorial finished merely to reach the home screen.

The existing `fresh-state-policy.js` and native policy gates remain unchanged.
No success body or route was enabled. This narrows the missing contract; it
is not a claim that fresh-account startup is playable.

## Repeat only when affected

```sh
python3 offline-dokkan/original-client/protocol-inspection/inspect_fresh_state_master.py \
  offline-dokkan/private/fresh-master/reference.db \
  --output offline-dokkan/research/fresh-master-structural-contract.json
```

The inspector rejects any source with a different byte length, hash or
required schema. Revisit those pins deliberately when adopting a new master;
never silently treat an unrelated database as the established source.
