# Source-backed battle roster translation

`source-roster.js` exposes `OfflineDokkanSourceRoster` in WebView/browser or exports through `require`. It contains no game rows, sample roster, invented stats or network requests. It translates selected-source data and the actual local core's owned-character stats into the exact `battle.js` fighter descriptor. It does not yet connect the native gameplay screen or make unsupported characters playable.

```js
const result = await OfflineDokkanSourceRoster.normalizeOwnedCard({
  contentId,
  source: {contentId, provider, query: async (sql, parameters) => rows},
  owned,                    // Actual card entry from profile.snapshot.
  stats,                    // Actual card.stats for that owned instance.
  definition,               // Effective immutable custom/upgrade document, when applicable.
  leaders: [leaderBinding, supporterBinding], // Two distinct actual owned instances.
  policy: OfflineDokkanSourceRoster.policyId,
  battlePolicy,              // Explicit source-v2 phase/Class policy described below.
  animations                // Optional verified {relationID: {path, sha256}} references.
});
```

Each leader binding contains its actual `owned` entry and effective `definition` when applicable. Source identity is checked before and after every awaited query. The trusted host supplies a read-only query closure already pinned to that exact master; a matching string alone is not a cryptographic proof that an arbitrary callback reads the correct database. Queries here are generated `SELECT`s over fixed allowed tables, bound integer IDs and bounded rows. No SQL comes from a player action. The host must choose and verify the actual team/supporter; this module cannot authenticate client-supplied owned/stats objects.

A returned `fighter` exists **only** when every checked requirement is supported. Otherwise `supported` is false, `fighter` is null, and `unsupported` lists exact source fields, reason codes and relevant values. `resolved` retains usable facts such as the bound stats, Ki anchors/curve, source Super Attack rows and translated effects. Do not hand partial `resolved` data to the battle engine or strip its unsupported list. `provenance` preserves content/provider/master/owned-instance/definition identity, selected policy, levels and effect-accounting ledger.

The selected immutable definition's named tables are its complete effective graph. An omitted table falls back to the master; a present table does not silently restore deleted master effects. Root source identity must always exist. Core stats must match the owned master/level, effective cap/growth/stat policy and `base_excludes_bonuses`. Existing custom/official-upgrade ownership without its effective document rejects. Nonempty potential/equipment state rejects until its combat effects are translated.

## Explicit own-game policy

The default is strict: missing `policy` returns `KI_CURVE_POLICY_REQUIRED` and `SUPER_MULTIPLIER_POLICY_REQUIRED` rather than guessing values. The trusted own-game host may explicitly choose `source-anchors-and-sa-linear-floor-v1`; no player-facing technical question is required.

That named **internal rule** interprets the actual card's Ki fields as anchors: minimum at0Ki,100% at `eball_mod_num100`, optional middle anchor, and maximum at `eball_mod_max_num` (12 or24). Integer PPM values interpolate between adjacent anchors using BigInt floor division. Conflicting, missing, decreasing or unsupported anchors reject. Raw fields/anchors are retained.

For an eligible ordinary/Ultra Super Attack, that same internal rule uses `100 + increase_rate + lv_bonus × (owned.sa_level − 1)` percent. Its actual source threshold comes from `card_specials.eball_num_start`. The effective relation is selected by its actual Super Attack level gate. Conditional/EX/unsupported styles, ambiguous thresholds, active level bonuses, unknown special effects and unknown targeting reject. Source rows remain attached in `resolved.superAttacks`.

These are deliberately named own-game rules, **not verified original-game interpolation/rounding or full Dokkan damage parity**. `originalGameRoundingVerified` stays false. No endpoint, “default LR multiplier,” missing curve or flat stat is substituted.

## Supported and blocked semantics

Recognized unconditional,100%-activation, one-turn/self passive rows translate actual Creator codes: ATK/DEF percentages (1/2/3), flat ATK/DEF (1/2/3 with calculation0 under the explicit source-v2 policy), Ki (5), per-sphere percentages (59/60/61), damage reduction (13:100 minus the source value), critical/dodge percentages (90/91), and one guaranteed additional normal attack (81 with no Super Attack conversion). Only supported start/on-attack/per-sphere phases are accepted. Targets, subtargets, conditions, scripts, duration, chance, calculation option and extra values are checked; unknown fields in these semantic positions reject.

Simple whole-team/type-mask Ki and unconditional zero-HP ATK/DEF leader rows are recognized. Unimplemented leader effects, HP phases, class/category scope and conditions reject. Exact no-op leader rows are explicitly counted. Links require actual link-level and rotation translation and currently reject. Current Class comes from the actual encoded `element`:0–4 neutral,10–14 Super,20–24 Extreme. `awakening_element_type` describes awakening alignment and is retained as source metadata; it does not turn a currently neutral Type into Super/Extreme. Encoded Class requires the explicit source-v2 battle policy. Unknown encodings reject. Active/standby/finish skills, scheduled passive additions, origin-battle overrides and all other unknown skill phases reject instead of disappearing.

The three exact Creator-encoded Super/Godly Exclusive rows are excluded from ordinary phases only when their source code/target/timing/values match the core's separate10%/20% descriptor and effective rarity. The descriptor requires `included_in_base=false` and `apply_once_after_other_boosts=true`. Mismatches reject; a matching title alone is insufficient. The battle engine then applies the final bonus once.

An animation reference is only a descriptor. The native host still verifies its actual resource through the content resolver before starting a battle that requires animations. Full battle-script rendering remains separate work.

## Flat-stat and Class policy

For new source-backed fighters the trusted host supplies the complete `battlePolicy` with `id: "offline-turn-battle-source-v2"`, `statPhasePolicy: "percent-then-flat-by-phase-v1"`, and `classPolicy: {id: "static-class-v1", samePpm, opposingPpm, neutralPpm, critical}`. All three multipliers are explicit positive integer PPM values; `critical` is explicitly `"apply"` or `"bypass"`. The usual minimum/Type/critical/animation policy fields are also required. No multiplier is inferred from a source website or presented as verified official behavior.

The engine sums flat amounts separately from percentages in each phase. It first floor-multiplies by that phase's percentage, then adds the phase's flat amount once. Leader/start/on-attack phases remain separate; on-attack DEF does not apply before attacking. The separate exclusive descriptor still applies once at the end. Source flat ATK/DEF1/2/3 with calculation0 translates to precise `atk_flat`/`def_flat` capabilities only under this named policy; unsupported flat per-sphere codes or receiving-attack phases still reject.

Supported source-v2 fighters include exact `classType` plus the `static_class` capability. Damage applies the configured static Class multiplier after Type and before subtracting DEF, for incoming and outgoing attacks. Critical Class handling follows the explicit configured choice. These are own-game rules, not an original-engine parity claim. New semantics are rejected under legacy battle policy; old version1 serialized state and replay stay unchanged.

## Focused verification

The earlier real-source case correctly blocked the unmodified character's unsupported flat ATK/Class/leader/links. The new targeted case used that actual fully-awakened supplied-master template to create a legitimate authored custom unit: real flat ATK1800 retained, explicit Ki leader, authored percentage/flat phase effects, and intentionally no links. The translator did not remove links from an unmodified character.

The actual core imported that definition, configured an explicitly authored **test-only** summon pool, and summoned seven distinct owned custom instances. Every fighter used actual `card.stats` and source rows. All seven normalized successfully with the new own policy. A played turn verified flat amounts versus percentages, pre/post-attack DEF, and explicit Super/Extreme Class damage. Missing policy/Class rejected. New state restore/retry passed; a focused previous-engine/current-engine boundary check produced byte-identical legacy serialization/retry. The old whole engine/session suites were not rerun. The supplied master SHA256 stayed unchanged.

The first attempt stopped at strict core fixture validation; the authored row timestamps/non-null link fields were corrected, then the one combined feature scenario passed. No production banner rates were changed. No native battle launch, full links/leader coverage, attack animation playback, original-engine formulas or real-game rewards were claimed.
