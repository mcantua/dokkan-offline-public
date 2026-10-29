# Actual original-client tutorial/profile reader shape

The supplied prepared original engine was inspected statically and readonly.
Its code/file offsets are preserved from the original iPhone6.6.0 client.
`research/tutorial-state-contract.json` records the exact source/body hashes
and the established relative field paths without code bytes or addresses.

## Established shape

Six recovered direct callers select member `user` through the same40-byte
JSON member wrapper, then pass that selected value unchanged into the pinned
2416-byte profile decoder. The profile decoder reads capacities directly from
that value, but selects its child `tutorial` before reading tutorial fields.

| Relative callback path | Native destination |
|---|---|
| `user.card_capacity` | 32-bit numeric field |
| `user.total_card_capacity` | separate32-bit numeric field |
| `user.support_item_capacity` | 32-bit numeric field |
| `user.is_support_item_capacity_extended` | byte boolean field |
| `user.tutorial.contents_lv` | 32-bit numeric field |
| `user.tutorial.progress` | separate32-bit numeric field |
| `user.tutorial.is_finished` | byte boolean field |

The40-byte member wrapper's hash is
`dd42e9a722691eec379059ee01aa2173858e9c7d57dd999863e33aa226704d78`.
It receives parent JSON, member name and byte length, returning the selected
child JSON. This same helper identity was shared with the auth trace to avoid
duplicating helper recovery or mistaking member selection for JSON parsing.

The scalar52-byte prior-value fallback and284-byte nullable lookup match
[the existing initializer contract](PROFILE-INITIALIZER-CONTRACT.md). Missing
or null scalar members preserve their prior native fields. This does not
prove that the parent `tutorial` object can be omitted, and does not make
constructor sentinels suitable for a fresh playable account.

These iPhone reader-relative paths match the existing sanitized Android
resource schema. The authored resource projector already uses that nesting;
no replacement schema/module or production projection change was needed.

## Actual tutorial data consumer boundary

A separate narrow table-reference pass found original native364-byte loader
bodies for `tutorial_phases`, `tutorial_steps` and `tutorial_processes`.
Their literal SQL is embedded as full SELECT expressions, rather than
standalone table-name strings. Each passes its SELECT to the same164-byte DB
helper; these SELECTs have no WHERE clause or bind parameters. Only schema
shape and function hashes are emitted in
`research/tutorial-table-frontier.json`.

All three loaders have the same direct608-byte caller, SHA-256
`c6f54e5ebf0d379205c2eb411ce3a49c8dce10ee6d039fa328276c2d9b8b1c6b`.
That caller reaches each loader and then organizes the returned collections;
its exact collection/key semantics are not established by that call graph.

This is native whole-table loading. The mapping from User tutorial fields to
selected phase/step/process therefore remains downstream in the loaded model
or cache consumer. It is not established by a fabricated SQL lookup or by
choosing the first master row. The actual master has no phase numbered0;
[FRESH-MASTER-SOURCE-FACTS.md](FRESH-MASTER-SOURCE-FACTS.md) records that separate
source fact and the unresolved starting-policy fields.

## Limits and next exact step

- Reader-relative `user.tutorial` is established. The upstream callback's
  parent JSON may still be an already-selected HTTP subobject; complete body
  root/wrapper and HTTP field-requiredness are not established here.
- Starting tutorial phases, capacities and their progression mapping remain
  unresolved. No scalar source/player values, account caches or keys were
  copied or used as defaults.
- Next follow the three loaded tutorial model caches to their actual
  phase/step consumers, then relate those lookups to the native User fields.
  Do not infer that `contents_lv` equals a phase ID or ordering number from
  the field name alone.
- No response route, body, source-game execution, compile, app/HTML build,
  native test, physical device or personal connection was used or enabled.

## Reusable bounded inspectors

`trace_tutorial_state.py` recovers four exact pinned profile/lookup bodies,
then its `--continue-from` mode uses the saved private nine-caller frontier
without repeating the old body/caller scan. Public evidence contains only
allowed field names, sizes, hashes and unresolved flags. Detailed addresses
stay under ignored `private/research-tutorial/`. Its `--loaders-from` mode
continues from a recovered tutorial loader-owner frontier without repeating
reader recovery or the whole text branch scan.

`trace_tutorial_tables.py` follows only the three reviewed table names inside
SELECT literals. The initial exact-standalone-string attempt found no such
literals; the concrete embedded-SQL discovery justified one corrected pass.
No passing native/app test or unrelated source investigation was repeated.
