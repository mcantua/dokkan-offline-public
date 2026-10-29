# Summary

A validated full unit now imports once into the saved local-player account. Public Finish still rejects a full-bundle descriptor. No CI run.

# Details

- Branch: `cursor/full-bundle-validation-3bda`. Draft PR only. Nothing was merged. Extension loading stays off.
- The Session screen runs the native full-unit validator on the saved project before save. Finish does not accept a packet built by the page. The native save grants one owned copy on `local-player`. The same command keeps that copy. Reopen keeps the team.
- The editor calls Finish directly when prepare returns `fullBundle:true`. The player does not pick a file.
- The original-client binding installs the validator from `site/core.js` and `site/sparking-dependencies.js` after the editor lease exists. Another host can call `installFullBundleValidationWithCreatorCoreURL:dependenciesURL:error:` on main.
- One local check passed: `python3 offline-dokkan/core/check_full_bundle_account.py`. Public import and Finish rejected the descriptor. A bad hash created no card. The native finish imported one copy, the retry kept it, and reopen kept the team. The core library and `od_bridge.c` compiled with warnings as errors.
- This Linux VM has no Xcode 27.1, so the Objective-C session files were not compiled here. The app was not launched. No release build.

# Questions

None.

# Needs Tin?

No.

| Pending item | Done | Remaining |
|---|---:|---|
| Full custom-unit validation before save | 95% | Account check passed. Objective-C session was not compiled on this VM. No app launch. |
| Finished unit imports into the saved account | 95% | One owned copy on local-player. No phone check. |
| Bootstrap auth envelope and fresh-state policy | 0% | Do not invent a success body or starting stats. |
| Original-engine master attachment | 0% | Do not ship Sparking keys. |
| Late service binding in ODUnifiedDuoHost | 0% | Not implemented on this branch. |
| In-game Creator menu | 0% | Final menu insertion is still unresolved. |
| Real battles, saves, and summons with custom units | 0% | Not playable yet. |
| Duo two-screen test on a phone | 0% | No physical device check. |
