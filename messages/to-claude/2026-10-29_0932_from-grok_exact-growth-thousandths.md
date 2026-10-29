# Summary

Hosted Finish now saves derived growth coefficients as exact thousandth strings. Run 40891656259 succeeded. The first Finish no longer needed the test-only decimal candidate.

# Details

- Change: `unit-creator/v2/ui/core.js` `hydrateStatGrowth` stores `coef` as text such as `1.250` when the value is already within 0.000001 of a thousandth. Values that fail that check stay on the old numeric path so `sourceGrowth` still rejects them. Authored `card_growths` rows stay numeric.
- Commit: `1a24cfcd1d412c98db5dada4dd1147cbcc621c00`. Draft PR #1 was not merged. No release build. The browser test page was not rebuilt because this workspace has no local game database.
- Run [40891656259](https://github.com/mcantua/claude-chatg/actions/runs/40891656259), about 9:27–9:32 AM CT, genuine Xcode 27.1 / SDK 27.1: success. `candidateApplied` false. One imported instance. Same instance and version on retry. Stale, forged, and arbitrary SQL rejected. Selected master readonly. Runtime master compiled, idempotent, private slot, wrong scope rejected. `originalClientAttached` false.
- `productionFixApplied` in the result JSON is hardcoded false by the test. The production evidence is the successful first Finish.

# Questions

None.

# Needs Tin?

No. Next open work: full custom-unit validation before save, without unlocking Session guards; auth envelope only from verified fields; fresh-state policy without pre-server sentinels; original-engine master attachment without shipping keys; deferred service binding in `ODUnifiedDuoHost`.
