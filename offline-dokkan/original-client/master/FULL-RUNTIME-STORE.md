# Detached native full-bundle runtime master

`ODRuntimeMasterStore` has a separate native-only entry:
`compileAcceptedFullBundlePacket:error:`. Its existing
`compileAcceptedPacket:error:` remains the strict single-form route and rejects
full-bundle packet fields or descriptors. Neither method is a WebView handler.

The full route requires the exact immutable Session/Core packet:

```
binding
project_bytes
definition_bytes
full_bundle_bytes
full_bundle_sha256
full_bundle_receipt
```

The common accepted binding retains its existing v1 fields. The full receipt is
`od-accepted-full-bundle-receipt-v1`; it binds the local-player profile, exact
content/save scope, definition/version, current owned instance, profile revision,
projection generation, all three byte hashes and member count. A native owner
must obtain it from Core's current owned-instance snapshot. A caller-created
dictionary does not acquire trust merely by matching these structural checks.

Before creating a runtime artifact the store independently checks all exact
byte hashes, the definition's full-bundle descriptor, source SHA, packet identity,
all1–5 member keys/source bindings/target IDs and the common awakening predicate.
False, null and numeric zero do not request awakening, matching Session.

The authored Forge compiler receives those exact bytes through its full-bundle
method. The store checks the complete returned member mapping, private IDs and
both native card rows per member: the awakened card and its `targetID-1` root.
It retains all returned tables, checks actual source column shapes, rejects row
collisions and resolves known scalar/SQLite foreign-key references. The encoded
reference flag is explicitly scoped to `private-owned-row-identities-only-v1`;
it does not claim complete original-game semantic verification.

Each form receives a private1000-ID block. All previous compiled member blocks
and the accepted project's authored blocks are reserved before choosing a new
contiguous cluster. A new accepted version receives a new cluster. The same
accepted version reuses its recorded IDs after verifying exact stored bytes,
receipt identity, regenerated rows and every row's owning version. Extra or
changed owned rows reject the retry rather than silently returning success.

The existing v1 derived-master metadata remains compatible. Full compilation
adds `od_runtime_full_bundles` in the same transaction as its immutable version
and row records. That table retains exact full-bundle bytes/hash and allocated
member IDs. An existing simple version cannot silently become a full version.

Publication uses the existing private lock, readonly SQLite backup, FULL
transaction and atomic readonly artifact replacement. The source remains
readonly and hash-verified; no canonical player state is written. All paths are
trusted native owner capabilities. No actual save folder is accessed by this
source-only development task.

Nonempty captured resources, source-dependency bundles and shared actions fail
with `RUNTIME_FULL_RESOURCE_ADMISSION_REQUIRED` before publication. Their accepted
bytes remain intact in Core. No file/CPK/Lua/animation remap is fabricated and no
resource is quietly removed to produce a partial playable unit.

Every new receipt says `cold_engine_reload_required:true`,
`original_client_attached:false` and `resource_admission_complete:false`.
Compilation does not install a key, attach a foreign SQLite handle, replace an
engine's live path/cache, mint ownership or prove custom-unit battles. The
original-game codec/cache/resource and physical Duo gates remain separate.

Verification is limited to the source contract recorded in
`full-runtime-store-source-evidence.json`. No Objective-C compilation, native
execution, app build, save migration or original-engine gameplay was performed
for this change. Native execution awaits Tin's build authorization.
