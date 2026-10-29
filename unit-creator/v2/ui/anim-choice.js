"use strict";
// ONE simple "Animation" choice for every move that plays an animation (counters, revivals, Super / Ultra / EX
// Super Attacks, Active Skills, Standby & Finish Skills, transformations…). The list says plainly whose animation it
// is ("Goku (Ultra Instinct)"), and always offers:
//   ★ Make my own animation…        → the animation maker, already pointed at this move
//   ★ One of my saved animations…   → My animations, to put one you made on this move
//   🔍 Any attack animation in the game… → every Super, Ultra, EX, Active, Finish and counter animation
// Only one animation is ever used: picking a game one replaces your own and the other way round.
window.ForgeAnimChoice = (() => {
  const esc = (t) => String(t == null ? "" : t).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const proj = () => (typeof state !== "undefined" && state.project) || {};
  const own = (key) => (proj().animationAssignments || {})[key] || null;
  const named = (key) => ((proj().uiLabels || {}).animations || {})[key] || "";
  const opt = (v, n, sel) => '<option value="' + esc(v) + '"' + (sel ? " selected" : "") + ">" + esc(n) + "</option>";
  // the three ways to get another animation, shared by every move
  function moreOptions(key) {
    const mine = own(key);
    return '<optgroup label="Your own">' + opt("own:new", mine ? "★ Edit my animation…" : "★ Make my own animation…") + opt("own:saved", "★ One of my saved animations…") + "</optgroup>" +
      '<optgroup label="Any move">' + opt("any", "🔍 Any attack animation in the game (Super, Ultra, EX, Active, Finish, counters)…") + "</optgroup>";
  }
  // buttons the choice presses for you (bound by the page like every other button)
  const hidden = (key) => ["studio:", "gallery:", "pick-animation:"].map((a) => '<button type="button" hidden data-guide="' + esc(a + key) + '"></button>').join("");
  const watch = (key) => '<button type="button" class="link-button" data-guide="preview-target:' + esc(key) + '">▶ Watch it</button>';
  function currentText(key, fallback) {
    const mine = own(key);
    return mine ? "★ My own animation" + (named(key) ? " — " + named(key) : "") : named(key) || fallback || "The original animation";
  }
  // A move whose animation is NOT a simple game list (Super Attacks, Active Skills…): one select + Watch.
  // extra: [[value, label, data-b action]] for move-specific options (e.g. copying a whole game attack)
  function block(key, o = {}) {
    const extra = o.extra || [];
    extras[key] = extra.map(([v, n]) => [v, n]);
    return '<div class="anim-choice"><div class="field full"><span>' + esc(o.label || "Animation") + '</span>' + pickButton(key, currentText(key, o.original)) +
      '</div><small class="pf-help">' + esc(o.help || "This is the animation that plays for this move. Only one is ever used.") + " " + watch(key) + "</small>" + hidden(key) +
      extra.map(([v, , action]) => '<button type="button" hidden data-b="' + esc(action) + '" data-animextra="' + esc(v) + '"></button>').join("") + "</div>";
  }
  // A move that has its own game list (counter animations, revival scenes): turns that field's select into the
  // single choice. bf = the field's data-bf ("v.anim"), plain = whether that list's names are already plain.
  function enhance(html, bf, key, o = {}) {
    const mine = own(key);
    const re = new RegExp('(<select data-bf="' + bf.replace(".", "\\.") + '")>([\\s\\S]*?)</select>');
    return html.replace(re, (m, head, opts) => {
      // the hidden list keeps the real value (the page saves it); the button says what plays
      const sel = opts.match(/<option([^>]*)\sselected>([^<]*)</);
      const cur = mine ? "★ My own animation" + (named(key) ? " — " + named(key) : "") : sel && !/data-cur/.test(sel[1]) ? sel[2] : named(key) || "Animation from another move";
      return pickButton(key, cur) + head.replace("<select", "<select hidden") + ' data-animchoice="' + esc(key) + '">' + opts + "</select>";
    }).replace(/(data-animchoice="[^"]*">[\s\S]*?<\/select>)(<\/label>)?/, "$1" + '<small class="pf-help">' + esc(o.help || "The animation that plays. Only one is ever used.") + " " + watch(key) + "</small>$2" + hidden(key));
  }
  const extras = {};
  const pickButton = (key, text) => '<button type="button" class="anim-pick-btn" data-animpick="' + esc(key) + '"><span>🎬 ' + esc(text) + '</span><b>Change ▾</b></button>';

  // ---------------------------------------------------------------- the picker: character first, then their moves
  // 1. "Whose animation?" — a search box and every character A–Z (plus your own animations at the top)
  // 2. tap a character — their animations, listed once each under plain headings (Super Attacks, Transformations…)
  const KINDS = [["super", "Super Attacks"], ["ultra", "Ultra Super Attacks"], ["ex", "EX Super Attacks"], ["fullpower", "Full Power"], ["ultimate", "Ultimates"], ["active", "Active Skills"], ["standby", "Standby Skills"], ["finish", "Finish Skills"], ["counter", "Counters"], ["transform", "Transformations"], ["giant", "Giant forms"], ["revival", "Revivals"], ["intro", "Intros"], ["nullify", "Nullify / absorb"]];
  const PART = (key) => /^transformation-begin:/.test(key) ? " (transforming)" : /^transformation-end:/.test(key) ? " (turning back)" : /^giant-begin:/.test(key) ? " (growing giant)" : /^giant-continue:/.test(key) ? " (giant form)" : /^giant-end:/.test(key) ? " (shrinking back)" : "";
  const pk = { key: "", select: null, view: "people", search: "", who: "", items: [], loading: false, seq: 0, shown: 150, extraNames: [] };
  function targetKind(key) {
    try { const t = window.ForgeGuide.targets(proj()).find((x) => x.key === key); if (t) return t.kind; } catch {}
    return { revival: "revival", counter: "counter", intro: "intro", transform: "transform" }[key.split(":")[0]] || "super";
  }
  const fold = (t) => String(t || "").normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();
  function peopleHTML() {
    const NS = window.ForgeNameSets, q = fold(pk.search);
    let names = (NS ? NS.allNames() : []).concat(pk.extraNames);
    names = [...new Set(names)].filter((n) => n && n !== "0" && (!q || fold(n).includes(q))).sort((a, b) => q ? (fold(b).startsWith(q)) - (fold(a).startsWith(q)) || a.localeCompare(b) : a.localeCompare(b));
    if (!names.length) return '<p class="hint">' + (NS && !NS.allNames().length ? "Loading characters…" : "No character called “" + esc(pk.search) + "”.") + "</p>";
    let html = "", letter = "";
    for (const n of names.slice(0, pk.shown)) {
      const l = q ? "" : (n[0] || "#").toUpperCase();
      if (l && l !== letter) { letter = l; html += '<h4 class="ap-letter">' + esc(l) + "</h4>"; }
      html += '<button type="button" class="ap-item ap-person" data-ap-char="' + esc(n) + '">' + esc(n) + "<span>›</span></button>";
    }
    if (names.length > pk.shown) html += '<p class="hint ap-more">Scroll for more…</p>';
    // scenes that belong to no one character (most transformation scenes) come first
    return (q ? "" : '<button type="button" class="ap-item ap-person" data-ap-char="">⟳ Shared transformation & finishing scenes<span>›</span></button>') + html;
  }
  function movesHTML() {
    if (pk.loading && !pk.items.length) return '<p class="hint">Loading ' + esc(pk.who || "shared") + "’s animations…</p>";
    if (!pk.items.length) return '<p class="hint">No animations found for ' + esc(pk.who) + ".</p>";
    let html = "";
    for (const [kind, title] of KINDS) {
      const seen = new Set(), rows = [];
      pk.items.forEach((it, i) => {
        if (it.kind !== kind) return;
        const label = (it.unitId > 0 || !/^Shared/.test(it.moveName || "") ? it.moveName || "Animation" : (it.script || "Animation")) + PART(it.key || "");
        if (seen.has(label)) return;          // other versions of the character share the move: list it once
        seen.add(label); rows.push('<button type="button" class="ap-item" data-ap-entry="' + i + '">' + esc(label) + "</button>");
      });
      if (rows.length) html += '<h4 class="ap-kind">' + esc(title) + "</h4>" + rows.join("");
    }
    return html + (pk.loading ? '<p class="hint">Loading more…</p>' : "");
  }
  function render() {
    const box = document.getElementById("ap-list"), head = document.getElementById("ap-head");
    if (!box) return;
    if (head) head.innerHTML = pk.view === "people" ? "" : '<button type="button" class="button ghost small" data-ap-back>← All characters</button><strong class="ap-who">' + esc(pk.view === "quick" ? "Revival scenes" : pk.who || "Shared scenes") + "</strong>";
    document.getElementById("ap-search").hidden = pk.view !== "people";
    box.innerHTML = pk.view === "people" ? peopleHTML() : pk.view === "quick" ? ownListHTML() : movesHTML();
  }
  // the revival field's own list of scenes, A–Z
  function ownListHTML() {
    const sel = pk.select;
    const items = [...sel.options].filter((o) => /^-?\d+$/.test(o.value) && o.value !== "0" && !o.hasAttribute("data-cur")).map((o) => [o.value, o.textContent.trim()]).sort((a, b) => a[1].localeCompare(b[1]));
    return items.map(([v, n]) => '<button type="button" class="ap-item' + (sel.value === v ? " on" : "") + '" data-ap-val="' + esc(v) + '">' + esc(n) + "</button>").join("");
  }
  // every animation of one character (or the shared scenes: who = "")
  async function loadCharacter(who) {
    pk.view = "moves"; pk.who = who; pk.items = []; pk.loading = true; const seq = ++pk.seq;
    render();
    const call = (args) => Native.call("animationCatalog", Object.assign({ search: "", kind: "all", offset: 0, unitId: 0, sourceDatabase: "" }, args)).catch(() => ({ items: [], more: false }));
    try {
      // the character's cards (all versions with exactly this name), then each card's animations
      let jobs = [{ kind: "transform" }, { kind: "ultimate" }, { kind: "giant" }];
      if (who) {
        const cards = await Native.call("query", { table: "cards", search: { column: "name", text: who }, limit: 1000 }).catch(() => []);
        const ids = [...new Set(cards.filter((c) => c.name === who).map((c) => Number(c.id)))];
        jobs = ids.length ? ids.map((id) => ({ unitId: id, kind: "all" })) : [{ search: who, kind: "all" }];
      }
      const runJob = async (job) => {
        for (let offset = 0; offset < 6000; offset += job.unitId ? 24 : 60) {
          const pages = await Promise.all((job.unitId ? [0, 1] : [0, 1, 2, 3, 4]).map((n) => call(Object.assign({}, job, { offset: offset + n * 12 }))));
          if (seq !== pk.seq) return;
          for (const pg of pages) pk.items.push(...(pg.items || []).filter((it) => who ? it.unitName === who : it.unitId === 0 || it.kind === "giant"));
          render();
          if (!pages[pages.length - 1].more) break;
        }
      };
      for (let i = 0; i < jobs.length; i += 6) { await Promise.all(jobs.slice(i, i + 6).map(runJob)); if (seq !== pk.seq) return; }
    } finally { if (seq === pk.seq) { pk.loading = false; render(); } }
  }
  function open(key, select) {
    pk.key = key; pk.select = select && select.matches("select[data-animchoice]") ? select : null; pk.search = ""; pk.view = "people"; pk.shown = 150; pk.extraNames = []; pk.seq++;
    const mine = own(key), ex = extras[key] || [];
    if (typeof dialog !== "function") return;
    dialog("Choose an animation",
      '<div class="ap"><div class="ap-own"><button type="button" class="button small" data-ap-own="new">' + (mine ? "★ Edit my animation" : "★ Make my own") + '</button><button type="button" class="button ghost small" data-ap-own="saved">★ My saved animations</button>' +
      (pk.select && targetKind(key) === "revival" ? '<button type="button" class="button ghost small" data-ap-quick>🎬 Revival scenes</button>' : "") +
      ex.map(([v, n]) => '<button type="button" class="button ghost small" data-ap-extra="' + esc(v) + '">' + esc(n) + "</button>").join("") + "</div>" +
      '<p class="ap-step">Or use a game animation — pick the character it belongs to:</p>' +
      '<div id="ap-head" class="ap-head"></div><input type="search" id="ap-search" placeholder="Type a character, e.g. Vegito" autocomplete="off">' +
      '<div id="ap-list" class="ap-list"></div></div>');
    const list = document.getElementById("ap-list");
    list.addEventListener("scroll", () => { if (pk.view === "people" && list.scrollTop + list.clientHeight > list.scrollHeight - 400) { pk.shown += 150; render(); } });
    let t;
    document.getElementById("ap-search").addEventListener("input", (e) => {
      pk.search = e.target.value.trim(); pk.shown = 150; render();
      clearTimeout(t);
      // characters the name list doesn't know yet still turn up
      if (pk.search.length >= 2) t = setTimeout(async () => {
        const q = pk.search;
        try {
          const r = await Native.call("animationCatalog", { search: q, kind: "all", offset: 0, unitId: 0, sourceDatabase: "" });
          if (q !== pk.search) return;
          pk.extraNames = [...new Set((r.items || []).filter((it) => it.unitId > 0).map((it) => it.unitName))];
          render();
        } catch {}
      }, 400);
    });
    if (window.ForgeNameSets) ForgeNameSets.load().then(render).catch(() => {});
    render();
  }

  function close() { const d = document.getElementById("dialog"); if (d && d.open) d.close(); }
  document.addEventListener("click", async (e) => {
    const t = e.target.closest && e.target.closest("[data-animpick],[data-ap-char],[data-ap-back],[data-ap-quick],[data-ap-val],[data-ap-entry],[data-ap-own],[data-ap-extra]");
    if (!t) return;
    e.preventDefault(); e.stopImmediatePropagation();
    if (t.dataset.animpick !== undefined) {
      const key = t.dataset.animpick, sel = t.parentElement.querySelector('select[data-animchoice="' + CSS.escape(key) + '"]');
      return open(key, sel);
    }
    if (t.dataset.apChar !== undefined) return loadCharacter(t.dataset.apChar);
    if (t.hasAttribute("data-ap-back")) { pk.seq++; pk.view = "people"; return render(); }
    if (t.hasAttribute("data-ap-quick")) { pk.view = "quick"; return render(); }
    if (t.dataset.apVal !== undefined) {           // from the move's own game list: saved like any field
      const sel = pk.select; close();
      if (!sel || !sel.isConnected) return;
      sel.value = t.dataset.apVal;
      sel.dispatchEvent(new Event("change", { bubbles: true }));
      return;
    }
    if (t.dataset.apEntry !== undefined) {         // any game animation: the usual "Use this animation" check
      const entry = pk.items[Number(t.dataset.apEntry)];
      if (!entry) return;
      state.studioTarget = pk.key;
      if (typeof chooseAnimationTarget === "function") {
        // once it's used, redraw the move so it shows (and keeps) the new animation
        const prev = window.forgeAfterAnimationUse, mine = (k) => {
          window.forgeAfterAnimationUse = prev;
          try { if (typeof prev === "function") prev(k); } catch {}
          if (window.ForgeBuilderUI && state.view === "editor") ForgeBuilderUI.render();
        };
        window.forgeAfterAnimationUse = mine;
        const d = document.getElementById("dialog");
        if (d) d.addEventListener("close", () => setTimeout(() => { if (window.forgeAfterAnimationUse === mine) window.forgeAfterAnimationUse = prev; }, 0), { once: true });
        return chooseAnimationTarget(entry);
      }
      close(); return press(document.body, "pick-animation:" + pk.key);
    }
    if (t.dataset.apExtra !== undefined) {
      close();
      const b = document.querySelector('[data-animextra="' + CSS.escape(t.dataset.apExtra) + '"]');
      if (b) b.click();
      return;
    }
    if (t.dataset.apOwn) {
      const key = pk.key; close();
      const prefix = Object.keys(prepare).find((p) => key.startsWith(p));
      if (prefix) { try { if (await prepare[prefix](key) === false) return; } catch (err) { if (typeof toast === "function") toast(err.message || String(err), true); return; } }
      press(document.body, (t.dataset.apOwn === "new" ? "studio:" : "gallery:") + key);
    }
  }, true);

  // before the maker / picker opens for a move that needs a game scene to start from (revivals)
  const prepare = {};
  function onPrepare(prefix, fn) { prepare[prefix] = fn; }
  function press(select, action) {
    const root = select.closest(".anim-choice, .field, label")?.parentElement || document;
    const b = root.querySelector('[data-guide="' + CSS.escape(action) + '"]') || document.querySelector('[data-guide="' + CSS.escape(action) + '"]');
    if (b) b.click();
    else if (typeof toast === "function") toast("Open Portraits & Sprites to do this.", true);
  }
  // a game animation picked over your own: your own stops being used (it stays in My animations)
  function dropOwn(key) {
    const p = proj(), mine = own(key);
    if (!mine) return false;
    if (/^(revival|transform|giant):/.test(key)) { try { window.ForgeGuide.restoreAbilityAnimation(p, key); } catch {} }
    delete p.animationAssignments[key];
    p.generatedFiles = (p.generatedFiles || []).filter((f) => f.owner !== key);
    if (p.uiLabels && p.uiLabels.animations) delete p.uiLabels.animations[key];
    return true;
  }
  document.addEventListener("change", async (e) => {
    const el = e.target;
    if (!el.matches || !el.matches("select[data-animchoice]")) return;
    const key = el.dataset.animchoice, v = el.value;
    if (v === "cur" || v === "") { e.stopImmediatePropagation(); return; }
    if (/^\d+$/.test(v) || /^-\d+$/.test(v)) {     // a game animation from the list: the page saves it as usual
      if (dropOwn(key) && typeof toast === "function") setTimeout(() => toast("Switched to the game's animation. Your own one is still in My animations."), 50);
      return;
    }
    e.stopImmediatePropagation();
    const back = () => { el.selectedIndex = 0; };
    if (v.startsWith("b:")) {
      back();
      const b = el.closest(".anim-choice").querySelector('[data-animextra="' + CSS.escape(v.slice(2)) + '"]');
      if (b) b.click();
      return;
    }
    back();
    const prefix = Object.keys(prepare).find((p) => key.startsWith(p));
    if (prefix) { try { if (await prepare[prefix](key) === false) return; } catch (err) { if (typeof toast === "function") toast(err.message || String(err), true); return; } }
    press(el, (v === "own:new" ? "studio:" : v === "own:saved" ? "gallery:" : "pick-animation:") + key);
  }, true);
  return { block, enhance, onPrepare, dropOwn, own, currentText, open };
})();
