# Persistent own-player binding for the original TeamModel

This is an adapter identity and save-layout contract, not a claim about the
original server's starting teams. Empty new accounts receive no team, name,
BGM, unit or selection merely because this adapter exists.

## Atomic snapshot

The existing native owner should include this property in the same canonical
player snapshot and profile revision, after checking the same persisted save,
profile and content scope:

```json
{
  "original_client_teams": {
    "schema": 1,
    "bindings": [
      {
        "slot": 0,
        "native_num": 7,
        "name": "Received own team name",
        "team_bgm_filename": null,
        "card_slots": [11, 0, 12, 0, 0, 0]
      }
    ],
    "selection": {"selected_team_num": 7}
  }
}
```

These example IDs and text are synthetic, not defaults. `slot` is the existing
Core slot. `native_num` is the original client's positive signed32 map key.
Their persisted association is explicit; neither field is derived by blindly
adding one to the other. Bindings must be unique by both `(profile, slot)` and
`(profile, native_num)`. `card_slots` retains exactly six ordered positions.
Every nonzero value is an existing, unconsumed owned instance in this profile,
with no duplicate nonzero instance. Filtering zero positions in order must
exactly equal the corresponding canonical `teams[].members`; projection must
reject a stale layout rather than silently changing formation.

`selection` contains only actually persisted choices. A missing selection is
unresolved, not an instruction to select team zero or create a first team.
The original post writer emits selection fields only for positive arguments.
Ordinary and Kobetu selections stay distinct. A choice must refer to an
admitted own binding; do not replace a missing regular selection with Kobetu.

Names are exact persisted UTF-8 strings, including an actually received empty
string. BGM is exact persisted null/string. The native row reader has no
proven UI text-length limit yet; a storage/request budget must be labeled as
our implementation budget, not an alleged official limit. Never adopt played
account names/BGM from a source cache, synthesize a URL/path, or add an asset
grant through this record.

## Native-only atomic write

Use one existing-owner queue operation with the expected persisted scope and
profile revision. A received own-client update may upsert these bindings and
update canonical `teams[].members` in the same Core transaction. Preserve
unlisted teams and omitted selections. Validate the entire batch before any
write; stale revision, duplicate keys/instances, foreign/unowned/consumed
instances, malformed six-position layouts or unavailable slot capacity roll
back the whole operation. This operation never creates an owned card.

For an already known `native_num`, retain its Core slot. For a new number
actually received through the admitted own-client path, allocating a free
Core slot is our explicit persistent adapter policy, not a recovered source
server default. The existing twenty-slot Core capacity must reject exhaustion
without silently replacing another team. Initial approved fresh-player policy
is a separate owner of any first-team creation.

The snapshot must come from the actual Core owner, not a caller-supplied JSON
claim of native authority or an optional projection-only policy. No WebView
operation exposes trusted binding writes. Existing generic Core team edits
that no longer match a retained layout must fail inside their mutation
transaction with an explicit layout conflict, preserving the original saved
formation. Identical ordered membership preserves its existing six positions;
unbound legacy teams remain editable. No invalid binding may be committed.

## Projection

Use the existing `resources-projector.js` and its native wrapper. Read the
persisted binding only from the atomic own-player snapshot, confirm every
binding against canonical teams/cards, and emit original rows as
`{num, name, user_card_ids, team_bgm_filename}` with all six positions retained.
Guard signed32 numbers and exact JS integer representations of owned64 IDs.
Configured resource policy may not override own teams or selections. Missing
bindings/selection are explicit unresolved issues; no HTTP readiness or native
runtime acceptance follows merely from producing a matching JSON candidate.
