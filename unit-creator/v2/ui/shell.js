"use strict";
// App shell: simple navigation (Home, Create, Animate, Library, More), readable page titles,
// Help (?) and Settings (⚙) on every screen, the first-launch welcome tour, and the user's
// look & feel settings. Everything here sits on top of the existing screens and controllers.
window.ForgeShell = (() => {
  const KEY = "forge-settings";
  const DEFAULTS = Object.freeze({ theme: "dokkan", text: 100, motion: "normal", contrast: false, tips: true, experience: "beginner", onboarded: false });
  const TITLES = { home: "Home", source: "Create a unit", editor: "Card builder", animations: "Animations", library: "Library", combat: "Combat practice", movies: "Game movies", assets: "Game data & files", ai: "AI helpers" };
  const read = () => { try { return Object.assign({}, DEFAULTS, JSON.parse(localStorage.getItem(KEY) || "{}")); } catch { return Object.assign({}, DEFAULTS); } };
  let settings = read();
  function save(patch) {
    settings = Object.assign({}, settings, patch);
    try { localStorage.setItem(KEY, JSON.stringify(settings)); } catch {}
    apply();
    return settings;
  }

  // ---------------------------------------------------------------- look & feel
  async function textZoom(percent) {
    try { await Native.call("textZoom", { percent }); } catch {}
  }
  function apply() {
    const root = document.documentElement;
    root.classList.toggle("dbz", settings.theme === "dokkan");
    root.classList.toggle("theme-calm", settings.theme === "calm");
    root.classList.toggle("high-contrast", Boolean(settings.contrast));
    root.classList.toggle("reduce-motion", settings.motion === "reduce");
    root.classList.toggle("no-tips", !settings.tips);
    root.dataset.experience = settings.experience;
  }
  function setExperience(level) {
    save({ experience: level === "advanced" ? "advanced" : "beginner" });
    const wantSimple = settings.experience === "beginner";
    try { localStorage.setItem("forge-layout", wantSimple ? "simple" : "full"); } catch {}
    if (state.simple !== wantSimple) document.getElementById("simple-layout-toggle")?.click();
  }

  // ---------------------------------------------------------------- navigation
  const ICON = { home: "⌂", source: "＋", animations: "▶", library: "▤", more: "☰" };
  const LABEL = { home: "Home", source: "Create", animations: "Animate", library: "Library" };
  function more() {
    let sheet = document.getElementById("shell-more");
    if (!sheet) {
      sheet = document.createElement("dialog");
      sheet.id = "shell-more";
      sheet.className = "shell-sheet more-sheet";
      sheet.setAttribute("aria-labelledby", "shell-more-title");
      document.body.append(sheet);
    }
    const item = (go, icon, title, text) => '<button type="button" class="more-item" data-shell-go="' + go + '"><span class="more-icon" aria-hidden="true">' + icon + "</span><span><strong>" + esc(title) + "</strong><small>" + esc(text) + "</small></span></button>";
    sheet.innerHTML = '<div class="sheet-head"><h2 id="shell-more-title">More</h2><button type="button" class="icon-button" data-sheet-close aria-label="Close">×</button></div>' +
      '<h3 class="more-group">Make</h3><div class="more-grid">' +
      item("templates", "★", "Templates & presets", "Ready-made units, abilities and Super Attacks") +
      item("ai", "✦", "AI helpers", "Describe a unit in your words; make card art") +
      item("movies", "🎬", "Game movies", "Watch and pick movie scenes") +
      item("combat", "⚔", "Combat practice", "Try your unit in a practice battle") + "</div>" +
      '<h3 class="more-group">Files</h3><div class="more-grid">' +
      item("import", "⬆", "Update & import", "Get the newest characters · import a unit file") +
      item("offline", "⬇", "Download game files", "Artwork, animations, sprites & sounds on this device") +
      "</div>" +
      '<h3 class="more-group">App</h3><div class="more-grid">' +
      item("settings", "⚙", "Settings", "Look, text size, help level, speed") +
      item("help", "?", "Help", "Guides, words explained and fixes") + "</div>";
    sheet.querySelector("[data-sheet-close]").onclick = () => sheet.close();
    sheet.querySelectorAll("[data-shell-go]").forEach((b) => b.onclick = () => { sheet.close(); go(b.dataset.shellGo); });
    if (!sheet.open) sheet.showModal();
  }
  async function go(target) {
    try {
      if (["home", "source", "animations", "library", "combat", "movies", "assets", "ai"].includes(target)) return await navigate(target);
      if (target === "quick") return window.ForgeQuickCreate ? ForgeQuickCreate.open() : await navigate("source");
      if (target === "templates") return window.ForgePresets ? ForgePresets.open() : await navigate("source");
      if (target === "settings") return ForgeSettings.open();
      if (target === "help") return ForgeHelp.open();
      if (target === "tour") return tour();
      if (target === "offline") return ForgeOffline.open();
      if (target === "recover") return ForgeSaveRecovery.browse();
      if (target === "import") return window.ForgeImport ? ForgeImport.open() : importFile();
      if (target === "speed") return ForgePerf.open();
    } catch (error) {
      toast(error.message || String(error), true);
    }
  }
  function buildNav() {
    const mobile = document.querySelector(".mobile-nav");
    if (mobile && !mobile.dataset.shell) {
      mobile.dataset.shell = "1";
      mobile.querySelectorAll("[data-nav]").forEach((b) => {
        const key = b.dataset.nav;
        if (LABEL[key]) b.innerHTML = '<span class="nav-glyph" aria-hidden="true">' + ICON[key] + "</span><span>" + LABEL[key] + "</span>";
        else b.classList.add("shell-hidden");
      });
      const order = ["home", "source", "animations", "library"];
      order.forEach((k) => { const b = mobile.querySelector('[data-nav="' + k + '"]'); if (b) mobile.append(b); });
      const m = document.createElement("button");
      m.type = "button";
      m.className = "shell-more-button";
      m.innerHTML = '<span class="nav-glyph" aria-hidden="true">' + ICON.more + "</span><span>More</span>";
      m.setAttribute("aria-label", "More: templates, AI, movies, files, settings and help");
      m.onclick = more;
      mobile.append(m);
    }
    const side = document.querySelector(".sidebar nav");
    if (side && !side.dataset.shell) {
      side.dataset.shell = "1";
      const homeBtn = side.querySelector('[data-nav="home"]');
      if (homeBtn) homeBtn.innerHTML = '<span class="nav-icon">⌂</span> Home';
      const extra = document.createElement("div");
      extra.className = "shell-side-extra";
      for (const [goTo, icon, label] of [["templates", "★", "Templates & presets"], ["offline", "⬇", "Offline downloads"], ["settings", "⚙", "Settings"], ["help", "?", "Help"]]) {
        const b = document.createElement("button");
        b.type = "button";
        b.dataset.sideGo = goTo;
        b.innerHTML = '<span class="nav-icon">' + icon + "</span> " + esc(label);
        b.onclick = () => go(goTo);
        extra.append(b);
      }
      side.after(extra);
    }
    const actions = document.querySelector(".top-actions");
    if (actions && !document.getElementById("shell-help")) {
      for (const [id, icon, label, fn] of [["shell-help", "?", "Help for this screen", () => ForgeHelp.open()], ["shell-settings", "⚙", "Settings", () => ForgeSettings.open()]]) {
        const b = document.createElement("button");
        b.type = "button";
        b.id = id;
        b.className = "shell-icon";
        b.textContent = icon;
        b.setAttribute("aria-label", label);
        b.title = label;
        b.onclick = fn;
        actions.append(b);
      }
    }
    title();
  }
  function title() {
    const t = TITLES[state.view] || "Home", brand = document.querySelector(".mobile-brand");
    if (brand) brand.textContent = state.view === "editor" && state.project ? Forge.card(state.project).name || t : t;
    const crumb = document.getElementById("breadcrumb");
    if (crumb) crumb.textContent = t + (state.view === "editor" && state.project ? " · " + (Forge.card(state.project).name || "") : "");
    document.querySelectorAll(".mobile-nav .shell-more-button").forEach((b) => b.classList.toggle("active", !["home", "source", "editor", "animations", "library"].includes(state.view)));
  }

  // ---------------------------------------------------------------- welcome tour
  function tour() {
    let d = document.getElementById("shell-tour");
    if (!d) {
      d = document.createElement("dialog");
      d.id = "shell-tour";
      d.className = "shell-sheet tour-sheet";
      d.setAttribute("aria-labelledby", "tour-title");
      document.body.append(d);
      d.addEventListener("close", () => save({ onboarded: true }));
    }
    let step = 0;
    const steps = [
      () => '<p class="eyebrow">WELCOME</p><h2 id="tour-title">Make your own Dokkan units</h2><p>Create brand-new cards for Dokkan Eclipse and Dokkan Sparking — no codes, no IDs, no scripting. Everything saves on this phone as you go.</p><ol class="tour-points"><li><span>＋</span><div><strong>Create</strong><br>Start from a character you like or a ready-made template.</div></li><li><span>✦</span><div><strong>Customize</strong><br>Stats, skills, Super Attacks, animations and art — with examples and presets.</div></li><li><span>▶</span><div><strong>Play</strong><br>Save one game file and import it into Dokkan Eclipse.</div></li></ol>',
      () => '<p class="eyebrow">STEP 2 OF 4</p><h2 id="tour-title">How much help would you like?</h2><div class="tour-choices">' +
        choice("experience", "beginner", "I’m new to this (recommended)", "Simple screens, step-by-step guidance and tips. Extra options stay tucked away until you want them.") +
        choice("experience", "advanced", "I’ve made units before", "Show every tool and setting straight away.") + '</div><p class="hint">You can change this any time in Settings.</p>',
      () => '<p class="eyebrow">STEP 3 OF 4</p><h2 id="tour-title">Make it comfortable</h2><h3>Text size</h3><div class="tour-choices tour-row">' + [[100, "Normal"], [115, "Large"], [130, "Extra large"]].map(([v, l]) => choice("text", v, l, "")).join("") + '</div><p class="tour-sample">Sample: Ki +3 and HP, ATK &amp; DEF +170%</p><h3>Look</h3><div class="tour-choices tour-row">' + choice("theme", "dokkan", "Dokkan (colourful)", "") + choice("theme", "calm", "Calm dark", "") + "</div>",
      () => '<p class="eyebrow">STEP 4 OF 4</p><h2 id="tour-title">You’re ready!</h2><p>Make your first unit in about a minute with <strong>⚡ Create a unit</strong> on Home, or look around first. The <strong>?</strong> button at the top explains any screen, and <strong>↶ Undo</strong> takes back a change.</p><div class="tour-finish"><button type="button" class="button" data-tour-go="quick">⚡ Make my first unit</button><button type="button" class="button ghost" data-tour-go="templates">★ Browse templates</button><button type="button" class="button subtle" data-tour-go="home">Look around</button></div>'
    ];
    function choice(name, value, label, text) {
      const on = String(settings[name]) === String(value);
      return '<label class="tour-choice' + (on ? " on" : "") + '"><input type="radio" name="tour-' + name + '" value="' + value + '"' + (on ? " checked" : "") + "><span><strong>" + esc(label) + "</strong>" + (text ? "<small>" + esc(text) + "</small>" : "") + "</span></label>";
    }
    function draw() {
      d.innerHTML = '<div class="tour-dots" aria-hidden="true">' + steps.map((_, i) => '<span class="' + (i === step ? "on" : i < step ? "done" : "") + '"></span>').join("") + '</div><div class="tour-body">' + steps[step]() + '</div><div class="row tour-nav">' + (step ? '<button type="button" class="button ghost" data-tour="back">← Back</button>' : '<button type="button" class="button subtle" data-tour="skip">Skip</button>') + (step < steps.length - 1 ? '<button type="button" class="button" data-tour="next">Next →</button>' : "") + "</div>";
      d.querySelectorAll('input[name="tour-experience"]').forEach((i) => i.onchange = () => { setExperience(i.value); draw(); });
      d.querySelectorAll('input[name="tour-text"]').forEach((i) => i.onchange = () => { save({ text: Number(i.value) }); textZoom(Number(i.value)); draw(); });
      d.querySelectorAll('input[name="tour-theme"]').forEach((i) => i.onchange = () => { save({ theme: i.value }); draw(); });
      d.querySelector('[data-tour="next"]')?.addEventListener("click", () => { step++; draw(); });
      d.querySelector('[data-tour="back"]')?.addEventListener("click", () => { step--; draw(); });
      d.querySelector('[data-tour="skip"]')?.addEventListener("click", () => d.close());
      d.querySelectorAll("[data-tour-go]").forEach((b) => b.onclick = () => { d.close(); go(b.dataset.tourGo); });
      d.querySelector(".tour-body")?.focus?.();
    }
    draw();
    if (!d.open) d.showModal();
  }

  // ---------------------------------------------------------------- beginner start card on Home
  function homeGuide() {
    const actions = document.querySelector(".db-actions");
    // The Home screen now shows its own 3 steps in the banner.
    if (!actions || state.view !== "home" || document.getElementById("shell-start") || document.querySelector(".db-hero-steps") || (state.projects || []).length > 2) return;
    const box = document.createElement("section");
    box.id = "shell-start";
    box.className = "shell-start";
    box.innerHTML = '<h2>New here? Start in 3 steps</h2><ol><li><strong>Create</strong> — tap <em>Quick Create</em>, pick a character and a fighting style.</li><li><strong>Customize</strong> — change anything; presets and examples help, and ↶ Undo is always there.</li><li><strong>Play</strong> — on the last step, tap Import to Eclipse or Import to Sparking.</li></ol><div class="row"><button type="button" class="button small" data-start-go="quick">⚡ Quick Create</button><button type="button" class="button ghost small" data-start-go="help">? How it works</button></div>';
    box.querySelectorAll("[data-start-go]").forEach((b) => b.onclick = () => go(b.dataset.startGo));
    actions.before(box);
  }
  new MutationObserver(() => { if (state.view === "home") requestAnimationFrame(homeGuide); }).observe(document.getElementById("main") || document.body, { childList: true });

  // ---------------------------------------------------------------- start-up
  function start() {
    apply();
    buildNav();
    const previous = updateNav;
    updateNav = function () { const r = previous.apply(this, arguments); buildNav(); title(); return r; };
    document.addEventListener("click", (e) => {
      const close = e.target.closest(".shell-sheet [data-sheet-close]");
      if (close) close.closest("dialog").close();
    });
    let tries = 0;
    const ready = setInterval(() => {
      if (window.__forgeWorkspaceStartup !== "ready" && ++tries < 200) return;
      clearInterval(ready);
      buildNav();
      if (settings.text !== 100) textZoom(settings.text);
      // The tour opens once, on the first launch (not during automated checks).
      // first the download question (apps only, once), then the tour
      // new game data? (every app open) → the download question (first launch) → the tour
      const data = window.ForgeOffline && ForgeOffline.newDataPrompt ? ForgeOffline.newDataPrompt().catch(() => {}) : Promise.resolve();
      const first = data.then(() => window.ForgeOffline && ForgeOffline.firstRun ? ForgeOffline.firstRun().catch(() => {}) : null);
      first.then(() => { if (!settings.onboarded && !navigator.webdriver) tour(); });
    }, 150);
  }
  start();
  return { settings: () => Object.assign({}, settings), save, apply, DEFAULTS, setExperience, textZoom, go, more, tour, title };
})();
