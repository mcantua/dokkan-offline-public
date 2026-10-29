"use strict";
// "Offline downloads": save Eclipse files on the phone ahead of time so animations and pictures
// open without waiting. Native side: OfflineLibrary (forge/preview-cache, same files the player uses).
window.ForgeOffline = (() => {
  const PACKS = [
    { id: "essentials", title: "Essentials", size: "about 200 MB", text: "The animation player, every animation script (2,600+) and every character picture in the app. Lists, the clip picker and Add clip become instant." },
    { id: "units", title: "My units & animations", size: "about 10–30 MB per character", text: "Artwork, effects, sounds and game movies (like fusion scenes) for your saved units and every animation you made. Their previews and videos play right away." },
    { id: "everything", title: "Everything", size: "about 8–12 GB", text: "Artwork for every character and every animation effect, so any preview plays without waiting. Best on Wi-Fi; you can pause and continue later." },
    { id: "sparking", title: "Sparking custom content", size: "about 5 GB", text: "Only what Sparking made itself: custom characters and transformations, moves and abilities, animations and effects, and custom stages. Original game files are never downloaded from Sparking — they come from Eclipse.", needsSparking: true },
  ];
  let timer = null, pill = null, pillTimer = null, last = null;
  const mb = (bytes) => {
    const n = Number(bytes) || 0;
    return n >= 1073741824 ? (n / 1073741824).toFixed(2) + " GB" : (n / 1048576).toFixed(n >= 104857600 ? 0 : 1) + " MB";
  };
  const when = (ms) => {
    try { return new Date(ms).toLocaleDateString(); } catch { return ""; }
  };
  const running = (s) => Boolean(s?.job?.running);

  // ---------------------------------------------------------------- before any download
  // An earlier install's folder can only be reused / cleaned up with Android's "All files access".
  // Ask the beginner-friendly way; never go around Android.
  async function reusedGameData(c) {
    const data = c?.gameData;
    if (data?.restoredEclipse) {
      state.info = await Native.call("info");
      await loadLookups();
      try { localStorage.removeItem("forge-finder-index"); } catch {}
    }
    if (data?.restoredEclipse || data?.restoredSparking) toast("Your saved game databases are ready. No download was needed.");
    if (data?.warning) toast(data.warning, true);
  }
  async function storageReady(force = false) {
    let c;
    try { c = await Native.call("storageCheck"); } catch { return true; }   // nothing to check here
    await reusedGameData(c);
    if (!c || (!c.needsChoice && !force)) return true;
    return new Promise((resolve) => {
      let d = document.getElementById("storage-choice");
      if (!d) { d = document.createElement("dialog"); d.id = "storage-choice"; d.className = "shell-sheet storage-choice"; d.setAttribute("aria-labelledby", "storage-choice-title"); document.body.append(d); }
      const names = (c.old || []).map((o) => o.path || o.name).filter(Boolean);
      const legacy = c.permissionKind === "storage";
      const access = legacy ? "storage access" : "All files access";
      d.innerHTML = '<p class="eyebrow">YOUR DOWNLOADS FOLDER</p><h2 id="storage-choice-title">Reuse the files you already have?</h2>' +
        (names.length ? "<p>Your phone still has downloads from an earlier install: <strong>" + names.map(esc).join("</strong>, <strong>") + "</strong>.</p>" : "<p>Keep downloads in the phone's Downloads folder so you can reuse them after reinstalling this app.</p>") +
        "<p>Android requires <strong>" + access + "</strong> before the app can use that folder again. Reinstalling removes the old permission. The app only moves or deletes recognized app downloads; your other files stay untouched.</p>" +
        (legacy ? '<ol class="storage-steps"><li>Tap <strong>Allow access</strong>.</li><li>Allow the Android storage permission, then tap <strong>I turned it on</strong>.</li></ol>' : '<ol class="storage-steps"><li>Tap <strong>Allow access</strong>.</li><li>Turn on <strong>Allow access to manage all files</strong>.</li><li>Come back to the app — it continues by itself.</li></ol>') +
        '<p class="hint" id="storage-choice-status" role="status"></p>' +
        '<div class="row"><button type="button" class="button" data-sc="allow">Allow access (recommended)</button><button type="button" class="button ghost" data-sc="check" hidden>I turned it on</button></div>' +
        '<div class="row"><button type="button" class="button subtle" data-sc="separate">' + (legacy ? 'Keep downloads inside this app' : 'Use a separate folder instead') + '</button><button type="button" class="button subtle" data-sc="cancel">Not now</button></div>' +
        '<p class="hint">' + (legacy ? 'Downloads kept inside the app are deleted if you uninstall it. Your earlier shared files stay untouched.' : 'A separate folder works too, but the old files stay where they are until you delete them in Files.') + '</p>';
      const st = d.querySelector("#storage-choice-status");
      const done = (ok) => { document.removeEventListener("visibilitychange", onBack); if (d.open) d.close(); resolve(ok); };
      const recheck = async () => {
        try { c = await Native.call("storageCheck"); await reusedGameData(c); } catch (e) { st.textContent = e.message || String(e); return; }
        if (c && c.permission && c.public) { toast("Access is on. Existing downloads will be reused. Conflicting copies are kept safely."); done(true); return true; }
        st.textContent = c && c.permission ? "Access is on, but the shared folder could not be opened. Your existing files were kept. You can keep downloads inside this app for now." : access + " isn't on yet. Allow it, then check again.";
        return false;
      };
      const onBack = () => { if (document.visibilityState === "visible") setTimeout(recheck, 400); };
      d.querySelector('[data-sc="allow"]').onclick = async () => {
        try {
          const r = await Native.call("storageAccess");
          if (!r || !r.opened) { st.textContent = "Open Settings › Apps › Dokkan Unit Creator › Permissions and allow " + access + ", then check again."; }
          else st.textContent = legacy ? "Allow the Android storage permission, then tap “I turned it on”." : "Turn on “Allow access to manage all files”, then come back.";
        } catch (e) { st.textContent = e.message || String(e); }
        d.querySelector('[data-sc="check"]').hidden = false;
        document.addEventListener("visibilitychange", onBack);
      };
      d.querySelector('[data-sc="check"]').onclick = recheck;
      d.querySelector('[data-sc="separate"]').onclick = async () => { try { await Native.call("storageDecline"); } catch {} done(true); };
      d.querySelector('[data-sc="cancel"]').onclick = () => done(false);
      d.addEventListener("cancel", (e) => { e.preventDefault(); done(false); }, { once: true });
      if (!d.open) d.showModal();
    });
  }
  // asset keys still used by saved animations and the open draft (the native clean-up keeps them)
  async function keepKeys() {
    const texts = [], out = new Set();
    let complete = true;
    try { texts.push(localStorage.getItem("forge-draft") || ""); } catch {}
    try { if (typeof state !== "undefined" && state.project) texts.push(JSON.stringify(state.project)); } catch {}
    try { if (window.ForgeAnimationGallery) texts.push(JSON.stringify(await ForgeAnimationGallery.list())); else complete = false; } catch { complete = false; }
    for (const t of texts) for (const m of String(t).matchAll(/sparking-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/g)) out.add(m[0]);
    return { keepKeys: [...out], keepKeysComplete: complete };
  }
  let sparkingState = null;
  async function sparkingAvailable() {
    if (sparkingState) return sparkingState;
    try { const info = await Native.call("sparkingInfo"); sparkingState = { available: Boolean(info && info.available) }; }
    catch { sparkingState = { available: false }; }
    return sparkingState;
  }
  // ---------------------------------------------------------------- Sparking: the same update checks as Eclipse
  // A quick look at Sparking's server (date + size of its game database) on every app open and before downloads.
  const SP_SEEN = "forge-sparking-server";
  const spSig = (r) => (Number(r.lastModified) || 0) + ":" + (Number(r.size) || -1);
  async function sparkingNewer() {
    let info; try { info = await Native.call("sparkingInfo"); } catch { return { newer: false, available: false }; }
    if (!info || !info.available) return { newer: false, available: false };
    let r; try { r = await Native.call("checkSparkingUpdates"); } catch { return { newer: false, available: true }; }
    if (!r || !r.ok) return { newer: false, available: true };
    const meta = info.meta || {}, mine = Date.parse(meta.date || "") || 0;
    let seen = null; try { seen = localStorage.getItem(SP_SEEN); } catch {}
    let newer;
    if (mine && r.lastModified) newer = Number(r.lastModified) > mine;                  // the server's data is newer than ours
    else if (seen) newer = seen !== spSig(r);
    else { newer = false; try { localStorage.setItem(SP_SEEN, spSig(r)); } catch {} }   // first check: remember where we are
    return { newer, available: true, size: Number(r.size) > 0 ? Number(r.size) : 0, label: r.lastModified ? new Date(Number(r.lastModified)).toLocaleDateString() : "" };
  }
  async function updateSparkingNow() {
    const r = await Native.call("checkSparkingUpdates").catch(() => null);
    const run = () => Native.call("updateSparking");
    if (typeof databaseTask === "function") await databaseTask("Updating Sparking characters", run); else await run();
    if (r && r.ok) { try { localStorage.setItem(SP_SEEN, spSig(r)); } catch {} }
    sparkingState = null;
    // Sparking files you downloaded before are brought up to date as well
    try {
      const s = await status();
      if (s && s.completed && s.completed.sparking && !running(s)) { last = await start({ action: "start", packs: ["sparking"], wifiOnly: s.wifiOnly !== false, movies: false }); updatePill(last); toast("Updating your Sparking downloads in the background."); }
    } catch {}
  }
  // "Wi-Fi only" really means it: nothing is downloaded over mobile data (the phone's own setting is used too)
  async function netAllows(wifiOnly) {
    let n = {};
    try { n = (await Native.call("offlineLibrary", { action: "status" })).network || {}; } catch {}
    if (n.web || n.unknown) return true;
    if (n.connected === false) return false;
    return !wifiOnly || (!n.metered && n.wifi !== false);
  }
  async function start(args) {
    if (!(await storageReady())) throw new Error("Download not started.");
    // game data updates are big too: on mobile data with Wi-Fi only on, they wait (the download job waits for Wi-Fi as well)
    if (await netAllows(args.wifiOnly !== false)) await latestData((args.packs || []).includes("sparking"));
    Object.assign(args, await keepKeys());
    return Native.call("offlineLibrary", args);
  }
  // Settings › "Clean up old files now"
  async function cleanup() {
    try {
      last = await start({ action: "start", packs: ["tidy"], wifiOnly: true, movies: false });
      updatePill(last);
      toast("Cleaning up old files…");
      open();
    } catch (e) { if (!/not started/.test(e.message)) toast(e.message || String(e), true); }
  }
  function cleanupText(c) {
    if (!c || typeof c !== "object") return "";
    const bits = [];
    if (c.freedBytes > 0) bits.push("freed " + mb(c.freedBytes));
    if (c.reused > 0) bits.push(c.reused + " files reused instead of downloaded again");
    if (c.reowned > 0) bits.push(c.reowned + " files taken over from an earlier install");
    if (c.conflicts > 0) bits.push(c.conflicts + " conflicting copies kept safely");
    if (c.merged && c.merged.length) bits.push("merged " + c.merged.join(", "));
    return bits.length ? "🧹 Cleaned up old files: " + bits.join(" · ") + "." : "🧹 No old or duplicate files found.";
  }

  async function status() {
    last = await Native.call("offlineLibrary", { action: "status" });
    updatePill(last);
    return last;
  }

  // ---------------------------------------------------------------- unit list for "My units"
  async function unitTargets(report = () => {}) {
    const projects = await Native.call("projects").catch(() => []);
    const cards = new Set(), scripts = new Set(), moviePacks = new Set();
    // the moves (and game movies) in your animations: units' own and My animations
    const fromClips = (clips) => {
      for (const c of clips || []) {
        const path = c?.source?.path;
        if (typeof path === "string" && /^ab_script\/[a-z0-9_\/-]+\.lua$/i.test(path) && !path.startsWith("ab_script/forge_movie/")) scripts.add(path);
        const pack = Number(c?.source?.movieEffectPackId) || 0;
        if (pack > 0) moviePacks.add(pack);
      }
    };
    try { for (const doc of (window.ForgeAnimationGallery ? await ForgeAnimationGallery.list() : []) || []) fromClips(doc?.animationStudio?.clips); } catch {}
    let files = [];
    try { files = await Native.call("animationFiles", {}); } catch {}
    const list = (projects || []).slice(0, 80), sourcesDone = new Set();
    let n = 0;
    // six units at a time; each character's moves are looked up once even if several units use it
    const one = async (item) => {
      try {
        const p = await Native.call("loadProject", { key: item.key });
        fromClips(p?.animationStudio?.clips);
        const source = Number(p?.source?.cardId) || 0;
        if (!source || (p?.source?.database && p.source.database !== "eclipse")) return;
        cards.add(source);
        const art = Number(p?.previewAppearance?.artCardId) || 0;
        if (art) cards.add(art);
        if (sourcesDone.has(source)) return;
        sourcesDone.add(source);
        for (let offset = 0; offset < 48; offset += 12) {
          const page = await Native.call("animationCatalog", { search: "", kind: "all", offset, unitId: source, sourceDatabase: "eclipse" });
          for (const entry of page.items || []) {
            if (entry.unitId && entry.unitId !== source) cards.add(Number(entry.unitId));
            let path = entry.path || null;
            if (!path && entry.script) { try { path = ForgeMotion.pathFor(entry.script, files); } catch {} }
            if (path) scripts.add(path);
          }
          if (!page.more) break;
        }
      } catch {} finally { report(++n, list.length); }
    };
    let next = 0;
    await Promise.all(Array.from({ length: Math.min(6, list.length) }, async () => { while (next < list.length) await one(list[next++]); }));
    return { cards: [...cards].filter((id) => id > 0 && id < 9000000).slice(0, 400), scripts: [...scripts].slice(0, 2000), moviePacks: [...moviePacks].slice(0, 400), units: (projects || []).length };
  }

  // ---------------------------------------------------------------- dialog
  async function open() {
    dialog("Downloads", '<div id="offline-root" class="offline"><p class="hint">Loading…</p></div>');
    const root = document.getElementById("offline-root");
    const alive = () => root.isConnected && document.getElementById("dialog")?.open;
    let separate = false;
    try { separate = Boolean((await ForgeDock.separateWindow()).separateWindow); } catch {}
    let cache = {};
    try { cache = await Native.call("previewCache"); } catch {}
    let s;
    try { s = await status(); } catch (error) {
      root.innerHTML = '<p class="notice error">' + esc(error.message || "Offline downloads are unavailable.") + "</p>";
      return;
    }
    // Super simple: two big tiles (Eclipse, Sparking) you switch on or off, one small "Download everything" button.
    const jobPacks = running(s) ? (s.job.packs || []) : null;
    const done = s.completed || {};
    let eclipseOn = jobPacks ? jobPacks.some((x) => x !== "sparking") : true;
    let sparkingOn = jobPacks ? jobPacks.includes("sparking") : Boolean(done.sparking);
    let basicsOnly = jobPacks ? !jobPacks.includes("everything") && eclipseOn : Boolean(done.essentials && !done.everything);
    let size = basicsOnly ? "basics" : "everything";
    let withSparking = sparkingOn;
    const chosen = new Set();
    const choose = () => {
      chosen.clear();
      if (eclipseOn) { chosen.add("essentials"); chosen.add("units"); if (!basicsOnly) chosen.add("everything"); }
      if (sparkingOn) chosen.add("sparking");
      size = basicsOnly ? "basics" : "everything"; withSparking = sparkingOn;
    };
    const chosenLabel = () => [eclipseOn ? (basicsOnly ? "Eclipse basics" : "Eclipse game files") : "", sparkingOn ? "Sparking game files" : ""].filter(Boolean).join(" + ") || "nothing yet";
    choose();
    root.innerHTML =
      '<p class="of-lead">Tap what you want on this phone, then Download. Files you already have are skipped.</p>' +
      (window.__forgeIOS ? '<p class="of-reuse" id="offline-reuse"></p>' : "") +
      (window.__forgeIOS ? '<p class="of-reuse" id="offline-dokkan-files"></p>' : "") +
      '<div class="of-tiles">' +
      '<label class="of-tile of-eclipse"><input type="checkbox" id="offline-eclipse-on"' + (eclipseOn ? " checked" : "") + '><span class="of-tile-check" aria-hidden="true"></span><span class="of-tile-body"><strong>🟠 Eclipse</strong><small id="offline-eclipse-size">' + (basicsOnly ? "about 200 MB" : "8–12 GB") + '</small><span class="of-opt-text">Every Eclipse character, animation and effect.</span><span class="offline-done" data-done="' + (basicsOnly ? "essentials" : "everything") + '"></span></span></label>' +
      '<label class="of-tile of-spark"><input type="checkbox" id="offline-sparking-on"' + (sparkingOn ? " checked" : "") + '><span class="of-tile-check" aria-hidden="true"></span><span class="of-tile-body"><strong>✨ Sparking</strong><small>optional · about 5 GB</small><span class="of-opt-text">Sparking’s own characters, moves, effects and stages.</span><span class="offline-done" data-done="sparking"></span><span class="of-sp-status" id="offline-sp-status"></span></span></label>' +
      "</div>" +
      '<label class="check-item of-data"><input type="checkbox" id="offline-any"' + (s.wifiOnly === false ? " checked" : "") + ">Also use mobile data (off = Wi-Fi only)</label>" +
      '<div class="row offline-actions"><button type="button" class="button of-go" id="offline-start">⬇ Download</button><button type="button" class="button ghost" id="offline-pause" hidden>Pause</button><button type="button" class="button subtle" id="offline-cancel" hidden>Cancel</button><button type="button" class="button ghost" id="offline-mobile" hidden>Use mobile data now</button></div>' +
      '<button type="button" class="button subtle small of-all" id="offline-all">⬇ Download everything <small>Eclipse + Sparking + game movies · 50 GB+</small></button>' +
      '<div class="offline-progress" aria-live="polite"><p class="offline-phase" id="offline-phase"></p><progress id="offline-bar" max="1" value="0" hidden></progress><p class="hint" id="offline-detail"></p></div>' +
      '<div data-offline-errors></div>' +
      '<details class="offline-more"><summary>More options</summary>' +
      '<section id="offline-creations" hidden><h3>Keep creations after reinstall</h3><p>Before uninstalling, save your latest units, saved versions, My animations editing documents and imported resources in one archive in Downloads. Saving again replaces that same archive. After reinstalling, allow storage access and restore it here. AI and Sparking connections must be set up again.</p><p class="hint">Up to 2 GB total, 10,000 files and 512 MB per file. Gallery editing data: up to 1,000 documents, 8 MiB each and 16 MiB total. Export larger collections separately. This is a manual snapshot, not an automatic backup after every edit.</p><p class="hint" data-creations-status></p><div class="row"><button type="button" class="button ghost small" data-creations-access>Allow storage access</button><button type="button" class="button ghost small" data-creations-save>Save creations for reinstall</button><button type="button" class="button ghost small" data-creations-restore>Restore creations</button></div></section>' +
      '<label class="check-item"><input type="checkbox" id="offline-basics"' + (basicsOnly ? " checked" : "") + ">Low on space: only the Eclipse basics (about 200 MB). The rest loads the first time you use it.</label>" +
      '<label class="check-item"><input type="checkbox" id="offline-movies"' + (s.movies ? " checked" : "") + '>Also every Eclipse game movie (40 GB or more). Otherwise a movie downloads the first time it plays.</label>' +
      '<label class="check-item"><input type="checkbox" id="offline-mode"' + (cache.offline ? " checked" : "") + ">Use downloaded files only (offline preview)</label>" +
      '<fieldset class="offline-player"><legend>Where previews play</legend><label class="check-item"><input type="radio" name="offline-player" value="dock"' + (separate ? "" : " checked") + '>Inside the app, in a panel at the top (recommended)</label><label class="check-item"><input type="radio" name="offline-player" value="window"' + (separate ? " checked" : "") + ">On a separate screen</label></fieldset>" +
      '<p class="hint" id="offline-storage"></p>' +
      '<p class="hint">' + (window.__forgeIOS ? "On iPhone, keep the app open while it downloads. If it stops, it continues by itself the next time you open the app." : "It keeps downloading with the screen off or while you use other apps. If it ever stops, it continues by itself the next time you open the app.") + '</p>' +
      '</details>';
    const $r = (sel) => root.querySelector(sel);
    let starting = false, sparkReady = true;
    const spStatus = $r("#offline-sp-status");
    sparkingAvailable().then(async (x) => {
      const box = $r("#offline-sparking-on");
      if (!box) return;
      if (!x.available) {
        sparkReady = false; box.checked = false; box.disabled = true; box.dataset.unavailable = "1"; sparkingOn = false; choose();
        spStatus.innerHTML = '<span class="offline-note">Not set up yet.</span> <button type="button" class="button ghost small" data-sp-setup>Set up Sparking</button>';
        const b = spStatus.querySelector("[data-sp-setup]"); if (b) b.onclick = (e) => { e.preventDefault(); document.getElementById("dialog")?.close(); if (typeof state !== "undefined") state.libraryFilter = "sparking"; if (typeof navigate === "function") navigate("library"); };
        draw(last); return;
      }
      spStatus.textContent = "Checking for updates…";
      const sp = await sparkingNewer().catch(() => ({ newer: false }));
      if (!alive()) return;
      spStatus.innerHTML = sp.newer ? '<span class="of-sp-new">New Sparking characters' + (sp.label ? " (" + esc(sp.label) + ")" : "") + ' — they come first</span>' : '<span class="of-sp-ok">✓ Up to date</span>';
    });
    // iPhone: the Sparking app keeps its downloaded game files in its Files folder. With that folder linked, files it
    // already has are copied from there instead of downloaded, and a reinstall of this app never means downloading them again.
    const reuseBox = $r("#offline-reuse");
    const showReuse = async () => {
      if (!reuseBox) return;
      let st = null; try { st = await Native.call("gameFolderStatus", { target: "sparking" }); } catch {}
      if (!alive()) return;
      if (st && st.linked && st.ok) { reuseBox.innerHTML = '<span class="of-sp-ok">✓ Files the Sparking app already has are taken from its folder, not downloaded again.</span>'; return; }
      reuseBox.innerHTML = '<span>Have the Sparking app on this phone? Link its folder once and the files it already has won’t be downloaded again.</span> <button type="button" class="button ghost small" data-reuse-link>Link Sparking’s folder</button>';
      reuseBox.querySelector("[data-reuse-link]").onclick = async () => {
        try {
          const r = await Native.call("linkGameFolder", { target: "sparking" });
          if (r && r.linked && r.looksRight === false) toast("That folder is “" + r.name + "”. Pick On My iPhone › Sparking.", true);
          else if (r && r.linked) toast("Linked. Sparking’s files will be reused.");
        } catch (e) { toast(e.message || String(e), true); }
        showReuse();
      };
    };
    showReuse();
    const filesBox = $r("#offline-dokkan-files");
    const showFiles = async () => {
      if (!filesBox) return;
      let st; try { st = await Native.call("dokkanFiles"); } catch { return; }
      if (!alive()) return;
      filesBox.innerHTML = (st.linked && st.ok ? '<span>✓ Dokkan Files folder linked: “' + esc(st.name) + '”. Eclipse downloads will save a copy here.</span> ' : '<span>Keep Eclipse characters after reinstall: choose a Dokkan Files folder in iCloud Drive or another folder outside this app.</span> ') +
        '<span>After reinstall, select that same folder again before downloading.</span> ' +
        '<button type="button" class="button ghost small" data-files-link>' + (st.linked ? "Choose folder again" : "Choose Dokkan Files") + '</button>' +
        (st.linked ? ' <button type="button" class="button subtle small" data-files-unlink>Unlink</button>' : "") +
        (st.warning ? '<span class="notice">' + esc(st.warning) + '</span>' : "");
      filesBox.querySelector("[data-files-link]").onclick = async () => {
        try {
          const r = await Native.call("dokkanFiles", { action: "link" });
          if (r.linked) toast(r.warning || "Linked. Saved Eclipse characters will be checked before downloading.", !!r.warning);
        } catch (e) { toast(e.message || String(e), true); }
        showFiles();
      };
      const unlink = filesBox.querySelector("[data-files-unlink]");
      if (unlink) unlink.onclick = async () => {
        try { await Native.call("dokkanFiles", { action: "unlink" }); await showFiles(); }
        catch (e) { toast(e.message || String(e), true); }
      };
    };
    showFiles();
    const creations = $r("#offline-creations");
    const showCreations = async () => {
      let st; try { st = await Native.call("userContentArchive", { action: "status" }); } catch { return; }
      if (!alive() || !st || !creations) return;
      creations.hidden = false;
      const message = creations.querySelector("[data-creations-status]");
      message.textContent = st.warning || (st.available ? (st.exists ? "One saved archive is in " + st.folder + ". Only your last saved copy survives uninstall; save again after editing." : "No readable creations archive found. If you saved one earlier, allow storage access again; otherwise save one before uninstalling.") : "Allow shared-storage access first. An archive inside the app would be deleted on uninstall.");
      creations.querySelector("[data-creations-save]").disabled = !st.available || !!st.warning;
      creations.querySelector("[data-creations-restore]").disabled = !st.available || !st.exists || !!st.warning;
      creations.querySelector("[data-creations-access]").hidden = !!st.available && !!st.exists && !st.warning;
      creations.querySelector("[data-creations-access]").onclick = async () => { await storageReady(true); await showCreations(); };
      const run = async (action) => {
        const buttons = [...creations.querySelectorAll("button")]; buttons.forEach(b => b.disabled = true);
        message.textContent = action === "save" ? "Saving your creations. Keep the app open…" : "Checking and restoring your saved creations…";
        let failure="";
        try {
          if (typeof flushSave === "function") await flushSave();
          if(action==="save"&&!st.galleryDocuments)throw Error("Update the Android app before backing up My animations with your other creations.");
          const gallery=action==="save"?await ForgeAnimationGallery.archiveSnapshot():null;
          const r = await Native.call("userContentArchive", { action,...gallery?{gallery}:{} });
          if(action==="save")toast("Saved one archive with " + r.files + " files, including "+r.galleryDocuments+" gallery documents. Private databases and credentials are excluded.");
          else if(r.gallery){
            let restored;
            try{restored=await ForgeAnimationGallery.restoreArchiveSnapshot(r.gallery);}catch(error){throw Error("Your files were restored, but My animations could not be restored. The archive is unchanged: free some device storage and tap Restore creations again. "+(error.message||String(error)));}
            toast("Restored "+r.restored+" files and "+restored.restored+" animations; "+restored.unchanged+" gallery documents were already identical.");
            if(restored.conflicts.length)toast("Kept "+restored.conflicts.length+" existing animation"+(restored.conflicts.length===1?"":"s")+" that differ from the archive: "+restored.conflicts.slice(0,5).map(doc=>doc.name).join(", ")+". Nothing was overwritten.",true);
          }else toast("Restored "+r.restored+" files; "+r.unchanged+" were already identical. This older archive contains no independent My animations editing documents.");
          if (action === "save" && r.excluded) toast(r.excluded + " unsupported or private files were excluded. Export any other important files separately.", true);
          if (action === "restore" && typeof navigate === "function") { document.getElementById("dialog")?.close(); navigate("library"); return; }
        } catch (e) { failure=e.message || String(e); toast(failure, true); }
        buttons.forEach(b => b.disabled = false); await showCreations();
        if(failure)message.textContent=failure;
      };
      creations.querySelector("[data-creations-save]").onclick = () => run("save");
      creations.querySelector("[data-creations-restore]").onclick = () => run("restore");
    };
    showCreations();
    $r("#offline-eclipse-on").onchange = (e) => { eclipseOn = e.target.checked; choose(); draw(last); };
    $r("#offline-sparking-on").onchange = (e) => { sparkingOn = e.target.checked; choose(); draw(last); };
    $r("#offline-basics").onchange = (e) => { basicsOnly = e.target.checked; $r("#offline-eclipse-size").textContent = basicsOnly ? "about 200 MB" : "8–12 GB"; choose(); draw(last); };
    $r("#offline-any").onchange = (e) => Native.call("offlineLibrary", { action: "wifiOnly", value: !e.target.checked }).then(draw).catch((err) => toast(err.message, true));
    $r("#offline-mode").onchange = (e) => Native.call("previewCache", { offline: e.target.checked }).then(() => toast(e.target.checked ? "Previews now use downloaded files only." : "Previews can download missing files again.")).catch((err) => toast(err.message, true));
    root.querySelectorAll('[name="offline-player"]').forEach((radio) => radio.onchange = () => ForgeDock.separateWindow(radio.value === "window").then(() => toast(radio.value === "window" ? "Previews will open on a separate screen." : "Previews will play inside the app.")).catch((err) => toast(err.message, true)));
    // the small third option: everything there is, in one tap
    $r("#offline-all").onclick = () => {
      eclipseOn = true; basicsOnly = false; sparkingOn = sparkReady;
      $r("#offline-eclipse-on").checked = true; $r("#offline-basics").checked = false; $r("#offline-eclipse-size").textContent = "8–12 GB";
      if (sparkReady) $r("#offline-sparking-on").checked = true;
      $r("#offline-movies").checked = true;
      choose(); draw(last);
      $r("#offline-start").click();
    };
    $r("#offline-start").onclick = async () => {
      if (!chosen.size) return toast("Tap Eclipse, Sparking or both first.", true);
      const button = $r("#offline-start"), phase = $r("#offline-phase");
      button.disabled = true;
      button.textContent = "Starting…";
      phase.classList.remove("offline-error");
      phase.textContent = "Starting the download…";
      starting = true;
      try {
        const args = { action: "start", packs: [...chosen], wifiOnly: !$r("#offline-any").checked, movies: eclipseOn && !basicsOnly && $r("#offline-movies").checked };
        if (chosen.has("units") && !chosen.has("everything")) {
          Object.assign(args, await unitTargets((n, total) => { if (alive()) phase.textContent = "Finding the characters, moves and movies in your units… " + n + " of " + total; }));
          if (!args.cards.length && !args.scripts.length && !args.moviePacks.length) toast("No saved units or animations use Eclipse characters yet. Essentials will still download.");
        }
        last = await start(args);
        starting = false;
        draw(last);
        poll();
        if (last && last.job && last.job.waiting) toast(last.job.waiting);
      } catch (error) {
        starting = false;
        if (/not started/.test(String(error && error.message))) { starting = false; if (alive()) { phase.textContent = ""; button.disabled = false; button.textContent = "⬇ Download"; } return; }
        const why = error.message || "The download could not start.";
        toast(why, true);
        if (alive()) { phase.classList.add("offline-error"); phase.textContent = "The download didn't start: " + why; }
        button.disabled = false;
        button.textContent = "Try again";
        return;
      } finally {
        starting = false;
        button.disabled = false;
      }
    };
    $r("#offline-pause").onclick = async () => draw(last = await Native.call("offlineLibrary", { action: last?.job?.paused ? "resume" : "pause" }));
    $r("#offline-cancel").onclick = async () => draw(last = await Native.call("offlineLibrary", { action: "cancel" }));
    // A download waiting for Wi-Fi looks stuck; one tap lets it use mobile data instead.
    $r("#offline-mobile").onclick = async () => { $r("#offline-any").checked = true; draw(last = await Native.call("offlineLibrary", { action: "wifiOnly", value: false })); toast("Downloading on mobile data."); };

    function draw(state) {
      if (!state || !alive() || starting) return;
      updatePill(state);
      const job = state.job, active = running(state);
      for (const pack of PACKS) {
        const done = state.completed?.[pack.id], el = root.querySelector('[data-done="' + pack.id + '"]');
        if (el) el.textContent = done ? " ✓ Downloaded " + when(done.at) + (done.failed ? " (" + done.failed + " files were unavailable)" : "") : "";
      }
      root.querySelectorAll("#offline-eclipse-on,#offline-sparking-on,#offline-basics,#offline-movies").forEach((e) => e.disabled = active || e.dataset.unavailable === "1");
      $r("#offline-all").hidden = active;
      $r("#offline-start").hidden = active;
      $r("#offline-start").textContent = job && job.finished && !job.cancelled && job.error === "" ? "⬇ Check for updates & download" : job && (job.cancelled || job.error) ? "⬇ Continue downloading" : "⬇ Download";
      $r("#offline-pause").hidden = !active;
      $r("#offline-pause").textContent = job?.paused ? "Resume" : "Pause";
      $r("#offline-cancel").hidden = !active;
      $r("#offline-mobile").hidden = !(active && /Wi-Fi/.test(job?.waiting || ""));
      if (!active && !job) { const n = state.network || {}; if (!$r("#offline-any").checked && (n.metered || n.wifi === false)) $r("#offline-phase").dataset.nowifi = "1"; else delete $r("#offline-phase").dataset.nowifi; }
      const bar = $r("#offline-bar"), phase = $r("#offline-phase"), detail = $r("#offline-detail");
      if (job) {
        const total = Math.max(1, job.total), done = Math.min(job.done, total);
        bar.hidden = !active;
        bar.max = total;
        bar.value = done;
        const pct = Math.floor((done / total) * 100);
        const nothing = !active && !job.error && !job.cancelled && job.failed > 0 && !(job.savedBytes > 0) && job.done <= job.failed + job.skipped + 2;
        phase.classList.toggle("offline-error", Boolean(!active && (job.error || nothing)));
        phase.textContent = active ? (job.waiting ? job.waiting : job.phase + (job.label ? " · " + job.label : "")) : job.error ? "Stopped: " + job.error : job.cancelled ? "Cancelled. Files saved so far are kept." : nothing ? "Nothing could be downloaded. " + (job.failures?.[0] ? "Reason: " + job.failures[0] : "Check your internet connection and try again.") : job.failed ? "Finished, but " + job.failed + " files couldn't be saved. Tap Download again to retry them." : "Finished. Everything you chose is on this phone.";
        detail.textContent = (active ? pct + "% · " : "") + job.done + " of " + job.total + " items checked · " + mb(job.savedBytes) + " downloaded" + (job.reused ? " · " + mb(job.reusedBytes) + " taken from Sparking (no download)" : "") + (job.skipped ? " · " + job.skipped + " not on Eclipse" : "") + (job.failed ? " · " + job.failed + " failed (download again to retry)" : "");
        if (job.cleanup) detail.textContent += (detail.textContent ? "\n" : "") + cleanupText(job.cleanup);
        if (job.originalsSkipped > 0) detail.textContent += "\n" + job.originalsSkipped + " original Sparking files skipped — Eclipse already has them.";
        const errors = root.querySelector("[data-offline-errors]");
        errors.innerHTML = job.failures?.length ? '<details class="offline-fail"' + (active ? "" : " open") + '><summary>' + job.failures.length + (job.failures.length >= 20 ? "+" : "") + ' files couldn\'t be saved — see why</summary><ul class="offline-errors">' + job.failures.slice(0, 8).map((f) => "<li>" + esc(f) + "</li>").join("") + '</ul><button type="button" class="button ghost small" data-offline-copy>Copy the details</button></details>' : "";
        const copy = errors.querySelector("[data-offline-copy]");
        if (copy) copy.onclick = () => Native.call("copy", { text: "Offline download problems:\n" + job.failures.join("\n") }).then(() => toast("Copied — paste it to me so I can fix it.")).catch(() => {});
      } else {
        bar.hidden = true;
        phase.textContent = "Ready: " + chosenLabel() + "." + (phase.dataset.nowifi ? " You're not on Wi-Fi — it starts when you connect to Wi-Fi." : "");
        detail.textContent = "";
      }
      const st = state.storage || {};
      $r("#offline-storage").textContent = (state.folder ? "Saved in: " + state.folder + " · " : "") + "Saved for previews: " + mb(st.bytes) + (st.free != null ? " · Free on this phone: " + mb(st.free) : "") + (state.network && state.network.connected === false ? " · No Internet connection" : state.network?.metered ? " · On mobile data" : "");
    }
    function poll() {
      clearInterval(timer);
      timer = setInterval(async () => {
        if (!alive()) { clearInterval(timer); timer = null; return; }
        try { draw(await status()); } catch {}
      }, 1000);
    }
    draw(s);
    poll();
  }

  // ---------------------------------------------------------------- small progress pill
  function updatePill(state) {
    const active = running(state);
    if (!pill) {
      pill = document.createElement("button");
      pill.type = "button";
      pill.id = "offline-pill";
      pill.hidden = true;
      pill.onclick = () => open();
      document.body.append(pill);
    }
    pill.hidden = !active;
    if (active && state.job.resumed && !updatePill.told) { updatePill.told = true; toast("Continuing your download where it stopped."); }
    if (active) {
      const j = state.job, pct = Math.floor((Math.min(j.done, Math.max(1, j.total)) / Math.max(1, j.total)) * 100);
      pill.textContent = (j.paused ? "⏸ " : "⬇ ") + pct + "%";
      pill.setAttribute("aria-label", "Offline downloads " + pct + " percent" + (j.paused ? ", paused" : "") + ". Open downloads.");
      if (!pillTimer) pillTimer = setInterval(() => { if (!document.getElementById("dialog")?.open || !document.getElementById("offline-root")) status().catch(() => {}); }, 4000);
    } else if (pillTimer) {
      clearInterval(pillTimer);
      pillTimer = null;
    }
  }

  // ---------------------------------------------------------------- new game data on every app open
  // Each time the app opens it quietly asks Eclipse whether newer game data exists; if so: one simple prompt.
  async function newDataPrompt() {
    if (navigator.webdriver && !window.__forceDbPrompt) return;
    const [n, sp] = await Promise.all([
      window.ForgeImport && ForgeImport.newer ? ForgeImport.newer().catch(() => ({ newer: false })) : { newer: false },
      sparkingNewer().catch(() => ({ newer: false }))]);
    if (!n.newer && !sp.newer) return;
    return new Promise((resolve) => {
      let d = document.getElementById("new-data");
      if (!d) { d = document.createElement("dialog"); d.id = "new-data"; d.className = "shell-sheet new-data"; d.setAttribute("aria-labelledby", "new-data-title"); document.body.append(d); }
      const mbOf = (b, def) => Math.max(1, Math.round((b || def) / 1048576));
      const total = (n.newer ? mbOf(n.size, 100 * 1048576) : 0) + (sp.newer ? mbOf(sp.size, 113 * 1048576) : 0);
      d.innerHTML = '<h2 id="new-data-title">🆕 New game data</h2>' +
        (n.newer ? "<p>Dokkan Eclipse has new characters" + (n.label ? " (" + esc(n.label) + ")" : "") + ".</p>" : "") +
        (sp.newer ? "<p>✨ Sparking has new characters" + (sp.label ? " (" + esc(sp.label) + ")" : "") + ".</p>" : "") +
        "<p>Your units are kept.</p>" +
        '<div class="row"><button type="button" class="button" data-nd="now">⬇ Download now · about ' + total + ' MB</button><button type="button" class="button subtle" data-nd="later">Later</button></div>';
      const done = () => { if (d.open) d.close(); resolve(); };
      d.querySelector('[data-nd="later"]').onclick = done;
      d.querySelector('[data-nd="now"]').onclick = async () => {
        let wifiOnly = true; try { wifiOnly = (await status()).wifiOnly !== false; } catch {}
        if (!(await netAllows(wifiOnly))) {
          const btn = d.querySelector('[data-nd="now"]');
          if (!btn.dataset.asked) { btn.dataset.asked = "1"; btn.insertAdjacentHTML("afterend", '<p class="hint offline-warn">You\'re not on Wi-Fi and “Wi-Fi only” is on. Connect to Wi-Fi and tap Download now again — or tap it once more to use mobile data this time.</p>'); return; }
        }
        if (d.open) d.close();
        if (n.newer) { try { await ForgeImport.update({ quiet: true }); } catch (e) {} }
        if (sp.newer) { try { await updateSparkingNow(); toast("Sparking characters are up to date."); } catch (e) { toast(e.message || String(e), true); } }
        resolve();
      };
      d.addEventListener("cancel", (e) => { e.preventDefault(); done(); }, { once: true });
      if (!d.open) d.showModal();
    });
  }
  // before any file download: always get the newest game data first, so the files match it
  async function latestData(withSparking) {
    if (window.ForgeImport && ForgeImport.newer) {
      const n = await ForgeImport.newer();
      if (n.newer) { toast("Getting the newest game data first…"); await ForgeImport.update({ quiet: true }).catch(() => {}); }
    }
    if (withSparking) {
      const sp = await sparkingNewer();
      if (sp.newer) { toast("Getting the newest Sparking characters first…"); await Native.call("updateSparking").then(async () => { const r = await Native.call("checkSparkingUpdates").catch(() => null); if (r && r.ok) try { localStorage.setItem(SP_SEEN, spSig(r)); } catch {} sparkingState = null; }).catch(() => {}); }
    }
  }

  // ---------------------------------------------------------------- first launch: download now, wait never
  // The very first thing the app asks: get Essentials or Everything onto the phone so animations, pictures,
  // sprites, battle motions and effects open instantly instead of loading each time. Asked once per install
  // (and again only if nothing was ever downloaded and you never answered). Resolves when it's closed.
  const ASKED = "forge-offline-asked";
  function asked() { try { return localStorage.getItem(ASKED) === "1"; } catch { return true; } }
  function markAsked() { try { localStorage.setItem(ASKED, "1"); } catch {} }
  async function firstRun() {
    if (asked() || navigator.webdriver) return;
    let s;
    try { s = await status(); } catch { return; }
    if (!s || s.web) return;                                   // the website can't keep files: apps only
    if (running(s) || Object.keys(s.completed || {}).length) { markAsked(); return; }
    // the first time: the same simple Downloads screen (Eclipse / Sparking / Download everything)
    markAsked();
    await open();
    return new Promise((resolve) => {
      const d = document.getElementById("dialog");
      if (!d || !d.open) return resolve();
      d.addEventListener("close", () => resolve(), { once: true });
    });
  }

  function button(label = "Offline downloads", cls = "ghost small") {
    return '<button type="button" class="button ' + cls + '" data-offline-open>⬇ ' + esc(label) + "</button>";
  }
  document.addEventListener("click", (event) => {
    const target = event.target.closest && event.target.closest("[data-offline-open]");
    if (target) { event.preventDefault(); open(); return; }
    const clean = event.target.closest && event.target.closest("[data-offline-cleanup]");
    if (clean) { event.preventDefault(); cleanup(); }
  });
  setTimeout(() => status().catch(() => {}), 3000);
  return { open, status, button, firstRun, cleanup, storageReady, newDataPrompt };
})();
