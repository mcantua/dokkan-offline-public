/* iPhone app: the Android app's native features, rebuilt on the iPhone's own services.
 * Loaded after web-native.js (units, .eclp export, AI copy & paste…) and ios-host.js (files, network,
 * SQLite, Keychain). Each section below replaces one part of the Android app's native code
 * (CreatorActivity and friends) with the same inputs, answers and error messages. */
(function () {
  "use strict";
  const host = window.ForgeHost, web = window.__forgeWeb;
  if (!host || !web) return;
  const H = web.handlers;
  const IOS = (window.__forgeIOS = { host, H });
  window.forgeNative.ios = true;
  document.documentElement.classList.remove("web-version");
  document.documentElement.classList.add("ios-app");
  const fail = (message) => new Error(message);

  // ---------------------------------------------------------------- game databases (SQLite)
  // Same files as the Android app (reference.db, sparking-reference.db), same SQL.
  const DB = { main: null, sparking: null };
  const IDENT = /^[a-zA-Z_][a-zA-Z0-9_]*$/;
  function identifier(name) {
    if (!IDENT.test(String(name))) throw fail("Invalid database name");
    return '"' + name + '"';
  }
  // GameDataStore: <dir>/database-state.json → {version:1, active:{file,meta}, previous?}; files in <dir>/databases/
  const STORES = { main: { dir: "", bundled: "db/reference.db" }, sparking: { dir: "sparking/", bundled: "db/sparking-reference.db" } };
  const HEX_DB = /^db-[a-f0-9]{64}\.db$/;
  async function storeState(kind) {
    const f = STORES[kind].dir + "database-state.json";
    if (!(await host.exists(f))) return null;
    const st = await host.readJson(f);
    if (!st || st.version !== 1) throw fail("Unsupported database state");
    for (const k of ["active", "previous"]) if (st[k] && !HEX_DB.test(st[k].file || "")) throw fail("Invalid stored database name");
    return st;
  }
  async function dbPath(kind) {
    const st = await storeState(kind);
    return st ? STORES[kind].dir + "databases/" + st.active.file : STORES[kind].bundled;
  }
  async function sql(path, text, params) {
    const r = await host.call("sql", { db: path, sql: text, params: params || [] });
    return r.rows.map((row) => { const o = {}; r.columns.forEach((c, i) => { const v = row[i]; o[c] = v && typeof v === "object" && v.base64 != null ? v.base64 : v; }); return o; });
  }
  async function openDb(kind) {
    const path = await dbPath(kind);
    if (DB[kind] && DB[kind].path === path) return DB[kind];
    await host.call("installDatabases");
    const tables = await sql(path, "SELECT name FROM sqlite_master WHERE type='table'");
    const schema = {};
    for (const t of tables) {
      if (!IDENT.test(t.name)) continue;
      schema[t.name] = await sql(path, "PRAGMA table_info(" + identifier(t.name) + ")");
    }
    DB[kind] = { path, schema };
    return DB[kind];
  }
  IOS.openDb = openDb; IOS.sql = sql; IOS.dbPath = dbPath; IOS.storeState = storeState;

  /** CreatorActivity.queryDatabase: filters / ids / search / order / limit / offset → rows */
  async function queryDatabase(kind, q) {
    const { path, schema } = await openDb(kind);
    const table = String(q.table || "");
    const cols = schema[table];
    if (!cols) throw fail("Table is not in this database.");
    const names = new Set(cols.map((c) => c.name));
    const where = [], args = [];
    const filters = q.filters && typeof q.filters === "object" ? q.filters : null;
    if (filters) {
      for (const k of Object.keys(filters)) {
        if (!names.has(k)) throw fail("Unknown column");
        if (filters[k] == null) where.push(identifier(k) + " IS NULL");
        else { where.push(identifier(k) + " = ?"); args.push(String(filters[k])); }
      }
    }
    if (Array.isArray(q.ids)) {
      if (!q.ids.length) return [];
      if (q.ids.length > 1000) throw fail("Too many row IDs");
      where.push('"id" IN (' + q.ids.map(() => "?").join(",") + ")");
      for (const id of q.ids) args.push(String(Math.trunc(Number(id))));
    }
    const search = q.search && typeof q.search === "object" ? q.search : null;
    if (search && search.text) {
      if (!names.has(search.column)) throw fail("Unknown search column");
      where.push(identifier(search.column) + " LIKE ?");
      args.push("%" + String(search.text).slice(0, 200) + "%");
    }
    const order = q.order == null ? "id" : String(q.order);
    if (!names.has(order)) throw fail("Unknown sort column");
    const limit = Math.max(1, Math.min(5000, q.limit != null && Number.isFinite(+q.limit) ? Math.trunc(+q.limit) : 100));
    const offset = Math.max(0, q.offset != null && Number.isFinite(+q.offset) ? Math.trunc(+q.offset) : 0);
    const text = "SELECT * FROM " + identifier(table) + (where.length ? " WHERE " + where.join(" AND ") : "") +
      " ORDER BY " + identifier(order) + " LIMIT " + limit + " OFFSET " + offset;
    return sql(path, text, args);
  }
  IOS.queryDatabase = queryDatabase;

  H.info = async function () {
    const { path, schema } = await openDb("main");
    const count = (await sql(path, "SELECT count(*) AS n FROM cards"))[0].n;
    const st = await storeState("main");
    const meta = st ? st.active.meta : await bundledMeta();
    return { schema, count, meta, database: { canRestore: !!(st && st.previous) } };
  };
  let bundled = null;
  async function bundledMeta() {
    if (bundled) return bundled;
    bundled = { source: "Bundled Eclipse English snapshot · 2026-10-14", date: "2026-10-14" };
    try { bundled = await (await fetch("web/ios-meta.json")).json(); } catch (e) {}
    return bundled;
  }
  H.query = (a) => queryDatabase("main", a || {});
  H.querySparking = (a) => queryDatabase("sparking", a || {});
  // web-native's table reader (used by its own helpers) now reads SQLite too
  web.query = H.query;

  // ---------------------------------------------------------------- AI (ForgeAi / AiHandoff)
  // Keys go to the iPhone Keychain ("ai.<provider>") and are added to requests natively; this code
  // only ever sees "hasKey" and a hint. Models and addresses live in ai-connections.json.
  const PROVIDERS = ["openai", "gemini", "anthropic", "xai", "openrouter", "custom"];
  const AI_BASE = { openai: "https://api.openai.com/v1", gemini: "https://generativelanguage.googleapis.com/v1beta", anthropic: "https://api.anthropic.com/v1", xai: "https://api.x.ai/v1", openrouter: "https://openrouter.ai/api/v1" };
  const AI_FILE = "ai-connections.json";
  async function aiStore() { const s = (await host.exists(AI_FILE)) ? await host.readJson(AI_FILE) : null; return s && typeof s === "object" ? s : {}; }
  async function aiSave(s) { try { await host.writeJson(AI_FILE, s); } catch (e) { throw fail("Could not save the AI connection."); } }
  async function publicView(provider, c) {
    const k = await host.call("secretHint", { key: "ai." + provider });
    return { provider, hasKey: !!k.hasKey, keyHint: k.keyHint || "", model: c.model || "", imageModel: c.imageModel || "", baseUrl: c.baseUrl || "", updatedAt: Number(c.updatedAt) || 0 };
  }
  function clean(v, max) {
    const t = String(v == null ? "" : v).trim();
    if (t.length > max) throw fail("A setting is too long.");
    if (/[\x00-\x1f\x7f]/.test(t)) throw fail("Remove spaces or line breaks from the key and model names.");
    return t;
  }
  H.aiConnections = async function () {
    const s = await aiStore(), out = [];
    for (const p of Object.keys(s)) if (PROVIDERS.includes(p)) out.push(await publicView(p, s[p] || {}));
    return { connections: out, active: (s._settings && s._settings.active) || "" };
  };
  H.aiSaveConnection = async function (a) {
    const provider = String(a.provider || "");
    if (!PROVIDERS.includes(provider)) throw fail("Choose an AI provider.");
    const s = await aiStore(), old = s[provider] || {}, c = Object.assign({}, old);
    if ("apiKey" in a && a.apiKey != null) {
      const key = clean(a.apiKey, 512);
      if (/\s/.test(key)) throw fail("The API key cannot contain spaces.");
      if (key || a.clearKey === true) await host.secretSet("ai." + provider, key);
    } else if (a.clearKey === true) await host.secretDelete("ai." + provider);
    c.model = clean(a.model != null ? a.model : old.model, 160);
    c.imageModel = clean(a.imageModel != null ? a.imageModel : old.imageModel, 160);
    if (provider === "custom") {
      const base = clean(a.baseUrl != null ? a.baseUrl : old.baseUrl, 300).replace(/\/+$/, "");
      let u = null; try { u = new URL(base); } catch (e) { throw fail("no protocol: " + base); }
      if (!(u.protocol === "https:" || (u.protocol === "http:" && u.hostname === "127.0.0.1")) || !u.hostname || u.username || u.password)
        throw fail("Use an https:// address (for example https://example.com/v1), or http://127.0.0.1 for an AI app running on this phone.");
      c.baseUrl = base;
    } else if (!(await host.call("secretHint", { key: "ai." + provider })).hasKey) {
      throw fail("Paste your API key to connect " + provider + ".");
    }
    c.updatedAt = Date.now();
    delete c.apiKey;
    s[provider] = c;
    if (a.makeActive !== false) s._settings = Object.assign({}, s._settings, { active: provider });
    await aiSave(s);
    return publicView(provider, c);
  };
  H.aiRemoveConnection = async function (a) {
    const provider = String(a.provider || "");
    if (!PROVIDERS.includes(provider)) throw fail("Choose an AI provider.");
    const s = await aiStore();
    delete s[provider];
    if (s._settings && s._settings.active === provider) s._settings.active = "";
    await host.secretDelete("ai." + provider);
    await aiSave(s);
    return { removed: true };
  };
  const jobs = new Map();
  H.aiStart = async function (a) {
    const now = Date.now();
    for (const [id, j] of jobs) if (now - j.started > 15 * 60000) jobs.delete(id);
    if ([...jobs.values()].filter((j) => !j.done).length >= 3) throw fail("Three AI requests are already running. Wait for one to finish.");
    const provider = String(a.provider || "");
    if (!PROVIDERS.includes(provider)) throw fail("Connect an AI provider first.");
    const s = await aiStore();
    if (!s[provider]) throw fail("Connect " + provider + " first.");
    const path = String(a.path || "");
    if (!/^[A-Za-z0-9/._:\-?=&%]{1,300}$/.test(path) || path.includes("..")) throw fail("Unsupported AI request.");
    const method = a.method === "GET" ? "GET" : "POST";
    let base = AI_BASE[provider];
    if (provider === "custom") { base = s.custom.baseUrl || ""; if (!base) throw fail("Add the server address for your custom AI."); }
    let body = null;
    if (method === "POST") {
      body = a.body && typeof a.body === "object" ? JSON.stringify(a.body) : "{}";
      if (new Blob([body]).size > 24 * 1024 * 1024) throw fail("This AI request is too large.");
    }
    const id = (crypto.randomUUID ? crypto.randomUUID() : "job-" + now + "-" + Math.random().toString(36).slice(2));
    const job = { started: now, done: false };
    jobs.set(id, job);
    host.call("aiRequest", { job: id, provider, url: base + path, method, body })
      .then((r) => { job.result = r; }, (e) => { job.error = (e && e.message) || "The AI request failed."; })
      .finally(() => { job.done = true; });
    return { job: id };
  };
  H.aiPoll = async function (a) {
    const job = jobs.get(a.job);
    if (!job || job.canceled) throw fail("This AI request is no longer available. Try again.");
    if (!job.done) return { done: false, seconds: Math.floor((Date.now() - job.started) / 1000) };
    jobs.delete(a.job);
    if (job.error) throw fail(job.error);
    return { done: true, status: job.result.status, text: job.result.text || "" };
  };
  H.aiCancel = async function (a) {
    const job = jobs.get(a.job);
    jobs.delete(a.job);
    if (job) { job.canceled = true; host.call("aiCancel", { job: a.job }).catch(() => {}); }
    return { canceled: true };
  };
  const ASSISTANTS = { chatgpt: ["ChatGPT", "https://chatgpt.com/"], grok: ["Grok", "https://grok.com/"], claude: ["Claude", "https://claude.ai/"] };
  H.aiCompose = async function (a) {
    const p = ASSISTANTS[String(a.provider || "").toLowerCase()];
    if (!p) throw fail("Choose ChatGPT, Claude, or Grok.");
    const prompt = String(a.prompt == null ? "" : a.prompt);
    if (!prompt.trim() || prompt.length > 64000 || prompt.includes("\u0000")) throw fail("Use a prompt between 1 and 64,000 characters.");
    await host.call("copyText", { text: prompt });
    // the official app opens if installed (it claims its website's links), otherwise the website
    try { await host.openURL(p[1]); } catch (e) { throw fail("Could not open " + p[0] + ". Your prompt may already be copied; open its official app and paste it."); }
    return { requested: true, copied: true, provider: p[0], transport: "clipboard-app" };
  };
  // Android shows a native "AI assistants" launcher screen; on iPhone the same choices show as cards
  // in the AI page (the screens support this), and each one opens the official app or website.
  H.ai = async function (a) {
    const id = String((a && a.provider) || "").toLowerCase();
    if (!id) return Object.keys(ASSISTANTS).map((k) => ({ id: k, name: ASSISTANTS[k][0], installed: false }));
    const p = ASSISTANTS[id];
    if (!p) throw fail("Choose ChatGPT, Claude, or Grok.");
    if (!(await host.openURL(p[1]).catch(() => false))) throw fail("Unable to open " + p[0]);
    return { opened: true };
  };

  // ---------------------------------------------------------------- calls run one at a time (like Android)
  // Android runs every bridge call on one worker thread in order; "importStatus" is answered at once
  // and file pickers (import, importApk, export) run separately.
  let progress = {};
  IOS.progress = (phase, label, bytes, total) => { progress = { phase, label, bytes: bytes || 0, total: total || 0 }; };
  H.importStatus = async () => progress;
  const OUT_OF_LINE = new Set(["importStatus", "import", "importApk", "export", "aiPoll", "previewDock"]);
  let chain = Promise.resolve();
  const callWeb = window.forgeNative.call;
  window.forgeNative.call = function (method, args) {
    if (!H[method]) return Promise.reject(fail("Unsupported action: " + method));
    if (OUT_OF_LINE.has(method)) return callWeb.call(window.forgeNative, method, args);
    const run = chain.then(() => callWeb.call(window.forgeNative, method, args));
    chain = run.catch(() => {});
    return run;
  };

  // ---------------------------------------------------------------- game database: verify, update, undo
  const REQUIRED = { cards: ["id", "name", "rarity", "element", "resource_id", "hp_max", "atk_max", "def_max", "passive_skill_set_id", "leader_skill_set_id"],
    card_categories: ["id", "name"], link_skills: ["id", "name"], leader_skill_sets: ["id"], leader_skills: ["id", "leader_skill_set_id"],
    passive_skill_sets: ["id"], passive_skills: ["id"], passive_skill_set_relations: ["id", "passive_skill_set_id", "passive_skill_id"] };
  async function verifyDb(path, strict) {
    try {
      const qc = await sql(path, "PRAGMA quick_check");
      if (!qc.length || Object.values(qc[0])[0] !== "ok") throw fail("Database integrity check failed");
      for (const [t, cols] of Object.entries(REQUIRED)) {
        const m = await sql(path, "SELECT type FROM sqlite_master WHERE name = ?", [t]);
        if (!m.length || m[0].type !== "table") throw fail("Expected game data table: " + t);
        const have = new Set((await sql(path, "PRAGMA table_info(" + identifier(t) + ")")).map((c) => c.name));
        if (cols.some((c) => !have.has(c))) throw fail("Database is missing game fields: " + t);
      }
      const n = (await sql(path, "SELECT count(*) AS n FROM cards"))[0].n;
      if (n < (strict ? 1000 : 1)) throw fail("The database contains starter or incomplete card data");
      return n;
    } finally { await host.call("sqlClose", { db: path }).catch(() => {}); }
  }
  IOS.verifyDb = verifyDb;
  const isoNow = () => new Date().toISOString();
  async function commitDb(kind, file, meta) {
    const S = STORES[kind], old = await storeState(kind);
    async function slot(src, m) {
      const h = await host.call("sha256", { path: src });
      if (h.bytes > 536870912) throw fail("Database exceeds 512 MB");
      const name = "db-" + h.sha256 + ".db", dest = S.dir + "databases/" + name;
      if (!(await host.exists(dest))) {
        const stage = S.dir + "databases/stage-" + Date.now().toString(36);
        try { await host.call("copy", { path: src, to: stage }); await host.move(stage, dest); }
        catch (e) { await host.remove(stage).catch(() => {}); throw fail("Could not stage database"); }
      }
      return { file: name, meta: Object.assign({}, m, { sha256: h.sha256, bytes: h.bytes }) };
    }
    const active = await slot(file, meta);
    let previous = old ? old.active : null;
    if (!old) previous = await slot(await dbPath(kind), kind === "main" ? await bundledMeta() : SPARKING_META);
    const st = { version: 1, active };
    if (previous && previous.file !== active.file) st.previous = previous;
    try { await host.writeJson(S.dir + "database-state.json", st); } catch (e) { throw fail("Could not activate the database; previous data was kept"); }
    const keep = new Set([active.file, st.previous && st.previous.file]);
    for (const f of await host.list(S.dir + "databases")) {
      if (HEX_DB.test(f.name) && !keep.has(f.name)) { await host.call("sqlClose", { db: S.dir + "databases/" + f.name }).catch(() => {}); await host.remove(S.dir + "databases/" + f.name); }
    }
    DB[kind] = null;
    return st;
  }
  IOS.commitDb = commitDb; IOS.bundledMeta = bundledMeta;
  async function useDb(path, source, meta) {
    const count = await verifyDb(path, false);
    await commitDb("main", path, Object.assign({}, meta, { source, date: isoNow(), count }));
    await host.remove("animation-files.json").catch(() => {});
    return H.info();
  }
  IOS.useDb = useDb;
  const DB_URL = "https://dokkan-eclipse.com/cdn/uncompressed/sqlite/current/en/database_decrypted.db";
  const LIBRARY = "dokkan-files", SAVED_DB = "eclipse-database.db", SAVED_META = "eclipse-database.json";
  let libraryWarning = "";
  async function saveDatabaseCopy(path, meta) {
    const side = "cache/eclipse-library.json";
    try {
      const st = await host.call("gameFolderStatus", { game: LIBRARY });
      if (!st.linked || !st.ok) { libraryWarning = st.linked ? "Link Dokkan Files again to keep the database after reinstall." : ""; return; }
      const h = await host.call("sha256", { path });
      await host.writeJson(side, { version: 1, url: DB_URL, sha256: h.sha256, bytes: h.bytes, meta });
      for (const [file, name] of [[path, SAVED_DB], [side, SAVED_META]]) {
        const r = await host.call("gameFolderWrite", { game: LIBRARY, path: file, name });
        if (!r || !r.linked || !(r.written || r.same)) throw fail("Folder is unavailable");
      }
      libraryWarning = "";
    } catch (e) { libraryWarning = "Game data works, but couldn't save it in Dokkan Files. Link the folder again and retry."; }
    finally { await host.remove(side).catch(() => {}); }
  }
  H.dokkanFiles = async (a = {}) => {
    if (a.action === "link") {
      const r = await host.call("gameFolderLink", { game: LIBRARY });
      if (!r.linked) return r;
      const st = await storeState("main");
      if (st && st.active.meta.sourceType === "eclipse-current") {
        const probe = "cache/eclipse-library-probe.json";
        try {
          const saved = await host.call("gameFolderCopyIn", { game: LIBRARY, rel: SAVED_META, to: probe });
          // An existing folder may have newer data than this installation. Let sync check it first.
          if (saved.missing) await saveDatabaseCopy(await dbPath("main"), st.active.meta);
        } finally { await host.remove(probe).catch(() => {}); }
      }
    } else if (a.action === "unlink") {
      await host.call("gameFolderUnlink", { game: LIBRARY }); libraryWarning = "";
    }
    return Object.assign({}, await host.call("gameFolderStatus", { game: LIBRARY }), { warning: libraryWarning });
  };
  async function reuseDatabaseCopy(tmp) {
    const side = tmp + ".json";
    try {
      const r = await host.call("gameFolderCopyIn", { game: LIBRARY, rel: SAVED_META, to: side });
      if (!r.copied || r.bytes > 65536) return null;
      const s = await host.readJson(side);
      if (!s || s.version !== 1 || s.url !== DB_URL || !/^[a-f0-9]{64}$/.test(s.sha256) ||
          !Number.isSafeInteger(s.bytes) || s.bytes <= 0 || s.bytes > 536870912 || !s.meta || s.meta.sourceType !== "eclipse-current") return null;
      let offline = false;
      try {
        const h = await host.net(DB_URL, { method: "HEAD", headers: { "Accept-Encoding": "identity" } });
        const status = Number(h.headers.get("X-Forge-Status")) || h.status;
        const sameVersion = s.meta.etag && !s.meta.etag.startsWith("W/") ? h.headers.get("ETag") === s.meta.etag :
          s.meta.publishedAt && h.headers.get("Last-Modified") === s.meta.publishedAt;
        if (status !== 200 || !sameVersion || Number(h.headers.get("Content-Length")) !== s.bytes) return null;
      } catch (e) { offline = true; }
      // Without a server answer, never replace a different database already downloaded by this installation.
      const current = offline ? await storeState("main") : null;
      if (current && current.active.meta.sourceType === "eclipse-current" && current.active.meta.sha256 !== s.sha256) return null;
      IOS.progress("verify", "Checking Eclipse characters saved in Dokkan Files");
      const copy = await host.call("gameFolderCopyIn", { game: LIBRARY, rel: SAVED_DB, to: tmp });
      if (!copy.copied || copy.bytes !== s.bytes) return null;
      const hash = await host.call("sha256", { path: tmp });
      if (hash.bytes !== s.bytes || hash.sha256 !== s.sha256) return null;
      await verifyDb(tmp, true);
      await useDb(tmp, "Eclipse database from Dokkan Files", s.meta);
      return { reused: true, offline };
    } catch (e) { return null; }
    finally { await host.remove(side).catch(() => {}); }
  }
  async function downloadCurrentDatabase(meta) {
    const tmp = "cache/database-download-" + Date.now().toString(36) + ".tmp";
    try {
      const saved = await reuseDatabaseCopy(tmp);
      if (saved) return Object.assign(await H.info(), { databaseReuse: saved });
      IOS.progress("download", "Downloading Eclipse’s current full English database", 0, 0);
      await host.keepAwake(true);
      let r;
      try {
        r = await host.download(DB_URL, tmp, { headers: { "User-Agent": "DokkanUnitCreator/2.3", "Accept-Encoding": "identity" }, keepErrors: true, onProgress: (d) => IOS.progress("download", "Downloading Eclipse’s current full English database", d.bytes, d.total) });
      } catch (e) { throw fail(e.message && /canceled/i.test(e.message) ? e.message : "Couldn't reach Dokkan Eclipse. Check your internet connection."); }
      if (r.status !== 200) throw fail("Eclipse returned HTTP " + r.status + ". You can import a local database or resource pack instead.");
      if (!/^https:\/\/dokkan-eclipse\.com\//.test(r.finalUrl || DB_URL)) throw fail("Only official Eclipse resource routes are supported");
      if (r.bytes > 536870912) throw fail("Database download exceeds 512 MB");
      IOS.progress("verify", "Checking downloaded database", r.bytes, r.bytes);
      await verifyDb(tmp, true);
      const m = Object.assign({}, meta || {}, { sourceType: "eclipse-current", downloadUrl: DB_URL, downloadedBytes: r.bytes });
      if (r.lastModified) m.publishedAt = r.lastModified;
      if (r.etag) m.etag = r.etag;
      const info = await useDb(tmp, "Eclipse current full English database", m);
      await saveDatabaseCopy(tmp, m);
      return Object.assign(info, { dokkanFilesWarning: libraryWarning });
    } finally { await host.remove(tmp).catch(() => {}); host.keepAwake(false).catch(() => {}); }
  }
  IOS.downloadCurrentDatabase = downloadCurrentDatabase;
  H.sync = async function () {
    try {
      const info = await downloadCurrentDatabase({});
      const reused = info.databaseReuse;
      const label = reused ? (reused.offline ? "Saved Eclipse characters restored; check for updates when online" : "Eclipse characters restored from Dokkan Files") :
        (info.dokkanFilesWarning || "Game database updated");
      IOS.progress("done", label);
      return info;
    }
    catch (e) { IOS.progress("error", "Update failed; previous data was kept"); throw e; }
  };
  H.checkUpdates = async function () {
    try {
      const r = await host.net(DB_URL, { method: "HEAD" });
      const status = Number(r.headers.get("X-Forge-Status")) || r.status;
      const lm = Date.parse(r.headers.get("Last-Modified") || "");
      const len = Number(r.headers.get("Content-Length"));
      return { ok: status >= 200 && status < 300, status, lastModified: Number.isFinite(lm) ? lm : 0, size: Number.isFinite(len) && r.headers.get("Content-Length") ? len : -1 };
    } catch (e) { return { ok: false, error: "Couldn't reach Dokkan Eclipse. Check your internet connection." }; }
  };
  H.restoreDatabase = async function () {
    try {
      IOS.progress("restore", "Checking the previous database");
      const st = await storeState("main");
      if (!st || !st.previous) throw fail("No previous database is available");
      await verifyDb("databases/" + st.previous.file, false);
      await host.writeJson("database-state.json", { version: 1, active: st.previous, previous: st.active });
      DB.main = null;
      const info = await H.info();
      IOS.progress("done", "Previous database restored; saved units kept");
      return info;
    } catch (e) { IOS.progress("error", "Restore failed; the active database was kept"); throw e; }
  };
  const SPARKING_META = { source: "Sparking game database · built-in snapshot", sourceType: "sparking-bundled", date: "2026-10-17", latestVersion: 1791992148 };
  IOS.SPARKING_META = SPARKING_META;

  // ---------------------------------------------------------------- units: saved as files, like Android
  const KEY = /^[a-zA-Z0-9_-]{1,100}$/;
  const ISO_MS = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/;
  const projectFile = (key) => { if (typeof key !== "string" || !KEY.test(key)) throw fail("Invalid project key"); return "projects/" + key + ".json"; };
  const enc = new TextEncoder();
  async function sha256Hex(bytes) { const d = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)); return Array.from(d, (b) => b.toString(16).padStart(2, "0")).join(""); }
  IOS.sha256Hex = sha256Hex;
  const webProjects = { projects: H.projects, loadProject: H.loadProject, deleteProject: H.deleteProject };
  let migrated = null;
  function migrate() {   // units saved by the first iPhone build (browser storage) move to files once
    if (migrated) return migrated;
    migrated = (async () => {
      if (await host.exists("projects/.migrated")) return;
      try {
        for (const row of (await webProjects.projects()) || []) {
          try { const p = await webProjects.loadProject({ key: row.key }); if (p && KEY.test(p.key || "") && !(await host.exists(projectFile(p.key)))) await host.writeText(projectFile(p.key), JSON.stringify(p)); } catch (e) {}
        }
      } catch (e) {}
      await host.writeText("projects/.migrated", isoNow());
    })();
    return migrated;
  }
  const int = (v) => (typeof v === "number" ? Math.trunc(v) : parseInt(v, 10)) || 0;
  function summary(p) {
    const card = (p.tables && p.tables.cards && p.tables.cards[0]) || {}, o = p.cardOverrides || {};
    const forms = Array.isArray(p.formProjects) ? p.formProjects : [];
    if (forms.length > 4) throw fail("A unit supports up to four transformation forms.");
    return { key: p.key, name: o.name != null ? o.name : (card.name != null ? card.name : ""), targetId: int(p.targetId),
      reservedIds: [int(p.targetId)].concat(forms.map((f) => int(f.targetId))), updatedAt: p.updatedAt != null ? String(p.updatedAt) : "",
      rarity: int(o.rarity != null ? o.rarity : card.rarity), lvMax: int(o.lv_max != null ? o.lv_max : card.lv_max), element: int(o.element != null ? o.element : card.element),
      resourceId: int(o.resource_id != null ? o.resource_id : card.resource_id), origin: p.libraryOrigin || "created",
      sparkingAnimations: !!(p.sourceDependencies && Array.isArray(p.sourceDependencies.animations) && p.sourceDependencies.animations.length),
      sourceDatabase: (p.source && p.source.database) || "", author: (p.patch && p.patch.author) || "" };
  }
  H.projects = async function () {
    await migrate();
    const out = [];
    for (const f of await host.list("projects")) {
      if (f.dir || !/\.json$/.test(f.name) || f.size > 20971520) continue;
      try { out.push(summary(JSON.parse(await host.readText("projects/" + f.name)))); } catch (e) {}
    }
    return out;
  };
  H.loadProject = async function (a) {
    await migrate();
    const f = projectFile(a.key), t = await host.readText(f);
    if (t == null) throw fail("This unit is no longer saved on this device.");
    return JSON.parse(t);
  };
  function validTarget(v) { return typeof v === "number" && Number.isInteger(v) && v > 0 && v <= 2147483647; }
  function validateProject(p) {
    const bad = () => fail("Unsupported project");
    if (!p || typeof p !== "object" || p.format !== "dokkan-unit-forge" || p.version !== 1 || !validTarget(p.targetId)) throw bad();
    if (!p.tables || !Array.isArray(p.tables.cards) || p.tables.cards.length !== 1 || typeof p.tables.cards[0] !== "object") throw bad();
    if ("formProjects" in p) {
      if (!Array.isArray(p.formProjects) || p.formProjects.length > 4) throw bad();
      const seen = [p.targetId];
      for (const f of p.formProjects) {
        if (!f || typeof f !== "object" || f.format !== "dokkan-unit-forge" || "formProjects" in f || "transformLinks" in f || f.version !== 1 || !validTarget(f.targetId)) throw bad();
        if (!f.tables || !Array.isArray(f.tables.cards) || f.tables.cards.length !== 1) throw bad();
        if (seen.some((t) => Math.abs(t - f.targetId) < 1000)) throw bad();
        seen.push(f.targetId);
      }
    }
  }
  let writes = Promise.resolve();   // PROJECT_WRITES lock
  const locked = (fn) => { const r = writes.then(fn); writes = r.catch(() => {}); return r; };
  async function saveProjectNow(p) {
    validateProject(p);
    const file = projectFile(p.key);
    const stored = await host.readText(file);
    if (stored != null) {
      try { const s = JSON.parse(stored); if (ISO_MS.test(s.updatedAt || "") && ISO_MS.test(p.updatedAt || "") && s.updatedAt > p.updatedAt) return { saved: true, superseded: true }; } catch (e) {}
    }
    const bytes = enc.encode(JSON.stringify(p));
    if (bytes.length > 20971520) throw fail("Project exceeds 20 MiB.");
    await host.writeBytes(file, bytes);
    return { saved: true, revision: await sha256Hex(bytes) };
  }
  IOS.saveProjectNow = saveProjectNow;
  H.saveProject = (a) => locked(async () => { await migrate(); return saveProjectNow(a.project); });
  H.deleteProject = (a) => locked(async () => {
    const key = a.key;
    if (typeof key !== "string" || !KEY.test(key)) throw fail("Invalid project key");
    if (!(await host.exists("projects/" + key + ".json"))) throw fail("This unit is no longer saved on this device.");
    try { await host.remove("projects/" + key + ".json"); } catch (e) { throw fail("Could not delete this unit. Try again."); }
    await host.remove("project-versions/" + key).catch(() => {});
    try { await webProjects.deleteProject({ key }); } catch (e) {}
    return { deleted: true, key };
  });

  // saved versions (ProjectVersions): project-versions/<key>/index.json + <uuid>.version
  const UUID4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
  const uuid4 = () => (crypto.randomUUID ? crypto.randomUUID() : "10000000-1000-4000-8000-100000000000".replace(/[018]/g, (c) => (c ^ (crypto.getRandomValues(new Uint8Array(1))[0] & (15 >> (c / 4)))).toString(16)));
  IOS.uuid4 = uuid4;
  function versionsOf(key) {
    if (typeof key !== "string" || !KEY.test(key)) throw fail("Invalid project key.");
    const dir = "project-versions/" + key + "/";
    async function rows() {
      const t = (await host.exists(dir + "index.json")) ? await host.readText(dir + "index.json") : null;
      if (t == null) return [];
      let r; try { r = JSON.parse(t); } catch (e) { throw fail("Invalid saved version index."); }
      if (!Array.isArray(r) || r.length > 10) throw fail("Invalid saved version index.");
      const seen = new Set(); let total = 0;
      for (const x of r) {
        if (!x || !UUID4.test(x.versionKey || "") || seen.has(x.versionKey) || !(x.bytes >= 1 && x.bytes <= 20971520) || !(x.fileBytes >= x.bytes && x.fileBytes <= x.bytes + 65536) || String(x.label || "").length > 160 || !x.createdAt) throw fail("Invalid saved version index.");
        seen.add(x.versionKey); total += x.fileBytes;
      }
      if (total > 41943040) throw fail("Saved versions exceed their size limit.");
      return r;
    }
    async function current() {
      const t = await host.readBytes("projects/" + key + ".json");
      if (!t) throw fail("Project backup is invalid or too large.");
      if (t.length > 20971520) throw fail("Project exceeds 20 MiB.");
      let p; try { p = JSON.parse(new TextDecoder().decode(t)); } catch (e) { throw fail("Project backup is invalid or too large."); }
      if (p.format !== "dokkan-unit-forge" || p.key !== key) throw fail("Backup does not belong to this project.");
      return { bytes: t, project: p, revision: await sha256Hex(t) };
    }
    function check(args, cur, required) {
      if (required || args.expectedCurrentRevision != null) {
        if (!/^[a-f0-9]{64}$/.test(String(args.expectedCurrentRevision || "")) || args.expectedCurrentRevision !== cur.revision)
          throw fail("This project changed after the version list was opened. Close it and reopen Saved versions.");
      }
    }
    async function add(bytes, labelIn, revision) {
      if (labelIn == null) throw fail("Give this version a readable name.");
      const label = String(labelIn).trim();
      if (!label || [...label].length > 80 || /[\x00-\x1f\x7f]/.test(label)) throw fail("Use a readable version name of 1–80 characters.");
      const versionKey = uuid4(), createdAt = isoNow();
      const header = enc.encode(JSON.stringify({ versionKey, label, createdAt, bytes: bytes.length, key, revision }) + "\n");
      const file = new Uint8Array(header.length + bytes.length); file.set(header); file.set(bytes, header.length);
      await host.writeBytes(dir + versionKey + ".version", file);
      return { versionKey, label, createdAt, bytes: bytes.length, fileBytes: file.length };
    }
    async function commit(newRow, old) {
      const out = [newRow]; let total = newRow.fileBytes;
      for (const r of old) { if (out.length >= 10 || total + r.fileBytes > 41943040) break; out.push(r); total += r.fileBytes; }
      try { await host.writeJson(dir + "index.json", out); } catch (e) { await host.remove(dir + newRow.versionKey + ".version").catch(() => {}); throw fail("Could not commit saved project version."); }
      const keep = new Set(out.map((r) => r.versionKey + ".version"));
      for (const f of await host.list(dir)) if (/^[0-9a-f-]{36}\.version$/.test(f.name) && !keep.has(f.name)) await host.remove(dir + f.name).catch(() => {});
      return out;
    }
    async function read(versionKey) {
      if (!UUID4.test(String(versionKey || ""))) throw fail("Invalid backup key.");
      const r = (await rows()).find((x) => x.versionKey === versionKey);
      if (!r) throw fail("This saved version is no longer available.");
      const b = await host.readBytes(dir + versionKey + ".version");
      const nl = b ? b.indexOf(10) : -1;
      if (!b || nl < 1 || nl > 65535) throw fail("Invalid backup envelope.");
      let h; try { h = JSON.parse(new TextDecoder().decode(b.subarray(0, nl))); } catch (e) { throw fail("Invalid backup envelope."); }
      const body = b.subarray(nl + 1);
      if (h.key !== key || h.versionKey !== versionKey || h.revision !== (await sha256Hex(body))) throw fail("Backup checksum does not match.");
      return JSON.parse(new TextDecoder().decode(body));
    }
    const list = async () => ({ versions: (await rows()).map(({ versionKey, label, createdAt, bytes }) => ({ versionKey, label, createdAt, bytes })), currentRevision: (await current()).revision });
    return { rows, current, check, add, commit, read, list };
  }
  H.listProjectVersions = (a) => locked(() => versionsOf(a.key).list());
  H.saveProjectVersion = (a) => locked(async () => {
    const v = versionsOf(a.key), cur = await v.current(); v.check(a, cur, false);
    const row = await v.add(cur.bytes, a.label, cur.revision); await v.commit(row, await v.rows());
    return Object.assign(await v.list(), { saved: true, versionKey: row.versionKey, label: row.label, createdAt: row.createdAt, bytes: row.bytes });
  });
  H.loadProjectVersion = (a) => locked(() => versionsOf(a.key).read(a.versionKey));
  H.restoreProjectVersion = (a) => locked(async () => {
    const v = versionsOf(a.key), cur = await v.current(); v.check(a, cur, true);
    const restored = await v.read(a.versionKey);
    const oldRows = await v.rows();
    const row = await v.add(cur.bytes, "Before restoring an earlier version", cur.revision);
    await v.commit(row, oldRows);
    const prev = Date.parse(cur.project.updatedAt || "");
    restored.updatedAt = new Date(Math.max(Date.now(), Number.isFinite(prev) ? prev + 1 : 0)).toISOString();
    try { await host.writeBytes(projectFile(a.key), enc.encode(JSON.stringify(restored))); }
    catch (e) { await host.writeJson("project-versions/" + a.key + "/index.json", oldRows).catch(() => {}); throw e; }
    return Object.assign(await v.list(), { saved: true, project: restored });
  });

  // ---------------------------------------------------------------- small things
  H.wipeData = async function (a) {
    if (a.confirm !== "DELETE") throw fail("Not confirmed.");
    const out = {};
    if (a.units) { await host.remove("projects"); await host.remove("project-versions"); await host.mkdir("projects"); await host.writeText("projects/.migrated", isoNow()); out.units = true; }
    if (a.files) { for (const d of ["assets", "lwf", "patches", "animation-sources"]) await host.remove(d); await host.mkdir("assets"); await host.mkdir("patches"); out.files = true; }
    if (a.downloads) { await host.remove("preview-cache"); await host.remove("movie-cache"); await host.remove("cache/mirror"); if (IOS.previewCache) await IOS.previewCache.settings().catch(() => {}); out.downloads = true; }
    if (a.ai) { const s = await aiStore(); for (const p of PROVIDERS) await host.secretDelete("ai." + p); void s; await host.remove(AI_FILE); out.ai = true; }
    if (a.settings) { try { localStorage.clear(); } catch (e) {} out.settings = true; }
    out.ok = true;
    return out;
  };
  H.copy = async (a) => { await host.call("copyText", { text: String(a.text == null ? "" : a.text) }); return { copied: true }; };
  const LINKS = { converter: "https://dokkan-eclipse.com/#convert-eclp", documentation: "https://dokkan-eclipse.com/wiki/documentation", downloads: "https://dokkan-eclipse.com/downloads", files: "https://dokkan-eclipse.com/files", sparkingLicense: "https://creativecommons.org/licenses/by-sa/4.0/" };
  H.external = async function (a) {
    if (a.target == null) throw fail("No value for target");
    let url = LINKS[a.target];
    if (a.target === "sparkingWiki") { if (!/^[1-9][0-9]{0,14}$/.test(String(a.revision))) throw fail("Invalid wiki revision"); url = "https://dokkansparking.miraheze.org/w/index.php?oldid=" + a.revision; }
    if (!url) throw fail("Unknown destination");
    await host.openURL(url);
    return { opened: true };
  };
  H.openEclipse = async () => { await host.openURL("https://dokkan-eclipse.com/downloads"); return { requested: true, installed: false }; };
  H.openStore = async () => ({ opened: false });
  H.renderMode = async () => ({ mode: "gpu", auto: false });
  H.textZoom = async (a) => {
    const n = Math.max(80, Math.min(200, Number(a.percent) || 100));
    try { localStorage.setItem("ios-text-zoom", String(n)); } catch (e) {}
    document.documentElement.style.webkitTextSizeAdjust = n + "%";
    return { percent: n };
  };
  try { const z = Number(localStorage.getItem("ios-text-zoom")); if (z) document.documentElement.style.webkitTextSizeAdjust = z + "%"; } catch (e) {}
  delete H.patchesStatus;
})();
