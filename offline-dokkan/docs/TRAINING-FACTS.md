# General training: verified facts and unresolved rules

`core/training.h/.c` supplies a read-only training catalog, checked base-item EXP/Zeni subtotals and conditional level projection. It does **not** consume items, grant EXP, charge Zeni, roll success or replace the existing guaranteed-Kai transaction. This module runs no save/schema operation and accepts no client claim about earned EXP or costs.

## Source-backed facts

The supplied Eclipse master contains75 training items. Each has a source element0–4, positive integer `exp` and nonnegative integer `zeni_to_use`; current base EXP ranges from1,000 to1,000,000 and item Zeni values from100 to25,000. Descriptions explicitly say “EXP or more”. The module calculates exactly these numeric **base-item subtotals** with overflow-checked integer multiplication/addition, retaining per-line quantity, available inventory and shortfall. Item costs are never multiplied by reward/drop policies.

A target card's actual/effective element is mapped through the existing AGL/TEQ/INT/STR/PHY encoding to report whether an item matches its base type. This boolean is a source identity fact, not an invented matching-type EXP factor.

Training locations expose actual descriptions and raw `zeni`, `exp`, `elements`, `multiplier`, `addend`, and referenced success records. Current location text describes addends **per Training Partner or Training Item kind**; multiplying that addend by every item quantity would be unjustified. The module does not interpret the location's `zeni` as an established full session charge. Success references expose their actual source key, effect and probability; it does not infer how guaranteed fields, baseline random success, type bonuses and rounding combine. No location or success modifier is silently applied to the base subtotals.

The retained Creator code only renders training scenes and items. Historical protocol evidence contains field names/types, not a verified training evaluator or current-client formula. The card master also contains `training_exp` and SA material/rate tables, but does not establish all target/material identity, level and cost semantics needed for general owned-card consumption.

## APIs

```c
od_training_catalog(master, &json, &error);
od_training_preview(master, actual_owned_master_id, effective_definition,
    actual_owned_level, known_experience_or_null,
    requested_items, request_count, actual_inventory, inventory_count,
    known_zeni_or_null, selected_field_id, &json, &error);
od_training_project_exp(verified_thresholds, count, actual_owned_level,
    known_experience_or_null, base_gain, &json, &error);
```

The trusted core must resolve the same-profile owned identity, immutable effective settings, actual current level/EXP, item inventory and Zeni. A future client operation may select an owned target/material IDs, but may not choose these resolved facts or provide claimed reward amounts. `field_id=0` means no selected location; no free/default field is invented.

Catalog IDs and references are validated against actual master data. Requests require distinct actual training item IDs and positive integer quantities. Unknown items, duplicate inventory entries, negative balances, invalid JSON numeric types, unsupported target types/levels and overflowing subtotals fail. Budgets are512 source items/fields,128 requested item kinds,4,096 inventory entries and10,000 curve rows; these are implementation bounds, not claimed game session limits.

JSON results use `sqlite3_malloc` and the existing core free boundary. The module depends only on SQLite and standard C. No additional signing/game/network dependency is required.

## Conditional base-EXP projection

For an available complete source `card_exps` curve, thresholds must start at zero, increase strictly, and cover every level through the target's effective cap. Projection uses the exact thresholds with integer arithmetic and binary search. It is explicitly **base items only**, separate from an unresolved final training result.

Known saved EXP must fit the saved owned level's actual threshold interval; inconsistency fails. If partial EXP is unknown, it remains unknown: the preview projects a lower/upper range from that level's minimum and maximum possible saved EXP. It never silently chooses zero partial progress.

If the projected base gain exceeds the last threshold, the result reports the bound as exceeding the cap and leaves its resulting level null. No cap-clamping, discarding of earned EXP or wasteful material-consumption policy is invented. Missing curves—including a private Creator extension absent from the source master—return an unavailable projection while retaining verified item subtotals. A trusted core that already resolved the explicit immutable Creator extension can reuse `od_training_project_exp` with that validated curve; this module does not independently extrapolate one.

Every preview returns `final_exp:null`, `final_zeni_cost:null`, and `can_commit:false`, even when the base-item subtotal is affordable. It explicitly identifies unresolved target eligibility, matching-type bonus, field/success combination, complete Zeni formula and cap-overflow handling.

## Required before real general training consumption

The source and retained legitimate code do not establish all target eligibility gates; matching-type bonus; material-card EXP/identity rules; combination/rounding/order of field addends and success; total target-level/item/partner/location Zeni cost; or over-cap discard/charge behavior. The current core also needs an actual Zeni balance/earning contract before charging it. None is filled with a guessed official formula.

A future verified transaction must pin those rules, resolve real inventory/owned state, protect locked or in-use materials, atomically debit exact items and Zeni, grant only the resolved EXP, and persist a stable-source command receipt with import/replay validation. The existing separate guaranteed-Kai feeding transaction stays the implemented consumption boundary until then.

## Focused verification

`check_training.py` uses the supplied master read-only. One combined scenario compares catalog counts/field metadata; exact item EXP and Zeni subtotals; matching/mismatching type facts without invented bonuses; known and unknown-partial EXP projections; over-cap reporting; one-item inventory shortfall; missing high-cap curves; invalid boolean overrides; overflow and duplicate rejection; and zero database changes. It passed under strict C11 warnings. No unrelated tests, web build or native package build were run for this task.

```sh
mkdir -p offline-dokkan/core/build
cc -std=c11 -Wall -Wextra -Werror -fPIC -shared \
  -I downloads/sqlite-header offline-dokkan/core/training.c \
  -Wl,-l:libsqlite3.so.0 -o offline-dokkan/core/build/libtraining-check.so
python3 offline-dokkan/core/check_training.py
```

Only code, documentation and this source-dependent scenario are committed. The source master and generated verification library remain ignored.
