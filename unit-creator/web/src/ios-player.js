/* iPhone app: opening an animation preview (Android: CreatorActivity.previewAnimation, PreviewDock,
 * PreviewBootstrap, WebViewStartup), plus prepared movies, the movie cache and "Save video". */
(function () {
  "use strict";
  const IOS = window.__forgeIOS;
  if (!IOS || !IOS.server) return;
  const { host, H, json, text, MiB } = IOS;
  const fail = (m) => new Error(m);
  const S = IOS.server;

  // ---------------------------------------------------------------- checks shared with Android
  function safePath(p) {
    if (typeof p !== "string" || !p || p.length > 500 || p.startsWith("/") || p.includes("\\") || /[:\x00-\x1f]/.test(p)) return false;
    return p.split("/").every((s) => s && s !== "." && s !== "..");
  }
  const validAnimationPath = (p) => typeof p === "string" && p.length < 240 && /^ab_script\/[a-z0-9_/-]+\.lua$/i.test(p) && safePath(p);
  const isInt = (v, lo, hi) => typeof v === "number" && Number.isFinite(v) && Math.floor(v) === v && v >= lo && v <= hi;
  IOS.safePath = safePath; IOS.validAnimationPath = validAnimationPath; IOS.isInt = isInt;
  function normalizeVersion(v) {
    if (v == null) return 0;
    if (!isInt(v, 1, 9007199254740991)) throw fail("Choose a valid Sparking content version.");
    return v;
  }
  function sparkingEffects(v) {
    if (v == null) return [];
    if (!Array.isArray(v) || v.length > 1024) throw fail("Choose up to 1024 Sparking animation effects.");
    const seen = new Set();
    for (const x of v) {
      if (!isInt(x, 1, 2147483647)) throw fail("Choose valid Sparking animation effects.");
      if (seen.has(x)) throw fail("Choose unique valid Sparking animation effects.");
      seen.add(x);
    }
    return v.slice();
  }
  const PACK_KEYS = new Set(["id", "category", "pack_name", "scene_name", "name", "red", "green", "blue", "alpha", "lite_flicker_rate"]);
  function normalizePacks(v) {
    if (v == null) return [];
    if (!Array.isArray(v) || v.length > 128) throw fail("Choose a supported number of edited movies.");
    const bad = () => fail("The edited movie preview is invalid. Reopen it from your unit.");
    const ids = new Set(), names = new Set();
    return v.map((e) => {
      if (!e || typeof e !== "object" || Array.isArray(e) || Object.keys(e).some((k) => !PACK_KEYS.has(k))) throw bad();
      if (!isInt(e.id, 1, 2147483647) || !isInt(e.category, 1, 5) || !(e.category === 1 || e.category === 5)) throw bad();
      const m = /^forge_movie_([1-9][0-9]{0,9})_([0-9]{1,2})_([0-9a-f]{32})$/.exec(typeof e.pack_name === "string" ? e.pack_name : "");
      if (!m || Number(m[1]) > 1999999000 || Number(m[2]) > 47 || (m[2].length > 1 && m[2][0] === "0")) throw bad();
      if (ids.has(e.id) || names.has(e.pack_name)) throw bad();
      ids.add(e.id); names.add(e.pack_name);
      const scene = e.scene_name == null ? "" : e.scene_name, name = e.name == null ? "" : e.name;
      if (typeof scene !== "string" || !/^[A-Za-z0-9_]{0,100}$/.test(scene)) throw bad();
      if (typeof name !== "string" || name.length > 160 || /[\x00-\x1f\x7f]/.test(name)) throw fail("The edited movie label is invalid.");
      const ch = (k, d, hi) => { const x = e[k] == null ? d : e[k]; if (!isInt(x, 0, hi)) throw bad(); return x; };
      return { id: e.id, category: e.category, pack_name: e.pack_name, scene_name: scene, name, red: ch("red", 255, 255), green: ch("green", 255, 255), blue: ch("blue", 255, 255), alpha: ch("alpha", 255, 255), lite_flicker_rate: ch("lite_flicker_rate", 70, 100) };
    });
  }
  IOS.normalizePacks = normalizePacks; IOS.sparkingEffects = sparkingEffects; IOS.normalizeVersion = normalizeVersion;

  // ---------------------------------------------------------------- dock preferences (forge-preview-dock)
  const PREFS = "preview-dock.json";
  let prefs = null;
  async function dockPrefs() {
    if (prefs) return prefs;
    prefs = Object.assign({ separateWindow: false, smooth: true, quality: "auto", qualityEpoch: 0, startFull: true, fraction: 0.46 },
      (await host.exists(PREFS)) ? (await host.readJson(PREFS)) || {} : {});
    return prefs;
  }
  const savePrefs = () => host.writeJson(PREFS, prefs).catch(() => {});

  // ---------------------------------------------------------------- previewAnimation
  let pending = { trim: null, size: null, start: null };
  function noteTrim(a) {
    const t = a.trim;
    pending.trim = t && typeof t.from === "number" && typeof t.to === "number" && t.from >= 0 && t.from < t.to && t.to <= 3600 ? { from: t.from, to: t.to } : null;
    pending.size = a.dockSize === "small" || a.dockSize === "full" ? a.dockSize : null;
    pending.start = "startAt" in a || "startPaused" in a ? { startAt: Math.max(0, Math.min(10000000, a.startAt | 0)), startPaused: Boolean(a.startPaused) } : null;
  }
  async function verifiedMusicPath(mode, path, txt, assetKey, assets) {
    try {
      if (mode !== "lua" || !/^ab_script\/finish_skill\/[A-Za-z0-9_]{1,80}\.lua$/.test(path || "")) return "";
      if (!txt) return path;
      let bytes = IOS.gameAssetRead ? await IOS.gameAssetRead({ assetKey, assets }, "lua/" + path, 2 * MiB) : null;
      if (!bytes) bytes = await host.readBytes("animation-sources/" + (await IOS.dbKey()) + "/" + path);
      if (!bytes) return "";
      return new TextDecoder().decode(bytes) === txt ? path : "";
    } catch (e) { return ""; }
  }
  H.previewAnimation = async function (a) {
    noteTrim(a);
    let appearance = null;
    if ("previewAppearance" in a) {
      const v = a.previewAppearance;
      if (!v || typeof v !== "object" || Object.keys(v).length !== 2) throw fail("Choose valid preview artwork");
      appearance = {};
      for (const k of ["actorId", "artCardId"]) { if (!isInt(v[k], 1, 9007199254740991)) throw fail("Choose valid preview artwork"); appearance[k] = v[k]; }
    }
    if ("effectPacks" in a && !Array.isArray(a.effectPacks)) throw fail("Choose valid edited movies");
    const packs = normalizePacks(a.effectPacks);
    const sparking = sparkingEffects(a.sparkingEffectIds);
    if (packs.some((p) => sparking.includes(p.id))) throw fail("An edited movie and a Sparking effect cannot share the same preview effect ID.");
    const version = normalizeVersion(a.sparkingVersion);
    if (sparking.length || a.sourceDatabase === "sparking") { await IOS.prepareSparkingSnapshot(); await IOS.sparkingDatabaseFile(version); }
    if ("assets" in a && !Array.isArray(a.assets)) throw fail("Choose valid preview pictures");
    if (IOS.overlayMap) IOS.overlayMap(a.assets);
    const mode = a.mode || "lua";
    if (!["lua", "pack", "movie", "training", "awakening"].includes(mode)) throw fail("Choose a supported preview type");
    const tool = mode === "pack" ? "lwf-player" : mode === "movie" ? "usm-player" : "lua-player";
    if (await IOS.previewCache.offline()) await IOS.previewCache.cacheText(IOS.SITE + "/tools/" + tool + "/", 2 * MiB);
    const txt = a.text == null ? "" : String(a.text), path = a.path == null ? "" : String(a.path), res = a.resourcePath == null ? "" : String(a.resourcePath);
    if (mode === "pack") { if (!/^[a-z0-9_./-]+\.lwf$/i.test(res) || !safePath(res)) throw fail("Choose a valid visual pack"); }
    else if (mode === "movie") { if (!/^movie\/[a-z0-9_./-]+\.usm$/i.test(res) || !safePath(res)) throw fail("Choose a movie from the game video browser"); }
    else if (txt.length > 2097152 || (!txt && !validAnimationPath(path))) throw fail("Choose a valid animation or a shorter composition");
    let items = null;
    if (mode === "training" || mode === "awakening") {
      if (!new RegExp("^ab_script/" + (mode === "training" ? "training" : "awaken") + "/a[0-9]{4}\\.lua$").test(path)) throw fail("Choose the matching item animation");
      if (!Array.isArray(a.trainingItems) || a.trainingItems.length > 5) throw fail("Choose up to five items for this scene");
      for (const it of a.trainingItems) {
        if (!it || typeof it !== "object" || !isInt(it.id, 1, 9999999) || !isInt(it.rarity, 0, 4)) throw fail("Choose valid scene items");
      }
      items = JSON.parse(JSON.stringify(a.trainingItems));
    }
    const req = { mode, assetKey: a.assetKey || "", resourcePath: res, scene: a.scene == null ? "" : String(a.scene), text: txt, path,
      forgeVerifiedMusicPath: await verifiedMusicPath(mode, path, txt, a.assetKey || "", a.assets),
      name: a.name || "Animation preview", attackerId: Math.max(1, Number(a.attackerId) || 1000010), enemyId: Math.max(1, Number(a.enemyId) || 1000020) };
    if (a.sourceDatabase === "sparking") req.sourceDatabase = "sparking";
    if (a.assets) req.assets = JSON.parse(JSON.stringify(a.assets));
    if (items) req.trainingItems = items;
    if (appearance) req.previewAppearance = appearance;
    req.effectPacks = packs;
    if (sparking.length) req.sparkingEffectIds = sparking;
    if (version > 0) req.sparkingVersion = version;
    if (JSON.stringify(req).length > 3145728) throw fail("Preview too large");
    setTimeout(() => { play(req).catch((e) => { note("Could not open this preview: " + e.message); IOS.dockNative("failed"); }); }, 0);
    return { opened: true, online: true };
  };

  // ---------------------------------------------------------------- the dock
  const D = (IOS.dock = { open: false, full: false, session: null, epoch: 0, boot: null, exportFull: false, lastRaw: null, ready: false, slowTimer: null });
  IOS.dockNative = (state) => { try { window.ForgeDock && ForgeDock.native && ForgeDock.native(state); } catch (e) {} };
  const note = (t) => host.call("playerNote", { text: t || "" }).catch(() => {});
  const pageEval = (script) => host.call("playerEval", { script });
  async function closeSession() {
    const s = D.session;
    D.session = null; S.session = null; D.boot = null;
    clearTimeout(D.slowTimer);
    if (s) { s.closed = true; await host.remove("cache/preview-movies-" + s.id).catch(() => {}); }
    await host.call("playerCookieClear").catch(() => {});
  }
  async function play(raw) {
    await IOS.serverReady();
    const p = await dockPrefs();
    await closeSession();
    D.lastRaw = raw;
    const req = JSON.parse(JSON.stringify(raw));
    const token = IOS.randomHex(32);
    const sess = { id: IOS.randomHex(16), token, cookie: "forge_preview_" + S.port + "=" + token, assetKey: req.assetKey || "", assets: req.assets || null,
      effectPacks: normalizePacks(req.effectPacks), verifiedMusic: req.forgeVerifiedMusicPath || "", sourceDatabase: req.sourceDatabase === "sparking" ? "sparking" : "eclipse",
      sparkingIds: sparkingEffects(req.sparkingEffectIds), version: normalizeVersion(req.sparkingVersion), movies: new Map(), movieBytes: 0, inFlight: 0 };
    for (const k of ["assetKey", "assets", "effectPacks", "sparkingEffectIds", "sparkingVersion", "forgeVerifiedMusicPath"]) delete req[k];
    req.bgmContext = IOS.bgmContext ? await IOS.bgmContext(sess) : { version: 1, found: false, reason: "This preview has no verified finish-skill music context." };
    // dock size: a "Save video" export always opens full screen
    let full;
    if (/^-- FORGE_SEQUENCE_EXPORT [0-9]{1,5}$/m.test(req.text || "")) { full = true; D.exportFull = true; }
    else if (pending.size) { full = pending.size === "full"; D.exportFull = false; }
    else if (D.exportFull) { full = false; D.exportFull = false; }
    else full = D.open ? D.full : p.startFull;
    req.dock = true; req.full = full;
    if (pending.start) { req.startAt = pending.start.startAt; req.startPaused = pending.start.startPaused; }
    if (pending.trim && req.mode === "movie") req.trim = pending.trim;
    req.autoplay = true; req.quality = p.quality; req.qualityEpoch = p.qualityEpoch; req.smooth30 = p.quality !== "best";
    pending = { trim: null, size: null, start: null };
    sess.req = req;
    D.session = sess; S.session = sess; D.open = true; D.full = full; D.ready = false;
    const tool = req.mode === "pack" ? "lwf-player" : req.mode === "movie" ? "usm-player" : "lua-player";
    startup();
    await host.call("playerOpen", { url: S.origin + "/_forge/open/" + token + "?tool=" + tool, full, title: req.name, fraction: p.fraction });
    IOS.dockNative(full ? "full" : "docked");
  }
  IOS.playPreview = play;

  // WebViewStartup overlay
  function startup() {
    D.epoch++;
    D.healthChecked = false;
    clearTimeout(D.slowTimer);
    host.call("playerOverlay", { show: true, spinner: true, title: "Opening animation preview", message: "Preparing this screen. Your saved units stay on this device." }).catch(() => {});
    const epoch = D.epoch;
    D.slowTimer = setTimeout(() => { if (D.epoch === epoch && !D.ready) slow("This screen has not responded yet. Keep waiting, try again, or copy a report to help diagnose it."); }, 45000);
  }
  function slow(message) {
    host.call("playerOverlay", { show: true, spinner: false, title: "Taking longer than usual", message,
      buttons: [{ id: "retry", label: "Try again" }, { id: "wait", label: "Keep waiting" }, { id: "report", label: "Copy startup report" }] }).catch(() => {});
  }
  function ready() { D.ready = true; clearTimeout(D.slowTimer); host.call("playerOverlay", { show: false }).catch(() => {}); }
  function failed(message) { clearTimeout(D.slowTimer); slow(message); }

  // PreviewBootstrap: the request travels to the page in checked pieces, then the page script mounts
  let generation = 0;
  const quote = (s) => JSON.stringify(s).replace(/\u2028/g, "\\u2028").replace(/\u2029/g, "\\u2029");
  function bootstrap(nonce, documentId, requestJson) {
    if (!/^[A-Za-z0-9_-]{16,128}$/.test(nonce)) throw fail("Invalid preview session nonce.");
    if (!/^[A-Za-z0-9_-]{16,128}$/.test(documentId)) throw fail("Invalid preview document identifier.");
    if (!requestJson || requestJson.length > 3145728) throw fail("Preview request exceeds its transport bounds.");
    if (/[\ud800-\udbff](?![\udc00-\udfff])|(?<![\ud800-\udbff])[\udc00-\udfff]/.test(requestJson)) throw fail("Preview request contains an incomplete Unicode character.");
    const B = new TextEncoder().encode(requestJson).length, U = requestJson.length;
    if (B > 3145728) throw fail("Preview request exceeds 3 MiB of UTF-8.");
    let obj; try { obj = JSON.parse(requestJson); } catch (e) { obj = null; }
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) throw fail("Preview request must be a JSON object.");
    const chunks = [];
    for (let i = 0; i < U;) {
      let end = Math.min(i + 48000, U);
      if (end < U && /[\ud800-\udbff]/.test(requestJson[end - 1]) && /[\udc00-\udfff]/.test(requestJson[end])) end--;
      chunks.push(requestJson.slice(i, end)); i = end;
    }
    const G = ++generation, N = quote(nonce), Dd = quote(documentId), C = chunks.length;
    const docGuard = "if(window.__forgeNativeDocumentId!==" + Dd + ")return false;";
    const sessGuard = docGuard + "var s=window.__forgePreviewBootstrap;if(!s||s.generation!==" + G + "||s.nonce!==" + N + "||s.phase!=='pending')return false;";
    return {
      count: C,
      begin: "(function(){" + docGuard + "var old=window.__forgePreviewBootstrap;if(old&&(old.mounted||old.generation>=" + G + "))return false;window.__forgePreviewBootstrap={generation:" + G + ",nonce:" + N + ",phase:'pending',mounted:false,next:0,bytes:0,units:0,chunks:[]};return true;})()",
      chunk: (i) => "(function(){" + sessGuard + "if(s.next!==" + i + ")return false;var text=" + quote(chunks[i]) + ";var bytes=new TextEncoder().encode(text).length;if(text.length>48000||s.units+text.length>" + U + "||s.bytes+bytes>" + B + "||s.bytes+bytes>3145728){delete s.chunks;s.phase='canceled';return false;}s.chunks.push(text);s.next++;s.units+=text.length;s.bytes+=bytes;return true;})()",
      mount: (P) => "(function(){" + sessGuard + "if(s.next!==" + C + "||s.units!==" + U + "||s.bytes!==" + B + ")return false;var request;try{request=JSON.parse(s.chunks.join(''));}catch(error){delete s.chunks;s.phase='canceled';return false;}delete s.chunks;s.phase='mounted';s.mounted=true;window.__forgeAnimation=request;(function(){\n" + P + "\n}).call(window);return true;})()",
      cancel: "(function(){" + sessGuard + "delete s.chunks;s.phase='canceled';return true;})()",
    };
  }
  IOS.bootstrap = bootstrap;

  async function pageFinished(url) {
    const sess = D.session;
    if (!sess || D.healthChecked) return;
    let u; try { u = new URL(url); } catch (e) { return; }
    if (u.origin !== S.origin || !/^\/tools\/(lua|lwf|usm)-player\//.test(u.pathname)) return;
    D.healthChecked = true;
    const epoch = D.epoch;
    let health;
    try {
      const runtime = await IOS.siteText("preview-runtime.js", 20000);
      const r = await pageEval(runtime + ";JSON.stringify({healthy:Boolean(window.ForgePreviewRuntime && window.ForgePreviewRuntime.healthy()),documentId:String(window.__forgeNativeDocumentId||'')})");
      health = JSON.parse(typeof r === "string" ? r : "{}");
    } catch (e) { note("Could not check the animation player. Tap Preview again."); failed("Could not open the animation player. Try again."); return; }
    if (epoch !== D.epoch || D.session !== sess) return;
    if (!health.healthy) {
      await host.call("playerLayout", { mode: "closed" }).catch(() => {});
      IOS.dockNative("failed");
      note("This device could not run the animation player reliably. Restart the app, then try again. Tap here to hide this message.");
      return;
    }
    sess.req.offline = await IOS.previewCache.offline();
    sess.req.localPreview = true;
    let boot, page;
    try {
      boot = bootstrap(IOS.uuid4(), health.documentId, JSON.stringify(sess.req));
      page = await IOS.siteText(sess.req.mode === "movie" ? "movie-page.js" : "animation-page.js", 200000);
    } catch (e) { note("Could not prepare this preview. Try a shorter sequence."); failed("Could not prepare this preview. Try a shorter sequence."); return; }
    D.boot = boot;
    const steps = [boot.begin];
    for (let i = 0; i < boot.count; i++) steps.push(boot.chunk(i));
    steps.push(boot.mount(page));
    for (const script of steps) {
      let r;
      try { r = await pageEval(script); } catch (e) { r = false; }
      if (epoch !== D.epoch || D.session !== sess || D.boot !== boot) return;
      if (r !== true) {
        pageEval(boot.cancel).catch(() => {});
        note("This preview did not finish opening. Tap Preview again to retry.");
        failed("This animation screen did not finish opening. Try again or copy a startup report.");
        IOS.dockNative("failed");
        return;
      }
    }
    ready();
    pageEval("window.ForgeDockPage&&ForgeDockPage.layout(" + (D.full ? "true" : "false") + ")").catch(() => {});
  }

  async function setLayout(mode) {
    if (mode === "closed") {
      D.open = false; D.full = false;
      await host.call("playerLayout", { mode: "closed" }).catch(() => {});
      await closeSession();
      IOS.dockNative("closed");
      return;
    }
    D.full = mode === "full";
    await host.call("playerLayout", { mode }).catch(() => {});
    IOS.dockNative(D.full ? "full" : "docked");
  }
  addEventListener("forge-host", (e) => {
    const d = e.detail || {};
    if (d.type !== "player") return;
    if (d.event === "server") { S.origin = null; S.port = 0; IOS.serverReady().catch(() => {}); return; }
    if (d.event === "started") { try { if (new URL(d.url).origin === S.origin) { D.boot = null; } } catch (x) {} }
    else if (d.event === "finished") pageFinished(d.url);
    else if (d.event === "title") {
      const parts = String(d.title).slice("forge-dock:".length).split(":");
      const cmd = parts[0];
      if (cmd === "pos" && /^[0-9]{1,7}$/.test(parts[1]) && /^[0-9]{1,7}$/.test(parts[2]) && /^[psd]$/.test(parts[3])) {
        try { window.ForgeDock && ForgeDock.position && ForgeDock.position(Number(parts[1]), Number(parts[2]), parts[3]); } catch (x) {}
      } else if (cmd === "close") setLayout("closed");
      else if (cmd === "size") setLayout(D.full ? "docked" : "full");
      else if (cmd === "bar-on" || cmd === "bar-off") host.call("playerBar", { on: cmd === "bar-on" }).catch(() => {});
    } else if (d.event === "button") {
      if (d.button === "close") setLayout("closed"); else if (d.button === "size") setLayout(D.full ? "docked" : "full");
    } else if (d.event === "overlay") {
      if (d.button === "retry" && D.lastRaw) { const raw = D.lastRaw; play(raw).catch((x) => note("Could not reopen this preview: " + x.message)); }
      else if (d.button === "wait") host.call("playerOverlay", { show: true, spinner: true, title: "Opening animation preview", message: "Waiting for the iPhone to open this screen. You can retry or copy a report at any time.", buttons: [{ id: "retry", label: "Try again" }, { id: "report", label: "Copy startup report" }] }).catch(() => {});
      else if (d.button === "report") {
        host.info().then((i) => host.call("copyText", { text: JSON.stringify({ kind: "dokkan-unit-creation-startup", schemaVersion: 1, appVersion: i.version, versionCode: i.build, iOS: i.system, deviceModel: i.model,
          screen: "animation preview", phase: D.ready ? "ready" : "not-responding", stage: D.healthChecked ? "request-transfer" : "navigation", scope: "Screen startup only; no animation playback or gameplay verification." }) }))
          .then(() => host.call("playerOverlay", { show: true, spinner: false, title: "Taking longer than usual", message: "Startup report copied. You can paste it into your support conversation. It contains device and startup details, without unit data, account details, or preview links.", buttons: [{ id: "retry", label: "Try again" }, { id: "wait", label: "Keep waiting" }] }))
          .catch(() => {});
      }
    } else if (d.event === "fraction") { dockPrefs().then((p) => { p.fraction = d.fraction; savePrefs(); }); }
    else if (d.event === "http503") {
      let path = ""; try { path = new URL(d.url).pathname; } catch (x) {}
      if (path.startsWith("/account/")) return;
      if (path.startsWith("/_forge/stage-")) note("The recording could not be captured or saved. Try again.");
      else IOS.previewCache.offline().then((off) => note(off ? "A file this animation needs is not downloaded yet. Turn off Offline preview or download it in Offline downloads." : "A preview file could not be loaded. Check your connection, then tap Preview again."));
    } else if (d.event === "error") { note("Could not open the animation player. Tap Preview again."); failed("Could not open the animation player. Try again."); }
    else if (d.event === "crashed") {
      host.call("playerLayout", { mode: "closed" }).catch(() => {}); closeSession(); D.open = false;
      note("The animation player stopped. Tap Preview to play it again."); IOS.dockNative("failed");
    }
  });

  H.previewDock = async function (a) {
    const p = await dockPrefs();
    const action = a.action || "status";
    let handled = false;
    if (action === "set") {
      for (const k of ["separateWindow", "smooth", "startFull"]) if (k in a) { if (typeof a[k] !== "boolean") throw fail("JSONObject[\"" + k + "\"] is not a boolean."); p[k] = a[k]; }
      if ("quality" in a) { p.quality = a.quality === "smooth" || a.quality === "best" ? a.quality : "auto"; p.qualityEpoch = (p.qualityEpoch | 0) + 1; }
      await savePrefs();
    } else if (action === "seek" || action === "play" || action === "pause") {
      const cmd = { type: action };
      if (action === "seek") { cmd.frame = Math.max(0, Math.min(10000000, a.frame | 0)); cmd.play = Boolean(a.play); }
      if (D.open) pageEval("window.ForgeDockPage&&ForgeDockPage.command&&ForgeDockPage.command(" + JSON.stringify(cmd) + ")").catch(() => {});
    } else if (["close", "back", "full", "dock", "toggle"].includes(action)) {
      handled = D.open;
      if (D.open) await setLayout(action === "close" || action === "back" ? "closed" : action === "full" ? "full" : action === "dock" ? "docked" : D.full ? "docked" : "full");
    }
    return { open: D.open, full: D.open && D.full, handled, separateWindow: p.separateWindow, smooth: p.smooth, quality: p.quality, startFull: p.startFull, dockable: !p.separateWindow };
  };

  // ---------------------------------------------------------------- prepared movies (per preview)
  const MOVIE = /^\/_forge\/prepared-movies\/([a-f0-9]{32})\.mp4$/;
  const movieDir = (s) => "cache/preview-movies-" + s.id + "/";
  IOS.prepareMovie = async function (sess, req) {
    const h = req.headers || {};
    if (!/^[0-9]+$/.test(h["content-length"] || "")) return text(411, "");
    const len = Number(h["content-length"]);
    if (len < 12 || len > 160 * MiB) return text(413, "");
    if (String(h["content-type"] || "").split(";")[0].trim().toLowerCase() !== "video/mp4") return text(415, "");
    if (sess.closed || sess.movies.size + sess.inFlight >= 32 || len > 512 * MiB - sess.movieBytes) return text(507, "Temporary movie storage is full. Return to the Studio and reopen the preview.");
    sess.inFlight++; sess.movieBytes += len;
    try {
      if (!req.bodyFile || req.bodyLength !== len) throw fail("Incomplete prepared movie");
      const head = await fetch(host.fileUrl(req.bodyFile), { headers: { Range: "bytes=0-7" } });
      const b = new Uint8Array(await head.arrayBuffer());
      if (String.fromCharCode(b[4], b[5], b[6], b[7]) !== "ftyp") { sess.movieBytes -= len; return text(415, ""); }
      const id = IOS.randomHex(16);
      try { await host.move(req.bodyFile, movieDir(sess) + id + ".mp4"); } catch (e) { throw fail("Could not retain this prepared movie"); }
      sess.movies.set(id, len);
      return Object.assign(json(201, { url: "/_forge/prepared-movies/" + id + ".mp4" }), { keepBody: true });
    } catch (e) { sess.movieBytes -= len; throw e; }
    finally { sess.inFlight--; }
  };
  IOS.preparedMovie = async function (sess, path, query) {
    const m = MOVIE.exec(path);
    if (!m || query || !sess.movies.has(m[1])) return text(404, "");
    return { status: 200, headers: { "Content-Type": "video/mp4", "Accept-Ranges": "bytes" }, file: movieDir(sess) + m[1] + ".mp4", range: true };
  };
  IOS.deleteMovie = async function (sess, req, path, query) {
    const m = MOVIE.exec(path);
    if (!m || query) return text(404, "");
    if (req.bodyLength) return text(400, "");
    if (!sess.movies.has(m[1])) return text(404, "");
    try { await host.remove(movieDir(sess) + m[1] + ".mp4"); } catch (e) { return text(503, e.message); }
    sess.movieBytes -= sess.movies.get(m[1]); sess.movies.delete(m[1]);
    return { status: 204, headers: {}, body: "" };
  };
  // kept converted movies (dock only), up to 3 GB
  IOS.movieCache = async function (sess, path, target) {
    try {
      if (target.includes("?")) return json(404, {});
      let m = /^\/_forge\/movie-cache\/([a-f0-9]{64}-[a-z]{1,4})\.mp4$/.exec(path);
      if (m) {
        const f = "movie-cache/" + m[1] + ".mp4", st = await host.stat(f);
        if (!st || st.size < 12) return json(404, {});
        return { status: 200, headers: { "Content-Type": "video/mp4" }, file: f, range: true };
      }
      m = /^\/_forge\/movie-cache\/keep\/([a-f0-9]{64}-[a-z]{1,4})\/([a-f0-9]{32})\.mp4$/.exec(path);
      if (!m || !sess.movies.has(m[2])) return json(404, {});
      const src = movieDir(sess) + m[2] + ".mp4", dest = "movie-cache/" + m[1] + ".mp4", size = sess.movies.get(m[2]);
      const have = await host.stat(dest);
      if (have && have.size === size) return json(200, { kept: true });
      const info = await host.info();
      if (info.freeBytes - size < 512 * MiB) return json(507, { kept: false });
      try { await host.call("copy", { path: src, to: "movie-cache/" + m[1] + ".part" }); await host.move("movie-cache/" + m[1] + ".part", dest); }
      catch (e) { return json(500, { kept: false }); }
      const files = (await host.list("movie-cache")).filter((f) => /\.mp4$/.test(f.name)).sort((a, b) => a.mtime - b.mtime);
      let total = files.reduce((n, f) => n + f.size, 0);
      for (const f of files) { if (total <= 3 * 1073741824) break; if (f.name === m[1] + ".mp4") continue; await host.remove("movie-cache/" + f.name).catch(() => {}); total -= f.size; }
      return json(200, { kept: true });
    } catch (e) { return json(500, {}); }
  };

  // ---------------------------------------------------------------- "Save video": frames and saving
  let capturing = false;
  IOS.stageCapture = async function (sess, query, head) {
    if (query) return text(404, "");
    if (head) return text(405, "");
    if (capturing || sess.closed) return text(503, "The animation snapshot is unavailable.");
    capturing = true;
    try {
      const shot = await host.call("playerSnapshot");
      setTimeout(() => host.remove(shot.file).catch(() => {}), 20000);
      return { status: 200, headers: { "Content-Type": "image/png" }, file: shot.file };
    } catch (e) { return text(503, e.message); }
    finally { capturing = false; }
  };
  IOS.stageExport = async function (sess, path, query, head) {
    const m = /^\/_forge\/stage-export\/([a-f0-9]{32})\.mp4$/.exec(path);
    if (head) return text(405, "");
    if (!m || query || !sess.movies.has(m[1])) return text(404, "");
    const size = sess.movies.get(m[1]);
    if (size < 12 || size > 160 * MiB) return text(404, "");
    try {
      const r = await host.call("saveDocument", { path: movieDir(sess) + m[1] + ".mp4", name: "animation-recording.mp4" });
      if (sess.closed) return text(503, "The animation preview was closed.");
      return json(200, { saved: !!r.saved });
    } catch (e) { return text(503, e.message); }
  };

  // the server needs its address before the first preview
  IOS.serverReady = async () => { if (!S.origin) { const i = await host.call("serverInfo"); S.origin = i.origin; S.port = i.port; } return S; };
})();
