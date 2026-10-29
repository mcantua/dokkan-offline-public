"use strict";
// Passive Skill step: "Copy every fully awakened version" and "Organize & balance".
// Both work on a copy of your unit and show the result (what was combined, what was capped to
// today's meta, and the new description) before anything is applied; ↶ Undo takes it back.
window.ForgePassiveOrganize = (() => {
  const G = () => window.ForgeGuide, PM = () => window.ForgePassiveMerge;
  const html = (s) => esc(String(s == null ? "" : s));
  const dbOf = (p) => (p && p.source && p.source.database === "sparking" ? "sparking" : "eclipse");
  const query = (p) => (o) => Native.call(dbOf(p) === "sparking" ? "querySparking" : "query", o);

  // The passive being edited (the Card Builder's stage, normally "before EZA"), as its own set.
  function targetSet(work) {
    const key = state.builder && window.ForgeBuilderUI && ForgeBuilderUI.stageKey ? ForgeBuilderUI.stageKey("passive") : "base";
    if (key !== "base") return ForgeBuilder.ensureStageEditable(work, "passive", key);
    if (work.awaken) throw Error("The card's original abilities stay as they are in the game. Choose an EZA step to edit.");
    if (!Forge.primaryPassive(work)) throw Error("Your unit has no Passive Skill yet. Add one ability first.");
    G().isolateAbilityStage(work, "base", "passive");
    return G().stageAbilityId(work, "base", "passive");
  }
  function settle(work, setId) {
    work.builderAuto = work.builderAuto || {};
    work.builderAuto["passive:" + setId] = false;   // keep the organized game wording
    if (work.builderLines) delete work.builderLines[setId];
  }
  // Shows the description the way the game does: headings and bullet points.
  function pretty(text) {
    return PM().parse(text).map((g) => (g.heading ? '<p class="porg-h">' + html(g.heading) + "</p>" : "") + "<ul>" + g.lines.map((l) => "<li>" + html(String(l).replace(/\{passiveImg:up_g\}/g, "↑").replace(/\{passiveImg:down_r\}/g, "↓").replace(/\{passiveImg:once\}/g, "① ").replace(/\{passiveImg:forever\}/g, "∞ ")) + "</li>").join("") + "</ul>").join("");
  }
  function closeDialog() { const d = document.getElementById("dialog"); if (d && d.open) d.close(); }
  function showResult(title, intro, work, setId, report) {
    const p = state.project, lines = PM().organizeSummary(report), pset = () => (work.tables.passive_skill_sets || []).find((x) => x.id === setId) || {};
    dialog(title, '<div data-no-ai class="porg"></div><p>' + html(intro) + '</p><ul class="porg-summary">' + lines.map((l) => "<li>" + html(l) + "</li>").join("") + '</ul>' +
      '<label class="field">Passive Skill name<span class="dice-wrap"><input id="porg-pname" maxlength="80" value="' + html(pset().name || "") + '"><button type="button" class="dice-button" id="porg-pdice" aria-label="Random name">🎲</button></span></label><details class="beginner-details" open><summary>New description</summary><div class="porg-text">' + pretty((window.ForgeBuilderUI && ForgeBuilderUI.describeSet && ForgeBuilderUI.describeSet(work, setId)) || report.text || "") + '</div></details><p class="hint">Nothing has changed yet. After applying, ↶ Undo takes it back in one step.</p><div class="row"><button type="button" class="button" id="porg-apply">Apply to my unit</button>' + (basket && basket.groups.length ? '<button type="button" class="button ghost" id="porg-back">← Back to my list</button>' : "") + '<button type="button" class="button ghost" id="porg-cancel">Cancel</button></div>');
    document.getElementById("porg-cancel").onclick = () => { basket = null; closeDialog(); };
    const back = document.getElementById("porg-back"), nameBox = document.getElementById("porg-pname");
    if (back) back.onclick = () => showBasket();
    nameBox.oninput = () => { pset().name = nameBox.value; };
    document.getElementById("porg-pdice").onclick = () => { if (window.ForgeSkillNames) nameBox.value = pset().name = ForgeSkillNames.random("passive", pset().name); };
    document.getElementById("porg-apply").onclick = async () => {
      if (state.project !== p) return toast("Your unit changed. Try again.", true);
      if (!String(pset().name || "").trim() && window.ForgeSkillNames) pset().name = ForgeSkillNames.random("passive");
      Object.assign(p, work);
      basket = null;
      closeDialog();
      scheduleSave();
      await flushSave();
      renderEditor();
      toast("Passive organized: " + report.before + " → " + report.after + " abilities. ↶ Undo takes it back.");
    };
  }

  // ---------------------------------------------------------------- organize & balance
  function organize() {
    const p = state.project;
    if (!p) return;
    basket = null;
    const work = Forge.clone(p), setId = targetSet(work);
    if (!PM().setRows(work, setId).length) return toast("This passive has no abilities yet — nothing to organize.", true);
    const report = PM().organize(work, setId);
    settle(work, setId);
    showResult("Organize & balance", "Exact copies become one, matching boosts at the same moment are combined, and everything is kept within today's meta.", work, setId, report);
  }

  // ---------------------------------------------------------------- passives from characters
  // Three simple steps:
  //   1. search a character NAME (each name shown once, e.g. "Vegito · 5 cards"),
  //   2. one screen that says how many passives will be copied, with one big button,
  //   3. the result, before anything changes.
  // For every fully awakened card with that exact name, only its strongest passive is copied
  // (Super EZA › EZA › fully awakened). The same passive is never listed twice.
  let basket = null;
  const fresh = (kind = "passive") => ({ kind, groups: [], off: new Set() });
  const KIND = {
    passive: { col: "passive_skill_set_id", table: "passive_skill_sets", one: "passive", many: "passives", title: "Copy passives" },
    leader: { col: "leader_skill_set_id", table: "leader_skill_sets", one: "leader skill", many: "leader skills", title: "Copy leader skills" }
  };
  const K = () => KIND[(basket && basket.kind) || "passive"];
  const basketCards = () => basket.groups.flatMap((g) => g.cards);
  const pickedCards = () => basketCards().filter((c) => !basket.off.has(Number(c.id)));
  const LEVEL = ["Fully awakened", "EZA", "Super EZA"];
  function pickCharacter(again, kind) {
    if (!state.project) return;
    if (!again || !basket || (kind && basket.kind !== kind)) basket = fresh(kind || "passive");
    const back = basket.groups.length;
    dialog(back ? "Add another character" : K().title + " from a character", '<div data-no-ai class="porg"></div>' +
      '<p>Type a character\'s name. You\'ll get the strongest ' + K().one + " of every fully awakened card with that name.</p>" +
      '<label class="field">Character name<input id="porg-search" type="search" placeholder="e.g. Vegito" autocomplete="off"></label>' +
      '<div id="porg-names" class="porg-names" aria-live="polite"></div>' +
      '<div class="row">' + (back ? '<button type="button" class="button ghost" id="porg-back">← Back to my list</button>' : "") + '<button type="button" class="button ghost" id="porg-cancel">Cancel</button></div>');
    const input = document.getElementById("porg-search"), box = document.getElementById("porg-names");
    let timer = 0, seq = 0;
    const run = async () => {
      const text = input.value.trim(), token = ++seq;
      if (text.length < 2) { box.innerHTML = '<p class="hint">Type at least 2 letters.</p>'; return; }
      box.innerHTML = '<p class="hint">Searching…</p>';
      let rows = [];
      try {
        // Eclipse: search the finder's small, remembered character list instead of asking the
        // game data for up to 2000 full card rows on every keystroke.
        if (window.ForgeFinder && dbOf(state.project) !== "sparking") { const low = text.toLowerCase(); rows = (await ForgeFinder.cards()).filter((c) => c.name.toLowerCase().includes(low)); }
        else rows = await query(state.project)({ table: "cards", search: { column: "name", text }, order: "id", limit: 2000 });
      } catch (e) { if (token === seq) box.innerHTML = '<p class="notice error">' + html(e.message) + "</p>"; return; }
      if (token !== seq) return;
      // one entry per exact name, counting its playable cards
      const names = new Map();
      for (const c of rows) {
        if (!playable(c)) continue;
        const n = names.get(c.name) || { name: c.name, count: 0, card: c };
        n.count++;
        if (Number(c.rarity) > Number(n.card.rarity)) n.card = c;
        names.set(c.name, n);
      }
      const low = text.toLowerCase(), list = [...names.values()].sort((x, y) => (y.name.toLowerCase() === low) - (x.name.toLowerCase() === low) || (y.name.toLowerCase().startsWith(low)) - (x.name.toLowerCase().startsWith(low)) || y.count - x.count || x.name.localeCompare(y.name)).slice(0, 40);
      box.innerHTML = list.length ? list.map((n) => '<button type="button" class="porg-name" data-porg-name="' + html(n.name) + '"><img loading="lazy" alt="" src="' + html(typeof thumb === "function" ? thumb(n.card) : "") + '"><span><strong>' + html(n.name) + "</strong><small>Copy their strongest " + K().many + "</small></span><b aria-hidden=\"true\">›</b></button>").join("") : "<p>No character with that name.</p>";
      box.querySelectorAll("[data-porg-name]").forEach((b) => b.onclick = () => choose(b.dataset.porgName).catch((e) => toast(e.message, true)));
    };
    input.oninput = () => { clearTimeout(timer); timer = setTimeout(run, 250); };
    document.getElementById("porg-cancel").onclick = () => { basket = null; closeDialog(); };
    const backBtn = document.getElementById("porg-back");
    if (backBtn) backBtn.onclick = () => showBasket();
    run();
    setTimeout(() => input.focus(), 50);
  }
  // Every fully awakened card with exactly this name: the top of each awakening line
  // (a card that does not Dokkan Awaken into another card). Pre-awakened copies, other
  // characters and the game's hidden helper cards (9xxxxxx) are left out.
  // Normal player cards only: 1xxxxx1 ids with real stats. Transformed forms (4xxxxxx), enemy and
  // event copies (2-9xxxxxx, 5xxxxxxx…) would otherwise show the same card again.
  const playable = (c) => { const id = Number(c.id); return id % 10 === 1 && id >= 1000000 && id < 2000000 && Number(c.hp_max) > 300 && c.passive_skill_set_id != null && c.leader_skill_set_id != null; };
  async function maxAwakened(q, name) {
    const all = (await q({ table: "cards", filters: { name }, limit: 2000 })).filter(playable);
    const routes = async (id, type) => { try { return await q({ table: "card_awakening_routes", filters: { card_id: id, type }, limit: 40 }); } catch (e) { return []; } };
    // EZA = Extreme Z-Awakening steps 1-7; Super EZA = steps 8 and up
    const info = await Promise.all(all.map(async (c) => {
      const steps = (await routes(c.id, "CardAwakeningRoute::Optimal")).map((r) => Number(r.optimal_awakening_step) || 0);
      return { c, next: (await routes(c.id, "CardAwakeningRoute::Dokkan")).filter((r) => Number(r.awaked_card_id) !== Number(c.id)), level: !steps.length ? 0 : Math.max(...steps) > 7 ? 2 : 1 };
    }));
    return info.filter((x) => !x.next.length).map((x) => Object.assign({}, x.c, { level: x.level }));
  }
  async function choose(name) {
    const q = query(state.project);
    if (!basket) basket = fresh();
    if (basket.groups.some((g) => g.name === name)) { toast(name + " is already in your list."); return showBasket(); }
    let group = null;
    const k = K();
    await busy("Finding " + name + "'s strongest " + k.many, async () => {
      // strongest first; one entry per passive: the same passive set, or the same passive name on
      // the same rarity and type (a re-release of the same card), is listed once
      const cards = (await maxAwakened(q, name)).sort((a, b) => b.level - a.level || b.rarity - a.rarity || b.id - a.id);
      const sets = cards.length ? await q({ table: k.table, ids: [...new Set(cards.map((c) => c[k.col]))], limit: 1000 }) : [];
      const have = new Set(basketCards().map((c) => c[k.col])), seen = new Set(), list = [];
      for (const c of cards) {
        const set = sets.find((x) => x.id === c[k.col]) || {};
        c.passiveName = set.name || (basket.kind === "leader" ? "Leader Skill" : "Passive Skill");
        // leader skills with the same wording are the same bonus
        const twin = basket.kind === "leader" ? "d|" + String(set.description || c.passiveName).replace(/\s+/g, " ").toLowerCase() : c.passiveName.toLowerCase() + "|" + c.rarity + "|" + c.element;
        if (have.has(c[k.col]) || seen.has(c[k.col]) || seen.has(twin)) continue;
        seen.add(c[k.col]); seen.add(twin);
        list.push(c);
      }
      group = { name, cards: list };
    });
    if (!group) return;
    if (!group.cards.length) { toast(name + " has no fully awakened " + k.many + " that aren't already in your list.", true); return basket.groups.length ? showBasket() : pickCharacter(true); }
    basket.groups.push(group);
    showBasket();
  }
  function showBasket() {
    const total = basketCards().length, n = pickedCards().length, names = basket.groups.map((g) => g.name);
    const who = names.length > 2 ? names.slice(0, -1).join(", ") + " and " + names[names.length - 1] : names.join(" and ");
    const line = (c) => '<label class="porg-row"><input type="checkbox" data-porg-card="' + c.id + '"' + (basket.off.has(Number(c.id)) ? "" : " checked") + '><span><strong>' + html(c.passiveName) + '</strong><small>' + html((Forge.rarities[c.rarity] || "") + " " + (Forge.elements[c.element] || "")) + '</small></span><em class="porg-level porg-level-' + c.level + '">' + LEVEL[c.level] + "</em></label>";
    const k = K(), noun = (x) => (x === 1 ? k.one : k.many), leader = basket.kind === "leader";
    dialog(k.title, '<div data-no-ai class="porg"></div>' +
      '<div class="porg-hero"><span class="porg-big">' + n + '</span><span><strong>' + noun(n) + " from " + html(who) + "</strong><small>The strongest version of each fully awakened card — Super EZA, EZA or fully awakened." + (leader ? " They become one leader skill, kept within today's meta (about Ki +3–4 and +220%)." : "") + "</small></span></div>" +
      '<button type="button" class="button porg-main" id="porg-go"' + (n ? "" : " disabled") + ">" + (leader ? "Combine " : "Copy ") + (n === total ? "all " : "") + n + " " + noun(n) + (leader ? " into one" : " into mine") + "</button>" +
      '<div class="porg-chips">' + basket.groups.map((g, i) => '<span class="porg-chip">' + html(g.name) + ' <button type="button" class="porg-chip-x" data-porg-remove="' + i + '" aria-label="Remove ' + html(g.name) + '">✕</button></span>').join("") + '<button type="button" class="porg-chip porg-chip-add" id="porg-add">＋ Add a character</button></div>' +
      '<details class="porg-pick"' + (basket.off.size ? " open" : "") + '><summary>Choose which ' + k.many + " (" + n + " of " + total + ")</summary>" +
      basket.groups.map((g) => (basket.groups.length > 1 ? '<p class="porg-pick-head">' + html(g.name) + "</p>" : "") + g.cards.map(line).join("")).join("") + "</details>" +
      '<p class="hint">' + (leader ? "Category bonuses are joined into one “A or B Category” bonus at the strongest value, extra bonuses for characters who also belong to other Categories are kept, and the total stays within today\'s meta." : "Copies of the same ability become one, matching boosts are combined, and everything is kept within today\'s meta.") + " You\'ll see the result before anything changes.</p>" +
      '<div class="row"><button type="button" class="button ghost" id="porg-cancel">Cancel</button></div>');
    const $$ = (sel) => [...document.querySelectorAll(sel)];
    const go = document.getElementById("porg-go");
    const sync = () => {
      const k = pickedCards().length;
      go.disabled = !k;
      go.textContent = (leader ? "Combine " : "Copy ") + (k === total ? "all " : "") + k + " " + noun(k) + (leader ? " into one" : " into mine");
      const big = document.querySelector(".porg-big"), sum = document.querySelector(".porg-pick summary");
      if (big) big.textContent = k;
      if (sum) sum.textContent = "Choose which " + K().many + " (" + k + " of " + total + ")";
    };
    $$("[data-porg-card]").forEach((b) => b.onchange = () => { const id = Number(b.dataset.porgCard); if (b.checked) basket.off.delete(id); else basket.off.add(id); sync(); });
    $$("[data-porg-remove]").forEach((b) => b.onclick = () => { const g = basket.groups.splice(Number(b.dataset.porgRemove), 1)[0]; for (const c of g.cards) basket.off.delete(Number(c.id)); if (basket.groups.length) showBasket(); else pickCharacter(true); });
    document.getElementById("porg-add").onclick = () => pickCharacter(true, basket.kind);
    document.getElementById("porg-cancel").onclick = () => { basket = null; closeDialog(); };
    go.onclick = () => {
      const cards = pickedCards(), used = basket.groups.filter((g) => g.cards.some((c) => cards.includes(c))).map((g) => g.name);
      closeDialog();
      (leader ? combineLeader : combine)(used, cards).catch((e) => toast(e.message || String(e), true));
    };
  }
  // kept for older callers/tests: pick a character by any of its cards
  async function versions(card) {
    const row = (await query(state.project)({ table: "cards", ids: [card.id], limit: 1 }))[0];
    return choose(row ? row.name : card.name);
  }
  async function combine(names, cards) {
    const p = state.project, copied = [], failed = [];
    let work = Forge.clone(p);
    const setId = targetSet(work);
    let skippedTransforms = 0;
    await busy("Combining " + cards.length + " passives", async () => {
      for (const [i, c] of cards.entries()) {
        const detail = document.getElementById("busy-detail");
        if (detail) detail.textContent = (i + 1) + " of " + cards.length + ": " + c.name;
        try {
          const d = await ForgeUnitCopy.gameDonor(c);
          const stages = G().abilityStages(d.project).filter((s) => G().stageSet(d.project, s.id, "passive"));
          const r = ForgeUnitCopy.build(d, new Set(["passive"]), { passive: "add", organize: false, targetSet: setId, passiveStage: stages.length > 1 ? stages[stages.length - 1].id : "base" }, work);
          work = r.work;
          for (const n of r.notes) { const m = n.match(/^(\d+) transformation/); if (m) skippedTransforms += Number(m[1]); }
          copied.push(c.name);
        } catch (e) { failed.push(c.name); }
      }
    });
    if (state.project !== p) throw Error("Your unit changed while combining. Try again.");
    if (!copied.length) throw Error("Couldn't read any of those passives. Nothing was changed.");
    const report = PM().organize(work, setId);
    settle(work, setId);
    const ps = (work.tables.passive_skill_sets || []).find((x) => x.id === setId);
    if (ps && window.ForgeSkillNames) ps.name = ForgeSkillNames.random("passive", ps.name);
    const intro = "Combined " + copied.length + " of " + cards.length + " passives from " + (names.length > 2 ? names.slice(0, -1).join(", ") + " and " + names[names.length - 1] : names.join(" and ")) + "." + (skippedTransforms ? " " + skippedTransforms + " transformation" + (skippedTransforms === 1 ? " was" : "s were") + " left out." : "") + (failed.length ? " Couldn't read: " + failed.slice(0, 5).join(", ") + "." : "");
    if (window.ForgeBuilderUI && ForgeBuilderUI.loadCausalities) await ForgeBuilderUI.loadCausalities(work).catch(() => {});
    showResult("Your combined passive", intro, work, setId, report);
  }

  // ---------------------------------------------------------------- leader skills
  // Today's top leaders (game data, 2026): one Category bonus of Ki +3–4 and up to +220%, or
  // Ki +3, HP +200% and ATK & DEF +170% plus +50% for characters who also belong to other
  // Categories. So, for any one ally, everything added up stays within these totals.
  const LEADER_META = { main: { ki1: 4, ki: 3, hp: 220, atk: 220, def: 220 }, total: { ki: 4, hp: 250, atk: 220, def: 220 }, cats: 4, also: 6 };
  // Reads a leader's rows as "who gets what" (who = the Categories they must belong to, or a
  // Type / Class). Conditions and other special effects can't be combined and are counted.
  function leaderAtoms(rows, subRows) {
    const subs = new Map();
    for (const r of subRows || []) { if (!subs.has(r.sub_target_type_set_id)) subs.set(r.sub_target_type_set_id, []); subs.get(r.sub_target_type_set_id).push(r); }
    const atoms = new Map();
    let skipped = 0;
    for (const r of rows) {
      const e = Number(r.efficacy_type);
      if (!e) continue;
      let v;
      try { v = JSON.parse(r.efficacy_values); } catch (err) { v = null; }
      if (r.causality_conditions || Number(r.exec_timing_type) !== 1 || ![5, 82, 83, 104].includes(e) || !Array.isArray(v) || ([82, 104].includes(e) && Number(r.calc_option) !== 2)) { skipped++; continue; }
      const sub = Number(r.sub_target_type_set_id) || 0, entries = sub ? (subs.get(sub) || []).slice().sort((a, b) => Math.abs(a.id) - Math.abs(b.id)).map((x) => [Number(x.target_value_type), Number(x.target_value)]) : [];
      if (sub && (!entries.length || entries.some(([t]) => t !== 1 && t !== 2))) { skipped++; continue; }
      const pos = entries.filter(([t]) => t === 1).map(([, x]) => x).sort((a, b) => a - b), target = Number(r.target_type);
      const mask = e === 83 || e === 82 ? Number(v[0]) : target === 12 ? 32 : target === 13 ? 64 : 31;
      const key = target + "|" + (pos.length ? 31 : mask) + "|" + pos.join(",");
      const a = atoms.get(key) || { target, mask: pos.length ? 31 : mask, pos, ki: 0, hp: 0, atk: 0, def: 0 };
      if (e === 5) a.ki += Number(v[0]) || 0;
      else if (e === 83) a.ki += Number(v[1]) || 0;
      else if (e === 82) { a.hp += Number(v[1]) || 0; a.atk += Number(v[1]) || 0; a.def += Number(v[1]) || 0; }
      else { a.hp += Number(v[0]) || 0; a.atk += Number(v[1]) || 0; a.def += Number(v[2]) || 0; }
      atoms.set(key, a);
    }
    return { atoms: [...atoms.values()], skipped };
  }
  const whoOf = (a) => a.target === 12 && a.mask === 32 ? { who: "super" } : a.target === 13 && a.mask === 64 ? { who: "extreme" } : a.target !== 2 ? null : a.mask === 31 ? { who: "all" } : a.mask > 0 && a.mask < 31 ? { who: "types", types: [0, 1, 2, 3, 4].filter((t) => a.mask & (1 << t)) } : (() => { const parts = ForgeBuilder.CLASS_TYPE_OPTIONS.filter(([m]) => a.mask & m).map(([m]) => m); return parts.length && parts.reduce((x, m) => x + m, 0) === a.mask ? { who: "classTypes", classTypes: parts } : null; })();
  // Many leaders → builder groups for one leader skill, plus what was capped.
  // Like today's leaders: one "A, B or C Category" bonus at the strongest value, plus an extra
  // bonus for characters who also belong to other Categories. Old Type / Class / All Types
  // bonuses are only used when none of the leaders has a Category bonus.
  function mergeLeaders(lists) {
    const best = new Map(), notes = [], strength = (a) => a.ki * 40 + a.hp + a.atk + a.def;
    for (const list of lists) for (const a of list) {
      const key = a.target + "|" + a.mask + "|" + a.pos.join(","), b = best.get(key);
      if (!b) best.set(key, Object.assign({}, a, { pos: a.pos.slice(), seen: 1 }));
      else { for (const f of ["ki", "hp", "atk", "def"]) b[f] = Math.max(b[f], a[f]); b.seen++; }
    }
    const all = [...best.values()], plain = (a) => a.target === 2 && a.mask === 31;
    const singles = all.filter((a) => plain(a) && a.pos.length === 1).sort((x, y) => strength(y) - strength(x) || y.seen - x.seen);
    const pairs = all.filter((a) => plain(a) && a.pos.length === 2), others = all.filter((a) => !a.pos.length && whoOf(a)).sort((x, y) => strength(y) - strength(x));
    const classExtras = all.filter((a) => a.pos.length && !plain(a)).length;
    const capNote = (label, src, out) => { for (const f of ["ki", "hp", "atk", "def"]) if (out[f] < src[f]) notes.push({ field: (f === "ki" ? "Ki" : f.toUpperCase()), group: label, wanted: src[f], kept: out[f] }); };
    const groups = [];
    if (singles.length) {
      const cats = [...new Set(singles.map((a) => a.pos[0]))], mainCats = cats.slice(0, LEADER_META.cats);
      if (cats.length > mainCats.length) notes.push({ text: "The " + mainCats.length + " strongest Categories were kept; " + (cats.length - mainCats.length) + " more were left out (a leader skill names up to " + LEADER_META.cats + ")." });
      const top = { ki: 0, hp: 0, atk: 0, def: 0 };
      for (const a of singles.filter((x) => mainCats.includes(x.pos[0]))) for (const f of Object.keys(top)) top[f] = Math.max(top[f], a[f]);
      const m = LEADER_META.main, main = { ki: Math.min(top.ki, mainCats.length > 1 ? m.ki : m.ki1), hp: Math.min(top.hp, m.hp), atk: Math.min(top.atk, m.atk), def: Math.min(top.def, m.def) };
      capNote("main", top, main);
      groups.push(Object.assign({ who: "categories", categories: mainCats, also: [] }, main));
      if (pairs.length) {
        const also = [], top2 = { ki: 0, hp: 0, atk: 0, def: 0 };
        for (const a of pairs) {
          const extra = a.pos.find((c) => !mainCats.includes(c));
          if (extra != null && !also.includes(extra)) also.push(extra);
          for (const f of Object.keys(top2)) top2[f] = Math.max(top2[f], a[f]);
        }
        const T = LEADER_META.total, extra = { ki: Math.max(0, Math.min(top2.ki, T.ki - main.ki)), hp: Math.max(0, Math.min(top2.hp, T.hp - main.hp)), atk: Math.max(0, Math.min(top2.atk, T.atk - main.atk)), def: Math.max(0, Math.min(top2.def, T.def - main.def)) };
        capNote("extra", top2, extra);
        const alsoList = also.slice(0, LEADER_META.also);
        if (alsoList.length && (extra.hp || extra.atk || extra.def || extra.ki)) groups.push(Object.assign({ who: "categories", categories: mainCats, also: alsoList }, extra));
      }
      if (others.length) notes.push({ text: "Type, Class and All Types bonuses from older cards were left out: today's leaders use Categories." });
    } else if (others.length) {
      // no Category leaders at all: the strongest Type / Class / All Types bonus
      const a = others[0], who = whoOf(a), m = LEADER_META.main, v = { ki: Math.min(a.ki, m.ki1), hp: Math.min(a.hp, m.hp), atk: Math.min(a.atk, m.atk), def: Math.min(a.def, m.def) };
      capNote("main", a, v);
      if (["types", "classTypes"].includes(who.who)) { const even = Math.min(v.hp || Infinity, v.atk || Infinity, v.def || Infinity); v.hp = v.atk = v.def = even === Infinity ? 0 : even; }
      groups.push(Object.assign({ categories: [], also: [], types: [], classTypes: [] }, who, v));
      if (others.length > 1) notes.push({ text: "Kept the strongest bonus; " + (others.length - 1) + " weaker Type / Class bonus" + (others.length > 2 ? "es were" : " was") + " left out." });
    }
    if (classExtras) notes.push({ text: "Extra bonuses for “characters who are also Super / Extreme Class” can't be combined and were left out." });
    return { groups, notes };
  }
  function leaderTarget(work) {
    const key = state.builder && window.ForgeBuilderUI && ForgeBuilderUI.stageKey ? ForgeBuilderUI.stageKey("leader") : "base";
    if (key !== "base") { ForgeBuilder.ensureStageEditable(work, "leader", key); return ForgeBuilder.stageView(work, "leader", key); }
    if (work.awaken) throw Error("The card's original leader skill stays as it is in the game. Choose an EZA step to edit.");
    return work;
  }
  const leaderNames = () => ({ category: (id) => ((state.categories || []).find((c) => c.id === Number(id)) || {}).name });
  async function combineLeader(names, cards) {
    const p = state.project, work = Forge.clone(p), view = leaderTarget(work), lists = [], failed = [], official = [];
    let skipped = 0;
    if (!(state.categories || []).length && typeof loadLookups === "function") await loadLookups().catch(() => {});
    await busy("Combining " + cards.length + " leader skills", async () => {
      for (const [i, c] of cards.entries()) {
        const detail = document.getElementById("busy-detail");
        if (detail) detail.textContent = (i + 1) + " of " + cards.length + ": " + c.name;
        try {
          const d = (await ForgeUnitCopy.gameDonor(c)).project;
          const stages = G().abilityStages(d).filter((st) => G().stageSet(d, st.id, "leader")), stage = stages.length ? stages[stages.length - 1].id : "base";
          const setId = G().stageAbilityId(d, stage, "leader"), rows = (d.tables.leader_skills || []).filter((r) => r.leader_skill_set_id === setId);
          let subRows = d.tables.sub_target_types || [];
          const need = [...new Set(rows.map((r) => Number(r.sub_target_type_set_id)).filter((x) => x && !subRows.some((s) => s.sub_target_type_set_id === x)))];
          for (const id of need) subRows = subRows.concat(await query(p)({ table: "sub_target_types", filters: { sub_target_type_set_id: id }, limit: 100 }));
          official.push(...subRows);
          const r = leaderAtoms(rows, subRows);
          skipped += r.skipped;
          if (r.atoms.length) lists.push(r.atoms); else failed.push(c.name);
        } catch (e) { failed.push(c.name); }
      }
    });
    if (state.project !== p) throw Error("Your unit changed while combining. Try again.");
    if (!lists.length) throw Error("None of those leader skills could be combined (they use conditions or special effects). Nothing was changed.");
    const merged = mergeLeaders(lists);
    if (!merged.groups.length) throw Error("Nothing to combine.");
    const name = window.ForgeSkillNames ? ForgeSkillNames.random("leader") : "Combined Leadership";
    const before = ((p.tables.leader_skill_sets || []).find((x) => x.id === Forge.card(ForgeBuilderUI && state.builder ? ForgeBuilder.stageView(p, "leader", ForgeBuilderUI.stageKey("leader")) : p).leader_skill_set_id) || {}).description || "";
    const set = ForgeBuilder.buildLeader(view, state.info.schema, merged.groups, { official, names: leaderNames(), name });
    work.builderAuto = work.builderAuto || {};
    work.builderAuto["leader:" + set.id] = true;
    const caps = merged.notes.filter((n) => n.field), texts = merged.notes.filter((n) => n.text).map((n) => n.text);
    const lines = ["Combined " + lists.length + " of " + cards.length + " leader skills from " + names.join(" and ") + " into one."];
    if (caps.length) lines.push("Kept within today's meta: " + [...new Set(caps.map((n) => (n.group === "extra" ? "extra bonus " : "") + n.field + " " + n.wanted + (n.field === "Ki" ? "" : "%") + " → " + n.kept + (n.field === "Ki" ? "" : "%")))].join(", ") + ".");
    lines.push(...texts);
    if (skipped) lines.push(skipped + " special leader effect" + (skipped === 1 ? "" : "s") + " (with conditions) couldn't be combined and were left out.");
    if (failed.length) lines.push("Couldn't use: " + failed.slice(0, 5).join(", ") + ".");
    showLeaderResult(work, set.id, lines, before);
  }
  function showLeaderResult(work, setId, lines, before) {
    const p = state.project, set = () => (work.tables.leader_skill_sets || []).find((x) => x.id === setId) || {};
    dialog("Your combined leader skill", '<div data-no-ai class="porg"></div><ul class="porg-summary">' + lines.map((l) => "<li>" + html(l) + "</li>").join("") + "</ul>" +
      '<label class="field">Leader Skill name<span class="dice-wrap"><input id="porg-lname" maxlength="80" value="' + html(set().name || "") + '"><button type="button" class="dice-button" id="porg-ldice" aria-label="Random name">🎲</button></span></label>' +
      '<div class="porg-text"><p class="porg-h">New leader skill</p><p>' + html(set().description || "").replace(/\n/g, "<br>") + "</p>" + (before ? '<p class="porg-h">Before</p><p class="muted">' + html(before).replace(/\n/g, "<br>") + "</p>" : "") + "</div>" +
      '<p class="hint">Nothing has changed yet. After applying, ↶ Undo takes it back. You can fine-tune each bonus on the Leader Skill step.</p><div class="row"><button type="button" class="button" id="porg-apply">Apply to my unit</button><button type="button" class="button ghost" id="porg-back">← Back to my list</button><button type="button" class="button ghost" id="porg-cancel">Cancel</button></div>');
    const nameBox = document.getElementById("porg-lname");
    nameBox.oninput = () => { set().name = nameBox.value; };
    document.getElementById("porg-ldice").onclick = () => { nameBox.value = set().name = ForgeSkillNames.random("leader", set().name); };
    document.getElementById("porg-cancel").onclick = () => { basket = null; closeDialog(); };
    document.getElementById("porg-back").onclick = () => showBasket();
    document.getElementById("porg-apply").onclick = async () => {
      if (state.project !== p) return toast("Your unit changed. Try again.", true);
      if (!String(set().name || "").trim()) set().name = ForgeSkillNames.random("leader");
      for (const k of Object.keys(p)) if (!(k in work)) delete p[k];
      Object.assign(p, work);
      basket = null;
      closeDialog();
      scheduleSave();
      await flushSave();
      renderEditor();
      toast("Leader skill combined. ↶ Undo takes it back.");
    };
  }

  // ---------------------------------------------------------------- buttons on the Passive step
  let queued = false;
  function inject() {
    queued = false;
    injectLeader();
    const copy = document.querySelector('#bld [data-guide="copy:passive"], #main [data-guide="copy:passive"]');
    if (!copy || copy.parentElement.querySelector(".porg-every")) return;
    const every = document.createElement("button");
    every.type = "button";
    every.className = "button ghost small porg-every";
    every.textContent = "⧉ Copy passives from characters";
    every.onclick = () => { try { pickCharacter(); } catch (e) { toast(e.message, true); } };
    const tidy = document.createElement("button");
    tidy.type = "button";
    tidy.className = "button ghost small porg-tidy";
    tidy.textContent = "🧹 Organize & balance";
    tidy.onclick = () => { try { organize(); } catch (e) { toast(e.message, true); } };
    copy.after(every, tidy);
  }
  function injectLeader() {
    const copy = document.querySelector('#bld [data-guide="copy:leader"], #main [data-guide="copy:leader"]');
    if (!copy || copy.parentElement.querySelector(".porg-leaders")) return;
    const b = document.createElement("button");
    b.type = "button";
    b.className = "button ghost small porg-leaders";
    b.textContent = "⧉ Combine leader skills from characters";
    b.onclick = () => { try { pickCharacter(false, "leader"); } catch (e) { toast(e.message, true); } };
    copy.after(b);
  }
  new MutationObserver(() => { if (!queued) { queued = true; requestAnimationFrame(inject); } }).observe(document.body, { childList: true, subtree: true });
  return { organize, pickCharacter, versions, choose, combine, combineLeader, showBasket, leaderAtoms, mergeLeaders };
})();
