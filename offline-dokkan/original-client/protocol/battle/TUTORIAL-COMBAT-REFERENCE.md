# Preserved native tutorial combat reference

Tin's latest instruction removes the introduction/tutorial sequence for new
players. This reference preserves useful original-engine findings; tutorial
combat is not the production first-playable path. Existing player progress is
not changed by these findings.

The current master database's phase number 3 names
`internal:Tutorial::BattleSetupScene`. Its parameters already contain fixed
native combat inputs: `card_ids`, `map_id`, `bgm_id`, `dummy_card_id`,
`force_high_speed`, nested `enemies`, `ball_tables` and
`fixed_next_turn_orders`. The enemy shape includes original HP, ATK, DEF,
turn, card and AI fields. The first process is `WAIT_INITIALIZE_PUZZLE`.
Earlier phases contain movie/story setup. No game rows, IDs or stats are
published here or recreated as new balance rules.

The exact native RTTI is `Tutorial::BattleSetupScene`. Its 184-byte factory
passes the original input into an 88-byte initializer, which invokes an
1840-byte fixed-parameter consumer. Those calls and matching field reads are
source-proven. The unchanged router's URI-to-factory registration has not been
independently inspected, and this scene has not been run in this workspace.

That consumer initializes original `InGameData`, turn orders and Ki tables,
then invokes the original enemy setup with the first enemy group. Its player
card setup call supplies an explicitly empty JSON value, the fixed card-ID
vector and flag one. The 1252-byte helper attempts its existing lookup and
has an explicit fallback factory taking the supplied ID when lookup misses
and that flag is set. It fills seven native slots, including its existing
dummy path, and initializes ability state. The current master contains the
two supplied player-card IDs, one enemy-card ID and dummy-card ID; only those
membership results are recorded publicly.

These facts demonstrate original native combat support and preserve a future
integration reference. They do not prove a complete ordinary quest response,
independent operation without every native manager, a native adapter ABI,
working assets, launched gameplay or persistence. No intro is added or
resumed by this work, and no existing save was read or changed.
