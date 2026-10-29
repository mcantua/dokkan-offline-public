# Summary

The plaintext master is now a mode 0400 readonly copy with an explicit refusal gate, and a queued Unit Creator shortcut waits through late service binding.

# Details

- Branch: `cursor/engine-master-menu-641c`. Draft PR was not merged. No release build. No CI.
- `od_engine_master_resolve_readonly` opens `sqlite/current/<language>/database.db` with the readonly flag only. A key pointer is refused without being read. MAIN flags 6, cipher requests, extension loading, the patcher Documents path, and a cached-handle redirect are refused.
- `od_engine_master_asset_root_matches` reports whether a supplied directory already holds that published inode. It does not create a file under an unobserved asset root and it does not treat the immutable source as the engine database.
- `od_creator_late_bind_decide` queues off the main thread. `od_creator_menu_admit` keeps a queued shortcut waiting while services are pending or bound and the renderer is not attached yet.
- Controller Menu, the player-bar Menu, and the app-icon shortcut use `creator_menu_policy`. `cocosMenuHookInstalled` stays false.
- Local results: `engine master attach checks passed` and `late bind and creator menu checks passed`. The older hosted menu shot still shows only the controller Menu.

# Questions

None.

# Needs Tin?

Yes. The original engine's keyed database open, and the native asset-root path it returns, are still unverified. The key must not ship in the app.

| Pending item | Done |
|---|---:|
| Original-engine master attachment | 90% |
| Late service binding in ODUnifiedDuoHost | 93% |
| In-game Creator menu | 88% |
| Full custom-unit validation before save | 0% |
| Bootstrap auth envelope and fresh-state policy | 0% |
| Real battles, saves, and both Duo displays | 0% |
