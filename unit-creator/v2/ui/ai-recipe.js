(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./core"), require("./guide-model"), require("./motion"));
  else root.ForgeAIRecipe = factory(root.Forge, root.ForgeGuide, root.ForgeMotion);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Forge, Guide, Motion) {
  "use strict";
  const CARD_SCHEMA = "dokkan-card-recipe/1", ANIMATION_SCHEMA = "dokkan-animation-recipe/1", MAX_RECIPE_BYTES = 65536;
  const ABILITY_KINDS = Object.freeze(["atkDef", "ki", "crit", "dodge", "guard", "reduction"]);
  const MOVE_ROLES = Object.freeze(["super", "ultra", "ex", "fullpower", "active", "standby", "finish", "normal", "counter", "dodge", "intro", "transform", "giant", "revival", "nullify"]);
  const RARITIES = Object.freeze({ N:0, R:1, SR:2, SSR:3, UR:4, TUR:4, LR:5 });
  const TYPES = Object.freeze(Object.assign({}, ...Object.entries(Forge.elements).map(([id, name]) => ({ [name.toUpperCase()]: Number(id) }))));
  const has = (value, key) => Object.prototype.hasOwnProperty.call(value, key);
  function fail(message) { throw new Error(message); }
  function integer(value, min, max, label) {
    if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) fail(label + " must be a whole number from " + min + " to " + max + ".");
    return value;
  }
  function text(value, max, label) {
    if (typeof value !== "string" || !value.trim() || value.length > max || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(value)) fail(label + " must be readable text of at most " + max + " characters.");
    return value.trim();
  }
  function object(value, keys, label) {
    if (!value || typeof value !== "object" || Array.isArray(value)) fail(label + " must be an object.");
    for (const key of Object.keys(value)) if (!keys.includes(key)) fail("Unsupported " + label + " field: " + key + ". Do not paste scripts, SQL or internal IDs.");
  }
  // Inspect descriptors before reading values: direct callers cannot introduce
  // accessors, prototypes, executable values or serialization hooks.
  function safeCopy(value, state = { nodes:0, units:0, parents:new Set() }, depth = 0) {
    if (++state.nodes > 4096 || depth > 12) fail("This recipe is too complex. Use a smaller set of edits.");
    if (typeof value === "string") { state.units += value.length; if (state.units > MAX_RECIPE_BYTES) fail("Keep the recipe within 64 KiB."); return value; }
    if (value === null || typeof value === "boolean") return value;
    if (typeof value === "number") { if (!Number.isFinite(value)) fail("Recipe numbers must be finite."); return value; }
    if (!value || typeof value !== "object") fail("Recipes contain JSON values only.");
    if (state.parents.has(value)) fail("Recipes cannot contain circular references.");
    const array = Array.isArray(value), proto = Object.getPrototypeOf(value);
    if (array ? proto !== Array.prototype : proto !== Object.prototype && proto !== null) fail("Recipes contain plain JSON objects only.");
    if (array && value.length > 64) fail("Use at most 64 entries in a recipe list.");
    state.parents.add(value);
    const result = array ? [] : {};
    for (const key of Reflect.ownKeys(value)) {
      if (array && key === "length") continue;
      if (typeof key !== "string" || ["__proto__", "prototype", "constructor"].includes(key)) fail("This recipe contains an unsafe property name.");
      state.units += key.length; if (state.units > MAX_RECIPE_BYTES) fail("Keep the recipe within 64 KiB.");
      const descriptor = Object.getOwnPropertyDescriptor(value, key);
      if (!descriptor.enumerable || !has(descriptor, "value")) fail("Recipes cannot contain accessors or hidden properties.");
      if (array && (!/^(?:0|[1-9][0-9]*)$/.test(key) || Number(key) >= value.length)) fail("Recipe lists cannot contain named properties.");
      result[key] = safeCopy(descriptor.value, state, depth + 1);
    }
    if (array && (result.length !== value.length || Array.from({length:value.length},(_,index)=>index).some(index=>!has(value,index)))) fail("Recipe lists cannot contain empty entries.");
    state.parents.delete(value); return result;
  }
  function rejectDuplicateKeys(raw) {
    let pos = 0;
    const space = () => { while (/\s/.test(raw[pos] || "") && pos < raw.length) pos++; };
    function string() {
      const start = pos++;
      while (pos < raw.length) { const c = raw[pos++]; if (c === "\\") pos++; else if (c === '"') return JSON.parse(raw.slice(start, pos)); }
      fail("Use complete JSON text.");
    }
    function value(depth) {
      if (depth > 12) fail("This recipe is too deeply nested.");
      space();
      if (raw[pos] === '"') { string(); return; }
      if (raw[pos] === "{") {
        pos++; space(); const keys = new Set();
        while (raw[pos] !== "}") {
          const key = string(); if (keys.has(key)) fail("A recipe repeats the field " + key + ". Keep one explicit value."); keys.add(key);
          space(); pos++; value(depth + 1); space(); if (raw[pos] === "}") break; pos++; space();
        }
        pos++; return;
      }
      if (raw[pos] === "[") { pos++; space(); while (raw[pos] !== "]") { value(depth + 1); space(); if (raw[pos] === "]") break; pos++; } pos++; return; }
      while (pos < raw.length && !/[\s,}\]]/.test(raw[pos])) pos++;
    }
    value(0);
  }
  function parse(paste) {
    if (typeof paste !== "string" || paste.length > MAX_RECIPE_BYTES || !paste.trim() || new TextEncoder().encode(paste).length > MAX_RECIPE_BYTES) fail("Paste up to 64 KiB of recipe JSON.");
    let raw = paste.trim();
    if (raw.startsWith("```")) {
      const fence = raw.match(/^```(?:json)?[ \t]*\r?\n([\s\S]*?)\r?\n```$/i);
      if (!fence) fail("Paste one complete JSON block, without surrounding commentary."); raw = fence[1].trim();
    }
    let value; try { value = JSON.parse(raw); } catch { fail("This is not valid JSON. Ask the assistant for the recipe block only."); }
    rejectDuplicateKeys(raw); return validate(value);
  }
  function validate(input) {
    const recipe = safeCopy(input);
    if (new TextEncoder().encode(JSON.stringify(recipe)).length > MAX_RECIPE_BYTES) fail("Keep the recipe within 64 KiB.");
    if (!recipe || typeof recipe !== "object" || Array.isArray(recipe)) fail("Paste a card or animation recipe object.");
    if (recipe.schema === CARD_SCHEMA) {
      object(recipe, ["schema","baseCharacter","name","notes","stats","rarity","type","leader","abilities","passiveMode","moves","artPrompt"], "card recipe");
      for (const [key, max] of [["baseCharacter",200],["name",160],["notes",4000],["artPrompt",4000]]) if (has(recipe,key)) recipe[key] = text(recipe[key],max,key);
      if (has(recipe,"stats")) { object(recipe.stats,["hp","atk","def"],"stats"); if (!Object.keys(recipe.stats).length) fail("Choose at least one stat to edit."); for(const key of Object.keys(recipe.stats)) integer(recipe.stats[key],1,1e9,key.toUpperCase()); }
      if (has(recipe,"rarity")) { recipe.rarity = text(recipe.rarity,10,"Rarity").toUpperCase(); if (!has(RARITIES,recipe.rarity)) fail("Choose rarity N, R, SR, SSR, UR, TUR or LR."); }
      if (has(recipe,"type")) { const key = text(recipe.type,24,"Type").toUpperCase().replace(/\s+/g," "); if (!has(TYPES,key)) fail("Choose a named AGL, TEQ, INT, STR or PHY type, optionally Super or Extreme."); recipe.type = Forge.elements[TYPES[key]]; }
      if (has(recipe,"leader")) { object(recipe.leader,["ki","percent"],"leader"); integer(recipe.leader.ki,0,24,"Leader Ki"); integer(recipe.leader.percent,0,1000,"All-Type leader bonus"); }
      if (has(recipe,"passiveMode") && !["add","replace"].includes(recipe.passiveMode)) fail("Passive mode must be add or replace.");
      if (recipe.passiveMode === "replace" && !has(recipe,"abilities")) fail("Replacing the base passive requires an explicit abilities list.");
      if (has(recipe,"abilities")) {
        if (!Array.isArray(recipe.abilities) || recipe.abilities.length > 6) fail("Use up to six distinct guided abilities.");
        const kinds = new Set();
        for (const ability of recipe.abilities) {
          object(ability,["kind","amount","chance"],"ability"); if (!ABILITY_KINDS.includes(ability.kind) || kinds.has(ability.kind)) fail("Choose distinct supported ability kinds: " + ABILITY_KINDS.join(", ") + "."); kinds.add(ability.kind);
          if (ability.kind === "guard") { if (has(ability,"amount")) fail("Guard uses chance only; omit amount."); }
          else integer(ability.amount,0,ability.kind === "atkDef" ? 1000 : ability.kind === "ki" ? 24 : 100,"Ability amount");
          if (!has(ability,"chance")) ability.chance = 100; integer(ability.chance,0,100,"Ability activation chance");
        }
      }
      if (has(recipe,"moves")) { object(recipe.moves,MOVE_ROLES,"move names"); for(const key of Object.keys(recipe.moves))recipe.moves[key]=text(recipe.moves[key],160,"Move name"); }
    } else if (recipe.schema === ANIMATION_SCHEMA) {
      object(recipe,["schema","order","clips"],"animation recipe");
      if (!has(recipe,"order") && !has(recipe,"clips")) fail("Choose an existing section order or section edits.");
      if (has(recipe,"order")) { if (!Array.isArray(recipe.order) || !recipe.order.length || recipe.order.length > 24) fail("Order must list existing section indices, up to 24."); for(const index of recipe.order)integer(index,0,23,"Section index"); if(new Set(recipe.order).size !== recipe.order.length)fail("List each section index once."); }
      if (has(recipe,"clips")) {
        if (!Array.isArray(recipe.clips) || !recipe.clips.length || recipe.clips.length > 24) fail("Choose up to 24 existing sections to edit."); const indices = new Set();
        for (const clip of recipe.clips) {
          object(clip,["index","from","to","x","y","zoom","rotation","opacity","mirror","mute","actor"],"section edit"); integer(clip.index,0,23,"Section index"); if(indices.has(clip.index))fail("Edit each section index once."); indices.add(clip.index);
          if (Object.keys(clip).length === 1) fail("Choose at least one edit for this section.");
          for(const key of ["from","to","x","y","zoom","rotation","opacity"]) if(has(clip,key) && (typeof clip[key] !== "number" || !Number.isFinite(clip[key])))fail("Section " + key + " must be a finite number.");
          for(const key of ["mirror","mute"])if(has(clip,key) && typeof clip[key] !== "boolean")fail("Section " + key + " must be true or false.");
          if(has(clip,"actor") && !["unit","opponent"].includes(clip.actor))fail("Choose unit or opponent as the section actor.");
        }
      }
    } else fail("Use schema dokkan-card-recipe/1 or dokkan-animation-recipe/1.");
    return recipe;
  }
  function ensureTables(project, schema, names) { for (const name of names) Guide.ensure(project,schema,name); }
  function passiveFields(ability) {
    const fields = { efficacy_type:{atkDef:3,ki:5,crit:90,dodge:91,guard:78,reduction:13}[ability.kind], target_type:1,sub_target_type_set_id:0,exec_game_type:0,exec_timing_type:1,calc_option:["atkDef","reduction"].includes(ability.kind)?2:0,probability:ability.chance,eff_value1:ability.kind === "reduction"?100-ability.amount:ability.kind === "guard"?0:ability.amount,eff_value2:ability.kind === "atkDef"?ability.amount:0,eff_value3:0,efficacy_values:"{}" };
    return fields;
  }
  function abilityText(ability) { return ability.kind === "guard" ? "Guard: " + ability.chance + "% activation" : ({atkDef:"ATK & DEF",ki:"Ki",crit:"Critical hit chance",dodge:"Dodge chance",reduction:"Damage reduction"}[ability.kind]) + " +" + ability.amount + (ability.kind === "ki"?"":"%") + (ability.chance === 100?"":"; " + ability.chance + "% activation"); }
  function renameMoves(project, moves, changes, warnings, pending) {
    const targets = Guide.targets(project), planned = new Map();
    for (const [role,name] of Object.entries(moves || {})) {
      const matches = targets.filter(target=>target.kind === role); let table, row;
      if(matches.length === 1) {
        const target=matches[0];
        if(["super","ultra","ex","fullpower"].includes(role)) { const relation=project.tables.card_specials.find(value=>value.id===target.row);table="special_sets";row=(project.tables.special_sets || []).find(value=>value.id===relation.special_set_id); }
        else if(["active","standby","finish"].includes(role)) { table=target.table;row=(project.tables[table] || []).find(value=>value.id===target.row); }
      }
      if(!row || !project.schema[table]?.some(column=>column.name === "name")) { pending.moves[role]=name;warnings.push("Move name for " + role + " is pending: choose one existing, named move slot in Moves.");continue; }
      if(table === "special_sets") {
        const sharing=targets.filter(target=>target.table === "card_specials" && project.tables.card_specials.find(value=>value.id===target.row)?.special_set_id === row.id);
        if(sharing.some(target=>target.kind !== role && moves[target.kind] !== name)) { pending.moves[role]=name;warnings.push("The " + role + " name shares its game record with another move. Rename it in Moves to review both slots.");continue; }
      }
      const key=table+":"+row.id, previous=planned.get(key);
      if(previous && previous.name !== name)fail("Two recipe names conflict for the same existing move. Choose one name.");
      planned.set(key,{row,name,role});
    }
    for(const {row,name,role} of planned.values()){row.name=name;changes.push("Renamed existing " + role + " move to “" + name + "”. Animation and gameplay settings kept.");}
  }
  function apply(project, input, options = {}) {
    const recipe = typeof input === "string" ? parse(input) : validate(input);
    if (!project || project.format !== "dokkan-unit-forge" || !project.tables?.cards?.[0]) fail("Choose an actual source character before applying an AI recipe.");
    const next=Forge.clone(project), schema=options.schema || next.schema, changes=[], warnings=[], pending={moves:{}};
    if (recipe.schema === ANIMATION_SCHEMA) {
      const studio=next.animationStudio, clips=studio?.clips;
      if(!Array.isArray(clips) || !clips.length)fail("Add original animation sections in the animation editor first.");
      if(recipe.order && (recipe.order.length !== clips.length || recipe.order.some(index=>index>=clips.length)))fail("The order must include every existing section exactly once.");
      for(const edit of recipe.clips || []) {
        if(!clips[edit.index])fail("This recipe names a section that is not in the current sequence.");
        for(const [key,value] of Object.entries(edit))if(key !== "index")clips[edit.index][key]=value;
        changes.push("Edited section " + (edit.index+1) + " using its existing source.");
      }
      if(recipe.order){studio.clips=recipe.order.map(index=>clips[index]);changes.push("Reordered the existing animation sections.");}
      const errors=Motion.validate(studio.clips);if(errors.length)fail(errors.join(" "));
      studio.dirty=true;warnings.push("The sequence draft is updated. Preview it and apply it to a move in the animation editor; existing gameplay assignments are unchanged.");
    } else {
      next.cardOverrides=next.cardOverrides || {};
      if(recipe.baseCharacter){const existing=next.source?.name || next.tables.cards[0].name;if(existing !== recipe.baseCharacter){pending.baseCharacter=recipe.baseCharacter;warnings.push("Base character suggestion: “" + recipe.baseCharacter + "”. The selected source character was kept; changing source requires choosing it from the game library.");}}
      if(recipe.name){next.cardOverrides.name=recipe.name;changes.push("Card name: “" + recipe.name + "”.");}
      if(recipe.notes){next.notes=[String(next.notes || "").trim(),recipe.notes].filter(Boolean).join("\n\n");changes.push("Added the design notes.");}
      for(const [key,value] of Object.entries(recipe.stats || {})){next.cardOverrides[key+"_max"]=value;const current=Forge.card(next)[key+"_init"];if(current>value)next.cardOverrides[key+"_init"]=value;changes.push(key.toUpperCase()+" maximum: "+value+".");}
      if(recipe.rarity){next.cardOverrides.rarity=RARITIES[recipe.rarity];changes.push("Rarity: "+recipe.rarity+".");warnings.push("Rarity changes keep inherited level, awakening and move requirements. Review those settings before gameplay.");}
      if(recipe.type){next.cardOverrides.element=TYPES[recipe.type.toUpperCase()];changes.push("Class and type: "+recipe.type+".");}
      if(recipe.leader){ensureTables(next,schema,["leader_skill_sets","leader_skills"]);Guide.isolateAbilityStage(next,"base","leader");Guide.editStage(next,"base","leader",view=>Forge.allTypesLeader(view,recipe.leader.ki,recipe.leader.percent));changes.push("Base leader: All Types Ki +"+recipe.leader.ki+" and HP, ATK & DEF +"+recipe.leader.percent+"%.");}
      if(recipe.abilities && (recipe.abilities.length || recipe.passiveMode === "replace")) {
        ensureTables(next,schema,["passive_skill_sets","passive_skills","passive_skill_set_relations"]);
        if(recipe.passiveMode === "replace") {
          const set=Guide.stageSet(next,"base","passive"), ids=new Set((next.tables.passive_skill_set_relations || []).filter(row=>row.passive_skill_set_id === set?.id).map(row=>row.passive_skill_id));
          const bound=Object.keys(next.animationAssignments || {}).some(key=>{const match=key.match(/^(?:intro|counter):(-?\d+)$|^(?:nullify|revival|transform|giant):passive_skills:(-?\d+)(?::|$)/);return match && ids.has(Number(match[1] || match[2]));});
          if(next.actionHooks?.dodge || bound || Object.keys(next.abilityAnimationOverrides || {}).some(key=>key.startsWith("passive_skills:") && ids.has(Number(key.slice(15)))))fail("Restore assigned passive animations and custom Dodge before replacing the base passive, or use additive abilities.");
        }
        Guide.isolateAbilityStage(next,"base","passive");
        Guide.editStage(next,"base","passive",view=>{
          if(recipe.passiveMode === "replace") {const set=Forge.primaryPassive(view);view.tables.passive_skill_set_relations=view.tables.passive_skill_set_relations.filter(row=>row.passive_skill_set_id !== set?.id);changes.push("Replaced only the base passive relations; other awakening stages and source rows kept.");}
          for(const ability of recipe.abilities){Forge.addPassive(view,passiveFields(ability));changes.push("Base passive: "+abilityText(ability)+".");}
        });
      }
      renameMoves(next,recipe.moves,changes,warnings,pending);
      if(recipe.artPrompt){pending.artPrompt=recipe.artPrompt;warnings.push("Artwork brief retained for review. No image was generated or installed, and animations were not assigned.");}
      if(!recipe.passiveMode || recipe.passiveMode === "add")warnings.push("Inherited abilities are preserved. New guided abilities add to the base passive only.");
    }
    const result=Forge.validate(next);if(result.errors.length)fail("This recipe cannot be applied safely: "+result.errors.slice(0,6).join(" "));
    warnings.push(...result.warnings);
    return {project:next,recipe,changes,warnings:[...new Set(warnings)],pending};
  }
  function preview(project, input, options) { const {project:unused,...result}=apply(project,input,options);return result; }
  return { CARD_SCHEMA, ANIMATION_SCHEMA, MAX_RECIPE_BYTES, ABILITY_KINDS, MOVE_ROLES, parse, validate, preview, apply };
});
