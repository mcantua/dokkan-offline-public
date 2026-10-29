# Accepted full-bundle row materialization

The new native-only `materializeAcceptedFullBundle` API is separate from the
existing strict single-project compiler. It does not weaken that compiler,
register a WebView operation, write a database, mint inventory or load the game.

## Trusted packet and allocation

`ODRuntimeForgeCompiler` copies the supplied project, definition and full-bundle
`NSData` before computing SHA-256. Project/definition digests must match the
existing exact nine-field accepted binding, and the full-bundle digest must
match the accepted definition's full-bundle descriptor. Native code sets the
internal hash-verification flag only after checking those exact bytes. A
JavaScript flag or data object alone is never acceptance authority.

The native caller separately proves the authoritative live full-bundle receipt,
content/save scope, current version and one owned instance. The native writer
owns collision checking, a contiguous cluster of one to five blocks, reference
validation, publication and idempotence. IDs use the existing Creator range
97000001–98999001 in 1,000-step blocks. They are returned exactly as requested.
`next` retains the old compiler contract; it is not automatically advanced past
the returned member cluster.

Before runtime rebasing, the compiler validates the complete Forge project and
recomputes its original materialized rowsets at the native acceptance packet's
fixed `materialization_utc`. Those rows must match the immutable bundle exactly.
This rejects an incompatible materializer/source revision rather than silently
changing a previously accepted unit. Bundle member order, keys, source binding,
authored IDs and transformation links must match the accepted project.

## Supported source-backed rebase

The initial full path supports resource-free settings and linked forms. It
copies the target remapping already used by `ForgeForms.target/reserve`: known
efficacy103 target fields, their encoded `efficacy_values[0]`, and explicit root
transformation links move together. `Forge.materializeAll` then performs the
existing source-card map, causalities, animation-row references, transformation
parameters and card-row materialization. No new ability or battle rule is
invented.

Each form retains both actual native rows emitted by Forge: the awakened card
ID and its tens-root row required by `Card::getRootCard()`. Returned
`native_root_card_ids` identify those roots. The member list remains one entry
per form, with the accepted authored ID and the newly requested runtime ID;
these rows never grant another owned instance or progression record.

Mixed overlap between old authored blocks and a changed runtime cluster is
unsupported. Reserve old blocks when allocating a new cluster, as the existing
Forms reservation code does. An identical mapping remains valid for an exact
idempotent retry.

After recomputation, any remaining moved private row-ID token in numeric,
encoded or resource fields rejects. Display-only name/description/timestamp
fields are preserved. The compiler does not guess whether an ambiguous number
is an undocumented effect operand. The returned
`encoded_references_complete:true` has the explicit scope
`private-owned-row-identities-only-v1`: it is not universal proof of proprietary
ability semantics, external source references, script behavior or gameplay.
The native writer must still validate source/database relationships.

The supported accepted authored slots are the same modern aligned private
blocks (97000001–98999001, ending001). Forge can accept other manual slot
shapes, but those now return the explicit
`RUNTIME_FULL_BUNDLE_AUTHORED_SLOT_UNSUPPORTED` gate, not a misleading hash or
binding failure. For example, a manual old ID ending0 has one native card row
before a rebase to an awakened/root pair; arbitrary old ranges can overlap new
skill-set identity namespaces. Those migrations need their own source-backed
row/reference proof before support is widened. The accepted bytes and editable
unit remain intact. This distinction was found by source inspection; no old
scenario was repeated to change the diagnostic code.

## Closed resource gate

Attached files, CPKs, generated scripts, authored movies, artwork/pose bindings,
shared dependencies, action hooks and animation assignments/overrides require
separate resource/ID/path proof. Such a packet returns
`RUNTIME_FULL_BUNDLE_RESOURCE_ADMISSION_REQUIRED`; it is not converted to a
settings-only unit. No resources or forms disappear silently. All results keep
resource admission, original-client attachment and gameplay readiness false.

## Focused evidence

One invocation of `check_full_runtime_forge.js` used the real Forge materializer
with a synthetic immutable two-form packet. It retained four native card rows,
rebased explicit and encoded transformation targets, remapped an indirect
source-card return, preserved the accepted project, and rejected changed hash
binding, unproved resources and an unmapped private-ID operand. The old
single-project API still rejected the form bundle. Exact scope is recorded in
`full-runtime-forge-evidence.json`.

No Objective-C compilation, native transaction, original game execution,
HTML/app build, physical display check or played save was involved. The native
compiler and writer integration remain source-only until an authorized focused
native verification. This is not a playable build.
