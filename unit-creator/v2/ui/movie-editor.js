"use strict";
// Movie editor ("Combine movie scenes"): pick game movie scenes, cut each one with a visual trim
// bar, put them in order, and make one movie. When every scene is a VP9 movie that starts on a
// cut point (keyframe) and keeps its original picture, the movie is joined instantly without
// re-encoding; otherwise it is re-encoded on the phone (slower) with clear progress.
window.ForgeMovieEditor = (() => {
  const LIMIT = 160 * 1024 * 1024, CHUNK = 256 * 1024, PAGE = 8;
  function encode(bytes) {
    let result = "";
    for (let at = 0; at < bytes.length; at += 8192) result += String.fromCharCode(...bytes.subarray(at, at + 8192));
    return btoa(result);
  }
  async function store(bytes, name, signal, progress) {
    let uploadId;
    try {
      ({ uploadId } = await Native.call("storeMovie", { action: "begin", name }));
      for (let offset = 0; offset < bytes.length; offset += CHUNK) {
        if (signal.aborted) throw new DOMException("Movie editing cancelled.", "AbortError");
        await Native.call("storeMovie", { action: "append", uploadId, offset, data: encode(bytes.subarray(offset, offset + CHUNK)) });
        progress("Saving your movie: " + Math.round(Math.min(bytes.length, offset + CHUNK) / bytes.length * 100) + "%", Math.min(bytes.length, offset + CHUNK) / bytes.length);
      }
      if (signal.aborted) throw new DOMException("Movie editing cancelled.", "AbortError");
      const result = await Native.call("storeMovie", { action: "finish", uploadId });
      uploadId = null;
      return result;
    } finally {
      if (uploadId) await Native.call("storeMovie", { action: "cancel", uploadId }).catch(() => {});
    }
  }
  const fpsOf = (input) => input.rate.n / input.rate.d;
  const plain = (c) => c.zoom === 100 && c.x === 0 && c.y === 0 && c.rotation === 0 && c.opacity === 100 && !c.mirror && !c.flip;
  function keyframes(input) {
    if (input.keyframes) return input.keyframes;
    input.keyframes = [];
    if (input.kind === "vp9-ivf" && globalThis.ForgeUsmWriter) {
      try { ForgeUsmWriter.inspectIVF(input.video).frames.forEach((f, i) => { if (f.key) input.keyframes.push(i); }); } catch { input.keyframes = []; }
    }
    return input.keyframes;
  }
  const nearestKey = (input, frame) => keyframes(input).reduce((best, k) => (best === null || Math.abs(k - frame) < Math.abs(best - frame) ? k : best), null);

  async function open(initial) {
    const owner = () => window.ForgeAnimationGallery?.current() || state.project;
    if (!owner()) throw Error("Start an animation, then choose Combine movie scenes.");
    const { ensureMovieRuntime } = await import("./vendor/media/editor.js");
    ensureMovieRuntime();
    await flushSave();
    const project = owner(), key = project.key, independent = project.format === ForgeAnimationGallery.FORMAT, clips = [], loaded = new Map();
    let items = [], offset = 0, working = false, controller = null, result = null, resultRevision = -1, revision = 0, request = 0;
    const panel = document.createElement("dialog");
    panel.className = "movie-editor-dialog";
    panel.setAttribute("aria-labelledby", "movie-editor-title");
    panel.innerHTML =
      '<div class="movie-editor-heading"><div><h2 id="movie-editor-title">Movie editor</h2><p>Cut game movie scenes and join them into one movie.</p></div><button type="button" class="icon-button" id="movie-edit-close" aria-label="Close movie editor">×</button></div>' +
      '<nav class="movie-steps" aria-label="Steps"><button type="button" data-step="1">1 · Pick scenes</button><button type="button" data-step="2">2 · Cut &amp; arrange</button><button type="button" data-step="3">3 · Make movie</button></nav>' +
      '<section class="movie-step" id="movie-step-1"><h3>1 · Pick scenes</h3><label class="field">Find a movie scene<input id="movie-edit-search" type="search" placeholder="Character, attack or story…"></label><div id="movie-edit-sources" class="movie-sources"><p class="hint">Loading scenes…</p></div><div class="row"><button type="button" class="button ghost small" id="movie-edit-prev">◀ Previous</button><button type="button" class="button ghost small" id="movie-edit-next">Next ▶</button></div><details class="movie-more"><summary>More scenes from your game files</summary><p class="hint">Import a game resource pack to use scenes that are not in the public list.</p><button type="button" class="button ghost small" id="movie-edit-import">Import game resources</button></details></section>' +
      '<section class="movie-step" id="movie-step-2"><div class="section-heading"><h3>2 · Cut &amp; arrange</h3><p id="movie-edit-total" class="hint"></p></div><p class="hint">Drag the green (start) and orange (end) handles to keep only the part you want. White marks are cut points: starting a scene on one lets your movie be made instantly.</p><ol id="movie-edit-sections" class="clip-list"></ol></section>' +
      '<section class="movie-step" id="movie-step-3"><h3>3 · Make movie</h3><label class="field">Movie name<input id="movie-edit-name" maxlength="120" value="My edited movie"></label><div id="movie-edit-plan" class="movie-plan"></div>' +
      '<details class="movie-more"><summary>Picture and sound options</summary><div class="field-grid"><label class="field">Picture shape<select id="movie-edit-size"><option value="original">Match the first scene</option><option value="360x640">Portrait · compact (faster)</option><option value="540x960">Portrait · detailed</option><option value="640x640">Square</option><option value="1280x720">Landscape</option></select></label><label class="field">Motion smoothness<select id="movie-edit-rate"><option value="original">Match the first scene</option><option value="30">30 frames per second</option><option value="60">60 frames per second</option></select></label><label class="field">Picture quality<select id="movie-edit-quality"><option value="36">Balanced (faster)</option><option value="24">High</option><option value="48">Smallest file</option><option value="lossless">Exact pixels · largest file</option></select></label><label class="field">Sound<select id="movie-edit-audio"><option value="auto">Keep the scenes’ sound</option><option value="mute">Silent movie</option></select></label></div><p class="hint">Changing these re-encodes the whole movie on this phone, which is slower.</p></details>' +
      '<div class="row movie-actions"><button type="button" class="button" id="movie-edit-build">Make my movie</button><button type="button" class="button ghost" id="movie-edit-cancel" hidden>Cancel</button></div>' +
      '<div class="movie-progress" id="movie-edit-progress" hidden><progress id="movie-edit-bar" max="1"></progress><p class="hint" id="movie-edit-elapsed"></p></div>' +
      '<div class="row movie-actions" id="movie-edit-done" hidden><button type="button" class="button ghost" id="movie-edit-preview">▶ Watch my movie</button><button type="button" class="button teal" id="movie-edit-save">Add to my animation</button></div></section>' +
      '<p id="movie-edit-status" class="movie-status" role="status" aria-live="polite"></p>';
    document.body.append(panel);
    panel.showModal();
    const q = (s) => panel.querySelector(s), alive = () => panel.isConnected && panel.open && owner() === project;
    let started = 0, clock = null;
    function status(message, error = false) {
      if (!panel.isConnected) return;
      q("#movie-edit-status").textContent = message;
      q("#movie-edit-status").setAttribute("role", error ? "alert" : "status");
      q("#movie-edit-status").classList.toggle("movie-status-error", error);
    }
    function progress(message, fraction) {
      status(message);
      const bar = q("#movie-edit-bar");
      if (typeof fraction === "number" && Number.isFinite(fraction)) { bar.max = 1; bar.value = Math.max(0, Math.min(1, fraction)); } else bar.removeAttribute("value");
    }
    function invalidate() {
      revision++;
      resultRevision = -1;
      buttons();
      plan();
    }
    function buttons() {
      panel.querySelectorAll("input,select,button").forEach((e) => { if (!e.closest(".trim")) e.disabled = working; });
      clips.forEach((c) => c.trim?.busy(working));
      q("#movie-edit-close").disabled = false;
      panel.querySelectorAll("[data-step]").forEach((b) => { b.disabled = false; });
      q("#movie-edit-cancel").disabled = !working;
      q("#movie-edit-cancel").hidden = !working;
      q("#movie-edit-build").hidden = working;
      q("#movie-edit-build").disabled = working || !clips.length;
      q("#movie-edit-progress").hidden = !working;
      const ready = !working && result && resultRevision === revision;
      q("#movie-edit-done").hidden = !ready;
      q("#movie-edit-preview").disabled = !ready;
      q("#movie-edit-save").disabled = !ready;
      q("#movie-edit-sections").querySelectorAll("[data-movie-order]").forEach((b) => {
        const [index, action] = b.dataset.movieOrder.split(":");
        b.disabled = working || action === "up" && Number(index) === 0 || action === "down" && Number(index) === clips.length - 1;
      });
      q("#movie-edit-prev").disabled = working || !offset;
      q("#movie-edit-next").disabled = working || offset + PAGE >= matches().length;
    }
    function close() {
      controller?.abort();
      panel.close();
    }
    q("#movie-edit-close").onclick = close;
    panel.querySelectorAll("[data-step]").forEach((b) => b.onclick = () => q("#movie-step-" + b.dataset.step).scrollIntoView({ behavior: "smooth", block: "start" }));
    panel.addEventListener("cancel", () => controller?.abort());
    panel.addEventListener("close", () => {
      controller?.abort();
      clearInterval(clock);
      request++;
      loaded.clear();
      clips.length = 0;
      panel.remove();
    }, { once: true });
    async function run(work) {
      if (working) return;
      working = true;
      controller = new AbortController();
      buttons();
      try {
        await work(controller.signal);
      } catch (error) {
        if (alive()) status(error.name === "AbortError" ? "Stopped. Your scenes and cuts are kept." : error.message, true);
      } finally {
        working = false;
        if (alive()) buttons();
      }
    }

    // ---------------------------------------------------------------- 1 · scenes
    function matches() {
      return ForgeMovies.filter(items, { search: q("#movie-edit-search").value, available: "available" });
    }
    function sources() {
      if (!alive()) return;
      const list = matches();
      offset = Math.min(offset, Math.max(0, Math.floor((list.length - 1) / PAGE) * PAGE));
      const rows = list.slice(offset, offset + PAGE);
      q("#movie-edit-sources").innerHTML = rows.length ? rows.map((row, i) => '<div class="movie-edit-source"><span><strong>' + esc(row.title) + "</strong>" + (row.variation ? " · visual " + esc(row.variation) : "") + (row.imported ? ' <span class="chip teal">on this phone</span>' : "") + '</span><div class="row"><button type="button" class="button ghost small" data-movie-source-preview="' + i + '">▶ Watch</button><button type="button" class="button small" data-movie-source-add="' + i + '">+ Add</button></div></div>').join("") + '<p class="hint">' + (offset + 1) + "–" + (offset + rows.length) + " of " + list.length + " scenes</p>" : '<p class="hint">No scenes match. Try another name, or import your game files under “More scenes”.</p>';
      q("#movie-edit-sources").querySelectorAll("[data-movie-source-preview]").forEach((b) => b.onclick = () => previewSource(rows[Number(b.dataset.movieSourcePreview)]).catch((e) => status(e.message, true)));
      q("#movie-edit-sources").querySelectorAll("[data-movie-source-add]").forEach((b) => b.onclick = () => run((signal) => add(rows[Number(b.dataset.movieSourceAdd)], signal)));
      buttons();
    }
    function ownedRows() {
      const rows = [];
      for (const binding of ForgeMovieModel.inspect(project)) {
        const asset = project.assets.find((a) => a.movieKey === binding.key && a.owner === ForgeMovieModel.OWNER);
        if (asset) rows.push({ path: binding.path, title: binding.name, group: "imported", format: "Imported", status: "available", imported: true, assetKey: asset.key, size: binding.size, owned: true });
      }
      return rows;
    }
    function setItems(extra) {
      const owned = ownedRows();
      items = ForgeMovies.merge(ForgeMovieCatalog.items, extra).filter((row) => !owned.some((o) => o.path === row.path));
      items.unshift(...owned);
      sources();
    }
    // The public scene list shows at once; scenes from imported game files are added when ready.
    async function catalog() {
      const token = ++request, assets = [];
      setItems([]);
      for (let page = 0; page < 200; page++) {
        const rows = await Native.call("assets", { query: ".usm", offset: page * 100, limit: 100 });
        if (!alive() || token !== request) return;
        assets.push(...rows);
        if (rows.length < 100) break;
      }
      if (assets.length) setItems(assets);
    }
    async function previewSource(row, trim) {
      const args = { mode: "movie", resourcePath: row.path, name: row.title };
      if (row.assetKey) args.assets = [{ path: row.path, key: row.assetKey }];
      if (trim) args.trim = trim;
      await Native.call("previewAnimation", args);
    }
    async function add(row, signal) {
      if (clips.length >= 12) throw Error("Use up to 12 scenes in one movie.");
      let input = loaded.get(row.assetKey || row.path);
      if (!input) {
        status("Loading " + row.title + "…");
        const saved = row.assetKey ? row : await Native.call("downloadAsset", { path: row.path });
        if (!alive() || signal.aborted) return;
        const url = await Native.call("assetUrl", { key: saved.key || saved.assetKey });
        const response = await fetch(url, { signal });
        if (!response.ok) throw Error("This saved movie could not be read. Import its complete resource again.");
        const declared = Number(response.headers.get("content-length"));
        if (declared > LIMIT) throw Error("Choose a movie of 160 MB or less.");
        const bytes = new Uint8Array(await response.arrayBuffer());
        if (bytes.length > LIMIT) throw Error("Choose a movie of 160 MB or less.");
        input = ForgeMovieInput.readMovie(bytes);
        let total = input.video.length + (input.audio?.length || 0);
        for (const value of loaded.values()) total += value.video.length + (value.audio?.length || 0);
        if (total > LIMIT) throw Error("These scenes need too much memory together. Use fewer different scenes.");
        loaded.set(row.assetKey || row.path, input);
      }
      if (!alive() || signal.aborted) return;
      clips.push({ row, input, from: 0, to: input.frames, zoom: 100, x: 0, y: 0, rotation: 0, opacity: 100, mirror: false, flip: false, mute: false });
      invalidate();
      sections();
      status(input.warnings.join(" ") || "Scene added. Cut it below, or add more scenes.");
      q("#movie-edit-sections").lastElementChild?.scrollIntoView({ behavior: "smooth", block: "center" });
    }

    // ---------------------------------------------------------------- 2 · sections
    function times() {
      let at = 0;
      return clips.map((c) => { const d = (c.to - c.from) / fpsOf(c.input), r = { start: at, end: at + d }; at += d; return r; });
    }
    function instantStart(c) {
      return c.input.kind === "vp9-ivf" && keyframes(c.input).includes(c.from);
    }
    function refreshTimes() {
      const t = times();
      q("#movie-edit-total").textContent = clips.length ? clips.length + " scene" + (clips.length === 1 ? "" : "s") + " · " + ForgeTrim.clock(t.at(-1).end, 2) + " total" : "";
      q("#movie-edit-sections").querySelectorAll("[data-movie-when]").forEach((n) => {
        const i = Number(n.dataset.movieWhen), c = clips[i];
        if (!c) return;
        n.textContent = "Plays " + ForgeTrim.clock(t[i].start, 2) + " – " + ForgeTrim.clock(t[i].end, 2) + " in your movie";
        const badge = n.parentElement.querySelector("[data-movie-badge]");
        if (badge) {
          const ok = instantStart(c);
          badge.textContent = c.input.kind !== "vp9-ivf" ? "Older movie format · will be re-encoded" : ok ? "⚡ Starts on a cut point" : "Starts between cut points";
          badge.className = "chip " + (ok ? "teal" : "orange");
          badge.dataset.movieBadge = "1";
        }
        const snap = n.closest("li").querySelector("[data-movie-snap]");
        if (snap) snap.hidden = c.input.kind !== "vp9-ivf" || instantStart(c);
      });
    }
    function field(index, key2, title, value, min, max, step = "1") {
      return '<label class="field">' + title + '<input type="number" required data-movie-edit="' + index + ":" + key2 + '" value="' + value + '" min="' + min + '" max="' + max + '" step="' + step + '"></label>';
    }
    function sections() {
      const list = q("#movie-edit-sections");
      list.textContent = "";
      if (!clips.length) {
        list.innerHTML = '<li class="clip-empty"><p><strong>No scenes yet.</strong> Tap “+ Add” on a scene above.</p></li>';
        refreshTimes();
        buttons();
        return;
      }
      clips.forEach((c, i) => {
        const fps = fpsOf(c.input), li = document.createElement("li");
        li.className = "clip-card clip-color-" + (i % 6);
        li.innerHTML = '<div class="clip-head"><span class="clip-no">' + (i + 1) + '</span><div class="clip-title"><h3>' + esc(c.row.title) + '</h3><p data-movie-when="' + i + '"></p><span data-movie-badge></span></div></div><div class="clip-trim"></div>' +
          '<button type="button" class="button ghost small movie-snap" data-movie-snap="' + i + '" hidden>⚡ Move start to the nearest cut point</button>' +
          '<div class="clip-actions"><button type="button" class="button teal small" data-movie-play="' + i + '">▶ Play this part</button><span class="clip-tools">' +
          [["up", "↑", "Move scene earlier"], ["down", "↓", "Move scene later"], ["copy", "⧉", "Duplicate scene"], ["remove", "✕", "Remove scene"]].map(([action, icon, label]) => '<button type="button" class="icon-button clip-icon' + (action === "remove" ? " clip-remove" : "") + '" data-movie-order="' + i + ":" + action + '" aria-label="' + label + " " + (i + 1) + '">' + icon + "</button>").join("") + "</span></div>" +
          '<details class="movie-more"><summary>Picture placement and sound</summary><div class="field-grid">' + field(i, "zoom", "Size (%)", c.zoom, 5, 800) + field(i, "x", "Left / right (%)", c.x, -200, 200) + field(i, "y", "Up / down (%)", c.y, -200, 200) + field(i, "rotation", "Rotation (degrees)", c.rotation, -180, 180) + field(i, "opacity", "Opacity (%)", c.opacity, 0, 100) + '</div><div class="row">' + [["mirror", "Mirror left and right"], ["flip", "Turn upside down"], ["mute", "Mute this scene"]].map(([k, label]) => '<label class="check-item"><input type="checkbox" data-movie-edit="' + i + ":" + k + '"' + (c[k] ? " checked" : "") + "> " + label + "</label>").join("") + '</div><p class="hint">Changing the picture means the movie is re-encoded, which is slower.</p></details>';
        list.append(li);
        const keys = keyframes(c.input).map((k) => k / fps);
        c.trim = ForgeTrim.mount(li.querySelector(".clip-trim"), {
          total: c.input.frames / fps, from: c.from / fps, to: c.to / fps, step: 0.1, minLength: 1 / fps, decimals: 2, markers: keys, snap: keys,
          onCommit: (from, to) => {
            const f = Math.max(0, Math.round(from * fps)), t = Math.min(c.input.frames, Math.round(to * fps));
            if (t <= f) { status("The end must be after the start.", true); return false; }
            c.from = f;
            c.to = t;
            invalidate();
            refreshTimes();
            return true;
          }
        });
      });
      list.querySelectorAll("[data-movie-edit]").forEach((el) => {
        el.oninput = () => el.setAttribute("aria-invalid", String(!el.checkValidity()));
        el.onchange = () => {
          const [index, prop] = el.dataset.movieEdit.split(":"), c = clips[Number(index)];
          if (!el.checkValidity()) { el.reportValidity(); return; }
          c[prop] = el.type === "checkbox" ? el.checked : Number(el.value);
          invalidate();
        };
      });
      list.querySelectorAll("[data-movie-play]").forEach((b) => b.onclick = () => {
        const c = clips[Number(b.dataset.moviePlay)], fps = fpsOf(c.input);
        previewSource(c.row, { from: c.from / fps, to: c.to / fps }).catch((e) => status(e.message, true));
      });
      list.querySelectorAll("[data-movie-snap]").forEach((b) => b.onclick = () => {
        const c = clips[Number(b.dataset.movieSnap)], k = nearestKey(c.input, c.from);
        if (k === null || k >= c.to) { status("There is no cut point before this scene’s end. Move the end later first.", true); return; }
        c.from = k;
        c.trim.set({ from: k / fpsOf(c.input) });
        invalidate();
        refreshTimes();
        status("Start moved to the nearest cut point.");
      });
      list.querySelectorAll("[data-movie-order]").forEach((b) => b.onclick = () => {
        const [index, action] = b.dataset.movieOrder.split(":"), i = Number(index);
        if (action === "remove") clips.splice(i, 1);
        else if (action === "copy") {
          if (clips.length >= 12) { status("Use up to 12 scenes in one movie.", true); return; }
          clips.splice(i + 1, 0, { ...clips[i], trim: null });
        } else {
          const j = i + (action === "up" ? -1 : 1);
          if (j >= 0 && j < clips.length) [clips[i], clips[j]] = [clips[j], clips[i]];
        }
        invalidate();
        sections();
      });
      refreshTimes();
      buttons();
    }

    // ---------------------------------------------------------------- 3 · make
    function output() {
      const first = clips[0]?.input, size = q("#movie-edit-size").value, rate = q("#movie-edit-rate").value;
      if (!first) return null;
      const [width, height] = size === "original" ? [first.width, first.height] : size.split("x").map(Number);
      return { width: width - width % 2, height: height - height % 2, rate: rate === "original" ? first.rate : { n: Number(rate), d: 1 }, size, rateChoice: rate, quality: q("#movie-edit-quality").value, audio: q("#movie-edit-audio").value };
    }
    function instantPlan() {
      const out = output(), reasons = [];
      if (!out) return { ok: false, reasons: ["Add a scene first."] };
      const first = clips[0].input;
      if (out.size !== "original" || out.rateChoice !== "original" || out.quality === "lossless") reasons.push("you changed the picture options");
      clips.forEach((c, i) => {
        if (c.input.kind !== "vp9-ivf") reasons.push("scene " + (i + 1) + " uses an older movie format");
        else if (!instantStart(c)) reasons.push("scene " + (i + 1) + " starts between cut points");
        if (!plain(c)) reasons.push("scene " + (i + 1) + " has picture changes");
        if (c.input.width !== first.width || c.input.height !== first.height || c.input.rate.n * first.rate.d !== first.rate.n * c.input.rate.d) reasons.push("scene " + (i + 1) + " has a different size or speed");
      });
      if (out.audio !== "mute") {
        const sound = clips.filter((c) => c.input.audio && !c.mute);
        if (sound.some((c) => c.input.audioKind !== "adx")) reasons.push("a scene’s sound needs converting");
      }
      return { ok: !reasons.length, reasons: [...new Set(reasons)] };
    }
    function plan() {
      const box = q("#movie-edit-plan");
      if (!clips.length) { box.innerHTML = '<p class="hint">Add at least one scene to make a movie.</p>'; return; }
      const p = instantPlan();
      box.innerHTML = p.ok ? '<p class="notice success">⚡ <strong>Instant.</strong> Your scenes can be joined without re-encoding, so your movie is ready in seconds.</p>' :
        '<p class="notice warning"><strong>This movie will be re-encoded on your phone.</strong> That can take a few minutes because ' + esc(p.reasons.slice(0, 3).join("; ")) + '.' + (p.reasons.some((r) => r.includes("between cut points")) ? " Tip: use “⚡ Move start to the nearest cut point” on those scenes." : "") + "</p>";
    }
    function elapsed() {
      clearInterval(clock);
      started = Date.now();
      clock = setInterval(() => {
        if (!panel.isConnected) return clearInterval(clock);
        const s = Math.floor((Date.now() - started) / 1000);
        q("#movie-edit-elapsed").textContent = "Working for " + Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") + ". Keep this screen open.";
      }, 1000);
    }
    function instant(name, signal) {
      const out = output(), worker = new Worker(new URL("./vendor/media/instant-worker.js", location.href));
      return new Promise((resolve, reject) => {
        const stop = () => { worker.terminate(); reject(new DOMException("Movie editing cancelled.", "AbortError")); };
        signal.addEventListener("abort", stop, { once: true });
        worker.onerror = (e) => { signal.removeEventListener("abort", stop); worker.terminate(); reject(Error(e.message || "The instant join could not start.")); };
        worker.onmessage = ({ data }) => {
          if (data.type === "progress") return progress(data.event.message + "…");
          signal.removeEventListener("abort", stop);
          worker.terminate();
          if (data.type === "error") reject(Error(data.message));
          else resolve({ data: data.data });
        };
        worker.postMessage({ name: "forge-motion", width: out.width, height: out.height, rate: out.rate, mute: out.audio === "mute",
          sections: clips.map((c) => ({ video: c.input.video, from: c.from, to: c.to, audio: c.input.audio, audioKind: c.input.audioKind, mute: c.mute })) });
      });
    }
    q("#movie-edit-search").oninput = () => { offset = 0; sources(); };
    q("#movie-edit-prev").onclick = () => { offset -= PAGE; sources(); };
    q("#movie-edit-next").onclick = () => { offset += PAGE; sources(); };
    q("#movie-edit-import").onclick = () => run(async () => {
      const imported = await Native.call("import");
      if (!alive() || !imported?.kind) return;
      rememberImportResult(imported);
      state.info = imported.info || await Native.call("info");
      await loadLookups();
      await catalog();
      status("Game files imported. Their scenes are in the list above.");
    });
    for (const id of ["name", "size", "rate", "quality", "audio"]) q("#movie-edit-" + id).oninput = q("#movie-edit-" + id).onchange = invalidate;
    q("#movie-edit-cancel").onclick = () => controller?.abort();
    q("#movie-edit-build").onclick = () => run(async (signal) => {
      if (!clips.length) throw Error("Add a movie scene first.");
      const name = q("#movie-edit-name").value.trim();
      if (!name) throw Error("Give your movie a name first.");
      if (name.length > 120 || /[\x00-\x1f\x7f]/.test(name)) throw Error("Choose a movie name of up to 120 characters without control characters.");
      const out = output(), version = revision, fps = out.rate.n / out.rate.d, frames = clips.reduce((sum, c) => sum + Math.max(1, Math.round((c.to - c.from) * c.input.rate.d / c.input.rate.n * fps)), 0);
      if (Math.round(frames * 60 / fps) > 10800) throw Error("Keep your movie within three minutes. Shorten or remove a scene first.");
      elapsed();
      let edited = null;
      if (instantPlan().ok) {
        progress("Joining your scenes…");
        try { edited = await instant(name, signal); } catch (e) {
          if (e.name === "AbortError") throw e;
          progress("Instant join was not possible (" + e.message + "). Re-encoding instead…");
        }
      }
      if (!edited) {
        progress("Starting the movie maker on this phone…");
        const { editMovie } = await import("./vendor/media/editor.js");
        edited = await editMovie({ name: "forge-motion", width: out.width, height: out.height, rate: out.rate, quality: out.quality === "lossless" ? 0 : Number(out.quality), lossless: out.quality === "lossless", audioMode: out.audio, clips: clips.map((c) => ({ ...c.input, audio: c.mute ? null : c.input.audio, startFrame: c.from, endFrame: c.to, transform: { scale: c.zoom / 100, x: c.x / 100 * out.width, y: c.y / 100 * out.height, rotation: c.rotation, opacity: c.opacity / 100, flipX: c.mirror, flipY: c.flip } })), signal }, (event) => {
          if (typeof event === "string") return progress(event);
          const fraction = Number(event?.progress);
          progress((event?.message || "Making your movie") + (Number.isFinite(fraction) && fraction > 0 ? " · " + Math.round(fraction * 100) + "%" : "") + "…", Number.isFinite(fraction) && fraction > 0 ? fraction : undefined);
        });
      }
      if (!alive() || signal.aborted) return;
      if (edited.data.length > 96 * 1024 * 1024) throw Error("This movie is larger than 96 MB. Choose a compact picture or fewer scenes.");
      result = await store(edited.data, name, signal, progress);
      if (!alive() || signal.aborted) return;
      resultRevision = version;
      clearInterval(clock);
      status("Your movie is ready (" + (result.size / 1048576).toFixed(1) + " MB, made in " + Math.max(1, Math.round((Date.now() - started) / 1000)) + " s). Watch it, then add it to your animation.");
    }).finally(() => clearInterval(clock));
    q("#movie-edit-preview").onclick = () => run(async () => {
      const path = "movie/forge_preview_" + result.key.split("/")[0].replace(/[^a-z0-9_]/gi, "_") + ".usm";
      await Native.call("previewAnimation", { mode: "movie", resourcePath: path, name: q("#movie-edit-name").value.trim(), assets: [{ path, key: result.key }] });
    });
    q("#movie-edit-save").onclick = () => run(async () => {
      if (!result || resultRevision !== revision) throw Error("Make this version of your movie first.");
      await flushSave();
      if (!alive()) throw Error("Open this animation’s movie editor again.");
      const original = owner(), before = JSON.stringify(original), next = Forge.clone(original), occupied = [];
      for (let page = 0; page < 200; page++) {
        const rows = await Native.call("query", { table: "effect_packs", search: { column: "pack_name", text: "forge_movie_" + original.targetId + "_" }, offset: page * 5e3, limit: 5e3 });
        occupied.push(...rows.map((r) => r.pack_name));
        if (rows.length < 5e3) break;
        if (page === 199) throw Error("The movie catalog is too large to reserve a safe resource.");
      }
      for (const other of await Native.call("projects")) if (other.key !== key) {
        const p = await Native.call("loadProject", { key: other.key });
        occupied.push(...(p.tables.effect_packs || []).map((r) => r.pack_name));
      }
      for (const other of await ForgeAnimationGallery.list()) if (other.key !== key) occupied.push(...(other.tables.effect_packs || []).map((r) => r.pack_name));
      if (!alive() || JSON.stringify(owner()) !== before) throw Error("Your animation changed. Make the movie again.");
      const planned = ForgeMovieModel.plan(next, { schema: state.info.schema, assetKey: result.key, size: result.size, metadata: result, storageTag: result.storageTag, name: q("#movie-edit-name").value.trim(), occupiedPackNames: occupied });
      const bindingKey = ForgeMovieModel.apply(next, planned);
      next.animationStudio = next.animationStudio || { clips: [], name: "My combined animation", purpose: "super", target: "", dirty: false };
      next.animationStudio.clips.push(ForgeMovieModel.makeClip(next, bindingKey));
      const errors = ForgeMotion.validate(next.animationStudio.clips);
      if (errors.length) throw Error(errors[0]);
      next.animationStudio.dirty = true;
      next.updatedAt = new Date().toISOString();
      if (independent) {
        const saved = await ForgeAnimationGallery.commitPrepared(next);
        panel.close();
        studioState.mode = "compose";
        if (!saved.current) { toast("Movie saved to the original animation in My animations."); return; }
        await renderStudio();
        toast("Movie added to your animation as a new clip.");
        return;
      }
      await Native.call("saveProject", { project: next });
      if (!alive() || JSON.stringify(state.project) !== before) {
        status("Movie saved to the original unit in your Library. Reopen it to continue.");
        return;
      }
      state.project = next;
      panel.close();
      studioState.mode = "compose";
      await navigate("animations");
      toast("Movie added to your animation as a new clip.");
    });
    sections();
    plan();
    try {
      const loading = catalog();
      if (initial) await run((signal) => add(initial, signal));
      await loading;
    } catch (error) {
      status(error.message, true);
    }
    return panel;
  }
  return { open, store, encode };
})();
