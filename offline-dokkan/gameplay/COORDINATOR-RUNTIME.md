# Private native engine bootstrap

The native host loads **only trusted bundled scripts** into its private iOS JavaScriptCore context or hidden Android engine WebView, in this order:

1. Define `nativeBattleRPC(op,args) → Promise`.
2. `coordinator-runtime.js` (UTF8 encoder and native SHA256 shim).
3. `battle.js`.
4. `session.js`.

Do not load game pages, user scripts or remote content into this context. Do not load this bootstrap into the visible game/Creator page. The native storage slot remains fixed and private. No arbitrary filesystem, SQL, reward or network interface is exposed by this runtime.

Native RPC has exactly three operations:

| Operation | Arguments | Result |
|---|---|---|
| `read` | `{}` | `null` or `{token,data}` |
| `cas` | `{expectedToken:null|string,data:string}` | New token string after durable commit, or `false` without writing |
| `sha256` | `{bytes:Array<number>}` | Exactly32 integer bytes |

SHA input is bounded at4MiB. Because JSON numeric byte arrays can expand to about16MiB, a JSON bridge needs an independently bounded transport frame (for example24MiB), not a4MiB JSON-text cap. Native values/callback arguments are preferable to code interpolation. The runtime always delegates SHA256 to the native platform, respects typed-view offsets/lengths and validates the32-byte reply. It provides no weak digest fallback. It installs `crypto` before `session.js` captures that object; a nonconfigurable existing crypto property fails explicitly instead of silently using another digest implementation.

Bare JavaScriptCore may lack `TextEncoder`; the included UTF8 encoder correctly handles ASCII/BMP/supplementary characters and replaces isolated surrogates with U+FFFD. It contains no game data or signing/key material.

The narrow global `OfflineBattleCoordinator` lazily creates its closure-owned session when the first request arrives. `handle(request)` is for **trusted native calls**. `handlePage(request)` restricts forwarded visible-game requests to `load`/`dispatch`.

```js
const reply = await OfflineBattleCoordinator.handle({id,op,args});
// Success: {id,result}
// Failure: {id,error:{code,message}}
```

| Operation | Exact argument keys | Success result |
|---|---|---|
| `startTrustedPlan` | `{plan}` | `{state,reference:{battleId,contentId,configurationSha256}}` |
| `openTrustedPlan` | `{reference}` | `{state,reference}` |
| `load` | `{}` | Current state directly |
| `dispatch` | `{command}` | `{state,events,replayed}` |

Use native-generated request IDs (a short safe string or nonnegative safe integer). Native code must preserve the outer reply ID/result/error unchanged. Page callers cannot start/open plans through `handlePage`; the native wrapper must enforce this same restriction before forwarding messages. An isolated script API alone does not make an unrestricted native bridge safe. No raw storage/session object is exported. Error replies contain bounded domain codes, not private paths or native exception dumps.

The native run coordinator creates/pins actual source-backed plans. After restart it uses the returned reference from its trusted run record. The page-facing loader/dispatcher unwraps `reply.result` and rejects `reply.error` for `battle-view.js`. The session commits authoritative state before returning visual events. There is no settlement operation or invented receipt verifier in this bootstrap: final results remain pending until the actual trusted core handoff is integrated.

One focused bare-cloud-JS-context scenario checked missing-browser-encoder UTF8 handling, actual native-callback SHA256 with a typed subarray, trusted start/reopen response shapes, narrow page authority and fixed RPC operations. Existing turn/session checks were not rerun. This is not iOS JavaScriptCore, Android WebView, disk durability, device launch or playable-game verification.
