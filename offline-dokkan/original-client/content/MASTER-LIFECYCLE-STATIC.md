# Original master: first open and reload lifetime

This is static source analysis of the preserved original iPhone engine. No game
was run, no key-provider body or key material was read, and no database was
opened. It narrows the first-playable integration path; it does not admit a
database hook or claim that the original client has reached home or battle.

## The seed and downloaded master are separate candidates

The selected native entry constructs the default downloaded-master path and
resolves the bundled `database.db` basename separately. It passes these native
strings to its cached-open wrapper. The wrapper attempts the first candidate;
after a nonzero open/key result it attempts the nonempty fallback candidate.
The uncached wrapper then performs its native schema checks and compatibility
retry. This is a preferred/fallback open sequence, **not evidence that the
535,552-byte bundled seed is copied to the downloaded-master path**.

The preferred path defaults to:

```
<own-app-Documents>/assets/sqlite/current/<language>/database.db
```

A configured native resource prefix can change it. Host `_resources` does not
set this getter. The first-play diagnostic must preserve the actual bundled
seed and stage separately obtained compatible downloaded assets before loading
the prepared image. It must not overwrite the seed with the current Android
cipher master, point MAIN at the immutable source, or pretend that an external
plaintext read proves compatibility with the original engine's codec.

The native selected entry has two direct branch sites in one 104-byte caller.
That caller retries through the selected entry after result16, source cleanup,
an internal close and cache clearing. The retry selects a different fixed
nonempty native first-candidate literal. Its meaning and the cleanup helpers
remain unproven; it is not an admitted host retry API.

The original first-open path is asynchronous. A364-byte producer passes its
276-byte worker entry directly to `pthread_create`, then calls the original
`std::thread::detach`. That worker initializes libc++ thread-local state, calls
the152-byte master initialization path and schedules its captured completion
through the source scheduler. Do not invoke the worker or master entry on an
invented host thread or assume main-thread execution.

Before the ordinary selected open, the native468-byte method identified by the
source diagnostic `DatabaseManager::removeOldPragmaKeyDatabase` checks the
preferred downloaded path through the resource singleton. If present, it uses
the original opaque key/open/schema checks, closes its temporary cached handle,
and clears that field. Failed validation reaches a256-byte cleanup helper:
the actual resource file-removal method calls `remove`, and the tree-removal
method calls `nftw` with a callback that also calls `remove`. The reviewed
relative tree is `sqlite/current/`. Therefore a diagnostic candidate must be a
separate working copy in the new app's own container: the original validator
can remove invalid downloaded data. Keep the immutable source outside that
working tree. This is observed source behavior; no file was removed here.

The native152-byte initialization path next performs its original query and
enters the104-byte selected-open/retry caller if no result object exists. The
query's application meaning remains unproven. These bounded assembly facts
are not replaced by guessed decompiler C signatures: Ghidra's104-byte output
misidentifies one call as a branch and follows only the348-byte callee, so it
cannot establish that caller's retry control flow.

## Close/reopen cannot be called blindly

The original close trampoline is8bytes. Ghidra follows its tail branch into
the actual680-byte close implementation, SHA256
`7f5fa934e493adcc4747b9309727a31b2b45a667e4859c3171947cc3de12a37e`.
Its111 high-Pcode instruction sites are outside the trampoline and inside that
implementation. Counting this as an8-byte function inspection would be wrong.

The implementation has a failure path for outstanding statements or unfinished
backups and returns5. The native216-byte reopen wrapper ignores the close
return, unconditionally clears its cached handle field, and enters the native
open wrapper. Therefore finding a real source reopen function does not make
arbitrary host hot reload safe. A quiescent scene, finalized statements, source
cache ownership and calling convention still need proof. Do not clear or
replace its handle from the host or pass in an external SQLite connection.

There is one direct596-byte callback caller of this reopen wrapper. Its native
RTTI is the exact libc++ wrapper for
`DialogDatabaseDownloadLayer::setFetchAssetEventListeners()::$_2`, signature
`void(cocos2d::EventCustom*)`, virtual slot6. The original688-byte listener
registration binds that wrapper to `EVENT_NET_FILE_DOWNLOAD_SUCCESS`. The
callback filters the event path with `/database.db$`, constructs the source
asset path, then calls its native reopen sequence. This identifies the actual
download-driven master activation path. It does not authorize posting an
invented event or calling a captured closure from the host. Callback payload
ownership, completion conditions and thread affinity still need proof before
reusing that path for Creator edits. Preserve the detached derived-master
compiler while those facts remain unknown.

The688-byte registration decompilation also follows two adjacent bodies of
244 and692bytes. The event/vtable binding above is inside the declared688-byte
body and was checked against its source instructions; the extra bodies are
not treated as admitted APIs. The152-byte initialization and468-byte validation
decompilation sites remain within their declared bodies. Full raw source and
actual high-Pcode scope receipts remain private.

## Startup ordering frontier

`inspect_master_lifecycle.py` performs one syntactic scan of ARM64 immediate
`B`/`BL` instructions and function-start ownership. It excludes the250 words
inside the opaque key-provider body and follows no key data. Raw branch sites
and addresses remain under ignored `private/research-master/`.

Its receipt, `master-lifecycle-evidence.json`, records:

| Selected role | Direct caller functions | Direct initializer callers |
|---|---:|---:|
| Master singleton |264|0|
| Cached open |2|0|
| Path/key open |2|0|
| Close/reopen |1|0|
| Close trampoline |8|0|
| Selected entry |1|0|

No initializer path was found through the observed direct-call graph within
eight edges. That **does not prove safe timing**: indirect virtual calls,
Objective-C dispatch, callbacks and dynamically resolved calls are absent from
this graph. The existing5,259 dyld initializer entries still execute before
AppController. Publishing before AppController therefore remains weaker than
publishing before `dlopen`/dyld initialization.

## Concrete next native integration

1. Recover and hash-check the original iPhone seed and actual startup framework
   from the supplied IPA. Keep the source read-only and private.
2. Before loading the prepared image, publish compatible working resources to
   the native Documents/assets tree in the new app's own container, preserving
   the original bundle fallback and separate source identities. Do not mutate
   a source-game installation or save directory.
3. Use the original unchanged open/key/schema path. A diagnostic must record
   fixed result codes and selected-file identity without a key, account data,
   raw personal path or database rows. The exact observation ABI is not yet
   admitted; do not invent function pointer casts to implement it.
4. Confirm ordinary original characters reach home, team selection and a real
   battle before attempting Creator-driven database generation changes.
5. Resume Creator runtime insertion only through an established engine-owned
   write/export path and a proved cache/statement generation boundary.

Run the static frontier, when this source or scope changes, with:

```
python3 offline-dokkan/original-client/content/inspect_master_lifecycle.py \
  offline-dokkan/private/source-client/OriginalDokkanEngine.dylib \
  offline-dokkan/original-client/content/master-lifecycle-evidence.json
```

One meaningful run completed successfully for this source. No app build,
runtime database test, device test or gameplay verification was performed.

`inspect_master_activation.py` separately pins the reviewed callback, cleanup
and thread bodies, verifies the exact selected RTTI, and writes
`master-activation-evidence.json`. It needs the retained private scoped-analysis
manifests; no raw addresses need to be added to the public repository. It is a
repeatable static identity check, not a runtime activation check.
