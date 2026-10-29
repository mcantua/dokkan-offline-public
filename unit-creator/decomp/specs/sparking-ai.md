# Spec: Sparking content + AI bridge methods (iOS port)

Scope: bridge methods `updateSparking`, `findSparkingAssets`, `downloadSparkingAssets`,
`querySparking`, `sparkingInfo`, `sparkingAudioCatalog` (plus the Sparking helpers they call:
`SparkingContent`, `SparkingContent$XXH64`, `SprkCodec`, `SprkEclp`, and the SQLCipher-4 path of
`LegacyDatabase`), and the AI methods `ai`, `aiCompose`, `aiConnections`, `aiSaveConnection`,
`aiRemoveConnection`, `aiStart`, `aiPoll`, `aiCancel`.

Sources: `decomp/src1/com_personal_aihub_{SparkingContent*,SprkCodec*,SprkEclp,AiHandoff*,Provider,
CreatorActivity,GameDataStore,LegacyDatabase,PreviewMetadata}.java` (checked against `smali1/` where
the Java was garbled), `work/dock/src/com/personal/aihub/{ForgeAi,ForgeFixes}.java`, UI JS in
`work/v2/ui/` (`sparking-content.js`, `sparking-audio.js`, `ai-connect.js`, `ai-assistant.js`, `app.js`).

Conventions used below
* `ROOT` = Android `getFilesDir()/forge` (`CreatorActivity.root`). `ASSETS` = `ROOT/assets`.
  `CACHE` = `getCacheDir()`.
* "Error: X" means the native call rejects and the bridge replies `{id, ok:false, error:"X"}`
  (the JS sees `new Error(X)`). Strings are quoted exactly as in the dex.
* Note on the dex strings: several messages have **no space before a number**, exactly as stored
  in the dex: `"exceeds32MiB."`, `"Sparking6.5.5"`, `"the512MiB"`, `"version1"`, `"exceeds1GiB."`,
  `"exceeds512MB."`. They are reproduced verbatim; probably a build-tool artefact, so fixing the
  spacing on iOS is harmless (nothing in the UI matches on these messages).
* JSON booleans: Java `put("x", 1)` on a boolean slot in the decompiler output is really `true`.
  Where a value is listed as `true/false` below it is a JSON boolean.
* Bridge dispatch order on Android: `ForgeFixes.dispatch` runs first. Any method whose name starts
  with `"ai"` **except `"aiCompose"`** goes to `ForgeAi.dispatch`; that returns `null` for unknown
  names (in particular for `"ai"`), and the original `CreatorActivity.dispatch` handles them.
  An unknown method ends with `Error: "Unsupported action: <method>"`.

---------------------------------------------------------------------------------------------------

## Part A: Sparking

### A.1 What "Sparking" is in this app

"Dokkan Sparking" is a fan private server (`dokkan-sparking.com`, Android package
`com.sparkingDokkan.GLB`, version 6.5.5). The app:
1. imports the original Sparking 6.5.5 APK (or a ZIP of it) and extracts **two secrets** from
   `lib/arm64-v8a/libbase.so`: a 16-byte AES key for `.sprk` patches, and a 64-character hex
   passphrase for the SQLCipher-4 game database;
2. ships a built-in decrypted Sparking database snapshot (`sparking-reference.db`, content
   version `1791992148`) so the "Library → Sparking" browser works offline;
3. can download the **current** encrypted database plus the public asset manifest from
   Sparking's public CDN, verify it with XXH64, decrypt it with the passphrase, and keep it as a
   second, independent game database (`sourceDatabase: "sparking"`), separate from the Eclipse DB;
4. downloads individual game resource files (CPK, ACB/AWB, Lua, USM...) listed in that manifest,
   verified by size + XXH64, for previews/exports of units copied from Sparking;
5. converts `.sprk` patch files into `.eclp` (Eclipse) patches.

No account or credentials are ever sent: requests are anonymous GETs.

### A.2 On-disk layout

```
ROOT/
  sprk-format-key.bin            32 bytes: AES-256 key for .sprk (16 key bytes from libbase.so + 16 zero bytes)
  sparking-database-format.bin   64 bytes: ASCII hex passphrase for the SQLCipher-4 database
  format-<uuid>.tmp              temp while writing either key file (write, fsync, rename)
  sparking-unavailable.db        never created; used as GameDataStore "reference" fallback path
  sparking/                      GameDataStore root for the Sparking DB
    databases/db-<sha256-of-file>.db     decrypted SQLite DBs (content-addressed, name regex "db-[a-f0-9]{64}\.db")
    databases/stage-<uuid>               temp during commit
    database-state.json          {"version":1,"active":{"file":..,"meta":{..}},"previous":{..}}
    database-state.json.tmp      temp
    assets-<sha256-of-manifest>.json     manifest saved by updateSparking
    catalog-assets-<version>.json        manifest fetched lazily (e.g. for the bundled snapshot)
    manifest-<uuid>.json, sparking-list-<uuid>.tmp   temps
    resource-cache/<hash>-<size>.data    verified downloaded resource (hash = manifest decimal xxhash string)
    resource-cache/<hash>-<size>.json    {"file_path","bytes","sha256","xxhash64"} for the .data
    base-scripts-<version>.cpk           cached "lua/ab_script.cpk" (original animation scripts)
  assets/sparking-<uuid>/<game path>     per-download copies handed to the UI (+ expanded CPK contents)
  assets/sparking-source-<version>/lua/ab_script/...   cached original animation sources
CACHE/
  sparking-data-<uuid>/{database.db, assets.json, readable.db}   updateSparking staging (deleted after)
  sparking-snapshot-<uuid>.db    bundled snapshot staging
  sparking-<uuid>/{decoded.zip, converted.eclp, payload/...}     .sprk import staging
```

`GameDataStore` (shared class, documented here only as used by Sparking):
* `state()`: reads `database-state.json` (max 1 MiB, else `"Database state is too large"`); must
  have `version == 1` else `"Unsupported database state"`; validates file names
  (`"Invalid stored database name"`). Returns null if the file is missing.
* `current()`: the active `databases/<file>`; if no state: `sparking/database.db` if it exists, else
  `ROOT/sparking-unavailable.db`.
* `meta()`: `state.active.meta`; with no state it falls back to `sparking/database-meta.json` or
  `{"source":"Bundled Eclipse English snapshot · 2026-10-14","date":"2026-10-14"}` (an
  irrelevant default for Sparking, since `prepareSparkingSnapshot` always creates a state first).
* `commit(file, meta)`: copies `file` into `databases/stage-<uuid>` (max 512 MiB, else
  `"Database exceeds 512 MB"`), fsyncs, hashes it (SHA-256, lowercase hex), renames to
  `db-<hash>.db` (if absent; `"Could not stage database"` on failure). The slot is
  `{"file":"db-<hash>.db","meta": <copy of meta> + {"sha256":<hash of decrypted file>,"bytes":<size>}}`.
  The new state is `{"version":1,"active":<slot>,"previous":<old active>}`, written to `.tmp`,
  fsynced and renamed (`"Could not activate the database; previous data was kept"`). Then `prune()`
  deletes every `databases/db-*.db` that is neither active nor previous.

**Secrets on iOS:** the two key files are derived from a user-supplied APK. Keep them in app-private
storage (Keychain or a file with `NSFileProtectionComplete`), never under the WKWebView's web root,
and never return them to JS.

### A.3 Bundled snapshot (`prepareSparkingSnapshot`)

Runs before every Sparking operation. If `sparking/database-state.json` does not exist:
1. copy app asset `sparking-reference.db` (in this repo: `work/apk/assets/sparking-reference.db`,
   104,357,888 bytes) to `CACHE/sparking-snapshot-<uuid>.db` (copy limit 512 MiB);
2. require SHA-256 ==
   `cf13b8553448507ad723e17a7b347e6eac4d7627a2e4fff56c0f7747660dffd8` (verified for the file in
   this repo), else `Error: "The built-in Sparking catalogue is incomplete. Reinstall the complete APK."`;
3. `count = verifyDb(file, true)` (see A.9);
4. `sparkingStore().commit(file, {"source":"Sparking game database · built-in snapshot",
   "sourceType":"sparking-bundled","date":"2026-10-17","latestVersion":1791992148,"count":count})`
   (the separator is U+00B7);
5. delete the temp file (always, also on error).

So `meta.latestVersion` is always present. Bundled version constant: **1791992148**.

### A.4 Bridge methods

#### `sparkingInfo` (args ignored)
1. `prepareSparkingSnapshot()`.
2. `available = (sparking state exists)`. It is always `true` after step 1, unless step 1 threw.
3. `keyConfigured = (length of ROOT/sparking-database-format.bin == 64)`.
4. If available: open the current Sparking DB read-only (cached in memory as `sparkingDb`) and build
   `schema`: for every row of `SELECT name FROM sqlite_master WHERE type='table'` whose name matches
   `[a-zA-Z_][a-zA-Z0-9_]*`, run `PRAGMA table_info("<name>")` and store the rows (array of objects
   with keys `cid,name,type,notnull,dflt_value,pk`; see `rows()` typing in A.4 querySparking).
   `count = SELECT count(*) FROM cards`.

Returns
```json
{"available":true,"keyConfigured":true|false,
 "count":<long>,"schema":{"<table>":[{"cid":0,"name":"id","type":"INTEGER","notnull":0,"dflt_value":null,"pk":1},...],...},
 "meta":{<active meta, see A.3 / updateSparking>}}
```
(`count`, `schema`, `meta` only when available.) UI uses `info.available`, `info.count`,
`info.keyConfigured`, `info.schema`, `info.meta.latestVersion`.

#### `querySparking` args = same as `query`
`ensureSparkingDb()` then the generic `queryDatabase(sparkingDb, sparkingSchema, args)`:
* `table` (required string) must be a key of the schema, else `"Table is not in this database."`
* `filters` (object, optional): every key must be a column (`"Unknown column"`);
  non-null value → `"<col>" = ?` with the value bound **as a string** (`String.valueOf`);
  JSON null → `"<col>" IS NULL`.
* `ids` (array, optional): `[]` → returns `[]` immediately; more than 1000 → `"Too many row IDs"`;
  else `"id" IN (?,?,...)` with each `getLong` bound as a string.
* `search` `{column, text}`: ignored when `text` is empty; `column` must exist
  (`"Unknown search column"`); `"<col>" LIKE ?` with `%` + first 200 chars of text + `%`.
* `order` (default `"id"`) must be a column (`"Unknown sort column"`).
* SQL: `SELECT * FROM "<table>"[ WHERE c1 AND c2 ...] ORDER BY "<order>" LIMIT <clamp(limit default 100, 1..5000)> OFFSET <max(0, offset default 0)>`.
* Identifiers are validated with `[a-zA-Z_][a-zA-Z0-9_]*` (`"Invalid database name"`) and double-quoted.
* Result: JSON array of row objects, column name → value: NULL → `null`, INTEGER → number (long),
  FLOAT → number (double), TEXT → string (BLOB → `getString`, effectively unsupported).

Note: when the DB is replaced (`updateSparking`) the cached handle and schema are closed and reset.

#### `updateSparking` (args ignored)
Precondition: `ROOT/sparking-database-format.bin` is a file of exactly 64 bytes, else
`Error: "Import the original Sparking 6.5.5 APK or its ZIP first. Then download characters here."`

1. Read the 64-byte passphrase. Create `CACHE/sparking-data-<uuid>/` (`"Could not prepare Sparking game data."`).
2. `SparkingContent.download(dir/database.db, dir/assets.json, progress)` (A.5.3). Progress
   callback → `importStatus` with phase `"manifest"` label `"Reading Sparking's game-content list"`,
   or phase `"database"` label `"Downloading Sparking characters"`.
3. `result.sourceEncryptedSHA256 = result.sha256`.
4. progress(`"decrypt"`, `"Opening and authenticating Sparking game data"`, 0, 0);
   `LegacyDatabase.decrypt(database.db, readable.db, passphrase, 4)` (SQLCipher 4, A.7).
5. progress(`"verify"`, `"Checking Sparking characters and skills"`, 0, 0);
   `count = verifyDb(readable.db, true)`.
6. `mkdirs ROOT/sparking`; `name = "assets-" + sha256hex(assets.json) + ".json"`; if
   `ROOT/sparking/<name>` does not exist, rename `assets.json` there
   (`"Could not save Sparking's resource list."`).
7. `sparkingStore().commit(readable.db, result + {"source":"Sparking game database",
   "sourceType":"sparking-current","date":<UTC "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'">,"count":count,
   "assetsManifest":name})`.
8. Close and drop the cached Sparking DB handle and schema.
   progress(`"done"`, `"Sparking characters are ready in Library"`, 0, 0).
9. Return `sparkingInfo()`.
Always: zero the passphrase buffer and delete the staging dir (also on error). Errors propagate
unchanged (see A.5 / A.7 messages).

Resulting `meta` keys: `latestVersion` (long), `bytes` and `sha256` (overwritten by commit with
the decrypted DB's size and SHA-256), `xxhash64` (decimal string, of the encrypted file),
`sourceURL` = `"https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db"`,
`sourceEncryptedSHA256`, `source`, `sourceType`, `date`, `count`, `assetsManifest`.

UI (`sparking-content.js`) runs it inside `databaseTask(...)`, which polls `importStatus`
(`{"phase","label","bytes","total"}`) for progress.

#### `findSparkingAssets` args `{version?: number, paths: string[]}`
1. `manifestFile = sparkingAssetManifest(args.optLong("version", -1))` (A.4.1).
2. Parse it (`readText` limit 32 MiB); collect `assets[*].file_path` into a set.
3. `paths.length > 128` → `Error: "Choose fewer game resources at a time."` (checked after reading
   the manifest). Each path must pass `safePath` (A.8), else `"Invalid resource path."`.
4. Return `{"available":[paths listed in manifest, in input order],"missing":[the others]}`.
No network unless the manifest has to be fetched. UI sends 64 paths per call.

#### `downloadSparkingAssets` args `{version?: number, paths: string[]}`
1. `manifestFile = sparkingAssetManifest(version or -1)`; `sourceVersion = meta.latestVersion`.
   Parse manifest (limit 32 MiB). `mkdirs ROOT/sparking/resource-cache`.
2. `paths.length` must be 1..32, else `"Choose between 1 and 32 game resource files at a time."`
3. `key = "sparking-" + UUID`; `dest = ASSETS/<key>` (via `assetFile`, which applies `safePath` and
   a canonical-prefix check: `"Invalid asset key"` / `"Unsafe path"`); `mkdirs`.
4. For each path (in order):
   * `safePath(path)` else `"Invalid Sparking game resource path."`
   * case-insensitive duplicate check on `NFC(path).toLowerCase()` →
     `"Selected resources have conflicting game paths."`
   * `rec = SparkingContent.assetRecord(manifest, path)` (A.5.1, enforces the resource allowlist).
   * running total of `rec.size` > 536,870,912 → `"This resource batch exceeds512MB. Choose fewer resources."`
   * cache: `stem = rec.hash + "-" + rec.size`; `data = resource-cache/<stem>.data`,
     `side = resource-cache/<stem>.json`. Cache hit iff `data` is a file of length `rec.size`,
     `side` exists, `side.xxhash64 == rec.hash` and `side.sha256 == sha256hex(data)` (side read
     with an 8 KiB limit). Otherwise
     `info = SparkingContent.downloadAsset(manifestFile, path, data, progress)` (A.5.4) and write
     `side = info` (JSON text). Progress → phase `"download"`, label `"Downloading Sparking game resources"`.
   * copy `data` → `ASSETS/<key>/<path>` (mkdirs parents; copy limit 512 MiB).
   * append `{"key":"<key>/<path>","path":path,"sourcePath":path,"size":<copied length>,
     "sha256":info.sha256,"source":"sparking"}`.
   * Any exception: delete the whole `ASSETS/<key>` tree and rethrow.
5. `expandCpkResources(ASSETS/<key>, n, totalBytes)`: recursively finds every `*.cpk` (case-insensitive)
   under the folder, opens it with `CpkArchive` and writes each entry to
   `<cpk path without ".cpk">/<entry path>` inside the same folder. Rules: expanded path must pass
   `safePath` (`"Unsafe expanded CPK path"`); case-insensitive NFC collisions with existing files →
   `"Imported resources have conflicting destinations: <path>"`; at most 100,000 files and 4 GiB
   (`"Resource import exceeds 4 GB"`, `"Expanded CPK resources exceed the import limit"`). A CPK that
   fails to open, or an entry that fails to read, adds a warning
   `"<cpk-rel-path-without-.cpk>: <message> The original archive was kept."` (resp.
   `"<entry path>: <message> The original archive was kept."`) instead of failing. (CPK format: see
   the CPK spec; not part of this area.)
6. Return
```json
{"count":<files incl. expanded>,"bytes":<total bytes>,"expanded":<number of expanded files>,
 "warnings":[...],
 "assets":[{"key","path","sourcePath","size","sha256","source":"sparking"}...],
 "sourceVersion":<meta.latestVersion>}
```
The UI tags each asset with `sourceVersion` and stores them in the project (`project.assets`), so
exports and previews reference them by `key` under `ASSETS/` (served as
`https://forge.local/local-asset/<key>`). UI sends 8 paths per call. It also asks for
`movie/en/<x>.usm` alongside every `ingame/battle/(effect|sp_effect)/<x>.cpk`.

#### `sparkingAudioCatalog` args `{version: number}`
1. `v = PreviewMetadata.normalizeVersion(args.version)` (missing → 0; must be a finite integral
   Number in 1..9007199254740991, else `"Choose a valid Sparking content version."`).
2. `v <= 0` → `Error: "Choose a recorded Sparking content version before preparing its audio."`
3. Return `{"version":v,"files":SparkingContent.audioRecords(<manifest of sparkingAssetManifest(v)>)}`
   where each file is `{"path":"se/...acb","bytes":<size>,"kind":"se"|"voice"}` (A.5.2).

The UI then downloads the chosen banks through `downloadSparkingAssets`.

#### A.4.1 `sparkingAssetManifest(version)` (internal)
1. `prepareSparkingSnapshot()`; `cur = meta.latestVersion`.
2. If `version != -1 && version != cur` →
   `Error: "This unit uses a different Sparking content version. Keep its original attached assets or recreate its copy from the matching catalogue."`
3. `name = meta.assetsManifest` or default `"catalog-assets-<cur>.json"`; must match
   `(assets-[a-f0-9]{64}|catalog-assets-[0-9]+)\.json` else `"Invalid Sparking resource-list reference."`
4. `file = ROOT/sparking/<name>`. If missing: `SparkingContent.downloadManifest(ROOT/sparking/manifest-<uuid>.json)`
   (progress phase `"manifest"`, label `"Opening Sparking resources"`); if the downloaded
   `latestVersion != cur` →
   `"Sparking's server has newer game content. Import the supported APK and update characters before downloading these resources."`;
   rename to `file` (`"Could not save the resource list."`); temp deleted on error.
5. Return `file`.

So for the bundled snapshot (1791992148) the manifest can only be fetched while the server still
reports that version; afterwards the user must `updateSparking`.

#### Related methods (not in the list, but they share this code)
* `animationFiles` with `{sourceDatabase:"sparking"}` → `sparkingAnimationFiles()`: if
  `meta.latestVersion == 1791992148`, returns the bundled list `ui/data/sparking-animation-paths.json`
  (filtered by `validAnimationPath`); otherwise the union (sorted, `TreeSet`) of manifest entries
  `lua/<p>` with `validAnimationPath(p)` and entries of `base-scripts-<v>.cpk` prefixed `ab_script/`.
  `validAnimationPath(p)`: length < 240, matches `(?i)ab_script/[a-z0-9_/-]+\.lua`, and `safePath`.
* `animationSource` with `{sourceDatabase:"sparking", path, assetKey?}` →
  `sparkingAnimationSource`: invalid path → `"Choose a Sparking animation from the browser."`;
  default `assetKey = "sparking-source-<latestVersion>/lua/<path>"`. If the asset file is missing:
  if `lua/<path>` is in the manifest (size must be <= 2 MiB, else
  `"This original animation exceeds the supported script size."`) download it; otherwise take entry
  `path.substring(10)` (after `ab_script/`) from `base-scripts-<v>.cpk` (downloaded from manifest path
  `lua/ab_script.cpk` on first use; progress label `"Preparing Sparking's original animation collection"`);
  duplicates → `"Conflicting original animation entries."`; missing or > 2 MiB →
  `"This animation is not present in Sparking's original collection or exceeds the supported size."`;
  written via `source-<uuid>.tmp` + rename (`"Could not save the original animation."`). Text read
  with a 2 MiB limit; empty, starting with `<`, or containing NUL →
  `"This Sparking animation file could not be opened."`. Returns
  `{"path","text","assetKey","size","sha256","cached":true,"local":true,"sourceDatabase":"sparking"}`.
  (The decompiled control flow here is garbled; the "manifest first, then CPK" order is inferred.)
* Imports: `importSparkingApk` (A.6.1) and `importSparkingPatch` (A.6.4) are reached through the
  generic file import flow, not through a dedicated bridge method.

### A.5 `SparkingContent`: network, manifest, downloads

#### Constants and URLs
* Manifest URL: `https://dokkan-sparking.com/client_assets` (max 32 MiB = 33,554,432 bytes).
* Database URL: `https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db`
  (max 192 MiB = 201,326,592 bytes).
* Resource URL template (must match exactly, see assetRecord):
  `https://ddl.dokkan-sparking.com/dokkan/assets/global/en/<file_path>` where the path part is
  `new URI(null,null,"/dokkan/assets/global/en/"+file_path,null).toASCIIString()` (i.e. percent-encoded
  for non-ASCII/illegal chars). The URL itself comes from the manifest (`url`), not built locally.

#### HTTP (`open(uri, isManifest)`)
* `GET`, **redirects not followed**, connect timeout 20 s, read timeout 60 s.
* Headers: `Accept-Encoding: identity`, `User-Agent: Dokkan-Unit-Creation-Sparking-Content`.
  Manifest only, additionally: `Accept: application/json`, `X-AssetVersion: 0`,
  `Sparking_Asset_Version: 0`.
* Status != 200: 401/403 →
  `"The Sparking public content server refused this request. No account credentials were sent."`;
  other → `"The Sparking public content server returned HTTP <code>. Try again later."`
* 200 with a `Content-Encoding` header other than `identity` (case-insensitive) →
  `"The Sparking server changed its download encoding."`
* iOS note: URLSession adds `Accept-Encoding: gzip` and decompresses silently; set the header
  explicitly to `identity` and disable redirects (delegate returning nil) to stay byte-exact. A 3xx
  is therefore an error ("returned HTTP 302...").

#### URL validation (`allowed(url, isManifest)`)
Parsed URI must have scheme `https`, host `dokkan-sparking.com` (manifest) / `ddl.dokkan-sparking.com`
(database), raw path exactly `/client_assets` / `/dokkan/assets/global/en/sqlite/current/en/database.db`,
no user-info, no fragment, port -1 or 443; the **manifest** URL must also have no query (the database
URL may carry a query). Failure → `"The Sparking server returned an unsupported download address."`

#### Manifest JSON (as consumed)
```json
{"latest_version": 1791992148,
 "assets":[{"file_path":"sqlite/current/en/database.db","url":"https://ddl.dokkan-sparking.com/...","size":123,
            "algorithm":"xxhash","hash":"12345678901234567890"}, ...]}
```
Only `latest_version`, `assets[].file_path`, `url`, `size`, `algorithm`, `hash` are read. `hash` is
the XXH64 (seed 0) of the file as an **unsigned decimal string**. Any other fields are kept in the
saved file but ignored. Numbers: "integer" means Java org.json produced Integer/Long, i.e. a JSON number
without fraction/exponent (in JS: `Number.isInteger(x)`; beware JSON.parse precision > 2^53, which
does not occur for these fields).

#### A.5.1 `assetRecord(manifest, path)`
1. `gamePath(path)` (allowlist, below).
2. `assets.length > 100000` → `"The Sparking manifest contains too many entries."`
3. Exactly one entry with `file_path == path`: more than one →
   `"The Sparking manifest repeats this game resource."`; none →
   `"This resource is not listed in the downloaded Sparking manifest."`
4. `size` must be Integer/Long, `0 < size <= 201326592`, and `algorithm == "xxhash"`, else
   `"Unsupported Sparking game resource size or checksum."`
5. `hash` must match `[0-9]{1,20}` and parse as an unsigned 64-bit integer, else
   `"Invalid Sparking resource checksum."`
6. `url`: https, host `ddl.dokkan-sparking.com`, raw path == encoded `/dokkan/assets/global/en/<path>`,
   no user-info/fragment, port -1/443 (query allowed), else
   `"The Sparking resource download address does not match its manifest path."`
7. Return the entry.

`gamePath(path)` rules:
* null, length > 500, contains `\` or `:`, or matches `(?s).*[\x00-\x1f\x7f].*` →
  `"Unsupported Sparking game resource path."`
* split on `/` (keeping empties): any empty, `.` or `..` segment → `"Unsafe Sparking game resource path."`
* first segment `se`: whole path must match `se/[A-Za-z0-9_-]{1,80}\.(acb|awb)` else
  `"Unsupported Sparking sound-effect bank path."`
* first segment `voice`: must match `voice/(?:(en|ja)/)?([A-Za-z0-9_-]{1,80})/([A-Za-z0-9_-]{1,80})\.(acb|awb)`
  **and** group 2 == group 3, else `"Unsupported Sparking voice bank path."`
* otherwise the first segment must be one of
  `character, ingame, script, movie, sound, lua, bgm, item, card_category, sd_battle, outgame, sugoroku`
  (from smali; the Java listing is truncated), else
  `"This download is not a supported game resource. Account and user-state files are excluded."`
  (Note: `sqlite/...` is not in this list, so the DB can only be fetched by `download()`.)

#### A.5.2 `audioRecords(manifest)`
`assets.length > 100000` → `"The Sparking manifest contains too many entries."`. For every entry
whose `file_path` starts with `se/` or `voice/` (manifest order): if 128 already collected →
`"The Sparking manifest contains too many audio banks."`; validate with `assetRecord` (so one bad
or duplicated audio entry fails the whole call); emit
`{"path":file_path,"bytes":size,"kind":"se"|"voice"}`.

#### A.5.3 `download(databaseDest, manifestDest, progress)` (used by updateSparking)
1. Destinations: parent dir must exist (`"Create a private Sparking download staging directory first."`);
   if the file exists it must be a regular, non-symlinked file (`"Unsafe Sparking download destination."`);
   the two must differ (`"Use separate private files for the Sparking database and manifest."`).
2. Temps, with one shared `<uuid>`: `sparking-<uuid>.database.tmp`, `sparking-<uuid>.manifest.tmp`,
   `sparking-<uuid>.database.old`, `sparking-<uuid>.manifest.old` (next to the destinations).
3. GET manifest. If Content-Length > 32 MiB → `"The Sparking manifest exceeds32MiB."`; read in 64 KiB
   chunks, abort with the same message if accumulated > 32 MiB; progress(`"manifest"`, bytesSoFar,
   contentLength or -1). If Content-Length >= 0 and != received →
   `"The Sparking manifest download is incomplete."`
4. Parse UTF-8 JSON. `rec = databaseRecord(manifest)`:
   * `assets.length > 100000` → `"The Sparking manifest contains too many entries."`
   * entries with `file_path == "sqlite/current/en/database.db"`: two →
     `"The Sparking manifest has duplicate game databases."`; none →
     `"The Sparking manifest does not list its game database."`
   * `size` must be a Number but not Double/Float → else `"Invalid Sparking database size."`
   * `0 < size <= 201326592` and `algorithm == "xxhash"` else
     `"Unsupported Sparking database size or checksum format."`
   * `hash` `[0-9]{1,20}` and parses as unsigned long, else `"Invalid Sparking database checksum."`
   * `allowed(url, false)` (database URL check above).
5. `latest_version` must be a Number, not Double/Float, `>= 0` → else
   `"Invalid Sparking content version."` (note: `downloadManifest` requires `> 0`).
6. Write the manifest bytes to the manifest temp (fsync).
7. GET `rec.url`. Content-Length >= 0 and != size → `"The Sparking database size differs from its manifest."`
   Stream in 128 KiB chunks into the DB temp while updating SHA-256 and XXH64; progress
   (`"database"`, bytes, size). If bytes > size or > 192 MiB →
   `"The Sparking database exceeds its declared size."` fsync.
8. If bytes != size or `toUnsignedDecimal(xxh64) != rec.hash` →
   `"The Sparking database checksum does not match. Existing content was kept."`
9. Commit with rollback: existing DB dest → rename to `.database.old`
   (`"Could not preserve the previous Sparking database."`); existing manifest dest → `.manifest.old`
   (`"Could not preserve the previous Sparking manifest."`); manifest temp → dest
   (`"Could not commit the Sparking manifest."`); DB temp → dest
   (`"Could not commit the Sparking database."`). On failure: delete temps; if nothing was committed
   delete the partial destinations and rename the `.old` files back; failure of that rollback →
   `"Sparking download rollback needs recovery: the previous database is retained in <name>"` /
   `"... the previous manifest is retained in <name>"`. On success delete temps and `.old`.
10. Return `{"latestVersion":<long>,"bytes":<long>,"sha256":"<hex of encrypted DB>",
    "xxhash64":"<unsigned decimal>","sourceURL":"https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db"}`.
    (`sourceURL` is the constant, even if the manifest URL carried a query.)

#### A.5.4 `downloadAsset(manifestFile, path, dest, progress)`
1. `manifestFile` must be a file, `0 < length <= 32 MiB`, else
   `"Update the Sparking content manifest first."` (read in 64 KiB chunks; > 32 MiB →
   `"The Sparking manifest exceeds32MiB."`).
2. `rec = assetRecord(manifest, path)`; `dest` checks as in `destination()`; dest == manifest →
   `"Do not overwrite the Sparking manifest with a game resource."`
3. GET `rec.url` (non-manifest headers). Content-Length >= 0 and != size →
   `"The Sparking resource size differs from its manifest."`
4. Stream (128 KiB) to `sparking-asset-<uuid>.tmp` next to dest, hashing SHA-256 + XXH64;
   progress(`"asset"`, bytes, size). bytes > size → `"The Sparking resource exceeds its declared size."`
   fsync.
5. bytes != size or xxh64 mismatch →
   `"The Sparking resource checksum does not match. Existing content was kept."`
6. Rename temp → dest (`"Could not commit the Sparking game resource."`). Temp deleted on any error.
7. Return `{"file_path":path,"bytes":<long>,"sha256":"<hex>","xxhash64":"<unsigned decimal>"}`.

#### A.5.5 `downloadManifest(dest, progress)`
GET manifest; Content-Length > 32 MiB or accumulated > 32 MiB →
`"The Sparking content list exceeds32MiB."`; progress(`"manifest"`, n, contentLength); length
mismatch → `"The Sparking content list download is incomplete."`; `databaseRecord(json)` must pass;
`latest_version` must be Integer/Long and `> 0` else `"Invalid Sparking content version."`; write to
`sparking-list-<uuid>.tmp` (fsync), rename to dest (`"Could not save Sparking's content list."`).
Returns `{"latestVersion":<long>,"bytes":<int>}`.

### A.6 SPRK / APK formats

#### A.6.1 APK import (`importSparkingApk`, via generic import)
Detected when the imported APK's package is `com.sparkingDokkan.GLB`. Steps:
progress(`"inspect"`, `"Reading Sparking resources and patch format"`); extract keys (below); run
the generic `importArchive`; save `ROOT/sprk-format-key.bin` (32 bytes) and
`ROOT/sparking-database-format.bin` (64 ASCII bytes) via `format-<uuid>.tmp` + rename
(`"Could not save this game's import format."`); add
`"sourceFormat":"sparking-apk","formatKeyConfigured":true,"note":"Sparking import is ready. Browse the included characters in Library → Sparking, or choose Update characters for current game data. You can also import supported .sprk patches and save ECLP from Library. Artwork and other game resources download separately."`;
progress(`"done"`, `"Sparking import ready"`). Key buffers are zeroed afterwards.

`supportedLibrary(apk)`:
* not a file → `"Import the original Sparking6.5.5 Android APK first."`
* open as ZIP; entries named exactly `lib/arm64-v8a/libbase.so`: two →
  `"The APK has duplicate native libraries."`; none, a directory, uncompressed size < 648,439 or
  > 16 MiB, or compressed size > 16 MiB →
  `"This APK does not contain the supported Sparking6.5.5 Android format library."`
* read it (limit 16 MiB, `"This Sparking resource exceeds its size limit."`); SHA-256 must equal
  `9d3f2749e391d990496b632b6adc135492f71e0baec7125d7b613a56e771dca0`, else
  `"This Sparking APK version is not supported for SPRK conversion. Its native format must be checked before importing encrypted patches."`

`keyFromApk`: `key = new byte[32]; key[0..16) = lib[648423 .. 648439)`; bytes 16..31 stay **zero**.
The SPRK cipher is therefore AES-256 with that 32-byte key.

`databaseKeyFromApk`: requires `lib.length > 487156` and `lib[487156] == 0` (NUL terminator), else
`"The supported Sparking database format key is unavailable."`; `lib[487092 .. 487156)` (64 bytes)
must all be `[0-9a-fA-F]`, else `"The supported Sparking database format key is invalid."`;
returned as a 64-char ASCII string (stored as raw ASCII bytes, used as the SQLCipher passphrase).

#### A.6.2 SPRK file format (version 1)
```
offset 0  : "SPRK" (0x53 0x50 0x52 0x4B)
offset 4  : 0x01 (version)
offset 5  : 16-byte AES-CTR initial counter block (IV)
offset 21 : ciphertext = AES-256-CTR(key, IV) of a ZIP archive, no padding, no MAC
```
Decode (`SprkCodec.decode(src, dst, key)`):
* key must be 32 bytes, else `"Import the supported Sparking APK before opening an SPRK patch."`
* dst parent must be a directory, dst != src, and dst (if it exists) not a symlink, else
  `"Choose a separate, safe staging file for this Sparking patch."`
* src must be a file with `21 < length` and `length - 21 <= 512 MiB`, else
  `"This Sparking patch is empty or exceeds the512MiB conversion limit."`
* header mismatch → `"Unsupported Sparking patch header. Only the verified SPRK version1 format is supported."`;
  short header → `"The Sparking file is truncated."`
* decrypt in 1 MiB chunks (running total > 512 MiB → `"Sparking patch exceeds the512MiB conversion limit."`)
  into `sprk-decode-<uuid>.zip.tmp`, fsync, validate with `central()` (A.6.3), rename to dst
  (`"Could not commit the decoded Sparking archive."`).
* Counter: Java `AES/CTR/NoPadding` increments the whole 16-byte block as a big-endian 128-bit
  integer. WebCrypto equivalent:
  `crypto.subtle.decrypt({name:"AES-CTR", counter: iv16, length: 128}, await importKey("raw", key32, "AES-CTR"), ciphertext)`.
  Swift: CommonCrypto `kCCModeCTR` with `kCCModeOptionCTR_BE`, or a manual counter.

#### A.6.3 Decoded ZIP validation (`central(zip)`)
* file size <= 512 MiB else `"Invalid or oversized Sparking ZIP."`; < 22 bytes →
  `"The decrypted Sparking file is not a complete ZIP."`
* EOCD search over the last `min(65557, len)` bytes, scanning backwards for signature `0x06054b50`
  whose comment length makes it end exactly at EOF. Require: found; disk numbers (EOCD+4, +6) both 0;
  entries-on-disk == total entries; `1 <= entries <= 10000`; CD size <= 16 MiB;
  `cdOffset + cdSize == eocdPosition`; neither is `0xFFFFFFFF` (no ZIP64); else
  `"Unsupported or incomplete Sparking ZIP directory."`
* each central header (46 bytes): signature `0x02014b50` else `"Corrupt Sparking ZIP directory."`;
  `flags & 0x41 == 0` (no encryption/strong encryption), method 0 or 8, sizes <= 512 MiB, local
  offset < cdOffset, name length 1..2000, disk-start (offset 34) == 0, unix mode
  `(externalAttrs >>> 16) & 0xF000` in {0, 0x8000, 0x4000}; else
  `"This Sparking ZIP contains an encrypted, linked, special or unsupported entry."`
* names: UTF-8 if flag 0x800 else CP437, strict decoding; a trailing `/` marks a directory (the slash
  is stripped for the checks); `safe(name)`: non-empty, <= 500 chars, not starting with `/`, no `\`,
  not matching `(?s).*[:\x00-\x1f\x7f].*`, no empty/`.`/`..` segment, else
  `"The Sparking archive contains an unsafe file path."`; duplicates →
  `"The Sparking ZIP contains duplicate file paths."`; mode 0x4000 on a non-directory →
  `"Invalid Sparking ZIP directory entry."`; directory with nonzero size is rejected (exact branch
  unclear in smali); sum of uncompressed sizes > 1 GiB → `"Expanded Sparking patch exceeds1GiB."`;
  extra+comment running past the CD → `"Truncated Sparking ZIP metadata."`; other limit failures →
  `"This Sparking ZIP exceeds supported limits or needs unsupported ZIP64 handling."`
* the CD must end exactly at `cdOffset+cdSize` (`"Sparking ZIP directory size does not match."`)
* no entry may have a file as an ancestor folder (`"A Sparking file conflicts with a folder."`)
* local header at each offset: signature `0x04034b50`, same method and flags, same decoded name,
  and `local+30+nameLen+extraLen+compressed <= cdOffset`; else
  `"Sparking ZIP local and directory headers do not match."` / `"Invalid Sparking ZIP file bounds."`

#### A.6.4 Inspection + ECLP conversion (`SprkCodec.inspect`, `SprkEclp.convert`)
`importSparkingPatch(file, name)`: requires `sprk-format-key.bin` of 32 bytes, else
`"First choose Import file and select the original Sparking 6.5.5 APK or its ZIP. Then import your .sprk patch here."`;
stages in `CACHE/sparking-<uuid>/` (`"Could not prepare Sparking conversion."`); progress
(`"convert"`, `"Opening Sparking patch"`); decode → `decoded.zip`; `SprkEclp.convert(decoded.zip,
stageDir, converted.eclp, CACHE, name)`; `importEclp(converted.eclp, name minus (?i)\.sprk$ + ".eclp")`
plus `"sourceFormat":"sparking-sprk"` and note
`"Sparking patch converted and added to the Sparking category in Library. Save ECLP to install it in Eclipse. Format conversion does not verify its SQL or gameplay compatibility; the original creator metadata was preserved."`

`inspect(zip, outDir)` (`outDir = stage/payload`, must not exist: `"Choose a new empty location for Sparking conversion."`)
extracts into `sprk-inspect-<uuid>` (`"Could not create Sparking conversion staging."`), checking
canonical containment (`"Unsafe Sparking path."`), CRC32 + size (`"Sparking resource checksum does not match."`),
per-entry <= 512 MiB and total <= 1 GiB (`"Expanded Sparking patch exceeds its supported size."`),
then renames to `outDir` (`"Could not commit staged Sparking resources."`). Entry roles by path:

| path | kind | relativePath |
|---|---|---|
| `patch_info.json` | `metadata` | same |
| `patches/localsql/*`, `localsql/*` | `localSql` | after prefix |
| `patches/sql/*` | `gameSql` | after `patches/sql/` |
| `patches/assets/*`, `assets/*` | `asset` | after prefix |
| `patches/Areas/*`, `Areas/*`, `areas/*` | `area` | after prefix |
| anything else | `other` | full path |

`relativePath` must pass `safe()`. Non-`other` kinds must be unique per `kind:relativePath`
(`"Sparking payload aliases would overwrite the same converted file."`). `patch_info.json` <= 1 MiB
(`"Sparking metadata exceeds1MiB."`), strict UTF-8, JSON nesting <= 32
(`"Sparking patch metadata is nested too deeply."`). A `gameSql` entry not ending in `.sql`
(case-insensitive) counts as "outside the verified layout", as does any `other`.

Result: `{"format":"sparking-sprk","formatVersion":1,"patchInfo":{..},"creatorName":"..","creatorId":<long>,
"entries":[{"path","relativePath","bytes","sha256","kind"}],"gameSql":[..],"localSql":[..],"assets":[..],
"areas":[..],"warnings":[..],"bytes":<total>,"canConvertToEclp":<bool>}`;
`canConvertToEclp = gameSql non-empty && no localSql && no areas && nothing outside the layout`.
Warnings (in order, when applicable):
`"This patch has no patch_info.json; keep its file name and supply a creation name."`,
`"No patches/sql game-database payload is present. Assets or local roster data alone cannot create an Eclipse unit."`,
`"This patch contains Sparking-only local roster SQL. It cannot be applied to Eclipse's game database."`,
`"This patch contains Sparking Areas content whose Eclipse mapping is unverified."`,
`"This archive has payloads outside the verified conversion layout. They need inspection before an Eclipse conversion."`
`creatorName`: first non-blank trimmed string of `creator_name`, `creatorName`, `creator`, then of
`creator.name`, `creator.creator_name`, `creator.creatorName`; else `""`. `creatorId`: first of
`creator_id`, `creatorId`, `creatorID` (top level, then in `creator`) whose `String.valueOf` matches
`[0-9]{1,10}` and is in 1..2147483647 (booleans skipped); else 0.

`convert`: stage dir missing → `"Could not create Sparking conversion staging."`; output exists →
`"Choose a new output file for Sparking conversion."`; not convertible →
`"This patch uses Sparking features that cannot yet be converted safely to Eclipse."` + `" " + warning`
for each warning. Metadata: `name = patchInfo.name || patchInfo.patch_name || filename minus .sprk`,
trimmed, `"Imported Sparking patch"` if empty, max 160 chars; `version = patchInfo.version` trimmed
(default/invalid → `"1.0"`, max 50); metadata JSON `{"uuid","name","version","author":creatorName,
"description":patchInfo.description,"sourceFormat":"sparking-sprk","sourceFilename","sourceZIPsha256":sha256(zip),
"compatibility":"Format converted; Eclipse SQL and gameplay compatibility need validation in Eclipse."}`.
ECLP entries: `gameSql` → `files/sparking-sql/<relativePath>`, `asset` → `files/<relativePath>`
(an asset ending in `.sql` → `"A Sparking asset ends in .sql and could be executed by Eclipse. Conversion was stopped."`;
case-insensitive NFC collision → `"Sparking SQL and assets would overwrite the same Eclipse file."`;
file-vs-folder → `"An Eclipse file would overwrite a converted resource folder."`), plus
`sparking-source.json` (= patchInfo) and `metadata.json`; written by `EclpCodec.write` (ECLP format:
see the ECLP spec). Output deleted on error. Returns the inspect object plus `"metadata"`.

### A.7 Sparking database cipher (SQLCipher 4 defaults; `LegacyDatabase.decrypt(.., mode 4)`)
Parameters: page size 4096, reserve 80 bytes per page (16-byte IV + 64-byte HMAC), KDF
PBKDF2-HMAC-SHA512 with 256,000 iterations, HMAC-SHA512. (Mode 3 = SQLCipher 3: 1024/48/SHA1/64,000;
not used by Sparking.)

```
pass = 64 ASCII bytes from sparking-database-format.bin   (used as raw passphrase bytes)
salt = file[0..16)
encKey  = PBKDF2(HMAC-SHA512, pass, salt, 256000, 32 bytes)
macSalt = salt XOR 0x3a (each byte)
macKey  = PBKDF2(HMAC-SHA512, encKey, macSalt, 2, 32 bytes)
for page n = 1..N (N = fileLen / 4096; fileLen must be >= 4096, <= 512 MiB, multiple of 4096):
  p = page bytes; off = (n == 1) ? 16 : 0
  mac = HMAC-SHA512(macKey, p[off .. 4032) || uint32LE(n))      // covers data + IV
  require mac == p[4032 .. 4096)   else "Database authentication failed. The file is damaged or does not match this imported APK's supported format."
  plain = AES-256-CBC-decrypt(encKey, iv = p[4016 .. 4032), p[off .. 4016)), no padding
  if n == 1: require plain[0..2) BE == 4096, plain[4] >= 80, plain[5] == 64, plain[6] == 32, plain[7] == 32
             else "The decrypted database has an unsupported SQLite header."
             out += "SQLite format 3\0" (16 bytes)
  out += plain; out += 80 zero bytes
```
The output keeps the reserved-bytes value (80) in its header, which SQLite accepts. Other errors:
empty or > 4096-byte key → `"The imported APK did not provide a supported database format."`;
bad output path → `"Choose a separate safe database output file."`; bad size →
`"This legacy database is incomplete or uses an unsupported page format."`; trailing bytes →
`"The legacy database changed during import."`; rename failure →
`"Could not save the authenticated database."` Written to `legacy-db-<uuid>.tmp`, fsync, rename.
WebCrypto note: PBKDF2/SHA-512 and HMAC are available, but AES-CBC in WebCrypto always strips PKCS#7
padding; do this natively (CommonCrypto `CCCrypt` without `kCCOptionPKCS7Padding`), or a 256k-iteration
PBKDF2 plus 100 MB of CBC in JS will also be slow.

### A.8 Shared validators
* `safePath(p)`: false if null, empty, > 500 chars, starts with `/`, contains `\`, matches
  `.*[:\x00-\x1f].*`, or has an empty/`.`/`..` segment (split on `/` keeping empties).
* `readText(file, limit)`: UTF-8 file read, fails above `limit` bytes (exact message belongs to the
  core spec).

### A.9 `verifyDb(file, strict=true)` (shared, summary)
`PRAGMA quick_check` must return `ok` (`"Database integrity check failed"`); required tables must exist
(`"Expected game data table: <t>"`) with required columns (`"Database is missing game fields: ..."`):
`cards(id,name,rarity,element,resource_id,hp_max,atk_max,def_max,passive_skill_set_id,leader_skill_set_id)`,
`card_categories`, `link_skills(id,name)`, `leader_skill_sets`, `leader_skills(leader_skill_set_id)`,
`passive_skill_sets(id)`, `passive_skills`, `passive_skill_set_relations(id,passive_skill_set_id,passive_skill_id)`
(exact per-table column lists: see the database spec). Returns `SELECT count(*) FROM cards`;
fewer than 1000 → `"The database contains starter or incomplete card data"`.

### A.10 XXH64 (`SparkingContent$XXH64`), streaming, seed 0
Standard XXH64 (verified: shifts are unsigned `ushr`; constants are the standard primes; initial
state is `v1 = P1+P2, v2 = P2, v3 = 0, v4 = -P1` = seed 0). The manifest stores the result as an
unsigned decimal string (`Long.toUnsignedString`). Reference JS implementation, tested against the
standard vectors (`""` → `ef46db3751d8e999`, `"abc"` → `44bc2cf5ad770999`) and chunked == one-shot:

```js
const M=(1n<<64n)-1n,P1=11400714785074694791n,P2=14029467366897019727n,
      P3=1609587929392839161n,P4=9650029242287828579n,P5=2870177450012600261n;
const rotl=(x,r)=>((x<<BigInt(r))|(x>>BigInt(64-r)))&M;
const round=(acc,lane)=>(rotl((acc+lane*P2)&M,31)*P1)&M;
const merge=(h,v)=>(((h^round(0n,v))*P1)+P4)&M;
class XXH64{
  constructor(){this.v=[(P1+P2)&M,P2,0n,(M+1n-P1)&M];this.buf=new Uint8Array(32);this.used=0;this.total=0;}
  lane(b,o){return new DataView(b.buffer,b.byteOffset+o,8).getBigUint64(0,true);}
  block(b,o){for(let i=0;i<4;i++)this.v[i]=round(this.v[i],this.lane(b,o+8*i));}
  update(b){let o=0,n=b.length;this.total+=n;
    if(this.used+n<32){this.buf.set(b.subarray(0,n),this.used);this.used+=n;return;}
    if(this.used>0){const k=32-this.used;this.buf.set(b.subarray(0,k),this.used);this.block(this.buf,0);o+=k;n-=k;this.used=0;}
    while(n>=32){this.block(b,o);o+=32;n-=32;}
    if(n>0){this.buf.set(b.subarray(o,o+n),0);this.used=n;}}
  digest(){const[v1,v2,v3,v4]=this.v;let h;
    if(this.total>=32){h=(rotl(v1,1)+rotl(v2,7)+rotl(v3,12)+rotl(v4,18))&M;h=merge(h,v1);h=merge(h,v2);h=merge(h,v3);h=merge(h,v4);}
    else h=P5;
    h=(h+BigInt(this.total))&M;let i=0;const p=this.buf;
    for(;i+8<=this.used;i+=8)h=((rotl(h^round(0n,this.lane(p,i)),27)*P1)+P4)&M;
    if(i+4<=this.used){const w=BigInt(new DataView(p.buffer,i,4).getUint32(0,true));h=((rotl(h^((w*P1)&M),23)*P2)+P3)&M;i+=4;}
    for(;i<this.used;i++)h=(rotl(h^((BigInt(p[i])*P5)&M),11)*P1)&M;
    h^=h>>33n;h=(h*P2)&M;h^=h>>29n;h=(h*P3)&M;h^=h>>32n;return h;}   // .toString() == manifest "hash"
}
```
BigInt is slow for 100+ MB; on iOS prefer native Swift (`UInt64` with `&*`, `&+`) or xxHash's C code.
SHA-256: lowercase hex (`%02x`).

### A.11 How Sparking data feeds previews and exports
* Projects copied from Sparking carry `sourceDatabase:"sparking"`, a `sparkingVersion` (=
  `meta.latestVersion` at copy time), optional `sparkingEffectIds` (array of unique integers
  1..2147483647, max 1024: `"Choose up to 1024 Sparking animation effects."`,
  `"Choose valid Sparking animation effects."`, `"Choose unique valid Sparking animation effects."`),
  and `project.assets` entries with `source:"sparking"`, `sourceVersion`, `key` under `ASSETS/`.
* `previewAnimation` / the preview server pick the Sparking DB by version through
  `PreviewMetadata.databaseFile(ROOT,"sparking",version)`: version 0 → current DB, else the active or
  previous slot whose `meta.latestVersion == version`; otherwise
  `"This animation needs Sparking content version <v>. Restore or import that version before previewing; another version was not substituted."`;
  no state → `"Download Sparking characters from Library before previewing this source."`; source names
  other than `""/"eclipse"/"sparking"` → `"Unsupported preview database source."`. Effect-pack IDs listed
  in `sparkingEffectIds` are resolved from the Sparking DB; a collision with an edited movie's effect ID →
  `"An edited movie and a Sparking effect cannot share the same preview effect ID."` For a Sparking source
  all metadata is local (`localOnly` → true); missing resources →
  `"This Sparking preview needs its matching imported character/effect resources. Download the selected unit's resources from Library; Eclipse metadata was not substituted."`
  (Preview internals: see the preview spec.)
* Exports never read the Sparking DB directly: the UI copies needed rows from Sparking
  (`querySparking`) into the project (`ForgeSparkingDependencies.collect`, `ForgeSparkingAnimationImport`),
  and resources are ordinary `ASSETS/sparking-<uuid>/...` files referenced by key, so export uses the
  generic asset pipeline (`exportSource`, `ExportAssetAudit`).
* Only one Sparking version is "current"; previous is kept for one update (GameDataStore keeps
  active + previous only). Resource downloads require `version == current` (A.4.1).

---------------------------------------------------------------------------------------------------

## Part B: AI

There are two separate features:
1. **Hand-off** (original app, `AiHandoff` + `MainActivity` launcher): copies a prompt and opens the
   official ChatGPT / Grok / Claude app or website. No network calls, no keys.
2. **Bring-your-own-key** (our `ForgeAi.java`): stores the user's API key natively and proxies HTTP
   requests built by `ai-connect.js` to the provider, with a start/poll/cancel job model.

### B.1 `ai` (args ignored; UI sometimes passes `{provider}`)
Opens the native "AI assistants" launcher screen (`MainActivity`) on the UI thread and returns
`{"opened":true}` immediately. The launcher lists the three providers of B.2 and opens the chosen
one; its preference (`SharedPreferences "orbit"`, key `preferApp`, default `true`) chooses between
"App first, then website" and "Always use the browser". Texts include the title
`"How should Dokkan Unit Creator open your AI?"`, the About dialog `"Your accounts. Your choice."`
and `"Unable to open <label>"` / `"No available app or web browser could open this service. Install or enable a browser, then try again."`
iOS: present an equivalent native sheet (or a JS dialog) and open the website URL (or the app's
universal link) with `UIApplication.open`.

### B.2 `aiCompose` args `{provider: "chatgpt"|"grok"|"claude", prompt: string}`
* `Provider.valueOf(provider.toUpperCase(Locale.ROOT))`; unknown → `Error: "Choose ChatGPT, Claude, or Grok."`

| enum | label | Android package | website |
|---|---|---|---|
| `CHATGPT` | `ChatGPT` | `com.openai.chatgpt` | `https://chatgpt.com/` |
| `GROK` | `Grok` | `ai.x.grok` | `https://grok.com/` |
| `CLAUDE` | `Claude` | `com.anthropic.claude` | `https://claude.ai/` |
(also `description`, `color`, `mark`: "Think, create, and explore."/#76D8B1/G; "A fresh perspective on
anything."/#CCD5EF/X; "Make room for your next idea."/#E9AA8D/C.)
* prompt blank (after trim), longer than 64,000 chars, or containing U+0000 →
  `Error: "Use a prompt between 1 and 64,000 characters."`
* On the UI thread: activity finishing → `"Return to the creator and try again."`; no clipboard →
  `"The clipboard is unavailable."`; copy the prompt to the clipboard (label
  `"Dokkan Unit Creator AI prompt"`); then try, in order: `ACTION_SEND text/plain` with
  `EXTRA_TEXT=prompt` targeted at the package → `transport:"share"`; the package's launch intent →
  `"clipboard-app"`; `ACTION_VIEW website` → `"clipboard-web"`. Any exception in this block →
  `"Could not open <label>. Your prompt may already be copied; open its official app and paste it."`
* Waits at most 15 s for the UI thread → `"Opening the assistant is taking too long. Check the selected app before retrying."`
* Returns `{"requested":true,"copied":true,"provider":"<label>","transport":"share"|"clipboard-app"|"clipboard-web"}`.
  UI shows `"Prompt copied. Send it in your assistant..."` when `copied` is truthy.
* iOS mapping: `UIPasteboard.general.string = prompt`; try the provider's app link (not knowable
  from this code; an `https://chatgpt.com/` etc. universal link opens the installed app if it claims
  the domain), else open the website → report `"clipboard-app"` or `"clipboard-web"`. A
  `UIActivityViewController` share sheet would correspond to `"share"`.

### B.3 Connection store (`ForgeAi`)
* File `ROOT/ai-connections.json` (max 1 MiB; unreadable or invalid → treated as `{}`); written via
  `ROOT/ai-connections.tmp` + fsync + rename (fallback: delete then rename; failure →
  `"Could not save the AI connection."`); then owner-only readable.
* Shape:
```json
{"openai":{"apiKey":"sk-...","model":"gpt-5-mini","imageModel":"","updatedAt":1761400000000},
 "custom":{"apiKey":"","model":"..","imageModel":"..","baseUrl":"https://host/v1","updatedAt":..},
 "_settings":{"active":"openai"}}
```
* Known providers: `openai`, `gemini`, `anthropic`, `xai`, `openrouter`, `custom`.
* **Keys never leave native code**: every bridge result uses `publicView`. `wipeData` with `{ai:true}`
  deletes both files and reports `"ai":true`.
* **iOS requirement**: store `apiKey` in the Keychain (e.g. service `ai-connections`, account =
  provider, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`), and keep the non-secret fields in a JSON
  file in Application Support. Never write keys into the WKWebView's file tree, localStorage or JS.

`publicView(provider, c)` =
`{"provider","hasKey":<apiKey non-empty>,"keyHint":"…"+last 4 chars if length > 4, else "set" if non-empty, else "",
  "model","imageModel","baseUrl","updatedAt":<long ms, 0 if absent>}` (the prefix is U+2026).

#### `aiConnections` (no args)
`{"connections":[publicView for each known provider key in the file, in file key order],
  "active":"<_settings.active or ''>"}`. UI falls back to the first connection when `active` is empty.

#### `aiSaveConnection` args `{provider, apiKey?, clearKey?, model?, imageModel?, baseUrl?, makeActive? (default true)}`
1. unknown provider → `"Choose an AI provider."`
2. `clean(v, max)`: trim; longer than max → `"A setting is too long."`; any char < 0x20 or 0x7F →
   `"Remove spaces or line breaks from the key and model names."`
3. if `apiKey` is present: `key = clean(apiKey, 512)`; a space inside →
   `"The API key cannot contain spaces."`; stored only if non-empty or `clearKey == true`
   (so an empty `apiKey` keeps the existing key).
4. `model = clean(args.model ?? old, 160)`; `imageModel = clean(args.imageModel ?? old, 160)`.
5. `custom` only: `base = clean(args.baseUrl ?? old, 300)` with trailing `/` stripped; must parse as a
   URL (Java `MalformedURLException` message otherwise, e.g. "no protocol: ..."), with scheme `https`,
   or `http` with host exactly `127.0.0.1`, a non-empty host and no user-info, else
   `"Use an https:// address (for example https://example.com/v1), or http://127.0.0.1 for an AI app running on this phone."`
6. non-custom without a stored key → `"Paste your API key to connect <provider>."` (provider id, e.g. `openai`).
7. `updatedAt = now (ms)`; save; if `makeActive` (default true) set `_settings.active = provider`.
8. Return `publicView(provider, c)`.

#### `aiRemoveConnection` args `{provider}`
Unknown → `"Choose an AI provider."`; deletes the provider entry; clears `_settings.active` if it
was that provider; saves; returns `{"removed":true}`. (iOS: also delete the Keychain item.)

### B.4 Requests: `aiStart` / `aiPoll` / `aiCancel`
Model: **no streaming**. `aiStart` launches a background request and returns a job id; JS polls
every 900 ms with `aiPoll` and gets the whole body when finished. JS gives up after 300 s
(`"The AI took longer than 5 minutes. Try again."`, calls `aiCancel`).

#### `aiStart` args `{provider, path, method?: "GET"|"POST", body?: object}`
1. Expire jobs older than 15 min. If 3 or more jobs are not done →
   `"Three AI requests are already running. Wait for one to finish."`
2. unknown provider → `"Connect an AI provider first."`; no stored entry → `"Connect <provider> first."`
3. `path` must match `/[A-Za-z0-9/._:\-?=&%]{1,300}` (whole string) and not contain `..`, else
   `"Unsupported AI request."`
4. method = `"GET"` only if exactly `"GET"`, else `"POST"`.
5. base URL:

| provider | base |
|---|---|
| `openai` | `https://api.openai.com/v1` |
| `gemini` | `https://generativelanguage.googleapis.com/v1beta` |
| `anthropic` | `https://api.anthropic.com/v1` |
| `xai` | `https://api.x.ai/v1` |
| `openrouter` | `https://openrouter.ai/api/v1` |
| `custom` | stored `baseUrl` (empty → `"Add the server address for your custom AI."`) |

6. POST body = `JSON.stringify(args.body)` if `body` is an object, else `"{}"`; > 24 MiB →
   `"This AI request is too large."` GET has no body.
7. Return `{"job":"<uuid>"}`; the request runs on a daemon thread.

HTTP request (`perform`): URL = base + path; redirects **not** followed; connect timeout 20 s,
read timeout 240 s. Headers:
* `Accept: application/json`
* `User-Agent: DokkanUnitCreation/2.12 (Android)` (iOS: e.g. `DokkanUnitCreation/2.12 (iOS)`)
* auth: gemini → `x-goog-api-key: <key>`; anthropic → `x-api-key: <key>` and
  `anthropic-version: 2023-06-01`; all others → `Authorization: Bearer <key>` only if the key is non-empty
  (custom may have none)
* openrouter → also `X-Title: Dokkan Unit Creation`
* POST → `Content-Type: application/json`, fixed-length body
Response: status >= 400 reads the error body, else the normal body; max 48 MiB
(`"The AI response is too large."`); decoded as UTF-8. Non-2xx statuses are **not** errors: they are
returned to JS (`status` + `text`). Exceptions set `job.error`: cancelled → `"Canceled."`; unknown
host → `"No Internet connection, or the AI server address is wrong."`; timeout →
`"The AI service took too long to answer. Try again."`; otherwise the exception message, or
`"The AI request failed."` if it has none.

#### `aiPoll` args `{job}`
* unknown/expired/cancelled id → `"This AI request is no longer available. Try again."`
* running → `{"done":false,"seconds":<whole seconds since start>}`
* finished → the job is removed; if it has an error, reject with it; else
  `{"done":true,"status":<http status>,"text":"<body or ''>"}`

#### `aiCancel` args `{job}`
Removes the job, marks it cancelled, disconnects the connection; always returns `{"canceled":true}`.

#### Requests the UI builds (`ai-connect.js`), for reference/testing
Default models in JS: openai `gpt-5-mini` / image `gpt-image-1.5`; gemini `gemini-flash-latest` /
`gemini-3.1-flash-image`; anthropic `claude-sonnet-5-5` (no images); xai `grok-4` /
`grok-imagine-image`; openrouter `openrouter/auto`; custom none.
* chat, anthropic: `POST /messages` `{model,max_tokens:4096,system,messages:[{role,content}]}`;
  reads `content[].text` where `type == "text"`.
* chat, gemini: `POST /models/<encodeURIComponent(model)>:generateContent`
  `{systemInstruction:{parts:[{text}]},contents:[{role:"user"|"model",parts:[{text}]}]}`;
  reads `candidates[0].content.parts[].text`, `promptFeedback.blockReason`.
* chat, others: `POST /chat/completions` `{model,messages:[{role:"system",content:system},...]}`;
  reads `choices[0].message.content` (string or parts array).
* image, gemini: `POST /models/<model>:generateContent` with
  `generationConfig:{responseModalities:["IMAGE"],imageConfig:{aspectRatio:"2:3"|"1:1"}}`; reads
  `inlineData|inline_data {data,mimeType|mime_type}`.
* image, others: `POST /images/generations` `{model,prompt,n:1}` + openai
  `{size:"1024x1536"|"1024x1024",output_format:"png",background:"transparent"|"auto"}`, otherwise
  `response_format:"b64_json"` (custom also `size`); reads `data[0].b64_json`.
* model list: `GET /models` (gemini: `GET /models?pageSize=200`); reads `models[]` / `data[]`.
* Error display: when `status >= 400` or the body is not JSON, JS shows
  `"<provider name> error <status>: <json.error.message | json.error | json.message | first 300 chars>"`.
* Connection test after saving: a chat with `"Reply with exactly: Connected"`.

iOS implementation notes: a `URLSession` data task per job (dictionary id → task + result), same
limits, same header set; disable redirects in the task delegate; map `NSURLErrorCannotFindHost` /
`NSURLErrorNotConnectedToInternet` to the unknown-host message and `NSURLErrorTimedOut` to the timeout
message; set `timeoutIntervalForRequest` = 240 s. Keys are read from the Keychain only inside the
native request builder. App Transport Security: allow `http://127.0.0.1` (`NSAllowsLocalNetworking`)
for the custom provider.

---------------------------------------------------------------------------------------------------

## Unknowns / caveats
* `bridge.js` on iOS posts to `window.webkit.messageHandlers.ForgeIOS` and expects replies via
  `window.__forgeReply({id, ok, result|error})`; there is no progress channel, so long tasks rely on
  `importStatus` polling (the progress object described above).
* Exact real-world manifest contents (other fields, query strings on URLs, real sizes) could not be
  checked: the Sparking servers are unreachable from this sandbox. Behaviour is inferred from code only.
* In `SprkCodec.central` the branch for directory entries with a nonzero size is ambiguous in the
  smali listing; treat it as a rejection.
* `sparkingAnimationSource` control flow is garbled in the Java; the "manifest `lua/<path>` first,
  then `ab_script.cpk`" order is inferred.
* The space-less messages (`"exceeds32MiB."`, etc.) are as stored in the dex.
* iOS equivalents of Android package resolution (`share` vs `clipboard-app`) and the provider app
  URL schemes are not in this code.
* `verifyDb` per-table column lists, `CpkArchive`, `EclpCodec.write`, `importArchive`/`importEclp`
  and the preview server internals belong to other specs and are only summarised here.
* The 64-character Sparking DB passphrase and the SPRK key exist only inside the user's APK (offsets
  487092 and 648423 of a `libbase.so` with the SHA-256 above); they are not in this repository.
