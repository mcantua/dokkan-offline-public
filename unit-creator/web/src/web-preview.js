/* Browser previews: real imported LWF artwork and cached editable animation scripts.
 * The generic GREE LWF renderer does not execute Dokkan's Lua battle engine. */
(function () {
  "use strict";
  const WEB = window.__forgeWeb;
  if (!WEB || window.__forgeIOS) return;
  const H = WEB.handlers, R = WEB.resourceStore, MiB = 1048576;
  const scriptPath = p => typeof p === "string" && p.length < 240 && /^ab_script\/[a-z0-9_/-]+\.lua$/i.test(p) && !p.split("/").some(s => !s || s === "." || s === "..");
  let current = null, scriptIndex = null;
  const sourceBase = () => window.__forgeStandaloneBase || new URL(".", location.href).href;
  async function resolve(path, options = {}) {
    R.path(path);
    const aliases = options.assets;
    if (aliases != null && (!Array.isArray(aliases) || aliases.length > 2000)) throw Error("Choose a supported preview asset list.");
    const map = new Map();
    for (const entry of aliases || []) {
      if (!entry || typeof entry.key !== "string") throw Error("Invalid preview asset reference.");
      R.path(entry.path); R.path(entry.key);
      if (map.has(entry.path) || entry.path.split(".").pop().toLowerCase() !== entry.key.split(".").pop().toLowerCase()) throw Error("The preview has conflicting resource aliases.");
      map.set(entry.path, entry.key);
    }
    if (map.has(path)) return R.read(map.get(path));
    if (options.assetKey) { const selected = await R.read(options.assetKey); if (selected.path === path) return selected; }
    const rows = (await R.list()).filter(r => r.path === path && (options.sourceDatabase !== "sparking" || r.sourceDatabase === "sparking"));
    if (!rows.length) throw Error("Import the matching game resource before previewing: " + path);
    // Resolve all textures from the selected pack, keeping identically named packs separate.
    const group = options.assetKey && options.assetKey.split("/")[0];
    rows.sort((a, b) => (b.key.split("/")[0] === group) - (a.key.split("/")[0] === group) || b.mtime - a.mtime || a.key.localeCompare(b.key));
    return rows[0];
  }
  H.animationSource = async function (a) {
    const path = a.path;
    if (!scriptPath(path)) throw Error("Choose an animation from the list.");
    const database = a.sourceDatabase === "sparking" ? "sparking" : "eclipse";
    let selected;
    if (!a.originalOnly) {
      try { selected = await resolve("lua/" + path, a); } catch (e) { if (a.assetKey || database === "sparking") throw e; }
    } else if (database === "eclipse") {
      selected = (await R.list()).filter(r => r.previewCache && r.sourceDatabase === "eclipse" && r.path === "lua/" + path).sort((x, y) => y.mtime - x.mtime)[0];
    }
    if (!selected && database === "sparking") throw Error("Import the matching Sparking Lua resource. Eclipse scripts are never substituted for Sparking.");
    let text, cached = !!selected;
    if (selected) {
      if (selected.size > 2 * MiB) throw Error("Animation scripts must be 2 MiB or smaller.");
      text = new TextDecoder("utf-8", { fatal: true }).decode(await selected.blob.arrayBuffer());
    } else {
      const settings = await R.get("kv", "browser-preview-settings") || {};
      if (settings.offline || !navigator.onLine) throw Error("This animation script has not been saved for offline use. Import its Lua file or connect once.");
      const response = await fetch("https://dokkan-eclipse.com/cdn/uncompressed/lua/" + path.split("/").map(encodeURIComponent).join("/"));
      if (!response.ok) throw Error("Eclipse animation source returned HTTP " + response.status + ". Import the matching Lua resource instead.");
      text = new TextDecoder("utf-8", { fatal: true }).decode(await R.limitedBytes(response, 2 * MiB));
    }
    if (!text.trim() || text.trimStart().startsWith("<") || text.includes("\u0000")) throw Error("This animation file is unreadable.");
    if (window.luaparse) { try { window.luaparse.parse(text, { luaVersion: "5.1" }); } catch (e) { throw Error("The animation has invalid Lua instructions: " + e.message); } }
    if (!selected) {
      const usage = await H.previewCache({}); if (usage.bytes + new TextEncoder().encode(text).length > usage.maxBytes) throw Error("Downloaded animation sources have reached the preview storage limit. Clear unused sources or import the file directly.");
      const row = R.record("lua/" + path, new TextEncoder().encode(text), "eclipse-source-" + R.id()); row.sourceDatabase = "eclipse"; row.previewCache = true; await R.commit([row]); selected = row; }
    return { path, text, cached, local: true, sourceDatabase: database, assetKey: selected.key };
  };
  H.animationFiles = async function (a) {
    const paths = new Set();
    const database = a.sourceDatabase === "sparking" ? "sparking" : "eclipse";
    if (database === "eclipse") {
      if (!scriptIndex) {
        const response = await fetch(sourceBase() + "data/preview-script-index.json");
        if (!response.ok) throw Error("The bundled animation index is unavailable.");
        const data = JSON.parse(new TextDecoder().decode(await R.limitedBytes(response, 2 * MiB)));
        if (data.schemaVersion !== 1 || !Array.isArray(data.scripts) || data.scripts.length > 50000) throw Error("The bundled animation index is invalid.");
        scriptIndex = data.scripts.map(s => typeof s === "string" ? s : s.path).filter(scriptPath);
      }
      scriptIndex.forEach(p => paths.add(p));
    }
    for (const row of await R.list()) if (row.path.startsWith("lua/") && scriptPath(row.path.slice(4)) && (database !== "sparking" || row.sourceDatabase === "sparking")) paths.add(row.path.slice(4));
    return [...paths].sort();
  };
  H.previewCache = async function (a) {
    const settings = await R.get("kv", "browser-preview-settings") || { offline: false, maxBytes: 512 * MiB };
    if (a.offline != null) { if (typeof a.offline !== "boolean") throw Error("Choose a valid offline setting."); settings.offline = a.offline; }
    if (a.maxBytes != null) { if (!Number.isSafeInteger(a.maxBytes) || a.maxBytes < 64 * MiB || a.maxBytes > 32 * 1024 ** 3) throw Error("Choose a supported preview storage budget."); settings.maxBytes = a.maxBytes; }
    if (a.offline != null || a.maxBytes != null) await R.put("kv", "browser-preview-settings", settings);
    if (a.clear) {
      const candidates = (await R.list()).filter(r => r.previewCache), protectedKeys = new Set(), candidateKeys = new Set(candidates.map(r => r.key));
      const d = await R.idb();
      const projects = await R.req(d.transaction("projects").objectStore("projects").getAll());
      const versions = await R.req(d.transaction("kv").objectStore("kv").getAll(IDBKeyRange.bound("versions:", "versions:\uffff")));
      const docs = [...projects, ...versions.flatMap(rows => rows.map(r => JSON.parse(r.text))), ...(window.ForgeAnimationGallery ? await ForgeAnimationGallery.list() : [])];
      if (window.ForgeAnimationGallery?.current()) docs.push(ForgeAnimationGallery.current());
      const stack = docs.slice(); let visited = 0;
      while (stack.length) {
        if (++visited > 1000000) throw Error("Your resource references are too large to inspect safely. No cached sources were cleared.");
        const value = stack.pop(); if (typeof value === "string" && candidateKeys.has(value)) protectedKeys.add(value); else if (value && typeof value === "object") stack.push(...Object.values(value));
      }
      const rows = candidates.filter(r => !protectedKeys.has(r.key));
      await new Promise((resolve, reject) => { const t = d.transaction("kv", "readwrite"); rows.forEach(r => t.objectStore("kv").delete(R.prefix + r.key)); t.oncomplete = resolve; t.onerror = t.onabort = () => reject(t.error || Error("Preview cleanup was interrupted.")); });
    }
    const rows = (await R.list()).filter(r => r.previewCache);
    return { ...settings, bytes: rows.reduce((n, r) => n + r.size, 0), count: rows.length, web: true };
  };
  function close() {
    const old = current; current = null;
    if (!old) return;
    cancelAnimationFrame(old.frame); old.observer.disconnect();
    try { old.player.destroy(); } catch (_) {}
  }
  H.previewAnimation = async function (a) {
    if (a.mode !== "pack") throw Error("This browser plays imported LWF artwork and poses. Scripted Dokkan battle previews need the full game-animation player in the phone app; the script can still be edited and assigned here.");
    if (!window.LWF || !LWF.CanvasResourceCache || !WEB.formats) throw Error("The artwork player is still starting. Try again.");
    const path = R.path(a.resourcePath);
    if (!/\.lwf$/i.test(path)) throw Error("Choose an imported LWF visual pack.");
    const pack = await resolve(path, a), bytes = new Uint8Array(await pack.blob.arrayBuffer());
    const checked = WEB.formats.inspectLwf(bytes), header = bytes[4] === 0x14 ? 332 : 324, view = new DataView(bytes.buffer);
    let records = 0;
    for (let off = 48; off < header - 4; off += 8) if ((records += view.getUint32(off + 4, true)) > 300000) throw Error("This visual pack contains too many objects for a browser preview.");
    if (checked.width > 4096 || checked.height > 4096 || checked.width * checked.height > 16e6) throw Error("This visual pack exceeds the browser preview canvas limit.");
    const parsed = LWF.Loader.loadArrayBuffer(bytes.buffer);
    if (!parsed || !parsed.check()) throw Error("The LWF artwork file is unreadable.");
    if (parsed.useScript || (bytes[7] & 8) || parsed.programObjects.length || parsed.particles.length) throw Error("This visual pack needs game scripts or particle features outside the generic artwork player. Its original files are kept for game export.");
    const scenes = ForgeBattlePoses.inspectLwf(bytes).scenes;
    if (a.scene && !scenes.some(s => s.name === a.scene)) throw Error("The selected pose is missing from this visual pack.");
    const cache = new LWF.CanvasResourceCache(), settings = { lwf: "browser-local.lwf", worker: false, prefix: "", imageMap: {} };
    let decodedPixels = 0;
    if (parsed.textures.length > 256) throw Error("This visual pack has more than 256 textures for browser preview.");
    for (const texture of parsed.textures) {
      if (!Number.isInteger(texture.width) || !Number.isInteger(texture.height) || texture.width < 1 || texture.height < 1 || texture.width > 4096 || texture.height > 4096 || (decodedPixels += texture.width * texture.height) > 32 * 1024 * 1024) throw Error("This visual pack exceeds the 128 MiB decoded-texture preview budget. Its original resources are kept for game export.");
    }
    cache.checkTextures(settings, parsed);
    const folder = path.slice(0, path.lastIndexOf("/") + 1); let total = bytes.length;
    for (const texture of settings._textures) {
      if (!/\.(png|jpe?g|webp|gif|bmp)$/i.test(texture.filename)) throw Error("This visual pack references an unsupported texture.");
      const row = await resolve(folder + texture.filename, { ...a, assetKey: pack.key });
      if (!row.image || (total += row.size) > 64 * MiB) throw Error("This visual pack's textures exceed the 64 MiB browser preview limit.");
      const image = await WEB.formats.inspectImage(new Uint8Array(await row.blob.arrayBuffer()), false);
      if ((decodedPixels += image.width * image.height) > 32 * 1024 * 1024) throw Error("This visual pack exceeds the 128 MiB decoded-texture preview budget. Its original resources are kept for game export.");
      settings.imageMap[texture.filename] = await H.assetUrl({ key: row.key });
    }
    close();
    dialog(String(a.name || "Imported artwork preview"), '<section class="web-lwf-preview"><p class="hint">Original imported LWF artwork · generic canvas renderer. Named poses play their actual frames and textures. Full battle Lua, game shaders, and sounds need the game player.</p><label class="field">Pose<select id="web-lwf-scene"><option value="">Whole visual pack</option>' + scenes.map(s => '<option value="' + esc(s.name) + '">' + esc(s.name) + '</option>').join("") + '</select></label><canvas id="web-lwf-canvas" aria-label="Imported animated artwork"></canvas><p id="web-lwf-status" role="status" aria-live="polite">Loading original textures…</p><div class="row"><button type="button" class="button" id="web-lwf-play">Pause</button><button type="button" class="button ghost" id="web-lwf-restart">Restart</button><label class="field">Playback speed<select id="web-lwf-speed"><option value="0.25">¼×</option><option value="0.5">½×</option><option value="1" selected>1×</option><option value="2">2×</option></select></label></div><label class="field">Frame<input id="web-lwf-frame" type="range" min="1" max="1" value="1"></label></section>');
    const canvas = document.getElementById("web-lwf-canvas"); canvas.width = checked.width; canvas.height = checked.height; settings.stage = canvas;
    cache.cache[settings.lwf] = { data: parsed };
    let player;
    try { player = await new Promise((resolve, reject) => { settings.onload = function (lwf) { lwf && !this.error.length ? resolve(lwf) : reject(Error("The visual pack's original textures could not be decoded.")); }; cache.loadLWF(settings); }); }
    catch (e) { if (canvas.isConnected) document.getElementById("web-lwf-status").textContent = e.message; throw e; }
    const shell = document.getElementById("dialog"), scene = document.getElementById("web-lwf-scene"), play = document.getElementById("web-lwf-play"), slider = document.getElementById("web-lwf-frame"), status = document.getElementById("web-lwf-status");
    if (!canvas.isConnected || !shell.open) { player.destroy(); throw Error("The visual preview was closed before loading finished."); }
    let target = player.rootMovie, paused = false, last = performance.now(), lastStatus = 0, speed = 1;
    const observer = new MutationObserver(() => { if (!canvas.isConnected || !shell.open) close(); }); observer.observe(shell, { childList: true, subtree: true, attributes: true, attributeFilter: ["open"] });
    const session = current = { player, observer, frame: 0 };
    const select = () => {
      if (target !== player.rootMovie) player.rootMovie.detachMovie("browserPreviewPose");
      target = scene.value ? player.rootMovie.attachMovie(scene.value, "browserPreviewPose") : player.rootMovie;
      if (!target) throw Error("The selected pose could not be opened.");
      slider.max = String(target.totalFrames); target.gotoAndPlay(1); paused = false; play.textContent = "Pause";
    };
    scene.onchange = () => { try { select(); } catch (e) { status.textContent = e.message; } };
    play.onclick = () => { paused = !paused; paused ? target.stop() : target.play(); play.textContent = paused ? "Play" : "Pause"; };
    document.getElementById("web-lwf-restart").onclick = () => { target.gotoAndPlay(1); paused = false; play.textContent = "Pause"; };
    document.getElementById("web-lwf-speed").onchange = e => { speed = Number(e.target.value); };
    slider.oninput = () => { paused = true; target.gotoAndStop(Number(slider.value)); player.exec(player.tick); player.render(); play.textContent = "Play"; };
    if (a.scene) scene.value = a.scene; select();
    const tick = now => {
      if (current !== session) return;
      if (!canvas.isConnected || !shell.open) return close();
      try { if (!paused) player.exec(Math.min(0.1, (now - last) / 1000) * speed); player.render(); last = now; if (now - lastStatus > 250) { slider.value = String(target.currentFrame); status.textContent = "Frame " + target.currentFrame + " of " + target.totalFrames; lastStatus = now; } session.frame = requestAnimationFrame(tick); }
      catch (e) { status.textContent = "This visual could not continue: " + e.message; close(); }
    };
    session.frame = requestAnimationFrame(tick);
    return { opened: true, local: true, mode: "pack", scenes: scenes.length };
  };
  WEB.preview = { resolve, close };
  addEventListener("pagehide", close);
})();
