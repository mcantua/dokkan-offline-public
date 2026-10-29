# Persistent own-player binding for the original TeamModel

This is an adapter identity and save-layout contract, not a claim about the
original server's starting teams. Empty new accounts receive no team, name,
BGM, unit or selection merely because this adapter exists.

## Atomic snapshot

The existing native owner includes this property in the same canonical
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
        "card_slots": [11, 0, 12, 0, 0, 0],
        "references": null
      }
    ],
    "selection": {"selected_team_num": 7},
    "advisory_context": {}
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
without silently replacing another team. New profiles still start with no
team. The first team is created only from an explicit formation submission,
as described below.

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
`{num, name, user_card_ids, team_bgm_filename}` plus the three persisted
reference fields described below, with all six positions retained.
Guard signed32 numbers and exact JS integer representations of owned64 IDs.
Configured resource policy may not override own teams or selections. Missing
bindings/selection are explicit unresolved issues; no HTTP readiness or native
runtime acceptance follows merely from producing a matching JSON candidate.

## Complete writer metadata

The actual 2,112-byte `postTeamsAPI` writer has now been reviewed through all
known mutable JSON field writes. Its row is exactly `num`, `name`,
`user_card_ids`, `referenced_sugoroku_map_id`, `referenced_z_battle_stage_id`
and `referenced_card_ids`. The last three use actual signed32 JSON
constructors; the vector contains signed32 reference IDs, not owned64 IDs.
BGM is read by a separate response decoder and is absent from this POST row.
The decoded POST normalizer therefore preserves the saved BGM.

`bindings[].references` is null when historical metadata is unconfigured, or:

```json
{"referenced_sugoroku_map_id": 0, "referenced_z_battle_stage_id": 0, "referenced_card_ids": []}
```

This example illustrates types only; these values are never granted as
fresh-player defaults. A nonnull object requires all three keys. Projection
stays pending while references are unknown. An omitted/null normalized update
preserves existing references; a complete received object replaces them.

The three optional top-level writer fields `sugoroku_map_id`,
`z_battle_stage_id`, and `origin_battle_id` use actual unsigned32 constructors.
They are stored only in `advisory_context`. They grant no progression, quest,
card, currency or reward. Omission preserves the existing context; a provided
object replaces it. The request's separately added `timewarp` is retained
only as transport metadata when its integer is exactly representable. Its
signedness/lifecycle is not established here and it never becomes the game
clock.

The implementation's own budgets are 4,096 UTF-8 bytes per name/BGM,
256 KiB per normalized batch, 32 KiB per reference object, and 1,024 reference
IDs. These are storage limits, not recovered official UI limits.

## Concrete owner and methods

`core/original_teams.c` supplies schema, validation, snapshots and savepoint
updates on the existing canonical SQLite connection. Core13 calls these
inside its own transactions; the module never advances a revision, commits
the owner's transaction, creates a second connection or owns command replay.
The native-only owner entrypoint checks persisted scope, command identity and
revision and rejects a held Creator lease. Ordinary JSON/WebView commands
cannot invoke native team writes. Canonical mutations and imports validate
retained layouts before commit.

`resources-projector.js` exports `projectTeams(envelope, expected)` and
`normalizeTeamUpdate(envelope, expected, decodedBody)`. The native wrapper
exposes `projectCurrentTeams:` and `normalizeOriginalTeamUpdate:reply:` using
the same Core owner. GET projection is independent of unresolved full-user
capacity policy. POST accepts only an already decoded object. Existing
bindings preserve their BGM; new user-submitted bindings use the explicit
no-custom-music policy below. The normalizer returns a revision-bound
mutation, not a committed write.

The native route adapter now registers GET/POST `/teams`, separately from
this data-only module. POST requires the actual same-image original decoder
capability and current engine verification before invoking the same Core
owner transaction. Historical SQL/JS receipts do not prove native runtime.
The actual original-client team screen, empty-team flow and write/read round
trip remain unverified.

The first combined Core13 SQL snapshot/projection check and the second
changed-metadata-only SQL→GET/POST normalizer→SQL check each passed once.
Receipts: `core-team-projection-evidence.json`,
`native-team-metadata-evidence.json` and Core
`original-team-metadata-evidence.json`. These execute actual extracted SQL
and JavaScript, not C transaction/replay control flow or Objective-C.

## First user-created formation

A genuinely empty canonical team list projects as `{"user_card_teams":[]}`.
No selection is emitted. The retained 488-byte reader iterates no rows; its
absent selection goes through the already-proven signed32 null-to-zero
conversion, retaining the native zero/unselected state. This is a source
contract for the response, not proof that the running empty-team UI offers
a creation control. Nonempty teams still require an actual saved selection
before their GET response is considered complete.

An explicit decoded original formation POST may contain a new positive
`num`. Its actual supplied name, complete reference fields and exactly six
owned-ID positions become the new binding. Core allocates a free slot in its
existing atomic transaction. A supplied selection may point to this new row
in the same transaction. Omitted selection remains omitted; the adapter
does not pick the first team. No unit, currency, reward or music asset is
granted. Existing bindings and their saved BGM are preserved.

The actual original writer has no BGM field. For a **new user-submitted
formation only**, our explicit app policy is **no custom formation music**,
stored and projected as the empty string. This is not a recovered original
server starting value or a music resource path. Names and numbers remain
the user's received values. Historical null/string BGM remains exact. The
actual 412-byte native string converter's bounded null-tag branch also
targets a proven NUL empty-string constant, so preserved null is not an
invented filename. The broad decompiler's 278 outside-body instruction sites
are not attributed to this proof. The
trusted native owner's existing `applyDecodedOriginalTeamUpdate` method may
also serve a concrete user formation action; ordinary WebView JSON cannot
obtain this authority. Legacy canonical teams without any native binding
remain unresolved rather than being silently renumbered.

The exact skip-policy User-only DTO stays available after cards or teams are
created. Its response still contains only `user`: it does not replace or
claim synchronization of the collection model. Existing unfinished tutorial
projection retains its previous empty-collection restriction.

`first-formation-evidence.json` records one focused JS scenario for this
changed flow, preserving BGM and positions and rejecting invalid ownership,
duplicate members, extra fields, dirty projection and an unowned selection.
The prior actual extracted Core SQL new-row allocation/ownership evidence
is reused. No new native compilation or game execution was performed by
this scenario.
