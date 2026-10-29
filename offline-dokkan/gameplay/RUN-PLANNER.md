# Preparing one actual local encounter

`run-planner.js` joins the existing owned-source translator, source encounter planner and battle engine into one trusted native preparation call. It does not create a second character catalog. It reads the actual saved team and the current immutable custom/upgrade definitions already used by the local core, including characters registered through the embedded Creator.

```js
const prepared = await OfflineDokkanRunPlanner.prepareEncounter({
  source: {provider, contentId, query: nativeSelectedMasterReadOnlyQuery},
  profile: actualProfileSnapshot,
  teamSlot, supporterInstanceId,
  coreStats: nativeOwnedCardStats,
  nativeStats: nativeSourceCardStats,
  assetManifest: {json, sha256, resolve: nativeVerifyInstalledAsset},
  battlePolicy: nativeExplicitSourceV2Policy,
  rosterPolicy: OfflineDokkanSourceRoster.policyId,
  encounterPolicy: nativeExplicitEncounterPolicy,
  mapId, battleIndex, roundNo, battleId, seed
});
```

The normal native caller loads `battle.js`, `source-roster.js`, `stage-plan.js`, then `run-planner.js`; Node uses the same modules through `require`. This is a native-owned capability, not an API that accepts arbitrary page-provided callbacks, policies, snapshots, SQL or ownership claims.

The actual `profile.snapshot` must match the selected verified source hash and have a revision. The selected team must contain exactly six distinct owned instance IDs. The helper is a seventh distinct owned instance; the first team member and helper are the two leaders. A missing character, duplicate helper, ambiguous team or missing/current-version effective definition fails. Created definitions come from `profile.created_definitions`; official upgrades come from `profile.official_upgrades`. Tournament-exclusive definition translation remains an explicit unsupported result. Merely registering a new Creator unit does not grant an owned copy: the planner requires an actual owned instance from the core.

`coreStats({contentId, profileId, profileRevision, instanceId})` calls the native core's actual `card.stats` for each owned instance. It may return that raw result, or a stronger native envelope with those four binding fields plus `stats`. An envelope with the wrong revision/source/profile/instance rejects. A raw result is recorded as not independently revision-attested. The native host must serialize these reads against the actual revision and recheck it at admission; a captured snapshot hash alone is not authority over a changing save.

`nativeStats({contentId, masterId, level})` is the stage planner's actual read-only native source-stat callback. `assetManifest` and the explicit source-v2/encounter policies retain their existing documented contracts. No stage balance, Class multiplier, Ki curve or summon policy is silently invented here. Missing animations under a policy that requires them block battle configuration.

Caller JSON data is copied before the first await. Source/provider/query, profile identity/revision and native callbacks/manifest are pinned around asynchronous work. All seven fighters pass the source translator, the actual selected source encounter and asset dependencies pass `stage-plan.js`, then `Battle.create` validates the combined input. Successful output contains a deeply frozen `configuration` suitable for the existing native battle session's `startTrustedPlan` **after native admission**. `provenance` includes source master SHA256, profile revision, exact snapshot/roster/configuration SHA256, actual selected team/helper and both source translation and stage provenance. SHA256 identifies the chosen bytes; the native importer/query adapter must already establish the selected file's identity.

Unsupported input returns `supported:false`, `configuration:null` and precise combined roster/stage/binding gaps. Partial fighters/enemies are never returned as a playable configuration. Input errors become a clear failure result; private native exception text is not exposed.

## Preparation does not authorize or settle a run

`rewards` remains **null**, not a fabricated zero-reward schedule. `authorizesRunStart` and `grantsRewards` are false. `requiresTrustedRunValidation` and `requiresNativeRevisionCheck` are true even when preparation is supported.

`admission` records actual source ACT/event-key/prerequisite fields, snapshot ACT and whether ACT is affordable. It still says `requires-native-validation`. The planner does not grant ACT, invent a starter card, unlock a quest, debit resources, create a core run, resolve unknown reward rules or claim a win. The trusted native coordinator must verify the current profile revision, unlocks, entry cost, complete installed dependencies and actual reward policy, then start the real core run transactionally before gameplay. It must route a persisted battle result through the existing trusted settlement/receipt boundary. A prepared battle is not proof of admission, a legitimate clear or gameplay completion.

## Focused integration evidence

One new combined planner case passed against the supplied master read-only. It imported a source-backed authored custom definition through the actual core, summoned seven actual owned copies under an explicitly test-only pool, saved a six-member team with `team.set`, and used the snapshot's current definitions and actual `card.stats`. The actual source map10/plain enemy1000580, actual native enemy stats and actual SHA256-checked authored `battle.css` dependency produced one valid frozen/hashed configuration. Duplicate-helper and stale native revision guards rejected. No prior engine/session test suite was repeated, and no production banner rates changed.

The prepared configuration and initial battle state were retained once in ignored `offline-dokkan/mobile/work/real-planner-preview/` for a browser screenshot. That is an authored development custom team with real source/core bindings, not native/physical game execution or original-engine parity. The source master SHA256 stayed unchanged. No reward, ACT or run-start authority was granted by the planner.
