# Assets, storage and offline downloads: iOS reimplementation spec

Scope: game assets, local storage and offline downloads for "Dokkan Unit Creator" (com.personal.aihub).
Native classes covered: GameAssets, ImageAssets, AssetDownload, AssetIndex, GameDirectory, GameMetadata,
GameDataStore, CpkArchive, CpkWriter, MovieStorage, DecorationStorage, LwfStorage, GameBgm,
LegacyDatabase, PatchProvider, ExportAssetAudit, the added classes OfflineLibrary, MovieCache and
ForgeFixes.cardIndex, plus their CreatorActivity bridge methods and the main WebView's request
interception. PreviewCache and PreviewScripts are covered as far as these features use them.

Sources: `/home/claude/decomp/src1/*.java` (androguard), checked against `/home/claude/decomp/smali1/*.smali`
where the Java was lossy, and `/home/claude/work/dock/src/com/personal/aihub/*.java`.

Conventions in this document:
* "Java error X" means the call rejects with `Error(message = X)`. The bridge reply is
  `{id, ok:false, error: e.getMessage() || "The operation failed."}`. A success is `{id, ok:true, result}`, and a
  null result becomes JSON `null`. Errors from org.json, such as a missing required argument, carry Android's
  org.json message, for example `No value for key`. A port does not need to reproduce those exactly.
* Every bridge call runs on one single-threaded worker (`Executors.newSingleThreadExecutor`), so calls never
  overlap, apart from the OfflineLibrary background threads. The iOS port should use one serial queue for the
  same guarantee.
* `optString(k)` returns `""` when the key is missing and the string `"null"` for a JSON null. `optString(k, null)`
  returns null only when the key is missing. `optInt` and `optLong` coerce numeric strings and use 0 when absent.
* Lower-casing uses `Locale.ROOT` (use `toLowerCase()` in JS). Case-insensitive keys use NFC + lower case:
  `s.normalize("NFC").toLowerCase()`.

---------------------------------------------------------------------------------------------------

## 0. On-disk layout (Android `getFilesDir()/forge` = "ROOT")

```
ROOT/                                   (CreatorActivity.root; the iOS port can use Application Support/forge)
  assets/                               ("ASSETS": every imported or generated user resource; asset keys are relative to it)
    <collection>/...                    one folder per import/generation, see 0.1
    _databases/...                      inside import collections: imported DB files (hidden from listings)
  projects/<key>.json                   (other spec)
  project-versions/<key>/...            (other spec)
  patches/<uuid>.eclp|.json             (other spec)
  lwf/                                  (wiped together with assets by wipeData; unused here)
  animation-files.json                  cached JSON array of animation script paths (animationFiles)
  animation-sources/<sourceKey>/ab_script/...lua   cached Eclipse Lua scripts (animationSource, OfflineLibrary)
  preview-cache/                        PreviewCache: <sha256hex>.body, <sha256hex>.json, settings.json, *.tmp
  movie-cache/<64hex>-<kind>.mp4        MovieCache (prepared MP4s, max 3 GB)
  .forge-movie-uploads-v1/              MovieStorage staging (.owner + upload-<uuid>.part)
  databases/db-<sha256>.db              GameDataStore slots
  database-state.json                   GameDataStore pointer
  database.db / database-meta.json      legacy single database (read only if no state file)
  bundled-database.db (+ .stamp)        bundled DB copy (ForgeFixes.refreshBundledDatabase)
  sparking/...                          Sparking content (other spec; see 9.4)
```
`assets/` and `projects/` are created when the app starts. `wipeData` (ForgeFixes) deletes `assets, lwf, patches,
animation-sources` when `files:true` and recreates `assets` and `patches`. With `downloads:true` it deletes
`preview-cache` and `movie-cache`.

### 0.1 Collection folder names inside ASSETS (first path segment of every asset key)
| Prefix | Created by | Content |
|---|---|---|
| `import-<uuid>` | ZIP/APK import (importArchive, single-file import) | game paths, possibly under `files/` or `tutorial0/`; DBs under `_databases/` |
| `apk-<…>`, `apk-work-<…>` | Eclipse APK import | game files |
| `patch-<…>` | ECLP import | patch resources |
| `sparking-…`, `sparking-source-<ver>/lua/<path>` | Sparking (other spec) | |
| `eclipse/<gamePath>` | `downloadAsset` without `group` | single Eclipse file |
| `art-download-<10–16 digits>-<6–64 [A-Za-z0-9_-]>/<gamePath>` | `downloadAsset` with `group` | protected artwork collection |
| `generated-<uuid>/image.png` | `storeAsset` | PNG |
| `generated-decoration-<uuid>/decoration.json` | `storeDecoration` | decoration JSON |
| `generated-lwf-<uuid>/animation.lwf` | `storeLwf` | LWF |
| `generated-movie-<uuid>/movie.usm` | `storeMovie` finish | USM |

An **asset key** is `<collection>/<relative path>`, for example `eclipse/character/card/1000010/card_1000010_character.png`.
GameAssets resolves the *game path* `P` within a collection C by trying `C/P`, then `C/files/P`, then `C/tutorial0/P`.

### 0.2 Path-safety predicates (used everywhere; port them exactly)

`CreatorActivity.safePath(s)`: s is not null or empty, length ≤ 500, does not start with "/", does not contain "\\",
does not match `.*[:\x00-\x1f].*`, and every segment of `s.split("/", -1)` is non-empty and not "." or "..".

`GameAssets.safe(s)`:
* s is not null or empty, length ≤ 500, and does not start with "/".
* Every char c satisfies c ≠ '\\', c ≠ ':', c ≠ '%', c ≥ 0x20 and c ≠ 0x7f.
* Every segment of `split("/",-1)` is non-empty, is not "." or "..", does not start with ".", and its lower case is
  not in PRIVATE = {"projects","patches","exports","_databases","metadata.json","forge-project.json",
  "database-meta.json","database-state.json","account.txt","credentials.json","secrets.json"}.
* The whole string does not match DATABASE = `(?i).*\.(db|sqlite|sqlite3)([-.].*)?$`.

`GameAssets.PREFIX` = `^(lua|script|character|ingame|movie|layout|bgm|outgame|origin|item|se|voice|comic_text|fonts|shader|dokkan_field|card_[a-z0-9_]+)/`
(Java `find()` at the start, so it is a prefix test.)

`CpkArchive.safePath(s)`: like GameAssets.safe for length, leading "/", "\\", ":", control chars and
empty/"."/".." segments. It **allows** '%', leading dots and the PRIVATE names.

`CpkWriter.safe(s)`: identical to GameAssets.safe, PRIVATE set and DB regex included.

`ImageAssets.safe(key)`: non-empty, length ≤ 500, matches `(?i).*\.(png|jpe?g|webp|gif|bmp|lwf|json)$`, has no
'\\' ':' '%' or control chars (<0x20 or 0x7f), and every segment is non-empty, does not start with ".", and is not
(case-insensitively) in {"_databases","projects","patches","exports"}. (A leading "/" yields an empty first
segment, which is rejected.)

`DecorationStorage.safe(s)`: non-empty, length ≤ 500, no leading "/", does not match `.*[\\:\x00-\x1f\x7f%].*`,
and every segment is non-empty and does not start with ".".

Symbolic links: every Android implementation refuses symlinks along the path and checks that the canonical
path starts with `canonical(ASSETS) + "/"`. The iOS sandbox has no attacker-made symlinks, but the
canonical-prefix check should be kept.

### 0.3 Supported resource-file extension regex (used by downloadAsset and import)
`(?i).*\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$`
Image regex: `(?i).*\.(png|jpe?g|webp|gif|bmp)$`.

---------------------------------------------------------------------------------------------------

## 1. Network: hosts, headers, redirect handling, limits

Every host is `https://dokkan-eclipse.com`. The phone cannot reach it from this sandbox, so response shapes below
are inferred from the consuming code.

| Client | UA header | Other headers | Redirects | Timeouts | Size limit | Non-200 |
|---|---|---|---|---|---|---|
| `AssetDownload.openOfficial(url)` (downloadAsset, OfflineLibrary.scripts) | `User-Agent: DokkanUnitCreator/2.7` | `Accept-Encoding: identity` | Manual. Every hop must be `https`, host exactly `dokkan-eclipse.com`, no userinfo, no port. Up to 5 redirects (6th hop rejected). 3xx without `Location` → "Invalid Eclipse redirect." Location is resolved relative to the current URL | connect 20 s, read 60 s | 160 MB (167772160) | `Eclipse returned HTTP <code>.` (with the period) |
| `CreatorActivity.connection/fetchText` (browseAssets, animationSource, animationFiles refresh) | `DokkanUnitCreator/2.3` | none (Android adds gzip transparently) | Manual, ≤5 (`Too many Eclipse redirects` when depth > 5). Only the **first** URL is checked for https and dokkan-eclipse.com (`Only official Eclipse resource routes are supported`); redirect targets are not re-checked except on the next recursion, which does re-check, so effectively every hop is checked | 20 s / 60 s | caller-supplied byte cap; `File exceeds the supported import size.` | `Eclipse returned HTTP <code>. You can import a local database or resource pack instead.` |
| `PreviewCache.ensure` (animationVisuals metadata, thumb serving) | `DokkanUnitCreator/2.5` | none | **Not followed**: any non-200 → `Eclipse returned HTTP <code>` | 20 s / 60 s | per call (default 160 MB): `Preview resource exceeds 160 MB` | as stated |
| `OfflineLibrary.download` | `DokkanUnitForge/2.7` | `Accept-Encoding: identity` | Manual, hops 0..5. Each hop checked (https, `dokkan-eclipse.com`, no userinfo, no port), else `Eclipse redirected outside its website`. No Location, or still redirecting at hop 5 → `Eclipse redirect could not be followed` | 20 s / 60 s | per call | 404/410 → MissingException (`Not on Eclipse`, counted as skipped). Other non-200 → `Eclipse returned HTTP <code>` |
| `ForgeFixes.checkUpdates` (other spec) | default | HEAD | follow | 15 s | – | – |

There are no retries anywhere. A failed download deletes its temp file.

URL templates used in this area:
* `https://dokkan-eclipse.com/cdn/uncompressed/<Uri.encode(path,"/")>` for downloadAsset
* `https://dokkan-eclipse.com/api/file-browser?path=<Uri.encode(path)>` for browseAssets; OfflineLibrary uses `URLEncoder.encode(folder,"UTF-8")`
* `https://dokkan-eclipse.com/cdn/uncompressed/lua/<path>` for animationSource and OfflineLibrary scripts (path is `ab_script/...lua`, not encoded)
* `https://dokkan-eclipse.com/api/scripts`: animationFiles refresh. Reads `.scripts` (array of strings or `{path}` objects)
* `https://dokkan-eclipse.com/api/card/<id>` and `https://dokkan-eclipse.com/api/effect-pack/<id>[?enemy=0|?enemy=1]`: animationVisuals, OfflineLibrary
* `https://dokkan-eclipse.com/api/card/<id>/fit/sp_name.png?w=1024&h=256&v=3`, `.../fit/sp_phrase.png?w=1024&h=512&v=3`: OfflineLibrary
* `https://dokkan-eclipse.com/api/se?cue=<id>`: OfflineLibrary sound effects
* `https://dokkan-eclipse.com/assets/<encodePath(path)>`: OfflineLibrary folder files (encodePath = per-segment `URLEncoder.encode(seg,"UTF-8").replace("+","%20")`; empty, "." or ".." segment → `Unsafe path`)
* `https://dokkan-eclipse.com/cdn/uncompressed/character/thumb/card_<id>_thumb/card_<id>_thumb.png` with `id = floor(resource_id or id / 10) * 10`: thumbnails (UI `resourceThumb`, OfflineLibrary.pictures)

Encoding helpers in JS:
* Android `Uri.encode(s, "/")` ≈ `s.split("/").map(encodeURIComponent).join("/")` (unreserved `A-Za-z0-9_-!.~'()*` kept; space → `%20`).
  `Uri.encode(s)` with no "/" allowed = `encodeURIComponent(s)`.
* Java `URLEncoder.encode(s,"UTF-8")` = `encodeURIComponent(s).replace(/[!'()~]/g, c => "%" + c.charCodeAt(0).toString(16).toUpperCase()).replace(/%20/g, "+")`.
* Java `URLDecoder.decode(s,"UTF-8")` = `decodeURIComponent(s.replace(/\+/g, " "))`.

### 1.1 AssetDownload.write(conn, dest, exclusive, limit) (exact algorithm)
1. `limit` must be in [1, 167772160], else `Invalid resource size limit.`
2. Temp file `<dest dir>/.download-<uuid>.tmp`.
3. Status ≠ 200 → `Resource download failed.`
4. If `Content-Length` is present it must match `[0-9]+` (`Invalid resource declared size.`) and be ≤ limit
   (`Resource download exceeds160MB.`; the missing space is in the binary).
5. If `Content-Encoding` is present and not `identity` (case-insensitive) → `Unsupported resource HTTP compression.`
6. When exclusive and dest already exists → `This artwork collection already contains that resource.`
7. Stream into the temp file (CREATE_NEW) in 64 KiB chunks. Running total > limit → `Resource download exceeds160MB.`
   Total > declared length → `Resource size does not match its download.` At the end, if a length was declared
   and total ≠ declared → `The resource download was incomplete.`
8. Move the temp file into place: exclusive → plain move, which fails if dest exists; otherwise atomic replace.
9. Return the byte count. The temp file is always deleted.

`AssetDownload.destination(ASSETS, key)`: `GameAssets.safe(key)` and ASSETS must be a real directory, else
`Invalid asset collection.` Create the intermediate dirs one by one (`Cannot create asset collection.`; a symlink
gives `Asset collections cannot use symbolic links.`). A final symlink, or a canonical path outside ASSETS, gives
`Invalid asset destination.`

---------------------------------------------------------------------------------------------------

## 2. Bridge methods

### 2.1 `assets`: list imported files (AssetIndex.list)
Args: `{query?: string, offset?: int, limit?: int}`.
* ASSETS must be a non-symlink directory, else `The imported asset folder is unavailable.`
* `q = query.toLowerCase()` (default ""), `skip = max(0, offset|0)` (default 0), `limit = clamp(limit (default 100), 1, 500)`.
* Depth-first walk of ASSETS. At each level, sort the children by `name + (isDir ? "/" : "")` using Java
  `String.compareTo` (UTF-16 code-unit order). Skip any entry named `_databases` (at any depth) and any symlink.
  Directories recurse. For each file: `key` = path relative to ASSETS with "/" separators. If
  `key.toLowerCase().includes(q)`, then either decrement `skip` (when > 0) or emit. Stop once `limit` rows are
  collected.
* Row: `{key, path, name, size, image}` where
  * `path` = key with its first segment removed (if it contains "/"), then `.replace(/^files\//, "")`. A
    `tutorial0/` prefix is **not** removed.
  * `name` = file name, `size` = bytes (number), `image` = name matches `(?i).*\.(png|jpe?g|webp|gif|bmp)$`.
* Returns a JSON **array**.
UI use: Library "Imported assets" pages (`limit: 41`/`pageSize+1` to detect more), movie pickers (`query:".usm"`,
100 per page), art editors (`query: String(id…)`), battle-pose editor (`query: root, limit: 500`).

### 2.2 `assetUrl`: URL that the UI can load an asset from
Args `{key}` (required). Returns the string `"https://forge.local/local-asset/" + Uri.encode(key, "/")`.
No validation happens here. Validation happens when the URL is fetched (see 3.1).
UI use: `<img src>` for imported previews (app.js `previewImportedAsset`, `projectPreviewUrl`),
`fetch(url)` of a USM in movie-editor (reads `content-length` if present and the whole body; it requires
`response.ok`), and AI-generated art (ai-connect.js).
**iOS:** WKWebView cannot intercept `https://forge.local`. Load the UI from a custom scheme served by a
`WKURLSchemeHandler` (for example `forge://local/index.html`) and return `forge://local/local-asset/<encoded key>`,
so it stays same-origin with the UI. Implement 3.1 in that handler. The UI never hard-codes the
`local-asset` prefix; it always asks `assetUrl`.

### 2.3 `assetStatus`: export attachment audit (ExportAssetAudit.check)
Args `{keys: string[]}` (required).
* `keys.length > 500`, or ASSETS not a real directory → `The attached files could not be checked safely.`
* Per key, in order:
  * A non-string → `Invalid attachment key.`
  * Empty, length > 500, leading "/", or matching `.*[\\:\x00-\x1f\x7f%].*` → `Invalid attachment key.`
  * Any segment that is empty, starts with ".", or is in {_databases, projects, patches, exports} (case-insensitive) → `Invalid attachment key.`
  * A symlink along the path → `Attached files cannot use symbolic links.`
  * A canonical path not under ASSETS → `Invalid attachment location.`
  * Row `{key, bytes: isFile ? length : 0, available: isFile && canRead && 0 < bytes ≤ 536870912}`.
* Returns an array of rows.
UI use: `ForgeExportAudit.check(... assetStatus: keys => Native.call("assetStatus",{keys}))` before export.

### 2.4 `readAsset`: read a small asset as base64 (ImageAssets.read)
Args `{key: string, maxBytes?: number}`. Every failure below gives `IMG_ERR` =
`"Choose a complete supported image (up to 12 MB,4096px per side)."` (no space after the comma) unless stated otherwise.
* `maxBytes` (default 12582912) must be a JSON number with an integral value in [1, 12582912].
* ASSETS must be a non-symlink directory. The key must pass `ImageAssets.safe`, with no symlink on the path,
  canonical path under ASSETS, and a regular file.
* File length > maxBytes → IMG_ERR. Read it whole; reading more than maxBytes → IMG_ERR.
* Inspect by extension of the key, lower-cased:
  * `.json` → `DecorationStorage.inspect(bytes)` (2.8). Errors use the decoration message.
  * `.lwf` → requires `length ≥ 16`, `length ≤ 12 MB` and magic bytes `4C 57 46 00` ("LWF\0").
    Result `{width:0, height:0, mime:"application/octet-stream"}`.
  * otherwise `ImageAssets.inspect(bytes, strict=false)` (section 5.1).
* Returns `{width, height, mime, key, base64: <standard base64 with padding>, bytes: <length>}`.
UI use: art editor and studio (`maxBytes: MAX_BYTES`), export audit decoration reading (`maxBytes:131072`), and
guided/battle-pose editors that decode `base64` to bytes.

### 2.5 `downloadAsset`: save one Eclipse file into ASSETS
Args `{path: string, group?: string}`.
1. `CreatorActivity.safePath(path)` and the extension regex in 0.3, else `Choose a supported resource file`.
2. If `group` is present (not null), it must match `^art-download-[0-9]{10,16}-[A-Za-z0-9_-]{6,64}$`, else
   `Invalid artwork collection.`
3. `key = (group ?? "eclipse") + "/" + path`, then `dest = AssetDownload.destination(ASSETS, key)`. This applies
   GameAssets.safe to the whole key, so PRIVATE names and DB extensions are refused here with `Invalid asset collection.`
4. GET `https://dokkan-eclipse.com/cdn/uncompressed/` + `Uri.encode(path,"/")` via openOfficial (section 1).
5. `AssetDownload.write(conn, dest, exclusive = group != null, 167772160)`. Without a group an existing file is
   replaced. With a group, an existing file gives `This artwork collection already contains that resource.`
6. Returns `{key, path, name: <file name>, size: <bytes written>, image: <image regex on path>}`.
UI use: the Library online browser (`{path}`) and the art/battle-pose editors, which pass
`group = "art-download-" + Date.now() + "-" + random`. They verify `saved.key.startsWith(group + "/")` and
`saved.size == listing size`. The movie editor downloads a `.usm` and then fetches it via `assetUrl`.

### 2.6 `browseAssets`: Eclipse online folder listing (proxy)
Args `{path?: string}` (default "").
* A non-empty path must pass `CreatorActivity.safePath`, else `Invalid resource path`.
* GET `https://dokkan-eclipse.com/api/file-browser?path=` + `encodeURIComponent(path)` through fetchText with an
  8 MB cap (8388608). Parse it as a JSON object and return it **unchanged**.
* Expected server shape (inferred from UI and GameDirectory): `{path, parentPath?, items:[{type:"directory"|"file",
  name, path (full path from root), size?}], error?}`. The UI throws `data.error` when present and requires
  `Array.isArray(items)`.
* Offline: no cache. Any network error propagates.

### 2.7 `storeAsset`: save a PNG (ImageAssets.store)
Args `{data: base64 string, name?: string}`.
* `data` must be a string with `length ≤ 16777216`, `length % 4 == 0` and matching `[A-Za-z0-9+/]*={0,2}`. It must
  decode, and re-encoding must give the identical string (canonical base64), else IMG_ERR.
* `inspect(bytes, strict=true)` (section 5.1): PNG only, else `Artwork edits must be PNG images.`
* ASSETS must be valid. `mkdir ASSETS/generated-<uuid>` (failure gives IMG_ERR), then write `image.png` (CREATE_NEW).
  On failure, delete the file and the dir.
* `name = (name ?? "Custom artwork")` with `[\x00-\x1f\x7f]` removed, cut to 160 chars.
* Returns `{width, height, mime:"image/png", key:"generated-<uuid>/image.png", path:"image.png", name, size:<decoded bytes>, image:true}`.

### 2.8 `storeDecoration`: card decoration JSON (DecorationStorage)
Args `{text: string}`. `DEC_ERR` = `"The card decoration metadata is invalid. Import its original artwork again."`
* `text` must be a string of length ≤ 131072 chars. Bytes = UTF-8.
* `inspect(bytes)`:
  1. 1 ≤ length ≤ 131072. Strict UTF-8 decode (a malformed sequence gives DEC_ERR), then `trim()`.
  2. Bracket scan outside strings: `"` toggles string mode, `\` escapes the next char inside a string, `{`/`[`
     increase depth (depth > 32 gives an error), `}`/`]` decrease it (depth < 0 gives an error). At the end the
     string must be closed, depth must be 0, and the text must start with "{" and end with "}".
  3. Parse a single JSON object with nothing after it.
  4. `card_id` is a JSON number with an integer value in [1, 2147483647].
  5. `shader_file` (getString) passes DecorationStorage.safe.
  6. `parameters` is an array with ≤ 128 objects. Each has string `type` and string `name`. If
     `type == "sampler2D"`, `value` must be a string that passes DecorationStorage.safe.
  7. Returns `{width:0, height:0, mime:"application/json"}`.
* ASSETS must be valid. Create `generated-decoration-<uuid>/decoration.json` (CREATE_NEW). On failure, delete both.
* Returns `{width:0,height:0,mime:"application/json", key:"generated-decoration-<uuid>/decoration.json",
  path:"decoration.json", name:"Custom card decoration", size:<bytes>, image:false}`.

### 2.9 `storeLwf`: custom LWF (LwfStorage)
Args `{data: base64, name?: string}`. `LWF_ERR` = `"Choose a complete, uncompressed supported LWF animation up to 12 MB."`
* Same strict base64 rules as storeAsset (length ≤ 16777216). A decode exception gives LWF_ERR.
* `inspect(bytes)` (section 5.3) gives `{mime:"application/octet-stream", width, height}`.
* Write `generated-lwf-<uuid>/animation.lwf`. Name default `"Custom character animation"` (sanitized, max 160).
* Returns `{mime, width, height, key:"generated-lwf-<uuid>/animation.lwf", path:"animation.lwf", name, size, image:false}`.

### 2.10 `storeMovie`: chunked USM upload (MovieStorage.call)
There is one MovieStorage instance per activity, created on first use with root = canonical ASSETS. It holds an
in-memory `jobs` map `uploadId → {name, bytes, touched}`. All calls are synchronized.
Errors are prefixed `"Movie: "`.

Construction:
* staging = `ROOT/.forge-movie-uploads-v1`. If it is created now, write `.owner` with exactly
  `"Dokkan Unit Forge movie uploads v1\n"` (35 bytes, CREATE_NEW).
* Every path component of ASSETS and staging must be a real directory, else `Movie: The private movie folder is unsafe.`
* `.owner` must be a regular file of 35 bytes with that content, else `Movie: The private upload folder is not owned by this app.`
* An unlistable folder gives `Movie: The private upload folder is unavailable.`
* Delete stale files matching `upload-<uuid v4>\.part`.

Every call:
* Re-check the directories.
* Expire jobs whose `now - touched ≥ 600000` ms (10 min). Expiry deletes the part file.
* `action` must be a string, else `Movie: Choose a valid movie upload action.` Allowed keys per action:
  `begin {action,name}`, `append {action,uploadId,offset,data}`, `finish|cancel {action,uploadId}`. Any extra key
  gives `Movie: Invalid movie upload arguments.` An unknown action gives `Movie: Invalid movie upload action.`

Actions:
* `begin`:
  * More than 3 jobs already open (4 or more) → `Movie: Finish or cancel another movie upload first.`
  * If `name` is present it must be a string of ≤ 160 chars, else `Movie: Choose a movie name of 160 characters or less.`
  * Name = optString default `"Custom movie"`, control chars removed; an empty result becomes `"Custom movie"`.
  * `uploadId` = random UUID v4 (lower-case, with dashes). Create an empty `staging/upload-<id>.part` (CREATE_NEW).
  * Returns `{uploadId}`.
* `append`, `finish` and `cancel` first check that `uploadId` is a string matching
  `[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}` and is in `jobs`, else
  `Movie: This movie upload expired or was canceled. Start it again.`
* `cancel`: discard (remove the job, delete the part file). Returns `{canceled:true}`.
* `append`:
  * `offset` must be an integral number equal to `job.bytes`, else
    `Movie: Movie chunks must arrive in their original order. Retry this chunk.`
  * `data` must be a string that is non-empty, ≤ 349528 chars, `%4==0` and canonical base64, decoding to
    1..262144 bytes, else `Movie: Invalid movie chunk.`
  * If `job.bytes + n > 100663296` (96 MB), or the sum of all jobs' bytes + n > 402653184 (384 MB): discard, then
    `Movie: Movie uploads are limited to 96 MB per movie and 384 MB total.`
  * The part file must be regular, not a symlink, and have length == job.bytes, else
    `Movie: The temporary movie file changed.` (the job is discarded on any error here).
  * Write at offset job.bytes and fsync. Then `job.bytes += n`, `touched = now`. Returns `{bytes: job.bytes}`.
* `finish`:
  * Same part-file check as append.
  * `info = inspect(part)` (section 6, the USM validator).
  * `mkdir ASSETS/generated-movie-<uuid>` (failure gives `Movie: The movie destination is unavailable.`). Atomically
    move the part file to `movie.usm` and remove the job.
  * Returns `info + {storageTag: uploadId without "-", key:"generated-movie-<uuid>/movie.usm", path:"movie.usm",
    size: job.bytes, name: job.name, image:false}`, where `info = {width, height, frames, rate:{n,d}, preservedAudio}`.
  * On error: discard the job, delete the created dir if any, rethrow.
UI use: movie-editor.js sends 256 KiB chunks (`CHUNK = 256*1024`) and cancels on abort.

### 2.11 `animationFiles`: list of Lua animation script paths
Args `{refresh?: bool, sourceDatabase?: string}`. `sourceDatabase == "sparking"` is handled by
`sparkingAnimationFiles` (section 9.4). Eclipse flow:
1. `cacheFile = ROOT/animation-files.json`, `set = sorted set`, `offline = PreviewCache.offline()`
   (preview-cache/settings.json `offline` flag).
2. If the cache file exists and (`!refresh` or `offline`), add its entries.
3. If `refresh && !offline`, fetch `https://dokkan-eclipse.com/api/scripts` (2 MB cap) and add `json.scripts`.
   Errors propagate.
4. If the set is still empty and the cache exists, try adding the cache again, ignoring errors.
5. If the set is still empty, add the packaged list from `ui/data/preview-script-index.json`.
   * It must have `schemaVersion == 1`, else `Update Dokkan Unit Creator to load the packaged animation catalog`.
   * An empty list gives `The packaged animation catalog is empty`.
   * More than 2 MB of file gives `The packaged script index is too large`.
6. Write the cache as a JSON array of the sorted set. This happens before step 7, so imported scripts are not
   cached.
7. Add imported scripts (`PreviewScripts.imported(ASSETS, set)`):
   * Fails with `Invalid imported animation folder` when ASSETS is a symlink or not a directory, with
     `Imported animations cannot be read` when it cannot be listed, and with
     `Too many imported animation collections` above 4096 entries.
   * For each collection dir C with a GameAssets.safe name, walk `C/lua/ab_script`, `C/files/lua/ab_script` and
     `C/tutorial0/lua/ab_script` to depth ≤ 24 and at most 50000 entries
     (`The imported animation catalog exceeds its 50,000-entry limit`).
   * Add `ab_script/<rel>` for each file with 0 < size ≤ 2 MB that passes `valid`.
   * Symlinks give `Imported animations cannot use symbolic links`.
8. Returns a JSON array of path strings, sorted with Java String order.

`PreviewScripts.add(set, arr)`: each item is a string, or an object's `path`. Valid when length < 240, matches
`(?i)ab_script/[a-z0-9_/-]+\.lua` (full match) and passes `GameAssets.safe`.
The cache file is deleted whenever the active database changes (`useDb`).
UI use: studio.js (`{refresh, sourceDatabase}`), offline.js, guided.js. `ForgeMotion.pathFor(script, files)` maps
DB script names to paths.

### 2.12 `animationSource`: text of one Lua animation script
Args `{path: string, assetKey?: string, originalOnly?: bool, sourceDatabase?: string}`. With
`sourceDatabase=="sparking"`, see section 9.4.
1. `validAnimationPath(path)`: length < 240, matches `(?i)ab_script/[a-z0-9_/-]+\.lua` and passes
   CreatorActivity.safePath. Otherwise `Choose an animation from the browser`.
2. Unless `originalOnly`, try the imported asset:
   * `GameAssets(ASSETS, preferredKey = assetKey || null).read("lua/" + path, 2097152)` (section 4.2).
   * If found: decode UTF-8. Text that is empty after trim, starts with "<" after trim, or contains a NUL gives
     `Unreadable imported animation file`.
   * Otherwise return `{path, text, cached:true, local:true}`.
3. Otherwise use the remote cache:
   * `meta = GameDataStore.meta()`.
   * `sourceKey = (meta.date || meta.sha256 || "bundled")` with `[^a-zA-Z0-9_-]` removed, cut to 80 chars.
     optString semantics apply: the first non-missing key wins, and a missing `date` falls back to `sha256`.
   * `file = ROOT/animation-sources/<sourceKey>/<path>`. If it exists, read it (2 MB cap). Otherwise fetch
     `https://dokkan-eclipse.com/cdn/uncompressed/lua/<path>` (2 MB cap).
   * Text that is empty after trim, starts with "<", or contains NUL → `Unreadable animation file`.
   * If it was fetched, create the dirs and write it.
   * Returns `{path, text, cached: <existed before>}`.

### 2.13 `animationCatalog`: searchable list of DB animation moves
Args `{search?, kind? = "all", unitId?, offset?, sourceDatabase?}`.
* Select the main DB, or the Sparking DB when `sourceDatabase=="sparking"`, and the matching `schema`
  (an object keyed by table name; built at DB open from `PRAGMA table_info`).
* Load the bundled `ui/data/animation-queries.json` (≤100000 bytes): an array of `{tables:[...], sql}`. Keep
  the `sql` of entries whose every table exists in the schema. With none left, return `{items:[], more:false}`.
* Build `SELECT * FROM (<sql1> UNION ALL <sql2> ...)` with conditions joined by ` AND ` after ` WHERE `:
  * search (cut to 100 chars) non-empty: `(unitName LIKE ? OR moveName LIKE ?)` with `%s%` twice
  * kind ≠ "all": `kind=?`
  * `unitId > 0`: `unitId=?` (bound as a string)
* Append ` ORDER BY unitId=0, unitName, moveName, unitId, key LIMIT ? OFFSET ?` with bind values `"13"` and
  `offset = clamp(offset, 0, 100000)`.
* Each row is an object of all columns (INTEGER → number, FLOAT → number, NULL → null, others → string). Columns
  produced by the bundled SQL: `key, kind, viewId, script, unitId, unitName, moveName, description, resourceId,
  rarity, relationId, sourceTable`. Sparking rows also get `sourceDatabase:"sparking"`.
* `more` = rows > 12. If so, drop index 12.
* Returns `{items, more, offset}`.
UI use: studio.js browser, offline.js (`kind:"all"`, pages of 12, up to offset 48).

### 2.14 `animationVisuals`: the LWF packs for a card
Args `{unitId}`. `unitId < 1` gives `Choose a character`.
* `meta = PreviewMetadata.resolve(ctx, PreviewCache(ROOT), "https://dokkan-eclipse.com/api/card/<id>", "")`. This is
  the preview-spec resolver. Here it means: local imported metadata (GameMetadata.resolve, section 7.2) merged with
  the Eclipse JSON fetched through PreviewCache.text(url, 1 MB) (cached in preview-cache, so it works offline once
  downloaded).
* For `[["battle","Battle poses"],["idle","Idle poses"],["sp","Attack poses"],["card_bg","Animated card background"]]`:
  `rel = meta[k]?.rel`. If rel matches `(?i)[a-z0-9_./-]+\.lwf` and passes safePath, push
  `{name: meta.name + " · " + label, path: rel}` (the separator is U+00B7 with spaces).
* If `meta.aura_effect_id > 0`, also resolve `https://dokkan-eclipse.com/api/effect-pack/<aura_effect_id>`. When its
  `lwf.rel` is valid, push `{name: meta.name + " · Aura", path: rel, scene: pack.scene_name}`. Any exception in the
  aura part is swallowed.
* Returns `{items}`.

### 2.15 `offlineLibrary`: offline downloads (OfflineLibrary.dispatch)
Args `{action: "status"|"start"|"pause"|"resume"|"cancel"|"wifiOnly", ...}` (default "status").
There is one static job per process. The preferences file is `forge-offline` with keys `wifiOnly` (default true),
`movies` (default false) and `completed` (JSON string, default "{}").
* `start`:
  * A job is running and not finished → `A download is already running. Pause or cancel it first.`
  * `packs` missing or empty → `Choose what to download.`
  * Store `wifiOnly = args.wifiOnly ?? true` and `movies = args.movies ?? false`, create a Job, run it on a daemon
    thread, and keep the screen on (iOS: `isIdleTimerDisabled = true`).
  * Other args: `cards: number[]` (≤400 used), `scripts: string[]` (≤2000), `moviePacks: number[]` (≤400).
* `pause` / `resume` set `job.paused` (no-op without a job). `cancel` sets `cancelled = true`, `paused = false`.
* `wifiOnly`: `value ?? true` is stored and applied to the running job.
* After any action: when the job is finished, the screen-on flag is cleared.
* Returns status:
```
{ wifiOnly, movies, completed: {<pack>: {at: epochMs, failed: n}},
  network: {connected: bool, metered: bool} | {unknown:true},
  job?: {running: !finished, paused, cancelled, finished, phase, label, waiting, total, done, failed, skipped,
         savedBytes, error, packs:[...], startedAt, finishedAt, failures:[first 20 strings]},
  storage: {bytes, count, maxBytes, free} }
```
  * While a job runs with `limit > 0`, `storage = {bytes: job.used, maxBytes: job.limit, free}`.
  * Otherwise a background scan (at most every 15 s) sums the `*.body` files in preview-cache, giving
    `{bytes, count, maxBytes: readLimit}`. Before the first scan completes this is `{maxBytes}` only. `free` = usable
    bytes on the volume. Any exception gives `{}`.

Job algorithm (packs = essentials | units | everything; `ORIGIN = https://dokkan-eclipse.com`):
* Uses a pool of 4 worker threads. Every queued task increments `total`. When it ends, `done++`. Outcomes:
  MissingException gives `skipped++`. Another error gives `failed++` and appends `"<label>: <msg>"` to failures
  (≤200 kept). StorageFull sets `error` and cancels the job. Cancelled stops quietly.
* `gate()`, before every network request, loops:
  * cancelled → throw Cancelled
  * paused → `waiting="Paused"`, sleep 500 ms
  * not connected → `"Waiting for an Internet connection"`, sleep 3 s
  * wifiOnly and the network is metered → `"Waiting for Wi-Fi (Wi-Fi only is on)"`, sleep 3 s
  * wifiOnly and the network state is unknown → `"Can't check for Wi-Fi. Turn off Wi-Fi only to continue."`, sleep 3 s
  * otherwise `waiting=""`.
  * iOS: use `NWPathMonitor` (`status == .satisfied`; `isExpensive || isConstrained` = metered).
* `prepare()`:
  * `PreviewCache.settings({})` gives `used = bytes`, `limit = maxBytes`.
  * `sourceKey` is computed as in animationSource.
  * `database = GameDataStore.current()`, falling back to `ROOT/bundled-database.db`.
  * `effectIds = SELECT id, category FROM effect_packs`.
  * DB errors are added to failures as `"Database: <msg>"`.
* Budget (`reserve(bytes)` before writing each file):
  * Free space minus bytes < 400 MB → StorageFull `"Your phone is almost out of space. Free some space, then tap Download again."`
  * If `used + bytes > limit - 256 MB`:
    * rescan `used` from the *.body files
    * pick the first budget B in [512MB, 1, 2, 4, 8, 16, 32 GB] with `B ≥ used + bytes + 512 MB`
    * if there is none → StorageFull `"Downloaded previews reached the 32 GB limit. Clear some downloads first."`
    * otherwise write it with `PreviewCache.settings({maxBytes:B})`
  * Then `used += bytes`. `release` subtracts.
* `save(url, max)`:
  * A relative url gets the ORIGIN prefix.
  * Return 0 if already saved.
  * Otherwise `gate()`, then `download(cacheRoot, url, max, budget)` (section 8.2), and add the result to `savedBytes`.
* `json(url)` = `save(url, 4 MB)`, then parse the saved body (≤4 MB). Not saved → `Not saved`.
* `file(url,max)`: dedupe on `seen`, then queue a task labelled with the url's last path segment.
* `folder(f)`: dedupe on `"folder:"+f`.
  * The task reads `json(ORIGIN + "/api/file-browser?path=" + URLEncoder(f))` and, for up to 400 items with
    `type=="file"`, takes `path = item.path` (if it contains no "/", `f + "/" + path`).
  * Paths matching `(?i)[a-z0-9_./ -]+\.(lwf|png|jpe?g|webp|json)` are queued as
    `file(ORIGIN + "/assets/" + encodePath(path), 160MB)`.
* `folderOf(rel)` = the part before the last "/" if that slash is at index > 0 and rel matches `(?i)[a-z0-9_./-]+`,
  else null.
* Phases, in order:
  1. If any of essentials, units or everything is selected:
     * **"Animation player"**: PreviewTools prepare (other spec). It waits up to 15 min while `preparing` and sets
       label `"Player files <preparedFiles> of <totalFiles>"`. If it is not ready, the failure is
       `"Animation player: some player files could not be saved. Download again to retry."`.
     * **"Animation scripts"**: for each path in `ui/data/preview-script-index.json` matching
       `(?i)ab_script/[a-z0-9_/-]+\.lua` without ".." and with no local `animation-sources/<sourceKey>/<path>` yet:
       * gate, then `openOfficial(ORIGIN+"/cdn/uncompressed/lua/"+path)`, reading ≤2 MB (`Script is too large`).
       * Text that is empty, starts with "<" or contains NUL counts as Missing. An "HTTP 404" error counts as Missing.
       * Write `<file>.part`, then rename (`Could not save script`).
       * Then wait until idle.
     * **"Character pictures"**: for each row of
       `SELECT DISTINCT (COALESCE(NULLIF(resource_id, 0), id) / 10) * 10, 0 FROM cards WHERE id < 9000000`
       with id > 0, queue the thumbnail URL (max 4 MB). Then wait until idle.
     * `complete("essentials")`.
  2. `units` without `everything`:
     * **"Your characters"**: `card(id)` for each of the args `cards`, then wait until idle.
     * **"Your animations"**:
       * paths = `ab_script/common/common.lua` + every index path starting `ab_script/ab_sys/` + args `scripts`
       * `scriptAssets(paths)`
     * **"Movies in your animations"**: `effect(id, withMovie=true)` for each moviePack, then wait until idle.
     * `complete("units")`.
  3. `everything`:
     * **"Every animation effect"**: `SELECT id, category FROM effect_packs ORDER BY id`. Category 5 is skipped
       unless movies is on. Run `effect(id)`, then wait until idle.
     * **"Every animation sound"**: `scriptAssets(all index paths)`.
     * **"Every character"**: `card(id)` for `SELECT id, 0 FROM cards WHERE id < 9000000 AND id % 10 IN (0, 1) ORDER BY id`,
       then wait until idle.
     * `complete("everything")`, and `complete("movies")` if movies is on.
  4. Final phase: `"Cancelled"` or `"Done"`. An exception sets `phase "Stopped"` and `error = msg`.
  5. Finally:
     * shut down the pool, waiting up to 75 s
     * clear the screen-on flag, `label=""`, `waiting=""`, `finished=true`, `finishedAt`
     * reset the storage-scan timer
     * delete `[a-f0-9]{64}\.j?part\d+` files in preview-cache
* `complete(pack)` throws Cancelled if the job was cancelled. Otherwise it sets
  `completed[pack] = {at: now, failed: failed}` in the prefs.
* `card(id)` (1..99999999, deduped as `"card:"+id`):
  * `json(ORIGIN+"/api/card/"+id)`. If `found` is false, stop.
  * For each of `battle, idle, sp, card_bg`: `folder(folderOf(obj.rel))`.
  * For each `textures[*].url` that starts with `/assets/` or `/api/card/`: `file(ORIGIN+url, 160MB)`.
  * `file(.../api/card/<id>/fit/sp_name.png?w=1024&h=256&v=3, 8MB)` and `.../fit/sp_phrase.png?w=1024&h=512&v=3`.
  * If `aura_effect_id > 0`: `effect(aura)`.
* `effect(id, withMovie = job.movies)` (deduped as `"effect:"+id+(withMovie?":movie":"")`):
  * For each form of `"" | "?enemy=0" | "?enemy=1"`: `pack = json(ORIGIN+"/api/effect-pack/"+id+form)`.
    Missing → continue. `found` false → continue.
  * `folder(folderOf(pack.lwf?.rel))`.
  * If withMovie and `pack.usm.url` starts with `/assets/`: `file(ORIGIN+url, 160MB)`.
* `scriptAssets(paths)`: for each local script file (2 MB cap):
  * Collect constants with `(?m)^\s*([A-Za-z_]\w*)\s*=\s*(\d{1,9})\s*;?`.
  * `entryEffect\w*\s*\(([^,()]*(?:\([^()]*\))?[^,()]*),\s*([A-Za-z_]\w*|\d{1,9})`: group 2 is a number or a
    constant. If it is in effectIds, `effect(id)`.
  * `setupMovie\s*\(...same...)`: `effect(id, true)`.
  * `playSe\w*\s*\(...same...)`: `file(ORIGIN+"/api/se?cue="+id, 32MB)`.
  * Errors are added to failures as `"<path>: <msg>"`. Then wait until idle.
UI use: offline.js polls `status` and shows `completed[pack].at`/`failed`, the progress bar `done/total`,
`waiting` and failures.

### 2.16 `cardIndex`: compact card list for the finder (ForgeFixes.cardIndex)
No args. `Game data is not ready yet.` if the DB is not open (`The app is still starting.` when there is no
activity).
* Read `PRAGMA table_info(cards)`. Missing required columns {id, name, hp_max, passive_skill_set_id,
  leader_skill_set_id} give `This game data has no <col> column.`
* Wanted columns, in order: `id, name, rarity, element, open_at, hp_max, atk_max, def_max, resource_id,
  passive_skill_set_id, leader_skill_set_id, optimal_awakening_grow_type`. Use `NULL` for absent columns.
* SQL: `SELECT <cols> FROM cards WHERE id % 10 = 1 AND ((id >= 1000000 AND id < 3000000) OR id >= 10000000) AND hp_max > 300 AND passive_skill_set_id IS NOT NULL AND leader_skill_set_id IS NOT NULL ORDER BY id`
* Each row is an array: `[id, name||"", rarity||0, element||0, openYYYYMMDD, hp||0, atk||0, def||0, resource||0,
  passive, leader, grow|null]`.
  * `openYYYYMMDD` = the first 10 chars of open_at with "-" removed, parsed as an integer when it is 8 digits,
    else 0.
  * `passive` and `leader` use getLong, so NULL becomes 0. They cannot be NULL here because of the WHERE clause.
* Returns an array of arrays. UI finder.js caches it in localStorage and falls back to paging `query` if this fails.

---------------------------------------------------------------------------------------------------

## 3. Request interception (main WebView), then the iOS scheme handler

Main WebView origin: `https://forge.local`, starting at `https://forge.local/index.html`. The settings disable
file and content access, set mixed content to NEVER, and enable DOM storage.

### 3.1 `shouldInterceptRequest` (CreatorActivity$AnonymousClass1)
1. First `ForgeFixes.intercept(request)` → `OfflineLibrary.intercept` (3.2). If that returns a response, use it.
2. If the host is `forge.local`:
   `p = url.getPath().substring(1)` (URL-decoded), and `""` becomes `index.html`.
   * `p` starts with `local-asset/`: `file = assetFile(p.substring(12))`.
     * `assetFile(key)`: `safePath(key)`, else `Invalid asset key`.
     * `new File(ASSETS, key)`; a canonical path not under ASSETS gives `Unsafe path`.
     * The body is a stream of the whole file.
   * otherwise: `safePath(p)` is required, and when `p` starts with `data/` only these are allowed:
     `data/mechanics.js`, `data/guide-data.js`, `data/animation-availability.js`, `data/movie-catalog.js`,
     `data/sparking-reference.json`. Anything else gives `Unavailable resource`. Serve the bundled `ui/<p>`.
   * MIME from `CreatorActivity.mime(p)` (lower-cased suffix):
     `.wasm` application/wasm, `.html` text/html, `.js` application/javascript, `.css` text/css,
     `.json` application/json, `.png` image/png, `.svg` image/svg+xml, `.jpg/.jpeg` image/jpeg, `.webp` image/webp,
     `.gif` image/gif, else application/octet-stream.
   * Encoding is "UTF-8" if the mime starts with `text/` or the path ends `.js`, else none.
   * The response is 200 (Android default) with no extra headers and no Range support.
   * Any failure gives **404** "Not Found", `text/plain`, an empty body and no headers. The decompiled try only
     shows the substring, but the "Unavailable resource" throw only makes sense if the handler covers the whole
     block.
3. Other hosts are not intercepted (normal network). `shouldOverrideUrlLoading` blocks navigation to any host
   other than forge.local (it returns true for those).

Note that local-asset does **not** restrict the extension or the `_databases`/PRIVATE names. It only uses
CreatorActivity.safePath. `.usm`, `.lwf` and so on are served as `application/octet-stream`.

### 3.2 OfflineLibrary.intercept (main-screen thumbnails)
* Only `GET` requests whose url starts with `https://dokkan-eclipse.com/cdn/uncompressed/character/thumb/` and ends
  with `.png`.
* If `PreviewCache.cachedBody(url)` exists, return `PreviewCache.response(request)` (3.3). That gives offline and
  instant thumbnails.
* Otherwise return null (the WebView loads from the network). When not in offline mode, and the saver queue
  (1 thread, capacity 300) has room and the url is not already queued, queue a background save:
  `if folderBytes(preview-cache) < limit - 64 MB: download(cacheRoot, url, 4 MB, no budget)`.
  `folderBytes` is cached for 60 s. Errors are ignored.

### 3.3 PreviewCache.response(request) (also used by the preview server)
* Headers: `Access-Control-Allow-Origin: *`, `Accept-Ranges: bytes`, `Cache-Control: no-store`.
* Anything other than GET or HEAD → 405, text/plain "Method not allowed" (reason "Unavailable").
* `ensure(url)` downloads if needed. The mime is the `type` from the .json, up to the first `;`, and the encoding is
  null.
* Range: header `Range` or `range` must match `bytes=([0-9]+-[0-9]*|-[0-9]+)`, and the file must be non-empty.
  * `start-[end]` gives end = min(end, len-1).
  * `-N` (N>0) gives start = max(0, len-N).
  * A start ≥ len or end < start is invalid.
  * The result is 206 with `Content-Range: bytes s-e/len`.
* `Content-Length` = e-s+1. HEAD gets an empty body.
* Any exception → **503**, text/plain body = the exception message.

### 3.4 iOS mapping
* WKWebView cannot intercept `https://` URLs. Serve the UI and assets through a `WKURLSchemeHandler` on a custom
  scheme (for example `forge`) and have `assetUrl` return that scheme. Implement Range in the handler as in
  GameAssets.response (4.3) so `<video>`/`<audio>` and partial fetches work.
* The thumbnails are plain `<img src="https://dokkan-eclipse.com/...thumb.png">` in the UI (app.js `resourceThumb`).
  To keep the offline and instant behaviour, either inject a small user script that rewrites such `src` values to
  `forge://local/eclipse-cache?u=<encoded url>` (the handler serves the cached body, or fetches it, caches it and
  returns it), or accept network loading backed by WKWebView's HTTP cache.

---------------------------------------------------------------------------------------------------

## 4. GameAssets (imported-resource resolver used by previews, animationSource and BGM)

`new GameAssets(root = ASSETS, preferredKey?, overlays?: JSONArray)`.

### 4.1 gamePath(url)
1. Parse the URI (a failure gives null). If `path` contains "\\" or matches `(^|/)\.{1,2}(/|$)` → null.
2. Resolve against `https://dokkan-eclipse.com`. The scheme must be https, the host `dokkan-eclipse.com` or
   `cdn.dokkan-eclipse.com`, with no userinfo and no port.
3. A path starting `/cdn/uncompressed/` gives the rest after 18 chars. A path starting `/assets/` gives the rest
   after 8 chars. Anything else → null.
4. The result must pass `safe` and `PREFIX`, else null.

### 4.2 resolve(url) → File | null, and read(path, max)
1. `gp = gamePath(url)`. If null, return null.
2. `overlay = overlayMap(overlays)` (map gamePath → assetKey, see below).
   * `target = overlay[gp]`.
   * If there is none, search the overlay entries where both key and value end with `.cpk` and
     `gp.startsWith(key minus ".cpk" + "/")`. Take the longest such prefix:
     `target = value minus ".cpk" + "/" + gp.substring(prefix.length)`. An overlay CPK aliases its expanded folder.
3. `forced = target != null || (preferredKey && (preferredPath(preferredKey) == gp || preferredPath(preferredKey) == fontFallback(gp)))`.
4. If ASSETS does not exist: forced → `The selected imported asset is unavailable. Choose it again.`, else null.
   ASSETS a symlink or not a dir → `Invalid imported resource folder`.
5. forced: `f = regular(target ?? preferredKey)`. Null gives the "unavailable… Choose it again." error. Return f.
6. Not forced:
   * List the collection dirs (safe name, real dir). Sort them newest first by `lastModified` desc, then by name asc.
   * For each dir D, try `regular(D/gp)`, `regular(D/files/gp)`, `regular(D/tutorial0/gp)`. Return the first hit.
   * Then, if `fontFallback(gp)` is non-null, repeat with that path.
   * Return null.
7. `regular(rel)`:
   * walk the segments; a symlink gives `Imported game assets cannot use symbolic links`, a missing segment gives null
   * the result must be a regular file, else null
   * size > 160 MB → `Imported game asset exceeds the 160 MB preview limit`
   * a canonical path outside ASSETS → `Imported game asset escapes its resource folder`
8. `fontFallback(p)`: for `fonts/X.(otf|ttf)` not already under `fonts/default/`, returns `fonts/default/X`.
9. `preferredPath(key)`:
   * `safe(key)` is required, else `Invalid selected game asset`.
   * Split on "/" (at least 2 segments). Drop the first (the collection), then a leading `files`, then a leading
     `tutorial0`. Join.
   * The result must pass safe and PREFIX, else `Invalid selected game asset`.
10. `read(p, max)`:
    * `safe(p) && PREFIX`, else `Invalid game asset path`.
    * `f = resolve("/assets/"+p)`. Null → return null.
    * `max` < 0, > 160 MB, or file length > max → `Imported game asset exceeds the supported size`.
    * Read; going over max while reading gives `Imported game asset changed or exceeds the supported size`.

`overlayMap(arr)` (preview "assets" manifest `[{path, key}]`):
* null → empty map. More than 2000 entries → `Invalid preview asset manifest`.
* Each entry: `path` must equal `gamePath("/assets/"+path)`, and `key` must pass safe and have ≥ 2 segments, else
  `Invalid preview asset alias`.
* The lower-cased extensions of path and key must be equal and match
  `png|jpe?g|webp|gif|bmp|lwf|lua|usm|cpk|kks|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|fsh|vsh|fnt|ttf|otf|strings|txt|bin`,
  else `Preview aliases need matching supported resource types`.
* Duplicate `path`s (NFC + lower case) → `Conflicting preview asset aliases`.
* Insertion order is kept.

### 4.3 GameAssets.response(request) (preview WebView `/assets/...` and `/cdn/uncompressed/...`)
* `resolve(url)`. Null → not handled.
* Headers: `Accept-Ranges: bytes`, `Cache-Control: no-store`, `Cross-Origin-Resource-Policy: same-origin`.
* Anything other than GET or HEAD → 405 "Method Not Allowed", text/plain, `Content-Length: 0`.
* Range: regex `^bytes=(\d*)-(\d*)$`.
  * With a start: s = start, e = min(len-1, end?). Invalid if s ≥ len or e < s.
  * Suffix: N > 0 and len > 0 are required; s = max(0, len-N), e = len-1.
  * Invalid → 416 "Range Not Satisfiable", `Content-Range: bytes */len`, `Content-Length: 0`.
  * Otherwise 206 "Partial Content" with `Content-Range: bytes s-e/len`.
* The body is read fully into memory, empty for HEAD. `Content-Length` = e-s+1.
* MIME from `GameAssets.mime(name)` (lower-cased extension):
  * images: bmp→image/bmp, gif→image/gif, jpg/jpeg→image/jpeg, png→image/png, webp→image/webp
  * video: m1v/m2v→video/mpeg, m4v/mp4→video/mp4, webm→video/webm
  * audio: mp3→audio/mpeg, ogg→audio/ogg, wav→audio/wav
  * fonts: otf→font/otf, ttf→font/ttf
  * text: fnt, fsh, vsh, lua, txt → text/plain
  * data: json→application/json, xml→application/xml
  * everything else → application/octet-stream
* Encoding is "UTF-8" for text/*, application/json and application/xml.

---------------------------------------------------------------------------------------------------

## 5. Binary format validators

### 5.1 ImageAssets.inspect(bytes, strict)
The input must be 12 ≤ length ≤ 12582912. `dimensions(w,h,mime)` requires 1 ≤ w,h ≤ 4096 and w*h ≤ 16,000,000.
All errors give IMG_ERR unless stated otherwise.
* **PNG** (signature `89 50 4E 47 0D 0A 1A 0A`). Chunks start at pos=8; loop while pos+12 ≤ len:
  * `len = u32be(pos)`. A value > 12582912, or pos+12+len > total, is an error.
  * `type` = 4 ASCII bytes at pos+4 and must match `[A-Za-z]{2}[A-Z][A-Za-z]`.
  * strict: a critical chunk (first letter upper case) other than IHDR, IDAT or IEND is an error. PLTE is therefore
    rejected.
  * The CRC32 over `type + data` must equal `u32be(pos+8+len)`.
  * The first chunk must be IHDR with len 13. A later IHDR is an error.
    * Take `w = u32be(pos+8)`, `h = u32be(pos+12)`.
    * Compression (pos+18) and filter (pos+19) must be 0, and interlace (pos+20) must be ≤ 1.
    * strict: bit depth (pos+16) must be 8, colour type (pos+17) must be 2 or 6, and interlace must be 0.
    * bpp = 4 when the colour type is 6, else 3.
  * Concatenate the IDAT data.
  * strict: `acTL`, `fcTL` or `fdAT` (APNG) is an error.
  * IEND must have len 0, end exactly at the end of the file, and follow non-empty IDAT data. It ends the loop.
  * No IEND → error.
  * strict: inflate the IDAT data (zlib). The output must be exactly `h*(w*bpp+1)` bytes, every row's filter byte
    must be ≤ 4, and there must be no trailing input. Any inflate problem is an error.
  * The result is `{width,height,mime:"image/png"}`.
* In strict mode, any non-PNG gives `Artwork edits must be PNG images.`
* **JPEG** (`FF D8`):
  * Start at pos=2 and loop while pos+4 ≤ len. The byte at pos must be FF. Skip further FF fill bytes.
  * The marker m is the next byte.
    * m == D9 or DA → break, and the image is invalid.
    * m == 01 or D0..D7 → standalone; continue.
    * Otherwise `seglen = u16be` (must be ≥ 2) and `pos += seglen` (must stay ≤ len).
  * When m is in SOF {C0,C1,C2,C3,C5,C6,C7,C9,CA,CB,CD,CE,CF}: seglen must be ≥ 8. Then `h = u16be(m_pos+4)`,
    `w = u16be(m_pos+6)`, where m_pos is the marker byte's index. The result is image/jpeg.
  * No SOF found → error.
* **GIF** (`GIF87a`/`GIF89a`, len ≥ 13): `w = u16le(6)`, `h = u16le(8)`, image/gif.
* **WebP**:
  * `RIFF` at 0, `WEBP` at 8, and `u32le(4) + 8 == len` exactly.
  * Chunks from pos=12: `id`, `size = u32le(pos+4)`. The chunk end must not exceed len.
    * `VP8X` with size ≥ 10: `w = u24le(pos+12)+1`, `h = u24le(pos+15)+1`.
    * `VP8L` with size ≥ 5 and data[0] (pos+8) == 0x2F: `b = u32le(pos+9)`, `w = (b & 0x3FFF)+1`,
      `h = ((b>>14) & 0x3FFF)+1`.
    * `VP8 ` with size ≥ 10 and bytes at pos+11..13 == `9D 01 2A`: `w = u16le(pos+14) & 0x3FFF`,
      `h = u16le(pos+16) & 0x3FFF`.
    * Otherwise advance by `pos = pos + 8 + size + (size & 1)`.
* **BMP** (`BM`, len ≥ 26): `hdr = u32le(14)`.
  * hdr == 12: `w = u16le(18)`, `h = u16le(20)`.
  * hdr ≥ 40 and len ≥ 54: `w = int32le(18)`, `h = abs(int32le(22))`.
  * The result is image/bmp.
* Anything else → error.

### 5.2 DecorationStorage.inspect: see 2.8.

### 5.3 LwfStorage.inspect(bytes) (LWF binary header)
`word(o)` = u32 little-endian. All failures give LWF_ERR.
* `len ≥ 324`, `len ≤ 12582912`, and magic `"LWF\0"` (4C 57 46 00).
* `ver = b4<<16 | b5<<8 | b6` must be one of 0x121010 (1183760), 0x131211 (1249809) or 0x141211 (1315345).
  The header length H = 332 for 0x141211, else 324.
* `len ≥ H`, and `(b7 & 4) == 0` (not compressed).
* `word(H-4) == len` (the stored file size).
* `w = word(8)`, `h = word(12)`, `fps = word(16)`: 1 ≤ w,h ≤ 16384 and 1 ≤ fps ≤ 240.
* Section table, for o from 32 while o < H-4, step 8: `off = word(o)`, `cnt = word(o+4)`. If either is non-zero
  then `off ≥ prevOff` (initially H), `off ≤ len` and `cnt ≤ len - off`; then set `prevOff = off`.
* `word(20) < word(H-24)` and `word(24) < word(H-8)`. These are index-range sanity checks; reproduce them literally.
* The result is `{mime:"application/octet-stream", width:w, height:h}`.

### 5.4 CRI @UTF table (CpkArchive.utf / Table): reader
The bytes may be encrypted. If they do not start with `@UTF`, XOR every byte with a key stream:
`k = 0x5F; for each i: b[i] ^= k; k = (k * 0x4115) & 0xFF` (0x4115 = 16661). After that they must start with `@UTF`
and be at least 32 long (`CPK: Unsupported table signature`). The rest is big-endian:
```
0  "@UTF"
4  u32 tableSize      -> length = tableSize+8, must be ≤ buffer length
8  u32 rowsOffset     -> rows    = +8 (absolute)
12 u32 stringsOffset  -> strings = +8
16 u32 dataOffset     -> data    = +8
20 u32 tableNameOffset (string, validated)
24 u16 numColumns (≤512)   26 u16 rowWidth   28 u32 numRows (≤10000)
32 column defs: 1 byte flags + u32 nameOffset (each 5 bytes, + inline constant if flags&0xF0==0x30)
```
* Layout must satisfy `rows ≥ 32, strings ≥ rows, data ≥ strings, data ≤ length` (`CPK: Invalid table layout`).
  The rows region `rowWidth*numRows` must fit before `strings` (`Truncated or invalid UTF rows`).
* Column flags: type = flags & 0x0F (must be < 12), storage = flags & 0xF0 ∈ {0x10 zero/none → value 0,
  0x30 constant (value read right after the def), 0x50 per-row}. Anything else gives
  `CPK: Unsupported UTF storage`. Duplicate names give `CPK: Duplicate UTF column`. The sum of per-row widths must
  be ≤ rowWidth.
* Type widths `[1,1,2,2,4,4,8,8,4,8,4,8]`:
  * 0 u8, 1 s8, 2 u16, 3 s16, 4 u32, 5 s32
  * 6 u64: the top byte must be 0 and the value ≤ 2^53-1, else `64-bit value exceeds safe range`
  * 7 s64: |v| ≤ 2^53-1
  * 8 f32, 9 f64
  * 10 string: u32 offset into strings, NUL-terminated before `data`. Decode strict UTF-8, else Shift_JIS, else
    `CPK: Unsupported filename encoding`. Unterminated gives `CPK: Unterminated UTF string`.
  * 11 bytes: u32 offset (from data) and u32 size, within length.
* Integer types become Long; f32/f64 become Double.
* The result is a list of row maps.
* Every CpkArchive error string is prefixed `"CPK: "`. Range failures read `CPK: Truncated or invalid <what>`.

### 5.5 CPK archive reader (CpkArchive): import expansion and Sparking scripts
* A packet at offset X: 16 bytes = 4-char tag, 4 ignored bytes, then u64 **little-endian** size at +8 (≤32 MB,
  `CPK: Metadata exceeds limit`). The UTF table follows at X+16. A wrong tag gives `CPK: Invalid <tag> packet`.
* `CPK ` at 0 must hold exactly 1 row (`CPK: Invalid archive header`). Numbers `TocOffset`, `ContentOffset` and
  `Files` must be Long ≥ 0 (`CPK: Invalid <name>`). `TocOffset == 0` →
  `CPK: Archive has no named TOC; an external name map is required` (ITOC-only archives are unsupported).
* `TOC ` at TocOffset: the row count must equal Files (`CPK: Archive file count does not match TOC`).
* base = min(ContentOffset, TocOffset).
* For each row:
  * FileName must be a String. DirName must be a String or Long 0, else `CPK: Invalid file name`. DirName `""` or
    `"<NULL>"` means no dir.
  * `path = dir ? dir+"/"+name : name`. It must pass CpkArchive.safePath (`CPK: Unsafe entry path`).
  * Duplicate paths (NFC + lower case) → `CPK: Duplicate entry path`.
  * FileSize and ExtractSize must be ≤ 160 MB, and the running ExtractSize total ≤ 2 GiB
    (`CPK: Extracted data exceeds limit`).
  * `offset = FileOffset + base` (overflow gives `Invalid file offset`). It must lie within the file
    (`Truncated or invalid file contents`) and be ≥ ContentOffset (`CPK: File overlaps archive metadata`).
* `Entry {path, offset, storedSize: FileSize, size: ExtractSize}`.
* `read(entry)`:
  * read storedSize bytes
  * if they start with `CRILAYLA` → `decodeCriLayla(bytes, size)`
  * else size must equal storedSize, otherwise `CPK: Unsupported compression format`.
* **CRILAYLA decode** (exact):
  ```
  require len ≥ 272 and bytes[0..8]=="CRILAYLA"                  else "Unsupported compressed entry"
  uncompressed = u32le(8); hdrOff = u32le(12); total = uncompressed + 256
  require total ≤ 160MB and total == expectedSize                 else "Compressed output size does not match file table"
  require 16+hdrOff+256 ≤ len and 272+hdrOff == len               else "Unexpected trailing CRILAYLA data"
  out = new Uint8Array(total); out.set(bytes[16+hdrOff .. +256], 0)     // stored 256-byte prefix
  bit reader: src = hdrOff+15 (reads BACKWARDS), pool=0
     take(n): v=0; while n>0 { if pool==0 { if src<16 throw "Truncated CRILAYLA bit stream"; cache=bytes[src--]; pool=8 }
              k=min(n,pool); v=(v<<k)|((cache>>(pool-k))&((1<<k)-1)); pool-=k; n-=k } return v
  i = total-1
  while i ≥ 256:
     if take(1)==0: out[i--] = take(8)
     else:
        offset = take(13)+3; length = 3
        for lvl of [2,3,5,8]: b=take(lvl); length+=b; if b != (1<<lvl)-1 -> break (no extension)
        if all four were max: do { b=take(8); length+=b; if length > i-255 throw "CRILAYLA match exceeds output" } while b==255
        if length > i-255 or i+offset ≥ total throw "Invalid CRILAYLA back-reference"
        while length-- > 0: out[i] = out[i+offset]; i--
  return out
  ```
* `expandCpkResources(dir, count, bytes)` runs during imports:
  * walk dir and collect existing relative paths (NFC + lower case) and every `*.cpk`
  * for each cpk, extract its entries to `<cpk path minus .cpk>/<entry path>`
  * safePath is required, otherwise `Unsafe expanded CPK path`
  * a destination that is already taken gives `Imported resources have conflicting destinations: <p>`
  * limits: 100000 files and a 4 GiB total, otherwise `Expanded CPK resources exceed the import limit`
  * a bad CPK or entry adds a warning `<p>: <msg> The original archive was kept.` (≤200, then
    `Additional CPK warnings were omitted. Original archives were kept.`)
  * the original cpk is kept
  * returns `{count, bytes, expanded, warnings}`.

### 5.6 CPK writer (CpkWriter.write): export of packed artwork
The UI has its own JS writer (`ui/cpk-writer.js`). The native one is used by `export` (`exportSource` when an
entry has `cpk:[{path, assetKey}]`). Exact layout:
* Input:
  * 1..5000 entries (`CPK: Choose1–5000 files.`, with an en dash; the JSON form says `CPK: Too many files.` when
    over 5000). A non-`.cpk` path or extra keys give `Invalid packed artwork entry.` (CreatorActivity).
  * Each `path` must pass CpkWriter.safe (`CPK: Unsafe archive path.`) and be unique (NFC + lower case;
    `CPK: Duplicate archive path.`). The stored path is the NFC form.
  * The source is `ASSETS/assetKey`: it must pass safe, contain no symlinks, be a file ≤ 160 MB and stay under
    ASSETS, else `CPK: Invalid imported asset key.` / `CPK: Imported assets cannot use symbolic links.` /
    `CPK: Missing or oversized imported asset.`
  * The total is ≤ 512 MB (`CPK: Archive exceeds512MB.`).
* Sort the entries with `compareCriPaths`: compare the UTF-8 bytes after mapping ASCII a–z to upper case. A tie
  breaks on length.
* `align(x) = ceil(x/2048)*2048` (> 512 MB gives an error).
* Offsets:
  * `contentOffset = align(toc.length + 2048)`.
  * Each file goes at the current offset. The next offset is `align(offset + size)`.
  * `contentSize = endOffset - contentOffset`.
* UTF writer (`utf(tableName, cols, rows)`), big-endian:
  * The string pool starts with `"<NULL>\0"`. Then intern `""`, the table name, every column name, and then every
    type-10 value of every row, in row order. Each string is UTF-8 + NUL and deduplicated (the first offset is
    reused).
  * Widths: type 6 → 8, type 2 → 2, any other (4, 10) → 4. rowWidth = the sum.
  * `rowsStart = 32 + cols*5`, `stringsStart = rowsStart + rows*rowWidth`, `end = stringsStart + pool.length`.
    The table size is end rounded up to a multiple of 8 (zero padded). Over 32 MB gives `CPK: Metadata exceeds32MB.`
  * Header: `"@UTF"`, u32 (size-8), u32 (cols*5+24), u32 (stringsStart-8), u32 (end-8), u32 tableNameOffset,
    u16 cols, u16 rowWidth, u32 rows.
  * Each column def: byte `type | 0x50`, then u32 nameOffset.
  * Rows: type 2 → s16, type 4 → s32, type 6 → s64, type 10 → u32 string offset.
  * Then the pool. The table is **not** XOR-encrypted.
* Packet = tag (4 ASCII) + int32 LE 255 + int64 LE utf.length + utf.
* Header table `"CpkHeader"`, one row. Columns (type): ContentOffset(6)=contentOffset, ContentSize(6)=contentSize,
  TocOffset(6)=2048, TocSize(6)=toc packet length, Files(4)=n, Version(2)=7, Revision(2)=14, Align(2)=2048,
  Sorted(2)=1, EnableFileName(2)=1, EID(2)=0, CpkMode(4)=1, Tvers(10)="Dokkan Unit Creator",
  EnabledPackedSize(6)=totalBytes, EnabledDataSize(6)=totalBytes. The packet must be ≤ 2048 bytes
  (`CPK: Header exceeds alignment.`).
* TOC table `"CpkTocInfo"`, one row per sorted entry i: DirName(10)=path before the last "/" (or ""),
  FileName(10)=the rest, FileSize(4)=size, ExtractSize(4)=size, FileOffset(6)=offset-2048, ID(4)=i,
  UserString(10)="".
* File:
  * `[header packet][zero pad to 2048][TOC packet][zero pad to contentOffset]`
  * then for each file: its bytes, zero padded to align(end)
  * The output must not exist (CREATE_NEW) and its parent must be a real dir (`CPK: Invalid archive output.`).
  * The source is re-checked before copying; a change in path or length, or a short read, gives
    `CPK: Asset changed during export.`
  * The partial output is deleted on failure.

### 5.7 LegacyDatabase.decrypt(in, out, key, mode): SQLCipher 3/4 page decryption (Sparking update / APK import)
* The mode is 3 or 4 (`Unsupported database cipher mode.`).
* Parameters by mode:

  | | mode 3 | mode 4 |
  |---|---|---|
  | pageSize | 1024 | 4096 |
  | reserve | 48 | 80 |
  | hmacLen | 20 | 64 |
  | HMAC algorithm | HmacSHA1 | HmacSHA512 |
  | kdf iterations | 64000 | 256000 |

* The key (password bytes) is 1..4096 bytes (`The imported APK did not provide a supported database format.`).
* Input and output must be different files with a safe output dir (`Choose a separate safe database output file.`).
* The input length must satisfy `pageSize ≤ len ≤ 512MB` and `len % pageSize == 0`, else
  `This legacy database is incomplete or uses an unsupported page format.`
* Key derivation:
  * `salt = page1[0..16]`
  * `encKey = PBKDF2(key, salt, iter, 32, HMAC)`
  * `macSalt = salt XOR 0x3a`
  * `macKey = PBKDF2(encKey, macSalt, 2, 32, HMAC)`
* For each page n = 1..N, with `usable = pageSize - reserve` and `start = n==1 ? 16 : 0`:
  * `HMAC(macKey, page[start .. usable+16] || u32le(n))` must equal `page[usable+16 .. +hmacLen]`, else
    `Database authentication failed. The file is damaged or does not match this imported APK's supported format.`
  * `plain = AES-256-CBC-NoPadding-decrypt(encKey, iv = page[usable .. usable+16], page[start .. usable])`.
  * Page 1: `plain[0..2]` (BE) must equal pageSize, `plain[4] ≥ reserve`, `plain[5]==64`, `plain[6]==32`,
    `plain[7]==32`, else `The decrypted database has an unsupported SQLite header.` Write
    `"SQLite format 3\0"` first.
  * Write `plain`, then `reserve` zero bytes.
* Leftover bytes give `The legacy database changed during import.` Writing goes to a temp file
  `legacy-db-<uuid>.tmp`, then it is renamed (`Could not save the authenticated database.`).
* iOS: CommonCrypto `CCKeyDerivationPBKDF` + `CCHmac` + `CCCrypt(kCCAlgorithmAES, no padding)`.

---------------------------------------------------------------------------------------------------

## 6. MovieStorage.inspect(file): authored USM validator (CRI USM, VP9-in-IVF + optional ADX)

The UI's `usm-writer.js` produces these files. The validator only accepts that profile. Reading the decompiled
Java was hard here; the rules below are the reconstructed intent, and every message is quoted exactly. All
messages are prefixed `Movie: `.
* File size 2048..100663296, else `Choose a complete authored movie up to 96 MB.`
* Walk the chunks from offset 0 (at most 70000, else `The movie contains too many packets.`). Each 32-byte header
  is big-endian:
  * sig[0..4]
  * `size = u32(4)+8`
  * `hdr = u16(8)+8`, which must be 32
  * `pad = u16(10)`
  * bytes 12,13,14 must be 0
  * `type = byte 15` ≤ 3
  * `size ≥ 32`, `size % 32 == 0`, `payload = size-32-pad ≥ 0`, and the chunk must fit in the file
  * Any failure gives `Invalid authored movie packet.` Reads larger than 1 MB, or truncated reads, give
    `The movie contains a truncated or oversized packet.`
* Chunk at offset 0: it must be `CRID`, type 1, size 2048, else `The movie directory is missing.`
  * The @UTF payload (≤3 rows; parsed with the 5.4 reader) has 2 or 3 rows.
  * row0: `filesize == file length` and `stmid == 0`. row1: `stmid == 0x40534656` ("@SFV"). row2, if present:
    `stmid == 0x40534641` ("@SFA").
  * Else `Invalid authored movie directory.`
  * A metadata payload must start "@UTF" with row count ≤ the limit, else `Invalid authored movie metadata.`
* Later chunks must be `@SFV` or `@SFA` (`Unsupported movie stream.`).
  * **type 1 (stream header)**: payload ≤ 65536 (`Movie metadata is too large.`), exactly 1 row
    (`Invalid stream metadata.`).
    * Video (only once, before any frame) requires:
      * `mpeg_codec==9`, `metadata_count==1`, `32 ≤ metadata_size ≤ 1048576`
      * `1 ≤ width,height ≤ 4096`, `width*height ≤ 16777216`
      * `1 ≤ total_frames ≤ 10000`, `framerate_d ≥ 1`, `1.0 ≤ framerate_n/framerate_d ≤ 120.0`
      * else `Unsupported VP9 movie metadata.`
    * Audio (only if the directory has 3 rows, once, before any audio data) requires:
      * `audio_codec==2`, `metadata_count==0`, `metadata_size==0`
      * `sampling_rate==48000`, `num_channels==2`, `total_samples ≥ 1`
      * else `Unsupported ADX movie metadata.`
  * **type 3 (seek table)**: video only, after the video header, before any frame, only once.
    `video.metadata_size == this chunk's size` and the payload is ≤ 1 MB. Parse the @UTF table (≤10000 rows) as
    the seek list. Else `Invalid movie seek metadata.`
  * **type 2 (marker)**: payload ≤ 64 (`Invalid movie marker.`). The text must equal one of the 32-byte strings
    `"#HEADER END     ===============\0"`, `"#METADATA END   ===============\0"` or
    `"#CONTENTS END   ===============\0"`, else `Unsupported movie marker.`
    * HEADER END for video: header seen, not yet marked, no frames, else `Invalid video header marker.` For
      audio: header seen, not yet marked, no audio bytes, else `Invalid audio header marker.`
    * METADATA END: video only, with a non-empty seek table, not yet marked and no frames, else
      `Invalid seek marker.`
    * CONTENTS END for video: frames > 0 and not yet ended, else `Invalid video end marker.` For audio: the ADX
      end block was seen and it was not yet ended, else `Invalid audio end marker.`
  * **type 0 (data)**:
    * Video requires header, HEADER END and METADATA END seen, CONTENTS END not seen, and payload ≥ 13, else
      `Incomplete VP9 packet.`
      * The first frame's payload starts with a 32-byte IVF header, and needs payload ≥ 45.
        * `"DKIF"`, u16le version 0, u16le hdrLen 32, `"VP90"`, else `Unsupported IVF movie header.`
        * u16le width == width and u16le height == height (a mismatch gives the same error).
        * u32le rate == framerate_n, u32le scale == framerate_d, u32le frameCount == total_frames, else
          `Movie frame timing differs from its metadata.`
      * Then the IVF frame header (12 bytes) at +0, or +32 for the first frame: u32le frameSize ≥ 1 and u64le
        pts == frame index. `frameSize + 12 + ivfHeader == payload`.
      * First VP9 byte b: `(b>>6)==2`, `(b & 0x30)==0` (profile 0). The first frame also needs `(b & 0x0C)==0`.
      * Else `Invalid authored VP9 frame.`
      * Record (chunk offset, keyframe = `(b & 0x0C)==0`). `videoBytes += size`, frames++.
    * Audio requires header and HEADER END seen, no CONTENTS END, no end block yet, and payload ≥ 1, else
      `Incomplete ADX packet.`
      * First data chunk = ADX header (payload ≥ 24 and `u16be(0)==0x8000`, else `Invalid ADX header.`):
        * `hlen = u16be(2)+4 == payload ≤ 4096`
        * bytes 4..7 = `03 12 04 02`
        * `u32be(8)==48000`, `u32be(12)==total_samples`
        * byte18 ∈ {3,4}, byte19 == 0
        * the last 6 bytes of the header are `"(c)CRI"`
        * else `Unsupported plain stereo ADX header.`
      * Later chunks: payload 18 with `u16be(0)==0x8001` and `u16be(2)==14` is the end block. Otherwise
        payload % 36 == 0 (`ADX audio ends inside a sample block.`), and `blocks += payload/36`.
      * `audioBytes += payload`.
* End of file checks:
  * The video header exists, CONTENTS END was seen, `frames == total_frames`, `videoBytes == dir.row1.filesize`,
    and the seek list is non-empty. Else `The movie ends before its declared video content.`
  * `seek[0].ofs_frmid == 0`, else `The first movie seek must point to its first frame.`
  * Every seek row: `0 ≤ ofs_frmid < frames`, that frame is a keyframe, and its chunk offset == `ofs_byte`. Else
    `Movie seek positions do not match its frames.`
  * With an audio row: the audio header, CONTENTS END and end block were all seen,
    `blocks == ceil(total_samples/32)`, `audioBytes == hlen + blocks*36 + 18 == dir.row2.filesize`, and
    `|total_samples/48000 - frames*d/n| ≤ d/n + 1/48000`. Else
    `The movie ends before its declared audio content.`
* Returns `{width, height, frames, rate:{n, d}, preservedAudio: dir has 3 rows}`.

---------------------------------------------------------------------------------------------------

## 7. Preview-side helpers (used by the preview server; listed here because they belong to this area)

### 7.1 GameDirectory (imported folder listing that stands in for `/api/file-browser`)
* `route(url)`: a leading "/" is prefixed with ORIGIN. The URL must be `https://dokkan-eclipse.com/api/file-browser`
  with a query.
  * Take the first `path=` value (URLDecoder). It must pass GameAssets.safe, and
    `path + "/forge-directory-probe.lwf"` must equal `gamePath("/assets/"+path+"/forge-directory-probe.lwf")`.
  * Return path, or null.
* `resolve(url)`:
  * Visual names match `(?i).*\.(png|lwf)$`.
  * Collect overlay entries whose parent dir == path and that are visual.
  * If ASSETS is missing: when there are no overlay hits and the preferred key lies under path →
    `The selected imported asset is unavailable. Choose it again.`; else null.
  * Otherwise scan the collection dirs:
    * Order them newest first. There are at most 4096 dirs (`Too many imported resource groups for a visual preview`).
    * In each, check `{C, C/files, C/tutorial0}/path` (a real directory within ASSETS).
    * List up to 10000 entries in total (`This visual folder exceeds the preview listing limit`).
    * Keep visual files whose name passes gamePath. The first one wins by name.
    * A file > 160 MB → `Imported game asset exceeds the 160 MB preview limit`.
  * Then add the preferred-key file if its dir == path and it is visual. Then add the overlay files.
  * More than 200 names → `This visual pack has more than 200 files. Choose a smaller pack.`
  * Returns `{path, parentPath: dirname or "", items:[{type:"file", name, path: path+"/"+name, size, source:"imported"}], forge_local:true}`,
    or null when it is empty.
* `merge(local, remote)`:
  * Remote items that are files with a slash-free visual name, `path == dir+"/"+name` passing gamePath, and
    0 ≤ size ≤ 160 MB are added as `{name, path, type:"file", size, source:"public"}`.
  * Local items override them by name. The bound is 200.
  * The result is `local` with the merged items, sorted by name.

### 7.2 GameMetadata.resolve(url) (imported metadata for `/api/card/<id>` and `/api/effect-pack/<id>`)
* URL checks:
  * Relative URLs are prefixed with ORIGIN. The scheme must be https, the host dokkan-eclipse.com or
    cdn.dokkan-eclipse.com, with no userinfo and no port.
  * Any query `patch` → null. `enemy=1` sets the enemy flag.
  * The path must match `^/api/(card|effect-pack)/([1-9][0-9]{0,14})$`.
* `descriptor(rel)`: the file comes from `GameAssets(ASSETS, preferredKey, overlays).resolve("/assets/"+rel)`.
  It produces `{rel, url:"/assets/"+rel, bytes, source:"imported", stamp:"imported:<mtime>:<len>"}`, or null.
* **card**:
  * `row("cards", id)` is required, with character_id in (0, 2^53), and `res = resource_id || id` > 0.
  * `art = floor(res/10)*10`, `cid5 = %05d(character_id)`, `sm = %02d(special_motion)`.
  * Descriptors:
    * battle `ingame/battle/character/<cid5>/battle/battle_character_<cid5>.lwf`
    * idle `.../<cid5>/idle/idle_character_<cid5>.lwf`
    * sp `.../<cid5>/sp<sm>/sp_character_<cid5>_<sm>.lwf`
    * card_bg (if bg_effect_id ≠ 0, with `b = floor(bg_effect_id/10)*10`): `character/card_bg/<b>/card_<b>.lwf`
  * Textures, with base `character/card/<art>/card_<art>`:
    * character `_character.png`
    * effect `_effect.png`
    * bg `_bg.png`
    * circle `_circle.png`
    * cutin `sp_cutin_1.png`
    * sp_cutin `sp_cutin_1.png`

    Both cutin entries append `sp_cutin_1.png` directly, with **no** underscore, so the path is
    `card_<art>sp_cutin_1.png`. That is what the binary does.
  * sp_name and sp_phrase come from the first of `character/card/<art>/en/card_<art>_<k>.png` or
    `<base>_<k>.png`.
  * If nothing is found → null.
  * Result:
    `{found:true, forge_local:true, id, name, character_id, character_size: characters.size|null, resource_id,
    art_id, bg_effect_id, special_motion, aura_id, aura_effect_id:null, aura_scale (default 1.0), aura_offset_x,
    aura_offset_y (default 0), is_aura_front: bool, battle, idle, sp, card_bg (descriptor|null), textures,
    dbSource:"imported"}`.
* **effect-pack**:
  * `row("effect_packs", id)` with pack_name matching `[-a-zA-Z0-9_]{1,100}`.
  * `rules.categories[category]` (from `ui/data/preview-metadata-rules.json`) supplies the `lwf[]` and `usm[]` path
    templates with `{pack}`.
  * The lwf is the first existing template. The usm candidates are, when enemy is set, the usm templates with
    `{pack}+rules.enemyMovieSuffix` first, then the normal ones.
  * Result: `{found:true, forge_local:true, id, category, name, pack_name, scene_name, rgba:{r,g,b,a},
    lite_flicker_rate, media: "both"|"lwf"|"usm", lwf, usm, enemy, dbSource:"imported"}`, or null if neither exists.
* `merge(local, remote)` (the remote is the Eclipse JSON):
  * **cards**: when character_id and art_id match, the result is remote overlaid by local keys.
    * For each pack: the local value, else the remote one. `sp` is taken from remote only when special_motion is
      equal. The binary has the same intent for `card_bg` with bg_effect_id.
    * `fsPath` is removed from every value.
    * textures = remote ∪ local, with local winning.
    * `aura_effect_id` comes from remote when local is null and aura_id is equal.
  * **effects**: when pack_name and category match, overlay as above.
    * lwf = local, else remote. usm = local, else remote when the enemy flag is equal.
    * `media` = `both`, `lwf`, `usm` or `missing`.
  * Otherwise return local.

### 7.3 GameBgm (finish-skill music)
* `context(db, scriptPath)`: the script path must match `ab_script/finish_skill/[A-Za-z0-9_]{1,80}\.lua`, else
  `{version:1, found:false, reason:"This preview has no verified finish-skill music context."}`.
* SQL: `SELECT DISTINCT f.bgm_id AS id FROM finish_skill_sets f JOIN special_views v ON v.id=f.special_view_id WHERE v.script_name=? LIMIT 3`,
  with the bind value being the file name without `.lua`.
  * Exactly 1 row with an integer id in 1..2^31-1 → `{version:1, found:true, scriptPath, id, package: "bgm_%03d"}`.
  * 0 rows → reason `This move has no music selected in the imported game database.`
  * More than 1 row → reason `This move has multiple different music contexts.`
  * An invalid id throws `Invalid game music context`. That, or any other exception, gives the reason
    `The imported game database cannot resolve this move’s music.` (with U+2019).
* `source(ASSETS, gameAssets, ctx)`:
  * Requires `found` and a package matching `bgm_[0-9]{3,10}`.
  * Resolve `/assets/bgm/<pkg>.acb` and `.awb`.
  * Neither found → null.
  * Exactly one found → `Imported move music is missing its matching cue sheet or waveform bank. Import the complete music pair.`
  * Different parent dirs → `Imported move music must use a cue sheet and waveform from the same collection and folder.`
  * Returns the `[acbRel, awbRel]` paths relative to ASSETS, which must pass safe (`Invalid imported music resource`).

### 7.4 MovieCache (prepared MP4s, preview WebView only)
* Folder `ROOT/movie-cache`, LIMIT 3 GiB, KEEP_FREE 512 MiB. KEY = `[a-f0-9]{64}-[a-z]{1,4}` (the SHA-256 of the
  source movie plus an output kind).
* Only GET (else 405 `{}`), and only without a query (404). Path `/_forge/movie-cache/<rest>`:
  * `KEY.mp4`:
    * if the file exists with length ≥ 12, touch its mtime and return 200 `video/mp4`, `Cache-Control: no-store`,
      `Content-Length`, with no Range support
    * otherwise 404 `{}`
  * `keep/KEY/<32hex>.mp4`: the source is the preview server's prepared movie with that id (in-memory `movies` map).
    * A missing source, or one shorter than 12 bytes → 404.
    * Same size already kept → 200 `{"kept":true}`.
    * Free space minus size < 512 MB → 507 `{"kept":false}`.
    * Otherwise copy to `KEY.part`, then rename (a failure gives 500 `{"kept":false}`).
    * Trim: when the folder total > 3 GiB, delete the oldest by mtime, skipping the new file.
    * 200 `{"kept":true}`.
  * Any throwable → 500 `{}`.
  * JSON replies are `application/json; UTF-8` with reasons OK, Not Found, Method Not Allowed,
    Insufficient Storage or Error.

### 7.5 PatchProvider (Android ContentProvider: no iOS equivalent needed)
* The authority is `<package>.patch`. The URI is `/<uuid36 [a-f0-9-]>/unit-patch.zip`, which maps to
  `cacheDir/converter/<uuid>/unit-patch.zip`.
* Read-only (mode "r"). The type is `application/zip`. query returns `_display_name` and `_size`.
* It shares the zip made by `convert` with the converter. On iOS, use a file URL / share sheet instead.

---------------------------------------------------------------------------------------------------

## 8. Caches

### 8.1 PreviewCache (`ROOT/preview-cache`)
* The key is `sha256hex(normalized(url))`. Files are `<hex>.body` (raw bytes) and `<hex>.json` = `{"url": normalized,
  "type": Content-Type || "application/octet-stream"}`. An entry counts as saved only when **both** files exist.
* `normalized(url)`:
  * The scheme must be https, the host exactly `dokkan-eclipse.com`, with no port or userinfo, and the path must
    match `/(tools/.*|assets/.*|static/.*|css/.*|cdn/uncompressed/.*|api/.*)`. Else
    `Unsupported public preview resource`.
  * Split the query on `&` and each part on the first `=`. URL-decode both sides.
  * A key `patch` → `Private patch previews are not cached`.
  * Drop parameters whose key matches `_|_t|t|ts|timestamp|cacheBust|nocache` **and** whose value is all digits.
  * Sort by key (a duplicate key keeps the last value). Re-encode each side with Java URLEncoder and join with `&`.
  * The result is `"https://dokkan-eclipse.com" + rawPath + ("?" + q if q nonempty)`.
* `settings.json`: `{maxBytes, offline}`. Budgets are {512 MiB, 1, 2, 4, 8, 16, 32 GiB}, and anything else falls
  back to 2 GiB.
* `settings(args)`, the `previewCache` bridge (other spec):
  * `maxBytes` must be one of the budgets, else `Choose one of the preview storage sizes.`
  * Setting `offline` to a new value bumps the revision.
  * `clear:true` (a boolean, else `Invalid preview storage request.`) deletes the `[a-f0-9]{64}\.(body|json|tmp)(\.tmp)?$`
    files and bumps the revision.
  * Returns `{offline, bytes, count, maxBytes}`, where bytes and count cover the `<64hex>.body` files.
* `ensure(url, max)`:
  * Interrupted → `Preview closed`.
  * Already saved → done.
  * offline → `This resource has not been saved for offline preview`.
  * Otherwise GET (2.5 UA, no redirects) into `<hex>.tmp`, with the size checks from section 1.
  * When the encoding is identity or absent and length > 0, a mismatch gives `Incomplete preview download`.
  * If `bytes + n > limit` → `Saved preview storage is full. Increase its size or clear downloaded previews in Animation Studio.`
  * Rename to .body (`Could not save preview`), then write the .json via a .tmp file and rename
    (`Could not save preview settings`).
* `text(url, max)`: ensure, then read as UTF-8. A body over max gives `Preview text exceeds the size limit`.

### 8.2 OfflineLibrary.download(cacheRoot, url, max, budget)
* Same key and files as PreviewCache, but uses its own HTTP rules (section 1).
* Write to `<hex>.part<threadId>`.
  * declared length > max, or more bytes read than max → `File is larger than the preview limit`
  * reserve the declared length before reading, or the read length afterwards
  * `length ≥ 0 && written ≠ length && no Content-Encoding` → `Incomplete download`
* If another writer saved the entry meanwhile, return 0.
* Rename to `.body`, then write `<hex>.jpart<tid>` and rename it to `.json`. Either rename failing gives
  `Could not save a downloaded file`.
* Returns the bytes written, or 0 if the entry was already present.
* On failure, delete the part and release the reservation.
* `readLimit(ROOT)`: `settings.json.maxBytes` if it is a valid budget, else 2 GiB. It is read without a lock.

### 8.3 GameDataStore (`ROOT/databases`, `ROOT/database-state.json`): mostly the DB spec
* `database-state.json` = `{version:1, active:{file:"db-<sha256>.db", meta:{..., sha256, bytes}}, previous?:{...}}`.
  The file names must match `db-[a-f0-9]{64}\.db` (`Invalid stored database name`). A version other than 1 gives
  `Unsupported database state`, and a state file over 1 MiB gives `Database state is too large`.
* `current()`:
  * with state → the active file
  * without state → `ROOT/database.db` if it exists, else `bundled-database.db`
* `meta()`:
  * with state → `active.meta`
  * without state → `ROOT/database-meta.json`, or else
    `{source:"Bundled Eclipse English snapshot · 2026-10-14", date:"2026-10-14"}`
* `commit(file, meta)`:
  * copy the file to `stage-<uuid>` with fsync (more than 512 MB gives `Database exceeds 512 MB`), hash it, and
    rename to `db-<hash>.db` (`Could not stage database`)
  * the new state is `{version:1, active, previous}`; previous is the old active, or a slot of the legacy/bundled
    current
  * write the state via a `.tmp` file with fsync, then rename (`Could not activate the database; previous data was kept`)
  * prune the unreferenced db files
* `restore()` swaps active and previous (`No previous database is available`).
* `hash(file)` = SHA-256 hex.
* animationSource and OfflineLibrary use `meta().date || meta().sha256 || "bundled"` as the `sourceKey`.

---------------------------------------------------------------------------------------------------

## 9. Notes for the iOS port

### 9.1 Storage
Use `Application Support/forge/` as ROOT (it is excluded from user-visible Files and survives updates). Mark
`preview-cache` and `movie-cache` with `isExcludedFromBackup`, since both can grow to tens of GB. Keep every file
name and JSON format identical, so that backups and diagnostics stay comparable and the UI-visible keys
(`generated-…/image.png` and so on) match.

### 9.2 Concurrency
Bridge calls run on one serial queue. OfflineLibrary uses its own operation queue with 4 workers plus a
single-thread "thumbnail saver" (queue capacity 300). MovieStorage state is in memory, lives as long as the
activity, and is synchronized.

### 9.3 What the UI expects from the shapes
* `assets` rows → `.key .path .name .size .image`
* `downloadAsset` → `.key` must start with `group + "/"`, and `.size` is compared with the listing size
* `readAsset` → `.base64`, `.width`, `.height`, `.mime`
* `store*` results are attached to projects as `{key, path, ...}`
* `storeMovie` finish → `{key, path, size, name, width, height, frames, rate, preservedAudio, storageTag}`
* `animationCatalog` → `{items, more, offset}`
* `animationVisuals` → `{items:[{name, path, scene?}]}`
* `animationSource` → `{path, text, cached, local?}`
* `browseAssets` passes the Eclipse JSON through unchanged
* `cardIndex` → an array of 12-element arrays

### 9.4 Sparking variants (summary; details belong to the Sparking spec)
* `animationFiles` with `sourceDatabase:"sparking"`:
  * The bundled Sparking snapshot has `latestVersion == 1791992148`. For it, read the bundled
    `ui/data/sparking-animation-paths.json`.
  * Otherwise take the manifest `ROOT/sparking/<assetsManifest || catalog-assets-<ver>.json>` assets whose
    `file_path` starts `lua/` and passes validAnimationPath, plus the entries of
    `ROOT/sparking/base-scripts-<ver>.cpk` (downloaded as `lua/ab_script.cpk`) prefixed with `ab_script/`.
  * Returns a sorted array.
* `animationSource` with `sourceDatabase:"sparking"`:
  * The asset key defaults to `sparking-source-<latestVersion>/lua/<path>`.
  * If the file is missing: when the manifest lists `lua/<path>`, download it (size ≤ 2 MB). Otherwise extract the
    entry `<path minus "ab_script/">` from base-scripts.cpk via CpkArchive (a duplicate gives
    `Conflicting original animation entries.`; missing or over 2 MB gives
    `This animation is not present in Sparking's original collection or exceeds the supported size.`).
  * Write via `source-<uuid>.tmp`.
  * Text checks as usual, with the message `This Sparking animation file could not be opened.`
  * Returns `{path, text, assetKey, size, sha256, cached:true, local:true, sourceDatabase:"sparking"}`.
  * A bad path gives `Choose a Sparking animation from the browser.`

---------------------------------------------------------------------------------------------------

## 10. What could not be determined

1. **Eclipse API response shapes**, because the server cannot be reached from the sandbox. The following are
   inferred from consumers only:
   * `/api/file-browser`: `{path, parentPath, items:[{type:"directory"|"file", name, path, size}]}`
   * `/api/scripts`: `{scripts:[...]}`
   * `/api/card/<id>`: `{found, name, battle/idle/sp/card_bg:{rel,url,…}, textures:{k:{url}}, aura_effect_id, …}`
   * `/api/effect-pack/<id>`: `{found, lwf:{rel}, usm:{url}, scene_name, …}`
   * Whether redirects or gzip occur in practice is also unknown.
2. **MovieStorage.inspect**: the decompiled control flow is badly mangled (register reuse). Section 6 is a
   reconstruction from the readable branches, the constants and the error strings. Two points are inferred rather
   than read: whether `audioBytes` also counts the ADX header and end block (the final equation
   `hlen + blocks*36 + 18` implies it does), and the exact check order. A port should be tested against files from
   `ui/usm-writer.js`.
3. **shouldInterceptRequest**: the androguard output shows the 404 handler around only the path substring. It most
   likely covers the whole forge.local branch (otherwise `Unavailable resource` would crash the WebView). smali
   from androguard does not list try ranges, so this could not be confirmed.
4. **LegacyDatabase page-1 byte checks**: `plain[4] ≥ reserve` is read from the decompiled comparison. Standard
   SQLCipher has exactly `reserve` here.
5. **GameMetadata merge for `card_bg`**: the boolean for "take remote card_bg only if bg_effect_id is equal" is lost
   in decompilation; the intent is inferred from the `sp` branch. Also, the `cutin` texture path
   (`card_<art>sp_cutin_1.png`, with no underscore) looks like an upstream bug but is what the binary does.
6. **expandCpkResources** count and size bookkeeping is partly garbled. The limits (100000 files, 4 GiB) and
   messages are certain.
7. **PreviewMetadata.resolve, PreviewTools and PreviewServer** belong to the preview spec. animationVisuals and
   OfflineLibrary depend on them and are described here only through their observable outputs.
