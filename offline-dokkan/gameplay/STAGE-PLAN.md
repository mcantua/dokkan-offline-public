# Source encounter planning for our own game

`stage-plan.js` resolves an actual map/quest/area, selected battle/round, enemy card references, enemy/round skills, puzzle-color weights and the selected source's AI catalog inventory through a fixed read-only native query adapter. Queries bind IDs; the selected provider/content/query identity is pinned before and after every asynchronous call. This module never contacts a server, grants rewards or substitutes invented original boss stats.

```js
const result = await OfflineDokkanStagePlan.planEncounter({
  source: {provider, contentId, query: nativeSelectedMasterReadOnlyQuery},
  mapId, battleIndex, roundNo,
  assetManifest: {json: installedManifestJson, sha256: nativePinnedManifestSha,
                  resolve: nativeVerifyInstalledAsset},
  authoredPolicy: nativeOwnEncounterPolicy,
  nativeStats: nativeReadOnlyCardStats
});
```

The source provider is provenance only, not a mode/player selector. `battleIndex` and `roundNo` are explicit trusted encounter selections; the planner does not guess a board destination. The result includes `supported`, `enemy|null`, exact `unsupported` gaps, resolved `facts` and `provenance`. Unsupported data cannot produce a partially usable enemy. `rewards` is always `null`; the run coordinator must independently validate progression, team, entry costs, dependencies and actual reward rules.

## What the supplied data proves

The supplied Eclipse snapshot has5,478 map-enemy records and the supplied Sparking snapshot5,567. Inspection found enemy objects containing only `card_id`, `enemy_skill_ids` and `enemy_round_skill_set_id`. Their round objects supply round numbers/IDs and enemy lists. They do **not** contain encounter HP/ATK/DEF, source level, AI binding or attack-slot plans. Five Sparking records have invalid JSON and some rounds lack IDs; the planner rejects malformed data and uses only an explicitly identified unambiguous round. The `enemy_ai_conditions` table alone does not establish which rule a given enemy uses.

Accordingly, default strict mode returns `STAGE_ENCOUNTER_STATS_POLICY_REQUIRED`, `STAGE_ENEMY_AI_BINDING_UNAVAILABLE` and the missing board-policy gap. It does not treat collectible-card maxima as original boss stats. Actual source skill records are loaded for provenance; any nonempty enemy skill list or round-skill-set reference is currently blocked instead of silently ignored. Multiple-enemy rounds and stage scripts also remain unsupported.

## Explicit authored encounter policy

Our own game may choose its own documented encounter balance. The native caller can provide:

```js
{
  id: 'offline-static-encounter-v1', version: 1,
  level: sourceLevel,
  hpScalePpm, atkScalePpm, defScalePpm,
  // hpBudget is optional and explicitly overrides scaled HP.
  attacks: [{slot, multiplierPpm}],
  kiBoardPolicy: 'uniform-six-v1',
  classPolicy: 'preserve-source-class-v1',
  presentation: 'authored-minimal-v1' // or verified-source-assets-v1
}
```

All numeric balance values and static attack slots are explicit. There are no guessed original values or hidden defaults. `nativeStats({contentId, masterId, level})` must return the actual read-only native `od_card_stats` result for that source card and configured level, with `master-coefficient-linear-floor-v1` and `base_excludes_bonuses=true`. Missing/invalid/bound-to-another-card stats reject. The source level cannot exceed the source cap. Integer scale operations floor exactly and reject overflow. The source card's name/type/class remain intact; native/source policy metadata preserves its unverified original rounding status.

For a plain single enemy with **no source enemy skills or round skill set**, this policy produces a real engine enemy from source-backed card stats plus the explicit authored scales/HP budget and repeated static normal attack slots. It says `originalEnemyAIResolved:false` and `originalGameParityVerified:false`. This is our balance, not a claim about Eclipse/Sparking's original encounter behavior or a recovered agreement. Source collectible passives/Leader Skills are not silently reused as enemy AI; enemy-specific skill lists are the actual source encounter ability references.

The output preserves `classType` from the actual encoded source element (`0..4 neutral`, `10..14 Super`, `20..24 Extreme`) and requires the new explicit `offline-turn-battle-source-v2` battle policy. That engine policy supplies the documented own class/stat-phase calculation choices. The planner does not drop class to force compatibility with the earlier limited policy. `uniform-six-v1` explicitly chooses our current uniform Ki board rather than claiming the imported map's nonuniform puzzle weights are implemented.

## Verified dependencies

The native host supplies a pinned SHA256 for an installed JSON manifest:

```js
{
  format: 'offline-dokkan-stage-dependencies', version: 1, contentId,
  encounters: [{mapId, battleIndex, roundNo, presentation,
    dependencies: [{path, size, sha256}]}]
}
```

The planner checks the manifest's actual bytes/hash, exact selected content/encounter/presentation, nonempty bounded dependency list, paths/sizes/SHA256 and absence of duplicate paths. Each dependency then goes through the trusted native resolver, which must return `{verified:true, size, sha256}` matching actual checked bytes. The resolver callback is native authority, not an `assets_ready` field accepted from a game page. Manifest construction still needs a complete source-backed dependency mapper; a content hash does not prove an arbitrary list is complete. Unknown/incomplete dependencies must not be omitted.

`authored-minimal-v1` permits our actual bundled authored renderer resources as explicit presentation dependencies. It does not pretend to supply original artwork or attack animations. `verified-source-assets-v1` requires the corresponding real imported dependencies; it is not satisfied by an authored CSS file. Complex source animations/Super Attacks and their Lua dependencies remain separate integration work.

One targeted actual-master scenario passed using the supplied Eclipse map/round/card, the real native read-only card-stat helper, and a SHA256-verified existing authored `battle.css` file. Default strict mode refused missing encounter policy; the explicit authored policy produced scaled actual source stats/static normal attack slots; a changed manifest hash blocked output. No raw database rows/assets were committed. This is not a native battle launch, source-AI reconstruction, proprietary-animation check or gameplay completion claim. Existing turn/session checks were not rerun.
