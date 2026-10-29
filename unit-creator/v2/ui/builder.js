/* Card Builder: the beginner-first default editor. Every choice is plain English and writes the
   real game rows through ForgeBuilder (builder-model.js). A live card preview mirrors the unit's
   in-game details screen. The previous editor stays available as "Classic editor". */
(function() {
  "use strict";
  if (!window.ForgeBuilder || typeof renderEditor !== "function") return;
  const B = window.ForgeBuilder, G = window.ForgeGuide, D = window.FORGE_GUIDE_DATA || {};
  if (B.setKiScale) B.setKiScale(() => state.project && Number(Forge.card(state.project).rarity) >= 5 ? 100 / 3 : 25);
  const prior = { renderEditor, renderPreview };
  try { state.builder = localStorage.getItem("forge-builder") !== "off"; } catch { state.builder = true; }
  const TABS = [["appearance", "Portraits & Sprites", "🖼"], ["look", "Artwork & Aura", "◐"], ["basics", "Basics", "◆"], ["leader", "Leader Skill", "♛"], ["passive", "Passive Skill", "✦"], ["supers", "Super Attacks", "✸"], ["active", "Active Skill", "⚡"], ["standby", "Standby & Finish", "⏳"], ["domain", "Domain", "🌐"], ["links", "Links & Categories", "⛓"], ["save", "Save & Play", "⬇"]];
  const AWAKEN_TABS = [["eza", "EZA Overview", "✪"], ["leader", "Leader Skill", "♛"], ["passive", "Passive Skill", "✦"], ["supers", "EZA Super Attack", "✸"], ["save", "Save & Play", "⬇"]];
  // EX Super Attacks: the game pairs each trigger with its own priority (20 / 30 / 40).
  const EX_TYPES = [[0, "When the 1st attack in a turn is a Super Attack"], [1, "As an additional Super Attack"], [2, "When the 1st Super Attack is a critical hit"]], EX_PRIORITY = { 0: 20, 1: 30, 2: 40 };
  const exText = (t, chance) => "Activates with a " + (chance || 70) + "% chance " + ["when the 1st attack in a turn is a Super Attack", "when performing an additional Super Attack", "when the 1st Super Attack performs a critical hit"][t];
  const tabsFor = () => state.project && state.project.awaken ? AWAKEN_TABS : TABS;
  const ui = { key: "", open: "", adding: false, leader: null, causality: new Map(), requested: new Set(), pending: new Set(), subTargets: null, subLoading: null, cardNames: new Map(), cardOpen: false, activeKind: "attack", tf: { how: "passive", into: "custom", cond: { mode: "all", items: [{ key: "turn", values: { turn: 4 } }] } }, lookupsLoading: null };
  // remember which Super Attack cards are open across re-renders
  document.addEventListener("toggle", (e) => { const d = e.target; if (d && d.dataset && d.dataset.sopen && ui.superOpen) { const id = Number(d.dataset.sopen); if (d.open) ui.superOpen.add(id); else ui.superOpen.delete(id); } }, true);
  const h = (v) => esc(v);
  const profiles = () => D.damageProfiles || [];
  const fail = (e) => toast(e && e.message || String(e), true);
  const names = () => ({
    category: (id) => ((state.categories || []).find((c) => c.id === Number(id)) || {}).name,
    nameSet: (id) => window.ForgeNameSets ? ForgeNameSets.label(id) : "",
    unique: (id) => window.ForgeNameSets ? ForgeNameSets.uniqueName(id) : "",
    link: (id) => ((state.links || []).find((l) => Number(l.id) === Number(id)) || {}).name,
    // the game stores Ki conditions as a % of the Super Attack Ki: LRs need 12 for 100%… in steps of 3 per 100%, others 4
    kiOf: (v) => { const lr = state.project && Number(Forge.card(state.project).rarity) >= 5; return Math.round(Number(v) * (lr ? 3 : 4) / 100); }
  });
  // Dokkan wording for any condition (combined rules, every condition type), or null while rows are loading
  function conditionWords(row, look) {
    if (!window.ForgeConditionWords || !row.causality_conditions) return "";
    let compiled;
    try { compiled = JSON.parse(row.causality_conditions).compiled; } catch { return ""; }
    return ForgeConditionWords.text(compiled, look, names(), row.exec_timing_type);
  }
  const queryMethod = () => state.project && state.project.source && state.project.source.database === "sparking" ? "querySparking" : "query";
  const q = (o) => Native.call(queryMethod(), o);
  const tab = () => tabsFor().some(([k]) => k === state.builderTab) ? state.builderTab : tabsFor()[0][0];
  const btn = (label, action, kind = "ghost small", extra = "") => '<button type="button" class="button ' + kind + '" data-b="' + h(action) + '"' + extra + ">" + h(label) + "</button>";
  const guide = (label, action, kind = "ghost small") => '<button type="button" class="button ' + kind + '" data-guide="' + h(action) + '">' + h(label) + "</button>" + (action.startsWith("studio:") ? '<button type="button" class="button ghost small" data-guide="gallery:'+h(action.slice(7))+'">My animations</button>' : '');
  const hint = (t) => '<p class="hint">' + h(t) + "</p>";
  // passive descriptions are always written automatically (there's no manual option any more)
  function auto(key, fallback) { if (/^(passive|leader):/.test(String(key))) return true; const a = state.project.builderAuto || {}; return a[key] === undefined ? fallback : a[key]; }
  function setAuto(key, value) { state.project.builderAuto = state.project.builderAuto || {}; state.project.builderAuto[key] = value; }

  // ------------------------------------------------------------ data helpers
  function stageKey(kind) {
    const p = state.project, groups = B.stageGroups(p, kind);
    let key = ((ui.stage || {})[p.key] || {})[kind];
    // the strongest awakening (last EZA / Super EZA step) is selected unless you picked another one
    if (!groups.some((g) => g.key === key)) { const open = groups.filter((g) => !g.locked); key = (open[open.length - 1] || groups[groups.length - 1]).key; }
    return key;
  }
  function setStage(kind, key) { ui.stage = ui.stage || {}; ui.stage[state.project.key] = ui.stage[state.project.key] || {}; ui.stage[state.project.key][kind] = key; }
  function stageGroup(kind) { return B.stageGroups(state.project, kind).find((g) => g.key === stageKey(kind)); }
  function stageLocked(kind) { const g = stageGroup(kind); return !!(state.project.awaken && g && g.key === "base"); }
  function target(kind) { const key = stageKey(kind); return key === "base" ? state.project : B.stageView(state.project, kind, key); }
  function passiveSet() { const g = stageGroup("passive"), id = g ? g.setId : Forge.card(state.project).passive_skill_set_id; return (state.project.tables.passive_skill_sets || []).find((r) => r.id === id); }
  // transformations added earlier only went into the base Passive Skill: put them in the one you're editing too
  // (an EZA set), so they show in its description and the unit transforms either way
  function linkTransformations() {
    const p = state.project, set = passiveSet(), base = Forge.card(p).passive_skill_set_id;
    if (!set || set.id === base) return;
    const rel = p.tables.passive_skill_set_relations || [], have = new Set(rel.filter((r) => r.passive_skill_set_id === set.id).map((r) => r.passive_skill_id));
    const missing = rel.filter((r) => r.passive_skill_set_id === base && !have.has(r.passive_skill_id)).map((r) => (p.tables.passive_skills || []).find((x) => x.id === r.passive_skill_id)).filter((r) => r && Number(r.id) < 0 && Number(r.efficacy_type) === 103);
    if (!missing.length) return;
    for (const r of missing) rel.push(Object.assign(Forge.rowDefault(p.schema.passive_skill_set_relations), { id: Forge.localId(p, "passive_skill_set_relations"), passive_skill_set_id: set.id, passive_skill_id: r.id }));
    refreshTexts(); scheduleSave();
  }
  function passiveRows(set = passiveSet()) {
    if (!set) return [];
    const ids = (state.project.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === set.id).map((r) => r.passive_skill_id);
    return ids.map((id) => (state.project.tables.passive_skills || []).find((r) => r.id === id)).filter(Boolean);
  }
  function leaderSet() { const g = stageGroup("leader"), id = g ? g.setId : Forge.card(state.project).leader_skill_set_id; return (state.project.tables.leader_skill_sets || []).find((r) => r.id === id); }
  function stageBar(kind) {
    const groups = B.stageGroups(state.project, kind);
    if (groups.length < 2) return "";
    const current = stageKey(kind);
    return '<section class="panel bld-stages"><h2>' + (state.project.awaken ? "Which EZA step are you editing?" : "Which version are you editing?") + '</h2><div class="bld-pills">' + groups.map((g) => '<button type="button" class="bld-pill' + (g.key === current ? " on" : "") + (g.locked ? " locked" : "") + '" data-b="stage:' + kind + ":" + g.key + '">' + h(g.label) + (g.locked ? " 🔒" : "") + "</button>").join("") + "</div>" + hint(state.project.awaken ? "Steps that share a button use the same skill. Each EZA step's changes only apply once the player reaches that step." : "This character also has an Extreme Z-Awakened (EZA) version with its own skills. The strongest step is selected; pick “Before EZA” to edit what your unit starts with.") + "</section>";
  }
  function leaderRows(set = leaderSet()) { return set ? (state.project.tables.leader_skills || []).filter((r) => r.leader_skill_set_id === set.id) : []; }
  function specialsOf(setId) { return (state.project.tables.specials || []).filter((r) => r.special_set_id === setId); }
  function activeSets() {
    const ids = new Set((state.project.tables.card_active_skills || []).map((r) => r.active_skill_set_id));
    return (state.project.tables.active_skill_sets || []).filter((s) => ids.has(s.id));
  }
  function activeRows(setId) { return (state.project.tables.active_skills || []).filter((r) => r.active_skill_set_id === setId); }
  function lookupCausality(id) {
    const local = (state.project.tables.skill_causalities || []).find((r) => r.id === id);
    if (local) return local;
    if (ui.causality.has(id)) return ui.causality.get(id);
    const known = (state.conditionRows || []).find((r) => r.id === id);
    return known;
  }
  function knownCausalities() { return [...(state.conditionRows || []), ...[...ui.causality.values()].filter(Boolean), ...(state.project.tables.skill_causalities || [])]; }
  function condInfo(row) {
    const d = B.decodeCondition(row.causality_conditions, lookupCausality);
    if (d && d.pending) { d.pending.forEach((id) => { if (!ui.requested.has(id)) ui.pending.add(id); }); return { pending: true, text: "checking conditions…" }; }
    if (!d) return { spec: null, text: "" };
    if (d.custom) {
      const words = conditionWords(row, (id) => { const r = lookupCausality(id); if (r === undefined && !ui.requested.has(id)) ui.pending.add(id); return r; });
      if (words === null) return { pending: true, text: "checking conditions…" };
      return { custom: true, text: words || G.describeCondition(row.causality_conditions, knownCausalities(), D.conditionTypes).replace(/^\((.*)\)$/, "$1") };
    }
    return { spec: d, text: B.conditionText(d, names()) };
  }
  async function loadPending() {
    const ids = [...ui.pending].filter((id) => !ui.requested.has(id));
    ui.pending.clear();
    if (!ids.length) return false;
    ids.forEach((id) => ui.requested.add(id));
    for (let i = 0; i < ids.length; i += 500) {
      const chunk = ids.slice(i, i + 500), rows = await q({ table: "skill_causalities", ids: chunk, limit: 1000 });
      for (const r of rows) ui.causality.set(r.id, r);
      for (const id of chunk) if (!ui.causality.has(id)) ui.causality.set(id, null);
    }
    return true;
  }
  async function ensureSubTargets() {
    if (ui.subTargets) return ui.subTargets;
    if (!ui.subLoading) ui.subLoading = (async () => {
      const all = [];
      if (state.info.schema.sub_target_types) for (let offset = 0; ; offset += 5000) {
        const rows = await q({ table: "sub_target_types", offset, limit: 5000 });
        all.push(...rows);
        if (rows.length < 5000) break;
      }
      ui.subTargets = all;
      return all;
    })().finally(() => { ui.subLoading = null; });
    return ui.subLoading;
  }
  async function cardName(id) {
    id = Number(id);
    if (ui.cardNames.has(id)) return ui.cardNames.get(id);
    const own = window.ForgeForms ? ForgeForms.all(state.project).find((m) => Number(m.targetId) === id) : null;
    if (own) { ui.cardNames.set(id, Forge.card(own).name); return Forge.card(own).name; }
    ui.cardNames.set(id, "");
    try { const row = (await q({ table: "cards", ids: [id], limit: 1 }))[0]; ui.cardNames.set(id, row ? row.name : ""); } catch {}
    return ui.cardNames.get(id);
  }
  function knownCardName(id) {
    id = Number(id);
    const own = window.ForgeForms ? ForgeForms.all(state.project).find((m) => Number(m.targetId) === id) : null;
    if (own) return Forge.card(own).name;
    if (!ui.cardNames.has(id)) { cardName(id).then((n) => { if (!n || state.view !== "editor" || !state.builder) return; if (["transform", "passive", "active"].includes(tab())) renderEditor(); else refreshCard(); }).catch(() => {}); return ""; }
    return ui.cardNames.get(id);
  }

  // ------------------------------------------------------------ automatic descriptions
  // "\"Saiyan Saga\" Category allies'" for an ability limited to a group of allies (sub-target set)
  function subOwner(row, project) {
    const id = Number(row.sub_target_type_set_id);
    if (!id) return "";
    if (!ui.subTargets) { ensureSubTargets().then(() => { if (state.view === "editor") { refreshTexts(); renderEditor(); } }).catch(() => {}); return ""; }
    const rows = [...((project || state.project).tables.sub_target_types || []), ...ui.subTargets].filter((r) => Number(r.sub_target_type_set_id) === id);
    if (!rows.length || rows.some((r) => ![1, 2].includes(Number(r.target_value_type)))) return "";
    const nm = (cid) => '"' + (names().category(cid) || "Category " + cid) + '"';
    const any = rows.filter((r) => Number(r.target_value_type) === 1).map((r) => nm(r.target_value)), all = rows.filter((r) => Number(r.target_value_type) === 2).map((r) => nm(r.target_value));
    const list = (a, w) => a.length <= 1 ? a.join("") : a.slice(0, -1).join(", ") + " " + w + " " + a[a.length - 1];
    return (any.length ? list(any, "or") : "") + (all.length ? (any.length ? " and " : "") + list(all, "and") : "") + " Category allies'";
  }
  // "the character and allies whose names include “Goku” or “Vegeta”" for an ability limited to named characters
  function subFor(row, project) {
    const id = Number(row.sub_target_type_set_id);
    if (!id || !ui.subTargets) return "";
    const rows = [...((project || state.project).tables.sub_target_types || []), ...ui.subTargets].filter((r) => Number(r.sub_target_type_set_id) === id);
    if (!rows.length || rows.some((r) => Number(r.target_value_type) !== 4)) return "";
    const NS = window.ForgeNameSets;
    if (NS) NS.load().then(() => {}).catch(() => {});
    const ns = rows.map((r) => "\"" + ((NS && NS.label(r.target_value)) || "a character") + "\"");
    const list = ns.length <= 1 ? ns.join("") : ns.slice(0, -1).join(", ") + " or " + ns[ns.length - 1];
    return (Number(row.target_type) === 16 ? "allies" : "the character and allies") + " whose names include " + list;
  }
  function lineExtra(row, project) {
    const out = Number(row.efficacy_type) === 103 ? { formName: formNameOf(row.eff_value1) } : {};
    const who = subOwner(row, project), named = !who && subFor(row, project);
    if (who) out.subOwner = who;
    if (named) out.subFor = named;
    return out;
  }
  // the name of what a transformation turns into: your own form's name first, then the game card's
  function formNameOf(id) {
    const p = state.project, n = Number(id);
    const link = (p.transformLinks || []).find((l) => Number(l.targetId) === n);
    const form = (p.formProjects || []).find((f) => (link && f.key === link.targetKey) || Number(f.targetId) === n);
    return form ? Forge.card(form).name : knownCardName(n);
  }
  function describer() {
    const fn = (row) => condInfo(row).text;
    fn.extra = (row) => lineExtra(row);
    return fn;
  }
  // The game's own wording (it uses {passiveImg:…} icons) is kept and updated line by line rather
  // than rewritten; abilities the builder can't read also keep their written text.
  // (Descriptions the app wrote itself also use the game's icons now, so "is it ours?" is decided
  // by comparing with what the app would write, not by looking for icons.)
  // Passive descriptions are always written for the person.
  function passiveAutoDefault() { return true; }
  // Rewrites the description of every passive of the unit (before EZA and each EZA / Super EZA step) whose
  // abilities changed — however they changed: added or removed here, from a preset, copied from another unit or
  // character, or by the AI helper. A change switches "Write the description for me" back on for that passive.
  function rowsOfSet(p, setId) {
    const ids = (p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === setId).map((r) => r.passive_skill_id);
    return ids.map((id) => (p.tables.passive_skills || []).find((r) => r.id === id)).filter(Boolean);
  }
  const rowSig = (rows) => rows.map((r) => [r.id, r.efficacy_type, r.eff_value1, r.eff_value2, r.eff_value3, r.exec_timing_type, r.target_type, r.calc_option, r.turn, r.probability, r.is_once, r.causality_conditions].join(",")).join("|");
  function autoWriteAll() {
    const p = state.project;
    if (!p || !p.tables || !p.tables.passive_skill_sets) return false;
    let changed = false;
    if (!p.autoTextV2) {   // units made before: switch every passive's description to automatic once
      for (const k of Object.keys(p.builderAuto || {})) if (k.startsWith("passive:")) p.builderAuto[k] = true;
      p.builderLines = {};
      p.autoTextV2 = true; changed = true;
    }
    p.builderSig = p.builderSig || {};
    const seen = new Set();
    for (const g of B.stageGroups(p, "passive")) {
      if (g.locked || g.setId == null || seen.has(g.setId)) continue;
      seen.add(g.setId);
      const set = p.tables.passive_skill_sets.find((x) => x.id === g.setId);
      if (!set) continue;
      const rows = rowsOfSet(p, set.id), sig = rowSig(rows), prev = p.builderSig[set.id];
      p.builderSig[set.id] = sig;
      if (prev !== undefined && prev !== sig) { setAuto("passive:" + set.id, true); if (p.builderLines) delete p.builderLines[set.id]; }
      if (auto("passive:" + set.id, true)) {
        let text;
        try { text = B.passiveText(rows, describer()); } catch (e) { continue; }
        if (text.includes(PENDING_TEXT)) { ui.textsStale = true; continue; }
        if (set.itemized_description !== text) { set.itemized_description = text; changed = true; }
      }
    }
    return changed;
  }
  let autoQueued = false;
  function queueAutoWrite() {
    if (autoQueued) return;
    autoQueued = true;
    setTimeout(() => {
      autoQueued = false;
      if (!autoWriteAll()) return;
      scheduleSave();
      const set = state.view === "editor" ? passiveSet() : null, box = set && document.querySelector('[data-manual="passive:' + set.id + '"]');
      if (box && box !== document.activeElement) box.value = set.itemized_description || "";
      if (typeof paintPdescPreviews === "function") paintPdescPreviews();
      refreshCard();
    }, 0);
  }
  // every way of adding or removing a passive ability goes through these two
  for (const name of ["addPassive", "removePassive"]) {
    const original = Forge[name];
    if (typeof original === "function" && !original.__autoText) {
      Forge[name] = function () { const r = original.apply(this, arguments); queueAutoWrite(); return r; };
      Forge[name].__autoText = true;
    }
  }
  function specialAutoDefault(set) { return specialsOf(set.id).every((r) => B.decodeSpecial(r)) && profiles().some((x) => x.increase_rate === set.increase_rate && x.lv_bonus === set.lv_bonus); }
  function activeAutoDefault(set) { return activeRows(set.id).every((r) => B.decodeActive(r) || Number(r.efficacy_type) === 103); }
  // Lines the description shows for each ability: [heading, line]. null while conditions load.
  const PENDING_TEXT = "checking conditions…";
  function passiveLines(rows) {
    const d = describer(), out = {};
    for (const row of rows) {
      const heading = B.officialHeading(row, d(row)), line = B.officialLine(row, d.extra(row));
      if ((heading + line).includes(PENDING_TEXT)) return null;
      out[row.id] = [heading, line];
    }
    return out;
  }
  // When the description isn't written automatically (for example it keeps the game's own
  // wording), abilities added, changed or removed in the builder are still reflected in it.
  function syncPassiveText(set, rows) {
    const PM = window.ForgePassiveMerge;
    if (!PM) return;
    const now = passiveLines(rows);
    if (!now) { ui.textsStale = true; return; }
    PM.syncText(state.project, set, rows, (row) => now[row.id]);
  }
  // Abilities can also change outside the builder's own buttons (copying from a character, adding
  // a counter, the AI helper…). On each render the description catches up with them.
  function passiveCatchUp() {
    autoWriteAll();
    const p = state.project, set = passiveSet();
    if (!set) return;
    const key = "passive:" + set.id, settled = (p.builderAuto || {})[key], rows = passiveRows(set), before = set.itemized_description;
    if (settled === true) {
      const text = B.passiveText(rows, describer());
      if (!text.includes(PENDING_TEXT)) set.itemized_description = text;
    } else if (settled === false && p.builderLines && p.builderLines[set.id]) syncPassiveText(set, rows);
    if (set.itemized_description !== before) {
      scheduleSave();
      const box = document.querySelector('[data-manual="passive:' + set.id + '"]');
      if (box && box !== document.activeElement) box.value = set.itemized_description || "";
      refreshCard();
    }
  }
  function passiveBaseline() {
    const p = state.project, set = passiveSet();
    passiveCatchUp();
    if (!set || (p.builderLines && p.builderLines[set.id])) return;
    const rows = passiveRows(set);
    settleAuto(set, rows);
    if (auto("passive:" + set.id, passiveAutoDefault(rows, set))) return;
    const now = passiveLines(rows);
    if (now) { p.builderLines = p.builderLines || {}; p.builderLines[set.id] = now; }
  }
  // Decide once per passive whether its description is written for the person or kept and updated
  // line by line, so a later wording change can't flip it.
  function settleAuto(set, rows) {
    const p = state.project, key = "passive:" + set.id;
    if ((p.builderAuto || {})[key] === undefined) setAuto(key, passiveAutoDefault(rows, set));
  }
  function refreshTexts() {
    const p = state.project, set = passiveSet();
    if (set) {
      const rows = passiveRows(set);
      settleAuto(set, rows);
      if (auto("passive:" + set.id, passiveAutoDefault(rows, set))) {
        const text = B.passiveText(rows, describer());
        if (text.includes(PENDING_TEXT)) ui.textsStale = true;
        else set.itemized_description = text;
        if (p.builderLines) delete p.builderLines[set.id];
      } else syncPassiveText(set, rows);
    }
    for (const rel of p.tables.card_specials || []) {
      const s = (p.tables.special_sets || []).find((x) => x.id === rel.special_set_id);
      if (s && !(p.awaken && Number(s.id) > 0) && auto("sa:" + s.id, specialAutoDefault(s))) s.description = B.superText(s, specialsOf(s.id), profiles());
    }
    for (const s of activeSets()) if (auto("active:" + s.id, activeAutoDefault(s))) {
      s.effect_description = B.activeText(p, s, profiles());
      const cond = condInfo(s);
      if (cond.pending) ui.textsStale = true;
      else s.condition_description = B.activeConditionText(cond.text, s);
    }
    for (const row of p.tables.passive_skills || []) if (Number(row.efficacy_type) === 103 && auto("td:passive_skills:" + row.id, false)) {
      const text = condInfo(row).text;
      B.setTransformationDescription(p, state.info.schema, "PassiveSkill", row.id, "Transforms" + (text ? " " + text : ""));
    }
    for (const row of p.tables.active_skills || []) if (Number(row.efficacy_type) === 103 && auto("td:active_skills:" + row.id, false)) {
      const s = (p.tables.active_skill_sets || []).find((x) => x.id === row.active_skill_set_id), text = s ? condInfo(s).text : "";
      B.setTransformationDescription(p, state.info.schema, "ActiveSkill", row.id, "Transforms via Active Skill" + (text ? " " + text : ""));
    }
  }
  function commit(work, options = {}) {
    try {
      const result = work(state.project);
      if (result && typeof result.then === "function") return result.then(() => finish(options)).catch(fail);
      finish(options);
      return result;
    } catch (e) {
      fail(e);
      if (options.render === false && state.view === "editor") setTimeout(() => renderEditor(), 0);
    }
  }
  function finish({ render = true, box = null } = {}) {
    refreshTexts();
    scheduleSave();
    if (render) renderEditor(); else { refreshCard(); if (box) softRefresh(box); else syncTextareas(); }
  }

  // ------------------------------------------------------------ card preview
  // The game's description, drawn like the card screen: headings, bullets and its icons
  // (green ↑ boost, red ↓ own stat lowered, yellow ↓ enemy lowered, once only, rest of battle).
  const PIMG = { up_g: ["▲", "Increase"], down_r: ["▼", "Decrease"], down_y: ["▼", "Enemy decrease"], once: ["1×", "Once only"], forever: ["∞", "For the rest of the battle"] };
  function icons(safe) {
    return safe.replace(/\{passiveImg:([A-Za-z0-9_]+)\}/g, (m, k) => { const [g, label] = PIMG[k] || [k.replace(/_/g, " "), k]; return '<span class="pimg pimg-' + h(k) + '" role="img" aria-label="' + h(label) + '">' + h(g) + "</span>"; });
  }
  function itemized(text) {
    const lines = String(text || "").split(/\n/);
    let out = "", open = false, li = "", exclusive = false;
    const flush = () => { if (li) { out += "<li>" + icons(h(li)) + "</li>"; li = ""; } };
    for (const raw of lines) {
      const line = raw.trim();
      if (!line) continue;
      const head = line.match(/^\*(.+)\*$/);
      if (head) { flush(); if (open) { out += "</ul>"; open = false; } out += (/Exclusive$/.test(head[1]) ? '<h5 class="bld-exclusive' + (/^Super/.test(head[1]) ? " bld-super" : "") + '">' : "<h5>") + icons(h(head[1])) + "</h5>"; exclusive = /Exclusive$/.test(head[1]) ? (/^Super/.test(head[1]) ? "super" : true) : false; continue; }
      if (line.startsWith("- ")) { flush(); if (!open) { out += exclusive ? '<ul class="bld-exclusive-list' + (exclusive === "super" ? " bld-super" : "") + '">' : "<ul>"; open = true; } li = line.slice(2); continue; }
      // official text wraps long lines onto the next line: it belongs to the bullet above
      if (open && li) { li += " " + line; continue; }
      flush();
      if (open) { out += "</ul>"; open = false; }
      out += "<p>" + icons(h(line)) + "</p>";
    }
    flush();
    return out + (open ? "</ul>" : "");
  }
  function oneLine(text) { return h(String(text || "").replace(/\s*\n\s*/g, " ")); }
  function artUrl() {
    const p = state.project, c = Forge.card(p);
    return state.previewUrl || resourceThumb((p.artBinding && p.artBinding.sourceId) || c.resource_id || p.source.resourceId);
  }
  function cardHTML() {
    const p = state.project, c = Forge.card(p), parts = B.elementParts(c.element), type = B.TYPES[parts.type], color = B.TYPE_COLORS[parts.type];
    const lset = leaderSet(), pset = passiveSet();
    const supers = (p.tables.card_specials || []).slice().sort((a, b) => (a.style === "Hyper") - (b.style === "Hyper") || a.lv_start - b.lv_start);
    const sections = [];
    sections.push('<section><h4>Leader Skill</h4>' + (lset ? "<p>" + oneLine(lset.description || "No description yet") + "</p>" : "<p class=\"muted\">None</p>") + "</section>");
    for (const rel of supers) {
      const s = (p.tables.special_sets || []).find((x) => x.id === rel.special_set_id);
      if (!s) continue;
      const label = rel.style === "Hyper" ? "Ultra Super Attack" : rel.style === "Extra" ? "EX Super Attack" : "Super Attack";
      sections.push("<section><h4>" + label + " <small>" + h(rel.eball_num_start) + "+ Ki" + (rel.lv_start ? " · SA Lv " + h(rel.lv_start) + "+" : "") + "</small></h4><strong>" + h(s.name) + "</strong><p>" + oneLine(s.description) + "</p></section>");
    }
    if (pset) sections.push("<section><h4>Passive Skill</h4><strong>" + h(pset.name) + '</strong><div class="itemized">' + itemized(pset.itemized_description) + "</div></section>");
    for (const s of activeSets()) sections.push("<section><h4>Active Skill</h4><strong>" + h(s.name) + "</strong><p>" + oneLine(s.effect_description) + '</p><p class="muted">' + oneLine(s.condition_description) + "</p></section>");
    const slots = window.ForgeForms ? ForgeForms.slots(p) : [];
    if (slots.length) sections.push("<section><h4>Transformation</h4>" + slots.map((s) => "<p>⟳ " + h(s.linkedName || knownCardName(s.targetId) || "Another form") + "</p>").join("") + "</section>");
    const links = Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]).filter(Boolean).map((id) => ((state.links || []).find((l) => l.id === id) || {}).name).filter(Boolean);
    sections.push('<section><h4>Link Skills <small>' + links.length + '/7</small></h4><div class="bld-chips">' + (links.length ? links.map((n) => '<span class="bld-chip">' + h(n) + "</span>").join("") : '<span class="muted">None yet</span>') + "</div></section>");
    const cats = (p.tables.card_card_categories || []).map((r) => names().category(r.card_category_id)).filter(Boolean);
    sections.push('<section><h4>Categories <small>' + cats.length + '</small></h4><div class="bld-chips">' + (cats.length ? cats.map((n) => '<span class="bld-chip">' + h(n) + "</span>").join("") : '<span class="muted">None yet</span>') + "</div></section>");
    if (window.ForgeRarityBadge) ForgeRarityBadge.remember(p);
    return '<div class="bld-card t' + parts.type + '">' + (p.levelPerk && p.levelPerk.boost ? '<div class="bld-godly-ribbon' + (p.levelPerk.lv === 180 ? " bld-super" : "") + '" title="Applied in battle, after every other boost">✦ ' + (p.levelPerk.lv === 180 ? "Super" : "Godly") +  ' Exclusive · ATK &amp; DEF +' + p.levelPerk.boost + '% · ' + p.levelPerk.boost + '% damage reduction</div>' : "") + '<div class="bld-card-face"><div class="bld-card-badges">' + (window.ForgeRarityBadge && ForgeRarityBadge.iconFor(p) ? '<span class="bld-rarity has-rb">' + ForgeRarityBadge.html(ForgeRarityBadge.iconFor(p), "big") + "</span>" : '<span class="bld-rarity">' + h(["N", "R", "SR", "SSR", "UR", "LR"][c.rarity] || "?") + "</span>") + '<span class="bld-type">' + h((B.CLASSES[parts.cls] ? B.CLASSES[parts.cls] + " " : "") + type) + '</span>' + (p.awaken ? '<span class="bld-eza-badge">' + (p.awaken.kind === "seza" ? "SUPER EZA" : "EZA") + "</span>" : "") + '</div><div class="bld-card-art"><span class="bld-card-initial">' + h(String(c.name || "?").trim().charAt(0)) + '</span><img src="' + h(artUrl()) + '" alt="" loading="lazy"></div><h3 class="bld-card-name">' + h(c.name) + '</h3><div class="bld-card-stats"><div><span>HP</span><strong>' + number(c.hp_max) + "</strong></div><div><span>ATK</span><strong>" + number(c.atk_max) + "</strong></div><div><span>DEF</span><strong>" + number(c.def_max) + "</strong></div><div><span>COST</span><strong>" + h(c.cost) + '</strong></div></div></div><div class="bld-card-details' + (ui.cardOpen ? " open" : "") + '">' + sections.join("") + '</div><button type="button" class="bld-card-toggle" data-b="card-toggle">' + (ui.cardOpen ? "Hide card details ▴" : "Show card details ▾") + "</button></div>";
  }
  // The live card is redrawn at most once per frame, only when its content really changed, and
  // the card art <img> is kept so the picture is not reloaded on every keystroke.
  let cardFrame = 0;
  function refreshCard() {
    if (cardFrame) return;
    cardFrame = requestAnimationFrame(() => { cardFrame = 0; paintCard(); });
  }
  function paintPdescPreviews() {
    document.querySelectorAll("[data-pdesc-preview]").forEach((node) => {
      const set = (state.project.tables.passive_skill_sets || []).find((x) => x.id === Number(node.dataset.pdescPreview)), box = node.querySelector(".bld-itemized");
      const area = document.querySelector('[data-manual="passive:' + node.dataset.pdescPreview + '"]');
      if (set && box) { const html = itemized(area ? area.value : set.itemized_description || ""); if (box.innerHTML !== html) box.innerHTML = html; }
    });
  }
  function paintCard() {
    queueAutoWrite();   // abilities copied in by any tool get their description written too
    paintPdescPreviews();
    if (!state.project) return;
    const el = document.getElementById("bld-card");
    if (el) {
      const html = cardHTML();
      if (el.__forgeHTML !== html) {
        const oldImg = el.querySelector(".bld-card-art img");
        el.innerHTML = html;
        el.__forgeHTML = html;
        const newImg = el.querySelector(".bld-card-art img");
        if (oldImg && newImg && oldImg.getAttribute("src") === newImg.getAttribute("src")) newImg.replaceWith(oldImg);
      }
    }
    const progress = document.querySelector("#bld .db-progress");
    if (progress) {
      const html = dbProgress();
      if (progress.__forgeHTML !== html) {
        const box = document.createElement("div");
        box.innerHTML = html;
        const next = box.firstElementChild;
        if (next) { next.__forgeHTML = html; progress.replaceWith(next); }
      }
    }
  }

  // ------------------------------------------------------------ shared controls
  function fieldInputs(fields, values, prefix = "v.") {
    return fields.map((f) => f.kind === "choice"
      ? '<label class="field">' + h(f.label) + '<select data-bf="' + prefix + f.name + '">' + selection(f.options, values[f.name]) +
        // a value that isn't in the list (e.g. an animation picked from another move) stays as it is
        (f.keepUnknown && !f.options.some(([v]) => String(v) === String(values[f.name])) ? '<option value="' + h(values[f.name]) + '" data-cur selected>Current</option>' : "") + "</select></label>"
      : '<label class="field">' + h(f.label) + '<input type="number" inputmode="numeric" step="1" data-bf="' + prefix + f.name + '" min="' + f.min + '" max="' + f.max + '" value="' + h(values[f.name]) + '"></label>').join("");
  }
  function readEditor(el) {
    const out = { v: {}, s: {} };
    el.querySelectorAll("[data-bf]").forEach((input) => {
      const [group, name] = input.dataset.bf.split(".");
      out[group] = out[group] || {};
      out[group][name] = input.type === "checkbox" ? input.checked : input.value === "" ? undefined : Number(input.value);
    });
    return out;
  }
  function categoryOptionsList() {
    return (state.categories || []).filter((r) => r.name && r.name !== "0").slice().sort((a, b) => a.name.localeCompare(b.name)).map((r) => [r.id, r.name]);
  }
  function conditionEditor(kind, id, row, { advanced = false } = {}) {
    const info = condInfo(row);
    let body;
    if (info.pending) body = hint("Reading this ability's conditions…");
    else if (info.custom) body = '<p class="bld-cond-custom"><strong>Uses advanced game rules:</strong> ' + h(info.text) + "</p>" + hint("These rules are kept exactly as they are. You can start over with simple conditions instead.") + btn("Start over with simple conditions", "cond-reset:" + kind + ":" + id, "subtle small");
    else {
      const items = info.spec ? info.spec.items : [];
      body = (items.length ? items.map((item, i) => {
        const def = B.conditionDef(item.key), values = item.values;
        const inputs = def.fields.map((f) => f.kind === "nameSet" && window.ForgeNameSets ? ForgeNameSets.fieldHTML(f, values[f.name], h, selection) : f.kind === "category"
          ? '<label class="field">' + h(f.label) + '<select data-cf="' + f.name + '">' + selection(categoryOptionsList(), values[f.name]) + "</select></label>"
          : f.kind === "choice" ? '<label class="field">' + h(f.label) + '<select data-cf="' + f.name + '">' + selection(f.options, values[f.name]) + "</select></label>"
          : '<label class="field">' + h(f.label) + '<input type="number" inputmode="numeric" step="1" data-cf="' + f.name + '" min="' + f.min + '" max="' + f.max + '" value="' + h(values[f.name]) + '"></label>').join("");
        return '<div class="bld-rule" data-rule="' + i + '" data-key="' + h(item.key) + '"><div class="bld-rule-head"><strong>' + h(def.label) + '</strong><button type="button" class="icon-button" data-b="cond-del:' + kind + ":" + id + ":" + i + '" aria-label="Remove this condition">×</button></div>' + (inputs ? '<div class="field-grid">' + inputs + "</div>" : "") + "</div>";
      }).join("") : '<p class="bld-always">Always active — no conditions.</p>') + (items.length > 1 ? '<label class="field bld-mode">These conditions must<select data-cmode>' + selection([["all", "ALL be true"], ["any", "ANY be true (at least one)"]], info.spec.mode) + "</select></label>" : "") + '<label class="field">Add a condition<select data-cadd><option value="">Choose a condition…</option>' + B.CONDITIONS.map((c) => '<option value="' + c.key + '">' + h(c.label) + "</option>").join("") + "</select></label>";
      if (info.text) body += '<p class="bld-cond-summary">Activates ' + h(info.text) + ".</p>";
    }
    const extra = advanced ? '<div class="row">' + guide("Advanced condition editor", "conditions:" + id, "subtle small") + guide("Copy conditions from a character", "copy-condition:" + id, "subtle small") + "</div>" : "";
    return '<div class="bld-cond" data-cond="' + kind + ":" + id + '"><h5>When does it activate?</h5>' + body + extra + "</div>";
  }
  function condRow(kind, id) {
    const p = state.project;
    if (kind === "passive") return (p.tables.passive_skills || []).find((r) => r.id === id);
    if (kind === "active") return (p.tables.active_skill_sets || []).find((r) => r.id === id);
    if (kind === "super") return (p.tables.card_specials || []).find((r) => r.id === id);
    return null;
  }
  function readConditions(box) {
    const items = [...box.querySelectorAll("[data-rule]")].map((ruleEl) => {
      const values = {};
      ruleEl.querySelectorAll("[data-cf]").forEach((input) => values[input.dataset.cf] = Number(input.value));
      return { key: ruleEl.dataset.key, values };
    });
    const mode = box.querySelector("[data-cmode]");
    return { mode: mode ? mode.value : "all", items };
  }
  function setConditions(kind, id, spec, soft = false, box = null) {
    commit((p) => B.applyCondition(p, state.info.schema, condRow(kind, id), spec), soft ? { render: false, box } : {});
    if (soft && box) {
      const cond = box.querySelector(".bld-cond-summary"), row = condRow(kind, id), text = row ? condInfo(row).text : "";
      if (cond) cond.textContent = "Activates " + text + ".";
    }
  }


  // ------------------------------------------------------------ Dragon Ball progress, tips & glossary
  const TAB_TIPS = {
    basics: "Give your fighter a name, rarity, class, type and stats. LR is the top rarity.",
    leader: "When this card leads your team, these bonuses power up your whole team.",
    passive: "Passive Skill = abilities that work by themselves in every battle.",
    supers: "Super Attacks fire at 12+ Ki; Ultra Super Attacks fire at 18+ Ki (LR).",
    active: "A big move the player can tap during battle once its conditions are met.",
    transform: "Let your unit power up into a new form mid-battle — like going Super Saiyan!",
    links: "Link Skills boost allies fighting next to each other. Categories decide which teams this unit joins.",
    look: "Card art and aura — your own art, AI-made art, custom in-game artwork and battle poses.",
    appearance: "Portrait = the card art and thumbnail. Battle sprite = the fighter you see in battle. Battle motion = how it moves when it attacks.",
    save: "Send your unit to Dokkan Eclipse or Dokkan Sparking, then test its artwork, moves and battle mechanics.",
    eza: "Extreme Z-Awakening powers up an existing card in steps 1–7. Super EZA adds step 8."
  };
  function tabTip(t) { return TAB_TIPS[t] ? '<p class="bld-tip"><span>💡</span>' + h(TAB_TIPS[t]) + ' <button type="button" class="text-button" data-b="glossary">What do these words mean?</button></p>' : ""; }
  function glossary() {
    const terms = [["Ki", "Energy that fills up during a turn. 12+ Ki fires a Super Attack, 18+ Ki an Ultra Super Attack."], ["Ki Sphere", "The colored orbs you collect each turn. They give Ki; some abilities boost stats per sphere."], ["Rarity", "N, R, SR, SSR, UR/TUR and LR. LR is the strongest and can have an Ultra Super Attack."], ["Class & Type", "Super (heroes) or Extreme (villains), plus AGL, TEQ, INT, STR or PHY. AGL > STR > PHY > INT > TEQ > AGL."], ["Leader Skill", "Bonuses for the whole team when this card is the leader, e.g. \"Saiyans\" Category Ki +3 and HP, ATK & DEF +170%."], ["Passive Skill", "Abilities that work automatically, like ATK & DEF +200% or 30% chance to evade."], ["Category", "A group like \"Pure Saiyans\" or \"Fusion\". Leader skills and team bonuses use categories."], ["Link Skill", "A bonus that activates when two allies next to each other share the same link."], ["Active Skill", "A once-per-battle move the player taps when its conditions are met."], ["Damage reduction", "Lowers the damage this unit takes. 40% reduction = takes 60% of the damage."], ["Guard", "Reduces damage, especially against attacks the unit is weak to."], ["Critical hit", "A hit that ignores the enemy's DEF and type advantage for huge damage."], ["Additional attack", "An extra attack after the normal one; it can become a Super Attack."], ["Stacking", "\"Rest of the battle\" boosts from Super Attacks add up every time they fire."], ["EZA / Super EZA", "Extreme Z-Awakening raises a card's level cap and upgrades its skills in 7 steps. Super EZA adds an 8th, even stronger step."]];
    dialog("Dokkan words, explained", '<dl class="bld-glossary">' + terms.map(([t, d]) => "<dt>" + h(t) + "</dt><dd>" + h(d) + "</dd>").join("") + "</dl>");
  }
  function dbProgress() {
    const p = state.project, c = Forge.card(p), done = [];
    if (p.awaken) {
      const growth = p.tables.optimal_awakening_growths || [], local = (rows) => rows.some((r) => Number(r.id) < 0);
      done.push(growth.length >= 7, local(p.tables.leader_skills || []), local(p.tables.passive_skills || []), local(p.tables.card_specials || []), (p.tables.card_awakening_routes || []).length >= growth.length, growth.length >= 8, !!p.lastExportAt);
    } else {
      const lset = (p.tables.leader_skill_sets || []).find((r) => r.id === c.leader_skill_set_id);
      const links = Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]).filter(Boolean).length;
      done.push(!!String(c.name || "").trim(), !!(lset && (p.tables.leader_skills || []).some((r) => r.leader_skill_set_id === lset.id && Number(r.efficacy_type) !== 0)), (Forge.primaryPassive(p) ? (p.tables.passive_skill_set_relations || []).some((r) => r.passive_skill_set_id === Forge.primaryPassive(p).id) : false), (p.tables.card_specials || []).length > 0, links > 0 && (p.tables.card_card_categories || []).length > 0, !!(p.artBinding || p.previewKey || (p.uiLabels && p.uiLabels.art)), !!p.lastExportAt);
    }
    const labels = p.awaken ? ["EZA steps", "EZA leader", "EZA passive", "EZA Super Attack", "Awakening medals", "Super EZA (optional)", "Saved for Eclipse"] : ["Name", "Leader Skill", "Passive Skill", "Super Attacks", "Links & Categories", "Card art (optional)", "Saved for Eclipse"];
    const count = done.filter(Boolean).length;
    return '<div class="db-progress" title="Collect all 7 Dragon Balls by preparing each part of your unit"><span class="db-balls">' + done.map((ok, i) => '<span class="db-ball s' + (i + 1) + (ok ? " lit" : "") + '" title="' + h(labels[i] + (ok ? " ✓" : "")) + '"></span>').join("") + '</span><span class="db-count">' + (count === 7 ? "All 7 Dragon Balls! Design prepared — test it in Eclipse or Sparking." : count + " / 7 Dragon Balls · next: " + h(labels[done.findIndex((x) => !x)])) + "</span></div>";
  }

  // ------------------------------------------------------------ EZA overview
  function ezaHTML() {
    const p = state.project, a = p.awaken, growth = (p.tables.optimal_awakening_growths || []).slice().sort((x, y) => x.step - y.step);
    const setName = (table, id) => ((p.tables[table] || []).find((r) => r.id === id) || {}).name || "—";
    const rows = growth.map((g) => "<tr><td>" + (g.step >= 8 ? "★ " : "") + g.step + '</td><td><input type="number" inputmode="numeric" min="1" max="200" data-bind="table:optimal_awakening_growths:' + g.id + ':lv_max" value="' + h(g.lv_max) + '" aria-label="Level cap"></td><td><input type="number" inputmode="numeric" min="1" max="30" data-bind="table:optimal_awakening_growths:' + g.id + ':skill_lv_max" value="' + h(g.skill_lv_max) + '" aria-label="Super Attack level cap"></td><td>' + h(setName("leader_skill_sets", g.leader_skill_set_id)) + "</td><td>" + h(setName("passive_skill_sets", g.passive_skill_set_id)) + "</td></tr>").join("");
    const canSeza = growth.length === 7;
    return '<section class="panel bld-eza-hero"><div class="guide-source"><img src="' + h(artUrl()) + '" alt=""><div><strong>' + h(a.kind === "seza" ? "Super EZA" : "EZA") + " for " + h(Forge.card(p).name) + "</strong><p>This adds Extreme Z-Awakening to the real game card #" + h(a.cardId) + ". It's the only kind of creation that changes an existing card: everything you add uses new IDs, and the card itself only gets its awakening steps.</p></div></div></section>" + '<section class="panel"><h2>Awakening steps</h2>' + hint("Each step raises the level cap and Super Attack level. Change the skills for each step on the Leader Skill and Passive Skill tabs.") + '<div class="bld-table-wrap"><table class="bld-table"><thead><tr><th>Step</th><th>Level cap</th><th>SA level cap</th><th>Leader Skill</th><th>Passive Skill</th></tr></thead><tbody>' + rows + "</tbody></table></div>" + (canSeza ? '<div class="row">' + btn("★ Add a Super EZA (step 8)", "eza-seza", "button") + "</div>" : "") + '</section><section class="panel"><h2>Awakening Medals</h2><p>' + h(a.medalName ? "New steps use " + a.medalName + "'s awakening medals." : "Steps that already exist in the game keep their own medals.") + "</p>" + hint("In Dokkan, each EZA step costs Awakening Medals. Pick a card whose EZA medals you can get in Eclipse.") + btn("Use another card's EZA medals", "eza-medals", "ghost") + "</section>";
  }
  async function medalsFrom(cardId) {
    const routes = (await Native.call("query", { table: "card_awakening_routes", filters: { card_id: Number(cardId) }, limit: 100 })).filter((r) => r.type === "CardAwakeningRoute::Optimal");
    const medals = {};
    for (const r of routes) medals[r.optimal_awakening_step] = r.card_awakening_set_id;
    return medals;
  }
  // EZA / Super EZA for one of YOUR units: opens it and adds the steps (or just opens its EZA if it has one)
  async function startAwakenOwn(kind, key) {
    await openUnit(key);
    const p = state.project;
    if (!p) return;
    const growth = (p.tables.optimal_awakening_growths || []).length;
    if (kind === "seza" && growth < 7) throw new Error("Give " + Forge.card(p).name + " an EZA first, then a Super EZA.");
    const has = kind === "eza" ? growth >= 7 : growth >= 8;
    if (!has) {
      const medals = await medalsFrom(1003211);
      if (kind === "seza" && !medals[8]) medals[8] = medals[7];
      commit(() => B.setupAwaken(p, state.info.schema, { kind, existingRoutes: [], medals, medalName: "Super Saiyan 3 Goku" }));
    }
    state.builderTab = "eza";
    renderEditor();
    window.scrollTo(0, 0);
    toast(has ? "This unit already has " + (kind === "seza" ? "a Super EZA" : "an EZA") + " — edit it here." : (kind === "seza" ? "Super EZA step added." : "EZA added.") + " Edit each step's skills on the Leader and Passive tabs.");
  }
  async function startAwaken(kind) {
    await loadPending().catch(() => {});
    return ForgeGuideUI.pickUnit(kind === "seza" ? "Which EZA card gets a Super EZA?" : "Which card do you want to awaken?", (picked) => busy(kind === "seza" ? "Preparing the Super EZA" : "Preparing the EZA", async () => {
      await flushSave();
      // EZA belongs on the playable card (ID ending in 1), not its base record (ending in 0).
      let card = picked;
      if (Number(card.id) % 10 === 0) { const playable = (await Native.call("query", { table: "cards", ids: [Number(card.id) + 1], limit: 1 }))[0]; if (playable) card = playable; }
      const p = await Forge.loadTemplate((o) => Native.call("query", o), state.info.schema, card.id, Forge.SLOT_FLOOR);
      const existing = await Native.call("query", { table: "card_awakening_routes", filters: { card_id: card.id }, limit: 100 });
      const growth = p.tables.optimal_awakening_growths || [];
      if (kind === "seza" && growth.length < 7) throw new Error(card.name + " has no EZA in the game yet. Choose “EZA” first.");
      let medals = {}, medalName = "";
      if (growth.length >= 7) { medals = await medalsFrom(card.id); if (kind === "seza" && !medals[8]) medals[8] = medals[7]; medalName = card.name; }
      else { medals = await medalsFrom(1003211); medalName = "Super Saiyan 3 Goku"; }
      B.setupAwaken(p, state.info.schema, { kind, existingRoutes: existing, medals, medalName });
      const projects = await Native.call("projects");
      await G.allocateId(p, (o) => Native.call("query", o), projects);
      state.project = p;
      state.previewUrl = "";
      state.builderTab = "eza";
      if (window.ForgeGuideUI && ForgeGuideUI.resetHistory) ForgeGuideUI.resetHistory();
      await flushSave();
      state.view = "editor";
      updateNav();
      renderEditor();
      window.scrollTo(0, 0);
      toast(kind === "seza" ? "Super EZA step added. Edit its passive on the Passive Skill tab." : "EZA created. Edit each step's skills on the Leader and Passive tabs.");
    }));
  }

  // ------------------------------------------------------------ tabs: basics
  // Rarity, class and type. When they were already picked in Quick Create, show them as one line
  // (with a "Change" link that opens the pickers) instead of asking again.
  function identityHTML(p, c, parts, rarity, cls, types) {
    const pickers = '<h3>Rarity</h3><div class="bld-pills">' + rarity + "</div>" + hint("LR and UR are the top rarities. Rarity changes the card frame and badge; levels below stay as you set them.") + '<h3>Class</h3><div class="bld-pills">' + cls + '</div><h3>Type</h3><div class="bld-pills">' + types + "</div>" + hint("AGL beats STR, STR beats PHY, PHY beats INT, INT beats TEQ, TEQ beats AGL.");
    if (!p.quickCreated) return pickers;
    const summary = (window.ForgeRarityBadge ? ForgeRarityBadge.label(p, Forge.rarities[c.rarity] || "") : Forge.rarities[c.rarity] || "") + " · " + ([, "Super", "Extreme"][parts.cls] || "") + " " + (B.TYPES[parts.type] || "");
    return '<details class="bld-identity"' + (state.identityOpen ? " open" : "") + '><summary><span class="bld-identity-label">Rarity, class &amp; type</span> <strong>' + h(summary) + '</strong> <span class="bld-identity-change">Change</span></summary>' + pickers + "</details>";
  }
  function basicsHTML() {
    const p = state.project, c = Forge.card(p), parts = B.elementParts(c.element);
    const rarity = Forge.rarities.map((r, i) => '<button type="button" class="bld-pill' + (Number(c.rarity) === i ? " on" : "") + '" data-b="rarity:' + i + '">' + h(r) + "</button>").join("");
    const cls = [[1, "Super", "Heroes and allies"], [2, "Extreme", "Villains and rivals"]].map(([v, n, d]) => '<button type="button" class="bld-pill wide' + (parts.cls === v ? " on" : "") + '" data-b="class:' + v + '"><strong>' + n + "</strong><small>" + d + "</small></button>").join("");
    const types = B.TYPES.map((t, i) => '<button type="button" class="bld-type-pill' + (parts.type === i ? " on" : "") + ' t' + i + '" data-b="type:' + i + '">' + t + "</button>").join("");
    const statField = (s, label) => '<label class="field">' + label + '<input type="number" inputmode="numeric" min="1" max="999999" step="1" data-bind="card:' + s + '_max" value="' + h(c[s + "_max"]) + '"></label>';
    return '<section class="panel"><h2>Name & identity</h2><label class="field">Character name<input data-bind="card:name" value="' + h(c.name) + '" maxlength="80" required></label><div class="guide-source"><img src="' + h(artUrl()) + '" alt=""><div><strong>Started from ' + h(p.source.name) + "</strong><p>Its artwork, animations and any abilities you keep come from this character. Everything here can be changed.</p></div></div>" + identityHTML(p, c, parts, rarity, cls, types) + '</section><section class="panel"><h2>Stats</h2>' + hint("Maximum-level stats before Hidden Potential and battle boosts. Quick presets start from the original character.") + '<div class="row">' + guide("Original stats", "stats:source") + guide("Balanced (+15%)", "stats:balanced") + guide("Attacker", "stats:attack") + guide("Defender", "stats:defense") + '</div><div class="field-grid three">' + statField("hp", "HP") + statField("atk", "ATK") + statField("def", "DEF") + '</div><details><summary>Level, cost and starting stats</summary><div class="field-grid">' + field("Team cost", "card:cost", c.cost, "number", "How much of a team's cost limit this card uses.", 'min="1" max="999"') + select("Maximum level", "card:lv_max", c.lv_max, [[60, "Level 60"], [80, "Level 80"], [100, "Level 100"], [120, "Level 120"], [140, "Level 140 (EZA)"], [150, "Level 150 (LR)"], [180, "Level 180"], [200, "Level 200"]]) + select("Super Attack level cap", "card:skill_lv_max", c.skill_lv_max, [[10, "SA level 10"], [15, "SA level 15"], [20, "SA level 20"], [25, "SA level 25"], [30, "SA level 30"]]) + ["hp", "atk", "def"].map((s) => field(s.toUpperCase() + " at level 1", "card:" + s + "_init", c[s + "_init"], "number", "", 'min="0" max="999999"')).join("") + "</div></details></section>";
  }

  // ------------------------------------------------------------ tabs: leader
  function leaderSignature() { return JSON.stringify(leaderRows().map((r) => [r.efficacy_type, r.target_type, r.sub_target_type_set_id, r.efficacy_values, r.calc_option, r.causality_conditions])); }
  function leaderDraft() {
    const set = leaderSet(), sig = (set ? set.id : "none") + leaderSignature();
    if (ui.leader && ui.leader.key === state.project.key && ui.leader.sig === sig) return ui.leader;
    const subs = [...(ui.subTargets || []), ...(state.project.tables.sub_target_types || [])];
    const decoded = B.decodeLeader(leaderRows(), subs);
    ui.leader = { key: state.project.key, sig, groups: decoded, decodedOk: !!decoded, open: null };
    return ui.leader;
  }
  function leaderGroupHTML(g, i, count) {
    const who = '<label class="field">Who gets this bonus<select data-lg="' + i + '" data-lf="who">' + selection(B.LEADER_WHO, g.who) + "</select></label>";
    let pick = "";
    if (g.who === "types") pick = '<div class="bld-pills">' + B.TYPES.map((t, ti) => '<button type="button" class="bld-type-pill small' + (g.types.includes(ti) ? " on" : "") + ' t' + ti + '" data-b="lg-type:' + i + ":" + ti + '">' + t + "</button>").join("") + "</div>";
    if (g.who === "classTypes") pick = '<div class="bld-pills">' + B.CLASS_TYPE_OPTIONS.map(([m, n], k) => '<button type="button" class="bld-type-pill small' + (g.classTypes.includes(m) ? " on" : "") + ' t' + (k % 5) + '" data-b="lg-ct:' + i + ":" + m + '">' + h(n) + "</button>").join("") + "</div>";
    if (g.who === "categories") {
      const chips = (list, field) => list.map((id) => '<span class="bld-chip">' + h(names().category(id) || id) + '<button type="button" data-b="lg-cat-del:' + i + ":" + field + ":" + id + '" aria-label="Remove">×</button></span>').join("");
      const adder = (field, label) => '<div class="bld-cat-add"><input type="search" data-catfilter="' + i + ":" + field + '" placeholder="Search categories…" aria-label="Search categories"><select data-catpick="' + i + ":" + field + '" aria-label="' + h(label) + '">' + selection(categoryOptionsList(), "") + "</select>" + btn("Add", "lg-cat-add:" + i + ":" + field, "ghost small") + "</div>";
      pick = "<h5>Characters in any of these Categories</h5><div class=\"bld-chips\">" + (chips(g.categories, "categories") || '<span class="muted">Add at least one Category</span>') + "</div>" + adder("categories", "Category to add") + "<details" + (g.also.length ? " open" : "") + "><summary>Only if they also belong to… (optional)</summary>" + hint("Use this for bonus tiers like “plus an additional Ki +1 for characters who also belong to …”.") + '<div class="bld-chips">' + chips(g.also, "also") + "</div>" + adder("also", "Extra Category to require") + "</details>";
    }
    const even = g.hp === g.atk && g.atk === g.def;
    const stats = even && !(ui.leader.split && ui.leader.split[i]) ? '<label class="field">HP, ATK & DEF +%<input type="number" inputmode="numeric" min="0" max="1000" step="1" data-lg="' + i + '" data-lf="all" value="' + h(g.hp) + '"></label>' : ["hp", "atk", "def"].map((s) => '<label class="field">' + s.toUpperCase() + ' +%<input type="number" inputmode="numeric" min="0" max="1000" step="1" data-lg="' + i + '" data-lf="' + s + '" value="' + h(g[s]) + '"></label>').join("");
    return '<article class="bld-group"><div class="bld-group-head"><strong>' + (i ? "Extra bonus " + (i + 1) : "Main bonus") + "</strong>" + (count > 1 ? '<button type="button" class="icon-button" data-b="lg-del:' + i + '" aria-label="Remove this bonus">×</button>' : "") + "</div>" + who + pick + '<div class="field-grid three"><label class="field">Ki +<select data-lg="' + i + '" data-lf="ki">' + selection(Array.from({ length: 7 }, (_, k) => [k, k ? "Ki +" + k : "No Ki bonus"]), g.ki) + "</select></label>" + stats + "</div>" + (["types", "classTypes"].includes(g.who) ? "" : '<label class="bld-check"><input type="checkbox" data-b-split="' + i + '"' + (!even || (ui.leader.split && ui.leader.split[i]) ? " checked" : "") + "> Different values for HP, ATK and DEF</label>") + "</article>";
  }
  function leaderHTML() {
    if (stageLocked("leader")) { const set = leaderSet(); return stageBar("leader") + '<section class="panel"><h2>Original Leader Skill</h2><p>' + h(set ? set.description : "None") + "</p>" + hint("This is the card as it is in the game, so it stays unchanged. Pick an EZA step above to give it a new leader skill.") + "</section>"; }
    const set = leaderSet();
    if (!ui.subTargets) {
      ensureSubTargets().then(() => { if (state.view === "editor" && tab() === "leader") renderEditor(); }).catch(fail);
      return '<section class="panel"><h2>Leader Skill</h2><p role="status">Loading team targeting data…</p></section>';
    }
    const draft = leaderDraft();
    randomLeaderName(set);
    const text = set ? '<div class="field-grid">' + field("Leader Skill name", tableBind("leader_skill_sets", set, "name"), set.name, "text", "", 'maxlength="80"') + "</div>" + area("What the game shows", tableBind("leader_skill_sets", set, "description"), set.description, "") : "";
    let body;
    if (!draft.groups) body = '<div class="notice"><strong>This leader skill uses advanced rules</strong> (conditions or special effects) that the builder keeps exactly as they are.</div><div class="row">' + btn("Build a new leader skill instead", "leader-new", "button") + "</div>";
    else body = '<div class="bld-groups">' + draft.groups.map((g, i) => leaderGroupHTML(B.normalizeGroup(g), i, draft.groups.length)).join("") + '</div><div class="row">' + (draft.groups.length < 8 ? btn("＋ Add another bonus tier", "lg-add", "ghost") : "") + "</div>" + (draft.error ? '<p class="bld-warn" role="alert">' + h(draft.error) + "</p>" : "");
    return stageBar("leader") + '<section class="panel"><h2>Leader Skill</h2>' + hint("Bonuses this character gives the whole team when it is the leader. Choose who gets each bonus and how big it is — the game rules and wording are written for you.") + body + "</section>" + (set ? '<section class="panel"><h2>Name & description</h2>' + text + "</section>" : "") + presetLeaderHTML();
  }
  // A new leader skill starts with a random Dokkan-style name (🎲 next to the box picks another).
  function randomLeaderName(set) {
    const p = state.project;
    if (!set || !window.ForgeSkillNames) return;
    p.leaderNamed = p.leaderNamed || [];
    if (p.leaderNamed.includes(set.id)) return;
    p.leaderNamed.push(set.id);
    set.name = ForgeSkillNames.random("leader", set.name);
    scheduleSave();
  }
  function presetLeaderHTML() {
    const presets = [["All Types: Ki +3, HP, ATK & DEF +170%", "all-170"], ["Super Class: Ki +3, HP, ATK & DEF +200%", "super-200"], ["Extreme Class: Ki +3, HP, ATK & DEF +200%", "extreme-200"]];
    return '<section class="panel"><h2>Quick starts</h2>' + hint("Pick a typical leader skill, then adjust it above.") + '<div class="row">' + presets.map(([n, k]) => btn(n, "leader-preset:" + k, "subtle small")).join("") + "</div></section>";
  }
  function applyLeader(soft = false) {
    const d = ui.leader;
    try {
      const set = leaderSet(), wantText = auto("leader:" + (set && set.id), true);
      const built = B.buildLeader(target("leader"), state.info.schema, d.groups, { official: ui.subTargets, names: wantText ? names() : null, name: wantText && set && set.name ? set.name : undefined });
      if (wantText && (!set || !set.name || /Leadership$|^Custom leadership$/.test(set.name))) built.name = B.leaderName(d.groups, names());
      d.error = "";
      d.sig = built.id + leaderSignature();
      scheduleSave();
    } catch (e) { d.error = e.message; }
    if (soft) {
      syncTextareas(); refreshCard();
      const warn = document.querySelector("#bld .bld-warn");
      if (d.error) { if (warn) warn.textContent = d.error; else toast(d.error, true); } else if (warn) warn.remove();
      return;
    }
    renderEditor();
  }

  // ------------------------------------------------------------ tabs: passive
  const groupIcon = { "Stats": "▲", "Ki & Ki Spheres": "●", "Defense": "⛨", "Offense": "✸", "Enemy effects": "✖", "Team support": "♥", "Growth": "↗" };
  // Who gets a passive: the usual choices, plus allies in chosen Categories or with chosen names (the game's
  // "sub-target" lists: Category = type 1, name group = type 4; the ability targets the team and is limited to them)
  function subEntries(row) {
    const id = Number(row.sub_target_type_set_id);
    if (!id) return [];
    return [...(state.project.tables.sub_target_types || []), ...(ui.subTargets || [])].filter((r) => Number(r.sub_target_type_set_id) === id).map((r) => [Number(r.target_value_type), Number(r.target_value)]);
  }
  function whoMode(row) {
    const e = subEntries(row);
    if (e.length && e.every(([t]) => t === 1)) return "cat";
    if (e.length && e.every(([t]) => t === 4)) return "name";
    if (e.length) return "other";
    return (ui.whoMode || {})[row.id] || "";
  }
  function whoHTML(row, who, s, PF) {
    const mode = whoMode(row), canPick = who.includes(2);
    if (Number(row.sub_target_type_set_id) && !ui.subTargets) ensureSubTargets().then(() => renderEditor()).catch(() => {});
    const opts = targetOptions(who, s.target).map(([v, l]) => [v, PF.whoLabel(row, v) || l]);
    if (canPick) opts.push(["cat", "Allies in certain Categories…"], ["name", "Certain characters (by name)…"]);
    const cur = mode === "cat" || mode === "name" ? mode : s.target;
    let html = '<div class="field-grid"><label class="field full">Who<select data-bsel="who:' + row.id + '">' + selection(opts, cur) + "</select>" + (PF.whoHelp(row) && !mode ? '<small class="pf-help">' + h(PF.whoHelp(row)) + "</small>" : "") + "</label></div>";
    if (mode === "cat" || mode === "name") {
      const e = subEntries(row).filter(([t]) => t === (mode === "cat" ? 1 : 4));
      const nameOf = ([t, v]) => t === 1 ? (names().category(v) || "Category " + v) : ((window.ForgeNameSets && ForgeNameSets.label(v)) || "Character group " + v);
      html += '<div class="who-pick"><p class="pf-tip">' + (mode === "cat" ? "Only allies in <strong>any</strong> of these Categories get it." : "Only characters whose names include <strong>any</strong> of these get it.") + "</p>" +
        '<div class="who-chips">' + (e.length ? e.map((x, i) => '<span class="who-chip">' + h(nameOf(x)) + '<button type="button" class="icon-button" data-b="who-del:' + row.id + ":" + i + '" aria-label="Remove">×</button></span>').join("") : '<span class="hint">Nobody chosen yet — add ' + (mode === "cat" ? "a Category" : "a character") + " below.</span>") + "</div>";
      if (mode === "cat") html += '<label class="field">Add a Category<select data-bsel="who-cat:' + row.id + '"><option value="">Choose a Category…</option>' + selection(categoryOptionsList(), "") + "</select></label>";
      else if (window.ForgeNameSets) html += ForgeNameSets.fieldHTML({ label: "Add a character", name: "whoname" }, 0, h, selection).replace('data-cf="whoname"', 'data-whoname="' + row.id + '"');
      html += '<label class="bld-check"><input type="checkbox" data-bsel-num="who-self:' + row.id + '"' + (Number(row.target_type) !== 16 ? " checked" : "") + "> This character gets it too (if it matches)</label></div>";
    }
    return html;
  }
  function setWho(row, entries, target) {
    const p = state.project;
    if (target !== undefined) row.target_type = target;
    if (!entries || !entries.length) row.sub_target_type_set_id = 0;
    else {
      if (![2, 16].includes(Number(row.target_type))) row.target_type = 2;
      row.sub_target_type_set_id = B.findSubTargetSet(p, entries, ui.subTargets) || B.createSubTargetSet(p, state.info.schema, entries);
    }
    B.pruneSubTargets(p);
  }
  function targetOptions(allowed, current) {
    const list = allowed.map((t) => [t, B.TARGETS[t].label]);
    if (!allowed.includes(Number(current))) list.push([current, (B.TARGETS[current] || { label: "Original target" }).label + " (original)"]);
    return list;
  }
  // The GR level perk: one locked card at the top (its two game rows are ATK "during the attack" and DEF "just
  // before receiving an attack" — the game's multiplicative stages, so it multiplies the finished stats).
  function godlyCardHTML(rows) {
    const g = rows.filter((r) => /Exclusive$/.test(r.name || ""));
    if (!g.length) return "";
    const atk = g.find((r) => Number(r.efficacy_type) === 1), def = g.find((r) => Number(r.efficacy_type) === 2);
    const dr = g.find((r) => Number(r.efficacy_type) === 13), drv = dr ? 100 - Number(dr.eff_value1) : 0;
    const v = atk ? Number(atk.eff_value1) : def ? Number(def.eff_value1) : 0, slr = /^Super/.test(g[0].name || "");
    return '<article class="bld-ability bld-godly' + (slr ? " bld-super" : "") + '"><div class="bld-ability-head"><span class="bld-icon">✦</span><div><span class="bld-when">' + h(g[0].name) + " · permanent · comes with " + (slr ? "level 180 (SLR)" : "level 200 (GR)") + '</span><strong>ATK &amp; DEF +' + v + '%, applied after every other boost' + (drv ? ' · reduces damage received by ' + drv + '%' : '') + '</strong>' +
      '<small class="bld-godly-how">Like an Active Skill boost, it comes last: leader, links, Ki, Super Attack and the rest of this passive first, then ×' + (1 + v / 100).toFixed(2) + ' ATK when attacking and ×' + (1 + v / 100).toFixed(2) + ' DEF when hit' + (drv ? ', and ' + drv + '% less damage taken' : '') + '. It can\'t be removed or changed.</small></div><span class="bld-godly-lock" title="Part of the ' + (slr ? "SLR" : "GR") + ' rarity. Change the level to remove it.">🔒</span></div></article>';
  }
  // Abilities without a friendly editor: their game values, labelled from the game's own list.
  function rawValuesHTML(row) {
    const C = window.ForgePassiveCatalog, e = C && C.entryFor(row), names = (e && e.values) || [];
    const inputs = [1, 2, 3].map((n) => [n, String(names[n - 1] || "").trim()]).filter(([n, label]) => (label || Number(row["eff_value" + n])) && !/^always\b|should always/i.test(label))
      .map(([n, label]) => { const m = /^([^(]*?)\s*\((.*)\)\s*$/.exec(label), name = m ? m[1] : label, legend = m ? m[2] : ""; return '<label class="field">' + h(name || "Value " + n) + (legend ? "<small>" + h(legend) + "</small>" : "") + '<input type="number" inputmode="numeric" step="1" data-bind="table:passive_skills:' + row.id + ":eff_value" + n + '" value="' + h(row["eff_value" + n]) + '"></label>'; }).join("");
    return (e ? hint(e.about || e.label) : "") + (inputs ? '<div class="field-grid bld-raw">' + inputs + "</div>" : hint("This ability has no amount to set. You can still change when, who, how long and conditions."));
  }
  function passiveCardHTML(row) {
    const decoded = B.decodePassive(row), def = decoded && B.passiveDef(decoded.key), s = B.settingsOf(row), info = condInfo(row), open = ui.open === "passive:" + row.id;
    const when = B.passiveHeading(row, info.text);
    const title = B.passiveLine(row, lineExtra(row));
    let editor = "";
    if (open) {
      if (Number(row.efficacy_type) === 103) editor = hint("This is a transformation.") + conditionEditor("passive", row.id, row, { advanced: true }) + btn("Go to Transformations", "tab:transform", "ghost small");
      else if (window.ForgePassiveFamilies && ForgePassiveFamilies.classify(row)) editor = familyEditorHTML(row, decoded, def, s, info, when, title);
      else {
        const settings = '<div class="field-grid">' + (def && (def.timing || def.stack) ? "" : '<label class="field">When<select data-bf="s.timing">' + selection(B.TIMINGS.map(([v, n]) => [v, n]).concat(B.TIMINGS.some(([v]) => v === s.timing) ? [] : [[s.timing, "Keep original timing"]]), s.timing) + "</select></label>") + '<label class="field">Who<select data-bf="s.target">' + selection(targetOptions(def ? B.allowedTargets(def) : Object.keys(B.TARGETS).map(Number), s.target), s.target) + "</select></label>" + (def && def.stack ? "" : '<label class="field">How long<select data-bf="s.turn">' + selection(B.DURATIONS.concat(B.DURATIONS.some(([v]) => v === s.turn) ? [] : [[s.turn, s.turn + " turns (original)"]]), s.turn) + "</select></label>") + '<label class="field">Chance to activate %<input type="number" inputmode="numeric" min="1" max="100" step="1" data-bf="s.chance" value="' + h(s.chance) + '"></label></div><label class="bld-check"><input type="checkbox" data-bf="s.once"' + (s.once ? " checked" : "") + "> Only once per battle</label>";
        const animKey = [120, 128].includes(Number(row.efficacy_type)) ? "counter:" + row.id : "";
        const PFx = window.ForgePassiveFamilies, vals = decoded ? (def.fields.length ? '<div class="field-grid">' + fieldInputs(def.fields, B.normalizeValues(def.fields, decoded.values)) + "</div>" : "") : rawValuesHTML(row);
        editor += (animKey && PFx && PFx.postFieldsHTML ? PFx.postFieldsHTML(vals, row) : vals) + settings + conditionEditor("passive", row.id, row, { advanced: true });
      }
    }
    const famIcon = window.ForgePassiveFamilies ? ForgePassiveFamilies.iconFor(row) : "";
    return '<article class="bld-ability' + (open ? " open" : "") + '" data-edit="passive:' + row.id + '"><div class="bld-ability-head"><span class="bld-icon">' + h(famIcon ? famIcon : def ? groupIcon[def.group] || "✦" : Number(row.efficacy_type) === 103 ? "⟳" : "◇") + '</span><div><span class="bld-when">' + h(when) + "</span><strong>" + h(title) + '</strong></div><div class="bld-ability-actions">' + btn(open ? "Done" : "Edit", "open:passive:" + row.id) + '<button type="button" class="icon-button" data-b="passive-del:' + row.id + '" aria-label="Remove this ability">×</button></div></div>' + (open ? '<div class="bld-editor">' + editor + "</div>" : "") + "</article>";
  }
  // Every passive ability edits the same way: what it does → who → when & how often → requirements, with a plain
  // summary on top and every raw game value under "Advanced". (Family/kind/growth live in passive-families.js.)
  const TIMING_HELP = { 1: "Checked at the start of every turn — the usual choice for boosts that are simply “on”.", 11: "Just before this character attacks.", 4: "While this character is attacking (applies to that attack).", 5: "When this character's attack lands.", 6: "When an enemy attacks this character.", 7: "Right after being hit.", 14: "After this character defeats an enemy.", 15: "After this character collects Ki Spheres.", 9: "At the end of the turn." };
  function familyEditorHTML(row, decoded, def, s, info, when, title) {
    const PF = window.ForgePassiveFamilies;
    const sec = (head, body, tip) => body ? '<section class="pf-sec"><h4>' + h(head) + "</h4>" + (tip ? '<p class="pf-tip">' + h(tip) + "</p>" : "") + body + "</section>" : "";
    const amounts = decoded ? (def.fields.length ? '<div class="field-grid">' + fieldInputs(def.fields.filter((f) => !(def.stack && f.name === "stat")).map((f) => f.name === "trigger" ? Object.assign({}, f, { label: "What makes it grow" }) : f), B.normalizeValues(def.fields, decoded.values)) + "</div>" : "") : (PF.valuesHTML(row) || '<p class="pf-nothing">✓ Nothing else to set — this ability just switches on. Choose who gets it and when below.</p>');
    const who = decoded ? B.allowedTargets(def) : (PF.targetsFor(row) || Object.keys(B.TARGETS).map(Number));
    const fixedTiming = def && (def.timing || def.stack);   // stacking picks what makes it grow in its own setting
    // some abilities only make sense at a few moments (e.g. stunning: when its attack hits, when it's attacked…)
    const whenList = def && def.timings ? def.timings.map((v) => B.TIMINGS.find(([t]) => t === v)).filter(Boolean) : B.TIMINGS;
    const timing = fixedTiming ? "" : '<label class="field">When<select data-bf="s.timing">' + selection(whenList.map(([v, n]) => [v, n]).concat(whenList.some(([v]) => v === s.timing) ? [] : [[s.timing, "Keep original timing"]]), s.timing) + '</select><small class="pf-help">' + h(TIMING_HELP[s.timing] || "") + "</small></label>";
    const lasts = def && def.stack ? "" : '<label class="field">How long it lasts<select data-bf="s.turn">' + selection(B.DURATIONS.concat(B.DURATIONS.some(([v]) => v === s.turn) ? [] : [[s.turn, s.turn + " turns (original)"]]), s.turn) + '</select><small class="pf-help">“Rest of the battle” keeps it on once it has happened.</small></label>';
    const chance = '<label class="field">Chance to activate<span class="pf-range"><input type="range" min="1" max="100" step="1" data-bf="s.chance" value="' + h(s.chance) + '" style="--p:' + h(s.chance) + '%"><b class="pf-range-val">' + h(s.chance) + '%</b></span><span class="pf-quick" role="group" aria-label="Quick chance">' + [25, 50, 70, 100].map((v) => '<button type="button" class="pf-quick-btn' + (Number(s.chance) === v ? " on" : "") + '" data-pf-chance="' + v + '">' + v + "%</button>").join("") + '</span><small class="pf-help">100% means it always happens when its requirements are met. Tap a number or drag the slider.</small></label>';
    const often = '<label class="field">How often<select data-bf="s.once">' + selection([[0, "Every time it's triggered"], [1, "Only once per battle"]], s.once ? 1 : 0) + "</select></label>";
    const animKey = [120, 128].includes(Number(row.efficacy_type)) ? "counter:" + row.id : "";
    return PF.summaryHTML(row, when, title, info.text) +
      sec("What it does", (PF.aboutFor(row) ? '<p class="pf-tip">' + h(PF.aboutFor(row)) + "</p>" : "") + PF.whatHTML(row) + (PF.postFieldsHTML ? PF.postFieldsHTML(amounts, row) : amounts) + "") +
      sec("Who gets it", whoHTML(row, who, s, PF)) +
      sec("When & how often", '<div class="field-grid">' + timing + lasts + chance + often + "</div>") +
      sec("Requirements & restrictions", conditionEditor("passive", row.id, row, { advanced: true }), "Requirements: add conditions that must be true (HP, turn, attacks performed, allies on the team…). Restrictions: open the Advanced condition editor and use NOT to block it in some situations.") +
      PF.toolsHTML(row) + PF.advancedHTML(row);
  }
  function passivePickerHTML() {
    return '<section class="panel bld-picker"><div class="bld-group-head"><h2>Add an ability</h2>' + btn("Close", "adding:off") + "</div>" + B.PASSIVE_GROUPS.map((g) => "<h3>" + h(groupIcon[g] + " " + g) + '</h3><div class="bld-picks">' + B.PASSIVE.filter((e) => e.group === g && e.key !== "revive").map((e) => btn(e.label, "passive-add:" + e.key, "bld-pick")).join("") + "</div>").join("") + '<h3>⚙ Special abilities</h3><div class="bld-picks">' + guide("Counterattack", "add-counter", "bld-pick") + guide("Bonus per matching-color Ki Sphere", "add-color-sphere-bonus", "bld-pick") + btn("Transformation", "tab:transform", "bld-pick") + guide("Copy a whole passive from a character", "copy:passive", "bld-pick") + "</div></section>";
  }
  function introNoticeHTML() {
    const I = window.ForgeIntro, c = I && I.carrier();
    if (!c) return "";
    const n = I.bonuses().length;
    return '<div class="notice intro-note"><strong>🎬 This character has an intro</strong> — ' + h(I.sceneName(c.passive_skill_effect_id)) + ". " + (n ? n + " bonus" + (n === 1 ? "" : "es") + " activate with it (listed under “Activates the Entrance Animation” in the description)." : "No bonuses yet — it is just for show.") + " " + btn("Set up the intro", "tab:intro", "ghost small") + "</div>";
  }
  function ezaNotice() {
    if (state.project.awaken || stageKey("passive") !== "base" || !(state.project.tables.optimal_awakening_growths || []).length) return "";
    return '<div class="notice">This character has Extreme Z-Awakening stages with their own abilities. The builder edits the abilities used <strong>before</strong> EZA. ' + guide("Use these for every EZA stage too", "match-eza", "ghost small") + "</div>";
  }
  // Abilities that do the same thing at the same moment add up in battle; warn when the total
  // goes past what today's strongest units have.
  function balanceHTML(rows) {
    const PM = window.ForgePassiveMerge, issues = PM ? PM.balanceIssues(rows) : [];
    if (!issues.length) return "";
    return '<div class="notice warning bld-balance"><strong>⚡ Balance check</strong><p>These add up past today’s strongest units, which can make the unit broken:</p><ul>' + issues.map((i) => "<li>" + h(i.label.replace(/\s*[+−-]?\s*%?$/, "").replace(/\s*\+$/, "")) + " " + h(i.total) + (/%/.test(i.label) ? "%" : "") + " in total (" + h(i.text) + (i.rows.length > 1 ? " and " + (i.rows.length - 1) + " more" : "") + ") — meta limit about " + h(i.cap) + (/%/.test(i.label) ? "%" : "") + "</li>").join("") + '</ul><div class="row">' + btn("Fit to today’s meta", "passive-fit", "button small") + "</div></div>";
  }
  function passiveHTML() {
    if (!ui.subTargets && !ui.subLoading) ensureSubTargets().catch(() => {});
    if (window.ForgeNameSets) ForgeNameSets.load().then((fresh) => {}).catch(() => {});
    if (!stageLocked("passive")) linkTransformations();
    if (stageLocked("passive")) { const set = passiveSet(); return stageBar("passive") + '<section class="panel"><h2>Original Passive Skill</h2><strong>' + h(set ? set.name : "") + '</strong><div class="itemized">' + itemized(set ? set.itemized_description : "") + "</div>" + hint("This is the card as it is in the game, so it stays unchanged. Pick an EZA step above to upgrade it.") + "</section>"; }
    const set = passiveSet(), rows = passiveRows(set);
    const autoOn = set ? auto("passive:" + set.id, passiveAutoDefault(rows, set)) : true;
    const top = set ? '<div class="field-grid">' + field("Passive Skill name", tableBind("passive_skill_sets", set, "name"), set.name, "text", "", 'maxlength="80"') + "</div>" : "";
    let tf = null;
    try { const t = state.project.awaken ? null : transformHTML(); tf = t && typeof t === "object" ? t : null; } catch (e) { tf = null; }
    const cardOf = (r) => (Number(r.efficacy_type) === 103 && tf && tf.byRow.get("passive_skills:" + r.id)) || passiveCardHTML(r);
    return stageBar("passive") + (ui.adding ? passivePickerHTML() : "") + (tf && ui.tfAdding ? '<section class="panel" id="bld-tf-new"><h2>⟳ New transformation</h2>' + tf.wizard + "</section>" : "") + '<section class="panel"><h2>Passive Skill</h2>' + hint("Abilities that work by themselves in battle. Tap Edit on one to change it.") + top + '<div class="row">' + btn("＋ Add an ability", "pcat:add", "button") + btn("★ Add a preset ability", "pcat:preset", "button ghost") + btn("⧉ Copy a character's passive", "pcat:copy", "button ghost") + "</div>" + '<div class="bld-abilities">' + godlyCardHTML(rows) + (rows.length ? rows.filter((r) => !/Exclusive$/.test(r.name || "") && !(window.ForgePassiveFamilies && ForgePassiveFamilies.companionIds().has(r.id))).map(cardOf).join("") : '<p class="bld-empty">No abilities yet. Add the first one below.</p>') + (tf ? tf.extra.join("") : "") + '</div>' + (tf ? tf.includeBtn : "") + (window.ForgePassiveFamilies ? ForgePassiveFamilies.disabledHTML(set) : "") + balanceHTML(rows) + "</section>" + introSectionHTML() + transformSectionHTML("passive") + (set ? '<details class="panel bld-pdesc-fold"><summary><h2>See how it looks in the game</h2><small>Written for you automatically</small></summary><div class="bld-pdesc-preview" data-pdesc-preview="' + set.id + '"><p class="bld-pdesc-title">How it looks in the game</p><div class="bld-itemized itemized">' + itemized(set.itemized_description || "") + "</div></div>" + "</details>" : "") + ezaNotice();
  }

  // ------------------------------------------------------------ tabs: super attacks
  function specialCardHTML(row) {
    const d = B.decodeSpecial(row), def = d && B.saDef(d.key), open = ui.open === "special:" + row.id, phrase = B.specialPhrase(row).text;
    let editor = "";
    if (open) {
      if (!d) editor = hint("This effect uses specialized game settings and is kept as it is.");
      else {
        const targets = B.SA_TARGETS[def.targets];
        editor = '<div class="field-grid">' + fieldInputs(def.fields, B.normalizeValues(def.fields, d.values)) + (targets.length > 1 ? '<label class="field">Who<select data-bf="s.target">' + selection(targets.map((t) => [t, B.TARGETS[t].label]), row.target_type) + "</select></label>" : "") + '<label class="field">How long<select data-bf="s.turn">' + selection(B.SA_DURATIONS.concat(B.SA_DURATIONS.some(([v]) => v === Number(row.turn)) ? [] : [[row.turn, row.turn + " turns (original)"]]), row.turn) + "</select></label>" + (def.type === "Special::ExtraEfficacySpecial" ? '<label class="field">Chance %<input type="number" inputmode="numeric" min="1" max="100" step="1" data-bf="s.chance" value="' + h(row.prob) + '"></label>' : "") + "</div>";
      }
    }
    return '<div class="bld-subability' + (open ? " open" : "") + '" data-edit="special:' + row.id + '"><div class="bld-ability-head"><span class="bld-icon">✸</span><div><strong>' + h(B.cap(phrase || "Special effect")) + '</strong></div><div class="bld-ability-actions">' + (d ? btn(open ? "Done" : "Edit", "open:special:" + row.id) : "") + '<button type="button" class="icon-button" data-b="special-del:' + row.id + '" aria-label="Remove this effect">×</button></div></div>' + (open ? '<div class="bld-editor">' + editor + "</div>" : "") + "</div>";
  }
  function superHTML(rel) {
    const p = state.project, set = (p.tables.special_sets || []).find((s) => s.id === rel.special_set_id);
    if (!set) return "";
    const label = rel.style === "Hyper" ? "Ultra Super Attack" : rel.style === "Extra" ? "EX Super Attack" : rel.style === "FullPower" ? "Full-power attack" : rel.style === "Condition" ? "Conditional Super Attack" : "Super Attack";
    const current = profiles().find((x) => x.increase_rate === set.increase_rate && x.lv_bonus === set.lv_bonus);
    const effects = specialsOf(set.id), key = "super:" + rel.id, autoOn = auto("sa:" + set.id, specialAutoDefault(set));
    const anim = (p.uiLabels && p.uiLabels.animations && p.uiLabels.animations[key]) || "The original animation";
    const pid = p.key; if (ui.superKey !== pid) { ui.superKey = pid; ui.superSeen = new Set((p.tables.card_specials || []).map((r) => r.id)); ui.superOpen = new Set(); }
    if (!ui.superSeen.has(rel.id)) { ui.superSeen.add(rel.id); ui.superOpen.add(rel.id); }   // a newly added attack opens
    const dmg = current ? current.name : "Original damage";
    return '<details class="panel bld-super bld-super-card" data-sopen="' + rel.id + '"' + (ui.superOpen.has(rel.id) ? " open" : "") + '><summary class="bld-super-sum"><span class="bld-super-kind">' + h(label) + '</span><strong>' + h(set.name || "Unnamed attack") + '</strong><small>' + h(rel.eball_num_start) + " Ki · " + h(dmg) + " · " + (Number(set.aim_target) ? "All enemies" : "One enemy") + '</small><span class="bld-super-edit">Edit ▾</span></summary><div class="bld-group-head"><h2>' + h(label) + (rel.lv_start ? ' <small class="muted">· replaces it from SA level ' + h(rel.lv_start) + "</small>" : "") + "</h2>" + ((p.tables.card_specials || []).length > 1 ? '<button type="button" class="icon-button" data-b="super-del:' + rel.id + '" aria-label="Remove this attack">×</button>' : "") + '</div><div class="field-grid">' + field("Attack name", tableBind("special_sets", set, "name"), set.name, "text", "", 'maxlength="80"') + '<label class="field">Attack type<select data-bsel="super-style:' + rel.id + '">' + selection([["Normal","Super Attack"],["Hyper","Ultra Super Attack"],["Condition","Conditional Super Attack"],["Extra","EX Super Attack"],["FullPower","Full-power attack"]],rel.style) + '</select></label>' + select("Ki needed", tableBind("card_specials", rel, "eball_num_start"), rel.eball_num_start, [[10, "10 Ki"], [11, "11 Ki"], [12, "12 Ki · Super Attack"], [15, "15 Ki"], [18, "18 Ki · Ultra Super Attack"], [24, "24 Ki"]]) + '<label class="field">Damage<select data-bsel="power:' + set.id + '">' + selection((current ? [] : [["keep", "Keep original damage (" + set.increase_rate + "%)"]]).concat(profiles().map((x) => [x.key, x.name + " · " + x.increase_rate + "%"])), current ? current.key : "keep") + "</select></label>" + select("Hits", tableBind("special_sets", set, "aim_target"), set.aim_target, [[0, "One enemy"], [1, "All enemies"]]) + '</div>' + (rel.style === 'Condition' || rel.causality_conditions ? conditionEditor('super',rel.id,rel) : '') + (rel.style === 'Extra' ? '<label class="field">When can the EX attack happen?<select data-bsel="super-extype:' + rel.id + '">' + selection(EX_TYPES, ((p.tables.extra_special_options||[]).find(r=>r.card_special_id===rel.id) || {}).extra_special_type ?? 0) + '</select></label><label class="field">EX activation chance (%)<input type="number" min="1" max="100" data-bsel-num="super-chance:' + rel.id + '" value="' + h((p.tables.extra_special_options||[]).find(r=>r.card_special_id===rel.id)?.probability ?? 70) + '"></label>' : '') + '<h3>Extra effects</h3><div class="bld-subabilities">' + (effects.length ? effects.map(specialCardHTML).join("") : '<p class="bld-empty">Only damage. Add effects like “raises ATK” or “stuns the enemy”.</p>') + '</div><label class="field">Add an effect<select data-bsel="special-add:' + set.id + '"><option value="">Choose an effect…</option>' + B.SA_EFFECTS.map((e) => '<option value="' + e.key + '">' + h(e.label) + "</option>").join("") + '</select></label><label class="bld-check"><input type="checkbox" data-bauto="sa:' + set.id + '"' + (autoOn ? " checked" : "") + "> Write the description for me</label>" + '<label class="field full">What the game shows<textarea data-bind="' + h(tableBind("special_sets", set, "description")) + '" data-manual="sa:' + set.id + '" rows="3">' + h(set.description || "") + '</textarea></label>' + ForgeAnimChoice.block(key, { label: label + " animation", original: anim, help: "The animation that plays for this attack. Only one is ever used — the attack keeps its own damage and effects.", extra: [["copy", "Copy a whole game attack (animation and damage)…", "super-copy:" + rel.id]] }) + "</details>";
  }
  function supersHTML() {
    if (state.project.awaken) return awakenSupersHTML();
    const p = state.project, rels = (p.tables.card_specials || []).slice().sort((a, b) => (a.style === "Hyper") - (b.style === "Hyper") || a.lv_start - b.lv_start);
    const hasNormal = rels.some((r) => r.style === "Normal"), hasHyper = rels.some((r) => r.style === "Hyper");
    return '<section class="panel"><h2>Super Attacks</h2>' + hint("Tap an attack to edit it.") + '<div class="row">' + (!hasNormal ? btn("＋ Add a Super Attack", "super-add:Normal", "button") : !hasHyper ? btn("＋ Add an Ultra Super Attack (18 Ki)", "super-add:Hyper", "button") : "") + btn("Copy an attack from the game", "super-copy", "ghost") + "</div>" +
      // Rarer kinds stay one tap away so the main choice is obvious.
      '<details class="beginner-details bld-more-supers"><summary>Other kinds of Super Attack</summary><p class="hint">Ultra (18+ Ki), conditional (only when something happens, e.g. after a transformation) and EX (extra attack) Super Attacks.</p><div class="row">' + (!hasNormal && !hasHyper ? btn("＋ Ultra Super Attack (18 Ki)", "super-add:Hyper", "ghost") : "") + btn("＋ Conditional Super Attack", "super-add:Condition", "ghost") + btn("＋ EX Super Attack", "super-add:Extra", "ghost") + "</div></details></section>" + rels.map(superHTML).join("");
  }

  function awakenSupersHTML() {
    const p = state.project, rels = (p.tables.card_specials || []).slice().sort((a, b) => (a.style === "Hyper") - (b.style === "Hyper") || a.lv_start - b.lv_start);
    const official = rels.filter((r) => Number(r.id) > 0), mine = rels.filter((r) => Number(r.id) < 0);
    const hasHyper = rels.some((r) => r.style === "Hyper");
    return '<section class="panel"><h2>EZA Super Attack upgrades</h2>' + hint("After EZA, a card's Super Attack usually gets stronger once its Super Attack level passes 14. Add an upgraded version here — the original attacks stay as they are.") + '<div class="row">' + btn("＋ Add an upgraded Super Attack", "super-add-eza:Normal", "button") + (hasHyper ? btn("＋ Add an upgraded Ultra Super Attack", "super-add-eza:Hyper", "ghost") : "") + '</div></section>' + mine.map(superHTML).join("") + '<section class="panel"><h2>The card\'s original attacks</h2>' + official.map((rel) => { const s2 = (p.tables.special_sets || []).find((x) => x.id === rel.special_set_id) || {}; return '<p><strong>' + h(s2.name) + "</strong> · " + h(rel.eball_num_start) + "+ Ki" + (rel.lv_start ? " · from SA level " + h(rel.lv_start) : "") + '<br><span class="muted">' + h(String(s2.description || "").replace(/\s+/g, " ")) + "</span></p>"; }).join("") + hint("These stay exactly as they are in the game.") + "</section>";
  }
  // ------------------------------------------------------------ tabs: active skill
  function activeEffectHTML(row) {
    const d = B.decodeActive(row), def = d && B.activeDef(d.key), open = ui.open === "activefx:" + row.id;
    if (Number(row.efficacy_type) === 103) return '<div class="bld-subability"><div class="bld-ability-head"><span class="bld-icon">⟳</span><div><strong>Transforms into ' + h(knownCardName(row.eff_val1) || "another form") + "</strong></div>" + btn("Transformations", "tab:transform") + "</div></div>";
    const t = Number(row.target_type), owner = (B.TARGETS[t] || {}).owner || "";
    const title = d ? B.cap(def.text(B.normalizeValues(def.fields, d.values), owner, t)) : G.effectSummary({ efficacy_type: row.efficacy_type, calc_option: row.calc_option, eff_value1: row.eff_val1, eff_value2: row.eff_val2, eff_value3: row.eff_val3, probability: 100 });
    let editor = "";
    if (open && d) {
      const targets = B.ACTIVE_TARGETS[def.targets];
      editor = '<div class="field-grid">' + fieldInputs(def.fields, B.normalizeValues(def.fields, d.values)) + (targets.length > 1 ? '<label class="field">Who<select data-bf="s.target">' + selection(targets.map((x) => [x, B.TARGETS[x].label]), t) + "</select></label>" : "") + "</div>";
    }
    return '<div class="bld-subability' + (open ? " open" : "") + '" data-edit="activefx:' + row.id + '"><div class="bld-ability-head"><span class="bld-icon">⚡</span><div><strong>' + h(title) + '</strong></div><div class="bld-ability-actions">' + (d ? btn(open ? "Done" : "Edit", "open:activefx:" + row.id) : "") + '<button type="button" class="icon-button" data-b="activefx-del:' + row.id + '" aria-label="Remove this effect">×</button></div></div>' + (open ? '<div class="bld-editor">' + editor + "</div>" : "") + "</div>";
  }
  // tells you when tapping this Active Skill transforms the character
  function activeTransformNote(set) {
    const r = activeRows(set.id).find((x) => Number(x.efficacy_type) === 103);
    if (!r) return "";
    const only = !B.activeAttack(state.project, set) && activeRows(set.id).every((x) => Number(x.efficacy_type) === 103);
    return '<div class="notice">⟳ <strong>Tapping this Active Skill transforms the character</strong> into ' + h(formNameOf(ForgeForms.target(r, "active_skills").targetId) || "its other form") + "." + (only ? " Right now that's all it does — you can add an ultimate attack or a boost (effects) to it below, and they happen together with the transformation." : " Its attack and effects happen together with the transformation.") + " " + btn("See Transformations", "tab:transform", "ghost small") + "</div>";
  }
  function activeHTML() {
    const p = state.project, sets = activeSets();
    if (!sets.length) {
      const kinds = [["attack", "Ultimate attack", "A huge finishing attack with its own cut-in animation, plus optional boosts."], ["buff", "Power-up", "A dramatic boost such as Ki +10 and ATK & DEF +100% for the turn."], ["transform", "Transformation", "Let the player choose when to transform (set it up under Transformations on the Passive Skill step)."]];
      return '<section class="panel"><h2>Active Skill</h2>' + hint("An Active Skill is a button the player taps in battle once its conditions are met (usually once per battle).") + '<div class="bld-kinds">' + kinds.map(([k, n, d]) => '<button type="button" class="bld-kind' + (ui.activeKind === k ? " on" : "") + '" data-b="active-kind:' + k + '"><strong>' + h(n) + "</strong><small>" + h(d) + "</small></button>").join("") + "</div>" + (ui.activeKind === "transform" ? '<div class="row">' + btn("Set up a transformation", "tab:transform", "button") + "</div>" : '<label class="field">Active Skill name<input id="bld-active-name" maxlength="80" value="' + h(ui.activeKind === "attack" ? "Ultimate Finisher" : "Awakened Power") + '"></label><div class="row">' + btn("Create my Active Skill", "active-create", "button") + "</div>" + hint("It starts with a game animation that fits. You can choose any character's Active Skill animation afterwards.")) + "</section>";
    }
    return sets.map((set) => {
      const atk = B.activeAttack(p, set), rows = activeRows(set.id), key = "active:" + set.id, autoOn = auto("active:" + set.id, activeAutoDefault(set));
      const anim = (p.uiLabels && p.uiLabels.animations && p.uiLabels.animations[key]) || (set.special_view_id ? "Game animation" : "No animation");
      return '<section class="panel"><div class="bld-group-head"><h2>Active Skill</h2><button type="button" class="icon-button" data-b="active-del:' + set.id + '" aria-label="Remove the Active Skill">×</button></div>' + activeTransformNote(set) + '<div class="field-grid">' + field("Name", tableBind("active_skill_sets", set, "name"), set.name, "text", "", 'maxlength="80"') + '<label class="field">Lasts<select data-bsel="active-turn:' + set.id + '">' + selection([[1, "This turn"], [2, "2 turns"], [3, "3 turns"], [4, "4 turns"], [99, "Rest of the battle"]].concat([1, 2, 3, 4, 99].includes(Number(set.turn)) ? [] : [[set.turn, set.turn + " turns (original)"]]), set.turn) + '</select></label><label class="field">Can be used<select data-bsel="active-limit:' + set.id + '">' + selection([[1, "Once per battle"], [2, "Twice per battle"], [3, "3 times per battle"]].concat([1, 2, 3].includes(Number(set.exec_limit)) ? [] : [[set.exec_limit, set.exec_limit + " times (original)"]]), set.exec_limit) + "</select></label></div>" +
        '<h3>Attack</h3>' + (atk && atk.inherited ? hint("Uses the original ultimate attack damage.") : atk ? '<div class="field-grid"><label class="field">Extra ATK boost for the attack %<input type="number" inputmode="numeric" min="0" max="5000" step="1" data-bsel-num="active-boost:' + set.id + '" value="' + h(atk.boost) + '"></label><label class="field">Hits<select data-bsel="active-aim:' + set.id + '">' + selection([[0, "One enemy"], [1, "All enemies"]], atk.allEnemies ? 1 : 0) + "</select></label></div>" + btn("Remove the attack (effects only)", "active-noattack:" + set.id, "subtle small") : '<p class="bld-empty">No attack — effects only.</p>' + btn("Add an ultimate attack", "active-attack:" + set.id, "subtle small")) +
        '<h3>Effects</h3><div class="bld-subabilities">' + (rows.length ? rows.map(activeEffectHTML).join("") : '<p class="bld-empty">No extra effects yet.</p>') + '</div><label class="field">Add an effect<select data-bsel="activefx-add:' + set.id + '"><option value="">Choose an effect…</option>' + B.ACTIVE_EFFECTS.map((e) => '<option value="' + e.key + '">' + h(e.label) + "</option>").join("") + "</select></label>" +
        conditionEditor("active", set.id, set) + '<label class="bld-check"><input type="checkbox" data-bauto="active:' + set.id + '"' + (autoOn ? " checked" : "") + "> Write the descriptions for me</label>" + '<div class="field-grid">' + '<label class="field full">Effect text<textarea data-bind="' + h(tableBind("active_skill_sets", set, "effect_description")) + '" data-manual="active:' + set.id + '" rows="3">' + h(set.effect_description || "") + '</textarea></label><label class="field full">Activation text<textarea data-bind="' + h(tableBind("active_skill_sets", set, "condition_description")) + '" data-manual="active:' + set.id + '" rows="2">' + h(set.condition_description || "") + "</textarea></label></div>" +
        ForgeAnimChoice.block(key, { label: "Active Skill animation", original: anim, help: "The animation that plays when the Active Skill is used. Only one is ever used.", extra: [["act", "Another character's Active Skill…", "active-anim:" + set.id]] }) + "</section>";
    }).join("");
  }

  // ------------------------------------------------------------ tabs: transform
  // The unit or form whose original game card is this transformation's target (copied chains).
  function chainMember(bundle, targetId) {
    return [bundle, ...(bundle.formProjects || [])].find((m) => Number(m.source && m.source.cardId) === Number(targetId) || Number(m.targetId) === Number(targetId)) || null;
  }
  // Transformations are set up inside the Passive Skill step (they are passive abilities in the game) and
  // The intro (entrance animation) is a passive ability in the game, so it is set up on the Passive Skill step.
  function introSectionHTML() {
    if (state.project.awaken || !window.ForgeIntro) return "";
    let body = "";
    try { body = ForgeIntro.html(); } catch (e) { body = ""; }
    return body ? '<div id="bld-intro" class="bld-intro-in">' + body + "</div>" : "";
  }
  // Revival (comes back after being K.O.'d) has its own section, like Transformations
  function revivalSectionHTML() {
    if (state.project.awaken) return "";
    const rows = passiveRows().filter((r) => Number(r.efficacy_type) === 109);
    return '<div id="bld-revival"><section class="panel"><h2>✚ Revival</h2>' + hint("The character comes back to life after being K.O.'d (once per battle). Choose how much HP it gets back, its revival animation, and boosts or a transformation after it revives.") +
      (rows.length ? '<div class="bld-abilities">' + rows.map(passiveCardHTML).join("") + "</div>" : '<p class="bld-empty">This character doesn’t revive.</p>') +
      '<div class="row">' + (rows.length ? "" : btn("＋ Add a revival", "revival-add", "button")) + (rows.length ? btn("⟳ Transform when it revives", "revival-tf", "button ghost") : "") + "</div></section></div>";
  }
  function transformSectionHTML(where) {
    if (state.project.awaken) return "";
    let body = "";
    try { body = transformHTML(); } catch (e) { body = ""; }
    // only when editing a transformed form (its "back to the starting form" panel) or a Sparking unit
    if (!body || typeof body !== "string") return "";
    return '<div id="bld-transform" class="bld-transform-in">' + body + "</div>";
  }
  // Transformations live in the Passive Skill list (each one is an ability card); the add questions open at the top
  function transformHTML() {
    const p = state.project, inForm = window.ForgeFormsUI && ForgeFormsUI.active();
    if (inForm) {
      let bundle = null;
      try { bundle = ForgeFormsUI.root(); } catch {}
      const own = ForgeForms.slots(p).map((slot) => {
        const member = bundle && chainMember(bundle, slot.targetId);
        return "<li>" + h(slot.name) + " → <strong>" + h(member ? Forge.card(member).name : knownCardName(slot.targetId) || "card " + slot.targetId) + "</strong>" + (member ? " (your " + (member === bundle ? "starting form" : "custom form") + ")" : "") + "</li>";
      }).join("");
      return '<section class="panel"><h2>Transform</h2>' + (own ? '<p>This form keeps the transformations of the card it was copied from:</p><ul class="bld-tf-chain">' + own + '</ul><p class="hint">Transformations into your own forms automatically use your copies when you export.</p>' : '<div class="notice">This form doesn’t transform again.</div>') + '<div class="row">' + btn("Use current base settings", "tf-base-current", "ghost") + btn("← Back to the starting form", "form-leave", "button") + "</div></section>";
    }
    if (p.source.database === "sparking") return '<section class="panel"><h2>Transform</h2><div class="notice">Building new transformations is available for Eclipse-database units. Existing transformations from this character are kept.</div></section>';
    return tfParts();
  }
  function tfParts() {
    const p = state.project;
    const slots = ForgeForms.slots(p), forms = p.formProjects || [], t = ui.tf;
    const linkedKeys = new Set();
    const cards = [], byRow = new Map();
    slots.forEach((slot) => {
      const row = (p.tables[slot.table] || []).find((r) => r.id === slot.row);
      const chained = !slot.linkedKey && chainMember(p, slot.targetId);
      if (chained && chained !== p) slot.linkedKey = chained.key;
      if (slot.linkedKey) linkedKeys.add(slot.linkedKey);
      const formIndex = forms.findIndex((f) => f.key === slot.linkedKey), mine = formIndex >= 0;
      const target = mine ? Forge.card(forms[formIndex]).name : slot.linkedName || knownCardName(slot.targetId) || "card " + slot.targetId;
      let when = "";
      if (slot.table === "passive_skills" && row) when = condInfo(row).text || "at the start of battle";
      else if (slot.table === "active_skills" && row) { const set = (p.tables.active_skill_sets || []).find((s) => s.id === row.active_skill_set_id); when = "the player taps the Active Skill button" + (set ? " “" + set.name + "”" : "") + (set && condInfo(set).text ? " (it can be used " + condInfo(set).text + ")" : ""); }
      else when = "during a special move";
      const key = slot.table + ":" + slot.row, open = ui.open === "tf:" + key;
      const html = '<article class="tf-simple"><p class="tf-into"><span class="bld-icon">⟳</span> Turns into <strong>' + h(target) + "</strong>" + (mine ? "" : ' <small class="tf-tag">original game card</small>') + '</p><p class="tf-when"><strong>When:</strong> ' + h(B.cap(when)) + "</p>" + (slot.table === "active_skills" ? '<p class="hint">This is an <strong>Active Skill transformation</strong>: the player chooses when to transform by tapping the button in battle. Its button settings are on the Active Skill step.</p>' : "") +
        '<div class="row">' + (mine ? btn("✎ Edit this form", "form-enter:" + formIndex, "button small") : btn("✎ Make it my own", "tf-custom:" + key, "button small")) +
        (slot.table === "passive_skills" && row ? btn(open ? "Done" : "⏱ Change when", "open:tf:" + key, "ghost small") : "") +
        btn("🗑 Remove", "tf-del:" + key, "ghost small") + "</div>" +
        (open && row ? '<div class="bld-editor">' + conditionEditor("passive", row.id, row, { advanced: true }) + "</div>" : "") +
        '<details class="beginner-details tf-more"><summary>More options</summary><div class="row">' + btn("Turn into a different character", "tf-custom:" + key, "ghost small") + btn("Turn into an original game card", "tf-card:" + key, "ghost small") + (mine ? btn("Copy this unit's stats & skills to it again", "tf-base-copy:" + formIndex, "ghost small") : "") + "</div></details></article>";
      cards.push(html); byRow.set(key, html);
    });
    const extra = [];
    forms.forEach((f, i) => {
      if (linkedKeys.has(f.key)) return;
      extra.push('<article class="tf-simple"><p class="tf-into"><span class="bld-icon">⟳</span> Another form: <strong>' + h(Forge.card(f).name) + '</strong></p><p class="tf-when">Reached from one of your other forms (for example a second transformation).</p><div class="row">' + btn("✎ Edit this form", "form-enter:" + i, "button small") + btn("🗑 Remove", "tf-form-del:" + i, "ghost small") + "</div></article>");
    });
    const canInclude = window.ForgeTemplateForms && !forms.length && slots.some((slot) => !slot.linkedKey && !chainMember(p, slot.targetId)) && slots.length > 1;
    const includeBtn = canInclude ? '<div class="row">' + btn("✎ Make all of them my own", "tf-include", "ghost small") + "</div>" : "";
    const trigger = !t.cond.items.length ? "always" : t.cond.items.length === 1 && t.cond.items[0].key === "hpBelow" && Number(t.cond.items[0].values.hp) === 50 ? "hp" : t.cond.items.length === 1 && t.cond.items[0].key === "turn" && Number(t.cond.items[0].values.turn) === 4 ? "turn" : "custom";
    let add;
    if (forms.length >= ForgeForms.MAX_FORMS) add = hint("This unit already has the most forms allowed (" + ForgeForms.MAX_FORMS + ").");
    else if (!ui.tfAdding) add = '<div class="row">' + btn(cards.length ? "＋ Add another transformation" : "＋ Add a transformation", "tf-adding:on", "button") + "</div>";
    else add = '<div class="tf-add"><h3>New transformation</h3>' +
      '<h4>1. How does it happen?</h4><div class="bld-kinds">' + [["passive", "By itself", "It transforms automatically when the time below comes."], ["active", "Active Skill (the player taps a button)", "An Active Skill button appears in battle. The player taps it to transform."], ["revival", "When it revives", "After being K.O.'d, it comes back to life in its new form."]].map(([k, n, d]) => '<button type="button" class="bld-kind' + (t.how === k ? " on" : "") + '" data-b="tf-how:' + k + '"><strong>' + h(n) + "</strong><small>" + h(d) + "</small></button>").join("") + "</div>" +
      (t.how === "active" ? '<p class="notice tf-active-note">' + (activeSets().length ? "⚡ The transformation is added to your Active Skill “" + h(activeSets()[0].name) + "”. Tapping it in battle transforms the character." : "⚡ You have no Active Skill yet, so a new one called “Transformation” is made for you. Tapping it in battle transforms the character. Later you can add an attack or a boost to it on the Active Skill step.") + "</p>" : "") + (t.how === "revival" ? '<h4>2. When?</h4><p class="hint">Right after its Revival Skill brings it back.' + (passiveRows().some((r) => Number(r.efficacy_type) === 109) ? "" : " This character has no revival yet — one is added for you (change it under Revival on this step).") + "</p>" : t.how === "active" && activeSets().length ? '<h4>2. From when can the player tap it?</h4><p class="hint">Whenever your Active Skill can be used. You can change that on the Active Skill step.</p>' : '<h4>' + (t.how === "active" ? "2. From when can the player tap it?" : "2. When?") + '</h4><div class="bld-pills">' + [["always", "Start of battle"], ["turn", "From turn 4"], ["hp", "HP 50% or below"]].map(([k, n]) => '<button type="button" class="bld-pill' + (trigger === k ? " on" : "") + '" data-b="tf-preset:' + k + '">' + n + "</button>").join("") + '</div><p class="hint" id="tf-trigger-summary">' + h(B.cap(B.conditionText(t.cond, names())) || "Ready at the start of battle") + '</p><details class="beginner-details"><summary>Something else</summary><div class="bld-cond" data-cond="tfnew:0">' + tfCondHTML() + "</div></details>") +
      '<h4>3. Who does it turn into?</h4><div class="bld-kinds">' + [["custom", "My own version", "A copy of any character that you can change."], ["card", "The original game card", "Exactly as it is in the game."]].map(([k, n, d]) => '<button type="button" class="bld-kind' + (t.into === k ? " on" : "") + '" data-b="tf-into:' + k + '"><strong>' + h(n) + "</strong><small>" + h(d) + "</small></button>").join("") + "</div>" +
      (t.into === "card" ? "" : '<details class="beginner-details"><summary>What the new form copies from this unit</summary><p class="hint">Ticked items stay the same as this unit (and keep matching it when you change it). Untick to give the new form its own.</p><div class="base-copy-choices">' + [["stats", "HP, ATK & DEF"], ["leader", "Leader Skill"], ["links", "Link Skills"], ["categories", "Categories"], ["gameplay", "Other gameplay settings"]].map(([k, n]) => '<label class="check-item"><input type="checkbox" data-tf-copy="' + k + '" checked><span>' + n + "</span></label>").join("") + "</div></details>") +
      '<div class="row">' + btn("Choose the character", "tf-create", "button") + btn("Cancel", "tf-adding:off", "ghost") + "</div></div>";
    return { byRow, extra, includeBtn, add, wizard: ui.tfAdding ? add : "", cards };
  }
  function tfCondHTML() {
    const spec = ui.tf.cond;
    return (spec.items.length ? spec.items.map((item, i) => {
      const def = B.conditionDef(item.key);
      const inputs = def.fields.map((f) => f.kind === "category" ? '<label class="field">' + h(f.label) + '<select data-cf="' + f.name + '">' + selection(categoryOptionsList(), item.values[f.name]) + "</select></label>" : f.kind === "choice" ? '<label class="field">' + h(f.label) + '<select data-cf="' + f.name + '">' + selection(f.options, item.values[f.name]) + "</select></label>" : '<label class="field">' + h(f.label) + '<input type="number" inputmode="numeric" step="1" data-cf="' + f.name + '" min="' + f.min + '" max="' + f.max + '" value="' + h(item.values[f.name]) + '"></label>').join("");
      return '<div class="bld-rule" data-rule="' + i + '" data-key="' + h(item.key) + '"><div class="bld-rule-head"><strong>' + h(def.label) + '</strong><button type="button" class="icon-button" data-b="tfcond-del:' + i + '" aria-label="Remove this condition">×</button></div>' + (inputs ? '<div class="field-grid">' + inputs + "</div>" : "") + "</div>";
    }).join("") : '<p class="bld-always">' + (ui.tf.how === "active" ? "Available at any time." : "Transforms at the start of the first turn.") + "</p>") + (spec.items.length > 1 ? '<label class="field bld-mode">These conditions must<select data-cmode>' + selection([["all", "ALL be true"], ["any", "ANY be true (at least one)"]], spec.mode) + "</select></label>" : "") + '<label class="field">Add a condition<select data-cadd><option value="">Choose a condition…</option>' + B.CONDITIONS.map((c) => '<option value="' + c.key + '">' + h(c.label) + "</option>").join("") + "</select></label>" + (spec.items.length ? '<p class="bld-cond-summary">' + h(B.cap(B.conditionText(spec, names()))) + ".</p>" : "");
  }
  async function exemplar(kind) {
    if (kind === "passive") {
      const row = (await Native.call("query", { table: "passive_skills", ids: [1998], limit: 1 }))[0];
      if (!row || Number(row.efficacy_type) !== 103) throw new Error("The game's transformation template is missing from the active database.");
      const params = await Native.call("query", { table: "battle_params", filters: { param_no: row.eff_value3 }, limit: 100 });
      return { row, params };
    }
    const set = (await Native.call("query", { table: "active_skill_sets", ids: [66], limit: 1 }))[0];
    const row = (await Native.call("query", { table: "active_skills", filters: { active_skill_set_id: 66 }, limit: 20 })).find((r) => Number(r.efficacy_type) === 103);
    if (!set || !row) throw new Error("The game's Active Skill transformation template is missing from the active database.");
    const params = await Native.call("query", { table: "battle_params", filters: { param_no: row.eff_val3 }, limit: 100 });
    return { row, params, viewId: set.special_view_id, bgmId: set.bgm_id };
  }
  async function newCustomForm(card) {
    const parent = state.project;
    const form = await Forge.loadTemplate((o) => Native.call("query", o), state.info.schema, card.id, 1950000001);
    const saved = await Native.call("projects");
    const reserved = [...saved, { key: "reserved-current-design", targetId: parent.targetId }, ...(parent.formProjects || []).map((f, i) => ({ key: "reserved-form-" + i, targetId: f.targetId }))];
    await G.allocateId(form, (o) => Native.call("query", o), reserved);
    const groups = Object.fromEntries(ForgeFormInheritance.GROUPS.map(k => [k, document.querySelector('[data-tf-copy="' + k + '"]')?.checked !== false]));
    ForgeFormInheritance.copy(parent, form, { groups, pending: true });
    return form;
  }
  async function createTransformation(card) {
    ui.tfAdding = false;
    let parent = state.project;
    const revival = ui.tf.how === "revival", how = revival ? "passive" : ui.tf.how, into = ui.tf.into, spec = revival ? { mode: "all", items: [{ key: "revived", values: {} }] } : JSON.parse(JSON.stringify(ui.tf.cond));
    if (revival && !passiveRows().some((r) => Number(r.efficacy_type) === 109) && window.ForgePassiveFamilies) { ForgePassiveFamilies.addNow("revive"); parent = state.project; }
    await busy(into === "custom" ? "Creating " + card.name + " as your new form" : "Adding the transformation", async () => {
      await flushSave();
      const baseline = JSON.stringify(parent), ex = await exemplar(how), form = into === "custom" ? await newCustomForm(card) : null;
      if (state.project !== parent || JSON.stringify(parent) !== baseline) throw new Error("Your unit changed while the form was prepared. Try again.");
      const work = Forge.clone(parent), schema = state.info.schema, targetId = form ? form.targetId : card.id;
      const condText = B.conditionText(spec, names());
      let table, row;
      if (how === "passive") {
        table = "passive_skills";
        // goes into the Passive Skill you're looking at (e.g. the EZA one), and the base one too, so the unit
        // transforms whether or not it has been Extreme Z-Awakened
        work.abilityAnimationSources = work.abilityAnimationSources || {};
        const sk = stageKey("passive"), view = sk === "base" ? work : B.stageView(work, "passive", sk);
        row = B.addPassiveTransformation(view, schema, { exemplar: ex, targetId, name: (Forge.primaryPassive(view) || {}).name || "Transformation", condition: spec, description: "Transforms" + (condText ? " " + condText : "") });
        const baseSet = Forge.card(work).passive_skill_set_id, rel = work.tables.passive_skill_set_relations || [];
        if (baseSet && !rel.some((r) => r.passive_skill_set_id === baseSet && r.passive_skill_id === row.id))
          rel.push(Object.assign(Forge.rowDefault(work.schema.passive_skill_set_relations), { id: Forge.localId(work, "passive_skill_set_relations"), passive_skill_set_id: baseSet, passive_skill_id: row.id }));
      } else {
        table = "active_skills";
        let set = (work.tables.active_skill_sets || []).find((s) => (work.tables.card_active_skills || []).some((r) => r.active_skill_set_id === s.id));
        if (!set) {
          set = B.createActive(work, schema, { name: "Transformation", viewId: ex.viewId, bgmId: ex.bgmId });
          B.applyCondition(work, schema, set, spec);
        }
        row = B.addActiveTransformation(work, schema, set, { exemplar: ex, targetId, description: "Transforms via Active Skill" + (condText ? " " + condText : "") });
        work.builderAuto = work.builderAuto || {};
        if (work.builderAuto["active:" + set.id] === undefined) work.builderAuto["active:" + set.id] = true;
      }
      work.builderAuto = work.builderAuto || {};
      work.builderAuto["td:" + table + ":" + row.id] = true;
      state.project = form ? ForgeForms.attach(work, form, { table, row: row.id }) : work;
      if (!form) ui.cardNames.set(Number(card.id), card.name);
      refreshTexts();
      scheduleSave();
      await flushSave();
      renderEditor();
      toast(form ? "Transformation added with your base settings. Tap “Edit this form” to customize " + card.name + "." : "Transformation added.");
    });
  }
  async function retarget(table, rowId, card, custom) {
    const parent = state.project;
    await busy(custom ? "Creating " + card.name + " as your new form" : "Changing the transformation", async () => {
      await flushSave();
      const baseline = JSON.stringify(parent), form = custom ? await newCustomForm(card) : null;
      if (state.project !== parent || JSON.stringify(parent) !== baseline) throw new Error("Your unit changed. Try again.");
      let work = Forge.clone(parent);
      if (form) work = ForgeForms.attach(work, form, { table, row: rowId });
      else {
        const row = work.tables[table].find((r) => r.id === rowId), info = ForgeForms.target(row, table);
        row[info.field] = Number(card.id);
        if (info.values) { info.values[0] = Number(card.id); row.efficacy_values = JSON.stringify(info.values); }
        if (work.transformLinks) work.transformLinks = work.transformLinks.filter((l) => !(l.table === table && l.row === rowId));
        ForgeForms.prune(work);
        ui.cardNames.set(Number(card.id), card.name);
      }
      const check = Forge.validate(work);
      if (check.errors.length) throw new Error(check.errors[0]);
      state.project = work;
      refreshTexts();
      scheduleSave();
      await flushSave();
      renderEditor();
    });
  }

  // ------------------------------------------------------------ tabs: links, look, save
  function linksHTML() {
    return '<section class="panel"><h2>Link Skills & Categories</h2>' + hint("Link Skills give bonuses when allies next to this character share them (up to 7). Categories decide which teams and leader skills include this character.") + '<label class="field">Search links and categories<input id="lookup-query" type="search" placeholder="Saiyan, Fierce Battle, Pure Saiyans…"></label><h3>Link Skills <span id="link-count"></span></h3><div class="check-grid" id="link-options">' + linkOptions("") + '</div><h3>Categories</h3><div class="check-grid" id="category-options">' + categoryOptions("") + "</div></section>";
  }
  function lookHTML() {
    const p = state.project;
    const all = G.targets(p), normals = all.filter((t) => t.kind === "normal"), others = all.filter((t) => !["normal", "dodge"].includes(t.kind));
    return '<section class="panel"><h2>Artwork & aura</h2><div class="guide-source"><img src="' + h(artUrl()) + '" alt=""><div><strong>' + h(p.artBinding ? "Custom in-game artwork" : (p.uiLabels && p.uiLabels.art) || "Original artwork") + "</strong><p>" + h((p.uiLabels && p.uiLabels.aura) || "Original aura") + '</p></div></div><div class="row">' + guide("Use another character's artwork", "pick-art") + guide("Customize in-game artwork", "game-art") + guide("Customize battle poses", "battle-poses") + (p.artBinding ? guide("Preview custom card", "preview-game-art") : "") + guide("Use another character's aura", "pick-aura") + guide("Choose editor preview image", "pick-preview") + '</div><div class="bld-ai-art"><div><strong>◈ Create new card art with AI</strong><p class="hint">Describe your character and let your connected AI draw it (or copy the prompt into any image app), then fit it into the in-game card.</p></div>' + btn("Create art with AI", "ai-art", "button") + '</div></section>';   // move animations live on Portraits & Sprites
  }
  // every move's animation (normal attacks, Super Attacks, Active Skill, intro/passive effects): shown on
  // the end of the Super Attacks tab
  function animationsPanelHTML() {
    const p = state.project;
    const all = G.targets(p), normals = all.filter((t) => t.kind === "normal"), others = all.filter((t) => !["normal", "dodge", "super", "ultra", "ex", "fullpower", "active"].includes(t.kind) && !/^active/.test(t.key));
    return '<details class="panel bld-anim-more"><summary><h2>Normal attacks &amp; other animations</h2><small>Tap to open</small></summary>' + hint("Here are the normal attacks and every other move that plays an animation. Tap ▶ Watch to see it, or Change… to use another one.") + '<article class="effect-card"><h3>Normal attack style</h3><label class="field">Which normal attacks can this character use?<select id="normal-attack-style">' + selection([["inherit", "Keep the original style"], ["mixed", "Melee and Ki blasts"], ["melee", "Melee only"], ["ki", "Ki blasts only"]], G.normalAttackStyle(p)) + "</select></label></article>" + normals.map((t) => ForgeAnimChoice.block(t.key, { label: t.name })).join("") + (others.length ? "<h3>Every other animated move</h3>" + others.map((t) => ForgeAnimChoice.block(t.key, { label: t.name })).join("") : "") + '<div class="row">' + guide("Open the animation editor", "studio", "button") + "</div></details>";
  }
  function checklist() {
    if (state.project.awaken) {
      const p = state.project, local = (rows) => (rows || []).some((r) => Number(r.id) < 0);
      const items = [[(p.tables.optimal_awakening_growths || []).length >= 7, "EZA steps 1–7", "eza"], [local(p.tables.leader_skills), "A new leader skill for an EZA step", "leader"], [local(p.tables.passive_skills), "An upgraded passive for an EZA step", "passive"], [local(p.tables.card_specials), "An upgraded Super Attack (optional)", "supers"]];
      return '<ul class="bld-checklist">' + items.map(([ok, label, t]) => '<li class="' + (ok ? "ok" : "todo") + '"><span>' + (ok ? "✓" : "○") + "</span>" + h(label) + (ok ? "" : " " + btn("Set up", "tab:" + t, "subtle small")) + "</li>").join("") + "</ul>";
    }
    const p = state.project, c = Forge.card(p), rows = passiveRows(), lset = leaderSet();
    const items = [[!!String(c.name || "").trim(), "Name your character", "basics"], [!!(lset && leaderRows(lset).some((r) => Number(r.efficacy_type) !== 0)), "Leader Skill", "leader"], [rows.length > 0, "At least one passive ability", "passive"], [(p.tables.card_specials || []).length > 0, "A Super Attack", "supers"], [Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]).filter(Boolean).length > 0, "Link Skills", "links"], [(p.tables.card_card_categories || []).length > 0, "Categories", "links"]];
    return '<ul class="bld-checklist">' + items.map(([ok, label, t]) => '<li class="' + (ok ? "ok" : "todo") + '"><span>' + (ok ? "✓" : "○") + "</span>" + h(label) + (ok ? "" : " " + btn("Set up", "tab:" + t, "subtle small")) + "</li>").join("") + "</ul>";
  }
  function saveHTML() {
    const p = state.project, check = Forge.validate(p);
    // the end of a unit: straight into the game you play it in
    const send = '<div class="send-game"><h3>Put it in your game</h3><div class="send-game-row">' +
      '<button type="button" class="send-btn send-eclipse" data-export="to-eclipse"' + (check.errors.length ? " disabled" : "") + '><strong>🟠 Import to Eclipse</strong><small>Saves your unit and opens Eclipse</small></button>' +
      '<button type="button" class="send-btn send-sparking" data-export="to-sparking"' + (check.errors.length ? " disabled" : "") + '><strong>✨ Import to Sparking</strong><small>Saves your unit and opens Sparking</small></button>' +
      '<button type="button" class="send-btn send-files" data-b="send-files"><strong>📄 Export .SQL / .JSON</strong><small>Save your creation as a file</small></button>' +
      "</div></div>";
    const list = checklist(), todo = (list.match(/class="todo"/g) || []).length;
    const ready = todo ? list.replace(/<li class="ok">.*?<\/li>/g, "") : '<p class="bld-ready-line">✓ Your unit is ready. Nothing is missing.</p>';
    return '<section class="panel"><h2>Ready to play?</h2>' + ready + validationHTML(check).replace(/^<div class="notice success">[\s\S]*?<\/div>/, "") + send + '</section><section class="panel"><details class="beginner-details bld-more-saves"><summary>Other ways to save</summary><div class="export-grid"><div class="export-option"><h3>Game file for Eclipse (.eclp)</h3><p>Saves the patch file to a folder you pick, for importing in Dokkan Eclipse yourself.</p><button class="button ghost" data-export="eclp">Save game file (.eclp)</button></div><div class="export-option"><h3>Editable backup (.json)</h3><p>Keep a copy you can import and keep editing later.</p><button class="button ghost" data-export="json">Save editable backup</button></div></div><div class="row"><button class="button ghost" data-export="sql">Database changes (.sql)</button><button class="button ghost" data-export="zip">Patch archive (.zip)</button></div></details><details class="beginner-details bld-patch-details"><summary>Name, author and version of the game file (optional)</summary><p class="hint">This is what Eclipse and Sparking show in their list of imported patches. It fills itself in, so you can skip it.</p><div class="field-grid">' + field("Patch name", "patch:name", p.patch.name) + field("Created by", "patch:author", p.patch.author) + field("Version", "patch:version", p.patch.version) + "</div>" + area("About this creation", "patch:description", p.patch.description) + '</details></section>';
  }

  // ------------------------------------------------------------ page
  function body() {
    switch (tab()) {
      case "eza": return ezaHTML();
      case "leader": return leaderHTML();
      case "passive": return passiveHTML();
      case "supers": return supersHTML() + animationsPanelHTML();
      case "active": return activeHTML();
      case "special": return window.ForgeSpecial ? ForgeSpecial.html() : "";
      case "standby": return window.ForgeSpecial ? ForgeSpecial.standbyHTML() : "";
      case "domain": return window.ForgeSpecial ? ForgeSpecial.domainHTML() : "";
      case "transform": return transformSectionHTML();
      case "links": return linksHTML();
      case "look": return lookHTML();
      case "appearance": return window.ForgeAppearance ? ForgeAppearance.html() : "";
      case "save": return saveHTML();
      default: return basicsHTML();
    }
  }
  function tabStatus(key) {
    const p = state.project;
    if (key === "leader") return !!leaderSet();
    if (key === "passive") return passiveRows().length > 0;
    if (key === "supers") return (p.tables.card_specials || []).length > 0;
    if (key === "active") return activeSets().length > 0;
    if (key === "special") return !!(window.ForgeSpecial && ForgeSpecial.status());
    if (key === "standby") return !!(window.ForgeSpecial && ForgeSpecial.standbyStatus());
    if (key === "domain") return !!(window.ForgeSpecial && ForgeSpecial.domainStatus());
    if (key === "intro") return !!(window.ForgeIntro && ForgeIntro.status());
    if (key === "transform") return ForgeForms.slots(p).length > 0;
    if (key === "links") return (p.tables.card_card_categories || []).length > 0;
    return null;
  }
  function renderBuilder() {
    if (ui.rendering) { ui.again = true; return; }
    ui.rendering = true;
    try { renderBuilderNow(); } finally {
      ui.rendering = false;
      if (ui.again) { ui.again = false; setTimeout(() => { if (state.builder && state.view === "editor") renderEditor(); }, 0); }
    }
  }
  // descriptions follow the character: whatever changed (a form renamed, a skill added or removed elsewhere),
  // the automatic descriptions are rewritten when the builder is drawn, and saved if they changed
  function syncTexts() {
    const p = state.project;
    if (!p || p.awaken) return;
    const snap = () => JSON.stringify([(p.tables.passive_skill_sets || []).map((x) => x.itemized_description), (p.tables.special_sets || []).map((x) => x.description), (p.tables.active_skill_sets || []).map((x) => [x.effect_description, x.condition_description]), (p.tables.transformation_descriptions || []).map((x) => x.description)]);
    const before = snap();
    try { refreshTexts(); } catch (e) { return; }
    if (snap() !== before) scheduleSave();
  }
  function renderBuilderNow() {
    const p = state.project;
    syncTexts();
    if (ui.key !== p.key) {
      const nowForm = !!(window.ForgeFormsUI && ForgeFormsUI.active());
      if (ui.key) state.builderTab = ui.wasForm && !nowForm ? "passive" : tabsFor()[0][0];   // a unit opens on its look first
      ui.wasForm = nowForm;
      ui.key = p.key; ui.open = ""; ui.adding = false; ui.leader = null;
      if (window.ForgeGuideUI && ForgeGuideUI.resetHistory) ForgeGuideUI.resetHistory();
    }
    const t = tab(), linked = !!(window.ForgeFormsUI?.active() && p.inheritedBaseSettings?.linked !== false);
    if (t === "supers" && ForgeSuperAttacks.missingEX(p).length) {
      const key=p.key+":"+ForgeSuperAttacks.missingEX(p).map(r=>r.id).join(",");
      if(ui.exHydrationKey!==key){ui.exHydrationKey=key;ForgeSuperAttacks.hydrateEX(p,q,state.info.schema).then(changed=>{if(changed&&state.project===p){scheduleSave();renderEditor();}}).catch(fail);}
    }
    if (["leader", "passive"].includes(t) && (!linked || t === "passive")) {
      const key = stageKey(t);
      if (key === "base") { if (!p.awaken && G.isolateAbilityStage(p, "base", t)) scheduleSave(); }
      else { const before = stageGroup(t).setId; if (B.ensureStageEditable(p, t, key) !== before) scheduleSave(); }
    }
    if (!(state.categories || []).length && !ui.lookupsLoading) ui.lookupsLoading = loadLookups().then(() => renderEditor()).catch(fail).finally(() => { ui.lookupsLoading = null; });
    const c = Forge.card(p), inForm = window.ForgeFormsUI && ForgeFormsUI.active();
    const TABS = tabsFor(), index = TABS.findIndex(([k]) => k === t), awaken = p.awaken;
    const banner = inForm ? '<div class="bld-form-banner"><div><p class="eyebrow">TRANSFORMED FORM</p><strong>Editing ' + h(c.name) + "</strong><p>This form belongs to " + h(Forge.card(ForgeFormsUI.root()).name) + ". Both save and export together.</p><p>" + (linked ? "Gameplay follows the base unit. Passive, Active, Super/EX, Domain and art stay separate." : "Inheritance is off. This form has separate gameplay settings.") + "</p></div>" + btn(linked ? "Customize inherited settings separately" : "Follow base gameplay settings", "tf-inherit-toggle", "ghost") + btn("← Back to the starting form", "form-leave", "button") + "</div>" : "";
    const html = '<div class="bld' + (awaken ? " bld-awaken" : "") + '" id="bld">' + banner + '<div class="section-heading bld-heading"><div><p class="eyebrow">' + (awaken ? (awaken.kind === "seza" ? "SUPER EZA BUILDER" : "EZA BUILDER") + " · GAME CARD #" + h(awaken.cardId) : "CARD BUILDER") + '</p><h1>' + h(c.name) + '</h1>' + dbProgress() + '</div><div class="row bld-tools">' + btn("✦ AI helper", "ai-helper", "small") + guide("↶ Undo", "undo", "subtle small") + guide("↷ Redo", "redo", "subtle small") + '<details class="bld-more"><summary class="button subtle small">⋯ More</summary><div class="bld-more-menu">' + btn("Help: what do these words mean?", "glossary", "ghost small") + (awaken ? "" : btn("Classic editor", "mode:classic", "ghost small")) + '<button type="button" class="button ghost small" data-action="project-versions">Saved versions</button>' + '</div></details></div></div>' + tabTip(t) + '<nav class="bld-tabs" aria-label="Builder steps">' + TABS.map(([k, n, icon], i) => {
      const status = tabStatus(k);
      return '<button type="button" class="bld-tab' + (k === t ? " active" : "") + '" data-b="tab:' + k + '"' + (k === t ? ' aria-current="step"' : "") + '><span class="bld-tab-icon">' + icon + "</span><span>" + h(n) + "</span>" + (status === true ? '<span class="bld-dot" aria-label="set up"></span>' : "") + "</button>";
    }).join("") + '</nav><div class="bld-layout"><aside class="bld-preview" aria-label="Live card preview"><div id="bld-card">' + cardHTML() + '</div></aside><div class="bld-main">' + body() + '<div class="bld-footer">' + (index > 0 ? btn("← " + TABS[index - 1][1], "tab:" + TABS[index - 1][0], "ghost") : "<span></span>") + '<span class="muted">' + (index + 1) + " / " + TABS.length + "</span>" + (index < TABS.length - 1 ? btn(TABS[index + 1][1] + " →", "tab:" + TABS[index + 1][0], "button") : "<span></span>") + "</div></div></div></div>";
    main(html);
    document.getElementById("main").classList.add("bld-page");
    bind(document.getElementById("bld"));
    if (linked && ["basics", "leader", "links"].includes(t)) {
      document.querySelectorAll('.bld-main > section input, .bld-main > section select, .bld-main > section textarea, .bld-main > section button').forEach(el => {
        if (el.dataset.bind === 'cardOverrides.name' || ['card:name','card:skill_lv_max'].includes(el.dataset.bind || el.dataset.bf)) return;
        el.disabled = true;
      });
      const notice = document.createElement('p'); notice.className = 'notice';
      notice.textContent = 'These settings follow your base unit. Edit them on the starting form, or choose “Customize inherited settings separately” above.';
      document.querySelector('.bld-main')?.prepend(notice);
    }
    if (ui.pending.size) loadPending().then((changed) => {
      if (!changed || state.view !== "editor") return;
      // descriptions written while conditions were still loading are finished now
      if (ui.textsStale) { ui.textsStale = false; refreshTexts(); if (!ui.textsStale) scheduleSave(); }
      renderEditor();
    }).catch(fail);
    else passiveBaseline();
  }

  // ------------------------------------------------------------ events
  function bind(root) {
    if (!root) return;
    root.addEventListener("click", (ev) => {
      const el = ev.target.closest("[data-b]");
      if (!el || !root.contains(el)) return;
      ev.preventDefault();
      Promise.resolve().then(() => run(el.dataset.b, el)).catch(fail);
    });
    root.addEventListener("change", (ev) => {
      const el = ev.target;
      try {
        if (el.matches("[data-bf]")) return onEditor(el);
        if (el.matches("[data-cf], [data-cmode]")) return onCondition(el);
        if (el.matches("[data-cadd]")) return onConditionAdd(el);
        if (el.matches("[data-whoname]")) { run("who-name:" + el.dataset.whoname + ":" + el.value, el).catch(fail); return; }
        if (el.matches("[data-bsel]")) { if (el.value !== "") run(el.dataset.bsel + ":" + el.value, el); return; }
        if (el.matches("[data-bsel-num]")) return run(el.dataset.bselNum + ":" + el.value, el);
        if (el.matches("[data-bauto]")) return onAuto(el);
        if (el.matches("[data-lg]")) return onLeaderField(el);
        if (el.matches("[data-b-split]")) { ui.leader.split = ui.leader.split || {}; ui.leader.split[el.dataset.bSplit] = el.checked; if (!el.checked) { const g = ui.leader.groups[Number(el.dataset.bSplit)]; g.atk = g.def = g.hp; applyLeader(); } else renderEditor(); return; }
        if (el.matches("[data-bind]")) setTimeout(() => { if (!state.project) return; refreshTexts(); scheduleSave(); refreshCard(); }, 0);
      } catch (e) { fail(e); }
    });
    root.addEventListener("input", (ev) => {
      const el = ev.target;
      if (el.matches("[data-manual]")) {
        setAuto(el.dataset.manual, false);
        requestAnimationFrame(paintPdescPreviews);
        const toggle = el.dataset.manual.startsWith("passive:") ? "passive" : el.dataset.manual;
        const box = root.querySelector('[data-bauto="' + toggle + '"]');
        if (box) box.checked = false;
      }
      if (el.matches("[data-catfilter]")) {
        const [i, f] = el.dataset.catfilter.split(":"), pick = root.querySelector('[data-catpick="' + i + ":" + f + '"]'), text = el.value.trim().toLocaleLowerCase();
        if (pick) pick.innerHTML = selection(categoryOptionsList().filter(([, n]) => n.toLocaleLowerCase().includes(text)), "");
      }
      if (el.matches('[data-bind^="card:"], [data-bind^="table:"]')) { clearTimeout(ui.cardTimer); ui.cardTimer = setTimeout(refreshCard, 120); }
    });
  }
  function onAuto(el) {
    const key = el.dataset.bauto, p = state.project;
    if (key === "leader") { const set = leaderSet(); setAuto("leader:" + (set && set.id), el.checked); if (el.checked && ui.leader && ui.leader.groups) applyLeader(); return; }
    if (key === "passive") { const set = passiveSet(); if (set) { setAuto("passive:" + set.id, el.checked); if (state.project.builderLines) delete state.project.builderLines[set.id]; } }
    else setAuto(key, el.checked);
    commit(() => {});
  }
  // Number and select edits update rows in place without rebuilding the page, so a tap that
  // follows typing (which fires "change" on blur) still lands on its button.
  function softRefresh(box) {
    if (!box) return;
    const [kind, rawId] = (box.dataset.edit || "").split(":"), id = Number(rawId), p = state.project, title = box.querySelector(".bld-ability-head strong");
    if (kind === "passive") {
      const row = p.tables.passive_skills.find((r) => r.id === id);
      if (row && title) title.textContent = B.passiveLine(row, Number(row.efficacy_type) === 103 ? { formName: formNameOf(row.eff_value1) } : {});
      const when = box.querySelector(".bld-when");
      if (row && when) when.textContent = B.passiveHeading(row, condInfo(row).text);
      const sum = box.querySelector(".pf-summary");
      if (row && sum && window.ForgePassiveFamilies) { const t = document.createElement("div"); t.innerHTML = ForgePassiveFamilies.summaryHTML(row, B.passiveHeading(row, condInfo(row).text), B.passiveLine(row), condInfo(row).text); sum.replaceWith(t.firstChild); }
      const help = box.querySelector('select[data-bf="s.timing"] + .pf-help');
      if (row && help) help.textContent = TIMING_HELP[Number(row.exec_timing_type)] || "";
    } else if (kind === "special") {
      const row = p.tables.specials.find((r) => r.id === id);
      if (row && title) title.textContent = B.cap(B.specialPhrase(row).text || "Special effect");
    } else if (kind === "activefx") {
      const row = p.tables.active_skills.find((r) => r.id === id), d = row && B.decodeActive(row);
      if (d && title) { const def = B.activeDef(d.key), t = Number(row.target_type); title.textContent = B.cap(def.text(B.normalizeValues(def.fields, d.values), (B.TARGETS[t] || {}).owner || "", t)); }
    }
    syncTextareas();
  }
  function syncTextareas() {
    document.querySelectorAll('#bld textarea[data-bind^="table:"]').forEach((el) => {
      if (el === document.activeElement) return;
      const [, table, id, field] = el.dataset.bind.split(":"), row = (state.project.tables[table] || []).find((r) => r.id === Number(id));
      if (row && el.value !== String(row[field] || "")) el.value = row[field] || "";
    });
    paintPdescPreviews();
  }
  function onEditor(el) {
    const box = el.closest("[data-edit]");
    if (!box) return;
    const [kind, rawId] = box.dataset.edit.split(":"), id = Number(rawId), p = state.project, data = readEditor(box);
    if (kind === "passive") {
      const row = p.tables.passive_skills.find((r) => r.id === id), decoded = B.decodePassive(row), s = Object.assign(B.settingsOf(row), data.s || {});
      return commit(() => {
        if (decoded) B.updatePassiveAbility(row, decoded.key, Object.assign({}, decoded.values, data.v), s);
        else {
          row.exec_timing_type = Number(s.timing); row.target_type = Number(s.target); row.turn = Number(s.turn);
          row.probability = Math.min(100, Math.max(1, Math.round(Number(s.chance) || 100))); row.is_once = s.once ? 1 : 0;
        }
      }, { render: false, box });
    }
    if (kind === "special") {
      const row = p.tables.specials.find((r) => r.id === id), d = B.decodeSpecial(row);
      if (!d) return;
      return commit(() => Object.assign(row, B.specialFields(d.key, Object.assign({}, d.values, data.v), { target: data.s && data.s.target !== undefined ? data.s.target : row.target_type, turn: data.s && data.s.turn !== undefined ? data.s.turn : row.turn, chance: data.s && data.s.chance !== undefined ? data.s.chance : row.prob })), { render: false, box });
    }
    if (kind === "activefx") {
      const row = p.tables.active_skills.find((r) => r.id === id), d = B.decodeActive(row);
      if (!d) return;
      return commit(() => Object.assign(row, B.activeFields(d.key, Object.assign({}, d.values, data.v), data.s && data.s.target !== undefined ? data.s.target : row.target_type)), { render: false, box });
    }
  }
  function onCondition(el) {
    const box = el.closest("[data-cond]");
    if (!box) return;
    const [kind, rawId] = box.dataset.cond.split(":"), spec = readConditions(box);
    if (kind === "tfnew") { ui.tf.cond = spec; const sum = box.querySelector(".bld-cond-summary"); if (sum) sum.textContent = B.cap(B.conditionText(spec, names())) + "."; return; }
    setConditions(kind, Number(rawId), spec, el.tagName === "INPUT", el.closest("[data-edit]") || box);
  }
  async function onConditionAdd(el) {
    const box = el.closest("[data-cond]"), key = el.value;
    if (!box || !key) return;
    const [kind, rawId] = box.dataset.cond.split(":"), spec = readConditions(box), values = B.conditionDefaults(key);
    if (B.conditionDef(key).fields.some((f) => f.kind === "category")) values.category = (categoryOptionsList()[0] || [0])[0];
    if (B.conditionDef(key).fields.some((f) => f.kind === "nameSet")) { if (window.ForgeNameSets) { await ForgeNameSets.load().catch(() => {}); values.set = ForgeNameSets.first(); } }
    spec.items.push({ key, values });
    if (kind === "tfnew") { ui.tf.cond = spec; return renderEditor(); }
    setConditions(kind, Number(rawId), spec);
  }
  function onLeaderField(el) {
    const g = ui.leader.groups[Number(el.dataset.lg)], f = el.dataset.lf;
    if (f === "who") { g.who = el.value; if (el.value === "categories" && !g.categories) g.categories = []; }
    else if (f === "all") g.hp = g.atk = g.def = Number(el.value);
    else g[f] = Number(el.value);
    applyLeader(el.tagName === "INPUT");
  }
  async function run(action, el) {
    const [cmd, ...rest] = action.split(":"), arg = rest.join(":"), p = state.project;
    switch (cmd) {
      case "tab": {
        await flushSave();
        // the intro and transformations now live inside the Passive Skill step
        if (arg === "transform") ui.tfAdding = true;
        const inside = { intro: "bld-intro", transform: "bld-tf-new", revival: "bld-passive-list" }[arg];
        state.builderTab = inside ? "passive" : arg; ui.open = ""; ui.adding = false; renderEditor();
        const spot = inside && document.getElementById(inside);
        if (spot) spot.scrollIntoView({ block: "start" }); else window.scrollTo(0, 0);
        return;
      }
      case "home": return navigate("home");
      case "glossary": return glossary();
      case "stage": { const [kind, ...key] = arg.split(":"); setStage(kind, key.join(":")); ui.open = ""; ui.adding = false; ui.leader = null; return renderEditor(); }
      case "eza-seza": return commit(() => { B.addSuperEza(p); setStage("passive", "steps:8-8"); });
      case "eza-medals": return ForgeGuideUI.pickUnit("Use the EZA medals of which card?", (card) => busy("Reading " + card.name + "'s medals", async () => { const medals = await medalsFrom(card.id); if (!Object.keys(medals).length) throw new Error(card.name + " has no EZA medals. Choose a card that has an Extreme Z-Awakening."); commit(() => B.setAwakenMedals(p, medals, card.name)); }));
      case "super-add-eza": return commit(() => { const made = B.createSuper(p, state.info.schema, { style: arg, lvStart: 14, ki: arg === "Hyper" ? 18 : 12, name: ((p.tables.special_sets || []).find((s2) => s2.id === ((p.tables.card_specials || []).find((r) => r.style === arg) || {}).special_set_id) || {}).name || "EZA Super Attack", profile: profiles().find((x) => x.key === (arg === "Hyper" ? "mega-colossal" : "immense")), profiles: profiles(), effects: [{ key: "atk", values: { amount: arg === "Hyper" ? 100 : 50 }, settings: { target: 1, turn: 99 } }] }); setAuto("sa:" + made.set.id, true); });
      case "ai-helper": return window.ForgeAIConnect ? ForgeAIConnect.openHelper(arg ? decodeURIComponent(arg) : "") : toast("The AI helper is unavailable.", true);
      case "ai-art": return window.ForgeAIConnect ? ForgeAIConnect.openArt() : toast("AI art is unavailable.", true);
      case "mode": await flushSave(); state.builder = arg !== "classic"; try { localStorage.setItem("forge-builder", state.builder ? "on" : "off"); } catch {} renderEditor(); window.scrollTo(0, 0); return;
      case "card-toggle": ui.cardOpen = !ui.cardOpen; return refreshCard();
      case "open": ui.open = ui.open === arg ? "" : arg; return renderEditor();
      case "adding": ui.adding = arg === "on"; renderEditor(); if (ui.adding) document.querySelector(".bld-picker")?.scrollIntoView({ block: "start" }); return;
      case "rarity": return commit(() => { p.cardOverrides.rarity = Number(arg); });
      case "class": return commit(() => { p.cardOverrides.element = B.elementValue(Number(arg), B.elementParts(Forge.card(p).element).type); });
      case "type": return commit(() => { const parts = B.elementParts(Forge.card(p).element); p.cardOverrides.element = B.elementValue(parts.cls || 1, Number(arg)); });
      case "tf-base-copy": return commit(() => { const form = p.formProjects?.[Number(arg)]; if (!form) throw Error("Choose a transformation first."); ForgeFormInheritance.copy(p, form); });
      case "tf-inherit-toggle": return ForgeFormsUI.setInheritance(p.inheritedBaseSettings?.linked === false);
      case "tf-base-current": return commit(() => { ForgeFormInheritance.copy(ForgeFormsUI.root(), p); });
      case "tf-preset": ui.tf.cond = arg === "hp" ? {mode:"all",items:[{key:"hpBelow",values:{hp:50}}]} : arg === "always" ? {mode:"all",items:[]} : {mode:"all",items:[{key:"turn",values:{turn:4}}]}; return renderEditor();
      case "form-leave": return ForgeFormsUI.leave("editor");
      case "form-enter": return ForgeFormsUI.enter(Number(arg));
      case "tf-include": return busy("Copying the transformations into your unit", async () => {
        await flushSave();
        const parent = state.project, baseline = JSON.stringify(parent), projects = await Native.call("projects");
        const result = await ForgeTemplateForms.include(parent, { query: (o) => Native.call("query", o), schema: state.info.schema, projects });
        if (state.project !== parent || JSON.stringify(parent) !== baseline) throw new Error("Your unit changed. Try again.");
        if (!result.added.length) throw new Error("These transformations could not be copied. They keep using the original game cards.");
        state.project = result.project;
        refreshTexts();
        scheduleSave();
        await flushSave();
        renderEditor();
        toast(ForgeTemplateForms.message(result));
      });
      // leader
      case "leader-new": ui.leader.groups = [B.leaderGroupDefaults("all")]; ui.leader.decodedOk = true; return applyLeader();
      case "leader-preset": {
        const presets = { "all-170": [{ who: "all", ki: 3, hp: 170, atk: 170, def: 170 }], "super-200": [{ who: "super", ki: 3, hp: 200, atk: 200, def: 200 }], "extreme-200": [{ who: "extreme", ki: 3, hp: 200, atk: 200, def: 200 }], "cat-modern": [{ who: "categories", categories: [((p.tables.card_card_categories || [])[0] || {}).card_category_id || (categoryOptionsList()[0] || [1])[0]], ki: 3, hp: 170, atk: 170, def: 170 }], "all-150": [{ who: "all", ki: 3, hp: 150, atk: 150, def: 150 }], "type-130": [{ who: "types", types: [B.elementParts(Forge.card(p).element).type], ki: 4, hp: 130, atk: 130, def: 130 }], "super-80": [{ who: "super", ki: 3, hp: 80, atk: 80, def: 80 }], "extreme-80": [{ who: "extreme", ki: 3, hp: 80, atk: 80, def: 80 }] };
        ui.leader = Object.assign(ui.leader || {}, { groups: presets[arg].map((g) => Object.assign(B.leaderGroupDefaults(g.who), g)) });
        return applyLeader();
      }
      // a fresh, empty tier: nothing is copied from the bonuses already there
      case "lg-add": ui.leader.groups.push(Object.assign(B.leaderGroupDefaults("categories"), { ki: 1, hp: 30, atk: 30, def: 30, categories: [], also: [] })); return applyLeader();
      case "lg-del": ui.leader.groups.splice(Number(arg), 1); return applyLeader();
      case "lg-type": { const [i, t] = arg.split(":").map(Number), g = ui.leader.groups[i]; g.types = g.types || []; g.types = g.types.includes(t) ? g.types.filter((x) => x !== t) : g.types.concat(t); return applyLeader(); }
      case "lg-ct": { const [i, m] = arg.split(":").map(Number), g = ui.leader.groups[i]; g.classTypes = g.classTypes || []; g.classTypes = g.classTypes.includes(m) ? g.classTypes.filter((x) => x !== m) : g.classTypes.concat(m); return applyLeader(); }
      case "lg-cat-add": { const [i, f] = arg.split(":"), pick = document.querySelector('[data-catpick="' + i + ":" + f + '"]'), id = Number(pick && pick.value); if (!id) throw new Error("Search for a Category, then choose it from the list."); const g = ui.leader.groups[Number(i)]; g[f] = (g[f] || []).filter((x) => x !== id).concat(id); return applyLeader(); }
      case "lg-cat-del": { const [i, f, id] = arg.split(":"), g = ui.leader.groups[Number(i)]; g[f] = (g[f] || []).filter((x) => x !== Number(id)); return applyLeader(); }
      // passive
      case "passive-fit": { let fixed = []; commit(() => { fixed = ForgePassiveMerge.fitToMeta(state.project, editableSet("passive")); }); return toast(fixed.length ? "Fitted to today’s meta: " + fixed.join(", ") : "Already within today’s meta."); }
      case "pcat": { const C = window.ForgePassiveCatalog; if (!C) throw new Error("The ability list is still loading. Try again."); if (arg === "copy") return C.copyChooser(); return window.ForgePassiveFamilies ? ForgePassiveFamilies.open(arg) : C.open(arg); }
      case "passive-add": { let row; commit(() => { row = B.addPassiveAbility(target("passive"), arg); }, { render: false }); ui.adding = false; if (row) ui.open = "passive:" + row.id; renderEditor(); document.querySelector('[data-edit="passive:' + (row && row.id) + '"]')?.scrollIntoView({ block: "center" }); return; }
      case "send-files": {
        dialog("Export your creation", '<p>Pick a file type.</p><div class="send-game-row">' +
          '<button type="button" class="send-btn send-files" data-export="sql"' + (Forge.validate(p).errors.length ? " disabled" : "") + '><strong>.SQL</strong><small>Game data only — for tools or adding to a database by hand. No pictures or animations.</small></button>' +
          '<button type="button" class="send-btn send-files" data-export="json"><strong>.JSON</strong><small>Your editable unit — import it later to keep working on it.</small></button></div>');
        document.querySelectorAll('#dialog [data-export]').forEach((b) => b.onclick = () => { document.getElementById("dialog").close(); exportProject(b.dataset.export); });
        return;
      }
      case "passive-del": { const id = Number(arg), row = p.tables.passive_skills.find((r) => r.id === id);
        if (row && /Exclusive$/.test(row.name || "")) return toast("The " + row.name + " is permanent. It comes with the unit's level (SLR 180 / GR 200).", true); if (row && Number(row.efficacy_type) === 103) return commit(() => B.removeTransformation(p, "passive_skills", id)); return commit(() => Forge.removePassive(p, id)); }
      case "cond-del": { const [kind, id, i] = arg.split(":"), box = el.closest("[data-cond]"), spec = readConditions(box); spec.items.splice(Number(i), 1); return setConditions(kind, Number(id), spec); }
      case "cond-reset": { const [kind, id] = arg.split(":"); return setConditions(kind, Number(id), { mode: "all", items: [] }); }
      // supers
      case "power": { const profile = profiles().find((x) => x.key === arg.split(":")[1]), set = p.tables.special_sets.find((s) => s.id === Number(arg.split(":")[0])); if (!profile || !set) return; return commit(() => { set.increase_rate = profile.increase_rate; set.lv_bonus = profile.lv_bonus; }); }
      case "special-add": { const [setId, key] = arg.split(":"); let row; commit(() => { row = B.addSpecialEffect(p, Number(setId), key, {}); }, { render: false }); if (row) ui.open = "special:" + row.id; return renderEditor(); }
      case "special-del": return commit(() => { p.tables.specials = p.tables.specials.filter((r) => r.id !== Number(arg)); });
      case "super-copy": return ForgeSuperAttacks.pick(arg ? Number(arg) : null);
      case "super-style": { const split=arg.lastIndexOf(":"),id=Number(arg.slice(0,split)),style=arg.slice(split+1);return commit(()=>ForgeSuperAttacks.setStyle(p,state.info.schema,id,style)); }
      case "super-extype": { const [id,value]=arg.split(":");return commit(()=>{const t=Number(value),row=(p.tables.extra_special_options||[]).find(r=>r.card_special_id===Number(id)),rel=(p.tables.card_specials||[]).find(r=>r.id===Number(id));if(!row||!rel)throw Error("Choose EX as this attack's type first.");if(![0,1,2].includes(t))throw Error("Choose when the EX attack can happen.");row.extra_special_type=t;rel.priority=EX_PRIORITY[t];const set=(p.tables.special_sets||[]).find(x=>x.id===rel.special_set_id);if(set&&"causality_description" in set||set)set.causality_description=exText(t,row.probability);}); }
      case "super-chance": { const [id,value]=arg.split(":");return commit(()=>{const row=(p.tables.extra_special_options||[]).find(r=>r.card_special_id===Number(id));if(!row)throw Error("Choose EX as this attack's type first.");const chance=Number(value);if(!Number.isInteger(chance)||chance<1||chance>100)throw Error("Choose a chance between 1 and 100%.");row.probability=chance;const rel=(p.tables.card_specials||[]).find(r=>r.id===Number(id)),set=rel&&(p.tables.special_sets||[]).find(x=>x.id===rel.special_set_id);if(set)set.causality_description=exText(Number(row.extra_special_type)||0,chance);}); }
      case "super-add": return commit(() => { const made = B.createSuper(p, state.info.schema, { style: arg, name: arg === "Hyper" ? Forge.card(p).name + "'s Ultimate Strike" : arg === "Condition" ? "Conditional Power Strike" : arg === "Extra" ? "EX Power Strike" : "Power Strike", ki: arg === "Hyper" ? 18 : 12, profile: profiles().find((x) => x.key === (arg === "Hyper" ? "mega-colossal" : "supreme")), profiles: profiles(), effects: [{ key: "atk", values: { amount: arg === "Hyper" ? 50 : 30 }, settings: { target: 1, turn: arg === "Hyper" ? 99 : 1 } }] }); setAuto("sa:" + made.set.id, true); });
      case "super-del": { const rel = p.tables.card_specials.find((r) => r.id === Number(arg)); dialog("Remove this attack?", "<p>The attack and its effects are removed from your unit. You can add a new one afterwards.</p>" + '<div class="row"><button class="button" id="bld-confirm">Remove attack</button><button class="button ghost" id="bld-cancel">Keep it</button></div>'); document.getElementById("bld-cancel").onclick = () => document.getElementById("dialog").close(); document.getElementById("bld-confirm").onclick = () => { document.getElementById("dialog").close(); if (rel) commit(() => B.removeSuper(p, rel.id)); }; return; }
      // active
      case "active-kind": ui.activeKind = arg; return renderEditor();
      case "active-create": return createActive();
      case "active-del": dialog("Remove the Active Skill?", "<p>The Active Skill and its effects are removed. Transformations it performed are removed too.</p>" + '<div class="row"><button class="button" id="bld-confirm">Remove</button><button class="button ghost" id="bld-cancel">Keep it</button></div>'); document.getElementById("bld-cancel").onclick = () => document.getElementById("dialog").close(); document.getElementById("bld-confirm").onclick = () => { document.getElementById("dialog").close(); commit(() => B.removeActive(p, Number(arg))); }; return;
      case "active-turn": return commit(() => { activeSets().find((s) => s.id === Number(arg.split(":")[0])).turn = Number(arg.split(":")[1]); });
      case "active-limit": return commit(() => { activeSets().find((s) => s.id === Number(arg.split(":")[0])).exec_limit = Number(arg.split(":")[1]); });
      case "active-boost": { const [id, v] = arg.split(":"), set = activeSets().find((s) => s.id === Number(id)), cur = B.activeAttack(p, set); return commit(() => B.setActiveAttack(p, state.info.schema, set, { boost: Number(v), allEnemies: cur && cur.allEnemies })); }
      case "active-aim": { const [id, v] = arg.split(":"), set = activeSets().find((s) => s.id === Number(id)), cur = B.activeAttack(p, set); return commit(() => B.setActiveAttack(p, state.info.schema, set, { boost: cur ? cur.boost : 0, allEnemies: v === "1" })); }
      case "active-attack": { const set = activeSets().find((s) => s.id === Number(arg)); return commit(() => B.setActiveAttack(p, state.info.schema, set, { boost: 100, allEnemies: false })); }
      case "active-noattack": { const set = activeSets().find((s) => s.id === Number(arg)); return commit(() => B.setActiveAttack(p, state.info.schema, set, null)); }
      case "who": case "who-cat": case "who-del": case "who-self": case "who-name": {
        const [rid, val] = [Number(arg.split(":")[0]), arg.split(":").slice(1).join(":")];
        const row = (p.tables.passive_skills || []).find((r) => r.id === rid);
        if (!row) return;
        await ensureSubTargets();
        const mode = whoMode(row), entries = subEntries(row);
        if (cmd === "who") {
          if (val === "cat" || val === "name") {
            ui.whoMode = ui.whoMode || {}; ui.whoMode[rid] = val;
            if (entries.length && mode !== val) commit(() => setWho(row, [])); else renderEditor();
            return;
          }
          if (ui.whoMode) delete ui.whoMode[rid];
          return commit(() => setWho(row, [], Number(val)));
        }
        const type = mode === "name" || cmd === "who-name" ? 4 : 1;
        if (cmd === "who-cat" || cmd === "who-name") {
          const v = Number(val);
          if (!v || entries.some(([t, x]) => t === type && x === v)) return renderEditor();
          return commit(() => setWho(row, entries.filter(([t]) => t === type).concat([[type, v]])));
        }
        if (cmd === "who-del") { const keep = entries.filter((_, i) => i !== Number(val)); return commit(() => setWho(row, keep)); }
        if (cmd === "who-self") return commit(() => { row.target_type = el && el.checked ? 2 : 16; });
        return;
      }
      case "activefx-add": { const [setId, key] = arg.split(":"); let row; commit(() => { row = B.addActiveEffect(p, Number(setId), key, {}); }, { render: false }); if (row) ui.open = "activefx:" + row.id; return renderEditor(); }
      case "activefx-del": return commit(() => { p.tables.active_skills = p.tables.active_skills.filter((r) => r.id !== Number(arg)); });
      case "active-anim": return pickActiveAnimation(Number(arg));
      // transform
      case "revival-add": { const row = window.ForgePassiveFamilies && ForgePassiveFamilies.addNow("revive"); if (row) { ui.open = "passive:" + row.id; renderEditor(); const el = document.getElementById("bld-revival"); if (el) el.scrollIntoView({ block: "start" }); } return; }
      case "revival-tf": ui.tfAdding = true; ui.tf.how = "revival"; renderEditor(); { const el = document.getElementById("bld-tf-new"); if (el) el.scrollIntoView({ block: "start" }); } return;
      case "tf-adding": ui.tfAdding = arg === "on"; renderEditor(); if (ui.tfAdding) { const el = document.getElementById("bld-tf-new"); if (el) el.scrollIntoView({ block: "start" }); } return;
      case "tf-how": ui.tf.how = arg; return renderEditor();
      case "tf-into": ui.tf.into = arg; return renderEditor();
      case "tfcond-del": ui.tf.cond.items.splice(Number(arg), 1); return renderEditor();
      case "tf-create": return ForgeGuideUI.pickUnit(ui.tf.into === "custom" ? "Which character should the new form start from?" : "Which card does it transform into?", (card) => createTransformation(card), { allVersions: ui.tf.into !== "custom" });
      case "tf-del": { const [table, id] = [arg.slice(0, arg.lastIndexOf(":")), Number(arg.slice(arg.lastIndexOf(":") + 1))]; dialog("Remove this transformation?", "<p>The transformation is removed" + ((p.transformLinks || []).some((l) => l.table === table && l.row === id) ? ", together with its custom form" : "") + ". This can be undone with Undo.</p>" + '<div class="row"><button class="button" id="bld-confirm">Remove</button><button class="button ghost" id="bld-cancel">Keep it</button></div>'); document.getElementById("bld-cancel").onclick = () => document.getElementById("dialog").close(); document.getElementById("bld-confirm").onclick = () => { document.getElementById("dialog").close(); commit(() => B.removeTransformation(p, table, id)); }; return; }
      case "tf-form-del": {
        const form = (p.formProjects || [])[Number(arg)];
        if (!form) return;
        const rows = ForgeForms.slots(p).filter((slot) => slot.linkedKey === form.key || (p.transformLinks || []).some((l) => l.targetKey === form.key && l.table === slot.table && l.row === slot.row));
        dialog("Remove " + Forge.card(form).name + "?", "<p>Your unit will no longer transform into this form, and the form is deleted. This can be undone with Undo.</p>" + '<div class="row"><button class="button" id="bld-confirm">Remove</button><button class="button ghost" id="bld-cancel">Keep it</button></div>');
        document.getElementById("bld-cancel").onclick = () => document.getElementById("dialog").close();
        document.getElementById("bld-confirm").onclick = () => { document.getElementById("dialog").close(); commit(() => {
          for (const slot of rows) B.removeTransformation(p, slot.table, slot.row);
          p.formProjects = (p.formProjects || []).filter((f) => f.key !== form.key);
          if (p.transformLinks) p.transformLinks = p.transformLinks.filter((l) => l.targetKey !== form.key);
          ForgeForms.prune(p);
        }); };
        return;
      }
      case "tf-custom": case "tf-card": { const table = arg.slice(0, arg.lastIndexOf(":")), id = Number(arg.slice(arg.lastIndexOf(":") + 1)); return ForgeGuideUI.pickUnit(cmd === "tf-custom" ? "Which character should the new form start from?" : "Which card does it transform into?", (card) => retarget(table, id, card, cmd === "tf-custom"), { allVersions: cmd === "tf-card" }); }
    }
  }
  async function createActive() {
    const p = state.project, kind = ui.activeKind, name = (document.getElementById("bld-active-name") || {}).value || "Active Skill";
    await busy("Creating your Active Skill", async () => {
      const id = kind === "attack" ? 388 : 342, ex = (await Native.call("query", { table: "active_skill_sets", ids: [id], limit: 1 }))[0];
      if (state.project !== p) throw new Error("Your unit changed. Try again.");
      commit(() => {
        const set = B.createActive(p, state.info.schema, { name, viewId: ex && ex.special_view_id, bgmId: ex && ex.bgm_id, attack: kind === "attack" ? { boost: 100, allEnemies: false } : null, effects: kind === "attack" ? [] : [{ key: "ki", values: { amount: 10 }, target: 1 }, { key: "atkdef", values: { atk: 100, def: 100 }, target: 1 }] });
        B.applyCondition(p, state.info.schema, set, { mode: "all", items: [{ key: "turn", values: { turn: 4 } }] });
        setAuto("active:" + set.id, true);
        if (ex) { p.uiLabels = p.uiLabels || {}; p.uiLabels.animations = p.uiLabels.animations || {}; p.uiLabels.animations["active:" + set.id] = "Animation from “" + ex.name + "”"; }
      });
    });
  }
  async function pickActiveAnimation(setId) {
    dialog("Choose an Active Skill animation", '<p>Search the game’s Active Skills by name. The chosen animation (with its cut-in and music) is used for your Active Skill; its effects are not copied.</p><label class="field">Active Skill name<input id="bld-anim-search" type="search" placeholder="Kamehameha, Final Flash, Power…"></label><div id="bld-anim-results"><p class="hint">Type to search…</p></div>');
    let timer, seq = 0;
    const search = async () => {
      const input = document.getElementById("bld-anim-search");
      if (!input) return;
      const token = ++seq, rows = (await q({ table: "active_skill_sets", search: { column: "name", text: input.value }, order: "id", limit: 60 })).filter((r) => r.special_view_id);
      if (token !== seq) return;
      const box = document.getElementById("bld-anim-results");
      if (!box) return;
      box.innerHTML = rows.length ? '<div class="guide-picks">' + rows.slice(0, 40).map((r) => '<button class="guide-pick" data-anim="' + r.id + '"><span><strong>' + h(r.name) + "</strong><small>" + h(r.ultimate_special_id ? "Ultimate attack" : "Power-up / scene") + "</small></span></button>").join("") + "</div>" : '<p class="hint">No Active Skills with animations match that name.</p>';
      box.querySelectorAll("[data-anim]").forEach((b) => b.onclick = () => {
        const ex = rows.find((r) => r.id === Number(b.dataset.anim)), set = activeSets().find((s) => s.id === setId);
        document.getElementById("dialog").close();
        if (!ex || !set) return;
        commit((p) => {
          set.special_view_id = ex.special_view_id;
          set.bgm_id = ex.bgm_id;
          B.dropAnimation(p, "active:" + set.id, "active_skill_sets", set.id);
          p.uiLabels = p.uiLabels || {}; p.uiLabels.animations = p.uiLabels.animations || {};
          p.uiLabels.animations["active:" + set.id] = "Animation from “" + ex.name + "”";
        });
      });
    };
    document.getElementById("bld-anim-search").oninput = () => { clearTimeout(timer); timer = setTimeout(() => search().catch(fail), 250); };
    await search();
  }

  // ------------------------------------------------------------ hooks into the app
  renderEditor = function() {
    if (!state.builder || !state.project || state.view !== "editor") {
      prior.renderEditor.apply(this, arguments);
      document.getElementById("main")?.classList.remove("bld-page");
      if (state.project && state.view === "editor" && !document.getElementById("bld-open")) {
        const heading = document.querySelector("#main .section-heading .row") || document.querySelector("#main .section-heading");
        if (heading) {
          const b = document.createElement("button");
          b.type = "button"; b.id = "bld-open"; b.className = "button small"; b.textContent = "✦ Card Builder";
          b.onclick = () => run("mode:builder").catch(fail);
          heading.prepend(b);
        }
      }
      return;
    }
    renderBuilder();
  };
  renderPreview = function() {
    prior.renderPreview.apply(this, arguments);
    if (state.builder && state.view === "editor") refreshCard();
  };
  // The skill set of the stage open in the builder, made private to that stage so it can change.
  function editableSet(kind) {
    const key = stageKey(kind);
    return B.ensureStageEditable(state.project, kind, key);
  }
  function setStageSet(kind, id) {
    const p = state.project, key = stageKey(kind), g = B.stageGroups(p, kind).find((x) => x.key === key);
    if (!g || g.key === "base") {
      if (p.awaken) throw new Error("The card's original abilities stay as they are in the game. Choose an EZA step to edit.");
      p.cardOverrides[kind + "_skill_set_id"] = id;
      return;
    }
    for (const row of p.tables.optimal_awakening_growths || []) if (g.steps.includes(Number(row.step))) row[kind + "_skill_set_id"] = id;
  }
  // Adds one game row to the passive being edited (the EZA step shown, if any), with undo and a fresh description.
  function addRow(kind, fields, opts = {}) {
    let row;
    commit(() => { const tp = target(kind); row = Forge.addPassive(tp, fields); const set = Forge.primaryPassive(tp); if (set && set.name) row.name = set.name; }, { render: false });
    ui.adding = false;
    if (row && opts.open) ui.open = "passive:" + row.id;
    renderEditor();
    if (row) document.querySelector('[data-edit="passive:' + row.id + '"]')?.scrollIntoView({ block: "center" });
    return row;
  }
  // removes the condition rules matching `pred` from every ability (used when a custom name is deleted)
  function dropConditions(pred) {
    let n = 0;
    commit((p) => {
      for (const rows of Object.values(p.tables)) for (const row of rows || []) {
        if (!row || typeof row.causality_conditions !== "string") continue;
        const info = condInfo(row);
        if (!info.spec || !info.spec.items) continue;
        const keep = info.spec.items.filter((i) => !pred(i));
        if (keep.length !== info.spec.items.length) { n += info.spec.items.length - keep.length; B.applyCondition(p, state.info.schema, row, Object.assign({}, info.spec, { items: keep })); }
      }
    }, { render: false });
    return n;
  }
  // the description the builder writes for one passive set (used by previews, e.g. combining passives)
  function describeSet(project, setId) {
    // conditions are looked up in that project first (copied abilities bring their own condition rows)
    const own = project.tables.skill_causalities || [];
    const look = (id) => own.find((r) => r.id === id) || lookupCausality(id);
    const fn = (row) => {
      const d = B.decodeCondition(row.causality_conditions, look);
      if (!d) return "";
      if (d.pending || d.custom) return conditionWords(row, look) || "";
      return B.conditionText(d, names());
    };
    fn.extra = (row) => lineExtra(row, project);
    try { return B.passiveText(rowsOfSet(project, setId), fn); } catch { return ""; }
  }
  // loads every game condition row a project's abilities use (for copied abilities), and the character names
  async function loadCausalities(project) {
    const own = new Set((project.tables.skill_causalities || []).map((r) => r.id)), ids = new Set();
    for (const rows of Object.values(project.tables)) for (const row of rows || []) {
      if (!row || typeof row.causality_conditions !== "string") continue;
      try { JSON.stringify(JSON.parse(row.causality_conditions).compiled).replace(/-?\d+/g, (n) => { n = Number(n); if (!own.has(n) && lookupCausality(n) === undefined) ids.add(n); return n; }); } catch {}
    }
    for (const id of ids) if (!ui.requested.has(id)) ui.pending.add(id);
    await Promise.all([loadPending(), window.ForgeNameSets ? ForgeNameSets.load().catch(() => {}) : null, ensureSubTargets().catch(() => {})]);
  }
  window.ForgeBuilderUI = { itemized: (t) => itemized(t), addRow, dropConditions, describeSet, loadCausalities, commit: (work, o) => commit(work, o), render: () => renderEditor(), tab: (key) => run("tab:" + key), refreshTexts, open: (key) => { ui.open = key; renderEditor(); }, startAwaken, startAwakenOwn, glossary, target: (kind) => target(kind), editableSet, setStageSet, stageKey };
})();
// Keep the Basics "Rarity, class & type" line open while you change them (the tab re-renders on each tap).
document.addEventListener("toggle", (e) => { if (e.target && e.target.classList && e.target.classList.contains("bld-identity") && typeof state !== "undefined") state.identityOpen = e.target.open; }, true);
// ------------------------------------------------------------ level perks (Basics → Maximum level)
// Level 180: team cost 88, Super Attack level 30. Level 200: team cost 99, Super Attack level 30 and a permanent
// ATK & DEF +20% in the passive (Godly Exclusive); level 180 gets +10% the same way (Super Exclusive). Going back below 180 undoes them (earlier cost and SA level return, +20% removed).
(function () {
  const PERKS = { 180: { sa: 30, boost: 10, dr: 10, cost: 88, title: "Super Exclusive" }, 200: { sa: 30, boost: 20, dr: 20, cost: 99, title: "Godly Exclusive" } };
  const drFor = (boost) => ((Object.values(PERKS).find((x) => x.boost === boost) || {}).dr || 0);
  const titleFor = (boost) => ((Object.values(PERKS).find((x) => x.boost === boost) || {}).title || "Godly Exclusive");
  // ---- Godly Exclusive in EVERY passive the unit has: before EZA, each EZA / Super EZA step, and each
  // transformation form (and its EZA steps). Rebuilt from scratch whenever it's out of step, so it's always
  // exactly one ATK row + one DEF row per passive.
  const GODLY = /Exclusive$/;
  const projectsOf = (p) => [p].concat((p.formProjects || []).filter((f) => f && f.tables));
  function passiveSetIdsOf(proj) {
    const B2 = window.ForgeBuilder, ids = [];
    const groups = B2 && B2.stageGroups ? B2.stageGroups(proj, "passive") : [{ setId: Forge.card(proj).passive_skill_set_id }];
    for (const g of groups) if (g.setId != null && !ids.includes(g.setId)) ids.push(g.setId);
    return ids;
  }
  function godlyBlock(boost) { return "*" + titleFor(boost) + "*\n- ATK & DEF " + boost + "%{passiveImg:up_g}, applied after every other boost\n- Reduces damage received by " + drFor(boost) + "%"; }
  function setGodlyText(set, boost) {
    const text = String(set.itemized_description || "").replace(/\n?\*[^*\n]*Exclusive\*(\n- [^\n]*)*/g, "").trim();
    set.itemized_description = boost ? godlyBlock(boost) + (text ? "\n" + text : "") : text;
  }
  function godlyInSync(p, boost) {
    for (const proj of projectsOf(p)) {
      const rows = (proj.tables.passive_skills || []).filter((r) => GODLY.test(r.name || ""));
      const rel = proj.tables.passive_skill_set_relations || [];
      for (const setId of passiveSetIdsOf(proj)) {
        const inSet = rows.filter((r) => rel.some((x) => x.passive_skill_id === r.id && x.passive_skill_set_id === setId));
        if (boost ? !(inSet.length === 3 && inSet.every((r) => r.name === titleFor(boost) && !r.causality_conditions && Number(r.probability) === 100 && !Number(r.is_once) && (Number(r.efficacy_type) === 13 ? Number(r.eff_value1) === 100 - drFor(boost) : Number(r.eff_value1) === boost)) && inSet.filter((r) => Number(r.efficacy_type) === 13).length === 1 && new RegExp("^\\*" + titleFor(boost) + "\\*").test(((proj.tables.passive_skill_sets || []).find((x) => x.id === setId) || {}).itemized_description || "")) : inSet.length) return false;
      }
      if (!boost && rows.length) return false;
    }
    return true;
  }
  function syncGodly(p, boost) {
    const FB = window.ForgeBuilder;
    let added = 0;
    for (const proj of projectsOf(p)) {
      for (const r of (proj.tables.passive_skills || []).filter((x) => GODLY.test(x.name || "") || x.name === "Level 200 Exclusive")) Forge.removePassive(proj, r.id);
      for (const setId of passiveSetIdsOf(proj)) {
        const set = (proj.tables.passive_skill_sets || []).find((x) => x.id === setId);
        if (!set) continue;
        if (boost) {
          // ATK "during the attack" and DEF "just before receiving an attack": the game's multiplicative stages,
          // so the boost multiplies the fully boosted stats (leader, links and the rest of the passive first).
          const view = Object.assign({}, proj, { schema: proj.schema || p.schema, cardOverrides: Object.assign({}, proj.cardOverrides, { passive_skill_set_id: setId }) });
          const atk = FB.addPassiveAbility(view, "atk", { amount: boost }, Object.assign(FB.newPassiveSettings("atk"), { timing: 4 }));
          const def = FB.addPassiveAbility(view, "def", { amount: boost }, Object.assign(FB.newPassiveSettings("def"), { timing: 6 }));
          // damage reduction from the same perk, also when receiving an attack (the game adds it to other reductions)
          const dr = FB.addPassiveAbility(view, "dr", { amount: drFor(boost) }, Object.assign(FB.newPassiveSettings("dr"), { timing: 6 }));
          atk.name = def.name = dr.name = titleFor(boost);
          added += 3;
        }
        setGodlyText(set, boost);
      }
    }
    return added;
  }
  async function applyLevelPerks(p, { quiet = false } = {}) {
    if (!p || p.awaken) return;
    const c = Forge.card(p), lv = Number(c.lv_max), perk = PERKS[lv], had = p.levelPerk || null;
    let changed = false;
    const boost = perk ? perk.boost : 0;
    if (!godlyInSync(p, boost)) { syncGodly(p, boost); changed = true; }
    if (perk) {
      const prevSa = had ? had.prevSa : Number(c.skill_lv_max), prevCost = had && had.prevCost != null ? had.prevCost : Number(c.cost);
      if (Number(c.skill_lv_max) !== perk.sa) { p.cardOverrides.skill_lv_max = perk.sa; changed = true; }
      if (Number(c.cost) !== perk.cost) { p.cardOverrides.cost = perk.cost; changed = true; }
      if (!had || had.lv !== lv || had.boost !== boost) changed = true;
      p.levelPerk = { lv, prevSa, prevCost, boost };
    } else if (had) {
      if (had.prevSa && Number(c.skill_lv_max) === 30) p.cardOverrides.skill_lv_max = had.prevSa;
      if (had.prevCost != null && [88, 99].includes(Number(c.cost))) p.cardOverrides.cost = had.prevCost;
      delete p.levelPerk; changed = true;
    }
    if (!changed) return;
    if (window.ForgeBuilderUI && ForgeBuilderUI.refreshTexts) ForgeBuilderUI.refreshTexts();
    // refreshTexts rewrites the passive being edited; make sure every passive still opens with the Godly block
    for (const proj of projectsOf(p)) for (const setId of passiveSetIdsOf(proj)) { const set = (proj.tables.passive_skill_sets || []).find((x) => x.id === setId); if (set) setGodlyText(set, boost); }
    if (typeof scheduleSave === "function") scheduleSave();
    if (typeof renderEditor === "function" && state.view === "editor") renderEditor();
    if (quiet) return;
    const icon = perk ? (lv === 200 ? "GR" : "SLR") : "";
    if (perk) toast(icon + " unlocked — level " + lv + ": team cost " + perk.cost + ", Super Attack level 30" + (perk.boost ? " and the " + perk.title + ": ATK & DEF +" + perk.boost + "% and " + perk.dr + "% damage reduction in every passive (before EZA, EZA steps and forms), permanent and applied after every other boost." : ".") + " Put the " + icon + " icon on the card art from 🎨 Change card artwork.");
    else if (p.rarityBadge) toast("This unit's card art still shows the " + (window.ForgeRarityBadge ? ForgeRarityBadge.NAMES[p.rarityBadge] || "rarity" : "rarity") + " icon. Remove it from 🎨 Change card artwork.");
  }
  // units opened in the builder are brought up to date once (e.g. GR units made before this fix)
  let lastChecked = null, lastSig = "";
    setInterval(() => {
    const p = typeof state !== "undefined" && state.view === "editor" ? state.project : null;
    if (!p) return;
    const lv = Number(Forge.card(p).lv_max), boost = PERKS[lv] ? PERKS[lv].boost : 0;
    // checked on open and then every second: the perk is permanent, so if anything removed or changed it, it's put back.
    // A cheap fingerprint first, so the full check only runs when the passive rows actually changed.
    const rowsAll = p.tables.passive_skills || [], ex = rowsAll.filter((r) => GODLY.test(r.name || ""));
    const sig = lv + "|" + rowsAll.length + "|" + (p.tables.passive_skill_set_relations || []).length + "|" + (p.formProjects || []).length + "|" + ex.map((r) => r.id + ":" + r.eff_value1).join(",");
    if (p === lastChecked && sig === lastSig) return;
    if (p === lastChecked && godlyInSync(p, boost)) { lastSig = sig; return; }
    lastChecked = p; lastSig = sig;
    if (boost || (p.tables.passive_skills || []).some((r) => GODLY.test(r.name || ""))) applyLevelPerks(p, { quiet: true }).catch(() => {});
  }, 1000);
  document.addEventListener("change", (e) => {
    if (!e.target.matches || !e.target.matches('[data-bind="card:lv_max"]')) return;
    setTimeout(() => applyLevelPerks(state.project).catch((err) => toast(err.message || String(err), true)), 0);
  });
  window.ForgeLevelPerks = { apply: applyLevelPerks, PERKS };
})();
