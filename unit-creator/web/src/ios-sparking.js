/* iPhone app: Dokkan Sparking content, exactly like the Android app (SparkingContent, SprkCodec,
 * SprkEclp, prepareSparkingSnapshot, the Sparking bridge methods). The two format keys from the
 * user's Sparking APK go to the iPhone Keychain; decryption runs natively (Host.m). */
(function () {
  "use strict";
  const IOS = window.__forgeIOS;
  if (!IOS || !IOS.formats) return;
  const { host, H } = IOS;
  const fail = (m) => new Error(m);
  const MiB = 1048576;
  const DIR = "sparking/";
  const BUNDLED_SHA = "cf13b8553448507ad723e17a7b347e6eac4d7627a2e4fff56c0f7747660dffd8";
  const MANIFEST_URL = "https://dokkan-sparking.com/client_assets";
  const DB_URL = "https://ddl.dokkan-sparking.com/dokkan/assets/global/en/sqlite/current/en/database.db";
  const UA = { "User-Agent": "Dokkan-Unit-Creation-Sparking-Content", "Accept-Encoding": "identity" };
  const MANIFEST_HEADERS = Object.assign({ Accept: "application/json", "X-AssetVersion": "0", "Sparking_Asset_Version": "0" }, UA);
  const progress = (p, l, b, t) => IOS.progress(p, l, b, t);

  // ---------------------------------------------------------------- built-in snapshot
  let preparing = null;
  IOS.prepareSparkingSnapshot = function () {
    if (preparing) return preparing;
    preparing = (async () => {
      if (await IOS.storeState("sparking")) return;
      await host.call("installDatabases");
      const src = "db/sparking-reference.db";
      const h = await host.call("sha256", { path: src }).catch(() => null);
      if (!h || h.sha256 !== BUNDLED_SHA) throw fail("The built-in Sparking catalogue is incomplete. Reinstall the complete APK.");
      const count = await IOS.verifyDb(src, true);
      await IOS.commitDb("sparking", src, Object.assign({}, IOS.SPARKING_META, { count }));
    })().finally(() => { preparing = null; });
    return preparing;
  };
  async function sparkingMeta() { await IOS.prepareSparkingSnapshot(); return (await IOS.storeState("sparking")).active.meta; }
  /** PreviewMetadata.databaseFile(ROOT, "sparking", version) */
  IOS.sparkingDatabaseFile = async function (version) {
    const st = await IOS.storeState("sparking");
    if (!st) throw fail("Download Sparking characters from Library before previewing this source.");
    if (!version) {
      const f = DIR + "databases/" + st.active.file;
      if (!(await host.exists(f))) throw fail("Download Sparking characters from Library before previewing this source.");
      return f;
    }
    for (const slot of [st.active, st.previous]) {
      if (slot && slot.meta && slot.meta.latestVersion === version && (await host.exists(DIR + "databases/" + slot.file))) return DIR + "databases/" + slot.file;
    }
    throw fail("This animation needs Sparking content version " + version + ". Restore or import that version before previewing; another version was not substituted.");
  };
  const keyConfigured = async () => !!(await host.call("secretHint", { key: "sparking.db" })).hasKey;

  H.sparkingInfo = async function () {
    await IOS.prepareSparkingSnapshot();
    const st = await IOS.storeState("sparking");
    const out = { available: !!st, keyConfigured: await keyConfigured() };
    if (st) {
      const { path, schema } = await IOS.openDb("sparking");
      out.count = (await IOS.sql(path, "SELECT count(*) AS n FROM cards"))[0].n;
      out.schema = schema;
      out.meta = st.active.meta;
    }
    return out;
  };
  const baseQuery = H.querySparking;
  H.querySparking = async (a) => { await IOS.prepareSparkingSnapshot(); return baseQuery(a); };

  // ---------------------------------------------------------------- network (no redirects, identity encoding)
  async function get(url, path, headers, label, phase) {
    let r;
    try { r = await host.download(url, path, { headers, keepErrors: true, noRedirect: true, onProgress: (d) => progress(phase, label, d.bytes, d.total) }); }
    catch (e) { throw fail(/canceled/i.test(e.message) ? e.message : "The Sparking public content server could not be reached. Check your internet connection."); }
    if (r.status === 401 || r.status === 403) throw fail("The Sparking public content server refused this request. No account credentials were sent.");
    if (r.status !== 200) throw fail("The Sparking public content server returned HTTP " + r.status + ". Try again later.");
    return r;
  }
  const integer = (v) => typeof v === "number" && Number.isInteger(v);
  const U64 = (s) => typeof s === "string" && /^[0-9]{1,20}$/.test(s) && BigInt(s) <= 18446744073709551615n;
  function dbRecord(m) {
    const assets = m && Array.isArray(m.assets) ? m.assets : [];
    if (assets.length > 100000) throw fail("The Sparking manifest contains too many entries.");
    const hits = assets.filter((a) => a && a.file_path === "sqlite/current/en/database.db");
    if (hits.length > 1) throw fail("The Sparking manifest has duplicate game databases.");
    if (!hits.length) throw fail("The Sparking manifest does not list its game database.");
    const r = hits[0];
    if (!integer(r.size)) throw fail("Invalid Sparking database size.");
    if (!(r.size > 0 && r.size <= 201326592 && r.algorithm === "xxhash")) throw fail("Unsupported Sparking database size or checksum format.");
    if (!U64(r.hash)) throw fail("Invalid Sparking database checksum.");
    let u; try { u = new URL(r.url); } catch (e) { u = null; }
    if (!u || u.protocol !== "https:" || u.hostname !== "ddl.dokkan-sparking.com" || u.pathname !== "/dokkan/assets/global/en/sqlite/current/en/database.db" || u.username || u.hash || (u.port && u.port !== "443"))
      throw fail("The Sparking server returned an unsupported download address.");
    return r;
  }
  function gamePath(p) {
    if (typeof p !== "string" || p.length > 500 || /[\\:]/.test(p) || /[\x00-\x1f\x7f]/.test(p)) throw fail("Unsupported Sparking game resource path.");
    const segs = p.split("/");
    if (segs.some((s) => !s || s === "." || s === "..")) throw fail("Unsafe Sparking game resource path.");
    if (segs[0] === "se") { if (!/^se\/[A-Za-z0-9_-]{1,80}\.(acb|awb)$/.test(p)) throw fail("Unsupported Sparking sound-effect bank path."); return; }
    if (segs[0] === "voice") {
      const m = /^voice\/(?:(en|ja)\/)?([A-Za-z0-9_-]{1,80})\/([A-Za-z0-9_-]{1,80})\.(acb|awb)$/.exec(p);
      if (!m || m[2] !== m[3]) throw fail("Unsupported Sparking voice bank path.");
      return;
    }
    if (!["character", "ingame", "script", "movie", "sound", "lua", "bgm", "item", "card_category", "sd_battle", "outgame", "sugoroku"].includes(segs[0]))
      throw fail("This download is not a supported game resource. Account and user-state files are excluded.");
  }
  function assetRecord(m, path) {
    gamePath(path);
    const assets = Array.isArray(m.assets) ? m.assets : [];
    if (assets.length > 100000) throw fail("The Sparking manifest contains too many entries.");
    const hits = assets.filter((a) => a && a.file_path === path);
    if (hits.length > 1) throw fail("The Sparking manifest repeats this game resource.");
    if (!hits.length) throw fail("This resource is not listed in the downloaded Sparking manifest.");
    const r = hits[0];
    if (!integer(r.size) || !(r.size > 0 && r.size <= 201326592) || r.algorithm !== "xxhash") throw fail("Unsupported Sparking game resource size or checksum.");
    if (!U64(r.hash)) throw fail("Invalid Sparking resource checksum.");
    let u; try { u = new URL(r.url); } catch (e) { u = null; }
    const want = "/dokkan/assets/global/en/" + path.split("/").map((s) => encodeURIComponent(s).replace(/%2F/g, "/")).join("/");
    if (!u || u.protocol !== "https:" || u.hostname !== "ddl.dokkan-sparking.com" || u.pathname !== want || u.username || u.hash || (u.port && u.port !== "443"))
      throw fail("The Sparking resource download address does not match its manifest path.");
    return r;
  }

  // quick check for newer Sparking game data (same as Eclipse's checkUpdates): date and size on Sparking's server
  H.checkSparkingUpdates = async function () {
    try {
      const r = await host.net(DB_URL, { method: "HEAD", headers: UA });
      const status = Number(r.headers.get("X-Forge-Status")) || r.status;
      const lm = Date.parse(r.headers.get("Last-Modified") || "");
      const len = Number(r.headers.get("Content-Length"));
      return { ok: status >= 200 && status < 300, status, lastModified: Number.isFinite(lm) ? lm : 0, size: Number.isFinite(len) && r.headers.get("Content-Length") ? len : -1 };
    } catch (e) { return { ok: false, error: "Couldn't reach Sparking. Check your internet connection." }; }
  };

  // ---------------------------------------------------------------- updateSparking
  H.updateSparking = async function () {
    if (!(await keyConfigured())) throw fail("Import the original Sparking 6.5.5 APK or its ZIP first. Then download characters here.");
    const stage = "cache/sparking-data-" + IOS.uuid4() + "/";
    try {
      await host.keepAwake(true);
      progress("manifest", "Reading Sparking's game-content list");
      const mr = await get(MANIFEST_URL, stage + "assets.json", MANIFEST_HEADERS, "Reading Sparking's game-content list", "manifest");
      if (mr.bytes > 32 * MiB) throw fail("The Sparking manifest exceeds32MiB.");
      let manifest; try { manifest = JSON.parse(await host.readText(stage + "assets.json")); } catch (e) { throw fail("The Sparking manifest could not be read."); }
      const rec = dbRecord(manifest);
      if (!integer(manifest.latest_version) || manifest.latest_version < 0) throw fail("Invalid Sparking content version.");
      // already have exactly this database: nothing to download
      const have = await IOS.storeState("sparking").catch(() => null);
      if (have && have.active && have.active.meta && have.active.meta.xxhash64 === rec.hash && have.active.meta.sourceType === "sparking-current") {
        progress("done", "You already have the newest Sparking characters", 0, 0);
        return H.sparkingInfo();
      }
      // the Sparking app on this phone already downloaded it: take its copy (checked against the manifest)
      progress("database", "Looking in Sparking's folder", 0, 0);
      let hs = null, dr = { bytes: rec.size };
      for (const rel of ["assets/sqlite/current/en/database.db", "assets/sqlite/current/en/Base/database.db"]) if (!hs) hs = await reuse(rel, stage + "database.db", rec);
      if (!hs) {
        progress("database", "Downloading Sparking characters", 0, rec.size);
        dr = await get(rec.url, stage + "database.db", UA, "Downloading Sparking characters", "database");
        if (dr.bytes > rec.size || dr.bytes > 201326592) throw fail("The Sparking database exceeds its declared size.");
        hs = await host.call("hashes", { path: stage + "database.db" });
        if (dr.bytes !== rec.size || hs.xxhash64 !== rec.hash) throw fail("The Sparking database checksum does not match. Existing content was kept.");
      }
      progress("decrypt", "Opening and authenticating Sparking game data", 0, 0);
      await host.call("sqlcipherDecrypt", { path: stage + "database.db", to: stage + "readable.db", keyName: "sparking.db", mode: 4 });
      progress("verify", "Checking Sparking characters and skills", 0, 0);
      const count = await IOS.verifyDb(stage + "readable.db", true);
      const mh = await host.call("sha256", { path: stage + "assets.json" });
      const name = "assets-" + mh.sha256 + ".json";
      if (!(await host.exists(DIR + name))) { try { await host.move(stage + "assets.json", DIR + name); } catch (e) { throw fail("Could not save Sparking's resource list."); } }
      await IOS.commitDb("sparking", stage + "readable.db", { latestVersion: manifest.latest_version, bytes: dr.bytes, sha256: hs.sha256, xxhash64: hs.xxhash64, sourceURL: DB_URL,
        sourceEncryptedSHA256: hs.sha256, source: "Sparking game database", sourceType: "sparking-current", date: new Date().toISOString(), count, assetsManifest: name });
      progress("done", "Sparking characters are ready in Library", 0, 0);
      return H.sparkingInfo();
    } finally { await host.remove(stage).catch(() => {}); host.keepAwake(false).catch(() => {}); }
  };

  // ---------------------------------------------------------------- the resource list for a version
  async function assetManifest(version) {
    const meta = await sparkingMeta(), cur = meta.latestVersion;
    if (version !== -1 && version !== cur) throw fail("This unit uses a different Sparking content version. Keep its original attached assets or recreate its copy from the matching catalogue.");
    const name = meta.assetsManifest || "catalog-assets-" + cur + ".json";
    if (!/^(assets-[a-f0-9]{64}|catalog-assets-[0-9]+)\.json$/.test(name)) throw fail("Invalid Sparking resource-list reference.");
    const file = DIR + name;
    if (!(await host.exists(file))) {
      const tmp = DIR + "manifest-" + IOS.uuid4() + ".json";
      try {
        const r = await get(MANIFEST_URL, tmp, MANIFEST_HEADERS, "Opening Sparking resources", "manifest");
        if (r.bytes > 32 * MiB) throw fail("The Sparking content list exceeds32MiB.");
        const m = JSON.parse(await host.readText(tmp));
        dbRecord(m);
        if (!integer(m.latest_version) || m.latest_version <= 0) throw fail("Invalid Sparking content version.");
        if (m.latest_version !== cur) throw fail("Sparking's server has newer game content. Import the supported APK and update characters before downloading these resources.");
        try { await host.move(tmp, file); } catch (e) { throw fail("Could not save the resource list."); }
      } finally { await host.remove(tmp).catch(() => {}); }
    }
    return file;
  }
  const manifests = new Map();
  async function readManifest(file) {
    if (!manifests.has(file)) {
      const st = await host.stat(file);
      if (!st || st.size <= 0 || st.size > 32 * MiB) throw fail("Update the Sparking content manifest first.");
      manifests.set(file, JSON.parse(await host.readText(file)));
    }
    return manifests.get(file);
  }
  const versionArg = (a) => (a.version == null ? -1 : Math.trunc(Number(a.version)));
  // Offline pack "Sparking custom content": Sparking's own files only (custom stages included). Folders
  // the original downloader doesn't list (dokkan_field, Custom, card, thumb, card_transform) get the very
  // same record, address and checksum checks.
  const PROJECT = /^(dokkan_field|Custom|card|thumb|card_transform)\/|^outgame\/extension\/dokkan_field\//;
  function packRecord(m, path) {
    if (!PROJECT.test(path)) return assetRecord(m, path);
    if (typeof path !== "string" || path.length > 500 || /[\\:]/.test(path) || /[\x00-\x1f\x7f]/.test(path) || path.split("/").some((x) => !x || x === "." || x === "..")) throw fail("Unsafe Sparking game resource path.");
    const hits = (m.assets || []).filter((a) => a && a.file_path === path);
    if (hits.length !== 1) throw fail(hits.length ? "The Sparking manifest repeats this game resource." : "This resource is not listed in the downloaded Sparking manifest.");
    const r = hits[0];
    if (!integer(r.size) || !(r.size > 0 && r.size <= 201326592) || r.algorithm !== "xxhash") throw fail("Unsupported Sparking game resource size or checksum.");
    if (!U64(r.hash)) throw fail("Invalid Sparking resource checksum.");
    let u; try { u = new URL(r.url); } catch (e) { u = null; }
    const want = "/dokkan/assets/global/en/" + path.split("/").map((x) => encodeURIComponent(x).replace(/%2F/g, "/")).join("/");
    if (!u || u.protocol !== "https:" || u.hostname !== "ddl.dokkan-sparking.com" || u.pathname !== want || u.username || u.hash || (u.port && u.port !== "443"))
      throw fail("The Sparking resource download address does not match its manifest path.");
    return r;
  }
  IOS.sparkingPackManifest = async function () {
    const file = await assetManifest(-1);
    return { file, m: await readManifest(file) };
  };
  // Reuse files the Sparking app already downloaded (its Files folder: Sparking/assets/...) instead of downloading
  // them again. Needs the Sparking folder link (the same one "Import to Sparking" uses); without it this does nothing.
  // Returns the bytes copied, or 0 when the folder isn't linked or doesn't have the file.
  let linkMemo = null, linkAt = 0;
  IOS.fromGameFolder = async function (rel, to, game = "sparking") {
    if (linkMemo === null || Date.now() - linkAt > 60000) {
      linkAt = Date.now();
      linkMemo = await host.call("gameFolderStatus", { game }).then((r) => !!(r && r.linked && r.ok), () => false);
    }
    if (!linkMemo) return 0;
    try {
      const r = await host.call("gameFolderCopyIn", { game, rel, to });
      if (r && r.copied) return Number(r.bytes) || 0;
      if (r && (r.lost || r.linked === false)) linkMemo = false;
    } catch (e) {}
    return 0;
  };
  IOS.resetFolderMemo = () => { linkMemo = null; };
  IOS.reused = { files: 0, bytes: 0 };
  // a copy from the game's folder counts only when it is exactly the file the manifest lists (size + xxhash)
  async function reuse(rel, to, rec) {
    const n = await IOS.fromGameFolder(rel, to);
    if (!n) return null;
    if (n === rec.size) {
      const hs = await host.call("hashes", { path: to }).catch(() => null);
      if (hs && hs.xxhash64 === rec.hash) { IOS.reused.files++; IOS.reused.bytes += n; return hs; }
    }
    await host.remove(to).catch(() => {});
    return null;
  }
  IOS.reuseFromSparking = reuse;
  // returns bytes downloaded (0 when it was already saved)
  IOS.sparkingPackFile = async function (file, m, path) {
    const rec = packRecord(m, path);
    const stem = "resource-cache/" + rec.hash + "-" + rec.size, st = await host.stat(DIR + stem + ".data");
    if (st && st.size === rec.size && (await host.exists(DIR + stem + ".json"))) {
      try { if ((await host.readJson(DIR + stem + ".json")).xxhash64 === rec.hash) return 0; } catch (e) {}
    }
    await cachedResource(file, m, path, rec);
    return rec.size;
  };
  H.findSparkingAssets = async function (a) {
    const m = await readManifest(await assetManifest(versionArg(a)));
    const have = new Set((m.assets || []).map((x) => x && x.file_path));
    const paths = Array.isArray(a.paths) ? a.paths : [];
    if (paths.length > 128) throw fail("Choose fewer game resources at a time.");
    for (const p of paths) if (!IOS.safePath(p)) throw fail("Invalid resource path.");
    return { available: paths.filter((p) => have.has(p)), missing: paths.filter((p) => !have.has(p)) };
  };
  async function cachedResource(manifestFile, m, path, rec) {
    const stem = "resource-cache/" + rec.hash + "-" + rec.size, data = DIR + stem + ".data", side = DIR + stem + ".json";
    const st = await host.stat(data);
    if (st && st.size === rec.size && (await host.exists(side))) {
      try { const s = await host.readJson(side); if (s.xxhash64 === rec.hash && s.sha256 === (await host.call("sha256", { path: data })).sha256) return { data, info: s }; } catch (e) {}
    }
    const tmp = DIR + "resource-cache/sparking-asset-" + IOS.uuid4() + ".tmp";
    try {
      // the Sparking app already has it: copy it from its folder (checked against the manifest) instead of downloading
      let hs = await reuse("assets/" + path, tmp, rec), bytes = rec.size;
      if (!hs) {
        const r = await get(rec.url, tmp, UA, "Downloading Sparking game resources", "download");
        if (r.bytes > rec.size) throw fail("The Sparking resource exceeds its declared size.");
        hs = await host.call("hashes", { path: tmp }); bytes = r.bytes;
        if (r.bytes !== rec.size || hs.xxhash64 !== rec.hash) throw fail("The Sparking resource checksum does not match. Existing content was kept.");
      }
      const r = { bytes };
      try { await host.move(tmp, data); } catch (e) { throw fail("Could not commit the Sparking game resource."); }
      const info = { file_path: path, bytes: r.bytes, sha256: hs.sha256, xxhash64: hs.xxhash64 };
      await host.writeJson(side, info);
      return { data, info };
    } finally { await host.remove(tmp).catch(() => {}); }
  }
  H.downloadSparkingAssets = async function (a) {
    const file = await assetManifest(versionArg(a)), meta = await sparkingMeta(), m = await readManifest(file);
    const paths = Array.isArray(a.paths) ? a.paths : [];
    if (paths.length < 1 || paths.length > 32) throw fail("Choose between 1 and 32 game resource files at a time.");
    const key = "sparking-" + IOS.uuid4(), out = [], seen = new Set();
    let total = 0;
    try {
      for (const path of paths) {
        if (!IOS.safePath(path)) throw fail("Invalid Sparking game resource path.");
        const k = path.normalize("NFC").toLowerCase();
        if (seen.has(k)) throw fail("Selected resources have conflicting game paths.");
        seen.add(k);
        const rec = assetRecord(m, path);
        if ((total += rec.size) > 536870912) throw fail("This resource batch exceeds512MB. Choose fewer resources.");
        const { data, info } = await cachedResource(file, m, path, rec);
        await host.call("copy", { path: data, to: "assets/" + key + "/" + path });
        out.push({ key: key + "/" + path, path, sourcePath: path, size: rec.size, sha256: info.sha256, source: "sparking" });
      }
      const r = await IOS.expandCpkResources(key, out.length, total);
      IOS.invalidateAssets();
      return Object.assign(r, { assets: out, sourceVersion: meta.latestVersion });
    } catch (e) { await host.remove("assets/" + key).catch(() => {}); throw e; }
  };
  H.sparkingAudioCatalog = async function (a) {
    const v = IOS.normalizeVersion(a.version);
    if (v <= 0) throw fail("Choose a recorded Sparking content version before preparing its audio.");
    const m = await readManifest(await assetManifest(v));
    const assets = Array.isArray(m.assets) ? m.assets : [];
    if (assets.length > 100000) throw fail("The Sparking manifest contains too many entries.");
    const files = [];
    for (const x of assets) {
      const p = x && x.file_path;
      if (typeof p !== "string" || !(p.startsWith("se/") || p.startsWith("voice/"))) continue;
      if (files.length >= 128) throw fail("The Sparking manifest contains too many audio banks.");
      const rec = assetRecord(m, p);
      files.push({ path: p, bytes: rec.size, kind: p.startsWith("se/") ? "se" : "voice" });
    }
    return { version: v, files };
  };

  // ---------------------------------------------------------------- Sparking animations
  IOS.sparkingAnimationFiles = async function () {
    const meta = await sparkingMeta();
    if (meta.latestVersion === 1791992148) {
      const list = JSON.parse(await IOS.siteText("data/sparking-animation-paths.json"));
      return (Array.isArray(list) ? list : list.paths || list.scripts || []).map((x) => (typeof x === "string" ? x : x.path)).filter(IOS.validAnimationPath).sort();
    }
    const m = await readManifest(await assetManifest(-1)), set = new Set();
    for (const x of m.assets || []) { const p = x && x.file_path; if (typeof p === "string" && p.startsWith("lua/") && IOS.validAnimationPath(p.slice(4))) set.add(p.slice(4)); }
    try { const cpk = await baseScripts(m, meta.latestVersion); for (const e of cpk.entries) { const p = "ab_script/" + e.path; if (IOS.validAnimationPath(p)) set.add(p); } } catch (e) {}
    return [...set].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  };
  async function baseScripts(m, v) {
    const f = DIR + "base-scripts-" + v + ".cpk";
    if (!(await host.exists(f))) {
      progress("download", "Preparing Sparking's original animation collection");
      const rec = assetRecord(m, "lua/ab_script.cpk");
      const { data } = await cachedResource(null, m, "lua/ab_script.cpk", rec);
      await host.call("copy", { path: data, to: f });
    }
    const blob = new Blob([await host.readBytes(f)]);
    return { blob, entries: await IOS.formats.cpkEntries(blob) };
  }
  IOS.sparkingAnimationSource = async function (a) {
    const path = a.path;
    if (!IOS.validAnimationPath(path)) throw fail("Choose a Sparking animation from the browser.");
    const meta = await sparkingMeta();
    const key = a.assetKey || "sparking-source-" + meta.latestVersion + "/lua/" + path;
    const file = "assets/" + key;
    if (!(await host.exists(file))) {
      const m = await readManifest(await assetManifest(-1));
      const listed = (m.assets || []).find((x) => x && x.file_path === "lua/" + path);
      let bytes;
      if (listed) {
        if (listed.size > 2 * MiB) throw fail("This original animation exceeds the supported script size.");
        const { data } = await cachedResource(null, m, "lua/" + path, assetRecord(m, "lua/" + path));
        bytes = await host.readBytes(data);
      } else {
        const { blob, entries } = await baseScripts(m, meta.latestVersion);
        const hits = entries.filter((e) => e.path === path.slice(10));
        if (hits.length > 1) throw fail("Conflicting original animation entries.");
        if (!hits.length || hits[0].size > 2 * MiB) throw fail("This animation is not present in Sparking's original collection or exceeds the supported size.");
        bytes = await IOS.formats.cpkRead(blob, hits[0]);
      }
      try { await host.writeBytes(file, bytes); } catch (e) { throw fail("Could not save the original animation."); }
      IOS.invalidateAssets();
    }
    const b = await host.readBytes(file);
    if (!b || b.length > 2 * MiB) throw fail("This Sparking animation file could not be opened.");
    const text = new TextDecoder().decode(b);
    if (!text.trim() || text.trim().startsWith("<") || text.includes("\u0000")) throw fail("This Sparking animation file could not be opened.");
    return { path, text, assetKey: key, size: b.length, sha256: await IOS.sha256Hex(b), cached: true, local: true, sourceDatabase: "sparking" };
  };

  // ---------------------------------------------------------------- the Sparking APK: its two format keys
  const LIB_SHA = "9d3f2749e391d990496b632b6adc135492f71e0baec7125d7b613a56e771dca0";
  // Sparking versions whose format library has been checked: where its two keys are (SPRK key, database key)
  const LIBS = { [LIB_SHA]: { v: "6.5.5", key: 648423, db: 487092 },
                 "83c0b40f49ae0edb0c91650ff36eb97a528db2c14627333f7023c3a13e0018d4": { v: "6.6", key: 665339, db: 495950 } };
  IOS.importSparkingApk = async function (file, name, entries) {
    progress("inspect", "Reading Sparking resources and patch format");
    const libs = entries.filter((e) => e.name === "lib/arm64-v8a/libbase.so");
    if (libs.length > 1) throw fail("The APK has duplicate native libraries.");
    const lib = libs[0];
    if (!lib || lib.dir || lib.usize < 600000 || lib.usize > 16 * MiB || lib.csize > 16 * MiB) throw fail("This APK does not contain a supported Sparking Android format library (6.5.5 or 6.6).");
    const b = new Uint8Array(await (await IOS.zipData(file, lib)).arrayBuffer());
    if (b.length > 16 * MiB) throw fail("This Sparking resource exceeds its size limit.");
    const lv = LIBS[await IOS.sha256Hex(b)];
    if (!lv) throw fail("This Sparking APK version is not supported yet (supported: Sparking 6.5.5 and 6.6). Its format must be checked before importing encrypted patches.");
    const key = new Uint8Array(32); key.set(b.subarray(lv.key, lv.key + 16));
    if (!(b.length > lv.db + 64 && b[lv.db + 64] === 0)) throw fail("The supported Sparking database format key is unavailable.");
    const dbKey = new TextDecoder().decode(b.subarray(lv.db, lv.db + 64));
    if (!/^[0-9a-fA-F]{64}$/.test(dbKey)) throw fail("The supported Sparking database format key is invalid.");
    const r = await IOS.importArchiveForSparking(file, name, entries);
    try {
      await host.secretSet("sparking.sprk", Array.from(key, (x) => x.toString(16).padStart(2, "0")).join(""));
      await host.secretSet("sparking.db", dbKey);
    } catch (e) { throw fail("Could not save this game's import format."); }
    key.fill(0); b.fill(0);
    progress("done", "Sparking import ready");
    return Object.assign(r, { sourceFormat: "sparking-apk", formatKeyConfigured: true,
      note: "Sparking import is ready. Browse the included characters in Library → Sparking, or choose Update characters for current game data. You can also import supported .sprk patches and save ECLP from Library. Artwork and other game resources download separately." });
  };

  // ---------------------------------------------------------------- .sprk patches → .eclp
  IOS.importSparkingPatch = async function (file, name) {
    if (!(await host.call("secretHint", { key: "sparking.sprk" })).hasKey) throw fail("First choose Import file and select the original Sparking 6.5.5 APK or its ZIP. Then import your .sprk patch here.");
    const stage = "cache/sparking-" + IOS.uuid4() + "/";
    try {
      progress("convert", "Opening Sparking patch");
      await host.writeBytes(stage + "patch.sprk", file);
      await host.call("sprkDecode", { path: stage + "patch.sprk", to: stage + "decoded.zip" });
      const zip = new Blob([await host.readBytes(stage + "decoded.zip")]);
      const entries = await central(zip);
      const inspected = await inspect(zip, entries);
      const converted = await convert(zip, inspected, name);
      const r = await IOS.importEclp(new Blob([converted.bytes]), name.replace(/\.sprk$/i, "") + ".eclp");
      return Object.assign(r, { sourceFormat: "sparking-sprk", note: "Sparking patch converted and added to the Sparking category in Library. Save ECLP to install it in Eclipse. Format conversion does not verify its SQL or gameplay compatibility; the original creator metadata was preserved." });
    } finally { await host.remove(stage).catch(() => {}); }
  };
  const SAFE = (n) => n && n.length <= 500 && !n.startsWith("/") && !n.includes("\\") && !/[:\x00-\x1f\x7f]/.test(n) && n.split("/").every((s) => s && s !== "." && s !== "..");
  async function central(zip) {
    const len = zip.size;
    if (len > 512 * MiB) throw fail("Invalid or oversized Sparking ZIP.");
    if (len < 22) throw fail("The decrypted Sparking file is not a complete ZIP.");
    const tl = Math.min(65557, len), tail = new Uint8Array(await zip.slice(len - tl).arrayBuffer()), dv = new DataView(tail.buffer);
    let e = -1;
    for (let i = tl - 22; i >= 0; i--) if (dv.getUint32(i, true) === 0x06054b50 && i + 22 + dv.getUint16(i + 20, true) === tl) { e = i; break; }
    const bad = () => fail("Unsupported or incomplete Sparking ZIP directory.");
    if (e < 0 || dv.getUint16(e + 4, true) || dv.getUint16(e + 6, true) || dv.getUint16(e + 8, true) !== dv.getUint16(e + 10, true)) throw bad();
    const n = dv.getUint16(e + 10, true), cdSize = dv.getUint32(e + 12, true), cdOff = dv.getUint32(e + 16, true);
    if (n < 1 || n > 10000 || cdSize > 16 * MiB || cdOff === 0xffffffff || cdSize === 0xffffffff || cdOff + cdSize !== len - tl + e) throw bad();
    const cd = new Uint8Array(await zip.slice(cdOff, cdOff + cdSize).arrayBuffer()), c = new DataView(cd.buffer);
    const out = [], seen = new Set(); let p = 0, total = 0;
    const cp437 = new TextDecoder("ibm866");
    for (let k = 0; k < n; k++) {
      if (p + 46 > cd.length || c.getUint32(p, true) !== 0x02014b50) throw fail("Corrupt Sparking ZIP directory.");
      const flags = c.getUint16(p + 8, true), method = c.getUint16(p + 10, true), crc = c.getUint32(p + 16, true), csize = c.getUint32(p + 20, true), usize = c.getUint32(p + 24, true);
      const nl = c.getUint16(p + 28, true), xl = c.getUint16(p + 30, true), cl = c.getUint16(p + 32, true), disk = c.getUint16(p + 34, true), ext = c.getUint32(p + 38, true), lho = c.getUint32(p + 42, true);
      const mode = (ext >>> 16) & 0xf000;
      if ((flags & 0x41) || !(method === 0 || method === 8) || csize > 512 * MiB || usize > 512 * MiB || lho >= cdOff || nl < 1 || nl > 2000 || disk || ![0, 0x8000, 0x4000].includes(mode))
        throw fail("This Sparking ZIP contains an encrypted, linked, special or unsupported entry.");
      if (p + 46 + nl + xl + cl > cd.length) throw fail("Truncated Sparking ZIP metadata.");
      let name;
      try { name = (flags & 0x800) ? new TextDecoder("utf-8", { fatal: true }).decode(cd.subarray(p + 46, p + 46 + nl)) : cp437.decode(cd.subarray(p + 46, p + 46 + nl)); } catch (x) { throw fail("The Sparking archive contains an unsafe file path."); }
      const dir = name.endsWith("/");
      const clean = dir ? name.slice(0, -1) : name;
      if (!SAFE(clean)) throw fail("The Sparking archive contains an unsafe file path.");
      if (seen.has(clean)) throw fail("The Sparking ZIP contains duplicate file paths.");
      if (mode === 0x4000 && !dir) throw fail("Invalid Sparking ZIP directory entry.");
      if (dir && usize) throw fail("This Sparking ZIP exceeds supported limits or needs unsupported ZIP64 handling.");
      if ((total += usize) > 1073741824) throw fail("Expanded Sparking patch exceeds1GiB.");
      seen.add(clean);
      out.push({ name: clean, dir, method, flags, crc, csize, usize, lho, nl });
      p += 46 + nl + xl + cl;
    }
    if (p !== cdSize) throw fail("Sparking ZIP directory size does not match.");
    const files = new Set(out.filter((x) => !x.dir).map((x) => x.name));
    for (const x of out) { const parts = x.name.split("/"); for (let i = 1; i < parts.length; i++) if (files.has(parts.slice(0, i).join("/"))) throw fail("A Sparking file conflicts with a folder."); }
    for (const x of out) {
      const h = new DataView(await zip.slice(x.lho, x.lho + 30).arrayBuffer());
      if (h.byteLength < 30 || h.getUint32(0, true) !== 0x04034b50 || h.getUint16(8, true) !== x.method || h.getUint16(6, true) !== x.flags) throw fail("Sparking ZIP local and directory headers do not match.");
      const ln = h.getUint16(26, true), lx = h.getUint16(28, true);
      if (x.lho + 30 + ln + lx + x.csize > cdOff) throw fail("Invalid Sparking ZIP file bounds.");
      x.dataStart = x.lho + 30 + ln + lx;
    }
    return out;
  }
  let crcT = null;
  function crc32(b) { if (!crcT) { crcT = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; crcT[n] = c >>> 0; } } let c = 0xffffffff; for (let i = 0; i < b.length; i++) c = crcT[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
  async function entryBytes(zip, x) {
    const raw = zip.slice(x.dataStart, x.dataStart + x.csize);
    const b = x.method === 0 ? new Uint8Array(await raw.arrayBuffer()) : new Uint8Array(await new Response(raw.stream().pipeThrough(new DecompressionStream("deflate-raw"))).arrayBuffer());
    if (b.length !== x.usize || crc32(b) !== x.crc) throw fail("Sparking resource checksum does not match.");
    return b;
  }
  async function inspect(zip, entries) {
    const files = [], warnings = [], kinds = new Set();
    let info = null, total = 0, outside = false;
    for (const x of entries.filter((e) => !e.dir)) {
      const b = await entryBytes(zip, x);
      if ((total += b.length) > 1073741824) throw fail("Expanded Sparking patch exceeds its supported size.");
      const p = x.name;
      let kind = "other", rel = p, m;
      if (p === "patch_info.json") kind = "metadata";
      else if ((m = /^(?:patches\/)?localsql\/(.+)$/.exec(p))) { kind = "localSql"; rel = m[1]; }
      else if ((m = /^patches\/sql\/(.+)$/.exec(p))) { kind = "gameSql"; rel = m[1]; }
      else if ((m = /^(?:patches\/)?assets\/(.+)$/.exec(p))) { kind = "asset"; rel = m[1]; }
      else if ((m = /^(?:patches\/Areas|Areas|areas)\/(.+)$/.exec(p))) { kind = "area"; rel = m[1]; }
      if (!SAFE(rel)) throw fail("Unsafe Sparking path.");
      if (kind !== "other") { const k = kind + ":" + rel; if (kinds.has(k)) throw fail("Sparking payload aliases would overwrite the same converted file."); kinds.add(k); }
      if (kind === "other" || (kind === "gameSql" && !/\.sql$/i.test(rel))) outside = true;
      if (kind === "metadata") {
        if (b.length > MiB) throw fail("Sparking metadata exceeds1MiB.");
        const t = new TextDecoder("utf-8", { fatal: true }).decode(b);
        let depth = 0, max = 0, inStr = false, esc = false;
        for (const ch of t) { if (inStr) { if (esc) esc = false; else if (ch === "\\") esc = true; else if (ch === '"') inStr = false; } else if (ch === '"') inStr = true; else if (ch === "{" || ch === "[") max = Math.max(max, ++depth); else if (ch === "}" || ch === "]") depth--; }
        if (max > 32) throw fail("Sparking patch metadata is nested too deeply.");
        info = JSON.parse(t);
      }
      files.push({ path: p, relativePath: rel, bytes: b, kind });
    }
    const by = (k) => files.filter((f) => f.kind === k);
    if (!info) warnings.push("This patch has no patch_info.json; keep its file name and supply a creation name.");
    if (!by("gameSql").length) warnings.push("No patches/sql game-database payload is present. Assets or local roster data alone cannot create an Eclipse unit.");
    if (by("localSql").length) warnings.push("This patch contains Sparking-only local roster SQL. It cannot be applied to Eclipse's game database.");
    if (by("area").length) warnings.push("This patch contains Sparking Areas content whose Eclipse mapping is unverified.");
    if (outside) warnings.push("This archive has payloads outside the verified conversion layout. They need inspection before an Eclipse conversion.");
    const str = (o, ks) => { for (const k of ks) if (o && typeof o[k] === "string" && o[k].trim()) return o[k].trim(); return ""; };
    const creator = info && typeof info.creator === "object" ? info.creator : null;
    const creatorName = str(info, ["creator_name", "creatorName", "creator"]) || str(creator, ["name", "creator_name", "creatorName"]);
    let creatorId = 0;
    for (const o of [info, creator]) for (const k of ["creator_id", "creatorId", "creatorID"]) {
      if (creatorId || !o || typeof o[k] === "boolean" || o[k] == null) continue;
      const s = String(o[k]); if (/^[0-9]{1,10}$/.test(s) && +s >= 1 && +s <= 2147483647) creatorId = +s;
    }
    return { info: info || {}, files, warnings, creatorName, creatorId, canConvert: by("gameSql").length > 0 && !by("localSql").length && !by("area").length && !outside };
  }
  async function convert(zip, ins, name) {
    if (!ins.canConvert) throw fail(["This patch uses Sparking features that cannot yet be converted safely to Eclipse."].concat(ins.warnings).join(" "));
    const info = ins.info;
    const nm = (String(info.name || info.patch_name || name.replace(/\.sprk$/i, "")).trim() || "Imported Sparking patch").slice(0, 160);
    let version = typeof info.version === "string" || typeof info.version === "number" ? String(info.version).trim() : "";
    if (!version || version.length > 50) version = "1.0";
    const zipSha = await IOS.sha256Hex(new Uint8Array(await zip.arrayBuffer()));
    const metadata = { uuid: IOS.uuid4(), name: nm, version, author: ins.creatorName, description: info.description, sourceFormat: "sparking-sprk", sourceFilename: name, sourceZIPsha256: zipSha,
      compatibility: "Format converted; Eclipse SQL and gameplay compatibility need validation in Eclipse." };
    const entries = [], seen = new Set();
    const add = (path, bytes) => {
      const k = path.normalize("NFC").toLowerCase();
      if (seen.has(k)) throw fail("Sparking SQL and assets would overwrite the same Eclipse file.");
      for (const s of seen) if (k.startsWith(s + "/") || s.startsWith(k + "/")) throw fail("An Eclipse file would overwrite a converted resource folder.");
      seen.add(k); entries.push({ path, bytes });
    };
    for (const f of ins.files) {
      if (f.kind === "gameSql") add("files/sparking-sql/" + f.relativePath, f.bytes);
      else if (f.kind === "asset") { if (/\.sql$/i.test(f.relativePath)) throw fail("A Sparking asset ends in .sql and could be executed by Eclipse. Conversion was stopped."); add("files/" + f.relativePath, f.bytes); }
    }
    add("sparking-source.json", new TextEncoder().encode(JSON.stringify(info)));
    entries.unshift({ path: "metadata.json", bytes: new TextEncoder().encode(JSON.stringify(metadata)) });
    return { bytes: await window.ForgeEclp.write(entries, { deriveKey: IOS.deriveKey }), metadata };
  }
})();
