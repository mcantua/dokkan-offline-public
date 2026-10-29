# Summary

Full custom-unit validation now has to pass before the native save. The WIP validator, bundle script, Core finish call, and scoped asset opener compiled locally. No CI run was started, and no app screen was shown.

# Details

- Branch: `cursor/full-bundle-validation-3bda`, off `chatgpt/ios-eclipse-database-reuse`. Draft PR only. Nothing was merged. The Finish number-precision files were not changed. Extension loading stays omitted.
- `ODNativeFullCreatorValidator` hashes the selected master and requires that digest to match the content id. Known reference columns must exist in the staged bundle or that master. Unknown id columns are not guessed. Shared dependency rows must match the master schema, must not overlap private ids, must agree with each other, and must not disagree with an existing master row. Captured files are read back. A duplicate hash is kept only when the stored immutable bytes match.
- `full_bundle.js` rejects a source-hash mismatch, a missing known reference, and a shared-dependency conflict. It still returns `core_bundle_accepted:false`. One focused rejection check passed.
- `od_creator_finish_bundle` now takes the packet bytes. It hashes them and refuses the save unless the hash and packet fields match the definition binding. Public `creator.import` and `creator.finish` still reject that descriptor. No WebView operation was added.
- `ODScopedCreatorTools` returns an asset file descriptor only when it is readonly.
- Local checks at about 9:50 AM CT: core C syntax with warnings as errors, four SHA-256 vectors, one JavaScript source-hash rejection, and iPhoneOS 16.5 header syntax of the validator and scoped tools with warnings as errors. No release build. No simulator screenshot, because this pass did not start CI and did not reach an app UI.

# Questions

None.

# Needs Tin?

No.

| Pending item | Done | Remaining |
|---|---:|---|
| Full custom-unit validation before save | 75% | Local compile passed. No genuine Xcode 27.1 run of this gate. The Session screen still cannot save a full bundle. |
| Bootstrap auth envelope and fresh-state policy | 0% | Do not invent a success body or starting stats. |
| Original-engine master attachment | 0% | Do not ship Sparking keys. |
| Late service binding in ODUnifiedDuoHost | 0% | Not implemented. |
| In-game Creator menu | 0% | Final menu insertion is still unresolved. |
| Real battles, saves, and summons with custom units | 0% | Not playable yet. |
| Duo two-screen test on a phone | 0% | No physical device check. |
