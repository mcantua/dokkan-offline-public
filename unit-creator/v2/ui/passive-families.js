"use strict";
// Passive abilities as simple FAMILIES (Critical hit, Dodge, ATK & DEF, Ki…). The list shows each family once;
// after adding one, its editor lets you pick the exact kind ("ATK only"), how it grows ("Grows with each attack",
// "For each Ki Sphere", "Based on HP left"…), % or fixed amount, who gets it, when, how long, chance, how often,
// requirements/restrictions, and — tucked away under "Advanced" — every raw game value.
// Each family/kind/growth combination maps onto one real game effect (the game's passive_skills rows), so nothing
// here is invented: a combination the game doesn't have is shown as unavailable.
window.ForgePassiveFamilies = (() => {
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const C = () => window.ForgePassiveCatalog, B = () => window.ForgeBuilder;
  const ENEMY = [3, 4, 14, 15];
  const SPHERE_BITS = [[1, "AGL"], [2, "TEQ"], [4, "INT"], [8, "STR"], [16, "PHY"], [32, "Rainbow"]];
  const TYPE_BITS = [[1, "AGL"], [2, "TEQ"], [4, "INT"], [8, "STR"], [16, "PHY"], [32, "Super Class"], [64, "Extreme Class"], [4096, "Super AGL"], [8192, "Super TEQ"], [16384, "Super INT"], [32768, "Super STR"], [65536, "Super PHY"], [131072, "Extreme AGL"], [262144, "Extreme TEQ"], [524288, "Extreme INT"], [1048576, "Extreme STR"], [2097152, "Extreme PHY"]];
  const COLORS0 = ["AGL", "TEQ", "INT", "STR", "PHY", "Rainbow"];
  const TYPES0 = ["AGL", "TEQ", "INT", "STR", "PHY"];

  // ---------------------------------------------------------------- the families
  const S = (id, label, help) => ({ id, label, help });
  const SCALE = {
    flat: S("flat", "Flat boost", "The same amount every time it applies."),
    grow: S("grow", "Grows (stacks) as the battle goes on", "Adds a little each time it triggers, up to a maximum you choose. Choose what makes it grow just below."),
    sphere: S("sphere", "For each Ki Sphere collected", "The more Ki Spheres the character collects this turn, the bigger the boost."),
    colors: S("colors", "For each Ki Sphere of chosen colors", "Only Ki Spheres of the colors you tick count."),
    one: S("one", "For each Ki Sphere of one color", "Only Ki Spheres of one color count."),
    hp: S("hp", "Based on HP left", "Changes with the character's HP: you set the amount at low HP and at full HP."),
    damage: S("damage", "From damage dealt", "Heals by a share of the damage the character deals.")
  };
  // slot: [kind, scale, eff, sub|null, side|null, friendlyKey?]   side: "up" (boost), "lower" (own stat down), "enemy"
  const FAMILIES = [
    { id: "atkdef", name: "ATK & DEF", icon: "▲", group: "Boosts", about: "Raise ATK and/or DEF — flat, stacking, per Ki Sphere or by HP.",
      kinds: [["both", "ATK & DEF"], ["atk", "ATK only"], ["def", "DEF only"]], scales: ["flat", "grow", "sphere", "colors", "one", "hp"],
      slots: [["both", "flat", 3, null, "up"], ["atk", "flat", 1, null, "up"], ["def", "flat", 2, null, "up"], ["atk", "grow", 98, "0"], ["def", "grow", 98, "1"],
        ["both", "sphere", 61], ["atk", "sphere", 59], ["def", "sphere", 60, null, "up"], ["atk", "colors", 68, "1"], ["def", "colors", 68, "3"], ["atk", "one", 64], ["def", "one", 65], ["both", "one", 66],
        ["both", "grow", "multi", [["atk", "grow"], ["def", "grow"]]], ["both", "colors", "multi", [["atk", "colors"], ["def", "colors"]]],
        ["both", "hp", 73], ["atk", "hp", 71], ["def", "hp", 72]] },
    { id: "ki", name: "Ki", icon: "●", group: "Boosts", about: "Extra Ki — flat, stacking or per Ki Sphere.", kinds: [["ki", "Ki"]], scales: ["flat", "grow", "sphere"],
      slots: [["ki", "flat", 5], ["ki", "grow", 98, "5"], ["ki", "sphere", 96]] },
    { id: "crit", name: "Chance of performing a critical hit", icon: "✸", group: "Offense", about: "Chance of a critical hit (ignores Type and hits harder).", kinds: [["crit", "Critical hit chance"]], scales: ["flat", "grow", "colors"],
      slots: [["crit", "flat", 90], ["crit", "grow", 98, "2"], ["crit", "colors", 68, "4"]] },
    { id: "additional", name: "Launches an additional attack", icon: "⚡", group: "Offense", about: "Launches extra attacks that can become Super Attacks.", kinds: [["add", "Additional attack"]], scales: ["flat"], slots: [["add", "flat", 81]] },
    { id: "effective", name: "Attacks are effective against all Types", icon: "✦", group: "Offense", about: "Attacks count as super effective against every Type.", kinds: [["eff", "Effective against all Types"]], scales: ["flat"], slots: [["eff", "flat", 76]] },
    { id: "alwaysHit", name: "Attacks guaranteed to hit", icon: "◎", group: "Offense", about: "The enemy can't evade this character's attacks.", kinds: [["hit", "Attacks always hit"]], scales: ["flat"], slots: [["hit", "flat", 92]] },
    { id: "ignoreDef", name: "Lowers the enemy's DEF to 0", icon: "⤓", group: "Offense", about: "Attacks treat the enemy's DEF as 0.", kinds: [["ignore", "Ignore enemy DEF"]], scales: ["flat"], slots: [["ignore", "flat", 53]] },
    { id: "dodge", name: "Chance of evading enemy's attack", icon: "↯", group: "Defense", about: "Chance to evade attacks, Super Attacks included.", kinds: [["dodge", "Dodge chance"]], scales: ["flat", "grow", "colors"],
      slots: [["dodge", "flat", 91], ["dodge", "grow", 98, "3"], ["dodge", "colors", 68, "5"]] },
    { id: "dr", name: "Damage reduction rate", icon: "⛨", group: "Defense", about: "Takes less damage from attacks.", kinds: [["dr", "Damage reduction"]], scales: ["flat", "grow", "colors"],
      slots: [["dr", "flat", 13], ["dr", "grow", 98, "4"], ["dr", "colors", 68, "6"]] },
    { id: "guard", name: "Guards all attacks", icon: "🛡", group: "Defense", about: "Less damage taken, and Type disadvantage is ignored.", kinds: [["guard", "Guard all attacks"]], scales: ["flat"], slots: [["guard", "flat", 78]] },
    { id: "counter", name: "Counters enemy's attack", icon: "↩", group: "Defense", about: "Hits back when attacked — choose what it counters and how hard.", kinds: [["counter", "Counter"], ["evade", "Evade, then counter"]], scales: ["flat"],
      slots: [["counter", "flat", 120, null, null, "counter"], ["evade", "flat", 128, null, null, "dodgeCounter"]] },
    { id: "noAlwaysHit", name: "Can nullify attacks that are guaranteed to hit", icon: "⊗", group: "Nullify & immunity", about: "Makes it possible to evade attacks that are guaranteed to hit.", kinds: [["block", "Can nullify attacks that are guaranteed to hit"]], scales: ["flat"], slots: [["block", "flat", 129]] },
    { id: "foresee", name: "Foresees enemy's Super Attack", icon: "👁", group: "Defense", about: "Shows which enemy will use a Super Attack.", kinds: [["foresee", "Foresee enemy Super Attacks"]], scales: ["flat"], slots: [["foresee", "flat", 101]] },
    { id: "nullifyAtk", name: "Nullifies enemy's attack", icon: "⊘", group: "Nullify & immunity", about: "Chance of nullifying an enemy's attack (it can also be absorbed as HP).", kinds: [["all", "Nullifies enemy's attack"]], scales: ["flat"], slots: [["all", "flat", 119]] },
    { id: "nullifySA", name: "Nullifies enemy's Super Attack", icon: "⊘", group: "Nullify & immunity", about: "Nullifies (or absorbs as HP) an enemy's Super Attack — all, Ki Blast, Unarmed or Physical.", kinds: [["super", "Nullifies enemy's Super Attack"]], scales: ["flat"], slots: [["super", "flat", 97]] },
    { id: "heal", name: "Recovers HP", icon: "♥", group: "Survival", about: "Heals HP — flat, per Ki Sphere or from damage dealt.", kinds: [["heal", "Recover HP"]], scales: ["flat", "colors", "damage"],
      slots: [["heal", "flat", 4], ["heal", "colors", 68, "2"], ["heal", "damage", 28]] },
    { id: "survive", name: "Survives K.O. attacks", icon: "🛡", group: "Survival", about: "Stays in the fight instead of being K.O.'d (up to once within a turn).", kinds: [["survive", "Survive a K.O. attack"]], scales: ["flat"],
      slots: [["survive", "flat", 52]] },
    { id: "immune", name: "Immune to negative effects", icon: "✧", group: "Nullify & immunity", about: "Can't be stunned, sealed or have ATK & DEF lowered.", kinds: [["immune", "Immune to negative effects"]], scales: ["flat"], slots: [["immune", "flat", 50]] },
    // single immunities (the game's own effect types; the 7th slot value is the row used when the game has no example)
    { id: "immuneStun", name: "Immune to stun", icon: "✧", group: "Nullify & immunity", about: "Can't be stunned.", kinds: [["s", "Immune to stun"]], scales: ["flat"], slots: [["s", "flat", 94, null, null, null, { target_type: 1 }]] },
    { id: "immuneSeal", name: "Immune to Super Attack seal", icon: "✧", group: "Nullify & immunity", about: "Its Super Attack can't be sealed.", kinds: [["s", "Immune to Super Attack seal"]], scales: ["flat"], slots: [["s", "flat", 100, null, null, null, { target_type: 1 }]] },
    { id: "immuneDown", name: "Immune to ATK & DEF reduction", icon: "✧", group: "Nullify & immunity", about: "Its ATK & DEF can't be lowered.", kinds: [["s", "Immune to ATK & DEF reduction"]], scales: ["flat"], slots: [["s", "flat", 99, null, null, null, { target_type: 1, eff_value1: 3 }]] },
    { id: "immuneAct", name: "Immune to action disabling", icon: "✧", group: "Nullify & immunity", about: "Its actions can't be disabled.", kinds: [["s", "Immune to action disabling"]], scales: ["flat"], slots: [["s", "flat", 112, null, null, null, { target_type: 1 }]] },
    { id: "team", name: "Type allies' ATK & DEF / Ki", icon: "♦", group: "Team", about: "Boosts allies of a chosen Type or Class.", kinds: [["atkdef", "ATK & DEF"], ["atk", "ATK"], ["def", "DEF"], ["hpatkdef", "HP, ATK & DEF (Type or Class)"], ["ki", "Ki"], ["kiClass", "Ki (Type or Class)"]], scales: ["flat"],
      slots: [["atkdef", "flat", 18], ["atk", "flat", 16, null, "up"], ["def", "flat", 17], ["hpatkdef", "flat", 82], ["ki", "flat", 20], ["kiClass", "flat", 83]] },
    { id: "lower", name: "Lowers the enemy's ATK & DEF", icon: "▼", group: "Enemy", about: "Lowers the enemy's ATK and/or DEF.", kinds: [["both", "ATK & DEF"], ["atk", "ATK"], ["def", "DEF"], ["atkType", "ATK (enemies of one Type)"]], scales: ["flat"],
      slots: [["both", "flat", 3, null, "enemy"], ["atk", "flat", 1, null, "enemy"], ["def", "flat", 2, null, "enemy"], ["atkType", "flat", 16, null, "enemy"]] },
    { id: "stun", name: "Stuns the attacked enemy", icon: "✖", group: "Enemy", about: "A stunned enemy can't attack.", kinds: [["stun", "Stuns the attacked enemy"]], scales: ["flat"], slots: [["stun", "flat", 9]] },
    { id: "seal", name: "Seals the attacked enemy's Super Attack", icon: "✖", group: "Enemy", about: "A sealed enemy can still do normal attacks, but no Super Attacks.", kinds: [["seal", "Seals the attacked enemy's Super Attack"]], scales: ["flat"], slots: [["seal", "flat", 48]] },
    { id: "disableAct", name: "Disables the enemy's action", icon: "✖", group: "Enemy", about: "The enemy loses one of its actions.", kinds: [["act", "Disables the enemy's action"]], scales: ["flat"], slots: [["act", "flat", 111]] },
    { id: "disableGuard", name: "Disables the enemy's guard", icon: "✖", group: "Enemy", about: "The enemy can't guard, so Type defence doesn't help it.", kinds: [["guard", "Disables the enemy's guard"]], scales: ["flat"], slots: [["guard", "flat", 24]] },
    { id: "spheres", name: "Changes Ki Spheres", icon: "◐", group: "Ki Spheres", about: "Turns Ki Spheres into other colors.", kinds: [["one", "One color into another"], ["several", "Several colors"], ["allOne", "All into one color"], ["allSeveral", "All into several colors"]], scales: ["flat"],
      slots: [["one", "flat", 51], ["several", "flat", 67], ["allOne", "flat", 69], ["allSeveral", "flat", 105]] },
    { id: "drawback", name: "Drawback", icon: "⚠", group: "Drawbacks", about: "A downside for balance: lower own stats or can't attack.", kinds: [["both", "Lower own ATK & DEF"], ["atk", "Lower own ATK"], ["def", "Lower own DEF"], ["defSphere", "Lower own DEF per Ki Sphere"], ["noAttack", "Can't attack"]], scales: ["flat"],
      slots: [["both", "flat", 3, null, "lower"], ["atk", "flat", 1, null, "lower"], ["def", "flat", 2, null, "lower"], ["defSphere", "flat", 60, null, "lower"], ["noAttack", "flat", 114]] },
    // ---- character exclusive (each uses a real setting from the game, picked by name)
    { id: "transform", name: "Transformation", icon: "⟳", group: "Character exclusive", about: "Transforms — by itself, with an Active Skill or when it revives.", kinds: [["tf", "Transformation"]], scales: ["flat"], slots: [], tab: "transform" },
    { id: "revive", name: "Revival", icon: "✚", group: "Character exclusive", about: "Revives with HP recovered when KO'd (once per battle).", kinds: [["revive", "Revive"]], scales: ["flat"], slots: [["revive", "flat", 109]] },
    { id: "intro", name: "Entrance Animation", icon: "🎬", group: "Character exclusive", about: "Activates the Entrance Animation upon the character's entry, with bonuses. Set up in the Intro section on this step.", kinds: [["i", "Entrance Animation"]], scales: ["flat"], slots: [], tab: "intro" },
    { id: "focus", name: "Directs enemy's attack towards the character", icon: "🎯", group: "Character exclusive", about: "Enemies attack this character (as on the new LR Super Saiyan Goku and LR Frieza (Final Form) Active Skills).", kinds: [["f", "Directs enemy's attack towards the character"]], scales: ["flat"], slots: [["f", "flat", 123, null, null, null, { target_type: 1 }]] },
    { id: "giant", name: "Giant form / Rage", icon: "🦍", group: "Character exclusive", about: "Becomes a Giant Ape, giant or raging form for a few turns (e.g. Great Ape, Furious Vegeta, Hirudegarn).", kinds: [["giant", "Giant / Rage form"]], scales: ["flat"], slots: [["giant", "flat", 79]] },
    { id: "exchange", name: "Reversible Exchange", icon: "⇄", group: "Character exclusive", about: "Swaps with a partner card and back (LR Exchange units like Goku & Frieza).", kinds: [["exchange", "Exchange with a partner"]], scales: ["flat"], slots: [["exchange", "flat", 131]] },
    { id: "endForm", name: "Deactivates transformation", icon: "⏏", group: "Character exclusive", about: "Returns a transformed form to its base form.", kinds: [["end", "End transformation"]], scales: ["flat"], slots: [["end", "flat", 117]] },
    { id: "standby", name: "Standby mode", icon: "⏳", group: "Character exclusive", about: "Marks the unit's Standby mode (pairs with the Standby & Finish step).", kinds: [["standby", "Standby mode"]], scales: ["flat"], slots: [["standby", "flat", 115]] },
    { id: "cancel", name: "Cancels a skill", icon: "⛔", group: "Character exclusive", about: "Switches off one of the unit's own skills (used by units whose Active or Standby Skill ends a mode).", kinds: [["cancel", "Cancel a skill"]], scales: ["flat"], slots: [["cancel", "flat", 110]] }
  ];
  const GROUPS = ["Boosts", "Offense", "Defense", "Nullify & immunity", "Survival", "Team", "Enemy", "Ki Spheres", "Drawbacks", "Character exclusive"];
  const famById = (id) => FAMILIES.find((f) => f.id === id);

  // ---------------------------------------------------------------- mapping rows <-> family slots
  const subOf = (e) => String(e.id).split(".")[3];
  function sideOfRow(eff, calc, target) {
    if (ENEMY.includes(Number(target))) return "enemy";
    return [1, 3].includes(Number(calc)) ? "lower" : "up";
  }
  function slotMatches(slot, eff, sub, side) {
    const [, , e, s, sd] = slot;
    if (e === "multi") return false;
    return e === eff && (s == null || s === String(sub)) && (!sd || sd === side);
  }
  function rowSub(row) {
    const e = Number(row.efficacy_type);
    if (e === 98) return String(row.eff_value3);
    if (e === 68) return String(row.eff_value2);
    return "None";
  }
  function classify(row) {
    if (!row) return null;
    const eff = Number(row.efficacy_type), sub = rowSub(row), side = sideOfRow(eff, row.calc_option, row.target_type);
    for (const f of FAMILIES) for (const slot of f.slots) if (slotMatches(slot, eff, sub, side)) return { fam: f, kind: slot[0], scale: slot[1], slot };
    return null;
  }
  function slotFor(fam, kind, scale) { return fam.slots.find((s) => s[0] === kind && s[1] === scale) || null; }
  function entriesFor(slot) {
    const [, , eff, sub, side] = slot;
    return C().all().filter((a) => a.eff === eff && (sub == null || subOf(a) === sub) && (!side || sideOfRow(a.eff, a.calc, a.target) === side)).sort((x, y) => y.uses - x.uses);
  }
  const isFixed = (calc) => [0, 1].includes(Number(calc));
  // the game row (fields) for a slot, keeping the current target / amount type when the game has them
  function fieldsFor(slot, prefer = {}) {
    const list = entriesFor(slot);
    if (list.length) {
      const score = (a) => (prefer.target != null && a.target === Number(prefer.target) ? 2 : 0) + (prefer.fixed != null && isFixed(a.calc) === prefer.fixed ? 1 : 0);
      const pick = list.slice().sort((x, y) => score(y) - score(x) || y.uses - x.uses)[0];
      return C().fields(pick);
    }
    if (slot[5] && B()) { const key = slot[5]; return B().passiveFields(key, {}, B().newPassiveSettings(key)); }
    if (slot[6]) return Object.assign({ efficacy_type: slot[2], calc_option: 0, target_type: 1, exec_timing_type: 1, sub_target_type_set_id: 0, turn: 1, probability: 100, is_once: 0, eff_value1: 0, eff_value2: 0, eff_value3: 0, efficacy_values: "{}", causality_conditions: null }, slot[6]);
    return null;
  }
  function targetsFor(row) {
    const c = classify(row);
    if (!c) return null;
    const set = new Set(entriesFor(c.slot).map((a) => a.target));
    const side = sideOfRow(row.efficacy_type, row.calc_option, row.target_type);
    if (!["transform", "giant", "exchange", "endForm", "standby", "cancel", "counter", "survive", "revive", "ignoreDef", "noAlwaysHit", "focus", "immuneStun", "immuneSeal", "immuneDown", "immuneAct"].includes(c.fam.id)) for (const t of side === "enemy" ? [3, 4, 14, 15] : [1, 2, 16, 12, 13]) set.add(t);
    set.add(Number(row.target_type));
    return [...set];
  }
  function amountTypes(slot) { return [...new Set(entriesFor(slot).map((a) => isFixed(a.calc) ? "fixed" : "pct"))]; }

  // "Who" in words that fit the ability ("Only this character comes back", "The whole team…")
  const WHO = {
    revive: { 1: "This character — it comes back to life itself when KO'd", 2: "The team — when an ally is KO'd, that ally comes back (like Master Roshi)" },
    heal: { 1: "Only this character recovers HP", 2: "The whole team recovers HP" },
    giant: { 1: "This character transforms" }, exchange: { 1: "This character swaps out" },
    foresee: { 1: "Only this character sees it", 2: "The whole team sees it" }
  };
  const WHO_HELP = {
    revive: "A revival works once per battle. Abilities with the condition “After any ally revives” (on this or another character) apply as soon as that character is in the rotation — even if it was waiting outside when the revival happened.",
    team: "Only allies of the chosen Type/Class get it.", lower: "Lowers stats of the enemies you choose here."
  };
  function whoLabel(row, t) { const c = classify(row); return c && WHO[c.fam.id] && WHO[c.fam.id][t] || ""; }
  function whoHelp(row) { const c = classify(row); return c ? WHO_HELP[c.fam.id] || "" : ""; }
  // ---------------------------------------------------------------- editor pieces (builder.js puts them together)
  const opt = (v, label, cur, dis) => '<option value="' + esc(v) + '"' + (String(v) === String(cur) ? " selected" : "") + (dis ? " disabled" : "") + ">" + esc(label) + "</option>";
  const helpTip = (t) => '<small class="pf-help">' + esc(t) + "</small>";
  function whatHTML(row) {
    const c = classify(row);
    if (!c) return "";
    const f = c.fam;
    let out = "";
    if (f.kinds.length > 1) out += '<label class="field' + (f.kindHelp ? " full" : "") + '">' + esc(f.kindLabel || "Kind") + '<select data-pf="kind:' + row.id + '">' + f.kinds.map(([k, l]) => opt(k, l, c.kind)).join("") + "</select>" + (f.kindHelp && f.kindHelp[c.kind] ? '<small class="pf-help">' + esc(f.kindHelp[c.kind]) + "</small>" : "") + "</label>";
    if (f.scales.length > 1) out += '<label class="field">How it works<select data-pf="scale:' + row.id + '">' + f.scales.filter((s) => f.slots.some((x) => x[1] === s)).map((s) => opt(s, SCALE[s].label, c.scale)).join("") + "</select>" + helpTip(SCALE[c.scale].help) + "</label>";
    const types = amountTypes(c.slot);
    // "% or fixed" only where it changes a number the player sees (stats, Ki, chances, healing)
    const AMOUNT_EFFS = [1, 2, 3, 4, 5, 13, 16, 17, 18, 28, 59, 60, 61, 68, 82, 83, 90, 91, 96, 98];
    if (types.length > 1 && AMOUNT_EFFS.includes(Number(row.efficacy_type))) out += '<label class="field">Amount is<select data-pf="amount:' + row.id + '">' + opt("pct", "A percentage (%)", isFixed(row.calc_option) ? "fixed" : "pct") + opt("fixed", "A fixed number", isFixed(row.calc_option) ? "fixed" : "pct") + "</select>" + (["atkdef", "lower", "drawback", "heal", "team"].includes(f.id) ? helpTip("A percentage grows with the character's stats; a fixed number adds the same amount to anyone.") : "") + "</label>";
    return out ? '<div class="field-grid">' + out + "</div>" : "";
  }
  // values for effects the builder's simple editor doesn't cover, with proper controls instead of numbers/IDs
  const VALUES = {
    98: [[1, "num", "Added each time"], [2, "num", "Maximum total", "Stops growing at this amount."]],
    71: [[1, "pct", "ATK boost at low HP %"], [2, "pct", "ATK boost at full HP %"]],
    72: [[1, "pct", "DEF boost at low HP %"], [2, "pct", "DEF boost at full HP %"]],
    73: [[1, "pct", "ATK & DEF boost at low HP %"], [2, "pct", "ATK & DEF boost at full HP %"]],
    68: [[1, "spheres", "Which Ki Sphere colors count"], [3, "num", "Amount per Ki Sphere"]],
    64: [[1, "color0", "Which Ki Sphere color counts"], [2, "pct", "ATK +% per Ki Sphere"]],
    66: [[1, "color0", "Which Ki Sphere color counts"], [2, "pct", "ATK & DEF +% per Ki Sphere"]],
    82: [[1, "types", "Which allies"], [2, "pct", "HP, ATK & DEF +%"]],
    83: [[1, "types", "Which allies"], [2, "num", "Ki +"]],
    16: [[1, "type0", "Which Type"], [2, "pct", "ATK %"]],
    17: [[1, "type0", "Which Type"], [2, "pct", "DEF +%"]],
    67: [[1, "spheres", "Change these colors"], [2, "spheres", "Into these colors"]],
    69: [[1, "color0", "Turn all Ki Spheres into"]],
    105: [[1, "sphere1", "New color 1"], [2, "sphere1", "New color 2"], [3, "sphere1", "New color 3"]],
    28: [[1, "pct", "% of damage dealt recovered as HP"]],
    97: [[1, "pct", "HP absorbed %", "Share of the blocked damage recovered as HP."]],
    65: [[1, "color0", "Which Ki Sphere color counts"], [2, "pct", "DEF +% per Ki Sphere"]],
    60: [[1, "num", "DEF change per Ki Sphere (%)"]],
    79: [[0, "choice", "Which form", "Every giant / rage form in the game. Its battle settings come with it."]],
    131: [[0, "choice", "Exchange partner", "Every Exchange pairing in the game."]],
    110: [[1, "pick", "What it switches off", "", [[1, "An Active Skill"], [2, "Another passive ability"]]], [3, "pick", "Whose", "", [[0, "This character's"], [1, "The enemy's"]]]],
    1: [[1, "num", "ATK amount"]], 2: [[1, "num", "DEF amount"]], 3: [[1, "num", "ATK amount"], [2, "num", "DEF amount"]],
    4: [[1, "num", "HP recovered"]], 13: [[1, "num", "Damage reduction"]], 90: [[1, "num", "Critical hit chance"]], 91: [[1, "num", "Dodge chance"]], 5: [[1, "num", "Ki +"]]
  };
  function valuesHTML(row) {
    const list = VALUES[Number(row.efficacy_type)];
    if (!list) return "";
    return '<div class="field-grid pf-values">' + list.map(([n, kind, label, help]) => {
      const v = Number(row["eff_value" + n]) || 0, key = row.id + ":" + n;
      let ctrl;
      if (kind === "choice") {
        const e = C().entryFor(row), list = (e && e.choices) || [], cur = [row.eff_value1, row.eff_value2, row.eff_value3].map(Number).join(",");
        const known = list.some(([vals]) => vals.join(",") === cur);
        return '<label class="field full">' + esc(label) + '<select data-pfchoice="' + row.id + '">' + (known ? "" : opt(cur, "Current setting", cur)) + list.map(([vals, l]) => opt(vals.join(","), l, cur)).join("") + "</select>" + (help ? helpTip(help) : "") + "</label>";
      }
      if (kind === "spheres" || kind === "types") {
        const bits = kind === "spheres" ? SPHERE_BITS : TYPE_BITS;
        ctrl = '<div class="pf-bits" data-pfbits="' + key + '">' + bits.map(([b, l]) => '<label class="pf-bit"><input type="checkbox" value="' + b + '"' + (v & b ? " checked" : "") + "> " + esc(l) + "</label>").join("") + "</div>";
        return '<div class="field full"><span>' + esc(label) + "</span>" + ctrl + (help ? helpTip(help) : "") + "</div>";
      }
      if (kind === "pick") { const opts = list.find((x) => x[0] === n)[4]; ctrl = '<select data-pfv="' + key + '">' + opts.map(([val, l]) => opt(val, l, v)).join("") + "</select>"; return '<label class="field">' + esc(label) + ctrl + "</label>"; }
      if (kind === "color0") ctrl = '<select data-pfv="' + key + '">' + COLORS0.map((c, i) => opt(i, c, v)).join("") + "</select>";
      else if (kind === "type0") ctrl = '<select data-pfv="' + key + '">' + TYPES0.map((c, i) => opt(i, c, v)).join("") + "</select>";
      else if (kind === "sphere1") ctrl = '<select data-pfv="' + key + '">' + opt(0, "—", v) + SPHERE_BITS.map(([b, l]) => opt(b, l, v)).join("") + "</select>";
      else ctrl = '<input type="number" inputmode="numeric" step="1" data-pfv="' + key + '" value="' + esc(v) + '">';
      return '<label class="field">' + esc(label) + ctrl + (help ? helpTip(help) : "") + "</label>";
    }).join("") + "</div>";
  }
  // "How it works in battle"
  function summaryHTML(row, when, line, condText) {
    const s = B().settingsOf(row), T = B().TARGETS || {};
    const dur = s.turn >= 99 ? "for the rest of the battle once it happens" : s.turn > 1 ? "for " + s.turn + " turns" : "for that turn";
    const items = [
      ["Does", line],
      ["Who", (T[s.target] || {}).label || "As set in the game data"],
      ["When", s.timing === 1 ? "Always on (checked at the start of each turn)" : ((B().TIMINGS.find(([t]) => t === s.timing) || [0, "As set in the game data"])[1])],
      ["Lasts", dur],
      ["Chance", s.chance >= 100 ? "Always (100%)" : s.chance + "%"],
      ["How often", s.once ? "Only once per battle" : "Every time it's triggered"],
      ["Needs", condText || "No requirements"]
    ];
    return '<div class="pf-summary"><strong>How it works in battle</strong><dl>' + items.map(([k, v]) => "<dt>" + esc(k) + "</dt><dd>" + esc(v) + "</dd>").join("") + "</dl></div>";
  }
  function toolsHTML(row) {
    const revive = Number(row.efficacy_type) === 109;
    return       '<div class="pf-tools">' + (revive ? '<button type="button" class="button small" data-pfa="revbonus:' + row.id + '">＋ Add a bonus after reviving</button><button type="button" class="button ghost small" data-b="revival-tf">⟳ Transform when it revives</button>' : "") +
      '<button type="button" class="button ghost small" data-pfa="dup:' + row.id + '">⧉ Duplicate</button>' +
      '<button type="button" class="button ghost small" data-pfa="link:' + row.id + '">＋ Add another effect at the same moment</button>' +
      '<button type="button" class="button ghost small" data-pfa="off:' + row.id + '">⏸ Turn off</button></div>';
  }
  function advancedHTML(row) {
    const tb = (f) => "table:passive_skills:" + row.id + ":" + f;
    const mech = (n) => (typeof mechanics === "function" ? mechanics(n) : []);
    const calcs = [[0, "Add a fixed number"], [1, "Subtract a fixed number"], [2, "Add a percentage"], [3, "Subtract a percentage"], [4, "Set to a number"]];
    const sel = (label, field, options, cur, help) => '<label class="field">' + esc(label) + '<select data-bind="' + tb(field) + '">' + options.map(([v, l]) => opt(v, l, cur)).join("") + (options.some(([v]) => Number(v) === Number(cur)) ? "" : opt(cur, String(cur), cur)) + "</select>" + (help ? helpTip(help) : "") + "</label>";
    const num = (label, field, help) => '<label class="field">' + esc(label) + '<input type="number" step="1" data-bind="' + tb(field) + '" value="' + esc(row[field]) + '">' + (help ? helpTip(help) : "") + "</label>";
    const e = C() && C().entryFor(row), names = (e && e.values) || [];
    return '<details class="pf-advanced"><summary>⚙ Advanced game settings</summary>' + helpTip("For experienced creators: the exact values the game reads. The settings above already cover normal use.") +
      '<div class="field-grid">' +
      sel("Every timing the game has", "exec_timing_type", mech("exec-types"), row.exec_timing_type) +
      sel("Every target the game has", "target_type", mech("target-types").filter((r) => r[0] !== 5), row.target_type) +
      sel("How the amount is applied", "calc_option", calcs, row.calc_option) +
      num("Effect type (game ID)", "efficacy_type", "Changing this turns it into a different ability.") +
      [1, 2, 3].map((n) => num("Value " + n + (names[n - 1] ? " · " + String(names[n - 1]).replace(/\s*\(.*$/, "") : ""), "eff_value" + n)).join("") +
      num("Duration in turns (99 = rest of battle)", "turn") + num("Chance %", "probability") +
      num("Ally group filter (sub-target set)", "sub_target_type_set_id", "0 = no filter.") +
      '</div><label class="field full">Extra effect values (JSON)<input type="text" data-bind="' + tb("efficacy_values") + '" value="' + esc(row.efficacy_values || "{}") + '"></label></details>';
  }

  // ---------------------------------------------------------------- changing kind / growth / amount type
  function switchTo(row, slot, prefer) {
    if (slot[2] === "multi") {
      // the game has no single effect for this (e.g. ATK & DEF that stacks): use one effect per stat, set up the same
      const c = classify(row), [first, ...rest] = slot[3].map(([k, sc]) => slotFor(c.fam, k, sc));
      switchTo(row, first, prefer);
      const setId = setIdOf(row);
      ForgeBuilderUI.commit(() => { for (const sl of rest) { const f = fieldsFor(sl, prefer); if (f) { Object.assign(f, { target_type: row.target_type, probability: row.probability, is_once: row.is_once, causality_conditions: row.causality_conditions }); Forge.addPassive(viewFor(setId), f); } } });
      return toast("The game does this with one effect per stat, so it's now two abilities — ATK and DEF — set up the same way.");
    }
    const f = fieldsFor(slot, prefer);
    if (!f) return toast("That combination isn't in the game.", true);
    ForgeBuilderUI.commit(() => {
      const keep = { target_type: row.target_type, exec_timing_type: row.exec_timing_type, turn: row.turn, probability: row.probability, is_once: row.is_once, causality_conditions: row.causality_conditions };
      Object.assign(row, f);
      // keep who/when/how long/chance/how often/requirements when the new effect allows them
      const targets = targetsFor(row) || [];
      if (targets.includes(Number(keep.target_type))) row.target_type = keep.target_type;
      const stack = Number(row.efficacy_type) === 98;
      if (!stack) { row.exec_timing_type = keep.exec_timing_type; row.turn = keep.turn; }
      row.probability = keep.probability; row.is_once = keep.is_once; row.causality_conditions = keep.causality_conditions;
    });
  }
  document.addEventListener("change", (e) => {
    const el = e.target;
    if (!el.matches || !state.project) return;
    const rows = state.project.tables.passive_skills || [];
    if (el.matches("[data-pf]")) {
      const [what, id] = el.dataset.pf.split(":"), row = rows.find((r) => r.id === Number(id)), c = classify(row);
      if (!c) return;
      if (what === "kind") {
        const slot = slotFor(c.fam, el.value, c.scale) || slotFor(c.fam, el.value, "flat") || c.fam.slots.find((s) => s[0] === el.value);
        return slot && switchTo(row, slot, { target: row.target_type, fixed: isFixed(row.calc_option) });
      }
      if (what === "scale") { const slot = slotFor(c.fam, c.kind, el.value); return slot && switchTo(row, slot, { target: row.target_type, fixed: isFixed(row.calc_option) }); }
      if (what === "amount") return switchTo(row, c.slot, { target: row.target_type, fixed: el.value === "fixed" });
    }
    if (el.matches("[data-pfchoice]")) {
      const row = rows.find((r) => r.id === Number(el.dataset.pfchoice)), vals = el.value.split(",").map(Number);
      if (row && vals.length === 3) ForgeBuilderUI.commit(() => { row.eff_value1 = vals[0]; row.eff_value2 = vals[1]; row.eff_value3 = vals[2]; });
      return;
    }
    if (el.matches("[data-pfv]")) {
      const [id, n] = el.dataset.pfv.split(":"), row = rows.find((r) => r.id === Number(id));
      if (row && el.value !== "") ForgeBuilderUI.commit(() => { row["eff_value" + n] = Number(el.value); });
    }
    const bits = el.closest && el.closest("[data-pfbits]");
    if (bits) {
      const [id, n] = bits.dataset.pfbits.split(":"), row = rows.find((r) => r.id === Number(id));
      const sum = [...bits.querySelectorAll("input:checked")].reduce((a, i) => a + Number(i.value), 0);
      if (!sum) { el.checked = true; return toast("Keep at least one ticked.", true); }
      if (row) ForgeBuilderUI.commit(() => { row["eff_value" + n] = sum; });
    }
  });
  // chance slider readout
  document.addEventListener("input", (e) => {
    const el = e.target;
    if (el.matches && el.matches('input[type="range"][data-bf="s.chance"]')) { const o = el.parentElement.querySelector(".pf-range-val"); if (o) o.textContent = el.value + "%"; el.style.setProperty("--p", el.value + "%"); }
  });

  // ---------------------------------------------------------------- duplicate / turn off / combine
  const viewFor = (setId) => Object.assign({}, state.project, { cardOverrides: Object.assign({}, state.project.cardOverrides, { passive_skill_set_id: setId }) });
  const rowFields = (row) => { const f = Object.assign({}, row); delete f.id; return f; };
  function setIdOf(row) { const rel = (state.project.tables.passive_skill_set_relations || []).find((r) => r.passive_skill_id === row.id); return rel ? rel.passive_skill_set_id : null; }
  document.addEventListener("click", (e) => {
    const b = e.target.closest && e.target.closest("[data-pfa]");
    if (!b || !state.project) return;
    const [act, id] = b.dataset.pfa.split(":"), p = state.project;
    if (act === "on") {
      const i = Number(id), item = (p.passiveOff || [])[i];
      if (!item) return;
      let row;
      ForgeBuilderUI.commit(() => { row = Forge.addPassive(viewFor(item.setId), item.fields); p.passiveOff.splice(i, 1); });
      return toast("Turned back on.");
    }
    if (act === "offdel") {
      const i = Number(id);
      ForgeBuilderUI.commit(() => { (p.passiveOff || []).splice(i, 1); });
      return;
    }
    const row = (p.tables.passive_skills || []).find((r) => r.id === Number(id));
    if (!row) return;
    if (act === "dup") {
      let copy;
      ForgeBuilderUI.commit(() => { copy = Forge.addPassive(viewFor(setIdOf(row)), rowFields(row)); });
      if (copy) ForgeBuilderUI.open("passive:" + copy.id);
      return toast("Duplicated. Change the copy below.");
    }
    if (act === "off") {
      const setId = setIdOf(row);
      ForgeBuilderUI.commit(() => { p.passiveOff = p.passiveOff || []; p.passiveOff.push({ setId, fields: rowFields(row) }); Forge.removePassive(p, row.id); });
      return toast("Turned off. It's kept below so you can turn it back on.");
    }
    if (act === "link") return open("add", { linkTo: row.id });
    if (act === "revbonus") return open("add", { afterRevive: true });
    if (act === "revanim") return ownRevivalAnimation(row);
  });
  // a revival needs a game scene to start from before your own animation can be made / chosen for it
  async function prepRevival(key) {
    const p = state.project, id = Number(key.split(":").pop()), src = "passive_skills:" + id, row = (p.tables.passive_skills || []).find((r) => r.id === id);
    if (!row) return false;
    if (!Number(row.eff_value2)) { row.eff_value2 = 2; if (typeof scheduleSave === "function") scheduleSave(); }
    p.abilityAnimationSources = p.abilityAnimationSources || {};
    if (!(p.abilityAnimationSources[src] && p.abilityAnimationSources[src].view)) {
      delete p.abilityAnimationSources[src];
      await Forge.hydrateAbilityAnimations(p, (o) => Native.call("query", o), state.info.schema);
    }
    if (!(p.abilityAnimationSources[src] && p.abilityAnimationSources[src].view)) { toast("This revival can't take another animation yet. Pick a game revival first.", true); return false; }
  }
  if (window.ForgeAnimChoice) ForgeAnimChoice.onPrepare("revival:", prepRevival);
  async function ownRevivalAnimation(row) {
    const key = "revival:passive_skills:" + row.id;
    if (await prepRevival(key) === false) return;
    const b = document.querySelector('[data-guide="studio:' + key + '"]');
    if (b) b.click();
  }

  // ---------------------------------------------------------------- extra pieces inside "What it does"
  // counters: "Reduce damage from" can differ from what it counters. When it does, the reduction is its own
  // (hidden) ability that fires when receiving that kind of attack, kept in step with the counter.
  // one simple choice; the matching "when receiving …" condition is built automatically
  const DR_WHAT = [["none", "No damage reduction"], [0, "Reduce damage from all attacks"], [1, "Reduce damage from normal attacks only"], [2, "Reduce damage from Super Attacks only"]];
  const drLinks = () => (state.project.counterDR = state.project.counterDR || {});
  const drRow = (id) => { const l = drLinks()[id]; return l && (state.project.tables.passive_skills || []).find((r) => r.id === l.row); };
  function companionIds() { const p = state.project; return new Set(Object.values(p.counterDR || {}).map((l) => l.row)); }
  function setDR(counter, what, amount) {
    const p = state.project, links = drLinks(), comp = drRow(counter.id);
    amount = Math.max(0, Math.min(100, Math.round(Number(amount) || 0)));
    if (what === "same") {
      if (comp) { Forge.removePassive(window.ForgeBuilderUI.target ? ForgeBuilderUI.target("passive") : p, comp.id); }
      delete links[counter.id];
      counter.eff_value1 = amount;
      return;
    }
    counter.eff_value1 = 0;
    const cond = B().counterCond(Number(what), counter);
    const fields = Object.assign({ efficacy_type: 13, calc_option: 2, target_type: 1, exec_timing_type: 6, turn: 1, probability: 100, is_once: 0, eff_value1: 100 - amount, eff_value2: 0, eff_value3: 0, efficacy_values: "", sub_target_type_set_id: 0, causality_conditions: null }, cond.causality_conditions === undefined ? {} : cond);
    if (comp) { Object.assign(comp, fields); }
    else {
      const view = ForgeBuilderUI.target("passive"), made = Forge.addPassive(view, fields), set = Forge.primaryPassive(view);
      if (set && set.name) made.name = set.name;
      links[counter.id] = { row: made.id, what: Number(what) };
    }
    if (links[counter.id]) links[counter.id].what = Number(what);
  }
  function drAmount(row) { const c = drRow(row.id); return c ? 100 - Number(c.eff_value1) : Number(row.eff_value1) || 0; }
  function counterExtrasHTML(html, row) {
    const what = (() => { try { return B().decodePassive(row).values.what; } catch { return 1; } })();
    // "Custom" only shows when the counter really uses its own requirements
    if (Number(what) !== 9) html = html.replace(/<option value="9"[^>]*>[^<]*<\/option>/, "");
    const link = drLinks()[row.id], amount = drAmount(row);
    let drw = link && drRow(row.id) ? link.what : amount > 0 ? Number(what) : "none";
    const options = DR_WHAT.slice();
    if (!options.some(([v]) => String(v) === String(drw))) options.push([drw, "Reduce damage from the attacks it counters"]);
    const pick = '<label class="field">Damage reduction<select data-pf-drwhat="' + row.id + '">' + options.map(([v, n]) => '<option value="' + v + '"' + (String(v) === String(drw) ? " selected" : "") + ">" + esc(n) + "</option>").join("") + "</select></label>";
    // the % box only shows when there is a reduction
    html = html.replace(/<label class="field">Damage received reduced by % \(0 = none\)(<input[^>]*data-bf="v\.dr"[^>]*>)<\/label>/, (m, input) =>
      pick + '<label class="field"' + (drw === "none" ? " hidden" : "") + ">Reduce damage by %" +
      (link && drRow(row.id)
        // the reduction lives on its own ability: this box edits that one, not the counter
        ? input.replace(/data-bf="v\.dr"/, 'data-pf-dramt="' + row.id + '"').replace(/value="[^"]*"/, 'value="' + amount + '"')
        : input.replace(/value="[^"]*"/, 'value="' + (drw === "none" ? 0 : amount) + '"')) + "</label>");
    return html;
  }
  function postFieldsHTML(html, row) {
    const AC = window.ForgeAnimChoice, eff = Number(row.efficacy_type);
    if (eff === 109 && AC) html = AC.enhance(html, "v.view", "revival:passive_skills:" + row.id, { help: "The animation that plays when this character revives. Only one is ever used." });
    if ([120, 128].includes(eff)) {
      if (eff === 120) html = counterExtrasHTML(html, row);
      else html = html.replace(/<option value="9"[^>]*>[^<]*<\/option>/, (m) => { try { return Number(B().decodePassive(row).values.what) === 9 ? m : ""; } catch { return m; } });
      if (AC) html = AC.enhance(html, "v.anim", "counter:" + row.id, { help: "The animation that plays when this character counters. Only one is ever used." });
    }
    return html;
  }
  document.addEventListener("change", (e) => {
    const el = e.target;
    if (!el.matches || !state.project) return;
    const box = el.closest && el.closest("[data-edit]"), id = box && Number(box.dataset.edit.split(":")[1]);
    const row = id && (state.project.tables.passive_skills || []).find((r) => r.id === id);
    if (!row) return;
    if (el.matches("[data-pf-drwhat]")) {
      e.stopImmediatePropagation();
      const amount = drAmount(row) || 30, what = (() => { try { return Number(B().decodePassive(row).values.what); } catch { return 1; } })();
      ForgeBuilderUI.commit(() => {
        if (el.value === "none") return setDR(row, "same", 0);
        const n = Number(el.value);
        // same as what it counters → kept on the counter itself; otherwise its own "when receiving …" ability
        setDR(row, n === what ? "same" : n, amount);
      });
      return;
    }
    // the reduction lives on its own ability: keep the number there
    if (el.matches("[data-pf-dramt]") && drRow(row.id)) {
      e.stopImmediatePropagation();
      ForgeBuilderUI.commit(() => setDR(row, drLinks()[row.id].what, el.value), { render: false, box });
    }
  }, true);
  // the counter's own conditions change ("What it counters") → its damage reduction keeps its own; removing the
  // counter removes the hidden reduction too
  document.addEventListener("click", (e) => {
    const b = e.target.closest && e.target.closest('[data-b^="passive-del:"]');
    if (!b || !state.project) return;
    const id = Number(b.dataset.b.split(":")[1]), comp = drRow(id);
    if (comp) setTimeout(() => { if (!(state.project.tables.passive_skills || []).some((r) => r.id === id)) { Forge.removePassive(window.ForgeBuilderUI.target ? ForgeBuilderUI.target("passive") : state.project, comp.id); delete drLinks()[id]; ForgeBuilderUI.render(); } }, 400);
  }, true);
  // when the revival scene changes, its animation source is read again (unless you made your own)
  document.addEventListener("change", (e) => {
    const el = e.target;
    if (!el.matches || !el.matches('[data-bf="v.view"]') || !state.project) return;
    const box = el.closest("[data-edit]"), id = box && Number(box.dataset.edit.split(":")[1]), p = state.project, key = "passive_skills:" + id;
    if (!id || (p.animationAssignments || {})["revival:" + key]) return;
    setTimeout(() => { if (p.abilityAnimationSources) delete p.abilityAnimationSources[key]; Forge.hydrateAbilityAnimations(p, (o) => Native.call("query", o), state.info.schema).catch(() => {}); }, 300);
  });
  function disabledHTML(set) {
    const list = (state.project.passiveOff || []).map((x, i) => [x, i]).filter(([x]) => set && x.setId === set.id);
    if (!list.length) return "";
    return '<div class="pf-off"><h3>Turned off</h3>' + list.map(([x, i]) => {
      let line = "";
      try { line = B().passiveLine(Object.assign({ id: 0 }, x.fields)); } catch {}
      return '<div class="pf-off-row"><span>' + esc(line) + '</span><button type="button" class="button ghost small" data-pfa="on:' + i + '">▶ Turn on</button><button type="button" class="icon-button" data-pfa="offdel:' + i + '" aria-label="Delete">×</button></div>';
    }).join("") + "</div>";
  }

  // ---------------------------------------------------------------- the list (＋ Add an ability / ★ Add a preset ability)
  let sheet = null, mode = "add", query = "", linkTo = null, afterRevive = false, afterAdd = null;
  function defaultFields(f) {
    const slot = f.slots.find((x) => x[2] !== "multi"), fields = slot ? fieldsFor(slot, {}) : null;
    // settings copied from a single rare card (e.g. 7% for 3 turns) are confusing as a start: begin always-on
    const top = slot && entriesFor(slot)[0];
    if (fields && top && top.uses < 5) Object.assign(fields, { probability: 100, turn: 1, is_once: 0 });
    return fields;
  }
  function preview(f) {
    if (f.tab || f.group === "Character exclusive") return f.about;
    try { return B().passiveLine(Object.assign({ id: 0, name: "" }, defaultFields(f))); } catch { return f.about; }
  }
  function listHTML() {
    const q = query.toLowerCase();
    const shown = FAMILIES.filter((f) => !f.hidden).filter((f) => !q || (f.name + " " + f.about + " " + f.kinds.map((k) => k[1]).join(" ")).toLowerCase().includes(q));
    if (!shown.length) return '<p class="hint">Nothing matches “' + esc(query) + "”.</p>";
    return GROUPS.filter((g) => shown.some((f) => f.group === g)).map((g) => "<h3>" + esc(g) + '</h3><div class="pf-list">' + shown.filter((f) => f.group === g).map((f) =>
      '<button type="button" class="pf-item" data-pfpick="' + f.id + '"><span class="pf-icon" aria-hidden="true">' + f.icon + "</span><span><strong>" + esc(f.name) + "</strong><small>" + esc(mode === "preset" ? preview(f) : f.about) + "</small></span></button>").join("") + "</div>").join("");
  }
  function draw() {
    const head = afterRevive ? "＋ Add a bonus after reviving" : linkTo ? "＋ Add an effect at the same moment" : mode === "preset" ? "★ Add a preset ability" : "＋ Add an ability";
    sheet.innerHTML = '<div class="sheet-head"><h2 id="pf-title">' + head + '</h2><button type="button" class="icon-button" data-pf-close aria-label="Close">×</button></div>' +
      '<p class="hint">' + (linkTo ? "The new effect copies when it happens, its chance, how long it lasts and its requirements, so both work together." : mode === "preset" ? "Each one is added with a balanced value from today’s LR and UR cards and works right away. Open it afterwards to change anything." : "Pick what you want. It works right away with sensible settings, and you can customize everything after it’s added.") + "</p>" +
      '<label class="field pcat-search">Search<input type="search" id="pf-q" placeholder="e.g. critical, Ki, dodge, heal" autocomplete="off" value="' + esc(query) + '"></label>' +
      '<div class="pf-results">' + listHTML() + "</div>";
    sheet.querySelector("[data-pf-close]").onclick = () => sheet.close();
    const qi = sheet.querySelector("#pf-q");
    qi.oninput = () => { query = qi.value.trim(); sheet.querySelector(".pf-results").innerHTML = listHTML(); bind(); };
    bind();
  }
  function bind() { sheet.querySelectorAll("[data-pfpick]").forEach((b) => b.onclick = () => { sheet.close(); add(famById(b.dataset.pfpick)); }); }
  function add(f) {
    if (!state.project) return toast("Open a unit first.", true);
    if (f.tab) { linkTo = null; return ForgeBuilderUI.tab(f.tab); }
    const fields = defaultFields(f);
    if (!fields) return toast("This ability isn't available.", true);
    const src = linkTo && (state.project.tables.passive_skills || []).find((r) => r.id === linkTo);
    if (src && Number(fields.efficacy_type) !== 98) Object.assign(fields, { exec_timing_type: src.exec_timing_type, turn: src.turn, probability: src.probability, is_once: src.is_once, causality_conditions: src.causality_conditions });
    if (afterRevive) Object.assign(fields, { exec_timing_type: 1, turn: 99, is_once: 0 });
    const row = ForgeBuilderUI.addRow("passive", fields, { open: mode !== "preset" || !!src || afterRevive });
    // "After the character's Revival Skill is activated": the game's own condition for post-revival boosts
    if (row && afterRevive) ForgeBuilderUI.commit((proj) => B().applyCondition(proj, state.info.schema, row, { mode: "all", items: [{ key: "revived", values: {} }] }));
    afterRevive = false;
    if (row && afterAdd) { const fn = afterAdd; afterAdd = null; fn(row); }
    if (row) toast("Added “" + f.name + "”" + (mode === "preset" && !src ? ": " + preview(f) : ". Customize it below."));
    linkTo = null;
    return row;
  }
  function open(which, opts = {}) {
    mode = which === "preset" ? "preset" : "add"; query = ""; linkTo = opts.linkTo || null; afterRevive = !!opts.afterRevive; afterAdd = opts.after || null;
    if (!sheet) { sheet = document.createElement("dialog"); sheet.className = "shell-sheet pcat-sheet pf-sheet"; sheet.setAttribute("aria-labelledby", "pf-title"); document.body.append(sheet); }
    draw();
    if (!sheet.open) sheet.showModal();
  }
  // adds an ability of a family straight away (used by the Revival section's own button)
  function addNow(id) {
    const f = famById(id), row = f ? add(Object.assign({}, f, { tab: null })) : null;
    // a new revival brings this character back (not an ally)
    if (row && id === "revive" && Number(row.target_type) !== 1) ForgeBuilderUI.commit(() => { row.target_type = 1; });
    return row;
  }
  return { addNow, postFieldsHTML, companionIds, whoLabel, whoHelp, FAMILIES, classify, targetsFor, whatHTML, valuesHTML, summaryHTML, toolsHTML, advancedHTML, disabledHTML, open, add, iconFor: (row) => { const c = classify(row); return c ? c.fam.icon : ""; }, aboutFor: (row) => { const c = classify(row); return c ? c.fam.about : ""; }, nameFor: (row) => { const c = classify(row); return c ? c.fam.name : ""; } };
})();
