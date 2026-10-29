"use strict";
(() => {
  var _a;
  const G = ForgeGuide, D = window.FORGE_GUIDE_DATA || {}, original = { stepHTML, renderEditor, renderHome, renderSource, searchSources, createUnit, bindDynamic, action, updateBinding, navigate, updateNav, scheduleSave, renderLibraryResults, showPatch };
  state.expert = localStorage.getItem("forge-expert") === "true";
  state.conditionRows = [];
  const originalSelect = select;
  select = function(...args) {
    const html = originalSelect(...args);
    return state.expert ? html : html.replace(/Inherited value [^<]*</g, "Keep inherited setting<");
  };
  const button = (label, actionName, style = "ghost") => '<button class="button ' + style + '" data-guide="' + actionName + '">' + esc(label) + "</button>";
  const hint = (text) => '<p class="hint">' + esc(text) + "</p>";
  const panel = (title, text, body) => '<section class="panel"><h2>' + esc(title) + "</h2>" + hint(text) + body + "</section>";
  const error = (e) => toast(e.message || String(e), true);
  let historyKey = "", past = [], future = [], last = "", recording = true, snapTimer = 0;
  function resetHistory() {
    var _a2;
    clearTimeout(snapTimer);
    snapTimer = 0;
    historyKey = ((_a2 = state.project) == null ? void 0 : _a2.key) || "";
    past = [];
    future = [];
    last = state.project ? JSON.stringify(state.project) : "";
  }
  // Undo snapshots serialize the whole unit. Taking one on every keystroke made typing lag on
  // big units, so a burst of edits is captured once, shortly after the user pauses.
  function commitSnapshot() {
    clearTimeout(snapTimer);
    snapTimer = 0;
    if (!state.project) return;
    if (historyKey !== state.project.key) return resetHistory();
    const next = JSON.stringify(state.project);
    if (last && next !== last) {
      past.push(last);
      while (past.length > 12 || past.length > 1 && past.reduce((n, s) => n + s.length, 0) > 8 * 1024 * 1024) past.shift();
      future = [];
      last = next;
    }
  }
  scheduleSave = function() {
    if (state.project && recording) {
      if (historyKey !== state.project.key) resetHistory();
      else {
        clearTimeout(snapTimer);
        snapTimer = setTimeout(commitSnapshot, 400);
      }
    }
    original.scheduleSave();
  };
  function undo(redo = false) {
    if (snapTimer) commitSnapshot();
    const stack = redo ? future : past;
    if (!stack.length) return toast(redo ? "Nothing to redo yet." : "Nothing to undo yet.");
    const value = stack.pop();
    (redo ? past : future).push(JSON.stringify(state.project));
    state.project = JSON.parse(value);
    last = value;
    recording = false;
    scheduleSave();
    recording = true;
    if (state.view === "animations") return renderStudio();
    renderEditor();
  }
  const sourceName = () => {
    var _a2;
    return ((_a2 = state.project) == null ? void 0 : _a2.source.name) || "your source character";
  };
  function currentAbilityStage() {
    var _a2, _b;
    if (state.abilityStageProject !== ((_a2 = state.project) == null ? void 0 : _a2.key)) {
      state.abilityStageProject = (_b = state.project) == null ? void 0 : _b.key;
      state.abilityStage = "base";
    }
    if (!G.abilityStages(state.project).some((stage) => stage.id === state.abilityStage)) state.abilityStage = "base";
    return state.abilityStage;
  }
  function selectedAbility(kind) {
    return G.stageSet(state.project, currentAbilityStage(), kind);
  }
  function editAbility(kind, operation) {
    return G.editStage(state.project, currentAbilityStage(), kind, operation);
  }
  function stageSelector() {
    const stages = G.abilityStages(state.project);
    if (stages.length < 2) return "";
    return '<section class="panel"><h2>Choose the awakening stage</h2><label class="field">Editing abilities for<select id="ability-stage">' + selection(stages.map((stage) => [stage.id, stage.label]), currentAbilityStage()) + "</select><small>Changes apply only to this stage. Other stages keep their own leader skills and passive abilities.</small></label></section>";
  }
  function leaderCategoryOptions(query) {
    const rows = state.categories.filter((row) => row.name !== "0" && row.name.toLocaleLowerCase().includes(query.toLocaleLowerCase())).sort((a, b) => a.name.localeCompare(b.name));
    return rows.length ? selection(rows.map((row) => [row.id, row.name]), state.leaderDraftCategory || rows[0].id) : '<option value="">No matching categories</option>';
  }
  function readableAbilityDescription(text) {
    return String(text || "").replace(/\{passiveImg:[A-Za-z0-9_]+\}/g, "").replace(/^\*([^*\n]+)\*$/gm, "$1");
  }
  function effectHTMLSimple(row) {
    var _a2;
    const known = [1,2,3,4,5,9,13,16,17,18,20,48,50,51,59,60,61,64,65,66,76,78,79,81,86,90,91,97,103,119,120,128].includes(row.efficacy_type), defs = state.mechanics.efficacies || [], name = G.effectNames[row.efficacy_type] || ((_a2 = defs.find((d) => d.id === row.efficacy_type)) == null ? void 0 : _a2.name) || "Inherited effect";
    let controls = "";
    if ([1, 2, 3, 4, 5, 13, 86, 90, 91].includes(row.efficacy_type)) {
      const percent = [13, 90, 91].includes(row.efficacy_type) || [2, 3].includes(row.calc_option) && row.efficacy_type !== 5;
      const limited = [13, 90, 91].includes(row.efficacy_type) || row.efficacy_type === 4 && percent;
      controls += '<div class="field-grid">' + simpleValue(row, "eff_value1", row.efficacy_type === 13 ? "Damage blocked (%)" : row.efficacy_type === 3 ? "ATK bonus (%)" : row.efficacy_type === 5 ? "Ki gained" : name + (percent ? " (%)" : ""), row.efficacy_type === 13 ? 100 - row.eff_value1 : row.eff_value1, percent ? "0" : "-24", limited ? "100" : percent ? "1000" : row.efficacy_type === 5 ? "24" : "1000000") + (row.efficacy_type === 3 ? simpleValue(row, "eff_value2", "DEF bonus" + (percent ? " (%)" : ""), row.eff_value2, percent ? "-100" : "-1000000", percent ? "1000" : "1000000") : "") + "</div>";
    }
  if(row.efficacy_type===50)controls+=hint('Uses the game’s broad status-effect protection. Its activation chance, duration and conditions are set below. Individual immunity profiles stay inherited.');if(row.efficacy_type===76)controls+=hint('Uses the game’s attacks-effective-against-all-Types effect while active. Choose its activation chance, duration and conditions below.');
  if(G.colorSphereKinds.some(([id])=>id===row.efficacy_type))controls+=G.canEditColorSphereBonus(row)?'<div class="field-grid"><label class="field">Matching character type and Ki Sphere color<select data-guide-color-sphere="'+row.id+':color">'+selection(G.colorSphereOptions(row.efficacy_type),row.eff_value1)+'</select></label><label class="field">'+esc(G.colorSphereKinds.find(([id])=>id===row.efficacy_type)[1])+' bonus per matching sphere (%)<input data-guide-color-sphere="'+row.id+':amount" type="number" min="0" max="1000" step="1" value="'+esc(row.eff_value2)+'"></label></div>'+hint('Only characters of the chosen type receive this bonus, and only matching-color Ki Spheres count. Combined ATK & DEF uses the same amount for both. Only source-supported combinations are offered.'):hint('This inherited color-filtered bonus uses a specialized profile. All source values are kept; copy a complete passive to replace its settings.');
  if(G.sphereBonusKinds.some(([id])=>id===row.efficacy_type)){const percentage=[2,3].includes(row.calc_option),max=percentage?1000:1000000;controls+='<div class="field-grid">'+[['eff_value1',row.efficacy_type===60?'DEF':'ATK'],...(row.efficacy_type===61?[['eff_value2','DEF']]:[])].map(([key,label])=>'<label class="field">'+label+' bonus per Ki Sphere'+(percentage?' (%)':'')+'<input data-guide-sphere-bonus="'+row.id+':'+key+'" type="number" min="0" max="'+max+'" step="1" value="'+esc(row[key])+'"></label>').join('')+'</div>'+hint('Scales with Ki Spheres obtained when this effect activates. This does not change sphere colors or Ki gained.');}
  if(G.typeSupportKinds.some(([id])=>id===row.efficacy_type)){const percentage=[2,3].includes(row.calc_option),max=row.efficacy_type===20?24:percentage?1000:1000000;controls+='<div class="field-grid"><label class="field">Affected character type<select data-guide-support="'+row.id+':eff_value1">'+selection((Number.isInteger(row.eff_value1)&&row.eff_value1>=0&&row.eff_value1<5?[]:[[row.eff_value1,'Keep inherited type setting']]).concat(G.sphereTypes.slice(0,5).map((name,index)=>[index,name])),row.eff_value1)+'</select></label>'+[['eff_value2',row.efficacy_type===18?'ATK bonus':G.typeSupportKinds.find(([id])=>id===row.efficacy_type)[1]+' bonus'],...(row.efficacy_type===18?[['eff_value3','DEF bonus']]:[])].map(([key,label])=>'<label class="field">'+label+(percentage?' (%)':'')+'<input data-guide-support="'+row.id+':'+key+'" type="number" min="0" max="'+max+'" step="1" value="'+esc(row[key])+'"></label>').join('')+'</div>'+hint('The bonus applies only to the selected type among the recipients selected under “Who it affects”. Activation conditions and timing are kept.');}
    if ([1,2,3,4,16,17,18,59,60,61,86].includes(row.efficacy_type)) controls += '<div class="field-grid">' + select("How the amount works", tableBind("passive_skills", row, "calc_option"), row.calc_option, [[2, "Increase by a percentage"], [3, "Reduce by a percentage"], [0, "Add a fixed amount"], [1, "Subtract a fixed amount"], [4, "Set to an exact amount"]]) + "</div>";
    if (row.efficacy_type === 79) controls += hint("Keeps the source character’s giant-form rules. Start from a character with the form you want, then choose its entry, turn, and exit animations in the animation editor.");
    if ([97, 119].includes(row.efficacy_type)) controls += hint("Keeps the source character’s attack filters and absorption or nullification settings. Choose its animation in the animation editor; copy a complete passive to use another character’s gameplay rules.");
    if (row.efficacy_type === 103) controls += hint("The source’s transformation profile is kept. Choose the form by name; use an existing transformation template for matching entry/exit rules.") + button("Choose transformed character", "form:" + row.id);
  if(row.efficacy_type===51&&[row.eff_value1,row.eff_value2].every(value=>Number.isInteger(value)&&value>=0&&value<G.sphereTypes.length))controls+='<div class="field-grid">'+[['eff_value1','Change this color'],['eff_value2','Into this color']].map(([key,label])=>'<label class="field">'+label+'<select data-guide-sphere="'+row.id+':'+key+'">'+selection(G.sphereTypes.map((name,index)=>[index,name]),row[key])+'</select></label>').join('')+'</div>'+hint('Changes matching Ki Spheres when this effect activates. Conditions, chance, and timing below still apply.');else if(row.efficacy_type===51)controls+=hint('This inherited conversion uses a special color setting. It stays unchanged; copy a complete passive to replace its profile.');
    if ([81, 120, 128].includes(row.efficacy_type)) controls += hint("This effect keeps a complete game-tested source profile. Copy another character’s passive to change the underlying behavior. Its animation can be chosen in the animation editor.");
    return '<article class="effect-card"><div class="effect-heading"><h3>' + esc(known ? G.effectSummary(row) : name) + '</h3><button class="icon-button" data-remove-effect="' + row.id + '" aria-label="Remove ' + esc(name) + '">×</button></div>' + (!known ? hint("This is an inherited effect with specialized settings. The app keeps it intact. You can replace it with a guided effect or edit it in Expert mode.") : "") + '<div class="field-grid">' + select("What it does", tableBind("passive_skills", row, "efficacy_type"), row.efficacy_type, defs.filter((r) => [1, 2, 3, 4, 5, 9, 13, 48, 78, 86, 90, 91].includes(r.id) || r.id === row.efficacy_type).map((r) => [r.id, G.effectNames[r.id] || r.name])) + select("Who it affects", tableBind("passive_skills", row, "target_type"), row.target_type, mechanics("target-types").filter((r) => r[0] !== 5 && (![50,76].includes(row.efficacy_type) || [1,2].includes(r[0]))).map((r) => row.sub_target_type_set_id && r[0] === row.target_type ? [r[0], r[1] + " · source-restricted group"] : r).concat(row.sub_target_type_set_id ? [[-20, "All allies · remove source restrictions"]] : [])) + "</div>" + controls + '<details><summary>When, chance, and duration</summary><div class="field-grid">' + select("When it happens", tableBind("passive_skills", row, "exec_timing_type"), row.exec_timing_type, mechanics("exec-types").filter((r) => ![12, 17].includes(r[0]))) + field("Chance to activate (%)", tableBind("passive_skills", row, "probability"), row.probability, "number", "100% means it always activates when its conditions are met.", 'min="0" max="100"') + select("How long it lasts", tableBind("passive_skills", row, "turn"), row.turn, [[1, "This turn"], [2, "2 turns"], [3, "3 turns"], [5, "5 turns"], [99, "99 turns"]], "Inherited special durations stay unchanged until you choose a replacement.") + select("How often", tableBind("passive_skills", row, "is_once"), row.is_once, [[0, "Whenever the conditions are met"], [1, "Once per battle"]]) + '</div></details><div class="guide-rule"><strong>Condition:</strong> ' + esc(G.describeCondition(row.causality_conditions, [...state.conditionRows, ...state.project.tables.skill_causalities || []], D.conditionTypes)) + " " + button("Choose conditions", "conditions:" + row.id, "subtle small") + " " + button("Copy a character’s conditions", "copy-condition:" + row.id, "subtle small") + "</div></article>";
  }
  function simpleValue(row, key, label, value, min, max) {
    // Inherited game data can legitimately sit outside the guided range (for example a flat
    // DEF -100000 or a 1200% boost). Widen the range to include the stored value so an untouched
    // inherited effect never blocks navigation as an "invalid" field.
    const current = Number(value);
    if (Number.isFinite(current)) {
      if (current < Number(min)) min = String(current);
      if (current > Number(max)) max = String(current);
    }
    return '<label class="field">' + esc(label) + '<input type="number" data-guide-value="' + row.id + ":" + key + '" value="' + esc(value) + '" min="' + min + '" max="' + max + '"></label>';
  }
  stepHTML = function() {
    var _a2, _b, _c, _d, _e;
    if (state.expert) return original.stepHTML();
    const p = state.project, c = Forge.card(p);
    if (state.step === 0) return panel("Name your creation", "Start with a working character, then make it your own. The app handles the internal identifiers for you.", '<div class="field-grid">' + field("Character name", "card:name", c.name) + area("Your idea", "notes", p.notes, "Describe how you want this unit to feel. This stays in your saved project.") + '</div><div class="guide-source"><img src="' + esc(resourceThumb(c.resource_id || p.source.resourceId)) + '" alt=""><div><strong>Based on ' + esc(sourceName()) + "</strong><p>Working moves, art, and gameplay settings are inherited.</p></div></div>" + button("What can I change?", "help"));
    if (state.step === 1) return panel("Choose your stats", "HP is health, ATK is attack power, and DEF is defense. These values apply before in-battle bonuses.", '<div class="row">' + button("Match the source", "stats:source") + button("Attack focused", "stats:attack") + button("Defense focused", "stats:defense") + button("Balanced", "stats:balanced") + '</div><div class="field-grid">' + select("Card rarity", "card:rarity", c.rarity, Forge.rarities.map((r, i) => [i, r])) + select("Class and type", "card:element", c.element, Object.entries(Forge.elements), "Super is generally heroic characters; Extreme is generally villains. Type controls strengths and weaknesses.") + ["hp", "atk", "def"].map((s) => field(s.toUpperCase() + " at maximum level", "card:" + s + "_max", c[s + "_max"], "number", "", 'min="1"')).join("") + '</div><details><summary>Level, team cost, and starting stats</summary><div class="field-grid">' + field("Team cost", "card:cost", c.cost, "number", "How much room this card takes under a team’s cost limit.") + select("Maximum level", "card:lv_max", c.lv_max, [[60, "Level 60"], [80, "Level 80"], [100, "Level 100"], [120, "Level 120"], [140, "Level 140 (EZA)"], [150, "Level 150 (LR)"], [180, "Level 180"], [200, "Level 200"]]) + select("Super Attack training cap", "card:skill_lv_max", c.skill_lv_max, [[10, "SA level 10"], [15, "SA level 15"], [20, "SA level 20"], [25, "SA level 25"], [30, "SA level 30"]]) + ["hp", "atk", "def"].map((s) => field(s.toUpperCase() + " at level 1", "card:" + s + "_init", c[s + "_init"], "number")).join("") + "</div></details>");
    if (state.step === 2) {
      const set = selectedAbility("leader");
      return panel("Lead your team", "A leader skill gives bonuses when this unit is a team leader. Editing its words alone does not change gameplay.", '<div class="row">' + button("Copy a character’s leader skill", "copy:leader") + "</div>" + (set ? '<div class="field-grid">' + field("Leader skill name", tableBind("leader_skill_sets", set, "name"), set.name) + area("What the game displays", tableBind("leader_skill_sets", set, "description"), set.description) + "</div>" : "") + '<div class="divider"></div><h3>Easy team leader</h3>' + hint("This changes the actual Ki and stat bonuses. Choose everyone on the team, or restrict the bonuses to one named category. For multiple tiers or specialized leader effects, copy a complete leader skill above.") + '<div class="field-grid">' + select("Who receives these bonuses", "leaderDraftScope", state.leaderDraftScope || "all", [["all", "All types · everyone on the team"], ["category", "One team category"]]) + select("Ki bonus", "leaderDraftKi", (_a2 = state.leaderDraftKi) != null ? _a2 : 3, [[0, "No extra Ki"], [1, "Ki +1"], [2, "Ki +2"], [3, "Ki +3"], [4, "Ki +4"]]) + select("HP, ATK & DEF bonus", "leaderDraftStats", (_b = state.leaderDraftStats) != null ? _b : 170, [[50, "+50%"], [100, "+100%"], [150, "+150%"], [170, "+170%"], [200, "+200%"], [250, "+250%"]]) + "</div>" + (state.leaderDraftScope === "category" ? '<label class="field">Find a team category<input id="leader-category-search" placeholder="Search category names…"></label><label class="field">Team category<select id="leader-category">' + leaderCategoryOptions("") + "</select></label>" : "") + button("Use these team bonuses", "leader-easy", ""));
    }
    if (state.step === 3) {
      const set = selectedAbility("passive"), ids = new Set((p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === (set == null ? void 0 : set.id)).map((r) => r.passive_skill_id)), effects = (p.tables.passive_skills || []).filter((r) => ids.has(r.id));
      return panel("Build your abilities", "Each effect below changes what your unit actually does in battle. Conditions, timing, and targets use named choices.", button("Copy a character’s passive", "copy:passive") + (set ? '<div class="field-grid">' + field("Passive skill name", tableBind("passive_skill_sets", set, "name"), set.name) + area("What the game displays", tableBind("passive_skill_sets", set, "itemized_description"), set.itemized_description, "Use the summary button below after changing effects, or write your own description.") + "</div>" : "") + '<div class="row">' + button("Write a description from my effects", "summarize") + button("Explain my inherited effects", "explain-effects") + '</div><div class="divider"></div><div class="row preset-row">' + [["stats", "ATK & DEF boost"], ["ki", "Extra Ki"], ["crit", "Critical hits"], ["dodge", "Dodge"], ["guard", "Guard"], ["reduction", "Reduce damage"]].map(([key, label]) => '<button class="button subtle small" data-action="preset-' + key + '">' + label + "</button>").join("") + button('Status protection / type advantage','add-battle-buff','subtle small')+button('Bonus per matching-color sphere','add-color-sphere-bonus','subtle small')+button('Bonus per Ki Sphere','add-sphere-bonus','subtle small')+button('Type-specific support','add-type-support','subtle small')+button('Change Ki Sphere colors','add-sphere-change','subtle small')+button("Counterattack", "add-counter", "subtle small") + "</div>" + effects.map(effectHTMLSimple).join(""));
    }
    if (state.step === 4) return movesHTML();
    if (state.step === 5) return panel("Choose your team connections", "Link Skills activate beside compatible allies. Categories determine which teams and leader skills this unit belongs to. Pick up to seven links.", '<label class="field">Find a link or category<input id="lookup-query" placeholder="Search names…"></label><h3>Link Skills <span id="link-count"></span></h3><div class="check-grid" id="link-options">' + linkOptions("") + '</div><h3>Team categories</h3><div class="check-grid" id="category-options">' + categoryOptions("") + "</div>");
    if (state.step === 6) return panel("Choose the look", "Choose card artwork and an aura. Battle poses use your original template’s fighter. Your editor preview and the game’s complete art pack are separate.", '<div class="guide-source"><img src="' + esc(state.previewUrl || resourceThumb(((_c = p.artBinding) == null ? void 0 : _c.sourceId) || c.resource_id)) + '" alt="Current artwork"><div><strong>' + esc(p.artBinding ? "Custom in-game artwork" : ((_d = p.uiLabels) == null ? void 0 : _d.art) || "Current character artwork") + "</strong><p>" + esc(((_e = p.uiLabels) == null ? void 0 : _e.aura) || "Current source aura") + '</p></div></div><div class="row">' + button("Choose character artwork", "pick-art") + button("Customize in-game artwork", "game-art") + button("Customize battle poses", "battle-poses") + (p.artBinding ? button("Preview custom game card", "preview-game-art") : "") + button("Choose aura from a character", "pick-aura") + button("Choose editor preview image", "pick-preview") + '</div><div class="divider"></div><h3>Animation appearance</h3>' + hint("The animation editor has named moves, live previews, and controls for section order, trim, size, placement, mirroring, rotation, opacity, and sound.") + button("Open the animation editor", "studio", "") + "<details><summary>Extra resource files (" + (p.assets || []).length + ")</summary>" + hint("Borrowed animations keep their existing game resources. Additional files are optional. File paths stay in Expert mode.") + (p.assets || []).map((a) => "<p>" + esc(a.path.split("/").pop()) + "</p>").join("") + button("Manage extra resources", "resources") + "</details>");
    if (state.step === 7) {
      state.step = 8;
      return stepHTML();
    }
    return exportSimple();
  };
  function abilityHint(p, target) {
    var _a2, _b, _c;
    const source = (_a2 = p.abilityAnimationSources) == null ? void 0 : _a2[target.sourceKey];
    if (target.kind === "giant" && !(source == null ? void 0 : source.view)) return "This source uses built-in giant-form visuals. To customize them, assign entering, staying in, and leaving giant form. All three are needed before export. You can restore the inherited animations together.";
    if (target.kind === "transform" && !(source == null ? void 0 : source.view) && Number((_c = (_b = source == null ? void 0 : source.params) == null ? void 0 : _b.find((row) => row.idx === 2)) == null ? void 0 : _c.value)) return "This source can return from its transformation. Customize both entering and leaving the form before export, or restore the inherited animations together.";
    return "This source already has this gameplay ability. Choose or combine its animation while keeping the source’s activation and gameplay rules.";
  }
  function movesHTML() {
    var _a2;
    const p = state.project;
    return panel("Choose your moves", "Names describe the attack. Animation choices control its visuals. Each move keeps the source’s gameplay rules unless you change or copy them.", (((_a2 = p.actionHooks) == null ? void 0 : _a2.dodge) ? '<article class="effect-card"><h3>Custom Dodge animation</h3>' + hint("Restoring the inherited animation also requires updating or removing the installed shared actions patch.") + button("Restore inherited Dodge", "restore-dodge", "ghost") + "</article>" : "") + '<article class="effect-card"><h3>Normal attack style</h3><label class="field">Which normal attacks can this character use?<select id="normal-attack-style">' + selection([["inherit", "Keep the source character’s style"], ["mixed", "Allow melee and Ki blasts"], ["melee", "Melee only"], ["ki", "Ki blasts only"]], G.normalAttackStyle(p)) + "</select></label>" + hint("Mixed attacks use the game’s own selection rules. These choices affect ground and air normal attacks; Super Attacks keep their own settings. Returning to the source style restores its original selection rules and keeps your edited animations.") + "</article>" + button("Add a move from another character", "copy:move") + " " + button("Open the animation editor", "studio") + (p.tables.card_specials || []).map((rel) => {
      var _a3, _b;
      const set = (p.tables.special_sets || []).find((s) => s.id === rel.special_set_id);
      if (!set) return "";
      const target = "super:" + rel.id, profiles = D.damageProfiles || [], current = profiles.find((x) => x.increase_rate === set.increase_rate && x.lv_bonus === set.lv_bonus);
      return '<article class="effect-card"><h3>' + esc(rel.style === "Hyper" ? "Ultra Super Attack" : rel.style === "Extra" ? "EX Super Attack" : rel.style === "FullPower" ? "Full-power attack" : "Super Attack") + '</h3><div class="field-grid">' + field("Move name", tableBind("special_sets", set, "name"), set.name) + select("Move type", tableBind("card_specials", rel, "style"), rel.style, [["Normal", "Super Attack"], ["Hyper", "Ultra Super Attack"], ["Extra", "EX / Extra Super Attack"], ["FullPower", "Full-power attack"], ["Condition", "Conditional attack"]], "Extra / EX availability depends on the source kit; the move type alone does not unlock it.") + area("What the game displays", tableBind("special_sets", set, "description"), set.description) + select("Ki needed", tableBind("card_specials", rel, "eball_num_start"), rel.eball_num_start, [[9, "9 Ki"], [10, "10 Ki"], [11, "11 Ki"], [12, "12 Ki · standard Super"], [18, "18 Ki · typical Ultra Super"], [24, "24 Ki"]]) + select("Available from Super Attack level", tableBind("card_specials", rel, "lv_start"), rel.lv_start, [[0, "Immediately"], [10, "SA level 10"], [15, "SA level 15"], [20, "SA level 20"]]) + '<label class="field">Damage class<select data-guide-power="' + set.id + '">' + selection([["keep", "Keep current attack power"], ...profiles.map((x) => [x.key, x.name])], (current == null ? void 0 : current.key) || "keep") + "</select><small>Changes damage scaling. Other attack effects remain inherited.</small></label></div><p><strong>Animation:</strong> " + esc(((_b = (_a3 = p.uiLabels) == null ? void 0 : _a3.animations) == null ? void 0 : _b[target]) || "Assigned game animation") + '</p><div class="row">' + '</div>' + ForgeAnimChoice.block(target) + '<div class="row">' + '<button class="button subtle small" data-duplicate-attack="' + rel.id + '">Duplicate this move</button></div></article>';
    }).join("") + ForgeGuide.targets(p).filter((t) => t.kind === "normal").map((t) => '<article class="effect-card"><h3>' + esc(t.name) + "</h3>" + hint(t.virtual ? "Uses the game’s built-in animation until you choose or build a replacement." : "Changes the visuals of this normal attack. Your normal attack style determines when it can be used.") + '<div class="row">' + '</div>' + ForgeAnimChoice.block(t.key) + '<div class="row">' + "</div></article>").join("") + G.targets(p).filter((t) => ["nullify", "revival", "transform", "giant"].includes(t.kind)).map((t) => {
      var _a3;
      return '<article class="effect-card"><h3>' + esc(t.name) + "</h3>" + hint(abilityHint(p, t)) + '<div class="row">' + '</div>' + ForgeAnimChoice.block(t.key) + '<div class="row">' + (((_a3 = p.abilityAnimationOverrides) == null ? void 0 : _a3[t.sourceKey]) ? button("Restore inherited animations", "restore-ability:" + t.key, "subtle small") : "") + "</div></article>";
    }).join("") + ["active_skill_sets", "standby_skill_sets", "finish_skill_sets"].map((table) => (p.tables[table] || []).map((row) => {
      var _a3, _b;
      const kind = table === "active_skill_sets" ? "active" : table === "standby_skill_sets" ? "standby" : "finish", key = kind + ":" + row.id;
      return '<article class="effect-card"><h3>' + esc(ForgeMotion.kinds[kind]) + '</h3><div class="field-grid">' + field("Move name", tableBind(table, row, "name"), row.name) + area("Displayed effect", tableBind(table, row, "effect_description"), row.effect_description) + area("Displayed activation rule", tableBind(table, row, "condition_description"), row.condition_description, "The source’s actual activation rule is preserved. Copy another character’s complete setup to change specialized rules safely.") + "</div><p>" + esc(((_b = (_a3 = p.uiLabels) == null ? void 0 : _a3.animations) == null ? void 0 : _b[key]) || "Assigned game animation") + '</p><div class="row">' + '</div>' + ForgeAnimChoice.block(key) + '<div class="row">' + "</div></article>";
    }).join("")).join("") + '<div class="notice">Transformations, Standby, EX moves, and Finish Skills also need gameplay setup. Starting with a character that already has that action preserves its complete setup. The animation editor changes the visuals of a supported move.</div>');
  }
  function exportSimple() {
    var _a2, _b;
    const p = state.project, roster = Forge.playerRosterEligibility(p), extra = ((_a2 = state.playerRosterCheck) == null ? void 0 : _a2.key) === p.key && state.playerRosterCheck.targetId === p.targetId ? state.playerRosterCheck.catalogIssues : [];
    roster.issues = [.../* @__PURE__ */ new Set([...roster.issues, ...extra || []])];
    roster.ready = !roster.issues.length;
    const rosterNotice = roster.ready ? "" : '<div class="notice" role="status"><strong>Check player-character availability</strong>' + hint(roster.issues.join(" ")) + hint("The export remains available for NPC or technical use. Saving a project does not require player-list eligibility.") + "</div>";
    return panel("Save and play your creation", "Your project already saves on this device. Export an Eclipse patch to install it in the game.", rosterNotice + sharedActionsNotice(p) + '<div class="field-grid">' + field("Creation name", "patch:name", p.patch.name) + field("Created by", "patch:author", p.patch.author) + area("About this creation", "patch:description", p.patch.description) + "</div>" + validationHTML(Forge.validate(p)) + '<div class="export-grid"><div class="export-option recommended"><span class="chip teal">PLAY IN ECLIPSE</span><h3>Installable game patch</h3><p>Includes your unit, generated animation instructions, attached files, and an editable project.</p><button class="button teal" data-export="eclp">' + (((_b = p.actionHooks) == null ? void 0 : _b.dodge) ? "Export Eclipse files" : "Save Eclipse patch (.eclp)") + '</button></div><div class="export-option"><h3>Editable project backup</h3><p>Keep a backup or continue editing on your PC. Attached images and other files need separate transfer; use ECLP to include them.</p><button class="button ghost" data-export="json">Save editable project (.json)</button></div></div><details><summary>Other export formats and options</summary><div class="field-grid">' + field("Version label", "patch:version", p.patch.version) + '</div><div class="row"><button class="button ghost" data-export="sql">Save database changes (.sql)</button><button class="button ghost" data-export="zip">Save patch archive (.zip)</button>' + (Native.canConvertOnline() ? '<button class="button subtle" data-export="eclp-online">Use Eclipse online converter</button>' : "") + '<button class="button subtle" data-action="converter">Open converter in browser</button></div>' + hint("SQL alone does not include the animation files. Use ECLP or the patch archive when you add a combined animation.") + "</details>" + hint("Test your unit in Eclipse before sharing it. Visual changes do not add new game-engine actions."));
  }
  // Classic editor: effects added, changed or removed (presets, counters, copies…) also update the
  // passive's written description, keeping the game's wording for everything else.
  function classicPassiveSync() {
    const PM = window.ForgePassiveMerge, B = window.ForgeBuilder, p = state.project;
    if (!PM || !B || !p || state.builder || state.view !== "editor") return;
    let set;
    try { set = selectedAbility("passive"); } catch { return; }
    if (!set) return;
    const ids = new Set((p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === set.id).map((r) => r.passive_skill_id));
    const rows = (p.tables.passive_skills || []).filter((r) => ids.has(r.id));
    const known = [...state.conditionRows || [], ...p.tables.skill_causalities || []];
    const condText = (row) => { if (!row.causality_conditions) return ""; const t = G.describeCondition(row.causality_conditions, known, D.conditionTypes); return /^Always$|inherited condition/i.test(t) ? "" : t.replace(/^\((.*)\)$/, "$1"); };
    if (PM.syncText(p, set, rows, (row) => [B.officialHeading(row, condText(row)), B.officialLine(row)])) scheduleSave();
  }
  renderEditor = function() {
    var _a2, _b, _c, _d;
    if (historyKey !== ((_a2 = state.project) == null ? void 0 : _a2.key)) resetHistory();
    try { classicPassiveSync(); } catch (e) { console.warn(e); }
    if (!state.expert && [2, 3].includes(state.step) && state.project) {
      if (G.isolateAbilityStage(state.project, currentAbilityStage(), state.step === 2 ? "leader" : "passive")) scheduleSave();
    }
    if (!state.expert && state.step === 7) state.step = 8;
    original.renderEditor();
    if (!state.project) return;
    if (!state.expert) {
      (_b = document.querySelector('[data-step="7"]')) == null ? void 0 : _b.remove();
      const labels = ["Name", "Stats", "Abilities for the team", "Battle abilities", "Moves", "Teams & links", "Appearance", "Technical", "Save & play"];
      document.querySelectorAll("[data-step]").forEach((b) => {
        const n = Number(b.dataset.step);
        b.innerHTML = "<span>" + (n === 8 ? 8 : n + 1) + "</span>" + esc(labels[n]);
      });
      const count = document.querySelector(".step-footer span");
      if (count) count.textContent = (state.step === 8 ? 8 : state.step + 1) + " / 8";
      const preview = document.querySelector(".preview-body p");
      if (preview) preview.textContent = "Based on " + sourceName();
    }
    if (!state.expert && [2, 3].includes(state.step) && ((_c = state.project.tables.optimal_awakening_growths) == null ? void 0 : _c.length)) {
      $("#editor-form").insertAdjacentHTML("afterbegin", stageSelector());
      $("#ability-stage").onchange = (e) => {
        var _a3;
        state.abilityStage = e.target.value;
        renderEditor();
        (_a3 = $("#ability-stage")) == null ? void 0 : _a3.focus();
      };
      const note = document.createElement("div");
      note.className = "notice";
      note.innerHTML = "You can customize each awakening stage separately, or replace every EZA stage with your base abilities. " + button("Use my base abilities for all EZA stages", "match-eza", "ghost small");
      $("#editor-form").append(note);
      bindGuide(note);
    }
    const categorySearch = $("#leader-category-search"), categoryChoice = $("#leader-category");
    if (categorySearch && categoryChoice) {
      categorySearch.oninput = () => {
        categoryChoice.innerHTML = leaderCategoryOptions(categorySearch.value);
      };
      categoryChoice.onchange = () => state.leaderDraftCategory = Number(categoryChoice.value);
    }
    const actions = document.createElement("div");
    actions.className = "row guide-history";
    actions.innerHTML = button("Undo", "undo", "subtle small") + button("Redo", "redo", "subtle small") + button(state.expert ? "Use Beginner mode" : "Expert mode", "mode", "subtle small") + button("Help", "help", "subtle small");
    (_d = document.querySelector(".section-heading")) == null ? void 0 : _d.append(actions);
    bindGuide(actions);
  };
  action = async function(name) {
    if (!state.expert && name.startsWith("preset-")) {
      const presets = { stats: { efficacy_type: 3, eff_value1: 100, eff_value2: 100, calc_option: 2 }, ki: { efficacy_type: 5, eff_value1: 3, eff_value2: 0, calc_option: 0 }, crit: { efficacy_type: 90, eff_value1: 50, eff_value2: 0, calc_option: 0 }, dodge: { efficacy_type: 91, eff_value1: 50, eff_value2: 0, calc_option: 0 }, guard: { efficacy_type: 78, eff_value1: 0, eff_value2: 0, calc_option: 0 }, reduction: { efficacy_type: 13, eff_value1: 60, eff_value2: 0, calc_option: 2 } }, preset = presets[name.slice(7)];
      if (preset) {
        editAbility("passive", (p) => Forge.addPassive(p, preset));
        scheduleSave();
        renderEditor();
      }
      return;
    }
    if (!state.expert && name === "step-next" && state.step === 6) {
      await flushSave();
      state.step = 8;
      renderEditor();
      return;
    }
    if (!state.expert && name === "step-prev" && state.step === 8) {
      await flushSave();
      state.step = 6;
      renderEditor();
      return;
    }
    if (name === "add-effect" && !state.expert) {
      editAbility("passive", (p) => Forge.addPassive(p, {}));
      scheduleSave();
      renderEditor();
      return;
    }
    return original.action(name);
  };
  updateBinding = function(el, eventType) {
    var _a2, _b, _c, _d, _e;
    if ((_a2 = el.dataset.bind) == null ? void 0 : _a2.startsWith("leaderDraft")) {
      const key = el.dataset.bind;
      state[key] = key === "leaderDraftScope" ? el.value : Number(el.value);
      if (key === "leaderDraftScope") renderEditor();
      return;
    }
    if (!state.expert && ((_b = el.dataset.bind) == null ? void 0 : _b.endsWith(":efficacy_type"))) {
      const bits = el.dataset.bind.split(":"), row = state.project.tables.passive_skills.find((r) => r.id === Number(bits[2]));
      const id = Number(el.value);
      Object.assign(row, { efficacy_values: "{}", eff_value1: [78, 9, 48].includes(id) ? 0 : id === 13 ? 60 : id === 5 ? 3 : 100, eff_value2: id === 3 ? 100 : 0, eff_value3: 0, calc_option: [1, 2, 3, 4, 13, 86].includes(id) ? 2 : 0 });
    }
    if (!state.expert && ((_c = el.dataset.bind) == null ? void 0 : _c.endsWith(":target_type"))) {
      const bits = el.dataset.bind.split(":"), row = state.project.tables.passive_skills.find((r) => r.id === Number(bits[2]));
      if (row) {
        row.sub_target_type_set_id = 0;
        if (Number(el.value) === -20) {
          const option = document.createElement("option");
          option.value = "2";
          option.textContent = "All allies";
          el.append(option);
          el.value = "2";
        }
      }
    }
    original.updateBinding(el, eventType);
    if (!state.expert && ((_d = el.dataset.bind) == null ? void 0 : _d.endsWith(":calc_option")) || !state.expert && ((_e = el.dataset.bind) == null ? void 0 : _e.endsWith(":target_type"))) renderEditor();
  };
  function rememberUnusedGenerated(keys) {
    if (!(keys == null ? void 0 : keys.length)) return;
    try {
      const prior = JSON.parse(localStorage.getItem("forge-unused-generated-assets") || "[]");
      localStorage.setItem("forge-unused-generated-assets", JSON.stringify([.../* @__PURE__ */ new Set([...prior, ...keys])].slice(-500)));
    } catch {
    }
  }
  const originalExport = exportProject;
  exportProject = async function(kind) {
    var _a2, _b;
    if (kind === "eclp-online" && !Native.canConvertOnline()) return originalExport(kind);
    if (state.project && kind !== "json") try {
      const previous = state.project;
      await flushSave();
      const previousSnapshot = JSON.stringify(previous);
      const counterMigrated = await migrateCounterBindings(previous);
      let artworkRepair;
      try {
        artworkRepair = await ForgeArt.repairMetadata(counterMigrated, { readAsset: async key => ForgeBattlePoseEditor.decode((await Native.call("readAsset", { key, maxBytes: 131072 })).base64), storeDecoration: text => Native.call("storeDecoration", { text }) });
      } catch (error) { rememberUnusedGenerated(error.createdAssets); throw error; }
      const migrated = artworkRepair.project;
      if (migrated !== previous) {
        try {
          if (state.project !== previous || JSON.stringify(previous) !== previousSnapshot) throw new Error("The unit changed. Export again.");
          await Native.call("saveProject", { project: migrated });
        } catch (error) { rememberUnusedGenerated(artworkRepair.createdAssets); throw error; }
        state.project = migrated;
        scheduleSave();
        await flushSave();
      }
    } catch (e) {
      toast(e.message, true);
      return;
    }
    // Units saved with the old 10-digit slots are always moved, even in Expert mode: Eclipse cannot load them.
    // The free-slot check runs in every mode: a unit must never replace an existing card or row in the game.
    if (state.project && kind !== "json" && !state.project.awaken) try {
      const p = state.project, projects = await Native.call("projects");
      let conflict = ForgeForms.all(p).some((member) => Forge.legacySlot(member.targetId)) || projects.some(other => other.key !== p.key && [other.targetId,...(other.reservedIds||[])].some(id => ForgeForms.all(p).some(form => Math.abs(Number(id)-Number(form.targetId))<1e3)));
      if (!conflict) {
        for (const [table, rows] of Object.entries(Forge.materializeAll(p))) if (rows.length && (await Native.call("query", { table, ids: rows.map((r) => r.id), limit: 1 })).length) {
          conflict = true;
          break;
        }
      }
      if (!conflict) for(const member of ForgeForms.all(p)) if(member.artBinding && (await Native.call("query",{table:"cards",filters:{resource_id:member.artBinding.resourceId},limit:1})).length){conflict=true;break;}
      if (!conflict && ((_a2 = p.movieBindings) == null ? void 0 : _a2.length)) {
        for (const binding of p.movieBindings) if ((await Native.call("query", { table: "effect_packs", filters: { pack_name: "forge_movie_" + p.targetId + "_" + binding.slot + "_" + binding.storageTag }, limit: 1 })).length) {
          conflict = true;
          break;
        }
      }
      if (!conflict && (p.artBinding || p.battlePoseBinding || ((_b = p.movieBindings) == null ? void 0 : _b.length))) {
        const owned = new Set((p.assets || []).filter((a) => ["forge-card-art", "forge-battle-poses", "forge-authored-movie"].includes(a.owner)).map((a) => a.key));
        let complete = false;
        for (let offset = 0; offset < 1e5; offset += 500) {
          const assets = await Native.call("assets", { query: String(Math.floor(p.targetId / 1e3)), offset, limit: 500 });
          if (assets.some((a) => !owned.has(a.key) && ForgeUnitRebase.namespace(a.path || a.key, p.targetId))) {
            conflict = true;
            break;
          }
          if (assets.length < 500) {
            complete = true;
            break;
          }
        }
        if (!conflict && !complete) throw new Error("Too many matching resources to safely check this unit slot.");
      }
      if (conflict) {
        await flushSave();
        const rebased = await busy("Reserving a free unit slot and rebuilding your private resources", async () => {
          let prepared;
          try {
            prepared = await (p.formProjects?.length ? ForgeForms.reserve : ForgeUnitRebase.reserve)(p, { query: (o) => Native.call("query", o), projects, schema: state.info.schema, prepareCounters: (project) => ForgeCounterReservations.prepare(project, { schema: state.info.schema }), listAssets: (o) => Native.call("assets", o), readAsset: async (key) => ForgeBattlePoseEditor.decode((await Native.call("readAsset", { key, maxBytes: 12 * 1024 * 1024 })).base64), storeDecoration: text => Native.call("storeDecoration", { text }), storeLwf: async (bytes, options) => Native.call("storeLwf", { name: options.name, data: ForgeBattlePoseEditor.encode(bytes) }) });
            if (state.project !== p || JSON.stringify(p) !== prepared.before) throw new Error("Your unit changed. Export again to reserve its new slot.");
            await Native.call("saveProject", { project: prepared.project });
          } catch (e) {
            rememberUnusedGenerated((prepared == null ? void 0 : prepared.createdAssets) || e.createdAssets);
            throw e;
          }
          state.project = prepared.project;
          state.previewUrl = await projectPreviewUrl(state.project);
          scheduleSave();
          await flushSave();
          return true;
        });
        if (!rebased) return;
        toast("A free unit slot was reserved. Private artwork, battle poses and assigned animations were rebuilt.");
      }
    } catch (e) {
      toast(e.message, true);
      return;
    }
    return originalExport(kind);
  };
  const oldAssets = renderAssets;
  renderAssets = async function() {
    await oldAssets();
    if (state.expert || state.view !== "assets") return;
    const heading = $("#main h1");
    if (heading) heading.textContent = "Game data & files";
    document.querySelectorAll('#main .tabs [data-action="asset-online"]').forEach((el) => el.hidden = true);
    // Imported files list: a plain heading instead of a tab chip and expert notes.
    const chip = document.querySelector('#main .tabs');
    if (chip) { const title = document.createElement("h2"); title.className = "assets-files-title"; title.textContent = "Files you imported"; chip.replaceWith(title); }
  };
  const oldPatch = showPatch;
  showPatch = function(key) {
    oldPatch(key);
    if (state.expert) return;
    const files = $("#dialog .patch-files");
    if (files) {
      const details = document.createElement("details");
      details.innerHTML = "<summary>Included files (technical)</summary>";
      files.before(details);
      details.append(files);
    }
    $("#dialog").querySelectorAll(".hint").forEach((el) => {
      if (el.innerHTML.includes("UUID:")) el.innerHTML = el.innerHTML.replace(/<br>UUID: [^<]*/, "");
    });
  };
  const oldLink = linkOptions, oldCategory = categoryOptions;
  linkOptions = function(query) {
    return state.expert ? oldLink(query) : oldLink(query).replace(/<small>\d+<\/small>/g, "");
  };
  categoryOptions = function(query) {
    return state.expert ? oldCategory(query) : oldCategory(query).replace(/<small>\d+<\/small>/g, "");
  };
  renderHome = function() {
    original.renderHome();
    if (!state.expert) document.querySelectorAll(".tile-body p").forEach((p) => {
      if (p.textContent.startsWith("Custom ID")) p.textContent = "Saved design · ready to edit";
    });
  };
  renderLibraryResults = function() {
    original.renderLibraryResults();
    if (!state.expert) document.querySelectorAll("#library-results .tile-body p").forEach((p) => {
      p.textContent = p.textContent.replace(/ · \d{6,}/g, "");
    });
  };
  createUnit = async function(id) {
    await busy("Preparing your character and reserving a free unit slot", async () => {
      state.projects = await Native.call("projects");
      let p = await Forge.loadTemplate((o) => Native.call("query", o), state.info.schema, id, Forge.SLOT_FLOOR);
      await G.allocateId(p, (o) => Native.call("query", o), state.projects);
      let note = "";
      if (window.ForgeTemplateForms) {
        $("#busy-title").textContent = "Copying this character’s transformations";
        const included = await ForgeTemplateForms.include(p, { query: (o) => Native.call("query", o), schema: state.info.schema, projects: state.projects });
        p = included.project;
        note = ForgeTemplateForms.message(included);
      }
      state.project = p;
      if (note) setTimeout(() => toast(note), 400);
      state.step = 0;
      state.previewUrl = "";
      resetHistory();
      await flushSave();
      state.view = "editor";
      updateNav();
      renderEditor();
      window.scrollTo(0, 0);
    });
  };
  navigate = async function(view) {
    if (view === "animations") {
      await flushSave();
      state.view = view;
      updateNav();
      return renderStudio();
    }
    return original.navigate(view);
  };
  updateNav = function() {
    original.updateNav();
    if (state.view === "animations") $("#breadcrumb").textContent = "Animations";
  };
  renderSource = function() {
    original.renderSource();
    if (!state.expert) {
      document.querySelector(".section-heading p:last-child").textContent = "Choose a character with moves and gameplay close to your idea. Everything can be adjusted afterward.";
      const box = document.createElement("section");
      box.className = "notice";
      box.innerHTML = "Want an EX move, Active Skill, or special form? Start with a character that already has it. " + button("Browse EX templates", "ex-templates", "ghost small") + button("Browse animation examples", "browse-examples", "ghost small");
      $("#source-results").before(box);
      bindGuide(box);
    }
  };
  searchSources = async function() {
    await original.searchSources();
    if (state.expert || state.view !== "source") return;
    document.querySelectorAll("#source-results .source-tile").forEach((tile) => {
      const card = state.sourceRows.find((c) => c.id === Number(tile.dataset.source));
      const p = tile.querySelector(".tile-body p");
      if (p && card) p.textContent = "HP " + number(card.hp_max) + " · ATK " + number(card.atk_max) + " · DEF " + number(card.def_max);
    });
  };
  bindDynamic = function(root) {
    original.bindDynamic(root);
    bindGuide(root);
  };
  function bindGuide(root) {
root.querySelectorAll('[data-guide-color-sphere]').forEach(el=>el.addEventListener('change',()=>{const [id,key]=el.dataset.guideColorSphere.split(':'),row=state.project.tables.passive_skills.find(r=>r.id===Number(id));try{if(el.value==='')throw new Error('Choose a sphere color and a whole bonus.');G.setColorSphereBonus(row,{[key]:Number(el.value)});scheduleSave();renderEditor();}catch(e){if(row)el.value=String(key==='color'?row.eff_value1:row.eff_value2);error(e);}}));root.querySelectorAll('[data-guide-sphere-bonus]').forEach(el=>el.addEventListener('change',()=>{const [id,key]=el.dataset.guideSphereBonus.split(':'),row=state.project.tables.passive_skills.find(r=>r.id===Number(id));try{if(el.value==='')throw new Error('Choose a whole bonus per Ki Sphere.');G.setSphereBonus(row,{[key]:Number(el.value)});scheduleSave();renderEditor();}catch(e){if(row)el.value=String(row[key]);error(e);}}));root.querySelectorAll('[data-guide-support]').forEach(el=>el.addEventListener('change',()=>{const [id,key]=el.dataset.guideSupport.split(':'),row=state.project.tables.passive_skills.find(r=>r.id===Number(id));try{if(el.value==='')throw new Error('Choose a whole bonus.');G.setTypeSupport(row,{[key]:Number(el.value)});scheduleSave();renderEditor();}catch(e){if(row)el.value=String(row[key]);error(e);}}));root.querySelectorAll('[data-guide-sphere]').forEach(el=>el.addEventListener('change',()=>{const [id,key]=el.dataset.guideSphere.split(':'),row=state.project.tables.passive_skills.find(r=>r.id===Number(id));try{if(!row)throw new Error('This effect changed. Open its colors again.');const from=key==='eff_value1'?Number(el.value):row.eff_value1,to=key==='eff_value2'?Number(el.value):row.eff_value2;G.setKiSphereChange(row,from,to);scheduleSave();renderEditor();}catch(e){if(row)el.value=String(row[key]);error(e);}}));

    const normalStyle = root.querySelector("#normal-attack-style");
    if (normalStyle) normalStyle.addEventListener("change", () => {
      var _a2;
      try {
        G.setNormalAttackStyle(state.project, state.info.schema, normalStyle.value);
        scheduleSave();
        renderEditor();
        (_a2 = $("#normal-attack-style")) == null ? void 0 : _a2.focus();
      } catch (e) {
        normalStyle.value = G.normalAttackStyle(state.project);
        error(e);
      }
    });
    root.querySelectorAll("[data-guide]").forEach((el) => el.addEventListener("click", () => guideAction(el.dataset.guide).catch(error)));
    root.querySelectorAll("[data-guide-value]").forEach((el) => el.addEventListener("change", () => {
      const [id, key] = el.dataset.guideValue.split(":"), row = state.project.tables.passive_skills.find((r) => r.id === Number(id));
      const value = Number(el.value), limited = [13, 90, 91].includes(row.efficacy_type) || row.efficacy_type === 4 && [2, 3].includes(row.calc_option);
      if (el.value === "" || !Number.isFinite(value) || !el.validity.valid || limited && (value < 0 || value > 100)) {
        el.setAttribute("aria-invalid", "true");
        toast(limited ? "Choose a whole percentage from 0 to 100." : "Choose a whole number from " + el.min + " to " + el.max + ".", true);
        return;
      }
      el.removeAttribute("aria-invalid");
      row[key] = row.efficacy_type === 13 ? 100 - value : value;
      scheduleSave();
      renderPreview();
    }));
    root.querySelectorAll("[data-guide-power]").forEach((el) => el.addEventListener("change", () => {
      const profile = (D.damageProfiles || []).find((r) => r.key === el.value), row = state.project.tables.special_sets.find((r) => r.id === Number(el.dataset.guidePower));
      if (profile) {
        row.increase_rate = profile.increase_rate;
        row.lv_bonus = profile.lv_bonus;
        scheduleSave();
      }
    }));
  }
  async function pickUnit(title, choose, { sourceDatabase = "eclipse", allVersions = false, mount = null, onBack = null } = {}) {
    // the character finder (filters for rarity, type, class, Category, EZA; newest first)
    if (window.ForgeFinder && sourceDatabase !== "sparking" && !mount) return ForgeFinder.pick(title, choose, { onBack });
    const CV = window.ForgeCardVersions, cvDb = sourceDatabase === "sparking" ? "sparking" : "eclipse";
    let all = !CV || allVersions, timer, seq = 0, offset = 0, hasMore = false, choosing = false;
    const html = (onBack ? '<button type="button" class="button ghost small" id="guide-unit-return">Back to animations</button>' : '') + '<p>Search by character name. Each character is shown once, in their fully awakened version.</p><label class="field">Character<input id="guide-unit-search" type="search" placeholder="Goku, Vegeta, Broly…"></label>' + (CV ? '<label class="cv-all"><input type="checkbox" id="guide-unit-all"' + (all ? " checked" : "") + '> Show every version (pre-awakened, enemy and transformation cards)</label>' : '') + '<div id="guide-unit-results"><p role="status">Finding characters…</p></div><div class="row"><button class="button ghost small" id="guide-unit-back" disabled>Previous</button><span id="guide-unit-range" role="status" aria-live="polite"></span><button class="button ghost small" id="guide-unit-next" disabled>Next</button></div>';
    if (mount) mount.innerHTML = html;
    else dialog(title, html);
    const root = mount || $("#dialog-content"), q = selector => root.querySelector(selector), input = q("#guide-unit-search"), results = q("#guide-unit-results"), modal = root.closest('dialog');
    const current = () => root.isConnected && (!modal || modal.open) && q("#guide-unit-results") === results && !choosing;
    const report = e => { if (current()) { results.innerHTML = '<p class="notice error" role="alert">' + esc(e.message || String(e)) + '</p><button type="button" class="button ghost" id="guide-unit-retry">Retry</button>'; q('#guide-unit-retry').onclick = () => search().catch(report); } error(e); };
    const page = () => all ? 30 : 120;
    const search = async () => {
      if (!current()) return;
      const token = ++seq, text = input.value, pageOffset = offset, size = page(), collapsed = !all;
      const rows = await Native.call(sourceDatabase === "sparking" ? "querySparking" : "query", { table: "cards", search: { column: "name", text }, order: "id", offset: pageOffset, limit: size + 1 });
      hasMore = rows.length > size;
      let shown = rows.slice(0, size);
      if (collapsed) shown = await CV.collapse(shown, { database: cvDb });
      else if (CV) await CV.load(cvDb).catch(() => null);
      if (!current() || token !== seq || input.value !== text || offset !== pageOffset || collapsed === all) return;
      q("#guide-unit-range").textContent = shown.length ? number(shown.length) + (collapsed ? (shown.length === 1 ? " character" : " characters") : " cards") : hasMore ? "None on this page — tap Next" : "No matching characters";
      q("#guide-unit-back").disabled = pageOffset === 0;
      q("#guide-unit-next").disabled = !hasMore;
      results.innerHTML = shown.length ? '<div class="guide-picks">' + shown.map(c => '<button type="button" class="guide-pick" data-pick="' + c.id + '"><img loading="lazy" src="' + esc(thumb(c)) + '" alt=""><span><strong>' + esc(c.name) + '</strong><small>' + esc(Forge.rarities[c.rarity]) + ' · ' + esc(Forge.elements[c.element]) + ' · ATK ' + number(c.atk_max) + '</small>' + (CV ? CV.badge(c, cvDb) : '') + '</span></button>').join('') + '</div>' : '<p class="hint">' + (hasMore ? 'No fully awakened characters on this page. Tap Next to keep looking.' : 'Try another character name.') + '</p>';
      results.querySelectorAll('[data-pick]').forEach(b => b.onclick = () => {
        if (!current()) return;
        const card = shown.find(c => Number(c.id) === Number(b.dataset.pick));
        if (!card) return report(Error('Choose a character from the current results.'));
        choosing = true; ++seq; clearTimeout(timer);
        results.querySelectorAll('button').forEach(button => button.disabled = true);
        const run = () => Promise.resolve().then(() => choose(card)).catch(e => { choosing = false; if (current()) results.querySelectorAll('button').forEach(button => button.disabled = false); report(e); });
        if (mount) run();
        else { modal.addEventListener('close', run, {once:true}); modal.close(); }
      });
    };
    input.oninput = () => { offset = 0; ++seq; q('#guide-unit-next').disabled = true; q('#guide-unit-back').disabled = true; results.innerHTML = '<p role="status">Finding characters…</p>'; clearTimeout(timer); timer = setTimeout(() => search().catch(report),250); };
    const toggle = q('#guide-unit-all');
    if (toggle) toggle.onchange = () => { all = toggle.checked; offset = 0; search().catch(report); };
    q('#guide-unit-next').onclick = () => { if (hasMore) { offset += page(); search().catch(report); } };
    q('#guide-unit-back').onclick = () => { offset = Math.max(0,offset-page()); search().catch(report); };
    if (onBack) q('#guide-unit-return').onclick = () => { ++seq; clearTimeout(timer); Promise.resolve().then(onBack).catch(report); };
    await search().catch(report);
  }
  // Where a copied passive goes: the stage open in the Card Builder, or the guided editor's stage.
  function passiveDestination(p) {
    if (state.builder && window.ForgeBuilderUI && ForgeBuilderUI.editableSet) return ForgeBuilderUI.editableSet("passive");
    G.isolateAbilityStage(p, currentAbilityStage(), "passive");
    return G.stageAbilityId(p, currentAbilityStage(), "passive");
  }
  function usePassiveSet(p, id) {
    if (state.builder && window.ForgeBuilderUI && ForgeBuilderUI.setStageSet) ForgeBuilderUI.setStageSet("passive", id);
    else G.setStageAbility(p, currentAbilityStage(), "passive", id);
  }
  async function copyKit(kind, card, sourceStage = "base", preloaded = null, mode = "add") {
    let merged = null;
    await busy("Copying " + card.name + "’s " + kind, async () => {
      const p = state.project, donor = preloaded || await Forge.loadTemplate((o) => Native.call("query", o), state.info.schema, card.id, p.targetId);
      if (kind === "leader") {
        if (!G.stageSet(donor, sourceStage, "leader")) throw new Error("This character has no leader skill. Choose another character.");
        const maps = G.importOwned(p, donor, ["leader_skill_sets", "leader_skills"]);
        G.setStageAbility(p, currentAbilityStage(), "leader", maps.leader_skill_sets.get(G.stageAbilityId(donor, sourceStage, "leader")));
      } else if (kind === "passive") {
        if (!G.stageSet(donor, sourceStage, "passive")) throw new Error("This character has no passive skill. Choose another character.");
        const target = mode === "replace" || !window.ForgePassiveMerge ? null : passiveDestination(p);
        const adding = target != null && (p.tables.passive_skill_sets || []).some((row) => row.id === target) && ForgePassiveMerge.setRows(p, target).length > 0;
        const maps = G.importOwned(p, adding ? ForgePassiveMerge.onlySet(donor, G.stageAbilityId(donor, sourceStage, "passive")) : donor, ["passive_skill_sets", "passive_skills", "passive_skill_set_relations", "passive_skill_set_additions", "dokkan_field_passive_skill_relations"]);
        const donorSet = maps.passive_skill_sets.get(G.stageAbilityId(donor, sourceStage, "passive"));
        if (adding) {
          // Add the copied passive to the current one: matching abilities are combined, the rest added.
          merged = ForgePassiveMerge.copyPassive(p, target, donorSet);
          merged.tidy = ForgePassiveMerge.organize(p, target);
          p.builderAuto = p.builderAuto || {};
          // keep the combined text (the game's own wording) instead of rewriting it
          p.builderAuto["passive:" + target] = false;
          if (p.builderLines) delete p.builderLines[target];
        } else usePassiveSet(p, donorSet);
      } else {
        for (const r of donor.tables.active_skill_sets || []) if (r.ultimate_special_id) {
          G.ensure(donor, state.info.schema, "ultimate_specials");
          const rows = await Native.call("query", { table: "ultimate_specials", ids: [r.ultimate_special_id], limit: 1 });
          if (rows.length && !donor.tables.ultimate_specials.some((x) => x.id === rows[0].id)) donor.tables.ultimate_specials.push(rows[0]);
        }
        G.importOwned(p, donor, ["special_sets", "specials", "card_specials", "card_motions", "ultimate_specials", "active_skill_sets", "active_skills", "card_active_skills", "dokkan_field_active_skill_set_relations", "standby_skill_sets", "standby_skills", "card_standby_skill_set_relations", "finish_specials", "finish_skill_sets", "finish_skills", "card_finish_skill_set_relations", "standby_skill_set_finish_skill_set_relations"]);
      }
      if (window.ForgeBuilderUI && ForgeBuilderUI.refreshTexts && state.builder) ForgeBuilderUI.refreshTexts();
      scheduleSave();
      renderEditor();
      if (!merged) toast((kind === "passive" && mode === "replace" ? "Replaced your passive with " : "Copied ") + card.name + "’s " + kind + ".");
    });
    if (merged) dialog("Added " + card.name + "’s passive", "<p>" + esc(ForgePassiveMerge.summary(merged) || "Nothing new to add — your passive already has these abilities.") + "</p>" + (merged.tidy ? '<ul class="porg-summary">' + ForgePassiveMerge.organizeSummary(merged.tidy).slice(1).map((l) => "<li>" + esc(l) + "</li>").join("") + "</ul>" : "") + '<p class="hint">The in-game description was updated to match. Check it on the Passive Skill tab.</p>');
  }
  async function chooseKitStage(kind, card) {
    if (!["leader", "passive"].includes(kind)) return copyKit(kind, card);
    const p = state.project;
    let donor;
    await busy("Reading " + card.name + "’s awakening abilities", async () => {
      donor = await Forge.loadTemplate((o) => Native.call("query", o), state.info.schema, card.id, p.targetId);
    });
    if (state.project !== p) throw Error("The selected creation changed. Choose its source again.");
    const stages = G.abilityStages(donor).filter((stage) => G.stageSet(donor, stage.id, kind));
    if (!stages.length) throw Error("This character has no " + kind + " skill. Choose another character.");
    const passive = kind === "passive" && !!window.ForgePassiveMerge;
    if (stages.length === 1 && !passive) return copyKit(kind, card, stages[0].id, donor);
    const stagePick = stages.length > 1 ? '<label class="field">Source awakening stage<select id="copy-kit-stage">' + selection(stages.map((stage) => [stage.id, stage.label]), stages[stages.length - 1].id) + "</select></label>" : '<input type="hidden" id="copy-kit-stage" value="' + esc(stages[0].id) + '">';
    const buttons = passive ? '<div class="row"><button class="button" id="copy-kit-apply">＋ Add to my passive</button><button class="button ghost" id="copy-kit-replace">Replace my passive</button></div><p class="hint">Add keeps your current abilities. Matching abilities are combined into one, kept within today’s meta, and the description is rewritten to match.</p>' : '<button class="button" id="copy-kit-apply">Use this stage’s ' + kind + " ability</button>";
    dialog("Copy " + card.name + "’s " + kind, (stages.length > 1 ? "<p>Choose which awakening stage to copy from.</p>" : "") + stagePick + '<h3 id="copy-kit-name"></h3><p id="copy-kit-description" class="guide-source-description"></p>' + buttons);
    const update = () => {
      const set = G.stageSet(donor, $("#copy-kit-stage").value, kind);
      $("#copy-kit-name").textContent = set.name || "Inherited ability";
      $("#copy-kit-description").textContent = readableAbilityDescription(set.itemized_description || set.description || "This source has no displayed description.");
    };
    $("#copy-kit-stage").onchange = update;
    update();
    const go = (mode) => {
      const sourceStage = $("#copy-kit-stage").value;
      $("#dialog").close();
      if (state.project !== p) return error(Error("The selected creation changed. Choose its source again."));
      copyKit(kind, card, sourceStage, donor, mode).catch(error);
    };
    $("#copy-kit-apply").onclick = () => go(passive ? "add" : "replace");
    if ($("#copy-kit-replace")) $("#copy-kit-replace").onclick = () => go("replace");
  }
  async function loadConditions() {
    if (state.conditionLoaded) return;
    if (state.conditionLoading) return state.conditionLoading;
    const revision = state.lookupRevision || 0;
    const pending = (async () => {
      const read = async (table) => {
        if (!state.info.schema[table]) return [];
        const all = [];
        for (let offset = 0; ; offset += 5e3) {
          const rows = await Native.call("query", { table, limit: 5e3, offset });
          all.push(...rows);
          if (rows.length < 5e3) return all;
        }
      };
      const [conditions2, characters, domains] = await Promise.all([read("skill_causalities"), read("card_unique_infos"), read("dokkan_fields")]);
      if (revision !== (state.lookupRevision || 0)) throw new Error("Game data changed. Open the conditions again.");
      state.conditionRows = conditions2;
      state.conditionCharacters = characters;
      state.conditionDomains = domains;
      G.references.links = Object.fromEntries(state.links.map((row) => [row.id, row.name]));
      G.references.categories = Object.fromEntries(state.categories.map((row) => [row.id, row.name]));
      G.references.characters = Object.fromEntries(characters.map((row) => [row.id, row.name]));
      G.references.domains = Object.fromEntries(domains.map((row) => [row.id, row.name]));
      state.conditionLoaded = true;
    })();
    state.conditionLoading = pending;
    try {
      return await pending;
    } finally {
      if (state.conditionLoading === pending) state.conditionLoading = null;
    }
  }
  async function copyConditionFromCharacter(effectId, card) {
    const p = state.project, row = p.tables.passive_skills.find((value) => value.id === effectId);
    if (!row) throw Error("This effect is no longer available.");
    let donor;
    await busy("Reading " + card.name + "’s activation rules", async () => {
      await loadConditions();
      donor = await Forge.loadTemplate((o) => Native.call("query", o), state.info.schema, card.id, p.targetId);
    });
    if (state.project !== p || !p.tables.passive_skills.includes(row)) throw Error("The selected creation changed. Choose its effect again.");
    const records = [...state.conditionRows, ...donor.tables.skill_causalities || []], choices = [];
    for (const stage of G.abilityStages(donor)) {
      const set = G.stageSet(donor, stage.id, "passive");
      if (!set) continue;
      const ids = new Set((donor.tables.passive_skill_set_relations || []).filter((rel) => rel.passive_skill_set_id === set.id).map((rel) => rel.passive_skill_id));
      for (const skill of donor.tables.passive_skills || []) if (ids.has(skill.id) && skill.causality_conditions) {
        try {
          const group = G.conditionGroup(skill, records);
          choices.push({ group, skill, set, stage });
        } catch {
        }
      }
    }
    if (!choices.length) {
      dialog("No reusable activation rules", "<p>" + esc(card.name) + " has no compatible conditional passive effects in this database. Copy the complete passive to retain specialized gameplay setup, or choose a guided condition.</p>");
      return;
    }
    dialog("Copy activation rules from " + card.name, '<p>Choose an ability by name. This replaces only the selected effect’s activation conditions, including its complete AND / OR / NOT groups. Timing, chance, duration and gameplay effects stay as you set them. Rules that depend on another mechanic still need that mechanic on your creation.</p><label class="field">Source ability<select id="condition-copy-choice">' + selection(choices.map((choice, index) => [index, choice.stage.label + " · " + (choice.set.name || "Passive ability") + " · " + G.effectSummary(choice.skill)]), 0) + '</select></label><p id="condition-copy-description" class="hint guide-source-description"></p><p id="condition-copy-rules"></p><button class="button" id="condition-copy-apply">Use this complete condition group</button>');
    const update = () => {
      const choice = choices[Number($("#condition-copy-choice").value)];
      $("#condition-copy-description").textContent = readableAbilityDescription(choice.set.itemized_description || choice.set.description || "Inherited passive ability");
      $("#condition-copy-rules").textContent = G.describeCondition(choice.skill.causality_conditions, records, D.conditionTypes);
    };
    $("#condition-copy-choice").onchange = update;
    update();
    $("#condition-copy-apply").onclick = () => {
      try {
        if (state.project !== p || !p.tables.passive_skills.includes(row)) throw Error("The selected creation changed. Choose its effect again.");
        G.setCondition(p, state.info.schema, row, [{ copied: choices[Number($("#condition-copy-choice").value)].group }]);
        $("#dialog").close();
        scheduleSave();
        renderEditor();
        toast("Copied the complete activation-rule group from " + card.name + ".");
      } catch (e) {
        error(e);
      }
    };
  }
  async function conditions(id) {
    var _a2, _b;
    const projectKey = (_a2 = state.project) == null ? void 0 : _a2.key;
    await loadConditions();
    if (((_b = state.project) == null ? void 0 : _b.key) !== projectKey || state.view !== "editor") return;
    const p = state.project, row = p.tables.passive_skills.find((value) => value.id === id);
    if (!row) throw new Error("This effect is no longer available.");
    const rows = [...state.conditionRows, ...p.tables.skill_causalities || []], C = ForgeConditions;
    let rules = [], dirty = false;
    try {
      if (row.causality_conditions) {
        const parsed = JSON.parse(row.causality_conditions);
        rules = [{ expression: C.expression(parsed.compiled) }];
      }
    } catch {
      throw new Error("Keep this specialized source condition, or copy another character’s ability. Its rule format cannot be changed safely here.");
    }
    dialog("Choose when this effect activates", "<p>Current: " + esc(G.describeCondition(row.causality_conditions, rows, D.conditionTypes)) + '</p><p>Your existing rules are kept together. Add a named rule, remove a group, or explicitly choose Always before applying.</p><label class="field">New rule<select id="condition-type">' + selection(C.definitions.map((def) => [def.type, def.label]), 2) + '</select></label><div class="field-grid condition-fields" id="condition-fields"></div><div class="row"><button class="button ghost" id="condition-add">Add rule</button><button class="button subtle" id="condition-clear">Always · remove all conditions</button><label class="field">Match<select id="condition-mode"><option value="all">All rules (AND)</option><option value="any">Any rule (OR)</option></select></label></div><div id="condition-rules" role="status" aria-live="polite"></div><details><summary>Reuse other named source conditions</summary><p class="hint">These preserve an existing game rule, including specialized settings. Uncertain source-only flags are kept intact rather than guessed.</p><label class="field">Search conditions<input id="condition-search" placeholder="Super Attack, Ki, enemy…"></label><div id="condition-results"></div></details><button class="button" id="condition-apply" disabled>Apply these conditions</button>');
    const lookupRows = (source) => source === "links" ? state.links : source === "categories" ? state.categories : source === "characters" ? state.conditionCharacters : state.conditionDomains;
    const fields = () => {
      const def = C.definitions.find((value) => value.type === Number($("#condition-type").value));
      $("#condition-fields").innerHTML = def.fields.length ? def.fields.map((field2) => {
        var _a3;
        const valueId = field2.index === 0 ? "condition-value" : "condition-value-" + field2.index;
        if (field2.kind === "number") return '<label class="field">' + esc(field2.label) + '<input id="' + valueId + '" data-condition-value="' + field2.index + '" type="number" min="' + field2.min + '" max="' + field2.max + '" step="1" value="' + field2.value + '"></label>';
        if (field2.kind === "choice") return '<label class="field">' + esc(field2.label) + '<select id="' + valueId + '" data-condition-value="' + field2.index + '">' + selection(field2.options, field2.value) + "</select></label>";
        const named = lookupRows(field2.source).filter((value) => String(value.name || "").trim() && value.name !== "0").slice().sort((a, b) => a.name.localeCompare(b.name));
        return '<div class="field"><label for="' + valueId + '">' + esc(field2.label) + '</label><input type="search" data-condition-filter="' + field2.index + '" aria-label="Filter ' + esc(field2.label.toLowerCase()) + ' names" placeholder="Find a name…"><select id="' + valueId + '" data-condition-value="' + field2.index + '">' + selection(named.map((value) => [value.id, value.name]), (_a3 = named[0]) == null ? void 0 : _a3.id) + "</select></div>";
      }).join("") : '<p class="hint">This rule needs no extra settings.</p>';
      $("#condition-fields").querySelectorAll("[data-condition-filter]").forEach((input) => input.oninput = () => {
        const field2 = def.fields.find((value) => value.index === Number(input.dataset.conditionFilter)), select2 = $('[data-condition-value="' + field2.index + '"]'), q = input.value.trim().toLocaleLowerCase(), named = lookupRows(field2.source).filter((value) => value.name !== "0" && String(value.name || "").toLocaleLowerCase().includes(q)).sort((a, b) => a.name.localeCompare(b.name)), previous = select2.value;
        select2.innerHTML = named.length ? selection(named.map((value) => [value.id, value.name]), previous) : '<option value="">No matching names</option>';
      });
    };
    const render = () => {
      $("#condition-rules").innerHTML = rules.length ? rules.map((rule, i) => {
        const label = rule.expression !== void 0 ? "Original rule group: " + G.describeCondition(JSON.stringify({ compiled: rule.expression }), rows, D.conditionTypes) : rule.existingId !== void 0 ? G.conditionLabel(rows.find((value) => value.id === rule.existingId), D.conditionTypes) : G.conditionLabel({ causality_type: rule.type, cau_val1: rule.values[0], cau_val2: rule.values[1], cau_val3: rule.values[2] }, D.conditionTypes);
        return "<p>" + esc(label) + ' <button class="icon-button" data-drop-rule="' + i + '" aria-label="Remove this condition">×</button></p>';
      }).join("") : '<p class="hint">Always · no activation conditions.</p>';
      $("#condition-apply").disabled = !dirty;
      $("#condition-rules").querySelectorAll("[data-drop-rule]").forEach((button2) => button2.onclick = () => {
        rules.splice(Number(button2.dataset.dropRule), 1);
        dirty = true;
        render();
      });
    };
    $("#condition-type").onchange = fields;
    $("#condition-add").onclick = () => {
      try {
        const type = Number($("#condition-type").value), input = [0, 0, 0];
        $("#condition-fields").querySelectorAll("[data-condition-value]").forEach((element) => input[Number(element.dataset.conditionValue)] = element.value);
        const rule = C.makeRule(type, input);
        if (type === 0) rules = [];
        else {
          if (rules.length >= 64) throw new Error("Use up to 64 condition groups.");
          rules.push(rule);
        }
        dirty = true;
        render();
      } catch (error2) {
        toast(error2.message, true);
      }
    };
    $("#condition-clear").onclick = () => {
      rules = [];
      dirty = true;
      render();
    };
    $("#condition-mode").onchange = () => {
      dirty = true;
      render();
    };
    $("#condition-apply").onclick = () => {
      try {
        G.setCondition(p, state.info.schema, row, rules, $("#condition-mode").value);
        $("#dialog").close();
        scheduleSave();
        renderEditor();
      } catch (error2) {
        toast(error2.message, true);
      }
    };
    $("#condition-search").oninput = () => {
      const q = $("#condition-search").value.toLocaleLowerCase(), matches = rows.map((value) => ({ row: value, label: G.conditionLabel(value, D.conditionTypes) })).filter((value) => value.label.toLocaleLowerCase().includes(q)).slice(0, 35);
      $("#condition-results").innerHTML = matches.map((value) => '<button class="guide-condition" data-existing-rule="' + value.row.id + '">' + esc(value.label) + "</button>").join("");
      $("#condition-results").querySelectorAll("[data-existing-rule]").forEach((button2) => button2.onclick = () => {
        if (rules.length >= 64) return toast("Use up to 64 condition groups.", true);
        rules.push({ existingId: Number(button2.dataset.existingRule) });
        dirty = true;
        render();
      });
    };
    fields();
    render();
  }
  function glossary() {
    dialog("Your beginner guide", '<div class="guide-glossary">' + [["Getting started", "Choose a source character, edit its battle abilities and moves, then Save & play. Your changes save automatically."], ["Stats", "HP is health. ATK is attack power. DEF is defense. Stat bonuses in battle come from your actual ability effects."], ["Descriptions and effects", "Descriptions are the words shown in the game. Effects are the settings that actually change gameplay. Use “Write a description from my effects” to keep them aligned."], ["Animations", "A visual sequence for a move. Browse by character, preview it, then select it or combine sections in the animation editor."], ["Conditions", "Rules for when an effect activates, such as HP below 50%. AND means all rules; OR means at least one rule."], ["Scripts", "Behind-the-scenes animation instructions. The app generates these from the visual editor; you do not need to write them."], ["IDs and file paths", "Internal reference numbers and storage locations. The app manages these automatically in Beginner mode."], ["Super, Ultra, and EX", "These are gameplay move types. An EX/Extra animation slot also needs the game’s EX mechanics. Start with an EX character template to inherit that setup."], ["Borrowing another move", "Choosing an animation changes its visuals. Copying a move or passive copies gameplay records as well. Form changes can still use original game characters."], ["Files to save", "ECLP installs in Eclipse. JSON is your editable project backup. ECLP/ZIP can include attached files; SQL alone contains database changes."], ["Previews", "The app saves the player and loaded resources on this device. Load and play a move online once, then use Offline preview. Missing resources still need downloading; actual in-game playback can differ."], ["Expert mode", "Optional access to all inherited tables, IDs, paths, and JSON. Beginner mode keeps these settings intact while showing visual choices."]].map(([title, text]) => "<h3>" + esc(title) + "</h3><p>" + esc(text) + "</p>").join("") + "</div>");
  }
  async function guideAction(name) {
    var _a2, _b;
    if (name === "undo") return undo();
    if (name === "redo") return undo(true);
    if (name === "mode") {
      state.expert = !state.expert;
      localStorage.setItem("forge-expert", String(state.expert));
      renderEditor();
      return;
    }
    if (name === "help") return glossary();
    if(name.startsWith("gallery:"))return ForgeAnimationGallery.show({unit:state.project,target:name.slice(8)});
    if (name === "studio" || name.startsWith("studio:")) {
      if(window.ForgeAnimationGallery)await ForgeAnimationGallery.exit();
      state.studioTarget = name.startsWith("studio:") ? name.slice(7) : null;
      state.studioMode = ((_b = (_a2 = state.project) == null ? void 0 : _a2.animationStudio) == null ? void 0 : _b.clips.length) ? "compose" : "browse";
      return navigate("animations");
    }
    if (name === "resources") return navigate("assets");
    if (name === "ex-templates") {
      state.studioKind = "ex";
      state.studioMode = "browse";
      state.studioTarget = null;
      return navigate("animations");
    }
    if (name === "browse-examples") {
      state.studioKind = "all";
      return navigate("animations");
    }
    if (name === "restore-dodge") {
      state.project.sharedActionsUpdateRequired = true;
      ForgeActionHooks.remove(state.project);
      scheduleSave();
      renderEditor();
      toast("Inherited Dodge restored. Update shared actions from your Library before testing in Eclipse.");
      return;
    }
    if (name.startsWith("restore-ability:")) {
      G.restoreAbilityAnimation(state.project, name.slice(16));
      scheduleSave();
      renderEditor();
      toast("The original animations for this ability were restored.");
      return;
    }
    if (name.startsWith("copy-condition:")) {
      const id = Number(name.slice(15));
      return pickUnit("Choose a character’s activation rules", (card) => copyConditionFromCharacter(id, card));
    }
    if (name.startsWith("conditions:")) return conditions(Number(name.slice(11)));
    if (name === "copy:move" && window.ForgeSuperAttacks) return ForgeSuperAttacks.pick();
    if (name.startsWith("copy:")) return pickUnit("Copy " + name.slice(5) + " from a character", (c) => chooseKitStage(name.slice(5), c));
    if (name === "game-art") return ForgeArtEditor.open();
    if (name === "battle-poses") return ForgeBattlePoseEditor.open();
    if (name === "preview-game-art") {
      return ForgeArtEditor.preview();
    }
    if (name === "pick-art" || name === "pick-aura") return pickUnit(name === "pick-art" ? "Choose game artwork" : "Choose an aura", (c) => {
      var _a3;
      const p = state.project;
      p.uiLabels = p.uiLabels || {};
      if (name === "pick-art") {
        if (p.artBinding) ForgeArt.restore(p);
        p.cardOverrides.resource_id = c.resource_id || Math.floor(Number(c.id) / 10) * 10;
        p.cardOverrides.bg_effect_id = (_a3 = c.bg_effect_id) != null ? _a3 : null;
        p.uiLabels.art = c.name;
        p.uiLabels.artCardId = c.id;
        state.previewUrl = "";
        delete p.previewKey;
      } else {
        dialog("Preview " + c.name + "’s aura", "<p>View the aura before applying it. The character’s aura size and placement are copied together.</p>" + button("Preview aura", "unused") + '<button class="button" id="apply-aura">Use this aura</button>');
        const preview = $("#dialog [data-guide]");
        preview.onclick = async () => {
          try {
            const result = await Native.call("animationVisuals", { unitId: c.id }), aura = result.items.find((v) => v.name.endsWith(" · Aura"));
            if (!aura) return toast("This character has no public aura preview available.", true);
            await Native.call("previewAnimation", { mode: "pack", resourcePath: aura.path, scene: aura.scene, name: aura.name });
          } catch (e) {
            toast(e.message, true);
          }
        };
        $("#apply-aura").onclick = () => {
          for (const key of ["aura_id", "aura_scale", "aura_offset_x", "aura_offset_y", "is_aura_front"]) p.cardOverrides[key] = c[key];
          p.uiLabels.aura = c.aura_id ? c.name + "’s aura" : "No special aura (from " + c.name + ")";
          $("#dialog").close();
          scheduleSave();
          renderEditor();
        };
        return;
      }
      scheduleSave();
      renderEditor();
    });
    if (name.startsWith("form:")) return pickUnit("Choose transformed character", (c) => {
      const row = state.project.tables.passive_skills.find((r) => r.id === Number(name.slice(5)));
      row.eff_value1 = c.id;
      scheduleSave();
      renderEditor();
    }, { allVersions: true });
    if (name === "pick-preview") {
      await importFile();
      state.assetTab = "local";
      await navigate("assets");
      toast("Choose Preview image beside an imported image to view it or use it in the editor.");
      return;
    }
    if (name.startsWith("pick-animation:")) {
      state.studioTarget = name.slice(15);
      state.studioMode = "browse";
      state.studioKind = "all";
      return navigate("animations");
    }
    if (name.startsWith("preview-target:")) return previewTarget(name.slice(15));
    if (name === "match-eza") {
      for (const stage of state.project.tables.optimal_awakening_growths || []) {
        stage.passive_skill_set_id = Forge.card(state.project).passive_skill_set_id;
        stage.leader_skill_set_id = Forge.card(state.project).leader_skill_set_id;
      }
      scheduleSave();
      renderEditor();
      toast("Your current base leader and passive are now used at all inherited EZA stages.");
      return;
    }
    if (name === "leader-easy") {
      if (state.leaderDraftScope === "category") {
        const category = state.categories.find((row) => {
          var _a3;
          return row.id === Number((_a3 = $("#leader-category")) == null ? void 0 : _a3.value);
        });
        if (!category) throw Error("Choose a team category.");
        const project = state.project, stage = currentAbilityStage(), targets = [];
        await busy("Preparing category leadership", async () => {
          for (let offset = 0; ; offset += 5e3) {
            const rows = await Native.call("query", { table: "sub_target_types", offset, limit: 5e3 });
            targets.push(...rows);
            if (rows.length < 5e3) break;
          }
          if (state.project !== project || currentAbilityStage() !== stage) throw Error("The selected unit or awakening stage changed. Choose the bonuses again.");
          editAbility("leader", (p) => {
            var _a3, _b2;
            return G.categoryLeader(p, category, targets, (_a3 = state.leaderDraftKi) != null ? _a3 : 3, (_b2 = state.leaderDraftStats) != null ? _b2 : 170);
          });
        });
      } else editAbility("leader", (p) => {
        var _a3, _b2;
        return Forge.allTypesLeader(p, (_a3 = state.leaderDraftKi) != null ? _a3 : 3, (_b2 = state.leaderDraftStats) != null ? _b2 : 170);
      });
      scheduleSave();
      renderEditor();
      return;
    }
    if (name.startsWith("stats:")) {
      const c = state.project.tables.cards[0], mode = name.slice(6);
      for (const stat of ["hp", "atk", "def"]) state.project.cardOverrides[stat + "_max"] = Math.round(Number(c[stat + "_max"]) * (mode === "source" ? 1 : mode === "balanced" ? 1.15 : mode === "attack" ? stat === "atk" ? 1.35 : 1.05 : stat === "def" ? 1.4 : 1.05));
      scheduleSave();
      renderEditor();
      return;
    }
    if (name === "summarize") {
      await loadConditions();
      const p = state.project, set = selectedAbility("passive");
      if (!set) return;
      const ids = new Set((p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === set.id).map((r) => r.passive_skill_id));
      const known = [...state.conditionRows, ...p.tables.skill_causalities || []], rows = (p.tables.passive_skills || []).filter((r) => ids.has(r.id));
      if (window.ForgeBuilder) {
        // the official "*When…*\n- effect" layout; the same abilities at the same moment are added up
        const describe = (r) => { if (!r.causality_conditions) return ""; const t = G.describeCondition(r.causality_conditions, known, D.conditionTypes); return /^Always$/.test(t) ? "" : t.replace(/^\((.*)\)$/, "$1"); };
        describe.extra = () => ({});
        set.itemized_description = ForgeBuilder.passiveText(rows, describe);
        if (p.builderLines) delete p.builderLines[set.id];
      } else set.itemized_description = rows.map((r) => G.effectSummary(r) + " (" + G.describeCondition(r.causality_conditions, known, D.conditionTypes) + ")").join("; ");
      scheduleSave();
      renderEditor();
      return;
    }
    if (name === "explain-effects") {
      await loadConditions();
      renderEditor();
      dialog("Understanding your effects", "<p>Effects change gameplay; the description is a separate label. Expand an effect’s timing controls to choose when, how often, and for whom it activates. Inherited specialized effects are preserved.</p>");
      return;
    }
  if(name==='add-battle-buff'){const project=state.project,stage=currentAbilityStage();dialog('Add a battle ability','<p>Choose a documented game effect. These abilities use the selected recipients, activation chance and duration; conditions can be added afterward.</p><div class="field-grid"><label class="field">Ability<select id="battle-buff-kind">'+selection(G.battleBuffKinds,50)+'</select></label><label class="field">Recipients<select id="battle-buff-recipients">'+selection([['self','This character'],['allies','All allies']],'self')+'</select></label><label class="field">Chance to activate (%)<input id="battle-buff-chance" type="number" min="0" max="100" step="1" value="100"></label><label class="field">Duration<select id="battle-buff-turns">'+selection([[1,'This turn'],[2,'2 turns'],[3,'3 turns'],[4,'4 turns'],[5,'5 turns'],[99,'99 turns']],99)+'</select></label></div><p class="hint" id="battle-buff-explanation" role="status">Prevents status effects using the game’s broad protection effect. Individual immunity types are not selected here.</p><button class="button" id="battle-buff-add">Add battle ability</button>');$('#battle-buff-kind').onchange=()=>{const kind=Number($('#battle-buff-kind').value);$('#battle-buff-turns').value=kind===50?'99':'1';$('#battle-buff-explanation').textContent=kind===50?'Prevents status effects using the game’s broad protection effect. Individual immunity types are not selected here.':'Attacks are effective against all Types while this effect is active.';};$('#battle-buff-add').onclick=()=>{try{if(state.project!==project||currentAbilityStage()!==stage)throw new Error('The selected unit or awakening stage changed. Add the battle ability again.');if(!$('#battle-buff-chance').value)throw new Error('Choose a whole activation chance.');editAbility('passive',p=>G.addBattleBuff(p,Number($('#battle-buff-kind').value),{recipients:$('#battle-buff-recipients').value,chance:Number($('#battle-buff-chance').value),turns:Number($('#battle-buff-turns').value)}));$('#dialog').close();scheduleSave();renderEditor();}catch(e){error(e);}};return;}
  if(name==='add-color-sphere-bonus'){const project=state.project,stage=currentAbilityStage(),sourceType=Number(Forge.card(project).element)%10;dialog('Add a matching-color sphere bonus','<p>This source-supported bonus counts only matching-color Ki Spheres and applies only to characters of the same selected type. It does not change sphere colors.</p><div class="field-grid"><label class="field">Bonus<select id="color-sphere-kind">'+selection(G.colorSphereKinds,64)+'</select></label><label class="field">Matching character type and Ki Sphere color<select id="color-sphere-type">'+selection(G.colorSphereOptions(64),Number.isInteger(sourceType)&&sourceType>=0&&sourceType<5?sourceType:0)+'</select></label><label class="field">Bonus per matching sphere (%)<input id="color-sphere-amount" type="number" min="0" max="1000" step="1" value="10"></label></div><p class="hint">Only combinations found in the game data are offered. Combined ATK & DEF uses one amount for both stats. Activation conditions, chance and timing can be adjusted after adding the effect.</p><button class="button" id="color-sphere-add">Add matching-color bonus</button>');$('#color-sphere-kind').onchange=()=>{const options=G.colorSphereOptions(Number($('#color-sphere-kind').value)),previous=Number($('#color-sphere-type').value);$('#color-sphere-type').innerHTML=selection(options,options.some(([id])=>id===previous)?previous:options[0]?.[0]);};$('#color-sphere-add').onclick=()=>{try{if(state.project!==project||currentAbilityStage()!==stage)throw new Error('The selected unit or awakening stage changed. Add the color bonus again.');if(!$('#color-sphere-amount').value)throw new Error('Choose a whole bonus per matching sphere.');editAbility('passive',p=>G.addColorSphereBonus(p,Number($('#color-sphere-kind').value),Number($('#color-sphere-type').value),Number($('#color-sphere-amount').value)));$('#dialog').close();scheduleSave();renderEditor();}catch(e){error(e);}};return;}
  if(name==='add-sphere-bonus'){const project=state.project,stage=currentAbilityStage();dialog('Add a bonus per Ki Sphere','<p>Give this unit a percentage bonus for each Ki Sphere obtained. You can change the activation conditions and timing afterward.</p><div class="field-grid"><label class="field">Bonus<select id="sphere-bonus-kind">'+selection(G.sphereBonusKinds,61)+'</select></label><label class="field"><span id="sphere-bonus-amount-label">ATK bonus per sphere (%)</span><input id="sphere-bonus-amount" type="number" min="0" max="1000" step="1" value="10"></label><label class="field" id="sphere-bonus-defense-field">DEF bonus per sphere (%)<input id="sphere-bonus-defense" type="number" min="0" max="1000" step="1" value="10"></label></div><button class="button" id="sphere-bonus-add">Add per-sphere effect</button>');$('#sphere-bonus-kind').onchange=()=>{const kind=Number($('#sphere-bonus-kind').value);$('#sphere-bonus-defense-field').hidden=kind!==61;$('#sphere-bonus-amount-label').textContent=(kind===60?'DEF':'ATK')+' bonus per sphere (%)';};$('#sphere-bonus-add').onclick=()=>{try{if(state.project!==project||currentAbilityStage()!==stage)throw new Error('The selected unit or awakening stage changed. Add the per-sphere bonus again.');const kind=Number($('#sphere-bonus-kind').value);if(!$('#sphere-bonus-amount').value||kind===61&&!$('#sphere-bonus-defense').value)throw new Error('Choose whole bonus amounts.');editAbility('passive',p=>G.addSphereBonus(p,kind,Number($('#sphere-bonus-amount').value),Number($('#sphere-bonus-defense').value)));$('#dialog').close();scheduleSave();renderEditor();}catch(e){error(e);}};return;}
  if(name==='add-type-support'){const project=state.project,stage=currentAbilityStage();dialog('Add type-specific support','<p>Give allies of one named type a stat or Ki bonus. You can adjust recipients, conditions and timing afterward.</p><div class="field-grid"><label class="field">Support bonus<select id="support-kind">'+selection(G.typeSupportKinds,18)+'</select></label><label class="field">Character type<select id="support-type">'+selection(G.sphereTypes.slice(0,5).map((label,index)=>[index,label]),0)+'</select></label><label class="field"><span id="support-amount-label">ATK bonus (%)</span><input id="support-amount" type="number" min="0" max="1000" step="1" value="30"></label><label class="field" id="support-defense-field">DEF bonus (%)<input id="support-defense" type="number" min="0" max="1000" step="1" value="30"></label></div><button class="button" id="support-add">Add support effect</button>');$('#support-kind').onchange=()=>{const kind=Number($('#support-kind').value);$('#support-defense-field').hidden=kind!==18;$('#support-amount-label').textContent=kind===20?'Ki gained':(kind===17?'DEF':'ATK')+' bonus (%)';$('#support-amount').max=kind===20?'24':'1000';$('#support-amount').value=kind===20?'3':'30';};$('#support-add').onclick=()=>{try{if(state.project!==project||currentAbilityStage()!==stage)throw new Error('The selected unit or awakening stage changed. Add support again.');if(!$('#support-amount').value||Number($('#support-kind').value)===18&&!$('#support-defense').value)throw new Error('Choose whole bonus amounts.');editAbility('passive',p=>G.addTypeSupport(p,Number($('#support-kind').value),Number($('#support-type').value),Number($('#support-amount').value),Number($('#support-defense').value)));$('#dialog').close();scheduleSave();renderEditor();}catch(e){error(e);}};return;}
  if(name==='add-sphere-change'){editAbility('passive',p=>G.addKiSphereChange(p));scheduleSave();renderEditor();return;}
    if (name === "add-counter") {
      state.studioKind = "counter";
      state.studioMode = "browse";
      state.studioCounterProfile = true;
      return navigate("animations");
    }
  }
  async function previewTarget(key) {
    var _a2, _b, _c, _d, _e, _f;
    if (key === "dodge:unit") {
      const hook = (_a2 = state.project.actionHooks) == null ? void 0 : _a2.dodge;
      if (!hook) throw new Error("Apply a custom dodge sequence in the animation editor first.");
      return Native.call("previewAnimation", { name: hook.name, text: ForgeMotion.compile(hook.clips, { damage: false, role: "defender", music: hook.music }), ...ForgePreviewBindings.request(state.project, { role: "defender" }) });
    }
    const target = G.targets(state.project).find((t) => t.key === key);
    if (!target) return;
    const actors = ForgePreviewBindings.request(state.project, { role: target.role === "defender" ? "defender" : "attacker" });
    const assignment = (_b = state.project.animationAssignments) == null ? void 0 : _b[key];
    if (assignment) {
      const file = (state.project.generatedFiles || []).find((f) => f.owner === key);
      if (file) return Native.call("previewAnimation", { name: assignment.name, text: file.text, ...actors });
    }
    if (target.virtual) throw new Error("This normal attack uses the game’s built-in motion. Choose an animation or build a sequence in Studio to give this unit its own motion.");
    const row = (_c = state.project.tables[target.table]) == null ? void 0 : _c.find((r) => r.id === target.row);
    if (!row) return;
    let script;
    if (target.kind === "normal") script = row.filename;
    else if (target.kind === "counter") {
      const value = G.numbersFromAbility(row, target.table)[0];
      if (!Number.isSafeInteger(value) || value < 1) throw Error("Choose a counterattack animation first.");
      script = "c" + String(Math.trunc(Math.fround(value))).padStart(4, "0");
    } else if (target.kind === "nullify") {
      let values;
      try {
        values = JSON.parse(row.efficacy_values || "{}");
      } catch {
      }
      const id = Array.isArray(values) ? values[2] : row[target.field];
      script = "as" + String(Number(id) || 1).padStart(4, "0");
    } else if (["revival", "transform", "giant"].includes(target.kind)) {
      const source = (_d = state.project.abilityAnimationSources) == null ? void 0 : _d[target.sourceKey], override = (_e = state.project.abilityAnimationOverrides) == null ? void 0 : _e[target.sourceKey], view = override ? (_f = state.project.tables[override.table]) == null ? void 0 : _f.find((r) => r.id === override.viewId) : source == null ? void 0 : source.view;
      script = target.kind === "revival" ? view == null ? void 0 : view.script_name : view == null ? void 0 : view[target.phase + "_script_name"];
      if (!script || script === "0") throw new Error(target.kind === "revival" ? "This original revival uses an effect pack. Choose an animation or build a sequence in Studio to customize this revival." : "This form transition uses the game’s built-in visuals. Choose an animation or build a sequence in Studio to customize this transition.");
    } else {
      const table = target.kind === "intro" ? "passive_skill_effects" : "special_views", ref = target.kind === "intro" ? row.passive_skill_effect_id : row[target.field];
      const view = (state.project.tables[table] || []).find((v) => v.id === Number(ref)) || (await Native.call("query", { table, ids: [Number(ref)], limit: 1 }))[0];
      script = view == null ? void 0 : view.script_name;
    }
    if (!script) throw new Error("Choose an animation for this move first.");
    const files = await Native.call("animationFiles"), path = ForgeMotion.pathFor(script, files);
    if (!path) throw new Error("The animation is not in the current public preview resources.");
    return Native.call("previewAnimation", { name: target.name, path, ...actors });
  }
  const help = document.createElement("button");
  help.className = "text-button";
  help.textContent = "Beginner guide";
  help.onclick = glossary;
  (_a = document.querySelector(".sidebar-bottom")) == null ? void 0 : _a.prepend(help);
  window.ForgeGuideUI = { resetHistory, undo, pickUnit, copyKit, conditions, glossary, previewTarget, bindGuide, action: (name) => guideAction(name) };
})();
