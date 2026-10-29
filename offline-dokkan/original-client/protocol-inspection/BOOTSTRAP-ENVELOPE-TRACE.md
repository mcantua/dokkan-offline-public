# Bootstrap envelope caller recovery

The supplied prepared iPhone engine was examined statically in the cloud. All
ten original bootstrap function-body hashes and sizes matched the existing
`research/bootstrap-auth-contract.json` pins exactly. No original application
was run or compiled. The prepared file was unchanged.

`trace_bootstrap_envelope.py` recovers those bodies from function starts, indexes
direct calls and tail branches, and bounds the caller/pointer-neighbor review.
Its Capstone dependency is pinned separately under `downloads/capstone/`. One
analysis invocation examined18 bounded caller/neighbor bodies. Detailed
symbolic summaries stay under ignored `private/research/`; the public record is
`research/bootstrap-envelope-recovery.json`. There are no raw instructions,
addresses, unknown literals, credentials or player values in that record.

## Established control-flow facts

- The nonce reader's4-byte alias tail-forwards its inputs unchanged. Its exact
  SHA256 is `bf9475f857991a4bb81625ac6fd7b84106e09bebfb84c221813aeaa35af21ba0`.
- The recovered200-byte caller passes its third input unchanged as the nonce
  reader's second input. Its SHA256 is
  `34cf3d5c78c7bae97efb781db82c8b72f67b04bddd16d8d62865771a440aaac2`.
- The already-pinned396-byte token consumer performs its `access_token` and
  `expires_in` lookups relative to its third input.
- Neither callback has a direct caller in the examined executable text. Both
  have image pointer references; the original dispatch remains indirect.

These observations restore the lost caller checkpoint and move the unresolved
boundary to the JSON value supplied by the virtual response dispatcher. They
do not prove that value is the complete HTTP JSON root. A `data`/other wrapper
could be selected upstream. Pointer adjacency is not proof that every neighbor
belongs to the same C++ vtable; no ABI or route was enabled from adjacency.

## Exact remaining work

Identify the callback address-point/virtual slot and the dispatcher that supplies
its third input, then trace that value back to JSON parsing. Until this chain is
proved, retain `wire_body_envelope_verified:false` and keep auth response/route
enablement closed. No fresh-account values, nonce formats or full sign-in
response requirements were established. A future authorized runtime check is
separate from this static evidence.

The symbolic inspector is conservative at branch joins and deliberately omits
unknown strings. Its call summaries aid manual review; they do not constitute
an automatic proof of whole-function behavior or runtime acceptance.

## Continued virtual-dispatch and holder trace

One new combined static invocation recovered each callback's structural primary
C++ address point: both callbacks occupy zero-based virtual slot6 (byte offset48),
with offset-to-top0 and9 consecutive function entries. Exact callback hashes
match the preceding evidence. The two address points are materialized in the
320-byte nonce setup body (SHA256
`396546cf7e90c266a4227dad916ccc6241bf5d7a2d869199a4369aae9a4895e3`)
and the748-byte token setup body (SHA256
`21bc9017688c88ec138be07f7f1bcde4c85cbb59dbf45c08912cb5a5349c3348`).
Nearby pointer entries alone were not used to identify a response receiver.

The same-slot candidate index found2028 bodies; only10 exposed one of the
allowlisted JSON field names in this conservative summary. This is an index of
possible call sites, not2028 confirmed bootstrap dispatchers. Detailed summaries
and source coordinates stay private. Public
`research/bootstrap-dispatch-frontier.json` retains only structural identities,
counts and limits.

A focused holder pass initially found no request vtable because its RTTI/virtual
entries differ from the callback family. One necessary correction admitted a
request table only when its existing materializer slot2 and method-kind getter
slot17 matched their already-proved body hashes. Two request tables were then
identified. Their setter slots8/10 share two8-byte thunks:

- Slot8 adjusts its first input by48bytes and tail-forwards to a148-byte helper.
- Slot10 adjusts that input by80bytes and tail-forwards to the identical helper.
- Helper SHA256 is
  `e5dc1f0612a5d1ae6280dae15062b1fa5cfa4625264d84a60d4cef86ef9772ec`.
  Its copy/swap family accesses a polymorphic callable pointer at container+24.

This narrows candidate invocation holders to request+72 and request+104.
Reusing the saved candidate summaries, without another same-slot scan, found a
1432-byte candidate (SHA256
`a7d135a3e5f611e4fe73e1a97e0a848ad8bbe91b276b69c3c67597f7e3b6ea57`)
calling the+72 holder at virtual slot6 and passing a local object as its third
input. A preceding720-byte helper has SHA256
`e551358ed7c7b5690cabc23114060313f24420be48d62967fcc1c270f366d10a`.
That helper's role as JSON parsing or root/wrapper selection was not proved.
The candidate receiver itself is not yet bound end to end to these two requests.
These facts therefore do not settle the HTTP envelope.

## Requiredness fallback and exact continuation

The nonce and token lookup wrappers both reach the same284-byte key-lookup helper
with SHA256
`c9e952bd968f1fdc300e030fa8122dbce410053c08c3542ca4144adc57d6c1f6`.
Its key input is represented by begin/end pointers. Missing-key behavior and the
subsequent string conversion remain unproved. At the first checkpoint two bounded
attempts to recover additional requiredness helpers failed closed: the saved-focus
locator omitted tail branches, and the needed direct-callee records were split
between retained summaries. The corrected locator now accepts both encodings
and merges only retained private metadata. A later narrowed continuation recovered
the four exact lookup/copy/conversion bodies in one successful invocation.
`research/bootstrap-field-requiredness-frontier.json` records their identities;
it does **not** establish missing-field behavior or string strictness.

Next use the saved `private/research/bootstrap-dispatch.private.json`,
`bootstrap-receiver.private.json`, `bootstrap-holder-accessors.private.json` and
`bootstrap-json-input.private.json` to continue exact identities. Prove the
request-holder receiver and720-byte helper before changing any HTTP-root flag.
Alternatively, recover the284-byte lookup and its conversion paths with the
corrected tail-branch locator to establish missing-field behavior. Keep full
envelope, runtime acceptance and route enablement flags false meanwhile.

## Important frame-provenance correction

The1432-byte candidate was narrowed further with a control-flow analysis of
affine stack aliases, joining conditional paths conservatively. This followed
only that body and the720-byte helper; it did not repeat the caller/slot scan.
The two local objects are distinct:

| Candidate call ordinal | Relevant stack alias (relative to entry SP) |
|---|---|
|16: virtual slot6 through manager member+704 | x8 points at local−104 |
|17: another indirect slot6 call | x2 points at local−104; x8 at local−136 |
|28:720-byte helper | x2 points at local−136 |
|29 and39: request+72 callback | x2 points at local−104 |

The720-byte helper therefore receives the other local buffer. It must not be
described as the producer of the object passed to the auth callback from this
evidence. The decisive next target is call17's callable, which receives the
response argument alongside the eventual callback-local object, plus call16's
callable stored through manager+704. The role of x8 as a hidden return destination
still requires the actual callee ABI; its register value alone does not prove it.

`research/bootstrap-json-frame-control-flow.json` records358/180 decoded
instructions and325/159 reachable instructions for these two exact bodies.
`trace_bootstrap_frames.py` preserves the small analysis for future continuation.
Its CLI wrapper was saved after the equivalent inline analysis; no redundant
wrapper run was performed. The existing linear receiver summaries were also
improved to retain frame aliases and allowlisted CFString field tags. A proposed
helper expansion hit its explicit fanout bound; the successful narrowed follow-up
kept only the two bodies. This produced no additional response-schema admission.

The profile/tutorial workstream independently confirmed that the same40-byte
`dd42…` helper selects a JSON member using parent, key pointer and key length;
its returned child is handed to the known decoder. That corroborates member
lookup semantics, but still supplies no complete HTTP-root binding. See
`FRESH-MASTER-SOURCE-FACTS.md` for that workstream's current scope and limits.

A separate48-byte request-family slot6 body (SHA256
`b02a0b86a9a1c356ea3cb57c0a53ba4e446c7d1324d32d6876bfbc1638bc3724`)
was followed once to eliminate a false trail. It adjusts its first input by24
bytes and tail-forwards two values loaded from its second input to a412-byte
assignment-shaped helper. This is a different vtable from the callback-family
slot6; it establishes no JSON-parser ABI. Evidence:
`research/bootstrap-request-slot6.json`. Do not conflate unrelated tables merely
because their numeric slot index matches.

## Exact callback type from retained RTTI

The two already-recovered callback address points were classified using only
their retained type-info records. Both are libc++
`std::__1::__function::__func` wrappers whose exact encoded function type is:

`void(cocos2d::network::HttpResponse*, Json::Value&)`

The JSON argument is a mutable JsonCpp `Json::Value` reference. This is compiled
type evidence, not an assumption about nlohmann JSON, a string response, or an
HTTP envelope. These two callback bodies return void. Source RTTI names and
addresses remain in ignored `private/research/bootstrap-callable-types.private.json`;
public facts are in `research/bootstrap-callable-types.json`.

A bounded continuation through the retained rebase-pointer metadata classified
446 relevant JsonCpp callable records without another code/caller scan. Most
are consumers or predicates. No admitted record establishes a `Json::Value()`
factory for the manager member+704. Initial type-name filtering missed coalesced
RTTI in `__const`; the corrected prefix-first metadata lookup includes those
records. Unrelated records are retained privately rather than bloating the
public evidence. Their signatures do not establish call17's receiver.

The prior candidate index also contains a600-byte caller of the1432-byte body,
SHA256 `1f538d12ba3eb4e7833f2275c4850c3035bd047a9d872b2c581081fd3b26ec42`.
That is a useful next receiver-provenance path. Its parameter types and complete
HTTP-body binding have not been admitted. Continue exact factory/receiver
provenance, keeping the request-family slot6 and callable-family slot6 distinct.

## Ordinary JSON root recovered through the installed HTTP callback

The earlier1432-byte returned-string candidate was a different callable family.
It is not the missing producer for the void auth callbacks and is no longer
the critical auth-root frontier. The actual chain is now bound by exact body
identities and the closure RTTI installed by the current request materializer:

1. The1284-byte request materializer invokes a920-byte completion installer.
2. That installer copies request success/failure holders at offsets48/80 into
   a104-byte closure. Its actual RTTI operator is the pinned588-byte
   `void(HttpClient*,HttpResponse*)` completion.
3. The completion copies the response-data byte range into one string. Its
  216-byte codec predicate uses the508-byte `content-type` getter, splits the
   header value at a semicolon, and compares the media type with
   `application/x-zstd`.
4. The ordinary nonempty, non-zstd path parses the string through a116-byte
   wrapper and704-byte range-reader tail into one JsonCpp document value.
5. The completion passes that same value to the captured success/failure
   callback. It does not select a child wrapper. The previously pinned nonce
   and token consumers therefore read their fields at that document root.

This is a static plain-JSON envelope proof, not successful offline login.
Compressed responses, complete success requirements, token/transaction formats,
field requiredness, native transport binding and real original-client execution
remain pending. The new JavaScript/native body candidates choose
`application/json`; no route is enabled.

Scope accounting is explicit in `research/bootstrap-plain-json-root.json`.
The116-byte decompilation follows112 instruction sites into the separately
admitted704-byte tail, not a1404-byte helper. The920-byte installer decompilation
also follows53 sites into four other source bodies after unwind/tail handling;
those body identities are retained. The capture/registration facts above were
cross-checked against instructions inside the declared920-byte installer.
The content-type getter and codec predicate each remain within their exact
declared bodies. Raw C/highPcode, instructions and coordinates stay private.
No whole-game execution, native compilation, account request or source-key
extraction occurred.
