# Owned-card base stats

`card.stats` is an internal read-only domain operation. The request selects only a same-profile `instance_id`; the core supplies its actual saved level, master ID and effective immutable created/exclusive/official-upgrade document. Clients cannot choose a level, curve or stats. No game HTTP response format is implied.

`card_stats.h/.c` opens no save and changes no state. The result exposes base `hp`, `atk`, `def`, level/cap, policy, source grow type/curve cap, and an exact rational coefficient. Every response explicitly identifies an **internal policy** and says original-game rounding is unverified. Missing source data fails rather than fabricating growth.

## Explicit policies

`master-coefficient-linear-floor-v1` uses each actual `card_growths(grow_type,lv,coef)` value and calculates:

```
initial + floor((maximum - initial) * coefficient)
```

This formula and floor rule are our documented design; the source proves its coefficients, not the original engine's rounding implementation. A trusted host may explicitly choose this default for existing documents and original master cards. Coefficients above one remain valid (the supplied type41 reaches1.8), as do nonzero starting coefficients. The evaluator never clamps these source facts to an assumed0..1 interval. A level absent from the source curve fails `STATS_CURVE_UNAVAILABLE`.

`creator-cap-normalized-v1` is our explicitly authorized created-tier growth policy. It must be pinned in immutable `definition.stat_policy`; passing a host default cannot silently enable it. This preserves the authored initial values at level1 and authored maximum values at the configured cap, including180/200:

1. Load the complete, contiguous selected real source grow-type curve from level1 through its last stored level.
2. Map `(owned_level - 1) / (configured_cap - 1)` onto that source interval.
3. Linearly interpolate its adjacent source coefficients using an exact integer rational.
4. Subtract its starting coefficient and divide by its final-minus-starting coefficient.
5. Use the normalized coefficient in the floor calculation above.

This rescales an existing source shape; it is not an alleged official180/200 table. Both source and target need at least two levels and the source endpoint must exceed its starting coefficient. All source coefficients must be nonnegative, monotonic exact thousandths, matching every value in the supplied1,310-row table; richer or malformed future curves fail explicitly. Integer multiplication/division checks JSON-safe overflow without forming a potentially overflowing full product. Definition updates cannot change/drop a previously pinned stat policy. Legacy definitions can pin one on a subsequent immutable version; existing versions are retained.

## Super/Godly Exclusive

Base stats exclude Hidden Potential, equipment, leader/passive effects and Super/Godly Exclusive. For created SLR/GR definitions, `final_exclusive` separately describes always-on ATK/DEF10%/20% and damage reduction10%/20%, applied once after other boosts. These do not increase the returned base numbers. The real battle evaluator must handle that final stage once and avoid processing the Creator's already encoded exclusive passive rows a second time. This helper does not claim to evaluate arbitrary passive/leader/condition effects.

## Creator native SQL export

The old `unit-creator/v2/ui/core.js` `extendLevels()` generated only `card_exps` above150. Combat Workshop still selects configured maximums rather than simulating owned levels. Creator now hydrates an actual selected source curve through `loadTemplate()` or the existing pre-export `hydrateNativeRecords()` path, including legacy projects and Sparking's own read-only query.

High-cap created exports pin `project.statPolicy=creator-cap-normalized-v1` and keep source curve metadata under `sourceStatGrowth` (policy, original source grow type, level/coefficient rows). Materialized SQL generates a separate private `card_growths` type in that unit's already reserved1,000-row block. The editable source card and all original growth rows stay unchanged. Both exported root/awakened card copies use the same generated curve; EXP925 remains the existing separate experience policy. Once pinned, lowering the cap retains the explicit normalized policy rather than silently reverting it. Ordinary unpinned source-supported units and official EZA source grow types keep their prior behavior.

Private growth rows use the actual source schema and primary key, retain normalized endpoints0/1 and fit within the unit's private block. Before reimport, SQL clears only that same unit's matching private growth rows, so lowering a prior cap leaves no stale rows. Different transformation forms use their own growth types; identical shared EXP925 rows are deduplicated. Missing metadata, unsupported schema/manual growth rows or unsafe private slots produce a normal validation error; legacy projects hydrate before export. Native original-game coefficient rounding and actual device gameplay still require separate evidence.

The focused real-master scenario applies180/200 SQL to one temporary copy, reimports the same SQL, compares every original growth row, checks root/card IDs and EXP, verifies legacy hydration/validation, safe namespaces and distinct180+200 form curves, and reduces a200-level curve to180 without stale rows. Source game files and generated SQL stay temporary/ignored.

The separate focused synthetic offline-core scenario checks beginning/middle/maximum, curved180/200 interpolation, preserved configured bounds, isolated exclusive descriptors, missing/unpinned policies, unsupported coefficient precision and large-product overflow. Unrelated gameplay checks were not repeated.
