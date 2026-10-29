# One cloud step for the original iPhone safe resource set

`extract_original_resources.py` prepares the original client's bundled game
resources, rather than treating nonmatching Android files as iPhone bytes. The
startup owner agreed this is preferable to recovering a thousand filenames one
at a time. This is a prepared input-recovery option, not an executed transfer or
working game.

The self-contained private Colab notebook embeds the repository's existing
`export_asset_catalog.py` and `iphone_asset_catalog.py` modules. It calls
`iphone_asset_catalog.resource_mapping` unchanged: the same resource roots and
extensions that previously identified 1,067 candidates. Bundle-root and
`tutorial0/` variants remain separate files even when their canonical candidate
paths collide. The only additional selection is the exact framework metadata
file `Frameworks/AdjustSigSdk.framework/Info.plist`. No other root configs,
executable code, source patcher, provisioning, signatures, keys, personal
configuration, or User/save tree is selected. A private path component inside
the resource allowlist stops the operation for review.

Inside Google's cloud the helper downloads the existing IPA once to temporary
Colab scratch and verifies its complete recorded size and SHA-256 **before**
resource extraction. The original Drive IPA is never modified. This uses about
1.14 GB of temporary Google-cloud disk, plus a bounded part buffer; it does not
copy the game through the Mac. Scratch is removed when the step exits. Google
manages notebook authorization; credentials are not serialized or uploaded by
the extractor. No app is built or executed.

Selected resource bytes are streamed into raw parts of at most 31 MiB, below
the chat's 32 MiB materialization limit. Each member has its own SHA-256 and
original ZIP CRC; each part has SHA-256 plus Google's server-returned size/MD5
transfer check. Part SHA-256 readback is performed when materializing those
parts in the chat workspace; server MD5 verification alone is not described as
SHA-256 readback. The tiny final manifest receives actual SHA-256 readback.

The existing Game Data folder holds one named output set. Owned identical
parts are reused on retry; differing or unowned parts are preserved and cause
a stop. Only an owned manifest can be updated, after every part verifies. No
dated copies, backup folder, source deletion, or sharing changes occur. Partial
parts from an interrupted first run remain available for an identical retry;
they are not a completed cache until the final manifest verifies.

The previously restored framework binary and opaque database seed remain
separate pinned startup inputs. They are listed as dependencies in the manifest
and are not duplicated into these resource parts. The seed is not published as
a master or decoded. The complete approved resource candidate set still does
not prove every startup file is present: any resource outside the existing
selector requires separate concrete source evidence and review.

## Manifest consumed by native staging preparation

The output is `Private-iPhone-original-resources-manifest.json`, format
`od-original-iphone-resource-parts-v1`. Its `source` records exact original IPA
size/hash and complete source-hash verification. `parts` contains one-based
`index`, `name`, Drive `id`, global `stream_offset`, `size`, `sha256`, and `md5`.
Payload parts are the concatenation of selected uncompressed bytes in original
ZIP-offset order. A member can cross part boundaries.

Each `members` entry records `bundle_relative_path`,
`canonical_candidate_path`, `mapping`, global `stream_offset`, `size`,
`sha256`, and `source_zip_crc32`. Native staging must verify all referenced part
and reconstructed member hashes, then preserve `bundle_relative_path` exactly.
It must never flatten a tutorial alias into a conflicting canonical candidate.
Framework metadata uses `mapping: required-framework-info` and a null canonical
candidate. Its exact source plist bytes are preserved.

The notebook is retained privately under
`offline-dokkan/private/startup-input-recovery/`; runtime Drive IDs are outside
Git. Root reviewed the helper, replaced the existing Drive notebook in place,
verified its exact uploaded bytes, and requested the necessary Google-account
Run-all step. Actual resource extraction is still pending confirmation and
output verification. No original file or sharing permission was changed.

One combined synthetic check passed: existing-selector filtering, distinct
root/tutorial aliases, member reconstruction across part boundaries, hashes,
private-path refusal, and source preservation. No real full-resource transfer,
native staging, build, launch, or gameplay check ran.
