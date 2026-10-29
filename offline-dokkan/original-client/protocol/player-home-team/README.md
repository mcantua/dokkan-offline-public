# Original iPhone player, home and team contracts

This folder follows the real supplied client. It does not implement another
home screen, collection, battle engine or account fixture.

Active new-profile policy: skip the intro using the persisted
`offline-new-player-skip-v1` record. Existing profiles keep their state. The
older unfinished-tutorial milestone below is retained evidence, not the
current new-player flow. Actual normal Home acceptance remains pending.

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

## Current Home/resources continuation

Retained current-client RTTI now identifies the actual ResourcesModel
success/failure callbacks and User/Card fetch consumers. All four exact
decompilations stayed inside their declared bodies. User selects the shared
root's `user`; Card selects `cards`, `user_card_id_updates` and `item_cards`;
the existing Team callback selects `teams`. Resources success also updates
`battle_status` after its consumer queue. These are concrete source
dependencies, not proof that an abbreviated player response can reach home.
See `home-resources-contract.json`. Exact registration owners and immediate
User/Card/battle-status updates are now recovered, each within its own body.
The User update calls the existing 2,416-byte decoder and aborts when decoded
rank is zero. Actual ARM64 confirms the check is at User byte 32; the apparent
`+4` in decompiled typed pointer arithmetic is not a separate validity flag.
The existing canonical positive-rank and UInt32 checks already cover this
gate, so no new default, source change or test was needed.

The actual 96-byte factory and 360-byte `ResourcesAPI` constructor now
establish `GET /resources/login` and `GET /resources/home` for those received
native request labels. They reuse the exact established 712-byte ancestor,
method getter and materializer. The constructor adds `battle_status:true`
only for `login`. The derived 92-byte override copies actual request item parameters through
the common body setter and tail-calls the already reviewed generic sender.
It is a send override, not a separate query getter. Its decompilation follows
the known 1,240-byte sender; those reused sites are recorded explicitly. No
configured full URL or absence of a query is assumed.

The separate `battle_status` update is optional in the actual native reader.
A missing child becomes the source-proven Json-null singleton, and any null
room/stage/force member skips all updates before stores. This is a native
skip with no invented default battle values. These facts still do not prove
a complete home response or admit an HTTP route.

## Retained unfinished-profile candidate

This section records the earlier tutorial-first milestone. The latest user
instruction skips the intro for new profiles; it does not reset existing
profiles. `projectInitialTutorialPlayer` and the same native wrapper emit
only own wire identity, positive canonical rank and persisted unfinished
tutorial progress. The native User callback selects `user` and calls the
reviewed decoder. Unconfigured capacities and `contents_lv` are omitted: its
actual default getter preserves the prior native fields on absent keys.
Explicit JSON null is not omission and is never emitted as a substitute.
This does not copy constructor sentinels into server state.

The mode requires the actual native-owned tutorial record, clean save scope
and empty own collection/teams. Migrated unresolved profiles and existing
collections are rejected rather than silently downgraded. Positive stored
tutorial checkpoints stay unchanged. It does not rely on the old Android
full-home schema, force a team selection or register a generic HTTP success.

`check_initial_tutorial_projection.js` passed one focused scenario; receipt
`initial-tutorial-projection-evidence.json`. The prior Core13/team checks were
not repeated. Native wrapper compilation, full resources endpoint dispatch
and actual tutorial battle remain unverified. The full Card row decoder and
full home DTO are separate pending work, not first-tutorial prerequisites
merely because the earlier cached schema listed them.

## Active new-profile skip-intro policy

New profiles now use `projectNewProfilePlayer` and native
`projectNewProfilePlayer:`. The exact persisted owner record must be
`{schema:1, policy:"offline-new-player-skip-v1", progress:0, is_finished:true}`.
This is the user's explicit new-profile policy, not a copied constructor
sentinel. The Core worker creates it only for genuinely new profiles.
Existing unfinished or completed profiles are not rewritten by projection.

The candidate emits only own identity, positive canonical rank and that
stored tutorial tuple. Unconfigured capacities and `contents_lv` stay
absent through the same proven native prior-value fallback. A populated
collection requires the full projection instead of silently dropping units.
The original User callback/root binding is established; reaching and
populating the actual normal Home still needs its consumer/source contracts
and runtime acceptance. No full-home, HTTP or gameplay completion is claimed.

`check_new_profile_skip_projection.js` passed one changed-policy scenario,
including preservation of an existing unfinished checkpoint. See
`new-profile-skip-projection-evidence.json`. Earlier unrelated scenarios were
not repeated; no native compilation or app build was performed.

The completed Title branch now reaches an identified original
`HomeMenuScene` statically: 172-byte finished gate → 872-byte normal
continuation → its already retained 2,304-byte tail → 160-byte factory. The
156-byte lookup passes actual `HomeMenuScene` RTTI as the dynamic-cast
destination. Its 104-byte allocator and 640-byte opener are distinct from
the original first `NoticeScene`. The next exact constructor/init scopes
will establish layout/model requirements; this is not a running Home screen
or proof that an empty collection works in it.

## Native resources adapter for the first client run

`ODOriginalPlayerResourcesAdapter` now supplies concrete native GET
`/resources/login` and `/resources/home` route objects. Its pure query policy
admits only known scalar flags and bounded decimal transport metadata. The
login flag `battle_status=true` is required, and its response can omit that
update through the proven native null guard. Unknown query shapes fail
closed; no network fallback, page authority or clock adoption exists.

The host installs static routes and supplies a main-only provider for its
actual scoped Core-backed projector after admission. Requests fail while it
is unavailable, check current context/activity before and after projection,
and retain the same issued projector identity through completion. The
response is the source-specific new-profile User DTO, with no root `sign`,
not a fabricated full Home response. The host owner is wiring these routes;
actual native compile/client launch results will determine the next required
fix. No additional duplicate source checks were run for this adapter.

The final Home constructor and 300-byte init scopes are now retained, both
own-body only. They initialize original native child layouts and controls.
Further speculative Home analysis is paused in favor of the actual client
run; empty-collection and Home runtime acceptance remain unverified.

The same native adapter now includes GET `/teams`, using the same deferred
Core-backed projector. The route returns the existing complete own-team DTO
only when `projectCurrentTeams:` supplies a nonnull serialized candidate.
Missing legacy bindings, unknown reference metadata or pending custom-unit
projection remain an explicit failure. A genuinely empty list now returns
`user_card_teams:[]` without creating a selection or team. It introduces no
team/selection defaults and no POST codec, and retains default query denial.
No older team checks were rerun for this native wiring.

Minimal User delivery uses the actual Core/user context independently of the
native-master observer. Requested card/team flags do not create extra data
in this User-only response. GET `/teams` additionally requires genuine
native-master currentness before and after projection. The factory supplies
the separate main-only predicates; the transport validator remains pure.

## Read-only practice input provider

`ODOriginalPracticePhaseProvider` reads the exact pinned selected-master
phase 3 parameters on a private readonly queue and returns unchanged UTF-8
JSON bytes to the original native parser. It checks current same-Core scope
before and after loading, verifies the original scene URI and shape, and
rejects known numeric owned-ID collisions. It creates no unit, team or
progression record. A clean Core snapshot does not prove a foreign native
cache is empty; the battle bridge owns that separate runtime guard.

This is input data for an explicit manual practice action. It does not restore
the skipped new-player intro or claim native-engine acceptance. Source
receipt: `practice-phase-provider-source.json`. Its factory/bridge integration
and native compilation belong to the next meaningful combined batch; no
extra isolated check was run.

## Original encoded team updates

The same route adapter now handles POST `/teams` through an optional original
request-decoder capability. It passes the exact wire bytes into that native
codec only. No plaintext substitute or base64-as-JSON path exists. The actual
engine must first pass the decoder's fixed native-owned JSON round trip; a
missing or unverified capability returns a specific failure without a write.

After decoding, the existing normalizer reads a fresh same-Core snapshot and
checks clean projection, actual owned IDs, saved metadata and proven writer
fields. The Core owner applies the normalized update with that exact scope
and revision, rejecting stale state or a Creator lease atomically. Response
data comes from current persisted teams. Request activity and the same
decoder/projector/master context are checked through asynchronous work.

An adapter-generated UUID names each admitted invocation; it is not an
invented original request ID. There is no permanent body-hash cache that
would forbid returning to a previous formation. A later identical request
is a new invocation and can advance the Core revision again. Cancellation
after a completed write cannot undo that accepted commit; a missing current
response is reported rather than falsely marked successful.

One new clean-admission normalization check passed; see
`team-post-clean-admission-evidence.json`. Old Core/team scenarios were not
repeated. Native codec self-check, an actual encoded save request, and the
real Core-to-client response round trip remain runtime verification work.

## First formation after creating a unit

An original decoded user formation submission can now create a new binding.
Its positive native number, name, six ordered owned-ID positions and complete
reference fields are retained. Existing atomic Core code allocates a free
slot; the request's actual selection can refer to the new row in that same
transaction. Omitted selection is not guessed. New formations use our
explicit no-custom-music policy (empty string), because the native POST
writer has no BGM field; all existing BGM values remain exact. This creates
no starter unit, reward, asset or automatic first team.

The skip-policy User-only response continues after cards/teams exist, so a
creation does not break later User refreshes. It emits no collection fields
and does not claim those models were synchronized. Existing unfinished
tutorial behavior is preserved. One focused changed-flow JS scenario passed
in `first-formation-evidence.json`; unchanged Core SQL evidence was reused.
Actual empty-team UI creation, original encoded POST, persistence and real
gameplay still need native execution.

Login/home now accept an optional native preparation waiter before their
first scope/projector admission. The actual Host shares its bounded initial
services queue and wakes requests only on real services binding or failure.
The adapter keeps each original request's activity/deadline, resumes once,
and rechecks the actual scoped projector and current context before use and
response delivery. A nil waiter retains immediate failure; no timer, polling
or native-master admission change is introduced. This is source integration
for the next combined native compile, not an additional runtime check.
