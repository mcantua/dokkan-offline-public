# Authored-movie runtime candidate plan

`runtime_movie_plan.js` is a new asynchronous, native-only candidate API. It
leaves the existing synchronous compiler, runtime store and their closed
resource gates unchanged. It neither publishes files nor inserts rows, loads
the original engine or grants a playable-unit receipt.

## API and trusted callbacks

```js
const candidate = await ODRuntimeMoviePlan.planAcceptedMovies({
  project, fullBundle, definition, acceptedBinding, fullBundleReceipt,
  nativeByteHashesVerified: true,
  nativeByteHashes: { project: projectSHA, definition: definitionSHA,
                      fullBundle: fullBundleSHA }
}, {
  schema, reservations,
  contextIsCurrent, query, listAssets,
  attestAcceptedResource, sha256Text
});
```

Input objects are decoded copies of the exact native accepted packet. The
native owner must independently verify the bytes/hashes and authoritative
current-version ownership receipt before constructing them; a JavaScript flag
or caller-created dictionary provides no acceptance authority. Content/save,
profile, definition/version/instance, member order, all three hashes and receipt
revision/generation must agree. Original materialized rows are recomputed at
the acceptance UTC and must match the immutable bundle.

Callbacks are native-owned closures, not page arguments:

- `contextIsCurrent()` resolves true only while the pinned native context and
  job remain admitted. The owner must revalidate current generation/version
  before eventual publication; the input receipt is a snapshot, not a lock.
- `query(options)` uses the existing bounded readonly selected-master/runtime
  query contract. `listAssets(options)` returns the actual bounded namespace
  catalog array. Neither callback may substitute invented empty collision data.
- `attestAcceptedResource(path)` accepts only the original declared logical
  path. The new `ODAcceptedCreatorResources` reader can back this with its
  `attestDeclaredResource:completion:` method. The result is exactly
  `{path,sha256,size,content_id,save_scope,full_bundle_sha256,project_sha256}`
  after native readonly blob verification and context admission. No file
  descriptor, filesystem path, mutable editor asset key or arbitrary hash
  lookup enters JavaScript.
- `sha256Text(text)` hashes the exact UTF8 candidate manifest for its pinned
  `plan_json`/`plan_sha256` identity.

The async job checks current admission before and after native calls. A private
copy of the accepted project is used throughout; the caller's original project
must remain unchanged. A fixed Date is used only during synchronous original
and final Forge materialization, never while awaiting callbacks.

## Existing Creator behavior reused

`ForgeForms.reserve` calls the actual `ForgeUnitRebase.reserve`, which performs
its existing row/resource collision checks and invokes `ForgeMovieModel.rebase`.
The planner does not copy transformation rewriting or replace numeric strings
in filenames. The real movie model updates its effect-pack name, logical USM
destination, private unit binding and supported movie clip metadata.

The supported custom-resource subset is declared authored movies only, plus
resource-free units/forms. Every movie has an actual declared captured asset,
matching immutable size/hash, original movie owner/key and a supported binding.
Custom artwork/fighters, CPKs, generated scripts, counters, shared dependencies,
action hooks and animation assignments/overrides reject explicitly. An orphan
`forge_movie_` row without a movie binding is not treated as resource-free.

For each supported movie, the candidate maps an **accepted logical path** to
its new logical destination while preserving the attested bytes, SHA-256 and
size. It returns the old/new effect-pack IDs, accepted project-row identity,
new pack name/path/private-unit ID and unchanged frame/audio metadata. The
materialized effect-pack row must agree with that exact binding. It exposes no
borrowed asset-store key or FD as resource-opening authority.

All actual Forge rowsets and member mappings remain in the candidate, including
the native tens-root and awakened card rows. The accepted editable project is
not replaced; transient Studio metadata changes are not written back into it.

## Deliberately unfinished publication boundary

Forms reservation returns candidate IDs through its existing algorithm. They
are not guaranteed to be a contiguous writer allocation. The current runtime
store's synchronous full-packet/resource gate remains closed; do not pass this
candidate to it as an accepted compiled artifact. A native async resource-aware
writer must reserve/revalidate these exact IDs, verify all row/encoded/source
references, publish resources coherently with the derived master and establish
the original engine's cold-reload/path/decoder contract.

Accordingly the candidate explicitly reports allocation, resource publication,
original-client attachment and gameplay readiness false. Encoded-reference
completeness also stays false. Hashing movie bytes does not prove USM decoding,
correct native playback or complete gameplay routing; units with custom Lua
assignments still require their own admitted branch.

## Focused source evidence

One invocation of `check_runtime_movie_plan.js` used a synthetic card/schema
and opaque synthetic movie bytes with the actual MovieModel plan/apply and
Forms reservation/rebase chain. It retained input identity, updated the real
pack/destination/private-unit metadata, preserved the descriptor hash/size,
kept native card roots and rejected changed capture metadata, another resource
branch and stale context. The evidence explicitly labels native callbacks as
simulated and USM decoding/native publication as unverified.

No existing tests were rerun. No native compilation, app/HTML build, original
game execution, save access or personal connection was used. The new candidate
still needs a native JSC adapter; this module alone is not a finished game.
