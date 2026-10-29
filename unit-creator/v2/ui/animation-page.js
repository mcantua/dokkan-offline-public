(() => {
  "use strict";
  var _a;
  const local = location.protocol === "http:" && location.hostname === "127.0.0.1" && ((_a = window.__forgeAnimation) == null ? void 0 : _a.localPreview) === true;
  if (!(local || (location.protocol === "https:" || location.protocol === "forge-preview:") && location.hostname === "dokkan-eclipse.com") || !/^\/tools\/(lua|lwf)-player\//.test(location.pathname)) return;
  const request = window.__forgeAnimation;
  if (!request || document.getElementById("forge-animation-bar")) return;
  // Preview quality (Settings > Animations): "auto" watches how fast this phone draws and turns on
  // fast colors when it falls behind (remembered for later previews), "smooth" always uses fast
  // colors at a lighter resolution, "best" always draws exact game colors.
  (() => {
    const quality = ["auto", "smooth", "best"].includes(request.quality) ? request.quality : "auto";
    const epoch = String(request.qualityEpoch || 0);
    let remembered = false;
    try { remembered = localStorage.getItem("forge-fast-colors") === epoch; } catch {}
    window.__forgeAutoQuality = quality === "auto";
    // Automatic: the small editing panel always uses fast colors (the exact-color pass costs a lot
    // and can't be judged at that size); full screen uses exact colors unless this phone was slow.
    // Phone tier (Chrome reports memory as 2, 4 or 8 GB): 4 GB or less draws the small panel at 1×;
    // 2 GB or less, or 4 processor cores or less, also uses fast colors full screen in Automatic.
    // Everything else is decided by how this phone actually performs (see the runner's speed watch).
    const memory = Number(navigator.deviceMemory) || 0, cores = Number(navigator.hardwareConcurrency) || 0;
    const lowEnd = memory > 0 && memory <= 4, veryLow = (memory > 0 && memory <= 2) || (cores > 0 && cores <= 4);
    const fastFor = (full) => quality === "smooth" || (quality === "auto" && (remembered || veryLow || (request.dock === true && full === false)));
    window.__forgeFastColor = fastFor(request.full !== false);
    window.__forgeFastFor = fastFor;
    addEventListener("forge-preview-fast", () => { remembered = true; });
    addEventListener("forge-preview-fast", () => { try { localStorage.setItem("forge-fast-colors", epoch); } catch {} });
    // Drawing resolution. Phones like the Pixel 10 have very sharp screens (about 3 pixels per
    // point), so the player drew up to 9 times more pixels than it needed and lagged. Unless
    // "Best colors" is chosen, it now draws at most 1.25× in the small panel (where extra
    // sharpness can't be seen), 2× full screen, and 1.5× with fast colors.
    const nativeRatio = window.devicePixelRatio || 1;
    window.__forgeDockFull = request.full !== false;
    const ratio = () => {
      if (quality === "best") return nativeRatio;
      const cap = request.dock && !window.__forgeDockFull ? (lowEnd ? 1 : 1.25) : window.__forgeFastColor ? 1.5 : 2;
      return Math.min(nativeRatio, cap);
    };
    if (nativeRatio > 1 && quality !== "best") {
      try { Object.defineProperty(window, "devicePixelRatio", { configurable: true, get: ratio }); } catch {}
    }
  })();
  const conditionNames = { _IS_PLAYER_SIDE_: "Your team is attacking", _IS_DODGE_: "Dodge or counter situation", _IS_DEAD_: "Opponent is defeated", _IS_DEAD_LAST_: "Final opponent is defeated", _IS_CRITICAL_: "Critical hit", _IS_GUARD_: "Guarding", _IS_EXTRA_ATTACK_: "Additional attack", _IS_KI_100_: "Full Ki", _IS_DOKKAN_MODE_: "Dokkan attack", _IS_SPECIAL_ATTACK_: "Super Attack", _IS_SPECIAL_AIM_ALL_: "Attack all enemies", _IS_FINISH_SPECIAL_ONLY_: "Finishing Super Attack", _IS_ATK_FLASH_MOVE_END_: "Attacker finishes moving", _IS_DFC_FLASH_MOVE_END_: "Defender finishes moving", _IS_SKIP_: "Skip this animation", _IS_ZAWAKEN_: "Awakened version", _IS_COSTUME_CHANGE_: "Changed outfit", _SPECIAL_SKILL_LEVEL_: "Awakening appearance" };
  const friendlyConditions = () => {
    const list2 = document.getElementById("conditionList");
    if (!list2) return;
    const simple = document.body.classList.contains("forge-simple") || document.body.classList.contains("forge-pack-simple");
    list2.querySelectorAll("label").forEach((row) => {
      const input = row.querySelector("[data-key]"), label = row.lastElementChild;
      if (!input || !label) return;
      const key = input.dataset.key;
      if (!label.dataset.forgeOriginal) label.dataset.forgeOriginal = label.textContent;
      if (conditionNames[key]) label.textContent = simple ? conditionNames[key] : label.dataset.forgeOriginal;
      row.querySelectorAll("option").forEach((option) => {
        if (!option.dataset.forgeOriginal) option.dataset.forgeOriginal = option.textContent;
        if (key === "_SPECIAL_SKILL_LEVEL_") option.textContent = simple ? { "0": "Original / EX", "1": "Extreme Z-Awakened / EX", "2": "Super Extreme Z-Awakened / EX" }[option.value] || option.dataset.forgeOriginal : option.dataset.forgeOriginal;
      });
    });
  };
  const list = document.getElementById("conditionList");
  if (list) {
    const hint = document.createElement("p");
    hint.className = "hint forge-friendly";
    hint.textContent = "Choose a situation to preview. Faded choices are unused by this animation.";
    list.before(hint);
    new MutationObserver(friendlyConditions).observe(list, { childList: true });
  }
  const clean = document.createElement("style");
  clean.textContent = ".nav-container{display:none!important}body.forge-simple #conditionList .name,body.forge-pack-simple #conditionList .name,body.forge-simple #conditionHint,body.forge-pack-simple #conditionHint,body.forge-simple .log-wrap,body.forge-pack-simple .log-wrap{display:none!important}body:not(.forge-simple):not(.forge-pack-simple) .forge-friendly{display:none!important}";
  document.head.append(clean);
  const mountPreviewLimits = (bar2) => {
    const box = document.createElement("section");
    box.id = "forge-preview-limits";
    box.hidden = true;
    box.setAttribute("aria-label", "Preview limits");
    box.style.cssText = "margin-top:12px;padding:10px 12px;background:#293b47;color:#fff;border-left:3px solid #ffcc83;border-radius:4px;overflow-wrap:anywhere";
    const status = document.createElement("p");
    status.setAttribute("role", "status");
    status.setAttribute("aria-live", "polite");
    status.setAttribute("aria-atomic", "true");
    status.style.cssText = "margin:0";
    const details = document.createElement("details"), summary = document.createElement("summary"), items = document.createElement("ul");
    summary.textContent = "All preview limits";
    details.append(summary, items);
    box.append(status, details);
    bar2.append(box);
    const rules = [
      [/\bmedia=missing\b|No visual resource in metadata/i, "Some animation artwork is unavailable. The preview may be incomplete."],
      [/missing its game color metadata/, "Some effect colors or transparency cannot be verified in this preview."],
      [/follows a battle character that is unavailable/, "An effect follows a character that is unavailable in this preview."],
      [/battle attachment point|captures an attachment when it starts/, "Some effects attach to moving body parts. Their exact placement still needs game testing."],
      [/additional battle phases still need verification|has not reconstructed transitions between multiple battle phases/, "Some changes between animation sections have not been verified. Check the result in Eclipse."],
      [/no single verified native ending/, "This scene has an estimated preview length. Its ending still needs game testing."],
      [/has not reconstructed the original game timing for character afterimages/, "Afterimage timing in this preview has not been verified against the game."],
      [/blend-color operation is not supported/, "Some blend-color effects are not supported in this preview."],
      [/uses grouped transparency in this preview/, "Overlapping artwork may have different transparency in this preview."],
      [/bitmap transparency could not be inspected/, "Some artwork transparency could not be verified within this preview’s memory limit."],
      [/artwork colors need an unverified texture or battle transparency context/, "Some artwork colors need more game context. Their appearance is approximate in this preview."],
      [/could not load its original pixels within the preview limit/, "Some artwork could not be decoded within this preview’s limits. Transparent colors and blur may differ from the game."],
      [/preview resized or rotated artwork to fit its atlas/, "Some artwork was resized or rotated for this player. Its shape and transparent colors still need game verification."],
      [/Background artwork uses an unverified game color and opacity context/, "Background colors and overlapping transparency still need verification against the game."],
      [/Full artwork color context is unavailable/, "This player could not verify the artwork’s full colors. Some colors may differ from the game."],
      [/word artwork.*grouped transparency|comic.*grouped transparency/i, "Overlapping word artwork uses approximate grouped transparency in this preview."],
      [/Character aura transparency still uses grouped rendering/, "Character aura transparency is approximate where its artwork overlaps."],
      [/animation character is unavailable for this transparency preview/, "A character needed for this transparency preview is unavailable."],
      [/uses a game sound filter that is not reproduced yet/, "This move’s sound filter is not reproduced in the preview. Its game export keeps the original filter."],
      [/patterned atlas draw remains unsupported/, "Some patterned artwork is not reproduced by this preview."],
      [/color\/blur surface unavailable/, "Some color or blur effects could not be drawn in this preview."],
      [/cannot retain some bright transparent colors/, "Some bright transparent colors are approximate in this browser."],
      [/Afterimage preview:/, "Some afterimages could not be reproduced completely in this preview."],
      [/unsupported pre-existing scale/, "Some camera movement cannot be reproduced with this preview’s existing scale."]
    ];
    let signature = "", queued = false, disposed = false;
    const refresh = () => {
      queued = false;
      if (disposed) return;
      const log = document.getElementById("log");
      let text = ((log == null ? void 0 : log.textContent) || "").slice(-2 * 1024 * 1024);
      const bound = text.lastIndexOf("bound · endFrame=");
      if (bound >= 0) text = text.slice(bound);
      const messages = [];
      const add = (value) => {
        if (!messages.includes(value)) messages.push(value);
      };
      if (document.querySelector("[data-forge-position-notice],[data-forge-camera-notice]")) add("Choose starting positions below to preview this continuation from battle.");
      if (document.querySelector("[data-forge-scene-ui-notice]")) add("Some messages or battle interface details need the game’s battle context.");
      for (const [pattern, message] of rules) if (pattern.test(text)) add(message);
      if (document.querySelector("[data-forge-bgm-status]")) add("This move’s music is not ready. The animation can still play.");
      const next = messages.join("\n");
      if (next === signature) return;
      signature = next;
      box.hidden = !messages.length;
      status.textContent = messages.length ? messages[0] + (messages.length > 1 ? " " + (messages.length - 1) + " other preview " + (messages.length === 2 ? "limit." : "limits.") : "") : "";
      details.hidden = messages.length < 2;
      items.textContent = "";
      for (const message of messages) {
        const item = document.createElement("li");
        item.textContent = message;
        items.append(item);
      }
    };
    // The player rewrites its status line while it plays; checking the (large) log on every
    // change cost time on each frame. Check at most a few times a second instead.
    const schedule = () => {
      if (!queued && !disposed) {
        queued = true;
        setTimeout(refresh, 400);
      }
    };
    const observer = new MutationObserver((changes) => {
      if (!queued && changes.some((change) => !box.contains(change.target))) schedule();
    });
    observer.observe(document.body, { childList: true, subtree: true, characterData: true });
    refresh();
    window.addEventListener("pagehide", () => {
      disposed = true;
      observer.disconnect();
    }, { once: true });
  };
  if (request.mode === "pack") {
    const bar2 = document.createElement("section");
    bar2.id = "forge-animation-bar";
    bar2.style.cssText = "position:sticky;top:0;z-index:10000;background:#152329;color:white;padding:18px;font:15px system-ui";
    const title2 = document.createElement("strong");
    title2.textContent = request.name || "Character poses";
    bar2.append(title2);
    const status = document.createElement("p");
    status.textContent = "Choose Load poses, then select a named pose below.";
    bar2.append(status);
    const load = document.createElement("button");
    load.textContent = "Load character poses";
    bar2.append(load);
    document.body.prepend(bar2);
    const style2 = document.createElement("style");
    style2.textContent = "body.forge-pack-simple header,body.forge-pack-simple h1,body.forge-pack-simple #drop,body.forge-pack-simple #assets,body.forge-pack-simple #meta,body.forge-pack-simple #log,body.forge-pack-simple #btnFiles,body.forge-pack-simple #btnFolder,body.forge-pack-simple #btnSplitSheets{display:none!important}";
    document.head.append(style2);
    document.body.classList.add("forge-pack-simple");
    friendlyConditions();
    const tools = document.createElement("button");
    tools.textContent = "Show player tools";
    tools.onclick = () => {
      document.body.classList.toggle("forge-pack-simple");
      friendlyConditions();
      tools.textContent = document.body.classList.contains("forge-pack-simple") ? "Show player tools" : "Hide player tools";
    };
    bar2.append(tools);
    if (request.dock && request.autoplay) setTimeout(() => { if (!load.disabled) load.click(); }, 400);
    mountPreviewLimits(bar2);
    const friendly = () => {
      if (request.scene && !bar2.dataset.sceneSelected) {
        const chosen = [...document.querySelectorAll(".movie-btn")].find((b) => b.dataset.name === request.scene || b.textContent === request.scene || b.textContent.endsWith("_" + request.scene));
        if (chosen) {
          chosen.click();
          bar2.dataset.sceneSelected = "1";
        }
      }
      const duplicates = {};
      document.querySelectorAll(".movie-btn").forEach((b) => {
        if (b.dataset.forgeRenamed) return;
        const raw = (b.dataset.name || b.textContent).toLowerCase(), words = [];
        for (const [token, name2] of [["idl", "Idle"], ["ak", "Attack"], ["atk", "Attack"], ["dam", "Taking damage"], ["ddg", "Dodge"], ["dash", "Dash"], ["run", "Running"], ["jump", "Jump"], ["launch", "Launcher"], ["combo", "Combo"], ["win", "Victory"], ["victory", "Victory"], ["die", "Defeated"], ["def", "Defending"], ["front", "Front"], ["side", "Side"], ["back", "Back"]]) if (new RegExp("(?:^|_)" + token + "(?:_|$)").test(raw)) words.push(name2);
        const name = words.length ? [...new Set(words)].join(" · ") : request.scene ? "Visual effect" : "Pose";
        duplicates[name] = (duplicates[name] || 0) + 1;
        b.textContent = name + " · variation " + duplicates[name];
        b.dataset.forgeRenamed = "1";
      });
    };
    load.onclick = async () => {
      load.disabled = true;
      status.textContent = "Loading this character’s visual pack…";
      try {
        const p = request.resourcePath;
        if (!/^[a-z0-9_./-]+\.lwf$/i.test(p) || p.split("/").some((x) => !x || x === "." || x === "..")) throw new Error("Invalid visual reference");
        const folder = p.slice(0, p.lastIndexOf("/")), listing = await fetch("/api/file-browser?path=" + encodeURIComponent(folder)).then(async (r) => {
          const data = await r.json();
          if (!r.ok || data.error) throw new Error(data.error || "This visual pack could not be listed");
          return data;
        }), entries = (listing.items || []).filter((x) => x.type === "file" && (x.path === p || /\.png$/i.test(x.path)));
        if (entries.length > 200) throw new Error("This pack has too many textures");
        const dt = new DataTransfer();
        let total = 0;
        for (const item of entries) {
          const r = await fetch("/assets/" + item.path.split("/").map(encodeURIComponent).join("/"));
          if (!r.ok) throw new Error("A matching game resource is unavailable");
          const bytes = await r.arrayBuffer();
          total += bytes.byteLength;
          if (total > 128 * 1024 * 1024) throw new Error("This pack exceeds the preview memory limit");
          dt.items.add(new File([bytes], item.name));
        }
        const input = document.getElementById("file");
        input.files = dt.files;
        input.dispatchEvent(new Event("change", { bubbles: true }));
        status.textContent = "Select a pose below. Labels describe recognized poses; other clips appear as variations.";
        let ticks = 0;
        const timer2 = setInterval(() => {
          friendlyConditions();
          friendly();
          if (++ticks > 100) clearInterval(timer2);
        }, 300);
      } catch (e) {
        status.textContent = e.message + ". Return and try another character visual.";
      } finally {
        load.disabled = false;
      }
    };
    return;
  }
  const bar = document.createElement("section");
  bar.id = "forge-animation-bar";
  bar.style.cssText = "position:sticky;top:0;z-index:10000;background:#152329;color:#fff;padding:16px;font:15px/1.5 system-ui;border-bottom:2px solid #82d7c5";
  const title = document.createElement("strong");
  title.textContent = request.name || "Animation preview";
  bar.append(title);
  const detail = document.createElement("p");
  detail.textContent = "Loading the saved animation player…";
  bar.append(detail);
  let movieStatus = null;
  window.addEventListener("forge-media-progress", (event) => {
    var _a2;
    movieStatus = ((_a2 = event.detail) == null ? void 0 : _a2.active) ? String(event.detail.message || "Preparing movie on your device…") : null;
    if (movieStatus) detail.textContent = movieStatus;
  });
  const start = document.createElement("button");
  start.id = "forge-animation-start";
  start.textContent = "Load and play animation";
  start.style.cssText = "padding:12px 18px;background:#ffb15d;border:0;border-radius:8px;color:#20150c";
  start.disabled = true;
  bar.append(start);
  const tech = document.createElement("button");
  tech.textContent = "Show player tools";
  tech.style.cssText = "margin-left:12px;padding:10px;background:#26364a;color:white;border:0;border-radius:8px";
  bar.append(tech);
  const movieSound = document.createElement("button");
  movieSound.id = "forge-movie-sound";
  movieSound.type = "button";
  movieSound.textContent = "Movie sound: On";
  movieSound.setAttribute("aria-pressed", "true");
  movieSound.disabled = true;
  movieSound.title = "Sound embedded in game movies, during preview and recording. Sound effects use the player’s other sound controls.";
  movieSound.style.cssText = "margin-left:12px;padding:10px;background:#26364a;color:white;border:0;border-radius:8px";
  bar.append(movieSound);
  let movieSoundSettings = null;
  const showMovieSoundState = (enabled) => {
    movieSound.textContent = "Movie sound: " + (enabled ? "On" : "Off");
    movieSound.setAttribute("aria-pressed", String(enabled));
  };
  import(new URL("/_forge/media/preview-movie-audio.js", location.href).href).then((module) => {
    movieSoundSettings = module;
    showMovieSoundState(module.getMovieSoundEnabled());
    movieSound.disabled = false;
  }).catch(() => {
    movieSound.textContent = "Movie sound unavailable";
    movieSound.title = "Reopen this preview to load the movie sound controls.";
  });
  const applyMovieSound = (root) => {
    var _a2, _b;
    if (!root || root.nodeType !== 1) return;
    const videos = [];
    if ((_a2 = root.matches) == null ? void 0 : _a2.call(root, "video.movie-decode,video[data-forge-movie]")) videos.push(root);
    (_b = root.querySelectorAll) == null ? void 0 : _b.call(root, "video.movie-decode,video[data-forge-movie]").forEach((video) => videos.push(video));
    videos.forEach((video) => {
      video.muted = true;
      video.defaultMuted = true;
    });
  };
  movieSound.onclick = () => {
    if (!movieSoundSettings) return;
    showMovieSoundState(movieSoundSettings.setMovieSoundEnabled(!movieSoundSettings.getMovieSoundEnabled()));
    applyMovieSound(document.body);
  };
  applyMovieSound(document.body);
  const movieSoundObserver = new MutationObserver((changes) => changes.forEach((change) => change.addedNodes.forEach(applyMovieSound)));
  movieSoundObserver.observe(document.body, { childList: true, subtree: true });
  window.addEventListener("pagehide", () => movieSoundObserver.disconnect(), { once: true });
  document.body.prepend(bar);
  mountPreviewLimits(bar);
  import(new URL("/_forge/media/preview-record-controls.js", location.href).href).then((module) => module.mountRecordControl(bar)).catch(() => {
  });
  const style = document.createElement("style");
  style.textContent = "body.forge-simple h1,body.forge-simple header,body.forge-simple .site-header,body.forge-simple footer,body.forge-simple #btnRefMode,body.forge-simple #refPanel,body.forge-simple #btnSplitSheets,body.forge-simple #btnExport,body.forge-simple #btnRecord,body.forge-simple #btnOpenScript,body.forge-simple #btnLoad,body.forge-simple #scriptListHint,body.forge-simple #scriptFilter,body.forge-simple #scriptPath,body.forge-simple #scriptSelect,body.forge-simple #log{display:none!important}body.forge-simple .forge-technical{display:none!important}";
  document.head.append(style);
  document.body.classList.add("forge-simple");
  friendlyConditions();
  tech.onclick = () => {
    document.body.classList.toggle("forge-simple");
    friendlyConditions();
    tech.textContent = document.body.classList.contains("forge-simple") ? "Show player tools" : "Hide player tools";
  };
  const set = (id, value) => {
    const e = document.getElementById(id);
    if (e) {
      e.value = String(value);
      e.dispatchEvent(new Event("input", { bubbles: true }));
      e.dispatchEvent(new Event("change", { bubbles: true }));
    }
  };
  ["attackerCardId", "enemyCardId", "levelBgId", "dokkanFieldId", "scriptFilter", "scriptPath", "scriptSelect", "exportTransforms", "keepAtlasPadding"].forEach((id) => {
    var _a2, _b;
    return (_b = (_a2 = document.getElementById(id)) == null ? void 0 : _a2.closest("label")) == null ? void 0 : _b.classList.add("forge-technical");
  });
  const timer = setInterval(() => {
    friendlyConditions();
    const e = document.getElementById("scriptSelect");
    if ((e == null ? void 0 : e.options.length) > 1) {
      clearInterval(timer);
      start.disabled = false;
      detail.textContent = "Ready. Your characters and animation are selected automatically. Loaded resources are saved for offline replay.";
    }
  }, 300);
  setTimeout(() => {
    clearInterval(timer);
    if (start.disabled) {
      start.disabled = false;
      detail.textContent = "If the animation list is slow, try Load and play. Unsaved resources need Internet access.";
    }
  }, 3e4);
  let watch, opponentScenes = null, opponentRequested = false;
  import(new URL("/_forge/media/preview-opponent-scenes.js", location.href).href).then(() => {
    opponentScenes = window.ForgeOpponentScenes;
    return opponentScenes == null ? void 0 : opponentScenes.mount({ request, bar, start, onOpponent: () => {
      opponentRequested = true;
      start.click();
    } });
  }).catch(() => {
  });
  start.onclick = async () => {
    var _a2;
    const useOpponent = opponentRequested;
    opponentRequested = false;
    clearInterval(watch);
    set("attackerCardId", request.attackerId || 1000010);
    set("enemyCardId", request.enemyId || 1000020);
    detail.textContent = "Loading animation and matching game resources…";
    let scriptText = request.text;
    if (!scriptText && request.path === "ab_script/ab_sys/dg0001.lua") {
      try {
        const response = await fetch("/cdn/uncompressed/lua/" + request.path);
        if (!response.ok) throw Error("Dodge source unavailable");
        scriptText = await response.text();
        if (scriptText.length > 2 * 1024 * 1024) throw Error("Dodge source exceeds the preview limit");
      } catch (e) {
        detail.textContent = e.message + ". Load this animation online first, then retry.";
        return;
      }
    }
    if (scriptText) {
      try {
        const input = document.getElementById("scriptFile"), dt = new DataTransfer();
        const notification = "onDodgeExecuted = onDodgeExecuted or function(frame) end\n";
        dt.items.add(new File([notification + scriptText], "forge-composition.lua", { type: "text/plain" }));
        input.files = dt.files;
        input.dispatchEvent(new Event("change", { bubbles: true }));
      } catch {
        detail.textContent = "This WebView cannot attach the preview. Update your browser or WebView and retry.";
        return;
      }
    } else {
      set("scriptPath", request.path);
      (_a2 = document.getElementById("btnLoad")) == null ? void 0 : _a2.click();
    }
    let ticks = 0;
    watch = setInterval(() => {
      var _a3;
      const play = document.getElementById("btnPlay"), status = document.getElementById("statusBar");
      if (play && !play.disabled) {
        clearInterval(watch);
        if (useOpponent && !(opponentScenes == null ? void 0 : opponentScenes.applyCondition(document.querySelector('[data-key="_IS_PLAYER_SIDE_"]')))) {
          detail.textContent = "This scene’s side choice is not ready. Load the animation, then try again.";
          return;
        }
        play.click();
        const incomplete = /\b(?:failed|error:|not found|missing resource|unsupported codec)\b/i.test(((_a3 = document.getElementById("log")) == null ? void 0 : _a3.textContent) || "");
        detail.textContent = "Playing " + (request.name || "your animation") + (incomplete ? ". Some resources could not be loaded; open player tools for details." : ". Pause, stop, or replay below.");
      } else if (++ticks > 600) {
        clearInterval(watch);
        detail.textContent = "The preview is taking longer than expected. Retry or open player tools for missing-resource details.";
      } else if (movieStatus) detail.textContent = movieStatus;
      else if (status) detail.textContent = status.textContent;
    }, 500);
  };

  // ---- In-app player (dock), video-player style: the animation fills the screen with nothing on
  // top of it. Tapping shows the controls (close, size, replay, pause, progress), which fade away
  // after 3 seconds while it plays. "Player tools" under ⋯ shows the classic page again.
  if (request.dock) {
    const exporting = /^-- FORGE_SEQUENCE_EXPORT [0-9]{1,5}$/m.test(request.text || "");
    const css = document.createElement("style");
    css.textContent = "body.forge-dock{overflow:hidden!important;background:#000!important}" +
      "body.forge-dock .forge-dock-hide{display:none!important}" +
      "body.forge-dock .forge-dock-wrap{position:fixed!important;inset:0!important;width:auto!important;height:auto!important;max-width:none!important;max-height:none!important;min-height:0!important;margin:0!important;padding:0!important;z-index:2147483000!important;background:#000!important;display:flex!important;flex-direction:column!important;align-items:center!important;justify-content:center!important;border:0!important;box-shadow:none!important;overflow:hidden!important}" +
      "body.forge-dock .forge-dock-path{display:flex!important;flex-direction:column!important;align-items:center!important;justify-content:center!important;width:100%!important;height:100%!important;max-width:none!important;max-height:none!important;min-height:0!important;margin:0!important;padding:0!important;border:0!important;box-shadow:none!important;overflow:hidden!important;position:relative!important}" +
      "body.forge-dock .stage-fit{border:0!important;box-shadow:none!important;margin:0 auto!important}" +
      "#forge-dock-controls,#forge-dock-loading{display:none}" +
      "body.forge-dock #forge-dock-controls{display:block;position:fixed;inset:0;z-index:2147483002;font:600 14px/1.2 system-ui,sans-serif;color:#fff;-webkit-tap-highlight-color:transparent;user-select:none}" +
      "#forge-dock-controls .layer{position:absolute;inset:0;opacity:0;pointer-events:none;transition:opacity .2s;background:linear-gradient(#000a,#0000 22%,#0000 70%,#000b)}" +
      "#forge-dock-controls.show .layer{opacity:1;pointer-events:auto}" +
      "#forge-dock-controls button{border:0;background:#0000;color:#fff;font:inherit;padding:0;display:grid;place-items:center}" +
      "#forge-dock-controls .top{position:absolute;left:0;right:0;top:0;display:flex;justify-content:space-between;padding:10px}" +
      "#forge-dock-controls .top button{width:48px;height:48px;font-size:26px;border-radius:50%}" +
      "#forge-dock-controls .top .right{display:flex;gap:4px}" +
      "#forge-dock-controls .center{position:absolute;left:0;right:0;top:50%;transform:translateY(-50%);display:flex;justify-content:center;align-items:center;gap:36px}" +
      "#forge-dock-controls .center button{width:60px;height:60px;border-radius:50%;background:#0008;font-size:28px}" +
      "#forge-dock-controls .center .play{width:76px;height:76px;font-size:34px}" +
      "#forge-dock-controls.done .center .play{display:none}" +
      "#forge-dock-controls.done .center .again{width:76px;height:76px;font-size:38px}" +
      "#forge-dock-controls .bottom{position:absolute;left:0;right:0;bottom:0;display:flex;align-items:center;gap:12px;padding:14px 16px 18px}" +
      "#forge-dock-controls .track{position:relative;flex:1;height:28px;touch-action:none}" +
      "#forge-dock-controls .track::before{content:'';position:absolute;left:0;right:0;top:12px;height:4px;border-radius:2px;background:#fff5}" +
      "#forge-dock-controls .fill{position:absolute;left:0;top:12px;height:4px;border-radius:2px;background:#ffb15d;width:0}" +
      "#forge-dock-controls .dot{position:absolute;top:6px;width:16px;height:16px;margin-left:-8px;border-radius:50%;background:#ffb15d;left:0}" +
      "#forge-dock-controls .time{font-variant-numeric:tabular-nums;font-size:13px;min-width:86px;text-align:right}" +
      "#forge-dock-controls .menu{position:absolute;right:10px;top:62px;min-width:200px;background:#141c22f2;border-radius:14px;padding:6px;display:none}" +
      "#forge-dock-controls .menu.open{display:block}" +
      "#forge-dock-controls .menu button{width:100%;min-height:46px;justify-content:start;display:flex;align-items:center;padding:0 12px;border-radius:10px;font-size:15px}" +
      "#forge-dock-controls .menu button[aria-pressed=true]::after{content:'✓';margin-left:auto;color:#ffb15d}" +
      "#forge-dock-controls .menu p{margin:6px 12px;font-size:12px;font-weight:400;color:#b9c9d1}" +
      "body.forge-dock #forge-dock-loading:not([hidden]){display:flex;position:fixed;inset:0;z-index:2147483001;flex-direction:column;align-items:center;justify-content:center;gap:12px;pointer-events:none;color:#cfd9df;font:14px system-ui,sans-serif;text-align:center;padding:24px}" +
      "#forge-dock-loading .spin{width:36px;height:36px;border:3px solid #fff3;border-top-color:#ffb15d;border-radius:50%;animation:forge-dock-spin .9s linear infinite}" +
      "#forge-dock-loading.problem .spin{display:none}" +
      "@keyframes forge-dock-spin{to{transform:rotate(360deg)}}" +
      "#forge-dock-tools{display:none;position:sticky;top:0;z-index:10001;width:100%;min-height:52px;padding:10px;border:0;background:#ffb15d;color:#20150c;font:700 16px system-ui}" +
      "body.forge-dock-classic #forge-dock-tools{display:block}";
    document.head.append(css);
    const click = (id) => { const e = document.getElementById(id); if (e && !e.disabled) { e.click(); return true; } return false; };
    const toggle = (id, value) => {
      const e = document.getElementById(id);
      if (!e) return false;
      e.checked = value;
      e.dispatchEvent(new Event("input", { bubbles: true }));
      e.dispatchEvent(new Event("change", { bubbles: true }));
      return e.checked;
    };
    // The app listens to the page title for "close" and "size" (no other way out of this page).
    const tellApp = (command) => { document.title = "forge-dock:" + command + ":" + Date.now(); };
    const runner = () => window.__forgeRunner || null;
    const ui = document.createElement("div");
    ui.id = "forge-dock-controls";
    ui.innerHTML = '<div class="layer" role="toolbar" aria-label="Animation controls">' +
      '<div class="top"><button type="button" class="close" aria-label="Close the player">✕</button><div class="right"><button type="button" class="size" aria-label="Make the player smaller">⤡</button><button type="button" class="more" aria-label="More options" aria-expanded="false">⋯</button></div></div>' +
      '<div class="center"><button type="button" class="again" aria-label="Play again from the start">↺</button><button type="button" class="play" aria-label="Pause">❚❚</button></div>' +
      '<div class="bottom"><div class="track" role="slider" aria-label="Position" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0" tabindex="0"><div class="fill"></div><div class="dot"></div></div><span class="time">0:00 / 0:00</span></div>' +
      '<div class="menu" role="menu"><button type="button" class="speed" aria-pressed="false">2× speed</button><button type="button" class="phone" aria-pressed="false">Phone frame</button><button type="button" class="tools">Player tools</button><p class="quality"></p></div></div>';
    document.body.append(ui);
    const $ui = (sel) => ui.querySelector(sel);
    const layer = $ui(".layer"), playBtn = $ui(".play"), againBtn = $ui(".again"), menu = $ui(".menu"), moreBtn = $ui(".more"), sizeBtn = $ui(".size");
    const fill = $ui(".fill"), dot = $ui(".dot"), time = $ui(".time"), track = $ui(".track"), qualityNote = $ui(".quality");
    const speed = $ui(".speed"), phone = $ui(".phone");
    const loading = document.createElement("div");
    loading.id = "forge-dock-loading";
    loading.setAttribute("role", "status");
    loading.setAttribute("aria-live", "polite");
    loading.innerHTML = '<div class="spin"></div><p class="forge-dock-status"></p>';
    document.body.append(loading);
    const status = loading.querySelector(".forge-dock-status");
    let hideTimer = 0, pausedNow = false, playing = false, done = false, seeking = false;
    const isPaused = () => { const r = runner(); return r ? !!r.userPaused : pausedNow; };
    const showControls = (stay = false) => {
      ui.classList.add("show");
      clearTimeout(hideTimer);
      if (!stay && !done && !isPaused()) hideTimer = setTimeout(hideControls, 3000);
    };
    function hideControls() { if (done || isPaused() || menu.classList.contains("open") || seeking) return; ui.classList.remove("show"); }
    // Taps on empty space show or hide the controls; taps on a button use the button.
    ui.addEventListener("click", (event) => {
      if (event.target.closest("button,.track")) { showControls(); return; }
      if (menu.classList.contains("open")) { menu.classList.remove("open"); moreBtn.setAttribute("aria-expanded", "false"); showControls(); return; }
      if (ui.classList.contains("show") && !done && !isPaused()) { clearTimeout(hideTimer); ui.classList.remove("show"); }
      else showControls();
    });
    const showPaused = (on) => { pausedNow = on; playBtn.textContent = on ? "▶" : "❚❚"; playBtn.setAttribute("aria-label", on ? "Play" : "Pause"); };
    const replay = () => {
      showPaused(false);
      setDone(false);
      if (start.dataset.forgeStarted !== "1") { start.click(); return; }
      click("btnStop");
      setTimeout(() => { click("btnPlay"); showControls(); }, 250);
    };
    againBtn.onclick = replay;
    playBtn.onclick = () => {
      if (isPaused()) { if (click("btnPlay")) showPaused(false); showControls(); }
      else if (click("btnPause")) { showPaused(true); showControls(true); }
      setTimeout(() => report(true), 50);
    };
    $ui(".close").onclick = () => tellApp("close");
    sizeBtn.onclick = () => tellApp("size");
    moreBtn.onclick = () => { const open = !menu.classList.contains("open"); menu.classList.toggle("open", open); moreBtn.setAttribute("aria-expanded", String(open)); showControls(open); };
    const closeMenu = () => { menu.classList.remove("open"); moreBtn.setAttribute("aria-expanded", "false"); };
    menu.addEventListener("click", (event) => { if (event.target.closest("button")) setTimeout(() => { closeMenu(); showControls(); }, 150); });
    speed.onclick = () => speed.setAttribute("aria-pressed", String(toggle("highSpeed", speed.getAttribute("aria-pressed") !== "true")));
    phone.onclick = () => phone.setAttribute("aria-pressed", String(toggle("phoneCrop", phone.getAttribute("aria-pressed") !== "true")));
    $ui(".tools").onclick = () => { menu.classList.remove("open"); setCompact(false); };
    const showQuality = () => { qualityNote.textContent = window.__forgeFastColor ? "Smooth mode is on for this phone." : window.__forgeAutoQuality ? "Quality adjusts to your phone automatically." : ""; };
    showQuality();
    // Progress: position from the player itself; drag or tap the bar to jump.
    const clock = (frames) => { const sec = Math.max(0, Math.round(frames / 60)); return Math.floor(sec / 60) + ":" + String(sec % 60).padStart(2, "0"); };
    const paintProgress = (frame) => {
      const r = runner(), max = Math.max(1, Number(r?.maxFrame) || 0), f = Math.max(0, Math.min(max, Number(frame ?? r?.frame) || 0)), pct = r ? f / max * 100 : 0;
      fill.style.width = pct + "%"; dot.style.left = pct + "%";
      track.setAttribute("aria-valuenow", String(Math.round(pct)));
      time.textContent = clock(f) + " / " + clock(r ? max : 0);
    };
    let frameLoop = 0;
    const loop = () => { frameLoop = 0; if (!ui.classList.contains("show")) return; if (!seeking) paintProgress(); frameLoop = requestAnimationFrame(loop); };
    new MutationObserver(() => { if (ui.classList.contains("show") && !frameLoop) loop(); }).observe(ui, { attributes: true, attributeFilter: ["class"] });
    const frameAt = (event) => { const box = track.getBoundingClientRect(), r = runner(); return Math.round(Math.max(0, Math.min(1, (event.clientX - box.left) / box.width)) * Math.max(0, Number(r?.maxFrame) || 0)); };
    track.addEventListener("pointerdown", (event) => { if (!runner()?.playing) return; seeking = true; track.setPointerCapture?.(event.pointerId); paintProgress(frameAt(event)); showControls(true); });
    track.addEventListener("pointermove", (event) => { if (seeking) paintProgress(frameAt(event)); });
    const endSeek = async (event) => {
      if (!seeking) return;
      seeking = false;
      const r = runner(), target = frameAt(event);
      if (!r?.playing || typeof r.scrubToFrame !== "function") return;
      const resume = !r.userPaused;
      try {
        if (resume) r.pause();
        await r.scrubToFrame(target);
        if (resume) { await r.resume(); showPaused(false); } else showPaused(true);
      } catch {}
      showControls();
      report(true);
    };
    track.addEventListener("pointerup", endSeek);
    track.addEventListener("pointercancel", () => { seeking = false; });
    const back = document.createElement("button");
    back.id = "forge-dock-tools";
    back.type = "button";
    back.textContent = "← Back to the simple player";
    back.onclick = () => setCompact(true);
    bar.before(back);
    function setDone(on) {
      done = on;
      ui.classList.toggle("done", on);
      if (on) { menu.classList.remove("open"); moreBtn.setAttribute("aria-expanded", "false"); paintProgress(Number(runner()?.maxFrame) || 0); showControls(true); }
    }
    const showStatus = () => {
      const text = (detail.textContent || "").replace(/\s*Loaded resources are saved for offline replay\.?/, "");
      if (playing || /^Playing\b/.test(text)) { playing = true; loading.hidden = true; return; }
      const problem = /longer than expected|could not|cannot|unavailable|failed|Retry|not ready/i.test(text);
      loading.classList.toggle("problem", problem);
      status.textContent = problem ? text : "Loading…";
      loading.hidden = false;
    };
    new MutationObserver(showStatus).observe(detail, { childList: true, characterData: true, subtree: true });
    // The editor's timeline: report the position to the app (via the title, a few times a second)
    // and accept seek/play/pause from it. A refreshed preview can open paused at a given moment.
    let pendingSeek = Number.isFinite(Number(request.startAt)) && Number(request.startAt) > 0 ? Number(request.startAt) : null;
    let pendingPause = request.startPaused === true, lastReport = "";
    const report = (force = false) => {
      const r = runner();
      if (!r || exporting || seeking) return;
      const f = Math.max(0, Math.round(Number(r.frame) || 0)), max = Math.max(0, Math.round(Number(r.maxFrame) || 0)), st = done ? "d" : r.userPaused ? "s" : r.playing ? "p" : "s";
      const key = f + ":" + max + ":" + st;
      if (!force && key === lastReport) return;
      lastReport = key;
      tellApp("pos:" + key);
    };
    setInterval(() => { if (playing) report(); }, 250);
    // Seeks are done one at a time; while one runs, only the newest request is kept (a fast series
    // of taps or drags used to start many overlapping seeks, which made the player lag).
    let seekRunning = null, nextSeek = null;
    const seekTo = (frame, play) => {
      if (seekRunning) { nextSeek = [frame, play]; return seekRunning; }
      seekRunning = seekOnce(frame, play).finally(() => { seekRunning = null; if (nextSeek) { const n = nextSeek; nextSeek = null; seekTo(n[0], n[1]); } });
      return seekRunning;
    };
    const seekOnce = async (frame, play) => {
      const r = runner();
      if (!r) return;
      if (!r.playing || done) { pendingSeek = frame; pendingPause = !play; replay(); return; }
      try {
        if (!r.userPaused) r.pause();
        await r.scrubToFrame(frame);
        if (play) { await r.resume(); showPaused(false); } else showPaused(true);
      } catch {}
      paintProgress();
      report(true);
    };
    const firstPlay = async () => {
      if (pendingSeek == null && !pendingPause) return;
      const at = pendingSeek, hold = pendingPause;
      pendingSeek = null; pendingPause = false;
      const r = runner();
      if (!r) return;
      try {
        if (hold || at != null) r.pause();
        if (at != null) await r.scrubToFrame(at);
        if (!hold) { await r.resume(); showPaused(false); } else { showPaused(true); showControls(true); }
      } catch {}
      report(true);
    };
    const command = (c) => {
      if (!c || typeof c !== "object") return;
      const r = runner();
      if (c.type === "seek" && Number.isFinite(Number(c.frame))) return seekTo(Math.max(0, Math.round(Number(c.frame))), c.play === true);
      if (c.type === "play") { if (done || !r?.playing) { replay(); return; } if (r.userPaused && click("btnPlay")) showPaused(false); setTimeout(() => report(true), 50); return; }
      if (c.type === "pause") { if (r?.playing && !r.userPaused && click("btnPause")) showPaused(true); setTimeout(() => report(true), 50); }
    };
    addEventListener("forge-preview-playing", () => { playing = true; setDone(false); showStatus(); firstPlay(); });
    addEventListener("forge-preview-done", () => { if (playing && !exporting) { setDone(true); report(true); } });
    addEventListener("forge-preview-fast", showQuality);
    showStatus();
    // Lay the stage out to fill the panel. stage.js re-fits it to its wrapper by itself.
    let laidOut = false;
    const layoutStage = () => {
      const fit = document.querySelector(".stage-fit");
      if (!fit) return false;
      const wrap = fit.closest("#modeLua") || fit.closest(".stage-wrap") || fit.parentElement;
      if (!wrap || wrap === document.body) return false;
      document.querySelectorAll(".forge-dock-wrap,.forge-dock-path,.forge-dock-hide").forEach((e) => e.classList.remove("forge-dock-wrap", "forge-dock-path", "forge-dock-hide"));
      wrap.classList.add("forge-dock-wrap");
      for (let node = fit; node && node !== wrap; node = node.parentElement) {
        if (node !== fit) node.classList.add("forge-dock-path");
        for (const sibling of node.parentElement ? node.parentElement.children : []) {
          if (sibling !== node && sibling.tagName !== "SCRIPT" && sibling.tagName !== "STYLE") sibling.classList.add("forge-dock-hide");
        }
      }
      laidOut = true;
      window.dispatchEvent(new Event("resize"));
      return true;
    };
    function setCompact(on) {
      tellApp(on ? "bar-off" : "bar-on"); // the app's own Close bar is only needed with the classic tools
      document.body.classList.toggle("forge-dock", on);
      document.body.classList.toggle("forge-dock-classic", !on);
      if (on) layoutStage();
      window.dispatchEvent(new Event("resize"));
      if (!on) window.scrollTo(0, 0);
    }
    const showSize = (full) => { sizeBtn.textContent = full === false ? "⤢" : "⤡"; sizeBtn.setAttribute("aria-label", full === false ? "Show the player on the whole screen" : "Make the player smaller"); };
    window.ForgeDockPage = Object.freeze({ command, layout: (full) => { if (typeof full === "boolean") { showSize(full); window.__forgeDockFull = full; if (window.__forgeFastFor && !window.__forgeExporting) window.__forgeFastColor = window.__forgeFastFor(full); } if (document.body.classList.contains("forge-dock")) layoutStage(); window.dispatchEvent(new Event("resize")); } });
    if (exporting) setCompact(false);
    else {
      setCompact(true);
      let tries = 0;
      const wait = setInterval(() => { if (layoutStage() || ++tries > 50) clearInterval(wait); }, 200);
      // What the phone shows, which also makes the stage larger in the panel.
      setTimeout(() => phone.setAttribute("aria-pressed", String(toggle("phoneCrop", true))), 300);
    }
    // Start by itself as soon as the player is ready (no "Load and play" tap).
    const originalStart = start.onclick;
    start.onclick = (event) => { start.dataset.forgeStarted = "1"; return originalStart.call(start, event); };
    if (request.autoplay) {
      const auto = setInterval(() => {
        if (!start.disabled) { clearInterval(auto); start.click(); }
      }, 150);
      setTimeout(() => { if (start.disabled && request.text) start.disabled = false; }, 8000);
      addEventListener("pagehide", () => clearInterval(auto), { once: true });
    }
    void laidOut;
  }
})();
