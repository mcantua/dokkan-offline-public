# HANDOFF — Dokkan Unit Creator (Android APK + iPhone web version)

> **Standing rule (user, Oct 27):** after EVERY change, rebuild (`python3 web/build.py`) and republish the pinned web test page https://claude.ai/artifact/L5VyXXXeoNXwYNuWuF8g6x (files map: every hashed file that changed — app.*.js, app.*.css AND start.*.js — plus any new file in web/site-artifact; old names → null), even when the change is mostly in the Android/iPhone apps. Before publishing, compare `find web/site-artifact -type f` with `Artifact list scope=files`: a missing start.*.js broke the page once (v44, fixed in v45).

You're taking over an ongoing project from another Claude session. This document covers what was built, what's in progress, what's next, and exactly how each step is done. Read it all before starting.



## BUILDS ONLY WHEN THE USER SAYS SO (user rule, 27 Oct 2026 5:04 PM)
Don't make new APK/IPA builds after changes. Fix and test the app in the web test page (sidebar artifact, still updated after every change); build only when he asks. When he does, it's 3 builds:

## EVERY RELEASE = 3 builds (user rule, 27 Oct 2026)
Every time the Android APK and iPhone IPA are made, also make the **iPhone Duo version**, the same way as v2.35.2 (docs/IPHONE-DUO-DISPLAY.md):
1. `VERSION=x BUILD=n bash ios-objc/build-ipa.sh` (check-duo.sh gate must pass) + `./build-from-release.sh n x-android`.
2. `python3 web/test_ios_duo.py` must pass (both displays, rail, fold).
3. Copy the IPA to the Mac `~/AI-Workspace/Dokkan-Unit-Creator/build/` (only the newest), double-click `run/device-install.command` (signs, installs on the iPhone Duo, logs the display), check `evidence/` (window = full screen, page width = window, dpr 3). Delete old evidence/builds.

## UPDATE (Oct 26, 2026 session, part 2): FULL iPhone app — read first
- The iPhone app is now a full port of the Android native layer, but **not yet run on a real iPhone**. Ask the user for screenshots.
- **Native (`ios-objc/`, Objective-C, built on Linux with `ios-objc/build-ipa.sh`):**
  - `Host.m`: the app:// scheme (site, `/__file`, `/__net`, `/__mirror`); `ForgeHost` actions (files, downloads, SQLite, Keychain, share, `saveDocument`, `sha256`/`hashes`(XXH64), `sqlcipherDecrypt`, `sprkDecode`, `network`, `aiRequest`); bundled DBs are symlinked.
  - `Player.m`: the loopback preview server that forwards to `ForgePreviewServer.handle`, plus the player panel.
- **JS (`web/src/ios-*.js`, loaded in order):** `ios-host`, `ios-native` (DB/query/sync/units/versions/AI/misc), `ios-formats` (PNG/LWF/@UTF/CPK/CRILAYLA/USM), `ios-preview` (PreviewCache/patches/server routes), `ios-player` (previewAnimation/dock/bootstrap/movies/recording), `ios-assets`, `ios-sparking`, `ios-offline`, `ios-io` (import/export/patches/APK). Plus `zstd.js`, a full decoder that `eclp.js` uses when present.
- **Specs** of every Android native method (decompiled with androguard): `/home/claude/decomp/specs/*.md`. They are not in the zip, so regenerate them with androguard if needed.
- **Tests** (stand-in for the iPhone: `web/ios_mock.py`):
  - `web/test_ios_full.py` (41 checks; `--sync` also downloads the 100 MB DB).
  - `web/test_ios_player.py <lua path|movie/...usm|...lwf>` (the real Eclipse player end to end, needs dokkan-eclipse.com allowed).
- **Build:** `python3 web/build.py && ios-objc/build-ipa.sh`. The site goes to `web/site-ios`, the DBs to `web/ios-db` (journal_mode=DELETE, which is required).
- **Known gaps:**
  - Thumbnail offline interception (Android's OfflineLibrary.intercept) isn't ported; the main screen loads thumbnails from the network.
  - "Use Eclipse online" (`convert`) is hidden, as Android does on iOS.
  - Whether app:// is a secure context (crypto.subtle) is assumed true (WebKit registers scheme-handler schemes as secure). If .eclp export fails on device, that's the first suspect.

- **The iPhone .ipa is built on Linux, with no Mac or GitHub needed:** `ios-objc/build-ipa.sh` → `out/UnitCreator-<ver>.ipa`. It's an Objective-C app (`ios-objc/main.m`) compiled with clang 18 + ld64.lld (`-adhoc_codesign`) against `iPhoneOS16.5.sdk` from github.com/theos/sdks; the script does a sparse git clone into `/home/claude/iosbuild/sdks` (git clone works; the GitHub web/API endpoints return 403). Icons are plain PNGs (no actool), and Info.plist is written by Python. Rebuild after web changes: `python3 web/build.py && ios-objc/build-ipa.sh`. It's unsigned (ad-hoc); the user signs it with Sideloadly. Not yet tested on a real iPhone, so ask for screenshots.
- **v2.30.2 (versionCode 89) is released** (Round 42, APK + IPA built together). The next Android build is **90 / `2.30.3-android`**. Always build the APK and the IPA together at the same version.
- **The iPhone app project is done** in `ios/`: Swift WKWebView shell (`App/`), `project.yml` (XcodeGen), `.github/workflows/ios.yml` (unsigned IPA on macos-15), and `site/` (copy of `web/site-ios`, made by `web/build.py` and then `ios/sync-site.sh`). It's a local git repo with commits on `main`, ready to push. It is **not compiled yet**, because no Mac was available.
  - Files are served at `app://local/` via `SiteSchemeHandler`. Saving goes through the `ForgeFiles` message handler and opens the iOS Share sheet; the reply comes back as the `forge-file-saved` event (`web-native.js` `saveNative`).
  - Test the web layer with `python3 web/test_ios.py` (14 checks, using a fake ForgeFiles bridge).
- **GitHub is linked** now (account `mcantua`; the API at api.github.com answers as that user). But creating a repo (public or private) was **blocked by the permission classifier** and needs the user's explicit OK. Next step: create the repo (or have the user create `unit-creator`), `add_repo` it with push access, push `ios/`, watch the Actions run, fix any Swift compile errors from the logs, download the IPA and send it.

## 0. First message checklist (do this before anything else)

The user attaches **one file, `Dokkan-Handoff-Kit.zip`**, with this document. Unzip it first (`unzip -q <path>/Dokkan-Handoff-Kit.zip -d /tmp/kit`). It contains this `HANDOFF.md` plus these four files (in older handoffs they may have been attached separately):

| File | What it is |
|---|---|
| `dokkan-unit-creator-project.zip` | All source code, build scripts, tests and tools (about 16 MB) |
| `Dokkan-Unit-Creator-v2.30.0.apk` | The last released Android app. It is also the base for every new build. |
| `signing-key.zip` | The user's private release key (`.jks` + `KEY-INFO.txt` with the password). **Private: never print the password or publish this file.** |
| `unit-creator-web.zip` | The built iPhone web version (GitHub Pages ready). Optional, because it can be rebuilt. |

Then set up the workspace. Paths are hard-coded to `/home/claude/work`; keep that layout. If you can't, run `grep -rl /home/claude/work` and fix the paths.

```bash
mkdir -p /home/claude/work && cd /home/claude/work
unzip -q /tmp/kit/dokkan-unit-creator-project.zip          # creates the folders below in place
mkdir -p base && cp /tmp/kit/Dokkan-Unit-Creator-v2.30.0.apk base/
cp /tmp/kit/signing-key.zip .
./setup.sh      # extracts the game databases, restores 3 big player files from the APK, unpacks the key, checks tools
```

`setup.sh` must end with `setup OK`. If attachments are missing, ask the user for them. Don't try to recreate them.

## 1. Who the user is and how to work with them

- They build custom Dokkan Battle units for **Dokkan Eclipse** (a fan-made Dokkan private server/mod). The app makes those units and exports `.eclp` files for Eclipse.
- **Phones:** a Google **Pixel 10** (Android) and a 2026 iPhone they call the "iPhone Duo" (iOS 26, probably foldable). They use a PC. They aren't a developer.
- **They want everything "stupid proof"**: beginner-friendly, minimal options, plain words, big obvious buttons, smooth on phones. They reject confusing UI quickly ("still very confusing"). When unsure, ask one focused multiple-choice question (AskUserQuestion), then build.
- They report problems with phone screenshots plus short messages. Fix the root cause, then **test it yourself before delivering**. They expect delivered builds to work.
- **Every Android round delivers:** the signed APK, an updated `deliver/CHANGES.md` (new "Round N" section), and a source zip. Keep replies short: what changed, the file, one next step.
- **They asked for "everything done for them."** Do all the work. Only ask them for things you're truly not allowed to do (create accounts, sign in, enter passwords, connect GitHub).

### Hard rules (keep these)
- Never send the user's account email address anywhere (no requests, headers, commits).
- AI API keys live only in Android native storage. Never export them, and never put them in files or the web version.
- Never disable TLS verification or unset `HTTPS_PROXY` in the sandbox.
- The sandbox can't reach `dokkan-eclipse.com` (proxy 403). Don't retry through other routes, and code must cope without it. The npm registry also returned a 403 "security policy" error, so avoid npm-dependent plans or check once first.
- Don't publish the signing key or the user's private data.

## 2. What the product is

**Android app "Dokkan Unit Creator"** (package from the original APK, `com.personal.aihub`). It's a native Android shell (Java, `CreatorActivity`) with a WebView that shows the UI in `assets/ui/` (HTML/CSS/JS). The UI talks to native code through a bridge (`Native.call(method, args)` in `v2/ui/bridge.js`).
- Bridge order in `bridge.js`: `window.forgeNative.call` → `webkit.messageHandlers.ForgeIOS` → `window.ForgeAndroid` → `forgeTestBridge`.
- The original APK came from an earlier "Beginner Test" build. We never had its Android Studio project. Everything is done by patching the APK:
  - **UI**: replace files in `assets/ui/` (source of truth: `v2/ui/`).
  - **New native code**: our own classes in `classes2.dex`, from `dock/src/com/personal/aihub/*.java`: `ForgeFixes` (dispatch for new bridge methods, DB refresh, wipe, openStore…), `ForgeAi`, `PreviewDock` (in-app animation player window), `OfflineLibrary` (offline downloads), `MovieCache` (converted MP4 cache).
  - **Hooks into the original code**: a few smali patches in `classes.dex` (see `patch/dock_smali.py`). These are **already inside the v2.30.0 APK**.
  - **Binary manifest**: `patch/AndroidManifest-v87n.xml`; the version is set with `patch/axml_version.py`.
- Main features: Card Builder (all unit fields, leader/passive/supers/active/transformations/links/categories/EZA), Quick Create, templates, copy from units/characters, AI helper (connect own AI or copy & paste mode), Combat practice, Animate (parts editor: join parts of several moves, play-and-tap), in-app animation player (Eclipse lua-player, patched), offline downloads of game files/movies, character finder with filters, Settings → Game data (one-tap newest database), Library, and `.eclp` / `.json` export and import.

**The `.eclp` format** (must stay byte-compatible with Eclipse):
- Layout: `"ECLP"` | u16 1 | u32 metaLen | metadata JSON | 32-byte salt | 12-byte nonce | AES-256-GCM(payload, 128-bit tag)
- Payload: u32 count, then for each entry: u16 pathLen, path, u64 stored length, u64 size, zstd frame
- Key: Argon2id(v0x13, t=3, m=65536 KiB, p=4, 32 bytes) of password = SHA-256(`uuid|name|version`) ‖ hex `ef16bc5f9378dc3fef16bc5f937ed622f910b35a9e76b8478b15d32be96dbf4c`
- Entries: `metadata.json`, `files/*.sql`, `forge-project.json`. Android uses zstd level 3.

Units get 8-digit card IDs ending in 1 (97000001…), and SQL uses `INSERT OR REPLACE` (see CHANGES Round 2).

## 3. What has been done (history)

The full history is in `deliver/CHANGES.md` (Rounds 1–40). Highlights:
- Rounds 1–10: export crashes fixed, Eclipse-compatible IDs, Card Builder, own-AI connections, no overwriting of game cards, EZA/Super EZA, Quick Create, templates.
- Rounds 11–18: in-app animation player, offline downloads, clip/movie editors, beginner redesign, Dragon Ball icon and the name "Dokkan Unit Creator", timeline editor.
- Rounds 19–30: clearer screens, copy from a unit (any animation on any move), combining character versions within the meta, passive text written like Dokkan's, the big overhaul, a simple "Update & import".
- Round 31 (v2.26.2): character finder with filters, plus one-tap newest database in Settings.
- Rounds 32–36: smooth Animate player with voices in sync (wall-clock pacing), fewer options, Animate with sliders, fast videos (persistent MP4 cache), downloads include movies.
- Round 37 (v2.29.0): **"Play and tap" parts editor**. The user's goal is to *join parts of several moves*, by *playing and tapping buttons*. This is the current Animate UI (`v2/ui/beginner-tools.js`).
- Round 38 (v2.29.1): offline download fix (`sp0111.lua` "Unreadable script" now counts as missing, not a failure).
- Round 39 (v2.29.2): Animate lag on very sharp screens (Pixel 10): DPR caps, seek coalescing, fast colors.
- Round 40 (**v2.30.0, versionCode 87**, current release): optimized for every Pixel and Samsung phone from 2020 on (`compat.js` polyfills and device tiers, `perf.js` auto-lite, WebView-too-old banner, `configChanges` in the manifest).

**iPhone web version (this session, not an APK):**
- The same UI runs in Safari with `web/src/web-native.js` standing in for the Android bridge:
  - Game data: per-table JSON, gzipped and bundled into 12 parts.
  - Units: IndexedDB.
  - `.eclp` export: done in the browser (`web/src/eclp.js` + `argon2.js` in a worker). Verified byte-compatible: the Android decoder opens web-made files.
  - Plus `.json` backup/import and offline support (service worker).
- Android-only parts are hidden on the web: animations, previews, offline packs, APK import, Sparking, "Connect an AI". The AI helper still works in copy & paste mode.
- **GitHub Pages build:** `web/site/`, delivered as `unit-creator-web.zip`.
  - 83 files, because GitHub's upload page takes at most 100 files at a time.
  - Includes `web/publish.yml`, a GitHub Actions workflow that unpacks the newest uploaded zip and deploys it.
  - Tested in Chromium at iPhone size and when unfolded, plus offline. **Not tested on real iOS Safari** (no WebKit in the sandbox).
- **Claude-hosted copy:** `web/site-artifact/`, published as the artifact https://claude.ai/artifact/Qq87wChxzpwgeEdPMKRLz4. It's owned by the user's *other* Claude account, so you can't update it from a new account; publish your own if needed.
  - Units are saved in the artifact `db` capability (private per user, gzipped and base64, chunked under the 256 KiB doc limit).
  - Files go through the `downloads` capability. `.eclp` isn't on its allowlist, so it's wrapped in a `.zip`.
  - Data is shipped as `.b64.txt`, because artifacts don't serve `.gz`.
  - No service workers, so it doesn't work offline.
  - Character images are blocked (CSP), so finder tiles show letters.
- **Why offline iPhone use isn't live yet:** offline needs a real site (service worker), and GitHub isn't connected. `list_repos` says no account is linked, and the `gh` token in the sandbox is invalid. The user wants offline on iPhone, which is why they asked for an IPA.

## 4. What's next (priority order)

1. **Offline iPhone app.** The user asked for a working **.IPA**. See §7 for the plan and constraints. Also offer the quicker win, the PWA on GitHub Pages (§6), which is offline and needs no 7-day re-signing.
2. **Keep the Android APK working and improving.** The next release is versionCode **88**, versionName **`2.30.1-android`** (must stay the same length as `2.30.0-android`). The only source change since v2.30.0 is in `v2/ui/shell.js`: sidebar shortcut buttons now have `data-side-go="…"`, with no visible change on Android.
3. Web/IPA gaps, if the user wants them:
   - **Opening Android-made `.eclp` on web/iOS:** needs a zstd decompressor in JS (compressed blocks). Web-made files use raw blocks.
   - **Animations on iPhone:** the Eclipse lua-player plus movie pipeline need `dokkan-eclipse.com` assets and the Android native movie converter. That's a big job; plan it with the user first.

## 5. How to build and test the Android APK

### Build a release (tested: rebuilding v2.30.0 this way gives an identical `classes2.dex` and manifest, and the same certificate)
```bash
cd /home/claude/work
./build-from-release.sh 88 2.30.1-android
# → out/Dokkan-Unit-Creator-v2.30.1-android.apk  (zip-aligned, signed v2+v3 with the user's key)
```
What it does:
1. Compiles `dock/src/*.java` (Java 8 target) against `dock/build/stubs` + `dock/app-v2.jar`, then turns it into `classes2.dex` with `tools/dx-30.0.2.jar`.
2. Sets the version in `patch/AndroidManifest-v87n.xml`.
3. Copies the base APK, replacing `assets/ui/*` with `v2/ui/` (removes files deleted there, adds new ones).
4. Signs with `tools/uber.jar` (uber-apk-signer).

The certificate SHA-256 must be `9d274247a6284dfa28b867439cbc2b7f9b87530ba4dd79e84f8423676b99fafa`. Check with `keytool -printcert -jarfile <apk>`. Android only installs updates signed with the same key.

**Smali hook changes** (rare; only if you must change the original `CreatorActivity` code):
1. Download apktool 2.x from GitHub (iBotPeaches/Apktool).
2. Run `apktool d base/Dokkan-Unit-Creator-v2.30.0.apk -o dec`. The hooks from `patch/dock_smali.py` are already applied there.
3. Edit `dec/smali/com/personal/aihub/*.smali`, then run `apktool b dec -o hooked.apk`.
4. Extract `classes.dex` and build with `CLASSES_DEX=/path/classes.dex ./build-from-release.sh …`.

`build3.sh` is the original full pipeline from the pristine APK, kept for reference. It needs files that aren't in the bundle.

### Test (always before delivering)
The UI runs in headless Chromium against a faithful mock of the native bridge (`harness/native_mock.py` + `harness/harness.py`, using the real game DB in `apk/assets/`):
```bash
cd /home/claude/work/harness
FORGE_UI=/home/claude/work/v2/ui python3 finder_ui.py      # prints PASS/FAIL lines
```
- **Always set `FORGE_UI`.** The default points at an old copy.
- Test state goes into `harness/state-*` (some tests use `FRESH=1` to reset). Screenshots go to `/tmp/claude-0/sim/…`.
- Current suites, by most recently touched:
  - Animate and player: `tl_fixes.py`, `seq_perf.py`, `parts_ui.py` (Animate parts editor), `perf_all.py` (phone-speed timing)
  - Downloads and data: `offline_ui.py`, `data_ui.py` (import/update/delete data)
  - Card Builder: `leader_ui.py`, `unit_copy.py`, `super_copy.py`, `passive_copy.py`, `passive_classic.py`, `eza_flow.py`, `builder_ui.py`, `builder_crawl.py`, `special_crawl.py`, `special_ui.py`, `porg_ui.py`, `ucopy_fixes.py`
  - Other: `finder_ui.py`, `ai_flow.py`, `anim_pick.py`, `art_studio_ui.py`, `id_audit.py`
- Run the suites for whatever you touched, plus `builder_crawl.py` for builder changes. Add a new test file for each new feature. Old ones live in `harness/retired/`.
- Check `.eclp` files with the real Android decoder:
  ```bash
  java -XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal -Djava.library.path=/home/claude/work/tools -cp tools/eclp-check/app.jar:tools/eclp-check/stubout:tools/eclp-check X file.eclp outdir
  ```
  The verification flags are needed because of a BouncyCastle VerifyError.

### Deliver
- Add a "Round 41 — … (v2.30.1, versionCode 88)" section to `deliver/CHANGES.md`. Use the existing style: problem, fix, files.
- Send the APK, CHANGES.md and a source zip with SendUserFile.

## 6. How to build and test the web version

```bash
cd /home/claude/work/web
python3 build.py            # → site/ (GitHub Pages, 83 files) and site-artifact/ (Claude artifact copy)
python3 test_web.py         # 24 checks: start, finder, build unit, save/reload, .eclp export (+ Android decoder), .json, import
python3 test_web2.py        # 16 checks: menus, offline via service worker, unfolded and landscape layouts
python3 test_hosted.py      # 17 checks: Claude-hosted copy with mocked db/user/downloads
```

How the build works:
- `build.py` copies `v2/ui` (skipping the Android movie engine, `vendor/media/*` except `preview-opponent-scenes.js`).
- It bundles all `<script>`/CSS into `start.*.js`, `app.*.js` and `app.*.css`, adding a leading `;`; that bundling is why the page loads fast and stays under the file limit.
- It converts `apk/assets/reference.db` into `data/db/part*.json.gz` (grouped by when tables are needed; order in `src/table-order.json`).
- It patches `index.html`, writes `sw.js`, and asserts at most 95 files.

Gotchas:
- The app's CSP blocks inline styles and `eval`. Set `element.style` in JS, and don't use Playwright `wait_for_function`; poll with `evaluate` instead.
- Playwright `evaluate` awaits a returned promise. For functions that open a dialog and wait for the user, use `void fn()`.
- `[hidden]` can be overridden by display rules, so add `[hidden]{display:none!important}` where needed.

**Put the PWA online (offline on iPhone):** the user must connect GitHub to Claude (claude.ai → Settings → Connectors/GitHub) and have a GitHub account. Only they can do that.
1. Create a public repo, e.g. `unit-creator` (the user can, or you via the API if you have credentials).
2. Push `web/site/` contents to `main` and set Pages to **Deploy from branch: main / root**. `.nojekyll` is included.
   - Or use the zip + `web/publish.yml` route (Pages source = GitHub Actions). It's documented for the user in `Put-it-online-iPhone.md` in the old session's deliveries.
3. The user opens `https://<user>.github.io/unit-creator/` in Safari, then **Share → Add to Home Screen**. It then works offline, and IndexedDB isn't purged for Home Screen apps.
4. Updates: rebuild and push. The service worker cache name includes a content hash.

## 7. Plan for the iPhone .IPA

**Constraints (tell the user plainly):**
- An `.ipa` must be built on macOS with Xcode. The sandbox is Linux, so build it in **GitHub Actions on a macOS runner**. That needs GitHub connected (§6).
- An installable IPA must be **signed**. Without a paid Apple Developer account ($99/yr), the user signs it on their PC with **Sideloadly** (or AltStore) using their free Apple ID. It then expires after **7 days** and must be re-signed (Sideloadly can auto-refresh, or reinstall weekly). With a paid account: 1-year signing or TestFlight.
- So deliver an **unsigned `.ipa`** from CI, plus clear Sideloadly steps.

**Recommended design: a thin native wrapper around the web build (offline by nature).**
- **Project:** a Swift (UIKit or SwiftUI) app with one `WKWebView`, generated with **XcodeGen** in CI (`brew install xcodegen`, `project.yml` in the repo), so there's no hand-written `.pbxproj`. Bundle ID e.g. `com.dokkanunitcreator.ios`, display name "Unit Creator", the app icon from `web/src/static/icons/` (make a 1024 px icon), and iOS 16+.
- **Serve the bundled site** (`web/site/` without `sw.js`) through a `WKURLSchemeHandler` on a custom scheme such as `app://local/`:
  - Map the request path to `Bundle.main` / `site/…` and return correct MIME types (`.js`, `.css`, `.json`, `.gz`→`application/gzip`, `.ttf`, `.png`).
  - `file://` won't work: workers (Argon2) and `fetch` of the data files need a real origin.
  - Use the default persistent `WKWebsiteDataStore` so IndexedDB survives, and verify IndexedDB works on the custom scheme (Capacitor uses the same approach).
- **Service worker:** it isn't needed and won't register on a custom scheme. `web-ui.js` already catches the failure. Strip `sw.js` from the bundle.
- **Saving files:** WKWebView doesn't reliably handle `<a download>` or blob links, and Web Share may be unavailable.
  - Add a message handler **`ForgeFiles`**. Don't reuse `ForgeIOS`, because `bridge.js` treats that one specially.
  - In `web-native.js` `saveFile()`, add a branch: if `window.webkit?.messageHandlers?.ForgeFiles`, post `{name, base64}`.
  - Swift writes the file to a temp folder and presents `UIActivityViewController` ("Save to Files", AirDrop). The native app can save `.eclp` directly, with no zip.
- **Opening files:** `<input type=file>` works in WKWebView (document picker). Optionally register `.eclp`/`.json` document types in Info.plist for "Open in…".
- **External links:** handle `target=_blank` / `window.open` in `WKUIDelegate` by opening Safari.
- **Safe areas:** the page uses `viewport-fit=cover` and `env(safe-area-inset-*)`. Set `contentInsetAdjustmentBehavior = .never`.
- **CI workflow** (`.github/workflows/ios.yml`, `runs-on: macos-15` or `macos-latest`):
  1. Checkout, then `python3 web/build.py` (or commit the built site), then copy `web/site` into the app's resources.
  2. `xcodegen generate`.
  3. `xcodebuild -project App.xcodeproj -scheme App -sdk iphoneos -configuration Release -derivedDataPath build CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build`
  4. `mkdir Payload && cp -r build/Build/Products/Release-iphoneos/App.app Payload/ && zip -r UnitCreator.ipa Payload`
  5. `actions/upload-artifact`.
  6. Download the artifact (e.g. `gh run download`) and send the `.ipa` to the user.
- **Testing:** you can't run iOS here. Test the web layer in Chromium with the existing tests, plus a mock `window.webkit.messageHandlers.ForgeFiles` for the save path. Read the CI logs carefully, and ask the user for screenshots from the device.
- **User install steps to give them:**
  1. Install **Sideloadly** on the PC and connect the iPhone by USB (trust the computer).
  2. Drag in the `.ipa`, enter their Apple ID in Sideloadly (they type it themselves), then Start.
  3. On the iPhone: Settings → General → VPN & Device Management → trust the developer.
  4. Turn on **Developer Mode** if iOS asks (Settings → Privacy & Security).

## 8. Workspace map (inside the zip)

| Path | What |
|---|---|
| `v2/ui/` | **The app UI (source of truth).** Key files: `app.js` (core app, export/import), `bridge.js`, `builder.js` (Card Builder), `beginner-tools.js` (Animate parts editor), `finder.js` (character finder), `import-hub.js`, `settings.js`, `offline.js`, `animation-page.js` (player integration), `compat.js` (loaded first, ES5 polyfills and device tiers), `perf.js`, `shell.js` (navigation), `core.js` (SQL export), `index.html`. `vendor/media/*` is the movie/player engine (3 big `.wasm` files are restored from the APK by `setup.sh`). |
| `v2/ui-files.txt` | List of every UI file (used by `setup.sh`). |
| `dock/src/com/personal/aihub/` | Native Java added in `classes2.dex`. `dock/build/stubs` + `dock/app-v2.jar` are the compile classpath. |
| `patch/` | `AndroidManifest-v87n.xml` (current binary manifest), `axml_version.py`, `axml_config.py` (configChanges), `dock_smali.py` (the smali hooks, for reference), `res/ic_orbit.bin` (icon). |
| `harness/` | Test harness and tests (see §5). |
| `web/` | Web version: `src/` (web-native.js, web-ui.js, web.css, eclp.js, argon2.js, argon2-worker.js, sw.js, artifact.js, static/ manifest and icons, table-order.json), `build.py`, tests, `publish.yml`. |
| `tools/` | `uber.jar` (signer), `dx-30.0.2.jar` (dex compiler), `libzstd-jni` (for the decoder), `eclp-check/` (Android `.eclp` decoder test tool). |
| `build-from-release.sh`, `setup.sh` | See §0 and §5. |
| `deliver/CHANGES.md` | Full change history, written for the user. |

## 9. Lessons learned (avoid repeating these)

- **Phones are slow:** test with `perf_all.py` and keep work off the main thread. Low-end tier: `html.tier-low`.
- **The user's "laggy" reports are real.** The last round's lag came from devicePixelRatio 3+ canvases on the Pixel 10. The fix was DPR caps and coalesced seeks.
- **Downloads from Eclipse:** follow redirects, use UA `DokkanUnitForge/2.7`, and an unreadable script counts as *missing*, not an error.
- **Web hosting limits:**
  - GitHub's upload page takes 100 files per upload, and the iPhone file picker can't choose folders. Use a zip plus the workflow, or push via git.
  - Claude artifacts: no `.gz`, no service workers, the downloads allowlist excludes `.eclp`, and `window.open` is mostly blocked.
- **In the sandbox:**
  - `pkill -f <pattern>` can kill your own shell when the pattern appears in the command. Avoid it.
  - Don't `sleep` in the foreground. Use background commands and Monitor.
- **Tone:** don't over-explain. The user wants it to work, and wants short, plain answers.

## iPhone foldable work (third IPA build)
- Native: `main.m` viewWillTransitionToSize → `__forgeFold.begin()/end()` (web/src/ios-ui.js), player relayout,
  SceneDelegate `didUpdateCoordinateSpace`; real memory/cores injected at document start; Host.m op `display`.
- CSS/JS: `web/src/ios.css` (forge-resizing, `.fd-tile{content-visibility:visible}`, More-menu anchoring), ios-ui.js
  (async image decoding, menu clamping, Settings "This iPhone's screen").
- Check: `web/test_ios_duo.py` (all pass). Same two finder/menu issues exist in the shared v2/ui code used by
  Android (perf.css `content-visibility:auto` on `.fd-tile`); not changed there yet.
- Not verifiable here: real foldable hardware (exact screen sizes, the hinge transition, ProMotion 120 Hz in WKWebView).
- **iPhone Duo native screens (Oct 26):** official sizes (apple.com/iphone-duo/specs): outer 1398×2034 px, inner 1878×2670 px
  → 466×678 / 626×890 pt at 3x. Apps built before the iOS 27.1 SDK are letterboxed on the inner display, so
  `build-ipa.sh` now marks the binary as built for SDK 27.1 (`-Wl,-platform_version,ios,16.4,27.1` + DTSDKName) while still
  compiling with the 16.5 SDK (the public 27.1 SDK copy at github.com/xybp888/iOS-SDKs only has arm64e stubs and its
  modulemaps don't work with clang 18). `UIRequiresFullScreen` removed. Safe-area (status bar / Dynamic Island / home bar)
  handling added in `web/src/ios.css`; `web/test_ios_duo.py` checks every main screen on both displays, both orientations,
  with emulated safe areas (CDP `Emulation.setSafeAreaInsetsOverride`). Needs confirming on a real iPhone Duo.
- **Standing rule from the user (character lists, Oct 26):** show only fully awakened characters, and only the most
  advanced version: Super EZA if it exists, else EZA, else fully awakened. Never earlier awakenings, never a non-EZA copy
  when an EZA exists, never duplicates of the same character/transformation. Applies to game cards, transformation
  forms, Sparking cards and all future additions. Implemented in `v2/ui/dbz-home.js` (`transformations()`, `rankOf`);
  Eclipse keeps old pre-EZA copies at 90/91/95/96xxxxx (same name as the 10/11/20/40xxxxx current card) — hidden.
- **Levels 180/200 and SA 30 (Oct 26):** Basics menus offer Level 180/200 and SA level 30. The game's card_exps tables stop
  at 150, so `core.js` `extendLevels()` gives units above 150 exp_type 925 and exports 200 card_exps rows (ids 925001-925200:
  the LR type-25 curve for 1-150, then +3.5% per level to 255,971,482 exp at 200). EZA steps above 150 do the same.
  Untested in Eclipse itself: confirm in-game that levelling past 150 and SA 30 work.
- **Level perks (Oct 26, user's design):** Level 180 → team cost 88, SA level 30. Level 200 → team cost 99, SA level 30 + a permanent ATK & DEF +20%,
  added as its own passive ability (never merged into other boosts) named "Level 200 Exclusive", which gets its own
  "*Level 200 Exclusive*" heading in the passive text. Going back below 180 restores the earlier SA level and removes the
  boost. Code: `ForgeLevelPerks` at the end of `v2/ui/builder.js`; heading rule in `builder-model.js` `passiveText()`.
- **SLR / ULR rarity icons (Oct 26):** level 180 = SLR (Super Saiyan 2 look: spiky gold aura, blue-white lightning,
  rising sparks, molten gold letters), level 200 = GR — Godly Rare (Ultra Instinct look: silver-blue aura, white lightning, silver
  chrome letters with a rainbow sheen). `v2/ui/rarity-badges.js/.css` (`ForgeRarityBadge`): html() for the app (card
  preview, Home, Library, Basics line), draw() for card art. Art studio (`art-studio.js` applyBadge) draws them onto the
  thumbnail and card picture; plain copies are kept in `project.rarityBadgeBase` so the icon can be redone/removed.
  The web test page shows the icons; drawing on card art needs the phone apps (game art files).
- **GR restyle (Oct 26):** GR (Godly Rare, level 200) now uses a Super Saiyan God look: crimson divine flame aura,
  slowly turning golden god rays, rising embers, gold-to-ruby letters, no lightning. SLR keeps the SSJ2 gold + lightning.
- **Icons, final direction (Oct 26, user):** SLR = Super Saiyan 2 aura + lightning with LR-icon style letters (rainbow
  holographic metal, white rim, dark outline). GR = Super Saiyan God: tall crimson-orange god flame, red glow, embers,
  crimson letters (the halo/wings attempt was dropped).
- **Godly Power (Oct 26, user):** the level-200 boost is now named "Godly Power · GR Exclusive", sits at the top of the
  passive text, glows red in the app preview (game text only supports {passiveImg:…}, no colours), and reads "ATK & DEF
  20%↑, added after every other boost". It's two abilities: ATK +20% when attacking (timing 4) and DEF +20% when receiving
  an attack (timing 6) — the game's later stat stages, so they multiply on top of start-of-turn boosts. Older GR units
  are upgraded automatically the next time their level perks run.
- **Godly Exclusive (Oct 26, user):** heading renamed "Godly Exclusive" (top of the passive, red glow in the app). In the
  builder it shows as one locked red glowing card first in the ability list (the two game rows are hidden from the
  normal list) and as a red ribbon on the card preview. Mechanics per data/mechanics.json: timing 4 ("during the attack")
  and 6 ("just before receiving an attack") are the multiplicative stages, so the +20% multiplies the finished stats
  (leader, links, start-of-turn passive first). Text: "ATK & DEF 20%↑, applied after every other boost".
- **Godly Exclusive everywhere (Oct 26):** `syncGodly()` in builder.js puts the ATK/DEF pair + "*Godly Exclusive*" text
  block into every passive set: base, each EZA/Super EZA stage (stageGroups) and each transformation form (formProjects).
  It's rebuilt whenever out of step; units open in the builder are checked once (older GR units get repaired).
- **Automatic passive descriptions (Oct 26, user):** "Write the description for me" is on by default for every passive
  (all EZA stages). `autoWriteAll()` in builder.js keeps a signature of each passive's abilities (p.builderSig); any
  change — via Forge.addPassive/removePassive (wrapped) or rows pushed directly by other tools (checked on every card
  refresh) — switches it back on and rewrites that passive's text. Typing your own text works until the next change.
  Older units are switched to automatic once (p.autoTextV2).
- **No manual passive description (Oct 26, user):** the "Write the description for me" checkbox and the text box are
  gone; passive descriptions are always written automatically (`auto()` returns true for every "passive:" key). The
  Passive tab keeps the "How it looks in the game" preview. Active-skill descriptions still have their own option.

## Passive step: three buttons (web test copy v21)
- The Passive step now has only: **＋ Add an ability**, **★ Add a preset ability**, **⧉ Copy a character's passive**. "Organize & balance" and "Ask AI to design my passive" are gone from it (no `data-guide="copy:passive"` / `data-b="adding:on"` on the row, so passive-organize.js and presets.js no longer inject there).
- `tools/make_passive_catalog.py` → `v2/ui/data/passive-catalog.json` + `v2/ui/passive-catalog-data.js` (130 abilities from real passive_skills; defaults = most common values on LR/UR cards with id ≥ 1022000).
- `v2/ui/passive-catalog.js` (window.ForgePassiveCatalog): searchable grouped list (add mode opens the editor; preset mode shows the balanced line and adds as is), `describe(row)` wording for abilities the friendly editor can't decode (HP-based scaling, per-sphere boosts, type/class boosts, sphere changes, fixed growth…), and the copy chooser (copy one passive via the guide flow, or combine via ForgePassiveOrganize.pickCharacter()).
- builder.js: `ForgeBuilderUI.addRow(kind, fields, {open})` adds to the EZA step being shown (undo + auto description); abilities without a friendly editor get labelled value fields (`.bld-raw`).
- Not yet in an APK/IPA build.

## SLR Super Exclusive (web test copy v22)
- Level 180 (SLR) now gets **Super Exclusive**: ATK & DEF +10%, built exactly like the GR Godly Exclusive (+20%): ATK row timing 4 + DEF row timing 6 in every passive (before EZA, EZA steps, forms), heading at the top of the description. PERKS[180] = {sa 30, boost 10, cost 88, title "Super Exclusive"}; `titleFor(boost)` picks the name, so 180 ↔ 200 rebuilds the rows.
- Shown in Super Saiyan 2 gold (`.bld-super` on the locked card, the description heading/list and the card ribbon) instead of the Godly red.
- Not yet in an APK/IPA build.

## Leader Skill step cleanup (web test copy v23)
- "＋ Add another bonus tier" adds an empty Category tier (Ki +1, +30%, no categories); nothing is copied from existing tiers.
- Removed "Copy a character's leader skill" (and so the injected "Combine leader skills from characters") and the "Write the in-game description for me" checkbox: `auto()` now forces `leader:` keys on, so the description is rewritten on every tier add/remove/change.
- Leader name is randomized (ForgeSkillNames.random("leader")) the first time each leader set is opened (`p.leaderNamed` remembers set ids); the 🎲 button still re-rolls it.
- Quick starts: All Types Ki +3 / +170%, Super Class Ki +3 / +200%, Extreme Class Ki +3 / +200% (old preset keys still accepted).

## Simpler passive ability list (web test copy v24)
- passive-catalog.js groups the 130 game variants into 64 plain abilities (`concepts()`: same plain name = one entry; `plainName()` strips "— who" and "(fixed amount)", RENAME gives plain words). Tapping one adds its most-used variant and opens the editor.
- Who / when / how long / chance / conditions are set in the editor as before; abilities that exist as both % and fixed number get an "Amount is" select (`variantHTML`, `data-pcat-calc`), which swaps calc_option + values to that variant.

## Passive families editor (web test copy v25)
- New `v2/ui/passive-families.js` (window.ForgePassiveFamilies): 20 families (ATK & DEF, Ki, Critical hit, Additional attack, Effective vs all, Always hit, Dodge, Damage reduction, Guard, Counterattack, Foresee, Nullify, Recover HP, Survive & revive, Immune, Boost allies of a Type, Lower enemy stats, Stop the enemy, Change Ki Sphere colors, Drawback). Each family = slots [kind, growth, eff, sub, side, friendlyKey] mapping onto real game effects; every catalogue entry classifies into a family (tested).
- "＋ Add an ability" / "★ Add a preset ability" open the family list (builder `pcat` case). Adding uses the most-used game variant's defaults.
- Editor (builder.js `familyEditorHTML`): summary ("How it works in battle", updates live via softRefresh) → What it does (Kind, How it works = flat / grows / per Ki Sphere / chosen colors / one color / by HP / from damage, Amount % or fixed, values with checkboxes/selects for colors & types) → Who → When & how often (timing with help, how long, chance slider, once per battle) → Requirements & restrictions (condition editor; NOT via the advanced editor) → Duplicate / Add another effect at the same moment (copies timing, chance, duration, conditions) / Turn off (kept in `p.passiveOff`, "Turn on" restores) → ⚙ Advanced game settings (every timing/target/calc, raw values, sub-target set, efficacy_values).
- Rows with no family (transformations, giant form…) keep the old editor. `ForgeBuilderUI.commit` exported.

## Every passive in the game + character exclusives (web test copy v26)
- Catalogue now includes every effect/variant in the game's passive_skills (185 variants, 56 effect types; only unnamed internals 0/1009/1011 and 103 transformations — Transform tab — are left out). Character-exclusive 79 (giant/rage) and 131 (exchange) carry `choices`: every real setting in the game named by card ("Bardock (Giant Ape)").
- New families: Ignore enemy DEF (53), Block "attacks always hit" (129), and a Character exclusive group: Transformation (→ Transform tab), Giant / Rage form, Exchange, End transformation, Standby mode, Cancel a skill. DEF per one color uses 65.
- Nothing is greyed out: ATK & DEF + "grows" / "chosen colors" (no single game effect) become two abilities (ATK and DEF) set up the same way; Who lists every target for that side.

## Eclipse export check (web/test_eclipse_unit.py)
- Builds a GR unit with every passive family and every kind × growth combination (75), a requirement, a linked effect, a turned-off ability, an EZA-step ability and a 2-tier leader; exports the .eclp from the web build; opens it with the Android decoder (tools/eclp-check); runs the SQL on a copy of the real game DB and checks card (lv 200 / SA 30 / cost 99, card_exps to 200), passive relations, real effect/target/timing ids, conditions → skill_causalities, Godly rows, giant form → real card. All pass, as do test_web, test_hosted and test_ios_full.

## Editor clean-up (web test copy v27)
- Abilities with nothing to set show "✓ Nothing else to set" instead of raw "Unknown" value boxes (raw values only under ⚙ Advanced). "Amount is" only for effects with a visible number. Each "What it does" starts with the ability's plain description. Stacking: one "What makes it grow" control (no duplicate When). Cancel a skill uses two dropdowns; DEF per one color (65) and DEF down per Ki Sphere (60) got proper fields. Rare one-card defaults start always-on (100%, this turn).

## Slider + name conditions (web test copy v28)
- Chance slider is drawn by our CSS (-webkit-appearance:none track/thumb, filled with --p) — iPhone's system slider showed the knob in the wrong place at 100%.
- New conditions (builder-model CONDITIONS, game causality type 41): "A character with a certain name is on the team" (sub 0, count), "Facing an enemy with a certain name" (sub 1), "A character with a certain name attacks in the same turn" (sub 2). `v2/ui/name-sets.js` (ForgeNameSets) lists the game's 138 name groups by name; typing any name creates a unit-owned group (set id 9100001+, rows in card_unique_info_set_relations, labels in p.nameSetLabels) with every game card name containing it. Export test checks it (Frieza → 35 names).
- Summary "When" shows only the timing; requirements are under "Needs".

## Name search (web test copy v29)
- Name conditions use a 🔍 button that opens "Choose a character": search box, "Use “<typed>”" (creates a name only when picked), "Your names" with × (ForgeNameSets.remove also drops conditions using it via ForgeBuilderUI.dropConditions), and the game's characters (duplicate labels like the two "Cooler" groups shown once, the larger). The hidden select keeps data-cf for the condition editor.
- (v30) Name search folds accents ("Rose" finds "Rosé"), matches anywhere in the name, and lists every single matching character (all 1,069 game card names) — picking one makes a name group of just that character (create(name, true)). "Everyone named …" still makes a group of every card containing the text.
- (v31) Descriptions merge bullets by what they SHOW (builder-model visibleSig: timing phrase, target, chance, once, conditions, visible duration) instead of every hidden setting: 'All allies' Ki +3 and ATK & DEF 30%↑' in one bullet, same-looking boosts add up, and repeated additional attacks become 'Launches 2 additional attacks, each of which has…'.
- (v32) The "Combine passives" preview now shows the builder's own description (ForgeBuilderUI.describeSet, conditions looked up in the copied project) instead of passive-merge's text. Rows limited to a group of allies (sub_target_type_set_id, types 1/2) are written with their Category names ('"Saiyan Saga" Category allies' ATK & DEF 40%↑') via extra.subOwner; "<group> allies' Ki +N" joins that group's ATK/DEF line (joinOwnerKi); passive-merge's setRows skips Exclusive rows so Godly/Super Exclusive are never combined or capped (the preview had shown Godly as ATK 10% / DEF 15%). Super/Extreme Type bits named.

## Dokkan wording for every condition + strongest awakening (web test copy v33)
- `v2/ui/condition-words.js` (ForgeConditionWords): game wording for all ~70 causality types (Ki % → Ki: LR ×3/100, others ×4/100; status bits 16 ATK↓, 32 DEF↓, 256 stun, 1024 seal; "whose name includes", Domains from dokkan_fields…) and AND / OR / NOT ("unless"). Used by builder condInfo for custom rules and by describeSet; ForgeBuilderUI.loadCausalities(project) loads copied abilities' game condition rows + names before the combine preview, so "An inherited condition" no longer appears.
- passiveHeading names the moment once (drops "when attacking" when the condition already says attacker/attacking, Ki Spheres obtained, receiving…), "an" before vowel names, "as the Nth attacker in a turn", name/Category conditions in game wording. Abilities with extra efficacy_values are worded like the plain ability; stacking (98) worded for any timing.
- Strongest awakening is selected by default: stageKey picks the last unlocked EZA / Super EZA step; copying a character's passive/leader preselects their strongest stage.
- (v34) builder-model foldLadders: "per Category ally" boosts stored as copies with counts 1,2,3… (When there is a / another / another N or more … ally on the team / attacking in the same turn) are written as one line: 'Super Class allies' ATK & DEF 30%↑, plus an additional ATK & DEF 3%↑ per "Majin Buu Saga" Category ally on the team (up to 21%)'.

## Intro step + revival detail (web test copy v35)
- New Card Builder step "🎬 Intro" (`v2/ui/intro.js`, window.ForgeIntro; tab after Passive Skill): No intro / Has an intro; 1) scene (all 127 game entrance scenes + Make my own), 2) when it plays (upon entry, Category allies with count, ally name, Super/Extreme Class allies, Category enemy, enemy name; custom conditions from the Passive step kept), 3) bonuses that activate with it (once-only, start-of-turn, same condition; "Lasts" per bonus; ★ typical bonus Ki +3 / ATK & DEF 100% for 5 turns; ＋ Add a bonus via the family list), plus the in-game preview. Like the game, the scene (passive_skill_effect_id) rides on the first bonus row; without bonuses an effect-less (efficacy 0) row carries it.
- Descriptions: intro rows are written under "Activates the Entrance Animation [condition] upon the character's entry" (enemy conditions: "at the start of the character's attacking turn"), placed after Exclusive perks; once-only 1-turn abilities read "for 1 turn". Passive step shows an intro notice; Special Skills' intro card links to the Intro step.
- New conditions: classAllies (type 46), revived (47, "After the character's Revival Skill is activated"), allyRevived (54). Revival editor: scene + music (scene's own music by default, REVIVAL_BGM map) and "＋ Add a bonus after reviving".
- Export test covers the intro (scene id + condition in the game file).

## Clear "Who" + own revival animation (web test copy v36)
- Who labels: builder-model TARGETS reworded (1 "Only this character", 2 "The whole team (this character and every ally)", 16 "Every ally except this character", 3/4 enemies, 12-15 class); passive-families WHO/WHO_HELP + whoLabel/whoHelp give family-specific wording (revive: "This character — comes back to life itself" / "The team — when an ally is KO'd, that ally comes back").
- Revive editor: "🎬 Revival animation — Use my own animation / Edit my animation" (ownRevivalAnimation → Look tab studio:revival:passive_skills:<id>); scene change re-hydrates the animation source unless a custom one is assigned. guide-model targets() scans all passive_skill_set_relations (EZA stages too). Studio itself only runs in the Android/iOS apps.
- Two-character revive: condition 54 (allyRevived) is a persistent party flag — a transform/boost with it fires when that character rotates in, with its own transformation animation (no revival animation). Labels for 47/54 explain this.
- v37: Revival animation is ONE choice (field label "Revival animation"): "No animation", "★ My own animation", then game revivals named by character (no "Like"). passive-families reviveSceneHTML injects the own option/help; a capture-phase change listener opens the maker for "own" and, when a game revival is picked over your own, calls ForgeGuide.restoreAbilityAnimation and drops the assignment. The separate 🎬 bar was removed. Music options read "Music from <character>". Test: /tmp/claude-0/eclipsetest/revanim3.py.

## One animation choice for every move (web test copy v38)
- New `v2/ui/anim-choice.js` (window.ForgeAnimChoice, loaded before guided.js): `block(key, {label, original, help, extra})` for moves without a game list (Super/Ultra/EX, Active, Standby/Finish, transforms, normals, Look tab) and `enhance(html, bf, key)` turning a list field (counter v.anim, revival v.view) into the same choice. Options: current/game list (plain names, no "Like"), ★ Make my own (studio:key), ★ One of my saved animations (gallery:key), 🔍 Any attack animation in the game (pick-animation:key → browser kind "all"; studio.js animationFit/applyComposition converts across kinds). Picking a game option drops your own (dropOwn). onPrepare("revival:") readies the revival source first. Old bld-anim button bars removed from builder (supers, active, counters, Look) and guided.js Look/Moves.
- Counters: "Custom — only what you set in Requirements" option shows only when actually used. New "Reduce damage from" (The attacks it counters / All / Normal / Super / Ki-blast / Unarmed): when different, DR moves to a hidden eff 13 row (timing 6, COUNTER_COND causality) tracked in p.counterDR[counterId] = {row, what}; hidden from the list (PF.companionIds), removed with the counter. builder-model exports COUNTER_WHAT, COUNTER_COND, counterCond.
- Test: /tmp/claude-0/eclipsetest/c_anim.py.
- v39: First-launch download question (offline.js firstRun, called by shell.js before the welcome tour): Everything (packs essentials+everything, optional movies) / Essentials / Not now, Wi-Fi-only box, free-space warning under 7 GB; asked once (localStorage forge-offline-asked), skipped on web (status().web) and when anything is already downloaded/running. Settings → Animations has an Offline downloads button. Test: /tmp/claude-0/eclipsetest/first.py.

## Downloads in one visible folder (Round 43 work, not built yet)
- **Android:** new `dock/src/.../PublicStorage.java`. On Android 11+ the private folders `forge/preview-cache`, `forge/movie-cache`, `forge/animation-sources` become symlinks to `Download/Dokkan Unit Creator/Game files | Game movies | Animation scripts` (absolute targets). Called from `ForgeFixes.configureWebView` and `refreshBundledDatabase` (once per start); old private files move over in a background thread (`<name>.moving`). `.nomedia` in every folder; downloads are `<hash>.body/.json`, movies now `KEY.video` (MovieCache), scripts `.lua` → nothing looks like media. A folder from an earlier install (marker `.dokkan-unit-creator` with another install id) is never reused → "Dokkan Unit Creator (2)". `ensure()` recreates deleted folders (OfflineLibrary download/prepare, MovieCache keep, PreviewDock). Wipe uses `PublicStorage.clear` (keeps links). Android 8–10 stay private. Sparking `sparking/resource-cache` stays private (SparkingContent's canonical-path checks). Original code was checked for symlink/canonical checks on these paths: none.
- **iPhone:** `Host.m` maps `preview-cache`, `movie-cache`, `animation-sources`, `cache/mirror` into Documents (Files app → On My iPhone › Dokkan Unit Creator › Game files…), excluded from iCloud backup, migrated once; Info.plist `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` true.
- **Everything order:** game movies now download last ("Every game movie"), so the 32 GB preview limit (hard-coded in the original PreviewCache.budget) or a full phone only stops movies. Measured sizes: Essentials ≈ 200 MB; Everything ≈ 8–12 GB (≈1.9 MB per character resource × 3,287 + ≈1.8 MB per effect pack × 1,398 + sounds); every game movie 40 GB+ (15,237 movie packs) → can't all fit under 32 GB.
- **JVM download test** (real OfflineLibrary + original classes from app-v2.jar, runtime stubs in `dock/test/runtime`, sqlite-jdbc from Maven): `JobRun <appdir> <downloadsdir> essentials[,everything] [movies]` (env SCRIPT_INDEX for a smaller script list), `StorageTest`, `ToolsCheck`. Results: Essentials 6,012 items, 0 failed, 123 not on Eclipse, 162 MB, player 55/55 ready; Everything sample (45 characters, 74 effect packs, 150 scripts, movies) 3,458 items, 0 failed, 7 not on Eclipse.

## Round 43 — v2.30.3 (versionCode 90) built: storage clean-up, earlier installs, Sparking custom-only
- **Manifest:** `patch/AndroidManifest-v90.xml` = v87n + `MANAGE_EXTERNAL_STORAGE` (build script now uses it). Requested only through Android's own Settings screen (`storageAccess` → ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).
- **PublicStorage v2:** LINKS now include `sparking/resource-cache` → "Sparking files" (SparkingContent only checks the canonical parent; verified). An earlier install's "Dokkan Unit Creator" (marker with another id / hidden) is never silently replaced by "(2)": files stay private (`waiting`) until the person chooses: All files access → `check()` adopts the folder (marker rewritten, `public-reown.txt`), relinks, merges "(n)" and marker-found folders anywhere on storage (depth 3, skips Android/); or `storageDecline` → "(n)". `tidy()` runs as the first job phase ("Cleaning up old files", `options.tidy`, report in `job.cleanup`): merge + re-own (copy/rename so this install owns them), half-finished/temp files, old `.mp4` movies, old game-data script folders (same size on Eclipse via HEAD → moved, else removed, offline → kept), stale preview/import staging, `forge/assets/sparking-<uuid>` copies not referenced by projects/project-versions/keepKeys (only when the UI says `keepKeysComplete`). Only the app's own file patterns (`known()`) are ever moved/deleted; `clear()` too.
- **Bridge:** `storageCheck`, `storageAccess`, `storageDecline` (ForgeFixes; iOS/web stubs). UI `ForgeOffline.storageReady()` dialog before every download, `cleanup()` (Settings › Animations › "Clean up old files now", pack `tidy`).
- **Sparking custom-only:** `SparkingCustom.java` / `v2/ui/sparking-custom.js`: content folders only; custom = Eclipse lacks the ID part of the path (file-browser listing, names without extension) or script not in Eclipse's index; `Custom/` always. New pack `sparking` (Android `OfflineLibrary.sparking()` via CreatorActivity.sparkingAssetManifest reflection; iOS `IOS.sparkingPackManifest/packFile`), into resource-cache with the app's side-file format so unit downloads reuse it. Original downloader (`SparkingContent.downloadAsset`) for its allowlisted folders; `SparkingFetch` applies the same checks to project folders it doesn't list (dokkan_field = custom stages, Custom, card, thumb, card_transform). Unit resources (`sparking-content.js fetchPaths`) and audio banks: originals via `downloadAsset` from Eclipse (shared `eclipse/` collection, not attached), custom from Sparking. Animation scripts unchanged (Sparking's 29 MB `lua/ab_script.cpk` stays: it feeds the shared-helper compatibility check).
- **Measured:** manifest 36,353 files / 24.8 GB; unit content 20,884 files: 18,753 original (16.3 GB, skipped) vs 2,131 custom (≈5 GB). JVM test `SparkTest` (sample: 34 stage files, 120 custom, 150 originals, 20 menu files): 138 custom downloaded incl. 18 stage files, 166 originals skipped, 0 failed, all pass the app's size/XXH64/SHA-256 cache check, rerun downloads 0 MB. `StorageTest`: 34 checks incl. earlier-install adopt/merge/re-own, personal files untouched, decline → (2), scripts reuse, orphan clean-up.
- **iOS:** Host.m `head` op; tidy + sparking phase in ios-offline.js.
- **Not yet verified on a real phone** (no device access from this session: the linked Mac's shell is an isolated VM and Terminal can't be typed into via computer use).
- **v2.30.4 (versionCode 91) built** (APK + IPA): simpler first-launch download question (Download using: Wi-Fi only / Wi-Fi or mobile data first; Everything / Just the basics; extras folded away), same Wi-Fi/mobile choice in Offline downloads. Next build: 92 / 2.30.5-android. User: keep test runs to a minimum.
- **v2.30.5 (versionCode 92) built:** every app open quietly runs `checkUpdates`; if Eclipse has newer game data → "🆕 New game data · Download now / Later" prompt (offline.js `newDataPrompt`, before the first-launch download question). Every file download first updates the game data automatically if a newer one exists (`latestData` in `start`). `ForgeImport.newer()` / `update({quiet})`. Next build: 93 / 2.30.6-android.
- **v2.30.6 (versionCode 93) built:** faster downloads — 10 parallel downloads (was 4; iOS too) and connection reuse (no `disconnect()` after a fully read file; redirects/404 drained; `http.maxConnections` 16). Essentials on the server test: 170 s → 70 s, 0 failed. Next build: 94 / 2.30.7-android.
- **v2.30.7 (versionCode 94) built:** Eclipse is latency-bound (~0.4 s per small file; measured 300 thumbnails: 10 threads 26 files/s, 32 threads 76 files/s) → Android 32 parallel downloads + http.maxConnections 32; iOS queue 24 and `_session` HTTPMaximumConnectionsPerHost 24. Preview storage limit set once at job start for the chosen packs (no repeated full-folder recounts while all downloads wait). Next build: 95 / 2.30.8-android.
- **v2.30.8 (versionCode 95) built:** maximum parallel downloads — Android 64 (+ http.maxConnections 64, each file retried twice after 2 s / 6 s on a dropped connection), iOS 48. Measured server ceiling (300 thumbnails, no keep-alive): 32→76, 64→87, 128→101 files/s, so 64 is near the top without hammering Eclipse. Next build: 96 / 2.30.9-android.
- **v2.30.9 (versionCode 96) built — downloads keep running in the background.** Android froze the app when the screen went off / another app opened, so "Everything" never finished. New `DownloadService` (foreground service, type specialUse = no 6-hour limit, notification "Downloading game files" with progress, partial wake lock + Wi-Fi lock, stops itself when the job ends). Manifest `patch/AndroidManifest-v96.xml` (re-encoded with pyaxml 0.1.1 from v90 + FOREGROUND_SERVICE, FOREGROUND_SERVICE_SPECIAL_USE, POST_NOTIFICATIONS, WAKE_LOCK, `<service>` + PROPERTY_SPECIAL_USE_FGS_SUBTYPE; booleans patched back to -1; attribute IDs checked with /tmp axdump). Interrupted downloads resume on the next app open (`pending` in prefs; iOS too). Stub classes added: android.app.Service, android.os.IBinder. Server check: 3,387 files in 20 s, 0 failed. Next build: 97 / 2.31.0-android? (versionName must stay 14 chars, e.g. 2.30.10 is too long → use 2.31.0-android).
- **Full test pass (Oct 27):** new `web/test_features.py` (one pass over every screen, every builder tab, leader quick start/tier, every passive family, intro, counter/revive/domain/standby, supers effect + animation choice, active skill, look, export validation, settings/offline/tour): 38/39 (the 39th was a wrong threshold in the test, fixed). Also passing: test_web (24), test_web2 (16), test_hosted (17), test_eclipse_unit (34, real decoder), test_ios_full (46), test_ios_duo (63), test_ios_player (16, run with `ab_script/attack_sp/sp0001.lua`; the default fs0001 is gone from Eclipse), harness parts_ui/finder_ui/tl_fixes/art_studio_ui/data_ui/ucopy_fixes/special_crawl/offline_ui, StorageTest, SparkTest, JobRun. Retired (they test UI removed on request this round): builder_ui, builder_crawl, leader_ui, passive_classic, passive_copy, porg_ui, shell_ui, eza_flow, anim_pick → harness/retired/. Harness tests needing `work/jvm` (ai_flow art, id_audit) can't run in this kit (folder missing); unit_copy needs two saved units in its state; special_ui expects base-set rows (now the strongest EZA stage is edited).

- v2.31.0 (code 97): Transform tab removed; transformSectionHTML(where) in builder.js renders #bld-transform at the end of the passive and intro steps; tab:transform alias goes to passive (or stays on intro). Sidebar artifact v46.
- v2.31.1 (code 98): Intro tab removed; introSectionHTML() renders ForgeIntro.html() in #bld-intro on the passive step; tab:intro / tab:transform go to passive and scroll to the section. Sidebar artifact v47.
- v2.31.2 (code 99): tf-form-del:<index> action on form cards removes linked transformation slots (B.removeTransformation), the form and its links, then ForgeForms.prune. Sidebar artifact v48.
- v2.31.3 (code 100): transformHTML rewritten as one panel of .tf-simple cards; wizard behind ui.tfAdding (tf-adding:on/off); CSS .tf-* in shell.css. Sidebar artifact v49.
- v2.31.4 (code 101): intro/transform sections moved above In-game description; formNameOf() names custom forms in the description; refreshTexts after tf-include and tf-custom/card; passiveText adds the Entrance Animation heading even with no bonuses. Sidebar artifact v50.
- v2.31.5 (code 102): B.setKiScale + conditions activeSkill/kiAbove (type 3); matchCondition tries every def of a type; condition-words case 3 says Active Skill at 24 Ki; activeTransformNote() on Active Skill step; wizard active note. Sidebar artifact v51.
- v2.31.6 (code 103): counter DR choice DR_WHAT none/0/1/2; same-as-counter stays on the counter row, else hidden companion row; companion % input uses data-pf-dramt (not data-bf) so counter edits don't double the reduction. Sidebar artifact v52.
- v2.31.7 (code 104): anim-choice.js picker (open(key, select)); enhance keeps the game select hidden and sets it on pick; catalog entries go through chooseAnimationTarget; web-native animationCatalog built from tables. Sidebar artifact v53 (start.js changed too).
- v2.31.8 (code 105): whoHTML/setWho in builder.js (data-bsel who:/who-cat:/who-del:/who-self:, data-whoname); settingsOf/passiveFields keep sub_target_type_set_id; decodePassive no longer rejects sub-target rows; subFor() + subTargetLine subFor wording. Sidebar artifact v54.
- v2.31.9 (code 106): picker categories = own kind, Everything, then all kinds; counters use the full catalog; fieldInputs keeps unknown choice values (data-cur option); enhance no longer adds a 'cur' option; web catalog adds shared special_views, transform/giant (battle_params idx 11/12), nullify, 'all'. Sidebar artifact v55.
- v2.32.0 (code 107): anim-choice picker = people list (ForgeNameSets.allNames + catalog search names) → loadCharacter(name) via cards by exact name → animationCatalog per unitId; shared view = unitId 0 transform/ultimate + giant. Revival quick list button. Sidebar artifact v56.
- v2.32.1 (code 108): intro.js useOwn(kind) → ForgeGuideUI.action('studio:'|'gallery:' + 'intro:'+carrier id) (guided.js now exports action). Sidebar artifact v57.
- v2.32.2 (code 109): verified active transformation joins existing Active Skill / creates 'Transformation' one; notes reworded. Sidebar artifact v58.
- v2.32.3 (code 110): finder.js loadForms() (passive/active 103, 79, passive 131, standby 103, card_exchange_relations; Exchange via active set name) + f.ver chips + .fd-form tag. Sidebar artifact v59.
- v2.32.4 (code 111): finder default ver 'all' (normal cards first, forms added when loaded), 'normal' = old behaviour. Sidebar artifact v60.
- v2.32.5 (code 112): finder tile tags in normal flow below meta. Sidebar artifact v61.
- v2.32.6 (code 113): loadForms records owners (passive set relations / card_active_skills / card_standby_skill_set_relations / exchange from); forms shown only if a top-version owner exists; ownerName on tile. Sidebar artifact v62.
- v2.32.7 (code 114): createTransformation passive uses stageView of the edited passive stage + relation to base set; linkTransformations() on passive render links own 103 rows from base set into edited EZA set. Sidebar artifact v63.
- v2.33.0 (code 115): Quick Create step 1 mounts ForgeFinder (#qc-finder); old search kept for own units/Sparking in details. ezaWho(kind) in dbz-home; ForgeBuilderUI.startAwakenOwn(kind,key). test_features create() uses #qc-finder. Sidebar artifact v64.
- v2.33.1 (code 116): families survive (52) / revive (109, tab revival); revivalSectionHTML; PF.addNow; tf how 'revival' = passive transform with condition revived. Sidebar artifact v65.
- v2.33.2 (code 117): revive family hidden:true (listHTML skips hidden); legacy picker skips revive. Sidebar artifact v66.
- v2.33.3 (code 118): passive defs stun/seal/disable use timings:[5,4,11,6,7] (When select limited to def.timings); PF family kindLabel/kindHelp. Sidebar artifact v67.
- v2.34.0 (code 119): PF families renamed to game wording; new families nullifyAtk/nullifySA/immuneStun(94)/immuneSeal(100)/immuneDown(99)/immuneAct(112)/stun/seal/disableAct/disableGuard/activeSkill/standbyFinish/domain/intro/focus(123); slot[6] raw-row fallback in fieldsFor; ACTIVE_EFFECTS focus. Sidebar artifact v68.
- v2.35.0 (code 120): transformHTML -> tfParts (byRow/extra/includeBtn/wizard); passive list uses cardOf; wizard #bld-tf-new; tabs standby/domain via ForgeSpecial.standbyHTML/domainHTML; syncTexts() in renderBuilderNow. Sidebar artifact v69.
- v2.35.1 (code 121): 'special' removed from TABS (ForgeSpecial.html kept but unused). Sidebar artifact v70.
- v2.35.2 (code 122): iPhone Duo full screen — see docs/IPHONE-DUO-DISPLAY.md. main.m -geometry/-pushGeometry (safe area + reservedRegionsOfKind at run time -> --sa-t/r/b/l, --rail-w/--rail-top, html.duo-rail, Library/display-log.jsonl); all env() -> var(--sa-x,env()); tab bar in the status column (.duo-rail); perf.js --nav-h 0 in rail. Build gate ios-objc/check-duo.sh (run by build-ipa.sh). Test web/test_ios_duo.py (88 checks, measured sizes). Mac test kit: ~/AI-Workspace/Dokkan-Unit-Creator (run/*.command, Finder double-click). Real phone: Naruto Blazing removed (his OK) to free a free-account slot; Unit Creator installed as com.dokkanunitcreator.ios.P4NRE7Q8ZT; inner 951x669 + live fold to outer verified on the phone. Wide layouts with a rail hide the sidebar and use the upright tab bar. Sidebar artifact v71.
- v2.35.3 (code 123): level perks get a 3rd row, DR (eff 13, timing 6, eff_value1 = 100 - dr; PERKS[].dr 10/20); godlyInSync needs 3 rows; checked every second (resyncs if removed); passive-del refuses Exclusive rows; exclusiveLines adds the DR line. Next: code 124.
- v2.35.4 (code 124): Host.m download session on its own background NSOperationQueue (was main queue -> freezes), _downloads @synchronized, progress emitted only when JS asked (progress flag); main.m pushGeometry skips unchanged geometry and only measures when logging (log write off main); perk check uses a fingerprint. Native checkSparkingUpdates (ForgeFixes.java HEAD + ios-sparking.js); offline.js sparkingNewer/updateSparkingNow; newDataPrompt covers Eclipse + Sparking; latestData(withSparking); simple downloads dialog (Everything/Basics radio, Sparking switch card, mobile data checkbox, More options). Next: code 125.
- v2.36.0 (code 125): REDESIGN = v2/ui/premium.css (+ premium.js) loaded after shell.css (before ios.css): colours/light/motion only, no layout/edge values; backdrop on body::after (body::before is the iOS status-bar mask). premium.js: #main.p-enter on navigate (wraps window.navigate), .bld-main.p-enter on tab change, html[data-type] from #bld-card .t<N>, quick chance buttons [data-pf-chance] (builder.js family editor) -> sets range + change. Ability editor steps numbered via CSS counter on .pf-sec h4. Feature inventory: docs/FEATURE-INVENTORY.md; regression: web/test_redesign.py (33 checks) + web/test_ios_duo.py (91).
  Sparking/Eclipse folder link (iOS): Player.m gameFolderStatus/Link/Unlink/Write (UIDocumentPicker folder -> security-scoped bookmark in NSUserDefaults forge.gameFolder.<game>; write with NSFileCoordinator; onlyIfMissing / replaces (same unit ID only)); ios-io.js sendToGame returns needsFolder -> app.js showFolderSetup; memo localStorage forge-sent-<game>-<unitKey> {file, sig} (sig ignores SQL timestamps + metadata created). SPRK IV = first 16 bytes of SHA-256(zip) (deterministic zip, mtime 1980). patch_info.json now has creator_id 0 (Sparking 6.6 requires it). Android SendToGame.java: creator_id, deterministic IV/zip time, rename-first replace. Phone install NOT done yet (Mac closed) - run run/device-install.command. Not yet copied to the Mac AI-Workspace (Mac was closed): copy source/ (ios-objc, web/src, v2/ui premium.*, app.js, builder.js, dock/src), docs/ (FEATURE-INVENTORY, SEND-TO-GAME) and tools/phone-apps.sh is already there. Web test page = Version 86. Portraits & Sprites tab: v2/ui/appearance.js (ForgeAppearance.html; builder TABS "appearance"); writes cardOverrides.resource_id+bg_effect_id (portrait), character_id (battle sprite; blocked while battlePoseBinding), special_motion (motion); previews via animationVisuals/previewAnimation. PUBLISH RULE: after every build, publish ALL changed hashed files (app.*.css, app.*.js AND start.*.js; start changes when web/src/web-native.js or early scripts change) and null the old names; check with Artifact list scope=files vs ls web/site-artifact. (Version 84 shipped without its new start.js -> "Could not open the creator"; fixed in 85.) Look v3 "Dragon Ball intensity" (user: blue too bright, then calm too boring): dark battlefield art + golden aura (art-src/make_art2.py -> premium-art.css), fire gradient for main actions, Goku-blue for second choices, fighting-game slash-bar menus (sidebar, More sheet, Home .p-menu, builder tabs) via clip-path; premium.css base blues shifted to deep violet. Home: no kicker/steps; EZA lives only in Create a unit (#cc-eza); Templates only in Create (Use a template); Home menu = Sparking characters + Downloads. SQL import: v2/ui/sql-import.js (ForgeSqlImport.parse/toProject: INSERT rows only; drops root-card copies; card row re-keyed to the source game card resource_id+1, targetId = file card id); app.js importSqlFile (window), import-hub data-imp="sql"; Native pickTextFile on iOS (ios-io.js), web (web-native.js) and Android (SqlPicker.java via ForgeFixes.dispatch + activityResult hook); iOS/web import() also route .sql. test_redesign.py covers the round trip. Identity redo (user said v1 "looks exactly the same"): v2/ui/premium-look.css (Dokkan menu style: royal-blue sky, ink outlines, chunky outlined buttons, Bangers titles, gold corner brackets, card frames) + premium-art.css (procedural WebP art as data URIs, made by art-src/make_art.py) loaded after premium.css; premium.css navy recoloured to royal blue; premium.js draws SVG nav icons and adds the Home main menu (.p-menu: EZA, My units, Animate, Templates, Sparking characters, Downloads - shortcuts only). Next: code 126.
- (unbuilt) Downloads: 2 tiles Eclipse/Sparking + small 'Download everything' (+movies); basics under More options; firstRun opens the same dialog. Wi-Fi only enforced: Android binds process to an unmetered Wi-Fi network during jobs (bindProcessToNetwork; stubs added in dock/stubs + dock/build/stubs), waits otherwise; iOS 'wifiOnlyDownloads' flag -> allowsCellularAccess/Expensive/Constrained NO + gate needs n.wifi; Wi-Fi loss retries after gate; DB updates skip when not on Wi-Fi. Pending: Import to Eclipse / Sparking (needs the apps' import mechanism: URL scheme / document types / Android intent; Sparking export = SPRK v1 AES-256-CTR encode of patch_info.json + patches/sql + assets).
- (unbuilt) Put it in your game: Save tab buttons Import to Eclipse / Import to Sparking -> exportProject('to-eclipse'|'to-sparking') -> Native sendToGame. Android SendToGame.java (writeExport via reflection; Download/Eclipse/*.eclp, Download/Sparking/*.sprk; launches com.anthen.eclipse / com.sparkingDokkan.GLB). iOS H.sendToGame (ios-io.js) + Host.m sprkEncode; save sheet + dbzdokkanww://. iOS Sparking set-up accepts 6.6 APK (LIBS offsets). Android Sparking set-up still 6.5.5-only. Not tested in the games. docs/SEND-TO-GAME.md; research in Mac AI-Workspace/Dokkan-Unit-Creator/research.
- (unbuilt) 3rd 'Put it in your game' button: Export .SQL / .JSON (builder action send-files -> dialog -> exportProject('sql'|'json')).
