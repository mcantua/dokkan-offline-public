/* iPhone app: imported and downloaded game files (Android: GameAssets, GameDirectory, GameMetadata,
 * PreviewMetadata, PreviewScripts, GameBgm, AudioBanks, AssetIndex, ImageAssets, DecorationStorage,
 * LwfStorage, MovieStorage, AssetDownload) and the bridge methods that use them. */
(function () {
  "use strict";
  const IOS = window.__forgeIOS;
  if (!IOS || !IOS.formats) return;
  const { host, H, F } = { host: IOS.host, H: IOS.H, F: IOS.formats };
  const fail = (m) => new Error(m);
  const MiB = 1048576, ORIGIN = "https://dokkan-eclipse.com";
  const A = "assets/";

  // ---------------------------------------------------------------- path rules (exact)
  const PRIVATE = new Set(["projects", "patches", "exports", "_databases", "metadata.json", "forge-project.json", "database-meta.json", "database-state.json", "account.txt", "credentials.json", "secrets.json"]);
  const DATABASE = /\.(db|sqlite|sqlite3)([-.].*)?$/i;
  const PREFIX = /^(lua|script|character|ingame|movie|layout|bgm|outgame|origin|item|se|voice|comic_text|fonts|shader|dokkan_field|card_[a-z0-9_]+)\//;
  function safe(s) {
    if (typeof s !== "string" || !s || s.length > 500 || s.startsWith("/") || /[\\:%\x00-\x1f\x7f]/.test(s)) return false;
    if (!s.split("/").every((x) => x && x !== "." && x !== ".." && !x.startsWith(".") && !PRIVATE.has(x.toLowerCase()))) return false;
    return !DATABASE.test(s);
  }
  function gamePath(url) {
    if (typeof url !== "string" || url.includes("\\")) return null;
    let u; try { u = new URL(url, ORIGIN); } catch (e) { return null; }
    if (/(^|\/)\.{1,2}(\/|$)/.test(url.split("?")[0])) return null;
    if (u.protocol !== "https:" || !(u.hostname === "dokkan-eclipse.com" || u.hostname === "cdn.dokkan-eclipse.com") || u.port || u.username || u.password) return null;
    let p; try { p = decodeURIComponent(u.pathname); } catch (e) { return null; }
    let rel = p.startsWith("/cdn/uncompressed/") ? p.slice(18) : p.startsWith("/assets/") ? p.slice(8) : null;
    return rel != null && safe(rel) && PREFIX.test(rel) ? rel : null;
  }
  const EXT = "png|jpe?g|webp|gif|bmp|lwf|lua|usm|cpk|kks|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|fsh|vsh|fnt|ttf|otf|strings|txt|bin";
  const extOf = (s) => (/\.([^./]+)$/.exec(s) || [])[1] || "";
  function overlayMap(arr) {
    const map = new Map();
    if (arr == null) return map;
    if (!Array.isArray(arr) || arr.length > 2000) throw fail("Invalid preview asset manifest");
    const seen = new Set();
    for (const e of arr) {
      if (!e || typeof e.path !== "string" || typeof e.key !== "string" || gamePath("/assets/" + e.path) !== e.path || !safe(e.key) || e.key.split("/").length < 2) throw fail("Invalid preview asset alias");
      const pe = extOf(e.path).toLowerCase(), ke = extOf(e.key).toLowerCase();
      if (pe !== ke || !new RegExp("^(" + EXT + ")$").test(pe)) throw fail("Preview aliases need matching supported resource types");
      const k = e.path.normalize("NFC").toLowerCase();
      if (seen.has(k)) throw fail("Conflicting preview asset aliases");
      seen.add(k); map.set(e.path, e.key);
    }
    return map;
  }
  IOS.overlayMap = overlayMap; IOS.assetSafe = safe; IOS.gamePath = gamePath;
  function preferredPath(key) {
    if (!safe(key)) throw fail("Invalid selected game asset");
    const parts = key.split("/");
    if (parts.length < 2) throw fail("Invalid selected game asset");
    parts.shift();
    if (parts[0] === "files") parts.shift();
    if (parts[0] === "tutorial0") parts.shift();
    const p = parts.join("/");
    if (!safe(p) || !PREFIX.test(p)) throw fail("Invalid selected game asset");
    return p;
  }
  const fontFallback = (p) => { const m = /^fonts\/([^/]+\.(otf|ttf))$/i.exec(p); return m ? "fonts/default/" + m[1] : null; };
  // collections, newest first then by name (cached briefly: previews ask for many files)
  let cols = null, colsAt = 0;
  async function collections() {
    if (cols && Date.now() - colsAt < 3000) return cols;
    const list = (await host.list(A)).filter((f) => f.dir && safe(f.name));
    if (list.length > 4096) throw fail("Too many imported resource groups for a visual preview");
    list.sort((a, b) => b.mtime - a.mtime || (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
    cols = list.map((f) => f.name); colsAt = Date.now();
    return cols;
  }
  IOS.invalidateAssets = () => { cols = null; };
  async function regular(rel) {
    const st = await host.stat(A + rel);
    if (!st || st.dir) return null;
    if (st.size > 160 * MiB) throw fail("Imported game asset exceeds the 160 MB preview limit");
    return { path: A + rel, size: st.size, mtime: st.mtime, rel };
  }
  /** GameAssets(ASSETS, preferredKey, overlays).resolve(url) */
  async function resolve(ctx, url) {
    const gp = gamePath(url);
    if (!gp) return null;
    const overlay = overlayMap(ctx.assets);
    let target = overlay.get(gp) || null;
    if (!target) {
      let best = "";
      for (const [k, v] of overlay) {
        if (/\.cpk$/i.test(k) && /\.cpk$/i.test(v)) { const pre = k.slice(0, -4) + "/"; if (gp.startsWith(pre) && pre.length > best.length) { best = pre; target = v.slice(0, -4) + "/" + gp.slice(pre.length); } }
      }
    }
    const pref = ctx.assetKey ? preferredPath(ctx.assetKey) : null;
    const forced = !!target || (pref != null && (pref === gp || pref === fontFallback(gp)));
    if (!(await host.exists("assets"))) { if (forced) throw fail("The selected imported asset is unavailable. Choose it again."); return null; }
    if (forced) { const f = await regular(target || ctx.assetKey); if (!f) throw fail("The selected imported asset is unavailable. Choose it again."); return f; }
    for (const p of [gp, fontFallback(gp)]) {
      if (!p) continue;
      for (const c of await collections()) for (const sub of ["", "files/", "tutorial0/"]) { const f = await regular(c + "/" + sub + p); if (f) return f; }
    }
    return null;
  }
  async function read(ctx, p, max) {
    if (!safe(p) || !PREFIX.test(p)) throw fail("Invalid game asset path");
    const f = await resolve(ctx, "/assets/" + p);
    if (!f) return null;
    if (max < 0 || max > 160 * MiB || f.size > max) throw fail("Imported game asset exceeds the supported size");
    return host.readBytes(f.path);
  }
  IOS.gameAssetResolve = (sess, url) => resolve(sess, url);
  IOS.gameAssetRead = (ctx, p, max) => read(ctx, p, max);

  // ---------------------------------------------------------------- GameDirectory (/api/file-browser)
  const VISUAL = /\.(png|lwf)$/i;
  IOS.gameDirectoryRoute = function (U) {
    let u; try { u = new URL(U, ORIGIN); } catch (e) { return null; }
    if (u.origin !== ORIGIN || u.pathname !== "/api/file-browser" || !u.search) return null;
    const m = /(?:^|&)path=([^&]*)/.exec(u.search.slice(1));
    if (!m) return null;
    let p; try { p = decodeURIComponent(m[1].replace(/\+/g, " ")); } catch (e) { return null; }
    if (!safe(p) || gamePath("/assets/" + p + "/forge-directory-probe.lwf") !== p + "/forge-directory-probe.lwf") return null;
    return p;
  };
  IOS.gameDirectory = async function (sess, p) {
    const overlay = overlayMap(sess.assets);
    const items = new Map();
    const parentOf = (x) => x.slice(0, Math.max(0, x.lastIndexOf("/")));
    const hits = [...overlay.entries()].filter(([gp]) => parentOf(gp) === p && VISUAL.test(gp));
    let pref = null; try { pref = sess.assetKey ? preferredPath(sess.assetKey) : null; } catch (e) {}
    if (!(await host.exists("assets"))) {
      if (!hits.length && pref && parentOf(pref) === p) throw fail("The selected imported asset is unavailable. Choose it again.");
      return null;
    }
    let scanned = 0;
    for (const c of await collections()) for (const sub of ["", "files/", "tutorial0/"]) {
      const dir = A + c + "/" + sub + p;
      const list = await host.list(dir).catch(() => []);
      scanned += list.length;
      if (scanned > 10000) throw fail("This visual folder exceeds the preview listing limit");
      for (const f of list) {
        if (f.dir || !VISUAL.test(f.name) || items.has(f.name) || !gamePath("/assets/" + p + "/" + f.name)) continue;
        if (f.size > 160 * MiB) throw fail("Imported game asset exceeds the 160 MB preview limit");
        items.set(f.name, { type: "file", name: f.name, path: p + "/" + f.name, size: f.size, source: "imported" });
      }
    }
    if (pref && parentOf(pref) === p && VISUAL.test(pref)) {
      const st = await host.stat(A + sess.assetKey);
      if (st) items.set(pref.split("/").pop(), { type: "file", name: pref.split("/").pop(), path: pref, size: st.size, source: "imported" });
    }
    for (const [gp, key] of hits) { const st = await host.stat(A + key); if (st) items.set(gp.split("/").pop(), { type: "file", name: gp.split("/").pop(), path: gp, size: st.size, source: "imported" }); }
    if (items.size > 200) throw fail("This visual pack has more than 200 files. Choose a smaller pack.");
    if (!items.size) { if (pref && parentOf(pref) === p) throw fail("The selected imported asset is unavailable. Choose it again."); return null; }
    return { path: p, parentPath: parentOf(p), items: [...items.values()].sort((a, b) => (a.name < b.name ? -1 : 1)), forge_local: true };
  };
  IOS.mergeDirectory = function (local, pub) {
    if (!pub || pub.path !== local.path || !Array.isArray(pub.items)) return local;
    const m = new Map();
    for (const it of pub.items) {
      if (!it || it.type !== "file" || typeof it.name !== "string" || it.name.includes("/") || !VISUAL.test(it.name) || it.path !== local.path + "/" + it.name || !gamePath("/assets/" + it.path) || !(it.size >= 0 && it.size <= 160 * MiB)) continue;
      m.set(it.name, { name: it.name, path: it.path, type: "file", size: it.size, source: "public" });
    }
    for (const it of local.items) m.set(it.name, it);
    return Object.assign({}, local, { items: [...m.values()].sort((a, b) => (a.name < b.name ? -1 : 1)).slice(0, 200) });
  };

  // ---------------------------------------------------------------- metadata (/api/card, /api/effect-pack)
  async function databaseFile(source, version) {
    if (source === "sparking") return IOS.sparkingDatabaseFile(version || 0);
    return IOS.dbPath("main");
  }
  async function row(db, table, id) { const r = await IOS.sql(db, 'SELECT * FROM "' + table + '" WHERE id=? LIMIT 1', [id]); return r[0] || null; }
  let rules = null;
  async function metadataRules() { if (!rules) rules = JSON.parse(await IOS.siteText("data/preview-metadata-rules.json", MiB)); return rules; }
  const pad = (n, w) => String(n).padStart(w, "0");
  async function descriptor(ctx, rel) {
    const f = await resolve(ctx, "/assets/" + rel).catch(() => null);
    return f ? { rel, url: "/assets/" + rel, bytes: f.size, source: "imported", stamp: "imported:" + f.mtime + ":" + f.size } : null;
  }
  async function localMetadata(ctx, url, db, packRow) {
    let u; try { u = new URL(url, ORIGIN); } catch (e) { return null; }
    if (u.searchParams.has("patch")) return null;
    const m = /^\/api\/(card|effect-pack)\/([1-9][0-9]{0,14})$/.exec(u.pathname);
    if (!m) return null;
    const id = Number(m[2]), enemy = u.searchParams.get("enemy") === "1";
    if (m[1] === "card") {
      const c = db ? await row(db, "cards", id) : null;
      if (!c || !(c.character_id > 0)) return null;
      const res = c.resource_id || id, art = Math.floor(res / 10) * 10, cid = pad(c.character_id, 5), sm = pad(c.special_motion || 0, 2);
      const out = { battle: await descriptor(ctx, `ingame/battle/character/${cid}/battle/battle_character_${cid}.lwf`),
        idle: await descriptor(ctx, `ingame/battle/character/${cid}/idle/idle_character_${cid}.lwf`),
        sp: await descriptor(ctx, `ingame/battle/character/${cid}/sp${sm}/sp_character_${cid}_${sm}.lwf`), card_bg: null };
      if (c.bg_effect_id) { const b = Math.floor(c.bg_effect_id / 10) * 10; out.card_bg = await descriptor(ctx, `character/card_bg/${b}/card_${b}.lwf`); }
      const base = `character/card/${art}/card_${art}`, textures = {};
      for (const [k, suf] of [["character", "_character.png"], ["effect", "_effect.png"], ["bg", "_bg.png"], ["circle", "_circle.png"], ["cutin", "sp_cutin_1.png"], ["sp_cutin", "sp_cutin_1.png"]]) { const d = await descriptor(ctx, base + suf); if (d) textures[k] = d; }
      for (const k of ["sp_name", "sp_phrase"]) { const d = (await descriptor(ctx, `character/card/${art}/en/card_${art}_${k}.png`)) || (await descriptor(ctx, `${base}_${k}.png`)); if (d) textures[k] = d; }
      if (!out.battle && !out.idle && !out.sp && !out.card_bg && !Object.keys(textures).length) return null;
      let size = null; try { const ch = await row(db, "characters", c.character_id); size = ch && ch.size != null ? ch.size : null; } catch (e) {}
      return Object.assign({ found: true, forge_local: true, id, name: c.name, character_id: c.character_id, character_size: size, resource_id: c.resource_id, art_id: art,
        bg_effect_id: c.bg_effect_id, special_motion: c.special_motion, aura_id: c.aura_id, aura_effect_id: null, aura_scale: c.aura_scale != null ? c.aura_scale : 1,
        aura_offset_x: c.aura_offset_x || 0, aura_offset_y: c.aura_offset_y || 0, is_aura_front: !!c.is_aura_front }, out, { textures, dbSource: "imported" });
    }
    const p = packRow || (db ? await row(db, "effect_packs", id) : null);
    if (!p || !/^[-a-zA-Z0-9_]{1,100}$/.test(p.pack_name || "")) return null;
    const R = await metadataRules(), cat = R.categories && R.categories[String(p.category)];
    if (!cat) return null;
    const fill = (t, pack) => t.split("{pack}").join(pack);
    let lwf = null, usm = null;
    for (const t of cat.lwf || []) { lwf = await descriptor(ctx, fill(t, p.pack_name)); if (lwf) break; }
    const usmCands = (enemy ? (cat.usm || []).map((t) => fill(t, p.pack_name + (R.enemyMovieSuffix || ""))) : []).concat((cat.usm || []).map((t) => fill(t, p.pack_name)));
    for (const t of usmCands) { usm = await descriptor(ctx, t); if (usm) break; }
    if (!lwf && !usm) return null;
    return { found: true, forge_local: true, id, category: p.category, name: p.name, pack_name: p.pack_name, scene_name: p.scene_name,
      rgba: { r: p.red, g: p.green, b: p.blue, a: p.alpha }, lite_flicker_rate: p.lite_flicker_rate, media: lwf && usm ? "both" : lwf ? "lwf" : "usm", lwf, usm, enemy, dbSource: "imported" };
  }
  function strip(v) { if (v && typeof v === "object") { const c = Object.assign({}, v); delete c.fsPath; return c; } return v; }
  function mergeMetadata(local, pub) {
    if (!local) return pub;
    if (!pub || !pub.found) return local;
    if ("character_id" in local) {
      if (local.character_id !== pub.character_id || local.art_id !== pub.art_id) return local;
      const out = Object.assign({}, pub, local);
      for (const k of ["battle", "idle", "sp", "card_bg"]) {
        let v = local[k];
        if (!v) { const okRemote = k === "sp" ? local.special_motion === pub.special_motion : k === "card_bg" ? local.bg_effect_id === pub.bg_effect_id : true; v = okRemote ? pub[k] : null; }
        out[k] = strip(v);
      }
      out.textures = {};
      for (const [k, v] of Object.entries(Object.assign({}, pub.textures || {}, local.textures || {}))) out.textures[k] = strip(v);
      if (local.aura_effect_id == null && local.aura_id === pub.aura_id) out.aura_effect_id = pub.aura_effect_id;
      return out;
    }
    if (local.pack_name !== pub.pack_name || local.category !== pub.category) return local;
    const out = Object.assign({}, pub, local);
    out.lwf = strip(local.lwf || pub.lwf);
    out.usm = strip(local.usm || (local.enemy === pub.enemy ? pub.usm : null));
    out.media = out.lwf && out.usm ? "both" : out.lwf ? "lwf" : out.usm ? "usm" : "missing";
    return out;
  }
  IOS.previewMetadata = async function (sess, url) {
    const isPack = /\/api\/effect-pack\/([0-9]+)/.exec(url), packId = isPack ? Number(isPack[1]) : 0;
    const own = isPack ? (sess.effectPacks || []).find((p) => p.id === packId) : null;
    const viaSparking = isPack && (sess.sparkingIds || []).includes(packId);
    let db = null;
    try { db = await databaseFile(viaSparking ? "sparking" : sess.sourceDatabase === "sparking" ? "sparking" : "eclipse", sess.version); } catch (e) { if (viaSparking || sess.sourceDatabase === "sparking") throw e; }
    const local = await localMetadata(sess, url, db, own || null);
    if (own) { if (local) return local; throw fail("Your edited movie is missing. Reopen or reattach it."); }
    if (sess.sourceDatabase === "sparking" || viaSparking) {
      if (local) return local;
      throw fail("This Sparking preview needs its matching imported character/effect resources. Download the selected unit's resources from Library; Eclipse metadata was not substituted.");
    }
    let pub;
    try { pub = JSON.parse(await IOS.previewCache.cacheText(url, MiB)); } catch (e) { if (!local) throw e; return local; }
    return mergeMetadata(local, pub);
  };

  // ---------------------------------------------------------------- scripts (/api/scripts, animationFiles)
  const SCRIPT = /^ab_script\/[a-z0-9_/-]+\.lua$/i;
  const validScript = (p) => typeof p === "string" && p.length < 240 && SCRIPT.test(p) && safe(p);
  let index = null;
  async function scriptIndex() {
    if (index) return index;
    const t = await IOS.siteText("data/preview-script-index.json");
    if (t.length > 2 * MiB) throw fail("The packaged script index is too large");
    const j = JSON.parse(t);
    if (j.schemaVersion !== 1) throw fail("Update Dokkan Unit Creator to load the packaged animation catalog");
    return (index = j);
  }
  const addScripts = (set, arr) => { for (const x of arr || []) { const p = typeof x === "string" ? x : x && x.path; if (validScript(p)) set.add(p); } };
  async function importedScripts(set) {
    if (!(await host.exists("assets"))) return false;
    const top = await host.list(A);
    if (top.length > 4096) throw fail("Too many imported animation collections");
    let count = 0, any = false;
    for (const c of top) {
      if (!c.dir || !safe(c.name)) continue;
      for (const sub of ["lua/ab_script", "files/lua/ab_script", "tutorial0/lua/ab_script"]) {
        const files = await host.list(A + c.name + "/" + sub, true).catch(() => []);
        count += files.length;
        if (count > 50000) throw fail("The imported animation catalog exceeds its 50,000-entry limit");
        for (const f of files) { if (f.size > 0 && f.size <= 2 * MiB && f.name.split("/").length <= 24) { const p = "ab_script/" + f.name; if (validScript(p)) { set.add(p); any = true; } } }
      }
    }
    return any;
  }
  const javaSort = (arr) => arr.sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  IOS.scriptListing = async function () {
    const j = await scriptIndex();
    const set = new Set(); addScripts(set, j.scripts);
    if (!set.size) throw fail("The packaged animation catalog is empty");
    const any = await importedScripts(set);
    return Object.assign({}, j, { scripts: javaSort([...set]).map((path) => ({ path })), count: set.size, includesImported: any });
  };
  H.animationFiles = async function (a) {
    if (a.sourceDatabase === "sparking") return IOS.sparkingAnimationFiles(a);
    const off = await IOS.previewCache.offline(), set = new Set(), cache = "animation-files.json";
    const has = await host.exists(cache);
    if (has && (!a.refresh || off)) addScripts(set, await host.readJson(cache));
    if (a.refresh && !off) {
      const r = await fetchText(ORIGIN + "/api/scripts", 2 * MiB);
      addScripts(set, JSON.parse(r).scripts);
    }
    if (!set.size && has) { try { addScripts(set, await host.readJson(cache)); } catch (e) {} }
    if (!set.size) { const j = await scriptIndex(); addScripts(set, j.scripts); if (!set.size) throw fail("The packaged animation catalog is empty"); }
    await host.writeJson(cache, javaSort([...set]));
    await importedScripts(set);
    return javaSort([...set]);
  };
  IOS.dbKey = async function () {
    const st = await IOS.storeState("main");
    const meta = st ? st.active.meta : (await IOS.bundledMeta());
    return String(meta.date != null ? meta.date : meta.sha256 != null ? meta.sha256 : "bundled").replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 80);
  };
  /** CreatorActivity.fetchText: official routes only, UA 2.3, a byte cap */
  async function fetchText(url, cap) {
    const u = new URL(url);
    if (u.protocol !== "https:" || u.hostname !== "dokkan-eclipse.com") throw fail("Only official Eclipse resource routes are supported");
    let r;
    try { r = await host.net(url, { headers: { "User-Agent": "DokkanUnitCreator/2.3" } }); } catch (e) { throw fail("Couldn't reach Dokkan Eclipse. Check your internet connection."); }
    if (r.status !== 200) throw fail("Eclipse returned HTTP " + r.status + ". You can import a local database or resource pack instead.");
    const b = new Uint8Array(await r.arrayBuffer());
    if (b.length > cap) throw fail("File exceeds the supported import size.");
    return new TextDecoder().decode(b);
  }
  IOS.fetchText = fetchText;
  const unreadable = (t) => !t.trim() || t.trim().startsWith("<") || t.includes("\u0000");
  H.animationSource = async function (a) {
    if (a.sourceDatabase === "sparking") return IOS.sparkingAnimationSource(a);
    const path = a.path;
    if (!IOS.validAnimationPath(path)) throw fail("Choose an animation from the browser");
    if (!a.originalOnly) {
      const b = await read({ assetKey: a.assetKey || null, assets: null }, "lua/" + path, 2 * MiB);
      if (b) { const t = new TextDecoder().decode(b); if (unreadable(t)) throw fail("Unreadable imported animation file"); return { path, text: t, cached: true, local: true }; }
    }
    const file = "animation-sources/" + (await IOS.dbKey()) + "/" + path;
    const had = await host.exists(file);
    const t = had ? await host.readText(file) : await fetchText(ORIGIN + "/cdn/uncompressed/lua/" + path, 2 * MiB);
    if (unreadable(t)) throw fail("Unreadable animation file");
    if (!had) await host.writeText(file, t);
    return { path, text: t, cached: had };
  };
  H.animationCatalog = async function (a) {
    const kind = a.sourceDatabase === "sparking" ? "sparking" : "main";
    const { path, schema } = await IOS.openDb(kind);
    const qs = JSON.parse(await IOS.siteText("data/animation-queries.json", 100000));
    const sqls = qs.filter((q) => (q.tables || []).every((t) => schema[t])).map((q) => q.sql);
    if (!sqls.length) return { items: [], more: false };
    const where = [], args = [];
    const search = String(a.search || "").slice(0, 100);
    if (search) { where.push("(unitName LIKE ? OR moveName LIKE ?)"); args.push("%" + search + "%", "%" + search + "%"); }
    if ((a.kind || "all") !== "all") { where.push("kind=?"); args.push(String(a.kind)); }
    if (Number(a.unitId) > 0) { where.push("unitId=?"); args.push(String(Math.trunc(a.unitId))); }
    const offset = Math.max(0, Math.min(100000, Math.trunc(Number(a.offset) || 0)));
    const text = "SELECT * FROM (" + sqls.join(" UNION ALL ") + ")" + (where.length ? " WHERE " + where.join(" AND ") : "") + " ORDER BY unitId=0, unitName, moveName, unitId, key LIMIT ? OFFSET ?";
    const items = await IOS.sql(path, text, args.concat(["13", String(offset)]));
    if (kind === "sparking") for (const r of items) r.sourceDatabase = "sparking";
    const more = items.length > 12;
    if (more) items.splice(12, 1);
    return { items, more, offset };
  };
  H.animationVisuals = async function (a) {
    const id = Math.trunc(Number(a.unitId) || 0);
    if (id < 1) throw fail("Choose a character");
    const sess = { assetKey: "", assets: null, effectPacks: [], sparkingIds: [], sourceDatabase: "eclipse", version: 0 };
    const meta = await IOS.previewMetadata(sess, ORIGIN + "/api/card/" + id);
    const items = [];
    const ok = (rel) => typeof rel === "string" && /^[a-z0-9_./-]+\.lwf$/i.test(rel) && IOS.safePath(rel);
    for (const [k, label] of [["battle", "Battle poses"], ["idle", "Idle poses"], ["sp", "Attack poses"], ["card_bg", "Animated card background"]]) {
      const rel = meta[k] && meta[k].rel; if (ok(rel)) items.push({ name: meta.name + " · " + label, path: rel });
    }
    try {
      if (meta.aura_effect_id > 0) {
        const pack = await IOS.previewMetadata(sess, ORIGIN + "/api/effect-pack/" + meta.aura_effect_id);
        if (pack.lwf && ok(pack.lwf.rel)) items.push({ name: meta.name + " · Aura", path: pack.lwf.rel, scene: pack.scene_name });
      }
    } catch (e) {}
    return { items };
  };

  // ---------------------------------------------------------------- move music (GameBgm / PreviewBgm)
  IOS.bgmContext = async function (sess) {
    const vp = sess.verifiedMusic;
    if (!/^ab_script\/finish_skill\/[A-Za-z0-9_]{1,80}\.lua$/.test(vp || "")) return { version: 1, found: false, reason: "This preview has no verified finish-skill music context." };
    try {
      const db = await databaseFile(sess.sourceDatabase, sess.version);
      const rows = await IOS.sql(db, "SELECT DISTINCT f.bgm_id AS id FROM finish_skill_sets f JOIN special_views v ON v.id=f.special_view_id WHERE v.script_name=? LIMIT 3", [vp.split("/").pop().replace(/\.lua$/, "")]);
      if (!rows.length) return { version: 1, found: false, reason: "This move has no music selected in the imported game database." };
      if (rows.length > 1) return { version: 1, found: false, reason: "This move has multiple different music contexts." };
      const id = rows[0].id;
      if (!IOS.isInt(id, 1, 2147483647)) throw fail("Invalid game music context");
      return { version: 1, found: true, scriptPath: vp, id, package: "bgm_" + pad(id, 3) };
    } catch (e) { return { version: 1, found: false, reason: "The imported game database cannot resolve this move’s music." }; }
  };
  async function bgmDescriptor(sess) {
    if (sess.bgm) return sess.bgm;
    const ctx = sess.req ? sess.req.bgmContext : await IOS.bgmContext(sess);
    let source = null;
    if (ctx.found && /^bgm_[0-9]{3,10}$/.test(ctx.package)) {
      const acb = await resolve(sess, "/assets/bgm/" + ctx.package + ".acb"), awb = await resolve(sess, "/assets/bgm/" + ctx.package + ".awb");
      if (acb || awb) {
        if (!acb || !awb) throw fail("Imported move music is missing its matching cue sheet or waveform bank. Import the complete music pair.");
        const dir = (p) => p.slice(0, p.lastIndexOf("/"));
        if (dir(acb.path) !== dir(awb.path)) throw fail("Imported move music must use a cue sheet and waveform from the same collection and folder.");
        const id = IOS.randomHex(16);
        sess.bgmFiles = { [id + ".acb"]: acb.path, [id + ".awb"]: awb.path };
        source = { kind: "imported", acb: { url: "/_forge/bgm-bank-assets/" + id + ".acb", size: acb.size }, awb: { url: "/_forge/bgm-bank-assets/" + id + ".awb", size: awb.size } };
      } else source = { kind: "public", acb: { url: "/_forge/bgm-source.acb" }, awb: { url: "/_forge/bgm-source.awb" } };
    }
    return (sess.bgm = { version: 1, context: ctx, source });
  }
  IOS.bgmRoute = async function (sess, path, query) {
    if (query) return IOS.text(404, "");
    if (sess.closed) throw fail("This music preview has closed");
    const d = await bgmDescriptor(sess);
    if (path === "/_forge/bgm-source") return IOS.json(200, d);
    const m = /^\/_forge\/bgm-source\.(acb|awb)$/.exec(path);
    if (m) {
      if (!d.source || d.source.kind !== "public") return IOS.text(404, "");
      const url = ORIGIN + "/cdn/uncompressed/bgm/" + d.context.package + "." + m[1];
      const { base } = await IOS.previewCache.ensure(url, m[1] === "acb" ? 32 * MiB : 160 * MiB);
      return { status: 200, headers: { "Content-Type": "application/octet-stream", "Accept-Ranges": "bytes" }, file: base + ".body", range: true };
    }
    const b = /^\/_forge\/bgm-bank-assets\/([a-f0-9]{32}\.(acb|awb))$/.exec(path);
    const f = b && sess.bgmFiles && sess.bgmFiles[b[1]];
    if (!f) return IOS.text(404, "");
    return { status: 200, headers: { "Content-Type": "application/octet-stream", "Accept-Ranges": "bytes" }, file: f, range: true };
  };

  // ---------------------------------------------------------------- imported sound / voice banks (AudioBanks)
  function identity(rel) {
    let m = /^se\/([A-Za-z0-9_-]{1,80})\.acb$/i.exec(rel);
    if (m) return { kind: "se", pkg: m[1], locale: "" };
    m = /^voice\/(?:(en|ja)\/)?([A-Za-z0-9_-]{1,80})\/([A-Za-z0-9_-]{1,80})\.acb$/i.exec(rel);
    if (m && m[2].toLowerCase() === m[3].toLowerCase()) return { kind: "voice", pkg: m[2], locale: (m[1] || "").toLowerCase() };
    return null;
  }
  async function audioCatalog(sess) {
    if (sess.audio) return sess.audio;
    const banks = [], warnings = [], files = {};
    if (!(await host.exists("assets"))) return (sess.audio = { catalog: { version: 1, banks, warnings }, files });
    const cands = new Map();
    const add = (c) => { const k = c.id.kind + "|" + c.id.locale + "|" + c.id.pkg.normalize("NFC").toLowerCase(); if (!cands.has(k)) cands.set(k, []); cands.get(k).push(c); };
    const overlay = overlayMap(sess.assets);
    for (const [gp, key] of overlay) {
      const id = identity(gp); if (!id) continue;
      const acb = await host.stat(A + key);
      if (!acb) throw fail("The selected audio bank is unavailable");
      const awbKey = overlay.get(gp.replace(/\.acb$/i, ".awb")) || key.replace(/\.acb$/i, ".awb");
      const awb = await host.stat(A + awbKey);
      add({ id, key, explicit: true, acb: { path: A + key, size: acb.size }, awb: awb ? { path: A + awbKey, size: awb.size } : null });
    }
    const groups = new Set([sess.assetKey, ...[...overlay.values()]].filter(Boolean).map((k) => k.split("/")[0]));
    const top = (await host.list(A)).filter((f) => f.dir && safe(f.name)).sort((a, b) => (a.name < b.name ? -1 : 1)).slice(0, 512);
    for (const c of top) {
      const bases = [c.name, c.name + "/files", c.name + "/tutorial0"];
      for (const p of await host.list(A + c.name + "/Payload").catch(() => [])) if (p.dir && /^[A-Za-z0-9_. -]{1,120}\.app$/.test(p.name)) bases.push(c.name + "/Payload/" + p.name, c.name + "/Payload/" + p.name + "/tutorial0");
      for (const base of bases) {
        const subs = ["se"];
        for (const L of ["", "en/", "ja/"]) for (const d of await host.list(A + base + "/voice/" + L).catch(() => [])) if (d.dir && /^[A-Za-z0-9_-]{1,80}$/.test(d.name) && d.name !== "en" && d.name !== "ja") subs.push("voice/" + L + d.name);
        for (const sub of subs) {
          const list = await host.list(A + base + "/" + sub).catch(() => []);
          const names = new Map();
          for (const f of list) { const k = f.name.normalize("NFC").toLowerCase(); if (names.has(k)) throw fail("Imported audio filenames are ambiguous"); names.set(k, f); }
          for (const f of list) {
            if (f.dir || !/\.acb$/i.test(f.name)) continue;
            const id = identity(sub + "/" + f.name); if (!id) continue;
            if (f.size < 1 || f.size > 32 * MiB) throw fail("Imported audio bank exceeds its supported size");
            const aw = names.get(f.name.replace(/\.acb$/i, ".awb").normalize("NFC").toLowerCase());
            if (aw && (aw.size < 1 || aw.size > 160 * MiB)) throw fail("Imported audio bank exceeds its supported size");
            add({ id, key: base + "/" + sub + "/" + f.name, group: c.name, acb: { path: A + base + "/" + sub + "/" + f.name, size: f.size }, awb: aw ? { path: A + base + "/" + sub + "/" + aw.name, size: aw.size } : null });
          }
        }
      }
    }
    for (const list of cands.values()) {
      let pick = list.filter((c) => c.explicit);
      if (!pick.length) pick = list.filter((c) => groups.has(c.group));
      if (!pick.length) pick = list;
      pick.sort((a, b) => (a.key < b.key ? -1 : 1));
      if (pick.length > 1) {   // drop byte-identical copies
        const uniq = [];
        for (const c of pick) {
          let dup = false;
          for (const u of uniq) {
            if (u.group === c.group && u.acb.size === c.acb.size && (u.awb ? u.awb.size : -1) === (c.awb ? c.awb.size : -1)) {
              const h1 = await host.call("sha256", { path: u.acb.path }), h2 = await host.call("sha256", { path: c.acb.path });
              if (h1.sha256 === h2.sha256) { dup = true; break; }
            }
          }
          if (!dup) uniq.push(c);
        }
        pick = uniq;
      }
      const c = pick[0];
      if (pick.length === 1) {
        const id = IOS.randomHex(16);
        files[id + ".acb"] = c.acb;
        const bank = { id, kind: c.id.kind, package: c.id.pkg, locale: c.id.locale, acb: { url: "/_forge/audio-bank-assets/" + id + ".acb", size: c.acb.size } };
        if (c.awb) { files[id + ".awb"] = c.awb; bank.awb = { url: "/_forge/audio-bank-assets/" + id + ".awb", size: c.awb.size }; }
        if (banks.length < 4096) banks.push(bank);
      } else if (warnings.length < 64) warnings.push("More than one imported " + c.id.kind + " bank supplies " + c.id.pkg + " (" + (c.id.locale || "default") + "). Select a single source collection to preview it.");
    }
    return (sess.audio = { catalog: { version: 1, banks, warnings }, files });
  }
  IOS.audioBankRoute = async function (sess, path, query) {
    if (query) return IOS.text(404, "");
    const { catalog, files } = await audioCatalog(sess);
    if (path === "/_forge/audio-banks") return IOS.json(200, catalog);
    const m = /^\/_forge\/audio-bank-assets\/([a-f0-9]{32}\.(acb|awb))$/.exec(path);
    const f = m && files[m[1]];
    if (!f) return IOS.text(404, "");
    const st = await host.stat(f.path);
    if (!st || st.size !== f.size) throw fail("The selected imported audio bank changed or is unavailable");
    return { status: 200, headers: { "Content-Type": "application/octet-stream", "Accept-Ranges": "bytes" }, file: f.path, range: true };
  };

  // ---------------------------------------------------------------- bridge: imported files
  H.assets = async function (a) {
    if (!(await host.exists("assets"))) throw fail("The imported asset folder is unavailable.");
    const q = String(a.query || "").toLowerCase();
    let skip = Math.max(0, a.offset | 0);
    const limit = Math.max(1, Math.min(500, a.limit == null ? 100 : a.limit | 0));
    const all = (await host.list(A, true)).filter((f) => !f.name.split("/").includes("_databases"));
    // depth-first order: compare by path with directories ending in "/"
    const keyOf = (n) => n.split("/").map((s, i, arr) => (i < arr.length - 1 ? s + "/" : s));
    all.sort((x, y) => { const a1 = keyOf(x.name), b1 = keyOf(y.name); for (let i = 0; i < Math.min(a1.length, b1.length); i++) if (a1[i] !== b1[i]) return a1[i] < b1[i] ? -1 : 1; return a1.length - b1.length; });
    const out = [];
    for (const f of all) {
      if (!f.name.toLowerCase().includes(q)) continue;
      if (skip > 0) { skip--; continue; }
      const parts = f.name.split("/"), name = parts[parts.length - 1];
      out.push({ key: f.name, path: (parts.length > 1 ? parts.slice(1).join("/") : f.name).replace(/^files\//, ""), name, size: f.size, image: /\.(png|jpe?g|webp|gif|bmp)$/i.test(name) });
      if (out.length >= limit) break;
    }
    return out;
  };
  H.assetUrl = async (a) => host.fileUrl("assets/" + String(a.key));
  H.assetStatus = async function (a) {
    const keys = a.keys;
    if (!Array.isArray(keys) || keys.length > 500 || !(await host.exists("assets"))) throw fail("The attached files could not be checked safely.");
    const out = [];
    for (const k of keys) {
      if (typeof k !== "string" || !k || k.length > 500 || k.startsWith("/") || /[\\:\x00-\x1f\x7f%]/.test(k)) throw fail("Invalid attachment key.");
      if (k.split("/").some((s) => !s || s.startsWith(".") || ["_databases", "projects", "patches", "exports"].includes(s.toLowerCase()))) throw fail("Invalid attachment key.");
      const st = await host.stat(A + k);
      const bytes = st && !st.dir ? st.size : 0;
      out.push({ key: k, bytes, available: !!(st && !st.dir && bytes > 0 && bytes <= 536870912) });
    }
    return out;
  };
  function imageSafe(key) {
    return typeof key === "string" && key && key.length <= 500 && /\.(png|jpe?g|webp|gif|bmp|lwf|json)$/i.test(key) && !/[\\:%\x00-\x1f\x7f]/.test(key) &&
      key.split("/").every((s) => s && !s.startsWith(".") && !["_databases", "projects", "patches", "exports"].includes(s.toLowerCase()));
  }
  H.readAsset = async function (a) {
    const max = a.maxBytes == null ? 12582912 : a.maxBytes;
    if (!(typeof max === "number" && Number.isInteger(max) && max >= 1 && max <= 12582912)) throw fail(F.IMG_ERR);
    if (!imageSafe(a.key)) throw fail(F.IMG_ERR);
    const st = await host.stat(A + a.key);
    if (!st || st.dir || st.size > max) throw fail(F.IMG_ERR);
    const b = await host.readBytes(A + a.key);
    if (!b || b.length > max) throw fail(F.IMG_ERR);
    const ext = extOf(a.key).toLowerCase();
    let info;
    if (ext === "json") info = inspectDecoration(b);
    else if (ext === "lwf") { if (b.length < 16 || b.length > 12582912 || !(b[0] === 0x4c && b[1] === 0x57 && b[2] === 0x46 && b[3] === 0)) throw fail(F.IMG_ERR); info = { width: 0, height: 0, mime: "application/octet-stream" }; }
    else info = await F.inspectImage(b, false);
    return Object.assign({}, info, { key: a.key, base64: host.toBase64(b), bytes: b.length });
  };
  const SUPPORTED = new RegExp("\\.(png|jpe?g|webp|gif|bmp|lwf|lua|usm|ogg|mp3|wav|awb|acb|atlas|plist|json|xml|tmx|bytes|cpk|fsh|vsh|fnt|ttf|otf|strings|txt|bin)$", "i");
  H.downloadAsset = async function (a) {
    const path = a.path;
    if (!IOS.safePath(path) || !SUPPORTED.test(path)) throw fail("Choose a supported resource file");
    if (a.group != null && !/^art-download-[0-9]{10,16}-[A-Za-z0-9_-]{6,64}$/.test(String(a.group))) throw fail("Invalid artwork collection.");
    const key = (a.group != null ? a.group : "eclipse") + "/" + path;
    if (!safe(key)) throw fail("Invalid asset collection.");
    if (a.group != null && (await host.exists(A + key))) throw fail("This artwork collection already contains that resource.");
    const url = ORIGIN + "/cdn/uncompressed/" + path.split("/").map(encodeURIComponent).join("/");
    const tmp = A + key.slice(0, key.lastIndexOf("/") + 1) + ".download-" + IOS.randomHex(8) + ".tmp";
    try {
      let r;
      try { r = await host.download(url, tmp, { headers: { "User-Agent": "DokkanUnitCreator/2.7", "Accept-Encoding": "identity" }, keepErrors: true }); }
      catch (e) { throw fail("Couldn't reach Dokkan Eclipse. Check your internet connection."); }
      if (r.status !== 200) throw fail("Eclipse returned HTTP " + r.status + ".");
      if (r.bytes > 167772160) throw fail("Resource download exceeds160MB.");
      await host.move(tmp, A + key);
      IOS.invalidateAssets();
      return { key, path, name: path.split("/").pop(), size: r.bytes, image: /\.(png|jpe?g|webp|gif|bmp)$/i.test(path) };
    } finally { await host.remove(tmp).catch(() => {}); }
  };
  H.browseAssets = async function (a) {
    const path = a.path == null ? "" : String(a.path);
    if (path && !IOS.safePath(path)) throw fail("Invalid resource path");
    return JSON.parse(await fetchText(ORIGIN + "/api/file-browser?path=" + encodeURIComponent(path), 8388608));
  };
  function strictBase64(s, max, err) {
    if (typeof s !== "string" || s.length > max || s.length % 4 || !/^[A-Za-z0-9+/]*={0,2}$/.test(s)) throw fail(err);
    let bin; try { bin = atob(s); } catch (e) { throw fail(err); }
    const b = new Uint8Array(bin.length); for (let i = 0; i < bin.length; i++) b[i] = bin.charCodeAt(i);
    if (host.toBase64(b) !== s) throw fail(err);
    return b;
  }
  const cleanName = (n, d) => String(n == null ? d : n).replace(/[\x00-\x1f\x7f]/g, "").slice(0, 160);
  async function storeNew(dir, file, bytes) {
    if (!(await host.exists("assets"))) await host.mkdir("assets");
    const key = dir + "/" + file;
    try { await host.writeBytes(A + key, bytes); } catch (e) { await host.remove(A + dir).catch(() => {}); throw e; }
    IOS.invalidateAssets();
    return key;
  }
  H.storeAsset = async function (a) {
    const b = strictBase64(a.data, 16777216, F.IMG_ERR);
    const info = await F.inspectImage(b, true);
    const key = await storeNew("generated-" + IOS.uuid4(), "image.png", b);
    return { width: info.width, height: info.height, mime: "image/png", key, path: "image.png", name: cleanName(a.name, "Custom artwork"), size: b.length, image: true };
  };
  const DEC_ERR = "The card decoration metadata is invalid. Import its original artwork again.";
  function decSafe(s) { return typeof s === "string" && s && s.length <= 500 && !s.startsWith("/") && !/[\\:\x00-\x1f\x7f%]/.test(s) && s.split("/").every((x) => x && !x.startsWith(".")); }
  function inspectDecoration(b) {
    if (b.length < 1 || b.length > 131072) throw fail(DEC_ERR);
    let t; try { t = new TextDecoder("utf-8", { fatal: true }).decode(b).trim(); } catch (e) { throw fail(DEC_ERR); }
    let inStr = false, esc = false, depth = 0;
    for (const ch of t) {
      if (inStr) { if (esc) esc = false; else if (ch === "\\") esc = true; else if (ch === '"') inStr = false; continue; }
      if (ch === '"') inStr = true;
      else if (ch === "{" || ch === "[") { if (++depth > 32) throw fail(DEC_ERR); }
      else if (ch === "}" || ch === "]") { if (--depth < 0) throw fail(DEC_ERR); }
    }
    if (inStr || depth || !t.startsWith("{") || !t.endsWith("}")) throw fail(DEC_ERR);
    let j; try { j = JSON.parse(t); } catch (e) { throw fail(DEC_ERR); }
    if (!IOS.isInt(j.card_id, 1, 2147483647) || typeof j.shader_file !== "string" || !decSafe(j.shader_file) || !Array.isArray(j.parameters) || j.parameters.length > 128) throw fail(DEC_ERR);
    for (const p of j.parameters) {
      if (!p || typeof p.type !== "string" || typeof p.name !== "string") throw fail(DEC_ERR);
      if (p.type === "sampler2D" && !(typeof p.value === "string" && decSafe(p.value))) throw fail(DEC_ERR);
    }
    return { width: 0, height: 0, mime: "application/json" };
  }
  H.storeDecoration = async function (a) {
    if (typeof a.text !== "string" || a.text.length > 131072) throw fail(DEC_ERR);
    const b = new TextEncoder().encode(a.text);
    inspectDecoration(b);
    const key = await storeNew("generated-decoration-" + IOS.uuid4(), "decoration.json", b);
    return { width: 0, height: 0, mime: "application/json", key, path: "decoration.json", name: "Custom card decoration", size: b.length, image: false };
  };
  H.storeLwf = async function (a) {
    const b = strictBase64(a.data, 16777216, F.LWF_ERR);
    const info = F.inspectLwf(b);
    const key = await storeNew("generated-lwf-" + IOS.uuid4(), "animation.lwf", b);
    return Object.assign({}, info, { key, path: "animation.lwf", name: cleanName(a.name, "Custom character animation"), size: b.length, image: false });
  };
  // chunked movie upload (MovieStorage)
  const jobs = new Map();
  const STAGE = ".forge-movie-uploads-v1/";
  H.storeMovie = async function (a) {
    const M = (m) => fail("Movie: " + m);
    const now = Date.now();
    for (const [id, j] of jobs) if (now - j.touched >= 600000) { jobs.delete(id); await host.remove(STAGE + "upload-" + id + ".part").catch(() => {}); }
    if (typeof a.action !== "string") throw M("Choose a valid movie upload action.");
    const allowed = { begin: ["action", "name"], append: ["action", "uploadId", "offset", "data"], finish: ["action", "uploadId"], cancel: ["action", "uploadId"] }[a.action];
    if (!allowed) throw M("Invalid movie upload action.");
    if (Object.keys(a).some((k) => !allowed.includes(k))) throw M("Invalid movie upload arguments.");
    if (a.action === "begin") {
      if (jobs.size > 3) throw M("Finish or cancel another movie upload first.");
      if ("name" in a && !(typeof a.name === "string" && a.name.length <= 160)) throw M("Choose a movie name of 160 characters or less.");
      const name = String(a.name == null ? "Custom movie" : a.name).replace(/[\x00-\x1f\x7f]/g, "") || "Custom movie";
      const id = IOS.uuid4();
      await host.writeText(STAGE + "upload-" + id + ".part", "");
      jobs.set(id, { name, bytes: 0, touched: now });
      return { uploadId: id };
    }
    const id = a.uploadId, job = typeof id === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(id) ? jobs.get(id) : null;
    if (!job) throw M("This movie upload expired or was canceled. Start it again.");
    const part = STAGE + "upload-" + id + ".part";
    const discard = async () => { jobs.delete(id); await host.remove(part).catch(() => {}); };
    if (a.action === "cancel") { await discard(); return { canceled: true }; }
    const st = await host.stat(part);
    if (!st || st.dir || st.size !== job.bytes) { await discard(); throw M("The temporary movie file changed."); }
    if (a.action === "append") {
      if (!(typeof a.offset === "number" && a.offset === job.bytes)) throw M("Movie chunks must arrive in their original order. Retry this chunk.");
      let b; try { b = strictBase64(a.data, 349528, "x"); } catch (e) { throw M("Invalid movie chunk."); }
      if (!a.data || b.length < 1 || b.length > 262144) throw M("Invalid movie chunk.");
      const total = [...jobs.values()].reduce((n, j) => n + j.bytes, 0);
      if (job.bytes + b.length > 100663296 || total + b.length > 402653184) { await discard(); throw M("Movie uploads are limited to 96 MB per movie and 384 MB total."); }
      try { await host.call("write", { path: part, base64: a.data, append: true }); } catch (e) { await discard(); throw e; }
      job.bytes += b.length; job.touched = Date.now();
      return { bytes: job.bytes };
    }
    let info;
    try {
      const blob = new Blob([await host.readBytes(part)]);
      info = await F.inspectUsm(blob);
    } catch (e) { await discard(); throw e; }
    const dir = "generated-movie-" + IOS.uuid4();
    try { await host.move(part, A + dir + "/movie.usm"); } catch (e) { await discard(); await host.remove(A + dir).catch(() => {}); throw M("The movie destination is unavailable."); }
    jobs.delete(id);
    IOS.invalidateAssets();
    return Object.assign({}, info, { storageTag: id.replace(/-/g, ""), key: dir + "/movie.usm", path: "movie.usm", size: job.bytes, name: job.name, image: false });
  };

  // ---------------------------------------------------------------- the finder's card list (ForgeFixes.cardIndex)
  H.cardIndex = async function () {
    const { path, schema } = await IOS.openDb("main").catch(() => { throw fail("Game data is not ready yet."); });
    const have = new Set((schema.cards || []).map((c) => c.name));
    for (const c of ["id", "name", "hp_max", "passive_skill_set_id", "leader_skill_set_id"]) if (!have.has(c)) throw fail("This game data has no " + c + " column.");
    const want = ["id", "name", "rarity", "element", "open_at", "hp_max", "atk_max", "def_max", "resource_id", "passive_skill_set_id", "leader_skill_set_id", "optimal_awakening_grow_type"];
    const sel = want.map((c) => (have.has(c) ? '"' + c + '"' : "NULL") + " AS " + c).join(", ");
    const r = await host.call("sql", { db: path, sql: "SELECT " + sel + " FROM cards WHERE id % 10 = 1 AND ((id >= 1000000 AND id < 3000000) OR id >= 10000000) AND hp_max > 300 AND passive_skill_set_id IS NOT NULL AND leader_skill_set_id IS NOT NULL ORDER BY id", params: [] });
    return r.rows.map((x) => {
      const open = String(x[4] == null ? "" : x[4]).slice(0, 10).replace(/-/g, "");
      return [x[0], x[1] || "", x[2] || 0, x[3] || 0, /^[0-9]{8}$/.test(open) ? Number(open) : 0, x[5] || 0, x[6] || 0, x[7] || 0, x[8] || 0, x[9] || 0, x[10] || 0, x[11] == null ? null : x[11]];
    });
  };
})();
