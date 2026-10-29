/* Card Builder model: plain-English ability catalogs that read and write the real game rows.
   Every catalog entry mirrors the most common official row shape for that effect in the bundled
   Eclipse database, so abilities built here behave like official ones. Pure logic, no DOM. */
(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./core"), require("./guide-model"));
  else root.ForgeBuilder = factory(root.Forge, root.ForgeGuide);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Forge, G) {
  "use strict";
  const clone = (v) => JSON.parse(JSON.stringify(v));
  const TYPES = ["AGL", "TEQ", "INT", "STR", "PHY"];
  const TYPE_COLORS = ["#2d7ff9", "#1fae4b", "#9b51e0", "#e5383b", "#f08c00"];
  const SPHERES = ["AGL", "TEQ", "INT", "STR", "PHY", "Rainbow"];
  const CLASSES = ["", "Super", "Extreme"];
  const int = (v, min, max, fallback = min) => {
    const n = Math.round(Number(v));
    if (!Number.isFinite(n)) return fallback;
    return Math.min(max, Math.max(min, n));
  };
  function ordinal(n) {
    const s = ["th", "st", "nd", "rd"], v = n % 100;
    return n + (s[(v - 20) % 10] || s[v] || s[0]);
  }
  const cap = (s) => s ? s.charAt(0).toUpperCase() + s.slice(1) : s;
  function list(items, word = "or") {
    if (items.length < 2) return items.join("");
    return items.slice(0, -1).join(", ") + " " + word + " " + items[items.length - 1];
  }
  function elementParts(element) {
    const e = Number(element) || 0;
    return { cls: e >= 20 ? 2 : e >= 10 ? 1 : 0, type: ((e % 10) + 10) % 10 % 5 };
  }
  const elementValue = (cls, type) => int(cls, 0, 2) * 10 + int(type, 0, 4);

  // ---------------------------------------------------------------- conditions
  const num = (name, label, def, min = 0, max = 999) => ({ name, label, kind: "number", def, min, max });
  // Ki in conditions is stored as a percentage that depends on rarity (LR: 24 Ki = 800, others: 24 Ki = 600)
  let kiScale = () => 25;
  function setKiScale(fn) { kiScale = fn; }
  const kiValue = (ki) => Math.round(Number(ki) * kiScale());
  const kiFrom = (v) => Math.round(Number(v) / kiScale());
  const CONDITIONS = [
    { key: "hpBelow", label: "HP is at or below a %", type: 2, fields: [num("hp", "HP %", 50, 1, 100)], enc: (v) => [v.hp, 0, 0], dec: (r) => ({ hp: r.cau_val1 }), text: (v) => "when HP is " + v.hp + "% or less" },
    { key: "hpAbove", label: "HP is at or above a %", type: 1, fields: [num("hp", "HP %", 50, 1, 100)], enc: (v) => [v.hp, 0, 0], dec: (r) => ({ hp: r.cau_val1 }), text: (v) => "when HP is " + v.hp + "% or more" },
    { key: "turn", label: "From a turn of the battle", type: 5, fields: [num("turn", "Starting turn", 4, 1, 99)], enc: (v) => [v.turn - 1, 0, 0], dec: (r) => ({ turn: r.cau_val1 + 1 }), text: (v) => "starting from the " + ordinal(v.turn) + " turn from the start of battle" },
    { key: "entryTurn", label: "From a turn after the character appears", type: 55, fields: [num("turn", "Starting turn", 3, 1, 99)], enc: (v) => [v.turn - 1, 0, 0], dec: (r) => ({ turn: r.cau_val1 + 1 }), text: (v) => "starting from the " + ordinal(v.turn) + " turn from the character's entry turn" },
    { key: "firstTurns", label: "During the first turns after appearing", type: 51, fields: [num("turns", "Number of turns", 3, 1, 99)], enc: (v) => [v.turns, 0, 0], dec: (r) => ({ turns: r.cau_val1 }), text: (v) => "for " + v.turns + " turn" + (v.turns === 1 ? "" : "s") + " from the character's entry turn" },
    { key: "hpBelowTurn", label: "HP at or below a % from a battle turn", type: 37, fields: [num("hp", "HP %", 50, 1, 100), num("turn", "Starting turn", 3, 1, 99)], enc: (v) => [v.hp, v.turn - 1, 0], dec: (r) => ({ hp: r.cau_val1, turn: r.cau_val2 + 1 }), text: (v) => "when HP is " + v.hp + "% or less starting from the " + ordinal(v.turn) + " turn from the start of battle" },
    // The game treats activating the Active Skill as attacking with 24 Ki ("When activating the Active Skill or when attacking with 24 Ki")
    { key: "activeSkill", label: "When activating the Active Skill", type: 3, fields: [], enc: () => [kiValue(24), 0, 0], dec: () => ({}), text: () => "when activating the Active Skill or when attacking with 24 Ki" },
    { key: "kiAbove", label: "When attacking with a certain Ki or more", type: 3, fields: [num("ki", "Ki", 18, 1, 24)], enc: (v) => [kiValue(v.ki), 0, 0], dec: (r) => ({ ki: kiFrom(r.cau_val1) }), text: (v) => v.ki >= 24 ? "when activating the Active Skill or when attacking with 24 Ki" : "when attacking with " + v.ki + " or more Ki" },
    { key: "attacks", label: "After performing a number of attacks", type: 44, sub: 2, fields: [num("count", "Number of attacks", 5, 1, 99)], enc: (v) => [2, v.count, 0], dec: (r) => ({ count: r.cau_val2 }), text: (v) => "after performing " + v.count + " or more attacks in battle" },
    { key: "supers", label: "After performing a number of Super Attacks", type: 44, sub: 1, fields: [num("count", "Number of Super Attacks", 3, 1, 99)], enc: (v) => [1, v.count, 0], dec: (r) => ({ count: r.cau_val2 }), text: (v) => "after performing " + v.count + " or more Super Attacks in battle" },
    { key: "received", label: "After receiving a number of attacks", type: 44, sub: 3, fields: [num("count", "Number of attacks received", 5, 1, 99)], enc: (v) => [3, v.count, 0], dec: (r) => ({ count: r.cau_val2 }), text: (v) => "after receiving " + v.count + " or more attacks in battle" },
    { key: "guards", label: "After guarding a number of attacks", type: 44, sub: 4, fields: [num("count", "Number of guards", 3, 1, 99)], enc: (v) => [4, v.count, 0], dec: (r) => ({ count: r.cau_val2 }), text: (v) => "after guarding " + v.count + " or more attacks in battle" },
    { key: "dodges", label: "After evading a number of attacks", type: 44, sub: 5, fields: [num("count", "Number of evasions", 3, 1, 99)], enc: (v) => [5, v.count, 0], dec: (r) => ({ count: r.cau_val2 }), text: (v) => "after evading " + v.count + " or more attacks in battle" },
    { key: "gotHit", label: "After receiving an attack", type: 24, fields: [], enc: () => [0, 0, 0], dec: () => ({}), text: () => "after receiving an attack" },
    { key: "dodged", label: "After evading an attack", type: 43, fields: [], enc: () => [0, 0, 0], dec: () => ({}), text: () => "after evading an attack" },
    { key: "guarded", label: "After guarding an attack", type: 30, fields: [], enc: () => [0, 0, 0], dec: () => ({}), text: () => "after guarding an attack" },
    { key: "superMove", label: "When performing or receiving a Super Attack", type: 40, fields: [], enc: () => [0, 0, 0], dec: () => ({}), text: () => "when performing or receiving a Super Attack" },
    { key: "defeated", label: "After defeating an enemy", type: 25, fields: [], enc: () => [0, 0, 0], dec: () => ({}), text: () => "after defeating an enemy" },
    { key: "allies", label: "Category allies on the team", type: 34, sub: 0, fields: [{ name: "category", label: "Category", kind: "category" }, num("count", "Characters needed (including this one)", 2, 1, 7)], enc: (v) => [0, v.category, v.count], dec: (r) => ({ category: r.cau_val2, count: r.cau_val3 }), text: (v, names) => {
      const n = '"' + (names.category(v.category) || "chosen") + '" Category';
      return v.count <= 1 ? "when there is a " + n + " ally on the team" : v.count === 2 ? "when there is another " + n + " ally on the team" : "when there are another " + (v.count - 1) + " or more " + n + " allies on the team";
    } },
    { key: "enemyCategory", label: "Facing a Category enemy", type: 34, sub: 1, fields: [{ name: "category", label: "Category", kind: "category" }], enc: (v) => [1, v.category, 1], dec: (r) => ({ category: r.cau_val2 }), text: (v, names) => 'when there is a "' + (names.category(v.category) || "chosen") + '" Category enemy' },
    { key: "enemyHp", label: "Enemy HP at or below a %", type: 18, fields: [num("hp", "Enemy HP %", 50, 1, 100)], enc: (v) => [v.hp, 0, 0], dec: (r) => ({ hp: r.cau_val1 }), text: (v) => "when the enemy's HP is " + v.hp + "% or less" },
    { key: "allyName", label: "A character with a certain name is on the team", type: 41, sub: 0, fields: [{ name: "set", label: "Character name", kind: "nameSet" }, num("count", "How many needed", 1, 1, 6)], enc: (v) => [0, v.set, v.count], dec: (r) => ({ set: r.cau_val2, count: r.cau_val3 }), text: (v, names) => { const n = '"' + ((names.nameSet && names.nameSet(v.set)) || "chosen character") + '"'; return v.count <= 1 ? "when there is an ally whose name includes " + n + " on the team" : "when there are " + v.count + " or more allies whose names include " + n + " on the team"; } },
    { key: "enemyName", label: "Facing an enemy with a certain name", type: 41, sub: 1, fields: [{ name: "set", label: "Enemy name", kind: "nameSet" }], enc: (v) => [1, v.set, 1], dec: (r) => ({ set: r.cau_val2 }), text: (v, names) => 'when there is an enemy whose name includes "' + ((names.nameSet && names.nameSet(v.set)) || "chosen character") + '"' },
    { key: "turnName", label: "A character with a certain name attacks in the same turn", type: 41, sub: 2, fields: [{ name: "set", label: "Character name", kind: "nameSet" }], enc: (v) => [2, v.set, 1], dec: (r) => ({ set: r.cau_val2 }), text: (v, names) => 'when there is an ally whose name includes "' + ((names.nameSet && names.nameSet(v.set)) || "chosen character") + '" attacking in the same turn' },
    { key: "classAllies", label: "Super or Extreme Class allies on the team", type: 46, sub: 0, fields: [{ name: "cls", label: "Class", kind: "choice", def: 32, options: [[32, "Super Class"], [64, "Extreme Class"]] }, num("count", "How many needed", 3, 1, 7)], enc: (v) => [0, v.cls, v.count], dec: (r) => ({ cls: r.cau_val2, count: r.cau_val3 }), text: (v) => { const w = window.ForgeConditionWords; return w ? w.phrase({ causality_type: 46, cau_val1: 0, cau_val2: v.cls, cau_val3: v.count }, {}) : "when there are " + v.count + " or more allies of the chosen Class on the team"; } },
    { key: "revived", label: "After this character revives (its Revival Skill activated)", type: 47, fields: [], enc: () => [0, 0, 0], dec: () => ({}), text: () => "after the character's Revival Skill is activated" },
    { key: "allyRevived", label: "After any ally revives — applies when this character is in the rotation, even if it wasn't when the ally revived", type: 54, fields: [], enc: () => [0, 0, 0], dec: () => ({}), text: () => "after an ally's Revival Skill is activated" },
    { key: "slot", label: "Attacking in a chosen slot", type: 19, fields: [{ name: "slot", label: "Attack slot", kind: "choice", def: 0, options: [[0, "1st attacker"], [1, "2nd attacker"], [2, "3rd attacker"]] }], enc: (v) => [v.slot, 0, 0], dec: (r) => ({ slot: r.cau_val1 }), text: (v) => "as the " + ordinal(Number(v.slot) + 1) + " attacker in a turn" }
  ];
  const conditionDef = (key) => CONDITIONS.find((c) => c.key === key);
  function conditionDefaults(key) {
    const def = conditionDef(key), out = {};
    for (const f of def ? def.fields : []) out[f.name] = f.def !== undefined ? f.def : f.kind === "choice" ? f.options[0][0] : 0;
    return out;
  }
  function normalizeConditionValues(def, values) {
    const out = {};
    for (const f of def.fields) {
      const raw = values && values[f.name] !== undefined ? values[f.name] : f.def;
      if (f.kind === "number") out[f.name] = int(raw, f.min, f.max, f.def);
      else if (f.kind === "nameSet") {
        const id = Number(raw);
        if (!Number.isSafeInteger(id) || id <= 0) throw new Error("Choose a character name for this condition.");
        out[f.name] = id;
      } else if (f.kind === "category") {
        const id = Number(raw);
        if (!Number.isSafeInteger(id) || id <= 0) throw new Error("Choose a category for this condition.");
        out[f.name] = id;
      } else out[f.name] = f.options.some(([v]) => String(v) === String(raw)) ? Number(raw) : f.options[0][0];
    }
    return out;
  }
  function conditionRule(item) {
    const def = conditionDef(item.key);
    if (!def) throw new Error("Choose a supported condition.");
    const values = normalizeConditionValues(def, item.values);
    return { type: def.type, values: def.enc(values) };
  }
  function matchCondition(record) {
    if (!record) return null;
    const type = Number(record.causality_type);
    // the first simple rule of this type that round-trips exactly
    for (const def of CONDITIONS.filter((c) => c.type === type && (c.sub === undefined || Number(record.cau_val1) === c.sub))) {
      const values = def.dec({ cau_val1: Number(record.cau_val1), cau_val2: Number(record.cau_val2), cau_val3: Number(record.cau_val3) });
      const back = def.enc(values);
      if (back[0] === Number(record.cau_val1) && back[1] === Number(record.cau_val2) && back[2] === Number(record.cau_val3)) return { key: def.key, values };
    }
    return null;
  }
  // Reads a causality_conditions value into { mode, items } when every rule is a known simple rule.
  // Returns null for "always", { pending: ids } when records must be loaded first, or { custom: true }.
  function decodeCondition(value, lookup) {
    if (!value) return null;
    let compiled;
    try { compiled = JSON.parse(value).compiled; } catch { return { custom: true }; }
    if (compiled === undefined || compiled === null) return null;
    let op = null;
    const ids = [];
    const visit = (node) => {
      if (typeof node === "number") { ids.push(node); return true; }
      if (!Array.isArray(node) || !["&", "|"].includes(node[0])) return false;
      if (op && op !== node[0]) return false;
      op = node[0];
      return node.slice(1).every(visit);
    };
    if (!visit(compiled)) return { custom: true };
    const missing = ids.filter((id) => lookup(id) === undefined);
    if (missing.length) return { pending: missing };
    const items = ids.map((id) => matchCondition(lookup(id)));
    if (items.some((x) => !x)) return { custom: true, ids };
    return { mode: op === "|" ? "any" : "all", items };
  }
  function conditionText(spec, names) {
    if (!spec || !spec.items || !spec.items.length) return "";
    const parts = spec.items.map((item) => {
      const def = conditionDef(item.key);
      return def ? def.text(normalizeConditionValues(def, item.values), names) : "";
    }).filter(Boolean);
    return list(parts, spec.mode === "any" ? "or" : "and");
  }
  function applyCondition(p, schema, row, spec) {
    const items = spec && spec.items || [];
    G.setCondition(p, schema, row, items.map(conditionRule), spec && spec.mode === "any" ? "any" : "all");
    pruneCausalities(p);
  }
  function pruneCausalities(p) {
    const local = p.tables.skill_causalities;
    if (!local || !local.length) return;
    const used = new Set();
    const scan = (value) => {
      if (!value) return;
      try {
        const visit = (n) => { if (typeof n === "number") used.add(n); else if (Array.isArray(n)) n.slice(1).forEach(visit); };
        visit(JSON.parse(value).compiled);
      } catch {}
    };
    const members = [p];
    for (const member of members) for (const rows of Object.values(member.tables)) for (const row of rows) if (row && typeof row.causality_conditions === "string") scan(row.causality_conditions);
    p.tables.skill_causalities = local.filter((r) => Number(r.id) > 0 || used.has(r.id));
  }

  // ---------------------------------------------------------------- shared effect wording
  const TARGETS = {
    1: { label: "Only this character", owner: "" },
    2: { label: "The whole team (this character and every ally)", owner: "all allies' " },
    16: { label: "Every ally except this character", owner: "allies' ", suffix: " (self excluded)" },
    12: { label: "Super Class allies only (incl. this character if Super)", owner: "Super Class allies' " },
    13: { label: "Extreme Class allies only (incl. this character if Extreme)", owner: "Extreme Class allies' " },
    3: { label: "The enemy this character attacks", owner: "the attacked enemy's " },
    4: { label: "Every enemy on the field", owner: "all enemies' " },
    14: { label: "Super Class enemies", owner: "Super Class enemies' " },
    15: { label: "Extreme Class enemies", owner: "Extreme Class enemies' " }
  };
  const VERB_EFFECTS = ["dr", "guard", "dodge", "heal", "immune", "foresee", "crit", "effective", "additional"];
  const SUBJECTS = { 2: "all allies", 16: "allies (self excluded)", 12: "Super Class allies", 13: "Extreme Class allies", 3: "the attacked enemy", 4: "all enemies" };
  const TARGET_SETS = { self: [1], buff: [1, 2, 16, 12, 13], allies: [2, 16, 12, 13], enemy: [3, 4], selfOrAllies: [1, 2] };
  const pctField = (name, label, def, min = 1, max = 2000) => ({ name, label, kind: "number", def, min, max, unit: "%" });
  const statPair = (atk, def) => atk === def ? "ATK & DEF +" + atk + "%" : "ATK +" + atk + "% and DEF +" + def + "%";
  const statPairDown = (atk, def) => atk === def ? "ATK & DEF −" + atk + "%" : "ATK −" + atk + "% and DEF −" + def + "%";
  const sphereMaskOptions = [[1, "AGL"], [2, "TEQ"], [4, "INT"], [8, "STR"], [16, "PHY"], [32, "Rainbow"], [31, "any Type (not Rainbow)"], [63, "any"]];
  const stackStats = [[0, "ATK", "%"], [1, "DEF", "%"], [2, "critical hit chance", "%"], [3, "dodge chance", "%"], [4, "damage reduction", "%"], [5, "Ki", ""]];
  const stackTriggers = [[5, "with each attack performed"], [7, "with each attack received"], [1, "at the start of each turn"]];


  // ---------------------------------------------------------------- counters & revivals
  // Counter animations (lua/ab_script/attack_counter/cNNNN.lua) and revival scenes that exist in
  // the game, named after a character that uses them. Your own counter animation can be made on
  // Artwork & Aura.
  const COUNTER_ANIMS = [[2, "Super Vegito"], [3, "Super Saiyan 4 Goku"], [4, "Super Saiyan 4 Vegeta"], [5, "Super Saiyan 4 Gogeta"], [6, "Super Saiyan 2 Caulifla"], [7, "Super Vegito \u00b7 version 2"], [8, "Super Saiyan 2 Vegeta & Bulma"], [9, "Super Full Power Saiyan 4 Goku"], [10, "Super Saiyan 4 Goku \u00b7 version 2"], [11, "Super Saiyan 4 Vegeta \u00b7 version 2"], [12, "Great Saiyaman 3"], [13, "Super Saiyan Goku"], [15, "Super Saiyan 4 Gogeta \u00b7 version 2"], [16, "Super Saiyan 4 Vegito (Xeno)"], [19, "Fusion Zamasu"], [20, "Gamma 1"], [21, "Goku"], [23, "Super Saiyan 3 Goku (Angel)"], [24, "Majin Buu (Pure Evil)"], [25, "Hit"], [27, "Super Saiyan 3 Gotenks"], [29, "Mercenary Tao"], [30, "Tien"], [31, "Super Saiyan 4 Gogeta \u00b7 version 3"], [32, "Omega Shenron"], [33, "Broly (Wrathful)"], [34, "Super Saiyan 4 Goku (Mini) (DAIMA)"], [35, "Dabura"], [36, "Gohan (Beast)"], [38, "Beerus"]];
  // the music each revival scene plays in the game (revival scene → bgm)
  const REVIVAL_BGM = { 1: 114, 2: 164, 3: 130, 4: 131, 5: 152, 7: 206, 8: 358, 9: 381, 10: 442, 11: 315, 12: 210, 13: 282, 15: 469, 16: 489, 17: 487, 18: 523 };
  const REVIVAL_VIEWS = [[0, "No animation"], [1, "Master Roshi"], [2, "Super Saiyan Gohan (Future)"], [3, "Goku (Ultra Instinct)"], [4, "Super Saiyan God SS Evolved Vegeta"], [5, "Vegeta/Goku"], [6, "Hercule"], [7, "Super Saiyan Goku"], [8, "Majin Buu (Good)"], [9, "Legendary Super Saiyan Broly"], [10, "Cell (Perfect Form)"], [11, "Piccolo & Gohan (Kid)/Gohan (Kid)"], [12, "Metal Cooler"], [13, "Omega Shenron"], [15, "Videl"], [16, "Super Saiyan Gohan (Future) / Super Saiyan Trunks (Youth) (Future)"], [17, "Super Garlic Jr."], [18, "Super Saiyan God Goku"]];
  const COUNTER_POWER = [[200, "Enormous power (×2)"], [300, "Tremendous power (×3)"], [400, "Ferocious power (×4)"]];
  const COUNTER_WHAT = [[0, "Any attack"], [1, "Normal attacks"], [2, "Super Attacks"], [3, "Ki-blast Super Attacks"], [4, "Unarmed Super Attacks"], [9, "Custom — only what you set in “Requirements & restrictions” below"]];
  const COUNTER_COND = { 0: null, 1: 2324, 2: 141, 3: ["&", 141, 1410], 4: ["&", 141, 1793] };
  function counterWhat(row) {
    if (!row.causality_conditions) return 0;
    let c;
    try { c = JSON.parse(row.causality_conditions).compiled; } catch (e) { return 9; }
    const k = JSON.stringify(c);
    for (const [n, v] of Object.entries(COUNTER_COND)) if (v !== null && JSON.stringify(v) === k) return Number(n);
    return 9;
  }
  function counterCond(what, row) {
    if (Number(what) === 9) return {};
    const c = COUNTER_COND[Number(what)];
    if (c === null || c === undefined) return { causality_conditions: null };
    const src = Array.isArray(c) ? c.slice(1).join("&") : String(c);
    return { causality_conditions: JSON.stringify({ source: src, compiled: c }) };
  }
  const POWER_WORD = (p) => p >= 400 ? "ferocious" : p >= 300 ? "tremendous" : "enormous";

  // ---------------------------------------------------------------- passive abilities
  const PASSIVE_GROUPS = ["Stats", "Ki & Ki Spheres", "Defense", "Offense", "Counters & revivals", "Enemy effects", "Team support", "Growth"];
  const PASSIVE = [
    { key: "atkdef", group: "Stats", label: "Raise ATK & DEF", eff: 3, calc: 2, targets: "buff", fields: [pctField("atk", "ATK +%", 100), pctField("def", "DEF +%", 100)], read: (r) => ({ atk: r.eff_value1, def: r.eff_value2 }), write: (v) => ({ eff_value1: v.atk, eff_value2: v.def, eff_value3: 0 }), text: (v) => statPair(v.atk, v.def) },
    { key: "atk", group: "Stats", label: "Raise ATK", eff: 1, calc: 2, targets: "buff", fields: [pctField("amount", "ATK +%", 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => "ATK +" + v.amount + "%" },
    { key: "def", group: "Stats", label: "Raise DEF", eff: 2, calc: 2, targets: "buff", fields: [pctField("amount", "DEF +%", 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => "DEF +" + v.amount + "%" },
    { key: "ki", group: "Ki & Ki Spheres", label: "Raise Ki", eff: 5, calc: 0, targets: "buff", fields: [num("amount", "Ki +", 3, 1, 24)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), match: (r) => !r.eff_value2, text: (v) => "Ki +" + v.amount },
    { key: "kiPerSphere", group: "Ki & Ki Spheres", label: "Ki per Ki Sphere obtained", eff: 96, calc: 0, targets: "self", timing: 1, fields: [{ name: "sphere", label: "Which Ki Spheres count", kind: "choice", def: 63, options: sphereMaskOptions }, num("amount", "Ki + per sphere", 1, 1, 12)], read: (r) => ({ sphere: r.eff_value1, amount: r.eff_value2 }), write: (v) => ({ eff_value1: v.sphere, eff_value2: v.amount, eff_value3: 0 }), match: (r) => sphereMaskOptions.some(([m]) => m === r.eff_value1), text: (v) => "Ki +" + v.amount + " per " + (v.sphere === 63 ? "" : (sphereMaskOptions.find(([m]) => m === v.sphere) || [0, ""])[1] + " ") + "Ki Sphere obtained" },
    { key: "atkPerSphere", group: "Ki & Ki Spheres", label: "ATK per Ki Sphere obtained", eff: 59, calc: 2, targets: "self", timing: 1, fields: [pctField("amount", "ATK +% per sphere", 10, 1, 200)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => "ATK +" + v.amount + "% per Ki Sphere obtained" },
    { key: "defPerSphere", group: "Ki & Ki Spheres", label: "DEF per Ki Sphere obtained", eff: 60, calc: 2, targets: "self", timing: 1, fields: [pctField("amount", "DEF +% per sphere", 10, 1, 200)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => "DEF +" + v.amount + "% per Ki Sphere obtained" },
    { key: "atkdefPerSphere", group: "Ki & Ki Spheres", label: "ATK & DEF per Ki Sphere obtained", eff: 61, calc: 2, targets: "self", timing: 1, fields: [pctField("atk", "ATK +% per sphere", 10, 1, 200), pctField("def", "DEF +% per sphere", 10, 1, 200)], read: (r) => ({ atk: r.eff_value1, def: r.eff_value2 }), write: (v) => ({ eff_value1: v.atk, eff_value2: v.def, eff_value3: 0 }), text: (v) => (v.atk === v.def ? "ATK & DEF +" + v.atk + "%" : "ATK +" + v.atk + "% and DEF +" + v.def + "%") + " per Ki Sphere obtained" },
    { key: "sphereChange", group: "Ki & Ki Spheres", label: "Change Ki Sphere colors", eff: 51, calc: 0, targets: "self", fields: [{ name: "from", label: "Change", kind: "choice", def: 0, options: SPHERES.map((s, i) => [i, s + " Ki Spheres"]) }, { name: "to", label: "Into", kind: "choice", def: 5, options: SPHERES.map((s, i) => [i, s + " Ki Spheres"]) }], read: (r) => ({ from: r.eff_value1, to: r.eff_value2 }), write: (v) => {
      if (v.from === v.to) throw new Error("Choose a different Ki Sphere color to change into.");
      return { eff_value1: v.from, eff_value2: v.to, eff_value3: 0 };
    }, match: (r) => [r.eff_value1, r.eff_value2].every((x) => Number.isInteger(x) && x >= 0 && x <= 5), text: (v) => "Changes " + SPHERES[v.from] + " Ki Spheres to " + SPHERES[v.to] + " Ki Spheres" },
    { key: "dr", group: "Defense", label: "Reduce damage received", eff: 13, calc: 2, targets: "buff", fields: [pctField("amount", "Damage reduced by %", 40, 1, 100)], read: (r) => ({ amount: 100 - r.eff_value1 }), write: (v) => ({ eff_value1: 100 - v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => "reduces damage received by " + v.amount + "%" },
    { key: "guard", group: "Defense", label: "Guard all attacks", eff: 78, calc: 0, targets: "selfOrAllies", fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }), text: () => "guards all attacks" },
    { key: "dodge", group: "Defense", label: "Chance to evade attacks", eff: 91, calc: 2, targets: "buff", fields: [pctField("amount", "Evade chance %", 30, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => v.amount >= 100 ? "evades enemy's attack (including Super Attack)" : v.amount + "% chance of evading enemy's attack (including Super Attack)" },
    { key: "heal", group: "Defense", label: "Recover HP", eff: 4, calc: 2, targets: "selfOrAllies", fields: [pctField("amount", "HP recovered %", 10, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => "recovers " + v.amount + "% HP" },
    { key: "immune", group: "Defense", label: "Immune to negative effects", eff: 50, calc: 0, targets: "selfOrAllies", fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }), text: () => "immune to negative effects" },
    { key: "foresee", group: "Defense", label: "Foresee the enemy's Super Attack", eff: 101, targets: "selfOrAllies", fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }), text: () => "foresees enemy's Super Attack" },
    { key: "crit", group: "Offense", label: "Critical hit chance", eff: 90, calc: 2, targets: "buff", fields: [pctField("amount", "Critical hit chance %", 50, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), match: (r) => !r.eff_value2, text: (v) => v.amount >= 100 ? "performs a critical hit" : v.amount + "% chance of performing a critical hit" },
    { key: "effective", group: "Offense", label: "Effective against all Types", eff: 76, calc: 0, targets: "selfOrAllies", fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }), text: () => "attacks are effective against all Types" },
    { key: "additional", group: "Offense", label: "Additional attack", eff: 81, calc: 0, targets: "self", fields: [pctField("super", "Chance it becomes a Super Attack %", 50, 0, 100)], read: (r) => ({ super: r.eff_value3 }), write: (v) => ({ eff_value1: 0, eff_value2: 0, eff_value3: v.super }), match: (r) => !r.eff_value1 && !r.eff_value2, text: (v) => v.super >= 100 ? "launches an additional Super Attack" : v.super <= 0 ? "launches an additional attack" : "launches an additional attack that has a " + v.super + "% chance of becoming a Super Attack" },
    { key: "counter", group: "Counters & revivals", label: "Counterattack", eff: 120, targets: "self", timing: 6, fields: [{ name: "what", label: "What it counters", kind: "choice", def: 1, options: COUNTER_WHAT }, { name: "power", label: "Counter damage", kind: "choice", def: 300, options: COUNTER_POWER }, pctField("dr", "Damage received reduced by % (0 = none)", 0, 0, 100), { name: "anim", label: "Counter animation", kind: "choice", def: 2, options: COUNTER_ANIMS, keepUnknown: true }], read: (r) => ({ what: counterWhat(r), power: r.eff_value2, dr: r.eff_value1, anim: r.eff_value3 }), write: (v, row) => Object.assign({ eff_value1: v.dr, eff_value2: v.power, eff_value3: v.anim }, counterCond(v.what, row)), match: (r) => Number(r.eff_value2) >= 100, text: (v) => (v.dr ? "reduces damage received by " + v.dr + "% and " : "") + "counters " + (["any attack", "normal attacks", "Super Attacks", "Ki-blast Super Attacks", "unarmed Super Attacks"][v.what] || "attacks") + " with " + POWER_WORD(v.power) + " power" },
    { key: "dodgeCounter", group: "Counters & revivals", label: "Evade and counter", eff: 128, targets: "self", timing: 6, fields: [{ name: "what", label: "What it evades and counters", kind: "choice", def: 1, options: COUNTER_WHAT }, { name: "power", label: "Counter damage", kind: "choice", def: 200, options: COUNTER_POWER }, { name: "anim", label: "Counter animation", kind: "choice", def: 25, options: COUNTER_ANIMS, keepUnknown: true }], read: (r) => ({ what: counterWhat(r), power: r.eff_value2, anim: r.eff_value3 }), write: (v, row) => Object.assign({ eff_value1: 0, eff_value2: v.power, eff_value3: v.anim }, counterCond(v.what, row)), match: (r) => Number(r.eff_value2) >= 100, text: (v) => "evades " + (["any attack", "normal attacks", "Super Attacks", "Ki-blast Super Attacks", "unarmed Super Attacks"][v.what] || "attacks") + " and counters with " + POWER_WORD(v.power) + " power" },
    { key: "revive", group: "Counters & revivals", label: "Revive when KO'd", eff: 109, calc: 2, targets: "selfOrAllies", timing: 1, ownText: true, fields: [pctField("hp", "HP recovered %", 70, 1, 100), { name: "view", label: "Revival animation", kind: "choice", def: 2, options: REVIVAL_VIEWS, keepUnknown: true }, { name: "music", label: "Revival music", kind: "choice", def: -1, options: [[-1, "The scene's own music"], [0, "Keep the battle music"]].concat(REVIVAL_VIEWS.filter(([v]) => REVIVAL_BGM[v]).map(([v, n]) => [REVIVAL_BGM[v], "Music from " + n])), keepUnknown: true }], read: (r) => ({ hp: r.eff_value1, view: r.eff_value2, music: Number(r.eff_value3) && Number(r.eff_value3) === REVIVAL_BGM[r.eff_value2] ? -1 : Number(r.eff_value3) || 0 }), write: (v) => ({ eff_value1: v.hp, eff_value2: v.view, eff_value3: Number(v.music) === -1 ? (REVIVAL_BGM[v.view] || 0) : Number(v.music) || 0 }), text: (v, s) => (s && s.target === 2 ? "revives an ally" : "revives") + " with " + (v.hp >= 100 ? "HP fully recovered" : v.hp + "% HP recovered") + " when KO'd" },
    { key: "atkDown", group: "Enemy effects", label: "Lower enemy ATK", eff: 1, calc: 3, targets: "enemy", fields: [pctField("amount", "ATK −%", 20, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => "ATK −" + v.amount + "%" },
    { key: "defDown", group: "Enemy effects", label: "Lower enemy DEF", eff: 2, calc: 3, targets: "enemy", fields: [pctField("amount", "DEF −%", 20, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }), text: (v) => "DEF −" + v.amount + "%" },
    { key: "atkdefDown", group: "Enemy effects", label: "Lower enemy ATK & DEF", eff: 3, calc: 3, targets: "enemy", fields: [pctField("atk", "ATK −%", 20, 1, 100), pctField("def", "DEF −%", 20, 1, 100)], read: (r) => ({ atk: r.eff_value1, def: r.eff_value2 }), write: (v) => ({ eff_value1: v.atk, eff_value2: v.def, eff_value3: 0 }), text: (v) => statPairDown(v.atk, v.def) },
    { key: "stun", group: "Enemy effects", label: "Stun", eff: 9, calc: 0, targets: "enemy", timings: [5, 4, 11, 6, 7], chance: 50, fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }), text: (v, s) => "stuns " + (s.target === 4 ? "all enemies" : "the attacked enemy") },
    { key: "seal", group: "Enemy effects", label: "Seal Super Attack", eff: 48, calc: 0, targets: "enemy", timings: [5, 4, 11, 6, 7], chance: 50, fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }), text: (v, s) => "seals " + (s.target === 4 ? "all enemies'" : "the attacked enemy's") + " Super Attack" },
    { key: "disable", group: "Enemy effects", label: "Disable the enemy's action", eff: 111, calc: 0, targets: "enemy", timings: [5, 4, 11, 6, 7], fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }), text: (v, s) => "disables " + (s.target === 4 ? "every enemy's" : "the attacked enemy's") + " action" },
    { key: "typeKi", group: "Team support", label: "Ki for allies of a Type", eff: 20, calc: 0, targets: "allies", fields: [{ name: "type", label: "Ally Type", kind: "choice", def: 0, options: TYPES.map((t, i) => [i, t]) }, num("amount", "Ki +", 2, 1, 24)], read: (r) => ({ type: r.eff_value1, amount: r.eff_value2 }), write: (v) => ({ eff_value1: v.type, eff_value2: v.amount, eff_value3: 0 }), match: (r) => r.eff_value1 >= 0 && r.eff_value1 <= 4, text: (v) => TYPES[v.type] + " Type allies' Ki +" + v.amount, ownText: true },
    { key: "typeStats", group: "Team support", label: "ATK & DEF for allies of a Type", eff: 18, calc: 2, targets: "allies", fields: [{ name: "type", label: "Ally Type", kind: "choice", def: 0, options: TYPES.map((t, i) => [i, t]) }, pctField("atk", "ATK +%", 20, 1, 1000), pctField("def", "DEF +%", 20, 1, 1000)], read: (r) => ({ type: r.eff_value1, atk: r.eff_value2, def: r.eff_value3 }), write: (v) => ({ eff_value1: v.type, eff_value2: v.atk, eff_value3: v.def }), match: (r) => r.eff_value1 >= 0 && r.eff_value1 <= 4, text: (v) => TYPES[v.type] + " Type allies' " + statPair(v.atk, v.def), ownText: true },
    { key: "stack", group: "Growth", label: "Grows with each attack (stacking)", eff: 98, targets: "self", stack: true, fields: [{ name: "stat", label: "What grows", kind: "choice", def: 0, options: stackStats.map(([v, n]) => [v, cap(n)]) }, num("step", "Increase each time", 10, 1, 500), num("max", "Maximum total", 50, 1, 2000), { name: "trigger", label: "Grows", kind: "choice", def: 5, options: stackTriggers }], read: (r) => ({ stat: r.eff_value3, step: r.eff_value1, max: r.eff_value2, trigger: r.exec_timing_type }), write: (v) => ({ eff_value1: v.step, eff_value2: Math.max(v.max, v.step), eff_value3: v.stat, calc_option: v.stat === 5 ? 0 : 2, exec_timing_type: v.trigger, turn: 99 }), match: (r) => r.eff_value3 >= 0 && r.eff_value3 <= 5 && stackTriggers.some(([t]) => t === r.exec_timing_type), text: (v, s) => {
      const [, name, unit] = stackStats.find(([s]) => s === v.stat) || stackStats[0];
      // a limit of 1000 or more is "no limit" in the game's own wording; turn 1 resets every turn
      const limit = v.max >= 1000 ? "" : " (up to " + (unit ? v.max + unit : "+" + v.max) + ")";
      return cap(name) + " +" + v.step + unit + " " + (stackTriggers.find(([t]) => t === v.trigger) || stackTriggers[0])[1] + limit + (s && s.turn > 0 && s.turn < 99 ? (s.turn === 1 ? " within the turn" : " for " + s.turn + " turns") : "");
    } }
  ];
  const TIMINGS = [[1, "At the start of each turn", ""], [11, "Right before attacking", "before attacking"], [4, "When attacking", "when attacking"], [5, "When an attack hits", "when the character's attack hits"], [6, "When receiving an attack", "when receiving an attack"], [7, "After receiving an attack", "after receiving an attack"], [14, "After defeating an enemy", "after defeating an enemy"], [15, "After collecting Ki Spheres", "after collecting Ki Spheres"], [9, "At the end of the turn", "at the end of the turn"]];
  const DURATIONS = [[1, "This turn"], [2, "2 turns"], [3, "3 turns"], [4, "4 turns"], [5, "5 turns"], [99, "Rest of the battle"]];
  const passiveDef = (key) => PASSIVE.find((e) => e.key === key);
  function decodePassive(row) {
    if (!row) return null;
    const eff = Number(row.efficacy_type);
    for (const def of PASSIVE) {
      if (def.eff !== eff) continue;
      if (def.calc !== undefined && def.calc !== Number(row.calc_option) && !(def.stack)) continue;
      if (def.match && !def.match(row)) continue;
      try {
        const v = JSON.parse(row.efficacy_values || "{}");
        if (Array.isArray(v) || (v && Object.keys(v).length)) return null;
      } catch { return null; }
      return { key: def.key, values: def.read(row) };
    }
    return null;
  }
  function normalizeValues(fields, values) {
    const out = {};
    for (const f of fields) {
      const raw = values && values[f.name] !== undefined ? values[f.name] : f.def;
      // keepUnknown: a value not in the list (e.g. your own counter animation) is kept as it is
      if (f.kind === "choice") out[f.name] = f.options.some(([v]) => String(v) === String(raw)) || (f.keepUnknown && Number.isFinite(Number(raw)) && raw !== "" && raw != null) ? Number(raw) : Number(f.def);
      else out[f.name] = int(raw, f.min, f.max, f.def);
    }
    return out;
  }
  function settingsOf(row) {
    return { timing: Number(row.exec_timing_type), target: Number(row.target_type), turn: Number(row.turn), chance: Number(row.probability), once: Number(row.is_once) === 1, sub: Number(row.sub_target_type_set_id) || 0 };
  }
  function allowedTargets(def) { return TARGET_SETS[def.targets] || TARGET_SETS.buff; }
  function passiveFields(key, values, settings = {}) {
    const def = passiveDef(key);
    if (!def) throw new Error("Choose an ability from the list.");
    const v = normalizeValues(def.fields, values), targets = allowedTargets(def);
    const target = targets.includes(Number(settings.target)) ? Number(settings.target) : targets[0];
    const timing = def.timing || (TIMINGS.some(([t]) => t === Number(settings.timing)) ? Number(settings.timing) : 1);
    const turn = DURATIONS.some(([t]) => t === Number(settings.turn)) ? Number(settings.turn) : 1;
    // growth that resets every turn ("within the turn") keeps its turn; other growth lasts the battle
    const fields = Object.assign({ efficacy_type: def.eff, calc_option: def.calc !== undefined ? def.calc : 0, target_type: target, exec_timing_type: timing, sub_target_type_set_id: Number(settings.sub) || 0, turn: def.stack ? (Number(settings.turn) > 0 && Number(settings.turn) < 99 ? Number(settings.turn) : 99) : turn, probability: int(settings.chance !== undefined ? settings.chance : def.chance || 100, 1, 100, 100), is_once: settings.once ? 1 : 0, efficacy_values: "{}" }, def.write(v));
    return fields;
  }
  function newPassiveSettings(key) {
    const def = passiveDef(key);
    return { timing: def.timing || (def.targets === "enemy" ? 5 : 1), target: allowedTargets(def)[0], turn: def.stack ? 99 : 1, chance: def.chance || 100, once: false };
  }
  function addPassiveAbility(p, key, values, settings) {
    const fields = passiveFields(key, values, settings || newPassiveSettings(key));
    const row = Forge.addPassive(p, fields);
    const set = Forge.primaryPassive(p);
    if (set && set.name) row.name = set.name;
    return row;
  }
  function updatePassiveAbility(row, key, values, settings) {
    Object.assign(row, passiveFields(key, values, settings));
    return row;
  }
  function durationText(turn, timing) {
    if (turn === 99) return " for the rest of the battle";
    if (turn > 1) return " for " + turn + " turns";
    return "";
  }
  function passiveLine(row, extra = {}) {
    if (extra && (extra.subOwner || extra.subFor) && Number(row.sub_target_type_set_id)) return subTargetLine(passiveLine, row, extra);
    const decoded = decodePassive(row), s = settingsOf(row);
    let line;
    const special = (!decoded || Number(row.efficacy_type) === 98) && window.ForgePassiveCatalog ? window.ForgePassiveCatalog.describe(row) : "";
    if (special) {
      line = special;
      if (Number(row.efficacy_type) !== 98) line += durationText(s.turn, s.timing);
      if (s.chance < 100) line = s.chance + "% chance: " + line;
    } else if (decoded) {
      const def = passiveDef(decoded.key), v = normalizeValues(def.fields, decoded.values);
      line = def.text(v, s);
      const t = TARGETS[s.target];
      if (!def.ownText && t && t.owner && !["stun", "seal", "disable"].includes(def.key)) {
        if (VERB_EFFECTS.includes(def.key)) line = SUBJECTS[s.target] ? SUBJECTS[s.target] + ": " + line : line;
        else line = t.owner + line + (t.suffix || "");
      }
      if (!def.stack) line += durationText(s.turn, s.timing);
      if (s.chance < 100 && !["dodge", "crit"].includes(def.key)) line = s.chance + "% chance: " + line;
    } else if (Number(row.efficacy_type) === 103) line = "transforms" + (extra.formName ? " into " + extra.formName : "");
    else if (Number(row.efficacy_type) === 120) line = "counters enemy's attacks";
    else if (Number(row.efficacy_type) === 79) line = "giant form transformation";
    else if (row.efficacy_values && row.efficacy_values !== "{}" && decodePassive(Object.assign({}, row, { efficacy_values: "{}" }))) return passiveLine(Object.assign({}, row, { efficacy_values: "{}" }), extra);
    else line = G && G.effectSummary ? G.effectSummary(row) : "Special effect";
    if (s.once) line += " (once only)";
    return cap(line);
  }

  // ---------------------------------------------------------------- official in-game wording
  // Dokkan Battle writes passives with icons: {passiveImg:up_g} (green ↑ boost),
  // {passiveImg:down_r} (red ↓ own stat lowered), {passiveImg:down_y} (yellow ↓ enemy lowered),
  // {passiveImg:once} (once only) and {passiveImg:forever} (lasts for the rest of the battle),
  // and words for chances (rare / medium / high / great). The wording below follows thousands of
  // official descriptions in the game data, e.g. "Ki +3 and ATK & DEF 150%{passiveImg:up_g}".
  const ICON = { up: "{passiveImg:up_g}", downSelf: "{passiveImg:down_r}", downEnemy: "{passiveImg:down_y}", once: "{passiveImg:once}", forever: "{passiveImg:forever}" };
  const chanceWord = (p) => (p <= 20 ? "rare" : p <= 40 ? "medium" : p <= 60 ? "high" : "great");
  const OWNERS = { 1: "", 2: "All allies' ", 16: "Allies' ", 12: "Super Class allies' ", 13: "Extreme Class allies' ", 3: "Attacked enemy's ", 4: "All enemies' " };
  const lowerFirst = (t) => (t && /^[A-Z][a-z]/.test(t) && !/^(Ki|HP)\b/.test(t) ? t.charAt(0).toLowerCase() + t.slice(1) : t);
  // "ATK 15%↑ per Ki Sphere obtained" + "DEF 15%↑ per Ki Sphere obtained" → "ATK & DEF 15%↑ per …"
  function pairAtkDef(lines) {
    const out = lines.slice();
    for (let i = 0; i < out.length; i++) {
      const a = out[i] && out[i].match(/^(.*?)ATK (\d+%?\{passiveImg:[a-z_]+\})(.*)$/);
      if (!a || /DEF/.test(a[3])) continue;
      const j = out.findIndex((l, k) => k !== i && l === a[1] + "DEF " + a[2] + a[3]);
      if (j < 0) continue;
      out[i] = a[1] + "ATK & DEF " + a[2] + a[3];
      out.splice(j, 1);
      if (j < i) i--;
    }
    return out;
  }
  const officialStat = (atk, def, icon) => atk && def && atk === def ? "ATK & DEF " + atk + "%" + icon : [atk ? "ATK " + atk + "%" + icon : "", def ? "DEF " + def + "%" + icon : ""].filter(Boolean).join(" and ");
  const SPHERE_WORD = { 63: "", 31: "Type ", 32: "Rainbow ", 1: "AGL ", 2: "TEQ ", 4: "INT ", 8: "STR ", 16: "PHY " };
  const STACK_HEADING = { 5: "For every attack performed", 7: "For every attack received", 1: "For every turn passed" };
  // { text, gerund? (verb effects, for "High chance of …"), own? (already names who it affects) }
  function officialCore(key, v, s) {
    const enemyAll = s.target === 4, up = ICON.up;
    switch (key) {
      case "atkdef": return { text: officialStat(v.atk, v.def, up) };
      case "atk": return { text: "ATK " + v.amount + "%" + up };
      case "def": return { text: "DEF " + v.amount + "%" + up };
      case "ki": return { text: "Ki +" + v.amount };
      case "kiPerSphere": return { text: "Receives an additional Ki +" + v.amount + " per " + (SPHERE_WORD[v.sphere] || "") + "Ki Sphere obtained", own: true };
      case "atkPerSphere": return { text: "ATK " + v.amount + "%" + up + " per Ki Sphere obtained" };
      case "defPerSphere": return { text: "DEF " + v.amount + "%" + up + " per Ki Sphere obtained" };
      case "atkdefPerSphere": return { text: officialStat(v.atk, v.def, up) + " per Ki Sphere obtained" };
      case "sphereChange": return { text: "Changes Ki Spheres: " + SPHERES[v.from] + " to " + SPHERES[v.to], own: true };
      case "dr": return { text: "Damage reduction rate " + v.amount + "%" + up };
      case "guard": return { text: "Guards all attacks", gerund: "guarding all attacks" };
      case "dodge": return v.amount >= 100 ? { text: "Evades enemy's attack", gerund: "evading enemy's attack" } : { text: "Chance of evading enemy's attack " + v.amount + "%" + up };
      case "heal": return { text: "Recovers " + v.amount + "% HP", gerund: "recovering " + v.amount + "% HP" };
      case "immune": return { text: "Immune to negative effects", gerund: "becoming immune to negative effects" };
      case "foresee": return { text: "Foresees enemy's Super Attack", gerund: "foreseeing enemy's Super Attack" };
      case "crit": return v.amount >= 100 ? { text: "Performs a critical hit", gerund: "performing a critical hit" } : { text: "Chance of performing a critical hit " + v.amount + "%" + up };
      case "effective": return { text: "Attacks are effective against all Types", gerund: "attacks becoming effective against all Types" };
      case "additional": {
        const what = v.super >= 100 ? "an additional Super Attack" : v.super <= 0 ? "an additional attack" : "an additional attack that has a " + chanceWord(v.super) + " chance of becoming a Super Attack";
        return { text: "Launches " + what, gerund: "launching " + what };
      }
      case "atkDown": return { text: "ATK " + v.amount + "%" + ICON.downEnemy };
      case "defDown": return { text: "DEF " + v.amount + "%" + ICON.downEnemy };
      case "atkdefDown": return { text: officialStat(v.atk, v.def, ICON.downEnemy) };
      case "stun": return { text: "Stuns " + (enemyAll ? "all enemies" : "the attacked enemy"), gerund: "stunning " + (enemyAll ? "all enemies" : "the attacked enemy"), own: true };
      case "seal": return { text: "Seals " + (enemyAll ? "all enemies' Super Attacks" : "the attacked enemy's Super Attack"), gerund: "sealing " + (enemyAll ? "all enemies' Super Attacks" : "the attacked enemy's Super Attack"), own: true };
      case "disable": return { text: "Disables " + (enemyAll ? "all enemies' actions" : "the attacked enemy's action"), gerund: "disabling " + (enemyAll ? "all enemies' actions" : "the attacked enemy's action"), own: true };
      case "typeKi": return { text: TYPES[v.type] + " Type allies' Ki +" + v.amount, own: true };
      case "typeStats": return { text: TYPES[v.type] + " Type allies' " + officialStat(v.atk, v.def, up), own: true };
      case "counter": return { text: (v.dr ? "Damage reduction rate " + v.dr + "%" + up + " temporarily and counters" : "Counters") + " with " + POWER_WORD(v.power) + " power", gerund: (v.dr ? "reducing damage received by " + v.dr + "% and countering" : "countering") + " with " + POWER_WORD(v.power) + " power" };
      case "dodgeCounter": return { text: "Evades enemy's attack and counters with " + POWER_WORD(v.power) + " power", gerund: "evading enemy's attack and countering with " + POWER_WORD(v.power) + " power" };
      case "revive": return { text: ICON.once + (s.target === 2 ? "Revives an ally" : "Revives") + " with " + (v.hp >= 100 ? "HP fully recovered" : v.hp + "% HP recovered"), own: true };
      case "stack": {
        const name = { 0: "ATK ", 1: "DEF ", 2: "Chance of performing a critical hit ", 3: "Chance of evading enemy's attack ", 4: "Damage reduction rate ", 5: "Ki +" }[v.stat] || "ATK ", unit = v.stat === 5 ? "" : "%";
        const limit = v.max >= 1000 ? "" : " (up to " + (unit ? v.max + unit : "+" + v.max) + ")";
        return { text: name + v.step + unit + (unit ? up : "") + (s.turn > 0 && s.turn < 99 ? (s.turn === 1 ? " within the turn" : " for " + s.turn + " turns") : "") + limit, stack: true };
      }
    }
    return null;
  }
  // who it affects + what + how long; chance and once/forever icons are added around it
  function officialBody(core, s) {
    if (core.own) return core.text;
    const owner = OWNERS[s.target] || "";
    if (!owner) return core.text;
    if (core.gerund) return cap(SUBJECTS[s.target] || "") + ": " + lowerFirst(core.text);
    return owner + lowerFirst(core.text) + (s.target === 16 ? " (self excluded)" : "");
  }
  function officialWrap(body, core, row, s) {
    let line = body;
    if (!core.stack) {
      if (s.turn > 1 && s.turn < 99) line += " for " + s.turn + " turns";
      else if (s.turn === 1 && [7, 14, 15].includes(s.timing)) line += " within the turn";
      else if (s.turn === 1 && s.once && s.timing === 1) line += " for 1 turn";   // once-only (e.g. with an intro): "for 1 turn"
    }
    if (s.chance < 100) line = cap(chanceWord(s.chance)) + " chance of " + (core.gerund && (core.own || !OWNERS[s.target]) ? core.gerund : lowerFirst(line));
    // lasts for the rest of the battle once it happens (plain always-on boosts need no icon)
    const lasting = core.stack ? s.turn >= 99 : s.turn >= 99 && (!!row.causality_conditions || s.once || s.timing !== 1);
    return (s.once ? ICON.once : "") + (lasting ? ICON.forever : "") + line;
  }
  function subTargetLine(fn, row, extra) {
    // named characters: "ATK & DEF 30%↑ for the character and allies whose names include “Goku”"
    if (extra.subFor) return fn(Object.assign({}, row, { sub_target_type_set_id: 0, target_type: 1 }), Object.assign({}, extra, { subOwner: null, subFor: null })) + " for " + extra.subFor;
    const r2 = Object.assign({}, row, { sub_target_type_set_id: 0 }), line = fn(r2, Object.assign({}, extra, { subOwner: null })), who = extra.subOwner;
    if (/^All allies' /.test(line)) return line.replace(/^All allies' /, who + " ");
    if (/^All allies: /i.test(line)) return line.replace(/^All allies: /i, who.replace(/'$/, "") + ": ");
    if (/^Allies' /.test(line)) return line.replace(/^Allies' /, who + " ");
    return who.replace(/'$/, "") + ": " + lowerFirst(line);
  }
  function officialLine(row, extra = {}) {
    if (extra && (extra.subOwner || extra.subFor) && Number(row.sub_target_type_set_id)) return subTargetLine(officialLine, row, extra);
    let d = decodePassive(row);
    const s = settingsOf(row);
    if (!d && row.efficacy_values && row.efficacy_values !== "{}" && decodePassive(Object.assign({}, row, { efficacy_values: "{}" }))) return officialLine(Object.assign({}, row, { efficacy_values: "{}" }), extra);
    if (!d) {
      if (Number(row.efficacy_type) === 103) return (s.once ? ICON.once : "") + "Transforms" + (extra.formName ? " into " + extra.formName : "");
      return passiveLine(row, extra);
    }
    const def = passiveDef(d.key), v = normalizeValues(def.fields, d.values), core = officialCore(d.key, v, s);
    if (!core) return passiveLine(row, extra);
    return cap(officialWrap(officialBody(core, s), core, row, s));
  }
  function officialHeading(row, condText) {
    const d = decodePassive(row);
    // counters: the condition is what they counter, so it names the heading
    if (d && (d.key === "counter" || d.key === "dodgeCounter")) {
      const w = Number(d.values.what);
      if (w !== 9) return ["When receiving an attack", "When receiving a normal attack", "When receiving a Super Attack", "When receiving a Ki-blast Super Attack", "When receiving an unarmed Super Attack"][w] || "When receiving an attack";
    }
    if (d && d.key === "revive") return condText ? cap(condText) : "When the character is KO'd";
    if (d && passiveDef(d.key).stack) {
      const v = normalizeValues(passiveDef(d.key).fields, d.values), each = STACK_HEADING[v.trigger] || STACK_HEADING[5];
      return condText ? cap(condText) + ", " + lowerFirst(each) : each;
    }
    return passiveHeading(row, condText);
  }
  // "Ki +3" + "ATK & DEF 150%↑" with the same owner and settings → "Ki +3 and ATK & DEF 150%↑"
  function officialJoinKi(kiRow, statRowValue) {
    const kd = decodePassive(kiRow), sd = decodePassive(statRowValue), s = settingsOf(kiRow);
    const kv = normalizeValues(passiveDef(kd.key).fields, kd.values), sv = normalizeValues(passiveDef(sd.key).fields, sd.values);
    const parts = officialCore(sd.key, sv, s).text.split(" and ");
    const text = "Ki +" + kv.amount + (parts.length > 1 ? ", " + parts.slice(0, -1).join(", ") + " and " + parts[parts.length - 1] : " and " + parts[0]);
    const core = { text };
    return cap(officialWrap(officialBody(core, s), core, kiRow, s));
  }
  // timings the game uses that the editor doesn't offer as a separate choice
  const HEADING_TIMINGS = TIMINGS.concat([[3, "", "when attacking"], [8, "", "when performing a Super Attack"]]);
  function passiveHeading(row, condText) {
    const timing = Number(row.exec_timing_type), decoded = decodePassive(row), stack = decoded && passiveDef(decoded.key).stack;
    let phrase = stack ? "" : (HEADING_TIMINGS.find(([t]) => t === timing) || [0, "", ""])[2];
    // conditions often already say the moment ("when attacking as the 3rd attacker")
    const c = String(condText || "");
    if (phrase && c && c.toLowerCase().includes(phrase.toLowerCase())) phrase = "";
    // the game names the moment once: "As the 3rd attacker in a turn", "5 or more Ki Spheres obtained",
    // "After evading an attack", "When HP is 50% or less when attacking"
    let cc = c;
    if (/performing or receiving a Super Attack/i.test(cc) && [6, 7].includes(timing)) cc = cc.replace(/performing or receiving a Super Attack/i, "receiving a Super Attack");
    if (/performing or receiving a Super Attack/i.test(cc) && [3, 4, 5, 11].includes(timing)) cc = cc.replace(/performing or receiving a Super Attack/i, "performing a Super Attack");
    if (cc !== c) return headingFrom("", cc);
    if (phrase && /attacking|attacker|attack hits|performing a Super/i.test(c) && [3, 4, 5, 11].includes(timing)) phrase = "";
    if (phrase && /receiving/i.test(c) && [6, 7].includes(timing)) phrase = "";
    if (phrase && /Ki Spheres? obtained/i.test(c) && timing === 15) phrase = "";
    if (phrase && /^(after|for every)/i.test(c)) phrase = "";
    if (phrase && /^with \d+ or more .*Ki Spheres? obtained/i.test(c)) phrase = "";
    return headingFrom(phrase, c);
  }
  function headingFrom(phrase, c) {
    // game style: "an" before a vowel sound ("an "Earth-Bred Fighters" Category ally")
    c = String(c || "").replace(/\ba "(?=[AEIOU])/g, 'an "');
    if (phrase && /^when /i.test(c)) return cap(c + " " + phrase);
    const parts = [phrase, c].filter(Boolean);
    return parts.length ? cap(parts.join(" ")) : "Basic effect(s)";
  }
  // Builds an itemized passive description in the official "*Heading*\n- effect" layout
  // (Dokkan Battle's "Basic effect(s)" / "When attacking" / … style).
  //
  // Combining follows the game's calculation rules, never just the wording:
  // - Only abilities under the same heading (same moment AND same condition) are combined.
  // - The same percentage boost at the same moment adds up in battle, so two "ATK +100%" and
  //   "ATK +50%" lines become "ATK +150%"; ATK and DEF boosts with the same settings become
  //   "ATK & DEF +150%" (or "ATK +X% and DEF +Y%" when they differ).
  // - Anything that differs in moment, condition, target, duration, chance, once-only, calculation
  //   (percentage, flat or lowering) or growth stays on its own line.
  // - "Ki +3" is written in front of the ATK & DEF boost it shares every setting with
  //   ("Ki +3 and ATK & DEF +150%"), as the game does; the amounts themselves are untouched.
  const NO_SUM = new Set(["additional"]);
  const settingsSig = (row) => [row.exec_timing_type, row.target_type, row.turn, row.probability, Number(row.is_once) || 0, row.causality_conditions || "", row.sub_target_type_set_id || 0].join("|");
  // what the description SHOWS of an ability's settings: abilities that read the same for the same group of
  // characters share one bullet ("All allies' Ki +3 and ATK & DEF 30%↑"), even if hidden details differ
  function visibleSig(row) {
    const t = Number(row.exec_timing_type), turn = Number(row.turn), cond = row.causality_conditions || "", once = Number(row.is_once) || 0;
    const phrase = (HEADING_TIMINGS.find(([x]) => x === t) || [0, "", ""])[2];
    const dur = turn > 1 && turn < 99 ? "t" + turn : turn >= 99 && (cond || once || t !== 1) ? "forever" : turn === 1 && [7, 14, 15].includes(t) ? "within" : "";
    return [phrase, row.target_type, row.probability, once, cond, row.sub_target_type_set_id || 0, dur].join("|");
  }
  function sumKey(row) {
    const d = decodePassive(row);
    if (!d || NO_SUM.has(d.key)) return null;
    const def = passiveDef(d.key), v = normalizeValues(def.fields, d.values);
    if (!def.fields.some((f) => f.kind !== "choice")) return null;
    return [d.key, visibleSig(row), row.calc_option].concat(def.fields.filter((f) => f.kind === "choice").map((f) => v[f.name])).join("|");
  }
  function summed(rows) {
    if (rows.length === 1) return rows[0];
    const d = decodePassive(rows[0]), def = passiveDef(d.key), total = normalizeValues(def.fields, d.values);
    for (const row of rows.slice(1)) {
      const v = normalizeValues(def.fields, decodePassive(row).values);
      for (const f of def.fields) if (f.kind !== "choice") total[f.name] = Math.min(f.max, total[f.name] + v[f.name]);
    }
    return Object.assign({}, rows[0], passiveFields(d.key, total, settingsOf(rows[0])), { id: rows[0].id });
  }
  // ATK / DEF boosts (or lowerings) that share every setting are written as one line.
  const STAT_UP = { atk: ["atk"], def: ["def"], atkdef: ["atk", "def"] }, STAT_DOWN = { atkDown: ["atk"], defDown: ["def"], atkdefDown: ["atk", "def"] };
  function statShare(row) {
    const d = decodePassive(row);
    if (!d) return null;
    const up = STAT_UP[d.key], down = STAT_DOWN[d.key];
    if (!up && !down) return null;
    const v = normalizeValues(passiveDef(d.key).fields, d.values), amounts = {};
    if (d.key === "atkdef" || d.key === "atkdefDown") { amounts.atk = v.atk; amounts.def = v.def; }
    else amounts[(up || down)[0]] = v.amount;
    return { dir: up ? "up" : "down", sig: (up ? "up" : "down") + "|" + visibleSig(row) + "|" + row.calc_option, amounts };
  }
  function statRow(base, dir, atk, def) {
    const s = settingsOf(base);
    let key, values;
    if (atk && def) { key = dir === "up" ? "atkdef" : "atkdefDown"; values = { atk, def }; }
    else if (atk) { key = dir === "up" ? "atk" : "atkDown"; values = { amount: atk }; }
    else { key = dir === "up" ? "def" : "defDown"; values = { amount: def }; }
    return Object.assign({}, base, passiveFields(key, values, s), { id: base.id });
  }
  // Order inside a heading, like the game: Ki & stats, then defence, offence, the rest; the
  // character's own effects before the team's and the enemy's.
  const ORDER = ["ki", "atkdef", "atk", "def", "dr", "guard", "dodge", "crit", "effective", "additional", "heal", "immune", "foresee", "kiPerSphere", "atkPerSphere", "defPerSphere", "atkdefPerSphere", "sphereChange", "stack"];
  const TARGET_ORDER = { 1: 0, 2: 1, 16: 2, 12: 3, 13: 4, 3: 5, 4: 6 };
  function rank(row) {
    const d = decodePassive(row), i = d ? ORDER.indexOf(d.key) : -1;
    return (TARGET_ORDER[Number(row.target_type)] ?? 7) * 100 + (i < 0 ? 60 : i) + (Number(row.efficacy_type) === 103 ? 90 : 0);
  }
  function composeGroup(rows, extra, plain) {
    // 1. add up identical abilities
    const items = [];
    for (const row of rows) {
      const key = sumKey(row), same = key && items.find((x) => x.key === key);
      if (same) same.rows.push(row); else items.push({ key, rows: [row] });
    }
    let entries = items.map((item) => ({ row: summed(item.rows), first: item.rows[0] }));
    // 2. ATK and DEF with identical settings become one line
    const stats = new Map(), rest = [];
    for (const e of entries) {
      const share = statShare(e.row);
      if (!share) { rest.push(e); continue; }
      const bucket = stats.get(share.sig) || { base: e.row, first: e.first, dir: share.dir, atk: 0, def: 0, order: rest.length };
      bucket.atk += share.amounts.atk || 0; bucket.def += share.amounts.def || 0;
      stats.set(share.sig, bucket);
    }
    entries = rest.slice();
    for (const b of stats.values()) entries.push({ row: statRow(b.base, b.dir, Math.min(2000, b.atk), Math.min(2000, b.def)), first: b.first });
    entries.sort((a, b) => rank(a.row) - rank(b.row));
    // 3. lines; "Ki +N" joins the ATK & DEF boost it shares every setting with
    const lines = [], used = new Set();
    for (const e of entries) {
      if (used.has(e)) continue;
      const d = decodePassive(e.row);
      let line = (plain ? passiveLine : officialLine)(e.row, extra ? extra(e.first) : {});
      if (d && d.key === "ki") {
        const partner = entries.find((x) => !used.has(x) && x !== e && statShare(x.row)?.dir === "up" && visibleSig(x.row) === visibleSig(e.row));
        if (partner) {
          used.add(partner);
          line = plain ? joinKi(e.row, partner.row) : officialJoinKi(e.row, partner.row);
        }
      }
      // several additional attacks that read the same → "Launches 2 additional attacks, each of which has…"
      if (d && d.key === "additional") {
        const twins = entries.filter((x) => x !== e && !used.has(x) && decodePassive(x.row)?.key === "additional" && visibleSig(x.row) === visibleSig(e.row) && Number(x.row.eff_value3) === Number(e.row.eff_value3));
        if (twins.length) {
          const n = twins.length + 1;
          twins.forEach((x) => used.add(x));
          line = line.replace(/aunches an additional attack that has an? /, "aunches " + n + " additional attacks, each of which has a ").replace(/aunches an additional Super Attack/, "aunches " + n + " additional Super Attacks").replace(/aunches an additional attack/, "aunches " + n + " additional attacks");
        }
      }
      used.add(e);
      if (!lines.includes(line)) lines.push(line);
    }
    return plain ? lines : joinOwnerKi(pairAtkDef(lines));
  }
  function joinOwnerKi(lines) {
    const out = lines.slice();
    for (let i = 0; i < out.length; i++) {
      const m = out[i].match(/^(.+? allies' )Ki \+(\d+)$/);
      if (!m) continue;
      const j = out.findIndex((l, k) => k !== i && l.startsWith(m[1]) && /^(ATK|DEF)/.test(l.slice(m[1].length)) && !/ per |Ki /.test(l.slice(m[1].length)));
      if (j < 0) continue;
      out[i] = m[1] + "Ki +" + m[2] + " and " + out[j].slice(m[1].length);
      out.splice(j, 1);
      if (j < i) i--;
    }
    return out;
  }
  // "Ki +3" + "ATK & DEF +150%" with the same owner, duration and chance → one line.
  function joinKi(kiRow, statRowValue) {
    const kd = decodePassive(kiRow), sd = decodePassive(statRowValue);
    const kv = normalizeValues(passiveDef(kd.key).fields, kd.values), sv = normalizeValues(passiveDef(sd.key).fields, sd.values), s = settingsOf(kiRow);
    let core = passiveDef("ki").text(kv, s) + " and " + passiveDef(sd.key).text(sv, s);
    const t = TARGETS[s.target];
    if (t && t.owner) core = t.owner + core + (t.suffix || "");
    core += durationText(s.turn, s.timing);
    if (s.chance < 100) core = s.chance + "% chance: " + core;
    if (s.once) core += " (once only)";
    return cap(core);
  }
  // The in-game description, in Dokkan Battle's own style (icons included). plain: the editor's
  // simple wording without icons.
  // Level perks (ForgeLevelPerks in builder.js) are named "… Exclusive"; their text is written here.
  const EXCLUSIVE = /Exclusive$|^Level \d+ Exclusive$/;
  function exclusiveLines(rows) {
    const atk = rows.find((r) => Number(r.efficacy_type) === 1), def = rows.find((r) => Number(r.efficacy_type) === 2);
    const a = atk ? Number(atk.eff_value1) : 0, d = def ? Number(def.eff_value1) : 0;
    const v = a === d ? "ATK & DEF " + a + "%{passiveImg:up_g}" : [a ? "ATK " + a + "%{passiveImg:up_g}" : "", d ? "DEF " + d + "%{passiveImg:up_g}" : ""].filter(Boolean).join(" and ");
    const dr = rows.find((r) => Number(r.efficacy_type) === 13);
    return [v + ", applied after every other boost"].concat(dr ? ["Reduces damage received by " + (100 - Number(dr.eff_value1)) + "%"] : []);
  }
  function passiveText(rows, describe, plain = false) {
    const groups = new Map();
    // the Entrance Animation: the ability carrying the intro scene, and the once-only start-of-turn abilities that share
    // its condition, are written under "Activates the Entrance Animation … upon the character's entry"
    const carrier = rows.find((r) => Number(r.passive_skill_effect_id));
    const introCond = carrier ? (carrier.causality_conditions || "") : null;
    const isIntro = (r) => carrier && (r === carrier || (Number(r.exec_timing_type) === 1 && Number(r.is_once) === 1 && (r.causality_conditions || "") === introCond && !EXCLUSIVE.test(r.name || "")));
    const introHeading = carrier ? (() => { const c = describe && carrier.causality_conditions ? String(describe(carrier) || "") : ""; return "Activates the Entrance Animation" + (c ? " " + c : "") + (/enemy|enemies/.test(c) ? " at the start of the character's attacking turn" : " upon the character's entry"); })() : "";
    // efficacy 0 rows only trigger an intro scene or a Domain; they have no text of their own
    for (const row of rows.filter((r) => Number(r.efficacy_type) !== 0)) {
      // level perks (e.g. the GR boost at level 200) get their own "… Exclusive" heading
      const heading = EXCLUSIVE.test(row.name || "") ? row.name : isIntro(row) ? introHeading : (plain ? passiveHeading : officialHeading)(row, describe ? describe(row) : "");
      if (!groups.has(heading)) groups.set(heading, []);
      groups.get(heading).push(row);
    }
    let out = [];
    for (const [heading, list] of groups) out.push([heading, EXCLUSIVE.test(heading) ? exclusiveLines(list) : composeGroup(list, describe && describe.extra, plain)]);
    // an intro with no bonuses still shows in the description, so you can see it was added
    if (carrier && !groups.has(introHeading)) out.push([introHeading, ["Plays the character's Entrance Animation"]]);
    if (!plain) out = foldLadders(out);
    // level perks first (the GR exclusive sits at the top), then basic effects, then the rest
    const rank = (hd) => EXCLUSIVE.test(hd) ? 0 : /^Activates the Entrance Animation/.test(hd) ? 1 : hd === "Basic effect(s)" ? 2 : 3;
    out.sort((a, b) => rank(a[0]) - rank(b[0]));
    return out.map(([heading, lines]) => "*" + heading + "*\n" + lines.map((l) => "- " + l).join("\n")).join("\n");
  }

  // The game builds "per Category ally" boosts as a ladder of copies: "when there is a … ally", "when there is another …
  // ally", "when there are another 2 or more … allies"… each giving the same small boost. Written the game's way:
  // "Super Class allies' ATK & DEF 30%↑, plus an additional ATK & DEF 3%↑ per "Majin Buu Saga" Category ally on the team
  // (up to 21%)".
  const LADDER = /^When there (?:is (an?|another)|are (another )?(\d+) or more) (.+?) (?:ally|allies)( on the team| attacking in the same turn)$/;
  function foldLadders(out) {
    const ladders = new Map();
    out.forEach(([heading, lines], i) => {
      const m = LADDER.exec(heading);
      if (!m) return;
      const count = m[1] === "a" || m[1] === "an" ? 1 : m[1] === "another" ? 2 : Number(m[3]) + (m[2] ? 1 : 0);
      const key = m[4] + "|" + m[5] + "|" + lines.join("\n");
      if (!ladders.has(key)) ladders.set(key, { who: m[4], where: m[5], lines, items: [] });
      ladders.get(key).items.push({ i, count });
    });
    const drop = new Set(), adds = [];
    for (const L of ladders.values()) {
      const counts = L.items.map((x) => x.count).sort((a, b) => a - b);
      if (counts.length < 2 || counts.some((c, k) => k && c !== counts[k - 1] + 1)) continue;   // a real ladder: 1,2,3… or 2,3,4…
      L.items.forEach((x) => drop.add(x.i));
      const per = " per " + (counts[0] >= 2 ? "other " : "") + L.who + " ally" + L.where;
      for (const line of L.lines) {
        const num = /(\d+)(%?)(\{passiveImg:[a-z_]+\}|↑)?/.exec(line), cap_ = num ? " (up to " + Number(num[1]) * counts.length + num[2] + ")" : "";
        adds.push({ line, text: line + per + cap_, per, cap_ });
      }
    }
    if (!drop.size) return out;
    const kept = out.filter((_, i) => !drop.has(i));
    let basic = kept.find(([h]) => h === "Basic effect(s)");
    if (!basic) { basic = ["Basic effect(s)", []]; kept.push(basic); }
    for (const a of adds) {
      // "Super Class allies' ATK & DEF 30%↑" + "Super Class allies' ATK & DEF 3%↑ per …" → one line
      const owner = (/^(.+?(?:allies'|allies:) )/.exec(a.line) || [])[1] || "", rest = a.line.slice(owner.length), stat = (/^([A-Za-z &]+?) \d/.exec(rest) || [])[1];
      const j = owner && stat ? basic[1].findIndex((l) => l.startsWith(owner + stat + " ") && !/ per /.test(l)) : -1;
      if (j >= 0) basic[1][j] = basic[1][j] + ", plus an additional " + rest + a.per + a.cap_;
      else basic[1].push(a.text);
    }
    return kept;
  }

  // ---------------------------------------------------------------- leader skills
  const LEADER_WHO = [["all", "All Types"], ["types", "Chosen Types"], ["super", "Super Class"], ["extreme", "Extreme Class"], ["classTypes", "Super / Extreme Types"], ["categories", "Categories"]];
  const CLASS_TYPE_OPTIONS = [];
  for (const cls of [1, 2]) for (let t = 0; t < 5; t++) CLASS_TYPE_OPTIONS.push([(cls === 1 ? 4096 : 131072) << t, CLASSES[cls] + " " + TYPES[t]]);
  function leaderGroupDefaults(who = "all") {
    return { who, types: [0], classTypes: [4096], categories: [], also: [], ki: 3, hp: 170, atk: 170, def: 170 };
  }
  function normalizeGroup(g) {
    const who = LEADER_WHO.some(([k]) => k === g.who) ? g.who : "all";
    const out = { who, ki: int(g.ki, 0, 24, 0), hp: int(g.hp, 0, 1000, 0), atk: int(g.atk, 0, 1000, 0), def: int(g.def, 0, 1000, 0), types: [], classTypes: [], categories: [], also: [] };
    if (who === "types") out.types = [...new Set((g.types || []).map(Number).filter((t) => t >= 0 && t <= 4))].sort();
    if (who === "classTypes") out.classTypes = [...new Set((g.classTypes || []).map(Number).filter((m) => CLASS_TYPE_OPTIONS.some(([v]) => v === m)))].sort((a, b) => a - b);
    if (who === "categories") {
      out.categories = [...new Set((g.categories || []).map(Number).filter((id) => Number.isSafeInteger(id) && id > 0))];
      out.also = [...new Set((g.also || []).map(Number).filter((id) => Number.isSafeInteger(id) && id > 0 && !out.categories.includes(id)))];
    }
    return out;
  }
  function checkGroup(g) {
    if (g.who === "types" && !g.types.length) throw new Error("Choose at least one Type for each leader bonus.");
    if (g.who === "classTypes" && !g.classTypes.length) throw new Error("Choose at least one Super or Extreme Type.");
    if (g.who === "categories" && !g.categories.length) throw new Error("Choose at least one Category for each Category bonus.");
    if (g.who === "categories" && g.categories.length * Math.max(1, g.also.length) > 24) throw new Error("Use fewer Categories in one bonus (up to 24 combinations).");
    if (!g.ki && !g.hp && !g.atk && !g.def) throw new Error("Give each leader bonus some Ki or stats.");
    const even = g.hp === g.atk && g.atk === g.def;
    if (!even && ["types", "classTypes"].includes(g.who)) throw new Error("Type-specific leader bonuses use the same HP, ATK & DEF percentage. Use All Types, a Class, or Categories for separate values.");
  }
  function categorySets(g) {
    const sets = [];
    g.categories.forEach((cat, i) => {
      const base = g.categories.slice(0, i).map((c) => [2, c]).concat([[1, cat]]);
      if (!g.also.length) sets.push(base);
      else g.also.forEach((extra, j) => sets.push(base.concat(g.also.slice(0, j).map((c) => [2, c]), [[1, extra]])));
    });
    return sets;
  }
  const byCreation = (a, b) => Math.abs(Number(a.id)) - Math.abs(Number(b.id));
  const setKey = (entries) => entries.map(([t, v]) => t + ":" + v).join(",");
  function findSubTargetSet(p, entries, official) {
    const key = setKey(entries);
    const local = new Map();
    for (const r of p.tables.sub_target_types || []) {
      if (!local.has(r.sub_target_type_set_id)) local.set(r.sub_target_type_set_id, []);
      local.get(r.sub_target_type_set_id).push(r);
    }
    for (const [id, rows] of local) if (setKey(rows.slice().sort(byCreation).map((r) => [Number(r.target_value_type), Number(r.target_value)])) === key) return id;
    if (official) {
      const byId = new Map();
      for (const r of official) {
        if (!byId.has(r.sub_target_type_set_id)) byId.set(r.sub_target_type_set_id, []);
        byId.get(r.sub_target_type_set_id).push(r);
      }
      for (const [id, rows] of byId) if (Number(id) > 0 && setKey(rows.slice().sort(byCreation).map((r) => [Number(r.target_value_type), Number(r.target_value)])) === key) return Number(id);
    }
    return null;
  }
  function createSubTargetSet(p, schema, entries) {
    G.ensure(p, schema, "sub_target_type_sets");
    G.ensure(p, schema, "sub_target_types");
    const set = Object.assign(Forge.rowDefault(p.schema.sub_target_type_sets), { id: Forge.localId(p, "sub_target_type_sets") });
    p.tables.sub_target_type_sets.push(set);
    for (const [type, value] of entries) p.tables.sub_target_types.push(Object.assign(Forge.rowDefault(p.schema.sub_target_types), { id: Forge.localId(p, "sub_target_types"), sub_target_type_set_id: set.id, target_value_type: type, target_value: value }));
    return set.id;
  }
  function pruneSubTargets(p) {
    if (!p.tables.sub_target_type_sets) return;
    const used = new Set();
    for (const rows of Object.values(p.tables)) for (const r of rows) if (r && r.sub_target_type_set_id !== undefined && !("target_value_type" in r)) used.add(r.sub_target_type_set_id);
    p.tables.sub_target_type_sets = p.tables.sub_target_type_sets.filter((s) => Number(s.id) > 0 || used.has(s.id));
    const live = new Set(p.tables.sub_target_type_sets.map((s) => s.id));
    p.tables.sub_target_types = (p.tables.sub_target_types || []).filter((r) => Number(r.sub_target_type_set_id) > 0 || live.has(r.sub_target_type_set_id));
  }
  function leaderRows(g) {
    // [target_type, sub entries or null, mask] tuples.
    const out = [];
    const stats = (target, sub, mask) => {
      if (!g.hp && !g.atk && !g.def) return;
      if (g.hp === g.atk && g.atk === g.def) out.push({ target, sub, efficacy_type: 82, calc_option: 2, values: [mask, g.hp, 0] });
      else out.push({ target, sub, efficacy_type: 104, calc_option: 2, values: [g.hp, g.atk, g.def] });
    };
    if (g.who === "categories") {
      for (const entries of categorySets(g)) {
        if (g.ki) out.push({ target: 2, sub: entries, efficacy_type: 5, calc_option: 0, values: [g.ki, 0, 0] });
        stats(2, entries, 31);
      }
      return out;
    }
    const target = g.who === "super" ? 12 : g.who === "extreme" ? 13 : 2;
    const mask = g.who === "all" ? 31 : g.who === "super" ? 32 : g.who === "extreme" ? 64 : g.who === "types" ? g.types.reduce((m, t) => m | (1 << t), 0) : g.classTypes.reduce((m, v) => m + v, 0);
    if (g.ki) out.push({ target, sub: null, efficacy_type: 83, calc_option: 0, values: [mask, g.ki, 0] });
    stats(target, null, mask);
    return out;
  }
  function buildLeader(p, schema, groups, options = {}) {
    if (!Array.isArray(groups) || !groups.length) throw new Error("Add at least one leader bonus.");
    if (groups.length > 8) throw new Error("Use up to eight leader bonuses.");
    const normalized = groups.map(normalizeGroup);
    normalized.forEach(checkGroup);
    const root = Forge.card(p);
    let set = (p.tables.leader_skill_sets || []).find((r) => r.id === root.leader_skill_set_id);
    if (!set) {
      G.ensure(p, schema, "leader_skill_sets");
      set = Object.assign(Forge.rowDefault(p.schema.leader_skill_sets), { id: Forge.localId(p, "leader_skill_sets"), name: "Custom leadership", description: "" });
      p.tables.leader_skill_sets.push(set);
      p.cardOverrides.leader_skill_set_id = set.id;
    }
    G.ensure(p, schema, "leader_skills");
    p.tables.leader_skills = p.tables.leader_skills.filter((r) => r.leader_skill_set_id !== set.id);
    for (const g of normalized) for (const spec of leaderRows(g)) {
      let sub = 0;
      if (spec.sub) sub = findSubTargetSet(p, spec.sub, options.official) || createSubTargetSet(p, schema, spec.sub);
      p.tables.leader_skills.push(Object.assign(Forge.rowDefault(p.schema.leader_skills), { id: Forge.localId(p, "leader_skills"), leader_skill_set_id: set.id, exec_timing_type: 1, target_type: spec.target, sub_target_type_set_id: sub, causality_conditions: null, efficacy_type: spec.efficacy_type, efficacy_values: JSON.stringify(spec.values), calc_option: spec.calc_option }));
    }
    pruneSubTargets(p);
    if (options.names) {
      set.description = leaderText(normalized, options.names);
      if (options.name !== undefined) set.name = String(options.name).trim() || leaderName(normalized, options.names);
    }
    return set;
  }
  function statText(g) {
    if (!g.hp && !g.atk && !g.def) return "";
    if (g.hp === g.atk && g.atk === g.def) return "HP, ATK & DEF +" + g.hp + "%";
    const byValue = new Map();
    for (const [k, v] of [["HP", g.hp], ["ATK", g.atk], ["DEF", g.def]]) if (v) { if (!byValue.has(v)) byValue.set(v, []); byValue.get(v).push(k); }
    return [...byValue.entries()].sort((a, b) => b[0] - a[0]).map(([v, keys]) => keys.join(" & ") + " +" + v + "%").join(" and ");
  }
  function whoText(g, names) {
    const q = (id) => '"' + (names.category(id) || "Category " + id) + '"';
    if (g.who === "all") return "All Types";
    if (g.who === "super") return "Super Class";
    if (g.who === "extreme") return "Extreme Class";
    if (g.who === "types") return list(g.types.map((t) => TYPES[t])) + " Type";
    if (g.who === "classTypes") return list(g.classTypes.map((m) => (CLASS_TYPE_OPTIONS.find(([v]) => v === m) || [0, "?"])[1])) + " Type";
    return list(g.categories.map(q)) + " Category" + (g.also.length ? " characters who also belong to the " + list(g.also.map(q)) + " Category:" : "");
  }
  // Official style: '"A" or "B" Category Ki +3, HP +200% and ATK & DEF +170%, plus an additional
  // HP, ATK & DEF +50% for characters who also belong to the "C" or "D" Category'.
  function leaderText(groups, names) {
    const gs = groups.map(normalizeGroup), out = [], used = new Set();
    const bonusOf = (g) => { const st = statText(g); return g.ki ? "Ki +" + g.ki + (st ? (/ and /.test(st) ? ", " : " and ") + st : "") : st; };
    const q = (id) => '"' + (names.category(id) || "Category " + id) + '"';
    gs.forEach((g, i) => {
      if (used.has(i)) return;
      let line = whoText(g, names) + " " + bonusOf(g);
      if (g.who === "categories" && !g.also.length) {
        const j = gs.findIndex((o, k) => k !== i && !used.has(k) && o.who === "categories" && o.also.length && !o.ki && o.categories.join() === g.categories.join());
        if (j >= 0) { used.add(j); line += ", plus an additional " + statText(gs[j]) + " for characters who also belong to the " + list(gs[j].also.map(q)) + " Category"; }
      }
      used.add(i);
      out.push(line);
    });
    return out.join(";\nplus ");
  }
  function leaderName(groups, names) {
    const g = normalizeGroup(groups[0] || {});
    if (g.who === "categories" && g.categories.length) return (names.category(g.categories[0]) || "Team") + " Leadership";
    if (g.who === "types") return TYPES[g.types[0]] + " Leadership";
    if (g.who === "super" || g.who === "extreme") return CLASSES[g.who === "super" ? 1 : 2] + " Leadership";
    return "All-Type Leadership";
  }
  // Recovers builder groups from existing leader rows. Returns null when the leader uses rules
  // the builder cannot represent (conditions, other effects, or unusual targeting).
  function decodeLeader(rows, subTargetRows) {
    const real = rows.filter((r) => Number(r.efficacy_type) !== 0);
    if (!real.length) return null;
    const subs = new Map();
    for (const r of subTargetRows || []) {
      if (!subs.has(r.sub_target_type_set_id)) subs.set(r.sub_target_type_set_id, []);
      subs.get(r.sub_target_type_set_id).push(r);
    }
    const buckets = new Map();
    for (const r of real) {
      if (r.causality_conditions || Number(r.exec_timing_type) !== 1 || ![5, 82, 83, 104].includes(Number(r.efficacy_type))) return null;
      let v;
      try { v = JSON.parse(r.efficacy_values); } catch { return null; }
      if (!Array.isArray(v) || v.length < 3) return null;
      const sub = Number(r.sub_target_type_set_id) || 0, target = Number(r.target_type);
      let key, mask = null;
      if (sub) {
        if (target !== 2) return null;
        const entries = (subs.get(sub) || []).slice().sort(byCreation).map((x) => [Number(x.target_value_type), Number(x.target_value)]);
        if (!entries.length || entries.some(([t]) => t !== 1 && t !== 2)) return null;
        if ([82, 83].includes(Number(r.efficacy_type)) && Number(v[0]) !== 31) return null;
        if (Number(r.efficacy_type) === 83) return null;
        key = "s:" + setKey(entries);
        buckets.set(key, buckets.get(key) || { entries, ki: 0, stats: null });
      } else {
        if (Number(r.efficacy_type) === 5) mask = target === 12 ? 32 : target === 13 ? 64 : 31;
        else if (Number(r.efficacy_type) === 104) mask = target === 12 ? 32 : target === 13 ? 64 : 31;
        else mask = Number(v[0]);
        key = "t:" + target + ":" + mask;
        buckets.set(key, buckets.get(key) || { target, mask, ki: 0, stats: null });
      }
      const b = buckets.get(key), e = Number(r.efficacy_type);
      if (e === 5) b.ki += Number(v[0]);
      else if (e === 83) b.ki += Number(v[1]);
      else if (e === 82) { if (b.stats) return null; b.stats = [v[1], v[1], v[1]].map(Number); if (Number(r.calc_option) !== 2) return null; }
      else if (e === 104) { if (b.stats) return null; b.stats = [v[0], v[1], v[2]].map(Number); if (Number(r.calc_option) !== 2) return null; }
    }
    const groups = [], catBuckets = [];
    for (const b of buckets.values()) {
      const [hp, atk, def] = b.stats || [0, 0, 0];
      if (b.entries) { catBuckets.push({ b, hp, atk, def }); continue; }
      const g = { who: "all", ki: b.ki, hp, atk, def, types: [], classTypes: [], categories: [], also: [] };
      if (b.target === 12 && b.mask === 32) g.who = "super";
      else if (b.target === 13 && b.mask === 64) g.who = "extreme";
      else if (b.target !== 2) return null;
      else if (b.mask === 31) g.who = "all";
      else if (b.mask > 0 && b.mask < 31) { g.who = "types"; g.types = [0, 1, 2, 3, 4].filter((t) => b.mask & (1 << t)); }
      else {
        const parts = CLASS_TYPE_OPTIONS.filter(([m]) => b.mask & m).map(([m]) => m);
        if (!parts.length || parts.reduce((a, m) => a + m, 0) !== b.mask) return null;
        g.who = "classTypes"; g.classTypes = parts;
      }
      groups.push(g);
    }
    // Category buckets with the same values form one group; verify they encode back exactly.
    const byValue = new Map();
    for (const c of catBuckets) {
      const k = [c.b.ki, c.hp, c.atk, c.def].join("/");
      if (!byValue.has(k)) byValue.set(k, []);
      byValue.get(k).push(c);
    }
    for (const items of byValue.values()) {
      const positives = items.map(({ b }) => b.entries.filter(([t]) => t === 1).map(([, v]) => v));
      if (positives.some((p) => p.length < 1 || p.length > 2)) return null;
      const cats = [...new Set(positives.map((p) => p[0]))], also = [...new Set(positives.filter((p) => p.length === 2).map((p) => p[1]))];
      const g = normalizeGroup({ who: "categories", categories: cats, also, ki: items[0].b.ki, hp: items[0].hp, atk: items[0].atk, def: items[0].def });
      const expected = categorySets(g).map(setKey).sort().join("|"), actual = items.map(({ b }) => setKey(b.entries)).sort().join("|");
      if (expected !== actual) return null;
      groups.push(g);
    }
    return groups.length ? groups : null;
  }

  // ---------------------------------------------------------------- super attacks
  const NORMAL = "Special::NormalEfficacySpecial", EXTRA = "Special::ExtraEfficacySpecial";
  const SA_EFFECTS = [
    { key: "atk", label: "Raise ATK", eff: 1, calc: 2, type: NORMAL, targets: "buff", fields: [pctField("amount", "ATK +%", 30, 1, 1000)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }) },
    { key: "def", label: "Raise DEF", eff: 2, calc: 2, type: NORMAL, targets: "buff", fields: [pctField("amount", "DEF +%", 30, 1, 1000)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }) },
    { key: "atkdef", label: "Raise ATK & DEF", eff: 3, calc: 2, type: NORMAL, targets: "buff", fields: [pctField("atk", "ATK +%", 30, 0, 1000), pctField("def", "DEF +%", 30, 0, 1000)], read: (r) => ({ atk: r.eff_value1, def: r.eff_value2 }), write: (v) => ({ eff_value1: v.atk, eff_value2: v.def, eff_value3: 0 }) },
    { key: "crit", label: "Critical hits", eff: 90, calc: 2, type: NORMAL, targets: "self", fields: [pctField("amount", "Critical hit chance %", 100, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }) },
    { key: "dodge", label: "Evasion", eff: 91, calc: 2, type: NORMAL, targets: "self", fields: [pctField("amount", "Evade chance %", 30, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }) },
    { key: "effective", label: "Effective against all Types", eff: 76, calc: 0, type: NORMAL, targets: "self", fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }) },
    { key: "atkDown", label: "Lower enemy ATK", eff: 1, calc: 3, type: NORMAL, targets: "enemy", turn: 3, fields: [pctField("amount", "ATK −%", 30, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }) },
    { key: "defDown", label: "Lower enemy DEF", eff: 2, calc: 3, type: NORMAL, targets: "enemy", turn: 3, fields: [pctField("amount", "DEF −%", 30, 1, 100)], read: (r) => ({ amount: r.eff_value1 }), write: (v) => ({ eff_value1: v.amount, eff_value2: 0, eff_value3: 0 }) },
    { key: "atkdefDown", label: "Lower enemy ATK & DEF", eff: 3, calc: 3, type: NORMAL, targets: "enemy", turn: 3, fields: [pctField("atk", "ATK −%", 20, 0, 100), pctField("def", "DEF −%", 20, 0, 100)], read: (r) => ({ atk: r.eff_value1, def: r.eff_value2 }), write: (v) => ({ eff_value1: v.atk, eff_value2: v.def, eff_value3: 0 }) },
    { key: "stun", label: "Stun the enemy", eff: 9, calc: 0, type: EXTRA, targets: "enemy", turn: 1, chance: 100, fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }) },
    { key: "seal", label: "Seal the enemy's Super Attack", eff: 48, calc: 0, type: EXTRA, targets: "enemy", turn: 2, chance: 100, fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }) },
    { key: "disable", label: "Disable the enemy's action", eff: 111, calc: 0, type: EXTRA, targets: "enemy", turn: 1, fields: [], read: () => ({}), write: () => ({ eff_value1: 0, eff_value2: 0, eff_value3: 0 }) }
  ];
  const SA_TARGETS = { buff: [1, 2, 16, 12, 13], self: [1], enemy: [3] };
  const SA_DURATIONS = [[1, "1 turn"], [2, "2 turns"], [3, "3 turns"], [4, "4 turns"], [5, "5 turns"], [99, "Rest of the battle (stacks)"]];
  const saDef = (key) => SA_EFFECTS.find((e) => e.key === key);
  function decodeSpecial(row) {
    for (const def of SA_EFFECTS) if (def.eff === Number(row.efficacy_type) && (def.calc === undefined || def.calc === Number(row.calc_option) || def.type === EXTRA) && !row.causality_conditions) return { key: def.key, values: def.read(row) };
    return null;
  }
  function specialFields(key, values, settings = {}) {
    const def = saDef(key);
    if (!def) throw new Error("Choose a Super Attack effect from the list.");
    const v = normalizeValues(def.fields, values), targets = SA_TARGETS[def.targets];
    const target = targets.includes(Number(settings.target)) ? Number(settings.target) : targets[0];
    const turn = SA_DURATIONS.some(([t]) => t === Number(settings.turn)) ? Number(settings.turn) : def.turn || 1;
    return Object.assign({ type: def.type, efficacy_type: def.eff, target_type: target, calc_option: def.calc, turn, prob: int(settings.chance !== undefined ? settings.chance : def.chance || 100, 1, 100, 100), causality_conditions: null }, def.write(v));
  }
  const adverb = (n) => n >= 80 ? "massively " : n >= 50 ? "greatly " : "";
  function specialPhrase(row) {
    const d = decodeSpecial(row);
    if (!d) return { kind: "other", text: "applies an extra effect" };
    const v = normalizeValues(saDef(d.key).fields, d.values), target = Number(row.target_type), turn = Number(row.turn), prob = Number(row.prob);
    const dur = turn === 99 ? "" : " for " + turn + " turn" + (turn === 1 ? "" : "s");
    const owner = target === 2 ? "all allies' " : target === 16 ? "allies' " : target === 12 ? "Super Class allies' " : target === 13 ? "Extreme Class allies' " : "";
    const tail = target === 16 ? " (self excluded)" : "";
    const chance = (verb, noun) => prob >= 100 ? verb : prob <= 20 ? "may " + verb : "has a " + prob + "% chance of " + noun;
    switch (d.key) {
      case "atk": case "def": {
        const stat = d.key === "atk" ? "ATK" : "DEF";
        return target === 1 ? { kind: "self", text: adverb(v.amount) + "raises " + stat + dur } : { kind: "ally", text: "raises " + owner + stat + " by " + v.amount + "%" + dur + tail };
      }
      case "atkdef":
        if (target !== 1) return { kind: "ally", text: "raises " + owner + (v.atk === v.def ? "ATK & DEF by " + v.atk + "%" : "ATK by " + v.atk + "% and DEF by " + v.def + "%") + dur + tail };
        if (adverb(v.atk) === adverb(v.def)) return { kind: "self", text: adverb(v.atk) + "raises ATK & DEF" + dur };
        return { kind: "self", text: adverb(v.atk) + "raises ATK and " + adverb(v.def) + "raises DEF" + dur };
      case "crit": return { kind: "after", text: v.amount >= 100 ? "all attacks become critical hits" + dur : "raises chance of performing a critical hit by " + v.amount + "%" + dur };
      case "dodge": return { kind: "after", text: "raises chance of evading enemy's attack (including Super Attack) by " + v.amount + "%" + dur };
      case "effective": return { kind: "after", text: "attacks become effective against all Types" + dur };
      case "atkDown": return { kind: "after", text: adverb(v.amount) + "lowers ATK" + dur };
      case "defDown": return { kind: "after", text: adverb(v.amount) + "lowers DEF" + dur };
      case "atkdefDown": return { kind: "after", text: adverb(Math.max(v.atk, v.def)) + "lowers ATK & DEF" + dur };
      case "stun": return { kind: "after", text: chance("stuns the enemy" + dur, "stunning the enemy") };
      case "seal": return { kind: "after", text: chance("seals Super Attack", "sealing Super Attack") };
      case "disable": return { kind: "after", text: "disables the enemy's action" };
    }
    return { kind: "other", text: "" };
  }
  function damageName(set, profiles) {
    const match = (profiles || []).find((x) => Number(x.increase_rate) === Number(set.increase_rate) && Number(x.lv_bonus) === Number(set.lv_bonus));
    if (!match) return "massive";
    return match.key === "normal" ? "" : match.name.replace(/ damage$/i, "").toLowerCase();
  }
  function superText(set, effects, profiles) {
    const phrases = effects.map(specialPhrase).filter((x) => x.text);
    const self = phrases.filter((x) => x.kind === "self").map((x) => x.text), after = phrases.filter((x) => x.kind === "after" || x.kind === "other").map((x) => x.text), ally = phrases.filter((x) => x.kind === "ally").map((x) => x.text);
    const tier = damageName(set, profiles), damage = "causes " + (tier ? tier + " " : "") + "damage to " + (Number(set.aim_target) === 1 ? "all enemies" : "enemy");
    let text = list(self.concat([damage]).concat(after), "and");
    if (ally.length) text += "; " + list(ally, "and");
    return cap(text);
  }
  function createSuper(p, schema, spec) {
    const style = ["Normal", "Hyper", "Condition", "Extra", "FullPower"].includes(spec.style) ? spec.style : "Normal";
    const template = (p.tables.card_specials || []).filter((r) => r.style === style).sort((a, b) => b.lv_start - a.lv_start)[0] || (p.tables.card_specials || [])[0];
    const viewId = Number(spec.viewId || (template && template.view_id) || 0);
    if (!viewId) throw new Error("This character has no Super Attack animation to start from. Choose a character with a Super Attack first.");
    // Check prerequisites before creating any records: a rejected action must leave
    // the draft intact, including when a partial/older database lacks EX support.
    for (const t of ["special_sets", "specials", "card_specials", ...(style === "Extra" ? ["extra_special_options"] : []), ...(style === "Condition" && (spec.condition?.items?.length || !spec.condition) ? ["skill_causalities"] : [])]) if (!schema[t]) throw new Error("This game database does not support " + t + ".");
    if (style === "Condition") for (const item of (spec.condition || {items:[{key:"turn",values:{turn:4}}]}).items || []) conditionRule(item);
    for (const effect of spec.effects || []) specialFields(effect.key, effect.values, effect.settings || {});
    for (const t of ["special_sets", "specials", "card_specials"]) G.ensure(p, schema, t);
    const profile = spec.profile || { increase_rate: 150, lv_bonus: 20 };
    const set = Object.assign(Forge.rowDefault(p.schema.special_sets), { id: Forge.localId(p, "special_sets"), name: String(spec.name || (style === "Hyper" ? "Ultra Super Attack" : "Super Attack")).slice(0, 80), description: "", causality_description: null, aim_target: spec.allEnemies ? 1 : 0, increase_rate: profile.increase_rate, lv_bonus: profile.lv_bonus, is_inactive: 0 });
    p.tables.special_sets.push(set);
    const rel = Object.assign(Forge.rowDefault(p.schema.card_specials), {
      id: Forge.localId(p, "card_specials"), card_id: Number(p.source.cardId), special_set_id: set.id, priority: style === "Extra" ? ({ 0: 20, 1: 30, 2: 40 }[Number((spec.extraOptions || {}).extra_special_type) || 0]) : style === "Condition" ? 10 : 0, style, lv_start: int(spec.lvStart || 0, 0, 99, 0),
      eball_num_start: int(spec.ki, 1, 24, style === "Hyper" ? 18 : 12), view_id: viewId, card_costume_condition_id: 0,
      special_bonus_id1: 0, special_bonus_lv1: 0, bonus_view_id1: 0, special_bonus_id2: 0, special_bonus_lv2: 0, bonus_view_id2: 0, causality_conditions: null, special_asset_id: null, detail_view_priority: 0
    });
    p.tables.card_specials.push(rel);
    if (style === "Condition") { rel.special_asset_id = 2; applyCondition(p, schema, rel, spec.condition || {mode:"all",items:[{key:"turn",values:{turn:4}}]}); }
    if (style === "Extra") {
      G.ensure(p, schema, "extra_special_options");
      p.tables.extra_special_options.push(Object.assign(Forge.rowDefault(schema.extra_special_options), spec.extraOptions || {probability:70,extra_special_type:0,bgm_id:null}, {id:Forge.localId(p,"extra_special_options"),card_special_id:rel.id}));
      const opt = p.tables.extra_special_options[p.tables.extra_special_options.length - 1], t = Number(opt.extra_special_type) || 0;
      set.causality_description = "Activates with a " + (opt.probability || 70) + "% chance " + ["when the 1st attack in a turn is a Super Attack", "when performing an additional Super Attack", "when the 1st Super Attack performs a critical hit"][t];
    }
    // A new attack owns its customized animation rather than depending on another move's file.
    const animation = template && p.animationAssignments && p.animationAssignments["super:" + template.id];
    if (animation) {
      const key="super:"+rel.id, target=G.targets(p).find(t=>t.key===key);
      if(animation.mode==="original" && animation.originalSource && G.canReuseOriginal(animation.originalSource,target))G.applyOriginal(p,schema,animation.originalSource,key,animation.name);
      else G.applyComposition(p,schema,animation.clips,key,animation.name,{music:animation.music});
    }
    for (const effect of spec.effects || []) addSpecialEffect(p, set.id, effect.key, effect.values, effect.settings);
    set.description = superText(set, (p.tables.specials || []).filter((r) => r.special_set_id === set.id), spec.profiles);
    return { set, rel };
  }
  function addSpecialEffect(p, setId, key, values, settings = {}) {
    const def = saDef(key);
    const row = Object.assign(Forge.rowDefault(p.schema.specials), { id: Forge.localId(p, "specials"), special_set_id: setId }, specialFields(key, values, Object.assign({ target: SA_TARGETS[def.targets][0], turn: def.turn || 1, chance: def.chance || 100 }, settings)));
    p.tables.specials.push(row);
    return row;
  }
  function removeSuper(p, relId) {
    const rel = (p.tables.card_specials || []).find((r) => r.id === relId);
    if (!rel) return;
    if ((p.tables.card_specials || []).length < 2) throw new Error("A unit needs at least one Super Attack.");
    p.tables.card_specials = p.tables.card_specials.filter((r) => r.id !== relId);
    if (!p.tables.card_specials.some((r) => r.special_set_id === rel.special_set_id)) {
      p.tables.special_sets = (p.tables.special_sets || []).filter((s) => s.id !== rel.special_set_id);
      p.tables.specials = (p.tables.specials || []).filter((s) => s.special_set_id !== rel.special_set_id);
    }
    if (p.tables.extra_special_options) p.tables.extra_special_options = p.tables.extra_special_options.filter((r) => r.card_special_id !== relId);
    dropAnimation(p, "super:" + relId, "card_specials", relId);
  }
  function dropAnimation(p, key, table, row) {
    if (p.animationAssignments) for (const k of Object.keys(p.animationAssignments)) if (k === key || k.startsWith(key + ":")) delete p.animationAssignments[k];
    p.generatedFiles = (p.generatedFiles || []).filter((f) => !(f.owner === key || String(f.owner || "").startsWith(key + ":")));
    p.animationReferences = (p.animationReferences || []).filter((r) => !(r.table === table && r.row === row));
    if (p.uiLabels && p.uiLabels.animations) delete p.uiLabels.animations[key];
  }

  // ---------------------------------------------------------------- active skills
  const ACTIVE_EFFECTS = [
    { key: "atk", label: "Raise ATK", eff: 1, calc: 2, targets: "buff", fields: [pctField("amount", "ATK +%", 100, 1, 2000)], val: (v) => [v.amount, 0, 0], read: (r) => ({ amount: r.eff_val1 }), thumb: [5011, 44], text: (v, o) => o + "ATK +" + v.amount + "%" },
    { key: "def", label: "Raise DEF", eff: 2, calc: 2, targets: "buff", fields: [pctField("amount", "DEF +%", 100, 1, 2000)], val: (v) => [v.amount, 0, 0], read: (r) => ({ amount: r.eff_val1 }), thumb: [5011, 44], text: (v, o) => o + "DEF +" + v.amount + "%" },
    { key: "atkdef", label: "Raise ATK & DEF", eff: 3, calc: 2, targets: "buff", fields: [pctField("atk", "ATK +%", 50, 0, 2000), pctField("def", "DEF +%", 50, 0, 2000)], val: (v) => [v.atk, v.def, 0], read: (r) => ({ atk: r.eff_val1, def: r.eff_val2 }), thumb: [5011, 44], text: (v, o) => o + statPair(v.atk, v.def) },
    { key: "ki", label: "Raise Ki", eff: 5, calc: 0, targets: "buff", fields: [num("amount", "Ki +", 10, 1, 24)], val: (v) => [v.amount, 0, 0], read: (r) => ({ amount: r.eff_val1 }), thumb: [5014, 43], text: (v, o) => o + "Ki +" + v.amount },
    { key: "heal", label: "Recover HP", eff: 4, calc: 2, targets: "selfOrAllies", fields: [pctField("amount", "HP recovered %", 30, 1, 100)], val: (v) => [v.amount, 0, 0], read: (r) => ({ amount: r.eff_val1 }), thumb: [5011, 44], text: (v) => "recovers " + v.amount + "% HP" },
    { key: "crit", label: "Critical hits", eff: 90, calc: 2, targets: "self", fields: [pctField("amount", "Critical hit chance %", 100, 1, 100)], val: (v) => [v.amount, 0, 0], read: (r) => ({ amount: r.eff_val1 }), thumb: [5011, 44], text: (v) => v.amount >= 100 ? "all attacks become critical hits" : v.amount + "% chance of performing a critical hit" },
    { key: "dodge", label: "Evasion", eff: 91, calc: 2, targets: "self", fields: [pctField("amount", "Evade chance %", 50, 1, 100)], val: (v) => [v.amount, 0, 0], read: (r) => ({ amount: r.eff_val1 }), thumb: [5011, 44], text: (v) => v.amount + "% chance of evading enemy's attack" },
    { key: "guard", label: "Guard all attacks", eff: 78, calc: 0, targets: "self", fields: [], val: () => [0, 0, 0], read: () => ({}), text: () => "guards all attacks" },
    { key: "effective", label: "Effective against all Types", eff: 76, calc: 0, targets: "self", fields: [], val: () => [0, 0, 0], read: () => ({}), text: () => "attacks become effective against all Types" },
    { key: "foresee", label: "Foresee the enemy's Super Attack", eff: 101, calc: 0, targets: "self", fields: [], val: () => [0, 0, 0], read: () => ({}), text: () => "foresees enemy's Super Attack" },
    { key: "sphereChange", label: "Change Ki Sphere colors", eff: 51, calc: 0, targets: "self", fields: [{ name: "from", label: "Change", kind: "choice", def: 0, options: SPHERES.map((s, i) => [i, s + " Ki Spheres"]) }, { name: "to", label: "Into", kind: "choice", def: 5, options: SPHERES.map((s, i) => [i, s + " Ki Spheres"]) }], val: (v) => { if (v.from === v.to) throw new Error("Choose a different Ki Sphere color to change into."); return [v.from, v.to, 0]; }, read: (r) => ({ from: r.eff_val1, to: r.eff_val2 }), text: (v) => "changes " + SPHERES[v.from] + " Ki Spheres to " + SPHERES[v.to] + " Ki Spheres" },
    { key: "stun", label: "Stun the enemy", eff: 9, calc: 0, targets: "enemyAny", fields: [], val: () => [0, 0, 0], read: () => ({}), thumb: [5015, null], text: (v, o, t) => "stuns " + (t === 4 ? "all enemies" : "the enemy") },
    { key: "seal", label: "Seal Super Attacks", eff: 48, calc: 0, targets: "enemyAny", fields: [], val: () => [0, 0, 0], read: () => ({}), text: (v, o, t) => "seals " + (t === 4 ? "all enemies'" : "the enemy's") + " Super Attack" },
    { key: "disable", label: "Disable enemy actions", eff: 111, calc: 0, targets: "enemyAny", fields: [], val: () => [0, 0, 0], read: () => ({}), text: (v, o, t) => "disables an action of " + (t === 4 ? "every enemy" : "the enemy") + " once within the turn" },
    // the new LR Super Saiyan Goku / Frieza (Final Form) Active Skills: "directs enemy's attack towards the character"
    { key: "focus", label: "Directs enemy's attack towards the character", eff: 123, calc: 0, targets: "self", fields: [], val: () => [0, 0, 0], read: () => ({}), text: () => "directs enemy's attack towards the character" }
  ];
  const ACTIVE_TARGETS = { buff: [1, 2, 16, 12, 13], self: [1], selfOrAllies: [1, 2], enemyAny: [3, 4] };
  const activeDef = (key) => ACTIVE_EFFECTS.find((e) => e.key === key);
  function decodeActive(row) {
    for (const def of ACTIVE_EFFECTS) if (def.eff === Number(row.efficacy_type) && def.calc === Number(row.calc_option) && !Number(row.sub_target_type_set_id)) return { key: def.key, values: def.read(row) };
    return null;
  }
  function activeFields(key, values, target) {
    const def = activeDef(key);
    if (!def) throw new Error("Choose an Active Skill effect from the list.");
    const v = normalizeValues(def.fields, values), targets = ACTIVE_TARGETS[def.targets];
    const [a, b, c] = def.val(v);
    return { target_type: targets.includes(Number(target)) ? Number(target) : targets[0], sub_target_type_set_id: 0, calc_option: def.calc, efficacy_type: def.eff, eff_val1: a, eff_val2: b, eff_val3: c, efficacy_values: "{}", thumb_effect_id: def.thumb ? def.thumb[0] : null, effect_se_id: def.thumb ? def.thumb[1] : null };
  }
  function addActiveEffect(p, setId, key, values, target) {
    const row = Object.assign(Forge.rowDefault(p.schema.active_skills), { id: Forge.localId(p, "active_skills"), active_skill_set_id: setId }, activeFields(key, values, target));
    p.tables.active_skills.push(row);
    return row;
  }
  const ULTIMATE_BASE = 550;
  function createActive(p, schema, spec) {
    for (const t of ["active_skill_sets", "active_skills", "card_active_skills"]) G.ensure(p, schema, t);
    if ((p.tables.card_active_skills || []).some((r) => Number(r.card_id) === Number(p.source.cardId))) throw new Error("This unit already has an Active Skill. Edit it, or remove it first.");
    const set = Object.assign(Forge.rowDefault(p.schema.active_skill_sets), { id: Forge.localId(p, "active_skill_sets"), name: String(spec.name || "Active Skill").slice(0, 80), effect_description: "", condition_description: "", turn: 1, exec_limit: 1, causality_conditions: null, ultimate_special_id: null, special_view_id: spec.viewId ? Number(spec.viewId) : null, costume_special_view_id: 0, bgm_id: spec.bgmId ? Number(spec.bgmId) : null });
    p.tables.active_skill_sets.push(set);
    if (spec.attack) setActiveAttack(p, schema, set, spec.attack);
    p.tables.card_active_skills.push(Object.assign(Forge.rowDefault(p.schema.card_active_skills), { id: Forge.localId(p, "card_active_skills"), card_id: Number(p.source.cardId), active_skill_set_id: set.id }));
    for (const e of spec.effects || []) addActiveEffect(p, set.id, e.key, e.values, e.target);
    return set;
  }
  function setActiveAttack(p, schema, set, attack) {
    if (!attack) {
      if (set.ultimate_special_id && Number(set.ultimate_special_id) < 0 && p.tables.ultimate_specials) p.tables.ultimate_specials = p.tables.ultimate_specials.filter((u) => u.id !== set.ultimate_special_id);
      set.ultimate_special_id = null;
      return;
    }
    G.ensure(p, schema, "ultimate_specials");
    let row = (p.tables.ultimate_specials || []).find((u) => u.id === set.ultimate_special_id);
    if (!row) {
      row = Object.assign(Forge.rowDefault(p.schema.ultimate_specials), { id: Forge.localId(p, "ultimate_specials"), name: set.name, description: "Ultimate damage" });
      p.tables.ultimate_specials.push(row);
      set.ultimate_special_id = row.id;
    }
    const boost = int(attack.boost, 0, 5000, 0);
    row.increase_rate = ULTIMATE_BASE + boost;
    row.aim_target = attack.allEnemies ? 1 : 0;
    row.name = set.name;
    row.description = "Ultimate damage" + (boost ? " +" + boost + "%" : "");
  }
  function activeAttack(p, set) {
    if (!set || !set.ultimate_special_id) return null;
    const row = (p.tables.ultimate_specials || []).find((u) => u.id === set.ultimate_special_id);
    if (!row) return { inherited: true };
    return { boost: Math.max(0, Number(row.increase_rate) - ULTIMATE_BASE), allEnemies: Number(row.aim_target) === 1 };
  }
  function removeActive(p, setId) {
    const transform = (p.tables.active_skills || []).filter((r) => r.active_skill_set_id === setId && Number(r.efficacy_type) === 103);
    for (const r of transform) removeTransformation(p, "active_skills", r.id);
    const set = (p.tables.active_skill_sets || []).find((s) => s.id === setId);
    if (set && Number(set.ultimate_special_id) < 0 && p.tables.ultimate_specials) p.tables.ultimate_specials = p.tables.ultimate_specials.filter((u) => u.id !== set.ultimate_special_id);
    p.tables.active_skill_sets = (p.tables.active_skill_sets || []).filter((s) => s.id !== setId);
    p.tables.active_skills = (p.tables.active_skills || []).filter((s) => s.active_skill_set_id !== setId);
    p.tables.card_active_skills = (p.tables.card_active_skills || []).filter((s) => s.active_skill_set_id !== setId);
    if (p.tables.dokkan_field_active_skill_set_relations) p.tables.dokkan_field_active_skill_set_relations = p.tables.dokkan_field_active_skill_set_relations.filter((r) => r.active_skill_set_id !== setId);
    dropAnimation(p, "active:" + setId, "active_skill_sets", setId);
  }
  function activeText(p, set, profiles) {
    const rows = (p.tables.active_skills || []).filter((r) => r.active_skill_set_id === set.id);
    const parts = [];
    let transforms = false;
    for (const r of rows) {
      if (Number(r.efficacy_type) === 103) { transforms = true; continue; }
      const d = decodeActive(r);
      if (!d) { parts.push("applies a special effect"); continue; }
      const def = activeDef(d.key), v = normalizeValues(def.fields, d.values), t = Number(r.target_type);
      const owner = t === 2 ? "all allies' " : t === 16 ? "allies' " : t === 12 ? "Super Class allies' " : t === 13 ? "Extreme Class allies' " : "";
      if (["heal", "crit", "dodge", "guard", "effective", "foresee"].includes(d.key) && SUBJECTS[t] && t !== 3 && t !== 4) parts.push(SUBJECTS[t] + ": " + def.text(v, "", 1));
      else parts.push(def.text(v, owner, t) + (t === 16 ? " (self excluded)" : ""));
    }
    const attack = activeAttack(p, set), lead = [];
    if (transforms) lead.push("Transforms");
    if (attack && !attack.inherited) lead.push((attack.boost ? "raises ATK by " + attack.boost + "% temporarily and " : "") + "causes ultimate damage to " + (attack.allEnemies ? "all enemies" : "enemy"));
    else if (attack) lead.push("causes ultimate damage");
    const turn = Number(set.turn);
    let text = list(lead, "and");
    if (parts.length) text += (text ? "; " : "") + list(parts, "and") + (turn === 99 ? "" : " for " + (turn || 1) + " turn" + ((turn || 1) === 1 ? "" : "s"));
    return cap(text || "Activates a special ability");
  }
  function activeConditionText(condText, set) {
    const once = Number(set.exec_limit) === 1;
    return condText ? "Can be activated " + condText + (once ? " (once only)" : "") : "Can be activated at any time" + (once ? " (once only)" : "");
  }

  // ---------------------------------------------------------------- transformations
  // A transformation is an efficacy 103 row (passive: automatic; active skill: chosen by the player)
  // whose battle_params group controls the transformation scene. The builder clones a game-tested
  // exemplar group and points its "previous card" value at this unit, so export gives the unit its
  // own private copy (Forge.materialize -> ownTransformationParams).
  function transformationSource(p, effectValues, exemplarParams) {
    const params = clone(exemplarParams).map((row) => Number(row.idx) === 6 ? Object.assign(row, { value: Number(p.source.cardId) }) : row);
    return { effect: 103, values: effectValues.slice(), cardId: Number(p.source.cardId), params, viewIndex: 11, viewTable: "transformation_views", view: null };
  }
  function addPassiveTransformation(p, schema, spec) {
    const ex = spec.exemplar;
    if (!ex || !ex.row || !Array.isArray(ex.params) || !ex.params.length) throw new Error("The game's transformation template is unavailable. Refresh the game database and try again.");
    const target = Number(spec.targetId);
    if (!Number.isSafeInteger(target) || target <= 0) throw new Error("Choose what this character transforms into.");
    const row = Forge.addPassive(p, { name: String(spec.name || ex.row.name || "Transformation").slice(0, 80), exec_timing_type: Number(ex.row.exec_timing_type) || 1, exec_game_type: Number(ex.row.exec_game_type) || 0, efficacy_type: 103, target_type: 1, sub_target_type_set_id: 0, calc_option: 0, turn: 1, is_once: 0, probability: 100, causality_conditions: null, eff_value1: target, eff_value2: 0, eff_value3: Number(ex.row.eff_value3), efficacy_values: "{}" });
    p.abilityAnimationSources = p.abilityAnimationSources || {};
    p.abilityAnimationSources["passive_skills:" + row.id] = transformationSource(p, [target, 0, Number(ex.row.eff_value3)], ex.params);
    if (spec.condition) applyCondition(p, schema, row, spec.condition);
    setTransformationDescription(p, schema, "PassiveSkill", row.id, spec.description || "Transforms");
    return row;
  }
  function addActiveTransformation(p, schema, set, spec) {
    const ex = spec.exemplar;
    if (!ex || !ex.row || !Array.isArray(ex.params) || !ex.params.length) throw new Error("The game's transformation template is unavailable. Refresh the game database and try again.");
    const target = Number(spec.targetId);
    if (!Number.isSafeInteger(target) || target <= 0) throw new Error("Choose what this character transforms into.");
    G.ensure(p, schema, "active_skills");
    const row = Object.assign(Forge.rowDefault(p.schema.active_skills), { id: Forge.localId(p, "active_skills"), active_skill_set_id: set.id, target_type: 1, sub_target_type_set_id: 0, calc_option: 0, efficacy_type: 103, eff_val1: target, eff_val2: Number(ex.row.eff_val2) || 0, eff_val3: Number(ex.row.eff_val3), efficacy_values: "{}", thumb_effect_id: null, effect_se_id: null });
    p.tables.active_skills.push(row);
    p.abilityAnimationSources = p.abilityAnimationSources || {};
    p.abilityAnimationSources["active_skills:" + row.id] = transformationSource(p, [target, row.eff_val2, row.eff_val3], ex.params);
    if (!set.special_view_id && ex.viewId) set.special_view_id = Number(ex.viewId);
    setTransformationDescription(p, schema, "ActiveSkill", row.id, spec.description || "Transforms");
    return row;
  }
  function setTransformationDescription(p, schema, skillType, skillId, text) {
    if (!schema.transformation_descriptions) return null;
    G.ensure(p, schema, "transformation_descriptions");
    let row = p.tables.transformation_descriptions.find((d) => d.skill_type === skillType && d.skill_id === skillId);
    if (!row) {
      row = Object.assign(Forge.rowDefault(p.schema.transformation_descriptions), { id: Forge.localId(p, "transformation_descriptions"), skill_type: skillType, skill_id: skillId });
      p.tables.transformation_descriptions.push(row);
    }
    row.description = String(text).slice(0, 400);
    return row;
  }
  function removeTransformation(p, table, rowId) {
    const type = { passive_skills: "PassiveSkill", active_skills: "ActiveSkill" }[table];
    if (table === "passive_skills") Forge.removePassive(p, rowId);
    else {
      p.tables[table] = (p.tables[table] || []).filter((r) => r.id !== rowId);
      if (p.abilityAnimationSources) delete p.abilityAnimationSources[table + ":" + rowId];
      if (p.abilityAnimationOverrides) delete p.abilityAnimationOverrides[table + ":" + rowId];
      dropAnimation(p, "transform:" + table + ":" + rowId, table, rowId);
    }
    if (p.tables.transformation_descriptions) p.tables.transformation_descriptions = p.tables.transformation_descriptions.filter((d) => !(d.skill_type === type && d.skill_id === rowId));
    if (p.transformLinks) {
      p.transformLinks = p.transformLinks.filter((l) => !(l.table === table && l.row === rowId));
    }
    const forms = typeof ForgeForms !== "undefined" ? ForgeForms : typeof globalThis !== "undefined" && globalThis.ForgeForms;
    if (p.formProjects && forms && forms.prune) forms.prune(p);
    else if (p.formProjects) {
      const keep = new Set((p.transformLinks || []).map((l) => l.targetKey));
      p.formProjects = p.formProjects.filter((f) => keep.has(f.key));
      if (p.transformLinks && !p.transformLinks.length) delete p.transformLinks;
      if (!p.formProjects.length && !p.transformLinks) delete p.formProjects;
    }
  }

  // ---------------------------------------------------------------- EZA / Super EZA
  const EZA_PATTERN = [[125, 10], [125, 11], [130, 11], [130, 12], [130, 13], [135, 14], [140, 15]];
  const ROUTE_TEXT = "Join an Extreme Z-Battle to get the required Awakening Medal(s).";
  function cloneSet(p, kind, setId) {
    const tables = kind === "leader" ? ["leader_skill_sets", "leader_skills"] : ["passive_skill_sets", "passive_skills", "passive_skill_set_relations"];
    const donor = { schema: p.schema, tables: {}, abilityAnimationSources: p.abilityAnimationSources };
    const set = (p.tables[kind + "_skill_sets"] || []).find((r) => r.id === setId);
    if (!set) throw new Error("This stage's " + kind + " skill is missing. Reload the unit.");
    donor.tables[kind + "_skill_sets"] = [set];
    if (kind === "leader") donor.tables.leader_skills = (p.tables.leader_skills || []).filter((r) => r.leader_skill_set_id === setId);
    else {
      donor.tables.passive_skill_set_relations = (p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === setId);
      const ids = new Set(donor.tables.passive_skill_set_relations.map((r) => r.passive_skill_id));
      donor.tables.passive_skills = (p.tables.passive_skills || []).filter((r) => ids.has(r.id));
    }
    const maps = G.importOwned(p, donor, tables);
    return maps[kind + "_skill_sets"].get(setId);
  }
  function stageGroups(p, kind) {
    const base = Forge.card(p)[kind + "_skill_set_id"];
    const groups = [{ key: "base", label: p.awaken ? "Before EZA (the card as it is in the game)" : "Before Extreme Z-Awakening", steps: [], setId: base, locked: !!p.awaken }];
    const rows = (p.tables.optimal_awakening_growths || []).slice().sort((a, b) => a.step - b.step);
    for (const row of rows) {
      const last = groups[groups.length - 1], id = row[kind + "_skill_set_id"];
      if (last.key !== "base" && last.setId === id) { last.steps.push(Number(row.step)); continue; }
      groups.push({ key: "", steps: [Number(row.step)], setId: id });
    }
    for (const g of groups) if (g.key !== "base") {
      const a = g.steps[0], b = g.steps[g.steps.length - 1];
      g.key = "steps:" + a + "-" + b;
      g.label = (a === b ? "EZA step " + a : "EZA steps " + a + "–" + b) + (b >= 8 ? " · Super EZA" : b === 7 ? " · full EZA" : "");
    }
    return groups;
  }
  // Makes the chosen stage's skill set private to that stage before editing: copies a set that is
  // shared with other stages, and (for an EZA of a game card) any set that still belongs to the game.
  function ensureStageEditable(p, kind, key) {
    const groups = stageGroups(p, kind), g = groups.find((x) => x.key === key);
    if (!g) throw new Error("Choose an awakening stage.");
    if (g.key === "base") {
      if (p.awaken) throw new Error("The card's original abilities stay as they are in the game. Choose an EZA step to edit.");
      return g.setId;
    }
    const growth = p.tables.optimal_awakening_growths || [];
    const shared = groups.some((x) => x !== g && x.setId === g.setId);
    if (!g.setId) throw new Error("This EZA step has no " + kind + " skill. Copy one from a character first.");
    if ((p.awaken && Number(g.setId) > 0) || shared) {
      const id = cloneSet(p, kind, g.setId);
      for (const row of growth) if (g.steps.includes(Number(row.step))) row[kind + "_skill_set_id"] = id;
      return id;
    }
    return g.setId;
  }
  function stageView(p, kind, key) {
    const g = stageGroups(p, kind).find((x) => x.key === key);
    if (!g || g.key === "base") return p;
    return Object.assign({}, p, { cardOverrides: Object.assign({}, p.cardOverrides, { [kind + "_skill_set_id"]: g.setId }) });
  }
  function routeRow(p, step, setId) {
    return Object.assign(Forge.rowDefault(p.schema.card_awakening_routes), { id: Forge.localId(p, "card_awakening_routes"), type: "CardAwakeningRoute::Optimal", card_id: Number(p.source.cardId), awaked_card_id: Number(p.source.cardId), num: 1, card_awakening_set_id: Number(setId), optimal_awakening_step: step, optimal_awakening_type: step >= 8 ? 2 : 1, description: ROUTE_TEXT, priority: 0, open_at: "2020-01-01 00:00:00" });
  }
  // spec: { kind: "eza"|"seza", existingRoutes: official Optimal routes of this card, medals: {step: card_awakening_set_id}, medalName }
  function setupAwaken(p, schema, spec) {
    if (!["eza", "seza"].includes(spec.kind)) throw new Error("Choose EZA or Super EZA.");
    for (const t of ["optimal_awakening_growths", "card_awakening_routes", "passive_skill_sets", "passive_skills", "passive_skill_set_relations", "leader_skill_sets", "leader_skills"]) G.ensure(p, schema, t);
    const card = Forge.card(p);
    p.awaken = { cardId: Number(p.source.cardId), kind: spec.kind, medalName: spec.medalName || "" };
    p.tables.optimal_awakening_growths = (p.tables.optimal_awakening_growths || []).slice().sort((a, b) => a.step - b.step).map((row, i) => Object.assign(clone(row), { id: -(i + 1) }));
    const growth = p.tables.optimal_awakening_growths;
    if (spec.kind === "seza" && growth.length < 7) throw new Error("This card has no Extreme Z-Awakening yet. Make its EZA first, then add a Super EZA.");
    if (!growth.length) {
      if (!card.passive_skill_set_id || !card.leader_skill_set_id) throw new Error("This card has no passive or leader skill to awaken. Choose another card.");
      EZA_PATTERN.forEach(([lv, sa], i) => growth.push(Object.assign(Forge.rowDefault(p.schema.optimal_awakening_growths), { id: -(i + 1), optimal_awakening_grow_type: Number(p.targetId) || 0, step: i + 1, lv_max: lv, skill_lv_max: sa, passive_skill_set_id: card.passive_skill_set_id, leader_skill_set_id: card.leader_skill_set_id })));
      const mid = cloneSet(p, "passive", card.passive_skill_set_id), full = cloneSet(p, "passive", card.passive_skill_set_id), lead = cloneSet(p, "leader", card.leader_skill_set_id);
      for (const row of growth) {
        if (row.step >= 3) row.passive_skill_set_id = row.step === 7 ? full : mid;
        if (row.step >= 5) row.leader_skill_set_id = lead;
      }
    }
    if (spec.kind === "seza" && !growth.some((r) => Number(r.step) === 8)) {
      const seven = growth.find((r) => Number(r.step) === 7);
      growth.push(Object.assign(clone(seven), { id: -(growth.length + 1), step: 8, passive_skill_set_id: cloneSet(p, "passive", seven.passive_skill_set_id) }));
    }
    p.tables.card_awakening_routes = (spec.existingRoutes || []).filter((r) => r.type === "CardAwakeningRoute::Optimal").map(clone);
    for (const row of growth) {
      const step = Number(row.step);
      if (p.tables.card_awakening_routes.some((r) => Number(r.optimal_awakening_step) === step)) continue;
      const medal = spec.medals && (spec.medals[step] || spec.medals[Math.min(step, 7)]);
      if (!medal) throw new Error("Choose which Awakening Medals unlock EZA step " + step + ".");
      p.tables.card_awakening_routes.push(routeRow(p, step, medal));
    }
    p.patch.name = card.name + (spec.kind === "seza" ? " — Super EZA" : " — EZA");
    return p;
  }
  function setAwakenMedals(p, medals, name) {
    for (const row of p.tables.card_awakening_routes || []) if (Number(row.id) < 0) {
      const step = Number(row.optimal_awakening_step), medal = medals[step] || medals[Math.min(step, 7)];
      if (medal) row.card_awakening_set_id = Number(medal);
    }
    if (p.awaken) p.awaken.medalName = name || "";
  }
  function addSuperEza(p) {
    if (!p.awaken) throw new Error("Super EZA is for awakening an existing card.");
    const growth = p.tables.optimal_awakening_growths || [];
    if (growth.length < 7) throw new Error("Finish the 7 EZA steps first.");
    if (growth.some((r) => Number(r.step) === 8)) throw new Error("This card already has a Super EZA step.");
    const seven = growth.find((r) => Number(r.step) === 7), sevenRoute = (p.tables.card_awakening_routes || []).find((r) => Number(r.optimal_awakening_step) === 7);
    growth.push(Object.assign(clone(seven), { id: Forge.localId(p, "optimal_awakening_growths"), step: 8, passive_skill_set_id: cloneSet(p, "passive", seven.passive_skill_set_id) }));
    p.tables.card_awakening_routes.push(routeRow(p, 8, sevenRoute ? sevenRoute.card_awakening_set_id : 0));
    p.awaken.kind = "seza";
  }

  return { TYPES, TYPE_COLORS, SPHERES, CLASSES, ordinal, cap, list, elementParts, elementValue,
    CONDITIONS, setKiScale, conditionDef, conditionDefaults, conditionRule, matchCondition, decodeCondition, conditionText, applyCondition, pruneCausalities,
    TARGETS, PASSIVE, PASSIVE_GROUPS, TIMINGS, DURATIONS, passiveDef, decodePassive, normalizeValues, settingsOf, allowedTargets, passiveFields, newPassiveSettings, addPassiveAbility, updatePassiveAbility, passiveLine, passiveHeading, passiveText, officialLine, officialHeading, ICON,
    LEADER_WHO, CLASS_TYPE_OPTIONS, leaderGroupDefaults, normalizeGroup, buildLeader, leaderText, leaderName, decodeLeader, categorySets, pruneSubTargets, findSubTargetSet, createSubTargetSet,
    SA_EFFECTS, SA_TARGETS, SA_DURATIONS, saDef, decodeSpecial, specialFields, specialPhrase, superText, createSuper, addSpecialEffect, removeSuper, damageName,
    ACTIVE_EFFECTS, ACTIVE_TARGETS, activeDef, decodeActive, activeFields, addActiveEffect, createActive, setActiveAttack, activeAttack, removeActive, activeText, activeConditionText, ULTIMATE_BASE,
    EZA_PATTERN, cloneSet, stageGroups, ensureStageEditable, stageView, setupAwaken, setAwakenMedals, addSuperEza,
    COUNTER_WHAT, COUNTER_COND, counterCond, transformationSource, addPassiveTransformation, addActiveTransformation, setTransformationDescription, removeTransformation, dropAnimation };
});
