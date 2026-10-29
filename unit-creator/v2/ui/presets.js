"use strict";
// Templates & presets: ready-made units and ready-made pieces (Passive abilities, Super Attack
// effects, Leader Skills, Active Skills). Everything is applied through the same action engine as
// the AI helper: you first see exactly what will change (worked out on a copy of your unit), then
// apply it, and Undo takes it back.
window.ForgePresets = (() => {
  const turn = (n) => [{ rule: "turn", turn: n }];
  const P = (abilities) => [{ do: "passive", replace: false, abilities }];
  const PRESETS = {
    passive: [
      { icon: "⬆", name: "Power up every turn", text: "ATK & DEF +120% at the start of each turn.", actions: P([{ ability: "atkdef", values: { atk: 120, def: 120 } }]) },
      { icon: "⚡", name: "Ki boost", text: "Ki +3 every turn, so Super Attacks come sooner.", actions: P([{ ability: "ki", values: { amount: 3 } }]) },
      { icon: "🛡", name: "Tough as nails", text: "Takes 30% less damage from every attack.", actions: P([{ ability: "dr", values: { amount: 30 } }]) },
      { icon: "🧱", name: "Guard from turn 3", text: "Guards all attacks once the battle reaches turn 3.", actions: P([{ ability: "guard", values: {}, conditions: turn(3) }]) },
      { icon: "💨", name: "Lucky dodger", text: "25% chance to evade enemy attacks.", actions: P([{ ability: "dodge", values: { amount: 25 } }]) },
      { icon: "🎯", name: "Critical striker", text: "40% chance of a critical hit when attacking.", actions: P([{ ability: "crit", values: { amount: 40 }, when: "attacking" }]) },
      { icon: "➕", name: "Extra attack", text: "Launches an additional attack that has a 50% chance of becoming a Super Attack.", actions: P([{ ability: "additional", values: { super: 50 }, when: "attacking" }]) },
      { icon: "📈", name: "Gets stronger with each attack", text: "ATK +20% for every 5 attacks, up to +100% (kept for the battle).", actions: P([{ ability: "stack", values: { stat: 0, step: 20, max: 100, trigger: 5 } }]) },
      { icon: "❤", name: "Heal when low", text: "Recovers 10% HP each turn when HP is 50% or less.", actions: P([{ ability: "heal", values: { amount: 10 }, conditions: [{ rule: "hpBelow", hp: 50 }] }]) },
      { icon: "🤝", name: "Team supporter", text: "Allies get Ki +2 and ATK & DEF +30%.", actions: P([{ ability: "ki", values: { amount: 2 }, who: "alliesExceptSelf" }, { ability: "atkdef", values: { atk: 30, def: 30 }, who: "alliesExceptSelf" }]) },
      { icon: "👁", name: "Foresee Super Attacks", text: "Shows which enemy will use a Super Attack.", actions: P([{ ability: "foresee", values: {}, who: "allies" }]) },
      { icon: "🌐", name: "Effective against all Types", text: "Attacks hit every Type as if they were weak to it.", actions: P([{ ability: "effective", values: {} }]) }
    ],
    super: [
      { icon: "💥", name: "Raise ATK for the battle", text: "Super Attack raises ATK by 50% for the rest of the battle.", actions: [{ do: "super", which: "super", effects: [{ effect: "atk", values: { amount: 50 }, who: "self", turns: 99 }] }] },
      { icon: "🛡", name: "Raise DEF", text: "Super Attack raises DEF by 50% for 3 turns.", actions: [{ do: "super", which: "super", effects: [{ effect: "def", values: { amount: 50 }, who: "self", turns: 3 }] }] },
      { icon: "📉", name: "Weaken the enemy", text: "Lowers the enemy’s DEF by 30% for 3 turns.", actions: [{ do: "super", which: "super", effects: [{ effect: "defDown", values: { amount: 30 }, turns: 3 }] }] },
      { icon: "💫", name: "Stun", text: "Super Attack may stun the enemy.", actions: [{ do: "super", which: "super", effects: [{ effect: "stun", values: {}, turns: 1, chance: 50 }] }] },
      { icon: "🔥", name: "Bigger damage", text: "Changes the Super Attack’s damage to “immense”.", actions: [{ do: "super", which: "super", damage: "immense" }] }
    ],
    leader: [
      { icon: "♛", name: "All Types +150%", text: "Ki +3 and HP, ATK & DEF +150% for every ally.", actions: [{ do: "leader", groups: [{ who: "all", ki: 3, hp: 150, atk: 150, def: 150 }] }] },
      { icon: "♛", name: "Super Class +80%", text: "Ki +3 and HP, ATK & DEF +80% for Super Class allies.", actions: [{ do: "leader", groups: [{ who: "super", ki: 3, hp: 80, atk: 80, def: 80 }] }] },
      { icon: "♛", name: "Extreme Class +80%", text: "Ki +3 and HP, ATK & DEF +80% for Extreme Class allies.", actions: [{ do: "leader", groups: [{ who: "extreme", ki: 3, hp: 80, atk: 80, def: 80 }] }] },
      { icon: "♛", name: "My Category +170%", text: "Ki +3 and HP, ATK & DEF +170% for allies in this unit’s first Category (like real LR leaders).", needsCategory: true, actions: (cat) => [{ do: "leader", groups: [{ who: "categories", categories: [cat], ki: 3, hp: 170, atk: 170, def: 170 }] }] }
    ],
    active: [
      { icon: "⚡", name: "Ultimate attack from turn 4", text: "A one-time massive attack the player can use from turn 4.", actions: [{ do: "active", kind: "attack", name: "Ultimate Strike", boost: 200, conditions: turn(4) }] },
      { icon: "🔥", name: "Power surge when hurt", text: "Once, when HP is 50% or less: ATK +100% for 1 turn.", actions: [{ do: "active", kind: "buff", name: "Last Stand", effects: [{ effect: "atk", values: { amount: 100 }, who: "self" }], conditions: [{ rule: "hpBelow", hp: 50 }], turns: 1 }] }
    ]
  };
  const GROUPS = [["unit", "Whole unit"], ["passive", "Passive abilities"], ["super", "Super Attack"], ["leader", "Leader Skill"], ["active", "Active Skill"]];
  const TAB_FOR = { basics: "unit", leader: "leader", passive: "passive", supers: "super", active: "active" };
  // Two extra unit templates built from the Quick Create ones.
  const EXTRA_STYLES = [
    { key: "crit", base: "allround", icon: "🎯", name: "Critical striker", text: "High ATK and frequent critical hits that ignore enemy defences.", passive: [{ ability: "atkdef", values: { atk: 200, def: 120 } }, { ability: "ki", values: { amount: 3 } }, { ability: "crit", values: { amount: 60 }, when: "attacking" }, { ability: "additional", values: { super: 30 }, when: "attacking" }] },
    { key: "healer", base: "support", icon: "❤", name: "Healer", text: "Keeps the team alive: heals every turn, reduces damage and boosts allies.", passive: [{ ability: "atkdef", values: { atk: 150, def: 180 } }, { ability: "ki", values: { amount: 3 } }, { ability: "heal", values: { amount: 7 } }, { ability: "dr", values: { amount: 20 } }, { ability: "atkdef", values: { atk: 20, def: 20 }, who: "alliesExceptSelf" }] }
  ];
  let sheet = null, group = "unit";

  function card() { return state.project ? Forge.card(state.project) : null; }
  function firstCategory(p) {
    const id = ((p.tables.card_card_categories || [])[0] || {}).card_category_id;
    const c = (state.categories || []).find((x) => x.id === id);
    return c && c.name && c.name !== "0" ? c.name : null;
  }
  function unitTemplates() {
    const QC = window.ForgeQuickCreate;
    if (!QC) return [];
    const list = QC.STYLES.map((s) => ({ icon: s.icon, name: s.name, text: s.text, style: s }));
    for (const x of EXTRA_STYLES) list.push({ icon: x.icon, name: x.name, text: x.text, style: QC.STYLES.find((s) => s.key === x.base), passive: x.passive });
    return list;
  }
  function actionsFor(item, p) {
    if (item.style) {
      const c = Forge.card(p), parts = ForgeBuilder.elementParts(c.element), cats = (p.tables.card_card_categories || []).map((r) => ((state.categories || []).find((x) => x.id === r.card_category_id) || {}).name).filter((n) => n && n !== "0");
      const acts = ForgeQuickCreate.styleActions(item.style, { name: c.name, rarity: Forge.rarities[c.rarity] === "LR" ? "LR" : "UR", cls: ForgeBuilder.CLASSES[parts.cls] || "Super", type: ForgeBuilder.TYPES[parts.type] || "AGL", category: cats[0], also: cats[1] });
      for (const a of acts) {
        if (a.do === "basics") { delete a.name; delete a.rarity; delete a.class; delete a.type; }
        if (a.do === "passive" && item.passive) a.abilities = item.passive;
      }
      return acts;
    }
    if (item.needsCategory) {
      const cat = firstCategory(p);
      if (!cat) throw Error("Give this unit a Category first (Links & Categories step).");
      return item.actions(cat);
    }
    return JSON.parse(JSON.stringify(item.actions));
  }
  function items() { return group === "unit" ? unitTemplates() : PRESETS[group]; }
  function stats(p) {
    const c = Forge.card(p);
    return { hp: c.hp_max, atk: c.atk_max, def: c.def_max };
  }

  async function open(which) {
    if (which) group = which;
    else if (state.view === "editor" && TAB_FOR[state.builderTab]) group = TAB_FOR[state.builderTab];
    if (!sheet) {
      sheet = document.createElement("dialog");
      sheet.className = "shell-sheet presets-sheet";
      sheet.setAttribute("aria-labelledby", "presets-title");
      document.body.append(sheet);
    }
    if (!(state.categories || []).length && typeof loadLookups === "function") { try { await loadLookups(); } catch {} }
    draw();
    if (!sheet.open) sheet.showModal();
  }
  function draw() {
    const c = card();
    sheet.innerHTML = '<div class="sheet-head"><h2 id="presets-title">Templates &amp; presets</h2><button type="button" class="icon-button" data-sheet-close aria-label="Close">×</button></div>' +
      (c ? '<p class="hint">For <strong>' + esc(c.name) + "</strong>. Tap a preset to see what it changes before anything is applied.</p>" : '<div class="notice"><strong>Open a unit first.</strong> Presets change the unit you are editing. Start one with Quick Create, or open one from Home.</div><div class="row"><button type="button" class="button" data-presets-go="quick">⚡ Quick Create</button><button type="button" class="button ghost" data-presets-go="home">My units</button></div>') +
      '<nav class="preset-tabs" role="tablist">' + GROUPS.map(([k, l]) => '<button type="button" role="tab" aria-selected="' + (k === group) + '" class="' + (k === group ? "on" : "") + '" data-preset-group="' + k + '">' + l + "</button>").join("") + "</nav>" +
      '<p class="hint preset-intro">' + ({ unit: "A complete fighting style: stats, Leader Skill, Passive, Super Attack effects (and an Active Skill for LRs). Your unit’s name, rarity and look stay the same.", passive: "Adds one ability to your Passive Skill. Your other abilities stay.", super: "Changes the effects of your unit’s Super Attack.", leader: "Replaces the Leader Skill with a typical one.", active: "Adds or replaces the Active Skill." })[group] + "</p>" +
      '<div class="preset-grid">' + items().map((it, i) => '<button type="button" class="preset-card" data-preset="' + i + '"' + (c ? "" : " disabled") + '><span class="preset-icon" aria-hidden="true">' + it.icon + "</span><span><strong>" + esc(it.name) + "</strong><small>" + esc(it.text) + "</small></span></button>").join("") + "</div>" +
      '<div id="preset-review" aria-live="polite"></div>';
    sheet.querySelector("[data-sheet-close]").onclick = () => sheet.close();
    sheet.querySelectorAll("[data-presets-go]").forEach((b) => b.onclick = () => { sheet.close(); ForgeShell.go(b.dataset.presetsGo); });
    sheet.querySelectorAll("[data-preset-group]").forEach((b) => b.onclick = () => { group = b.dataset.presetGroup; draw(); });
    sheet.querySelectorAll("[data-preset]").forEach((b) => b.onclick = () => review(items()[Number(b.dataset.preset)]).catch((e) => showError(e)));
  }
  function showError(e) {
    const box = sheet.querySelector("#preset-review");
    box.innerHTML = '<div class="notice error"><strong>This preset can’t be used yet.</strong> ' + esc(e.message || String(e)) + "</div>";
    box.scrollIntoView({ block: "nearest", behavior: "smooth" });
  }
  async function review(item) {
    if (!state.project) throw Error("Open a unit first.");
    const ctx = await ForgeAIConnect.context(), baseline = JSON.stringify(state.project), copy = Forge.clone(state.project);
    const actions = actionsFor(item, copy);
    const result = ForgeAIConnect.applyActions(copy, actions, ctx);
    const before = stats(state.project), after = stats(copy);
    const stat = (k, label) => '<div class="preset-stat"><span>' + label + "</span><strong>" + number(after[k]) + "</strong>" + (after[k] !== before[k] ? '<small class="' + (after[k] > before[k] ? "up" : "down") + '">' + (after[k] > before[k] ? "▲ " : "▼ ") + number(Math.abs(after[k] - before[k])) + "</small>" : "<small>same</small>") + "</div>";
    const box = sheet.querySelector("#preset-review");
    box.innerHTML = '<section class="preset-preview"><h3>' + esc(item.icon + " " + item.name) + ' · preview</h3><div class="preset-stats">' + stat("hp", "HP") + stat("atk", "ATK") + stat("def", "DEF") + "</div>" +
      (result.changes.length ? "<p><strong>What will change:</strong></p><ul>" + result.changes.map((x) => "<li>" + esc(x) + "</li>").join("") + "</ul>" : '<p class="hint">Nothing would change — your unit already has this.</p>') +
      '<div class="row"><button type="button" class="button" id="preset-apply"' + (result.changes.length ? "" : " disabled") + '>Apply to my unit</button><button type="button" class="button ghost" id="preset-cancel">Not now</button></div><p class="hint">You can take it back with ↶ Undo.</p></section>';
    box.scrollIntoView({ block: "nearest", behavior: "smooth" });
    box.querySelector("#preset-cancel").onclick = () => { box.textContent = ""; };
    box.querySelector("#preset-apply").onclick = async () => {
      if (JSON.stringify(state.project) !== baseline) return review(item);
      ForgeAIConnect.applyActions(state.project, actionsFor(item, state.project), ctx);
      if (window.ForgeBuilderUI) ForgeBuilderUI.refreshTexts();
      scheduleSave();
      await flushSave().catch((e) => toast(e.message, true));
      sheet.close();
      if (state.view === "editor") renderEditor(); else await navigate("editor");
      toast("“" + item.name + "” applied. Tap ↶ Undo to take it back.");
    };
  }
  // Entry points: the card builder's toolbar, each builder step and the Home screen.
  let queued = false;
  function inject() {
    queued = false;
    const tools = document.querySelector(".bld-tools");
    if (tools && !tools.querySelector(".shell-presets-button")) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "button ghost small shell-presets-button";
      b.textContent = "★ Presets";
      b.onclick = () => open();
      (tools.querySelector('[data-b="ai-helper"]') || tools.firstChild)?.after(b);
    }
    const add = document.querySelector('[data-b="adding:on"]');
    if (add && !add.parentElement.querySelector(".shell-presets-inline")) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "button ghost small shell-presets-inline";
      b.textContent = "★ Add a preset ability";
      b.onclick = () => open("passive");
      add.after(b);
    }
    const home = document.querySelector(".db-actions");
    if (home && !home.querySelector(".shell-presets-home")) {
      const b = document.createElement("button");
      b.type = "button";
      b.className = "db-action shell-presets-home";
      b.innerHTML = '<span class="db-action-icon">★</span><span><strong>Start from a template</strong><small>Ready-made units like Tank or Heavy hitter — see the stats before you pick.</small></span>';
      b.onclick = () => open("unit");
      home.prepend(b);
    }
  }
  new MutationObserver(() => { if (!queued) { queued = true; requestAnimationFrame(inject); } }).observe(document.body, { childList: true, subtree: true });
  return { open, PRESETS, unitTemplates };
})();
