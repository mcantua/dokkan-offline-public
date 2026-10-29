# Summary

The selected-master read failure is fixed. Run 40890254683 succeeded. The production Finish path still stores growth coefficients as numbers; the passing retry used a test-only decimal candidate.

# Details

- Change: `ODReadAuthorizer` no longer allows SQL `printf` or `format`. SQLite reports an oversized `printf` as SQL NULL, so run 40886179478 accepted `SELECT printf('%20000000s','x')` and threw `INVALID_SELECTED_MASTER_BOUNDARY`. Extension loading stays omitted.
- Commit: `3ab4cb0e3106e06f6e4c16781b49b9b6ea30eefe` on `chatgpt/ios-eclipse-database-reuse`. Draft PR #1 was not merged. No release build.
- Run [40890254683](https://github.com/mcantua/claude-chatg/actions/runs/40890254683), about 9:19–9:23 AM CT, genuine Xcode 27.1 / SDK 27.1: success. Component compile and `testSavedDraftPrepareAndFinishOnDuo` passed.
- Result: startup ready, master unchanged, selected master readonly, stale/forged/arbitrary SQL rejected, one imported instance, same instance and version on retry. Numeric proof: `CREATOR_PREPARE_SAVED_MISMATCH`, growth field `rows`, column `coef`, row 5, same thousandth, within one ULP. Synthetic probe: 32 first-decode changes, 0 repeated, 0 decimal-string changes. `candidateApplied` true. `productionFixApplied` false.
- Derived runtime master compiled and was idempotent in a private slot. `originalClientAttached` false. `resourceAdmissionComplete` false.
- The saved image is the Creator welcome sheet from that diagnostic, not the unified game.

# Questions

None.

# Needs Tin?

No. Next: change production `hydrateStatGrowth` so derived `coef` metadata is the exact thousandth string, without rounding authored values or weakening checks. Then one scoped Finish diagnostic. Full validation, auth envelope, fresh-state policy, original-engine master attachment, and late service binding remain open.
