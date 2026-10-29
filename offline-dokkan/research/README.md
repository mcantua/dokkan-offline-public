# Protocol evidence: observed strings and historical wire candidates

Collected in the cloud on Oct 28, 2026. No game server, account, Mac, PC or physical device was contacted.

## What is established

`route-evidence.json` inventories all 35 paths reported in Claude's IPA findings. Every reported fragment is corroborated in at least one of the existing iOS/Android patcher string lists. It records file-relative line numbers only, never arbitrary string contents. All current request/method/response verification flags remain false.

The available iOS strings establish these static hook names:

| Source | Selected labels and line numbers |
|---|---|
| `mac-workspace/research/eclipse-ios-patcher-strings.txt` | `HttpAsynConnection` 2363; `EclipseOfflineMode` 2389; `OfflineCache` 2796; `startRequest:` 2907; `responseData` 2908; `connectionDidFinishLoading:` 2909; `_buildOfflineLoginResponse` 3085; `EclipseOfflineProtocol` 3479 |
| `mac-workspace/research/sparking-ios-patcher-strings.txt` | `HttpAsynConnection` 416; `responseCode` 3878; `startRequest:` 3880; `responseData` 3881; `connectionDidFinishLoading:` 3882; `LocalResponseHandler` 5212; source-file label `LocalResponseHandler.x.m` 8828 |

These support an in-process adapter design. They do not supply method signatures, calling conventions, body formats, completion ordering or working hooks for the current game binary. No code/key bytes were copied into the evidence.

## Public historical evidence — useful candidates, not current-client verification

Two public sources were inspected through read-only GitHub tools, pinned to the revisions below. No source implementation or raw player/game response records were copied into our project.

- [teslabyte/Webplay2, WebAPI.java at a9ac155](https://github.com/teslabyte/Webplay2/blob/a9ac155def37049d36c316b02fe110e0aaa03773/src/webplay/Network/WebAPI.java)
- [BunRum/SillyDokkanNodejs, start.js at a650dd4](https://github.com/BunRum/SillyDokkanNodejs/blob/a650dd4809805d595c7d031eb07cb9a47409196d/start.js)

The second is a third-party reference server that serves static JSON and mock behavior. Its existence does **not** establish a complete or correct offline implementation. Its game version and compatibility with today's Eclipse/Sparking are unverified. It must not be used to fake working endpoints.

Important correction to route assumptions: several paths in the IPA findings are **suffix fragments**, not complete request URLs. Historical evidence provides these candidates:

| Reported fragment | Historical candidate | Evidence and limits |
|---|---|---|
| `/auth/sign_in` | `POST /auth/sign_in` | Both public sources; no current nonce/envelope/login confirmation |
| `/sugoroku_maps/start` | `POST /quests/{quest_id}/sugoroku_maps/start` | Both public sources; do not implement only a suffix dispatch and assume compatibility |
| `/sugoroku_maps/finish` | `POST /quests/{quest_id}/sugoroku_maps/finish` | Both public sources; continuation/retry routes also exist historically |
| `/briefing` | `GET /quests/{quest_id}/briefing` | Reference server; current payload unknown |
| `/potentials` | `GET /user_cards/{owned_card_id}/potentials` | Reference server; this is an owned-instance reference, not a master card ID |
| `/potentials/release` | `POST /user_cards/{owned_card_id}/potentials/release` | Reference handler reads `potential_squares` from the decoded body |
| `/unrelease` | `POST /user_cards/{owned_card_id}/potentials/{node_id}/unrelease` | Reference server; operation semantics/costs still require actual evidence |
| `/equip` | `POST /cards/{card_id}/equip` | Reference server; exact card-ID kind and body are unverified |
| `/teams` | `GET /teams`, `POST /teams` | Historical client reads with GET; reference server has POST and reads `user_card_teams` and `selected_team_num`. These may represent different operations, not interchangeable verbs |
| `/assets/database` | `GET /client_assets/database` | Reference server; reported path is a suffix, response format remains version-specific |
| `/item_reverse_resolutions` | `GET /item_reverse_resolutions/achievements` | Reference server; do not map the whole family to one fabricated response |
| `/iap_rails` | `GET /iap_rails/googleplay_products` | Historical Android candidate, **not** evidence of the current iOS purchase contract |
| `/resources/login`, `/resources/home` | `GET /resources/{type}` with `login`/`home` | Reference server selects static snapshots; current envelope and required fields unknown |
| `/ondemand_assets`, `/missions/put_forward` | POST at the reported paths | Reference server; request fields and effects not established by these stubs |

Historical catalog/progression reads also include GET `/cards`, `/user_areas`, `/missions`, `/events`, `/dragonball_sets`, `/db_stories`, `/announcements`, `/cooperation_campaigns`, `/joint_campaigns`, `/sd/battle`, `/sd/packs` and `/client_assets`. No relevant current-client wire contract is confirmed by these older sources. A public search for `DokkanSparkingPatcher` / `LocalResponseHandler Dokkan` found no inspectable current patcher source.

`historical-response-shapes.json` records **only field names and types**, with scalar values removed, from five public historical fixtures. Per-file source permalinks are in the JSON. It is evidence for investigating nesting and client-required fields, never a response template to ship. It shows, for example:

- Login has card/team/inventory/progression/campaign sections, not just a user object.
- A map-start response includes `token`, `dummy_card_id`, `sugoroku`, `user` and `missions` in the historical snapshot.
- A map-finish response has separate XP/Zeni/reward/user-state sections and replay-sensitive results.
- Events groups `events`, `z_battle_stages`, `eventkagi_events` and `eventkagi_z_battle_stages`.

Scalar examples, original IDs, player names, tokens and asset bodies are intentionally absent. Empty lists do not establish an item schema; optional/omitted fields and integer-enum meanings remain unknown.

## Safe collection tools, specific Mac approval now received

`tools/collect-ipa-metadata.command` is **not executed on the Mac**. Tin has now approved this read-only metadata step. Prefer `mac-workspace/run/approved-ipa-metadata.command`, which invokes the same collector for both original IPAs without another permission dialog. No Mac execution has occurred here. It asks him to select one IPA and writes only a small latest metadata file to `~/AI-Workspace/Offline Dokkan Battle/evidence/ipa-metadata.json`.

Exact operation: read the original ZIP without extracting or modifying it; hash its main executable; read app version/bundle metadata; hash either recognized patcher and record allowlisted static hook names. `macho_metadata.py` additionally reads bounded thin/universal Mach-O headers, recorded SDK/minimum OS, encryption status, chained-fixup presence and allowlisted library basenames. Unknown library names/paths are omitted. It does not launch the game, inspect accounts, dump strings, extract keys, decrypt binaries or connect to the internet. It deliberately **does not collect request/response payloads or assert wire compatibility**. It needs Python 3 already installed and performs no software installation. Keep the helper module beside the collector when copying it. A game-version hash can then pin the correct adapter investigation.

If Tin later obtains a decoded request/response fixture through an approved capture, `collect_protocol_evidence.py schema INPUT --out OUTPUT` creates a structure-only result locally. Input format is our collector format:

```json
{"method":"POST","path":"/quests/955003/sugoroku_maps/start","response_status":200,"request":{},"response":{}}
```

Those empty objects illustrate the input format only; they are not claimed game payloads. Raw inputs must remain under ignored `offline-dokkan/private/`. The sanitizer removes **all scalar payload values**, retains only allowlisted static route paths/templates, replaces every dynamic path segment (numeric IDs, UUIDs and names alike), strips query/host information and records object/array types. Unknown routes become `/[unrecognized-route]`. Object field names must be in an explicit reviewed protocol allowlist; arbitrary alphabetic/opaque/username keys become `[redacted-key]`, with collisions and type variants recorded. Array/object/depth truncation is explicit. It refuses to overwrite its input. It does not capture traffic or obtain credentials.

New genuine protocol field names must be reviewed locally before extending that allowlist; redacted unknown keys must not be treated as proof that a field is absent. A targeted privacy regression passed for opaque path IDs, arbitrary alphabetic/hex map keys, scalar values, unknown routes and redaction collisions/type unions.

## Verification performed

One combined synthetic Linux check passed: IPA hashes/allowlisted hooks, no canary bytes in output, value-free fixture shapes, numeric-path normalization, refusal to overwrite input, and coverage of all 35 route fragments. `bash -n` passed for the Mac wrapper. No real Mac/device execution was attempted. These checks verify the collector, **not the game protocol**.

## What still blocks a genuine adapter

For each supported executable/profile, obtain the actual method/path, decoded request/response shape, required field defaults, numeric enums, envelope transformation, error/status behavior and asynchronous completion behavior. At least bootstrap, one successful and one failed card/team mutation, map start/finish/retry and missing-content paths need real supported-client evidence. No current endpoint should be marked verified from this historical inventory alone. Domain/save-core development can continue independently in the cloud.
