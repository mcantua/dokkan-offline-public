# INTERNAL HARNESS — not the production Dokkan game

Tin rejected this simplified replacement-game presentation. This directory's authored mechanics/policies and view are retained only for internal backend experiments. They do not satisfy the required 1-to-1 Dokkan client, visual, animation or gameplay behavior. Do not ship or present this as the finished game. No more replacement-game work is authorized as the production direction; use the real client/engine with the local core and embedded Creator.

# Local turn-battle foundation

This is an actual state machine for our own game's turn/rotation, Ki Sphere choices, attacks, damage, enemy responses and victory/defeat. It does not reuse the Creator Combat Workshop's approximate real-time fighting controls. No source-game login, HTTP adapter, networking, proprietary assets or reward grants are involved.

`battle.js` loads in a browser/WKWebView/WebView as `OfflineDokkanBattle` and in Node with `require`. `battle-view.js` mounts interactive controls over an actual host-supplied battle. It contains no demo roster or fake stage. `battle.css` supports narrow and wide windows. These are a gameplay foundation, **not completed native playable-game integration or original-engine parity**.

## Host contract

The trusted game host creates a battle from its actual owned team and `card.stats` results, effective immutable custom/master definitions, read-only source data, verified enemy/stage dependencies, and an explicit policy:

```js
const state = OfflineDokkanBattle.create({
  battleId, contentId, seed, policy, roster, enemy
});
```

Seven distinct owned instances include the chosen supporter. Each fighter supplies actual HP/ATK/DEF, numeric Type (`AGL=0`, `TEQ=1`, `INT=2`, `STR=3`, `PHY=4`), base/max Ki, a complete integer Ki-multiplier curve, up to two source-backed Super Attacks with thresholds/multipliers, normalized phase effects and the core's separate final-exclusive descriptor. No guessed stats/curve/attack multiplier defaults exist. The maximum Ki is12 or24. Name/master/instance IDs preserve the connection to the actual character.

The host must account for **every** source effect in `coverage.sourceEffects` / `translatedEffects`; unsupported effects/capabilities fail before starting. A coverage declaration is a trusted-host assertion, not proof that the engine can interpret raw passive rows. **Never strip unknown source effects, class/leader/link rules, transformation/active/standby/revival/counter requirements or resource dependencies just to pass validation.** Raw DB rows still need a verified translator. This module's supported capability list is deliberately limited; full Dokkan skill semantics remain unfinished.

`enemy.attacks` is the trusted stage's ordered attack plan, with slots0..3 (before first unit, before second, before third, after third). Attack values are already computed source-backed enemy ATK values; this module does not infer enemy AI from a map ID. The same plan repeats each turn in this first version. More complex turn-dependent plans must not be silently flattened into it.

Commands are `collect` with an ordered `[x,y]` path, `order` with the same three unit IDs in a new order before Ki collection, or `resolve` after all three units collect. Each has an intent ID and the current revision:

```js
const result = OfflineDokkanBattle.transition(state, {
  id: intentId, revision: state.revision, kind: 'collect', path
});
// result = {state, events, replayed}
```

Commands clone their input before mutation. Invalid selections cannot damage current state. Same-ID/same-input retries return the current state without new attacks/events; changed-input reuse and stale revisions fail. IDs are retained for the entire bounded battle rather than evicted/reused. The RNG and board persist, so restart does not reroll collected spheres or previously resolved combat.

The host serially commits `serialize(result.state)` to its private battle save **before** showing `events`. It must pin the immutable battle configuration/content and own the trusted state; client-supplied saved JSON is not authority to claim a clear. `restore` validates shape/ranges/identity but does not authenticate a save. Trusted run settlement must independently resolve this battle ID/outcome exactly once through the existing core. This module cannot create stones, owned cards, rewards or completed quests.

## Explicit first-version policy

The required `offline-turn-battle-v1` policy names an **own game rule**, not a verified original Dokkan formula. The host explicitly supplies minimum damage, Type advantage/disadvantage and critical multipliers; production must not invent undocumented defaults. Integer multiplications use BigInt floor division and reject unsafe results.

- The Ki board is a bounded5×6 rectangular grid. Collection starts at the bottom and follows adjacent same-color spheres, with Rainbow connectors. Matching Type spheres give2Ki; other/Rainbow spheres give1Ki. Same-color healing, special sphere changes and alternative collection topology are not implemented. Required unsupported capabilities reject.
- Three selected units collect, then the entire turn resolves. Reordering is allowed before collection. The ordered first three return to the end of the seven-unit rotation queue; the first two recur after two turns, while the third floats to the later rotation. Player ordering controls the next returns.
- ATK/DEF leader/start/on-attack/per-sphere percentage groups are separate floor-multiplied phases; within a phase, percentages add. On-attack DEF is not active for enemy attacks before that unit attacks. The core's Super/Godly Exclusive ATK/DEF applies once after these stat phases. The host must exclude the Creator's corresponding already-encoded exclusive rows to avoid counting them twice.
- ATK is floor-multiplied by the exact supplied Ki curve and the highest reached Super Attack multiplier. Type follows `TEQ>AGL>STR>PHY>INT>TEQ`. Ordinary damage subtracts enemy DEF after the attack multipliers and then applies the explicit minimum. Critical hits use the policy's critical multiplier and bypass enemy DEF/Type. This legacy policy does not apply Class modifiers. The explicit source-v2 policy below adds static Class handling; attack variance and full official calculation parity remain unfinished.
- Enemy attacks subtract the current defender's effective DEF, then apply ordinary damage reduction and the separate final exclusive reduction once. Static critical/dodge chances and one additional normal attack are supported. Stacking, conditional chance scopes and additional Super Attacks are not.
- Battles stop immediately at victory or defeat. A128-turn limit returns `unsettled-limit`, not a fabricated clear/loss/reward. Unknown/missing skill or animation capabilities do not become no-op successes.

Animation descriptors carry only a safe relative path and SHA256. With `policy.requireAnimations=true`, Super Attacks without descriptors fail creation. The native host must resolve all descriptors using its verified content resolver before starting, then feed committed events to the real animation player. A descriptor alone does not prove an animation exists or that Lua playback works. The view currently shows the interactive sphere/team/HP state; full character artwork and attack-script rendering remain to integrate.

## Interactive view

```js
const view = OfflineDokkanBattleView.mount(container, {
  load: async () => nativeBattleLoad(),
  dispatch: async command => nativeBattleDispatch(command),
  onEvents: async (events, state) => playVerifiedBattleEvents(events, state),
  onExit: returnToGame
});
```

The host serializes `load` behind `dispatch`. After a transport failure, the view reloads canonical state to distinguish rejection from a committed result whose reply was lost. If reload also fails, it retains the same intent for retry and disables other commands. It does not mint a second attack/collect ID for an uncertain write. Closing a view leaves native persisted battle state intact.

One combined `node offline-dokkan/gameplay/check-battle.cjs` scenario passed with authored fixtures: a played turn, correct separate ATK phases and pre/post-attack DEF, rotation, serialization/restart, no-repeat retry, invalid-path preservation, victory/defeat and unsupported-capability refusal. This is **not** a native launch, a real imported-character battle, real animation playback or final gameplay acceptance. Do not rerun it for unrelated code changes.


## Source-backed flat stats and static Class

The legacy `offline-turn-battle-v1` policy and version1 serialized states retain their previous behavior. `Battle.policyId` still names that policy. New source-backed battles select `Battle.sourcePolicyId` (`offline-turn-battle-source-v2`) and must supply `statPhasePolicy: Battle.statPhasePolicyId` (`percent-then-flat-by-phase-v1`) plus:

```js
classPolicy: {
  id: 'static-class-v1',
  samePpm, opposingPpm, neutralPpm, // Explicit own-game values, no hidden defaults.
  critical                        // Explicitly 'apply' or 'bypass'.
}
```

This policy requires `classType: 'neutral' | 'super' | 'extreme'` on every fighter and enemy. Actual encoded source `element`0–4/10–14/20–24 determines neutral/Super/Extreme; the source normalizer preserves the full original encoding and awakening metadata separately. Missing/unknown Class fails, and the source-v2 fighter declares `static_class` coverage. The configured same/opposing/neutral multiplier applies after Type and before subtracting DEF in both directions; critical behavior follows the explicit setting. These are named own-game rules, not verified original-game multipliers.

New `atk_flat`/`def_flat` effects carry raw stat amounts, separate from percentages. For each leader/start/on-attack phase the engine floor-multiplies the previous value by that phase's percentage, then adds its summed flat amount once. Per-sphere authored flat effects multiply their amount by the collected sphere count once. The core's exclusive bonus remains final and separate. On-attack DEF is unavailable to attacks received before that character attacks. Unknown source phases/conditions still reject. Flat effects or Class fields cannot be smuggled into the legacy policy.

[SOURCE-ROSTER.md](SOURCE-ROSTER.md) describes the actual read-only source/owned-stat translator. One focused changed-feature case imported a source-backed authored custom unit through the real core, summoned seven actual owned instances using an explicit test-only pool, normalized their true stats/abilities and played a turn with correct flat/percentage and Class handling. A focused legacy serialization/retry boundary also matched the previous engine byte-for-byte. Unchanged full engine/session tests were not repeated. Source links and unsupported skills remain blocked; the native gameplay screen, verified animations and full progression integration are still pending.
