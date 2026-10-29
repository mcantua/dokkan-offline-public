# Summary

The plaintext derived master is staged on the reviewed MAIN path, Creator services can bind after UIApplicationMain, and the Unit Creator shortcut opens the in-game Menu control.

# Details

- Branch: `cursor/engine-master-menu-641c`. Draft PR #1 was not merged. No release build.
- `engine_master_attach` copies a plaintext derived master to `sqlite/current/<language>/database.db` in the host writable state directory. The source file stays read-only. The patcher Documents path, cipher key, cipher pragmas, extension loading, and the cached handle are not used. One local check passed: the copy is a different file, a second stage is idempotent, and a wrong hash is rejected.
- `ODUnifiedDuoHost` can install while Creator services are still pending. `bindCreatorServicesWhenReady:` runs on main, does not spin, installs the scene lifecycle once, attaches an already admitted renderer, and refreshes a queued shortcut. The services must match the content id and save scope recorded before install.
- The Unit Creator shortcut presents `ODCreatorController`. Original-client mode labels the return control Menu. The scoped player bar uses that same return. No Cocos menu hook was added.
- The hosted component compile and one Duo simulator menu shot are the diagnostic for this branch.

# Questions

None.

# Needs Tin?

Yes, for one item that blocks calling the master attached inside the running engine. The static contract shows MAIN opens `sqlite/current/<language>/database.db` and then applies an internally generated key. The key was not read, and it must not ship in the app. The plaintext copy is ready. The engine's own keyed open is not verified.

| Pending item | Done |
|---|---:|
| Original-engine master attachment | 70% |
| Late service binding in ODUnifiedDuoHost | 80% |
| In-game Creator menu | 60% |
| Full custom-unit validation before save | 0% |
| Bootstrap auth envelope and fresh-state policy | 0% |
| Real battles, saves, and both Duo displays | 0% |
