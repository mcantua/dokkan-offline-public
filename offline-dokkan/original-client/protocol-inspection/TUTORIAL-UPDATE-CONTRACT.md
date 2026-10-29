# Actual original-client tutorial update request

The pinned supplied original iPhone engine, not an authored game harness, was
inspected readonly. `research/tutorial-update-contract.json` records exact
body hashes and the proven source flow. No client was executed or patched.

## Method and relative suffix

The264-byte tutorial update constructor materializes the resource/name string
`tutorial` and passes method-kind2 into its712-byte game API ancestor.
The complete register chain is:

| Boundary | Source of the method kind |
|---|---|
| Tutorial constructor264bytes | literal2 into argument1 of game API ancestor |
| Game API ancestor712bytes | original argument1 forwarded as argument6 |
| Request ancestor352bytes | original argument6 forwarded as argument2 |
| Common request constructor420bytes | argument2 stored at request member188 |
| Actual derived request virtual getter17 | reads that same method member |
| Actual derived request virtual method2 | inherits the exact1284-byte materializer |
| Previously pinned Foundation method table | kind2 becomes `PUT` |

The actual tutorial-derived vtable was recovered; its getter/materializer
hashes match the earlier bootstrap contract. This is not an assumption that
an unrelated request has the same layout. Existing unchanged Foundation proof
was reused rather than rerun.

The resource/name string follows a separate argument chain into the common
constructor's native string at192. The248-byte suffix helper appends that
string and, conditionally, `?` plus native query string136. The664-byte URL
builder constructs `/` plus that suffix through the imported standard string
concatenation function, then appends it to the configured prefix/port.
Thus the reviewed relative suffix is `/tutorial`, optionally with a query.
The configured host/port value and complete runtime URL were not read or
verified; query absence for this request is not established. No handler for a
guessed full path was registered.

## Body before serialization

The constructor converts its caller's signed32 progress input into a native
JSON numeric value and writes member `progress` through the mutable JSON
member helper. The240-byte body setter copies the supplied JSON object and
adds member `timewarp` from the request's raw64-bit native field16. It then
stores the serialized result in the request string at112, used by the
existing materializer.

These are field/value-origin facts. No current progress, timewarp value,
server clock offset, account data or source key was read or adopted. The
meaning/lifecycle of timewarp and complete on-wire serialization remain
unverified. Do not invent `timewarp=0`, starting progress or a complete request
fixture from this evidence.

The source-derived name `timewarp` was admitted only after reviewing the
actual static JSON member-name argument in the pinned setter. Unknown source
literals were not dumped. Request virtual slots3/4 are its raw16-byte-offset
getter/setter, not a response parser; this distinction was shared with the
auth trace.

## Response and starting-policy limits

A tutorial response callback has not yet been tied to this request. Other
unbound native readers mention `progress`; their fields cannot be declared
this endpoint's response merely because the names match. Virtual slot20 was
checked and reaches request preparation/materialization, so it is not being
misrepresented as a typed response factory.

The actual fresh master still does not establish starting tutorial values or
capacities. [FRESH-MASTER-SOURCE-FACTS.md](FRESH-MASTER-SOURCE-FACTS.md) and
[TUTORIAL-STATE-CONTRACT.md](TUTORIAL-STATE-CONTRACT.md) describe those separate
boundaries. The existing projector already has the correct `user.tutorial`
nesting. No duplicate projector, fabricated server response or newly admitted
route was added.

## Continue in the cloud

`recover_tutorial_update.py` restores only the11 reviewed body spans by exact
length/hash into an ignored private manifest. It emits no instructions,
addresses or raw data publicly:

```sh
python3 offline-dokkan/original-client/protocol-inspection/recover_tutorial_update.py \
  offline-dokkan/private/source-client/OriginalDokkanEngine.dylib \
  --private-output offline-dokkan/private/research-tutorial/reviewed-update-spans.private.json
```

That manifest is ready for the targeted cloud decompiler and for the existing
`trace_tutorial_state.py --frontier-from` mode. Follow the tutorial request's
actual callback installation and serialization function, resolve timewarp's
native value source, and confirm the configured URI/query contract. Do not
repeat old master/schema or reader inspections. No compiler, native test,
HTML/app build, physical device, save folder, signing key or personal internet
connection was used for this work.

The initial common/auth direct-caller-only scanner missed the intermediate
game API family; its unneeded untracked script and intermediate public
receipts were removed after this exact frontier was retained. Private working
summaries remain ignored for continued analysis. The shared164-byte
string-construction helper is not a
proven database query operation simply because table loaders pass SQL text.
