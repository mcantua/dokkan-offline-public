/* Web version of the Android bridge (Native.call). Loaded before the app's own scripts.
 * - Game data: compressed table files (data/db/*.json.gz) read on demand, queried exactly like
 *   the Android app's SQLite queries (filters, id lists, name search, order, limit, offset).
 * - Units and imported files: stored in this browser (IndexedDB), on this device only.
 * - .eclp export: built in the browser (eclp.js + argon2-worker.js), then saved or shared.
 * Imported resources, authored artwork and movies remain local to this browser; exports include
 * their actual bytes. Native-only device actions report their limits without claiming success. */
(function () {
  "use strict";
  const BASE = window.__forgeStandaloneBase || new URL(".", document.currentScript ? document.currentScript.src : location.href).href.replace(/web\/$/, "");
  const ANDROID_ONLY = "This device feature requires the phone app. Your browser changes have not been applied to it.";
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
  async function put(store, key, value) { const d = await idb(); const t = d.transaction(store, "readwrite"); t.objectStore(store).put(value, key); return new Promise((res, rej) => { t.oncomplete = () => res(true); t.onerror = () => rej(t.error || new Error("Couldn't save this data.")); t.onabort = () => rej(t.error || new Error("Saving was interrupted.")); }); }
  async function del(store, key) { const d = await idb(); const t = d.transaction(store, "readwrite"); t.objectStore(store).delete(key); return new Promise((res, rej) => { t.oncomplete = () => res(true); t.onerror = () => rej(t.error || new Error("Couldn't delete this data.")); t.onabort = () => rej(t.error || new Error("Deleting was interrupted.")); }); }
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
          const c = await cloud(); if (!c) return false;
          let info; try { info = summary(p); } catch (e) { info = { key: p.key, name: "" }; }
          const z = await packText(JSON.stringify(p)), parts = Math.ceil(z.length / CHUNK) || 1;
          for (let i = 1; i < parts; i++) await c.col.doc("p-" + key + "~" + i).set({ kind: "chunk", z: z.slice(i * CHUNK, (i + 1) * CHUNK) });
          await c.col.doc("p-" + key).set({ kind: "project", key, summary: info, updatedAt: p.updatedAt || new Date().toISOString(), parts, z: z.slice(0, CHUNK) });
        }
        return true;
      } catch (e) {
        console.warn("cloud save", e && (e.code || e.message));
        if (e && e.code === "quota_exceeded" && window.toast) toast("Claude's storage for this app is full. Delete units you don't need, or save .json backups.", true);
        return false;
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
    const c = await cloud(); if (!c) return false;
    const head = await c.col.doc("p-" + key).get();
    const parts = head.exists ? (head.data().parts || 1) : 1;
    await c.col.doc("p-" + key).delete();
    for (let i = 1; i < parts; i++) await c.col.doc("p-" + key + "~" + i).delete();
    return true;
  }
  // Saving files: hosted pages hand files over through Claude ("downloads"); .eclp isn't on its
  // list of file types, so it is wrapped in a .zip (tap it once in the Files app to get the .eclp).
  const CRC = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
  function crc32(b) { let c = 0xffffffff; for (let i = 0; i < b.length; i++) c = CRC[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
  function zipEntries(entries) {
    const localParts = [], centralParts = [], seen = new Set();
    let offset = 0, centralSize = 0, total = 0;
    if (!entries.length || entries.length > 10000) throw new Error("Choose 1–10,000 files for the ZIP.");
    for (const { name, bytes } of entries) {
    if (!name || name.startsWith("/") || name.includes("\\") || /[:\x00-\x1f]/.test(name) || name.split("/").some((x) => !x || x === "." || x === "..") || seen.has(name)) throw new Error("Invalid or duplicate ZIP file path.");
    seen.add(name); total += bytes.length;
    if (total > 67108864) throw new Error("ZIP export exceeds 64 MiB.");
    const n = new TextEncoder().encode(name), crc = crc32(bytes), d = new Date();
    if (n.length > 65535) throw new Error("ZIP file path is too long.");
    const time = (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1), date = ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate();
    const local = new DataView(new ArrayBuffer(30)), central = new DataView(new ArrayBuffer(46));
    [[0, 0x04034b50, 4], [4, 20, 2], [6, 0x0800, 2], [8, 0, 2], [10, time, 2], [12, date, 2], [14, crc, 4], [18, bytes.length, 4], [22, bytes.length, 4], [26, n.length, 2], [28, 0, 2]].forEach(([o, v, z]) => z === 4 ? local.setUint32(o, v, true) : local.setUint16(o, v, true));
    [[0, 0x02014b50, 4], [4, 20, 2], [6, 20, 2], [8, 0x0800, 2], [10, 0, 2], [12, time, 2], [14, date, 2], [16, crc, 4], [20, bytes.length, 4], [24, bytes.length, 4], [28, n.length, 2], [30, 0, 2], [32, 0, 2], [34, 0, 2], [36, 0, 2], [38, 0, 4], [42, 0, 4]].forEach(([o, v, z]) => z === 4 ? central.setUint32(o, v, true) : central.setUint16(o, v, true));
    central.setUint32(42, offset, true);
    localParts.push(local, n, bytes); centralParts.push(central, n);
    offset += 30 + n.length + bytes.length; centralSize += 46 + n.length;
    }
    const end = new DataView(new ArrayBuffer(22));
    [[0, 0x06054b50, 4], [4, 0, 2], [6, 0, 2], [8, entries.length, 2], [10, entries.length, 2], [12, centralSize, 4], [16, offset, 4], [20, 0, 2]].forEach(([o, v, z]) => z === 4 ? end.setUint32(o, v, true) : end.setUint16(o, v, true));
    return new Blob([...localParts, ...centralParts, end], { type: "application/zip" });
  }
  const zipOne = (name, bytes) => zipEntries([{ name, bytes }]);
  window.__forgeZipOne = zipOne;

  // ---------------------------------------------------------------- imported resources (same database, no destructive upgrade)
  const RESOURCE_LIMIT = 67108864, RESOURCE_PREFIX = "resource:", IMPORT_LEASE_PREFIX = "animation-import:";
  const RESOURCE_EXT = /\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|m4a|aac|flac|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$/i;
  const IMAGE_EXT = /\.(png|jpe?g|webp|gif|bmp)$/i;
  function resourcePath(path) {
    if (typeof path !== "string" || !path || path.length > 440 || path.startsWith("/") || /[\\:%\x00-\x1f\x7f]/.test(path) || !RESOURCE_EXT.test(path)) throw new Error("Choose a supported game resource with a safe file path.");
    if (path.split("/").some(p => !p || p.startsWith(".") || /^(?:projects|patches|exports|_databases|credentials|secrets|account)(?:\.|$)/i.test(p)) || /(?:api.?key|signing.?key|sparking.?key|credentials|secrets)/i.test(path)) throw new Error("Private files and keys cannot be imported as game resources.");
    return path;
  }
  const resourceId = () => crypto.randomUUID ? crypto.randomUUID() : Array.from(crypto.getRandomValues(new Uint8Array(16)), b => b.toString(16).padStart(2, "0")).join("");
  const assetPublic = ({ key, path, name, size, image, mtime }) => ({ key, path, name, size, image, mtime });
  function resourceRecord(path, bytes, group) {
    resourcePath(path);
    if (!bytes.length || bytes.length > RESOURCE_LIMIT) throw new Error("Game resource files must be between 1 byte and 64 MiB.");
    return { key: group + "/" + path, path, name: path.split("/").pop(), size: bytes.length, image: IMAGE_EXT.test(path), mtime: Date.now(), blob: new Blob([bytes]) };
  }
  async function resourceRecords() { const d = await idb(); return req(d.transaction("kv").objectStore("kv").getAll(IDBKeyRange.bound(RESOURCE_PREFIX, RESOURCE_PREFIX + "\uffff"))); }
  async function resource(key) {
    if (typeof key !== "string" || key.length > 500) throw new Error("Invalid resource reference.");
    resourcePath(key);
    const row = await get("kv", RESOURCE_PREFIX + key);
    if (!row || !(row.blob instanceof Blob) || row.size !== row.blob.size) throw new Error("This attached file is missing from this browser. Import its resource pack again.");
    return row;
  }
  // Hold a real origin-wide lock until the gallery has saved or discarded this import.
  // Without Web Locks, only this live window may reconcile its own leases; uncertain
  // foreign leases are retained rather than guessed dead from a timer.
  const importLocks = window.__forgeImportLockState || (window.__forgeImportLockState = { held: new Map() });
  const importLockName = token => "dokkan-unit-creator:animation-import:" + token;
  async function holdImportLock(token, ifAvailable = false) {
    if (importLocks.held.has(token)) return true;
    if (!navigator.locks?.request) { if (ifAvailable) return false; importLocks.held.set(token, { release() {} }); return true; }
    return new Promise((resolve, reject) => {
      let release; const untilDone = new Promise(done => { release = done; });
      navigator.locks.request(importLockName(token), { mode: "exclusive", ifAvailable }, async lock => {
        if (!lock) { resolve(false); return; }
        importLocks.held.set(token, { release }); resolve(true); await untilDone;
      }).catch(error => { importLocks.held.delete(token); reject(error); });
    });
  }
  function releaseImportLock(token) { const owned = importLocks.held.get(token); importLocks.held.delete(token); owned?.release(); }
  async function availableImportLease(row) {
    if (importLocks.held.has(row.token)) return true;
    if (!navigator.locks?.request) return false;
    return holdImportLock(row.token, true);
  }
  async function commitResources(rows, patch, lease) {
    const d = await idb();
    await new Promise((resolve, reject) => {
      const t = d.transaction(patch ? ["kv", "patches"] : ["kv"], "readwrite");
      try { for (const row of rows) t.objectStore("kv").add(row, RESOURCE_PREFIX + row.key); if (patch) t.objectStore("patches").add(patch, patch.summary.key); if (lease) t.objectStore("kv").add(lease, IMPORT_LEASE_PREFIX + lease.token); } catch (e) { try { t.abort(); } catch (_) {} reject(new Error(e?.name === "QuotaExceededError" ? "Browser storage is full. No resources were imported." : "Importing resources was interrupted. No files were saved.")); }
      t.oncomplete = resolve;
      t.onerror = t.onabort = () => reject(t.error || new Error("Importing resources was interrupted. No files were saved."));
    });
  }
  async function limitedBytes(response, limit) {
    if (!response.body) throw new Error("This resource has no readable contents.");
    const reader = response.body.getReader(), parts = []; let size = 0;
    try { for (;;) { const { done, value } = await reader.read(); if (done) break; size += value.length; if (size > limit) throw new Error("The resource exceeds the supported size."); parts.push(value); } } catch (e) { await reader.cancel().catch(() => {}); throw e; }
    return new Uint8Array(await new Blob(parts).arrayBuffer());
  }
  async function unzipResources(bytes, options = {}) {
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength), dec = new TextDecoder("utf-8", { fatal: true });
    const error = () => new Error("This ZIP is incomplete or uses an unsupported archive format. Choose a standard, unencrypted ZIP.");
    let end = -1;
    for (let i = bytes.length - 22; i >= Math.max(0, bytes.length - 65557); i--) if (view.getUint32(i, true) === 0x06054b50 && i + 22 + view.getUint16(i + 20, true) === bytes.length) { end = i; break; }
    if (end < 0 || view.getUint16(end + 4, true) || view.getUint16(end + 6, true)) throw error();
    const count = view.getUint16(end + 10, true), start = view.getUint32(end + 16, true), length = view.getUint32(end + 12, true);
    if (!count || count > (options.maxFiles || 10000) || view.getUint16(end + 8, true) !== count || start + length !== end) throw error();
    const entries = [], seen = new Set(), intervals = []; let pos = start, total = 0;
    for (let i = 0; i < count; i++) {
      if (pos + 46 > end || view.getUint32(pos, true) !== 0x02014b50) throw error();
      const flags = view.getUint16(pos + 8, true), method = view.getUint16(pos + 10, true), crc = view.getUint32(pos + 16, true), stored = view.getUint32(pos + 20, true), size = view.getUint32(pos + 24, true), n = view.getUint16(pos + 28, true), extra = view.getUint16(pos + 30, true), comment = view.getUint16(pos + 32, true), offset = view.getUint32(pos + 42, true);
      if (pos + 46 + n + extra + comment > end || flags & 1 || ![0, 8].includes(method) || view.getUint16(pos + 34, true) || ((view.getUint32(pos + 38, true) >>> 16) & 0xf000) === 0xa000) throw error();
      const nameBytes = bytes.subarray(pos + 46, pos + 46 + n), name = dec.decode(nameBytes);
      if (!(flags & 0x800) && /[^\x00-\x7f]/.test(name)) throw new Error("Save this ZIP with UTF-8 file names before importing it.");
      pos += 46 + n + extra + comment;
      if (offset + 30 > start || view.getUint32(offset, true) !== 0x04034b50 || view.getUint16(offset + 6, true) !== flags || view.getUint16(offset + 8, true) !== method) throw error();
      const localName = view.getUint16(offset + 26, true), localExtra = view.getUint16(offset + 28, true), data = offset + 30 + localName + localExtra;
      if (data + stored > start || localName !== n || !nameBytes.every((b, j) => bytes[offset + 30 + j] === b)) throw error();
      intervals.push([offset, data + stored]);
      if (name.endsWith("/")) { if (size || options.noDirectories) throw error(); continue; }
      if (!size || size > RESOURCE_LIMIT || (total += size) > (options.maxBytes || RESOURCE_LIMIT)) throw new Error("The resource pack exceeds its expanded import size limit.");
      const canonical = name.normalize("NFC").toLowerCase(); if (seen.has(canonical)) throw new Error("This archive contains conflicting file paths."); seen.add(canonical);
      // A Unit Creator ZIP also contains its editable project and patch metadata.
      if ((["metadata.json", "forge-project.json", "database.sql"].includes(name) || /^files\/[^/]+\.sql$/i.test(name))) { entries.push({ path: name, data, stored, size, method, crc }); continue; }
      const path = name.startsWith("files/") ? name.slice(6) : name; resourcePath(path);
      entries.push({ path: name, data, stored, size, method, crc });
    }
    if (pos !== end) throw error();
    intervals.sort((a, b) => a[0] - b[0]); if (intervals.some((r, i) => i && r[0] < intervals[i - 1][1])) throw error();
    const out = [];
    for (const e of entries) {
      let raw = bytes.slice(e.data, e.data + e.stored);
      if (e.method === 8) { let stream; try { stream = new DecompressionStream("deflate-raw"); } catch (_) { throw new Error("This browser cannot open compressed ZIP files. Update your browser or import an ECLP file instead."); } raw = await limitedBytes(new Response(new Blob([raw]).stream().pipeThrough(stream)), e.size); }
      if (raw.length !== e.size || crc32(raw) !== e.crc) throw new Error("A ZIP file failed its size or checksum check. No files were imported.");
      out.push({ path: e.path, bytes: raw });
    }
    return out;
  }
  async function exportEntries(entries) {
    if (!Array.isArray(entries) || !entries.length || entries.length > 10000) throw new Error("Choose a supported patch to export.");
    const out = [], seen = new Set(); let total = 0;
    for (const e of entries) {
      if (!e || typeof e.path !== "string" || e.path.startsWith("/") || /[\\:\x00-\x1f]/.test(e.path) || e.path.split("/").some(p => !p || p === "." || p === "..") || seen.has(e.path)) throw new Error("Unsafe or duplicate patch file path."); seen.add(e.path);
      let bytes;
      if (typeof e.text === "string") bytes = new TextEncoder().encode(e.text);
      else if (typeof e.assetKey === "string") bytes = new Uint8Array(await (await resource(e.assetKey)).blob.arrayBuffer());
      else if (e.bytes instanceof Uint8Array) bytes = e.bytes;
      else if (e.bytes instanceof ArrayBuffer) bytes = new Uint8Array(e.bytes);
      else if (e.cpk) {
        if (!/\.cpk$/i.test(e.path) || !Array.isArray(e.cpk) || !e.cpk.length || e.cpk.length > 5000 || !window.ForgeCpk) throw new Error("The packed artwork writer is unavailable or the resource list is invalid.");
        const files = []; let size = 0;
        for (const item of e.cpk) {
          resourcePath(item.path); const row = await resource(item.assetKey);
          if ((size += row.size) > RESOURCE_LIMIT - total) throw new Error("Packed artwork exceeds the 64 MiB browser export limit.");
          files.push({ path: item.path, data: new Uint8Array(await row.blob.arrayBuffer()) });
        }
        if (window.ForgeCpk.layout(files.map(f => ({ path: f.path, size: f.data.length }))).totalBytes > RESOURCE_LIMIT - total) throw new Error("Packed artwork exceeds the 64 MiB browser export limit.");
        bytes = window.ForgeCpk.encode(files);
      }
      else throw new Error("This patch references a resource that is not saved in this browser.");
      if ((total += bytes.length) > RESOURCE_LIMIT) throw new Error("An exported patch must be 64 MiB or less.");
      out.push({ path: e.path, bytes });
    }
    return out;
  }

  const DEC_ERR = "The card decoration metadata is invalid. Import its original artwork again.";
  function decSafe(s) { return typeof s === "string" && s && s.length <= 500 && !s.startsWith("/") && !/[\\:\x00-\x1f\x7f%]/.test(s) && s.split("/").every((x) => x && !x.startsWith(".")); }
  function inspectDecoration(b) {
    if (b.length < 1 || b.length > 131072) throw new Error(DEC_ERR);
    let t; try { t = new TextDecoder("utf-8", { fatal: true }).decode(b).trim(); } catch (e) { throw new Error(DEC_ERR); }
    let inStr = false, esc = false, depth = 0;
    for (const ch of t) {
      if (inStr) { if (esc) esc = false; else if (ch === "\\") esc = true; else if (ch === '"') inStr = false; continue; }
      if (ch === '"') inStr = true;
      else if (ch === "{" || ch === "[") { if (++depth > 32) throw new Error(DEC_ERR); }
      else if (ch === "}" || ch === "]") { if (--depth < 0) throw new Error(DEC_ERR); }
    }
    if (inStr || depth || !t.startsWith("{") || !t.endsWith("}")) throw new Error(DEC_ERR);
    let j; try { j = JSON.parse(t); } catch (e) { throw new Error(DEC_ERR); }
    if (!(Number.isSafeInteger(j.card_id) && j.card_id >= 1 && j.card_id <= 2147483647) || typeof j.shader_file !== "string" || !decSafe(j.shader_file) || !Array.isArray(j.parameters) || j.parameters.length > 128) throw new Error(DEC_ERR);
    for (const p of j.parameters) {
      if (!p || typeof p.type !== "string" || typeof p.name !== "string") throw new Error(DEC_ERR);
      if (p.type === "sampler2D" && !(typeof p.value === "string" && decSafe(p.value))) throw new Error(DEC_ERR);
    }
    return { width: 0, height: 0, mime: "application/json" };
  }
  const movieUploads = new Map(), assetUrls = new Map();
  addEventListener("pagehide", () => { for (const u of assetUrls.values()) URL.revokeObjectURL(u); assetUrls.clear(); });
  function toBase64(bytes) { let bin = ""; for (let i = 0; i < bytes.length; i += 32768) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 32768)); return btoa(bin); }
  function strictBase64(text, limit) {
    if (typeof text !== "string" || text.length > Math.ceil(limit / 3) * 4 || text.length % 4 || !/^[A-Za-z0-9+/]*={0,2}$/.test(text)) throw new Error("Invalid resource bytes.");
    let binary; try { binary = atob(text); } catch (_) { throw new Error("Invalid resource bytes."); }
    const bytes = Uint8Array.from(binary, c => c.charCodeAt(0));
    if (bytes.length > limit || toBase64(bytes) !== text) throw new Error("Invalid resource bytes."); return bytes;
  }

  // ---------------------------------------------------------------- game data
  let manifest = null, sparkingManifest = null;
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
  async function getSparkingManifest() {
    const main = await getManifest();
    if (!main.sparkingAvailable) throw err("This browser page doesn't include the Sparking character database.");
    if (!sparkingManifest) sparkingManifest = gunzipJson(BASE + "data/sparking-db/manifest.json.gz").catch((e) => { sparkingManifest = null; throw e; });
    return sparkingManifest;
  }
  async function table(name, database = "eclipse") {
    const cacheKey = database + ":" + name;
    if (tables.has(cacheKey)) return tables.get(cacheKey);
    if (loading.has(cacheKey)) return loading.get(cacheKey);
    const p = (async () => {
      const m = database === "sparking" ? await getSparkingManifest() : await getManifest();
      if (!m.schema[name]) throw new Error("Table is not in this database.");
      // tables come packed in a few bigger files; each file is downloaded once and shared
      const file = m.files[name], folder = database === "sparking" ? "data/sparking-db/" : "data/db/", partKey = folder + file;
      if (!parts.has(partKey)) parts.set(partKey, gunzipJson(BASE + folder + file).catch((e) => { parts.delete(partKey); throw e; }));
      let data = m.bundled ? (await parts.get(partKey))[name] : await parts.get(partKey);
      if (database === "sparking" && data.base === true) {
        const base = await table(name);
        if (JSON.stringify(base.cols) !== JSON.stringify(data.c)) throw new Error("The Sparking snapshot doesn't match its shared Eclipse data.");
        const rows = data.r.map((row) => {
          if (Number.isInteger(row)) {
            if (row < 0 || row >= base.rows.length) throw new Error("Invalid shared Sparking row.");
            return base.rows[row];
          }
          if (!Array.isArray(row) || !row.length) throw new Error("Invalid Sparking table delta.");
          if (row[0] === -1) {
            if (row.length !== data.c.length + 1) throw new Error("Invalid new Sparking row.");
            return row.slice(1);
          }
          if (!Number.isInteger(row[0]) || row[0] < 0 || row[0] >= base.rows.length || row.length % 2 !== 1) throw new Error("Invalid changed Sparking row.");
          const out = base.rows[row[0]].slice();
          for (let i = 1; i < row.length; i += 2) {
            if (!Number.isInteger(row[i]) || row[i] < 0 || row[i] >= out.length) throw new Error("Invalid Sparking column delta.");
            out[row[i]] = row[i + 1];
          }
          return out;
        });
        data = { c: data.c, r: rows };
      }
      const col = new Map(data.c.map((c, i) => [c, i]));
      const t = { name, cols: data.c, col, rows: data.r, eq: new Map(), sorted: new Map() };
      tables.set(cacheKey, t);
      return t;
    })();
    loading.set(cacheKey, p);
    try { return await p; } finally { loading.delete(cacheKey); }
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
  async function query(a, database = "eclipse") {
    const t = await table(String(a.table || ""), database);
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
  const PROJECT_LIMIT = 20971520;
  function projectText(p) {
    const object = (v) => v && typeof v === "object" && !Array.isArray(v);
    if (!p || p.format !== "dokkan-unit-forge" || p.version !== 1 || !/^[a-zA-Z0-9_-]{1,100}$/.test(String(p.key || "")) || !object(p.source) || !object(p.cardOverrides) || !object(p.tables) || !Array.isArray(p.tables.cards) || p.tables.cards.length !== 1 || !object(p.tables.cards[0]) || !Number.isSafeInteger(Number(p.targetId)) || Number(p.targetId) <= 0) throw new Error("This file isn't a supported unit from this app.");
    if (p.formProjects != null && (!Array.isArray(p.formProjects) || p.formProjects.length > 64)) throw new Error("This unit has too many transformation forms.");
    const text = JSON.stringify(p);
    if (new TextEncoder().encode(text).length > PROJECT_LIMIT) throw new Error("A unit file must be 20 MiB or smaller.");
    return text;
  }
  async function persistProject(p, patch, resources = []) {
    const text = projectText(p), copy = JSON.parse(text);
    let localError;
    try {
      const d = await idb();
      const superseded = await new Promise((resolve, reject) => {
        const t = d.transaction(resources.length ? ["projects", "patches", "kv"] : patch ? ["projects", "patches"] : ["projects"], "readwrite"), store = t.objectStore("projects"), old = store.get(p.key);
        let stale = false;
        old.onsuccess = () => {
          try {
            stale = newer(old.result, copy);
            if (!stale) { store.put(copy, p.key); if (patch) t.objectStore("patches").put(patch, patch.summary.key); for (const row of resources) t.objectStore("kv").add(row, RESOURCE_PREFIX + row.key); }
          } catch (e) { try { t.abort(); } catch (_) {} }
        };
        t.oncomplete = () => resolve(stale);
        t.onerror = () => reject(t.error || new Error("Couldn't save this unit."));
        t.onabort = () => reject(t.error || new Error("Saving was interrupted."));
      });
      if (superseded) return { saved: false, superseded: true };
    }
    catch (e) { localError = e || new Error("Saving was interrupted."); }
    if (localError) {
      if (!patch && !resources.length && HOSTED && await cloudSave(copy)) return { saved: true, storage: "cloud", revision: await revision(text) };
      throw new Error("Couldn't save this unit in the browser. Keep it open and export a .json copy before leaving. " + (localError.message || "Storage is unavailable."));
    }
    if (HOSTED) cloudSave(copy);
    return { saved: true, storage: "local", revision: await revision(text) };
  }
  const newer = (a, b) => String(a && a.updatedAt || "") > String(b && b.updatedAt || "");
  async function versionContext(key) {
    const project = await get("projects", key);
    if (!project) throw new Error("This unit is no longer saved on this device.");
    const text = projectText(project), rows = await get("kv", "versions:" + key) || [];
    if (!Array.isArray(rows) || rows.length > 10 || rows.some((r) => !r || typeof r.text !== "string" || r.bytes > PROJECT_LIMIT || r.bytes < 1 || !/^[a-f0-9]{64}$/.test(r.revision || ""))) throw new Error("Invalid saved version index.");
    return { project, text, rows, revision: await revision(text) };
  }
  const publicVersions = (rows) => rows.map(({ versionKey, label, createdAt, bytes }) => ({ versionKey, label, createdAt, bytes }));
  function checkVersionRevision(a, current, required) {
    if ((required || a.expectedCurrentRevision != null) && a.expectedCurrentRevision !== current.revision) throw new Error("This project changed after the version list was opened. Close it and reopen Saved versions.");
  }
  async function versionRow(text, label, safety = false) {
    label = String(label || "").trim();
    if (!label || [...label].length > 80 || /[\x00-\x1f\x7f]/.test(label)) throw new Error("Use a readable version name of 1–80 characters.");
    const versionKey = Array.from(crypto.getRandomValues(new Uint8Array(16)), (b) => b.toString(16).padStart(2, "0")).join("");
    return { versionKey, label, createdAt: new Date().toISOString(), bytes: new TextEncoder().encode(text).length, revision: await revision(text), text, safety };
  }
  function keepVersions(row, old) {
    const out = [row]; let size = row.bytes;
    for (const r of old) {
      if (row.safety && r.safety) continue; // retain at most one automatic recovery copy
      if (out.length >= 10 || size + r.bytes > 41943040) break;
      size += r.bytes; out.push(r);
    }
    return out;
  }
  async function commitVersions(key, current, rows, project) {
    const d = await idb();
    return new Promise((resolve, reject) => {
      const t = d.transaction(["projects", "kv"], "readwrite");
      const p = t.objectStore("projects").get(key), v = t.objectStore("kv").get("versions:" + key);
      let pending = 2, conflict = false;
      const ready = () => {
        if (--pending) return;
        if (JSON.stringify(p.result) !== current.text || JSON.stringify(v.result || []) !== JSON.stringify(current.rows)) { conflict = true; t.abort(); return; }
        try {
          t.objectStore("kv").put(rows, "versions:" + key);
          if (project) t.objectStore("projects").put(project, key);
        } catch (e) { t.abort(); }
      };
      p.onsuccess = ready; v.onsuccess = ready;
      t.oncomplete = () => resolve(true);
      t.onerror = () => reject(t.error || new Error("Couldn't save this version."));
      t.onabort = () => reject(new Error(conflict ? "This project changed. Reopen Saved versions before trying again." : "Saving the version was interrupted; the current design was kept."));
    });
  }
  async function readVersion(key, versionKey, rows) {
    const row = rows.find((r) => r.versionKey === versionKey);
    if (!row) throw new Error("This saved version is no longer available.");
    if (await revision(row.text) !== row.revision) throw new Error("Saved version checksum does not match.");
    const p = JSON.parse(row.text); projectText(p);
    if (p.key !== key) throw new Error("This version does not belong to the open unit.");
    return p;
  }

  // ---------------------------------------------------------------- files: choose, save, share
  function chooseFile(accept) {
    // A visible button inside a small window: iPhones only open the file picker from a direct tap.
    return new Promise((resolve) => {
      const d = document.createElement("dialog");
      d.className = "web-file-dialog";
      d.innerHTML = '<h2>Import a file</h2><p>Choose an editable unit, ECLP or ZIP pack, image, or game resource file.</p><label class="button web-file-button">📁 Choose a file<input type="file" hidden></label><button type="button" class="button ghost">Cancel</button>';
      document.body.append(d);
      const input = d.querySelector("input");
      input.accept = accept;
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
    if (HOSTED && !window.__forgeStandaloneBase) return saveHosted(name, blob);
    return saveBrowser(name, blob);
  }
  function saveBrowser(name, blob) {
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
    if (!downloads) return saveBrowser(name, blob);
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
  const catalogCache = new Map(), catalogObjects = new Map();
  async function objects(name, database = "eclipse") {
    const key = database + ":" + name;
    if (!catalogObjects.has(key)) catalogObjects.set(key, (async () => {
      const manifest = database === "sparking" ? await getSparkingManifest() : await getManifest();
      if (!manifest.schema[name]) return [];
      const t = await table(name, database);
      return t.rows.map(r => { const o = {}; t.cols.forEach((c, i) => { o[c] = r[i]; }); return o; });
    })().catch(error => { catalogObjects.delete(key); throw error; }));
    return catalogObjects.get(key);
  }
  const okScript = (s) => s != null && !["", "0", "none"].includes(String(s));
  async function catalogRows(kind, database = "eclipse") {
    const cacheKey = database + ":" + kind;
    if (catalogCache.has(cacheKey)) return catalogCache.get(cacheKey);
    const p = (async () => {
      const read = name => objects(name, database);
      if (window.ForgeCardVersions) await ForgeCardVersions.load(database);
      const cards = new Map((await read("cards")).map((c) => [c.id, c])), out = [];
      const card = (id) => cards.get(id);
      const add = (key, k, viewId, script, c, moveName, sourceTable, fallbackUnit) => {
        if (c && window.ForgeCardVersions && (!ForgeCardVersions.isPlayerCard(c, database) || ForgeCardVersions.finalId(c.id, database) !== c.id)) return;
        out.push({ key, kind: k, viewId, script, unitId: c ? c.id : 0, unitName: c ? c.name : fallbackUnit, moveName, description: "", resourceId: c ? (c.resource_id || c.id) : 0, rarity: c ? c.rarity : 0, sourceTable, sourceDatabase: database });
      };
      if (["super", "ultra", "ex", "fullpower", "ultimate", "transform"].includes(kind)) {
        const views = new Map((await read("special_views")).map((v) => [v.id, v])), sets = new Map((await read("special_sets")).map((s) => [s.id, s]));
        for (const cs of await read("card_specials")) {
          const v = views.get(cs.view_id); if (!v || !okScript(v.script_name)) continue;
          const sn = String(v.script_name), k = /^tf/.test(sn) ? "transform" : /^ut/.test(sn) ? "ultimate" : cs.style === "Hyper" ? "ultra" : cs.style === "Extra" ? "ex" : cs.style === "FullPower" ? "fullpower" : "super";
          if (k !== kind) continue;
          const c = card(cs.card_id), st = sets.get(cs.special_set_id);
          add("view:" + v.id + ":" + (c ? c.id : 0), k, v.id, sn, c, st ? st.name : "Shared battle animation", "special_views", "Shared or enemy sequence");
        }
        // animations no card uses directly (shared, enemy and form-change scenes)
        const used = new Set((await read("card_specials")).map((cs) => cs.view_id));
        for (const v of views.values()) {
          if (used.has(v.id) || !okScript(v.script_name)) continue;
          const sn = String(v.script_name), k = /^tf/.test(sn) ? "transform" : /^ut/.test(sn) ? "ultimate" : "super";
          if (k === kind) add("view:" + v.id + ":0", k, v.id, sn, null, "Shared battle animation", "special_views", "Shared or enemy sequence");
        }
      } else if (["active", "standby", "finish"].includes(kind)) {
        const T = { active: ["active_skill_sets", "card_active_skills", "active_skill_set_id"], standby: ["standby_skill_sets", "card_standby_skill_set_relations", "standby_skill_set_id"], finish: ["finish_skill_sets", "card_finish_skill_set_relations", "finish_skill_set_id"] }[kind];
        const views = new Map((await read("special_views")).map((v) => [v.id, v])), sets = new Map((await read(T[0])).map((s) => [s.id, s]));
        for (const r of await read(T[1])) {
          const st = sets.get(r[T[2]]), c = card(r.card_id), v = st && views.get(st.special_view_id);
          if (!st || !c || !v || !okScript(v.script_name)) continue;
          add(kind + ":" + st.id + ":" + c.id, kind, v.id, v.script_name, c, st.name, "special_views");
        }
      }
      if (["transform", "giant"].includes(kind)) {
        // form changes: the passive's battle_params (idx 11 = transformation view, 12 = giant form view)
        const idx = kind === "transform" ? 11 : 12, eff = kind === "transform" ? 103 : 79;
        const viewTable = new Map((await read(kind === "transform" ? "transformation_views" : "metamorphic_views")).map((v) => [v.id, v]));
        const params = new Map(); for (const b of await read("battle_params")) if (Number(b.idx) === idx) params.set(b.param_no, b.value);
        const ps = await read("passive_skills"), rel = await read("passive_skill_set_relations"), bySet = new Map();
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
        const ps = await read("passive_skills"), rel = await read("passive_skill_set_relations"), bySet = new Map();
        for (const c of cards.values()) { if (!bySet.has(c.passive_skill_set_id)) bySet.set(c.passive_skill_set_id, []); bySet.get(c.passive_skill_set_id).push(c); }
        const setsOf = new Map(); for (const r of rel) { if (!setsOf.has(r.passive_skill_id)) setsOf.set(r.passive_skill_id, []); setsOf.get(r.passive_skill_id).push(r.passive_skill_set_id); }
        const views = kind === "revival" ? new Map((await read("revival_views")).map((v) => [v.id, v])) : kind === "intro" ? new Map((await read("passive_skill_effects")).map((v) => [v.id, v])) : null;
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
    const ready = p.catch(error => { catalogCache.delete(cacheKey); throw error; });
    catalogCache.set(cacheKey, ready);
    return ready;
  }
  const handlers = {
    async animationCatalog(a) {
      const database = a.sourceDatabase === "sparking" ? "sparking" : "eclipse", cacheKey = database + ":all";
      const kind = String(a.kind || "super"), q = String(a.search || "").toLowerCase().slice(0, 100);
      const ALL = ["super", "ultra", "ex", "fullpower", "ultimate", "transform", "active", "standby", "finish", "counter", "revival", "intro", "giant", "nullify"];
      if (kind === "all" && !catalogCache.has(cacheKey)) catalogCache.set(cacheKey, Promise.all(ALL.map(kind => catalogRows(kind, database))).then((ls) => ls.flat().sort((a, b) => (a.unitId === 0) - (b.unitId === 0) || String(a.unitName).localeCompare(String(b.unitName)) || String(a.moveName).localeCompare(String(b.moveName)))).catch(error => { catalogCache.delete(cacheKey); throw error; }));
      let list = await (kind === "all" ? catalogCache.get(cacheKey) : catalogRows(kind, database));
      if (q) list = list.filter((r) => String(r.unitName).toLowerCase().includes(q) || String(r.moveName).toLowerCase().includes(q));
      if (Number(a.unitId) > 0) list = list.filter((r) => r.unitId === Number(a.unitId));
      const offset = Math.max(0, Math.trunc(Number(a.offset) || 0)), items = list.slice(offset, offset + 12);
      return { items, more: list.length > offset + 12, offset };
    },
    async info() {
      const m = await getManifest();
      document.documentElement.classList.toggle("web-sparking", !!m.sparkingAvailable);
      return { schema: m.schema, count: m.count, meta: { source: "Eclipse game data · " + m.date + " (web)", date: m.date }, database: { canRestore: false }, sparkingSnapshotId: m.sparkingSnapshotId || null, web: true };
    },
    query, cardIndex,
    async querySparking(a) { return query(a, "sparking"); },
    async sparkingInfo() {
      if (!(await getManifest()).sparkingAvailable) return { schema: {}, available: false, web: true, keyConfigured: false };
      const m = await getSparkingManifest();
      return { schema: m.schema, available: true, count: m.count, web: true, keyConfigured: false,
        meta: { source: "Sparking database snapshot bundled in this page", sourceType: m.sourceType, snapshotId: m.snapshotId } };
    },
    async sparkingCatalog(a) {
      if (!window.ForgeCardVersions) throw new Error("The character picker is still starting. Try again.");
      if (!catalogCache.has("browser-sparking")) catalogCache.set("browser-sparking", (async () => {
        const all = [];
        for (let offset = 0; offset < 50000; offset += 5000) {
          const rows = await query({ table: "cards", offset, limit: 5000 }, "sparking"); all.push(...rows);
          if (rows.length < 5000) break;
        }
        const final = await window.ForgeCardVersions.collapse(all, { database: "sparking" });
        const rank = { seza: 2, eza: 1, "": 0 };
        return final.sort((x, y) => (rank[ForgeCardVersions.status(y, "sparking")] || 0) - (rank[ForgeCardVersions.status(x, "sparking")] || 0) || String(x.name).localeCompare(String(y.name)) || y.rarity - x.rarity || x.id - y.id);
      })().catch((e) => { catalogCache.delete("browser-sparking"); throw e; }));
      const q = String(a.search || "").trim().toLowerCase(), offset = Math.max(0, Math.trunc(Number(a.offset) || 0)), limit = Math.max(1, Math.min(120, Math.trunc(Number(a.limit) || 120)));
      const rows = (await catalogCache.get("browser-sparking")).filter((r) => !q || String(r.name).toLowerCase().includes(q));
      return { items: rows.slice(offset, offset + limit), more: rows.length > offset + limit, total: rows.length };
    },
    async projects() {
      let localError;
      const local = await getAll("projects").catch((e) => { localError = e; return []; });
      const remote = await cloudList().catch(() => null);
      if (remote) {
        const have = new Map(remote.map((r) => [r.key, r.updatedAt || ""]));
        // copy up units that only exist here, or were changed here after the last upload finished
        for (const p of local) if (!have.has(p.key) || String(p.updatedAt || "") > have.get(p.key)) cloudSave(p);
        const out = new Map(remote.filter((r) => r.summary).map((r) => [r.key, r.summary]));
        for (const p of local) if (!have.has(p.key) || String(p.updatedAt || "") >= have.get(p.key)) { try { out.set(p.key, summary(p)); } catch (e) {} }
        return [...out.values()];
      }
      if (localError) throw new Error("Couldn't read your saved units. Browser storage is unavailable; your library has not been cleared.");
      return local.map((p) => { try { return summary(p); } catch (e) { return null; } }).filter(Boolean);
    },
    async loadProject(a) {
      let local = null, remote = null, localError;
      try { local = await get("projects", a.key); } catch (e) { localError = e; }
      try { remote = await cloudLoad(a.key); } catch (e) { console.warn("cloud load", e); }
      if (local && (!remote || newer(local, remote))) return local;
      if (remote) { put("projects", remote.key, remote).catch(() => {}); return remote; }
      if (localError) throw new Error("Couldn't open this unit because browser storage is unavailable.");
      throw new Error("This unit is no longer saved.");
    },
    async saveProject(a) {
      return persistProject(a.project);
    },
    async listProjectVersions(a) {
      const c = await versionContext(a.key);
      return { versions: publicVersions(c.rows), currentRevision: c.revision };
    },
    async saveProjectVersion(a) {
      const c = await versionContext(a.key); checkVersionRevision(a, c, false);
      const row = await versionRow(c.text, a.label), rows = keepVersions(row, c.rows);
      await commitVersions(a.key, c, rows);
      return { saved: true, versionKey: row.versionKey, versions: publicVersions(rows), currentRevision: c.revision };
    },
    async loadProjectVersion(a) {
      const c = await versionContext(a.key);
      return readVersion(a.key, a.versionKey, c.rows);
    },
    async restoreProjectVersion(a) {
      const c = await versionContext(a.key); checkVersionRevision(a, c, true);
      const project = await readVersion(a.key, a.versionKey, c.rows);
      const row = await versionRow(c.text, "Before restoring an earlier version", true), rows = keepVersions(row, c.rows);
      project.updatedAt = new Date(Math.max(Date.now(), (Date.parse(c.project.updatedAt || "") || 0) + 1)).toISOString();
      await commitVersions(a.key, c, rows, project);
      if (HOSTED) cloudSave(project);
      return { saved: true, project, versions: publicVersions(rows), currentRevision: await revision(JSON.stringify(project)) };
    },
    async deleteProject(a) {
      const local = await get("projects", a.key);
      if (local) await del("projects", a.key);
      const remoteDeleted = HOSTED && await cloudDelete(a.key);
      if (!local && !remoteDeleted) throw new Error("This unit is no longer saved on this device.");
      await del("kv", "versions:" + a.key);
      return { deleted: true, key: a.key };
    },
    async patches() { return (await getAll("patches")).map((x) => x.summary); },
    async deletePatch(a) { await del("patches", a.key); return { deleted: true, key: a.key }; },
    async export(a) {
      const name = String(a.name || "export.bin").replace(/[\\/:*?"<>|]+/g, "_");
      if (a.kind === "eclp") {
        if (a.patchKey) { const p = await get("patches", a.patchKey); if (!p) throw new Error("This file is no longer saved."); return saveFile(name, new Blob([p.bytes], { type: "application/octet-stream" })); }
        const entries = await exportEntries(a.entries);
        const bytes = await ForgeEclp.write(entries, { deriveKey: deriveInWorker });
        return saveFile(name, new Blob([bytes], { type: "application/octet-stream" }));
      }
      if (a.kind === "zip") {
        const entries = (await exportEntries(a.entries)).map(e => ({ name: e.path, bytes: e.bytes }));
        return saveFile(name, zipEntries(entries));
      }
      const type = a.kind === "json" ? "application/json" : "text/plain";
      return saveFile(name, new Blob([a.text || ""], { type }));
    },
    async pickTextFile(a) {
      const file = await chooseFile((a && a.accept) || ".sql");
      if (!file) return {};
      if (file.size > PROJECT_LIMIT) throw new Error("Import files must be 20 MiB or smaller.");
      return { name: file.name, text: await file.text() };
    },
    async import() {
      const file = await chooseFile(".json,.eclp,.zip,.sql,.png,.jpg,.jpeg,.webp,.gif,.bmp,.lwf,.lua,.usm,.cpk,.ogg,.mp3,.m4a,.aac,.flac,.wav,.awb,.acb,.atlas,.plist,.xml,.bytes,.bin,.txt");
      if (!file) return {};
      if (file.size > RESOURCE_LIMIT) throw new Error("Import files must be 64 MiB or smaller.");
      if (/\.sql$/i.test(file.name)) return { kind: "sql", name: file.name, text: await file.text() };
      const bytes = new Uint8Array(await file.arrayBuffer()), stamp = resourceId(), group = "import-" + stamp;
      let project = null, patch = null, entries = [], rows = [];
      if (/\.eclp$/i.test(file.name) || String.fromCharCode(...bytes.subarray(0, 4)) === "ECLP") {
        const pack = await ForgeEclp.read(bytes, { deriveKey: deriveInWorker, maxBytes: RESOURCE_LIMIT, maxFiles: 10000 }); entries = pack.entries;
        patch = { key: "patch-" + stamp, metadata: pack.metadata, filename: file.name, importedAt: new Date().toISOString(), count: entries.length, bytes: bytes.length, entries: entries.map(e => ({ path: e.path, bytes: e.bytes.length })) };
      } else if (/\.zip$/i.test(file.name)) entries = await unzipResources(bytes);
      else if (/\.cpk$/i.test(file.name)) {
        if (!window.__forgeWeb.formats) throw new Error("Resource readers are still starting. Try again.");
        entries.push({ path: resourcePath(file.name), bytes });
        const packed = await window.__forgeWeb.formats.cpkEntries(file); let total = bytes.length;
        if (packed.length > 10000) throw new Error("Choose an archive with no more than 10,000 resource files.");
        for (const e of packed) { if ((total += e.size) > RESOURCE_LIMIT) throw new Error("This archive expands beyond the 64 MiB browser limit."); entries.push({ path: file.name.slice(0, -4) + "/" + resourcePath(e.path), bytes: await window.__forgeWeb.formats.cpkRead(file, e) }); }
      } else if (/\.json$/i.test(file.name)) {
        try { project = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes)); } catch (e) { throw new Error("This JSON is not a readable unit file."); }
        if (project.format !== "dokkan-unit-forge") { project = null; entries = [{ path: resourcePath(file.name), bytes }]; }
      } else entries = [{ path: resourcePath(file.name), bytes }];
      const inner = entries.find(e => e.path === "forge-project.json");
      if (inner) { try { project = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(inner.bytes)); } catch (e) { throw new Error("The editable unit in this archive is unreadable. No files were imported."); } }
      let total = 0; const destinations = new Set();
      for (const e of entries) {
        if (["metadata.json", "forge-project.json", "database.sql"].includes(e.path) || /^files\/[^/]+\.sql$/i.test(e.path)) continue;
        const path = e.path.startsWith("files/") ? e.path.slice(6) : e.path;
        resourcePath(path); const canonical = path.normalize("NFC").toLowerCase();
        if (destinations.has(canonical)) throw new Error("The archive has conflicting resource destinations."); destinations.add(canonical);
        if ((total += e.bytes.length) > RESOURCE_LIMIT) throw new Error("Imported resources exceed 64 MiB.");
        rows.push(resourceRecord(path, e.bytes, group));
      }
      if (!project) {
        if (!rows.length && !patch) throw new Error("This archive has no supported game resources or editable unit.");
        await commitResources(rows, patch ? { summary: patch, bytes } : null);
        return patch ? { kind: "patch", patch, note: "Game file and its resources saved in this browser." } : { kind: "assets", count: rows.length, bytes: total, note: "Resources saved in this browser. You can attach them from Game data & files." };
      }
      projectText(project); for (const form of project.formProjects || []) projectText(form);
      for (const row of rows) row.sourceDatabase = project.source.database === "sparking" ? "sparking" : "eclipse";
      const originalKeys = [project, ...(project.formProjects || [])].map(p => p.key);
      if (new Set(originalKeys).size !== originalKeys.length) throw new Error("This unit has duplicate transformation identities.");
      const keys = new Map(), paths = new Map(rows.map(r => [r.path, r.key])), byKey = new Map(rows.map(r => [r.key, r])), fingerprints = new Map(), aliases = new Set();
      const fingerprint = row => {
        if (!fingerprints.has(row.key)) fingerprints.set(row.key, row.blob.arrayBuffer().then(bytes => crypto.subtle.digest("SHA-256", bytes)).then(bytes => Array.from(new Uint8Array(bytes), b => b.toString(16).padStart(2, "0")).join("")));
        return fingerprints.get(row.key);
      };
      for (const member of [project, ...(project.formProjects || [])]) {
        const oldKey = member.key, newKey = "unit-" + member.targetId + "-" + stamp + "-" + keys.size;
        keys.set(oldKey, newKey); member.key = newKey;
        for (const a of member.assets || []) {
          if (!a || typeof a.key !== "string") throw new Error("This unit contains an invalid resource reference.");
          const imported = paths.get(a.path);
          if (imported) {
            const canonical = keys.get(a.key);
            if (canonical && canonical !== imported) {
              const first = byKey.get(canonical), next = byKey.get(imported);
              if (!first || !next || first.size !== next.size || await fingerprint(first) !== await fingerprint(next)) throw new Error("This unit has conflicting resource references with different file contents.");
              aliases.add(imported);
            } else keys.set(a.key, imported);
          }
          else if (entries.length) throw new Error("This archive is missing an attached unit resource: " + String(a.path));
        }
      }
      const used = new Set(keys.values()); rows = rows.filter(row => !aliases.has(row.key) || used.has(row.key));
      project.libraryOrigin = "uploaded";
      project = JSON.parse(JSON.stringify(project), (key, value) => typeof value === "string" && keys.has(value) ? keys.get(value) : value);
      const saved = await persistProject(project, patch ? { summary: patch, bytes } : null, rows);
      if (!saved || saved.saved !== true) throw new Error("Importing this unit could not be confirmed. Your existing units were kept.");
      return { kind: "project", project, patch };
    },
    async importAnimationBackup() {
      const file = await chooseFile(".zip,application/zip");
      if (!file) return { canceled: true };
      if (file.size > 80 * 1048576) throw new Error("Animation backups must be 80 MiB or smaller.");
      const entries = await unzipResources(new Uint8Array(await file.arrayBuffer()), { maxFiles: 257, maxBytes: 72 * 1048576, noDirectories: true });
      const manifestEntry = entries.find(e => e.path === "animation.json");
      if (!manifestEntry || manifestEntry.bytes.length > 8 * 1048576) throw new Error("This archive has no supported animation backup manifest.");
      let manifest;
      try { manifest = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(manifestEntry.bytes)); } catch (_) { throw new Error("The animation backup manifest is unreadable."); }
      const doc = manifest && manifest.document;
      if (!manifest || manifest.format !== "dokkan-animation-backup" || manifest.version !== 1 || !Array.isArray(manifest.resources) || manifest.resources.length > 256 || !doc || doc.format !== "dokkan-animation-gallery" || doc.version !== 1 || !Array.isArray(doc.assets) || !Array.isArray(doc.animationStudio?.clips)) throw new Error("This archive is not a supported editable animation backup.");
      const files = new Map(entries.map(e => [e.path, e.bytes])), seen = new Set(), validated = []; let total = 0;
      const extension = "png|jpg|jpeg|webp|gif|bmp|lwf|lua|usm|ogg|mp3|m4a|aac|wav|flac|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin";
      const backupPath = new RegExp("^resources/([1-9][0-9]{0,2})\\.(?:" + extension + ")$");
      for (const item of manifest.resources) {
        if (!item || typeof item.path !== "string" || !backupPath.test(item.path) || Number(backupPath.exec(item.path)[1]) > 256 || seen.has(item.path) || !Number.isSafeInteger(item.bytes) || item.bytes < 1 || item.bytes > RESOURCE_LIMIT || typeof item.sha256 !== "string" || !/^[a-f0-9]{64}$/.test(item.sha256)) throw new Error("The animation backup has an invalid or duplicate resource record.");
        seen.add(item.path); total += item.bytes; if (total > RESOURCE_LIMIT) throw new Error("Animation backup resources exceed 64 MiB.");
        const bytes = files.get(item.path);
        if (!bytes || bytes.length !== item.bytes) throw new Error("An animation backup resource is missing or has the wrong size.");
        const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", bytes));
        if (Array.from(digest, b => b.toString(16).padStart(2, "0")).join("") !== item.sha256) throw new Error("An animation backup resource failed its fingerprint check. No resources were imported.");
        validated.push({ path: item.path, bytes });
      }
      if (entries.length !== validated.length + 1 || entries.some(e => e.path !== "animation.json" && !seen.has(e.path))) throw new Error("The animation backup contains unlisted files.");
      for (const asset of doc.assets) if (!asset || typeof asset.key !== "string" || !seen.has(asset.key)) throw new Error("The animation backup references an unlisted attachment.");
      const random = crypto.getRandomValues(new Uint8Array(16)); random[6] = (random[6] & 15) | 64; random[8] = (random[8] & 63) | 128;
      const hex = Array.from(random, b => b.toString(16).padStart(2, "0")).join(""), token = [hex.slice(0, 8), hex.slice(8, 12), hex.slice(12, 16), hex.slice(16, 20), hex.slice(20)].join("-");
      const group = "animation-backup-" + token, rows = validated.map(e => resourceRecord(e.path, e.bytes, group)), resources = {};
      for (const row of rows) resources[row.path] = row.key;
      await holdImportLock(token);
      try { await commitResources(rows, null, { version: 1, token, group, resources: rows.map(row => row.key), createdAt: new Date().toISOString() }); }
      catch (error) { releaseImportLock(token); throw error; }
      return { document: doc, resources, importToken: token };
    },
    async animationImportLeases(a) {
      const valid = row => {
        if (!row || row.version !== 1 || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(row.token || "") || row.group !== "animation-backup-" + row.token || !Array.isArray(row.resources) || row.resources.length > 256 || new Set(row.resources).size !== row.resources.length) throw new Error("This animation import lease is invalid. No files were removed.");
        for (const key of row.resources) if (typeof key !== "string" || !key.startsWith(row.group + "/resources/") || resourcePath(key) !== key) throw new Error("This animation import lease has invalid resource references. No files were removed.");
        return row;
      };
      if (a.action === "pending") {
        const d = await idb(), rows = await req(d.transaction("kv").objectStore("kv").getAll(IDBKeyRange.bound(IMPORT_LEASE_PREFIX, IMPORT_LEASE_PREFIX + "\uffff")));
        const pending = [];
        for (const row of rows.map(valid)) if (await availableImportLease(row)) {
          if (!await get("kv", IMPORT_LEASE_PREFIX + row.token)) { releaseImportLock(row.token); continue; }
          pending.push({ token: row.token, resources: row.resources.slice() });
        }
        return pending;
      }
      if (!["commit", "discard"].includes(a.action) || typeof a.token !== "string" || !/^[0-9a-f-]{36}$/.test(a.token)) throw new Error("Choose a known animation import lease.");
      const finalize = async () => {
      const d = await idb();
      return new Promise((resolve, reject) => {
        const t = d.transaction(["kv", "projects"], "readwrite"), kv = t.objectStore("kv"), lease = kv.get(IMPORT_LEASE_PREFIX + a.token), projects = t.objectStore("projects").getAll(), versions = kv.getAll(IDBKeyRange.bound("versions:", "versions:\uffff"));
        let pending = 3, result, failure;
        const ready = () => {
          if (--pending) return;
          try {
            if (!lease.result) throw new Error("This animation import lease is no longer pending.");
            const row = valid(lease.result); if (row.token !== a.token) throw new Error("Animation import lease identity changed.");
            let referenced = false;
            if (a.action === "discard") {
              const texts = projects.result.map(p => JSON.stringify(p));
              for (const rows of versions.result) { if (!Array.isArray(rows)) throw new Error("Saved version references could not be checked. No resources were removed."); for (const version of rows) { if (typeof version.text !== "string") throw new Error("A saved version could not be checked. No resources were removed."); texts.push(version.text); } }
              referenced = row.resources.some(key => texts.some(text => text.includes(JSON.stringify(key))));
            }
            if (a.action === "discard" && !referenced) for (const key of row.resources) kv.delete(RESOURCE_PREFIX + key);
            kv.delete(IMPORT_LEASE_PREFIX + a.token);
            result = a.action === "commit" ? { committed: true, token: a.token } : { discarded: !referenced, committed: referenced, referenced, token: a.token };
          } catch (error) { failure = error; try { t.abort(); } catch (_) {} }
        };
        lease.onsuccess = projects.onsuccess = versions.onsuccess = ready;
        t.oncomplete = () => resolve(result);
        t.onerror = t.onabort = () => reject(failure || t.error || new Error("Animation import cleanup was interrupted. Its lease and files were kept."));
      });
      };
      if (importLocks.held.has(a.token)) { const result = await finalize(); releaseImportLock(a.token); return result; }
      if (!navigator.locks?.request) throw new Error("This import belongs to another browser window. Its resources were kept because the owner cannot be checked safely.");
      return navigator.locks.request(importLockName(a.token), { mode: "exclusive", ifAvailable: true }, async lock => {
        if (!lock) throw new Error("This animation import is still being saved in another tab. Its files were kept.");
        return finalize();
      });
    },
    async importApk() { throw err("Importing the Eclipse app file needs the Android app."); },
    async copy(a) {
      const text = String(a.text || "");
      try { if (!navigator.clipboard?.writeText) throw new Error("Clipboard unavailable"); await navigator.clipboard.writeText(text); return { copied: true }; }
      catch (_) {
        const t = document.createElement("textarea"); t.value = text; t.setAttribute("aria-label", "Text to copy"); t.style.position = "fixed"; t.style.left = "-10000px"; document.body.append(t); t.focus(); t.select();
        let copied = false; try { copied = document.execCommand("copy") === true; } finally { t.remove(); }
        if (!copied) throw new Error("This browser did not allow clipboard access. Select and copy the visible prompt manually.");
        return { copied: true };
      }
    },
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
      if (a.units && HOSTED) { const list = await cloudList(); for (const r of list || []) if (!await cloudDelete(r.key)) throw new Error("The cloud unit could not be deleted. Try again while connected."); }
      if (a.units || a.files) {
        const d = await idb();
        await new Promise((resolve, reject) => {
          const t = d.transaction(["projects", "patches", "kv"], "readwrite");
          if (a.units) { t.objectStore("projects").clear(); t.objectStore("patches").clear(); t.objectStore("kv").delete(IDBKeyRange.bound("versions:", "versions:\uffff")); }
          if (a.files) { t.objectStore("kv").delete(IDBKeyRange.bound(RESOURCE_PREFIX, RESOURCE_PREFIX + "\uffff")); t.objectStore("kv").delete(IDBKeyRange.bound(IMPORT_LEASE_PREFIX, IMPORT_LEASE_PREFIX + "\uffff")); }
          t.oncomplete = resolve; t.onerror = t.onabort = () => reject(t.error || new Error("Data cleanup was interrupted."));
        });
        if (a.files) { for (const u of assetUrls.values()) URL.revokeObjectURL(u); assetUrls.clear(); for (const token of [...importLocks.held.keys()]) releaseImportLock(token); }
      }
      if (a.settings) { try { localStorage.clear(); } catch (e) {} }
      return { units: !!a.units, files: !!a.files, settings: !!a.settings, web: true };
    },
    async assets(a) {
      const q = String(a.query || "").toLowerCase(), offset = Math.max(0, Math.trunc(Number(a.offset) || 0)), limit = Math.max(1, Math.min(500, Math.trunc(Number(a.limit) || 100)));
      return (await resourceRecords()).filter(r => r.key.toLowerCase().includes(q)).sort((a, b) => a.key.localeCompare(b.key)).slice(offset, offset + limit).map(assetPublic);
    },
    async assetStatus(a) {
      if (!Array.isArray(a.keys) || a.keys.length > 500) throw new Error("Choose up to 500 attached files to check.");
      return Promise.all(a.keys.map(async key => { resourcePath(key); const row = await get("kv", RESOURCE_PREFIX + key); return { key, available: !!(row && row.blob instanceof Blob && row.size === row.blob.size && row.size > 0), bytes: row && row.size || 0 }; }));
    },
    async assetUrl(a) {
      const r = await resource(a.key);
      let mime = "application/octet-stream";
      if (r.image) mime = (await window.__forgeWeb.formats.inspectImage(new Uint8Array(await r.blob.arrayBuffer()), false)).mime;
      if (assetUrls.has(r.key)) return assetUrls.get(r.key);
      const url = URL.createObjectURL(r.blob.slice(0, r.size, mime)); assetUrls.set(r.key, url); return url;
    },
    async readAsset(a) {
      const max = a.maxBytes == null ? 12582912 : a.maxBytes;
      if (!Number.isSafeInteger(max) || max < 1 || max > 12582912) throw new Error("Read up to 12 MiB of a supported resource.");
      const r = await resource(a.key); if (r.size > max) throw new Error("This resource exceeds the requested read limit.");
      const bytes = new Uint8Array(await r.blob.arrayBuffer());
      let info = { width: 0, height: 0, mime: /\.json$/i.test(r.path) ? "application/json" : "application/octet-stream" };
      if (r.image) info = await window.__forgeWeb.formats.inspectImage(bytes, false);
      else if (/\.lwf$/i.test(r.path)) info = window.__forgeWeb.formats.inspectLwf(bytes);
      return { ...info, key: r.key, base64: toBase64(bytes), bytes: bytes.length };
    },
    async storeAsset(a) {
      const bytes = strictBase64(a.data, 12582912), info = await window.__forgeWeb.formats.inspectImage(bytes, true), row = resourceRecord("image.png", bytes, "generated-" + resourceId());
      await commitResources([row]); return { ...assetPublic(row), ...info };
    },
    async storeLwf(a) {
      const bytes = strictBase64(a.data, 12582912), info = window.__forgeWeb.formats.inspectLwf(bytes), row = resourceRecord("animation.lwf", bytes, "generated-" + resourceId());
      await commitResources([row]); return { ...assetPublic(row), ...info };
    },
    async storeDecoration(a) {
      if (typeof a.text !== "string" || a.text.length > 131072) throw new Error("The card decoration metadata is invalid.");
      const bytes = new TextEncoder().encode(a.text); inspectDecoration(bytes);
      const row = resourceRecord("decoration.json", bytes, "generated-" + resourceId()); await commitResources([row]); return { ...assetPublic(row), width: 0, height: 0, mime: "application/json" };
    },
    async browseAssets(a) {
      const path = String(a.path || ""); if (path) resourcePath(path + "/probe.bin");
      const response = await fetch("https://dokkan-eclipse.com/api/file-browser?path=" + encodeURIComponent(path));
      if (!response.ok) throw new Error("The official resource browser returned HTTP " + response.status + ". Import a local ZIP resource pack instead.");
      const data = JSON.parse(new TextDecoder().decode(await limitedBytes(response, 8388608)));
      if (!data || !Array.isArray(data.items) || data.items.length > 50000) throw new Error("The resource folder listing is unreadable.");
      return data;
    },
    async downloadAsset(a) {
      const path = resourcePath(a.path);
      if (a.group != null && !/^art-download-[0-9]{10,16}-[A-Za-z0-9_-]{6,64}$/.test(String(a.group))) throw new Error("Invalid artwork collection.");
      const response = await fetch("https://dokkan-eclipse.com/cdn/uncompressed/" + path.split("/").map(encodeURIComponent).join("/"));
      if (!response.ok || /text\/html/i.test(response.headers.get("content-type") || "")) throw new Error("This game resource could not be downloaded. Import its local resource pack instead.");
      const row = resourceRecord(path, await limitedBytes(response, RESOURCE_LIMIT), a.group || "download-" + resourceId());
      await commitResources([row]); return assetPublic(row);
    },
    async storeMovie(a) {
      const allowed = { begin: ["action", "name"], append: ["action", "uploadId", "offset", "data"], finish: ["action", "uploadId"], cancel: ["action", "uploadId"] }[a.action];
      if (!allowed || Object.keys(a).some(k => !allowed.includes(k))) throw new Error("Invalid movie upload request.");
      const now = Date.now(); for (const [id, job] of movieUploads) if (now - job.touched > 600000) movieUploads.delete(id);
      if (a.action === "begin") {
        if (movieUploads.size >= 2) throw new Error("Finish or cancel another movie upload first.");
        if (a.name != null && (typeof a.name !== "string" || a.name.length > 160 || /[\x00-\x1f\x7f]/.test(a.name))) throw new Error("Choose a readable movie name up to 160 characters.");
        const uploadId = resourceId(); movieUploads.set(uploadId, { parts: [], bytes: 0, name: a.name || "Custom movie", touched: now }); return { uploadId };
      }
      const job = movieUploads.get(a.uploadId); if (!job) throw new Error("This movie upload expired or was canceled. Start it again.");
      if (a.action === "cancel") { movieUploads.delete(a.uploadId); return { canceled: true }; }
      if (a.action === "append") {
        if (a.offset !== job.bytes) throw new Error("Movie chunks must arrive in their original order.");
        const bytes = strictBase64(a.data, 262144);
        if (!bytes.length || job.bytes + bytes.length > RESOURCE_LIMIT || [...movieUploads.values()].reduce((n, j) => n + j.bytes, 0) + bytes.length > RESOURCE_LIMIT) throw new Error("Browser movie uploads are limited to 64 MiB in total.");
        job.parts.push(bytes); job.bytes += bytes.length; job.touched = now; return { bytes: job.bytes };
      }
      try {
        const blob = new Blob(job.parts), info = await window.__forgeWeb.formats.inspectUsm(blob), row = resourceRecord("movie.usm", new Uint8Array(await blob.arrayBuffer()), "generated-movie-" + resourceId());
        await commitResources([row]); return { ...assetPublic(row), ...info, name: job.name, storageTag: resourceId().replace(/-/g, "") };
      } finally { movieUploads.delete(a.uploadId); }
    },
    async patchesStatus() { return {}; },
    async importStatus() { return {}; },
    async aiConnections() { return { connections: [], active: "", web: true, mode: "copy-paste" }; },
    async ai(a) {
      const providers = { chatgpt: ["ChatGPT", "https://chatgpt.com/"], claude: ["Claude", "https://claude.ai/"], grok: ["Grok", "https://grok.com/"], gemini: ["Gemini", "https://gemini.google.com/"], copilot: ["Copilot", "https://copilot.microsoft.com/"] };
      if (!a.provider) return Object.entries(providers).map(([id, p]) => ({ id, name: p[0], installed: false, web: true }));
      const provider = providers[String(a.provider).toLowerCase()]; if (!provider) throw new Error("Choose one of the listed AI assistants.");
      openLink(provider[1]); return { requested: true, provider: provider[0], transport: "website" };
    },
    async aiCompose(a) {
      const provider = String(a.provider || "").toLowerCase(), prompt = a.prompt;
      if (!["chatgpt", "claude", "grok", "gemini", "copilot"].includes(provider)) throw new Error("Choose one of the listed AI assistants.");
      if (typeof prompt !== "string" || !prompt.trim() || prompt.length > 64000 || prompt.includes("\u0000")) throw new Error("Use a readable prompt between 1 and 64,000 characters.");
      // Start both from the user's tap so phone browsers retain clipboard and popup activation.
      const copy = handlers.copy({ text: prompt }), launch = handlers.ai({ provider });
      const [copied, requested] = await Promise.all([copy, launch]);
      return { ...requested, copied: copied.copied };
    },
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
  window.__forgeWeb = { query, table, getManifest, handlers, cloud, hosted: HOSTED, resourceStore: { list: resourceRecords, read: resource, path: resourcePath, record: resourceRecord, commit: commitResources, limitedBytes, id: resourceId, get, put, del, idb, req, prefix: RESOURCE_PREFIX } };
  document.documentElement.classList.add("web-version");
})();
