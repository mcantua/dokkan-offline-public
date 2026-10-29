# Original MAIN master: codec and cached-handle boundary

The bounded read-only inspection in `inspect_master_codec.py` re-examined the
reviewed MAIN open/key/cache entry points in the exact prepared engine.
`master-codec-evidence.json` records their body hashes and selected call roles.
The engine was not executed. No key-provider body or key data was followed;
raw entry addresses and disassembly remain ignored and private.

## Established path

The original master wrapper first checks its cached handle at object offset16.
The already recorded MAIN contract identifies a nonzero-handle short circuit.
The new receipt independently records the load and zero test. Replacing a file
or its resource mapping does not replace that existing handle.

For an uncached open, the wrapper obtains an opaque native-produced key and
calls its path/key wrapper. Within the selected path/key wrapper:

1. The internal open shim receives the resolved pathname and output-handle
   pointer. The shim passes flags6 (`READWRITE|CREATE`) and a null VFS into the
   internal open core. This is not the external readonly staging helper.
2. After the existing successful-open check, `strlen` is called on the key
   parameter. The resulting length and that same key parameter are passed to
   the internal key-attachment entry along with the opened handle.
3. The key-attachment entry guards the handle, key pointer and key length before
   reaching its internal codec attachment. The receipt records that the opaque
   key and length continue to the codec arguments. It does not claim a null-key
   branch is an admitted successful plaintext mode.

The established schema checks and compatibility3 retry remain as documented in
`MASTER-OPEN-CONTRACT.md`. This pass did not expand the read into key generation,
derive a key, follow unknown helpers, or infer Android/iPhone key equality.

The reviewed close/reopen path loads the cached object+16 handle, calls the
previously identified close helper, stores zero into that field and re-enters
the original master wrapper. This proves there is a source-owned reopen path;
it does not establish a safe moment to call it while statements, battle objects
or resource-path caches still refer to the previous generation.

## Consequence for a derived per-save master

The source engine already supplies its own opaque key in native memory. Asking
Tin to paste a key, placing one in a file, or bundling an extracted key is not
the missing integration step.

The smallest legitimate direction is to keep codec ownership inside the
original engine: bind the selected path to a separate per-save working copy,
let its original open/key path own the handle, and apply custom rows through
an independently verified engine-owned write/export path. Before doing this,
prove that the working copy's format is accepted by that exact codec and that
the handle/path transition occurs at a safe generation boundary. A copied
Android cipher database or a plaintext derived database is not established as
compatible merely because the schema or path matches.

Passing a handle from the authored external SQLite library into object+16 is
not admitted. The original internal codec, connection allocation, mutexes and
ownership belong together. Likewise, no reviewed callable C API currently
allows the host to borrow the producer's key or replace its cached handle.
Linear register tags and body hashes do not establish a C++ string ABI,
thread affinity, exception/cleanup behavior or borrowed-key lifetime.

## Exact remaining native proof

- Observe the actual selected resolver path and its file identity after the
  active resource prefix is known; see `MASTER-ROOT-STATIC.md`.
- Observe the original open/codec/schema result on an isolated per-save working
  copy without logging the key or user data. Record source and working-copy
  identity separately.
- Establish one actual caller-safe entry for applying the custom rows through
  the engine's own database connection, or a compatible export/import path.
- Establish statement/path-cache ownership and the safe close/reopen boundary
  after a Creator edit. Do not clear object+16 or reopen a live handle blindly.

Until those facts exist, staging remains staging. No source adapter was added
that pretends a foreign SQLite handle or an invented plaintext bypass is safe.
Other native startup, resource and Creator integration can continue without
extracting a key.

The inspection command is:

```
python3 offline-dokkan/original-client/content/inspect_master_codec.py \
  offline-dokkan/private/source-client/OriginalDokkanEngine.dylib \
  offline-dokkan/original-client/content/master-codec-evidence.json
```

This is static evidence, not an app build, original-game launch or gameplay
acceptance. The JSON explicitly labels its register tags as linear, not a
path-sensitive runtime or callable-ABI proof.
