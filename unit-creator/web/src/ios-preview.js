/* iPhone app: the animation player, exactly like the Android app.
 * The native side (ios-objc/Player.m) runs a private web server on 127.0.0.1 and shows the player
 * panel; every request of the Eclipse player arrives here (ForgePreviewServer.handle) and is answered
 * the way Android's PreviewServer / PreviewCache / PreviewResources / GameAssets… answer it.
 * Answer shape: {status, headers, body | base64 | file ("site:<path>" = the app's own files), range}. */
(function () {
  "use strict";
  const IOS = window.__forgeIOS;
  if (!IOS) return;
  const { host, H } = IOS;
  const fail = (m) => new Error(m);
  const SITE = "https://dokkan-eclipse.com", CDN = "https://cdn.dokkan-eclipse.com/uncompressed";
  const MiB = 1048576;
  const enc = new TextEncoder(), dec = new TextDecoder();
  const sha256Hex = (bytes) => IOS.sha256Hex(typeof bytes === "string" ? enc.encode(bytes) : bytes);
  const json = (status, value, extra) => ({ status, headers: Object.assign({ "Content-Type": "application/json" }, extra || {}), body: JSON.stringify(value) });
  const text = (status, message) => ({ status, headers: { "Content-Type": "text/plain; charset=utf-8" }, body: String(message || "") });
  const randomHex = (n) => Array.from(crypto.getRandomValues(new Uint8Array(n)), (b) => b.toString(16).padStart(2, "0")).join("");
  async function siteText(path, max) {
    const r = await fetch(path, { cache: "no-store" });
    if (!r.ok) throw fail("A packaged movie component is missing. Reinstall the app.");
    const t = await r.text();
    if (max && t.length > max) throw fail("Preview text exceeds the size limit");
    return t;
  }

  // ---------------------------------------------------------------- PreviewCache (FORGE/preview-cache)
  const CACHE_DIR = "preview-cache/";
  const SIZES = [536870912, 1, 2, 4, 8, 16, 32].map((k, i) => (i ? k * 1073741824 : k));
  let cfgCache = null, revision = 0, totalBytes = null;
  async function settings() {
    if (cfgCache) return cfgCache;
    try { cfgCache = (await host.exists(CACHE_DIR + "settings.json")) ? (await host.readJson(CACHE_DIR + "settings.json")) || {} : {}; } catch (e) { cfgCache = {}; }
    return cfgCache;
  }
  const storageLimit = (cfg) => (SIZES.includes(cfg.maxBytes) ? cfg.maxBytes : 2147483648);
  async function offline() { try { return !!(await settings()).offline; } catch (e) { return false; } }
  function normalized(url) {
    let u;
    try { u = new URL(url); } catch (e) { throw fail("Unsupported public preview resource"); }
    if (u.protocol !== "https:" || u.hostname !== "dokkan-eclipse.com" || u.port || u.username || u.password ||
        !/^\/(tools\/.*|assets\/.*|static\/.*|css\/.*|cdn\/uncompressed\/.*|api\/.*)$/.test(u.pathname)) throw fail("Unsupported public preview resource");
    const raw = url.slice(url.indexOf(u.host) + u.host.length).split("?")[0].split("#")[0];
    const q = u.search.slice(1);
    const params = new Map();
    if (q) for (const part of q.split("&")) {
      const i = part.indexOf("="), k = decodeURIComponent((i < 0 ? part : part.slice(0, i)).replace(/\+/g, " ")), v = i < 0 ? "" : decodeURIComponent(part.slice(i + 1).replace(/\+/g, " "));
      if (k === "patch") throw fail("Private patch previews are not cached");
      if (/^(_|_t|t|ts|timestamp|cacheBust|nocache)$/.test(k) && /^[0-9]+$/.test(v)) continue;
      params.set(k, v);
    }
    const form = (s) => encodeURIComponent(s).replace(/%20/g, "+").replace(/[!'()~]/g, (c) => "%" + c.charCodeAt(0).toString(16).toUpperCase()).replace(/\*/g, "*");
    const keys = [...params.keys()].sort();
    return SITE + raw + (keys.length ? "?" + keys.map((k) => form(k) + "=" + form(params.get(k))).join("&") : "");
  }
  const inflight = new Map();
  async function ensure(url, limit) {
    limit = limit || 160 * MiB;
    const n = normalized(url), base = CACHE_DIR + (await sha256Hex(n));
    if ((await host.exists(base + ".body")) && (await host.exists(base + ".json"))) return { base, url: n };
    if (await offline()) throw fail("This resource has not been saved for offline preview");
    if (inflight.has(base)) { await inflight.get(base); return ensure(url, limit); }
    const job = (async () => {
      const tmp = base + ".tmp";
      try {
        const r = await host.download(n, tmp, { headers: { "User-Agent": "DokkanUnitCreator/2.5" }, keepErrors: true });
        if (r.status !== 200) throw fail("Eclipse returned HTTP " + r.status);
        if (r.bytes > limit) throw fail("Preview resource exceeds 160 MB");
        const cfg = await settings();
        if (totalBytes == null) totalBytes = (await cacheUsage()).bytes;
        if (totalBytes + r.bytes > storageLimit(cfg)) throw fail("Saved preview storage is full. Increase its size or clear downloaded previews in Animation Studio.");
        try { await host.move(tmp, base + ".body"); } catch (e) { throw fail("Could not save preview"); }
        await host.writeJson(base + ".json", { url: n, type: r.contentType || "application/octet-stream" });
        totalBytes += r.bytes;
      } finally { await host.remove(tmp).catch(() => {}); }
    })();
    inflight.set(base, job);
    try { await job; } finally { inflight.delete(base); }
    return { base, url: n };
  }
  async function cacheUsage() {
    // added up on the phone (in the background), not by sending every file's details to the page
    try { const u = await host.call("usage", { path: CACHE_DIR, suffix: ".body" }); if (u && typeof u.bytes === "number") return { bytes: u.bytes, count: u.count || 0 }; } catch (e) {}
    let bytes = 0, count = 0;
    for (const f of await host.list(CACHE_DIR)) if (/^[a-f0-9]{64}\.body$/.test(f.name)) { bytes += f.size; count++; }
    return { bytes, count };
  }
  async function cacheText(url, max) {
    const { base } = await ensure(url);
    const st = await host.stat(base + ".body");
    if (max && st && st.size > max) throw fail("Preview text exceeds the size limit");
    return host.readText(base + ".body");
  }
  async function cacheType(base) { const m = await host.readJson(base + ".json"); return String((m && m.type) || "application/octet-stream").split(";")[0].trim(); }
  async function cachedBody(url) { const base = CACHE_DIR + (await sha256Hex(normalized(url))); return (await host.exists(base + ".body")) && (await host.exists(base + ".json")) ? base + ".body" : null; }
  async function discard(url) { const base = CACHE_DIR + (await sha256Hex(normalized(url))); for (const x of [".body", ".json", ".tmp", ".json.tmp"]) await host.remove(base + x).catch(() => {}); totalBytes = null; }
  const PC = (IOS.previewCache = { ensure, cacheText, cachedBody, discard, normalized, offline, settings, cacheType });

  H.previewCache = async function (a) {
    if ("clear" in a && typeof a.clear !== "boolean") throw fail("Invalid preview storage request.");
    if ("maxBytes" in a && !(typeof a.maxBytes === "number" && SIZES.includes(a.maxBytes))) throw fail("Choose one of the preview storage sizes.");
    const cfg = Object.assign({}, await settings());
    if ("maxBytes" in a) cfg.maxBytes = a.maxBytes;
    if (typeof a.offline === "boolean") { if (!!cfg.offline !== a.offline) revision++; cfg.offline = a.offline; }
    if (a.clear === true) {
      revision++;
      try { for (const f of await host.list(CACHE_DIR)) if (/^[a-f0-9]{64}\.(body|json|tmp)(\.tmp)?$/.test(f.name)) await host.remove(CACHE_DIR + f.name); }
      catch (e) { throw fail("Could not clear a saved preview file."); }
      totalBytes = 0;
    }
    if ("offline" in a || "maxBytes" in a) {
      try { await host.writeJson(CACHE_DIR + "settings.json", cfg); } catch (e) { throw fail("Could not save preview settings"); }
      cfgCache = cfg;
    }
    const u = await cacheUsage();
    return { offline: !!cfg.offline, bytes: u.bytes, count: u.count, maxBytes: storageLimit(cfg) };
  };

  // ---------------------------------------------------------------- player tools for offline use (PreviewTools)
  const tools = { preparing: false, label: "", failures: [] };
  let toolsManifest = null;
  async function bootstrapManifest() {
    if (toolsManifest) return toolsManifest;
    const m = JSON.parse(await siteText("data/preview-bootstrap.json", 262144));
    if (!m || m.schemaVersion !== 1 || m.origin !== SITE || !Array.isArray(m.resources)) throw fail("Unsupported preview tools manifest");
    if (!/^[a-f0-9]{64}$/.test(m.version || "")) throw fail("Invalid preview tools version");
    if (m.resources.length < 1 || m.resources.length > 256) throw fail("Invalid preview tools count");
    let total = 0; const seen = new Set();
    for (const r of m.resources) {
      const p = r.path;
      if (typeof p !== "string" || !p.startsWith("/") || p.includes("\\") || p.includes("//") || /[\x00-\x1f\x7f]/.test(p) || /(^|\/)\.\.?(\/|$|\?)/.test(p) || seen.has(p) ||
          !(/^\/(tools|static|css)\//.test(p) || p === "/api/scripts" || p === "/api/script?path=ab_script%2Fcommon%2Fcommon.lua")) throw fail("Invalid preview tools resource");
      if (!(Number.isInteger(r.bytes) && r.bytes >= 1 && r.bytes <= 2 * MiB) || !/^[a-f0-9]{64}$/.test(r.sha256 || "") || String(r.label || "").length > 160) throw fail("Invalid preview tools checksum or size");
      seen.add(p); total += r.bytes;
    }
    if (total > 16 * MiB) throw fail("Preview tools exceed their size limit");
    return (toolsManifest = m);
  }
  async function toolMatches(r) {
    const body = await cachedBody(SITE + r.path).catch(() => null);
    if (!body) return { ok: false, missing: true };
    const st = await host.stat(body);
    if (!st || st.size !== r.bytes) return { ok: false };
    const h = await host.call("sha256", { path: body });
    return { ok: h.sha256 === r.sha256 };
  }
  H.previewTools = async function (a) {
    for (const k of Object.keys(a || {})) if (k !== "prepare" || typeof a.prepare !== "boolean") throw fail("Invalid preview tools request");
    const m = await bootstrapManifest();
    if (a.prepare && !tools.preparing) {
      if (await offline()) throw fail("Connect once and switch off Offline preview to prepare the player tools.");
      tools.preparing = true; tools.failures = [];
      const rev = revision;
      (async () => {
        for (const r of m.resources) {
          if (rev !== revision) break;
          tools.label = r.label || r.path;
          try {
            if ((await toolMatches(r)).ok) continue;
            if (await offline()) throw fail("Offline preview is enabled. Connect again to finish preparing the player.");
            await discard(SITE + r.path);
            if (rev !== revision) throw fail("Preview preparation stopped because storage or offline settings changed.");
            await ensure(SITE + r.path, r.bytes);
            if (!(await toolMatches(r)).ok) { await discard(SITE + r.path); throw fail("The hosted tool changed. Update the app before saving this version."); }
          } catch (e) {
            if (tools.failures.length < 20) tools.failures.push({ path: r.path, message: e.message });
            if ((await offline()) || rev !== revision) break;
          }
        }
        tools.label = ""; tools.preparing = false;
      })();
    }
    let prepared = 0, preparedBytes = 0, missing = 0, invalid = 0, totalB = 0;
    for (const r of m.resources) {
      totalB += r.bytes;
      const s = await toolMatches(r);
      if (s.ok) { prepared++; preparedBytes += r.bytes; } else if (s.missing) missing++; else invalid++;
    }
    return { version: m.version, ready: prepared === m.resources.length, preparing: tools.preparing, preparedFiles: prepared, totalFiles: m.resources.length,
      preparedBytes, totalBytes: totalB, missingFiles: missing, invalidFiles: invalid, offline: await offline(), failures: tools.failures.slice(), currentLabel: tools.label };
  };

  // ---------------------------------------------------------------- player patches (hash-locked find/replace)
  const PATCHES = { "/tools/lua-player/js/usm-player.js": "media-player-patches.json", "/tools/lua-player/js/audio-bus.js": "audio-player-patches.json", "/tools/lwf-player/js/lwf-pack.js": "lwf-player-patches.json" };
  const TRAINING = new Set(["binders.js", "runner.js", "tcb-keys.js", "lwf-player.js", "recorder.js", "atlas-fit.js", "app.js"].map((f) => "/tools/lua-player/js/" + f).concat(["/static/vendor/lwf/lwf.js"]));
  const manifests = new Map();
  async function manifestFile(name) { if (!manifests.has(name)) manifests.set(name, siteText(name).then(JSON.parse)); return manifests.get(name); }
  async function playerPatches(path, s) {
    let m = null;
    if (PATCHES[path]) m = await manifestFile(PATCHES[path]);
    else if (TRAINING.has(path)) {
      const t = await manifestFile("training-player-patches.json");
      m = (t.manifests || []).find((x) => x.path === path);
      if (!m) throw fail("The packaged item scene adapter is incompatible. Update Dokkan Unit Creator.");
    } else return s;
    if (m.path !== path) throw fail("The packaged player adapter is incompatible. Update Dokkan Unit Creator.");
    const changed = () => fail("The public player changed. Update Dokkan Unit Creator before previewing this animation.");
    if ((await sha256Hex(s)) !== m.sourceSha256) throw changed();
    for (const p of m.patches || []) {
      const i = p.find ? s.indexOf(p.find) : -1;
      if (!p.find || i < 0 || i !== s.lastIndexOf(p.find)) throw changed();
      s = s.slice(0, i) + p.replace + s.slice(i + p.find.length);
    }
    return s;
  }
  IOS.playerPatches = playerPatches;

  // ---------------------------------------------------------------- the server (one per app; a new cookie per preview)
  const S = (IOS.server = { origin: null, port: 0, session: null });
  async function serverInfo() {
    if (!S.origin) { const i = await host.call("serverInfo"); S.origin = i.origin; S.port = i.port; }
    return S;
  }
  function rewrite(s) {
    const o = S.origin, esc = (x) => x.replace(/\//g, "\\/");
    return s.split(CDN).join(o + "/cdn/uncompressed").split(esc(CDN)).join(esc(o + "/cdn/uncompressed"))
      .split(SITE).join(o).split(esc(SITE)).join(esc(o));
  }
  function transport() {
    return "window.__forgeNativeDocumentId=" + JSON.stringify(crypto.randomUUID ? crypto.randomUUID() : IOS.uuid4()) + ";(()=>{const origin=" + JSON.stringify(S.origin) +
      ";const map=u=>{const s=String(u),cdn='https://cdn.dokkan-eclipse.com/uncompressed',site='https://dokkan-eclipse.com';return s.startsWith(cdn+'/')?origin+'/cdn/uncompressed'+s.slice(cdn.length):s.startsWith(site+'/')?origin+s.slice(site.length):s};const fetch=window.fetch;window.fetch=(u,o)=>fetch(u instanceof Request?new Request(map(u.url),u):map(u),o);const open=XMLHttpRequest.prototype.open;XMLHttpRequest.prototype.open=function(m,u,...a){return open.call(this,m,map(u),...a)}})();";
  }
  IOS.rewrite = rewrite; IOS.transport = transport;
  const RESOURCES = { "/_forge/training-context.js": "training-context.js", "/_forge/native-audio.js": "native-audio.js", "/_forge/audio-bank.js": "audio-bank.js",
    "/_forge/imported-audio.js": "imported-audio.js", "/_forge/media/movie-edit-plan.js": "movie-edit-plan.js", "/_forge/media/usm-writer.js": "usm-writer.js",
    "/_forge/media/native-adx.js": "native-adx.js", "/_forge/media/hca-metadata.js": "hca-metadata.js", "/tools/usm-player/js/pipeline.js": "media-pipeline.js",
    "/tools/lua-player/js/forge-imported.js": "imported-preview.js", "/tools/usm-player/js/forge-metadata.js": "media-metadata.js" };
  function packaged(path) {
    let file = RESOURCES[path];
    const m = !file && /^\/_forge\/media\/((?:libav\/)?[A-Za-z0-9][A-Za-z0-9_.-]*)$/.exec(path);
    if (m) file = "vendor/media/" + m[1];
    if (!file) return null;
    const type = /\.wasm$/.test(file) ? "application/wasm" : /\.js$/.test(file) ? "application/javascript; charset=utf-8" : /\.json$/.test(file) ? "application/json; charset=utf-8" : "text/plain; charset=utf-8";
    return { file, type };
  }
  const MIME = { bmp: "image/bmp", gif: "image/gif", jpg: "image/jpeg", jpeg: "image/jpeg", png: "image/png", webp: "image/webp", mp3: "audio/mpeg", ogg: "audio/ogg", wav: "audio/wav",
    otf: "font/otf", ttf: "font/ttf", json: "application/json", xml: "application/xml", plist: "application/xml", lua: "text/plain", txt: "text/plain", fsh: "text/plain", vsh: "text/plain" };
  const mime = (name) => MIME[(String(name).split(".").pop() || "").toLowerCase()] || "application/octet-stream";
  const isText = (type) => /^text\//.test(type) || /javascript|json/.test(type);

  async function finishBody(path, type, readText, fileAnswer) {
    if (!isText(type)) return fileAnswer;
    let s = await readText();
    if (s.length > 64 * MiB) throw fail("Preview resource exceeds 160 MB");
    s = rewrite(await playerPatches(path, s));
    if (/^text\/html/.test(type)) {
      const inject = "<script>" + transport() + "</script><script src=\"/tools/lua-player/js/forge-imported.js\"></script>";
      const m = /<head(?:\s[^>]*)?>/i.exec(s);
      s = m ? s.slice(0, m.index + m[0].length) + inject + s.slice(m.index + m[0].length) : inject + s;
    }
    return { status: 200, headers: { "Content-Type": type.includes("charset") || !/^text\/|javascript|json/.test(type) ? type : type + "; charset=utf-8", "Accept-Ranges": "bytes" }, body: s, range: true };
  }

  async function generic(req, target, path) {
    const U = SITE + target;
    const sess = S.session;
    // 1. directory listing for visual packs
    const dir = IOS.gameDirectoryRoute ? IOS.gameDirectoryRoute(U) : null;
    if (dir) {
      const local = await IOS.gameDirectory(sess, dir);
      if (local) {
        let pub = null;
        try { pub = JSON.parse(await cacheText(U, 2 * MiB)); } catch (e) { pub = null; }
        return json(200, IOS.mergeDirectory(local, pub));
      }
    }
    // 2. card / effect metadata
    if (/^\/api\/(card|effect-pack)\/[1-9][0-9]*(\?enemy=1)?$/.test(target)) {
      const meta = await IOS.previewMetadata(sess, U);
      return { status: 200, headers: { "Content-Type": "application/json" }, body: rewrite(JSON.stringify(meta)) };
    }
    // 3. imported game file
    const imported = IOS.gameAssetResolve ? await IOS.gameAssetResolve(sess, U) : null;
    if (imported) {
      if (imported.size > 160 * MiB) throw fail("This imported preview asset exceeds 160 MB.");
      const type = mime(imported.path);
      return finishBody(path, type, () => host.readText(imported.path), { status: 200, headers: { "Content-Type": type, "Accept-Ranges": "bytes" }, file: imported.path, range: true });
    }
    // 4. the app's own packaged files
    const pkg = packaged(path);
    if (pkg) return { status: 200, headers: { "Content-Type": pkg.type, "Accept-Ranges": "bytes", "Cross-Origin-Resource-Policy": "same-origin" }, file: "site:" + pkg.file, range: true };
    // 5. public resource (saved copy, else download)
    const { base } = await ensure(U);
    const type = await cacheType(base);
    return finishBody(path, type, () => host.readText(base + ".body"),
      { status: 200, headers: { "Content-Type": type, "Accept-Ranges": "bytes", "Access-Control-Allow-Origin": "*" }, file: base + ".body", range: true });
  }

  async function handle(req) {
    await serverInfo();
    const method = req.method, target = req.target, h = req.headers || {};
    const HEAD = method === "HEAD";
    if (!/^[A-Z]{3,8}$/.test(method) || !target.startsWith("/") || target.startsWith("//") || target.includes("\\") || target.length > 8192 || /[\x00-\x1f\x7f#]/.test(target)) return text(400, "");
    const qi = target.indexOf("?"), path = qi < 0 ? target : target.slice(0, qi), query = qi < 0 ? "" : target.slice(qi + 1);
    if (path.split("/").some((seg) => seg === "." || seg === "..")) return text(400, "");
    if (h.host !== "127.0.0.1:" + S.port) return text(403, "");
    if ("transfer-encoding" in h || "expect" in h) return text(400, "");
    if (h.origin && h.origin !== S.origin) return text(403, "");
    const sess = S.session;
    if ((method === "GET" || HEAD) && sess && path === "/_forge/open/" + sess.token) {
      const tool = new URLSearchParams(query).get("tool");
      return { status: 302, headers: { Location: "/tools/" + (["lua-player", "lwf-player", "usm-player"].includes(tool) ? tool : "lua-player") + "/",
        "Set-Cookie": sess.cookie + "; Path=/; HttpOnly; SameSite=Strict" }, body: "" };
    }
    if (!sess || !String(h.cookie || "").split(";").some((c) => c.trim() === sess.cookie)) return text(403, "");
    try {
      if (method === "POST" && path === "/_forge/prepared-movies" && !query) return await IOS.prepareMovie(sess, req);
      if (method === "DELETE" && path.startsWith("/_forge/prepared-movies/")) return await IOS.deleteMovie(sess, req, path, query);
      if (!(method === "GET" || HEAD)) return text(405, "");
      if (h["content-length"] && h["content-length"] !== "0") return text(400, "");
      if (path.startsWith("/_forge/prepared-movies/")) return await IOS.preparedMovie(sess, path, query);
      if (path.startsWith("/_forge/movie-cache/")) return await IOS.movieCache(sess, path, target);
      if (path.startsWith("/_forge/stage-export/")) return await IOS.stageExport(sess, path, query, HEAD);
      if (path === "/_forge/stage-capture") return await IOS.stageCapture(sess, query, HEAD);
      if (["/_forge/bgm-source", "/_forge/bgm-source.acb", "/_forge/bgm-source.awb"].includes(path) || path.startsWith("/_forge/bgm-bank-assets/")) return await IOS.bgmRoute(sess, path, query);
      if (path === "/_forge/audio-banks" || path.startsWith("/_forge/audio-bank-assets/")) return await IOS.audioBankRoute(sess, path, query);
      if (path.startsWith("/_forge/") && !["/_forge/training-context.js", "/_forge/native-audio.js", "/_forge/audio-bank.js", "/_forge/imported-audio.js"].includes(path) && !/^\/_forge\/media\/(libav\/)?[A-Za-z0-9][A-Za-z0-9_.-]*$/.test(path)) return text(404, "");
      if (target === "/api/scripts") { try { return json(200, await IOS.scriptListing()); } catch (e) { return text(503, e.message); } }
      return await generic(req, target, path);
    } catch (e) {
      return text(503, (e && e.message) || "The preview file could not be prepared.");
    }
  }
  window.ForgePreviewServer = { handle };
  IOS.handleServer = handle;
  Object.assign(IOS, { json, text, mime, randomHex, siteText, SITE, CDN, MiB });
})();
