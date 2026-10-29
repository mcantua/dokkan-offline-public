"use strict";
// 🎬 Intro (Entrance Animation) — its own Card Builder step.
// In the game an intro is a passive ability that carries an entrance scene (passive_skill_effect_id). It plays once,
// at the start of the turn the character enters battle (or when its condition is met), and any once-only, start-of-turn
// abilities with the same condition activate together with it — the game writes them under
// "Activates the Entrance Animation … upon the character's entry".
window.ForgeIntro = (() => {
  const h = (t) => String(t == null ? "" : t).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const B = () => window.ForgeBuilder, UI = () => window.ForgeBuilderUI;
  const p = () => state.project;
  const view = () => (UI() && UI().target ? UI().target("passive") : p());
  const setOf = (v) => Forge.primaryPassive(v);
  function rowsOf(v) {
    const set = setOf(v);
    if (!set) return [];
    const ids = (v.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === set.id).map((r) => r.passive_skill_id);
    return ids.map((id) => (v.tables.passive_skills || []).find((r) => r.id === id)).filter(Boolean);
  }
  const carrier = (v = view()) => rowsOf(v).find((r) => Number(r.passive_skill_effect_id));
  function bonuses(v = view()) {
    const c = carrier(v);
    if (!c) return [];
    const cond = c.causality_conditions || "";
    return rowsOf(v).filter((r) => r !== c && Number(r.efficacy_type) !== 0 && Number(r.exec_timing_type) === 1 && Number(r.is_once) === 1 && (r.causality_conditions || "") === cond && !/Exclusive$/.test(r.name || ""));
  }
  const scenes = () => (window.ForgeSpecial && ForgeSpecial.INTROS) || [];
  const sceneName = (id) => { const x = scenes().find(([i]) => Number(i) === Number(id)); return x ? x[1] + "'s entrance" : Number(id) < 0 ? "Your own entrance animation" : "Entrance scene #" + id; };

  // when it plays: the game's usual intro conditions, plus anything set on the Passive step
  const WHEN = [
    ["entry", "Every time, upon the character's entry"],
    ["allies", "When there are allies of a Category on the team"],
    ["allyName", "When there is an ally with a certain name on the team"],
    ["classAllies", "When there are Super or Extreme Class allies on the team"],
    ["enemyCategory", "When facing a Category enemy"],
    ["enemyName", "When facing an enemy with a certain name"]
  ];
  function specOf(c) {
    if (!c || !c.causality_conditions) return { key: "entry", values: {} };
    const d = B().decodeCondition(c.causality_conditions, (id) => (p().tables.skill_causalities || []).find((r) => r.id === id) || (state.conditionRows || []).find((r) => r.id === id));
    if (d && d.items && d.items.length === 1 && WHEN.some(([k]) => k === d.items[0].key)) return d.items[0];
    return { key: "custom", values: {} };
  }
  function whenText(c) {
    if (!c) return "";
    const t = UI() && UI().describeSet ? (UI().describeSet(view(), setOf(view()).id).match(/\*(Activates the Entrance Animation[^*]*)\*/) || [])[1] : "";
    return t || "Activates the Entrance Animation upon the character's entry";
  }
  const cats = () => (state.categories || []).filter((c) => c.name && c.name !== "0").slice().sort((a, b) => a.name.localeCompare(b.name));
  const sel = (attr, options, cur) => "<select " + attr + ">" + options.map(([v, l]) => '<option value="' + h(v) + '"' + (String(v) === String(cur) ? " selected" : "") + ">" + h(l) + "</option>").join("") + "</select>";
  function whenFields(spec) {
    const v = spec.values || {};
    if (spec.key === "allies") return '<label class="field">Category' + sel('data-intro-v="category"', cats().map((c) => [c.id, c.name]), v.category) + '</label><label class="field">How many on the team (including this character)' + sel('data-intro-v="count"', [1, 2, 3, 4, 5, 6, 7].map((n) => [n, n === 1 ? "Just this character" : n === 2 ? "This character + 1 more (\"another\")" : "This character + " + (n - 1) + " more"]), v.count || 2) + "</label>";
    if (spec.key === "enemyCategory") return '<label class="field">Category' + sel('data-intro-v="category"', cats().map((c) => [c.id, c.name]), v.category) + "</label>";
    if (spec.key === "classAllies") return '<label class="field">Class' + sel('data-intro-v="cls"', [[32, "Super Class"], [64, "Extreme Class"]], v.cls || 32) + '</label><label class="field">How many' + sel('data-intro-v="count"', [1, 2, 3, 4, 5, 6, 7].map((n) => [n, n + " or more"]), v.count || 3) + "</label>";
    if (spec.key === "allyName" || spec.key === "enemyName") return '<div class="field ns-field"><span>' + (spec.key === "allyName" ? "Ally's name" : "Enemy's name") + '</span><button type="button" class="ns-btn" data-nspick>🔍 ' + h((v.set && window.ForgeNameSets && ForgeNameSets.label(v.set)) || "Search for a character") + '</button><select data-intro-v="set" data-cf-kind="nameSet" hidden><option value="' + h(v.set || 0) + '" selected></option></select></div>';
    return "";
  }

  function html() {
    const v = view(), c = carrier(v);
    if (window.ForgeNameSets) ForgeNameSets.load().catch(() => {});
    const head = '<section class="panel intro-panel"><h2>🎬 Intro (Entrance Animation)</h2><p class="hint">A short scene that plays when your character enters battle — like the entrances of Super Saiyan Goku or Perfect Cell. You decide whether your unit has one, when it plays, and what bonuses the character gets when it does.</p>';
    if (!c) {
      return head + '<div class="intro-choice"><button type="button" class="intro-opt on" disabled><strong>No intro</strong><small>The character just appears. Nothing extra happens.</small></button><button type="button" class="intro-opt" data-intro="add"><strong>＋ Add an intro</strong><small>Choose a scene, when it plays and (optional) bonuses that activate with it.</small></button></div></section>';
    }
    const spec = specOf(c), bon = gains(v), set = setOf(v);
    const preview = UI() && UI().describeSet ? UI().describeSet(v, set.id) : "";
    const introBlock = (preview.split(/\n(?=\*)/).find((g) => /^\*Activates the Entrance Animation/.test(g)) || "");
    return head +
      '<div class="intro-choice"><button type="button" class="intro-opt" data-intro="remove"><strong>No intro</strong><small>Removes the scene. Its bonuses stay as normal once-only abilities.</small></button><button type="button" class="intro-opt on" disabled><strong>✓ Has an intro</strong><small>Set it up below.</small></button></div>' +
      '<div class="intro-sec"><h3>1. The scene</h3><div class="intro-scene"><span class="intro-scene-name">' + (((p().animationAssignments || {})["intro:" + c.id]) ? "★ My own animation" + ((((p().uiLabels || {}).animations || {})["intro:" + c.id]) ? " — " + h(p().uiLabels.animations["intro:" + c.id]) : "") : "🎬 " + h(sceneName(c.passive_skill_effect_id))) + '</span><button type="button" class="button ghost small" data-intro="scene">Change scene</button><button type="button" class="button ghost small" data-intro="own:new">★ Make my own</button><button type="button" class="button ghost small" data-intro="own:saved">★ My saved animations</button></div><p class="pf-tip">Every entrance scene in the game is available. “Make my own” lets you build a custom one on Portraits &amp; Sprites.</p></div>' +
      '<div class="intro-sec"><h3>2. When it plays</h3><p class="pf-tip">It plays once per battle, at the start of the turn the character enters — only if the condition is met at that moment.</p><div class="field-grid"><label class="field">Plays' + sel('data-intro-when', WHEN.concat(spec.key === "custom" ? [["custom", "Custom condition (set on the Passive Skill step)"]] : []), spec.key) + "</label>" + whenFields(spec) + "</div></div>" +
      '<div class="intro-sec"><h3>3. What you get when it plays</h3><p class="pf-tip">Optional. Bonuses activate once, together with the intro, and last as long as you choose — e.g. “Ki +3 and ATK &amp; DEF 100%↑ for 5 turns”. Without bonuses the intro is just for show.</p>' +
      (bon.length ? '<div class="intro-bonuses">' + bon.map((r) => '<div class="intro-bonus"><span class="intro-bonus-line">' + h(B().cap(B().passiveLine(r))) + '</span><label class="intro-turns">Lasts' + sel('data-intro-turn="' + r.id + '"', [[1, "1 turn"], [2, "2 turns"], [3, "3 turns"], [4, "4 turns"], [5, "5 turns"], [6, "6 turns"], [7, "7 turns"], [10, "10 turns"], [99, "Rest of the battle"]].concat([1, 2, 3, 4, 5, 6, 7, 10, 99].includes(Number(r.turn)) ? [] : [[r.turn, r.turn + " turns"]]), r.turn) + '</label><button type="button" class="button ghost small" data-intro="edit:' + r.id + '">Edit</button><button type="button" class="icon-button" data-intro="del:' + r.id + '" aria-label="Remove this bonus">×</button></div>').join("") + "</div>" : '<p class="bld-empty">No bonuses yet.</p>') +
      '<div class="row"><button type="button" class="button" data-intro="bonus">＋ Add a bonus</button><button type="button" class="button ghost" data-intro="preset">★ Typical intro bonus</button></div></div>' +
      (introBlock ? '<div class="intro-sec"><h3>How it reads in the game</h3><div class="bld-pdesc-preview"><div class="bld-itemized itemized">' + (UI().itemized ? UI().itemized(introBlock) : h(introBlock)) + "</div></div></div>" : "") +
      "</section>";
  }
  const status = () => !!(state.project && carrier());

  // ---------------------------------------------------------------- actions
  // Like the game, the scene rides on the first bonus ability; an intro with no bonus uses an effect-less ability.
  function normalize(v) {
    const c = carrier(v), list = bonuses(v);
    if (!c || Number(c.efficacy_type) !== 0 || !list.length) return;
    const to = list[0], a = p().animationAssignments || {};
    to.passive_skill_effect_id = c.passive_skill_effect_id;
    if (a["intro:" + c.id]) { a["intro:" + to.id] = a["intro:" + c.id]; delete a["intro:" + c.id]; }
    if (!(v.tables.dokkan_field_passive_skill_relations || []).some((x) => x.passive_skill_id === c.id)) Forge.removePassive(v, c.id);
    else c.passive_skill_effect_id = null;
  }
  function commit(work) { UI().commit((proj) => { work(proj); normalize(view()); }); }
  const gains = (v = view()) => { const c = carrier(v); return c ? (Number(c.efficacy_type) !== 0 ? [c] : []).concat(bonuses(v)) : []; };
  function removeBonus(id) {
    const v = view(), c = carrier(v), row = (v.tables.passive_skills || []).find((r) => r.id === id);
    if (!row) return;
    if (row === c) {
      // keep the intro: hand the scene to another bonus, or to an effect-less ability
      const next = bonuses(v)[0], a = p().animationAssignments || {};
      const to = next || Forge.addPassive(v, { efficacy_type: 0, calc_option: 0, target_type: 1, exec_timing_type: 1, turn: 1, probability: 100, is_once: 1, eff_value1: 0, eff_value2: 0, eff_value3: 0, efficacy_values: "{}", causality_conditions: c.causality_conditions });
      to.passive_skill_effect_id = c.passive_skill_effect_id;
      if (a["intro:" + c.id]) { a["intro:" + to.id] = a["intro:" + c.id]; delete a["intro:" + c.id]; }
    }
    Forge.removePassive(v, id);
  }
  function setWhen(spec) {
    const v = view(), c = carrier(v);
    if (!c) return;
    const targets = [c].concat(bonuses(v));
    commit((proj) => { for (const r of targets) B().applyCondition(proj, state.info.schema, r, spec.key === "entry" ? { mode: "all", items: [] } : { mode: "all", items: [spec] }); });
  }
  function readWhen(box, key) {
    const values = {};
    box.querySelectorAll("[data-intro-v]").forEach((el) => { values[el.dataset.introV] = Number(el.value); });
    const def = B().conditionDefaults ? B().conditionDefaults(key) : {};
    const out = Object.assign({}, def, values);
    if (key === "allies" || key === "enemyCategory") out.category = out.category || (cats()[0] || {}).id;
    if (key === "allies" && !values.count) out.count = 2;
    if ((key === "allyName" || key === "enemyName") && !out.set && window.ForgeNameSets) out.set = ForgeNameSets.first();
    return { key, values: out };
  }
  function pickScene(after) {
    const list = scenes();
    dialog("Choose an entrance scene", '<div data-no-ai class="ucopy-dialog"></div><div class="ap-own"><button type="button" class="button small" data-intro="own:new">★ Make my own animation</button><button type="button" class="button ghost small" data-intro="own:saved">★ One of my saved animations</button></div><p>Or use an entrance scene from the game. It plays when your character enters battle.</p><label class="field">Find a character<input id="intro-q" type="search" placeholder="e.g. Gohan"></label><div id="intro-list" class="porg-names"></div><div class="row"><button type="button" class="button ghost" id="intro-cancel">Cancel</button></div>');
    const draw = () => {
      const q = document.getElementById("intro-q").value.trim().toLowerCase();
      const box = document.getElementById("intro-list");
      box.innerHTML = list.filter(([, n]) => !q || n.toLowerCase().includes(q)).map(([id, n]) => '<button type="button" class="porg-name" data-intro-scene="' + id + '"><span><strong>' + h(n) + "</strong><small>Their entrance scene</small></span><b aria-hidden=\"true\">›</b></button>").join("") || "<p>No match.</p>";
      box.querySelectorAll("[data-intro-scene]").forEach((b) => b.onclick = () => { const d = document.getElementById("dialog"); if (d) d.close(); after(Number(b.dataset.introScene)); });
    };
    document.getElementById("intro-q").oninput = draw;
    document.getElementById("intro-cancel").onclick = () => document.getElementById("dialog").close();
    draw();
  }
  function addIntro(sceneId) {
    commit(() => {
      const v = view();
      for (const r of rowsOf(v)) if (Number(r.passive_skill_effect_id)) r.passive_skill_effect_id = null;
      Forge.addPassive(v, { efficacy_type: 0, calc_option: 0, target_type: 1, exec_timing_type: 1, turn: 1, probability: 100, is_once: 1, eff_value1: 0, eff_value2: 0, eff_value3: 0, efficacy_values: "{}", causality_conditions: null, passive_skill_effect_id: sceneId });
    });
    toast("Intro added: " + sceneName(sceneId) + ". Now choose when it plays and its bonuses.");
  }
  // your own animation as the intro: the intro needs to exist first (a game scene stands in until yours is used)
  function useOwn(kind) {
    const d = document.getElementById("dialog");
    if (d && d.open) d.close();
    if (!carrier()) {
      const first = scenes()[0];
      if (!first) throw new Error("The game's entrance scenes are still loading. Try again in a moment.");
      commit(() => { const v = view(); Forge.addPassive(v, { efficacy_type: 0, calc_option: 0, target_type: 1, exec_timing_type: 1, turn: 1, probability: 100, is_once: 1, eff_value1: 0, eff_value2: 0, eff_value3: 0, efficacy_values: "{}", causality_conditions: null, passive_skill_effect_id: first[0] }); });
    }
    const c = carrier();
    if (!c || !window.ForgeGuideUI || !ForgeGuideUI.action) return;
    return ForgeGuideUI.action((kind === "saved" ? "gallery:" : "studio:") + "intro:" + c.id);
  }
  function removeIntro() {
    const v = view(), c = carrier(v);
    if (!c) return;
    commit(() => {
      delete (p().animationAssignments || {})["intro:" + c.id];
      if (Number(c.efficacy_type) === 0 && !(v.tables.dokkan_field_passive_skill_relations || []).some((x) => x.passive_skill_id === c.id)) Forge.removePassive(v, c.id);
      else c.passive_skill_effect_id = null;
    });
    toast("Intro removed. ↶ Undo brings it back.");
  }
  // a typical game intro bonus: Ki +3 and ATK & DEF 100%↑ for 5 turns (once, with the intro)
  function presetBonus() {
    const v = view(), c = carrier(v);
    if (!c) return;
    commit(() => {
      for (const [key, vals] of [["ki", { amount: 3 }], ["atkdef", { atk: 100, def: 100 }]]) {
        const r = B().addPassiveAbility(v, key, vals, Object.assign(B().newPassiveSettings(key), { timing: 1, turn: 5, once: true, target: 1 }));
        r.causality_conditions = c.causality_conditions;
      }
    });
    toast("Added: Ki +3 and ATK & DEF 100%↑ for 5 turns when the intro plays.");
  }
  document.addEventListener("click", (e) => {
    const b = e.target.closest && e.target.closest("[data-intro]");
    if (!b || !state.project || !document.getElementById("bld")) return;
    const [act, arg] = b.dataset.intro.split(":");
    try {
      if (act === "add") return pickScene(addIntro);
      if (act === "own") return useOwn(arg);
      if (act === "scene") return pickScene((id) => commit(() => { const c = carrier(); c.passive_skill_effect_id = id; if (window.ForgeAnimChoice) ForgeAnimChoice.dropOwn("intro:" + c.id); }));
      if (act === "remove") return removeIntro();
      if (act === "preset") return presetBonus();
      if (act === "bonus") return window.ForgePassiveFamilies && ForgePassiveFamilies.open("add", { linkTo: carrier().id, keepHere: true, after: () => UI().commit(() => normalize(view())) });
      if (act === "edit") { UI().tab("passive"); setTimeout(() => UI().open("passive:" + arg), 50); return; }
      if (act === "del") { commit(() => removeBonus(Number(arg))); return; }
    } catch (err) { toast(err.message || String(err), true); }
  });
  document.addEventListener("change", (e) => {
    const el = e.target;
    if (!el.matches || !document.getElementById("bld") || !el.closest(".intro-panel")) return;
    try {
      if (el.matches("[data-intro-when]")) { if (el.value !== "custom") setWhen(readWhen(document.createElement("div"), el.value)); return; }
      if (el.matches("[data-intro-v]")) { const key = el.closest(".intro-panel").querySelector("[data-intro-when]").value; setWhen(readWhen(el.closest(".intro-sec"), key)); return; }
      if (el.matches("[data-intro-turn]")) { const r = (p().tables.passive_skills || []).find((x) => x.id === Number(el.dataset.introTurn)); if (r) commit(() => { r.turn = Number(el.value); }); }
    } catch (err) { toast(err.message || String(err), true); }
  });
  return { html, status, carrier, bonuses: gains, sceneName };
})();
