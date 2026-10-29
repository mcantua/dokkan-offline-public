# iPhone bundle and Android export resource identity

The actual private iPhone client is now a usable comparison input. Reusing all
Android resources without checking them would be incorrect: most structurally
corresponding bundled resources did not match the supplied Android export.

`content/iphone_asset_catalog.py` produces a read-only SQLite catalog with the
same `metadata` and `assets` schema consumed by `od_asset_catalog_*`. It reads
the pinned IPA and manifest without extracting the full game, accessing an
account, using the network, or modifying either original. Only an explicit
allowlist of game-resource roots/extensions is considered. Patcher/config/SDK
directories, private User state, signing material and the bundled master seed
are not admitted as reusable assets. Traversal, duplicate ZIP names, symlink
entries, oversized files and native-invalid content paths fail closed.

The mapper considers the iPhone app's resource-root path and its `tutorial0/`
resource container as structural candidates for Android `assets/` references.
It admits a reference only when the complete file length and SHA-256 match the
Android export record. `ipa_matches` records one preferred entry per canonical
reference; `ipa_aliases` retains all29 exact byte-verified ZIP entries, including
the two duplicate root/tutorial aliases. This supports explicit verified lookup
through `original-client/content/iphone_resources.h`; generating the catalog
does not install a search-path redirect into the original game.

## Actual comparison

Pinned inputs and sanitized results are recorded in
`ios-asset-compatibility.json`. Version6.6.0 matches the inspected client and
export, but equal version numbers alone do not establish content identity.

| Observed resource comparison | Count |
| --- | ---: |
| Safe iPhone resource candidates | 1,067 |
| Candidate entries with identical complete bytes | 29 |
| Unique reusable canonical references | 27 |
| Same-length candidates with a different SHA-256 | 647 |
| Candidates with a different length | 170 |
| Candidate paths absent from the export | 221 |
| Non-resource bundle entries excluded | 351 |

The27 unique admitted references cover51,272,144bytes. The29 matching entry
headers identify20 CRI AWB resources,6 CRI UTF resources and3 CRI CPK packs;
duplicate root/tutorial candidates explain the difference between entries and
unique references. Matches include bundled audio and three tutorial English UI
packs. The byte differences could reflect platform, encryption or source
variants; this comparison does not establish their cause.

The root iPhone `database.db` is535,552bytes, SHA-256
`667e554a9cfb8c4765f05a1d85f0fdf707ade61562b50e3e5cd98ac52f997ba3`.
Its header is not plaintext SQLite. It remains an opaque bundled seed, never a
replacement for the exported114,827,264byte full master and never an admitted
resource catalog record. No keys or decryption values were read or emitted.

## Native consumption and limits

The generated catalog is private at
`offline-dokkan/private/iphone-client/byte-identical-assets.sqlite3`:
36,864bytes, SHA-256
`a45b7c9f308e6d07452fd07ac2eeea28981be034554a73e35094552ba9163384`.
The host must verify this catalog checksum before opening it with the pinned
export-manifest identity. The native catalog API reads canonical `assets/...`
references from `assets` and accepts no caller-supplied replacement hashes.
The explicit iPhone resource API additionally requires an exact `ipa_aliases`
entry and validates its original bundle path against the canonical reference.
Source bytes must still be imported under a host-selected root and pass the
existing resolver's length/SHA checks before a read-only cache descriptor is
returned. A tutorial entry's existence alone does not make its canonical source
path available. `content/iphone_resource_import.py stage` now performs that
bounded admission; see `original-client/content/README.md`.

One combined actual-input check verified pinned inputs, immutable catalog
generation, source preservation, private/path exclusions and separation of byte
identity from runtime claims. One narrow native interop check then loaded this
actual catalog and copied6,752 matching iPhone-bundled bytes through the native
resolver to a read-only descriptor. It rejected private/traversal paths, direct
`tutorial0` aliases and a cataloged asset whose canonical source bytes were not
installed. The original resource stayed unchanged; temporary check files were
removed. No broad suite or app/HTML package was rebuilt.

These checks do not verify CPK extraction, HCA/audio decoding, the iPhone engine's
resource search order, actual scene dependencies or gameplay. Catalog metadata
therefore keeps `ios_compatibility_verified=false` and
`runtime_paths_verified=false`. Connect explicit verified resource imports and
the actual original-client path hook before claiming in-game availability.

## Reproduce the private catalog

Use an absent output path; existing outputs/staging are preserved. No generated
catalog or original game bytes belong in Git.

```sh
python3 offline-dokkan/content/iphone_asset_catalog.py \
  offline-dokkan/private/iphone-client/Sparking-6.6.ipa \
  offline-dokkan/private/sparking-client/assets-manifest.json \
  offline-dokkan/private/iphone-client/byte-identical-assets.sqlite3 \
  --ipa-sha256 0ea61911a09c4e7735f2d7b32b7b2c6c6977c1f4acf0a9db278049528b662816 \
  --manifest-sha256 2196f85c0d09e41967d6b0c08a1860fe57037c1f172cd8c048e9cad70f0f5a33 \
  --package com.sparkingDokkan.GLB \
  --bundle-id GLB.Dkkn.Sparking.dev --version 6.6.0
```

Source inputs remain in their existing private Drive locations. Root owns
retaining this small generated catalog in the existing project Game Data folder
and synchronizing the coherent source cohort; this task created no extra Drive
folder, backup or duplicate upload.
