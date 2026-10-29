# Optional passive original-master observer

This optional offline recipe instruments a separate derived engine. It does
not overwrite the immutable source or the current app package, enable loader
admission, change a game database, read a key/provider, or claim gameplay.
The probes execute only when the original client reaches its existing code.

Five pinned MOV instructions become direct branches to leaf ARM64 islands.
Each island saves/restores its scratch registers, live LR, NZCV and SP, then
replays the MOV and branches back. It calls no native function. Original
function-start and unwind payloads remain unchanged. The existing316-byte
cached-open body retains its original unwind coverage. New island PCs have no
newly proved asynchronous unwind/sampling coverage while SP is temporarily96
bytes lower; leaf code makes no C++ calls, but this does not prove async unwind.
The package remains diagnostic and device-unverified. The existing316-byte
cached-open frame's unused SP+0 holds the observation ticket; its24-byte opaque
context starts atSP+8 and saved registers start atSP+32. The exact entire body
and independent retained-source review establish that separation. No opaque
context or key pointer is inspected. Exceptions leave the invocation incomplete
and therefore unsuitable for admission.

The five sites belong only to the316-byte cached-open wrapper and248-byte
path/key wrapper. The filename island reads the resolved master filename at
the latter's existing pre-open boundary, using its actual path string length.
It validates the saved preferred/fallback return site, parent-frame ticket,
ring ownership and manager/out-slot relationship. It never treats another
path/key caller as the same invocation. Entry, attempted-path results and
final wrapper result are paired by that ticket. Cached return1 is not a fresh
open. Final16 remains failure; a successful fallback is distinct from the
staged candidate. Overlap, collision or incomplete execution fails closed.

The new RX segment is16KiB; the separate RW segment is64KiB. No segment is W+X.
Both precede the relocated LINKEDIT. Chained-start entries and all affected
linkedit offsets are adjusted. Original code/data addresses remain stable.
The exact inverse recovers SHA256
`efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222`.
Verification also regenerates and compares every derived byte, so merely
dropping unexpected inserted code/data is never sufficient admission.

Dependencies and official wheel hashes/licenses are retained under the ignored
`downloads/native-probe` runtime/wheels and its small source manifest. A single
combined check covers inverse/tamper rejection and synthetic ARM64 control flow
at two slides, including registers, LR, NZCV, SP, path bounds, fallback, failure,
reuse and collision. The original game, key provider and cached SQLite handle
are not mapped/executed by that emulator. Initial assembly exposed Keystone's
high-address ADR issue; ADR/absolute branch encodings are now emitted directly
and independently decoded/executed. This is not iOS/dyld/device evidence.

```sh
python3 recipe.py --source /private/pinned/OriginalDokkanEngine.dylib \
  --output /private/separate/ObservedOriginalDokkanEngine.dylib \
  --receipt /private/separate/recipe.json
```

The output is an unsigned optional engine. Loader policy, signing envelope,
same-file runtime consumption and packaging must be coordinated separately.
No native acceptance flag may change merely because this recipe/check passes.
See [FORMAT.md](FORMAT.md) for the native-only read/admission contract.
