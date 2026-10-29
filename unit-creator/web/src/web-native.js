/* Web version of the Android bridge (Native.call). Loaded before the app's own scripts.
 * - Game data: compressed table files (data/db/*.json.gz) read on demand, queried exactly like
 *   the Android app's SQLite queries (filters, id lists, name search, order, limit, offset).
 * - Units and imported files: stored in this browser (IndexedDB), on this device only.
 * - .eclp export: built in the browser (eclp.js + argon2-worker.js), then saved or shared.
 * Things only the Android app can do (animation previews, offline packs, APK imports) answer with
 * a clear message instead of failing silently. */
(function () {
  "use strict";
  const BASE = new URL(".", document.currentScript ? document.currentScript.src : location.href).href.replace(/web\/$/, "");
  const ANDROID_ONLY = "This needs the Android app for now. In the web version you can find characters, build and edit units, save them and export .eclp files.";
  const err = (message) => Object.assign(new Error(message), { webOnly: true });

  // ---------------------------------------------------------------- IndexedDB
  let dbp = null;
  function idb() {
    if (dbp) return dbp;
    dbp = new Promise((resolve, reject) => {
      const open = indexedDB.open("dokkan-unit-creator", 1);
      open.onupgradeneeded = () => { const d = open.result; for (const s of ["projects", "patches", "kv"]) if (!d.objectStoreNames.contains(s)) d.createObjectStore(s); };
      open.onsuccess = () => resolve(open.result);
      open.onerror = () => reject(open.error || new Error("This browser can't save data (private browsing?)."));
    });
    return dbp;
  }
  async function tx(store, mode, fn) {
    const d = await idb();
    return new Promise((resolve, reject) => {
      const t = d.transaction(store, mode), s = t.objectStore(store);
      let result;
      Promise.resolve(fn(s)).then((r) => { result = r; });
      t.oncomplete = () => resolve(result && typeof result === "object" && "result" in result && result instanceof IDBRequest ? result.result : result);
      t.onerror = () => reject(t.error);
      t.onabort = () => reject(t.error || new Error("Saving was interrupted."));
    });
  }
  const req = (r) => new Promise((resolve, reject) => { r.onsuccess = () => resolve(r.result); r.onerror = () => reject(r.error); });
  async function getAll(store) { const d = await idb(); return req(d.transaction(store).objectStore(store).getAll()); }
  async function get(store, key) { const d = await idb(); return req(d.transaction(store).objectStore(store).get(key)); }
  async function put(store, key, value) { const d = await idb(); const t = d.transaction(store, "readwrite"); t.objectStore(store).put(value, key); return new Promise((res, rej) => { t.oncomplete = () => res(true); t.onerror = () => rej(t.error); t.onabort = () => rej(t.error); }); }
  async function del(store, key) { const d = await idb(); const t = d.transaction(store, "readwrite"); t.objectStore(store).delete(key); return new Promise((res, rej) => { t.oncomplete = () => res(true); t.onerror = () => rej(t.error); }); }
  // Ask Safari to keep the data (it may otherwise clear site data after weeks without a visit).
  try { navigator.storage && navigator.storage.persist && navigator.storage.persist(); } catch (e) {}

  // ---------------------------------------------------------------- Claude-hosted version
  // When this runs as a Claude artifact, units are kept in Claude's private per-person storage
  // (they can't be wiped by the browser and follow you between devices). The browser copy stays
  // as a fast local cache and as the fallback when that storage isn't available.
  const HOSTED = !!window.__forgeArtifact;
  const host = (name) => (HOSTED && window.claude && typeof window.claude.use === "function") ? window.claude.use(name).catch(() => null) : Promise.resolve(null);
  let cloudp = null;
  function cloud() {
    if (cloudp) return cloudp;
    cloudp = (async () => {
      const [db, user] = await Promise.all([host("db"), host("user")]);
      if (!db || !user) return null;
      let uid = null;
      try { uid = await user.id(); } catch (e) {}
      if (!uid) return null;
      return { db, col: db.collection("data/users/" + uid) };
    })();
    return cloudp;
  }
  const CHUNK = 180000;
  async function packText(text) {
    const gz = await new Response(new Blob([text]).stream().pipeThrough(new CompressionStream("gzip"))).arrayBuffer();
    const b = new Uint8Array(gz); let bin = "";
    for (let i = 0; i < b.length; i += 32768) bin += String.fromCharCode.apply(null, b.subarray(i, i + 32768));
    return btoa(bin);
  }
  async function unpackText(b64) {
    const bin = atob(b64), b = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) b[i] = bin.charCodeAt(i);
    return new Response(new Blob([b]).stream().pipeThrough(new DecompressionStream("gzip"))).text();
  }
  const writing = new Map();   // one write at a time per unit; only the newest waiting save is kept
  function cloudSave(project) {
    const key = project.key, entry = writing.get(key) || { busy: null, next: null };
    writing.set(key, entry);
    entry.next = project;
    if (!entry.busy) entry.busy = (async () => {
      try {
        while (entry.next) {
          const p = entry.next; entry.next = null;
          const c = await cloud(); if (!c) return;
          let info; try { info = summary(p); } catch (e) { info = { key: p.key, name: "" }; }
          const z = await packText(JSON.stringify(p)), parts = Math.ceil(z.length / CHUNK) || 1;
          for (let i = 1; i < parts; i++) await c.col.doc("p-" + key + "~" + i).set({ kind: "chunk", z: z.slice(i * CHUNK, (i + 1) * CHUNK) });
          await c.col.doc("p-" + key).set({ kind: "project", key, summary: info, updatedAt: p.updatedAt || new Date().toISOString(), parts, z: z.slice(0, CHUNK) });
        }
      } catch (e) {
        console.warn("cloud save", e && (e.code || e.message));
        if (e && e.code === "quota_exceeded" && window.toast) toast("Claude's storage for this app is full. Delete units you don't need, or save .json backups.", true);
      } finally { entry.busy = null; if (!entry.next) writing.delete(key); }
    })();
    return entry.busy;
  }
  async function cloudLoad(key) {
    const c = await cloud(); if (!c) return null;
    const head = await c.col.doc("p-" + key).get();
    if (!head.exists) return null;
    const h = head.data(); let z = h.z;
    for (let i = 1; i < (h.parts || 1); i++) { const part = await c.col.doc("p-" + key + "~" + i).get(); if (!part.exists) throw new Error("Part of this unit is missing from storage."); z += part.data().z; }
    return JSON.parse(await unpackText(z));
  }
  async function cloudList() {
    const c = await cloud(); if (!c) return null;
    const snap = await c.col.where("kind", "==", "project").limit(1000).get();
    return snap.docs.map((d) => d.data());
  }
  async function cloudDelete(key) {
    const c = await cloud(); if (!c) return;
    const head = await c.col.doc("p-" + key).get();
    const parts = head.exists ? (head.data().parts || 1) : 1;
    await c.col.doc("p-" + key).delete();
    for (let i = 1; i < parts; i++) await c.col.doc("p-" + key + "~" + i).delete();
  }
  // Saving files: hosted pages hand files over through Claude ("downloads"); .eclp isn't on its
  // list of file types, so it is wrapped in a .zip (tap it once in the Files app to get the .eclp).
  const CRC = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
  function crc32(b) { let c = 0xffffffff; for (let i = 0; i < b.length; i++) c = CRC[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
  function zipOne(name, bytes) {
    const n = new TextEncoder().encode(name), crc = crc32(bytes), d = new Date();
    const time = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1), date = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
    const local = new DataView(new ArrayBuffer(30)), central = new DataView(new ArrayBuffer(46)), end = new DataView(new ArrayBuffer(22));
    [[0, 0x04034b50, 4], [4, 20, 2], [6, 0x0800, 2], [8, 0, 2], [10, time, 2], [12, date, 2], [14, crc, 4], [18, bytes.length, 4], [22, bytes.length, 4], [26, n.length, 2], [28, 0, 2]].forEach(([o, v, z]) => z === 4 ? local.setUint32(o, v, true) : local.setUint16(o, v, true));
    [[0, 0x02014b50, 4], [4, 20, 2], [6, 20, 2], [8, 0x0800, 2], [10, 0, 2], [12, time, 2], [14, date, 2], [16, crc, 4], [20, bytes.length, 4], [24, bytes.length, 4], [28, n.length, 2], [30, 0, 2], [32, 0, 2], [34, 0, 2], [36, 0, 2], [38, 0, 4], [42, 0, 4]].forEach(([o, v, z]) => z === 4 ? central.setUint32(o, v, true) : central.setUint16(o, v, true));
    const cdOffset = 30 + n.length + bytes.length;
    [[0, 0x06054b50, 4], [4, 0, 2], [6, 0, 2], [8, 1, 2], [10, 1, 2], [12, 46 + n.length, 4], [16, cdOffset, 4], [20, 0, 2]].forEach(([o, v, z]) => z === 4 ? end.setUint32(o, v, true) : end.setUint16(o, v, true));
    return new Blob([local, n, bytes, central, n, end], { type: "application/zip" });
  }
  window.__forgeZipOne = zipOne;

  // ---------------------------------------------------------------- game data
  let manifest = null;
  const tables = new Map(), loading = new Map(), parts = new Map();
  async function gunzipJson(url) {
    // The Claude-hosted copy stores each data file as base64 text (".b64.txt"), the only way it serves binary.
    const res = await fetch(HOSTED ? url + ".b64.txt" : url, { cache: "force-cache" });
    if (!res.ok) throw new Error("Couldn't load game data (" + res.status + "). Check your connection and reload.");
    if (typeof DecompressionStream === "undefined") throw new Error("This browser is too old for the web version. Update iOS (Safari 16.4 or newer).");
    let body = res.body;
    if (HOSTED) {
      const bin = atob((await res.text()).trim()), bytes = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      body = new Blob([bytes]).stream();
    }
    const text = await new Response(body.pipeThrough(new DecompressionStream("gzip"))).text();
    return JSON.parse(text);
  }
  async function getManifest() {
    if (!manifest) manifest = await gunzipJson(BASE + "data/db/manifest.json.gz");
    return manifest;
  }
  async function table(name) {
    if (tables.has(name)) return tables.get(name);
    if (loading.has(name)) return loading.get(name);
    const p = (async () => {
      const m = await getManifest();
      if (!m.schema[name]) throw new Error("Table is not in this database.");
      // tables come packed in a few bigger files; each file is downloaded once and shared
      const file = m.files[name];
      if (!parts.has(file)) parts.set(file, gunzipJson(BASE + "data/db/" + file).catch((e) => { parts.delete(file); throw e; }));
      const data = m.bundled ? (await parts.get(file))[name] : await parts.get(file);
      const col = new Map(data.c.map((c, i) => [c, i]));
      const t = { name, cols: data.c, col, rows: data.r, eq: new Map(), sorted: new Map() };
      tables.set(name, t);
      return t;
    })();
    loading.set(name, p);
    try { return await p; } finally { loading.delete(name); }
  }
  // SQLite ordering: NULL < numbers < text
  function cmp(a, b) {
    if (a === b) return 0;
    if (a === null || a === undefined) return -1;
    if (b === null || b === undefined) return 1;
    const na = typeof a === "number", nb = typeof b === "number";
    if (na && nb) return a - b;
    if (na) return -1;
    if (nb) return 1;
    return a < b ? -1 : a > b ? 1 : 0;
  }
  function sortedIndex(t, column) {
    if (t.sorted.has(column)) return t.sorted.get(column);
    const c = t.col.get(column), idx = t.rows.map((_, i) => i);
    idx.sort((x, y) => cmp(t.rows[x][c], t.rows[y][c]) || x - y);
    t.sorted.set(column, idx);
    return idx;
  }
  const key = (v) => (v === null || v === undefined ? "\u0000null" : typeof v === "number" ? "n" + v : /^-?\d+(\.\d+)?$/.test(String(v)) ? "n" + Number(v) : "s" + String(v));
  function eqIndex(t, column) {
    if (t.eq.has(column)) return t.eq.get(column);
    const c = t.col.get(column), map = new Map();
    t.rows.forEach((r, i) => { const k = key(r[c]); let list = map.get(k); if (!list) map.set(k, (list = [])); list.push(i); });
    t.eq.set(column, map);
    return map;
  }
  /** Same rules as the Android app's query (CreatorActivity.query). */
  async function query(a) {
    const t = await table(String(a.table || ""));
    let candidates = null; // row indexes, or null = all
    const intersect = (list) => { if (!candidates) { candidates = new Set(list); return; } const next = new Set(); for (const i of list) if (candidates.has(i)) next.add(i); candidates = next; };
    for (const [k, v] of Object.entries(a.filters || {})) {
      if (!t.col.has(k)) throw new Error("Unknown column");
      intersect(eqIndex(t, k).get(key(v)) || []);
    }
    if (Array.isArray(a.ids)) {
      if (!a.ids.length) return [];
      if (a.ids.length > 1000) throw new Error("Too many row IDs");
      const ids = eqIndex(t, "id"), list = [];
      for (const id of a.ids) for (const i of ids.get(key(Number(id))) || []) list.push(i);
      intersect(list);
    }
    let search = null;
    if (a.search && a.search.text) {
      if (!t.col.has(a.search.column)) throw new Error("Unknown search column");
      search = { c: t.col.get(a.search.column), text: String(a.search.text).slice(0, 200).toLowerCase() };
    }
    const order = a.order || "id";
    if (!t.col.has(order)) throw new Error("Unknown sort column");
    const limit = Math.max(1, Math.min(5000, Number(a.limit) || 100)), offset = Math.max(0, Number(a.offset) || 0);
    const out = [];
    let skipped = 0;
    for (const i of sortedIndex(t, order)) {
      if (candidates && !candidates.has(i)) continue;
      const row = t.rows[i];
      if (search) { const v = row[search.c]; if (v === null || v === undefined || !String(v).toLowerCase().includes(search.text)) continue; }
      if (skipped < offset) { skipped++; continue; }
      const o = {};
      for (let c = 0; c < t.cols.length; c++) o[t.cols[c]] = row[c];
      out.push(o);
      if (out.length >= limit) break;
    }
    return out;
  }
  async function cardIndex() {
    const t = await table("cards"), c = (n) => t.col.get(n), out = [];
    const id = c("id"), name = c("name"), hp = c("hp_max"), pas = c("passive_skill_set_id"), lead = c("leader_skill_set_id");
    for (const r of t.rows) {
      const v = Number(r[id]);
      if (v % 10 !== 1 || !((v >= 1e6 && v < 3e6) || v >= 1e7) || !(Number(r[hp]) > 300) || r[pas] == null || r[lead] == null) continue;
      const open = String(r[c("open_at")] || "").slice(0, 10).replace(/-/g, "");
      out.push([v, r[name] || "", Number(r[c("rarity")]) || 0, Number(r[c("element")]) || 0, /^\d{8}$/.test(open) ? Number(open) : 0, Number(r[hp]) || 0, Number(r[c("atk_max")]) || 0, Number(r[c("def_max")]) || 0, Number(r[c("resource_id")]) || 0, Number(r[pas]), Number(r[lead]), c("optimal_awakening_grow_type") === undefined || r[c("optimal_awakening_grow_type")] == null ? null : Number(r[c("optimal_awakening_grow_type")])]);
    }
    return out;
  }

  // ---------------------------------------------------------------- units
  function summary(p) {
    const c = p.tables.cards[0], o = p.cardOverrides || {}, g = (k, d) => (k in o ? o[k] : c[k] !== undefined ? c[k] : d);
    const reserved = [Number(p.targetId)];
    for (const f of p.formProjects || []) reserved.push(Number(f.targetId));
    return { key: p.key, name: g("name", ""), lvMax: Number(g("lv_max", 0)) || 0, targetId: p.targetId, reservedIds: reserved, updatedAt: p.updatedAt || "", rarity: g("rarity", 0), element: g("element", 0), resourceId: g("resource_id", 0), origin: p.libraryOrigin || "created", sparkingAnimations: !!(p.sourceDependencies && p.sourceDependencies.animations && p.sourceDependencies.animations.length), sourceDatabase: (p.source && p.source.database) || "", author: (p.patch && p.patch.author) || "" };
  }
  async function revision(text) {
    const d = new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text)));
    return Array.from(d, (b) => b.toString(16).padStart(2, "0")).join("");
  }

  // ---------------------------------------------------------------- files: choose, save, share
  function chooseFile(accept) {
    // A visible button inside a small window: iPhones only open the file picker from a direct tap.
    return new Promise((resolve) => {
      const d = document.createElement("dialog");
      d.className = "web-file-dialog";
      d.innerHTML = '<h2>Import a file</h2><p>Choose a unit file from this app (.json), a .sql file, or an .eclp made by this web version.</p><label class="button web-file-button">📁 Choose a file<input type="file" accept="' + accept + '" hidden></label><button type="button" class="button ghost">Cancel</button>';
      document.body.append(d);
      const input = d.querySelector("input");
      const done = (file) => { d.close(); d.remove(); resolve(file || null); };
      input.onchange = () => done(input.files && input.files[0]);
      d.querySelector(".ghost").onclick = () => done(null);
      d.addEventListener("cancel", () => done(null));
      d.showModal();
    });
  }
  // Inside the iPhone app (.ipa): the app shows the iPhone's own Save / Share sheet.
  const IOS_APP = () => !!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ForgeFiles);
  async function saveNative(name, blob) {
    const bytes = new Uint8Array(await blob.arrayBuffer());
    let bin = ""; for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
    const id = "f" + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
    return new Promise((resolve) => {
      const done = (e) => { if (!e.detail || e.detail.id !== id) return; removeEventListener("forge-file-saved", done); resolve({ saved: !!e.detail.saved, name }); };
      addEventListener("forge-file-saved", done);
      window.webkit.messageHandlers.ForgeFiles.postMessage({ id, name, base64: btoa(bin) });
    });
  }
  function saveFile(name, blob) {
    if (IOS_APP()) return saveNative(name, blob);
    if (HOSTED) return saveHosted(name, blob);
    // Shown as a button so Safari treats it as your tap (needed for Share / Download on iPhone).
    return new Promise((resolve) => {
      const d = document.createElement("dialog");
      d.className = "web-file-dialog";
      const canShare = !!(navigator.canShare && navigator.canShare({ files: [new File([blob], name, { type: blob.type || "application/octet-stream" })] }));
      d.innerHTML = '<h2>Your file is ready</h2><p><strong></strong><br><small>' + Math.max(1, Math.round(blob.size / 1024)) + ' KB</small></p>' +
        (canShare ? '<button type="button" class="button" data-act="share">📤 Save or send (Files, AirDrop…)</button>' : "") +
        '<button type="button" class="button' + (canShare ? " ghost" : "") + '" data-act="download">⬇ Download</button><button type="button" class="button ghost" data-act="close">Close</button>';
      d.querySelector("strong").textContent = name;
      document.body.append(d);
      const close = (saved) => { d.close(); d.remove(); resolve({ saved, name }); };
      d.querySelectorAll("[data-act]").forEach((b) => b.onclick = async () => {
        const act = b.dataset.act;
        if (act === "close") return close(false);
        if (act === "share") {
          try { await navigator.share({ files: [new File([blob], name, { type: blob.type || "application/octet-stream" })], title: name }); return close(true); }
          catch (e) { if (e && e.name === "AbortError") return; }
        }
        const url = URL.createObjectURL(blob), a = document.createElement("a");
        a.href = url; a.download = name; document.body.append(a); a.click(); a.remove();
        setTimeout(() => URL.revokeObjectURL(url), 60000);
        close(true);
      });
      d.addEventListener("cancel", () => close(false));
      d.showModal();
    });
  }
  async function saveHosted(name, blob) {
    const eclp = /\.eclp$/i.test(name);
    const fileName = eclp ? name + ".zip" : name;
    const data = eclp ? zipOne(name, new Uint8Array(await blob.arrayBuffer())) : blob;
    const downloads = await host("downloads");
    return new Promise((resolve) => {
      const d = document.createElement("dialog");
      d.className = "web-file-dialog";
      d.innerHTML = '<h2>Your file is ready</h2><p><strong></strong><br><small>' + Math.max(1, Math.round(data.size / 1024)) + ' KB</small></p>' +
        (eclp ? '<p class="web-file-tip">It comes in a <b>.zip</b>. In the <b>Files</b> app, tap the zip once and your <b>.eclp</b> file appears next to it.</p>' : "") +
        '<p class="web-file-status" role="status" hidden></p>' +
        '<button type="button" class="button" data-act="save">⬇ Save file</button><button type="button" class="button ghost" data-act="close">Close</button>';
      d.querySelector("strong").textContent = name;
      document.body.append(d);
      const status = d.querySelector(".web-file-status"), saveBtn = d.querySelector('[data-act="save"]');
      const say = (text) => { status.hidden = false; status.textContent = text; };
      const close = (saved) => { d.close(); d.remove(); resolve({ saved, name: fileName }); };
      if (!downloads) { saveBtn.hidden = true; say("Saving files isn't available in this view. Open this page in the Claude app or at claude.ai and try again."); }
      saveBtn.onclick = async () => {
        saveBtn.disabled = true;
        try { await downloads.save({ filename: fileName, data }); close(true); }
        catch (e) {
          saveBtn.disabled = false;
          const code = e && e.code;
          if (code === "declined") say("Not saved. Tap Save file to try again.");
          else if (code === "rate_limited") say("A save is already waiting for you. Finish that one first, then try again.");
          else if (code === "too_large") say("This file is too big to save here.");
          else { saveBtn.hidden = true; say("Saving files isn't available here (" + (code || "unavailable") + "). Open this page in the Claude app or at claude.ai."); }
        }
      };
      d.querySelector('[data-act="close"]').onclick = () => close(false);
      d.addEventListener("cancel", () => close(false));
      d.showModal();
    });
  }
  // Argon2 in a worker (about 2–5 seconds), with a message while it works.
  function deriveInWorker(pw, salt) {
    return new Promise((resolve, reject) => {
      let w;
      try { w = new Worker(BASE + "web/argon2-worker.js"); } catch (e) { resolve(self.ForgeArgon2.argon2id(pw, salt, { iterations: 3, memoryKiB: 65536, parallelism: 4, tagLength: 32 })); return; }
      const busyText = document.querySelector("#busy p");
      w.onmessage = (e) => {
        if (e.data.progress != null) { if (busyText) busyText.textContent = "Locking the file the way Eclipse expects… " + Math.round(e.data.progress * 100) + "%"; return; }
        w.terminate();
        e.data.error ? reject(new Error(e.data.error)) : resolve(new Uint8Array(e.data.key));
      };
      w.onerror = (e) => { w.terminate(); reject(new Error(e.message || "Couldn't prepare the file.")); };
      w.postMessage({ pw, salt });
    });
  }

  function openLink(url) { const a = document.createElement("a"); a.href = url; a.target = "_blank"; a.rel = "noopener"; document.body.append(a); a.click(); a.remove(); }
  // ---------------------------------------------------------------- the bridge
  // ---------------------------------------------------------------- game animations list (same rows as the apps' catalog)
  const catalogCache = new Map();
  async function objects(name) {
    try { const t = await table(name); return t.rows.map((r) => { const o = {}; t.cols.forEach((c, i) => { o[c] = r[i]; }); return o; }); } catch (e) { return []; }
  }
  const okScript = (s) => s != null && !["", "0", "none"].includes(String(s));
  async function catalogRows(kind) {
    if (catalogCache.has(kind)) return catalogCache.get(kind);
    const p = (async () => {
      const cards = new Map((await objects("cards")).map((c) => [c.id, c])), out = [];
      const card = (id) => cards.get(id);
      const add = (key, k, viewId, script, c, moveName, sourceTable, fallbackUnit) => out.push({ key, kind: k, viewId, script, unitId: c ? c.id : 0, unitName: c ? c.name : fallbackUnit, moveName, description: "", resourceId: c ? (c.resource_id || c.id) : 0, rarity: c ? c.rarity : 0, sourceTable });
      if (["super", "ultra", "ex", "fullpower", "ultimate", "transform"].includes(kind)) {
        const views = new Map((await objects("special_views")).map((v) => [v.id, v])), sets = new Map((await objects("special_sets")).map((s) => [s.id, s]));
        for (const cs of await objects("card_specials")) {
          const v = views.get(cs.view_id); if (!v || !okScript(v.script_name)) continue;
          const sn = String(v.script_name), k = /^tf/.test(sn) ? "transform" : /^ut/.test(sn) ? "ultimate" : cs.style === "Hyper" ? "ultra" : cs.style === "Extra" ? "ex" : cs.style === "FullPower" ? "fullpower" : "super";
          if (k !== kind) continue;
          const c = card(cs.card_id), st = sets.get(cs.special_set_id);
          add("view:" + v.id + ":" + (c ? c.id : 0), k, v.id, sn, c, st ? st.name : "Shared battle animation", "special_views", "Shared or enemy sequence");
        }
        // animations no card uses directly (shared, enemy and form-change scenes)
        const used = new Set((await objects("card_specials")).map((cs) => cs.view_id));
        for (const v of views.values()) {
          if (used.has(v.id) || !okScript(v.script_name)) continue;
          const sn = String(v.script_name), k = /^tf/.test(sn) ? "transform" : /^ut/.test(sn) ? "ultimate" : "super";
          if (k === kind) add("view:" + v.id + ":0", k, v.id, sn, null, "Shared battle animation", "special_views", "Shared or enemy sequence");
        }
      } else if (["active", "standby", "finish"].includes(kind)) {
        const T = { active: ["active_skill_sets", "card_active_skills", "active_skill_set_id"], standby: ["standby_skill_sets", "card_standby_skill_set_relations", "standby_skill_set_id"], finish: ["finish_skill_sets", "card_finish_skill_set_relations", "finish_skill_set_id"] }[kind];
        const views = new Map((await objects("special_views")).map((v) => [v.id, v])), sets = new Map((await objects(T[0])).map((s) => [s.id, s]));
        for (const r of await objects(T[1])) {
          const st = sets.get(r[T[2]]), c = card(r.card_id), v = st && views.get(st.special_view_id);
          if (!st || !c || !v || !okScript(v.script_name)) continue;
          add(kind + ":" + st.id + ":" + c.id, kind, v.id, v.script_name, c, st.name, "special_views");
        }
      }
      if (["transform", "giant"].includes(kind)) {
        // form changes: the passive's battle_params (idx 11 = transformation view, 12 = giant form view)
        const idx = kind === "transform" ? 11 : 12, eff = kind === "transform" ? 103 : 79;
        const viewTable = new Map((await objects(kind === "transform" ? "transformation_views" : "metamorphic_views")).map((v) => [v.id, v]));
        const params = new Map(); for (const b of await objects("battle_params")) if (Number(b.idx) === idx) params.set(b.param_no, b.value);
        const ps = await objects("passive_skills"), rel = await objects("passive_skill_set_relations"), bySet = new Map();
        for (const c of cards.values()) { if (!bySet.has(c.passive_skill_set_id)) bySet.set(c.passive_skill_set_id, []); bySet.get(c.passive_skill_set_id).push(c); }
        const setsOf = new Map(); for (const r of rel) { if (!setsOf.has(r.passive_skill_id)) setsOf.set(r.passive_skill_id, []); setsOf.get(r.passive_skill_id).push(r.passive_skill_set_id); }
        const parts = kind === "transform" ? [["begin", "transformation-begin"], ["end", "transformation-end"]] : [["begin", "giant-begin"], ["continue", "giant-continue"], ["end", "giant-end"]];
        for (const p of ps) {
          if (Number(p.efficacy_type) !== eff) continue;
          const v = viewTable.get(params.get(p.eff_value3)); if (!v) continue;
          for (const [part, prefix] of parts) {
            const sn = v[part + "_script_name"]; if (!okScript(sn)) continue;
            for (const sid of setsOf.get(p.id) || []) for (const c of bySet.get(sid) || []) add(prefix + ":" + p.id + ":" + c.id, kind, v.id, sn, c, p.name || "Transformation", kind === "transform" ? "transformation_views" : "metamorphic_views");
          }
        }
      } else if (["counter", "revival", "intro", "nullify"].includes(kind)) {
        const ps = await objects("passive_skills"), rel = await objects("passive_skill_set_relations"), bySet = new Map();
        for (const c of cards.values()) { if (!bySet.has(c.passive_skill_set_id)) bySet.set(c.passive_skill_set_id, []); bySet.get(c.passive_skill_set_id).push(c); }
        const setsOf = new Map(); for (const r of rel) { if (!setsOf.has(r.passive_skill_id)) setsOf.set(r.passive_skill_id, []); setsOf.get(r.passive_skill_id).push(r.passive_skill_set_id); }
        const views = kind === "revival" ? new Map((await objects("revival_views")).map((v) => [v.id, v])) : kind === "intro" ? new Map((await objects("passive_skill_effects")).map((v) => [v.id, v])) : null;
        for (const p of ps) {
          let viewId = 0, script = "", src = "passive_skills";
          if (kind === "counter") { if (![120, 128].includes(Number(p.efficacy_type)) || !(p.eff_value3 > 0)) continue; script = "c" + String(p.eff_value3).padStart(4, "0"); }
          else if (kind === "nullify") { if (![97, 119].includes(Number(p.efficacy_type)) || !(p.eff_value3 > 0)) continue; script = "as" + String(p.eff_value3).padStart(4, "0"); }
          else if (kind === "revival") { if (Number(p.efficacy_type) !== 109) continue; const v = views.get(p.eff_value2); if (!v || !v.script_name) continue; viewId = v.id; script = v.script_name; src = "revival_views"; }
          else { const v = p.passive_skill_effect_id && views.get(p.passive_skill_effect_id); if (!v || !v.script_name) continue; viewId = v.id; script = v.script_name; src = "passive_skill_effects"; }
          for (const sid of setsOf.get(p.id) || []) for (const c of bySet.get(sid) || []) add((kind === "intro" ? "intro:" + viewId : kind + ":" + p.id) + ":" + c.id, kind, viewId, script, c, p.name || "Animation", src);
        }
      }
      const seen = new Set();
      const list = out.filter((r) => { const k = r.key; if (seen.has(k)) return false; seen.add(k); return true; });
      list.sort((a, b) => (a.unitId === 0) - (b.unitId === 0) || String(a.unitName).localeCompare(String(b.unitName)) || String(a.moveName).localeCompare(String(b.moveName)) || a.unitId - b.unitId);
      return list;
    })();
    catalogCache.set(kind, p);
    return p;
  }
  const handlers = {
    async animationCatalog(a) {
      const kind = String(a.kind || "super"), q = String(a.search || "").toLowerCase().slice(0, 100);
      const ALL = ["super", "ultra", "ex", "fullpower", "ultimate", "transform", "active", "standby", "finish", "counter", "revival", "intro", "giant", "nullify"];
      if (kind === "all" && !catalogCache.has("all")) catalogCache.set("all", Promise.all(ALL.map(catalogRows)).then((ls) => ls.flat().sort((a, b) => (a.unitId === 0) - (b.unitId === 0) || String(a.unitName).localeCompare(String(b.unitName)) || String(a.moveName).localeCompare(String(b.moveName)))));
      let list = await (kind === "all" ? catalogCache.get("all") : catalogRows(kind));
      if (q) list = list.filter((r) => String(r.unitName).toLowerCase().includes(q) || String(r.moveName).toLowerCase().includes(q));
      if (Number(a.unitId) > 0) list = list.filter((r) => r.unitId === Number(a.unitId));
      const offset = Math.max(0, Math.trunc(Number(a.offset) || 0)), items = list.slice(offset, offset + 12);
      return { items, more: list.length > offset + 12, offset };
    },
    async info() {
      const m = await getManifest();
      return { schema: m.schema, count: m.count, meta: { source: "Eclipse game data · " + m.date + " (web)", date: m.date }, database: { canRestore: false }, web: true };
    },
    query, cardIndex,
    async querySparking() { throw err("Sparking characters aren't in the web version yet. Use Eclipse characters, or the Android app."); },
    async sparkingInfo() { return { schema: {}, available: false }; },
    async projects() {
      const local = await getAll("projects").catch(() => []);
      const remote = await cloudList().catch(() => null);
      if (remote) {
        const have = new Map(remote.map((r) => [r.key, r.updatedAt || ""]));
        // copy up units that only exist here, or were changed here after the last upload finished
        for (const p of local) if (!have.has(p.key) || String(p.updatedAt || "") > have.get(p.key)) cloudSave(p);
        const out = remote.map((r) => r.summary).filter(Boolean);
        for (const p of local) if (!have.has(p.key)) { try { out.push(summary(p)); } catch (e) {} }
        return out;
      }
      return local.map((p) => { try { return summary(p); } catch (e) { return null; } }).filter(Boolean);
    },
    async loadProject(a) {
      let p = null;
      try { p = await cloudLoad(a.key); } catch (e) { console.warn("cloud load", e); }
      if (p) { put("projects", p.key, p).catch(() => {}); return p; }
      p = await get("projects", a.key).catch(() => null);
      if (!p) throw new Error("This unit is no longer saved.");
      return p;
    },
    async saveProject(a) {
      const p = a.project;
      if (!p || p.format !== "dokkan-unit-forge") throw new Error("Unsupported project");
      if (!/^[a-zA-Z0-9_-]{1,100}$/.test(p.key)) throw new Error("Invalid project key");
      const text = JSON.stringify(p);
      const copy = JSON.parse(text);
      try { await put("projects", p.key, copy); } catch (e) { if (!HOSTED) throw e; }
      if (HOSTED) cloudSave(copy);
      return { saved: true, revision: await revision(text) };
    },
    async deleteProject(a) {
      const local = await get("projects", a.key).catch(() => null);
      if (local) await del("projects", a.key);
      if (HOSTED) await cloudDelete(a.key);
      else if (!local) throw new Error("This unit is no longer saved on this device.");
      return { deleted: true, key: a.key };
    },
    async patches() { return (await getAll("patches")).map((x) => x.summary); },
    async deletePatch(a) { await del("patches", a.key); return { deleted: true, key: a.key }; },
    async export(a) {
      const name = String(a.name || "export.bin").replace(/[\\/:*?"<>|]+/g, "_");
      if (a.kind === "eclp") {
        if (a.patchKey) { const p = await get("patches", a.patchKey); if (!p) throw new Error("This file is no longer saved."); return saveFile(name, new Blob([p.bytes], { type: "application/octet-stream" })); }
        const entries = (a.entries || []).map((e) => { if (typeof e.text !== "string") throw err("Custom artwork files can't be packed in the web version yet. Export without custom art, or use the Android app."); return { path: e.path, bytes: e.text }; });
        const bytes = await ForgeEclp.write(entries, { deriveKey: deriveInWorker });
        return saveFile(name, new Blob([bytes], { type: "application/octet-stream" }));
      }
      if (a.kind === "zip") throw err("ZIP export isn't in the web version yet. Use .eclp or the editable backup (.json).");
      const type = a.kind === "json" ? "application/json" : "text/plain";
      return saveFile(name, new Blob([a.text || ""], { type }));
    },
    async pickTextFile(a) {
      const file = await chooseFile((a && a.accept) || ".sql");
      if (!file) return {};
      return { name: file.name, text: await file.text() };
    },
    async import() {
      const file = await chooseFile(".json,.eclp,.sql,application/json");
      if (!file) return {};
      if (/\.sql$/i.test(file.name)) return { kind: "sql", name: file.name, text: await file.text() };
      const bytes = new Uint8Array(await file.arrayBuffer());
      let project = null, patch = null;
      if (/\.eclp$/i.test(file.name) || String.fromCharCode(...bytes.subarray(0, 4)) === "ECLP") {
        const pack = await ForgeEclp.read(bytes, { deriveKey: deriveInWorker });
        const inner = pack.entries.find((e) => e.path === "forge-project.json");
        const key = "patch-" + Date.now().toString(36);
        patch = { key, metadata: pack.metadata, filename: file.name, importedAt: new Date().toISOString(), count: pack.entries.length, bytes: bytes.length, entries: pack.entries.map((e) => ({ path: e.path, bytes: e.bytes.length })) };
        await put("patches", key, { summary: patch, bytes });
        if (inner) project = JSON.parse(new TextDecoder().decode(inner.bytes));
        else return { kind: "patch", patch, note: "Added to Library → Game files." };
      } else {
        try { project = JSON.parse(new TextDecoder().decode(bytes)); } catch (e) { throw new Error("This file isn't a unit file from this app."); }
      }
      if (!project || project.format !== "dokkan-unit-forge") throw new Error("This file isn't a unit file from this app.");
      // a fresh key, like the Android app, so an import never overwrites a unit you already have
      const stamp = Date.now().toString(36), keys = new Map();
      const rekey = (p) => { const k = "unit-" + p.targetId + "-" + stamp; keys.set(p.key, k); p.key = k; };
      rekey(project); for (const f of project.formProjects || []) rekey(f);
      project.libraryOrigin = "uploaded";
      const text = JSON.stringify(project).replace(/"(unit-[A-Za-z0-9_-]+)"/g, (m, k) => keys.has(k) ? '"' + keys.get(k) + '"' : m);
      project = JSON.parse(text);
      try { await put("projects", project.key, project); } catch (e) { if (!HOSTED) throw e; }
      if (HOSTED) await cloudSave(project);
      return { kind: "project", project, patch };
    },
    async importApk() { throw err("Importing the Eclipse app file needs the Android app."); },
    async copy(a) { try { await navigator.clipboard.writeText(String(a.text || "")); } catch (e) { const t = document.createElement("textarea"); t.value = String(a.text || ""); document.body.append(t); t.select(); document.execCommand("copy"); t.remove(); } return { copied: true }; },
    async external(a) {
      const targets = { converter: "https://dokkan-eclipse.com/#convert-eclp", documentation: "https://dokkan-eclipse.com/wiki/documentation", downloads: "https://dokkan-eclipse.com/downloads", files: "https://dokkan-eclipse.com/files", sparkingLicense: "https://creativecommons.org/licenses/by-sa/4.0/" };
      const url = targets[a.target]; if (!url) throw new Error("Unknown link."); openLink(url); return { opened: true };
    },
    async openEclipse() { openLink("https://dokkan-eclipse.com"); return { installed: false, opened: true }; },
    async openStore() { return { opened: false }; },
    async renderMode() { return { mode: "gpu", auto: false, web: true }; },
    async textZoom(a) { return { percent: Number(a.percent) || 100 }; },
    async previewCache() { return { offline: false, bytes: 0, count: 0, maxBytes: 0, web: true }; },
    async previewDock(a) { return { open: false, full: false, separateWindow: false, smooth: true, quality: "auto", startFull: true, handled: false, dockable: false }; },
    async storageCheck() { return { web: true, permission: false, public: false, needsChoice: false, old: [] }; },
    async storageAccess() { return { opened: false }; },
    async storageDecline() { return { web: true, needsChoice: false }; },
    async offlineLibrary() { return { wifiOnly: true, movies: false, completed: {}, network: { connected: navigator.onLine }, storage: {}, web: true }; },
    async checkSparkingUpdates() { return { ok: false, web: true }; },
    async gameFolderStatus() { return { web: true }; },
    async sendToGame() { throw new Error("Import to Eclipse / Sparking works in the phone app. Here, use Save game file (.eclp)."); },
    async checkUpdates() { const m = await getManifest(); return { ok: true, lastModified: Date.parse(m.date + "T12:00:00Z"), size: 0, web: true }; },
    async sync() { throw err("The web version gets new characters when the website is updated. Reload the page to get the newest version."); },
    async wipeData(a) {
      if (a.units) {
        if (HOSTED) { const list = await cloudList().catch(() => null); for (const r of list || []) await cloudDelete(r.key); }
        const d = await idb(); const t = d.transaction(["projects", "patches"], "readwrite"); t.objectStore("projects").clear(); t.objectStore("patches").clear(); await new Promise((r) => { t.oncomplete = r; });
      }
      if (a.settings) { try { localStorage.clear(); } catch (e) {} }
      return { units: !!a.units, settings: !!a.settings, web: true };
    },
    async assets() { return []; },
    async assetUrl() { return null; },
    async patchesStatus() { return {}; },
    async importStatus() { return {}; },
    async aiConnections() { return []; },
    async animationFiles() { return []; },
  };
  window.forgeNative = {
    web: true,
    async call(method, args) {
      const fn = handlers[method];
      if (!fn) throw err(ANDROID_ONLY);
      return fn(args || {});
    },
  };
  window.__forgeWeb = { query, table, getManifest, handlers, cloud, hosted: HOSTED };
  document.documentElement.classList.add("web-version");
})();
