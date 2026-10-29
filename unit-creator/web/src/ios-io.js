/* iPhone app: import and export exactly like the Android app (CreatorActivity.importUri/writeExport,
 * importEclp, importArchive, importEclipseApk, expandCpkResources, patches). Files come from the
 * iPhone's file picker; saving uses the iPhone's Save dialog. */
(function () {
  "use strict";
  const IOS = window.__forgeIOS;
  if (!IOS || !IOS.formats) return;
  const { host, H, formats: F } = IOS;
  const fail = (m) => new Error(m);
  const MiB = 1048576, GiB = 1073741824;
  const enc = new TextEncoder(), dec = new TextDecoder();
  const A = "assets/";
  const isoNow = () => new Date().toISOString();
  const safePath = IOS.safePath;

  // ---------------------------------------------------------------- ZIP reading straight from the picked file (no full copy in memory)
  async function zipEntries(blob) {
    const size = blob.size, tailLen = Math.min(size, 65557), tail = new Uint8Array(await blob.slice(size - tailLen).arrayBuffer());
    let e = -1;
    for (let i = tail.length - 22; i >= 0; i--) if (tail[i] === 0x50 && tail[i + 1] === 0x4b && tail[i + 2] === 5 && tail[i + 3] === 6) { e = i; break; }
    if (e < 0) throw fail("Not a ZIP archive");
    const dv = new DataView(tail.buffer);
    let count = dv.getUint16(e + 10, true), cdSize = dv.getUint32(e + 12, true), cdOff = dv.getUint32(e + 16, true);
    if (count === 0xffff || cdOff === 0xffffffff) {   // ZIP64
      const loc = e - 20;
      if (loc < 0 || dv.getUint32(loc, true) !== 0x07064b50) throw fail("Not a ZIP archive");
      const z64 = Number(dv.getBigUint64(loc + 8, true));
      const r = new DataView(await blob.slice(z64, z64 + 56).arrayBuffer());
      count = Number(r.getBigUint64(32, true)); cdSize = Number(r.getBigUint64(40, true)); cdOff = Number(r.getBigUint64(48, true));
    }
    if (count > 100000) throw fail("Archive contains too many entries");
    const cd = new Uint8Array(await blob.slice(cdOff, cdOff + cdSize).arrayBuffer()), c = new DataView(cd.buffer);
    const out = []; let p = 0;
    for (let n = 0; n < count; n++) {
      if (c.getUint32(p, true) !== 0x02014b50) throw fail("Damaged ZIP directory");
      const method = c.getUint16(p + 10, true), crc = c.getUint32(p + 16, true);
      let csize = c.getUint32(p + 20, true), usize = c.getUint32(p + 24, true);
      const nl = c.getUint16(p + 28, true), xl = c.getUint16(p + 30, true), cl = c.getUint16(p + 32, true);
      let lho = c.getUint32(p + 42, true);
      const name = dec.decode(cd.subarray(p + 46, p + 46 + nl));
      let x = p + 46 + nl;
      const xe = x + xl;
      while (x + 4 <= xe) {
        const id = c.getUint16(x, true), len = c.getUint16(x + 2, true);
        if (id === 1) { let q = x + 4; if (usize === 0xffffffff) { usize = Number(c.getBigUint64(q, true)); q += 8; } if (csize === 0xffffffff) { csize = Number(c.getBigUint64(q, true)); q += 8; } if (lho === 0xffffffff) lho = Number(c.getBigUint64(q, true)); }
        x += 4 + len;
      }
      out.push({ name, method, crc, csize, usize, lho, dir: name.endsWith("/") });
      p = xe + cl;
    }
    return out;
  }
  async function zipData(blob, e) {
    const h = new DataView(await blob.slice(e.lho, e.lho + 30).arrayBuffer());
    if (h.getUint32(0, true) !== 0x04034b50) throw fail("Damaged ZIP entry");
    const start = e.lho + 30 + h.getUint16(26, true) + h.getUint16(28, true);
    const raw = blob.slice(start, start + e.csize);
    if (e.method === 0) return raw;
    if (e.method !== 8) throw fail("Unsupported ZIP compression");
    const out = await new Response(raw.stream().pipeThrough(new DecompressionStream("deflate-raw"))).blob();
    if (out.size !== e.usize) throw fail("The APK inside this ZIP is incomplete or corrupted. Download the original ZIP again.");
    return out;
  }
  IOS.zipEntries = zipEntries; IOS.zipData = zipData;

  // ---------------------------------------------------------------- Android binary XML (package name, versions)
  function axmlManifest(b) {
    const dv = new DataView(b.buffer, b.byteOffset, b.byteLength);
    let strings = [], p = 8;
    const out = {};
    while (p + 8 <= b.length) {
      const type = dv.getUint16(p, true), hsize = dv.getUint16(p + 2, true), size = dv.getUint32(p + 4, true);
      if (size < 8) break;
      if (type === 0x0001) {
        const n = dv.getUint32(p + 8, true), flags = dv.getUint32(p + 16, true), sStart = dv.getUint32(p + 20, true), utf8 = !!(flags & 256);
        for (let i = 0; i < n; i++) {
          let q = p + sStart + dv.getUint32(p + hsize + i * 4, true);
          if (utf8) { let l = b[q++]; if (l & 0x80) q++; l = b[q++]; if (l & 0x80) l = ((l & 0x7f) << 8) | b[q++]; strings.push(dec.decode(b.subarray(q, q + l))); }
          else { let l = dv.getUint16(q, true); q += 2; if (l & 0x8000) { l = ((l & 0x7fff) << 16) | dv.getUint16(q, true); q += 2; } let s = ""; for (let k = 0; k < l; k++) s += String.fromCharCode(dv.getUint16(q + k * 2, true)); strings.push(s); }
        }
      } else if (type === 0x0102) {
        const name = strings[dv.getUint32(p + 20, true)];
        if (name === "manifest") {
          const as = dv.getUint16(p + 24, true), asz = dv.getUint16(p + 26, true) || 20, ac = dv.getUint16(p + 28, true);
          let q = p + 16 + as;
          for (let i = 0; i < ac; i++, q += asz) {
            const an = strings[dv.getUint32(q + 4, true)], raw = dv.getInt32(q + 8, true), vtype = b[q + 15], data = dv.getInt32(q + 16, true);
            out[an] = raw >= 0 ? strings[raw] : vtype === 3 ? strings[data] : data;
          }
          return out;
        }
      }
      p += type === 0x0003 ? hsize : size;
    }
    return out;
  }
  IOS.axmlManifest = axmlManifest;

  // ---------------------------------------------------------------- import progress (Android: importProgress, polled by importStatus)
  const progress = (phase, label, bytes, total) => IOS.progress(phase, label, bytes, total);

  // ---------------------------------------------------------------- patches (imported .eclp files): patches/<uuid>.{eclp,json}
  const PATCH = /^[a-f0-9-]{36}$/;
  const webPatches = { patches: H.patches, deletePatch: H.deletePatch };
  H.patches = async function () {
    const out = [];
    for (const f of await host.list("patches")) {
      if (f.dir || !/\.json$/.test(f.name) || f.size > 20 * MiB) continue;
      try { out.push(JSON.parse(await host.readText("patches/" + f.name))); } catch (e) {}
    }
    try { for (const p of (await webPatches.patches()) || []) out.push(p); } catch (e) {}   // from the first iPhone build
    return out;
  };
  H.deletePatch = async function (a) {
    const key = String(a.key || "");
    if (!PATCH.test(key)) { if (/^patch-/.test(key)) return webPatches.deletePatch(a); throw fail("Invalid patch key"); }
    const has = (await host.exists("patches/" + key + ".eclp")) || (await host.exists("patches/" + key + ".json"));
    if (!has) throw fail("This patch is no longer saved on this device.");
    try { await host.remove("patches/" + key + ".eclp"); await host.remove("patches/" + key + ".json"); } catch (e) { throw fail("Could not delete this patch. Try again."); }
    return { deleted: true, key };
  };

  // ---------------------------------------------------------------- export
  let fflateReady = null;
  function fflate() {
    if (window.fflate) return Promise.resolve(window.fflate);
    if (!fflateReady) fflateReady = new Promise((res, rej) => { const s = document.createElement("script"); s.src = "vendor/fflate.js"; s.onload = () => res(window.fflate); s.onerror = () => rej(fail("Cannot prepare this ZIP.")); document.head.append(s); });
    return fflateReady;
  }
  async function entryBytes(e) {
    if (e.cpk) {
      if (!/\.cpk$/i.test(e.path) || "assetKey" in e || "text" in e) throw fail("Invalid packed artwork entry.");
      const files = [];
      for (const x of e.cpk) {
        if (!IOS.assetSafe(x.assetKey)) throw fail("CPK: Invalid imported asset key.");
        const b = await host.readBytes(A + x.assetKey);
        if (!b || b.length > 160 * MiB) throw fail("CPK: Missing or oversized imported asset.");
        files.push({ path: x.path, data: b });
      }
      return window.ForgeCpk.encode(files);
    }
    if (e.assetKey != null) {
      if (!safePath(e.assetKey)) throw fail("Invalid asset key");
      const b = await host.readBytes(A + e.assetKey);
      if (!b) throw fail("Unsafe path");
      return b;
    }
    return enc.encode(e.text == null ? "" : String(e.text));
  }
  async function saveExport(name, bytes) {
    const safeName = String(name || "custom-unit.json").replace(/[\\/:*?"<>|\x00-\x1f]+/g, "_") || "custom-unit.json";
    const path = "cache/exports/" + safeName;
    await host.remove("cache/exports").catch(() => {});
    await host.writeBytes(path, bytes);
    try {
      const r = await host.call("saveDocument", { path, name: safeName });
      return r.saved ? { saved: true, name: String(name == null ? "" : name) } : {};
    } finally { host.remove("cache/exports").catch(() => {}); }
  }
  const webExport = H.export;
  H.export = async function (a) {
    const kind = a.kind;
    let bytes;
    if (kind === "eclp" && a.patchKey != null) {
      if (!PATCH.test(String(a.patchKey))) { if (/^patch-/.test(String(a.patchKey))) return webExport(a); throw fail("Invalid patch key"); }
      bytes = await host.readBytes("patches/" + a.patchKey + ".eclp");
      if (!bytes) throw fail("This patch is no longer saved on this device.");
    } else if (kind === "eclp" || kind === "zip") {
      const entries = Array.isArray(a.entries) ? a.entries : [];
      const seen = new Set(), files = [];
      for (const e of entries) {
        if (!safePath(e.path) || seen.has(e.path)) throw fail(kind === "zip" ? "Invalid or duplicate patch path" : "Unsafe or duplicate ECLP path.");
        seen.add(e.path);
        files.push({ path: e.path, bytes: await entryBytes(e) });
      }
      if (kind === "zip") {
        const z = await fflate(), obj = {};
        for (const f of files) obj[f.path] = [f.bytes, { level: 6 }];
        bytes = z.zipSync(obj);
      } else {
        let meta = a.metadata && typeof a.metadata === "object" ? a.metadata : null;
        if (!meta) { const m = files.find((f) => f.path === "metadata.json"); if (m) meta = JSON.parse(dec.decode(m.bytes)); }
        if (!meta) throw fail("Missing ECLP metadata");
        for (const k of ["uuid", "name", "version"]) if (!meta[k] || !String(meta[k]).trim() || String(meta[k]).length > 1000) throw fail("Patch UUID, name, and version are required (maximum 1,000 characters)");
        const list = files.some((f) => f.path === "metadata.json") ? files : [{ path: "metadata.json", bytes: enc.encode(JSON.stringify(meta)) }].concat(files);
        bytes = await window.ForgeEclp.write(list, { deriveKey: IOS.deriveKey });
      }
    } else {
      bytes = enc.encode(a.text == null ? "" : String(a.text));
    }
    if (bytes.length > 4 * GiB) throw fail("Export exceeds the 4 GB output limit.");
    return saveExport(a.name, bytes);
  };

  // ---------------------------------------------------------------- "Import to Eclipse / Sparking" (end of a unit)
  // Neither game accepts files from another app (no document types, no share target), but both share their
  // Documents folder in Files (On My iPhone › Sparking / Eclipse), and both import from there with their own
  // picker. So: the person links the game's folder once (iPhone folder picker → security-scoped bookmark, Player.m
  // gameFolder*), and from then on the unit is saved straight into it and the game opens. Without a linked folder
  // the save sheet is used. The same unit sent twice gives the same .sprk file (IV from its SHA-256), which the
  // app recognises: no second copy. docs/SEND-TO-GAME.md has the details.
  const GAME_FOLDER = { sparking: /spark/i, eclipse: /eclipse|eclp/i };
  // What a unit's patch contains, ignoring the export time written into its SQL (FNV-1a over every file).
  function contentSignature(files) {
    let h1 = 0x811c9dc5 >>> 0, h2 = 0x01000193 >>> 0;
    const add = (bytes) => { for (let i = 0; i < bytes.length; i++) { h1 = Math.imul(h1 ^ bytes[i], 16777619) >>> 0; h2 = Math.imul(h2 ^ bytes[i], 2246822519) >>> 0; } };
    for (const f of files.slice().sort((x, y) => (x.path < y.path ? -1 : 1))) {
      add(enc.encode(f.path + "\0"));
      add(/\.sql$/i.test(f.path) || f.path === "metadata.json" ? enc.encode(dec.decode(f.bytes).replace(/\d{4}-\d\d-\d\d[ T]\d\d:\d\d:\d\d(\.\d+)?Z?/g, "").replace(/"created"\s*:\s*\d+/g, "")) : f.bytes);
    }
    return h1.toString(16) + h2.toString(16) + ":" + files.length;
  }
  // the unit's own ID ends every export name ("Goku-97001001.sprk"): a rename only replaces a file of the same unit
  const idOf = (n) => (/-(\d{5,})\.(sprk|eclp)$/i.exec(String(n || "")) || [])[1] || "";
  H.gameFolderStatus = async (a) => { const r = await host.call("gameFolderStatus", { game: a.target }); return Object.assign(r, { looksRight: !r.name || GAME_FOLDER[a.target].test(r.name) }); };
  H.linkGameFolder = async (a) => { const r = await host.call("gameFolderLink", { game: a.target }); if (IOS.resetFolderMemo) IOS.resetFolderMemo(); return Object.assign(r, { looksRight: !r.name || GAME_FOLDER[a.target].test(r.name) }); };
  H.unlinkGameFolder = (a) => { if (IOS.resetFolderMemo) IOS.resetFolderMemo(); return host.call("gameFolderUnlink", { game: a.target }); };
  H.sendToGame = async function (a) {
    const target = a && a.target, req = (a && a.request) || {};
    if (target !== "eclipse" && target !== "sparking") throw fail("Choose Eclipse or Sparking.");
    const base = String(req.name || "My unit").replace(/\.(eclp|zip|sprk)$/i, "").replace(/[\\/:*?"<>|\x00-\x1f]+/g, " ").replace(/^[.\s]+/, "").trim().slice(0, 80) || "My unit";
    let folder = null;
    if (!a.useSheet) {
      folder = await host.call("gameFolderStatus", { game: target }).catch(() => null);
      if (folder && (!folder.linked || !folder.ok)) return { needsFolder: true, target, lost: !!folder.linked };
    }
    const entries = Array.isArray(req.entries) ? req.entries : [], seen = new Set(), files = [];
    for (const e of entries) {
      if (!safePath(e.path) || seen.has(e.path)) throw fail("Unsafe or duplicate patch path.");
      seen.add(e.path);
      files.push({ path: e.path, bytes: await entryBytes(e) });
    }
    let bytes, name;
    const stage = "cache/send-" + IOS.uuid4() + "/";
    try {
      if (target === "eclipse") {
        const m = files.find((f) => f.path === "metadata.json");
        if (!m) throw fail("Missing ECLP metadata");
        bytes = await window.ForgeEclp.write(files, { deriveKey: IOS.deriveKey });
        name = base + ".eclp";
      } else {
        // Sparking's patch layout: patch_info.json, patches/sql/*.sql, patches/assets/*. Sparking 6.6 requires
        // a whole-number creator_id (0 = no creator group) and a text creator_name.
        const m = files.find((f) => f.path === "metadata.json");
        let meta = {}; try { meta = m ? JSON.parse(dec.decode(m.bytes)) : {}; } catch (e) {}
        const z = await fflate(), obj = {}, opt = { level: 6, mtime: new Date(1980, 0, 1) };
        const info = { name: String(meta.name || base).slice(0, 120), version: String(meta.version || "1.0"), description: String(meta.description || ""), creator_id: 0, creator_name: String(meta.author || "Dokkan Unit Creator").slice(0, 80), created_with: "Dokkan Unit Creator" };
        obj["patch_info.json"] = [enc.encode(JSON.stringify(info, null, 2)), opt];
        obj["patches/"] = [new Uint8Array(0), opt]; obj["patches/sql/"] = [new Uint8Array(0), opt];   // folder entries
        let sql = 0;
        for (const f of files) {
          if (!f.path.startsWith("files/")) continue;
          const rel = f.path.slice(6);
          if (/\.sql$/i.test(rel)) {
            if (!f.bytes.length) throw fail("This unit's game data is empty.");
            obj["patches/sql/" + rel.replace(/^sparking-sql\//, "")] = [f.bytes, opt]; sql++;
          } else obj["patches/assets/" + rel] = [f.bytes, opt];
        }
        if (!sql) throw fail("This unit has no game data to send to Sparking.");
        await host.writeBytes(stage + "patch.zip", z.zipSync(obj));
        const sum = await host.call("sha256", { path: stage + "patch.zip" });
        await host.call("sprkEncode", { path: stage + "patch.zip", to: stage + "patch.sprk", iv: String(sum.sha256 || "").slice(0, 32) });
        name = base + ".sprk";
      }
      if (folder) {
        if (target === "eclipse") await host.writeBytes(stage + "patch.sprk", bytes);
        // Remember what was sent for this unit: the same content again (export timestamps aside) keeps the file
        // that's already there; a renamed unit replaces its old file instead of leaving a second copy.
        const memo = "forge-sent-" + target + "-" + String(a.unitKey || base), sig = contentSignature(files);
        let last = null; try { last = JSON.parse(localStorage.getItem(memo) || "null"); } catch (e) {}
        const w = await host.call("gameFolderWrite", { game: target, path: stage + "patch.sprk", name,
          onlyIfMissing: !!(last && last.file === name && last.sig === sig), replaces: last && last.file !== name && idOf(last.file) && idOf(last.file) === idOf(name) ? last.file : "" });
        if (!w.linked) return { needsFolder: true, target, lost: true };
        try { localStorage.setItem(memo, JSON.stringify({ file: name, sig })); } catch (e) {}
        let opened = false;
        try { opened = Boolean((await host.openURL("dbzdokkanww://jp.co.bandainamcogames.BNGI0221")) !== false); } catch (e) {}
        return { saved: true, direct: true, same: !!w.same, replaced: (!!w.existed && !w.same) || !!w.removedOld, opened, file: name, folder: "On My iPhone › " + (w.folder || (target === "eclipse" ? "Eclipse" : "Sparking")) };
      }
      if (!bytes) bytes = await host.readBytes(stage + "patch.sprk");
    } finally { await host.remove(stage).catch(() => {}); }
    const r = await saveExport(name, bytes);
    if (!r.saved) return { saved: false };
    let opened = false;
    try { opened = Boolean((await host.openURL("dbzdokkanww://jp.co.bandainamcogames.BNGI0221")) !== false); } catch (e) {}
    return { saved: true, opened, file: name, folder: target === "eclipse" ? "On My iPhone › Eclipse" : "Files" };
  };

  // ---------------------------------------------------------------- import
  const RESOURCE = /\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|m4a|aac|flac|awb|acb|atlas|plist|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$/i;
  const ARCHIVE_RES = /\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$/i;
  const SEGMENTS = new Set(["character", "lua", "ingame", "layout", "bgm", "movie", "card_transform", "card_metamorphic", "card_category", "card_costume", "dokkan_field", "origin", "outgame", "item", "comic_text", "fonts", "shader", "se", "voice", "tutorial0"]);
  function normalizeAsset(p) {
    const parts = p.split("/");
    const i = parts.findIndex((s) => SEGMENTS.has(s));
    if (i >= 0) return parts.slice(i).join("/");
    return p.replace(/^(assets|files|uncompressed)\//, "");
  }
  async function head(blob, n) { return new Uint8Array(await blob.slice(0, n).arrayBuffer()); }
  async function chooseFile(apk, animation = false) {
    progress("select", animation ? "Choose an animation backup ZIP" : apk ? "Choose the latest Eclipse APK" : "Choose a file to import");
    return new Promise((resolve) => {
      const d = document.createElement("dialog");
      d.className = "web-file-dialog";
      d.innerHTML = "<h2>" + (animation ? "Import an animation backup" : apk ? "Import the Eclipse APK" : "Import a file") + "</h2><p>" + (animation ? "Choose the animation ZIP you saved from My animations. Its clips and attached files are restored together; your units stay saved." : apk ? "Choose the latest Eclipse Android APK (com.anthen.eclipse) from Files." : "Choose a unit (.json or .sql), an ECLP or SPRK patch, a game database, a picture or game file, a ZIP, or an APK.") +
        '</p><label class="button web-file-button">📁 Choose a file<input type="file" hidden></label><button type="button" class="button ghost">Cancel</button>';
      document.body.append(d);
      const input = d.querySelector("input");
      if (animation) input.accept = '.zip,application/zip';
      const done = (f) => { d.close(); d.remove(); resolve(f || null); };
      input.onchange = () => done(input.files && input.files[0]);
      d.querySelector(".ghost").onclick = () => done(null);
      d.addEventListener("cancel", () => done(null));
      d.showModal();
    });
  }
  let picking = false;
  async function pickAndImport(apkMode) {
    if (picking) throw fail("Finish the existing file picker first.");
    picking = true;
    let file;
    try { file = await chooseFile(apkMode); } finally { picking = false; }
    if (!file) return {};
    if (file.size > 4 * GiB) throw fail("File exceeds the supported import size.");
    return importFile(file, file.name || "import", apkMode);
  }
  H.import = () => pickAndImport(false);
  // a text file (.sql) for "Import a .sql file": its text goes to the app's own reader (sql-import.js)
  H.pickTextFile = async () => {
    if (picking) throw fail("Finish the existing file picker first.");
    picking = true; let file;
    try { file = await chooseFile(false); } finally { picking = false; }
    if (!file) return {};
    if (file.size > 64 * MiB) throw fail("This .sql file is too large (over 64 MB).");
    return { name: file.name || "unit.sql", text: await file.text() };
  };
  // A portable animation backup has no unit/database import route and no executable SQL entries.
  const animationResource = (p) => /^resources\/[1-9][0-9]{0,2}\.(png|jpg|jpeg|webp|gif|bmp|lwf|lua|usm|ogg|mp3|m4a|aac|wav|flac|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$/.test(p) && Number(p.split('/')[1].split('.')[0]) <= 256;
  async function animationEntries(file) {
    if (file.size > 80 * MiB || file.size < 22) throw fail('Choose an animation ZIP up to 80 MiB.');
    const tail = new Uint8Array(await file.slice(Math.max(0, file.size - 65557)).arrayBuffer()), dv = new DataView(tail.buffer);
    let end = -1;
    for (let i = tail.length - 22; i >= 0; i--) if (dv.getUint32(i, true) === 0x06054b50 && i + 22 + dv.getUint16(i + 20, true) === tail.length) { end = i; break; }
    if (end < 0 || dv.getUint16(end + 4, true) || dv.getUint16(end + 6, true) || dv.getUint16(end + 8, true) !== dv.getUint16(end + 10, true)) throw fail('Invalid animation ZIP directory.');
    const count = dv.getUint16(end + 10, true), size = dv.getUint32(end + 12, true), offset = dv.getUint32(end + 16, true);
    if (count < 1 || count > 257 || offset + size !== file.size - tail.length + end || size > 256 * 1024) throw fail('Animation ZIP entries or ZIP64 are not supported.');
    const directory = new Uint8Array(await file.slice(offset, offset + size).arrayBuffer()), view = new DataView(directory.buffer), entries = [], names = new Set(); let at = 0;
    for (let i = 0; i < count; i++) {
      if (at + 46 > directory.length || view.getUint32(at, true) !== 0x02014b50) throw fail('Invalid animation ZIP entry.');
      const flags = view.getUint16(at + 8, true), method = view.getUint16(at + 10, true), mode = view.getUint32(at + 38, true) >>> 16 & 0xf000, nl = view.getUint16(at + 28, true), xl = view.getUint16(at + 30, true), cl = view.getUint16(at + 32, true);
      if ((flags & ~0x808) || ![0, 8].includes(method) || ![0, 0x8000].includes(mode) || view.getUint16(at + 34, true) || nl < 1 || nl > 200 || at + 46 + nl + xl + cl > directory.length) throw fail('Animation ZIP contains linked, encrypted or unsupported entries.');
      const name = new TextDecoder('utf-8', { fatal: true }).decode(directory.subarray(at + 46, at + 46 + nl)), canonical = name.normalize('NFC').toLowerCase();
      if ((name !== 'animation.json' && !animationResource(name)) || names.has(canonical)) throw fail('Animation ZIP contains duplicate or unexpected paths.');
      names.add(canonical); entries.push({ name, flags, method, crc: view.getUint32(at + 16, true), csize: view.getUint32(at + 20, true), usize: view.getUint32(at + 24, true), lho: view.getUint32(at + 42, true), directory: offset });
      at += 46 + nl + xl + cl;
    }
    if (at !== directory.length) throw fail('Invalid animation ZIP entry count.'); return entries;
  }
  async function animationBytes(file, entry, limit) {
    if (entry.usize < 1 || entry.usize > limit || entry.lho + 30 > entry.directory) throw fail('Animation resource exceeds its size limit.');
    const h = new DataView(await file.slice(entry.lho, entry.lho + 30).arrayBuffer());
    if (h.getUint32(0, true) !== 0x04034b50 || h.getUint16(6, true) !== entry.flags || h.getUint16(8, true) !== entry.method) throw fail('Damaged animation ZIP entry.');
    const nl = h.getUint16(26, true), start = entry.lho + 30 + nl + h.getUint16(28, true);
    if (start + entry.csize > entry.directory || new TextDecoder('utf-8', { fatal: true }).decode(await file.slice(entry.lho + 30, entry.lho + 30 + nl).arrayBuffer()) !== entry.name) throw fail('Conflicting animation ZIP entry.');
    const chunks = []; let total = 0, crc = -1;
    const append = (chunk) => { total += chunk.length; if (total > limit || total > entry.usize) throw fail('Animation resource expands beyond its limit.'); for (const byte of chunk) { crc ^= byte; for (let k = 0; k < 8; k++) crc = crc >>> 1 ^ (crc & 1 ? 0xedb88320 : 0); } chunks.push(chunk.slice()); };
    if (!entry.method) { for (let p = 0; p < entry.csize; p += 65536) append(new Uint8Array(await file.slice(start + p, start + Math.min(entry.csize, p + 65536)).arrayBuffer())); }
    else { const z = await fflate(), inflate = new z.Inflate(append); for (let p = 0; p < entry.csize; p += 65536) inflate.push(new Uint8Array(await file.slice(start + p, start + Math.min(entry.csize, p + 65536)).arrayBuffer()), p + 65536 >= entry.csize); }
    if (total !== entry.usize || (crc ^ -1) >>> 0 !== entry.crc) throw fail('Animation resource failed its size or CRC check.');
    const bytes = new Uint8Array(total); let p = 0; for (const chunk of chunks) { bytes.set(chunk, p); p += chunk.length; } return bytes;
  }
  const importToken = /^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/, leaseRoot = 'animation-import-leases/';
  async function animationLease(token) {
    if (!importToken.test(token || '')) throw fail('Invalid animation import token.');
    const path = leaseRoot + token + '.json', info = await host.stat(path);
    if (!info || info.dir || info.size > 128 * 1024) throw fail('Animation import journal is missing or invalid.');
    const lease = await host.readJson(path);
    if (lease?.version !== 1 || lease.token !== token || !Array.isArray(lease.resources) || lease.resources.length > 256 || new Set(lease.resources).size !== lease.resources.length || lease.resources.some(key => typeof key !== 'string' || !key.startsWith('import-' + token + '/') || !/^[1-9][0-9]{0,2}\.[a-z0-9]{1,8}$/.test(key.slice(44)))) throw fail('Animation import journal contains unsafe resources.');
    return lease;
  }
  H.animationImportLeases = async ({ action = 'pending', token } = {}) => {
    if (action === 'pending') {
      const result = [];
      for (const file of await host.list(leaseRoot)) if (!file.dir && importToken.test(file.name.replace(/\.json$/, '')) && file.name.endsWith('.json')) { const lease = await animationLease(file.name.slice(0, 36)); result.push({ token: lease.token, resources: lease.resources }); }
      return result;
    }
    const lease = await animationLease(token);
    if (action === 'commit') { await host.remove(leaseRoot + token + '.json'); return { committed: true }; }
    if (action !== 'discard') throw fail('Unknown animation import lease action.');
    let count = 0, total = 0;
    for (const directory of ['projects', 'project-versions']) for (const file of await host.list(directory, true)) {
      if (file.dir || !/\.(json|version)$/.test(file.name)) continue;
      if (!safePath(file.name) || ++count > 50000 || file.size > 21 * MiB || (total += file.size) > 512 * MiB) throw fail('Saved unit references could not be checked safely; pending resources were kept.');
      const bytes = await host.readBytes(directory + '/' + file.name); if (!bytes || bytes.length !== file.size) throw fail('A saved unit reference could not be read; pending resources were kept.');
      if (new TextDecoder().decode(bytes).includes('import-' + token)) { await host.remove(leaseRoot + token + '.json'); return { discarded: false, committed: true, referenced: true }; }
    }
    const names = new Set(lease.resources.map(key => key.slice(key.lastIndexOf('/') + 1))), folders = [A + 'import-' + token, 'cache/animation-import-' + token];
    for (const folder of folders) {
      const info = await host.stat(folder); if (!info) continue; if (!info.dir) throw fail('A pending animation folder changed; its files were kept.');
      const files = await host.list(folder);
      if (files.some(file => file.dir || !names.has(file.name))) throw fail('A pending animation folder contains other files; they were kept.');
      await host.remove(folder);
    }
    await host.remove(leaseRoot + token + '.json'); IOS.invalidateAssets(); return { discarded: true };
  };
  H.importAnimationBackup = async () => {
    if (picking) throw fail('Finish the existing file picker first.');
    picking = true; let file;
    try { file = await chooseFile(false, true); } finally { picking = false; }
    if (!file) return { canceled: true };
    const entries = await animationEntries(file), entry = entries.find(e => e.name === 'animation.json');
    if (!entry) throw fail('Animation backup metadata is missing.');
    const manifest = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(await animationBytes(file, entry, 8 * MiB))), doc = manifest.document;
    if (manifest.format !== 'dokkan-animation-backup' || manifest.version !== 1 || doc?.format !== 'dokkan-animation-gallery' || doc.version !== 1 || !Array.isArray(doc.assets) || !Array.isArray(manifest.resources) || manifest.resources.length > 256 || entries.length !== manifest.resources.length + 1) throw fail('This is not a supported animation backup.');
    const seen = new Set(); let total = 0;
    for (const r of manifest.resources) { if (!animationResource(r.path) || seen.has(r.path) || !Number.isSafeInteger(r.bytes) || r.bytes < 1 || r.bytes > 64 * MiB || !/^[a-f0-9]{64}$/.test(r.sha256) || (total += r.bytes) > 64 * MiB || !entries.some(e => e.name === r.path && e.usize === r.bytes)) throw fail('Invalid or oversized animation resource metadata.'); seen.add(r.path); }
    if (doc.assets.some(a => !seen.has(a.key))) throw fail('An attached animation resource is missing from this backup.');
    if ((await H.animationImportLeases({ action: 'pending' })).length >= 64) throw fail('Finish pending animation imports before importing another backup.');
    const token = IOS.uuid4(), group = 'import-' + token, stage = 'cache/animation-import-' + token, resources = {}; let committed = false, leased = false;
    for (const r of manifest.resources) resources[r.path] = group + '/' + r.path.slice(10);
    try {
      if (await host.exists(leaseRoot + token + '.json')) throw fail('Animation import token already exists.');
      await host.writeJson(leaseRoot + token + '.json', { version: 1, token, resources: Object.values(resources) }); leased = true;
      await host.mkdir(stage);
      for (const r of manifest.resources) { const bytes = await animationBytes(file, entries.find(e => e.name === r.path), r.bytes); if (await IOS.sha256Hex(bytes) !== r.sha256) throw fail('An animation resource failed its SHA-256 check.'); const name = r.path.slice(10); await host.writeBytes(stage + '/' + name, bytes); }
      if (await host.exists(A + group)) throw fail('Animation resource destination already exists.');
      await host.move(stage, A + group); committed = true; IOS.invalidateAssets();
      return { document: doc, resources, importToken: token };
    } finally { if (!committed) { if (leased) await H.animationImportLeases({ action: 'discard', token }); else await host.remove(stage).catch(() => {}); } }
  };
  H.importApk = () => pickAndImport(true);
  IOS.importFile = (file, name) => importFile(file, name || file.name, false);

  async function importFile(file, name, apkMode) {
    const lower = name.toLowerCase();
    if (apkMode || lower.endsWith(".apk")) {
      const entries = await zipEntries(file).catch(() => null);
      if (entries) {
        const pkg = await apkPackage(file, entries);
        if (pkg && pkg.package === "com.sparkingDokkan.GLB" && IOS.importSparkingApk) return IOS.importSparkingApk(file, name, entries);
        if (entries.some((e) => e.name === "assets/patcher/maps/android_current.json")) return importEclipseApk(file, name, entries, pkg);
        if (apkMode) throw fail("Choose the Eclipse Android APK (com.anthen.eclipse). The selected app was not installed or run.");
      } else if (apkMode) throw fail("Choose the Eclipse Android APK (com.anthen.eclipse). The selected app was not installed or run.");
    }
    if (lower.endsWith(".sql")) {
      if (file.size > 64 * MiB) throw fail("This .sql file is too large (over 64 MB).");
      return { kind: "sql", name, text: await file.text() };
    }
    if (lower.endsWith(".json")) {
      let p; try { p = JSON.parse(await file.text()); } catch (e) { p = null; }
      if (!p || p.format !== "dokkan-unit-forge") throw fail("This JSON is not a Dokkan Unit Creator project. Use a SQLite database for game data.");
      p.libraryOrigin = "uploaded";
      p.provenance = { file: name, importedAt: isoNow() };
      p.key = "unit-" + p.targetId + "-" + Date.now();
      await IOS.saveProjectNow(p);
      return { kind: "project", project: p };
    }
    const magic = await head(file, 16);
    const m4 = String.fromCharCode.apply(null, magic.subarray(0, 4));
    if (m4 === "ECLP") return importEclp(file, name);
    if (m4 === "SPRK") { if (!IOS.importSparkingPatch) throw fail("Import the Sparking APK first."); return IOS.importSparkingPatch(file, name); }
    if (dec.decode(magic) === "SQLite format 3\u0000") {
      const tmp = "cache/import-" + Date.now() + ".db";
      try { await host.writeBytes(tmp, file); return { kind: "database", info: await IOS.useDb(tmp, name, {}) }; }
      finally { host.remove(tmp).catch(() => {}); }
    }
    if (lower.endsWith(".zip")) {
      const entries = await zipEntries(file);
      const files = entries.filter((e) => !e.dir);
      if (files.length === 1 && /\.apk$/i.test(files[0].name)) {
        if (files[0].usize > 512 * MiB) throw fail("The APK inside this ZIP is incomplete or corrupted. Download the original ZIP again.");
        const inner = new File([await zipData(file, files[0])], files[0].name.split("/").pop());
        const ie = await zipEntries(inner);
        const pkg = await apkPackage(inner, ie);
        if (pkg && pkg.package === "com.sparkingDokkan.GLB" && IOS.importSparkingApk) return IOS.importSparkingApk(inner, inner.name, ie);
        if (pkg && pkg.package === "com.anthen.eclipse") return importEclipseApk(inner, inner.name, ie, pkg);
        return importArchive(inner, inner.name, ie);
      }
      if (files.some((e) => e.name === "metadata.json") && files.some((e) => /^files\/.*\.sql$/i.test(e.name))) return importPatchZip(file, name, files);
      return importArchive(file, name, entries);
    }
    if (/\.(zip|apk|apks|ipa|eclp)$/i.test(name)) return importArchive(file, name, await zipEntries(file));
    if (RESOURCE.test(name)) return importSingle(file, name);
    throw fail("Choose a unit JSON, SQL, ECLP or SPRK patch, readable SQLite database, image, ZIP, or APK archive.");
  }
  async function apkPackage(file, entries) {
    const m = entries.find((e) => e.name === "AndroidManifest.xml");
    if (!m) return null;
    try { return axmlManifest(new Uint8Array(await (await zipData(file, m)).arrayBuffer())); } catch (e) { return null; }
  }

  async function importSingle(file, name) {
    const base = name.split("/").pop();
    if (file.size > GiB) throw fail("File exceeds the supported import size.");
    const group = "import-" + IOS.uuid4();
    await host.writeBytes(A + group + "/" + base, file);
    const r = await expandCpkResources(group, 1, file.size);
    IOS.invalidateAssets();
    return Object.assign(r, { kind: "assets", asset: { key: group + "/" + base, path: base, name: base, size: file.size, image: /\.(png|jpe?g|webp|gif|bmp)$/i.test(base) } });
  }

  // CPK archives inside an import are unpacked next to themselves (the originals are kept)
  async function expandCpkResources(group, count, bytes) {
    const all = await host.list(A + group, true);
    const taken = new Set(all.map((f) => f.name.normalize("NFC").toLowerCase()));
    const warnings = []; let expanded = 0;
    const warn = (w) => { if (warnings.length < 200) warnings.push(w); else if (warnings.length === 200) warnings.push("Additional CPK warnings were omitted. Original archives were kept."); };
    for (const f of all.filter((x) => /\.cpk$/i.test(x.name))) {
      try {
        const blob = new Blob([await host.readBytes(A + group + "/" + f.name)]);
        const list = await F.cpkEntries(blob);
        const baseDir = f.name.slice(0, -4);
        for (const e of list) {
          const rel = baseDir + "/" + e.path;
          if (!safePath(rel)) throw fail("Unsafe expanded CPK path");
          const k = rel.normalize("NFC").toLowerCase();
          if (taken.has(k)) throw fail("Imported resources have conflicting destinations: " + rel);
          if (++count > 100000 || (bytes += e.size) > 4 * GiB) throw fail("Expanded CPK resources exceed the import limit");
          await host.writeBytes(A + group + "/" + rel, await F.cpkRead(blob, e));
          taken.add(k); expanded++;
        }
      } catch (e) { warn(f.name + ": " + e.message + " The original archive was kept."); }
    }
    return { count, bytes, expanded, warnings };
  }

  async function importArchive(file, name, entries) {
    const group = "import-" + IOS.uuid4();
    try {
      let count = 0, bytes = 0;
      const seen = new Set(), dbs = [];
      for (const e of entries) {
        if (e.dir) continue;
        if (!safePath(e.name)) throw fail("Archive contains an unsafe file path");
        const isDb = /\.(db|sqlite|sqlite3)$/i.test(e.name);
        if (!isDb && !ARCHIVE_RES.test(e.name)) continue;
        if (++count > 100000) throw fail("Archive contains too many files");
        const dest = isDb ? "_databases/" + e.name.split("/").pop() : normalizeAsset(e.name);
        const k = dest.normalize("NFC").toLowerCase();
        if (seen.has(k)) throw fail("Archive contains conflicting resource paths");
        seen.add(k);
        if (e.usize > GiB) throw fail("File exceeds the supported import size.");
        if ((bytes += e.usize) > 4 * GiB) throw fail("Resource import is larger than 4 GB");
        progress("extract", "Reading archive files", bytes, 0);
        await host.writeBytes(A + group + "/" + dest, await zipData(file, e));
        if (isDb) dbs.push({ path: A + group + "/" + dest, name: e.name });
      }
      const r = await expandCpkResources(group, count, bytes);
      let chosen = null;
      for (const d of dbs) { try { await IOS.verifyDb(d.path, false); if (!chosen || /decrypted/i.test(d.name)) chosen = d; } catch (e) {} }
      let database = false;
      if (chosen) { await IOS.useDb(chosen.path, name, {}); database = true; }
      IOS.invalidateAssets();
      return Object.assign(r, { kind: "archive", database, note: database ? "Readable game database imported." : "No readable game database found; the previous database was kept. Resource files were imported where available." });
    } catch (e) { await host.remove(A + group).catch(() => {}); throw fail("Could not import this ZIP/APK. " + e.message); }
  }

  async function importPatchZip(file, name, files) {
    const out = [], seen = new Set();
    if (files.length > 100000) throw fail("Too many ZIP entries");
    let total = 0;
    for (const e of files) {
      if (!safePath(e.name) || seen.has(e.name)) throw fail("Unsafe or duplicate ZIP patch path");
      seen.add(e.name);
      if ((total += e.usize) > 4 * GiB) throw fail("Patch ZIP too large");
      out.push({ path: e.name, bytes: new Uint8Array(await (await zipData(file, e)).arrayBuffer()) });
    }
    const bytes = await window.ForgeEclp.write(out, { deriveKey: IOS.deriveKey });
    const r = await importEclp(new Blob([bytes]), name.replace(/\.zip$/i, "") + ".eclp");
    r.note = "Patch ZIP converted to ECLP locally and added to Library.";
    return r;
  }

  // ECLP: authenticated, unpacked to assets/patch-<uuid>/, kept in Library; its unit (if any) is added
  async function importEclp(file, name) {
    const bytes = new Uint8Array(await file.arrayBuffer());
    let pack;
    try { pack = await window.ForgeEclp.read(bytes, { deriveKey: IOS.deriveKey }); }
    catch (e) { throw fail(/damaged|changed/i.test(e.message) ? "ECLP authentication failed: file damaged or metadata changed" : e.message); }
    const key = IOS.uuid4(), dir = A + "patch-" + key + "/";
    try {
      let size = 0;
      for (const e of pack.entries) { await host.writeBytes(dir + e.path, e.bytes); size += e.bytes.length; }
      let project = null;
      const inner = pack.entries.find((e) => e.path === "forge-project.json");
      if (inner) {
        let p; try { p = JSON.parse(dec.decode(inner.bytes)); } catch (e) { p = null; }
        if (!p || p.format !== "dokkan-unit-forge" || p.version !== 1 || !p.tables || !Array.isArray(p.tables.cards) || p.tables.cards.length !== 1) throw fail("Invalid embedded unit project");
        project = await restoreForms(p, key, pack, name);
      }
      await host.writeBytes("patches/" + key + ".eclp", bytes);
      const meta = { key, metadata: pack.metadata, filename: name, importedAt: isoNow(), count: pack.entries.length, bytes: size,
        entries: pack.entries.map((e) => ({ path: e.path, size: e.bytes.length })), projectKey: project ? project.key : null };
      await host.writeJson("patches/" + key + ".json", meta);
      if (project) await IOS.saveProjectNow(project);
      IOS.invalidateAssets();
      return { kind: project ? "project" : "patch", project, patch: meta, note: "ECLP authenticated and added to Library. SQL stays inside the patch and is never executed by this app." };
    } catch (e) {
      await host.remove(dir).catch(() => {}); await host.remove("patches/" + key + ".eclp").catch(() => {}); await host.remove("patches/" + key + ".json").catch(() => {});
      throw e;
    }
  }
  // ProjectFormsData.restore: new keys for the unit and its forms, attached files pointed at the patch folder
  async function restoreForms(p, patchKey, pack, name) {
    const files = new Set(pack.entries.map((e) => e.path));
    const keyMap = new Map(), assetMap = new Map();
    const rekey = (x) => { const k = "unit-" + x.targetId + "-" + IOS.uuid4(); if (x.key) keyMap.set(x.key, k); x.key = k; };
    const forms = Array.isArray(p.formProjects) ? p.formProjects : [];
    if (forms.length > 4) throw fail("Too many embedded forms.");
    for (const f of forms) {
      if (f && f.formProjects) throw fail("Nested transformation forms are not supported.");
      if (!f || f.version !== 1 || !f.tables || !Array.isArray(f.tables.cards) || f.tables.cards.length !== 1) throw fail("Invalid embedded unit form.");
    }
    for (const x of [p].concat(forms)) {
      rekey(x);
      for (const a of Array.isArray(x.assets) ? x.assets : []) {
        if (!files.has("files/" + a.path)) throw fail("Embedded form resource missing.");
        const nk = "patch-" + patchKey + "/files/" + a.path;
        if (a.key) assetMap.set(a.key, nk);
        a.key = nk;
      }
      if (x.previewKey) { if (assetMap.has(x.previewKey)) x.previewKey = assetMap.get(x.previewKey); else delete x.previewKey; }
    }
    for (const l of Array.isArray(p.transformLinks) ? p.transformLinks : []) {
      if (l && l.targetKey != null) { if (!keyMap.has(l.targetKey)) throw fail("An embedded transformation form is missing."); l.targetKey = keyMap.get(l.targetKey); }
    }
    const walk = (v, depth) => {
      if (depth > 80) throw fail("The embedded unit is too deeply nested.");
      if (Array.isArray(v)) return v.map((x) => walk(x, depth + 1));
      if (v && typeof v === "object") { for (const k of Object.keys(v)) v[k] = walk(v[k], depth + 1); return v; }
      if (typeof v === "string" && assetMap.has(v)) return assetMap.get(v);
      return v;
    };
    walk(p, 0);
    p.libraryOrigin = "uploaded";
    p.provenance = { file: name, patchKey, author: pack.metadata && pack.metadata.author, importedAt: isoNow() };
    return p;
  }

  // The Eclipse Android APK: its game database (or the newest one online) and its game files
  async function importEclipseApk(file, name, entries, pkg) {
    const group = "apk-" + IOS.uuid4();
    try {
      progress("inspect", "Checking Eclipse APK");
      if (!pkg || pkg.package !== "com.anthen.eclipse") throw fail("Choose the Eclipse Android APK (com.anthen.eclipse). The selected app was not installed or run.");
      let gameVersion = null;
      const map = entries.find((e) => e.name === "assets/patcher/maps/android_current.json");
      if (map) {
        if (map.usize > 8388608) throw fail("APK version map too large");
        try { const v = JSON.parse(await (await zipData(file, map)).text()).version; gameVersion = v ? String(v).slice(0, 100) : null; } catch (e) {}
      }
      const sha = await sha256Blob(file);
      const apk = { packageName: pkg.package, versionName: pkg.versionName || "", versionCode: pkg.versionCode || 0, gameVersion, filename: name, sha256: sha };
      progress("extract", "Reading APK database and resources");
      if (entries.length > 100000) throw fail("Too many APK entries");
      const cands = []; let count = 0, bytes = 0, sawDb = false; const seen = new Set();
      for (const e of entries) {
        if (e.dir) continue;
        if (!safePath(e.name)) throw fail("Unsafe APK file path");
        if (e.usize > 512 * MiB) throw fail("APK resource exceeds 512 MB");
        if (/^assets\/(sqlite\/current\/en\/database(_decrypted)?\.db|database\.db)$/.test(e.name)) {
          sawDb = true;
          const tmp = "cache/apk-work-" + group + "/database-" + cands.length + ".db";
          await host.writeBytes(tmp, await zipData(file, e));
          cands.push({ path: tmp, name: e.name, rank: /\/sqlite\/current\/en\//.test(e.name) ? (/_decrypted/.test(e.name) ? 3 : 2) : 1 });
        } else if (e.name.startsWith("assets/") && !/^assets\/(patcher|dexopt|org)\//.test(e.name) && ARCHIVE_RES.test(e.name)) {
          const dest = normalizeAsset(e.name), k = dest.normalize("NFC").toLowerCase();
          if (seen.has(k)) throw fail("Conflicting APK resource paths");
          seen.add(k);
          if ((bytes += e.usize) > 4 * GiB) throw fail("APK resources exceed 4 GB");
          count++;
          if (count % 50 === 0) progress("extract", "Reading APK database and resources", bytes, 0);
          await host.writeBytes(A + group + "/" + dest, await zipData(file, e));
        }
      }
      const r = await expandCpkResources(group, count, bytes);
      apk.resourceCount = r.count;
      cands.sort((x, y) => y.rank - x.rank);
      let chosen = null;
      for (const c of cands) {
        const h = new Uint8Array(await (await fetch(host.fileUrl(c.path), { headers: { Range: "bytes=0-15" } })).arrayBuffer());
        if (dec.decode(h) !== "SQLite format 3\u0000") continue;
        try { await IOS.verifyDb(c.path, true); chosen = c; break; } catch (e) {}
      }
      const meta = { apk, resourceGroup: group };
      let info, mode;
      if (chosen) {
        apk.embeddedDatabase = chosen.name; meta.sourceType = "apk-embedded";
        progress("verify", "Validating the database inside the APK");
        info = await IOS.useDb(chosen.path, "Database inside " + name, meta); mode = "embedded";
      } else {
        apk.embeddedDatabase = sawDb ? "starter-or-encrypted" : "not-included";
        info = await IOS.downloadCurrentDatabase(meta); mode = "downloaded";
      }
      progress("done", "Eclipse APK imported; game data ready");
      IOS.invalidateAssets();
      return { kind: "apk", database: true, mode, apk, count: r.count, bytes: r.bytes, expanded: r.expanded, warnings: r.warnings, info,
        note: mode === "embedded" ? "APK database validated and activated. Saved units were kept." : "The APK contains starter or encrypted data. Eclipse’s current full English database was downloaded and validated; saved units were kept." };
    } catch (e) {
      await host.remove(A + group).catch(() => {});
      progress("error", "Update failed; previous data and saved units were kept");
      throw fail(e.message + " Your previous database and saved units were kept.");
    } finally { host.remove("cache/apk-work-" + group).catch(() => {}); }
  }
  async function sha256Blob(blob) {
    const tmp = "cache/hash-" + Date.now() + ".bin";
    if (blob.size <= 256 * MiB) return IOS.sha256Hex(new Uint8Array(await blob.arrayBuffer()));
    await host.writeBytes(tmp, blob);
    try { return (await host.call("sha256", { path: tmp })).sha256; } finally { host.remove(tmp).catch(() => {}); }
  }
  IOS.importEclp = importEclp; IOS.importArchiveForSparking = importArchive; IOS.expandCpkResources = expandCpkResources; IOS.normalizeAsset = normalizeAsset;

  // the .eclp key is derived in a worker (keeps the screen smooth); Android: Argon2id via BouncyCastle
  IOS.deriveKey = function (pw, salt) {
    return new Promise((resolve) => {
      let w;
      try { w = new Worker("web/argon2-worker.js"); } catch (e) { resolve(window.ForgeArgon2.argon2id(pw, salt, { iterations: 3, memoryKiB: 65536, parallelism: 4, tagLength: 32 })); return; }
      w.onmessage = (e) => {
        if (e.data.progress != null) return;
        w.terminate();
        if (e.data.error) resolve(window.ForgeArgon2.argon2id(pw, salt, { iterations: 3, memoryKiB: 65536, parallelism: 4, tagLength: 32 }));
        else resolve(new Uint8Array(e.data.key));
      };
      w.onerror = () => { w.terminate(); resolve(window.ForgeArgon2.argon2id(pw, salt, { iterations: 3, memoryKiB: 65536, parallelism: 4, tagLength: 32 })); };
      w.postMessage({ pw, salt });
    });
  };

  // ---------------------------------------------------------------- "Use Eclipse online" is Android-only (as on Android's iOS path)
  addEventListener("DOMContentLoaded", () => { if (window.Native) window.Native.canConvertOnline = () => false; });
  H.convert = async () => { throw fail("Unsupported action: convert"); };
})();
