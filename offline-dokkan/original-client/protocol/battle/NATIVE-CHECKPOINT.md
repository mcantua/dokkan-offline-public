# Original battle checkpoint structure

The actual `InGameData` constructor initializes an embedded object whose exact
RTTI is `InGameSugorokuData`. The original battle-start callback passes that
same embedded object to the reviewed 92-byte setter. That setter copies the
entire incoming `sugoroku` JSON value into its internal map storage.

Two methods from this object's actual vtable serialize and restore its native
checkpoint. They are not the fresh start-response parser.

| Checkpoint member | Observed handling |
|---|---|
| `map` | Copies the object's complete internal map JSON |
| `player_position` | Signed 32-bit position |
| `map_scale` | Numeric value; restore clamps the resulting float to 1–3 |
| `bgm_no` | Signed 32-bit value |
| `steps`, `actual_steps` | Iterate values into native integer vectors |
| `dices` | Restore reads exactly three indexed integer entries |
| `passing` | Restore reads boolean entries when present; otherwise rebuilds from `actual_steps` |

The serializer receives the original object in X0 and caller-owned JSON result
storage in X8. The restore method receives the original object in X0 and the
checkpoint JSON address in X1. These register observations do not establish a
new exported adapter API or an allowed invocation point.

This identifies the original game's checkpoint representation and connects it
to real battle state. No native checkpoint invocation, persistence, resumed
battle or compatibility with the local backend has been verified. No save
directory or existing save file was read or changed.

The fresh start callback separately iterates `sugoroku.events`, then each
event's `content.enemies` nested groups, reading `card_id` and `ai_type`. Those
observations do not establish the rest of the map layout or permit inventing a
playable start response. Exact source identities and limits are retained in
`native-checkpoint-evidence.json` and `response-consumer-evidence.json`.
