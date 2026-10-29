# Full Creator bundle staging

`full_bundle.js` is the isolated next admission layer for the **complete saved
Forge project**, including linked forms, new abilities, attached resources,
custom scripts, authored movies, artwork, poses and shared dependencies. It
uses the existing `ForgeForms.reserve`, `ForgeUnitRebase.reserve`,
`Forge.materializeAll` and `Forge.exportEntries`. It contains no battle formulas,
new ID range, gameplay UI or substitute engine.

The current production gates remain intact. This module returns an explicitly
unaccepted candidate, never a Core receipt or original-engine admission.

## Current rejection points

| Layer | Actual restriction | Required full-bundle extension |
|---|---|---|
| `adapter/creator-project.js` `checkUnsupportedRuntime` | Nonempty `formProjects`/`transformLinks`, assets/CPKs/scripts, action/animation hooks, pose bindings and source dependencies reject. | Preserve a full immutable project, not an expanded single-card settings DTO. |
| `mobile/ios/ODCreatorSession.m` `ODUnsupported` / `expectedDefinition` | Same runtime rejection; only established settings tables enter the recomputed definition. | New typed native full-bundle acceptance; exact pending bytes before command, cached-receipt recovery, immutable accepted versions. |
| `core/od_core.c` `definition_validate_ex` | One original-source root card, fixed table set/row validation, no forms/resources document. | Versioned full-bundle identity tied atomically to the single owned instance and progression. Do not relax or repurpose the existing strict definition. |
| `master/runtime_forge.js`, `runtime_master.py`, `ODRuntimeMasterStore.m` | Current accepted single-form packet only; custom resources/forms/unsupported policies reject. | Consume the separately admitted full candidate and native resource/reference proof. |
| Original engine | Master path/cipher/cache, resource namespace and actual transformation runtime ownership remain unverified. | Actual source-backed attachment and gameplay proof before runtime DTO admission. |

## Existing complete Creator contracts reused

`forms-model.js` permits one starting form and at most four additional forms,
with at most64 explicit existing efficacy103 transformation links. All members
use the same selected source. Nested bundles, unsupported cycles, overlapping
private blocks and conflicting resource paths reject. `transformLinks` is the
actual field name. Indirect source-card transformation chains use Forge's own
reachability and card-map logic.

`ForgeForms.reserve` preserves old member blocks under distinct reservation
keys, calls `ForgeUnitRebase.reserve` for every standalone member, and updates
both transformation numeric fields and encoded `efficacy_values`. The existing
rebase path regenerates the existing movie/counter/action scripts and uses the
existing art/pose planning functions; this module invents none of those rules.
It requires native scoped query/storage callbacks for the features being moved.
The existing Creator explicitly disallows multi-form shared Sparking animation
dependencies and custom shared Dodge hooks. Those combinations still reject.

## Native-only candidate API

```js
const candidate = await ODCreatorFullBundle.stage(immutableProject, {
  contentId, saveScope, projectSHA256, definitionId, version,
  ownedInstanceId, sourceDatabase, schema, query, projects,
  sha256Text, describeAsset, listAssets,
  readAsset, storeLwf, storeDecoration, prepareCounters,
  sourceSHA256, sourceHashVerified
});
```

The native caller must independently verify exact original accepted project
bytes/hash and source/save identity; a JavaScript object or supplied hash does
not grant that authority. `sourceSHA256` must be the lowercase digest named by
`contentId`, and `sourceHashVerified` must be true only after native code has
hashed that master file. The JavaScript check rejects a mismatch. It does not
replace the native hash. `query` is the existing bounded read-only selected
master/runtime query. `projects` includes every retained historical runtime
reservation. `schema` is the actual selected source PRAGMA metadata. Storage
callbacks stay private/native and must scope generated files to this candidate.
No WebView operation or raw SQL mutation is introduced.

Each member retains the **same** native `ownedInstanceId`, or null while that
single authoritative ownership binding is pending. A form never mints inventory,
gets an independent EXP/Hidden Potential/Super Attack record, or copies account
state. Battle form changes must resolve through that one canonical instance and
its pinned definition version; this module does not implement progression.

The candidate retains the complete rebased project, all materialized rowsets,
all member mappings, compatibility export entries, resource entries and shared
source/action bundles. Compatibility SQL is preserved as an export only and is
never executed here. No `INSERT OR REPLACE` touches the immutable source.

Asset inputs need native attestation of SHA/size/current content/save scope.
Generated text is hashed by the native callback. CPK entry sources are retained
with exact names and input hashes; their output container build remains pending.
Shared Dodge settings/generated dispatcher remain separately marked for an
actual shared-action binding instead of disappearing with Forge's normal
per-unit exporter exclusion. Shared dependency rowsets are retained separately,
requiring source identity/reference/resource admission before installation.

`runtimeProjectJSON` contains the exact staged UTF8 JSON string and
`runtime_project_sha256` identifies those exact bytes; its encoding is explicitly
`utf8-json-stringify-v1`. It is not substituted for native `NSJSONWritingSortedKeys`
original-project hashes. A native publisher must preserve/verify the exact
staged bytes, generated-file proofs and the original accepted-version linkage.

On failure, `createdAssets` identifies candidate-owned new storage keys for
native cleanup. Never delete original attachments, a previously accepted bundle,
or the sole working artifact. Publication, cancellation and retry ownership
remain the native host's responsibility.

Every result says `core_bundle_accepted:false`, `original_client_attached:false`
and `gameplay_ready:false`. Its unresolved list includes native atomic full
acceptance, reference/encoded-ability proof, native derived-master publication,
resource/CPK building, actual engine path/cipher/cache and the shared progression
lease. A successful candidate alone never unlocks the existing production gates.

## Validation before save

The native validator hashes the selected plaintext master and continues only
when that digest is the hash named by the content id. Known `*_id` columns must
point at a row in the staged bundle or that master. Unknown `*_id` columns are
not treated as references. Shared dependency rows must use the master schema,
must not overlap private row ids, must agree across members, and must not
disagree with a master row that already uses the same id. Multi-form projects
still reject shared animation dependencies and custom shared Dodge hooks.

Captured bytes are read back from the immutable blob. A second file with the
same hash is kept only when the stored bytes and size match and the stored file
is not writable. `od_creator_finish_bundle` hashes that packet and refuses the
save unless the hash and packet fields match the definition binding. Public
`creator.import` and `creator.finish` still reject a full-bundle descriptor.
No WebView operation was added.

The Session screen can save a full unit only after the host installs
`ODNativeFullCreatorValidator` for the saved `local-player` account. Prepare
then returns `fullBundle:true`. Finish ignores a page-supplied packet, runs
that validator on the saved project, and imports one owned copy into the open
account. The same Finish command keeps that copy. A page that sends
`full_bundle` is rejected. Nothing here attaches the original engine or makes
a custom unit playable.

## Focused evidence

`staging-evidence.json` records one new data-only scenario with the actual full
current master and two real fully awakened source characters. Existing Forge
attached/rebased two forms and retained an added copy of a real inherited
ability (no invented mechanics).234 rows materialized; all member ownership
bindings stayed on one instance, original project remained unchanged, staged
bytes matched their hash, and a resource attested for a different save scope
rejected. No game source rows were mutated, app/HTML package built, old suite
repeated, original engine attached or real gameplay asserted.
