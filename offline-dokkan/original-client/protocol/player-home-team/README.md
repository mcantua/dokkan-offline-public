# Original iPhone player, home and team contracts

This folder follows the real supplied client. It does not implement another
home screen, collection, battle engine or account fixture.

The existing `resources-projector.js` remains the reusable data projection.
It takes an atomic own-player snapshot and trusted policy, preserves ledger
balances and owned instance identities, and rejects stale scope or invented
engine IDs. It must stay unbound to HTTP until the actual current-client
consumer and required sections are established.

## What the current reader proves

The exact 2,416-byte native User decoder is retained in the private scoped
Ghidra program. The first four-function decompilation completed, with every
high-Pcode instruction site inside its declared source body. The profile
reader's own body references the reviewed fields recorded in
`literal-annotations.json`. These are real source references, not completed
login, home or collection behavior.

`annotate_reader_literals.py` creates private literal-address annotations for
already pinned bodies, so the scoped decompiler can identify field names
without copying unknown strings into public reports. It performs no new
whole-image caller or literal-reference search. The source image and each
selected body must match their pinned hashes.

The adjacent 1,212-byte caller also references link-skill level-up items,
quantity and skill level. It is therefore unsafe to identify that caller as
the home/resources handler merely because it updates `user`. Its exact
request binding remains open. The 688- and 1,152-byte callers also update
`user`; that fact alone does not identify their routes.

## First playable path

1. Bind the proven auth request materializer and completion path to the real
   nonce/token consumers. Reuse the auth worker's evidence instead of
   guessing a JSON wrapper or response content type.
2. Apply the User decoder's actual scalar conversions. This source step is
   implemented: peer-checked ARM64 converts its numeric fields as unsigned32,
   unsigned64, and signed64 for `act_at`. `resources-projector.js` now rejects
   unsigned32 overflow and inexact JS64 integers without clamping or changing
   HTTP gates. One focused projection scenario passed; see
   `native-integer-projection-evidence.json`. Timestamp units and fresh-state
   values are separate unresolved policy questions.
3. Recover the actual resources/home consumer and its ordinary owned-card
   and team readers, then connect the existing own-state projector to those
   exact relative fields and request paths.
4. Establish a fresh own-player policy from the agreed rules and verified
   source facts. Played source-account values and constructor sentinels are
   not fresh-player defaults.
5. Verify startup, offline login, home, ordinary team selection and one real
   battle before expanding Creator resources or custom battle integration.

There is no admitted player/home/team HTTP route and no native-runtime
acceptance yet. No app build, game execution, device access or personal
connection was used for this work. Private decompiler inputs and detailed
continuation queues stay under ignored `private/research-player-team/` and
`private/ghidra/`; only tool source, hashes and contract facts belong here.

## Team reader discovery

A single exact-name pass over five reviewed team fields identified 17
candidate bodies. It does not establish any endpoint. The scoped follow-up
distinguished an actual 488-byte read path from two JSON writers: the reader
selects `selected_team_num` and `selected_kobetu_team_num` through the known
40-byte member selector, then the same signed32 conversion used by the auth
TTL reader. It also selects `user_card_teams` for collection decoding. The
2,112- and 1,436-byte candidates instead use a different mutable-member/assign
path and must not be mistaken for response DTO consumers. The later work below closes writer ownership and the direct team request
bindings; home/collection and native runtime acceptance remain open.

The exact scoped decompilation of the 488-byte reader and 1,436-byte writer
stayed inside each declared body. The 2,112-byte candidate's high-Pcode
footprint includes seven sites outside its declared body; no claim of exact
2,112-byte-only interpretation is made. The string getter's decompiler also
followed additional bodies, so this work does not claim its entire string ABI
from the nominal 412-byte entry alone.

`team-reader-contract.json` now records three concrete callback paths: one
passes callback JSON directly into the collection reader, another selects
its `teams` child first, and an update callback also passes JSON directly.
The direct fetch/update registrations now bind to the original GET/POST
`/teams` family below; the ResourcesModel request route remains separate. The reader
reaches the actual 796-byte row decoder and separate 320-byte team-BGM
decoder, matching the previously sanitized resource nesting. This does not
authorize mapping Core slots to native team numbers or copying cached teams.

The previously selected 1,152-byte User caller has since been identified by
the battle worker as the real quest-finish success consumer, with the same
body hash. It is useful shared reader evidence, not a home response handler.
Reuse that interpretation rather than requesting another decompilation.

## Native team-number and formation semantics

Peer review of the actual ARM64 `postTeamsAPI` writer establishes that the
two selection arguments are emitted only when positive. Each row's `num`
comes from its `map<int, UserDeck>` key, separately from the JSON array's
enumeration index. Its `user_card_ids` always serializes six positions: a
64-bit owned-card object ID in an occupied position, zero in an empty one.
The later four-byte array belongs to another field and must not be treated
as the owned-card IDs.

Core currently stores compact `teams[{slot,members}]` arrays without zero
entries. A real native formation can have empty positions, so importing it
by merely removing zero IDs would lose formation layout. Core13 now adds an explicit own-player binding for native numbers and
the six positions, while preserving canonical compact members. No `slot + 1` mapping, missing team,
name or BGM default has been introduced. The original number is opaque; our persisted association is an explicit
adapter identity choice, not an alleged recovered server default.

## Exact team request method and relative path

The actual `TeamsIndexAPI` constructor passes kind 0 and the resource `teams`
to the exact 712-byte game-API ancestor already established for tutorial
requests. `TeamsUpdateAPI` passes kind 1 and the same resource. Their real
vtables inherit the same method getter and 1,284-byte materializer used by
auth. Reusing the already reviewed ancestor/storage/URL/Apple-bridge chain
establishes static `GET /teams` and `POST /teams`, optionally with a query.
No complete configured runtime URL or query absence has been assumed.

The known request setup binds the actual force-fetch and post success
consumers. The separate ResourcesModel callback selects the `teams` child.
The formation-save UI caller passes zero for the selection argument and an
explicit deck map, which means that write preserves the selection under the
positive-only writer rule. It does not establish `Core.slot + 1`.

Concrete own-team projection now reads the atomic persisted binding contract
in `CORE-TEAM-BINDING.md`. The new Core `original_teams.c` module owns schema,
normalized native updates, snapshot serialization and ownership/layout
validation. The existing projector consumes that real snapshot property,
preserves all six positions, and rejects missing bindings, stale formations,
foreign cards or policy overrides. It adds no second optional JSON policy
that claims native authority without actual persistence. Core13/native-owner
hooks are implemented and the first combined SQL-to-projector scenario
passed; native code remains uncompiled. HTTP admission and native playtest status remain
false until the actual route and original client are connected.

## Verification boundary for the persistent team implementation

`check_core_team_projection.js` accepts the actual synthetic Core SQL snapshot
from the combined migration/ownership scenario on standard input. It checks
that the existing projector retains an opaque native number independently of
Core slot, exact six-position gaps and saved name/BGM, while rejecting stale
layouts, unowned IDs and policy replacement. The empty-account case creates
no team or selection. The Core worker owns the combined run; this worker does
not duplicate it or compile a native app. Its receipt is separate from the
older numeric-boundary scenario, whose unchanged source facts are reused.

## Complete POST metadata and independent teams adapter

The full known field-write set of the actual 2,112-byte writer has been
reviewed. Row reference IDs are signed32; owned formation IDs remain64-bit.
The three optional top-level quest-context IDs are unsigned32. The Core
module now retains references and advisory context without granting cards or
advancing quest progress. Unknown historical references remain null and keep
projection pending. No fresh team/name/BGM/selection is manufactured.

The same existing native projector exposes dedicated GET teams projection
and decoded POST normalization, independent of unresolved full-user policy.
The normalizer preserves saved BGM, six positions and omitted selection or
context; it separates `timewarp` from gameplay clocks. It never decodes a
signed/compressed transport body or executes an HTTP request.

The second, changed-metadata-only combined check passed on its first run:
`python3 offline-dokkan/core/check_original_client_state.py --metadata-only`.
`check_native_team_metadata.js` consumed its actual synthetic SQL snapshot
and returned the normalized mutation for the same SQL round trip. See
`native-team-metadata-evidence.json` and Core
`original-team-metadata-evidence.json`. The earlier migration, ownership and
layout evidence was reused without rerunning that scenario.
C/Objective-C compilation, original-client execution, home/collection route
contracts and first-team initialization remain outside these receipts.
