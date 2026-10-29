"use strict";
// ✪ Special Skills (Card Builder step): Counters, Revivals, Intros, Domains, Standby & Finish
// Skills, plus shortcuts to Active Skills, EX / Ultra Super Attacks and Transformations.
// Everything is plain words: no game IDs. Each change is one ↶ Undo step.
window.ForgeSpecial = (() => {
  const B = () => window.ForgeBuilder, G = () => window.ForgeGuide, UI = () => window.ForgeBuilderUI;
  const h = (s) => esc(String(s == null ? "" : s));
  const INTROS = [[131, "Buu (Kid)"], [130, "Super Saiyan Gohan (Youth)"], [129, "Perfect Cell"], [128, "Super Saiyan Goku"], [127, "Frieza (Final Form)"], [126, "Dr. Arinsu"], [125, "Panzy"], [124, "Super Saiyan 3 Goku (Mini) (DAIMA)"], [122, "Turles"], [121, "Cell Max"], [120, "Metal Cooler Army"], [119, "Beerus"], [118, "Super Saiyan God Goku"], [117, "Super Saiyan God Vegeta (Ultra Supervillain)"], [116, "Saibaiman"], [115, "Vegeta + Nappa"], [114, "Majin Vegeta + Super Saiyan 2 Goku (Angel)"], [113, "Dabura"], [112, "Goku (Ultra Instinct -Sign-) +  Super Saiyan God SS Evolved Vegeta"], [111, "Super Saiyan 4 Vegeta + Super Saiyan 4 Goku"], [110, "Luud"], [109, "Super Saiyan 3 Vegeta (DAIMA)"], [108, "Super Saiyan 4 Goku (DAIMA)"], [107, "Ultimate Gohan + Gamma 1"], [104, "Gamma 2 + Piccolo (Power Awakening)"], [103, "Super Garlic Jr."], [102, "Third Eye Gomah"], [101, "Super Saiyan 4 Goku (Mini) (DAIMA)"], [100, "Android #16"], [99, "Chi-Chi"], [98, "SS Gohan Possessed (GT) & SS Goten Possessed (GT)"], [97, "Majin Buu (Good)"], [96, "Super Saiyan 2 Gohan (Youth)"], [95, "Frieza (Final Form)"], [94, "Piccolo Jr. (Giant Form)"], [93, "Vegeta"], [92, "Goku"], [91, "Broly (Wrathful)"], [90, "Golden Frieza + Gogeta"], [89, "Super Saiyan Gohan (Teen) +  Super Saiyan Trunks (Kid) & Super Saiyan Goten (Kid)"], [88, "Super Saiyan 4 Gogeta"], [87, "Omega Shenron"], [86, "Goku Black (Super Saiyan Ros\u00e9) + Zamasu"], [85, "Super Saiyan God SS Goku +  Super Saiyan God SS Vegeta"], [84, "Tien"], [83, "Mercenary Tao"], [82, "Super Saiyan 2 Caulifla + Super Saiyan 2 Kale"], [81, "Super Saiyan God SS Goku (Kaioken)"], [80, "Hit"], [79, "Cell (Perfect Form)"], [78, "Goku (Youth)"], [77, "Super Saiyan 3 Vegeta (Mini) (DAIMA)"], [76, "Super Saiyan 2 Gohan (Youth)"], [75, "Trunks (Kid) + Goten (Kid)"], [74, "Glorio"], [73, "Super Saiyan Goku (Mini) (DAIMA)"], [72, "Super Saiyan God SS Evolved Vegeta"], [71, "Frieza (Final Form) (Angel) + Goku"], [69, "Beerus"], [68, "Super Saiyan Vegeta (Angel) + Super Saiyan Goku (Angel)"], [67, "Super Saiyan Goku + Super Saiyan Vegeta (Angel)"], [66, "Anilaza"], [65, "Super Saiyan God SS Goku (Universe Tree Power)"], [64, "Lord Slug"], [63, "Bio-Broly"], [62, "Vegeta"], [61, "Super Saiyan Bardock"], [60, "Grandpa Gohan"], [59, "Legendary Super Saiyan Broly"], [58, "Paragus"], [57, "Broly"], [56, "Master Roshi"], [55, "Goku (Ultra Instinct -Sign-)"], [54, "Cell Max"], [53, "Super Saiyan 2 Trunks (Future)"], [52, "Krillin"], [51, "Ultimate Gohan"], [50, "Majin Buu (Good)"], [49, "Super Saiyan 3 Goku (Angel)"], [48, "Goku (Youth) & Krillin (Youth) & Bulma (Youth)"], [47, "Captain Ginyu (Ginyu Force)"], [46, "Toppo"], [45, "Frieza (1st Form)"], [44, "Gohan (Beast)"], [43, "Super Saiyan Goku"], [42, "Super Saiyan Broly"], [41, "Hirudegarn"], [40, "Super Saiyan Goku &  Super Saiyan Vegeta & Super Saiyan Trunks (Teen)"], [39, "Cell (Perfect Form) (GT) &  Frieza (Final Form) (GT)"], [38, "Android #21 (Transformed, Evil)"], [37, "Super Full Power Saiyan 4 Limit Breaker Vegito (Xeno)"], [36, "Ribrianne & Kakunsa & Rozie"], [35, "Pilaf & Shu & Mai"], [34, "Androids #17 & #18"], [33, "Super Saiyan Gohan (Future)"], [32, "Super Saiyan Trunks (Future)"], [31, "Zamasu"], [30, "Fusion Zamasu"], [29, "Super Saiyan God SS Goku &  Super Saiyan God SS Vegeta"], [28, "Omega Shenron"], [27, "Turles"], [26, "Dr. Wheelo"], [25, "Bulma (Youth)"], [24, "Goku"], [23, "Piccolo Jr. (Giant Form)"], [22, "Buu (Super)"], [21, "Bulma (Youth)"], [20, "Super Saiyan God Goku"], [19, "Gohan (Kid)"], [18, "Goku"], [17, "Piccolo (Power Awakening)"], [16, "Ultimate Gohan"], [15, "Yamcha"], [14, "Bardock"], [13, "Gamma 2"], [12, "Gamma 1"], [11, "Cooler (Final Form)"], [10, "Super Saiyan God SS Vegeta &  Super Saiyan Trunks (Future)"], [9, "Fusion Zamasu"], [8, "Golden Frieza"], [7, "Super Saiyan God SS Goku/ Super Saiyan God SS Vegeta"], [6, "Majin Vegeta"], [5, "Vegeta (Giant Ape)"], [4, "Goku (Kaioken)"], [3, "Gohan (Teen) & Goten (Kid) & Trunks (Kid)"], [2, "Super Saiyan 4 Goku & Super Saiyan 4 Vegeta"], [1, "Super Saiyan God Goku &  Super Saiyan God Vegeta"]];
  const DOMAINS = [[1, "Wasteland (Future)", "\"Future Saga\" Category Super Class enemies' and allies' ATK & DEF +10%", 3001, 4], [2, "Infinite Zamasu", "Increases damage received by Super Class enemies and allies by 30%", 3000, 5], [3, "City (Future) (Rainy)", "Increases damage received by Extreme Class enemies and allies by 30%", 3002, 5], [4, "City (Future) (Rift in Time)", "\"Super Bosses\" Category enemies' and allies' ATK & DEF +10%, plus an additional ATK & DEF +10% for characters who are also Extreme Class", 3003, 4], [5, "Extradimensional Space", "Extreme Class enemies' and allies' ATK & DEF +10%, plus an additional ATK & DEF +10% for characters who also belong to the \"Exploding Rage\" or \"Movie Bosses\" Category; increases damage received by Super Class enemies and allies by 10%", 3004, 4], [6, "Illuminated World of Void", "Super Class enemies' and allies' ATK & DEF +15%, plus an additional ATK +15% for characters who also belong to the \"Realm of Gods\" Category; Super Class enemies and allies can nullify attacks that are guaranteed to hit, making it possible to evade these attacks", 3005, 3], [7, "Molten Lava of Natade Village", "\"Uncontrollable Power\" Category enemies' and allies' ATK & DEF +15%; increases damage received by Super Class enemies and allies by 15%, plus an additional 10% for characters who also belong to the \"Movie Heroes\" Category", 3006, 3], [8, "Inside Majin Buu", "\"Power Absorption\" or \"Transformation Boost\" Category enemies' and allies' ATK & DEF +15%; \"Majin Buu Saga\" Category enemies' and allies' ATK & DEF +15%", 3008, 3], [9, "Earth Shrouded in Clouds", "\"Demonic Power\" Category enemies' and allies' ATK & DEF +15%; increases damage received by Super Class enemies and allies by 10%, plus an additional 15% for characters who also belong to the \"Earth-Bred Fighters\" Category", 3007, 3], [10, "Cell Games Arena", "\"Tournament Participants\" Category enemies' and allies' ATK & DEF +15%; \"Androids\" or \"Androids/Cell Saga\" Category enemies' and allies' ATK & DEF +15%", 3009, 5], [11, "Earth Shrouded in Minus Energy", "\"Inhuman Deeds\", \"Power Absorption\" or \"GT Bosses\" Category enemies' and allies' ATK +25%; increases damage received by Super Class enemies and allies by 20%, plus an additional 10% for characters who also belong to the \"Earth-Protecting Heroes\", \"Fused Fighters\" or \"GT Heroes\" Category", 3010, 3], [12, "Tree of Might", "\"Space-Traveling Warriors\" or \"Terrifying Conquerors\" Category enemies' and allies' ATK & DEF +15%, plus an additional ATK & DEF +10% for characters who also belong to the \"Planetary Destruction\" Category; increases damage received by Super Class enemies and allies by 10%", 3011, 3], [13, "New Red Ribbon Army's Base (Ruined)", "\"Movie Bosses\" Category enemies' and allies' ATK +60%", 3012, 2]];
  const p = () => state.project;
  const schema = () => state.info.schema;
  // The passive being edited in the Card Builder (its own copy for an EZA step).
  function passiveView() {
    if (UI() && UI().editableSet) UI().editableSet("passive");
    return UI() && UI().target ? UI().target("passive") : p();
  }
  function passiveRows(view = UI() && UI().target ? UI().target("passive") : p()) {
    const set = Forge.primaryPassive(view);
    if (!set) return [];
    const ids = new Set((view.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === set.id).map((r) => r.passive_skill_id));
    return (view.tables.passive_skills || []).filter((r) => ids.has(r.id));
  }
  const decoded = (row) => { try { return B().decodePassive(row); } catch (e) { return null; } };
  const rowsOf = (keys) => passiveRows().filter((r) => { const d = decoded(r); return d && keys.includes(d.key); });
  function done(message) {
    if (UI() && UI().refreshTexts) UI().refreshTexts();
    scheduleSave();
    renderEditor();
    if (message) toast(message + " ↶ Undo takes it back.");
  }
  function closeDialog() { const d = document.getElementById("dialog"); if (d && d.open) d.close(); }
  const card = (icon, title, what, body, actions) => '<article class="sp-card"><div class="sp-head"><span class="sp-icon" aria-hidden="true">' + icon + '</span><div><h3>' + h(title) + '</h3><p>' + h(what) + '</p></div></div><div class="sp-body">' + body + '</div><div class="sp-actions">' + actions + "</div></article>";
  const btn = (label, action, kind = "ghost small") => '<button type="button" class="button ' + kind + '" data-sp="' + h(action) + '">' + h(label) + "</button>";
  const item = (text, actions) => '<div class="sp-item"><span>' + text + '</span><span class="sp-item-actions">' + actions + "</span></div>";
  const empty = (text) => '<p class="sp-empty">' + h(text) + "</p>";
  const plain = (text) => h(String(text || "").replace(/\{passiveImg:[^}]*\}/g, ""));

  // ---------------------------------------------------------------- the step
  function html() {
    const unit = p();
    if (!unit) return "";
    if (unit.awaken) return '<section class="panel"><h2>Special skills</h2><p>EZA projects change an existing card. Use the Leader, Passive and Super Attack steps for its EZA stages.</p></section>';
    const counters = rowsOf(["counter", "dodgeCounter"]), revivals = rowsOf(["revive"]);
    const intro = introRow(), domains = domainList(), standby = standbyInfo(), actives = activeSets();
    const supers = (unit.tables.card_specials || []), styles = { Hyper: "Ultra", Extra: "EX", Condition: "Conditional", FullPower: "Full-power" };
    const forms = window.ForgeForms ? ForgeForms.slots(unit).length : 0;
    return '<section class="panel sp-intro"><h2>Special skills</h2><p class="hint">Extra mechanics that make a unit stand out. Tap <strong>＋ Add</strong> on any of them — every option is explained, and ↶ Undo takes any change back.</p></section><div class="sp-grid">' +
      card("🛡", "Counters", "Hits back when the enemy attacks — like Super Vegito or Super Saiyan 4 Goku.",
        counters.length ? counters.map((r) => item(h(B().cap(B().passiveLine(r))), btn("Edit", "counter-edit:" + r.id) + btn("🎬", "anim:counter:" + r.id, "subtle small") + btn("✕", "passive-del:" + r.id, "subtle small"))).join("") : empty("No counter yet."),
        btn("＋ Add a counter", "counter-add", "button small")) +
      card("✚", "Revival", "Comes back with HP restored when KO'd — like Super Saiyan Gohan (Future).",
        revivals.length ? revivals.map((r) => item(h(B().cap(B().passiveLine(r))), btn("Edit", "revive-edit:" + r.id) + btn("✕", "passive-del:" + r.id, "subtle small"))).join("") : empty("No revival yet."),
        revivals.length ? "" : btn("＋ Add a revival", "revive-add", "button small")) +
      card("🎬", "Intro (entrance scene)", "A short animation when the character first enters battle.",
        intro ? item(h(introName(intro.passive_skill_effect_id)), btn("🎬", "anim:intro:" + intro.id, "subtle small")) : empty("No intro yet."),
        btn(intro ? "Set up the intro" : "＋ Add an intro", "go:intro", intro ? "ghost small" : "button small")) +
      card("⚡", "Active Skill", "A button the player taps once its conditions are met.",
        actives.length ? actives.map((s) => item("<strong>" + h(s.name || "Active Skill") + "</strong><small>" + plain(s.effect_description) + "</small>", "")).join("") : empty("No Active Skill yet."),
        btn(actives.length ? "Edit on the Active Skill step" : "＋ Add on the Active Skill step", "go:active", actives.length ? "ghost small" : "button small")) +
      card("✸", "EX, Ultra & Conditional Super Attacks", "Extra Super Attack types: EX attacks that can trigger on their own, LR Ultra Super Attacks and attacks with activation rules.",
        supers.length ? supers.map((r) => item(h(styles[r.style] || "Super Attack") + " · " + h(((unit.tables.special_sets || []).find((x) => x.id === r.special_set_id) || {}).name || "Super Attack"), "")).join("") : empty("No Super Attacks yet."),
        btn("Change on the Super Attacks step", "go:supers")) +
      card("⟳", "Transformations", "Turns into another form, by turns, conditions, an Active Skill or a Standby Skill.",
        forms ? item(forms + " transformation" + (forms === 1 ? "" : "s"), "") : empty("No transformation yet."),
        btn(forms ? "Edit transformations" : "＋ Add a transformation", "go:transform", forms ? "ghost small" : "button small")) +
      "</div>";
  }

  // ---------------------------------------------------------------- forms for passive-based skills
  function fieldHTML(f, value) {
    if (f.kind === "choice") {
      let options = f.options.slice();
      if (!options.some(([v]) => String(v) === String(value)) && value != null) options = [[value, "Your own (kept)"]].concat(options);
      return '<label class="field">' + h(f.label) + '<select data-spf="' + f.name + '">' + options.map(([v, l]) => '<option value="' + h(v) + '"' + (String(v) === String(value) ? " selected" : "") + ">" + h(l) + "</option>").join("") + "</select></label>";
    }
    return '<label class="field">' + h(f.label) + '<input type="number" inputmode="numeric" data-spf="' + f.name + '" min="' + f.min + '" max="' + f.max + '" value="' + h(value) + '"></label>';
  }
  const HELP = {
    counter: "<ul class=\"sp-help\"><li><strong>What it counters</strong>: normal attacks, Super Attacks (or one kind of them), or any attack.</li><li><strong>Counter damage</strong>: how hard it hits back — Enormous ×2, Tremendous ×3 (most units today), Ferocious ×4.</li><li><strong>Damage reduced</strong>: makes the hit it counters weaker (0 = full damage, 70 = 70% less).</li><li><strong>Chance</strong>: 100% always counters; lower numbers counter sometimes.</li><li><strong>Animation</strong>: borrow a counter scene from a character, or make your own on Portraits &amp; Sprites.</li></ul>",
    dodgeCounter: "<ul class=\"sp-help\"><li>Evades the attack completely, then counters.</li><li><strong>Counter damage</strong>: Enormous ×2, Tremendous ×3, Ferocious ×4.</li></ul>",
    revive: "<ul class=\"sp-help\"><li>When the character is KO'd, it comes back once with this much HP.</li><li><strong>Who revives</strong>: the character itself, or (like Master Roshi) it revives an ally.</li><li><strong>Revival scene</strong>: the short animation that plays.</li></ul>"
  };
  function skillForm(key, row) {
    const def = B().passiveDef(key), d = row ? decoded(row) : null, v = d ? B().normalizeValues(def.fields, d.values) : B().normalizeValues(def.fields, {}), s = row ? B().settingsOf(row) : B().newPassiveSettings(key);
    const who = key === "revive" ? '<label class="field">Who revives<select data-spf="__target"><option value="1"' + (s.target !== 2 ? " selected" : "") + '>This character</option><option value="2"' + (s.target === 2 ? " selected" : "") + ">An ally (like Master Roshi)</option></select></label>" : "";
    dialog((row ? "Edit " : "Add ") + def.label.toLowerCase(), '<div data-no-ai class="ucopy-dialog"></div>' + HELP[key] + '<div class="field-grid sp-form">' + def.fields.map((f) => fieldHTML(f, v[f.name])).join("") + who +
      (key === "revive" ? "" : '<label class="field">Chance (%)<input type="number" min="1" max="100" data-spf="__chance" value="' + h(s.chance || 100) + '"></label>') + "</div>" +
      '<p class="hint">More options (extra conditions, once only…) are on the Passive Skill step.</p><div class="row"><button type="button" class="button" id="sp-save">' + (row ? "Save" : "Add") + '</button><button type="button" class="button ghost" id="sp-cancel">Cancel</button></div>');
    document.getElementById("sp-cancel").onclick = closeDialog;
    document.getElementById("sp-save").onclick = () => {
      try {
        const values = {};
        document.querySelectorAll("[data-spf]").forEach((el) => { values[el.dataset.spf] = Number(el.value); });
        const settings = Object.assign({}, s);
        if (values.__chance) settings.chance = Math.max(1, Math.min(100, values.__chance));
        if (values.__target) settings.target = values.__target;
        if (key === "revive") settings.once = false;
        delete values.__chance; delete values.__target;
        if (row) {
          // picking a game counter animation replaces your own one
          const own = (p().animationAssignments || {})["counter:" + row.id];
          if (own && values.anim !== undefined && Number(values.anim) !== Number(own.scriptNumber)) {
            delete p().animationAssignments["counter:" + row.id];
            p().generatedFiles = (p().generatedFiles || []).filter((f) => f.owner !== "counter:" + row.id);
          }
          B().updatePassiveAbility(row, key, values, settings);
        }
        else { const view = passiveView(); B().addPassiveAbility(view, key, values, settings); }
        closeDialog();
        done(row ? "Saved." : def.label + " added.");
      } catch (e) { toast(e.message || String(e), true); }
    };
  }
  function removePassive(id) {
    const view = UI() && UI().target ? UI().target("passive") : p();
    Forge.removePassive(view, Number(id));
    for (const k of Object.keys(p().animationAssignments || {})) if (k.endsWith(":" + id) && /^(counter|intro):/.test(k)) {
      delete p().animationAssignments[k];
      p().generatedFiles = (p().generatedFiles || []).filter((f) => f.owner !== k);
    }
    done("Removed.");
  }

  // ---------------------------------------------------------------- intro
  const introName = (id) => { const x = INTROS.find(([i]) => Number(i) === Number(id)); return x ? "Intro from " + x[1] : Number(id) < 0 ? "Your own intro animation" : "Intro scene"; };
  function introRow() { return passiveRows().find((r) => Number(r.passive_skill_effect_id)); }
  function introTrigger() {
    // the intro plays when this ability first activates: a start-of-turn, once-only ability
    const view = passiveView(), rows = passiveRows(view);
    const domainRows = new Set((p().tables.dokkan_field_passive_skill_relations || []).map((r) => r.passive_skill_id));
    let row = rows.find((r) => Number(r.efficacy_type) === 0 && Number(r.exec_timing_type) === 1 && !r.causality_conditions && !domainRows.has(r.id));
    if (!row) row = Forge.addPassive(view, { efficacy_type: 0, calc_option: 0, target_type: 1, exec_timing_type: 1, turn: 1, probability: 100, is_once: 1, eff_value1: 0, eff_value2: 0, eff_value3: 0, efficacy_values: "{}", causality_conditions: null });
    return row;
  }
  function pickIntro() {
    dialog("Choose an intro", '<div data-no-ai class="ucopy-dialog"></div><p>Pick the entrance scene of a character from the game. It plays when your character first enters battle. To make your own, use <strong>🎬 Make my own</strong> after adding one.</p><label class="field">Find a character<input id="sp-intro-search" type="search" placeholder="e.g. Gohan"></label><div id="sp-intro-list" class="porg-names"></div><div class="row"><button type="button" class="button ghost" id="sp-cancel">Cancel</button></div>');
    const draw = () => {
      const q = document.getElementById("sp-intro-search").value.trim().toLowerCase();
      const list = INTROS.filter(([, n]) => !q || n.toLowerCase().includes(q)).slice(0, 60);
      const box = document.getElementById("sp-intro-list");
      box.innerHTML = list.map(([id, n]) => '<button type="button" class="porg-name" data-sp-intro="' + id + '"><span><strong>' + h(n) + "</strong><small>Their entrance scene</small></span><b aria-hidden=\"true\">›</b></button>").join("") || "<p>No match.</p>";
      box.querySelectorAll("[data-sp-intro]").forEach((b) => b.onclick = () => {
        try {
          const id = Number(b.dataset.spIntro), view = passiveView();
          for (const r of passiveRows(view)) if (Number(r.passive_skill_effect_id)) r.passive_skill_effect_id = null;
          introTrigger().passive_skill_effect_id = id;
          closeDialog();
          done("Intro added: " + introName(id) + ".");
        } catch (e) { toast(e.message || String(e), true); }
      });
    };
    document.getElementById("sp-intro-search").oninput = draw;
    document.getElementById("sp-cancel").onclick = closeDialog;
    draw();
  }
  function removeIntro() {
    const view = UI() && UI().target ? UI().target("passive") : p();
    for (const r of passiveRows(view)) if (Number(r.passive_skill_effect_id)) {
      r.passive_skill_effect_id = null;
      delete (p().animationAssignments || {})["intro:" + r.id];
      if (Number(r.efficacy_type) === 0 && !(view.tables.dokkan_field_passive_skill_relations || []).some((x) => x.passive_skill_id === r.id)) Forge.removePassive(view, r.id);
    }
    done("Intro removed.");
  }

  // ---------------------------------------------------------------- domains
  const domainInfo = (id) => {
    const local = (p().tables.dokkan_fields || []).find((x) => x.id === Number(id));
    if (local) {
      const turn = ((p().tables.dokkan_field_efficacies || []).find((e) => e.dokkan_field_efficacy_set_id === local.dokkan_field_efficacy_set_id && Number(e.efficacy_type) === 121) || {}).turn;
      return { name: local.name, description: local.description, turns: turn || 3, local };
    }
    const g = DOMAINS.find(([i]) => i === Number(id));
    return g ? { name: g[1], description: g[2], turns: g[4], resource: g[3] } : { name: "Domain", description: "", turns: 3 };
  };
  function domainList() {
    const unit = p(), out = [];
    const mine = new Set(passiveRows().map((r) => r.id));
    for (const r of (unit.tables.dokkan_field_passive_skill_relations || []).filter((x) => mine.has(x.passive_skill_id))) out.push(Object.assign({ rel: { table: "passive", id: r.id }, when: "Starts by itself" }, domainInfo(r.dokkan_field_id)));
    for (const r of unit.tables.dokkan_field_active_skill_set_relations || []) out.push(Object.assign({ rel: { table: "active", id: r.id }, when: "With the Active Skill" }, domainInfo(r.dokkan_field_id)));
    return out;
  }
  function activeSets() {
    const ids = new Set((p().tables.card_active_skills || []).map((r) => r.active_skill_set_id));
    return (p().tables.active_skill_sets || []).filter((s) => ids.has(s.id));
  }
  function addDomain() {
    const hasActive = activeSets().length > 0;
    dialog("Add a Domain", '<div data-no-ai class="ucopy-dialog"></div><p>Choose a Domain from the game. You can rename it and change its numbers afterwards with <strong>Customize</strong>.</p>' +
      '<div class="sp-domains">' + DOMAINS.map(([id, name, desc, , turns]) => '<label class="porg-row sp-domain"><input type="radio" name="sp-domain" value="' + id + '"' + (id === 7 ? " checked" : "") + '><span><strong>' + h(name) + "</strong><small>" + h(desc) + " · " + turns + " turns</small></span></label>").join("") + "</div>" +
      '<h3>When does it appear?</h3><div class="sp-when">' + (hasActive ? '<label class="porg-row"><input type="radio" name="sp-when" value="active" checked><span><strong>When my Active Skill is used</strong><small>Like Legendary Super Saiyan Broly.</small></span></label>' : "") +
      '<label class="porg-row"><input type="radio" name="sp-when" value="turn"' + (hasActive ? "" : " checked") + '><span><strong>By itself, from a turn after the character enters</strong><small>Like Super Saiyan Gohan (Future).</small></span></label><label class="field">From turn<input type="number" id="sp-domain-turn" min="1" max="20" value="3"></label></div>' +
      '<div class="row"><button type="button" class="button" id="sp-save">Add Domain</button><button type="button" class="button ghost" id="sp-cancel">Cancel</button></div>');
    document.getElementById("sp-cancel").onclick = closeDialog;
    document.getElementById("sp-save").onclick = () => {
      try {
        const id = Number((document.querySelector('input[name="sp-domain"]:checked') || {}).value), when = (document.querySelector('input[name="sp-when"]:checked') || {}).value, unit = p(), sc = schema();
        if (!id) throw Error("Choose a Domain.");
        if (when === "active") {
          G().ensure(unit, sc, "dokkan_field_active_skill_set_relations");
          unit.tables.dokkan_field_active_skill_set_relations.push(Object.assign(Forge.rowDefault(unit.schema.dokkan_field_active_skill_set_relations), { id: Forge.localId(unit, "dokkan_field_active_skill_set_relations"), dokkan_field_id: id, active_skill_set_id: activeSets()[0].id }));
        } else {
          const view = passiveView(), turn = Math.max(1, Math.min(20, Number(document.getElementById("sp-domain-turn").value) || 3));
          const row = Forge.addPassive(view, { efficacy_type: 0, calc_option: 0, target_type: 1, exec_timing_type: 1, turn: 1, probability: 100, is_once: 1, eff_value1: 0, eff_value2: 0, eff_value3: 0, efficacy_values: "{}", causality_conditions: null });
          B().applyCondition(view, sc, row, { mode: "all", items: [{ key: "entryTurn", values: { turn } }] });
          G().ensure(unit, sc, "dokkan_field_passive_skill_relations");
          unit.tables.dokkan_field_passive_skill_relations.push(Object.assign(Forge.rowDefault(unit.schema.dokkan_field_passive_skill_relations), { id: Forge.localId(unit, "dokkan_field_passive_skill_relations"), dokkan_field_id: id, passive_skill_id: row.id }));
        }
        closeDialog();
        done("Domain added: " + domainInfo(id).name + ".");
      } catch (e) { toast(e.message || String(e), true); }
    };
  }
  function relRow(kind, id) {
    const table = kind === "active" ? "dokkan_field_active_skill_set_relations" : "dokkan_field_passive_skill_relations";
    return { table, row: (p().tables[table] || []).find((r) => r.id === Number(id)) };
  }
  function removeDomain(kind, id) {
    const unit = p(), { table, row } = relRow(kind, id);
    if (!row) return;
    unit.tables[table] = unit.tables[table].filter((r) => r !== row);
    if (kind === "passive") {
      const trigger = (unit.tables.passive_skills || []).find((r) => r.id === row.passive_skill_id);
      if (trigger && Number(trigger.efficacy_type) === 0 && !Number(trigger.passive_skill_effect_id)) Forge.removePassive(UI() && UI().target ? UI().target("passive") : unit, trigger.id);
    }
    const local = (unit.tables.dokkan_fields || []).find((x) => x.id === row.dokkan_field_id);
    if (local && !(unit.tables.dokkan_field_active_skill_set_relations || []).concat(unit.tables.dokkan_field_passive_skill_relations || []).some((r) => r.dokkan_field_id === local.id)) {
      unit.tables.dokkan_fields = unit.tables.dokkan_fields.filter((x) => x !== local);
      unit.tables.dokkan_field_efficacies = (unit.tables.dokkan_field_efficacies || []).filter((e) => e.dokkan_field_efficacy_set_id !== local.dokkan_field_efficacy_set_id);
      unit.tables.dokkan_field_efficacy_sets = (unit.tables.dokkan_field_efficacy_sets || []).filter((e) => e.id !== local.dokkan_field_efficacy_set_id);
    }
    if (B().pruneCausalities) B().pruneCausalities(unit);
    done("Domain removed.");
  }
  // Customize: the Domain becomes this unit's own copy (name, text, background, turns, numbers).
  async function ownDomain(id) {
    const unit = p(), sc = schema();
    const local = (unit.tables.dokkan_fields || []).find((x) => x.id === id);
    if (local) return local;
    const q = (o) => Native.call("query", o);
    const field = (await q({ table: "dokkan_fields", ids: [id], limit: 1 }))[0];
    if (!field) throw Error("That Domain is not in the game data.");
    const effects = await q({ table: "dokkan_field_efficacies", filters: { dokkan_field_efficacy_set_id: field.dokkan_field_efficacy_set_id }, limit: 100 });
    for (const t of ["dokkan_field_efficacy_sets", "dokkan_fields", "dokkan_field_efficacies"]) G().ensure(unit, sc, t);
    const set = Object.assign(Forge.rowDefault(unit.schema.dokkan_field_efficacy_sets), { id: Forge.localId(unit, "dokkan_field_efficacy_sets") });
    unit.tables.dokkan_field_efficacy_sets.push(set);
    const own = Object.assign(Forge.clone(field), { id: Forge.localId(unit, "dokkan_fields"), dokkan_field_efficacy_set_id: set.id });
    unit.tables.dokkan_fields.push(own);
    for (const e of effects) unit.tables.dokkan_field_efficacies.push(Object.assign(Forge.clone(e), { id: Forge.localId(unit, "dokkan_field_efficacies"), dokkan_field_efficacy_set_id: set.id }));
    for (const r of (unit.tables.dokkan_field_active_skill_set_relations || []).concat(unit.tables.dokkan_field_passive_skill_relations || [])) if (r.dokkan_field_id === id) r.dokkan_field_id = own.id;
    return own;
  }
  const EFFECT_LABEL = { 1: "ATK +%", 2: "DEF +%", 3: "ATK & DEF +%", 122: "Damage received +%" };
  async function editDomain(kind, relId) {
    const { row } = relRow(kind, relId);
    if (!row) return;
    const info = domainInfo(row.dokkan_field_id), game = DOMAINS.find(([i]) => i === Number(row.dokkan_field_id));
    let effects = [];
    if (info.local) effects = (p().tables.dokkan_field_efficacies || []).filter((e) => e.dokkan_field_efficacy_set_id === info.local.dokkan_field_efficacy_set_id);
    else effects = await Native.call("query", { table: "dokkan_field_efficacies", filters: { dokkan_field_efficacy_set_id: (await Native.call("query", { table: "dokkan_fields", ids: [row.dokkan_field_id], limit: 1 }))[0].dokkan_field_efficacy_set_id }, limit: 100 });
    // the game lists each effect twice (when the Domain starts and every turn): edit them together
    const groups = [], seen = new Map();
    for (const e of effects) {
      if (!EFFECT_LABEL[e.efficacy_type]) continue;
      const k = e.efficacy_type + "|" + (e.causality_conditions || "");
      if (!seen.has(k)) { seen.set(k, groups.length); groups.push({ key: k, type: Number(e.efficacy_type), value: Number(e.eff_value1) }); }
    }
    const bg = info.local ? info.local.resource_id : game ? game[3] : 3006;
    dialog("Customize Domain", '<div data-no-ai class="ucopy-dialog"></div><p>These changes make this Domain your unit\'s own copy; the game\'s Domain is untouched.</p><div class="field-grid"><label class="field">Name<input id="sp-dn" maxlength="60" value="' + h(info.name) + '"></label><label class="field">How many turns it lasts<input id="sp-dt" type="number" min="1" max="20" value="' + h(info.turns) + '"></label><label class="field full">What it does (the text players see)<textarea id="sp-dd" rows="4">' + h(info.description) + '</textarea></label><label class="field">Background<select id="sp-db">' + DOMAINS.map(([, n, , r]) => '<option value="' + r + '"' + (Number(r) === Number(bg) ? " selected" : "") + ">" + h(n) + "</option>").join("") + "</select></label></div>" +
      (groups.length ? "<h3>Numbers</h3><p class=\"hint\">Each line keeps the game's rule for who it affects (for example Super Class or a Category).</p><div class=\"field-grid\">" + groups.map((g, i) => '<label class="field">' + h(EFFECT_LABEL[g.type]) + " · effect " + (i + 1) + '<input type="number" min="0" max="300" data-sp-eff="' + i + '" value="' + h(g.value) + '"></label>').join("") + "</div>" : "") +
      '<div class="row"><button type="button" class="button" id="sp-save">Save</button><button type="button" class="button ghost" id="sp-cancel">Cancel</button></div>');
    document.getElementById("sp-cancel").onclick = closeDialog;
    document.getElementById("sp-save").onclick = async () => {
      try {
        const own = await ownDomain(row.dokkan_field_id), unit = p();
        own.name = document.getElementById("sp-dn").value.trim() || own.name;
        own.description = document.getElementById("sp-dd").value;
        own.resource_id = Number(document.getElementById("sp-db").value) || own.resource_id;
        const turns = Math.max(1, Math.min(20, Number(document.getElementById("sp-dt").value) || 3));
        const mine = (unit.tables.dokkan_field_efficacies || []).filter((e) => e.dokkan_field_efficacy_set_id === own.dokkan_field_efficacy_set_id);
        for (const e of mine) if (Number(e.efficacy_type) === 121) e.turn = turns;
        document.querySelectorAll("[data-sp-eff]").forEach((el) => {
          const g = groups[Number(el.dataset.spEff)], v = Math.max(0, Math.min(300, Number(el.value) || 0));
          for (const e of mine) if (e.efficacy_type + "|" + (e.causality_conditions || "") === g.key) { e.eff_value1 = v; if (g.type === 3) e.eff_value2 = v; }
        });
        closeDialog();
        done("Domain saved.");
      } catch (e) { toast(e.message || String(e), true); }
    };
  }

  // ---------------------------------------------------------------- standby & finish
  function standbyInfo() {
    const unit = p(), rel = (unit.tables.card_standby_skill_set_relations || [])[0];
    if (!rel) return null;
    const set = (unit.tables.standby_skill_sets || []).find((s) => s.id === rel.standby_skill_set_id);
    if (!set) return null;
    const rows = (unit.tables.standby_skills || []).filter((r) => r.standby_skill_set_id === set.id);
    const charge = rows.find((r) => Number(r.efficacy_type) === 115);
    const finishIds = (unit.tables.standby_skill_set_finish_skill_set_relations || []).filter((r) => r.standby_skill_set_id === set.id).map((r) => r.finish_skill_set_id);
    const finishes = (unit.tables.finish_skill_sets || []).filter((f) => finishIds.includes(f.id));
    return { rel, set, rows, charge, turns: charge ? Number(charge.turn) : 0, finishes };
  }
  async function addStandby() {
    let list = [];
    await busy("Finding characters with a Standby Skill", async () => {
      const rels = await Native.call("query", { table: "card_standby_skill_set_relations", limit: 5000 });
      const ids = [...new Set(rels.map((r) => Number(r.card_id)).filter((id) => id >= 1000000 && id < 2000000))];
      const cards = ids.length ? await Native.call("query", { table: "cards", ids: ids.slice(0, 1000), limit: 1000 }) : [];
      const seen = new Set();
      list = cards.filter((c) => !seen.has(c.name + c.rarity) && seen.add(c.name + c.rarity)).sort((a, b) => b.id - a.id);
    });
    dialog("Copy a Standby Skill", '<div data-no-ai class="ucopy-dialog"></div><p>Pick a character. Their Standby Skill and finishing attacks are copied onto your unit; your other skills stay the same.</p><div class="porg-names">' + list.map((c) => '<button type="button" class="porg-name" data-sp-sb="' + c.id + '"><img loading="lazy" alt="" src="' + h(typeof thumb === "function" ? thumb(c) : "") + '"><span><strong>' + h(c.name) + "</strong><small>" + h((Forge.rarities[c.rarity] || "") + " " + (Forge.elements[c.element] || "")) + "</small></span><b aria-hidden=\"true\">›</b></button>").join("") + '</div><div class="row"><button type="button" class="button ghost" id="sp-cancel">Cancel</button></div>');
    document.getElementById("sp-cancel").onclick = closeDialog;
    document.querySelectorAll("[data-sp-sb]").forEach((b) => b.onclick = async () => {
      closeDialog();
      const c = list.find((x) => Number(x.id) === Number(b.dataset.spSb)), unit = p();
      let result = null;
      await busy("Copying " + c.name + "'s Standby Skill", async () => {
        const d = await ForgeUnitCopy.gameDonor(c);
        result = ForgeUnitCopy.build(d, new Set(["standby"]), {});
      });
      if (!result || state.project !== unit) return;
      for (const k of Object.keys(unit)) if (!(k in result.work)) delete unit[k];
      Object.assign(unit, result.work);
      done("Standby Skill copied from " + c.name + ".");
    });
  }
  function editStandby() {
    const s = standbyInfo();
    if (!s) return;
    const fin = s.finishes;
    dialog("Edit Standby Skill", '<div data-no-ai class="ucopy-dialog"></div><div class="field-grid"><label class="field">Standby Skill name<span class="dice-wrap"><input id="sp-sn" maxlength="60" value="' + h(s.set.name || "") + '"><button type="button" class="dice-button" data-sp-dice="sp-sn:standby" aria-label="Random name">🎲</button></span></label>' +
      (s.charge ? '<label class="field">Stands by for (turns)<input id="sp-st" type="number" min="1" max="10" value="' + h(s.turns) + '"></label>' : "") +
      '<label class="field full">What it does<textarea id="sp-se" rows="3">' + h(s.set.effect_description || "") + '</textarea></label><label class="field full">When it can be used<textarea id="sp-sc" rows="2">' + h(s.set.condition_description || "") + "</textarea></label></div>" +
      (fin.length ? "<h3>Finishing attacks</h3>" + fin.map((f, i) => '<div class="field-grid"><label class="field">Name<span class="dice-wrap"><input data-sp-fn="' + f.id + '" id="sp-fn' + i + '" maxlength="60" value="' + h(f.name || "") + '"><button type="button" class="dice-button" data-sp-dice="sp-fn' + i + ':finish" aria-label="Random name">🎲</button></span></label><label class="field full">What it does<textarea data-sp-fe="' + f.id + '" rows="2">' + h(f.effect_description || "") + "</textarea></label></div>").join("") +
        '<p class="hint">The finishing attacks belong to the form your unit turns into while standing by. To change their damage, make that form your own under Transformations on the Passive Skill step.</p>' : "") +
      '<div class="row"><button type="button" class="button" id="sp-save">Save</button><button type="button" class="button ghost" id="sp-cancel">Cancel</button></div>');
    document.querySelectorAll("[data-sp-dice]").forEach((b) => b.onclick = () => { const [id, kind] = b.dataset.spDice.split(":"); document.getElementById(id).value = ForgeSkillNames.random(kind); });
    document.getElementById("sp-cancel").onclick = closeDialog;
    document.getElementById("sp-save").onclick = () => {
      s.set.name = document.getElementById("sp-sn").value.trim() || s.set.name;
      s.set.effect_description = document.getElementById("sp-se").value;
      s.set.condition_description = document.getElementById("sp-sc").value;
      const t = document.getElementById("sp-st");
      if (t && s.charge) s.charge.turn = Math.max(1, Math.min(10, Number(t.value) || s.turns));
      document.querySelectorAll("[data-sp-fn]").forEach((el) => { const f = fin.find((x) => x.id === Number(el.dataset.spFn)); if (f) f.name = el.value.trim() || f.name; });
      document.querySelectorAll("[data-sp-fe]").forEach((el) => { const f = fin.find((x) => x.id === Number(el.dataset.spFe)); if (f) f.effect_description = el.value; });
      closeDialog();
      done("Standby Skill saved.");
    };
  }
  function removeStandby() {
    const unit = p(), s = standbyInfo();
    if (!s) return;
    const finIds = s.finishes.map((f) => f.id);
    // its transformation (the form it stands by in): descriptions, links and own forms go too
    for (const r of s.rows.filter((x) => Number(x.efficacy_type) === 103)) {
      if (unit.tables.transformation_descriptions) unit.tables.transformation_descriptions = unit.tables.transformation_descriptions.filter((d) => !(d.skill_type === "StandbySkill" && d.skill_id === r.id));
      if (unit.transformLinks) unit.transformLinks = unit.transformLinks.filter((l) => !(l.table === "standby_skills" && l.row === r.id));
      if (B().dropAnimation) B().dropAnimation(unit, "transform:standby_skills:" + r.id, "standby_skills", r.id);
    }
    unit.tables.card_standby_skill_set_relations = (unit.tables.card_standby_skill_set_relations || []).filter((r) => r !== s.rel);
    unit.tables.standby_skills = (unit.tables.standby_skills || []).filter((r) => r.standby_skill_set_id !== s.set.id);
    unit.tables.standby_skill_sets = (unit.tables.standby_skill_sets || []).filter((x) => x !== s.set);
    unit.tables.standby_skill_set_finish_skill_set_relations = (unit.tables.standby_skill_set_finish_skill_set_relations || []).filter((r) => r.standby_skill_set_id !== s.set.id);
    const specials = new Set(s.finishes.map((f) => f.finish_special_id));
    unit.tables.card_finish_skill_set_relations = (unit.tables.card_finish_skill_set_relations || []).filter((r) => !finIds.includes(r.finish_skill_set_id));
    unit.tables.finish_skills = (unit.tables.finish_skills || []).filter((r) => !finIds.includes(r.finish_skill_set_id));
    unit.tables.finish_skill_sets = (unit.tables.finish_skill_sets || []).filter((f) => !finIds.includes(f.id));
    unit.tables.finish_specials = (unit.tables.finish_specials || []).filter((x) => !specials.has(x.id) || (unit.tables.finish_skill_sets || []).some((f) => f.finish_special_id === x.id));
    for (const k of Object.keys(unit.animationAssignments || {})) if (k === "standby:" + s.set.id || finIds.some((id) => k === "finish:" + id)) delete unit.animationAssignments[k];
    if (unit.formProjects && window.ForgeForms && ForgeForms.prune) ForgeForms.prune(unit);
    if (unit.transformLinks && !unit.transformLinks.length) delete unit.transformLinks;
    if (B().pruneCausalities) B().pruneCausalities(unit);
    done("Standby Skill removed.");
  }

  // ---------------------------------------------------------------- actions
  async function action(name) {
    const [verb, ...rest] = name.split(":"), arg = rest.join(":");
    try {
      if (verb === "counter-add") return skillForm("counter");
      if (verb === "counter-edit") { const r = passiveRows().find((x) => x.id === Number(arg)), d = r && decoded(r); return r && skillForm(d ? d.key : "counter", r); }
      if (verb === "revive-add") return skillForm("revive");
      if (verb === "revive-edit") return skillForm("revive", passiveRows().find((x) => x.id === Number(arg)));
      if (verb === "passive-del") return removePassive(arg);
      if (verb === "intro-pick") return pickIntro();
      if (verb === "intro-del") return removeIntro();
      if (verb === "domain-add") return addDomain();
      if (verb === "domain-edit") { const [k, id] = arg.split(":"); return await editDomain(k, id); }
      if (verb === "domain-del") { const [k, id] = arg.split(":"); return removeDomain(k, id); }
      if (verb === "standby-add") return await addStandby();
      if (verb === "standby-edit") return editStandby();
      if (verb === "standby-del") return removeStandby();
      if (verb === "go") return UI() && UI().tab ? UI().tab(arg) : null;
      if (verb === "anim") {
        if (UI() && UI().tab) UI().tab("look");
        setTimeout(() => {
          const b = document.querySelector('[data-guide="pick-animation:' + arg + '"]');
          if (b) { b.scrollIntoView({ block: "center" }); b.click(); }
          else toast("Find it under Animations on this step and tap Change….");
        }, 400);
      }
    } catch (e) { toast(e.message || String(e), true); }
  }
  document.addEventListener("click", (ev) => {
    const b = ev.target.closest("[data-sp]");
    if (!b || !document.getElementById("bld")) return;
    ev.preventDefault();
    action(b.dataset.sp);
  });

  // ---------------------------------------------------------------- their own steps: Standby & Finish, Domain
  function stepHTML(title, hintText, body) {
    const unit = p();
    if (!unit) return "";
    if (unit.awaken) return '<section class="panel"><h2>' + h(title) + '</h2><p>EZA projects change an existing card. Use the Leader, Passive and Super Attack steps for its EZA stages.</p></section>';
    return '<section class="panel sp-intro"><h2>' + h(title) + '</h2><p class="hint">' + h(hintText) + '</p></section><div class="sp-grid">' + body + "</div>";
  }
  function standbyHTML() {
    const standby = standbyInfo();
    return stepHTML("Standby Skill & Finish Skill", "The character stands by and charges for several turns, then unleashes a Finish Skill.",
      card("⏳", "Standby & Finish Skill", "Stands by and charges for several turns, then unleashes a finishing attack — like Babidi or Goku & Vegeta (Angel).",
        standby ? item("<strong>" + h(standby.set.name || "Standby Skill") + "</strong><small>" + h(standby.turns ? "Charges for " + standby.turns + " turns" : "") + (standby.finishes.length ? " · then: " + h(standby.finishes.map((f) => f.name).filter(Boolean).join(" or ")) : "") + "</small>", btn("Edit", "standby-edit") + btn("🎬", "anim:standby:" + standby.set.id, "subtle small") + btn("✕", "standby-del", "subtle small")) : empty("No Standby Skill yet."),
        standby ? "" : btn("＋ Copy a Standby Skill from a character", "standby-add", "button small")));
  }
  function domainHTML() {
    const domains = domainList();
    return stepHTML("Domain", "Creates a Domain that changes the battlefield for a few turns.",
      card("🌐", "Domain", "Changes the battlefield for a few turns: boosts some characters and weakens others.",
        domains.length ? domains.map((d) => item("<strong>" + h(d.name) + "</strong><small>" + h(d.when) + " · " + h(d.turns) + " turns</small>", btn("Customize", "domain-edit:" + d.rel.table + ":" + d.rel.id) + btn("✕", "domain-del:" + d.rel.table + ":" + d.rel.id, "subtle small"))).join("") : empty("No Domain yet."),
        domains.length ? "" : btn("＋ Add a Domain", "domain-add", "button small")));
  }
  const status = () => { const unit = p(); return !!unit && (rowsOf(["counter", "dodgeCounter", "revive"]).length > 0 || !!introRow() || domainList().length > 0 || !!standbyInfo()); };
  const standbyStatus = () => !!p() && !!standbyInfo(), domainStatus = () => !!p() && domainList().length > 0;
  return { html, standbyHTML, domainHTML, standbyStatus, domainStatus, status, action, INTROS, DOMAINS };
})();
