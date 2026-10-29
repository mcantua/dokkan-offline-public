"use strict";
// 🔎 Character finder: name search plus filters — rarity, type, Super/Extreme class, Category,
// EZA / Super EZA, and sorting (newest first by default). Used on Create and in every
// "pick a character" window. The character list is indexed once (and remembered) so filtering
// is instant; a Category is looked up when it's chosen.
window.ForgeFinder = (() => {
  const h = (s) => esc(String(s == null ? "" : s));
  const KEY = "forge-finder-index";
  const TYPES = ["AGL", "TEQ", "INT", "STR", "PHY"];
  let index = null, loading = null;
  const stamp = () => { const i = state.info || {}; return JSON.stringify([i.meta && (i.meta.date || i.meta.source), i.count]); };
  // [id, name, rarity, element, openYYYYMMDD, hp, atk, def, resource, passive, leader, grow]
  async function load() {
    if (index && index.stamp === stamp()) return index;
    if (loading) return loading;
    loading = (async () => {
      try { const c = JSON.parse(localStorage.getItem(KEY) || "null"); if (c && c.stamp === stamp() && c.v === 2) { index = c; return index; } } catch (e) {}
      let rows = null;
      // One small native answer with just the columns the finder needs (fast). Older app builds
      // without it page through the whole cards table instead.
      try { const r = await Native.call("cardIndex"); if (Array.isArray(r) && r.length) rows = r.map((x) => x.map((v, i) => i === 1 ? String(v ?? "") : v == null ? null : Number(v))); } catch (e) {}
      if (!rows) rows = [];
      if (!rows.length) for (let offset = 0; offset < 60000; offset += 5000) {
        const page = await Native.call("query", { table: "cards", limit: 5000, offset, order: "id" });
        for (const c of page) {
          const id = Number(c.id);
          if (id % 10 !== 1 || !(id >= 1e6 && id < 3e6 || id >= 1e7) || !(Number(c.hp_max) > 300) || c.leader_skill_set_id == null || c.passive_skill_set_id == null) continue;
          rows.push([id, c.name, Number(c.rarity), Number(c.element), Number(String(c.open_at || "").slice(0, 10).replace(/-/g, "")) || 0, Number(c.hp_max) || 0, Number(c.atk_max) || 0, Number(c.def_max) || 0, Number(c.resource_id) || 0, c.passive_skill_set_id, c.leader_skill_set_id, c.optimal_awakening_grow_type == null ? null : Number(c.optimal_awakening_grow_type)]);
        }
        if (page.length < 5000) break;
      }
      index = { v: 2, stamp: stamp(), rows };
      try { localStorage.setItem(KEY, JSON.stringify(index)); } catch (e) {}
      return index;
    })();
    try { return await loading; } finally { loading = null; }
  }
  const card = (r) => ({ id: r[0], name: r[1], rarity: r[2], element: r[3], open: r[4], hp_max: r[5], atk_max: r[6], def_max: r[7], resource_id: r[8], passive_skill_set_id: r[9], leader_skill_set_id: r[10], optimal_awakening_grow_type: r[11] });
  const categoryCards = new Map();
  async function inCategory(catId) {
    if (categoryCards.has(catId)) return categoryCards.get(catId);
    const ids = new Set();
    for (let offset = 0; offset < 60000; offset += 5000) {
      const rows = await Native.call("query", { table: "card_card_categories", filters: { card_category_id: catId }, limit: 5000, offset });
      for (const r of rows) ids.add(Math.floor(Number(r.card_id) / 10) * 10 + 1);
      if (rows.length < 5000) break;
    }
    categoryCards.set(catId, ids);
    return ids;
  }
  // ---------------------------------------------------------------- other versions of characters
  // Cards you only reach in battle: what a character transforms into, exchanges into, revives / swaps in as,
  // turns into as a giant, or becomes from a Standby Skill. Found from the skills that point at them.
  const VERSIONS = [["all", "All versions"], ["normal", "Normal cards"], ["tf", "Transformed forms"], ["exchange", "Exchange forms"], ["revival", "Revival / swap-in"], ["giant", "Giant forms"], ["standby", "Standby forms"]];
  const VERSION_TAG = { tf: "Transformed form", exchange: "Exchange form", revival: "Revival form", giant: "Giant form", standby: "Standby form" };
  let forms = null, formsLoading = null;
  async function allRows(table, filters) {
    const out = [];
    for (let offset = 0; offset < 60000; offset += 5000) {
      const rows = await Native.call("query", Object.assign({ table, limit: 5000, offset }, filters ? { filters } : {})).catch(() => []);
      out.push(...rows);
      if (rows.length < 5000) break;
    }
    return out;
  }
  function loadForms() {
    if (forms) return Promise.resolve(forms);
    if (formsLoading) return formsLoading;
    formsLoading = (async () => {
      const kinds = new Map();   // base id (…0) -> kind (first found wins: exchange > tf > others)
      const owners = new Map();  // base id -> the cards that turn into it
      const mark = (id, kind, from) => {
        id = Math.floor(Number(id) / 10) * 10;
        if (!(id > 0)) return;
        if (!kinds.has(id) || kind === "exchange") kinds.set(id, kind);
        if (!owners.has(id)) owners.set(id, new Set());
        for (const o of from || []) owners.get(id).add(Number(o));
      };
      // who owns which skill: passive set -> cards (from the character list), active / standby set -> cards
      const ix = await load(), cardsByPassive = new Map();
      for (const r of ix.rows) { if (!cardsByPassive.has(r[9])) cardsByPassive.set(r[9], []); cardsByPassive.get(r[9]).push(r[0]); }
      const [prel, cact, cstb] = await Promise.all([allRows("passive_skill_set_relations"), allRows("card_active_skills"), allRows("card_standby_skill_set_relations")]);
      const passiveOwners = new Map(), activeOwners = new Map(), standbyOwners = new Map();
      for (const r of prel) { const cs = cardsByPassive.get(r.passive_skill_set_id); if (cs) { if (!passiveOwners.has(r.passive_skill_id)) passiveOwners.set(r.passive_skill_id, []); passiveOwners.get(r.passive_skill_id).push(...cs); } }
      for (const r of cact) { if (!activeOwners.has(r.active_skill_set_id)) activeOwners.set(r.active_skill_set_id, []); activeOwners.get(r.active_skill_set_id).push(r.card_id); }
      for (const r of cstb) { if (!standbyOwners.has(r.standby_skill_set_id)) standbyOwners.set(r.standby_skill_set_id, []); standbyOwners.get(r.standby_skill_set_id).push(r.card_id); }
      const [p103, p79, p131, a103, a79, s103, ex] = await Promise.all([allRows("passive_skills", { efficacy_type: 103 }), allRows("passive_skills", { efficacy_type: 79 }), allRows("passive_skills", { efficacy_type: 131 }), allRows("active_skills", { efficacy_type: 103 }), allRows("active_skills", { efficacy_type: 79 }), allRows("standby_skills", { efficacy_type: 103 }), allRows("card_exchange_relations")]);
      const setIds = [...new Set(a103.map((r) => r.active_skill_set_id))];
      const sets = new Map();
      for (let i = 0; i < setIds.length; i += 400) for (const r of await Native.call("query", { table: "active_skill_sets", ids: setIds.slice(i, i + 400), limit: 400 }).catch(() => [])) sets.set(r.id, r);
      p103.forEach((r) => mark(r.eff_value1, "tf", passiveOwners.get(r.id)));
      a103.forEach((r) => mark(r.eff_val1, /exchange/i.test((sets.get(r.active_skill_set_id) || {}).name || "") ? "exchange" : "tf", activeOwners.get(r.active_skill_set_id)));
      s103.forEach((r) => { try { mark(JSON.parse(r.efficacy_values)[0], "standby", standbyOwners.get(r.standby_skill_set_id)); } catch (e) {} });
      p79.forEach((r) => mark(r.eff_value1, "giant", passiveOwners.get(r.id))); a79.forEach((r) => mark(r.eff_val1, "giant", activeOwners.get(r.active_skill_set_id)));
      p131.forEach((r) => mark(r.eff_value1, "revival", passiveOwners.get(r.id)));
      ex.forEach((r) => mark(r.to_card_id, "exchange", [r.from_card_id]));
      const ids = [...kinds.keys()].flatMap((b) => [b, b + 1]), rows = [];
      for (let i = 0; i < ids.length; i += 400) rows.push(...await Native.call("query", { table: "cards", ids: ids.slice(i, i + 400), limit: 400 }).catch(() => []));
      const best = new Map();
      for (const c of rows) { const b = Math.floor(Number(c.id) / 10) * 10, cur = best.get(b); if (!cur || Number(c.id) % 10 === 1) best.set(b, c); }
      forms = [...best.values()].filter((c) => c.name && c.name !== "0").map((c) => {
        const r = [Number(c.id), String(c.name), Number(c.rarity), Number(c.element), Number(String(c.open_at || "").slice(0, 10).replace(/-/g, "")) || 0, Number(c.hp_max) || 0, Number(c.atk_max) || 0, Number(c.def_max) || 0, Number(c.resource_id) || 0, c.passive_skill_set_id, c.leader_skill_set_id, c.optimal_awakening_grow_type];
        r.kind = kinds.get(Math.floor(Number(c.id) / 10) * 10);
        r.owners = [...(owners.get(Math.floor(Number(c.id) / 10) * 10) || [])];
        return r;
      });
      return forms;
    })().finally(() => { formsLoading = null; });
    return formsLoading;
  }
  // f: { text, rarity: "" | 5 | 4 | 3 | "low", type: "" | 0-4, cls: "" | 1 | 2, category, eza: "" | "eza" | "seza" | "none", sort, every }
  async function search(f) {
    const ix = await load(), CV = window.ForgeCardVersions;
    if (CV) await CV.load().catch(() => null);
    const text = String(f.text || "").trim().toLowerCase(), words = text.split(/\s+/).filter(Boolean);
    const cat = f.category ? await inCategory(Number(f.category)) : null;
    const ver = f.ver === undefined || f.ver === "" ? "all" : f.ver;
    let base = ix.rows.map(card);
    if (ver !== "normal") {
      // "All versions" shows normal cards right away and adds the other versions as soon as they're found
      const fl = ver === "all" ? (forms || []) : await loadForms();
      const extra = fl.filter((r) => ver === "all" || r.kind === ver).map((r) => Object.assign(card(r), { formKind: r.kind, owners: r.owners }));
      const have = new Set(base.map((c) => Math.floor(c.id / 10)));
      base = ver === "all" ? base.concat(extra.filter((c) => !have.has(Math.floor(c.id / 10)))) : extra;
    }
    const names = base.some((c) => c.formKind) ? new Map(ix.rows.map((r) => [Math.floor(r[0] / 10), r[1]])) : null;
    let list = base.filter((c) => {
      if (c.formKind && c.owners && c.owners.length && names) {
        // whose form it is (the top version first)
        const top = c.owners.find((o) => !(CV && CV.isAwakenedFurther(Math.floor(o / 10) * 10 + 1))) || c.owners[0];
        c.ownerName = String(names.get(Math.floor(top / 10)) || "").replace(/\s+/g, " ").trim();
      }
      if (!f.every && CV) {
        if (!c.formKind && CV.isAwakenedFurther(c.id)) return false;
        // other versions: only those of fully awakened / EZA / Super EZA characters
        // (a form no playable character uses is left out too)
        if (c.formKind && (!c.ownerName || !c.owners.some((o) => names.has(Math.floor(o / 10)) && !CV.isAwakenedFurther(Math.floor(o / 10) * 10 + 1)))) return false;
      }
      if (words.length) { const n = c.name.toLowerCase(); if (!words.every((w) => n.includes(w))) return false; }
      if (f.rarity === "low") { if (c.rarity > 2) return false; } else if (f.rarity !== "" && f.rarity != null && c.rarity !== Number(f.rarity)) return false;
      if (f.type !== "" && f.type != null && c.element % 10 % 5 !== Number(f.type)) return false;
      if (f.cls !== "" && f.cls != null && Math.floor(c.element / 10) !== Number(f.cls)) return false;
      if (cat && !cat.has(c.id)) return false;
      if (f.eza) { const s = CV ? CV.status(c) : ""; if (f.eza === "none" ? s !== "" : f.eza === "eza" ? s === "" : s !== "seza") return false; }
      return true;
    });
    // one entry per card (re-releases with the same skills are listed once)
    const seen = new Set();
    list = list.filter((c) => { const k = [c.name, c.element, c.rarity, c.passive_skill_set_id, c.leader_skill_set_id, c.formKind || ""].join("|"); return !seen.has(k) && seen.add(k); });
    const sorts = { newest: (a, b) => b.open - a.open || b.id - a.id, oldest: (a, b) => a.open - b.open || a.id - b.id, name: (a, b) => a.name.localeCompare(b.name) || b.rarity - a.rarity, atk: (a, b) => b.atk_max - a.atk_max, hp: (a, b) => b.hp_max - a.hp_max, rarity: (a, b) => b.rarity - a.rarity || b.open - a.open };
    list.sort(sorts[f.sort] || sorts.newest);
    if (text && (!f.sort || f.sort === "newest")) {
      // exact and starts-with name matches first
      const score = (c) => { const n = c.name.toLowerCase(); return n === text ? 0 : n.startsWith(text) ? 1 : 2; };
      list.sort((a, b) => score(a) - score(b));
    }
    return list;
  }

  // ---------------------------------------------------------------- the panel
  const chip = (group, value, label, on, cls = "") => '<button type="button" class="fd-chip' + (on ? " on" : "") + (cls ? " " + cls : "") + '" data-fd="' + group + '" data-fv="' + h(value) + '" aria-pressed="' + (on ? "true" : "false") + '">' + h(label) + "</button>";
  function controls(f) {
    const cats = (state.categories || []).filter((c) => c.name && c.name !== "0").slice().sort((a, b) => a.name.localeCompare(b.name));
    const active = ["rarity", "type", "cls", "category", "eza"].filter((k) => f[k] !== "" && f[k] != null).length;
    return '<div class="fd">' +
      '<label class="field fd-search">Find a character<input type="search" data-fd-text placeholder="Name, e.g. Gohan or Super Saiyan 4" value="' + h(f.text || "") + '" autocomplete="off"></label>' +
      '<div class="fd-row fd-ver" role="group" aria-label="Version">' + VERSIONS.map(([v, l]) => chip("ver", v, l, (f.ver || "all") === v)).join("") + "</div>" +
      '<div class="fd-row" role="group" aria-label="Rarity">' + [["", "Any rarity"], [5, "LR"], [4, "UR / TUR"], [3, "SSR"], ["low", "SR & lower"]].map(([v, l]) => chip("rarity", v, l, String(f.rarity ?? "") === String(v))).join("") + "</div>" +
      '<div class="fd-row" role="group" aria-label="Type">' + chip("type", "", "Any type", f.type === "" || f.type == null) + TYPES.map((t, i) => chip("type", i, t, String(f.type) === String(i), "t" + i)).join("") + "</div>" +
      '<div class="fd-row" role="group" aria-label="Class">' + [["", "Any class"], [1, "Super"], [2, "Extreme"]].map(([v, l]) => chip("cls", v, l, String(f.cls ?? "") === String(v))).join("") + "</div>" +
      '<details class="fd-more"' + (f.category || f.eza || (f.sort && f.sort !== "newest") || f.every ? " open" : "") + '><summary>More filters' + (active ? " · " + active + " on" : "") + "</summary>" +
      '<div class="field-grid">' +
      '<label class="field">Category<input list="fd-cats" data-fd-cat placeholder="Any category" value="' + h(f.categoryName || "") + '"><datalist id="fd-cats">' + cats.map((c) => '<option value="' + h(c.name) + '">').join("") + "</datalist></label>" +
      '<label class="field">Extreme Z-Awakening<select data-fd-sel="eza">' + [["", "Any"], ["eza", "Has EZA (or Super EZA)"], ["seza", "Has Super EZA"], ["none", "No EZA yet"]].map(([v, l]) => '<option value="' + v + '"' + ((f.eza || "") === v ? " selected" : "") + ">" + l + "</option>").join("") + "</select></label>" +
      '<label class="field">Sort by<select data-fd-sel="sort">' + [["newest", "Newest first"], ["oldest", "Oldest first"], ["name", "Name A–Z"], ["rarity", "Rarity"], ["atk", "Highest ATK"], ["hp", "Highest HP"]].map(([v, l]) => '<option value="' + v + '"' + ((f.sort || "newest") === v ? " selected" : "") + ">" + l + "</option>").join("") + "</select></label>" +
      '<label class="bld-check fd-every"><input type="checkbox" data-fd-every' + (f.every ? " checked" : "") + "> Also show earlier versions (before Dokkan Awakening)</label>" +
      "</div></details>" +
      '<div class="fd-bar"><span class="fd-count" role="status"></span><button type="button" class="text-button fd-clear" data-fd-clear' + (active || f.text ? "" : " hidden") + ">Clear filters</button></div>" +
      '<div class="fd-results"></div><div class="fd-pager"></div>' +
      '<p class="fd-update">Can\'t find a brand-new character? <button type="button" class="text-button" data-fd-update>⬇ Get the newest game data</button></p></div>';
  }
  function tile(c) {
    const CV = window.ForgeCardVersions;
    return '<button type="button" class="fd-tile" data-fd-pick="' + c.id + '"><img loading="lazy" alt="" src="' + h(typeof thumb === "function" ? thumb(c) : "") + '">' + '<span class="fd-name">' + h(c.name) + '</span><span class="fd-meta"><b class="fd-rar r' + c.rarity + '">' + h(Forge.rarities[c.rarity] || "") + '</b> <b class="fd-el t' + (c.element % 10 % 5) + '">' + h(Forge.elements[c.element] || "") + "</b></span>" +
      // what kind of card it is, on its own line under the name (never over it)
      (c.formKind ? '<span class="fd-form">' + h(VERSION_TAG[c.formKind] || "Other version") + "</span>" + (c.ownerName ? '<span class="fd-from">of ' + h(c.ownerName) + "</span>" : "") : CV ? CV.badge(c) : "") + "</button>";
  }
  // Mounts the finder into `root`. onPick(card) gets a full card row from the game data.
  function mount(root, onPick, start = {}) {
    const f = Object.assign({ text: "", rarity: "", type: "", cls: "", category: "", categoryName: "", eza: "", sort: "newest", every: false, ver: "all" }, start);
    let page = 0, seq = 0, timer = 0, results = [];
    const PAGE = 60;
    root.innerHTML = controls(f);
    const q = (s) => root.querySelector(s);
    async function draw(resetPage = true) {
      const token = ++seq;
      if (resetPage) page = 0;
      const count = q(".fd-count");
      if (count) count.textContent = index ? "Searching…" : "Getting the character list ready (only the first time)…";
      if ((f.ver || "all") === "all" && !forms) loadForms().then(() => { if (root.isConnected) draw(false); }).catch(() => {});
      try { results = await search(f); } catch (e) { if (token === seq) q(".fd-results").innerHTML = '<p class="notice error">' + h(e.message) + "</p>"; return; }
      if (token !== seq || !root.isConnected) return;
      const shown = results.slice(0, (page + 1) * PAGE);
      q(".fd-count").textContent = results.length ? results.length.toLocaleString() + " character" + (results.length === 1 ? "" : "s") : "No character matches these filters.";
      q(".fd-results").innerHTML = shown.map(tile).join("");
      q(".fd-pager").innerHTML = results.length > shown.length ? '<button type="button" class="button ghost fd-morebtn">Show more (' + (results.length - shown.length).toLocaleString() + " left)</button>" : "";
      const more = q(".fd-morebtn");
      if (more) more.onclick = () => { page++; draw(false); };
      const clear = q("[data-fd-clear]");
      if (clear) clear.hidden = !(f.text || f.rarity !== "" || f.type !== "" || f.cls !== "" || f.category || f.eza || (f.ver && f.ver !== "all"));
      root.querySelectorAll("[data-fd-pick]").forEach((b) => b.onclick = async () => {
        b.disabled = true;
        try {
          const row = (await Native.call("query", { table: "cards", ids: [Number(b.dataset.fdPick)], limit: 1 }))[0];
          if (row) await onPick(row);
        } catch (e) { toast(e.message || String(e), true); } finally { if (b.isConnected) b.disabled = false; }
      });
    }
    root.addEventListener("click", (ev) => {
      const b = ev.target.closest("[data-fd]");
      if (b && root.contains(b)) {
        f[b.dataset.fd] = b.dataset.fv === "" ? "" : /^-?\d+$/.test(b.dataset.fv) ? Number(b.dataset.fv) : b.dataset.fv;
        root.querySelectorAll('[data-fd="' + b.dataset.fd + '"]').forEach((x) => { const on = x === b; x.classList.toggle("on", on); x.setAttribute("aria-pressed", on ? "true" : "false"); });
        draw();
      }
      if (ev.target.closest("[data-fd-update]")) {
        const d = root.closest("dialog"); if (d && d.open) d.close();
        if (window.ForgeImport) ForgeImport.open();
        return;
      }
      if (ev.target.closest("[data-fd-clear]")) {
        Object.assign(f, { text: "", rarity: "", type: "", cls: "", category: "", categoryName: "", eza: "", sort: "newest", every: false, ver: "all" });
        root.innerHTML = controls(f);
        bindInputs();
        draw();
      }
    });
    function bindInputs() {
      q("[data-fd-text]").oninput = (e) => { f.text = e.target.value; clearTimeout(timer); timer = setTimeout(draw, 200); };
      q("[data-fd-cat]").onchange = (e) => {
        const name = e.target.value.trim().toLowerCase(), cat = (state.categories || []).find((c) => String(c.name).toLowerCase() === name);
        f.category = cat ? cat.id : ""; f.categoryName = cat ? cat.name : "";
        if (name && !cat) toast("Choose a Category from the list.", true);
        draw();
      };
      root.querySelectorAll("[data-fd-sel]").forEach((s) => s.onchange = () => { f[s.dataset.fdSel] = s.value; draw(); });
      q("[data-fd-every]").onchange = (e) => { f.every = e.target.checked; draw(); };
    }
    bindInputs();
    draw();
    return { refresh: draw, filters: f };
  }
  // A "pick a character" window with the finder.
  function pick(title, choose, { onBack = null, every = false } = {}) {
    dialog(title, '<div data-no-ai class="ucopy-dialog"></div>' + (onBack ? '<button type="button" class="button ghost small" id="fd-back">← Back</button>' : "") + '<div id="fd-root"></div>');
    const d = document.getElementById("dialog");
    if (onBack) document.getElementById("fd-back").onclick = () => Promise.resolve().then(onBack).catch((e) => toast(e.message, true));
    mount(document.getElementById("fd-root"), async (row) => {
      d.addEventListener("close", () => Promise.resolve().then(() => choose(row)).catch((e) => toast(e.message || String(e), true)), { once: true });
      d.close();
    }, { every });
    setTimeout(() => { const i = d.querySelector("[data-fd-text]"); if (i) i.focus(); }, 60);
  }
  // Create screen: the finder replaces the plain name + rarity search.
  if (typeof renderSource === "function") {
    const previous = renderSource;
    renderSource = function() {
      const result = previous.apply(this, arguments);
      const controls = document.querySelector("#main .source-controls");
      if (controls && !document.getElementById("fd-create")) {
        const host = document.createElement("div");
        host.id = "fd-create";
        controls.before(host);
        controls.hidden = true;
        for (const id of ["source-results", "source-pages"]) { const e = document.getElementById(id); if (e) e.hidden = true; }
        mount(host, (row) => createUnit(Number(row.id)), { text: state.sourceQuery || "" });
      }
      return result;
    };
  }
  if (typeof searchSources === "function") {
    const plain = searchSources;
    searchSources = function() { return document.getElementById("fd-create") ? Promise.resolve() : plain.apply(this, arguments); };
  }
  function reset() { index = null; forms = null; categoryCards.clear(); }
  const cards = async () => (await load()).rows.map(card);
  return { load, cards, search, mount, pick, reset };
})();
