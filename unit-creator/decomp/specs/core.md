# Core bridge spec (Android "Dokkan Unit Creator" -> iPhone port)

Sources: `decomp/src1/com_personal_aihub_CreatorActivity*.java` (+ smali1 where the .java is lossy),
`work/dock/src/com/personal/aihub/ForgeFixes.java`, `ProjectVersions`, `ProjectFormsData`,
`GameDataStore`, `EclpCodec`, `ConverterActivity`, UI `work/v2/ui/*.js`, `work/web/src/web-native.js`,
`work/harness/native_mock.py`. The decomp already contains the dock_smali.py text renames
("Forge" -> "Dokkan Unit Creator"), so the strings below are the shipped ones.

Notation: `root` = `<filesDir>/forge`. `assets` = `root/assets`. `projects` = `root/projects`.
"MiB" limits are exact byte counts given in parentheses.

---------------------------------------------------------------------------------------------------
## 0. Transport (JavascriptInterface and bridge.js)

### 0.1 JS side (`ui/bridge.js`, already supports iOS)
`Native.call(method, args = {})` picks, in order:
1. `window.forgeNative.call(method,args)` (web-native.js defines this; **if the iOS build loads
   web-native.js, the native handler is never used**: drop web-native.js or don't define `forgeNative`).
2. `window.webkit.messageHandlers.ForgeIOS` -> `postMessage(JSON.stringify({id, method, args}))`
   (a JSON **string**, not an object). No chunking on iOS.
3. `window.ForgeAndroid` -> `postMessage(raw)`; if `raw.length > 24000` and `postMessageChunk` exists,
   splits into 24000-char chunks (never splitting a surrogate pair) and calls
   `postMessageChunk(id, index, count, chunk)` for each.
4. `window.forgeTestBridge(method,args)`; else throws `"This screen must run inside the Android or desktop app."`

`id` is a per-page incrementing integer starting at 1. Pending promises are resolved by
`window.__forgeReply(message)`: `message = {id, ok:true, result}` or `{id, ok:false, error}`;
rejects with `new Error(message.error || "Operation failed")`. Unknown ids are ignored.

`Native.canConvertOnline()` returns `false` when `messageHandlers.ForgeIOS` exists -> the UI hides
"Use Eclipse online" (so `convert` is not reachable from the iOS UI).

### 0.2 Android interface object `ForgeAndroid` (class `CreatorActivity$Bridge`)
Registered with `addJavascriptInterface(new Bridge(), "ForgeAndroid")`. Exactly two methods:

* `void postMessage(String json)`
  - Parses `{id:int, method:string, args?:object}` (`getInt("id")`, `getString("method")`,
    `optJSONObject("args")` else `{}`). Logs `"Request <id> <method>"` (tag ForgeBridge).
  - **Parse failure -> silently returns, no reply** (JS promise never settles).
  - `method == "importStatus"`: answered **immediately on the JS binder thread**
    (`reply(id, importProgress, null)`), bypassing the worker queue, so polling works while a
    long task runs.
  - `method in {"import","importApk","export"}`: `runOnUiThread(pick(id, method, args))` (system file
    picker; see 0.4).
  - everything else: queued on ONE single-thread executor (`Executors.newSingleThreadExecutor()`):
    `reply(id, dispatch(method,args), null)`; any `Exception` -> `reply(id, null, e)`.
    => **All bridge calls are strictly serialized FIFO** (ForgeFixes relies on this: "these file
    operations never race with saveProject"). iOS must use a serial queue too, but answer
    `importStatus` out of band.
* `synchronized void postMessageChunk(int id, int index, int count, String chunk)`
  - Accepts only if `id>=1 && index>=0 && 1<=count<=1024 && index<count && chunk!=null && chunk.length()<=24000`;
    otherwise silently ignored.
  - index 0 starts a buffer; if 8 transfers already pending -> error `"Too many pending transfers"`.
  - missing buffer or total > 20971520 chars -> error `"Project transfer exceeds 20 MB"`.
  - On the last chunk the buffer is removed and passed to `postMessage(fullString)`.
  - Errors are replied to `id` via `reply(id,null,e)` and the buffer dropped.

### 0.3 Reply (`reply()` -> UI thread)
Builds `{"id":id,"ok":bool,...}`; on error `"error": e.getMessage()` or `"The operation failed."`
when the message is null; on success `"result": value` (`null` -> JSON null). Skipped if the
activity is finishing/destroyed or the WebView is gone. Logs `"Reply <id> chars=<n>"`.
* `< 24000` chars: `evaluateJavascript("window.__forgeReply(" + json + ")")`.
* `>= 24000`: `window.__forgeReplyParts=window.__forgeReplyParts||{};window.__forgeReplyParts[<id>]=[]`,
  then repeated `window.__forgeReplyParts[<id>].push(<JSONObject.quote(slice)>)` with 24000-char
  slices (surrogate-safe), then
  `window.__forgeReply(JSON.parse(window.__forgeReplyParts[<id>].join('')));delete window.__forgeReplyParts[<id>]`.
iOS: `evaluateJavaScript("window.__forgeReply(" + json + ")")` works for large payloads too;
chunking is optional. Errors in JS are just `{ok:false,error:"<message>"}` - **error strings are
shown to the user verbatim** (toasts), so keep the exact texts below.

Uncaught `org.json.JSONException` messages leak through as errors, e.g. `getString("key")` on a
missing key -> `"No value for key"`; file-not-found -> Java's
`"<path>: open failed: ENOENT (No such file or directory)"`.

### 0.4 File pickers (`pick`)
* Only one picker at a time: else reply error `"Finish the existing file picker first."`
* import/importApk: sets progress `{phase:"select", label:"Choose a file to import" | "Choose the latest Eclipse APK", bytes:0,total:0}`,
  `ACTION_OPEN_DOCUMENT`, CATEGORY_OPENABLE, type `*/*`, request 501.
* export: `ACTION_CREATE_DOCUMENT`, type `application/zip` if `args.kind=="zip"` else
  `application/octet-stream`, title = `args.name` or `"custom-unit.json"`, request 502.
* Result: cancel / no data -> reply `{}` (empty object; UI treats `result.saved !== true` as canceled
  and `!result.kind` as import canceled). Otherwise on the worker:
  502 -> `writeExport(uri,args)` reply; 501 -> `importUri(uri, method=="importApk")` reply.
* iOS: `UIDocumentPickerViewController(forOpeningContentTypes:)` for import, and
  `forExporting:` (or share sheet) for export, writing a temp file named `args.name`.

### 0.5 Page hosting (WebViewClient)
Loads `https://forge.local/index.html`; `shouldInterceptRequest` serves host `forge.local`:
path `""` -> `index.html`; `local-asset/<key>` -> `assetFile(key)` (assets dir, safePath +
canonical-prefix check: `"Invalid asset key"`, `"Unsafe path"`); else must be `safePath` and if it
starts with `data/` only these are served: `data/mechanics.js`, `data/guide-data.js`,
`data/animation-availability.js`, `data/movie-catalog.js`, `data/sparking-reference.json`
(others -> 404 text/plain "Not Found"). Files come from APK `assets/ui/<path>`. MIME by `mime()`:
.wasm application/wasm, .html text/html, .js application/javascript, .css text/css, .json
application/json, .png, .svg image/svg+xml, .jpg/.jpeg image/jpeg, .webp, .gif, else
application/octet-stream; charset UTF-8 for text/* and .js. Non-forge.local navigation is blocked
(`shouldOverrideUrlLoading` returns true). `ForgeFixes.intercept` (OfflineLibrary) runs first.
WebView: JS on, DOM storage on, file/content access off, mixed content compatibility.
Lifecycle hooks: `onPause` -> `window.forgePersist && window.forgePersist()`; Back ->
`Boolean(window.forgeHandleBack && window.forgeHandleBack())`, finish if result != "true".
iOS: WKWebView can't intercept `https`; use a custom scheme (e.g. `forge://local/`) via
`WKURLSchemeHandler`. The UI never hard-codes `https://forge.local` (only `assetUrl` returns it),
so change `assetUrl` to the new origin. Call `forgePersist()` on `sceneWillResignActive`.

### 0.6 Progress
No push events. Long tasks write `importProgress = {phase, label, bytes, total}` (via `progress()`);
UI (`app.js databaseTask`) polls `importStatus` every 750 ms and shows
`label · <bytes MB> / <total MB> MB`. Initial value `{}`; **never reset** after a task (keeps the last
`done`/`error` entry). Phases used: select, inspect, extract, verify, download, done, error,
restore, manifest, decrypt, convert.

### 0.7 Dispatch order (`CreatorActivity.dispatch`)
1. `ForgeFixes.dispatch(root, method, args)` (non-null result wins): deleteProject, wipeData,
   checkUpdates, cardIndex, openStore, deletePatch, renderMode, textZoom, previewDock,
   offlineLibrary, any `ai*` except `aiCompose`; `previewAnimation` only records then falls through.
2. Special-cased: aiCompose, openEclipse, sparkingInfo, animationFiles (sparking), updateSparking,
   downloadSparkingAssets, sparkingAudioCatalog, findSparkingAssets, querySparking, the four
   `*ProjectVersion(s)`, storeDecoration, assetStatus.
3. Switch: importStatus, external, animationFiles, assets, previewCache, previewTools, readAsset,
   projects, loadProject, patches, assetUrl, previewAnimation, ai, copy, info, sync, downloadAsset,
   query, restoreDatabase, browseAssets, saveProject, storeAsset, storeMovie, convert,
   animationVisuals, animationCatalog, storeLwf, animationSource.
4. Otherwise error `"Unsupported action: <method>"`.

**`version` and `patchesStatus` do not exist natively** (-> `"Unsupported action: version"`).
No UI file calls either. web-native.js invents `patchesStatus` (returns `{}`); nothing calls `version`.
`import`, `importApk`, `export` never reach dispatch (picker path).

---------------------------------------------------------------------------------------------------
## 1. Game database (info / query / querySparking / sync / checkUpdates / restoreDatabase)

### 1.1 Storage model (`GameDataStore(root, root/bundled-database.db)`)
* Bundled DB: APK asset `reference.db` (~103 MB, in `work/apk/assets/reference.db`) is copied once
  (via `root/bundled.tmp`, rename) to `root/bundled-database.db` (`"Could not prepare the card database."`
  on rename failure; copy limit 536870912).
  `ForgeFixes.refreshBundledDatabase` (called by ensureDb): stamp file `root/bundled-database.stamp`
  = `versionCode + ":" + lastUpdateTime`; when it changes deletes `bundled-database.db`, `-journal`,
  `-wal`, `-shm`, `bundled.tmp` so the new bundled DB is recopied. Never touches imported DBs.
* Imported/downloaded DBs: `root/databases/db-<sha256>.db`; pointer `root/database-state.json`:
  `{"version":1,"active":{"file":"db-<64hex>.db","meta":{...}},"previous":{...}?}`.
  `state()` validates version==1 (`"Unsupported database state"`), file names match
  `db-[a-f0-9]{64}\.db` (`"Invalid stored database name"`), pointer <= 1 MiB (`"Database state is too large"`).
* `current()`: state? `databases/<active.file>` : (`root/database.db` if exists (legacy) else bundled).
* `meta()`: state? `active.meta` : `root/database-meta.json` if exists else
  `{"source":"Bundled Eclipse English snapshot · 2026-10-14","date":"2026-10-14"}`.
* `commit(file, meta)` (synchronized): `slot()` copies file to `databases/stage-<uuid>` (fsync,
  limit 536870912 -> `"Database exceeds 512 MB"`), hashes it, renames to `db-<sha>.db` (if absent;
  `"Could not stage database"`), meta' = meta + `sha256` + `bytes`. New state =
  `{version:1, active:<slot>, previous: oldState.active | (first time and current() is a file:
  slot(current(), meta()))}` written atomically via `database-state.json.tmp` + fsync + rename
  (`"Could not activate the database; previous data was kept"`). Then `prune()` deletes every other
  `db-<64hex>.db`. => exactly one level of undo; first import makes the bundled DB the "previous".
* `restore()`: swaps active and previous (`"No previous database is available"`).
* DB opened read-only (`openDatabase(path, null, OPEN_READONLY)`).

### 1.2 `verifyDb(file, strict)` -> card count
Opens read-only; `PRAGMA quick_check` must return `"ok"` else `"Database integrity check failed"`.
Required tables and columns (each must exist as type `table`):
| table | columns |
|---|---|
| cards | id, name, rarity, element, resource_id, hp_max, atk_max, def_max, passive_skill_set_id, leader_skill_set_id |
| card_categories | id, name |
| link_skills | id, name |
| leader_skill_sets | id |
| leader_skills | id, leader_skill_set_id |
| passive_skill_sets | id |
| passive_skills | id |
| passive_skill_set_relations | id, passive_skill_set_id, passive_skill_id |
Missing column -> `"Database is missing game fields: <table>"`; not a table ->
`"Expected game data table: <table>"`. `SELECT count(*) FROM cards` must be >= 1000 (strict) or
>= 1 -> else `"The database contains starter or incomplete card data"`.

### 1.3 `info` (args ignored)
`ensureDb()` (copy bundled, open current, build schema), then
```json
{"schema": {"<table>": [{"cid":0,"name":"id","type":"INTEGER","notnull":0,"dflt_value":null,"pk":1}, ...]},
 "count": <SELECT count(*) FROM cards>,
 "meta": <GameDataStore.meta()>,
 "database": {"canRestore": <state != null && state.previous != null>}}
```
Schema = for each `SELECT name FROM sqlite_master WHERE type='table'` whose name matches
`[a-zA-Z_][a-zA-Z0-9_]*`, the rows of `PRAGMA table_info("<name>")` (row conversion as in 1.4).
Meta keys the UI reads (`app.js` ~919): `source`, `sourceType` (`apk-embedded` | `eclipse-current` |
absent), `date`, `publishedAt`, `sha256`, `apk.{filename,versionName,gameVersion,sha256}`.

### 1.4 `query` (queryDatabase) - exact language
Args: `{table, filters?, ids?, search?, order?, limit?, offset?}`.
1. `schema[table]` must exist -> else `"Table is not in this database."` (`getString("table")`
   missing -> `"No value for table"`). Column set = schema names.
2. `filters` object: for each key (iteration order of the JSON object) - unknown ->
   `"Unknown column"`; JSON null -> `"<col>" IS NULL`; else `"<col>" = ?` bound as
   `String.valueOf(value)` (org.json: ints -> "123", doubles "1.5", true -> "true", nested
   objects -> their JSON text). **Bound as TEXT**; SQLite type affinity of the column decides
   matching (numeric-affinity columns convert "123" to 123).
3. `ids` array: empty -> return `[]` immediately; > 1000 -> `"Too many row IDs"`; each `getLong(i)`
   (strings like "12" are accepted, non-numeric -> JSONException) bound as text:
   `"id" IN (?,?,...)`.
4. `search` object with non-empty `text`: `search.column` must be a column
   (`"Unknown search column"`) -> `"<col>" LIKE ?` with `"%" + text[0..200 chars] + "%"`.
   No escaping: `%` and `_` in the text act as wildcards. SQLite LIKE = ASCII case-insensitive only.
5. `order = optString("order","id")` must be a column (`"Unknown sort column"`; also applies when
   defaulting to `id` on a table without `id`).
6. SQL: `SELECT * FROM "<table>"[ WHERE c1 AND c2 ...] ORDER BY "<order>" LIMIT <L> OFFSET <O>`
   (conditions joined with `" AND "` in order filters, ids, search),
   `L = max(1, min(5000, optInt("limit",100)))` (so `limit:0` -> 1),
   `O = max(0, optInt("offset",0))`. Ascending only; ties in SQLite's natural order.
   Identifiers validated by `[a-zA-Z_][a-zA-Z0-9_]*` (`"Invalid database name"`) and double-quoted.
7. Rows -> array of objects keyed by column name: NULL -> null, INTEGER -> long, FLOAT -> double,
   TEXT -> string, BLOB -> `getString` (Android throws on BLOB; none expected).
`querySparking`: identical, against the Sparking DB (`ensureSparkingDb()`: on first use copies APK
asset `sparking-reference.db` to cache, requires SHA-256
`cf13b8553448507ad723e17a7b347e6eac4d7627a2e4fff56c0f7747660dffd8` else
`"The built-in Sparking catalogue is incomplete. Reinstall the complete APK."`, commits it into
`GameDataStore(root/sparking, root/sparking-unavailable.db)` with meta
`{source:"Sparking game database · built-in snapshot", sourceType:"sparking-bundled", date:"2026-10-17", latestVersion:1791992148, count}`).

web-native.js `query` differences: `limit:0` -> 100 (Android 1); search uses JS
`toLowerCase().includes` (no `%`/`_` wildcards, Unicode case folding); filter matching uses its own
number/string key normalisation instead of SQLite affinity; tables come from `data/db/*.json.gz`
(not reference.db); `querySparking` throws "Sparking characters aren't in the web version yet...".

### 1.5 `sync` (one-tap newest database)
`downloadCurrentDatabase({})`:
* URL `https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db`
  (decrypted SQLite, ~100 MB; UI text says "about 100 MB").
* `connection()`: only `https` + host exactly `dokkan-eclipse.com`
  (`"Only official Eclipse resource routes are supported"`), connect 20 s, read 60 s, redirects
  followed manually (max 5, each must pass the same host check; `"Too many Eclipse redirects"`),
  `User-Agent: DokkanUnitCreator/2.3`; non-200 ->
  `"Eclipse returned HTTP <code>. You can import a local database or resource pack instead."`
* Content-Length > 536870912 or streamed > that -> `"Database download exceeds 512 MB"`; if
  Content-Length > 0 and bytes differ -> `"The database download was incomplete"`.
* Temp file `root/database-download-<uuid>.tmp` (always deleted).
* Progress: `download` "Downloading Eclipse’s current full English database" (U+2019) with
  bytes/total(max(0,len)); `verify` "Checking downloaded database"; `verifyDb(tmp, strict=true)`.
* `useDb(tmp, "Eclipse current full English database", meta)` with meta =
  `{sourceType:"eclipse-current", downloadUrl:<url>, publishedAt:<Last-Modified header string or absent>, downloadedBytes:<n>}`
  + useDb adds `source`, `date` (ISO `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'` UTC), `count` (non-strict
  verify), GameDataStore adds `sha256`, `bytes`.
* `useDb` also: `ensureDb()`, deletes `root/animation-files.json` (animation list cache), closes the
  open DB, returns `info()`.
* syncDatabase wrapper: success -> progress `done` "Game database updated"; failure -> progress
  `error` "Update failed; previous data was kept" and rethrow.
* Result: the `info()` object. UI then sets `state.info`, reloads lookups, clears
  `localStorage["forge-finder-index"]`.

### 1.6 `checkUpdates` (ForgeFixes; never throws)
`HEAD` same URL, connect/read 15 s, `setInstanceFollowRedirects(true)` (any host), no custom UA.
Returns `{"ok": 200<=code<300, "status": code, "lastModified": <ms epoch, 0 if absent>, "size": <Content-Length int, -1 if unknown>}`;
on any throwable `{"ok":false,"error":"Couldn't reach Dokkan Eclipse. Check your internet connection."}`.
UI compares `new Date(lastModified).toISOString().slice(0,10)` with its stored data date and shows
`Update now · about <size/1MiB or 100> MB`.

### 1.7 `restoreDatabase`
progress `restore` "Checking the previous database"; requires `state.previous`
(`"No previous database is available"`); `verifyDb(previousFile)` (non-strict); `GameDataStore.restore()`
(swap); close DB; `info()`; progress `done` "Previous database restored; saved units kept".
Any failure -> progress `error` "Restore failed; the active database was kept" (rethrown).

web-native.js: `info` from manifest with `database.canRestore:false, web:true`; `sync` throws
"The web version gets new characters when the website is updated..."; `checkUpdates` fakes from the
manifest date; `restoreDatabase` missing (-> ANDROID_ONLY message).

---------------------------------------------------------------------------------------------------
## 2. Projects

### 2.1 `projects` (args ignored) -> array (directory order, unsorted)
For each `projects/*.json` (readText limit 20971520), skipping any file that throws:
```json
{"key", "name": cardOverrides.name ?? cards[0].name ?? "",
 "targetId": long, "reservedIds": [targetId, ...formProjects[i].targetId],
 "updatedAt": optString, "rarity": int (override first), "element": int (override first),
 "resourceId": long (override resource_id first), "origin": libraryOrigin ?? "created",
 "sparkingAnimations": sourceDependencies.animations.length>0,
 "sourceDatabase": source.database ?? "", "author": patch.author (patch object required)}
```
`reservedIds` throws `"A unit supports up to four transformation forms."` if > 4 forms (=> skipped).

### 2.2 `loadProject {key}`
`projectFile(key)`: key must match `[a-zA-Z0-9_-]{1,100}` -> else `"Invalid project key"`;
file `projects/<key>.json`; returns the parsed JSON object (readText 20 MiB limit; missing file ->
Java ENOENT message). web-native: `"This unit is no longer saved."`.

### 2.3 `saveProject {project}` (under lock PROJECT_WRITES)
Validation (any failure -> `"Unsupported project"`):
* `format == "dokkan-unit-forge"`, `version` is a Number equal to 1.0,
* `targetId` number, `0 < targetId <= 2147483647`, integral,
* `tables.cards` array of exactly 1 object.
* `targetId` rewritten as long. If `formProjects` key present: must be array (else error), length
  <= 4; each form: object, format dokkan-unit-forge, no `formProjects`, no `transformLinks`,
  version 1, integral targetId in (0, 2147483647], exactly one card; its targetId must differ by
  >= 1000 from the main targetId and every earlier form's targetId (abs diff < 1000 -> error).
  Form targetId rewritten as long.
Then `projectFile(project.key)` (`"Invalid project key"`). **Supersede check**: if the stored file
exists and both stored and new `updatedAt` match `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z` and
stored > new (string compare) -> return `{"saved":true,"superseded":true}` without writing (UI
throws "A newer copy of this unit is already saved...").
Bytes = `project.toString()` UTF-8 (org.json compact serialization). > 20971520 ->
`"Project exceeds 20 MiB."`. Written atomically (`ProjectVersions.atomic`: `<name>.<uuid>.tmp`,
fsync, rename; `"Could not commit saved project version."`). Returns
`{"saved":true,"revision":"<sha256 hex of written bytes>"}`.
The revision only needs to be self-consistent with ProjectVersions (both hash the stored file bytes).

web-native: only checks format and key regex, no version/targetId/forms validation, no supersede
check, no 20 MiB limit; revision = sha256(JSON.stringify(project)); stores in IndexedDB.

### 2.4 `deleteProject {key}` (ForgeFixes)
key regex `[a-zA-Z0-9_-]{1,100}` else `"Invalid project key"`; canonical-path check
`"Unsafe project path"`; missing -> `"This unit is no longer saved on this device."`; delete failure
-> `"Could not delete this unit. Try again."`; also removes `root/project-versions/<key>/`.
Returns `{"deleted":true,"key":key}`.

### 2.5 Saved versions (`ProjectVersions`, all under PROJECT_WRITES)
Common: `args.key` (`getString`) -> constructor: key regex `[a-zA-Z0-9_-]{1,100}`
(`"Invalid project key."` - note trailing period), project file must be `root/projects/<key>.json`
(`"Current project is outside its storage directory."`), dir `root/project-versions/<key>`
(canonical == absolute else `"Unsafe backup directory."`; mkdirs failure `"Cannot create saved versions."`).
Storage:
* `index.json`: JSON array (newest first) of `{versionKey, label, createdAt, bytes, fileBytes}`;
  read limit 65536 bytes; validation: <= 10 rows, versionKey UUIDv4
  (`[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}`), unique, 1<=bytes<=20971520,
  bytes<=fileBytes<=bytes+65536, label length <= 160, createdAt present; else
  `"Invalid saved version index."`; sum(fileBytes) > 41943040 -> `"Saved versions exceed their size limit."`.
* `<versionKey>.version`: one header line = JSON `{"versionKey","label","createdAt","bytes","key","revision"}` + `"\n"` +
  the exact project bytes. `fileBytes` = total file size. Header must be 1..65535 bytes.
* `current()` reads `projects/<key>.json` (must exist; `"Project backup is invalid or too large."`;
  size cap 20 MiB) and checks `format=="dokkan-unit-forge"` and `key` matches
  (`"Backup does not belong to this project."`; > 20 MiB `"Project exceeds 20 MiB."`).
* `candidate(bytes,label)`: label trimmed, null -> `"Give this version a readable name."`, empty /
  > 80 code points / control chars `(?s).*[\x00-\x1f\x7f].*` ->
  `"Use a readable version name of 1–80 characters."` (en dash). versionKey = random UUID,
  createdAt = UTC `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`, `bytes` = project byte length.
* `with(new, rows)`: new first, then older rows in order while count < 10 and running
  fileBytes total <= 41943040 (stops at the first that would exceed). `clean()` deletes
  `[0-9a-f-]{36}\.version` files not in the index.
* `check(args, currentBytes, required)`: if required or `expectedCurrentRevision` present, it must
  match `[a-f0-9]{64}` and equal sha256(current bytes) else
  `"This project changed after the version list was opened. Close it and reopen Saved versions."`.
* `read(versionKey)`: `"Invalid backup key."`, not in index ->
  `"This saved version is no longer available."`, file read cap 21037056, bad envelope
  `"Invalid backup envelope."`, header key/versionKey/revision mismatch
  `"Backup checksum does not match."`.

Methods:
* `listProjectVersions {key}` -> `{"versions":[{versionKey,label,createdAt,bytes}], "currentRevision":"<sha256 of current file>"}`.
* `saveProjectVersion {key, label, expectedCurrentRevision?}` -> list() + `"saved":true` +
  `versionKey,label,createdAt,bytes` of the new version. (On commit failure the new .version file
  is deleted.)
* `loadProjectVersion {key, versionKey}` -> the stored project object (not written anywhere).
* `restoreProjectVersion {key, versionKey, expectedCurrentRevision}` (revision required):
  automatically saves the current project as version labelled
  `"Before restoring an earlier version"`, commits index, then writes the restored project with
  `updatedAt = max(now, previousCurrent.updatedAt + 1 ms)` (UTC ISO, strict parse) atomically to
  `projects/<key>.json`; on write failure re-commits the old index. Returns list() +
  `"saved":true` + `"project": <restored project>`.

`ProjectFormsData.reservedIds` described in 2.1; `ProjectFormsData.restore` used by ECLP import (4.3).
web-native: **none of the four version methods exist** (-> ANDROID_ONLY error).

---------------------------------------------------------------------------------------------------
## 3. Patches (imported .eclp files)

### 3.1 `patches` -> array
Each `root/patches/*.json` parsed (20 MiB cap, bad files skipped), directory order. Object written by
importEclp:
`{"key":"<uuid>","metadata":{...header metadata...},"filename":"<display name>","importedAt":"<iso>","count":n,"bytes":<sum of extracted sizes>,"entries":[{"path","size"}],"projectKey":"unit-<targetId>-<uuid>"|null}`.
UI reads `metadata.name/author/uuid/sourceFormat`, `filename`, `key`.
### 3.2 `deletePatch {key}` (ForgeFixes)
key `[a-f0-9-]{36}` else `"Invalid patch key"`; neither `patches/<key>.eclp` nor `.json` ->
`"This patch is no longer saved on this device."`; delete failure `"Could not delete this patch. Try again."`
(does NOT delete `assets/patch-<key>/` nor the linked project). Returns `{"deleted":true,"key":key}`.
### 3.3 `patchesStatus` - not implemented natively (see 0.7). web returns `{}`.
web-native: patches in IndexedDB with keys `patch-<base36>` (would fail Android's regex).

---------------------------------------------------------------------------------------------------
## 4. Export / import

### 4.1 `export` args (from UI)
* `{name, kind:"json", text}` (project backup, `JSON.stringify(p,null,2)`),
  `{name, kind:"sql", text}`, and any other kind -> raw `optString("text")` UTF-8.
* `{name, kind:"eclp"|"zip", entries:[...], metadata?}` where entries (core.js `exportEntries`) are:
  `{path:"metadata.json", text}`, `{path:"files/<slug>.sql", text}`, `{path:"forge-project.json", text}`,
  `{path:"files/<asset.path>", assetKey}` per attached asset (all forms),
  `{path:"files/<pack.path>", cpk:[{path, assetKey}]}` per packed CPK,
  `{path:"files/<generated.path>", text}` per generated file (e.g. `lua/ab_script/ab_sys/dg0001.lua`).
* `{name, kind:"eclp", patchKey}` (Library "save game file") -> copies `patches/<patchKey>.eclp`
  verbatim (`patchFile`: `[a-f0-9-]{36}` else `"Invalid patch key"`).
* Shared Actions file: `{kind:"eclp", name, entries}` (export-flow.js supportRequest).

### 4.2 `writeExport(uri, args)`
Work dir `cache/forge-export-cpk-<uuid>/` (`"Cannot prepare artwork export."`), output first built in
`prepared-export.bin`, then copied to the picked URI (`"Cannot write this destination."`,
`"Export exceeds the 4 GB output limit."` > 4294967296). Work dir always deleted.
Entry source (`exportSource(entry, workDir, index)`):
* has `cpk`: path must end `.cpk` and entry must not have `assetKey`/`text` else
  `"Invalid packed artwork entry."`; builds `<workDir>/<index>.cpk` with
  `CpkWriter.write(assets, cpkArray, file)` (JS equivalent exists: `ui/cpk-writer.js`, ForgeCpk).
* has `assetKey`: file `assetFile(assetKey)` (safePath + inside `assets/`).
* else text: `optString("text")` UTF-8 (missing -> empty).
Kinds:
* **zip**: `java.util.zip.ZipOutputStream` (DEFLATED, default level 6), entries in the given order,
  path must be safePath and unique (`"Invalid or duplicate patch path"`); file copy limit 1 GiB.
* **eclp**: path safePath + unique (`"Unsafe or duplicate ECLP path."`); metadata = `args.metadata`
  object, else the `metadata.json` entry's text parsed (first one); none -> `"Missing ECLP metadata"`.
  `EclpCodec.write(out, cacheDir, entries, metadata.toString(), metadata.getString("uuid"),
  getString("name"), getString("version"))`. Note header metadata is the **org.json re-serialization**
  (compact, `/` escaped as `\/`), not the original text.
* other: text bytes.
Result: `{"saved":true,"name": optString("name")}`; picker cancel -> `{}`.

### 4.3 ECLP format (`EclpCodec`)
```
"ECLP" | u16 version=1 | u32 metaLen | metadata UTF-8 (metaLen bytes) | salt[32] | nonce[12] |
AES-256-GCM ciphertext of payload, 128-bit tag appended (no AAD)
payload = u32 count | count x ( u16 pathLen | path UTF-8 | u64 storedLen | u64 size | zstd frame[storedLen] )
```
All integers little-endian. Ciphertext starts at offset `54 + metaLen`.
Key: `pw = SHA-256(uuid + "|" + name + "|" + version)` (32 bytes) `||` fixed 32 bytes from hex
`ef16bc5f9378dc3fef16bc5f937ed622f910b35a9e76b8478b15d32be96dbf4c` (64-byte password);
`key = Argon2id(v=0x13, t=3, m=65536 KiB, p=4, salt, outLen 32)` (BouncyCastle). Only
uuid/name/version are bound; other metadata fields are not authenticated.
uuid/name/version must be non-blank, <= 1000 chars:
`"Patch UUID, name, and version are required (maximum 1,000 characters)"`. Memory guard: needs
100663296 bytes free heap else
`"There is not enough memory to convert this Eclipse patch. Close previews and try again, or use a device with more memory."`
(also on OutOfMemoryError).
Write: <= 100000 entries (`"Too many patch files"`), metadata <= 4194304 bytes (`"Patch metadata too large"`),
path safePath (`EclpCodec.safePath`: like 5.1 but max 4096) and UTF-8 <= 4096 and unique
(`"Invalid or duplicate ECLP path"`), each <= 536870912 and total <= 4294967296
(`"ECLP exceeds the 512 MB per file or 4 GB total limit"`). Each entry compressed with
**zstd-jni `ZstdOutputStream(level 3)`** (streaming frame; no content-size field, no checksum by
default) into temp `cache/eclp-write-<uuid>/<n>`; size mismatch `"Resource changed during export"`;
compressed > 512 MiB `"Compressed entry exceeds Eclipse’s 512 MB limit"`. Salt and nonce from
SecureRandom.
Read (`header`/`extract`): magic+version check `"Unsupported ECLP header or version"`;
1 <= metaLen <= 4194304, file length >= 70+metaLen and <= 4299161600 (`"Invalid ECLP length"`);
GCM failure -> `"ECLP authentication failed: file damaged or metadata changed"`; count <= 100000
(`"Too many ECLP files"`); pathLen 1..4096 (`"Invalid ECLP path length"`); unsafe/duplicate
(`"Unsafe or duplicate ECLP path"`); storedLen 1..512 MiB, size <= 512 MiB, total <= 4 GiB
(`"Invalid ECLP entry size"`); canonical destination inside target dir (`"Unsafe ECLP destination"`);
decompressed length must equal size and stored bytes fully consumed (`"ECLP entry size mismatch"`);
trailing bytes -> `"Unexpected trailing ECLP payload data"`; truncation -> `"Truncated ECLP file"`;
overflow `"ECLP file exceeds its declared or supported size"`; negative int `"Invalid ECLP integer"`.
Decryption goes to `cache/eclp-payload-<uuid>` first.
web eclp.js: same container, but writes zstd **raw blocks** only and can read only raw/RLE blocks,
so it cannot open Android-made (.eclp with compressed zstd blocks) files. iOS needs a real zstd
(bundle libzstd; Apple Compression has no zstd), Argon2id (bundle reference C or reuse
`web/src/argon2.js` worker), AES-GCM (CryptoKit `AES.GCM`, combined = ciphertext||tag).

### 4.4 `import` (`importUri(uri, apkMode=false)`)
Copies the picked file to `cache/forge-import-<millis>` (+`.apk` if apkMode or name ends .apk;
display name from `_display_name`, default `"import"`; limit 4294967296 ->
`"File exceeds the supported import size."`; null stream `"Cannot read selected file"`); temp deleted
afterwards. Detection order (name tests case-insensitive):
1. name ends `.apk`: package `com.sparkingDokkan.GLB` -> `importSparkingApk`; else if the zip has
   `assets/patcher/maps/android_current.json` -> `importEclipseApk`; else continue.
2. name ends `.json` -> project: must have `format=="dokkan-unit-forge"` else
   `"This JSON is not a Dokkan Unit Creator project. Use a SQLite database for game data."`;
   sets `libraryOrigin:"uploaded"`, `provenance:{file:<name>, importedAt:<iso>}`,
   `key:"unit-<targetId>-<System.currentTimeMillis()>"`; `saveProject` (validation errors apply;
   form keys are NOT rewritten); returns `{"kind":"project","project":<obj>}`.
3. first 4 bytes `ECLP` -> importEclp; `SPRK` -> importSparkingPatch; first 16 bytes
   `"SQLite format 3\0"` -> `{"kind":"database","info": useDb(file, <name>)}` (non-strict verify).
4. name `*.zip`: `importWrappedApk` (zip with exactly ONE file, which ends `.apk`, <= 512 MiB,
   CRC/size checked -> `"The APK inside this ZIP is incomplete or corrupted. Download the original ZIP again."`;
   then Sparking APK / Eclipse APK (`com.anthen.eclipse`) / importArchive) ; else `importPatchZip`
   (zip with `metadata.json` and at least one `(?i)files/.*\.sql` entry -> every file entry stored as
   ECLP entry with the zip path, ECLP built with metadata uuid/name/version, then importEclp with
   name `<name without .zip>.eclp`, note `"Patch ZIP converted to ECLP locally and added to Library."`;
   errors `"Unsafe or duplicate ZIP patch path"`, `"Patch ZIP too large"`, `"Too many ZIP entries"`).
5. name matches `(?i).*\.(zip|apk|apks|ipa|eclp)$` -> `importArchive` (an `.eclp` without magic ends
   here and fails as a ZIP).
6. name matches `(?i).*\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|m4a|aac|flac|awb|acb|atlas|plist|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$`
   -> stored as `assets/import-<uuid>/<basename>` (1 GiB cap), CPK expanded, returns
   `{count,bytes,expanded,warnings, "kind":"assets","asset":{"key":"import-<uuid>/<name>","path":<name>,"name":<name>,"size":n,"image":<png|jpe?g|webp|gif|bmp>}}`.
7. else `"Choose a unit JSON, ECLP or SPRK patch, readable SQLite database, image, ZIP, or APK archive."`

**importEclp(file, name)** -> `patchKey = randomUUID`; extract into `assets/patch-<uuid>/`
(using header metadata uuid/name/version); if `forge-project.json` exists: must be
dokkan-unit-forge v1 with 1 card (`"Invalid embedded unit project"`); key
`unit-<targetId>-<uuid>`, `libraryOrigin:"uploaded"`,
`provenance:{file, patchKey, author: metadata.author, importedAt}`, `ProjectFormsData.restore`:
forms (<=4 `"Too many embedded forms."`, no nesting `"Nested transformation forms are not supported."`,
each v1 with 1 card `"Invalid embedded unit form."`) rekeyed `unit-<targetId>-<uuid>`; each
`assets[i]` requires file `files/<path>` in the extracted dir (`"Embedded form resource missing."`)
and is rekeyed to `patch-<uuid>/files/<path>`; `previewKey` remapped or removed; `transformLinks[].targetKey`
remapped (`"An embedded transformation form is missing."`); then every string value anywhere equal
to an old asset key is replaced (depth limit 80, `"The embedded unit is too deeply nested."`).
Copies the original file to `patches/<uuid>.eclp`, writes `patches/<uuid>.json` (3.1 shape),
`saveProject(project)` if any. Returns
`{"kind":"project"|"patch","project":<obj>|null,"patch":<meta>,"note":"ECLP authenticated and added to Library. SQL stays inside the patch and is never executed by this app."}`.
On failure deletes the extracted dir and both patch files.

**importArchive(file, name)** (any ZIP/APK/IPA): `assets/import-<uuid>/`; <=100000 entries
(`"Archive contains too many entries"`/`"...too many files"`), unsafe path
`"Archive contains an unsafe file path"`; keeps `(?i).*\.(db|sqlite|sqlite3)$` as
`_databases/<basename>` and resource extensions (`png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin`)
at `normalizeAsset(path)`; NFC+lowercase duplicate -> `"Archive contains conflicting resource paths"`;
1 GiB per file, 4 GiB total (`"Resource import is larger than 4 GB"`). Each DB is
`verifyDb` non-strict (invalid ones ignored); chosen = last one whose path contains "decrypted",
else the first valid. CPK expansion; `useDb(chosen, name)` if any. Returns
`{count,bytes,expanded,warnings,"kind":"archive","database":bool,"note":"Readable game database imported." | "No readable game database found; the previous database was kept. Resource files were imported where available."}`.
Errors wrapped: `"Could not import this ZIP/APK. " + message` (dir deleted).
`normalizeAsset`: if any path segment is one of `character, lua, ingame, layout, bgm, movie,
card_transform, card_metamorphic, card_category, card_costume, dokkan_field, origin, outgame,
item, comic_text, fonts, shader, se, voice, tutorial0`, the path from the first such segment;
else strip leading `^(assets|files|uncompressed)/`.
`expandCpkResources(dir, count, bytes)` returns `{count, bytes, expanded, warnings[]}`
(unpacks .cpk in place, keeps originals, <=200 warnings then
`"Additional CPK warnings were omitted. Original archives were kept."`) - details belong to the
asset spec.

### 4.5 `importApk` (`importUri(uri, true)` -> `importEclipseApk`)
1. progress `inspect` "Checking Eclipse APK". `inspectEclipseApk`: Android `getPackageArchiveInfo`
   must give package `com.anthen.eclipse` else
   `"Choose the Eclipse Android APK (com.anthen.eclipse). The selected app was not installed or run."`.
   **iOS must parse the binary AndroidManifest.xml itself** (package, versionName, versionCode;
   see `work/patch/axml_*.py` for an AXML parser). gameVersion = `"version"` string of
   `assets/patcher/maps/android_current.json` (entry <= 8388608 bytes else
   `"APK version map too large"`; truncated to 100 chars; empty -> null).
   apkInfo = `{packageName, versionName ("" if null), versionCode, gameVersion, filename, sha256}`.
2. `ensureDb()`; resource group `apk-<uuid>` = `assets/apk-<uuid>/`; work dir `cache/apk-work-<uuid>/`.
   progress `extract` "Reading APK database and resources".
3. For each non-directory entry (<= 100000, `"Too many APK entries"`; unsafe ->
   `"Unsafe APK file path"`):
   * matches `assets/(sqlite/current/en/database(_decrypted)?\.db|database\.db)` -> DB candidate
     copied to `<work>/database-<n>.db` (remember original path; sets "saw DB" flag);
   * else if starts with `assets/`, does NOT match `assets/(patcher|dexopt|org)/.*`, and matches the
     resource-extension list (as importArchive incl. json) -> `assets/apk-<uuid>/<normalizeAsset(path)>`;
   * else skipped.
   Per entry <= 536870912 (`"APK resource exceeds 512 MB"`), total 4 GiB (`"APK resources exceed 4 GB"`),
   NFC-lowercase duplicate -> `"Conflicting APK resource paths"`.
4. `expandCpkResources(group, count, bytes)`; apkInfo.resourceCount = count.
5. Candidates sorted by rank desc (`/sqlite/current/en/` + `_decrypted` = 3, `/sqlite/current/en/` = 2,
   other (`assets/database.db`) = 1). First candidate whose first 16 bytes are
   `"SQLite format 3\0"` and passes `verifyDb(strict=true)` (>= 1000 cards; failures skip to next) wins.
   meta base = `{"apk": apkInfo, "resourceGroup": "apk-<uuid>"}`.
   * found: apkInfo.embeddedDatabase = original entry path; meta.sourceType `"apk-embedded"`;
     progress `verify` "Validating the database inside the APK";
     `useDb(file, "Database inside <filename>", meta)`; mode `"embedded"`.
   * none: apkInfo.embeddedDatabase = `"starter-or-encrypted"` (a DB entry existed) or
     `"not-included"`; `downloadCurrentDatabase(meta)` (1.5); mode `"downloaded"`.
6. progress `done` "Eclipse APK imported; game data ready". Result:
   `{"kind":"apk","database":true,"mode":..,"apk":apkInfo,"count":n,"bytes":n,"expanded":n,"warnings":[..],"info":<info()>,
   "note":"APK database validated and activated. Saved units were kept." | "The APK contains starter or encrypted data. Eclipse’s current full English database was downloaded and validated; saved units were kept."}`.
7. Failure: deletes the resource group, progress `error`
   "Update failed; previous data and saved units were kept", rethrows
   `<message> + " Your previous database and saved units were kept."`; work dir always deleted.
In plain `import` mode an APK without `android_current.json` is treated as an archive (4.4 step 5).

### 4.6 `importStatus` -> current `importProgress` object (see 0.6).

web-native: `import` handles only .json and web-made .eclp (key `"unit-<targetId>-<base36>"`,
rekeys forms/keys by string replace, no provenance, patch summary in IndexedDB); `importApk` throws;
`importStatus` returns `{}`; `export` zip throws; eclp with `assetKey`/`cpk` entries throws
("Custom artwork files can't be packed in the web version yet..."); export result
`{saved, name}` from its own save dialog / `ForgeFiles` iOS message handler
(`{id,name,base64}` -> `forge-file-saved` event `{id,saved}`); sanitizes names with
`[\\/:*?"<>|]+` -> `_`.

---------------------------------------------------------------------------------------------------
## 5. Misc

### 5.1 `safePath` (CreatorActivity)
non-empty, length <= 500, not starting `/`, no `\`, no match of `.*[:\x00-\x1f].*`, and every
`/`-segment (split with -1) non-empty and not `.` or `..`.

### 5.2 `wipeData {confirm:"DELETE", units?, files?, downloads?, ai?}` (ForgeFixes)
`confirm` must equal `"DELETE"` else `"Not confirmed."`. units: delete `projects/`,
`project-versions/`, recreate `projects/`. files: delete `assets/`, `lwf/`, `patches/`,
`animation-sources/`; recreate `assets/`, `patches/`. downloads: delete `preview-cache/`,
`movie-cache/`. ai: delete `ai-connections.json` and `ai-connections.tmp`. Game DB never touched.
Returns `{<each done flag>:true, "ok":true}`. Settings are cleared by the UI itself.
web-native: no confirm check; `units` also clears patches; has a `settings` flag
(`localStorage.clear()`); ignores files/downloads/ai; returns `{units,settings,web:true}`.

### 5.3 `copy {text}` -> clipboard (`ClipData` label `"Dokkan unit design"`), `{"copied":true}`.
### 5.4 `external {target, revision?}` -> opens `ACTION_VIEW`, returns `{"opened":true}`:
`converter` https://dokkan-eclipse.com/#convert-eclp, `documentation`
https://dokkan-eclipse.com/wiki/documentation, `downloads` https://dokkan-eclipse.com/downloads,
`files` https://dokkan-eclipse.com/files, `sparkingLicense`
https://creativecommons.org/licenses/by-sa/4.0/, `sparkingWiki`
`https://dokkansparking.miraheze.org/w/index.php?oldid=<revision>` (revision must match
`[1-9][0-9]{0,14}` else `"Invalid wiki revision"`); else `"Unknown destination"`. Missing target ->
`"No value for target"` (import-hub.js fallback calls `external {url}` which therefore fails).
web-native: no sparkingWiki; error `"Unknown link."`.
### 5.5 `openEclipse` -> launches package `com.anthen.eclipse`, else VIEW
https://dokkan-eclipse.com/downloads; `{"requested":true,"installed":bool}`; launch failure toast
`"Could not open Eclipse. Open it from your device's app list."`. UI: if `!installed` toasts
"Eclipse is not installed. Its official download page was requested." iOS: cannot detect it ->
open the downloads URL, return `installed:false`. (web opens https://dokkan-eclipse.com.)
### 5.6 `openStore {app:"chrome"|other}` -> Play Store `market://details?id=com.android.chrome|com.google.android.webview`
(fallback https://play.google.com/store/apps/details?id=...), `{"opened":true}`; "The app is still starting."
if no activity. Only called by compat.js for outdated WebViews -> iOS: return `{opened:false}`.
### 5.7 `renderMode {set?:"gpu"|"software"}` -> prefs `forge-render` (`software`, `autoSoftware`,
`crashes`, `crashAt`); set resets auto/crashes and applies `setLayerType`; returns
`{"mode":"gpu"|"software","auto":bool}`; auto-software after 2 renderer crashes within 10 min.
Error `"Rendering settings are not ready yet."`. iOS: always `{mode:"gpu",auto:false}`.
### 5.8 `textZoom {percent}` -> clamp 80..200 (default 100), persisted (`textZoom` pref) and applied
to WebView text zoom; startup applies it, or caps the system zoom at 140 when 100. Returns
`{"percent":n}`; `"Display settings are not ready yet."`. iOS: WKWebView has no textZoom; use
`pageZoom` or inject `document.documentElement.style.webkitTextSizeAdjust = n+'%'`.
### 5.9 `version` - no such native method (0.7).
### 5.10 `convert` (+ ConverterActivity) - Android only; iOS UI hides it (`canConvertOnline()` false)
Args = the export request + `patch` (project.patch object). Writes a **zip** export (kind forced
`zip`) to `cache/converter/<uuid>/unit-patch.zip` (dir deleted on error, rethrown), starts
ConverterActivity with extras `token=<uuid>`, `patch=<patch JSON>`; returns `{"opened":true}`.
ConverterActivity: token must match `[a-f0-9-]{36}` and the zip exist; buttons Close / Converter
(https://dokkan-eclipse.com/#convert-eclp) / Sign in (https://dokkan-eclipse.com/account); status
"Eclipse online • choose the prepared ZIP, convert, then download."; navigation allowed only to
https `dokkan-eclipse.com` and `discord.com|www.discord.com|discordapp.com|www.discordapp.com`;
on every page finished on dokkan-eclipse.com injects `window.__forgePatch=<patch JSON>;` + APK asset
`ui/converter-page.js`; file chooser auto-answers `content://<pkg>.patch/<token>/unit-patch.zip`
(status "Patch ZIP attached. Choose Convert Zip to ECLP, then its download link."); downloads only
from https `dokkan-eclipse.com` or `cdn.dokkan-eclipse.com`, save via CREATE_DOCUMENT
(name `URLUtil.guessFileName` sanitized `[\\/:*?"<>|\x00-\x1f]`->`_`, default `custom-unit.eclp`),
fetched with WebView cookies and its UA (or `DokkanUnitCreator/2.1`), manual redirects <= 6, rejects
`text/html` ("The download link returned a web page. Sign in again or reconvert."), empty, > 4 GiB.
Zip deleted when the activity finishes.

---------------------------------------------------------------------------------------------------
## 6. Files touched (Android layout; mirror under the iOS app's Application Support)
`root/projects/<key>.json`, `root/project-versions/<key>/{index.json,<uuid>.version}`,
`root/patches/<uuid>.{eclp,json}`, `root/assets/{patch-<uuid>,import-<uuid>,apk-<uuid>,...}/`,
`root/bundled-database.db` (+`.stamp`), `root/databases/db-<sha256>.db`,
`root/database-state.json`, legacy `root/database.db`/`database-meta.json`,
`root/animation-files.json` (deleted on DB change), `root/sparking/...`, temp files in cache.

## 7. web-native.js coverage summary for this area
| method | web-native | gap vs Android |
|---|---|---|
| info | manifest-based | no canRestore, different meta, adds `web:true` |
| query | in-memory tables | limit 0, LIKE wildcards, affinity (1.4) |
| querySparking | throws | missing |
| projects/load/save/delete | IndexedDB (+Claude cloud) | no validation/supersede/20 MiB; different missing-unit message |
| *ProjectVersion(s) | absent | missing entirely |
| patches/deletePatch | IndexedDB | key format differs; no `.json` meta file |
| patchesStatus | `{}` | not an Android method |
| export | json/text, eclp text-only | no zip, no assetKey/cpk, raw zstd blocks |
| import | json + web eclp | no DB/zip/apk/assets/sprk paths, no compressed-zstd ECLP |
| importApk / importStatus | throws / `{}` | missing |
| sync / checkUpdates / restoreDatabase | throws / fake / absent | missing |
| wipeData | partial | flags differ, no confirm check |
| copy, external, openEclipse, openStore, renderMode, textZoom | simple stubs | see 5.x |
| convert | absent | hidden on iOS anyway |

## 8. Could not determine
* `CpkWriter` and `expandCpkResources` internals (only the interface; see the asset spec / ui/cpk-writer.js).
* Exact zstd-jni defaults used by `ZstdOutputStream(out, 3)` (checksum/content-size flags assumed off;
  readers must not require them).
* Whether `importArchive` catches verifyDb failures for every exception type (decompiler shows an
  empty catch; behaviour assumed: invalid DBs are ignored).
* `importEclipseApk` candidate loop: smali shows verify failures go to the next candidate (handler
  re-enters the loop); not fully proven from the try-table (not present in the listing).
* The exact Java exception texts for missing files (platform-generated).
* Directory listing order for `projects`/`patches` (unspecified on Android; UI sorts itself).
