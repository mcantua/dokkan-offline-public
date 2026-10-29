The integrated entry now calls `ODCreateUnifiedDuoStartupHost` in
`ODUnifiedDuoNativeFactory.m`. It uses only the actual `org.offlinedokkan.duo`
bundle and the typed shared native startup preparation. The diagnostic identity
and entry remain separate.

The factory verifies the exact bundled plaintext Core reference, retains its
readonly file identity, and creates one canonical Core and one deferred player
capability. Preparation runs on native IO through that same Core's owner queue;
the real profile/content/save scope returns on main after the ordinary main loop
starts. The factory then creates same-Core scoped Creator services and the
hash-pinned resource projector on IO and binds them to the actual Host on main.
No source account, starting collection, guessed save scope or second Core is used.

The Host initially installs deny-all Foundation transport before loading the
admitted original engine. Its source-bound native configuration can arm the
reviewed routes once before actual AppDelegate requests. Local ping/nonce/sign-in
handlers remain Host-owned and obtain current same-Core snapshots. The local
one-hour token lifetime is explicit offline policy, not a recovered server value.

Original engine/auth/UI initialization is allowed before observing native master
acceptance. The minimal persisted new-profile User DTO is independent of the
original engine's encrypted master. Full game data, teams/cards and Creator
mutations keep a separate native-master gate. The plaintext Core reference is
never staged as the original preferred MAIN database, and no language, native key
or schema-acceptance result is invented.

Required integrated bundle additions are pinned in
`integrated-native-factory-source.json`. Existing original shell, engine, opaque
seed, dependency and compatible resource inputs use the same shared preparation
as diagnostic. The package must select `OD_UNIFIED_DUO_STARTUP_ENTRY=1` and leave
the diagnostic constructor disabled.

This is concrete composition source, not a playable acceptance report. Shared
original preparation currently admits only fresh native User/current state and
preserves/rejects existing native state. Resume, real login/Home, actual battles,
persistent gameplay and both Duo displays still need actual original-client
evidence. No preferred opaque master working copy is selected by this factory.
