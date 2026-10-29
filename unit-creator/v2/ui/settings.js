"use strict";
// Settings: look & comfort, how much help you get, animations, speed and your data.
// Every section has "Restore defaults"; "Restore all defaults" resets the whole app's settings
// (your units and files are never touched).
window.ForgeSettings = (() => {
  let sheet = null;
  const radio = (name, value, current, title, text = "") => '<label class="set-choice' + (String(value) === String(current) ? " on" : "") + '"><input type="radio" name="' + name + '" value="' + value + '"' + (String(value) === String(current) ? " checked" : "") + "><span><strong>" + esc(title) + "</strong>" + (text ? "<small>" + esc(text) + "</small>" : "") + "</span></label>";
  const toggle = (id, on, title, text = "") => '<label class="set-toggle"><span><strong>' + esc(title) + "</strong>" + (text ? "<small>" + esc(text) + "</small>" : "") + '</span><input type="checkbox" role="switch" id="' + id + '"' + (on ? " checked" : "") + "></label>";
  const section = (id, title, intro, html, reset = false) => '<section class="set-section" id="set-' + id + '"><div class="set-head"><h3>' + esc(title) + "</h3>" + (reset ? '<button type="button" class="text-button" data-set-reset="' + id + '">Restore defaults</button>' : "") + "</div>" + (intro ? '<p class="hint">' + esc(intro) + "</p>" : "") + html + "</section>";

  async function open(focus) {
    if (!sheet) {
      sheet = document.createElement("dialog");
      sheet.className = "shell-sheet settings-sheet";
      sheet.setAttribute("aria-labelledby", "settings-title");
      document.body.append(sheet);
    }
    const s = ForgeShell.settings();
    let dock = { separateWindow: false, startFull: true, quality: "auto" }, cache = { offline: false };
    try { dock = await ForgeDock.separateWindow(); } catch {}
    try { cache = await Native.call("previewCache"); } catch {}
    const lite = window.ForgePerf ? ForgePerf.lite() : false;
    const player = dock.separateWindow ? "window" : dock.startFull === false ? "half" : "full";
    const quality = ["auto", "smooth", "best"].includes(dock.quality) ? dock.quality : "auto";
    sheet.innerHTML = '<div class="sheet-head"><h2 id="settings-title">Settings</h2><button type="button" class="icon-button" data-sheet-close aria-label="Close settings">×</button></div>' +
      '<nav class="set-jump" aria-label="Settings sections">' + [["game", "Game data"], ["look", "Look"], ["help", "Help level"], ["anim", "Animations"], ["speed", "Speed"], ["data", "Your data"]].map(([k, l]) => '<button type="button" data-set-jump="' + k + '">' + l + "</button>").join("") + "</nav>" +
      section("game", "🎮 Game data", "New Dokkan characters come out all the time. Get them here with one tap — your own units are always kept.",
        '<div id="set-game-box" class="set-game"></div>', false) +
      section("look", "Look & comfort", "Choose what is easiest on your eyes.",
        "<h4>Style</h4><div class=\"set-choices set-row\">" + radio("set-theme", "dokkan", s.theme, "Dokkan", "Colourful, game-like") + radio("set-theme", "calm", s.theme, "Calm dark", "Plain and quiet") + "</div>" +
        "<h4>Text size</h4><div class=\"set-choices set-row\">" + [[90, "Small"], [100, "Normal"], [115, "Large"], [130, "Extra large"]].map(([v, l]) => radio("set-text", v, s.text, l)).join("") + '</div><p class="set-sample">Sample: Ki +3 and HP, ATK &amp; DEF +170%</p>' +
        toggle("set-contrast", s.contrast, "High contrast", "Brighter text and clearer borders.") +
        toggle("set-motion", s.motion === "reduce", "Reduce motion", "Turns off moving effects and animations in menus.")) +
      section("help", "Help level", "Beginner keeps screens simple; you can always open extra options when you need them.",
        '<div class="set-choices">' + radio("set-exp", "beginner", s.experience, "Beginner (recommended)", "Simple screens, step-by-step guidance and tips.") + radio("set-exp", "advanced", s.experience, "Advanced", "Every tool and setting is shown.") + "</div>" +
        toggle("set-tips", s.tips, "Show tips", "Short hints at the top of each builder step.") +
        '<div class="row"><button type="button" class="button ghost small" data-set-go="tour">👋 Take the welcome tour</button></div>') +
      section("anim", "Animations", "",
        "<h4>How the player opens</h4><div class=\"set-choices\">" + radio("set-player", "full", player, "Full screen (recommended)", "The animation fills the screen. Tap Close when you're done.") + radio("set-player", "half", player, "Half screen", "The player sits at the top and your editor stays visible below it.") + radio("set-player", "window", player, "Separate screen (old player)", "Only if the other two don't work on your phone.") + "</div>" +
        "<h4>Preview quality</h4><div class=\"set-choices\">" + radio("set-quality", "auto", quality, "Automatic (recommended)", "Exact game colors full screen, a lighter picture in the small editing panel, and smooth mode by itself if your phone starts to lag.") + radio("set-quality", "smooth", quality, "Smoothest", "Always smooth. Colors and glows may look slightly simpler.") + radio("set-quality", "best", quality, "Best colors", "Always exact game colors at your screen's full sharpness. Can lag, even on new phones.") + "</div>" +
        toggle("set-offline", Boolean(cache.offline), "Offline preview", "Only use files already downloaded to this phone.") + (window.ForgeOffline ? '<div class="row">' + ForgeOffline.button("Offline downloads (Essentials or Everything)") + '<button type="button" class="button ghost small" data-offline-cleanup>🧹 Clean up old files now</button></div><p class="hint">Removes outdated, half-finished and duplicate downloads — also ones left by earlier versions — and keeps everything still in use.</p>' : "")) +
      section("speed", "Speed", "If the app feels slow on your phone, turn on Lite effects.",
        toggle("set-lite", lite, "Lite effects", "Same layout without heavy glows and animations. Best for older phones. Turns on by itself if your phone struggles.") +
        '<div class="row"><button type="button" class="button ghost small" data-set-go="speed">Screen flickers or stays blank?</button></div>') +
      section("data", "Your data", "Your units save on this phone automatically.",
        '<div class="set-list">' +
        (state.project ? '<button type="button" class="set-link" data-set-versions><strong>Saved versions of ' + esc(Forge.card(state.project).name || "this unit") + "</strong><small>Go back to an earlier copy of the unit you have open.</small></button>" : "") +
        '<button type="button" class="set-link" data-set-go="recover"><strong>Recover unsaved designs</strong><small>Get back work that wasn’t saved.</small></button>' +
        '<button type="button" class="set-link" data-set-go="import"><strong>Import a unit file</strong><small>A unit from this app, Dokkan Eclipse or Sparking.</small></button>' +
        '<button type="button" class="set-link" data-set-go="offline"><strong>⬇ Download game files</strong><small>Artwork, animations and sprites saved on this device, so nothing has to load while you create.</small></button>' +
        '<button type="button" class="set-link" data-set-go="ai"><strong>✦ AI tools</strong><small>Connect an AI to write units and draw card art.</small></button>' +
        '<button type="button" class="set-link set-danger" data-set-wipe><strong>🗑 Delete my data</strong><small>Remove your units, your files, downloads or everything.</small></button></div>', false) +
      '<div class="set-foot"><button type="button" class="button subtle" data-set-reset="all">Restore all defaults</button><p class="hint">Restoring defaults only changes settings. Your units and files stay as they are.</p></div>';
    const q = (sel) => sheet.querySelector(sel);
    q("[data-sheet-close]").onclick = () => sheet.close();
    sheet.querySelectorAll("[data-set-jump]").forEach((b) => b.onclick = () => q("#set-" + b.dataset.setJump).scrollIntoView({ behavior: "smooth", block: "start" }));
    const mark = (name) => sheet.querySelectorAll('input[name="' + name + '"]').forEach((i) => i.closest(".set-choice").classList.toggle("on", i.checked));
    sheet.querySelectorAll('input[name="set-theme"]').forEach((i) => i.onchange = () => { ForgeShell.save({ theme: i.value }); mark("set-theme"); });
    sheet.querySelectorAll('input[name="set-text"]').forEach((i) => i.onchange = () => { ForgeShell.save({ text: Number(i.value) }); ForgeShell.textZoom(Number(i.value)); mark("set-text"); });
    sheet.querySelectorAll('input[name="set-exp"]').forEach((i) => i.onchange = () => { ForgeShell.setExperience(i.value); mark("set-exp"); toast(i.value === "advanced" ? "Advanced: every tool is shown." : "Beginner: simple screens with guidance."); });
    sheet.querySelectorAll('input[name="set-player"]').forEach((i) => i.onchange = () => ForgeDock.separateWindow(i.value === "window").then(() => i.value === "window" ? null : ForgeDock.startFull(i.value === "full")).then(() => { mark("set-player"); toast(i.value === "window" ? "Previews will open on a separate screen." : i.value === "full" ? "Previews will fill the screen." : "Previews will use the top half of the screen."); }).catch((e) => toast(e.message, true)));
    sheet.querySelectorAll('input[name="set-quality"]').forEach((i) => i.onchange = () => ForgeDock.quality(i.value).then(() => { mark("set-quality"); toast(i.value === "smooth" ? "Previews will always be smooth." : i.value === "best" ? "Previews will always use exact game colors." : "Previews will adjust to your phone automatically."); }).catch((e) => toast(e.message, true)));
    q("#set-contrast").onchange = (e) => ForgeShell.save({ contrast: e.target.checked });
    q("#set-motion").onchange = (e) => ForgeShell.save({ motion: e.target.checked ? "reduce" : "normal" });
    q("#set-tips").onchange = (e) => ForgeShell.save({ tips: e.target.checked });
    q("#set-offline").onchange = (e) => Native.call("previewCache", { offline: e.target.checked }).then(() => toast(e.target.checked ? "Previews now use downloaded files only." : "Previews can download missing files again.")).catch((err) => toast(err.message, true));
    q("#set-lite").onchange = (e) => { window.ForgePerf?.setLite(e.target.checked); toast(e.target.checked ? "Lite effects on." : "Full effects on."); };
    sheet.querySelectorAll("[data-set-go]").forEach((b) => b.onclick = () => { sheet.close(); ForgeShell.go(b.dataset.setGo); });
    q("[data-set-wipe]").onclick = () => { sheet.close(); wipe(); };
    q("[data-set-versions]")?.addEventListener("click", () => { sheet.close(); openProjectVersions().catch((e) => toast(e.message, true)); });
    sheet.querySelectorAll("[data-set-reset]").forEach((b) => b.onclick = async () => {
      const part = b.dataset.setReset, D = ForgeShell.DEFAULTS;
      if (part === "look" || part === "all") { ForgeShell.save({ theme: D.theme, text: D.text, contrast: D.contrast, motion: D.motion }); ForgeShell.textZoom(D.text); }
      if (part === "help" || part === "all") { ForgeShell.setExperience(D.experience); ForgeShell.save({ tips: D.tips }); }
      if (part === "anim" || part === "all") { await ForgeDock.separateWindow(false).catch(() => {}); await ForgeDock.startFull(true).catch(() => {}); await ForgeDock.quality("auto").catch(() => {}); await Native.call("previewCache", { offline: false }).catch(() => {}); }
      if (part === "speed" || part === "all") window.ForgePerf?.setLite(false);
      toast(part === "all" ? "All settings are back to their defaults." : "Defaults restored.");
      await open(part === "all" ? null : part);
    });
    if (!sheet.open) sheet.showModal();
    if (window.ForgeImport && ForgeImport.card) ForgeImport.card(q("#set-game-box"), () => open("game")).catch(() => {});
    if (focus) q("#set-" + focus)?.scrollIntoView({ block: "start" });
  }
  // Delete my data: choose what goes, tick "I understand", then one red button.
  function wipe() {
    const opt = (id, title, text, on) => '<label class="set-toggle"><span><strong>' + esc(title) + "</strong><small>" + esc(text) + '</small></span><input type="checkbox" id="' + id + '"' + (on ? " checked" : "") + "></label>";
    dialog("Delete my data", '<div data-no-ai class="ucopy-dialog"></div><p>Choose what to delete from this device. <strong>This can\'t be undone.</strong> Export a unit first (Save &amp; Play) if you want to keep a copy.</p>' +
      opt("wipe-units", "My units", "Every character you made, with their saved versions.", true) +
      opt("wipe-files", "My files", "Imported artwork, songs, animations and exported game files.", true) +
      opt("wipe-downloads", "Downloaded game files", "Offline artwork and animations (you can download them again).", false) +
      opt("wipe-ai", "AI connections", "Saved AI keys and connections.", false) +
      opt("wipe-settings", "App settings", "Look, text size, help level and other choices go back to normal.", false) +
      '<label class="bld-check wipe-sure"><input type="checkbox" id="wipe-sure"> I understand this deletes the ticked items for good.</label>' +
      '<div class="row"><button type="button" class="button danger" id="wipe-go" disabled>Delete</button><button type="button" class="button ghost" id="wipe-cancel">Cancel</button></div>');
    const $q = (id) => document.getElementById(id), go = $q("wipe-go");
    const sync = () => { go.disabled = !$q("wipe-sure").checked || !["wipe-units", "wipe-files", "wipe-downloads", "wipe-ai", "wipe-settings"].some((id) => $q(id).checked); };
    document.querySelectorAll("#dialog input[type=checkbox]").forEach((c) => c.onchange = sync);
    $q("wipe-cancel").onclick = () => $q("dialog").close();
    go.onclick = async () => {
      const pick = { units: $q("wipe-units").checked, files: $q("wipe-files").checked, downloads: $q("wipe-downloads").checked, ai: $q("wipe-ai").checked };
      const resetSettings = $q("wipe-settings").checked;
      go.disabled = true;
      try {
        if (pick.units || pick.files || pick.downloads || pick.ai) await Native.call("wipeData", Object.assign({ confirm: "DELETE" }, pick));
        // "My animations" (the animation gallery) lives in this browser's own storage
        if (pick.files) { try { await new Promise((res) => { const r = indexedDB.deleteDatabase(window.ForgeAnimationGallery && ForgeAnimationGallery.DB_NAME || "forge-animation-gallery"); r.onsuccess = r.onerror = r.onblocked = () => res(); }); } catch (e) {} }
        if (resetSettings || pick.units) {
          try { for (const k of Object.keys(localStorage)) if (/^forge|^dokkan|^shell/i.test(k) && (resetSettings || /draft|recover|unsaved/i.test(k))) localStorage.removeItem(k); } catch (e) {}
        }
        $q("dialog").close();
        if (pick.units) { state.project = null; state.projects = []; }
        toast("Deleted. The app will reload.");
        setTimeout(() => location.reload(), 900);
      } catch (e) { go.disabled = false; toast(e.message || String(e), true); }
    };
  }
  return { open, wipe };
})();
