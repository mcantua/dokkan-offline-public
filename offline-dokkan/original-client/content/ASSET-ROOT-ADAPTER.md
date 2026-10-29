# Original native asset-root read adapter

The existing `od_iphone_resources_fopen` recognizes exact absolute paths below
an attested `.app` bundle. It does not cover resources requested below the
original native asset root. The separately reviewed original resource-root
contract is recorded in `MASTER-ROOT-STATIC.md`: the default resource prefix
comes from the app's own Documents directory plus the native/default asset
prefix. A host-selected `_resources` URL is not automatically that engine root.
This is static evidence; no runtime resource root or complete game launch is
claimed.

## Added source interface

`od_iphone_resources_fopen_asset_root` is a separate, explicit-root adapter.
The native caller must supply and attest the actual absolute canonical asset
root, without a trailing slash, using the established original-client contract.
This API does not guess a sandbox path, discover/modify the native prefix,
replace the bundle adapter, install a hook, mount Drive or change search order.

A read-only path inside that exact root is admitted only when:

1. Its relative path is canonical, bounded and has no traversal/URL encoding.
2. `ipa_matches` names a preferred exact verified IPA entry for its canonical
   `assets/...` reference.
3. That preferred entry also passes the existing independent `ipa_aliases`
   mapping/path validation and returns the same canonical reference.
4. The existing content resolver verifies the complete length/SHA-256 before
   returning a read-only descriptor, then `fdopen` wraps that same descriptor.

`od_iphone_resources_asset_reference` exposes the same double-sided mapping for
trusted native consumers. A verified tutorial alias can supply a canonical
resource only when the catalog explicitly admits that exact alias. Requests
containing `tutorial0/` are never rewritten by stripping a prefix.

Unknown canonical resources, outside-root paths and write modes retain the
preserved original libc callback. A known preferred entry with a missing or
contradictory alias fails as invalid catalog metadata. Missing/corrupt admitted
content fails closed rather than falling back to unverified source bytes.
The original exact-bundle-path interface remains unchanged.

## Real file publication for Foundation existence

`inspect_asset_probes.py` recovered the pinned 544-byte resource-vtable probe
and its matching full-path resolver. The probe calls the actual
`stringWithUTF8String:` and `fileExistsAtPath:` selectors; the resolver loads
that probe's vtable slot. Sanitized evidence is in
`research/native-asset-probe-evidence.json`. This establishes a concrete
Foundation existence boundary, not a claim that every resource/control-flow
path has been traced. No direct stat/access import call occurred in this
selected probe. Adding a guessed libc stat hook would not establish coverage.

`od_iphone_resources_publish_asset` provides a physical-file path instead of
fabricating a successful existence result. The trusted native host supplies an
attested assets-root directory descriptor, distinct from the immutable import
and private cache roots, plus a separate trusted working-boundary descriptor
for a directory in the app's own namespace that contains the root (for example,
its native Documents directory). Both must be readonly directory descriptors.
The host attests that these are its current own-app directories; neither FD
can come from page/request input.

Before creating children, a bounded parent-directory FD walk rejects an
import/cache root or any descendant. It succeeds only on the exact supplied
boundary's device/inode identity, stopping there without attempting to traverse
above the app sandbox. Every parent opens with `O_NOFOLLOW`; a walk failure,
depth exhaustion or filesystem-root termination before reaching the boundary
rejects. Source/cache roots outside the boundary can remain independently
pinned imported/bookmarked inputs, but are never publication targets. Child
traversal also refuses to enter a protected directory nested below the working
root. No caller/web-supplied sandbox path is accepted or guessed by this API.

The publisher admits only the existing resource-generator root/extension
vocabulary, rejects `save`/`User` directory components, and requires the same
canonical preferred-entry plus exact verified IPA alias. Master databases,
keys, profiles and persisted player state are outside that namespace.
Unknown/unadmitted paths are checked before any destination directory is made.

Child directories open with `O_NOFOLLOW`; only missing directories are created
and their parent directories are synced. Existing final paths are never
replaced or chmodded. A matching readonly regular file is hash-verified
idempotently; symlinks, writable files, conflicting bytes and unsafe paths
reject. A new file is copied from the verified cache to an exclusive local
stage, synced, changed to mode0400, reopened readonly and SHA-readback-verified,
then atomically linked without replacement. Only the owned stage is removed.
The final directory is synced before success. If removal of the exclusive
staging file fails, publication reports an error; host recovery may need to
remove that known owned stage later, without deleting another file.

The small new `od_content_verify_readonly_fd` helper reuses the existing
content SHA implementation and hashes through `pread`. It rejects nonregular
or nonreadonly descriptors and checks length/hash/before-after identity without
changing the caller's file position. Existing resolver callers are unchanged.

Publication creates real resource files for Foundation and libc to observe.
It does not prove that an original engine has requested/decoded them. A directory
sync error after linking leaves the verified final file intact and reports a
durability failure; `newly_published` records the link even on that failure.
Retrying the same name verifies and syncs it. Empty directories created before
a later failure may remain; pre-existing trees/files are not rolled back or
deleted. Use the existing host serial content queue off the render thread.

## Verification boundary and next native check

One bounded actual-image probe analysis plus source review and a focused
whitespace/conflict check only; no C compiler,
app/HTML build, native simulator, game execution, account/source cache access,
save/signing access, or new asset download was performed. Existing 27-reference
hash identity evidence is reused; it does not verify this new native adapter.

When native verification/builds are authorized, exercise one admitted canonical
resource and actual physical publication, its verified tutorial-backed mapping,
idempotent readonly publication, preservation of a conflicting existing file,
symlink/traversal/private-path rejection, wrong or unreachable working boundary,
protected-root ancestry, a contradictory preferred alias,
corrupt admitted content, and nonchanging FD offsets. Cover a sync failure
after linking with a same-name retry; unknown resource/write-mode passthrough
still belongs to the separate read adapter. Use a tiny synthetic catalog or the existing pinned private
catalog; do not repeat unrelated suites. The original image import hook and
actual engine use of this resource root remain separate acceptance work.
