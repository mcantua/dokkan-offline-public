/* Dragon Ball themed home screen and the 3-tap Quick Create wizard. */
(function() {
  "use strict";
  if (typeof renderHome !== "function" || !window.ForgeBuilder) return;
  const B = window.ForgeBuilder, h = (v) => esc(v);
  const fail = (e) => toast(e && e.message || String(e), true);
  document.documentElement.classList.add("dbz");

  // ------------------------------------------------------------ fighting styles
  const STYLES = [
    { key: "allround", icon: "⚔", name: "All-rounder", text: "Big stats, Ki, critical hits and some damage reduction. Great at everything.", stats: [1, 1, 1] },
    { key: "nuke", icon: "💥", name: "Heavy hitter", text: "Huge ATK that grows with every attack, plus extra Super Attacks.", stats: [0.95, 1.15, 0.9] },
    { key: "tank", icon: "🛡", name: "Tank", text: "Massive DEF, damage reduction and guard. Takes hits for the team.", stats: [1.1, 0.9, 1.3] },
    { key: "dodge", icon: "💨", name: "Speedster", text: "Evades attacks and powers up each time it's targeted.", stats: [1, 1.05, 0.95] },
    { key: "support", icon: "✨", name: "Support", text: "Boosts the whole team's Ki, ATK and DEF and foresees enemy Supers.", stats: [1.05, 0.95, 1.05] }
  ];
  function styleActions(style, opts) {
    const lr = opts.rarity === "LR", cat = opts.category, also = opts.also;
    const base = lr ? [21000, 20000, 12500] : [16500, 15000, 9500];
    const stat = (i) => Math.round(base[i] * style.stats[i] / 10) * 10;
    const actions = [{ do: "basics", name: opts.name, rarity: opts.rarity, class: opts.cls, type: opts.type, hp: stat(0), atk: stat(1), def: stat(2) }];
    const groups = cat ? [{ who: "categories", categories: [cat], ki: 3, hp: lr ? 170 : 150, atk: lr ? 170 : 150, def: lr ? 170 : 150 }] : [{ who: "all", ki: 3, hp: lr ? 150 : 130, atk: lr ? 150 : 130, def: lr ? 150 : 130 }];
    if (cat && also) groups.push({ who: "categories", categories: [cat], also: [also], ki: 1, hp: 30, atk: 30, def: 30 });
    actions.push({ do: "leader", groups });
    const turn4 = [{ rule: "turn", turn: 4 }];
    const passives = {
      allround: [{ ability: "atkdef", values: { atk: 200, def: 200 } }, { ability: "ki", values: { amount: 3 } }, { ability: "crit", values: { amount: 30 }, when: "attacking" }, { ability: "dr", values: { amount: 20 } }, { ability: "additional", values: { super: 30 }, when: "attacking", conditions: turn4 }],
      nuke: [{ ability: "atkdef", values: { atk: 250, def: 150 } }, { ability: "ki", values: { amount: 4 } }, { ability: "stack", values: { stat: 0, step: 20, max: 100, trigger: 5 } }, { ability: "crit", values: { amount: 50 }, when: "attacking" }, { ability: "additional", values: { super: 50 }, when: "attacking" }],
      tank: [{ ability: "atkdef", values: { atk: 150, def: 300 } }, { ability: "ki", values: { amount: 3 } }, { ability: "dr", values: { amount: 40 } }, { ability: "guard", values: {}, conditions: [{ rule: "turn", turn: 3 }] }, { ability: "stack", values: { stat: 1, step: 20, max: 100, trigger: 7 } }],
      dodge: [{ ability: "atkdef", values: { atk: 180, def: 180 } }, { ability: "ki", values: { amount: 3 } }, { ability: "dodge", values: { amount: 40 } }, { ability: "stack", values: { stat: 0, step: 30, max: 150, trigger: 7 } }, { ability: "crit", values: { amount: 50 }, conditions: [{ rule: "dodged" }] }],
      support: [{ ability: "atkdef", values: { atk: 160, def: 160 } }, { ability: "ki", values: { amount: 3 } }, { ability: "ki", values: { amount: 2 }, who: "alliesExceptSelf" }, { ability: "atkdef", values: { atk: 30, def: 30 }, who: "alliesExceptSelf" }, { ability: "foresee", values: {}, who: "allies" }]
    };
    actions.push({ do: "passive", name: opts.passiveName || undefined, replace: true, abilities: passives[style.key] });
    const superFx = { allround: [{ effect: "atk", values: { amount: 30 }, who: "self", turns: 99 }], nuke: [{ effect: "atk", values: { amount: 50 }, who: "self", turns: 99 }, { effect: "defDown", values: { amount: 30 }, turns: 3 }], tank: [{ effect: "def", values: { amount: 50 }, who: "self", turns: 3 }], dodge: [{ effect: "atk", values: { amount: 30 }, who: "self", turns: 99 }, { effect: "dodge", values: { amount: 20 }, who: "self", turns: 1 }], support: [{ effect: "atkdef", values: { atk: 20, def: 20 }, who: "allies", turns: 2 }] };
    actions.push({ do: "super", which: "super", damage: style.key === "nuke" ? "immense" : "supreme", effects: superFx[style.key] });
    if (lr) {
      actions.push({ do: "super", which: "ultra", name: "Final " + (opts.superName || "Burst"), damage: "mega-colossal", effects: style.key === "support" ? [{ effect: "atkdef", values: { atk: 30, def: 30 }, who: "allies", turns: 2 }] : [{ effect: "atk", values: { amount: 100 }, who: "self", turns: 99 }] });
      actions.push({ do: "active", kind: "attack", name: "Ultimate " + (opts.superName || "Strike"), boost: style.key === "nuke" ? 300 : 200, conditions: [{ rule: "turn", turn: 4 }] });
    }
    return actions;
  }

  // ------------------------------------------------------------ quick create wizard
  const qc = { step: 1, card: null, style: "allround", rarity: "LR", cls: "Super", type: "AGL", name: "", results: [], game: [], mine: [], sparking: [], query: "" };
  function modal() {
    let d = document.getElementById("qc-dialog");
    if (!d) { d = document.createElement("dialog"); d.id = "qc-dialog"; d.className = "aic-dialog qc-dialog"; document.body.append(d); }
    return d;
  }
  // SLR / GR: an LR at level 180 / 200 with that level's bonuses (see ForgeLevelPerks in builder.js)
  const QC_TIER = {
    SLR: { tier: "slr", lv: 180, title: "SLR · Super Legendary Rare: an LR at level 180 — team cost 88, Super Attack level 30 and the Super Exclusive: a permanent ATK & DEF +10% and 10% damage reduction, applied after every other boost and can't be removed." },
    GR: { tier: "gr", lv: 200, title: "GR · Godly Rare: an LR at level 200 — team cost 99, Super Attack level 30 and the Godly Exclusive: a permanent ATK & DEF +20% and 20% damage reduction, applied after every other boost and can't be removed." }
  };
  function stepsBar() { return '<ol class="qc-steps">' + ["Pick a fighter", "Fighting style", "Final touches"].map((n, i) => '<li class="' + (qc.step === i + 1 ? "on" : qc.step > i + 1 ? "done" : "") + '"><span class="db-ball s' + (i + 1) + (qc.step > i ? " lit" : "") + '"></span>' + h(n) + "</li>").join("") + "</ol>"; }
  function renderQC() {
    const d = modal();
    let body = "";
    if (qc.step === 1) body = '<h3>Who is your fighter based on?</h3><p class="hint">Pick the character your NEW unit starts from. Only fully awakened, EZA and Super EZA characters are listed, plus their transformed, exchange, revival, giant and standby versions. Your unit gets its own new IDs — the game character is never changed.</p><div id="qc-finder"></div><details class="beginner-details qc-mine"><summary>Or start from one of your own units (or a Sparking character)</summary><label class="field">Search<input id="qc-search" type="search" placeholder="Goku, Vegeta, Broly, Gohan…" value="' + h(qc.query) + '"></label><div id="qc-results" class="qc-grid">' + qcResults() + "</div></details>";
    if (qc.step === 2) body = '<h3>How should ' + h(qc.card.name) + ' fight?</h3><div class="qc-styles">' + STYLES.map((s) => '<button type="button" class="qc-style' + (qc.style === s.key ? " on" : "") + '" data-qc-style="' + s.key + '"><span class="qc-icon">' + s.icon + "</span><strong>" + h(s.name) + "</strong><small>" + h(s.text) + "</small></button>").join("") + "</div>";
    if (qc.step === 3) body = '<h3>Final touches</h3><label class="field">Name<input id="qc-name" maxlength="80" value="' + h(qc.name) + '"></label><h4>Rarity</h4><div class="bld-pills">' + ["GR", "SLR", "LR", "UR"].map((r) => '<button type="button" class="bld-pill' + (window.ForgeRarityBadge ? " qc-tier" : "") + (qc.rarity === r ? " on" : "") + '" data-qc-rarity="' + r + '"' + (QC_TIER[r] ? ' title="' + h(QC_TIER[r].title) + '"' : "") + '>' + (window.ForgeRarityBadge ? ForgeRarityBadge.html(QC_TIER[r] ? QC_TIER[r].tier : r.toLowerCase()) + (r === "UR" ? '<small class="qc-tur">/ TUR</small>' : "") : r === "UR" ? "UR / TUR" : r) + "</button>").join("") + (QC_TIER[qc.rarity] ? '<p class="hint qc-tier-hint">' + h(QC_TIER[qc.rarity].title) + "</p>" : "") + '</div><h4>Class</h4><div class="bld-pills">' + ["Super", "Extreme"].map((c) => '<button type="button" class="bld-pill' + (qc.cls === c ? " on" : "") + '" data-qc-class="' + c + '">' + c + "</button>").join("") + '</div><h4>Type</h4><div class="bld-pills">' + B.TYPES.map((t, i) => '<button type="button" class="bld-type-pill t' + i + (qc.type === t ? " on" : "") + '" data-qc-type="' + t + '">' + t + "</button>").join("") + '</div><p class="hint">You get a full kit: leader skill for ' + h(qc.card.name) + "'s team, a passive, Super Attack" + (qc.rarity !== "UR" ? ", Ultra Super Attack and Active Skill" : "") + ". You can change anything afterwards.</p>";
    d.innerHTML = '<div class="aic-head"><h2>⚡ Quick Create</h2><button type="button" class="icon-button" id="qc-close" aria-label="Close">×</button></div>' + stepsBar() + body + '<div class="row qc-nav">' + (qc.step > 1 ? '<button type="button" class="button ghost" id="qc-back">← Back</button>' : "") + (qc.step === 2 ? '<button type="button" class="button" id="qc-next">Next →</button>' : "") + (qc.step === 3 ? '<button type="button" class="button qc-go" id="qc-create">Create my unit!</button>' : "") + "</div>";
    d.querySelector("#qc-close").onclick = () => d.close();
    const back = d.querySelector("#qc-back"); if (back) back.onclick = () => { qc.step--; renderQC(); };
    const next = d.querySelector("#qc-next"); if (next) next.onclick = () => { qc.step = 3; renderQC(); };
    d.querySelectorAll("[data-qc-style]").forEach((b) => b.onclick = () => { qc.style = b.dataset.qcStyle; qc.step = 3; renderQC(); });
    d.querySelectorAll("[data-qc-rarity]").forEach((b) => b.onclick = () => { qc.rarity = b.dataset.qcRarity; renderQC(); });
    d.querySelectorAll("[data-qc-class]").forEach((b) => b.onclick = () => { qc.cls = b.dataset.qcClass; renderQC(); });
    d.querySelectorAll("[data-qc-type]").forEach((b) => b.onclick = () => { qc.type = b.dataset.qcType; renderQC(); });
    const name = d.querySelector("#qc-name"); if (name) name.oninput = () => { qc.name = name.value; };
    const search = d.querySelector("#qc-search");
    if (search) { let timer; search.oninput = () => { qc.query = search.value; clearTimeout(timer); timer = setTimeout(() => qcSearch().catch(fail), 250); }; bindResults(); }
    // game characters: the character finder (top versions + their other versions, with filters)
    const host = d.querySelector("#qc-finder");
    if (host && window.ForgeFinder) ForgeFinder.mount(host, (row) => {
      qc.card = Object.assign({ __kind: "game" }, row); qc.name = row.name; qc.step = 2;
      const parts = B.elementParts(row.element);
      qc.type = B.TYPES[parts.type]; qc.cls = parts.cls === 2 ? "Extreme" : "Super";
      renderQC();
    }, { text: "" });
    const go = d.querySelector("#qc-create"); if (go) go.onclick = () => qcCreate().catch(fail);
    if (!d.open) d.showModal();
  }
  function qcResults() {
    const more = qc.more ? '<button type="button" class="button ghost small qc-more" id="qc-more">More characters…</button>' : "";
    if (!qc.results.length) return '<p class="hint">' + (window.ForgeFinder ? (qc.query ? "None of your units or Sparking characters match." : "Your units appear here.") : qc.more ? "No fully awakened characters on this page yet." : qc.query ? "No matching characters." : "Loading characters…") + "</p>" + (window.ForgeFinder ? "" : more);
    return more ? qcResultsList() + more : qcResultsList();
  }
  // Where a fighter in the list comes from: the game (one entry per character), a transformation
  // form, the Sparking collection, or a unit you made or imported yourself.
  const KIND_BADGE = (c) => c.__kind === "form" ? '<span class="cv-badge qc-kind qc-kind-form">TRANSFORMATION</span>'
    : c.__kind === "sparking" ? '<span class="cv-badge qc-kind qc-kind-sparking">SPARKING</span>' + (c.__form ? '<span class="cv-badge qc-kind qc-kind-form">TRANSFORMATION</span>' : "")
    : c.__kind === "mine" ? '<span class="cv-badge qc-kind qc-kind-mine">' + (c.origin === "imported" ? "IMPORTED BY YOU" : "YOUR UNIT") + "</span>" : "";
  function qcResultsList() {
    return qc.results.map((c, i) => '<button type="button" class="qc-pick qc-' + (c.__kind || "game") + '" data-qc-i="' + i + '"><img loading="lazy" src="' + h(thumb(c.__kind === "mine" ? { id: c.resourceId || c.targetId } : c)) + '" alt=""><span><strong>' + h(c.name) + "</strong><small>" + h(Forge.rarities[c.rarity] || "") + " · " + h(Forge.elements[c.element] || "") + "</small>" + KIND_BADGE(c) + (window.ForgeCardVersions && c.__kind !== "mine" ? ForgeCardVersions.badge(c, c.__kind === "sparking" ? "sparking" : undefined) : "") + "</span></button>").join("");
  }
  function bindResults() {
    const moreButton = document.getElementById("qc-more");
    if (moreButton) moreButton.onclick = () => { moreButton.disabled = true; qcSearch(true).catch(fail); };
    document.querySelectorAll("#qc-dialog [data-qc-i]").forEach((b) => b.onclick = () => {
      const card = qc.results[Number(b.dataset.qcI)];
      if (!card) return;
      qc.card = card; qc.name = card.name; qc.step = 2;
      const parts = B.elementParts(card.element);
      qc.type = B.TYPES[parts.type]; qc.cls = parts.cls === 2 ? "Extreme" : "Super";
      renderQC();
    });
  }
  const QC_PAGE = 200;
  // Show only the most advanced version of everything: Super EZA, else EZA, else fully awakened.
  const RANK = { seza: 2, eza: 1, "": 0 };
  const rankOf = (c, database) => RANK[window.ForgeCardVersions ? ForgeCardVersions.status(c, database) : ""] || 0;
  // Transformation forms in a page of search results, following the same rules:
  // - 9xxxxxx cards that share a name with a current card are the game's old pre-EZA copies: hidden.
  // - the same transformation listed more than once (same name, type, rarity and passive) shows once,
  //   as its most advanced version; and when one copy has an EZA / Super EZA, copies without are hidden.
  async function transformations(rows, listed, database) {
    const CV = window.ForgeCardVersions, method = database === "sparking" ? "querySparking" : "query";
    const shown = new Set(listed.map((c) => Number(c.id)));
    const candidates = rows.filter((c) => {
      const id = Number(c.id);
      return id % 10 === 1 && !shown.has(id) && !(CV && CV.isPlayerCard(c, database)) && Number(c.hp_max) > 300 && c.leader_skill_set_id != null && c.passive_skill_set_id != null;
    });
    // old copies: 90/91/95/96xxxxx whose current card (10/11/20/40xxxxx + the same last 5 digits) has the same name
    const copies = candidates.filter((c) => /^9[0-9]/.test(String(c.id)) && String(c.id).length === 7);
    const current = new Map();
    if (copies.length) {
      const ids = [];
      for (const c of copies) { const x = Number(c.id) % 100000; ids.push(1000000 + x, 1100000 + x, 2000000 + x, 4000000 + x); }
      try { for (const r of await Native.call(method, { table: "cards", ids, limit: ids.length })) current.set(Number(r.id), r); } catch {}
    }
    const isOldCopy = (c) => { const x = Number(c.id) % 100000; return /^9[0-9]/.test(String(c.id)) && [1000000, 1100000, 2000000, 4000000].some((b) => { const r = current.get(b + x); return r && r.name === c.name; }); };
    const best = new Map();
    for (const c of candidates) {
      if (isOldCopy(c)) continue;
      const k = [c.name, c.element, c.rarity, c.passive_skill_set_id].join("|"), prev = best.get(k);
      if (!prev || rankOf(c, database) > rankOf(prev, database)) best.set(k, c);
    }
    const out = [...best.values()];
    const top = new Map();
    for (const c of out) { const k = [c.name, c.element, c.rarity].join("|"); top.set(k, Math.max(top.get(k) || 0, rankOf(c, database))); }
    return out.filter((c) => rankOf(c, database) >= top.get([c.name, c.element, c.rarity].join("|")));
  }
  const words = (t) => String(t || "").toLowerCase().split(/\s+/).filter(Boolean);
  // Units you made or imported, matching the search (they come first).
  function ownUnits(text) {
    const w = words(text);
    return (state.projects || []).filter((p) => { const n = String(p.name || "").toLowerCase(); return w.every((x) => n.includes(x)); })
      .slice(0, 30).map((p) => Object.assign({ __kind: "mine", id: "mine:" + p.key }, p));
  }
  // The Sparking collection, when it's been downloaded (Android and iPhone apps).
  async function sparkingFighters(text) {
    if (!words(text).length) return [];
    let info; try { info = await Native.call("sparkingInfo"); } catch { return []; }
    if (!info || !info.available) return [];
    const rows = await Native.call("querySparking", { table: "cards", search: { column: "name", text }, order: "id", limit: 200 });
    const CV = window.ForgeCardVersions, list = CV ? await CV.collapse(rows, { database: "sparking" }) : rows.filter((c) => Number(c.id) % 10 === 1);
    const cards = list.filter((c) => c.rarity >= 3).map((c) => Object.assign({ __kind: "sparking" }, c));
    const forms = (await transformations(rows, list, "sparking")).map((c) => Object.assign({ __kind: "sparking", __form: true }, c));
    return cards.concat(forms).sort((x, y) => y.rarity - x.rarity || String(x.name).localeCompare(String(y.name))).slice(0, 40);
  }
  // The starting unit for Quick Create, from wherever the picked fighter comes from.
  async function startingUnit(card, projects) {
    const eclipse = (o) => Native.call("query", o);
    if (card.__kind === "mine") {
      const own = await Native.call("loadProject", { key: card.key });
      if (!own || !own.tables) throw Error("That saved unit could not be read.");
      const prepared = await (own.formProjects?.length ? ForgeForms.reserve : ForgeUnitRebase.reserve)(own, { query: eclipse, projects, schema: state.info.schema,
        prepareCounters: (project) => ForgeCounterReservations.prepare(project, { schema: state.info.schema }), listAssets: (o) => Native.call("assets", o).catch((e) => /asset folder is unavailable/i.test(e && e.message || "") ? [] : Promise.reject(e)),   // nothing imported yet = nothing to clash with
        readAsset: async (key) => ForgeBattlePoseEditor.decode((await Native.call("readAsset", { key, maxBytes: 12 * 1024 * 1024 })).base64),
        storeDecoration: (text) => Native.call("storeDecoration", { text }),
        storeLwf: async (bytes, options) => Native.call("storeLwf", { name: options.name, data: ForgeBattlePoseEditor.encode(bytes) }) });
      const p = prepared.project;
      p.key = "unit-" + p.targetId + "-" + Date.now();
      p.libraryOrigin = "created";
      delete p.versions;
      p.createdAt = p.updatedAt = new Date().toISOString();
      return { p, note: "" };
    }
    if (card.__kind === "sparking") {
      const info = await Native.call("sparkingInfo");
      const p = await Forge.loadTemplate((o) => Native.call("querySparking", o), info.schema, card.id, Forge.SLOT_FLOOR);
      await ForgeGuide.allocateId(p, eclipse, projects);
      p.source.database = "sparking";
      p.provenance = { sourceDatabase: "Sparking", sourceCardId: Number(card.id), importedAt: new Date().toISOString(), sourceVersion: info.meta && info.meta.latestVersion };
      if (window.ForgeSparkingDependencies) p.sourceDependencies = await ForgeSparkingDependencies.collect(p, { sourceQuery: (o) => Native.call("querySparking", o), targetQuery: eclipse, sourceSchema: info.schema, targetSchema: state.info.schema });
      if (typeof studioState !== "undefined") { studioState.sourceDatabase = "sparking"; studioState.files = []; }
      return { p, note: "Made from a Sparking card. Review its matching resources before installing it in Eclipse." };
    }
    let p = await Forge.loadTemplate(eclipse, state.info.schema, card.id, Forge.SLOT_FLOOR);
    await ForgeGuide.allocateId(p, eclipse, projects);
    let note = "";
    if (window.ForgeTemplateForms) {
      const included = await ForgeTemplateForms.include(p, { query: eclipse, schema: state.info.schema, projects });
      p = included.project;
      note = ForgeTemplateForms.message(included);
    }
    return { p, note };
  }
  async function qcSearch(more = false) {
    const text = qc.query, offset = more ? qc.offset || 0 : 0;
    const rows = await Native.call("query", { table: "cards", search: { column: "name", text }, order: "id", limit: QC_PAGE, offset });
    if (text !== qc.query) return;
    // One entry per character: the fully awakened, playable version (highest rarity first).
    const CV = window.ForgeCardVersions;
    let list;
    if (CV) list = await CV.collapse(rows);
    else { const seen = new Set(); list = rows.filter((c) => Number(c.id) % 10 === 1 && !seen.has(c.name + c.element) && seen.add(c.name + c.element)); }
    if (text !== qc.query) return;
    // Transformation forms (and other playable forms) are separate cards in the game data.
    const forms = await transformations(rows, list);
    if (text !== qc.query) return;
    const kept = more ? qc.game.slice() : [], ids = new Set(kept.map((c) => c.id));
    for (const c of list) if (c.rarity >= 3 && !ids.has(c.id)) { ids.add(c.id); kept.push(Object.assign({ __kind: "game" }, c)); }
    for (const c of forms) if (!ids.has(c.id)) { ids.add(c.id); kept.push(Object.assign({ __kind: "form" }, c)); }
    qc.game = kept.sort((x, y) => y.rarity - x.rarity || String(x.name).localeCompare(String(y.name)) || (x.__kind === "form") - (y.__kind === "form") || y.id - x.id);
    if (!more) {
      qc.mine = ownUnits(text);
      qc.sparking = [];
      sparkingFighters(text).then((found) => { if (text !== qc.query || !found.length) return; qc.sparking = found; qc.results = qc.mine.concat(window.ForgeFinder ? [] : qc.game, qc.sparking); const box = document.getElementById("qc-results"); if (box) { box.innerHTML = qcResults(); bindResults(); } }).catch(() => {});
    }
    qc.results = (qc.mine || []).concat(window.ForgeFinder ? [] : qc.game, qc.sparking || []);
    qc.offset = offset + QC_PAGE;
    qc.more = rows.length === QC_PAGE;
    const box = document.getElementById("qc-results");
    if (box) { box.innerHTML = qcResults(); bindResults(); }
  }
  async function quickCreate() {
    Object.assign(qc, { step: 1, card: null, results: [], game: [], mine: [], sparking: [], query: "", more: false, offset: 0 });
    renderQC();
    await qcSearch();
  }
  async function qcCreate() {
    const d = modal(), style = STYLES.find((s) => s.key === qc.style), card = qc.card;
    d.close();
    const made = await busy("Powering up " + (qc.name || card.name) + "…", async () => {
      await flushSave();
      const projects = await Native.call("projects");
      const start = await startingUnit(card, projects);
      let p = start.p;
      const formNote = start.note;
      if (formNote) setTimeout(() => toast(formNote), 1200);
      if (!(state.categories || []).length) await loadLookups();
      const catIds = (p.tables.card_card_categories || []).map((r) => r.card_category_id);
      const cats = catIds.map((id) => (state.categories.find((c) => c.id === id) || {}).name).filter((n) => n && n !== "0");
      const ctx = await ForgeAIConnect.context();
      const tierPick = QC_TIER[qc.rarity];
      ForgeAIConnect.applyActions(p, styleActions(style, { name: (qc.name || card.name).trim(), rarity: tierPick ? "LR" : qc.rarity, cls: qc.cls, type: qc.type, category: cats[0], also: cats[1], superName: ((p.tables.special_sets || []).find((s2) => s2.id === ((p.tables.card_specials || []).find((r) => r.style === "Normal") || {}).special_set_id) || {}).name }), ctx);
      p.builderAuto = Object.assign({}, p.builderAuto);
      p.quickCreated = true;   // rarity, class and type were chosen in Quick Create: Basics shows them as one line
      p.patch.name = Forge.card(p).name + " — Custom Unit";
      state.project = p;
      if (tierPick) { p.cardOverrides.lv_max = tierPick.lv; if (window.ForgeLevelPerks) await ForgeLevelPerks.apply(p); }
      state.previewUrl = "";
      state.builderTab = "appearance";   // pick the look first
      if (window.ForgeGuideUI && ForgeGuideUI.resetHistory) ForgeGuideUI.resetHistory();
      if (window.ForgeBuilderUI) ForgeBuilderUI.refreshTexts();
      await flushSave();
      state.view = "editor";
      updateNav();
      renderEditor();
      window.scrollTo(0, 0);
      return true;
    });
    if (made && state.view === "editor") toast("⚡ " + Forge.card(state.project).name + " is ready! Change anything you like, then Save & Play.");
  }

  // ------------------------------------------------------------ home
  function homeTile(p) {
    const parts = B.elementParts(p.element);
    return '<button class="unit-tile db-tile t' + parts.type + '" data-open="' + h(p.key) + '"><img class="db-tile-portrait art-pending" data-unit-art="' + h(p.key) + '" loading="lazy" alt="' + h(p.name || 'Your unit') + '">' + (window.ForgeRarityBadge && ForgeRarityBadge.iconFor(p) ? '<span class="db-tile-rarity has-rb">' + ForgeRarityBadge.html(ForgeRarityBadge.iconFor(p)) + '</span>' : '<span class="db-tile-rarity">' + h(Forge.rarities[p.rarity] || "") + '</span>') + '<span class="db-tile-type">' + h(Forge.elements[p.element] || "") + "</span><strong>" + h(p.name || "Your unit") + '</strong><small>Tap to keep building →</small></button>';
  }
  const previous = renderHome;
  renderHome = function() {
    if (state.view !== "home") return previous.apply(this, arguments);
    const projects = state.projects || [];
    // Home: one big way to start, your units right under it, and the other ways to start below.
    const units = '<section class="db-section db-units"><div class="db-section-head"><h2>Your units <span class="count">' + projects.length + '</span></h2>' + (projects.length ? '<button class="button ghost small" id="db-library">See all →</button>' : '<span id="db-library" hidden></span>') + '</div>' + (projects.length ? '<div class="db-tiles">' + projects.slice(0, 12).map(homeTile).join("") + "</div>" : '<p class="db-empty">No units yet. Tap <strong>Create a unit</strong> to make your first one.</p>') + '</section>';
    // Dokkan-style home: your latest unit big in the middle, event-style banners on the right,
    // a big "Continue" button like the game's Quest button.
    const last = projects.slice().sort((a, b) => String(b.updatedAt || "").localeCompare(String(a.updatedAt || "")))[0];
    const web = document.documentElement.classList.contains("web-version");
    const banner = (id, icon, title, sub, main) => '<button type="button" class="dk-banner' + (main ? " dk-main" : "") + '" ' + id + '><span class="dk-banner-icon" aria-hidden="true">' + icon + '</span><span class="dk-banner-txt"><strong>' + title + "</strong><small>" + sub + "</small></span></button>";
    const banners = banner('id="db-quick"', "⚡", "Create a unit", "Brand-new unit", true) +
      banner('data-dk="eza"', "★", "EZA / Super EZA", "Power up a card") +
      banner('data-dk="templates"', "✦", "Templates", "Ready-made units") +
      banner('data-dk="import"', "⬆", "Import", "Unit files &amp; .sql") +
      (web ? "" : banner('data-dk="sparking"', "⚡", "Sparking characters", "Build from Sparking")) +
      banner('data-dk="offline"', "⬇", "Downloads", "Game files for offline");
    const stage = '<section class="dk-stage' + (last ? "" : " dk-empty") + '"><div class="dk-art" aria-hidden="true">' + (last ? '<img class="dk-art-img art-pending" data-unit-art="' + h(last.key) + '" alt="">' : "") + '</div>' +
      '<div class="dk-top"><span class="dk-logo">DOKKAN<b>UNIT CREATOR</b></span><span class="dk-games">Eclipse · Sparking</span></div>' +
      '<div class="dk-banners">' + banners + "</div>" +
      (last ? '<div class="dk-plate"><small>Last edited</small><strong>' + h(last.name || "Your unit") + '</strong></div><button type="button" class="dk-continue" data-open="' + h(last.key) + '">▶ Continue</button>'
        : '<div class="dk-plate"><small>Welcome!</small><strong>Make your first unit</strong></div><button type="button" class="dk-continue" id="dk-start">▶ Start</button>') + "</section>";
    main(stage + units);
    window.ForgeCollectionArt?.mount(document.querySelector(".db-tiles"),projects.slice(0,12));
    if (last) window.ForgeCollectionArt?.mount(document.querySelector(".dk-art"), [last]);
    const start = document.getElementById("dk-start"); if (start) start.onclick = () => newUnitChoice();
    document.getElementById("db-quick").onclick = () => newUnitChoice();
    document.getElementById("db-library").onclick = () => navigate("library").catch(fail);
    const go = (t) => window.ForgeShell && ForgeShell.go(t);
    document.querySelectorAll("[data-dk]").forEach((b) => b.onclick = () => {
      const k = b.dataset.dk;
      if (k === "eza") return ezaChoice();
      if (k === "sparking") return navigate("library").then(() => setTimeout(() => { const f = document.querySelector('[data-library-filter="sparking"]'); if (f) f.click(); }, 80)).catch(fail);
      go(k);
    });
  };
  // Home's one big button: make a new unit, or EZA / Super EZA a card that's already in the game.
  function createChoice() {
    dialog("Create a unit", '<div class="qc-styles"><button type="button" class="qc-style" id="cc-new"><span class="qc-icon">⚡</span><strong>Create a unit</strong><small>Make a brand-new unit.</small></button><button type="button" class="qc-style" id="cc-eza"><span class="qc-icon">★</span><strong>EZA / Super EZA a card</strong><small>Power up a card that’s already in the game.</small></button></div>');
    document.getElementById("cc-new").onclick = () => newUnitChoice();
    document.getElementById("cc-eza").onclick = () => { document.getElementById("dialog").close(); ezaChoice(); };
  }
  function newUnitChoice() {
    dialog("Create a unit", '<div class="qc-styles"><button type="button" class="qc-style" id="cc-template"><span class="qc-icon">★</span><strong>Start from a character template</strong><small>Pick a character and a ready-made fighting style (like Tank or Heavy hitter). Your unit is ready in seconds, then change anything.</small></button><button type="button" class="qc-style" id="cc-scratch"><span class="qc-icon">🛠</span><strong>Build from scratch</strong><small>Pick the character whose art and animations you want, then make the leader, passive, supers and transformations yourself.</small></button></div><button type="button" class="button ghost small" id="cc-back">← Back</button>');
    document.getElementById("cc-template").onclick = () => { document.getElementById("dialog").close(); quickCreate().catch(fail); };
    document.getElementById("cc-scratch").onclick = () => { document.getElementById("dialog").close(); navigate("source").catch(fail); };
    document.getElementById("cc-back").onclick = () => createChoice();
  }
  function ezaChoice() {
    dialog("Extreme Z-Awakening", '<p>Choose what to make. Your changes are added to that card in Eclipse; all new skills use their own IDs.</p><div class="qc-styles"><button type="button" class="qc-style" id="ez-eza"><span class="qc-icon">★</span><strong>EZA</strong><small>Give a card 7 awakening steps (or redo its EZA) with stronger leader and passive skills.</small></button><button type="button" class="qc-style" id="ez-seza"><span class="qc-icon">✪</span><strong>Super EZA</strong><small>Add an 8th, even stronger step to a card that already has an EZA.</small></button></div>');
    document.getElementById("ez-eza").onclick = () => ezaWho("eza");
    document.getElementById("ez-seza").onclick = () => ezaWho("seza");
  }
  // EZA / Super EZA: any character in the game, or one of your own units (made or imported)
  function ezaWho(kind) {
    const mine = (state.projects || []).slice().sort((a, b) => String(b.updatedAt || "").localeCompare(String(a.updatedAt || "")));
    dialog(kind === "seza" ? "Super EZA — which character?" : "EZA — which character?",
      '<div class="qc-styles"><button type="button" class="qc-style" id="ezw-game"><span class="qc-icon">🔎</span><strong>A character from the game</strong><small>Give any character in the game ' + (kind === "seza" ? "a Super EZA" : "an EZA") + ", or change the one it already has.</small></button></div>" +
      "<h3>Or one of your units</h3>" + (mine.length ? '<div class="porg-names">' + mine.map((p) => '<button type="button" class="porg-name" data-ezw="' + h(p.key) + '"><span><strong>' + h(p.name || "Unit") + "</strong><small>" + h(p.origin === "imported" ? "Imported by you" : "Made by you") + '</small></span><b aria-hidden="true">›</b></button>').join("") + "</div>" : '<p class="hint">You have no units yet.</p>') +
      '<div class="row"><button type="button" class="button ghost" id="ezw-back">← Back</button></div>');
    document.getElementById("ezw-back").onclick = () => ezaChoice();
    document.getElementById("ezw-game").onclick = () => { document.getElementById("dialog").close(); ForgeBuilderUI.startAwaken(kind); };
    document.querySelectorAll("[data-ezw]").forEach((b) => b.onclick = () => { document.getElementById("dialog").close(); Promise.resolve(ForgeBuilderUI.startAwakenOwn(kind, b.dataset.ezw)).catch(fail); });
  }
  window.ForgeQuickCreate = { open: quickCreate, styleActions, STYLES, ezaChoice, createChoice };
})();
