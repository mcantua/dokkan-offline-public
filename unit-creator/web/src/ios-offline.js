/* iPhone app: Offline downloads (Android: OfflineLibrary): player files, animation scripts, character
 * pictures, your characters' animations and movies, or everything; saved into the preview storage so
 * animations play without Internet. Same packs, phases, Wi-Fi-only rule and storage budget. */
(function () {
  "use strict";
  const IOS = window.__forgeIOS;
  if (!IOS || !IOS.previewCache) return;
  const { host, H } = IOS;
  const fail = (m) => new Error(m);
  const MiB = 1048576, GiB = 1073741824, ORIGIN = "https://dokkan-eclipse.com";
  const PREFS = "offline-library.json";
  const BUDGETS = [512 * MiB, GiB, 2 * GiB, 4 * GiB, 8 * GiB, 16 * GiB, 32 * GiB];
  class Missing extends Error {}
  class Cancelled extends Error {}
  class StorageFull extends Error {}
  let prefs = null, job = null, scan = { at: 0, value: null };
  async function loadPrefs() {
    if (!prefs) prefs = Object.assign({ wifiOnly: true, movies: false, completed: {} }, (await host.exists(PREFS)) ? (await host.readJson(PREFS)) || {} : {});
    return prefs;
  }
  const savePrefs = () => host.writeJson(PREFS, prefs).catch(() => {});
  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const encPath = (p) => p.split("/").map((s) => { if (!s || s === "." || s === "..") throw fail("Unsafe path"); return encodeURIComponent(s).replace(/[!'()~]/g, (c) => "%" + c.charCodeAt(0).toString(16).toUpperCase()); }).join("/");

  async function storageInfo() {
    if (job && !job.finished && job.limit > 0) return { bytes: job.used, maxBytes: job.limit, free: (await host.info()).freeBytes };
    try {
      if (Date.now() - scan.at > 15000) {
        scan.at = Date.now();
        H.previewCache({}).then((r) => { scan.value = r; }).catch(() => {});
      }
      const free = (await host.info()).freeBytes;
      const s = await IOS.previewCache.settings();
      return scan.value ? { bytes: scan.value.bytes, count: scan.value.count, maxBytes: scan.value.maxBytes, free } : { maxBytes: [536870912].concat(BUDGETS.slice(1)).includes(s.maxBytes) ? s.maxBytes : 2 * GiB };
    } catch (e) { return {}; }
  }
  async function status() {
    const p = await loadPrefs();
    const out = { wifiOnly: p.wifiOnly, movies: p.movies, completed: p.completed, network: await host.call("network").catch(() => ({ unknown: true })), storage: await storageInfo(), folder: "Files › On My iPhone › Dokkan Unit Creator" };
    if (job) out.job = { running: !job.finished, paused: job.paused, cancelled: job.cancelled, finished: job.finished, phase: job.phase, label: job.label, waiting: job.waiting, total: job.total, done: job.done,
      failed: job.failed, skipped: job.skipped, savedBytes: job.savedBytes, reused: job.reused || 0, reusedBytes: job.reusedBytes || 0, error: job.error, packs: job.packs, startedAt: job.startedAt, finishedAt: job.finishedAt, failures: job.failures.slice(0, 20), cleanup: job.cleanup, originalsSkipped: job.originals, resumed: !!job.resumed };
    if (job && job.finished) host.keepAwake(false).catch(() => {});
    return out;
  }

  // iPhone: the app's downloads folder is always its own (Files › On My iPhone › Dokkan Unit Creator)
  H.storageCheck = async () => ({ permission: true, public: true, folder: "Files › On My iPhone › Dokkan Unit Creator", needsChoice: false, old: [] });
  H.storageAccess = async () => ({ opened: false });
  H.storageDecline = async () => H.storageCheck();

  H.offlineLibrary = async function (a) {
    const action = a.action || "status";
    const p = await loadPrefs();
    if (action === "start") {
      if (job && !job.finished) throw fail("A download is already running. Pause or cancel it first.");
      const packs = Array.isArray(a.packs) ? a.packs.filter((x) => typeof x === "string") : [];
      if (!packs.length) throw fail("Choose what to download.");
      p.wifiOnly = a.wifiOnly == null ? true : !!a.wifiOnly;
      p.movies = a.movies == null ? false : !!a.movies;
      await savePrefs();
      job = newJob(packs, a);
      p.pending = Object.assign({}, a, { action: "start" });
      await savePrefs();
      host.keepAwake(true).catch(() => {});
      run(job);
    } else if (!job && action === "status" && p.pending && Array.isArray(p.pending.packs)) {
      // the last download was interrupted (the app was closed): continue where it stopped
      job = newJob(p.pending.packs, Object.assign({}, p.pending, { tidy: false }));
      job.resumed = true;
      host.keepAwake(true).catch(() => {});
      run(job);
    } else if (action === "pause" || action === "resume") { if (job) job.paused = action === "pause"; }
    else if (action === "cancel") { if (job) { job.cancelled = true; job.paused = false; } }
    else if (action === "wifiOnly") { p.wifiOnly = a.value == null ? true : !!a.value; await savePrefs(); }
    return status();
  };

  // ---------------------------------------------------------------- clean-up before downloading
  // (iPhone: an uninstall removes the app's files, so there are no earlier-install folders to merge)
  async function tidy(j) {
    const r = { freedBytes: 0, removed: 0, reused: 0, reowned: 0, merged: [], adopted: false };
    const old = Date.now() - 10 * 60000;
    const drop = async (path, size) => { await host.remove(path).catch(() => {}); r.freedBytes += size || 0; r.removed++; };
    try {
      const files = await host.list("preview-cache").catch(() => []), names = new Set(files.map((f) => f.name));
      for (const f of files) {
        if (f.dir || f.mtime > old) continue;
        const half = (/^[a-f0-9]{64}\.body$/.test(f.name) && !names.has(f.name.slice(0, 64) + ".json")) || (/^[a-f0-9]{64}\.json$/.test(f.name) && !names.has(f.name.slice(0, 64) + ".body"));
        if (half || /^[a-f0-9]{64}\.(j?part\w*|tmp)$/.test(f.name)) await drop("preview-cache/" + f.name, f.size);
      }
      for (const f of await host.list("movie-cache").catch(() => [])) if (!f.dir && /\.part$/.test(f.name) && f.mtime <= old) await drop("movie-cache/" + f.name, f.size);
      for (const f of await host.list("sparking/resource-cache").catch(() => [])) if (!f.dir && /^sparking-asset-.*\.tmp$/.test(f.name) && f.mtime <= old) await drop("sparking/resource-cache/" + f.name, f.size);
      // scripts of an older game-data version: still the same size on Eclipse → moved over, else removed
      const key = j.sourceKey;
      if (key && /^[A-Za-z0-9_-]{1,80}$/.test(key)) {
        for (const d of await host.list("animation-sources").catch(() => [])) {
          if (!d.dir || d.name === key || !/^[A-Za-z0-9_-]{1,80}$/.test(d.name)) continue;
          const base = "animation-sources/" + d.name + "/";
          const all = (await host.call("list", { path: base + "ab_script", deep: true }).catch(() => [])).filter((f) => /^[A-Za-z0-9_/-]+\.lua$/.test(f.name));
          let offline = false;
          for (const f of all) {
            const from = base + "ab_script/" + f.name, to = "animation-sources/" + key + "/ab_script/" + f.name;
            if (await host.exists(to)) { await drop(from, f.size); continue; }
            let size = -1;
            try { const h = await host.call("head", { url: ORIGIN + "/cdn/uncompressed/lua/ab_script/" + encPath(f.name) }); size = h.status === 200 ? h.length : -1; }
            catch (e) { offline = true; continue; }
            if (size === f.size) { try { await host.move(from, to); r.reused++; continue; } catch (e) {} }
            await drop(from, f.size);
          }
          if (!offline) await host.remove(base).catch(() => {});
        }
      }
    } catch (e) {}
    return r;
  }

  // ---------------------------------------------------------------- Sparking: custom-made content only
  const SPARK_CONTENT = /^(character\/|card\/|thumb\/|card_transform\/|card_category\/|ingame\/|movie\/|lua\/ab_script\/|Custom\/|dokkan_field\/|outgame\/extension\/dokkan_field\/|script\/image\/character\/|bgm\/|voice\/|se\/).+/;
  const SPARK_TYPES = /\.(cpk|png|jpe?g|webp|lwf|lua|usm|acb|awb|json|atlas|plist|tmx|bytes|txt|ogg|mp3|wav)$/i;
  const stemOf = (n) => String(n || "").replace(/\.[A-Za-z0-9]+$/, "");
  function idPart(path) {
    const parts = path.split("/");
    for (let i = 1; i < parts.length; i++) if (/\d/.test(parts[i])) return [parts.slice(0, i).join("/"), stemOf(parts[i])];
    return [parts.slice(0, -1).join("/"), stemOf(parts[parts.length - 1])];
  }
  async function sparking(j, index) {
    let pack;
    try { pack = await IOS.sparkingPackManifest(); }
    catch (e) { j.failed++; j.failures.push("Sparking: " + (e.message || "the Sparking catalogue isn't ready. Download Sparking characters in Library first.")); return; }
    const scripts = new Set(index), lists = new Map();
    const names = async (folder) => {
      if (!lists.has(folder)) {
        let set = new Set();
        try {
          const form = encodeURIComponent(folder).replace(/[!'()~]/g, (c) => "%" + c.charCodeAt(0).toString(16).toUpperCase()).replace(/%20/g, "+");
          const d = await json(j, ORIGIN + "/api/file-browser?path=" + form);
          set = new Set((d.items || []).map((it) => stemOf(it && it.name)));
        } catch (e) { if (!(e instanceof Missing)) throw e; }
        lists.set(folder, set);
      }
      return lists.get(folder);
    };
    for (const rec of pack.m.assets || []) {
      const path = rec && rec.file_path;
      if (typeof path !== "string" || !SPARK_CONTENT.test(path) || !SPARK_TYPES.test(path) || path.includes("..")) continue;
      let custom;
      try {
        if (path.startsWith("Custom/")) custom = true;
        else if (path.startsWith("lua/")) custom = !scripts.has(path.slice(4));
        else { const [folder, name] = idPart(path); custom = !(await names(folder)).has(name); }
      } catch (e) { j.failed++; if (j.failures.length < 200) j.failures.push(path + ": couldn't check whether it is custom-made (" + e.message + ")"); continue; }
      if (!custom) { j.originals++; continue; }
      queue(j, path.split("/").pop(), async () => {
        await gate(j);
        const info = await host.info();
        if (info.freeBytes - (rec.size || 0) < 400 * MiB) throw new StorageFull("Your phone is almost out of space. Free some space, then tap Download again.");
        for (let tries = 0; ; tries++) {   // Wi-Fi went away: wait for it and try again, never mobile data
          try { j.savedBytes += await IOS.sparkingPackFile(pack.file, pack.m, path); break; }
          catch (e) {
            if (j.cancelled) throw new Cancelled();
            if (!/internet|offline|network|connection|cellular|lost|reached/i.test(String(e && e.message)) || tries > 2000) throw e;
            await sleep(3000); await gate(j);
          }
        }
      });
    }
    await idle(j);
  }

  function newJob(packs, a) {
    return { packs, cards: (Array.isArray(a.cards) ? a.cards : []).slice(0, 400), scripts: (Array.isArray(a.scripts) ? a.scripts : []).slice(0, 2000), moviePacks: (Array.isArray(a.moviePacks) ? a.moviePacks : []).slice(0, 400),
      paused: false, cancelled: false, finished: false, phase: "Starting", label: "", waiting: "", total: 0, done: 0, failed: 0, skipped: 0, savedBytes: 0, error: "",
      startedAt: Date.now(), finishedAt: 0, failures: [], seen: new Set(), queue: [], active: 0, used: 0, limit: 0, effectIds: new Map(), sourceKey: "",
      tidy: a.tidy !== false, cleanup: null, originals: 0 };
  }

  // one network "gate" before every request (pause, offline, Wi-Fi only)
  async function gate(j) {
    for (;;) {
      if (j.cancelled) throw new Cancelled();
      if (j.paused) { j.waiting = "Paused"; await sleep(500); continue; }
      const n = await host.call("network").catch(() => ({ unknown: true }));
      if (!n.unknown && !n.connected) { j.waiting = "Waiting for an Internet connection"; await sleep(3000); continue; }
      const wifiOnly = (await loadPrefs()).wifiOnly;
      host.call("wifiOnlyDownloads", { on: !!wifiOnly }).catch(() => {});   // iOS itself then refuses mobile data
      if (wifiOnly) {
        if (n.unknown) { j.waiting = "Can't check for Wi-Fi. Turn on “Also use mobile data” to continue."; await sleep(3000); continue; }
        if (n.metered || n.wifi === false) { j.waiting = "Waiting for Wi-Fi (mobile data is off for downloads)"; await sleep(3000); continue; }
      }
      j.waiting = "";
      return;
    }
  }
  async function reserve(j, bytes) {
    const info = await host.info();
    if (info.freeBytes - bytes < 400 * MiB) throw new StorageFull(j.moviePhase ? "Your phone ran out of space for more game movies. Everything else is downloaded." : "Your phone is almost out of space. Free some space, then tap Download again.");
    if (j.used + bytes > j.limit - 256 * MiB) {
      j.used = (await H.previewCache({})).bytes;
      const b = BUDGETS.find((x) => x >= j.used + bytes + 512 * MiB);
      if (!b) throw new StorageFull(j.moviePhase ? "Game movies stopped at the 32 GB download limit. Everything else is downloaded." : "Downloaded previews reached the 32 GB limit. Clear some downloads first.");
      if (b > j.limit) { await H.previewCache({ maxBytes: b }); j.limit = b; }
    }
    j.used += bytes;
  }
  // OfflineLibrary.download: into the preview storage, UA DokkanUnitForge/2.7; 404/410 = not on Eclipse
  async function save(j, url, max) {
    if (url.startsWith("/")) url = ORIGIN + url;
    if (await IOS.previewCache.cachedBody(url)) return 0;
    await gate(j);
    const n = IOS.previewCache.normalized(url);
    const base = "preview-cache/" + (await IOS.sha256Hex(new TextEncoder().encode(n)));
    const part = base + ".part" + Math.random().toString(36).slice(2, 8);
    let reserved = 0;
    // the Sparking app on this phone may already have this game file (Sparking/assets/<same path>): copy it
    // instead of downloading. It counts only when it is the same size as Eclipse's copy.
    const m = /^https:\/\/dokkan-eclipse\.com\/assets\/([^?#]+)$/.exec(n);
    if (m && IOS.fromGameFolder) {
      let rel = ""; try { rel = "assets/" + decodeURIComponent(m[1]); } catch (e) {}
      const got = rel && !/(^|\/)\.\.(\/|$)/.test(rel) ? await IOS.fromGameFolder(rel, part) : 0;
      if (got) {
        let size = -1;
        try { const h = await host.call("head", { url: n }); size = h.status === 200 ? h.length : -1; } catch (e) { size = got; }   // offline: keep the game's copy
        if (size === got && got <= max) {
          try {
            await reserve(j, got); reserved = got;
            if (!(await host.exists(base + ".body"))) { await host.move(part, base + ".body"); await host.writeJson(base + ".json", { url: n, type: ({ png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg", webp: "image/webp", json: "application/json" })[(n.split(".").pop() || "").toLowerCase()] || "application/octet-stream", from: "sparking-folder" }); }
            IOS.reused.files++; IOS.reused.bytes += got; j.reused = (j.reused || 0) + 1; j.reusedBytes = (j.reusedBytes || 0) + got;
            return 0;
          } catch (e) { if (reserved) { j.used -= reserved; reserved = 0; } }
        }
        await host.remove(part).catch(() => {});
      }
    }
    try {
      // a download cut off because Wi-Fi went away waits for Wi-Fi and tries again (it is never moved to mobile data)
      let r;
      for (let tries = 0; ; tries++) {
        try { r = await host.download(n, part, { headers: { "User-Agent": "DokkanUnitForge/2.7", "Accept-Encoding": "identity" }, keepErrors: true }); break; }
        catch (e) {
          if (j.cancelled) throw new Cancelled();
          const net = /internet|offline|network|connection|cellular|lost/i.test(String(e && e.message));
          if (!net && tries >= 2) throw e;
          if (tries > 2000) throw e;
          await sleep(net ? 3000 : tries ? 6000 : 2000);
          await gate(j);
        }
      }
      if (r.status === 404 || r.status === 410) throw new Missing("Not on Eclipse");
      if (r.status !== 200) throw fail("Eclipse returned HTTP " + r.status);
      if (!/^https:\/\/dokkan-eclipse\.com\//.test(r.finalUrl || n)) throw fail("Eclipse redirected outside its website");
      if (r.bytes > max) throw fail("File is larger than the preview limit");
      await reserve(j, r.bytes); reserved = r.bytes;
      if (await host.exists(base + ".body")) { j.used -= reserved; return 0; }
      try { await host.move(part, base + ".body"); await host.writeJson(base + ".json", { url: n, type: r.contentType || "application/octet-stream" }); }
      catch (e) { throw fail("Could not save a downloaded file"); }
      j.savedBytes += r.bytes;
      return r.bytes;
    } catch (e) { if (reserved) j.used -= reserved; throw e; }
    finally { host.remove(part).catch(() => {}); }
  }
  async function json(j, url) {
    await save(j, url, 4 * MiB);
    const t = await IOS.previewCache.cacheText(url, 4 * MiB).catch(() => null);
    if (t == null) throw fail("Not saved");
    return JSON.parse(t);
  }
  // 24 files at a time: keeps Wi-Fi busy without choking the phone or Eclipse's server
  function queue(j, label, fn) {
    j.total++;
    j.queue.push({ label, fn });
    pump(j);
  }
  function pump(j) {
    while (j.active < 24 && j.queue.length) {
      const t = j.queue.shift();
      j.active++;
      Promise.resolve().then(t.fn).then(() => {}, (e) => {
        if (e instanceof Missing) j.skipped++;
        else if (e instanceof Cancelled) {}
        else if (e instanceof StorageFull) { j.error = e.message; j.cancelled = true; }
        else { j.failed++; if (j.failures.length < 200) j.failures.push(t.label + ": " + e.message); }
      }).finally(() => { j.done++; j.active--; pump(j); });
    }
  }
  async function idle(j) { while (j.active || j.queue.length) { if (j.cancelled) { j.queue.length = 0; } await sleep(200); } if (j.cancelled) throw new Cancelled(); }
  const file = (j, url, max) => { if (j.seen.has(url)) return; j.seen.add(url); queue(j, url.split("?")[0].split("/").pop(), () => save(j, url, max)); };
  const folderOf = (rel) => { if (typeof rel !== "string" || !/^[a-z0-9_./-]+$/i.test(rel)) return null; const i = rel.lastIndexOf("/"); return i > 0 ? rel.slice(0, i) : null; };
  function folder(j, f) {
    if (!f || j.seen.has("folder:" + f)) return;
    j.seen.add("folder:" + f);
    queue(j, f, async () => {
      const form = encodeURIComponent(f).replace(/[!'()~]/g, (c) => "%" + c.charCodeAt(0).toString(16).toUpperCase()).replace(/%20/g, "+");
      const d = await json(j, ORIGIN + "/api/file-browser?path=" + form);
      for (const it of (d.items || []).filter((x) => x && x.type === "file").slice(0, 400)) {
        let path = String(it.path || "");
        if (!path.includes("/")) path = f + "/" + path;
        if (/^[a-z0-9_./ -]+\.(lwf|png|jpe?g|webp|json)$/i.test(path)) file(j, ORIGIN + "/assets/" + encPath(path), 160 * MiB);
      }
    });
  }
  function card(j, id) {
    if (!(id >= 1 && id <= 99999999) || j.seen.has("card:" + id)) return;
    j.seen.add("card:" + id);
    queue(j, "card " + id, async () => {
      const c = await json(j, ORIGIN + "/api/card/" + id);
      if (!c.found) return;
      for (const k of ["battle", "idle", "sp", "card_bg"]) folder(j, folderOf(c[k] && c[k].rel));
      for (const t of Object.values(c.textures || {})) if (t && typeof t.url === "string" && (t.url.startsWith("/assets/") || t.url.startsWith("/api/card/"))) file(j, ORIGIN + t.url, 160 * MiB);
      file(j, ORIGIN + "/api/card/" + id + "/fit/sp_name.png?w=1024&h=256&v=3", 8 * MiB);
      file(j, ORIGIN + "/api/card/" + id + "/fit/sp_phrase.png?w=1024&h=512&v=3", 8 * MiB);
      if (c.aura_effect_id > 0) effect(j, c.aura_effect_id);
    });
  }
  function effect(j, id, withMovie) {
    if (withMovie == null) withMovie = j.movies;
    const key = "effect:" + id + (withMovie ? ":movie" : "");
    if (j.seen.has(key)) return;
    j.seen.add(key);
    queue(j, "effect " + id, async () => {
      for (const form of ["", "?enemy=0", "?enemy=1"]) {
        let pack;
        try { pack = await json(j, ORIGIN + "/api/effect-pack/" + id + form); } catch (e) { if (e instanceof Missing) continue; throw e; }
        if (!pack.found) continue;
        folder(j, folderOf(pack.lwf && pack.lwf.rel));
        if (withMovie && pack.usm && typeof pack.usm.url === "string" && pack.usm.url.startsWith("/assets/")) file(j, ORIGIN + pack.usm.url, 160 * MiB);
      }
    });
  }
  async function scriptAssets(j, paths) {
    for (const path of paths) {
      try {
        const t = await host.readText("animation-sources/" + j.sourceKey + "/" + path);
        if (t == null) continue;
        const consts = new Map();
        for (const m of t.matchAll(/^\s*([A-Za-z_]\w*)\s*=\s*(\d{1,9})\s*;?/gm)) consts.set(m[1], Number(m[2]));
        const num = (s) => (/^\d+$/.test(s) ? Number(s) : consts.get(s));
        const arg = "\\(([^,()]*(?:\\([^()]*\\))?[^,()]*),\\s*([A-Za-z_]\\w*|\\d{1,9})";
        for (const m of t.matchAll(new RegExp("entryEffect\\w*\\s*" + arg, "g"))) { const id = num(m[2]); if (id != null && j.effectIds.has(id)) effect(j, id); }
        for (const m of t.matchAll(new RegExp("setupMovie\\s*" + arg, "g"))) { const id = num(m[2]); if (id != null) effect(j, id, true); }
        for (const m of t.matchAll(new RegExp("playSe\\w*\\s*" + arg, "g"))) { const id = num(m[2]); if (id != null) file(j, ORIGIN + "/api/se?cue=" + id, 32 * MiB); }
      } catch (e) { if (j.failures.length < 200) j.failures.push(path + ": " + e.message); }
    }
    await idle(j);
  }
  async function complete(j, pack) {
    if (j.cancelled) throw new Cancelled();
    const p = await loadPrefs();
    p.completed[pack] = { at: Date.now(), failed: j.failed };
    await savePrefs();
  }

  async function run(j) {
    try {
      j.movies = (await loadPrefs()).movies;
      const s = await H.previewCache({});
      j.used = s.bytes; j.limit = s.maxBytes;
      j.sourceKey = await IOS.dbKey();
      let index = [];
      try { index = (await IOS.scriptListing()).scripts.map((x) => x.path); } catch (e) {}
      try {
        const db = await IOS.dbPath("main");
        for (const r of await IOS.sql(db, "SELECT id, category FROM effect_packs")) j.effectIds.set(r.id, r.category);
      } catch (e) { j.failures.push("Database: " + e.message); }
      const has = (p) => j.packs.includes(p);
      if (j.tidy) { j.phase = "Cleaning up old files"; j.cleanup = await tidy(j); scan.at = 0; }
      if (has("essentials") || has("units") || has("everything")) {
        j.phase = "Animation player";
        await H.previewTools({ prepare: true });
        const t0 = Date.now();
        let st = await H.previewTools({});
        while (st.preparing && Date.now() - t0 < 15 * 60000) { if (j.cancelled) throw new Cancelled(); j.label = "Player files " + st.preparedFiles + " of " + st.totalFiles; await sleep(1000); st = await H.previewTools({}); }
        if (!st.ready) { j.failed++; j.failures.push("Animation player: some player files could not be saved. Download again to retry."); }
        j.phase = "Animation scripts";
        for (const path of index) {
          if (!/^ab_script\/[a-z0-9_/-]+\.lua$/i.test(path) || path.includes("..")) continue;
          const f = "animation-sources/" + j.sourceKey + "/" + path;
          if (j.seen.has("script:" + path)) continue;
          j.seen.add("script:" + path);
          queue(j, path.split("/").pop(), async () => {
            if (await host.exists(f)) return;
            await gate(j);
            let text;
            try { text = await IOS.fetchText(ORIGIN + "/cdn/uncompressed/lua/" + path, 2 * MiB); }
            catch (e) { if (/HTTP 404/.test(e.message)) throw new Missing("Not on Eclipse"); if (/exceeds/.test(e.message)) throw fail("Script is too large"); throw e; }
            if (!text.trim() || text.trim().startsWith("<") || text.includes("\u0000")) throw new Missing("Not on Eclipse");
            try { await host.writeText(f + ".part", text); await host.move(f + ".part", f); } catch (e) { throw fail("Could not save script"); }
          });
        }
        await idle(j);
        j.phase = "Character pictures";
        const db = await IOS.dbPath("main");
        for (const r of await IOS.sql(db, "SELECT DISTINCT (COALESCE(NULLIF(resource_id, 0), id) / 10) * 10 AS a, 0 FROM cards WHERE id < 9000000")) {
          if (r.a > 0) file(j, ORIGIN + "/cdn/uncompressed/character/thumb/card_" + r.a + "_thumb/card_" + r.a + "_thumb.png", 4 * MiB);
        }
        await idle(j);
        await complete(j, "essentials");
      }
      if (has("units") && !has("everything")) {
        j.phase = "Your characters";
        for (const id of j.cards) card(j, Number(id));
        await idle(j);
        j.phase = "Your animations";
        await scriptAssets(j, ["ab_script/common/common.lua"].concat(index.filter((p) => p.startsWith("ab_script/ab_sys/")), j.scripts.filter((p) => typeof p === "string")));
        j.phase = "Movies in your animations";
        for (const id of j.moviePacks) effect(j, Number(id), true);
        await idle(j);
        await complete(j, "units");
      }
      if (has("everything")) {
        const db = await IOS.dbPath("main");
        j.phase = "Every animation effect";
        // game movies are huge (tens of GB): they come last, so running out of room never stops the rest
        for (const r of await IOS.sql(db, "SELECT id, category FROM effect_packs ORDER BY id")) { if (r.category === 5) continue; effect(j, r.id, false); }
        await idle(j);
        j.phase = "Every animation sound";
        await scriptAssets(j, index);
        j.phase = "Every character";
        for (const r of await IOS.sql(db, "SELECT id, 0 FROM cards WHERE id < 9000000 AND id % 10 IN (0, 1) ORDER BY id")) card(j, r.id);
        await idle(j);
        await complete(j, "everything");
        if (j.movies) {
          j.phase = "Every game movie";
          j.moviePhase = true;
          for (const r of await IOS.sql(db, "SELECT id, category FROM effect_packs ORDER BY id")) effect(j, r.id, true);
          await idle(j);
          await complete(j, "movies");
        }
      }
      if (has("sparking")) {
        j.phase = "Sparking custom content";
        await sparking(j, index);
        await complete(j, "sparking");
      }
      j.phase = j.cancelled ? "Cancelled" : "Done";
    } catch (e) {
      if (e instanceof Cancelled) j.phase = "Cancelled";
      else { j.phase = "Stopped"; j.error = e.message; }
    } finally {
      j.queue.length = 0;
      const t0 = Date.now();
      while (j.active && Date.now() - t0 < 75000) await sleep(200);
      host.keepAwake(false).catch(() => {});
      j.label = ""; j.waiting = ""; j.finished = true; j.finishedAt = Date.now(); host.call("wifiOnlyDownloads", { on: false }).catch(() => {});
      try { const pr = await loadPrefs(); delete pr.pending; await savePrefs(); } catch (e) {}
      scan.at = 0;
      for (const f of await host.list("preview-cache").catch(() => [])) if (/^[a-f0-9]{64}\.j?part/.test(f.name)) host.remove("preview-cache/" + f.name).catch(() => {});
    }
  }
})();
