"use strict";
// Every passive ability found in the game, for the Passive step's three buttons:
//   ＋ Add an ability        — pick any of them, then set it up in its editor
//   ★ Add a preset ability   — the same list, each with a balanced setting taken from today's LR/UR cards
//   ⧉ Copy a character's passive — copy one character's whole passive, or combine abilities from several
// The list comes from passive-catalog-data.js (tools/make_passive_catalog.py builds it from the game data).
window.ForgePassiveCatalog = (() => {
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
  const GROUP_ICON = { "Stats": "▲", "Ki & Ki Spheres": "●", "Offense": "✸", "Defense & survival": "⛨", "HP": "♥", "Enemy & battle effects": "✖", "Special": "✦" };
  let sheet = null, mode = "add", query = "", group = "";

  function all() { return ((window.ForgePassiveCatalogData || {}).abilities || []); }
  function byId(id) { return all().find((a) => a.id === id); }
  // The list shows each ability ONCE, in plain words ("Raise Ki", "Dodge"). Who it affects and whether the
  // amount is a % or a fixed number are chosen afterwards in its editor — the game's versions of the same
  // ability (self / allies / Super Class…, % / fixed) are the "variants" of one entry.
  const ENEMY = [3, 4, 14, 15];
  const LOWER = [1, 3];
  let conceptCache = null;
  function plainName(a) {
    let n = a.label.replace(/\s+—\s+[^—]*$/, "").replace(/\s*\((fixed amount|percentage|fixed|set value|alternate setting \d+)\)/g, "").trim();
    const enemy = ENEMY.includes(a.target);
    if (enemy && /^Lower /.test(n)) n = n.replace(/^Lower /, "Lower enemy ");
    else if (!enemy && LOWER.includes(a.calc) && /^Lower /.test(n) && a.group === "Stats") n = n.replace(/^Lower /, "Lower own ");
    return RENAME[n] || n.replace(/^Grows with each attack: (.*)$/, (m, x) => cap1(x) + " up with each attack").replace(/^Boost per Ki Sphere type: HP$/, "Recover HP per Ki Sphere of chosen colors").replace(/^Boost per Ki Sphere type: (.*)$/, (m, x) => cap1(x) + " up per Ki Sphere of chosen colors");
  }
  const cap1 = (t) => t.charAt(0).toUpperCase() + t.slice(1);
  const RENAME = {
    "Raise Type ATK & DEF": "Type allies: ATK & DEF", "Raise Type ATK": "Type allies: ATK", "Raise Type DEF": "Type allies: DEF", "Raise Type Ki": "Type allies: Ki",
    "Type/Class HP, ATK & DEF Boost": "Type or Class allies: HP, ATK & DEF", "Type/Class Ki Boost": "Type or Class allies: Ki", "Lower enemy Type ATK": "Lower enemy ATK (one Type)",
    "HP-Based ATK & DEF Scaling": "ATK & DEF based on HP left", "HP-Based ATK Scaling": "ATK based on HP left", "HP-Based DEF Scaling": "DEF based on HP left",
    "Ki Boost per Type Ki Sphere": "Ki up per Ki Sphere", "ATK & DEF Boost per Ki Sphere": "ATK & DEF up per Ki Sphere", "ATK Boost per Ki Sphere": "ATK up per Ki Sphere", "DEF Boost per Ki Sphere": "DEF up per Ki Sphere", "Lower DEF Boost per Ki Sphere": "DEF down per Ki Sphere",
    "Type Ki Sphere ATK Boost": "ATK up per Ki Sphere of one color", "Type Ki Sphere ATK & DEF Boost": "ATK & DEF up per Ki Sphere of one color",
    "Change Ki Sphere Type": "Change one Ki Sphere color", "Change Multiple Ki Sphere Types": "Change several Ki Sphere colors", "Change All Ki Spheres": "Change all Ki Spheres to one color", "Replace All Ki Spheres": "Change all Ki Spheres to several colors",
    "Super Effective Against All": "Effective against all Types", "Always Hit": "Attacks always hit", "Critical Hit": "Critical hit", "Additional Attack": "Additional attack",
    "Nullify/Absorb Enemy Attack": "Nullify enemy attacks", "Nullify/Absorb Super Attack": "Nullify enemy Super Attacks", "Damage Absorption": "Recover HP from damage dealt", "Survive KO": "Survive a K.O. attack", "Revival": "Revive",
    "Prevent Status Effects": "Immune to negative effects", "Guard Against All Attacks": "Guard all attacks", "Foresee Enemy's Super Attack": "Foresee enemy Super Attacks", "Counter Attack": "Counterattack", "Damage Reduction": "Damage reduction",
    "Lower Damage Reduction": "Damage reduction", "Disable Enemy Action": "Enemy can't act", "Guard Disabled": "Disable enemy guard", "Attack Impossible": "Can't attack (self)", "Super Attack Seal": "Seal Super Attacks", "Recover HP": "Recover HP"
  };
  function concepts() {
    if (conceptCache) return conceptCache;
    const map = new Map();
    for (const a of all()) {
      const name = plainName(a), key = a.group + "|" + name;
      if (!map.has(key)) map.set(key, { id: "c" + map.size, name, group: a.group, about: a.about, uses: 0, variants: [] });
      const c = map.get(key);
      c.variants.push(a); c.uses += a.uses;
    }
    conceptCache = [...map.values()];
    for (const c of conceptCache) c.variants.sort((x, y) => y.uses - x.uses);
    const order = ["Stats", "Ki & Ki Spheres", "Offense", "Defense & survival", "HP", "Enemy & battle effects", "Special"];
    conceptCache.sort((x, y) => order.indexOf(x.group) - order.indexOf(y.group) || y.uses - x.uses);
    return conceptCache;
  }
  function groups() { return [...new Set(concepts().map((c) => c.group))]; }
  function conceptOf(row) {
    const e = entryFor(row);
    return e ? concepts().find((c) => c.variants.includes(e)) : null;
  }

  // The game row for one catalogue entry, with its balanced values.
  function fields(a) {
    const d = a.defaults || {};
    return {
      efficacy_type: a.eff, calc_option: a.calc, target_type: a.target, sub_target_type_set_id: 0, causality_conditions: null,
      exec_timing_type: Number(d.exec_timing_type) || 1, turn: Number(d.turn) || 1, probability: Number(d.probability) || 100, is_once: Number(d.is_once) || 0,
      eff_value1: Number(d.eff_value1) || 0, eff_value2: Number(d.eff_value2) || 0, eff_value3: Number(d.eff_value3) || 0, efficacy_values: d.efficacy_values || "{}"
    };
  }
  // Wording for abilities the friendly editor has no sentence for (the game's own phrasing where it has one).
  const TYPE_BITS = [[1, "AGL"], [2, "TEQ"], [4, "INT"], [8, "STR"], [16, "PHY"], [32, "Super Class"], [64, "Extreme Class"], [4096, "Super AGL"], [8192, "Super TEQ"], [16384, "Super INT"], [32768, "Super STR"], [65536, "Super PHY"], [131072, "Extreme AGL"], [262144, "Extreme TEQ"], [524288, "Extreme INT"], [1048576, "Extreme STR"], [2097152, "Extreme PHY"]];
  const SPHERE_BITS = [[1, "AGL"], [2, "TEQ"], [4, "INT"], [8, "STR"], [16, "PHY"], [32, "Rainbow"], [448, "Candy"], [4096, "Carrot"]];
  const bits = (v, list) => { v = Number(v) || 0; const out = []; for (const [b, n] of list) if (b === 448 ? (v & 448) === 448 : v & b) out.push(n); return out; };
  const andList = (a) => a.length <= 1 ? a.join("") : a.slice(0, -1).join(", ") + " or " + a[a.length - 1];
  const OWNER = { 1: "", 2: "All allies' ", 16: "Allies' (self excluded) ", 12: "Super Class allies' ", 13: "Extreme Class allies' ", 3: "The attacked enemy's ", 4: "All enemies' " };
  function sphereName(v) {
    v = Number(v) || 0;
    if (v === 63) return "any"; if (v === 31) return "any Type"; if (v === 47) return "any non-PHY"; if (v === 61) return "any non-TEQ"; if (v === 62) return "any non-AGL";
    const n = bits(v, SPHERE_BITS); return n.length ? andList(n) : "a";
  }
  function describe(row) {
    const e = Number(row.efficacy_type), c = Number(row.calc_option), v1 = Number(row.eff_value1) || 0, v2 = Number(row.eff_value2) || 0, v3 = Number(row.eff_value3) || 0;
    const pct = [2, 3].includes(c) ? "%" : "", sign = [1, 3].includes(c) ? "−" : "+", owner = OWNER[Number(row.target_type)] || "";
    const stat = (k) => ({ 0: "ATK", 1: "DEF", 2: "critical hit chance", 3: "dodge chance", 4: "damage reduction", 5: "Ki" })[k] || "ATK";
    switch (e) {
      case 98: {
        // "ATK +40% with each attack received (up to 200%)" — what makes it grow is the ability's timing
        const t = Number(row.exec_timing_type), trig = [6, 7].includes(t) ? "with each attack received" : t === 1 ? "at the start of each turn" : t === 15 ? "for every Ki Sphere obtained" : [8].includes(t) ? "with each Super Attack performed" : "with each attack performed";
        const u = [0, 1].includes(c) && Number(v3) !== 5 ? "" : Number(v3) === 5 ? "" : "%";
        return owner + cap1(stat(v3)) + " " + sign + v1.toLocaleString("en-US") + u + " " + trig + " (up to " + sign + v2.toLocaleString("en-US") + u + ")";
      }
      case 71: case 72: case 73: {
        const what = { 71: "ATK", 72: "DEF", 73: "ATK & DEF" }[e], lo = Math.min(v1, v2), hi = Math.max(v1, v2);
        return what + " " + sign + lo + "% to " + hi + "% (" + (v1 > v2 ? "the less HP remaining, the greater the boost" : "the more HP remaining, the greater the boost") + ")";
      }
      case 82: return (andList(bits(v1, TYPE_BITS)) || "Type") + " allies' HP, ATK & DEF " + sign + v2 + pct;
      case 83: return (andList(bits(v1, TYPE_BITS)) || "Type") + " allies' Ki " + sign + v2;
      case 67: return "Changes " + (sphereName(v1) === "any" ? "all" : sphereName(v1)) + " Ki Spheres to " + (andList(bits(v2, SPHERE_BITS)) || "other") + " Ki Spheres";
      case 68: {
        const k = { 1: "ATK", 2: "HP", 3: "DEF", 4: "critical hit chance", 5: "dodge chance", 6: "damage reduction" }[v2] || "ATK", per = " per " + sphereName(v1) + " Ki Sphere obtained";
        if (v2 === 2) return "Recovers " + (pct ? v3 + "% HP" : v3.toLocaleString("en-US") + " HP") + per;
        return owner + k + " " + sign + v3.toLocaleString("en-US") + pct + per;
      }
      case 69: return "Changes all Ki Spheres to " + (["AGL", "TEQ", "INT", "STR", "PHY", "Rainbow"][v1] || "one type of") + " Ki Spheres";
      case 105: return "Changes all Ki Spheres to " + andList([v1, v2, v3].map((x) => andList(bits(x, SPHERE_BITS))).filter(Boolean)) + " Ki Spheres";
      case 79: case 131: {
        const ent = entryFor(row), hit = ent && (ent.choices || []).find(([v]) => Number(v[0]) === v1), nm = hit ? hit[1].replace(/\s*\(from .*\)$/, "") : "";
        return e === 79 ? "Transforms into " + (nm || "a giant form") + " for a while" : "Can Exchange with " + (nm || "a partner card");
      }
      case 117: return "Deactivates transformation";
      case 115: return "Standby mode";
      case 110: return "Cancels " + (v1 === 1 ? "an Active Skill" : "one of its skills");
      case 53: return "Lowers the enemy's DEF to 0";
      case 129: return "Can nullify attacks that are guaranteed to hit, making it possible to evade these attacks";
      case 50: return "Immune to negative effects";
      case 94: return "Immune to stun";
      case 99: return "Immune to ATK & DEF reduction";
      case 100: return "Immune to Super Attack seal";
      case 112: return "Immune to action disabling";
      case 123: return "Directs enemy's attack towards the character";
      case 65: return "DEF " + sign + v2 + "% per " + (["AGL", "TEQ", "INT", "STR", "PHY", "Rainbow"][v1] || "matching") + " Ki Sphere obtained";
      case 64: case 66: return (e === 64 ? "ATK " : "ATK & DEF ") + sign + v2 + "% per " + (["AGL", "TEQ", "INT", "STR", "PHY", "Rainbow"][v1] || "matching") + " Ki Sphere obtained";
      case 92: return owner ? owner + "attacks guaranteed to hit" : "Attacks guaranteed to hit";
      case 28: return "Recovers HP by " + v1 + "% of damage dealt";
      case 52: return "Survives K.O. attacks";
      case 24: return "Disables the enemy's guard";
      case 114: return "Unable to attack";
      default: return "";
    }
  }
  // How the balanced version reads in the game ("ATK & DEF +100%", "Ki +3"...).
  function line(a) {
    const B = window.ForgeBuilder;
    try { if (B && B.passiveLine) return B.passiveLine(Object.assign({ id: 0, name: "" }, fields(a))); } catch {}
    return a.about || a.label;
  }
  // The entry an existing row came from (for labelling its raw values in the editor).
  function entryFor(row) {
    const list = all(), eff = Number(row.efficacy_type), calc = Number(row.calc_option), t = Number(row.target_type);
    return list.find((a) => a.eff === eff && a.calc === calc && a.target === t) || list.find((a) => a.eff === eff && a.calc === calc) || list.find((a) => a.eff === eff) || null;
  }

  function matches(c) {
    if (group && c.group !== group) return false;
    if (!query) return true;
    const q = query.toLowerCase();
    return (c.name + " " + c.about + " " + c.group).toLowerCase().includes(q);
  }
  function listHTML() {
    const shown = concepts().filter(matches);
    if (!shown.length) return '<p class="hint">No ability matches “' + esc(query) + "”.</p>";
    return groups().filter((g) => shown.some((a) => a.group === g)).map((g) => "<h3>" + esc((GROUP_ICON[g] || "✦") + " " + g) + ' <small class="muted">' + shown.filter((a) => a.group === g).length + "</small></h3>" +
      '<div class="pcat-list">' + shown.filter((a) => a.group === g).map((a) =>
        '<button type="button" class="pcat-item" data-pcat="' + esc(a.id) + '"><strong>' + esc(a.name) + "</strong>" +
        (mode === "preset" ? '<span class="pcat-line">' + esc(line(a.variants[0])) + "</span>" : "") +
        '<span class="pcat-go" aria-hidden="true">' + (mode === "preset" ? "Add" : "＋") + "</span></button>").join("") + "</div>").join("");
  }
  function draw() {
    const count = concepts().length;
    sheet.innerHTML = '<div class="sheet-head"><h2 id="pcat-title">' + (mode === "preset" ? "★ Add a preset ability" : "＋ Add an ability") + '</h2><button type="button" class="icon-button" data-pcat-close aria-label="Close">×</button></div>' +
      '<p class="hint">' + (mode === "preset"
        ? "Each ability is already set to a balanced value from today’s LR and UR cards. Tap one to add it as shown — you can change anything afterwards."
        : "Pick the ability you want. You’ll set how much, who it affects, when it happens and its conditions next.") + "</p>" +
      '<label class="field pcat-search">Search<input type="search" id="pcat-q" placeholder="e.g. Ki, dodge, guard, critical" autocomplete="off" value="' + esc(query) + '"></label>' +
      '<div class="pcat-groups" role="tablist">' + ['<button type="button" data-pcat-group="" class="' + (group ? "" : "on") + '">All</button>'].concat(groups().map((g) => '<button type="button" data-pcat-group="' + esc(g) + '" class="' + (group === g ? "on" : "") + '">' + esc((GROUP_ICON[g] || "") + " " + g) + "</button>")).join("") + "</div>" +
      '<div class="pcat-results">' + listHTML() + "</div>";
    sheet.querySelector("[data-pcat-close]").onclick = () => sheet.close();
    const q = sheet.querySelector("#pcat-q");
    q.oninput = () => { query = q.value.trim(); sheet.querySelector(".pcat-results").innerHTML = listHTML(); bindItems(); };
    sheet.querySelectorAll("[data-pcat-group]").forEach((b) => b.onclick = () => { group = b.dataset.pcatGroup; draw(); });
    bindItems();
  }
  function bindItems() {
    sheet.querySelectorAll("[data-pcat]").forEach((b) => b.onclick = () => {
      const c = concepts().find((x) => x.id === b.dataset.pcat);
      if (!c) return;
      sheet.close();
      add(c.variants[0], { open: mode === "add", name: c.name });
    });
  }
  function add(a, opts = {}) {
    if (!state.project) return toast("Open a unit first.", true);
    if (!window.ForgeBuilderUI || !ForgeBuilderUI.addRow) return toast("Open the Passive step first.", true);
    const row = ForgeBuilderUI.addRow("passive", fields(a), { open: opts.open });
    if (row) toast((opts.open ? "Added “" : "Added the preset “") + (opts.name || plainName(a)) + "”" + (opts.open ? ". Set it up below." : ": " + line(a)));
    return row;
  }
  function open(which) {
    mode = which === "preset" ? "preset" : "add"; query = ""; group = "";
    if (!sheet) {
      sheet = document.createElement("dialog");
      sheet.className = "shell-sheet pcat-sheet";
      sheet.setAttribute("aria-labelledby", "pcat-title");
      document.body.append(sheet);
    }
    draw();
    if (!sheet.open) sheet.showModal();
    setTimeout(() => sheet.querySelector("#pcat-q")?.focus({ preventScroll: true }), 30);
  }

  // In the ability's editor: % or fixed number, when the game has both for this ability.
  function variantHTML(row) {
    const c = conceptOf(row);
    if (!c) return "";
    const calcs = [...new Set(c.variants.map((v) => [0, 1].includes(v.calc) ? "fixed" : "pct"))];
    if (calcs.length < 2) return "";
    const cur = [0, 1].includes(Number(row.calc_option)) ? "fixed" : "pct";
    return '<div class="field-grid"><label class="field">Amount is<select data-pcat-calc="' + row.id + '"><option value="pct"' + (cur === "pct" ? " selected" : "") + '>A percentage (%)</option><option value="fixed"' + (cur === "fixed" ? " selected" : "") + ">A fixed number</option></select></label></div>";
  }
  document.addEventListener("change", (e) => {
    const el = e.target;
    if (!el.matches || !el.matches("[data-pcat-calc]") || !state.project) return;
    const row = (state.project.tables.passive_skills || []).find((r) => r.id === Number(el.dataset.pcatCalc)), c = row && conceptOf(row);
    if (!c) return;
    const want = el.value === "fixed", t = Number(row.target_type);
    const v = c.variants.filter((x) => [0, 1].includes(x.calc) === want).sort((x, y) => (y.target === t) - (x.target === t))[0];
    if (!v) return;
    const f = fields(v);
    // keep who / when / how long / conditions; take the new kind of amount with a sensible value
    Object.assign(row, { calc_option: f.calc_option, eff_value1: f.eff_value1, eff_value2: f.eff_value2, eff_value3: f.eff_value3, efficacy_values: f.efficacy_values });
    if (typeof scheduleSave === "function") scheduleSave();
    if (window.ForgeBuilderUI) { ForgeBuilderUI.refreshTexts && ForgeBuilderUI.refreshTexts(); ForgeBuilderUI.render(); }
  });

  // ⧉ Copy a character's passive: one character's whole passive, or abilities combined from several.
  function copyChooser() {
    if (!state.project) return toast("Open a unit first.", true);
    const d = document.createElement("dialog");
    d.className = "shell-sheet pcat-sheet pcat-copy";
    d.setAttribute("aria-labelledby", "pcat-copy-title");
    d.innerHTML = '<div class="sheet-head"><h2 id="pcat-copy-title">⧉ Copy a character’s passive</h2><button type="button" class="icon-button" data-pcat-close aria-label="Close">×</button></div>' +
      '<div class="pcat-choices">' +
      '<button type="button" class="pcat-choice" data-guide="copy:passive"><span class="pcat-choice-icon">⧉</span><span><strong>Copy one character’s passive</strong><small>Your passive becomes an exact copy of the one you pick, with all its conditions.</small></span></button>' +
      '<button type="button" class="pcat-choice" data-pcat-combine><span class="pcat-choice-icon">⊕</span><span><strong>Combine passives from characters</strong><small>Pick one or more characters and add their abilities to the passive you already have. Repeats are merged.</small></span></button>' +
      "</div>";
    document.body.append(d);
    const done = () => { d.close(); d.remove(); };
    d.querySelector("[data-pcat-close]").onclick = done;
    d.addEventListener("cancel", () => setTimeout(() => d.remove(), 0));
    const one = d.querySelector('[data-guide="copy:passive"]');
    one.addEventListener("click", done);   // runs before the copy flow opens its own window
    if (window.ForgeGuideUI && ForgeGuideUI.bindGuide) ForgeGuideUI.bindGuide(d);
    d.querySelector("[data-pcat-combine]").onclick = () => { done(); try { ForgePassiveOrganize.pickCharacter(); } catch (e) { toast(e.message, true); } };
    d.showModal();
  }
  return { open, add, copyChooser, entryFor, fields, line, all, describe, concepts, variantHTML, plainName };
})();
