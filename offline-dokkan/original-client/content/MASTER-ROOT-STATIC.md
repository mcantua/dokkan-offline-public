# Original engine's Documents-based resource root

`inspect_master_root.py` examined only the pinned prepared iPhone engine,
read-only. The engine was not executed. Its receipt is
`master-root-evidence.json`; raw addresses and selected disassembly stay under
the ignored `offline-dokkan/private/research-master/` directory.

The reviewed resource singleton's native-root virtual method calls
`NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)`.
It selects `objectAtIndex:0`, obtains `UTF8String`, writes that string into its
C++ indirect result, and appends `/`. The inspector checks this exact result
flow, the selected function hashes and the resource vtable relationship.

The already reviewed prefix helper uses this native root and a nonempty
configured prefix, otherwise `assets`. Combined with the established master
relative template, its **default** selected master path is:

```
<own-app-Documents>/assets/sqlite/current/<language>/database.db
```

The Foundation call and its enum arguments are proven static behavior. The
actual container URL, current configured prefix, selected language and resolver
cache contents have not been observed. A configured prefix can change the
default; this result does not admit a prefix setter or an arbitrary root rewrite.

`ODUnifiedDuoHost`'s `_resources` directory is a host-supplied capability. Passing
it to the host does not change this original-engine getter. Publishing a master
under the host's separate writable-state directory likewise does not make that
file visible at the original engine's selected path. The app-bundle resource
fallback and the Documents-based downloaded-assets root need separate explicit
native capabilities in a resource adapter.

The MAIN engine and source patcher can construct the same default master path,
but their database contracts remain different: MAIN uses its internal flags6
open/key path, caches its handle and has compatibility3 fallback; the patcher
uses readonly/fullmutex and compatibility4. See `MASTER-OPEN-CONTRACT.md`.
No key bytes, User records, saves or signing material were inspected.

## Smallest useful follow-up

Supply an explicit trusted assets-root capability to the existing read-only
resource adapter, separate from the original `.app` root. Admit it only after
confirming the original engine's active prefix/root, then map exact reviewed
resource paths to hash-verified cache descriptors. Do not install a guessed
Cocos setter or copy a master into an existing source-game assets tree.

For master integration, independently establish which file the original
resolver actually returns and whether its own open/key/schema path can consume
the derived master. Recheck before a cached handle/path is reused. Staging or
an external plaintext SQLite read cannot establish those facts. The current
remaining trace is a value-free observation of selected path/root identity,
open mode, codec outcome and cache generation in the original client. No key
value or played-account state is needed in that trace.

To reproduce this static inspection in the cloud, with the pinned private
prepared engine and recorded Capstone5.0.6 dependency already restored:

```
python3 offline-dokkan/original-client/content/inspect_master_root.py \
  offline-dokkan/private/source-client/OriginalDokkanEngine.dylib \
  offline-dokkan/original-client/content/master-root-evidence.json
```

This inspection is not an app build, launch, plaintext-master attachment,
offline-battle check or physical Duo acceptance.
