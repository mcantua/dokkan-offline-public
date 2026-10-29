# Original-client master admission

`master_contract.py` supplies read-only, bounded, SHA-pinned schema admission for the original iPhone/Duo integration. It rejects non-plaintext SQLite inputs, source/length mismatches, non-standalone snapshots, special files, symlinks, changed inputs, views/triggers/virtual tables and unsupported settings columns. The host provides the selected content hash independently of a Creator document. No supplied SQL is executed and no source database is modified.

The optional settings check uses the exact existing Creator definition table names and actual selected-master column/type metadata. It verifies the source card exists, existing row IDs, scalar/null/integer/text/JSON shapes, unique IDs and row budgets. New row IDs, extended-stat/progression policies and unsupported runtime features reject. It returns only counts, content identity and explicit unresolved contracts. It does not expose row values, create an overlay, assign game IDs, replace global source cards or alter owned-instance/progression state.

This check belongs after the existing core's strict Creator validation. Core semantic checks, fully-awakened eligibility, referential closure and per-save ownership remain mandatory. The selected source's schema cannot establish what the original engine accepts or how it binds a custom definition to an owned instance. Every result therefore states `column_admission_only: true` and `original_client_runtime_admitted: false`. A per-save runtime projection will require verified original-engine row lookup, ID/reference rewriting and instance binding before it can be admitted. Those contracts have not been invented here.

## Actual inputs

The IPA's bundled root `database.db` is a535,552byte non-plaintext seed, SHA256 `667e554a9cfb8c4765f05a1d85f0fdf707ade61562b50e3e5cd98ac52f997ba3`. It is rejected as `PLAINTEXT_SQLITE_REQUIRED`; no decryption or key inspection was attempted. It is not the exported current master.

The complete Android-export manifest pins114,827,264bytes/SHA256 `f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d`. The encrypted original has now been selectively retrieved, verified and authenticated/decrypted as recorded below. Matching it or its verified plaintext derivative does not itself prove iPhone resource/runtime compatibility.

The existing Sparking editor reference is104,357,888bytes/SHA256 `cf13b8553448507ad723e17a7b347e6eac4d7627a2e4fff56c0f7747660dffd8`,19,308cards and233tables. The Eclipse editor reference is103,497,728bytes/SHA256 `4b8d0d0d4c46f339da4dd2c72ab014fdfcb4cc5dc56870aec412481c4a61eae7`,17,786cards and233tables. Their observed card/Creator settings column schemas match, but their content identities differ from each other and from the missing full current master. Neither is silently substituted for that master. The examined `cards`, `leader_skills`, `passive_skills`, `card_specials` and `specials` tables have no declared SQLite foreign keys; relationships must not be inferred from a successful column check.

## Use

To inspect the existing reference with an independently pinned source identity:

```sh
python3 offline-dokkan/original-client/master/master_contract.py \
  unit-creator/apk/assets/sparking-reference.db \
  --sha256 cf13b8553448507ad723e17a7b347e6eac4d7627a2e4fff56c0f7747660dffd8 \
  --bytes 104357888
```

An optional `--definition` accepts an existing core-validated settings definition. No definition or raw DB is checked into Git. The API can be used by host-side import tooling; it is not an on-device SQLite hook or an installed game feature. Use a private standalone snapshot with no concurrent writers. Before/after descriptor/path identity and full hash checks reject modifications before a result is published.

One combined actual-input scenario is recorded in `admission-evidence.json`: actual reference columns accepted; unknown columns, an unverified runtime policy, mismatched source identity, reference-as-current-master substitution and the actual non-plaintext iPhone seed rejected. The original reference hash remained unchanged. No game launch, app package, HTML rebuild or device test was performed.

## Durable per-save rows and native access

`overlay_store.py` now materializes admitted settings into a dedicated private SQLite sidecar. The file is pinned to one independently selected master hash and SHA-256 save identity. It never opens the authoritative player save. A revision and all its rows publish in one full-synchronous transaction, using expected-version comparison and immutable command receipts. Exact retries return the original receipt; stale versions, command conflicts, foreign save/content identities, source-card changes and creator-credit changes reject. A failure after row insertion rolls back the entire edit.

Existing source row IDs remain unchanged inside the tuple `(definition_id, version, table, source_row_id)`. Separate custom definitions may therefore use the same source IDs without replacing global source rows. Recognized reference columns use the existing strict core's `reference_table()` mapping and Forge's source loader; referenced records must exist in the same definition scope or pinned master. An unknown modified `*_id` column rejects instead of inferring a relationship. No new numeric game IDs, blanket remapping rule, SQLite global view or game-cache override has been introduced.

The existing source-only admission currently rejects new local/negative row IDs. Editing settings of existing ability rows can be staged, but newly authored abilities that require new records remain explicitly unsupported. Extended-stat/progression policies, extra runtime/form fields and transformation/resource changes without verified mappings also reject. Nothing is silently removed from a submitted definition. A complete multi-form/custom-resource project must remain in the existing Creator project store while those original-engine paths are implemented; this sidecar does not claim complete Creator runtime support.

`bind_owned` mirrors an instance that the native host has already proved exists in the authoritative core. It never mints a card, imports an account or rewrites level/EXP/Super Attack level/Hidden Potential/team state. A binding cannot be reassigned to another definition. Edits retain the same instance binding and select the new definition head. Host-pinned previous revision lookup permits an in-progress battle to keep its original settings snapshot. Authority over battle-start and edit-in-use checks remains in the actual core.

`overlay_reader.h/.c` is the usable native C read boundary for Duo host integration. It opens an existing sidecar read-only with `SQLITE_OPEN_NOFOLLOW`, verifies format/content/save identity, uses prepared bounded queries and short SQLite read snapshots, and returns scoped rows or binding metadata. The caller supplies the actual Creator projection generation, distinct from the ordinary player/profile revision; stale mirrors reject. The binding includes the digest of its persisted document serialization. Independent core comparison must use JSON semantic equality when serializers differ, while the immutable definition ID/version remains exact. Returned JSON uses SQLite allocation and must be freed with `odov_free`.

Two focused boundaries were checked for this followup: `overlay-evidence.json` records one combined actual-reference store scenario (transactional edit, stable binding, historical revision, retry/conflict, missing-reference rejection, rollback, restart and original preservation); `native-reader-evidence.json` records the new C-to-SQLite boundary (scoped row/binding read and stale/unbound/wrong-scope/nonsettings rejection). The C reader compiled with warnings as errors against the pinned public SQLite header and ran on the host's SQLite3.46.1; the Python staging runtime uses SQLite3.53.1. No on-device or original-engine execution is inferred.

### Required original-engine attach contract — still pending

The runtime inspector has not established an original per-card SQLite lookup/cache context. Static linkage to SQLite does not establish one. Keep this sidecar detached; every receipt/snapshot continues to say `original_client_attached: false`.

Before an actual engine hook may use a row, the native host must establish all of these conditions:

- Verify current selected master and compatible resource identity, and the same private save identity used by the sidecar.
- Establish the actual owned instance using the authoritative core, then verify its definition/version/document digest and current projection generation against the sidecar. Never accept these authorities from a web page.
- Pin a whole definition revision at battle start, preserving scope through every row/reference/cache access. Never replace all instances of an official source card or silently fall back when a custom dependency is missing.
- Establish original row-reader ABI, value representation, per-instance context, reference rewriting and cache invalidation. Actual JSON ability/form/resource semantics need their own verified support.
- Reconcile the committed Creator projection outbox before attachment. The implemented schema10/native callback pipeline below provides durable retry/readback/ack. Core and sidecar remain separate files; a generation mismatch deliberately blocks a read, and the original-engine row/cache binding still needs verification.

The implemented store/native reader can be integrated now as a detached native service. It is not evidence of original-game custom-unit consumption, successful battles or Duo display acceptance.

## Same-transaction core outbox and completed native reconciliation

Core save schema10 adds `creator_projection` and a durable private save identity. Triggers advance a per-profile **projection generation** in the same transaction as relevant active-definition, owned-definition and consumption changes. Ordinary XP, lock or other player revision changes do not invalidate unchanged Creator rows. Native acknowledgement is separate bookkeeping; it neither advances player revision nor mints/progresses a card. Valid schema1–9 saves migrate transactionally. Import stages a private candidate and requeues above both the imported and current projection epochs, so restoring an older backup cannot reuse a device's newer sidecar generation.

The trusted APIs in `core/od_core.h` are outside `od_execute` and all web operation allowlists:

```c
int od_projection_snapshot(od_core *, const char *profile, char **json);
int od_projection_definition(od_core *, const char *profile, int64_t generation,
                             const char *definition_id, int64_t version, char **json);
int od_projection_ack(od_core *, const char *profile, int64_t generation,
                      const char *persisted_state_json, char **json);
```

A snapshot contains `{generation, applied_generation, state}`. Its exact state pins content, private save identity, profile, definition versions and existing owned-instance bindings. Documents are fetched only for that generation and referenced versions. A stale generation or altered binding/state acknowledgement rejects. Cached ordinary command retries do not enqueue a second projection intent.

`OverlayStore.reconcile(snapshot, definitions)` is the host/cloud implementation. `overlay_reconcile.h/.c` supplies the actual native writer with typed callbacks to the already-owning core/bridge queue: snapshot, version-pinned definition fetch, acknowledgement, JSON release and ordinary unkeyed SHA-256. It performs source-row admission, a full-synchronous sidecar transaction, native persisted-state readback and then acknowledgement. A failed acknowledgement leaves the core intent pending; restart safely repeats the same committed sidecar generation. The native worker must run on the existing owner queue and use its exact selected immutable master. It never opens a second authoritative core or exposes a trusted operation to editor JavaScript.

Content IDs preserve the native host's exact `sha256:<hash>`, `eclipse:sha256:<hash>` or `sparking:sha256:<hash>` string. Only the trailing master hash is used for checksum comparison; source prefixes are never stripped or silently migrated. `MasterContract(..., content_id=...)` validates that exact identity against the independent master SHA. The private scope is SHA256 of compact ASCII JSON `[save_identity,profile_id,content_id]`.

The direct native reconcile receipt is the core acknowledgement object `{generation, applied_generation, content_id, save_identity, profile_id}`. It does not announce original-engine attachment. Document SHA values identify their persisted JSON serialization; semantically equivalent immutable documents with different object ordering do not conflict. Reconciliation still rejects unsupported original-runtime features/new IDs instead of dropping them or acknowledging a partial mirror.

`projection-evidence.json` records one focused actual-core save/edit/retry/restart/reconcile scenario, including the schema9→10 boundary, stale/forged acknowledgements, XP/lock independence, progress preservation and older-save requeue. `native-reconcile-evidence.json` records the new all-native C callback pipeline with the actual source-qualified Sparking identity, durable write/readback/ack, failed-ack restart recovery and unsupported-policy rejection. A discovered correlated `json_each` alias was corrected before the successful native scenario; only that failed new boundary was retried. Existing unrelated feature suites were not repeated. Both source masters and authoritative progress were preserved; no original engine, game scene, installed package or physical Duo behavior was asserted.


## Current full game master restored from the actual source

The complete114,827,264byte current export is now available privately. Every one of its28,034 SQLCipher4 pages authenticated. Readable SQLite SHA256 is `1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4`, with the same114,827,264byte length. `PRAGMA quick_check` passed. It contains19,588card rows and232game tables (233including SQLite's sequence table). Table sets and column metadata match the existing Sparking editor reference, with280additional card rows; identical schema does not establish identical content.

`restore_sparking_master.py` reuses the existing Unit Creator pipeline: `SparkingSetup.java` admits the source APK's6.6library by its existing public hash/offset map, and `Host.m` supplies the verified SQLCipher4 format (4096byte pages,80reserved bytes, PBKDF2-HMAC-SHA512 and authenticated AES-256-CBC pages). The actual passphrase is derived from the person's original private APK in memory only. It is never accepted on the command line, written, printed or embedded in source/output. Owned key/library buffers are wiped after use and CLI process core dumps are disabled. Original encrypted input/APK remain unchanged. No SPRK patch-container cipher or guessed database algorithm was substituted.

The helper streams source authentication and the pinned encrypted checksum together, writes only private staging, verifies SQLite/schema before atomic no-replace publication, and keeps the final plaintext read-only. The ordinary narrow-query VM budget initially interrupted full-file integrity work; that fixed `quick_check` now uses its own60second deadline without relaxing normal schema/settings query limits. Only the new failed restoration boundary was investigated; unrelated game/core/native tests were not repeated.

Private inputs/derived databases stay ignored and outside Git. `current-master-evidence.json` contains sanitized hashes, counts, provenance and schema comparison only. The active plaintext snapshot is `offline-dokkan/private/iphone-client/current-export-master.plain.db`; its exact full source/encrypted identity remains separately pinned to `f37296ef05e31000d9868741b18525a5d41311ccc152acb82c848b7b1c8ef14d`. Native data import must preserve that provenance and select the plaintext hash as its own core content identity; do not pretend encrypted and plaintext files share a checksum or silently rebind an older player save.

## Native bootstrap facts and derived runtime-master compiler

Core11 adds persistent own local wire identity and source-grounded EXP only for
new card grants. `bootstrap-evidence.json` describes its focused scenario; the
old Core10 evidence remains the frozen base. Native direct snapshots expose
`source_rank` from the selected master, including real friends capacity.
`fresh-policy-findings.json` records the bounded remaining tutorial/capacity
research. Phase IDs alone do not prove fresh wire progress/content-level enums.

`runtime_master.py` and `runtime_forge.js` now reuse the actual Creator
`Forge.validate`, `Forge.nextUnitId` and `Forge.materializeAll`. The source master
stays immutable. Compilation creates a private per-save derived SQLite master,
adds rows with INSERT only and uses the existing97000001–98999001 private layout.
A newer accepted definition version receives a new unused block; prior version
rows and immutable accepted project/definition bytes remain available. Source
project target IDs and compatibility exports are unchanged. Every output row
must match actual source schema, avoid existing source/runtime IDs, and resolve
known scalar relationships. Unknown encoded relationships/resources are not
claimed verified by those scalar checks.

The trusted host supplies exact immutable accepted project and Core definition
bytes and their SHA values. This API is not a WebView operation and must not be
fed a mutable saved draft or a merely prepared intent. The native Session
accepted-project pending/confirmed registry is a separate integration boundary.
Currently accepted single-form settings must match the complete project card
and projected tables; omitted dependency rows must be identical to the actual
selected source. Forms, new local ability rows unsupported by the strict Core,
custom assets/scripts/animation assignments and unsupported runtime policies
reject explicitly. The complete editable project stays in Creator; no feature
is silently stripped or the strict Core definition relaxed.

The compiler stages a complete source/previous-runtime SQLite backup, applies
one FULL-synchronous transaction, then atomically replaces its own artifact.
A private OS advisory lock serializes compilation and releases on crash. The
published file is read-only; the source and canonical player save are never
updated. Crash staging cleanup and actual original-engine cold-attach/cache
rules remain host responsibilities. Do not update an engine's selected path
mid-battle or assume an open cache follows the replacement.

`runtime_reader.h/.c` supplies native-only `od_runtime_card_id`, validating exact
content/save scope, definition/version and both document hashes before returning
a compiled private card ID. The owner must first protect/verify the derived
file and independently prove authoritative owned-instance/version. This reader
does not load the original engine or prove resource compatibility. A successful
compile/read receipt continues to say `original_client_attached:false`.
`runtime-evidence.json` records one actual current-master/Forge/Core Finish
scenario and the new native reader boundary; no old suite or app build ran.

The immutable native packet is now mandatory:
`{binding:{format:'od-accepted-creator-project-v1',content_id,save_scope,definition_id,version,project_sha256,definition_sha256,instance_id,accepted:true},project_bytes,definition_bytes}`.
`RuntimeMaster.compile(binding,project_bytes,project_sha256,definition_bytes,definition_sha256)`
requires exact native byte hashes; no JS/Python reserialization is a substitute
for the accepted native packet. The host must obtain this from Session's native
accepted-version registry, including receipt recovery, never from tool input.
The compiler's structural receipt checks do not themselves grant native trust.

`ODRuntimeForgeCompiler.h/.m` provides the on-device materialization boundary:
it evaluates only fixed bundled Creator/runtime code in its own JavaScriptCore
context and passes the accepted project as data. `runtime_forge.js` now supports
that global branch as well as cloud Node. It does not write SQLite, allocate
ownership, register any WebView handler or attach the original engine. Native
trusted writer validation/transaction and genuine-SDK compilation remain
separate pending integration; the global JavaScript branch alone was checked
against the actual current-master-derived Forge project.

`ODRuntimeMasterStore.h/.m` now supplies the native transaction writer using the
same registry schema and packet. It verifies the actual immutable master SHA,
uses read-only SQLite backups, rejects a changed/unadmitted omitted row, runs
only the existing Forge allocator/materializer, checks actual source column
shapes/collisions and known scalar references, then appends new private rows and
immutable version receipts in one FULL transaction. Source aliasing is rejected.
Publication fsyncs an atomic read-only replacement, protected by an OS advisory
lock. A failed publication acknowledgement leaves a retryable compiled version;
no progression or ownership is granted. Native trusted callers provide canonical
file URLs inside their own private directory and prove current ownership/lease.

Native writer and JavaScriptCore Objective-C compilation/execution are being
checked together with the existing hosted Finish scenario, not an additional
feature suite. Until that evidence arrives these two native components are
source-ready, with native execution unverified. The Python transaction and C
read boundary evidence does not substitute for this new native writer check.

The final original-engine path/cipher contract remains unresolved. Supplied
iPhone seed and full Android source master are opaque source files; the derived
artifact is plaintext SQLite. File names and linked SQLite symbols do not prove
that the original engine can consume it. The observed asset fopen adapter does
not redirect a master DB. Do not admit custom-unit HTTP runtime IDs or original
battle use until the exact selected engine master path/codec and resource lease
are actually established.
