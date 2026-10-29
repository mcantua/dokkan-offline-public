# Public Dokkan interface research provenance

Checked October29,2026 using public repository metadata and exact source blobs. No account/login/game API was contacted, no source was executed, and no opaque server binary or private/stolen server dump was obtained. Repository/interface facts are retained; no third-party implementation is incorporated into the app.

## Licensed historical client reference

- Repository: <https://github.com/pawelorzech/dokkan-battle-bot>
- Pinned commit: `16cacd3571e4afd2af6f13cf5ae1da5ca6e193d1`.
- Reviewed source: [`commands.py`](https://github.com/pawelorzech/dokkan-battle-bot/blob/16cacd3571e4afd2af6f13cf5ae1da5ca6e193d1/commands.py),260,361bytes, SHA256 `1fd1821782f50c35bb0471369d35e928aefd7bd78f44ed8af557b1983cf67404`.
- Repository license: LGPL-3.0; reviewed LICENSE SHA256 `da7eabb7bafdf7d3ae5e9f223aa5bdc1eece45ac569dc21b3b037520b4464768`. This is source-reference analysis, not linked/copied LGPL implementation. Preserve upstream licensing if any implementation is reused later.
- Actual code includes a `complete_stage` HTTP client that constructs start/finish dictionaries and reads selected result fields. It is not a server implementation. README states it is unsupported; no current6.6 compatibility is established.
- `inspect_public_client_requests.py` parses this pinned source as AST only and emits approved field labels and literal type categories, never scalar values/credentials/signatures. The result is `research/public-client-request-evidence.json`.

The literal source supports historical boolean/array/integer categories for some quest request fields. Expressions remain unresolved. Conditional dictionaries do not prove runtime requiredness, indexed names may belong to intermediate objects, and none establish a complete server response or an admitted selected-client contract. Authentication/signing implementations were not imported.

## Other actual source inspected

| Source | Actual contents and license | Use decision |
| --- | --- | --- |
| [MNprojects/DokkanAPI](https://github.com/MNprojects/DokkanAPI/tree/c28a0248e36d97ebb678345d97be746f5f98d656) |11files; reviewed `src/server.ts` and README implement a GraphQL character-data API; AGPL-3.0. `server.ts` SHA256 `f16703ee6efa692fcc9f37db256db3222380e1c34c5c75f7b3545d7007550499`. | Not a game-server replacement or login/home/battle protocol foundation; no dependency imported. |
| [Bouncer011/DokkanBattleAPI](https://github.com/Bouncer011/DokkanBattleAPI/tree/6e302300444086d5e06e9fe7cfd2a8f8001e9de1) |5files: LICENSE, brief README, two card-data Python files and index.html; MIT. | No complete original-game handler/model implementation found; no dependency imported. |
| [DokkanEntropy/Wiki](https://github.com/DokkanEntropy/Wiki) |47public wiki files; `dokkan-code/` contains damage-calculation documentation, not server source. No repository license identified. Public docs describe a bundled localhost server. | Documentation confirms that such an architecture exists; it supplies no licensed server code/current wire contract to reuse. No closed binaries fetched. |
| [de-alone/dokkang-server](https://github.com/de-alone/dokkang-server) |Source tree contains lecture/study-group/post controllers; MIT. | Unrelated application despite name; rejected. |

Targeted public searches covered Dokkan server/private/API/offline and UniDokkan references. No reusable complete licensed original-game server was found in those inspected candidates. This is a bounded search result, not a claim that none exists anywhere. Raw public reference files and metadata remain ignored/private research inputs with exact hashes; public provenance above is sufficient to recover them.

## Current admission

No public reference is proven compatible with the supplied6.6.0 client. Current Sparking inspection independently establishes Foundation HTTP, JSON-object parsing and an optional object-valued `leader` mutation. Historical request fields can guide matching selected-client parser/constructor code; they cannot justify invented login/home/quest responses or live fan-server dependence. Continue actual local projections only after their required structures/control paths are verified.
