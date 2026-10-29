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
path and must not be mistaken for response DTO consumers. Team-member rows,
model ownership and request binding remain under investigation.

The exact scoped decompilation of the 488-byte reader and 1,436-byte writer
stayed inside each declared body. The 2,112-byte candidate's high-Pcode
footprint includes seven sites outside its declared body; no claim of exact
2,112-byte-only interpretation is made. The string getter's decompiler also
followed additional bodies, so this work does not claim its entire string ABI
from the nominal 412-byte entry alone.
