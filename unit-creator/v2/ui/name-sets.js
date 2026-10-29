"use strict";
// Character NAMES for conditions ("when there is a “Goku” ally on the team", "when facing “Frieza”").
// The game checks names through card_unique_info_set_relations: a "name group" (set id) lists every card name that
// counts as that character. The game's own groups are offered by name; typing any other name makes a new group in
// the unit (every game card name containing it), exported with the unit.
window.ForgeNameSets = (() => {
  let sets = null, loading = null, infos = null;
  const CUSTOM_BASE = 9100000;
  async function all(table) {
    const out = [];
    for (let offset = 0; ; offset += 5000) { const rows = await Native.call("query", { table, offset, limit: 5000 }); out.push(...rows); if (rows.length < 5000) break; }
    return out;
  }
  function load() {
    if (loading) return loading;
    loading = (async () => {
      const [rel, uni] = await Promise.all([all("card_unique_info_set_relations"), all("card_unique_infos")]);
      infos = uni.map((u) => ({ id: u.id, name: String(u.name || "").replace(/\s+/g, " ").trim() })).filter((u) => u.name);
      const nameOf = new Map(infos.map((u) => [u.id, u.name]));
      const groups = new Map();
      for (const r of rel) { const n = nameOf.get(r.card_unique_info_id); if (!n) continue; if (!groups.has(r.card_unique_info_set_id)) groups.set(r.card_unique_info_set_id, []); groups.get(r.card_unique_info_set_id).push(n); }
      sets = [...groups.entries()].map(([id, names]) => ({ id, label: names.slice().sort((a, b) => a.length - b.length || a.localeCompare(b))[0], names }));
      if (typeof state !== "undefined" && state.view === "editor" && window.ForgeBuilderUI && document.querySelector("[data-cf-kind='nameSet']")) ForgeBuilderUI.render();
    })().catch((e) => { loading = null; throw e; });
    return loading;
  }
  function custom() {
    const p = typeof state !== "undefined" && state.project;
    return p ? Object.entries(p.nameSetLabels || {}).map(([id, label]) => ({ id: Number(id), label, custom: true })) : [];
  }
  // the game has a few groups with the same short name (two "Cooler"s): show each name once (the bigger group)
  function gameList() {
    const by = new Map();
    for (const s of sets || []) { const k = s.label.toLowerCase(), cur = by.get(k); if (!cur || s.names.length > cur.names.length) by.set(k, s); }
    return [...by.values()];
  }
  function list() { return gameList().concat(custom()).sort((a, b) => a.label.localeCompare(b.label)); }
  function label(id) { const s = (sets || []).concat(custom()).find((x) => x.id === Number(id)); return s ? s.label : ""; }
  function first() { const l = list(); return l.length ? l[0].id : 0; }
  // "Rose" finds "Rosé", "super saiyan rose" finds "Goku Black (Super Saiyan Rosé)"
  const fold = (t) => String(t || "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/\s+/g, " ").trim();
  const has = (name, q) => fold(name).includes(fold(q));
  // a new name group: every game card name containing the typed name ("Goku" → Super Saiyan Goku, Goku (Youth)…)
  function create(text, exact = false) {
    const p = state.project, q = String(text || "").trim();
    if (!q) throw new Error("Type a character name.");
    if (!infos) throw new Error("Character names are still loading. Try again in a moment.");
    const hits = exact ? infos.filter((u) => fold(u.name) === fold(q)) : infos.filter((u) => has(u.name, q));
    if (!hits.length) throw new Error("No character in the game is called “" + q + "”.");
    const lbl = exact ? hits[0].name : q;
    const existing = Object.entries(p.nameSetLabels || {}).find(([, l]) => fold(l) === fold(lbl));
    if (existing) return Number(existing[0]);
    window.ForgeGuide.ensure(p, state.info.schema, "card_unique_info_set_relations");
    p.nameSetLabels = p.nameSetLabels || {};
    const id = Math.max(CUSTOM_BASE, ...Object.keys(p.nameSetLabels).map(Number)) + 1;
    for (const u of hits) p.tables.card_unique_info_set_relations.push(Object.assign(Forge.rowDefault(p.schema.card_unique_info_set_relations), { id: Forge.localId(p, "card_unique_info_set_relations"), card_unique_info_id: u.id, card_unique_info_set_id: id }));
    p.nameSetLabels[id] = lbl;
    return id;
  }
  // removes one of your names, and any condition that used it
  function remove(id) {
    const p = state.project;
    id = Number(id);
    const dropped = window.ForgeBuilderUI && ForgeBuilderUI.dropConditions ? ForgeBuilderUI.dropConditions((item) => item.values && Number(item.values.set) === id) : 0;
    delete p.nameSetLabels[id];
    if (p.tables.card_unique_info_set_relations) p.tables.card_unique_info_set_relations = p.tables.card_unique_info_set_relations.filter((r) => Number(r.card_unique_info_set_id) !== id);
    if (typeof scheduleSave === "function") scheduleSave();
    return dropped;
  }
  function matches(text) {
    const q = String(text || "").trim();
    if (!q || !infos) return [];
    return infos.filter((u) => has(u.name, q)).map((u) => u.name);
  }

  // ---------------------------------------------------------------- the control: a button that opens a search
  const esc = (t) => String(t == null ? "" : t).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  function fieldHTML(f, value, h, selection) {
    if (!sets) load().catch(() => {});
    const cur = value ? label(value) || "Name group " + value : "";
    return '<div class="field ns-field"><span>' + h(f.label) + '</span><button type="button" class="ns-btn" data-nspick>🔍 ' + h(cur || (sets ? "Search for a character" : "Loading names…")) + '</button>' +
      '<select data-cf="' + f.name + '" data-cf-kind="nameSet" hidden><option value="' + h(value || 0) + '" selected>' + h(cur) + "</option></select></div>";
  }
  let sheet = null, target = null;
  function results(q) {
    q = q.trim();
    const ql = fold(q);
    const mine = custom().filter((s) => !ql || fold(s.label).includes(ql));
    const game = gameList().filter((s) => !ql || fold(s.label).includes(ql) || s.names.some((n) => fold(n).includes(ql))).sort((a, b) => (fold(b.label).startsWith(ql)) - (fold(a.label).startsWith(ql)) || a.label.localeCompare(b.label));
    const exact = q && game.concat(mine).some((s) => fold(s.label) === ql);
    // every single card name in the game that matches (each can be used on its own)
    const singles = q ? [...new Set(infos.filter((u) => fold(u.name).includes(ql)).map((u) => u.name))].sort((a, b) => (fold(b).startsWith(ql)) - (fold(a).startsWith(ql)) || a.length - b.length || a.localeCompare(b)) : [];
    const typed = q && !exact ? matches(q) : [];
    let out = "";
    if (typed.length) out += '<button type="button" class="ns-item ns-typed" data-nsuse="' + esc(q) + '"><strong>Everyone named “' + esc(q) + '”</strong><small>Every card whose name includes it — ' + typed.length + " cards, e.g. " + esc(typed.slice(0, 3).join(", ")) + "</small></button>";
    if (mine.length) out += "<h3>Your names</h3>" + mine.map((s) => '<div class="ns-row"><button type="button" class="ns-item" data-nsid="' + s.id + '"><strong>' + esc(s.label) + "</strong><small>" + matches(s.label).length + ' cards</small></button><button type="button" class="icon-button" data-nsdel="' + s.id + '" aria-label="Remove ' + esc(s.label) + '">×</button></div>').join("");
    if (singles.length) out += "<h3>Characters (" + singles.length + ")</h3>" + singles.slice(0, 150).map((n) => '<button type="button" class="ns-item" data-nsexact="' + esc(n) + '"><strong>' + esc(n) + "</strong><small>Only this character</small></button>").join("");
    out += "<h3>Character groups</h3>" + (game.length ? game.map((s) => '<button type="button" class="ns-item" data-nsid="' + s.id + '"><strong>' + esc(s.label) + "</strong><small>" + esc(s.names.length > 1 ? s.names.length + " cards, e.g. " + s.names.slice(0, 2).join(", ") : s.names[0]) + "</small></button>").join("") : '<p class="hint">No game character group called that' + (typed.length ? " — use the option above." : ".") + "</p>");
    if (q && !typed.length && !singles.length && !game.length && !mine.length) out = '<p class="hint">No card in the game has “' + esc(q) + '” in its name.</p>';
    return out;
  }
  function choose(id) {
    if (!target || !target.isConnected) return;
    const sel = target.closest(".ns-field").querySelector("select[data-cf-kind='nameSet']");
    sel.innerHTML = '<option value="' + id + '" selected>' + esc(label(id)) + "</option>";
    sel.value = String(id);
    sheet.close();
    sel.dispatchEvent(new Event("change", { bubbles: true }));
  }
  function draw(q = "") {
    sheet.querySelector(".ns-results").innerHTML = results(q);
    sheet.querySelectorAll("[data-nsid]").forEach((b) => b.onclick = () => choose(Number(b.dataset.nsid)));
    sheet.querySelectorAll("[data-nsexact]").forEach((b) => b.onclick = () => { try { const id = create(b.dataset.nsexact, true); choose(id); } catch (e) { toast(e.message, true); } });
    sheet.querySelectorAll("[data-nsuse]").forEach((b) => b.onclick = () => { try { const id = create(b.dataset.nsuse); toast("“" + label(id) + "” added to your names."); choose(id); } catch (e) { toast(e.message, true); } });
    sheet.querySelectorAll("[data-nsdel]").forEach((b) => b.onclick = () => {
      const n = label(b.dataset.nsdel), dropped = remove(b.dataset.nsdel);
      toast("Removed “" + n + "”" + (dropped ? " and the " + (dropped === 1 ? "condition" : dropped + " conditions") + " that used it." : "."));
      if (dropped && window.ForgeBuilderUI) { sheet.close(); ForgeBuilderUI.render(); return; }
      draw(sheet.querySelector("#ns-q").value);
    });
  }
  async function openPicker(btn) {
    target = btn;
    if (!sheet) { sheet = document.createElement("dialog"); sheet.className = "shell-sheet ns-sheet"; sheet.setAttribute("aria-labelledby", "ns-title"); document.body.append(sheet); }
    sheet.innerHTML = '<div class="sheet-head"><h2 id="ns-title">Choose a character</h2><button type="button" class="icon-button" data-ns-close aria-label="Close">×</button></div>' +
      '<label class="field">Search<input type="search" id="ns-q" placeholder="Type a name, e.g. Goku, Frieza, Android #18" autocomplete="off"></label><div class="ns-results"><p class="hint">Loading names…</p></div>';
    sheet.querySelector("[data-ns-close]").onclick = () => sheet.close();
    if (!sheet.open) sheet.showModal();
    const qi = sheet.querySelector("#ns-q");
    qi.focus({ preventScroll: true });
    try { await load(); } catch (e) { sheet.querySelector(".ns-results").innerHTML = '<p class="notice error">' + esc(e.message || e) + "</p>"; return; }
    let t;
    qi.oninput = () => { clearTimeout(t); t = setTimeout(() => draw(qi.value), 120); };
    draw(qi.value);
  }
  document.addEventListener("click", (e) => { const b = e.target.closest && e.target.closest("[data-nspick]"); if (b) { e.preventDefault(); openPicker(b); } });
  function uniqueName(id) { const u = infos && infos.find((x) => x.id === Number(id)); return u ? u.name : ""; }
  // every character name in the game (one each)
  function allNames() { return infos ? [...new Set(infos.map((u) => u.name))] : []; }
  return { uniqueName, load, list, label, first, create, remove, matches, fieldHTML, openPicker, allNames };
})();
