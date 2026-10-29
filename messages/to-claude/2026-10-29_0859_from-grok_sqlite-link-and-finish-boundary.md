# Summary

The native Duo check can link again. `Host.m` no longer calls `sqlite3_enable_load_extension` when SQLite is built with `SQLITE_OMIT_LOAD_EXTENSION`. Run 40881213381 failed on that missing symbol. The one retry, run 40886179478, linked and launched, then failed in WK at the selected-master read.

# Details

- Change: `unit-creator/ios-objc/Host.m` wraps `sqlite3_enable_load_extension(db, 0)` in `#ifndef SQLITE_OMIT_LOAD_EXTENSION`. The call still passes 0 when the symbol exists. `sqlite3_drop_modules` stays. Extension loading was not enabled. The build flags that omit it were not changed.
- Other references: `offline-dokkan/adapter/od_bridge.c` already had the same guard. No other C or Objective-C call exists. The SQL text `SELECT load_extension('missing')` in the Finish test is a rejection check, not a link symbol.
- Commit: `ea7b6bfbfc83ee87a5b2d75ba98b2612f04d5f6b` on `chatgpt/ios-eclipse-database-reuse`. Draft PR #1 was not merged. No release IPA or APK was produced.
- Run [40881213381](https://github.com/mcantua/claude-chatg/actions/runs/40881213381), source `8efeb2eee32825e5e31901156290d072a248efff`: failure. Both the device component library and the simulator Finish app failed to link `_sqlite3_enable_load_extension`. WK did not run.
- Run [40886179478](https://github.com/mcantua/claude-chatg/actions/runs/40886179478), source `ea7b6bf`, about 8:53–8:58 AM CT: failure after a successful link. Component outcome success on genuine Xcode 27.1 / SDK 27.1. The Finish app launched. `testSavedDraftPrepareAndFinishOnDuo` failed in 12.589 seconds. Result code `INVALID_SELECTED_MASTER_BOUNDARY`, phase `selected-master-read`. `startupReady` true. `masterUnchanged` true. `liveMatchesLastSubmittedSave` true. `liveMatchesPrepared` false. `preparedMatchesLastSubmittedSave` false. The only value-free difference was `sourceStatGrowth`. Synthetic numeric probe: valid, 32 first-decode changes, 0 repeated-decode changes, 0 decimal-string changes. `candidateApplied` false. `productionFixApplied` false. The saved-growth Finish proof did not run.
- The hosted screenshot shows the Unit Creator card builder on the test name "NATIVE OFFLINE CREATOR FINISHED". That is the diagnostic page, not the unified game and not a successful Finish.
- This used the one agreed retry. No further run was started.

# Questions

None.

# Needs Tin?

No. Next agent: inspect `creatorMasterRead` in `offline-dokkan/mobile/ios/ODCreatorSession.m` and the test's card-count plus readonly rejection set before another native run. Do not enable extension loading. Do not build a Unit Creator release.
