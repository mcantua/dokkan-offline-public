# Verified iPhone resources for original-client integration

The actual resource bridge now has usable admitted source files and a native
lookup/cache API. It does not mount Drive, patch the original binary or change
the original game's resource search order. The verified original-client hook
remains a separate attachment requirement.

`iphone_resources.h/.c` accepts an immutable host-verified catalog, pinned
manifest/IPA/bundle identity, a local source root and a separate private cache
root. The host must verify the catalog's complete SHA-256 before opening it;
metadata matching is an identity check, not authentication of arbitrary SQLite
bytes. Use the host's serial content queue and close returned descriptors.

`od_iphone_resources_reference` accepts an exact bundle-relative resource path
only when it occurs in the catalog's hash-admitted `ipa_aliases` table. It checks
the alias against its canonical `assets/...` reference, then obtains length/hash
from the existing native catalog. Absolute paths, URLs, traversal, private or
unknown paths and structural guesses reject. A verified `tutorial0/...` alias is
accepted only if that exact entry's bytes passed comparison; merely stripping
the prefix is insufficient. `od_iphone_resources_resolve` then uses the existing
SHA-verifying resolver and returns a read-only content-cache descriptor.

## Actual staged data and evidence

`content/iphone_resource_import.py stage` checks the catalog checksum and pinned
source identity, then streams only its27 selected resources from the private IPA
to a new host-selected canonical source root. Every selected resource is checked
again against its exact length/SHA. It does not rehash the whole IPA unnecessarily,
extract its unselected files, read keys/player data, or replace an existing root.
An import receipt is written last. Failed new imports remove their own incomplete
root; pre-existing roots/stages and original inputs stay intact.

The real cloud import produced27 files/51,272,144bytes at:

- Source root: `offline-dokkan/private/iphone-client/verified-resource-source`
- Native cache: `offline-dokkan/private/iphone-client/verified-resource-cache`
- Catalog: `offline-dokkan/private/iphone-client/byte-identical-assets.sqlite3`
- Catalog bytes:36,864; SHA-256:
  `a45b7c9f308e6d07452fd07ac2eeea28981be034554a73e35094552ba9163384`

One combined import/native-cache check passed for all29 exact original bundle
aliases, including the duplicate root/tutorial entries. All resolved through
the27 staged resources to read-only SHA-verified descriptors. Unknown/private/
traversal/URL requests rejected, existing roots/stages were preserved, and
temporary check/compiler files were removed. Exact receipt/limits are in
`research/ios-resource-import.json`. No app/HTML build or player-data import ran.

This is actual source/cache readiness for those27 references. It does not prove
CPK extraction, HCA decoding, complete scene dependencies, the game's path-hook
attachment or gameplay. All647 same-size hash mismatches and other unsupported
resources remain unadmitted. Nothing silently converts them.

## Cloud import command

Use an absent destination; an existing source root is preserved.

```sh
python3 offline-dokkan/content/iphone_resource_import.py stage \
  offline-dokkan/private/iphone-client/Sparking-6.6.ipa \
  offline-dokkan/private/iphone-client/byte-identical-assets.sqlite3 \
  offline-dokkan/private/iphone-client/verified-resource-source \
  --catalog-sha256 a45b7c9f308e6d07452fd07ac2eeea28981be034554a73e35094552ba9163384 \
  --manifest-sha256 2196f85c0d09e41967d6b0c08a1860fe57037c1f172cd8c048e9cad70f0f5a33 \
  --ipa-sha256 0ea61911a09c4e7735f2d7b32b7b2c6c6977c1f4acf0a9db278049528b662816
```

## Selective large ZIP member extraction

The same tool's `extract-member` command takes a seekable cloud ZIP, one exact
central-directory member name, pinned archive byte length, pinned member length
and pinned member SHA-256. It reads only ZIP metadata and that member. It never
copies/downloads or rehashes the whole archive, replaces an existing output/stage,
or changes the original. It uses exclusive staging, rechecks source identity and
publishes a read-only file without replacing an existing candidate.

For the missing full English master, use the actual private26,650,901,563byte
Drive archive through an already authorized cloud filesystem. First obtain its
exact master member name; do not guess its enclosing ZIP prefix. The exported
master reference is114,827,264bytes with SHA-256
`f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d`.
The535,552byte opaque iPhone seed is not that master.

The selective extractor was checked against one real6,752byte IPA member and
prior-stage preservation in the same batch. The full26GB archive and missing
master were not accessed, so large-archive/member availability is not claimed.
The helper supplies no authentication or networking and cannot itself bypass the
Drive connector's file-size limit. No additional Colab action was requested.

The self-contained `tools/Private-current-master-extract.ipynb` now embeds
`content/select_export_master.py` for the existing Google Drive cloud mount. It
selects exactly one safe member with the pinned full-master suffix from the
verified-size original archive and writes `Game Data/Current-export-master.db`
plus a value-free receipt. Same-hash output is reused; different output is
preserved. It needs no repository checkout, source ZIP copy, key or account-data
read. One small disposable fixture checked the new unique-suffix selection,
forced Drive-FUSE publication fallback, reuse, existing-output preservation and
traversal rejection. The real26GB archive has not yet been accessed by this
helper; root owns any necessary account-owner execution request.

## Actual resource import hook boundary

The inspected main executable and patcher both import standard libc `_fopen`;
the main also imports `_fread`, `_fseek`, `_ftell`, `_stat`, `_lstat`, `_access`,
`_open` and `_read`. The selected Cocos FileUtils search/root exports were absent
from both symbol tables. The source `ios_current.json` maps are byte-identical
to their `ios_6.4.0.json` copies and include Android/NDK function signatures.
No offset from those maps is treated as a verified current iPhone hook.

`od_iphone_resources_fopen` supplies a narrow standard-libc read adapter for a
separately verified import hook. Given an explicit actual original `.app` root,
it maps exact admitted read-only paths to verified cache descriptors and creates
a read-only `FILE*`. Other paths/bundles/write modes retain the preserved libc
callback. A corrupt/missing admitted cache fails closed; traversal is rejected.
There is no guessed Cocos resource-root rewrite or fallback download. One narrow
check passed actual6,752 resource bytes and callback/rejection behavior.

The adapter does not rebind Mach-O import slots, establish which original scene
opens a resource, or verify a decoder. Root's loader must attach only through a
verified actual-image import mechanism and supply the preserved libc function.
Do not register it by inventing an address or claiming source readiness equals
an in-game hook. Sanitized source/runtime limits: `research/ios-resource-hooks.json`.

### Exact original-image fopen binding plan

`fopen_bind_plan.py` reads only the pinned55,697,728byte original executable
(SHA-256 `9d6bf0470c4b4ff7d914740ccf9f1622afa962b763e18bfcf1f6e051bfae0610`)
and decodes its non-PAC PTR_64_OFFSET chains, import-format3 records and
uncompressed symbol pool. Only exact `_fopen` name matches are emitted; no
unknown symbol names, arbitrary strings or keys are output. Sanitized receipt:
`research/ios-fopen-bind-plan.json`.

| Actual source field | Value |
| --- | ---: |
| Source image base | 4,294,967,296 |
| fopen slot VM address | 4,339,177,888 |
| Slot image-relative VM/file offset | 44,210,592 |
| Import index | 779 |
| Import record file offset | 50,852,936 |
| Library ordinal, verified libSystem | 41 |
| Symbol-pool name offset | 24,462 |
| Import and pointer addends | 0 |
| Source target segment initial/max protection | Read/write,3 |

`fopen_bind_attach.h/.c` contains that one compiled plan. A trusted native loader
supplies the actual loaded image header/slide and callbacks that attest the
verified source/prepared-image identity, safely read memory, query existing live
writability and atomically compare/exchange an aligned pointer. Callbacks
return0 on success. They must not change VM protections, patch code or target
another image. Pin the image lifetime and serialize attach/detach.

Before any pointer update the component checks actual arm64 non-PAC Mach-O
headers, the exact source segment geometry/protections, libSystem ordinal41,
the selected chained-pointer format6/import-format3 record/name/addends and
current writable-slot permissions. It replaces only the still-matching original
libc pointer, retaining it for guarded detach. Read-only slots, changed pointers,
unsupported/PAC metadata and identity failures refuse. It calls no `mprotect`,
`vm_protect` or dynamic memory-permission weakening API and makes no blind write.

One actual-original-header/metadata fixture passed guarded callback attach and
detach plus read-only, changed-pointer, identity and PAC rejection. Source-only
standard-C compilation passed. The fixture used a scratch slot behind trusted
callbacks, not a loaded/executed original game. Real runtime attachment remains
unverified. The loader's prepared-image transformation must preserve these VM
addresses and import metadata offsets; a separately verified static import rewrite
to an authored plugin is an alternative strategy and must not be confused with
this guarded runtime-CAS route.
