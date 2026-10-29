# Animation preview player — reimplementation spec (iPhone port)

Scope: everything from `Native.call('previewAnimation', …)` to a playing Eclipse player page, plus
`previewDock`, `previewCache`, `previewTools`, the per-preview local server and all of its routes,
audio banks / BGM, prepared movies + MovieCache, stage capture / recording export, the bootstrap
transfer, the player patch manifests, and the callbacks between the player page and the main UI.

Sources: `decomp/src1` + `decomp/smali1` (CreatorActivity, PreviewActivity, PreviewServer,
PreviewBootstrap, PreviewScripts, PreviewResources, PreviewCache, PreviewMetadata, PreviewEffectPacks,
PreviewBgm, PreviewTools, AudioBanks, GameBgm, GameAssets, GameDirectory, GameMetadata, StageCapture,
StageExport, WebViewStartup), `work/dock/src/.../PreviewDock.java`, `MovieCache.java`,
`ForgeFixes.java`, `work/patch/dock_smali.py`, `work/v2/ui/*`.

Paths below:
- `FORGE` = Android `getFilesDir()/forge` (the app's private data root; on iOS e.g.
  `Application Support/forge`).
- `CACHE` = Android `getCacheDir()` (iOS `Caches/`).
- `ASSETS` = `FORGE/assets` (user-imported game files: one sub-folder per imported "collection").
- `ui/…` = files packaged in the app (`work/v2/ui/…`).
- User-agent strings: the shipped APK was rebuilt with `DokkanUnitForge/x` → `DokkanUnitCreator/x`
  (dock_smali.py step 4). Use `DokkanUnitCreator/2.5` for preview downloads.

Where the decompiler was ambiguous I checked smali; residual unknowns are listed in §12.

---------------------------------------------------------------------------------------------------

## 1. Architecture in one picture

```
main UI WebView (index.html, bridge.js)                     player WebView (separate, isolated)
  Native.call('previewAnimation', args) ──► native            http://127.0.0.1:<port>/tools/<tool>/
     validates, writes CACHE/animation-preview/<uuid>/request.json        ▲      │ every request
     reply {opened:true, online:true}                                     │      ▼
     UI thread: ForgeFixes.openPreview(token)                    PreviewServer (one per preview,
        → PreviewDock.open (in-app panel)  ── fallback ──►       random port, HttpOnly cookie)
          PreviewActivity (full-screen window)                    ├─ /_forge/* native routes
                                                                  ├─ ui/* packaged JS (PreviewResources)
                                                                  ├─ imported files (GameAssets/…)
                                                                  └─ PreviewCache (disk) ⇄ https://dokkan-eclipse.com
```

The Eclipse web player (`https://dokkan-eclipse.com/tools/lua-player/`, `/tools/lwf-player/`,
`/tools/usm-player/`) is NOT bundled. It is downloaded (and cached on disk) on demand, served from a
loopback HTTP server so that it runs same-origin with the app's own `/_forge/…` endpoints, patched in
flight (hash-locked find/replace manifests), and then driven by an injected script
(`ui/animation-page.js` or `ui/movie-page.js`) that receives the preview request through a chunked
`evaluateJavascript` handshake.

---------------------------------------------------------------------------------------------------

## 2. End-to-end flow

### 2.1 What the UI sends: `previewAnimation` args

Callers: studio.js, guided.js, beginner-tools.js, training-picker.js, movie-editor.js, movies.js,
art-editor.js, battle-pose-editor.js, animation-gallery.js. Args object (all optional unless noted):

| key | type | meaning |
|---|---|---|
| `mode` | `"lua"`(default) \| `"pack"` \| `"movie"` \| `"training"` \| `"awakening"` | which player |
| `text` | string ≤ 2 097 152 chars | Lua composition source (lua/training/awakening) |
| `path` | string | Lua script path `ab_script/...lua` |
| `resourcePath` | string | `.lwf` path (pack) or `movie/....usm` (movie) |
| `scene` | string | LWF scene/movie button to auto-select (pack) |
| `name` | string | title, default `"Animation preview"` |
| `attackerId`, `enemyId` | number | card ids, defaults 1000010 / 1000020, `max(1, …)` |
| `assetKey` | string | "preferred" imported file key `<collection>/.../<file>` |
| `assets` | array of `{path,key}` | imported-asset alias overlay (§5.4) |
| `sourceDatabase` | `""`/`"eclipse"`/`"sparking"` | metadata DB to use |
| `effectPacks` | array (≤128) | edited movies registered as effect packs (§7.3) |
| `sparkingEffectIds` | array of int (≤1024) | effect-pack ids to read from the Sparking DB |
| `sparkingVersion` | int 1..2^53-1 | exact Sparking content version |
| `trainingItems` | array (≤5) of `{id, rarity}` | training/awakening scenes |
| `previewAppearance` | `{actorId, artCardId}` | exactly 2 keys, both integers 1..2^53-1 |
| **dock-only (never stored in request.json)**: `trim` `{from,to}`, `dockSize` `"small"|"full"`, `startAt` int, `startPaused` bool | | read by `PreviewDock.noteTrim` before the handler runs |

### 2.2 Native `previewAnimation` (CreatorActivity.previewAnimation) — exact algorithm

Order matters (first failing check wins). Errors are thrown as messages (bridge replies
`{id, ok:false, error:<message>}`).

1. `ForgeFixes.dispatch` first calls `PreviewDock.noteTrim(args)` (see §3.3), then the original handler.
2. `previewAppearance` present → must be an object with exactly 2 keys; for `actorId` and
   `artCardId` the value must be a JS number, finite, integral, `1 ≤ v ≤ 9007199254740991`; else
   **"Choose valid preview artwork"**. Normalized to `{actorId:long, artCardId:long}`.
3. `effectPacks` present but not an array → **"Choose valid edited movies"**.
   `packs = PreviewEffectPacks.normalize(args.effectPacks)` (§7.3).
4. `sparking = PreviewMetadata.sparkingEffects(args.sparkingEffectIds)` (§7.4);
   `validateEffectSources(packs, sparking)` → if any pack id is also a sparking id:
   **"An edited movie and a Sparking effect cannot share the same preview effect ID."**
5. `version = normalizeVersion(args.sparkingVersion)` (absent → 0; else number, finite, integral,
   1..2^53-1, else **"Choose a valid Sparking content version."**).
6. If `sparking.length>0` or `sourceDatabase=="sparking"`: ensure the built-in Sparking DB snapshot
   is installed (`prepareSparkingSnapshot`, other spec) and call
   `PreviewMetadata.databaseFile(FORGE,"sparking",version)` (throws if unavailable, §7.4).
7. `assets` present but not an array → **"Choose valid preview pictures"**;
   `GameAssets.overlayMap(assets)` validates it (§5.4).
8. `mode = args.mode || "lua"`; not in {lua,pack,movie,training,awakening} →
   **"Choose a supported preview type"**. `tool = pack→"lwf-player", movie→"usm-player", else "lua-player"`.
9. If `PreviewCache.offline()` is true: `cache.text("https://dokkan-eclipse.com/tools/"+tool+"/", 2 MiB)`
   (this throws **"This resource has not been saved for offline preview"** if the player page is not
   cached — i.e. offline previews require the player to have been downloaded).
10. Per-mode checks:
    - pack: `resourcePath` must match `(?i)[a-z0-9_./-]+\.lwf` and `safePath` → else **"Choose a valid visual pack"**.
    - movie: `resourcePath` must match `(?i)movie/[a-z0-9_./-]+\.usm` and `safePath` → else **"Choose a movie from the game video browser"**.
    - lua/training/awakening: if `text.length > 2097152` or (`text` empty and `!validAnimationPath(path)`) →
      **"Choose a valid animation or a shorter composition"**.
    - `safePath(p)`: non-empty, ≤500 chars, not starting with `/`, no `\`, no `:` or control chars
      (`.*[:\x00-\x1f].*`), and no empty/`.`/`..` segment when split on `/`.
    - `validAnimationPath(p)`: `length < 240` && matches `(?i)ab_script/[a-z0-9_/-]+\.lua` && `safePath`.
11. training/awakening: `path` must match `ab_script/training/a[0-9]{4}\.lua` (training) or
    `ab_script/awaken/a[0-9]{4}\.lua` (awakening) → else **"Choose the matching item animation"**.
    `trainingItems` must be an array with ≤5 entries (missing → same error)
    **"Choose up to five items for this scene"**; each entry an object (**"Choose valid scene items"**)
    whose `id` is a JS number, integral, 1..9 999 999 and `rarity` integral 0..4 (else
    **"Choose valid scene items"**).
12. Build the request JSON (key order irrelevant):
    ```json
    { "mode", "assetKey": args.assetKey||"", "resourcePath", "scene", "text", "path",
      "forgeVerifiedMusicPath": verifiedMusicPath(...),           // §7.1
      "name": args.name||"Animation preview",
      "attackerId": max(1, args.attackerId||1000010), "enemyId": max(1, args.enemyId||1000020),
      "sourceDatabase": "sparking"            // only if args.sourceDatabase=="sparking"
      "assets": [...],                        // only if given (deep copy)
      "trainingItems": [...],                 // only training/awakening
      "previewAppearance": {...},             // only if given
      "effectPacks": [...normalized...],      // always (maybe [])
      "sparkingEffectIds": [...],             // only if non-empty
      "sparkingVersion": n }                  // only if > 0
    ```
13. `token = UUID.randomUUID()` (lowercase hex with dashes, 36 chars). Write the JSON to
    `CACHE/animation-preview/<token>/request.json`.
14. On the UI thread: `if (!ForgeFixes.openPreview(activity, token)) startActivity(PreviewActivity, extra "token")`.
15. Return `{"opened": true, "online": true}` (always these values; the window opens asynchronously).

`verifiedMusicPath(mode, path, text, assetKey, assets)` → returns `path` or `""`:
- only for `mode=="lua"` and `path` matching `ab_script/finish_skill/[A-Za-z0-9_]{1,80}\.lua`, else `""`;
- if `text` is empty → return `path`;
- else bytes = imported file `lua/<path>` (GameAssets(ASSETS, assetKey, assets).read, ≤2 MiB) or, if
  none, the cached public copy `FORGE/animation-sources/<dbKey>/<path>` (≤2 MiB, where
  `dbKey = (meta.date || meta.sha256 || "bundled")` of the active game DB with `[^a-zA-Z0-9_-]` removed,
  truncated to 80) — if neither exists return `""`;
- return `path` iff `bytes == utf8(text)` exactly, else `""`; any exception → `""`.
  (Meaning: move music is only resolved when the composition is the unmodified original script.)

### 2.3 Choosing the window

`ForgeFixes.openPreview(activity, token)` → `PreviewDock.open(...)`, any throwable → `false` →
PreviewActivity. `PreviewDock.open` returns false (fallback) when: token not `[a-f0-9-]{36}`;
pref `separateWindow` is true; the system WebView major version is 1..119; `request.json` missing;
the main WebView's parent isn't a FrameLayout. On iOS there is no old-WebView case; implement the
dock and optionally the separate full-screen window as the `separateWindow` alternative.

`request.json` is read with a 3 MiB limit (`PreviewBootstrap.MAX_REQUEST_BYTES = 3145728`, error
"Preview too large") and must parse as a JSON object. The dock deletes `request.json` and its folder
after `play()` succeeds; PreviewActivity deletes them in `onDestroy` when finishing.

### 2.4 Starting one preview (common to dock and window)

```
cache  = PreviewCache(FORGE)
server = PreviewServer(ctx, cache, req.assetKey, req.assets, req.effectPacks,
                       req.forgeVerifiedMusicPath, req.sourceDatabase,
                       sparkingEffects(req.sparkingEffectIds), normalizeVersion(req.sparkingVersion))
for k in ["assetKey","assets","effectPacks","sparkingEffectIds","sparkingVersion","forgeVerifiedMusicPath"]:
    delete req[k]                         # private: never sent to the page
req.bgmContext = server.bgmContext()      # GameBgm context, §7.1
```
Dock only (PreviewDock.play) additionally sets:
```
req.dock = true
req.full = <panel currently full screen?>
req.startAt = int, req.startPaused = bool          # if pendingStart (from noteTrim)
req.trim = {from,to}                                # if pendingTrim and req.mode=="movie"
req.autoplay = true
req.quality = pref quality ("auto"|"smooth"|"best", default "auto")
req.qualityEpoch = pref qualityEpoch (int, default 0)
req.smooth30 = (quality != "best")
```
Then:
- player WebView settings: JavaScript on, DOM storage on, file access off, content access off,
  media playback does NOT require a user gesture, mixed content "never allow" (mode 1), black bg.
- `StageCapture(activity, web, server.origin)` and `StageExport(activity)` are attached to the server.
- `web.loadUrl(server.entryURL(req.mode))` →
  `http://127.0.0.1:<port>/_forge/open/<token64>?tool=<lua-player|lwf-player|usm-player>`
  (tool from mode as in §2.2 step 8).
- WebViewStartup overlay `begin(web)` (§9).
- Dock: if `req.text` matches `(?m)^-- FORGE_SEQUENCE_EXPORT [0-9]{1,5}$` (a "Save video" export), the
  panel is forced full screen (remember `exportFull` to shrink back afterwards); else if `dockSize`
  was given, use it; else if the previous preview was an export that forced full, go back to docked.

### 2.5 Page load → health check → bootstrap → mount

`/_forge/open/<token>` replies 302 `Location: /tools/<tool>/` with
`Set-Cookie: forge_preview_<port>=<token64>; Path=/; HttpOnly; SameSite=Strict`. The browser then
loads the (patched, rewritten) Eclipse player HTML with two injected scripts at the top of `<head>`
(§4.4). Afterwards:

1. `onPageStarted(url)` with a local url → reset `bootstrap=null`, `bootstrapEpoch=-1`, `startup.begin(view)` (new epoch).
2. `onPageFinished(url)`: only for local urls whose path matches `/tools/(lua|lwf|usm)-player/.*`, and
   only once per startup epoch. `startup.stage("player-runtime")`. Evaluate:
   ```
   <contents of ui/preview-runtime.js (≤20000 bytes)>;JSON.stringify({healthy:Boolean(window.ForgePreviewRuntime && window.ForgePreviewRuntime.healthy()),documentId:String(window.__forgeNativeDocumentId||'')})
   ```
   (preview-runtime.js checks 32-bit integer semantics: `[2147483648,4294967295,-1]` → `|0`, `>>>0`, `~`.)
3. Result (Android returns a JSON-encoded string; parse twice). If `view.getUrl() != url` or the
   preview was closed → ignore. If `!healthy` → "unreliable runtime" (§9.2) and stop.
4. `req.offline = cache.offline(); req.localPreview = true`.
   `boot = new PreviewBootstrap(nonce=UUID.random(), documentId=health.documentId, json=req.toString())`.
   `page = ui/movie-page.js if req.mode=="movie" else ui/animation-page.js` (≤200 000 bytes).
   `startup.stage("request-transfer")`, then `sendBootstrap(index=-1)`.
5. `sendBootstrap(i)`: script = `i<0 ? beginScript() : i>=chunkCount ? mountScript(page) : chunkScript(i)`;
   evaluate; when the result is exactly `true` (`"true"` on Android): if `i != chunkCount` send `i+1`;
   when the mount (i == chunkCount) returned true → `startup.stage("controls-ready")`, `startup.ready()`
   (overlay hidden), and dock: `ForgeDockPage.layout(full)` (§10.2). Any other result → evaluate
   `cancelScript()`, show the failure note (§9.3), `startup.failed(...)`, dock: tell main UI `"failed"`.
   Every callback first re-checks `startup.current(view, epoch) && bootstrap == boot`.

### 2.6 PreviewBootstrap — exact generated JS

Constructor `(nonce, documentId, requestJson)`:
- `nonce`, `documentId` must match `[A-Za-z0-9_-]{16,128}` else `IllegalArgumentException("Invalid preview session nonce.")` /
  `("Invalid preview document identifier.")`. NOTE: UUID strings contain `-` and are 36 chars → valid.
- `requestJson` non-empty, ≤ 3 145 728 UTF-16 units, no unpaired surrogates
  ("Preview request contains an incomplete Unicode character."), UTF-8 length ≤ 3 145 728
  ("Preview request exceeds 3 MiB of UTF-8."), must parse as a JSON object
  ("Preview request must be a JSON object."); else "Preview request exceeds its transport bounds.".
- `requestBytes` = UTF-8 byte length, `requestUnits` = UTF-16 length.
- Chunks: consecutive substrings of ≤ 48 000 UTF-16 units (`MAX_CHUNK_UNITS`); if a cut would split
  a surrogate pair (char[end-1] high && char[end] low) cut one unit earlier.
- `generation` = process-wide counter, incremented per bootstrap (1..2^53-1).
- `quote(s)` = JSON string literal of s, additionally replacing U+2028 → ` `, U+2029 → ` `.

Templates (`G` = generation, `N` = quote(nonce), `D` = quote(documentId), `i`, `C` = chunkCount,
`U` = requestUnits, `B` = requestBytes, `T` = quote(chunk text), `P` = page script text):

```js
// documentGuard
if(window.__forgeNativeDocumentId!==D)return false;
// sessionGuard = documentGuard +
var s=window.__forgePreviewBootstrap;if(!s||s.generation!==G||s.nonce!==N||s.phase!=='pending')return false;

// beginScript
(function(){<documentGuard>var old=window.__forgePreviewBootstrap;if(old&&(old.mounted||old.generation>=G))return false;window.__forgePreviewBootstrap={generation:G,nonce:N,phase:'pending',mounted:false,next:0,bytes:0,units:0,chunks:[]};return true;})()

// chunkScript(i)
(function(){<sessionGuard>if(s.next!==i)return false;var text=T;var bytes=new TextEncoder().encode(text).length;if(text.length>48000||s.units+text.length>U||s.bytes+bytes>B||s.bytes+bytes>3145728){delete s.chunks;s.phase='canceled';return false;}s.chunks.push(text);s.next++;s.units+=text.length;s.bytes+=bytes;return true;})()

// mountScript(P)   (note the literal newlines around P)
(function(){<sessionGuard>if(s.next!==C||s.units!==U||s.bytes!==B)return false;var request;try{request=JSON.parse(s.chunks.join(''));}catch(error){delete s.chunks;s.phase='canceled';return false;}delete s.chunks;s.phase='mounted';s.mounted=true;window.__forgeAnimation=request;(function(){
P
}).call(window);return true;})()

// cancelScript
(function(){<sessionGuard>delete s.chunks;s.phase='canceled';return true;})()
```
`window.__forgeNativeDocumentId` is set by the server-injected transport script (§4.4), so a chunk
can only land in the exact document the server produced. On iOS `evaluateJavaScript` returns a
`Bool`; treat `true` as success. (A WKWebView implementation could just as well use
`callAsyncJavaScript` with the JSON as an argument, but keeping these scripts keeps the page contract.)

The injected page script reads `window.__forgeAnimation`. `animation-page.js` only activates when
`location.protocol==="http:" && location.hostname==="127.0.0.1" && __forgeAnimation.localPreview===true`
OR (`location.protocol` is `https:` or `forge-preview:` and `hostname==="dokkan-eclipse.com"`), and the
path matches `^/tools/(lua|lwf)-player/`. `movie-page.js` requires `request.mode==="movie"` and a valid
`resourcePath` (`^movie\/[a-z0-9_./-]+\.usm$`i, ≤300 chars, no empty/./.. segments).

### 2.7 What the injected page does (for orientation; it is UI JS, reuse as-is)

- `animation-page.js`: builds the simplified control bar; sets `#attackerCardId`/`#enemyCardId`;
  feeds `request.text` (prefixed with `onDodgeExecuted = onDodgeExecuted or function(frame) end\n`) as a
  `File` named `forge-composition.lua` into `#scriptFile` via `DataTransfer`, or sets `#scriptPath`
  and clicks `#btnLoad`; for `ab_script/ab_sys/dg0001.lua` without text it fetches
  `/cdn/uncompressed/lua/<path>`; pack mode lists `/api/file-browser?path=<folder>`; auto-plays when
  `request.autoplay`; implements quality/devicePixelRatio caps; exposes `window.ForgeDockPage`;
  reports position and commands through `document.title` (§10.1). Imports
  `/_forge/media/preview-movie-audio.js`, `/_forge/media/preview-opponent-scenes.js`,
  `/_forge/media/preview-record-controls.js`.
- `movie-page.js`: USM player UI; imports `/_forge/media/movie-source.js`, `/tools/usm-player/js/pipeline.js`
  (= ui/media-pipeline.js) and `/_forge/media/playback.js`; honours `request.trim`, `request.offline`.

### 2.8 Dock vs. separate window

| | PreviewDock (in-app panel, default) | PreviewActivity (separate window) |
|---|---|---|
| when | default | pref `separateWindow`, WebView < 120, or dock failure |
| layout | panel over the top of the main screen; main WebView pushed down (`topMargin = panelHeight`); full screen hides main WebView | own activity: button "Back to Animation Studio", status line "Animation preview • loaded resources are saved on this device", WebView below |
| request extras | dock, full, autoplay, quality, qualityEpoch, smooth30, startAt/startPaused, trim | none (user taps "Load and play") |
| page→native | `document.title = "forge-dock:…"` commands (§10.1) | none (plain WebChromeClient) |
| native→page | `ForgeDockPage.layout(full)`, `ForgeDockPage.command({...})` | none |
| native→main UI | `ForgeDock.native(state)`, `ForgeDock.position(...)` | none |
| MovieCache routes `/_forge/movie-cache/*` | answered | not answered (404 from server allow-list) |
| reuse | one dock; each new preview replaces the one playing (`play()` stops the old server; same WebView reused) | one activity per preview |
| retry | WebViewStartup "Try again" → destroy WebView, replay same raw request with same start/trim | `recreate()` |
| render crash | destroy web, note "The animation player stopped. Tap Preview to play it again.", main `"failed"` | `WebViewFailure.show(...)` screen, retry recreates |

PreviewActivity version gate (WebView major 1..119): status text "Animation previews need a current
Android System WebView or Chrome. Update it, then reopen this preview. You can keep editing and
exporting units." + button "Open WebView update page" (not relevant on iOS). Activity-level errors:
"Could not open this preview: <message>" then finish.

---------------------------------------------------------------------------------------------------

## 3. Bridge methods in this area

All go through `Native.call(method, args)`; reply `{id, ok:true, result}` or
`{id, ok:false, error:<exception message or "The operation failed.">}` (iOS: `window.__forgeReply`
via `webkit.messageHandlers.ForgeIOS`, see bridge.js).

### 3.1 `previewAnimation(args)` → `{opened:true, online:true}` — §2.2.

### 3.2 `previewCache(args)` → `PreviewCache(FORGE).settings(args)`
Args (all optional): `clear` (must be boolean if present, else **"Invalid preview storage request."**),
`maxBytes` (must be a JSON number equal to an integer in the allowed set, else
**"Choose one of the preview storage sizes."**), `offline` (boolean).
Allowed `maxBytes`: 536 870 912 (512 MiB) or k·1 073 741 824 for k ∈ {1,2,4,8,16,32}.
Algorithm (under the global cache lock):
1. `cfg = read FORGE/preview-cache/settings.json` (any error → `{}`).
2. `maxBytes` → `cfg.maxBytes = v`.
3. `offline` → if different from current → `revision++`; `cfg.offline = v`.
4. `clear == true` → `revision++`; delete every file in `preview-cache/` whose name matches
   `[a-f0-9]{64}\.(body|json|tmp)(\.tmp)?$` (failure → **"Could not clear a saved preview file."**).
5. If `offline` or `maxBytes` was given → atomically write settings.json (`.tmp` + rename;
   failure **"Could not save preview settings"**).
6. Return `{offline: <current>, bytes: Σ size of *.body, count: number of *.body,
   maxBytes: storageLimit()}`; `storageLimit` = `cfg.maxBytes` if in the allowed set else 2 147 483 648.
`revision` is a process-wide counter used to abort tool preparation (§3.4).

### 3.3 `previewDock(args)` (ForgeFixes → PreviewDock.dispatch)
Prefs file `forge-preview-dock`: `separateWindow` (bool, default false), `smooth` (bool, true),
`quality` (`"auto"|"smooth"|"best"`, `"auto"`), `qualityEpoch` (int, 0), `startFull` (bool, true),
`fraction` (float, 0.46 — docked panel height / available height).
- No activity → **"The preview player is not ready yet."**
- `action` default `"status"`.
- `action:"set"` with any of: `separateWindow` (bool, `getBoolean` — non-bool throws JSON error),
  `smooth` (bool), `quality` (anything not `smooth`/`best` → `auto`; also `qualityEpoch += 1`),
  `startFull` (bool).
- `action:"seek"|"play"|"pause"`: build `{type:action}`; seek adds
  `frame: clamp(args.frame|0, 0, 10 000 000)`, `play: Boolean(args.play)`; evaluate in the player:
  `window.ForgeDockPage&&ForgeDockPage.command&&ForgeDockPage.command(<json>)` (fire-and-forget).
- `action:"close"|"back"` → dispose the dock; `"full"` → full screen; `"dock"` → docked;
  `"toggle"` → flip. Runs on the UI thread; the bridge thread waits ≤ 3 s. `handled` = there was an open dock.
- Returns `{open, full: open&&dock.full, handled, separateWindow, smooth, quality, startFull,
  dockable}`; `dockable = !separateWindow && !(WebView major 1..119)` (iOS: `!separateWindow`).

`PreviewDock.noteTrim(args)` (called for every `previewAnimation`, stored in statics consumed by the
next `play`):
- `pendingTrim = {from,to}` if `args.trim` has numbers with `0 ≤ from < to ≤ 3600`, else null.
- `pendingSize = args.dockSize` if `"small"`/`"full"`, else null.
- `pendingStart = {startAt: clamp(args.startAt|0, 0, 10 000 000), startPaused: Boolean}` if either key present, else null.

### 3.4 `previewTools(args)` → `PreviewTools(ctx, FORGE).request(args)`
Prepares the hosted player files for offline use from the packaged manifest
`ui/data/preview-bootstrap.json` (≤256 KiB):
`{schemaVersion:1, version:<64 hex>, origin:"https://dokkan-eclipse.com", resources:[{path, bytes, sha256, label}]}`
(currently 55 resources, e.g. `/tools/lua-player/`, `/tools/lua-player/js/app.js?v=eclipse67`,
`/static/vendor/lwf/lwf.js`, `/api/script?path=ab_script%2Fcommon%2Fcommon.lua`, …).
Manifest validation (else "Unsupported preview tools manifest" / "Invalid preview tools version" /
"Invalid preview tools count" (1..256) / "Invalid preview tools resource" / "Invalid preview tools
checksum or size" / "Preview tools exceed their size limit"): path is a relative URI (not absolute,
no authority/fragment), path starts with `/`, no `\`, no `//`, no control chars, no `.`/`..`
segments, starts with `/tools/`, `/static/` or `/css/` — or is exactly `/api/scripts` or
`/api/script?path=ab_script%2Fcommon%2Fcommon.lua`; unique; `bytes` integral 1..2 MiB; `sha256` 64
hex; `label` ≤160 chars; Σbytes ≤ 16 MiB.
- Args: only key allowed is `prepare` and it must be boolean, else **"Invalid preview tools request"**.
- One job per FORGE root (static map): `{preparing, label, failures[]}`.
- `prepare:true` and not already preparing: if offline → **"Connect once and switch off Offline
  preview to prepare the player tools."**; else start a background thread with the current
  `revision`: for each entry, stop if `revision` changed; set `label`; if not `matches(entry)`:
  if offline → failure "Offline preview is enabled. Connect again to finish preparing the player.";
  else `discard(url)`, `prepareBody(url, bytes, revision)` (download ≤ bytes, see §5.2; errors
  "Preview preparation stopped because storage or offline settings changed." / "Invalid preview tool
  size"), re-check, on mismatch `discard` and failure **"The hosted tool changed. Update the app before
  saving this version."**. On a failure append `{path, message}` (max 20) and continue with the next
  entry if still online and the revision is unchanged, else stop. Finally `label=""`, `preparing=false`.
- `matches(entry)`: cached body for `https://dokkan-eclipse.com`+path exists, its size == bytes and
  SHA-256 == sha256.
- Returns status: `{version, ready: preparedFiles==total, preparing, preparedFiles, totalFiles,
  preparedBytes, totalBytes, missingFiles, invalidFiles, offline, failures:[{path,message}], currentLabel}`.

### 3.5 Related read-only methods that use this subsystem (brief)
- `animationVisuals({unitId})` → resolves `https://dokkan-eclipse.com/api/card/<id>` through
  `PreviewMetadata.resolve` and lists `{name:"<card name> · Battle poses|Idle poses|Attack poses|Animated card background", path:<rel .lwf>}`
  for keys battle/idle/sp/card_bg, plus `· Aura` with `scene` from `/api/effect-pack/<aura_effect_id>`.
  Error **"Choose a character"** if id < 1.
- `animationFiles`, `animationSource` use `FORGE/animation-files.json`, `/api/scripts`,
  `https://dokkan-eclipse.com/cdn/uncompressed/lua/<path>` and `PreviewScripts` (other spec covers them;
  `PreviewScripts.listing` is described in §5.6).

---------------------------------------------------------------------------------------------------

## 4. PreviewServer (per-preview loopback HTTP server)

### 4.1 Construction
- `token` = two random UUIDs without dashes concatenated (64 hex chars).
- Validations: `sourceDatabase` via `normalizeSource` (`""`/`"eclipse"` → `"eclipse"`, `"sparking"`,
  anything else **"Unsupported preview database source."**); sparking ids; version
  (**"Choose a valid Sparking content version."**); effect packs normalized + cross-checked;
  if sparking source or sparking ids → `databaseFile(FORGE,"sparking",version)` must exist;
  `GameAssets.overlayMap(assets)` (else **"Invalid preview asset manifest"**).
- `gameAssets = GameAssets(ASSETS, assetKey, assets)`; `audioBanks = AudioBanks(ASSETS, assetKey, assets)`.
- `movieRoot = CACHE/preview-movies-<uuid>/` (created; failure **"Could not prepare temporary preview storage."**).
- BGM: open `databaseFile(FORGE, sourceDatabase, version)` read-only; if that fails and source is
  sparking → rethrow; `bgm = PreviewBgm(db, ASSETS, gameAssets, forgeVerifiedMusicPath)`
  (context computed immediately; db closed afterwards).
- Listen on `127.0.0.1`, port 0 (random), backlog 32. `origin = "http://127.0.0.1:<port>"`.
  `cookie = "forge_preview_<port>=<token>"`. 8 worker threads, queue 32, ≤32 concurrent clients,
  socket read timeout 30 s, one request per connection (`Connection: close`).
- `close()`: closes StageExport ("The animation preview was closed."), StageCapture, audio banks, BGM,
  the listener and all client sockets, deletes `movieRoot`. The owner then expires the cookie:
  `CookieManager.setCookie(origin, cookie + "; Path=/; Max-Age=0; HttpOnly; SameSite=Strict")`.
- `local(url)`: scheme `http`, host `127.0.0.1`, port == listener port, no userinfo.
- The player WebView blocks everything that is not `local`: `shouldInterceptRequest` returns
  `403 "Blocked"` text/plain `Cache-Control: no-store` body
  "Preview requests must use the isolated local player."; top-level navigations to non-local URLs are
  cancelled. So ALL network access of the player goes through this server.

### 4.2 Request parsing (reject → 400 with empty body)
- Read header bytes until `\r\n\r\n`, max 16 384 bytes ("HTTP headers exceed limit").
- Request line split on single spaces into exactly 3 parts; version must be `HTTP/1.1`; method
  `[A-Z]{3,8}`; target starts with `/`, not `//`, no `\`, ≤ 8192 chars.
- Target parsed as URI: no host, no fragment. Path segments may not be `.`/`..` or contain `\`;
  no chars < 0x20 or 0x7f.
- ≤ 64 header lines; each `name: value`, name lowercased must match `[a-z0-9-]{1,80}`, no duplicate
  names; values trimmed; no control chars except TAB.

### 4.3 Dispatch (in this exact order)
```
H = "127.0.0.1:<port>"
if headers.host != H                                   → 403
if has transfer-encoding or has expect                 → 400
if has origin and origin != this.origin                → 403
HEAD = method=="HEAD"
if (GET|HEAD) and path == "/_forge/open/<token>":
     tool = query param "tool" ∈ {lua-player,lwf-player,usm-player} else "lua-player"
     → 302, Location: /tools/<tool>/, Set-Cookie: <cookie>; Path=/; HttpOnly; SameSite=Strict
if no cookie part (split "cookie" on ";" and trim) equals <cookie>      → 403
if POST  and path == "/_forge/prepared-movies" and no query            → prepare()       §6.1
if DELETE and path startsWith "/_forge/prepared-movies/"               → deleteMovie()   §6.1
if not (GET|HEAD)                                                       → 405
if content-length present and != "0"                                    → 400
path startsWith "/_forge/prepared-movies/"    → movie()                 §6.1
path startsWith "/_forge/stage-export/"       → stage export            §8.2
path == "/_forge/stage-capture"               → stage capture           §8.1
path ∈ {"/_forge/bgm-source", "/_forge/bgm-source.acb", "/_forge/bgm-source.awb"}
   or startsWith "/_forge/bgm-bank-assets/"   → BGM                     §7.1
path == "/_forge/audio-banks" or startsWith "/_forge/audio-bank-assets/" → audio banks  §7.2
path startsWith "/_forge/" and not one of
   /_forge/training-context.js, /_forge/native-audio.js, /_forge/audio-bank.js,
   /_forge/imported-audio.js, or matching /_forge/media/(libav/)?[A-Za-z0-9][A-Za-z0-9_.-]*   → 404
target == "/api/scripts" (exact, no query)    → PreviewScripts.listing  §5.6  (error → 503 text)
otherwise → generic handler §4.4
```
(The dock's WebView answers `/_forge/movie-cache/*` itself before the request reaches the server,
§6.2.)

All responses are produced by `writeHeaders`:
```
HTTP/1.1 <code> Response\r\n
<route headers…>
Content-Length: <n>
Connection: close
Cache-Control: no-store
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Resource-Policy: same-origin
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Content-Security-Policy: default-src 'self' data: blob:; script-src 'self' 'unsafe-inline' 'unsafe-eval' blob:; connect-src 'self' blob:; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; media-src 'self' blob: data:; worker-src 'self' blob:; frame-src 'none'; object-src 'none'; base-uri 'self'; form-action 'none'
```
(header values have CR/LF stripped; reason phrase is literally "Response"). COOP+COEP make the page
`crossOriginIsolated` (SharedArrayBuffer for the ffmpeg/libav wasm). HEAD responses send headers only.

Range support (`sendStream`, used for every 200 body): header `range` matching
`bytes=([0-9]+-[0-9]*|-[0-9]+)` on a non-empty body → 206 with `Content-Range: bytes a-b/total`
(suffix form `-n` → last n bytes; n must be > 0; end clamped to total-1); invalid/unsatisfiable range
→ 416 with `Content-Range: bytes */<total>`. No range → 200.

Error convention: exceptions inside a route → **503** `Content-Type: text/plain; charset=utf-8`
with the exception message as body (players show it; the native shell shows a note for 503s, §9.3).

### 4.4 Generic handler (player files, game files, metadata)
Let `T` = request target (path + query), `U = "https://dokkan-eclipse.com" + T`.
1. **Directory listing** — if `GameDirectory.route(U)` (U is `https://dokkan-eclipse.com/api/file-browser?path=<p>`
   with `p` decoded from the first `path=` param, `GameAssets.safe(p)`, and `p + "/forge-directory-probe.lwf"`
   being a valid game path): `local = GameDirectory(ASSETS, assetKey, assets).resolve(U)`; if non-null →
   reply `application/json` = `GameDirectory.merge(local, JSON(cache.text(U, 2 MiB)))` (§5.5).
2. **Metadata** — if `T` matches `/api/(card|effect-pack)/[1-9][0-9]*(\?enemy=1)?` → reply
   `application/json` = `rewrite(PreviewMetadata.resolve(ctx, cache, U, assetKey, assets, effectPacks,
   sourceDatabase, sparkingEffectIds, sparkingVersion).toString())` (§7.4).
3. **Imported game file** — `f = gameAssets.resolve(U)` (§5.4). If found: size > 160 MiB →
   error "This imported preview asset exceeds 160 MB."; else 200 with `mime(f.name)` (table below).
4. **Packaged app file** — `PreviewResources.response(U)` (§4.5).
5. **Public resource** — `cache.response(U)` (§5.2: disk cache, else download).
6. Response headers: `Content-Type: <mime>`, `Accept-Ranges: bytes`.
   - status ≠ 200 → forward status + body (≤1 MiB).
   - mime starts with `text/` or contains `javascript` or `json` → read body (≤64 MiB) as UTF-8,
     `s = rewrite(playerPatches(path, s))` (§4.6/§4.7); if mime starts with `text/html` inject
     `"<script>" + transport() + "</script><script src=\"/tools/lua-player/js/forge-imported.js\"></script>"`
     immediately after the first `<head…>` tag (regex `<head(?:\s[^>]*)?>`, case-insensitive), or
     prepend it if no `<head>`; send with Range support.
   - otherwise stream the bytes (Range supported).

`mime()` for imported files (by extension, lowercase): bmp image/bmp, gif image/gif, jpg/jpeg
image/jpeg, png image/png, webp image/webp, mp3 audio/mpeg, ogg audio/ogg, wav audio/wav, otf font/otf,
ttf font/ttf, json application/json, xml/plist application/xml, lua/txt/fsh/vsh text/plain, anything
else application/octet-stream. (Note: imported `.lua`/`.json`/`.xml` go through patch+rewrite too —
harmless since no manifest matches their paths.)

`transport()` (a fresh document id per HTML response):
```js
window.__forgeNativeDocumentId=<JSON-quoted random UUID>;(()=>{const origin=<JSON-quoted origin>;const map=u=>{const s=String(u),cdn='https://cdn.dokkan-eclipse.com/uncompressed',site='https://dokkan-eclipse.com';return s.startsWith(cdn+'/')?origin+'/cdn/uncompressed'+s.slice(cdn.length):s.startsWith(site+'/')?origin+s.slice(site.length):s};const fetch=window.fetch;window.fetch=(u,o)=>fetch(u instanceof Request?new Request(map(u.url),u):map(u),o);const open=XMLHttpRequest.prototype.open;XMLHttpRequest.prototype.open=function(m,u,...a){return open.call(this,m,map(u),...a)}})();
```
`rewrite(s)`: in this order replace `https://cdn.dokkan-eclipse.com/uncompressed` → `<origin>/cdn/uncompressed`
and `https://dokkan-eclipse.com` → `<origin>`, each both in plain form and in JSON-escaped form
(every `/` written as `\/`).

`/tools/lua-player/js/forge-imported.js` is `ui/imported-preview.js` (see §4.5). Caveat: its `install()`
only activates on 127.0.0.1 if `__forgeAnimation.localPreview===true` at load time, which is not yet
the case (the request is mounted after `onPageFinished`), so on the Android loopback server it is
effectively inert; under a `forge-preview://dokkan-eclipse.com` origin it WOULD activate (fetch wrapper,
`ForgeLwfTimeline`, texture case aliases). Keep this in mind if you choose the custom-scheme design (§11).

### 4.5 PreviewResources — packaged JS served at fixed Eclipse paths
Only for `https://dokkan-eclipse.com` URLs, GET/HEAD (else 405 "Method not allowed"):

| path | packaged file |
|---|---|
| `/_forge/training-context.js` | `ui/training-context.js` |
| `/_forge/native-audio.js` | `ui/native-audio.js` |
| `/_forge/audio-bank.js` | `ui/audio-bank.js` |
| `/_forge/imported-audio.js` | `ui/imported-audio.js` |
| `/_forge/media/movie-edit-plan.js` | `ui/movie-edit-plan.js` |
| `/_forge/media/usm-writer.js` | `ui/usm-writer.js` |
| `/_forge/media/native-adx.js` | `ui/native-adx.js` |
| `/_forge/media/hca-metadata.js` | `ui/hca-metadata.js` |
| `/tools/usm-player/js/pipeline.js` | `ui/media-pipeline.js` |
| `/tools/lua-player/js/forge-imported.js` | `ui/imported-preview.js` |
| `/tools/usm-player/js/forge-metadata.js` | `ui/media-metadata.js` |
| `/_forge/media/(libav/)?<name>` (`[A-Za-z0-9][A-Za-z0-9_.-]*`) | `ui/vendor/media/<rest>` |

Type: `.wasm` → `application/wasm` (no charset), `.js` → `application/javascript`, `.json` →
`application/json`, else `text/plain` (charset UTF-8 except wasm). Headers `Cache-Control: no-store`,
`Accept-Ranges: bytes`, `Cross-Origin-Resource-Policy: same-origin`, `Content-Length`. Range as in
§4.3 (invalid → 416 "Invalid byte range"). Missing asset → 404
"A packaged movie component is missing. Reinstall the app.". (In the server the request object has
no headers, so ranges are actually applied by the server's `sendStream`.) These files ARE subject to
§4.6 patches only if their path matches a manifest (none do).

### 4.6 Player patch manifests (exact semantics)
`playerPatches(path, text)` where `path` = request path without query:

| path | manifest |
|---|---|
| `/tools/lua-player/js/usm-player.js` | `ui/media-player-patches.json` |
| `/tools/lua-player/js/audio-bus.js` | `ui/audio-player-patches.json` |
| `/tools/lwf-player/js/lwf-pack.js` | `ui/lwf-player-patches.json` |
| `/tools/lua-player/js/binders.js`, `runner.js`, `tcb-keys.js`, `lwf-player.js`, `recorder.js`, `atlas-fit.js`, `app.js` (all under `/tools/lua-player/js/`) and `/static/vendor/lwf/lwf.js` | the entry of `ui/training-player-patches.json` → `manifests[]` whose `path` equals it; none → **"The packaged item scene adapter is incompatible. Update Dokkan Unit Creator."** |
| anything else | unchanged |

Manifest format (single) `{version:1, path, sourceSha256, patches:[{find, replace}]}`; training file
`{version:1, manifests:[<single>…]}`. Algorithm:
1. `manifest.path` must equal the request path, else **"The packaged player adapter is incompatible. Update Dokkan Unit Creator."**
2. `hex(SHA-256(utf8(text)))` must equal `sourceSha256`, else **"The public player changed. Update Dokkan Unit Creator before previewing this animation."**
3. For each patch in order on the *current* text: `find` non-empty and occurring exactly once
   (`indexOf == lastIndexOf`, ≥0) else the same "public player changed" error; replace that occurrence
   with `replace` (literal, no regex, no `$` handling).
4. Errors become 503 text responses (the player then fails to load that module).
Manifests in the repo: audio 15 patches, lwf 14, media 13, training 8 manifests (binders 4, runner 1,
tcb-keys 1→3, lwf-player 1, recorder 1, atlas-fit 1, lwf.js 1, app 2). The JS reference implementations
are `ui/*-player-transform.cjs` (same algorithm, plus `version===1`, ≤32 patches for training). The
patched code imports `/_forge/media/*.js` modules (served per §4.5) — e.g. recorder.js becomes
`export {StageRecorder} from '/_forge/media/stage-recorder.js';`, usm-player.js imports
`/_forge/media/preview-movie-audio.js` and `playback.js`, binders.js installs training/BGM/audio hooks.
Note the hash covers the file bytes as served by Eclipse; the query string (`?v=eclipse67`) is ignored
for matching but is part of the cache key.

---------------------------------------------------------------------------------------------------

## 5. Storage, caching and asset resolution

### 5.1 Disk layout
```
FORGE/preview-cache/settings.json                 {"offline":bool,"maxBytes":long}
FORGE/preview-cache/<sha256(normalizedURL)>.body  response body
FORGE/preview-cache/<sha256(normalizedURL)>.json  {"url":<normalizedURL>,"type":<Content-Type or "application/octet-stream">}
                       .tmp / .json.tmp           in-progress files
FORGE/movie-cache/<64hex>-<kind>.mp4              kept converted movies (MovieCache) ; .part while copying
FORGE/assets/<collection>/...                     imported game files (also <collection>/files/..., <collection>/tutorial0/...)
FORGE/animation-sources/<dbKey>/<ab_script path>  downloaded public Lua sources
CACHE/animation-preview/<token>/request.json      hand-off file (deleted after open)
CACHE/preview-movies-<uuid>/<32hex>.mp4[.tmp]     per-preview prepared movies (deleted on close)
```
`wipeData({downloads:true})` deletes `preview-cache` and `movie-cache`.

### 5.2 PreviewCache
- `normalized(url)`: must be `https://dokkan-eclipse.com` (no port/userinfo) with path matching
  `/(tools/.*|assets/.*|static/.*|css/.*|cdn/uncompressed/.*|api/.*)` else
  **"Unsupported public preview resource"**. Query: split on `&`, each `k=v` URL-decoded; key `patch`
  → **"Private patch previews are not cached"**; drop params whose key matches
  `_|_t|t|ts|timestamp|cacheBust|nocache` AND whose value is all digits; keep the rest sorted by key
  (TreeMap: duplicate keys keep the last), re-encode with `URLEncoder` (form encoding: space→`+`).
  Result `https://dokkan-eclipse.com<rawPath>[?k=v&…]`.
- File base = `FORGE/preview-cache/` + lowercase hex SHA-256 of the normalized URL (UTF-8).
- `ensure(url, limit=160 MiB)`: if thread interrupted → "Preview closed". If `.body` and `.json` both
  exist → hit. Else if offline → **"This resource has not been saved for offline preview"**. Else,
  under a global lock (re-check after locking): GET the normalized URL with connect timeout 20 s, read
  timeout 60 s, **no redirects followed**, `User-Agent: DokkanUnitCreator/2.5`; status ≠ 200 →
  **"Eclipse returned HTTP <code>"**; `Content-Length > limit` or streamed bytes > limit →
  **"Preview resource exceeds 160 MB"** (same text for every limit); if no Content-Encoding (or
  identity) and Content-Length > 0 and bytes ≠ Content-Length → **"Incomplete preview download"**;
  if current total of `.body` sizes + new size > storageLimit →
  **"Saved preview storage is full. Increase its size or clear downloaded previews in Animation Studio."**;
  rename `.tmp` → `.body` (failure "Could not save preview"), write `.json` `{url,type}`.
  On any error delete the `.tmp`. No eviction — the cache only grows until cleared.
- `text(url, max)`: ensure + read body as UTF-8; size > max → "Preview text exceeds the size limit".
- `resourceBody(url, limit)`: limit must be 1..160 MiB ("Invalid preview resource limit"); ensure with
  that limit; body > limit → "This music resource exceeds its preview size limit".
- `prepareBody(url, size, revision)`: (lock) revision mismatch or offline → "Preview preparation stopped
  because storage or offline settings changed."; size 1..16 MiB; ensure(url, size).
- `cachedBody(url)` → body file if both files exist; `discard(url)` deletes `.body .json .tmp .json.tmp`
  ("Could not repair a saved preview tool").
- `response(req)`: GET/HEAD only (405 "Method not allowed"); `ensure(req.url)`; mime = stored `type`
  up to the first `;`; headers `Access-Control-Allow-Origin: *`, `Accept-Ranges: bytes`,
  `Cache-Control: no-store`, `Content-Length`; Range as usual; any exception →
  **503** text/plain with the message. (The server copies only status/mime/body.)
- `offline()`: `settings.json.offline` (any error → false).

### 5.3 What is fetched from where
Everything public is fetched from `https://dokkan-eclipse.com` + the request target (after the page's
transport mapping, CDN URLs `https://cdn.dokkan-eclipse.com/uncompressed/X` become
`/cdn/uncompressed/X` and are therefore fetched from `https://dokkan-eclipse.com/cdn/uncompressed/X`).
Typical targets: `/tools/<tool>/…` (player HTML/JS/CSS), `/static/…`, `/css/…`, `/api/script?path=…`,
`/api/card/<id>`, `/api/effect-pack/<id>[?enemy=1]`, `/api/file-browser?path=…`,
`/assets/<game path>` (LWF/PNG/ACB/AWB/USM…), `/cdn/uncompressed/<game path>` (lua, bgm, movie).
Other hosts are unreachable (the WebView blocks non-local requests).

### 5.4 GameAssets (imported files, used by the server)
- `gamePath(url)`: resolve against `https://dokkan-eclipse.com`; reject `\` and `.`/`..` segments;
  host `dokkan-eclipse.com` or `cdn.dokkan-eclipse.com`, https, no port/userinfo; path
  `/cdn/uncompressed/<rel>` or `/assets/<rel>`; `rel` must be `safe` and match
  `^(lua|script|character|ingame|movie|layout|bgm|outgame|origin|item|se|voice|comic_text|fonts|shader|dokkan_field|card_[a-z0-9_]+)/`.
- `safe(p)`: non-empty, ≤500, not starting with `/`; no `\ : %` or chars < 0x20 or 0x7f; no
  empty/`.`/`..`/dot-prefixed segment; no segment equal (case-insensitive) to `projects` or
  `secrets.json`; and NOT matching `(?i).*\.(db|sqlite|sqlite3)([-.].*)?$`. (The decompiled PRIVATE set
  is truncated; strings `exports`, `metadata.json`, `database-meta.json`, `account.txt` were also
  present in the initializer — treat all six as private segment names.)
- `overlayMap(assets)`: ≤2000 entries `{path,key}`; `path == gamePath("/assets/"+path)`; `key` safe
  with ≥2 segments; both extensions equal and in
  `png|jpe?g|webp|gif|bmp|lwf|lua|usm|cpk|kks|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|fsh|vsh|fnt|ttf|otf|strings|txt|bin`;
  NFC-lowercased paths unique. Errors: "Invalid preview asset manifest", "Invalid preview asset alias",
  "Preview aliases need matching supported resource types", "Conflicting preview asset aliases".
- `preferredPath(key)`: drop first segment (collection), then a leading `files`, then a leading
  `tutorial0`; result must be safe + PREFIX ("Invalid selected game asset").
- `resolve(url)` → File or null:
  1. `rel = gamePath(url)`; null → null.
  2. Alias: exact overlay entry for `rel`; else the longest overlay entry `X.cpk → K.cpk` such that
     `rel` starts with `X/` → alias `K/<rest>`.
  3. "Pinned" = alias found, or `assetKey` set and `preferredPath(assetKey)` equals `rel` or equals
     `fontFallback(rel)`.
  4. If ASSETS doesn't exist: pinned → **"The selected imported asset is unavailable. Choose it again."**, else null.
  5. Pinned → `regular(alias ?? assetKey)` or that same error.
  6. Else: collections = safe, non-symlink sub-directories of ASSETS sorted by lastModified DESC then
     name ASC; for each try `<c>/<rel>`, `<c>/files/<rel>`, `<c>/tutorial0/<rel>`; then the same with
     `fontFallback(rel)` (`fonts/X.(otf|ttf)` → `fonts/default/X`); else null.
  - `regular(rel)`: walk segments (any symlink → "Imported game assets cannot use symbolic links"),
    must be a file ≤160 MiB ("Imported game asset exceeds the 160 MB preview limit"), canonical path
    inside ASSETS ("Imported game asset escapes its resource folder").

### 5.5 GameDirectory (`/api/file-browser` for pack mode)
`resolve(U)` builds a listing of `.png`/`.lwf` files (regex `(?i).*\.(png|lwf)$`) in folder `p`:
items from overlay aliases whose path's parent is `p`; items found in `<c>/p`, `<c>/files/p`,
`<c>/tutorial0/p` across collections (same order as §5.4, first name wins; ≤10 000 entries scanned,
≤4096 collections); the preferred asset if it lives in `p`. Item:
`{type:"file", name, path:"<p>/<name>", size, source:"imported"}`. More than 200 items →
"This visual pack has more than 200 files. Choose a smaller pack." Result
`{path:p, parentPath:<p up to last "/" or "">, items:[…sorted by name], forge_local:true}`; null if no items
(but if the preferred asset is inside `p` and nothing found → "The selected imported asset is
unavailable. Choose it again.").
`merge(local, public)`: if same `path` and public has `items`: union keyed by name; public items are
kept only if `type=="file"`, name has no `/`, visual extension, `path == "<p>/<name>"`, valid game
path, `0 ≤ size ≤ 160 MiB` (re-emitted as `{name,path,type:"file",size,source:"public"}`); local items
override public ones; ≤200; returns a copy of `local` with merged `items`.

### 5.6 PreviewScripts (`/api/scripts` inside the player)
`listing(ctx, ASSETS)`: read `ui/data/preview-script-index.json` (≤2 MiB) — must have
`schemaVersion==1` (else **"Update Dokkan Unit Creator to load the packaged animation catalog"**);
collect valid paths from `scripts` (strings or `{path}`), valid = `length<240`, matches
`(?i)ab_script/[a-z0-9_/-]+\.lua`, `GameAssets.safe`; empty → "The packaged animation catalog is empty".
Add imported scripts: for each safe non-symlink collection dir (≤4096, "Too many imported animation
collections") walk `<c>/lua/ab_script`, `<c>/files/lua/ab_script`, `<c>/tutorial0/lua/ab_script`
(depth ≤24, ≤50 000 entries total, no symlinks anywhere, files 1..2 MiB) adding `ab_script/<rel>` when
valid. Reply = the index JSON with `scripts:[{path}…]` (sorted), `count`, `includesImported:bool`.

---------------------------------------------------------------------------------------------------

## 6. Movies

### 6.1 Prepared movies (per preview, in the server)
The page converts USM → MP4 in JS (ffmpeg/libav wasm, `ui/media-pipeline.js`, `vendor/media/*`) and
hands the result to native so `<video>` can stream it from a same-origin URL with Range support.
- `POST /_forge/prepared-movies` (no query; cookie required):
  `content-length` required, digits only (else 411); 12 ≤ length ≤ 160 MiB (else 413);
  content-type (before `;`, trimmed, case-insensitive) must be `video/mp4` (else 415).
  Capacity: not closed, `(kept + inFlight) < 32`, and `length ≤ 512 MiB − preparedBytes` → else
  **507** body "Temporary movie storage is full. Return to the Studio and reopen the preview.".
  Stream exactly `length` bytes to `<movieRoot>/<id>.mp4.tmp` (`id` = random UUID without dashes,
  32 hex) (EOF → "Incomplete prepared movie"), fsync; bytes 4..7 must be `ftyp` else 415; rename to
  `<id>.mp4` ("Could not retain this prepared movie"); reply **201** `application/json`
  `{"url":"/_forge/prepared-movies/<id>.mp4"}`. Failures release the reserved bytes.
- `GET|HEAD /_forge/prepared-movies/<id>.mp4` (`[a-f0-9]{32}\.mp4`, known id, no query) → 200/206
  `Content-Type: video/mp4`, `Accept-Ranges: bytes`; else 404.
- `DELETE /_forge/prepared-movies/<id>.mp4` (no query, no body) → 204; unknown → 404; delete failure
  → 503; bad name/query → 404; body present → 400.
- All files are deleted when the server closes.
Client: `vendor/media/playback.js` (POST, then validates `url` against
`^\/_forge\/prepared-movies\/[A-Za-z0-9_-]{16,128}\.mp4$`).

### 6.2 MovieCache (dock only; answered by the dock WebView before the server)
`/_forge/movie-cache/*`, GET only (else 405 `{}`), no `?` in URL (else 404 `{}`):
- `/_forge/movie-cache/<KEY>.mp4` with `KEY = [a-f0-9]{64}-[a-z]{1,4}` (SHA-256 of the original USM bytes
  + `-` + kind: `a` audio-only/default, `h` h264 profile, `v` vp9-opus, optional trailing `f`
  forceFfmpeg; see media-pipeline.js) → file `FORGE/movie-cache/<KEY>.mp4` if ≥12 bytes: touch
  lastModified, 200 `video/mp4` `Cache-Control: no-store` `Content-Length`; else 404 `{}`.
- `/_forge/movie-cache/keep/<KEY>/<id32>.mp4` → copy the server's prepared movie `<id>` to
  `<KEY>.part` then rename to `<KEY>.mp4` (if a target of the same size exists → 200
  `{"kept":true}`); if free space − size < 512 MiB → 507 `{"kept":false}`; rename failure → 500
  `{"kept":false}`; unknown id → 404 `{}`; then trim the folder to ≤3 GiB deleting oldest
  lastModified first (never the just-kept file). Success 200 `{"kept":true}`.
- Any exception → 500 `{}`. JSON responses `application/json`, `Cache-Control: no-store`.

### 6.3 Movie page offline note
`movie-page.js` fetches the USM through `/_forge/media/movie-source.js` (≤160 MiB, must start with
`CRID`) → `/assets/movie/…usm` or `/cdn/uncompressed/movie/…` → the generic handler (imported file or
PreviewCache). USM demux/decode, ADX/HCA audio and MP4 muxing are all JS — no native video codec work.

---------------------------------------------------------------------------------------------------

## 7. Audio, effect packs, metadata, Sparking

### 7.1 Move music (PreviewBgm + GameBgm)
`GameBgm.context(db, verifiedPath)`:
- If `verifiedPath` doesn't match `ab_script/finish_skill/[A-Za-z0-9_]{1,80}\.lua` →
  `{version:1, found:false, reason:"This preview has no verified finish-skill music context."}`.
- Query (script name = file name without `.lua`):
  `SELECT DISTINCT f.bgm_id AS id FROM finish_skill_sets f JOIN special_views v ON v.id=f.special_view_id WHERE v.script_name=? LIMIT 3`
  - exactly 1 row with integral id 1..2^31-1 → `{version:1, found:true, scriptPath, id, package:"bgm_%03d"}`
    (invalid id → error "Invalid game music context" → caught below);
  - 0 rows → reason "This move has no music selected in the imported game database.";
  - >1 → reason "This move has multiple different music contexts.";
  - any exception (incl. null db) → reason "The imported game database cannot resolve this move’s music."
- This object is `request.bgmContext`.

`PreviewBgm.descriptor()` (`GET /_forge/bgm-source`, JSON, cached per preview):
`{version:1, context, source}` where `source` is
- `null` if `!context.found`;
- imported: if `GameBgm.source` finds `/assets/bgm/<package>.acb` AND `.awb` via GameAssets (exactly one
  of them → "Imported move music is missing its matching cue sheet or waveform bank. Import the complete
  music pair."; different parent folders → "Imported move music must use a cue sheet and waveform from
  the same collection and folder."; relative paths must be safe → "Invalid imported music resource"):
  build `AudioBanks(ASSETS, null, [{path:"se/<package>.acb", key:<acbRel>}, {path:"se/<package>.awb",
  key:<awbRel>}], onlyAliases=true)`; its catalogue must contain exactly one bank (else "Imported move
  music is ambiguous"); source = `{kind:"imported", acb:{url,size}, awb:{url,size}}` with the urls'
  `/audio-bank-assets/` replaced by `/bgm-bank-assets/`;
- otherwise public: `{kind:"public", acb:{url:"/_forge/bgm-source.acb"}, awb:{url:"/_forge/bgm-source.awb"}}`.
- After close: "This music preview has closed".

Routes (no query allowed → 404):
- `/_forge/bgm-source.acb|.awb` → only when source kind is public: file =
  `cache.resourceBody("https://dokkan-eclipse.com/cdn/uncompressed/bgm/<package>.<ext>", limit)` with
  limit 32 MiB for `.acb`, 160 MiB for `.awb`; stream `application/octet-stream` (Range ok); otherwise 404.
- `/_forge/bgm-bank-assets/<id>.(acb|awb)` → imported bank file (AudioBanks.resolve on the
  `/audio-bank-assets/` form) or 404.
- Errors → 503 text.
Client: `vendor/media/preview-bgm.js` / `preview-bgm-source.js` (decoding is JS).

### 7.2 Imported sound/voice banks (AudioBanks)
`GET /_forge/audio-banks` → catalogue JSON; `GET /_forge/audio-bank-assets/<id>.(acb|awb)` → bytes
(`application/octet-stream`, Range ok) or 404; queries → 404; errors → 503 text. Client:
`ui/imported-audio.js`, `ui/audio-bank.js`, `ui/native-audio.js` (ACB/AWB parsing and HCA/ADX decoding
are all JS; native only discovers and serves the files).

Catalogue algorithm (`AudioBanks(root=ASSETS, preferredKey, overlays, onlyAliases)`; cached per preview):
- Limits: ACB ≤ 32 MiB, AWB ≤ 160 MiB, ≤4096 banks, ≤512 collections, ≤50 000 scanned entries,
  ≤512 MiB of byte comparison.
- `identity(rel)` (case-insensitive): `^se/([A-Za-z0-9_-]{1,80})\.acb$` → kind `se`, pkg; or
  `^voice/(?:(en|ja)/)?([A-Za-z0-9_-]{1,80})/([A-Za-z0-9_-]{1,80})\.acb$` with group2 == group3 →
  kind `voice`, pkg, locale (`en`/`ja`/`""`). Logical key `kind|locale|NFC-lower(pkg)`.
- Preferred groups = first segment of `preferredKey` and of every overlay key.
- Root missing → `{version:1, banks:[], warnings:[]}`. Symlinked/non-dir root → "Invalid imported audio folder".
- Unless `onlyAliases`: for each collection dir `c` (safe, non-symlink, sorted by name) and each base in
  `c`, `c/files`, `c/tutorial0`, and every `c/Payload/<X>.app` and `c/Payload/<X>.app/tutorial0`
  (`X` matching `[A-Za-z0-9_. -]{1,120}`): scan folder `<base>/se`, and `<base>/voice/<L><pkgdir>` for
  L ∈ {"", "en/", "ja/"} and each `pkgdir` matching `[A-Za-z0-9_-]{1,80}` (not `en`/`ja`). In a folder,
  file names that collide after NFC+lowercase → "Imported audio filenames are ambiguous"; each `*.acb`
  is a candidate with key `<base>/<sub>/<file>`, identity from `<sub>/<file>`, companion = the `.awb`
  with the same name (case-insensitive) if present.
- Overlay entries whose path has an identity are explicit candidates (key = overlay key; awb = overlay's
  matching `.awb` entry, or the key with `.acb`→`.awb`; missing explicit file → "The selected audio bank
  is unavailable"/"The selected audio companion is unavailable"; companion must be in the same folder
  with the same base name → "Audio bank companions must belong to the same collection and folder").
- Files are checked: no symlinks, inside root, size 1..max ("Imported audio bank exceeds its supported size").
- Per logical key: prefer explicit candidates, else those in preferred groups, else all. If >1, sort by
  key and drop duplicates that are byte-identical (same collection, same sizes, same bytes). If exactly
  one remains → bank `{id:<32 hex random>, kind, package, locale, acb:{url:"/_forge/audio-bank-assets/<id>.acb", size}, awb?:{url:"…/<id>.awb", size}}`;
  else warning (≤64) "More than one imported <kind> bank supplies <pkg> (<locale or default>). Select a
  single source collection to preview it."
- Result `{version:1, banks:[…], warnings:[…]}`. `resolve`: re-check file still exists with the same
  size, else "The selected imported audio bank changed or is unavailable".

### 7.3 Effect packs = edited movies (`effectPacks`)
`PreviewEffectPacks.normalize(value)` (null → `[]`; non-array or >128 → **"Choose a supported number of
edited movies."**). Each entry may only contain keys `id, category, pack_name, scene_name, name, red,
green, blue, alpha, lite_flicker_rate` (else **"The edited movie preview is invalid. Reopen it from your
unit."**). `id` integral 1..2^31-1; `category` integral 1..5 and must be 1 or 5; `pack_name` string
matching `forge_movie_[1-9][0-9]{0,9}_[0-9]{1,2}_[0-9a-f]{32}` whose 3rd `_` part ≤ 1 999 999 000 and
4th part ≤ 47 with no leading zeros; ids and pack names unique (all those → "…invalid. Reopen it from
your unit."); `scene_name` (default "") string `[A-Za-z0-9_]{0,100}`, `name` (default "") string ≤160
chars with no control chars (else **"The edited movie label is invalid."**); `red/green/blue/alpha`
default 255, range 0..255; `lite_flicker_rate` default 70, range 0..100.
In metadata resolution these act as rows of `effect_packs` with priority over the DB
(`/api/effect-pack/<id>` with one of these ids must resolve locally from the imported movie files or
fail with **"Your edited movie is missing. Reopen or reattach it."**).

### 7.4 Metadata `/api/card/<id>`, `/api/effect-pack/<id>[?enemy=1]` (PreviewMetadata + GameMetadata)
`databaseFile(FORGE, source, version)`:
- eclipse → `GameDataStore(FORGE, FORGE/bundled-database.db).current()` (active imported DB, else bundled).
- sparking → store `FORGE/sparking`; version 0 → current DB if state exists and file present else
  **"Download Sparking characters from Library before previewing this source."**; version > 0 → the
  `active` or `previous` state entry whose `meta.latestVersion == version` and whose file exists, else
  **"This animation needs Sparking content version <v>. Restore or import that version before
  previewing; another version was not substituted."**
`sparkingEffects(v)`: null → []; must be an array (≤1024, "Choose up to 1024 Sparking animation
effects.") of unique integral numbers 1..2^31-1 ("Choose valid Sparking animation effects." /
"Choose unique valid Sparking animation effects.").

`resolve(url)`:
1. Row source: `effect_packs` → own edited-movie pack if id matches, else Sparking DB if id ∈
   sparkingEffectIds, else project DB; other tables (`cards`, `characters`) → project DB
   (`SELECT * FROM "<table>" WHERE id=? LIMIT 1`, columns → JSON with integer/float/text/null types).
2. Rules from `ui/data/preview-metadata-rules.json` (≤1 MiB; `categories.<n>.lwf[]`, `.usm[]` path
   templates with `{pack}`, `enemyMovieSuffix`).
3. `local = GameMetadata.resolve(url)` — builds a response ONLY from imported files (null if none):
   - card: `cards` row; `character_id` (1..2^53-1), `res = resource_id || id`, `art = floor(res/10)*10`,
     `C = %05d(character_id)`, `M = %02d(special_motion||0)`. Descriptors (`{rel, url:"/assets/"+rel,
     bytes, source:"imported", stamp:"imported:<mtime>:<size>"}`) for
     `ingame/battle/character/C/battle/battle_character_C.lwf` (battle),
     `…/C/idle/idle_character_C.lwf` (idle), `…/C/spM/sp_character_C_M.lwf` (sp),
     `character/card_bg/<bgArt>/card_<bgArt>.lwf` (card_bg; `bgArt=floor(bg_effect_id/10)*10`, only if
     bg_effect_id≠0). Textures (key → file `character/card/<art>/card_<art>` + suffix):
     character `_character.png`, effect `_effect.png`, bg `_bg.png`, circle `_circle.png`,
     cutin `sp_cutin_1.png`, sp_cutin `sp_cutin_1.png`; plus `sp_name`/`sp_phrase` from
     `character/card/<art>/en/card_<art>_<k>.png` or `character/card/<art>/card_<art>_<k>.png`.
     If nothing found → null. Else `{found:true, forge_local:true, id, name, character_id,
     character_size:<characters.size>|null, resource_id, art_id:art, bg_effect_id, special_motion,
     aura_id, aura_effect_id:null, aura_scale:(default 1), aura_offset_x, aura_offset_y,
     is_aura_front:bool, battle, idle, sp, card_bg, textures, dbSource:"imported"}`.
   - effect-pack: row must exist, `pack_name` `[-a-zA-Z0-9_]{1,100}`, category rules exist; lwf = first
     existing of rules.lwf; usm = first existing of (`enemy` ? rules.usm with `{pack}=pack+enemyMovieSuffix`
     : nothing) followed by rules.usm; none → null. Else `{found:true, forge_local:true, id, category,
     name, pack_name, scene_name, rgba:{r,g,b,a}, lite_flicker_rate, media:"both"|"lwf"|"usm", lwf, usm,
     enemy:bool, dbSource:"imported"}`.
   - A `patch` query param → null; URLs must be https dokkan-eclipse.com/cdn.dokkan-eclipse.com.
4. If it's an effect-pack url for an own edited-movie id → return `local` or "Your edited movie is
   missing. Reopen or reattach it.".
5. `localOnly` (source sparking, or effect-pack id ∈ sparkingEffectIds) → return `local` or
   **"This Sparking preview needs its matching imported character/effect resources. Download the selected
   unit's resources from Library; Eclipse metadata was not substituted."**
6. Else `public = JSON(cache.text(url, 1 MiB))` (if that throws and `local` is null → rethrow; if
   `local` exists use it alone); return `GameMetadata.merge(local, public)`:
   - local null → public; public not `found` → local.
   - card: only if `character_id` and `art_id` equal: start from public, overlay all local keys; for
     battle/idle/sp/card_bg use local, else public only when compatible (sp: same special_motion;
     card_bg: same bg_effect_id; battle/idle always); `fsPath` removed; textures = public ∪ local;
     `aura_effect_id` from public when local's is null and aura_id equal.
   - effect-pack: only if same pack_name and category: public + local keys; `lwf` local else public;
     `usm` local else public when `enemy` flags equal; `media` = both/lwf/usm/missing.
   - otherwise local unchanged.
The server sends this JSON after `rewrite()`.

### 7.5 Sparking summary
`sourceDatabase:"sparking"` switches the metadata DB, BGM DB and forbids Eclipse metadata fallback;
`sparkingEffectIds` route chosen effect packs to the Sparking DB; `sparkingVersion` pins the exact
content version. Before any of that `previewAnimation` installs the built-in Sparking snapshot if the
Sparking store has no state (asset `sparking-reference.db`, SHA-256
`cf13b8553448507ad723e17a7b347e6eac4d7627a2e4fff56c0f7747660dffd8`, meta date `2026-10-17`,
latestVersion 1791992148; error "The built-in Sparking catalogue is incomplete. Reinstall the complete
APK.") — details belong to the data-store spec.

### 7.6 Training / awakening scenes
Native only validates (`§2.2` step 11), passes `trainingItems` and uses the lua-player; the scene logic
is JS (`/_forge/training-context.js` = ui/training-context.js, injected by the patched binders.js),
loading `/assets/outgame/effect/anim_160000/anim_160000.lwf`,
`/assets/item/training_item/thumb_training_items_<id 7 digits>.png`,
`/assets/item/awaken/en/thumb/thumb_awaken_items_<id 5 digits>/…`, etc. through the generic handler.

---------------------------------------------------------------------------------------------------

## 8. Recording ("Save video"): StageCapture + StageExport

The JS recorder (`/_forge/media/stage-recorder.js`, via patched recorder.js) records at 30 fps by
fetching one PNG snapshot per frame, encodes locally (worker, VP9/H.264 via wasm) to MP4, then saves.

### 8.1 `GET /_forge/stage-capture` (no query; HEAD → 405) → `image/png`
- Only one capture at a time and not closed, else "The animation snapshot is unavailable." (503).
- On the UI thread: owner finishing / WebView detached / no URL →
  "Open the animation player before recording."; the WebView URL must start with
  `<origin>/tools/lua-player/` (else the same error). Evaluate:
  ```js
  (()=>{const e=document.getElementById('stage');if(!e)return null;const p=e.parentElement;const r=e.dataset.phone==='1'&&(p&&p.classList.contains('stage-fit'))?p.getBoundingClientRect():e.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,vw:innerWidth,vh:innerHeight};})()
  ```
- Validate: all finite, scale > 0, x ≥ 0, y ≥ 0, 2 ≤ width,height ≤ 4096, x+width ≤ vw+1,
  y+height ≤ vh+1, else **"Keep the complete animation stage visible before recording."**. Convert to
  device pixels with `scale = web.getScale()`: `left=ceil(x·s)`, `top=ceil(y·s)`,
  `w=floor((x+width)·s)−left`, `h=floor((y+height)·s)−top`; require 2..4096 and inside the WebView
  (+1 px) else **"The animation stage is outside this preview."**.
- Copy those window pixels (PixelCopy of the window rect offset by the WebView's window location) into
  an ARGB bitmap, PNG-encode (≤ 8 MiB, else "The animation snapshot exceeds8MiB."), copy failure →
  "The device could not capture the current animation frame (<code>).". Timeout 15 s.
- iOS: `WKWebView.takeSnapshot(with: WKSnapshotConfiguration(rect: <CSS rect>, snapshotWidth: …))`
  (WK rects are in view points = CSS px at zoom 1), PNG-encode. Respect the same validation/limits.

### 8.2 `GET /_forge/stage-export/<id>.mp4` (no query; HEAD → 405)
Recorder flow: `POST /_forge/prepared-movies` with the MP4 → `{url}` → GET the same url with
`/prepared-movies/` replaced by `/stage-export/` → `{saved:bool}` → `DELETE` the prepared movie.
- `<id>` `[a-f0-9]{32}\.mp4`, known prepared file, 12 B..160 MiB, else 404.
- `StageExport.save(file)` blocks the request until the user finishes the system "create document"
  dialog (`ACTION_CREATE_DOCUMENT`, type `video/mp4`, title `animation-recording.mp4`, request code 531):
  cancel → `{"saved":false}`; chosen → copy (≤160 MiB, "The recording exceeds160MiB.") to the
  destination (`"wt"`), on error delete the created document and fail; success → `{"saved":true}`.
  Concurrent save → "Finish the existing recording save dialog first."; closed preview → "The animation
  preview was closed." / "The animation preview is closed."; missing destination stream →
  "The selected destination is unavailable."; invalid file → "The recording is unavailable.".
  Errors → 503 text/plain. In the dock, picker results arrive via `ForgeFixes.activityResult` →
  `PreviewDock.activityResult` → `recordingExport.result(...)`.
- iOS: present `UIDocumentPickerViewController(forExporting: [tempURL])` (or a share sheet) and
  resolve `{saved: didPick}`.

---------------------------------------------------------------------------------------------------

## 9. Startup overlay and error messages

### 9.1 WebViewStartup (overlay on top of the player area)
- `begin(web)`: new `epoch`, phase `loading`, stage `navigation`; shows spinner, title
  "Opening animation preview" (`"Opening " + screen`, screen = `"animation preview"`), message
  "Preparing this screen. Your saved units stay on this device."; after 45 s without `ready` →
  `slow("This screen has not responded yet. Keep waiting, try again, or copy a report to help diagnose it.")`.
- `slow(msg)`: phase `not-responding`, title "Taking longer than usual", buttons "Try again"
  (→ retry callback; phase `retry-requested`), "Keep waiting" (title "Opening …", message "Waiting for
  Android to open this screen. You can retry or copy a report at any time."), "Copy startup report"
  (clipboard label "Dokkan Unit Creator startup", JSON `{kind:"dokkan-unit-creation-startup",
  schemaVersion:1, appVersion, versionCode, androidAPI, deviceModel, screen, phase, stage, navigation,
  elapsedMs, webViewPackage, webViewVersion, scope:"Screen startup only; no animation playback or
  gameplay verification."}`; message "Startup report copied. You can paste it into your support
  conversation. It contains device and startup details, without unit data, account details, or preview
  links." / "Could not copy the report. You can still retry or return to the previous screen.").
- `stage(name)` records progress: `player-runtime`, `request-transfer`, `controls-ready`.
- `ready()` hides the overlay; `failed(msg)` → `slow(msg)`; `current(web, epoch)` guards callbacks.

### 9.2 Unreliable runtime (health check false)
Dock: destroy WebView, main `"failed"`, note "This device could not run the animation player reliably.
Update Android System WebView or Chrome, then try again. Tap here to hide this message."
Window: "This device could not run animation previews reliably. Update Android System WebView or Chrome,
then restart the device and reopen this preview. …" + buttons "Open WebView update page",
"Reopen animation preview". (iOS wording: drop the WebView advice.)

### 9.3 Notes shown by the shell
Dock note bar (orange, tap to hide) / window status line:
| event | dock text | window text |
|---|---|---|
| HTTP 503 on `/_forge/stage-*` | The recording could not be captured or saved. Try again. | The recording could not be captured or saved. Check the player message, then try again. |
| HTTP 503 elsewhere, offline | A file this animation needs is not downloaded yet. Turn off Offline preview or download it in Offline downloads. | A file needed for this preview is not saved on this device. Turn off Offline preview in Animation Studio, then load the animation again. |
| HTTP 503 elsewhere, online | A preview file could not be loaded. Check your connection, then tap Preview again. | A preview file could not be loaded. Check your connection or import the matching game assets, then retry. Player tools show the details. |
| main-frame load error | Could not open the animation player. Tap Preview again. (+ startup.failed "Could not open the animation player. Try again.") | Could not open the local animation player. Return to the Studio and reopen this preview. |
| preview-runtime.js unreadable | Could not check the animation player. Tap Preview again. | Could not check the animation player. Return to the Studio and reopen this preview. |
| bootstrap build failed | Could not prepare this preview. Try a shorter sequence. | Could not prepare this preview. Return and try a shorter sequence. |
| a bootstrap step returned non-true | This preview did not finish opening. Tap Preview again to retry. | This preview did not finish opening. Reopen it to try again. |
| retry failed | Could not reopen this preview: <msg> | — |
(503s for paths starting `/account/` are ignored.)

---------------------------------------------------------------------------------------------------

## 10. Callbacks between player page, native and main UI

There is NO JavascriptInterface on the player WebView. Channels:

### 10.1 Player page → native: `document.title`
`animation-page.js`: `tellApp(cmd)` sets `document.title = "forge-dock:" + cmd + ":" + Date.now()`.
Native (`onReceivedTitle`; iOS: KVO on `WKWebView.title`) splits the text after `forge-dock:` on `:`:
- `pos:<frame>:<last>:<p|s|d>:<ts>` (frame/last `[0-9]{1,7}`; p=playing, s=stopped/paused, d=done) →
  main UI `window.ForgeDock&&ForgeDock.position&&ForgeDock.position(<frame>,<last>,'<st>')`. Sent ≤4×/s
  while playing (frames at 60 per second).
- `close` → dispose dock; `size` → toggle full/docked; `bar-on` / `bar-off` → show/hide the native top
  bar (title + "Full screen"/"Smaller" + "✕  Close"; only shown with the classic player tools).

### 10.2 Native → player page
- `window.ForgeDockPage&&ForgeDockPage.layout(<true|false>)` after mount and on every layout change.
- `window.ForgeDockPage&&ForgeDockPage.command&&ForgeDockPage.command({"type":"seek","frame":n,"play":bool})`,
  `{"type":"play"}`, `{"type":"pause"}` (from `previewDock` seek/play/pause).

### 10.3 Native → main UI (dock only)
- `window.ForgeDock&&ForgeDock.native("full"|"docked"|"closed"|"failed")` — on layout, dispose, and
  failures; dock.js toggles `html.dock-open` and dispatches `forge-dock-state` / `forge-dock-failed`.
- `ForgeDock.position(frame,last,status)` → `forge-dock-position` event.
- Main UI Back handling (dock.js `forgeHandleBack`): full → `previewDock {action:"dock"}`; docked →
  `{action:"close"}`.

### 10.4 Dock geometry (for faithfulness)
Panel colors: bg `#0B141A`, bar `#152329`, text `#F2F5F7`, accent `#FFB15D`. Docked height =
`clamp(round(available·fraction), min=min(200dp, avail/2), max=max(min, avail−140dp))`; grip
(22dp, "━━━") drags the height and saves `fraction`. Full screen hides the main WebView; docked moves it
below the panel. Lifecycle: pause/resume the player WebView with the activity; dispose on destroy.
Starting size: `dockSize` from the editor, else pref `startFull` (default full screen).

---------------------------------------------------------------------------------------------------

## 11. iOS implementation notes (recommendations)

1. **Serve the player from a loopback HTTP server** (Network.framework `NWListener` on 127.0.0.1,
   random port; `NSAppTransportSecurity/NSAllowsLocalNetworking = YES`). This keeps every page check
   (`http:` + `127.0.0.1` + `localPreview`), the cookie gate, Range/`<video>` streaming,
   COOP/COEP (`crossOriginIsolated` for SharedArrayBuffer — WebKit honours it for potentially-trustworthy
   origins, which 127.0.0.1 is), module imports and `fetch` all identical. Set the session cookie by
   following the `/_forge/open/<token>` 302 (WKWebView stores it), and expire it on close via
   `WKHTTPCookieStore.delete`.
   Alternative: a `WKURLSchemeHandler` for `forge-preview://dokkan-eclipse.com/...` — page scripts accept
   that origin, but then `transport()`/`rewrite()` must map to that origin, `imported-preview.js` becomes
   active (§4.4), cookies don't apply, and AVFoundation-backed `<video>` playback from a custom scheme
   is unreliable; prefer the loopback server.
2. Block everything else: `WKNavigationDelegate.decidePolicyFor` → allow only the local origin; set a
   `WKContentRuleList` blocking all other URLs (WKWebView has no `shouldInterceptRequest`). The
   MovieCache routes (§6.2) should simply be implemented in the local server.
3. `evaluateJavaScript` returns typed values (Bool / String) — compare `true` directly; the health
   check returns a JSON string to parse once.
4. Title channel → observe `webView.title` via KVO (or add a `WKScriptMessageHandler` AND keep the title
   path for compatibility).
5. Settings: `configuration.mediaTypesRequiringUserActionForPlayback = []`,
   `allowsInlineMediaPlayback = true`, JavaScript on, non-persistent website data store per preview is
   fine (but localStorage `forge-fast-colors` is meant to persist; a shared default store keeps it).
6. Health check (`ForgePreviewRuntime.healthy()`) always passes on JavaScriptCore; keep it.
7. The stack is otherwise pure HTTP + files + SQLite: PreviewCache (URLSession with redirects disabled
   via delegate, UA `DokkanUnitCreator/2.5`), GameAssets/AudioBanks/GameDirectory file walks,
   PreviewMetadata (SQLite read-only), PreviewTools manifest download, patch manifests (SHA-256 +
   unique find/replace), stage capture (`takeSnapshot`), export (document picker).

---------------------------------------------------------------------------------------------------

## 12. Uncertainties / things not determined

- `GameAssets.PRIVATE` initializer is truncated in the decompile (only `projects`, `secrets.json` survive
  in the `asList`; the strings `exports`, `metadata.json`, `database-meta.json`, `account.txt` are loaded
  just before). Most likely all six are private names.
- Whether the `/api/file-browser` merge tolerates an unavailable public listing (`cache.text` throwing,
  e.g. offline) — the decompile has no inner try, so the whole route probably returns 503 even if a
  local listing exists. A lenient port (return the local listing alone) is harmless.
- `PreviewServer` constructor has a catch that rethrows as "Invalid edited movie preview" / "Could not
  prepare move music" around AudioBanks/DB/BGM construction; exact try-ranges are lost.
- The server ignores the WebView-side Range header for PreviewResources/cache responses and re-applies
  Range itself (behaviourally equivalent).
- Server-side handling of a `HEAD` to `/_forge/open/...` uses the same 302 without body.
- The `ForgeFixes.dispatch` hook placement inside `CreatorActivity.dispatch` is not in dock_smali.py
  (it lives in another patch step); behaviour: it runs first and returns non-null for handled methods.
- `previewAnimation` always answers `online:true` even when offline; the UI doesn't depend on it.
- Not verified against the live site (no network): the patch manifests' `sourceSha256` values pin the
  Oct-2026 Eclipse player files; if Eclipse updates them, previews fail with the "public player changed"
  error until new manifests ship.
