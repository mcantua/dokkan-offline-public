# Original iPhone resource staging

`stage_original_resources.py` consumes the reviewed extractor's
`od-original-iphone-resource-parts-v1` manifest and raw parts. It runs only in
the cloud Linux workspace. It prepares new private source trees; it does not
build an application, copy anything onto a Mac/device or access a live save.

The source IPA size and SHA-256 are fixed to the supplied original client. The
caller must supply the exact extraction-manifest SHA-256 from the reviewed
Google-cloud extraction receipt. Every part is opened read-only without
following symlinks, length/SHA-256 checked and held by its original FD. Member
offsets must cover the exact concatenated stream without gaps or overlap.
Each output member is independently length/SHA-256 checked, including files
that cross part boundaries. Source identities are checked again before the
new tree is published. The original IPA, parts and caches are preserved.

The manifest must contain exactly the existing 1,067 resource candidates and
the one original Adjust framework `Info.plist`. The existing
`iphone_asset_catalog.resource_mapping` remains the selector. Private path
components, duplicates, traversal, malformed offsets and an expanded selector
are refused. The separately restored exact framework binary and opaque
535,552-byte app-root seed are also verified and copied to their original
bundle locations. The seed is not decoded or installed as a downloaded master.

The output contains two distinct source-staging trees:

- `bundle/` preserves every exact original bundle-relative path, including
  `tutorial0/...`. Different original/root/tutorial bytes remain distinct.
  This tree also contains the original framework metadata/binary and app-root
  seed. It does not contain the genuine shell or prepared engine; their
  existing pinned loader recipe is separate. It additionally includes the
  exact compatible catalog and 27 immutable SHA-named compatible-cache blobs
  under `OriginalClient/` for the existing native FD preloader.
- `documents/assets/...` contains only the 27 canonical references already
  admitted by the existing byte-identical iPhone compatibility catalog. The
  tool requires that exact 36,864-byte catalog SHA-256, original IPA/export
  identities, preferred alias, and each source member's exact size/hash.
  A structural candidate alone never becomes a Documents alias. No conflicting
  tutorial/root variant is silently selected, and no `User`, `save/` or
  preferred `sqlite/current` master tree is created.

Both trees contain working copies. They never point the original engine at
the only immutable source/cache. Resource files are read-only. Output must be
absent and remain below this repository's ignored `offline-dokkan/private`
directory. The original parent and staging directory FDs remain open; generated
reads/writes use relative `O_NOFOLLOW` traversal. Parent/stage identity is checked
before publication. FD-relative Linux `renameat2(RENAME_NOREPLACE)` never
replaces an existing directory or follows a replacement parent symlink. A
pre-publication failure removes only this invocation's owned tree through the
held parent FD. If the parent changes at publication, success is refused and
the verified new tree in the original held namespace is preserved for review;
no unrelated redirected tree is touched. Literal `User`, `save/`, `saves/` and
signing-file arguments are refused before input I/O.

The generated `staging-receipt.json` records the original/manifest/catalog
pins, bundle count and exact compatible aliases. It explicitly records no
live app Documents write, native execution or playable build. It is a source
preparation receipt, not a native startup/save/scope capability.

After the complete extraction is available, use the reviewed private local
paths and manifest hash with this command; do not put Drive account IDs or
personal paths into committed scripts:

```sh
python3 offline-dokkan/original-client/loader/stage_original_resources.py \
  /workspace/dokkan-offline-public/offline-dokkan/private/original-resource-parts/manifest.json \
  /workspace/dokkan-offline-public/offline-dokkan/private/original-resource-parts \
  /workspace/dokkan-offline-public/offline-dokkan/private/iphone-client/byte-identical-assets.sqlite3 \
  /workspace/dokkan-offline-public/offline-dokkan/private/source-client/original-startup \
  /workspace/dokkan-offline-public/offline-dokkan/private/original-resource-staging \
  --manifest-sha256 "$REVIEWED_RESOURCE_MANIFEST_SHA256"
```

The resource extraction and this real-input staging command have not run.
When builds are explicitly authorized, the package recipe must merge
`bundle/` into a fresh own diagnostic bundle, preserve the genuine shell and
prepared original engine. The diagnostic's source now composes the existing
FD catalog/resource preloader/no-overwrite publisher to cold-stage the admitted
working aliases into actual own Documents before `dlopen`, on one serial
preparation queue before `UIApplicationMain`. It enumerates requirements from
the exact pinned catalog and checks actual path/FD identities. This native
composition has not been compiled or executed. Never copy
the opaque seed into the preferred downloaded-master path. Existing native
User/current-master trees remain refused by the diagnostic factory. No
complete native composition or gameplay proof follows from this source tool.

The first combined synthetic scenario passed: a member crossing part boundaries;
different root/tutorial bytes preserved; only the catalog-admitted root bytes
copied to the canonical Documents alias; existing output refused; corrupt
member rollback; and corrupt part refusal. The synthetic constants were
scoped to that fixture, not exposed as CLI overrides. A second focused run
passed the new native-cache/catalog payload, parent replacement during writes
with FD-relative cleanup, parent replacement at publication with refusal of
success and preservation of an external existing tree, `User` refusal before
reads, and FD cleanup. Earlier unchanged cases were not repeated. The final
signing-suffix and exceptional-parent-FD cleanup guards were source-reviewed
afterward; no third run was made. No original game input or native build was
executed in either scenario.
