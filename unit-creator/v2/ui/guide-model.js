(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./core"), require("./motion"), require("./conditions"), require("./movie-model"));
  else root.ForgeGuide = factory(root.Forge, root.ForgeMotion, root.ForgeConditions, root.ForgeMovieModel);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Forge, Motion, Conditions, MovieModel) {
  "use strict";
  function ensure(p, schema, table) {
    if (!schema[table]) throw new Error("This game database does not support " + table + ".");
    p.tables[table] = p.tables[table] || [];
    p.schema[table] = Forge.clone(schema[table]);
    return p.tables[table];
  }
  const references = { links: {}, categories: {}, characters: {}, domains: {} };
  function conditionLabel(row, definitions = []) {
    if (!row) return "An inherited condition";
    const guided = Conditions.label(row, references);
    if (guided) return guided;
    const a = Number(row.cau_val1), b = Number(row.cau_val2), type = Number(row.causality_type);
    const friendly = { 0: "Always", 1: "HP above " + a + "%", 2: "HP below " + a + "%", 3: "Ki above the source’s inherited threshold", 4: "Ki below the source’s inherited threshold", 5: "After turn " + a, 14: "Attacking in the first slot", 15: "More than " + a + " enemies", 16: "Fewer than " + a + " enemies", 17: "Enemy HP above " + a + "%", 18: "Enemy HP below " + a + "%", 19: "Attacking in slot " + (a + 1), 24: "After being attacked", 25: "After defeating an enemy", 30: "Successfully guarding", 40: "Performing or receiving a Super Attack", 43: "After successfully dodging", 47: "After this character revives", 53: "While in Standby", 54: "After an ally revives", 55: "After " + a + " turns from first appearance", 56: "Receiving a normal attack", 58: a ? "While a Domain is active" : "While no Domain is active", 59: a === 1 ? "Character is Super class" : "Character is Extreme class", 61: "After receiving an attack this turn" };
    if (friendly[type]) return friendly[type];
    if ([6, 7].includes(type)) return (type === 6 ? "Team has the link " : "Enemy has the link ") + (references.links[a] || "chosen by the source");
    if ([22, 29].includes(type)) return (type === 22 ? "Team includes " : "Enemy includes ") + (references.characters[a] || "the source’s named character");
    if (type === 34) return (a === 1 ? "Enemy category requirement: " : a === 2 ? "Attacking allies’ category requirement: " : "Team category requirement: ") + (references.categories[b] || "the source’s category");
    if (type === 57) return "While " + (references.domains[a] || "the source’s Domain") + " is active";
    const def = definitions.find((d) => Number(d[0]) === type);
    if (!def) return "Specialized source rule (kept unchanged)";
    const values = [a, b, Number(row.cau_val3)], details = def.slice(3, 6).map((label, i) => {
      if (!label || ["0", "-"].includes(label) || /leave all/i.test(label)) return "";
      if (/id|bitset|bitpattern|flags|relations|setid/i.test(label)) return "Uses the source’s " + (/category/i.test(label) ? "category group" : /link/i.test(label) ? "Link Skill" : /card|unique|chara/i.test(label) ? "character group" : "gameplay group");
      return label + ": " + values[i];
    }).filter(Boolean);
    return def[2] + (details.length ? " · " + details.join("; ") : "");
  }
  function describeCondition(value, rows, definitions = []) {
    if (!value) return "Always";
    try {
      const v = JSON.parse(value);
      const describe = (n) => typeof n === "number" ? conditionLabel(rows.find((r) => r.id === n), definitions) : Array.isArray(n) ? n[0] === "!" ? "Unless " + describe(n[1]) : "(" + n.slice(1).map(describe).join(n[0] === "&" ? " and " : " or ") + ")" : "Keep inherited condition";
      return describe(v.compiled);
    } catch {
      return "Keep inherited condition";
    }
  }
  function conditionGroup(row, sourceRows) {
    if (!(row == null ? void 0 : row.causality_conditions)) throw new Error("This source effect activates without additional conditions. Choose Always in the condition editor.");
    let expression;
    try {
      expression = Conditions.expression(JSON.parse(row.causality_conditions).compiled);
    } catch {
      throw new Error("This source uses an unsupported condition format. Its complete passive can still be copied.");
    }
    const ids = /* @__PURE__ */ new Set(), visit = (node) => {
      if (typeof node === "number") ids.add(node);
      else node.slice(1).forEach(visit);
    };
    visit(expression);
    const records = [...ids].map((id) => {
      const record = sourceRows.find((value) => value.id === id);
      if (!record || !["causality_type", "cau_val1", "cau_val2", "cau_val3"].every((field) => Number.isSafeInteger(record[field]))) throw new Error("The source is missing a complete activation-rule record. Refresh its game database before copying.");
      return Forge.clone(record);
    });
    return { expression, records };
  }
  function setCondition(p, schema, row, rules, mode = "all") {
    if (!Array.isArray(rules) || rules.length > 64 || !["all", "any"].includes(mode)) throw new Error("Use up to 64 conditions, matching all or any rules.");
    const normalized = rules.map((rule) => {
      if (rule.copied) return { copied: conditionGroup({ causality_conditions: JSON.stringify({ compiled: rule.copied.expression }) }, rule.copied.records || []) };
      if (rule.expression !== void 0) return { expression: Conditions.expression(rule.expression) };
      if (rule.existingId !== void 0 && rule.existingId !== null) {
        if (!Number.isSafeInteger(Number(rule.existingId))) throw new Error("Choose a valid inherited condition.");
        return { existingId: Number(rule.existingId) };
      }
      const type = Number(rule.type);
      if (!Number.isSafeInteger(type) || type < 0 || type > 2147483647) throw new Error("Choose a valid condition.");
      return { type, values: Conditions.values(rule) };
    });
    if (!normalized.length) {
      row.causality_conditions = null;
      return;
    }
    const local = ensure(p, schema, "skill_causalities");
    const ids = normalized.map((rule) => {
      if (rule.copied) {
        const maps = /* @__PURE__ */ new Map();
        for (const original of rule.copied.records) {
          let record2 = local.find((value) => ["causality_type", "cau_val1", "cau_val2", "cau_val3"].every((field) => value[field] === original[field]));
          if (!record2) {
            record2 = { ...Forge.rowDefault(p.schema.skill_causalities), ...original, id: Forge.localId(p, "skill_causalities") };
            local.push(record2);
          }
          maps.set(original.id, record2.id);
        }
        const remap = (node) => typeof node === "number" ? maps.get(node) : [node[0], ...node.slice(1).map(remap)];
        return remap(rule.copied.expression);
      }
      if (rule.expression !== void 0) return rule.expression;
      if (rule.existingId !== void 0) return rule.existingId;
      const found = local.find((r) => Number(r.causality_type) === rule.type && ["cau_val1", "cau_val2", "cau_val3"].every((field, i) => Number(r[field]) === rule.values[i]));
      if (found) return found.id;
      const record = Object.assign(Forge.rowDefault(p.schema.skill_causalities), { id: Forge.localId(p, "skill_causalities"), causality_type: rule.type, cau_val1: rule.values[0], cau_val2: rule.values[1], cau_val3: rule.values[2] });
      local.push(record);
      return record.id;
    });
    const op = mode === "any" ? "|" : "&";
    let compiled = ids[0];
    for (const id of ids.slice(1)) compiled = [op, compiled, id];
    row.causality_conditions = JSON.stringify({ source: ids.map((id) => typeof id === "number" ? String(id) : Conditions.source(id)).join(op), compiled });
  }
  function importOwned(p, donor, tables) {
    var _a, _b;
    const maps = {};
    for (const table of tables) {
      if (!donor.schema[table]) continue;
      ensure(p, donor.schema, table);
      maps[table] = /* @__PURE__ */ new Map();
      for (const old of donor.tables[table] || []) {
        const id = Forge.localId(p, table);
        maps[table].set(old.id, id);
        p.tables[table].push({ ...Forge.clone(old), id });
      }
    }
    for (const table of Object.keys(maps)) for (const row of p.tables[table].filter((r) => [...maps[table].values()].includes(r.id))) {
      for (const [field, value] of Object.entries(row)) {
        if (field === "id") continue;
        if (field === "card_id") {
          row[field] = p.source.cardId;
          continue;
        }
        const target = Forge.foreign[field] || (field.endsWith("_id") ? field.slice(0, -3) + "s" : null);
        if (target && ((_a = maps[target]) == null ? void 0 : _a.has(value))) row[field] = maps[target].get(value);
      }
    }
    for (const [key, input] of Object.entries(donor.abilityAnimationSources || {})) {
      const split = key.lastIndexOf(":"), table = key.slice(0, split), id = Number(key.slice(split + 1));
      if ((_b = maps[table]) == null ? void 0 : _b.has(id)) {
        p.abilityAnimationSources = p.abilityAnimationSources || {};
        p.abilityAnimationSources[table + ":" + maps[table].get(id)] = Forge.clone(input);
      }
    }
    return maps;
  }
 // Efficacy 51: documented sphere indices; native reference passive 369 uses
 // source 0 -> destination 5, calc 0, self, turn-start, one turn, 100%.
 const sphereTypes=Object.freeze(['AGL (blue)','TEQ (green)','INT (purple)','STR (red)','PHY (orange)','Rainbow']);
 function sphereValues(from,to){if(!Number.isInteger(from)||!Number.isInteger(to)||from<0||from>5||to<0||to>5)throw new Error('Choose both Ki Sphere colors by name.');if(from===to)throw new Error('Choose a different destination color.');return {eff_value1:from,eff_value2:to};}
 function setKiSphereChange(row,from,to){const values=sphereValues(from,to);if(!row||row.efficacy_type!==51)throw new Error('Choose a Ki Sphere color-change effect.');Object.assign(row,values);return row;}
 function addKiSphereChange(p,from=0,to=5){const values=sphereValues(from,to);return Forge.addPassive(p,{efficacy_type:51,calc_option:0,eff_value1:values.eff_value1,eff_value2:values.eff_value2,eff_value3:0});}
 // Documented type-filtered bonuses. Existing native examples: passive
 // 1000797 (DEF), 527 (ATK/DEF), 10 (Ki); type value excludes Rainbow.
 const typeSupportKinds=Object.freeze([[16,'ATK'],[17,'DEF'],[18,'ATK & DEF'],[20,'Ki']].map(value=>Object.freeze(value)));
 function setTypeSupport(row,changes){
  if(!row||!typeSupportKinds.some(([id])=>id===row.efficacy_type)||!changes||typeof changes!=='object')throw new Error('Choose a type-specific support effect.');
  for(const [field,value]of Object.entries(changes)){const max=field==='eff_value1'?4:row.efficacy_type===20?24:[2,3].includes(row.calc_option)?1000:1000000;if(!['eff_value1','eff_value2',...(row.efficacy_type===18?['eff_value3']:[])].includes(field)||!Number.isInteger(value)||value<0||value>max)throw new Error(field==='eff_value1'?'Choose AGL, TEQ, INT, STR or PHY by name.':'Choose a whole bonus from 0 to '+max+'.');}
  Object.assign(row,changes);return row;
 }
 function addTypeSupport(p,kind,type,amount,defAmount){
  if(!typeSupportKinds.some(([id])=>id===kind))throw new Error('Choose ATK, DEF, ATK & DEF or Ki support.');
  const fields={efficacy_type:kind,calc_option:kind===20?0:2,target_type:2,eff_value1:type,eff_value2:amount,eff_value3:kind===18?defAmount:0};setTypeSupport(fields,{eff_value1:type,eff_value2:amount,...(kind===18?{eff_value3:defAmount}:{})});return Forge.addPassive(p,fields);
 }
 // Plain per-sphere bonuses: reference passive 313 (ATK), 1167 (DEF),
 // 376 (separate ATK/DEF). Color-filtered variants have distinct profiles.
 const sphereBonusKinds=Object.freeze([[59,'ATK'],[60,'DEF'],[61,'ATK & DEF']].map(value=>Object.freeze(value)));
 function setSphereBonus(row,changes){
  if(!row||!sphereBonusKinds.some(([id])=>id===row.efficacy_type)||!changes||typeof changes!=='object')throw new Error('Choose a bonus per Ki Sphere effect.');
  const max=[2,3].includes(row.calc_option)?1000:1000000;for(const [field,value]of Object.entries(changes))if(!['eff_value1',...(row.efficacy_type===61?['eff_value2']:[])].includes(field)||!Number.isInteger(value)||value<0||value>max)throw new Error('Choose a whole bonus per sphere from 0 to '+max+'.');
  Object.assign(row,changes);return row;
 }
 function addSphereBonus(p,kind,amount,defAmount){
  if(!sphereBonusKinds.some(([id])=>id===kind))throw new Error('Choose ATK, DEF or ATK & DEF per Ki Sphere.');
  const fields={efficacy_type:kind,calc_option:2,target_type:1,eff_value1:amount,eff_value2:kind===61?defAmount:0,eff_value3:0};setSphereBonus(fields,{eff_value1:amount,...(kind===61?{eff_value2:defAmount}:{})});return Forge.addPassive(p,fields);
 }
 // Native 64/65/66 first gate the recipient character type, then count
 // the third-value sphere color. Only observed matching-type/color profiles
 // are offered: passive IDs below retain the source-backed supported set.
 const colorSphereKinds=Object.freeze([[64,'ATK'],[65,'DEF'],[66,'ATK & DEF']].map(value=>Object.freeze(value)));
 const colorSphereProfiles=Object.freeze([[64,0,1001098],[64,1,615],[64,2,411],[64,3,410],[64,4,404],[65,1,2001158],[66,3,1001099],[66,4,1001024]].map(value=>Object.freeze(value)));
 function colorSphereOptions(kind){return colorSphereProfiles.filter(([effect])=>effect===kind).map(([,type])=>[type,sphereTypes[type]]);}
 function canEditColorSphereBonus(row){if(!row||row.calc_option!==2||row.target_type!==1||row.sub_target_type_set_id!==0||row.exec_game_type!==0||row.eff_value1!==row.eff_value3||!Number.isInteger(row.eff_value2)||row.eff_value2<0||row.eff_value2>1000||!colorSphereProfiles.some(([kind,type])=>kind===row.efficacy_type&&type===row.eff_value1))return false;try{const values=JSON.parse(row.efficacy_values||'{}');return values!==null&&!Array.isArray(values)&&typeof values==='object'&&Object.keys(values).length===0;}catch{return false;}}
 function setColorSphereBonus(row,changes){
  if(!canEditColorSphereBonus(row))throw new Error('This inherited color-filtered bonus uses a different source profile. Copy a complete passive to replace it.');
  if(!changes||typeof changes!=='object'||Object.keys(changes).some(key=>!['color','amount'].includes(key)))throw new Error('Choose a supported sphere color and bonus.');
  const color=changes.color===undefined?row.eff_value1:changes.color,amount=changes.amount===undefined?row.eff_value2:changes.amount;
  if(!Number.isInteger(color)||!colorSphereProfiles.some(([kind,type])=>kind===row.efficacy_type&&type===color))throw new Error('Choose one of the matching character types and sphere colors offered for this bonus.');
  if(!Number.isInteger(amount)||amount<0||amount>1000)throw new Error('Choose a whole bonus per matching sphere from 0 to 1000 percent.');
  Object.assign(row,{eff_value1:color,eff_value2:amount,eff_value3:color});return row;
 }
 function addColorSphereBonus(p,kind,color,amount){const fields={efficacy_type:kind,calc_option:2,target_type:1,sub_target_type_set_id:0,exec_game_type:0,eff_value1:color,eff_value2:amount,eff_value3:color,efficacy_values:'{}'};setColorSphereBonus(fields,{color,amount});return Forge.addPassive(p,fields);}
 // Mechanics documentation defines both as zero-parameter effects.
 // Reference passives 48 (status prevention, 99 turns) and 457 (all-Type
 // effectiveness, one turn) supply the self/start-of-turn native profiles.
 const battleBuffKinds=Object.freeze([[50,'Prevent status effects'],[76,'Attacks effective against all Types']].map(value=>Object.freeze(value)));
 function addBattleBuff(p,kind,options={}){
  if(!battleBuffKinds.some(([id])=>id===kind))throw new Error('Choose status protection or attacks effective against all Types.');
  if(!options||typeof options!=='object'||Array.isArray(options)||Object.keys(options).some(key=>!['recipients','chance','turns'].includes(key)))throw new Error('Choose recipients, chance and duration for this battle ability.');
  const recipients=options.recipients===undefined?'self':options.recipients,chance=options.chance===undefined?100:options.chance,turns=options.turns===undefined?(kind===50?99:1):options.turns;
  if(!['self','allies'].includes(recipients))throw new Error('Choose this character or all allies.');
  if(!Number.isInteger(chance)||chance<0||chance>100)throw new Error('Choose a whole activation chance from 0 to 100 percent.');
  if(![1,2,3,4,5,99].includes(turns))throw new Error('Choose one of the offered battle durations.');
  return Forge.addPassive(p,{efficacy_type:kind,target_type:recipients==='self'?1:2,calc_option:0,probability:chance,turn:turns,eff_value1:0,eff_value2:0,eff_value3:0});
 }
  function categoryLeader(p, category, targets2, ki, stats) {
    if (!category || !Number.isSafeInteger(Number(category.id)) || !String(category.name || "").trim()) throw new Error("Choose a named category from the game database.");
    if (!Number.isInteger(ki) || ki < 0 || ki > 24 || !Number.isInteger(stats) || stats < 0 || stats > 1e3) throw new Error("Use whole-number Ki from 0 to 24 and stat bonuses from 0 to 1000 percent.");
    if (!Array.isArray(targets2)) throw new Error("Load the category targeting records first.");
    const groups = /* @__PURE__ */ new Map();
    for (const row of targets2) {
      const id = row.sub_target_type_set_id;
      if (!groups.has(id)) groups.set(id, []);
      groups.get(id).push(row);
    }
    const found = [...groups].find(([id, rows]) => Number.isSafeInteger(Number(id)) && Number(id) > 0 && rows.length === 1 && Number(rows[0].target_value_type) === 1 && Number(rows[0].target_value) === Number(category.id));
    if (!found) throw new Error("This database has no verified single-category targeting profile for " + category.name + ". Copy a character’s complete leader skill instead.");
    Forge.allTypesLeader(p, ki, stats);
    const set = (p.tables.leader_skill_sets || []).find((row) => row.id === Forge.card(p).leader_skill_set_id);
    set.name = category.name + " Leadership";
    set.description = '"' + category.name + '" Category Ki +' + ki + " and HP, ATK & DEF +" + stats + "%";
    for (const row of p.tables.leader_skills.filter((row2) => row2.leader_skill_set_id === set.id)) {
      row.sub_target_type_set_id = Number(found[0]);
      if (row.efficacy_type === 83) {
        row.efficacy_type = 5;
        row.efficacy_values = JSON.stringify([ki, 0, 0]);
      }
    }
    return set;
  }
  function abilityStages(p) {
    return [{ id: "base", label: "Before Extreme Z-Awakening" }, ...(p.tables.optimal_awakening_growths || []).slice().sort((a, b) => a.step - b.step || a.id - b.id).map((row) => ({ id: String(row.id), label: "EZA stage " + row.step + " · level " + row.lv_max + (row.skill_lv_max ? " · Super Attack level " + row.skill_lv_max : ""), row }))];
  }
  function stageHolder(p, stageId) {
    if (String(stageId) === "base") return p.cardOverrides;
    const row = (p.tables.optimal_awakening_growths || []).find((row2) => String(row2.id) === String(stageId));
    if (!row) throw new Error("Choose an awakening stage available on this character.");
    return row;
  }
  function stageAbilityId(p, stageId, kind) {
    if (!["leader", "passive"].includes(kind)) throw new Error("Choose a leader skill or passive ability.");
    return String(stageId) === "base" ? Forge.card(p)[kind + "_skill_set_id"] : stageHolder(p, stageId)[kind + "_skill_set_id"];
  }
  function stageSet(p, stageId, kind) {
    const id = stageAbilityId(p, stageId, kind);
    return (p.tables[kind + "_skill_sets"] || []).find((row) => row.id === id);
  }
  function setStageAbility(p, stageId, kind, id) {
    stageAbilityId(p, stageId, kind);
    stageHolder(p, stageId)[kind + "_skill_set_id"] = id;
  }
  function editStage(p, stageId, kind, operation) {
    const view = { ...p, cardOverrides: { ...p.cardOverrides, [kind + "_skill_set_id"]: stageAbilityId(p, stageId, kind) } };
    const result = operation(view);
    setStageAbility(p, stageId, kind, Forge.card(view)[kind + "_skill_set_id"]);
    return result;
  }
  function isolateAbilityStage(p, stageId, kind) {
    var _a, _b;
    const id = stageAbilityId(p, stageId, kind), set = stageSet(p, stageId, kind);
    if (!set) return false;
    const others = abilityStages(p).filter((stage) => stage.id !== String(stageId));
    let shared = others.some((stage) => stageAbilityId(p, stage.id, kind) === id);
    if (kind === "passive") {
      const ownIds = new Set((p.tables.passive_skill_set_relations || []).filter((row) => row.passive_skill_set_id === id).map((row) => row.passive_skill_id));
      if ((p.tables.passive_skill_set_relations || []).some((row) => row.passive_skill_set_id !== id && ownIds.has(row.passive_skill_id))) shared = true;
    }
    if (!shared) return false;
    const tables = kind === "leader" ? ["leader_skill_sets", "leader_skills"] : ["passive_skill_sets", "passive_skills", "passive_skill_set_relations"], donor = { schema: p.schema, tables: {}, abilityAnimationSources: p.abilityAnimationSources };
    donor.tables[kind + "_skill_sets"] = [set];
    if (kind === "leader") donor.tables.leader_skills = (p.tables.leader_skills || []).filter((row) => row.leader_skill_set_id === id);
    else {
      donor.tables.passive_skill_set_relations = (p.tables.passive_skill_set_relations || []).filter((row) => row.passive_skill_set_id === id);
      const ids = new Set(donor.tables.passive_skill_set_relations.map((row) => row.passive_skill_id));
      donor.tables.passive_skills = (p.tables.passive_skills || []).filter((row) => ids.has(row.id));
      for (const [table, filter] of [["passive_skill_set_additions", (row) => row.target_passive_skill_set_id === id], ["dokkan_field_passive_skill_relations", (row) => ids.has(row.passive_skill_id)]]) if (p.schema[table]) {
        tables.push(table);
        donor.tables[table] = (p.tables[table] || []).filter(filter);
      }
    }
    const refs = (p.animationReferences || []).slice(), maps = importOwned(p, donor, tables);
    for (const ref of refs) if ((_a = maps[ref.table]) == null ? void 0 : _a.has(ref.row)) {
      const copy = { ...Forge.clone(ref), row: maps[ref.table].get(ref.row) };
      if ((_b = maps[copy.targetTable]) == null ? void 0 : _b.has(copy.targetId)) copy.targetId = maps[copy.targetTable].get(copy.targetId);
      p.animationReferences.push(copy);
    }
    setStageAbility(p, stageId, kind, maps[kind + "_skill_sets"].get(id));
    return true;
  }
  async function allocateId(p, query, projects) {
    // Start from a random slot so units made on different phones (or shared by other creators who
    // use this app) are very unlikely to share IDs. Every candidate is checked against saved units
    // and the active game database before it is used, so an existing card is never replaced.
    const slots = Math.floor((Forge.SLOT_CEILING - Forge.SLOT_FLOOR) / 1e3) + 1;
    const first = Math.floor(Math.random() * slots);
    let candidate = Forge.SLOT_FLOOR;
    for (let attempt = 0; attempt < Math.min(slots, 400); attempt++) {
      candidate = Forge.SLOT_FLOOR + ((first + attempt) % slots) * 1e3;
      if (projects.some((x) => x && x.key !== p.key && [x.targetId, ...(x.reservedIds || []), ...(x.formProjects || []).map((f) => f.targetId)].some((id) => Math.abs(Number(id) - candidate) < 1e3))) continue;
      p.targetId = candidate;
      const tables = Forge.materialize(p);
      let collision = false;
      for (const [table, all] of Object.entries(tables)) {
        const rows = table === "cards" && p.awaken ? all.filter((r) => Number(r.id) !== Number(p.awaken.cardId)) : all;
        if (!rows.length) continue;
        if ((await query({ table, ids: rows.map((r) => r.id), limit: 1 })).length) {
          collision = true;
          break;
        }
      }
      if (!collision) return candidate;
    }
    throw new Error("Could not reserve a free unit slot. Refresh game data and retry.");
  }
  function abilityValues(table, row) {
    try {
      const values = JSON.parse(row.efficacy_values || "{}");
      if (Array.isArray(values)) return values;
    } catch {
    }
    return table === "passive_skills" ? [row.eff_value1, row.eff_value2, row.eff_value3] : [row.eff_val1, row.eff_val2, row.eff_val3];
  }
  function abilityTargets(p, ids) {
    var _a, _b, _c;
    const items = [];
    for (const table of ["passive_skills", "active_skills", "standby_skills", "finish_skills"]) for (const row of p.tables[table] || []) {
      if (table === "passive_skills" && !ids.has(row.id)) continue;
      const key = table + ":" + row.id, effect = Number(row.efficacy_type), values = abilityValues(table, row), source = (_a = p.abilityAnimationSources) == null ? void 0 : _a[key];
      if ([97, 119].includes(effect)) items.push({ key: "nullify:" + key, kind: "nullify", name: (Number(values[0]) > 0 ? "Absorb an attack" : "Nullify an attack") + " · " + (row.name || "Inherited ability"), table, row: row.id, field: table === "passive_skills" ? "eff_value3" : "eff_val3", abilityIndex: 2, damage: false, recover: effect === 97 && Number(values[0]) > 0, role: "defender", sourceKey: key });
      if (effect === 109 && (source == null ? void 0 : source.view)) items.push({ key: "revival:" + key, kind: "revival", name: "Revival · " + (row.name || "Inherited revival"), table, row: row.id, abilityIndex: 1, damage: false, sourceKey: key });
      if (effect === 103 && ((_b = source == null ? void 0 : source.params) == null ? void 0 : _b.length)) {
        for (const phase of ["begin", "end"]) {
          items.push({ key: "transform:" + key + ":" + phase, kind: "transform", name: (phase === "begin" ? "Transformation" : "Return from transformation") + " · " + (row.name || "Inherited form change"), table, row: row.id, phase, abilityIndex: 2, damage: false, sourceKey: key });
        }
      }
      if (effect === 79 && ((_c = source == null ? void 0 : source.params) == null ? void 0 : _c.length)) for (const phase of ["begin", "continue", "end"]) items.push({ key: "giant:" + key + ":" + phase, kind: "giant", name: { begin: "Enter giant form", continue: "Giant-form turn", end: "Leave giant form" }[phase] + " · " + (row.name || "Inherited giant form"), table, row: row.id, phase, abilityIndex: 2, damage: false, sourceKey: key });
    }
    return items;
  }
  function animationReference(p, ref) {
    p.animationReferences = p.animationReferences || [];
    p.animationReferences = p.animationReferences.filter((r) => !(r.table === ref.table && r.row === ref.row && r.field === ref.field && r.index === ref.index));
    p.animationReferences.push(ref);
  }
  function referenceAbility(p, target, targetTable, targetId) {
    const row = p.tables[target.table].find((r) => r.id === target.row);
    let values;
    try {
      values = JSON.parse(row.efficacy_values || "{}");
    } catch {
    }
    const ref = { table: target.table, row: target.row, targetTable, targetId };
    if (Array.isArray(values)) {
      values[target.abilityIndex] = targetId;
      row.efficacy_values = JSON.stringify(values);
      Object.assign(ref, { field: "efficacy_values", index: target.abilityIndex });
    } else {
      ref.field = (target.table === "passive_skills" ? "eff_value" : "eff_val") + (target.abilityIndex + 1);
      row[ref.field] = targetId;
    }
    if (targetTable) animationReference(p, ref);
  }
  function applyAbilityAnimation(p, schema, target, script) {
    var _a, _b;
    const source = (_a = p.abilityAnimationSources) == null ? void 0 : _a[target.sourceKey];
    p.abilityAnimationOverrides = p.abilityAnimationOverrides || {};
    let owned = p.abilityAnimationOverrides[target.sourceKey];
    const table = target.kind === "revival" ? "revival_views" : target.kind === "giant" ? "metamorphic_views" : "transformation_views";
    if (target.kind !== "revival" && (!Array.isArray(source.params) || source.params.length > 64 || source.params.some((r) => !Number.isInteger(r.idx) || r.idx < 0 || r.idx > 63) || new Set(source.params.map((r) => r.idx)).size !== source.params.length)) throw new Error("This form animation has invalid or unsupported game parameters. Reopen its source using current game data.");
    if (!owned) {
      const list = ensure(p, schema, table), record2 = Object.assign(Forge.rowDefault(p.schema[table]), Forge.clone(source.view || {}), { id: Forge.localId(p, table) });
      if (["transform", "giant"].includes(target.kind) && !source.view) {
        Object.assign(record2, { begin_script_name: "0", begin_lite_flicker_rate: 0, end_script_name: "0", end_lite_flicker_rate: 0 });
        if (target.kind === "giant") Object.assign(record2, { continue_script_name: "0", continue_lite_flicker_rate: 0 });
      }
      list.push(record2);
      owned = { table, viewId: record2.id };
      if (!source.view && target.kind !== "revival") owned.requiredPhases = target.kind === "giant" ? ["begin", "continue", "end"] : Number((_b = source.params.find((r) => r.idx === 2)) == null ? void 0 : _b.value) ? ["begin", "end"] : ["begin"];
      if (target.kind === "revival") referenceAbility(p, target, table, record2.id);
      else {
        const params = ensure(p, schema, "battle_params"), byIndex = new Map(source.params.map((r) => [Number(r.idx), r])), viewIndex = target.kind === "giant" ? 12 : 11, last = Math.max(viewIndex, ...byIndex.keys());
        let group;
        for (let idx = 0; idx <= last; idx++) {
          const row = Object.assign(Forge.rowDefault(p.schema.battle_params), Forge.clone(byIndex.get(idx) || {}), { id: Forge.localId(p, "battle_params"), idx });
          if (group === void 0) group = row.id;
          row.param_no = group;
          if (!byIndex.has(idx)) row.value = 0;
          params.push(row);
          animationReference(p, { table: "battle_params", row: row.id, field: "param_no", targetTable: "battle_params", targetId: group });
          if (target.kind === "transform" && idx === 6 && row.value === (source.cardId || p.source.cardId)) animationReference(p, { table: "battle_params", row: row.id, field: "value", targetTable: "cards", targetId: p.tables.cards[0].id });
          if (idx === viewIndex) {
            row.value = record2.id;
            animationReference(p, { table: "battle_params", row: row.id, field: "value", targetTable: table, targetId: record2.id });
          }
        }
        owned.paramId = group;
        referenceAbility(p, target, "battle_params", group);
      }
      p.abilityAnimationOverrides[target.sourceKey] = owned;
    }
    const record = p.tables[table].find((r) => r.id === owned.viewId);
    if (!record) throw new Error("This animation lost its owned gameplay record.");
    if (target.kind === "revival") Object.assign(record, { script_name: script, script_lite_flicker_rate: 70 });
    else {
      record[target.phase + "_script_name"] = script;
      record[target.phase + "_lite_flicker_rate"] = 70;
    }
    return owned.viewId;
  }
  function restoreAbilityAnimation(p, targetKey) {
    var _a, _b, _c;
    const target = targets(p).find((t) => t.key === targetKey);
    if (!target || !["revival", "transform", "giant"].includes(target.kind)) throw new Error("Choose a form or revival animation to restore.");
    const source = (_a = p.abilityAnimationSources) == null ? void 0 : _a[target.sourceKey], owned = (_b = p.abilityAnimationOverrides) == null ? void 0 : _b[target.sourceKey];
    if (!owned) return false;
    const row = p.tables[target.table].find((r) => r.id === target.row);
    let values;
    try {
      values = JSON.parse(row.efficacy_values || "{}");
    } catch {
    }
    if (Array.isArray(values)) {
      values[target.abilityIndex] = source.values[target.abilityIndex];
      row.efficacy_values = JSON.stringify(values);
    } else row[(target.table === "passive_skills" ? "eff_value" : "eff_val") + (target.abilityIndex + 1)] = source.values[target.abilityIndex];
    const params = new Set((p.tables.battle_params || []).filter((r) => r.param_no === owned.paramId).map((r) => r.id));
    p.tables[owned.table] = (p.tables[owned.table] || []).filter((r) => r.id !== owned.viewId);
    if (owned.paramId !== void 0) p.tables.battle_params = (p.tables.battle_params || []).filter((r) => !params.has(r.id));
    p.animationReferences = (p.animationReferences || []).filter((r) => !(r.table === target.table && r.row === target.row) && !(r.table === owned.table && r.row === owned.viewId) && !(r.targetTable === owned.table && r.targetId === owned.viewId) && !(r.table === "battle_params" && params.has(r.row)) && !(r.targetTable === "battle_params" && r.targetId === owned.paramId));
    for (const key of Object.keys(p.animationAssignments || {})) if (["revival", "transform", "giant"].some((kind) => key === kind + ":" + target.sourceKey || key.startsWith(kind + ":" + target.sourceKey + ":"))) {
      delete p.animationAssignments[key];
      p.generatedFiles = (p.generatedFiles || []).filter((f) => f.owner !== key);
      if ((_c = p.uiLabels) == null ? void 0 : _c.animations) delete p.uiLabels.animations[key];
    }
    delete p.abilityAnimationOverrides[target.sourceKey];
    return true;
  }
  const normalControlCategories = [20002, 20004, 30001, 30003];
  function normalAttackStyle(p) {
    var _a;
    return ((_a = p.normalAttackStyle) == null ? void 0 : _a.mode) || "inherit";
  }
  function setNormalAttackStyle(p, schema, mode) {
    if (!["inherit", "mixed", "melee", "ki"].includes(mode)) throw new Error("Choose an inherited, mixed, melee-only or Ki-blast-only normal attack style.");
    const previous = p.normalAttackStyle;
    if (!previous && mode === "inherit") return false;
    const view = Forge.clone(p), rows = ensure(view, schema, "card_motions"), controls = rows.filter((row) => normalControlCategories.includes(Number(row.category)));
    if (previous && JSON.stringify(controls) !== JSON.stringify(previous.ownedRows)) throw new Error("Normal attack controls changed in Expert mode. Undo those changes before choosing another guided style.");
    const saved = previous || { sourceRows: Forge.clone(controls), sourceOrder: rows.map((row) => row.id) }, remaining = rows.filter((row) => !normalControlCategories.includes(Number(row.category)));
    view.tables.card_motions = remaining;
    if (mode === "inherit") {
      const ids = new Set(remaining.map((row) => row.id));
      if (saved.sourceRows.some((row) => ids.has(row.id))) throw new Error("An edited motion now uses an inherited control record. Undo that Expert-mode edit before restoring the source attack style.");
      const restored = remaining.concat(Forge.clone(saved.sourceRows)), order = new Map(saved.sourceOrder.map((id, index) => [id, index]));
      restored.sort((a, b) => (order.has(a.id) ? order.get(a.id) : Infinity) - (order.has(b.id) ? order.get(b.id) : Infinity));
      view.tables.card_motions = restored;
      delete view.normalAttackStyle;
    } else {
      const categories = mode === "melee" ? [20002, 20004] : mode === "ki" ? [30001, 30003] : [], reserved = new Set(saved.sourceRows.map((row) => row.id));
      for (const category of categories) {
        let id = Forge.localId(view, "card_motions");
        while (reserved.has(id) || remaining.some((row) => row.id === id)) id--;
        remaining.push(Object.assign(Forge.rowDefault(view.schema.card_motions), { id, card_id: view.source.cardId, category, filename: null }));
      }
      view.normalAttackStyle = { mode, sourceRows: Forge.clone(saved.sourceRows), sourceOrder: saved.sourceOrder.slice(), ownedRows: Forge.clone(remaining.filter((row) => normalControlCategories.includes(Number(row.category)))) };
    }
    p.tables.card_motions = view.tables.card_motions;
    p.schema.card_motions = view.schema.card_motions;
    if (view.normalAttackStyle) p.normalAttackStyle = view.normalAttackStyle;
    else delete p.normalAttackStyle;
    return true;
  }
  function targets(p) {
    var _a, _b, _c, _d, _e;
    const items = [];
    for (const r of p.tables.card_specials || []) {
      const set2 = (p.tables.special_sets || []).find((s) => s.id === r.special_set_id);
      items.push({ key: "super:" + r.id, table: "card_specials", row: r.id, field: "view_id", name: (r.style === "Hyper" ? "Ultra Super Attack" : r.style === "Extra" ? "EX Super Attack" : r.style === "FullPower" ? "Full-power attack" : (r.style === "Condition" ? "Conditional Super Attack" : "Super Attack")) + " · " + ((set2 == null ? void 0 : set2.name) || "Attack"), kind: r.style === "Extra" ? "ex" : r.style === "Hyper" ? "ultra" : r.style === "FullPower" ? "fullpower" : "super", damage: true });
    }
    for (const [table, kind, label] of [["active_skill_sets", "active", "Active Skill"], ["standby_skill_sets", "standby", "Standby"], ["finish_skill_sets", "finish", "Finish Skill"]]) for (const r of p.tables[table] || []) items.push({ key: kind + ":" + r.id, table, row: r.id, field: "special_view_id", name: label + " · " + r.name, kind, damage: kind === "finish" || Boolean(r.ultimate_special_id) });
    for (const category of [10001, 10003]) {
      const rows = (p.tables.card_motions || []).filter((r) => r.category === category), list = rows.length ? rows : [null];
      for (const [index, r] of list.entries()) items.push({ key: index ? "normal:" + r.id : "normal:melee:" + category, table: "card_motions", row: (_a = r == null ? void 0 : r.id) != null ? _a : null, field: "filename", name: (category === 10001 ? "Ground" : "Air") + " melee normal attack" + (index ? " · variation " + (index + 1) : ""), kind: "normal", category, virtual: !r, damage: true });
    }
    for (const category of [10002, 10004]) {
      const rows = (p.tables.card_motions || []).filter((r) => r.filename && r.category === category), list = rows.length ? rows : ["mixed", "ki"].includes(normalAttackStyle(p)) ? [null] : [];
      for (const [index, r] of list.entries()) {
        const virtualKey = "normal:ki:" + category, owned = r && ((_d = (_c = (_b = p.animationAssignments) == null ? void 0 : _b[virtualKey]) == null ? void 0 : _c.file) == null ? void 0 : _d.endsWith("/" + r.filename + ".lua"));
        items.push({ key: !r || owned ? virtualKey : "normal:" + r.id, table: "card_motions", row: (_e = r == null ? void 0 : r.id) != null ? _e : null, field: "filename", name: (category === 10002 ? "Ground" : "Air") + " Ki-blast normal attack" + (index ? " · variation " + (index + 1) : ""), kind: "normal", category, virtual: !r, damage: true });
      }
    }
    const set = Forge.primaryPassive(p), ids = new Set((p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === (set == null ? void 0 : set.id)).map((r) => r.passive_skill_id));
    // counters, revivals, transformations… of every passive the unit has (before EZA and each EZA step)
    const allIds = new Set((p.tables.passive_skill_set_relations || []).map((r) => r.passive_skill_id));
    for (const r of p.tables.passive_skills || []) if (allIds.has(r.id) && [120, 128].includes(r.efficacy_type)) items.push({ key: "counter:" + r.id, table: "passive_skills", row: r.id, field: "eff_value3", abilityIndex: 2, name: (r.efficacy_type === 128 ? "Dodge counterattack" : "Counterattack") + " · " + (r.name || "Passive counter"), kind: "counter", damage: true });
    if ((p.tables.passive_skills || []).some((r) => ids.has(r.id) && r.efficacy_type === 91)) items.push({ key: "dodge:unit", name: "Dodge · this character (experimental engine hook)", kind: "dodge", damage: false });
    for (const r of p.tables.passive_skills || []) if (ids.has(r.id) && r.exec_timing_type === 1) items.push({ key: "intro:" + r.id, table: "passive_skills", row: r.id, name: "Intro / passive animation · " + effectSummary(r), kind: "intro", damage: false });
    return items.concat(abilityTargets(p, allIds));
  }
  function numbersFromAbility(row, table = "passive_skills") {
    if (!row || ![120, 128].includes(Number(row.efficacy_type))) return [];
    let values;
    try {
      values = JSON.parse(row.efficacy_values || "{}");
    } catch {
    }
    const value = Number(Array.isArray(values) ? values[2] : row[table === "passive_skills" ? "eff_value3" : "eff_val3"]);
    return Number.isSafeInteger(value) && value > 0 ? [value] : [];
  }
  function counterNumbers(p) {
    var _a;
    const numbers = /* @__PURE__ */ new Set();
    for (const table of ["passive_skills", "active_skills", "standby_skills", "finish_skills"]) for (const row of ((_a = p.tables) == null ? void 0 : _a[table]) || []) for (const value of numbersFromAbility(row, table)) numbers.add(value);
    for (const file of [...p.generatedFiles || [], ...p.assets || [], ...Object.values(p.animationAssignments || {})]) {
      const match = String(file.path || file.file || "").match(/(?:^|\/)attack_counter\/c(\d+)\.lua$/i);
      if (match && Number.isSafeInteger(Number(match[1]))) numbers.add(Number(match[1]));
    }
    return [...numbers].sort((a, b) => a - b);
  }
  function reserveCounterScripts(p, occupiedNumbers) {
    var _a, _b, _c, _d, _e, _f;
    if (!Array.isArray(occupiedNumbers) && !(occupiedNumbers instanceof Set)) throw new Error("Check the game database, saved units and imported counter scripts before assigning a custom counter.");
    const occupied = new Set(occupiedNumbers), numbers = {}, targetsForCounter = targets(p).filter((t) => t.kind === "counter");
    for (const asset of p.assets || []) {
      const match = String(asset.path || "").match(/(?:^|\/)attack_counter\/c(\d+)\.lua$/i);
      if (match) occupied.add(Number(match[1]));
    }
    for (const file of p.generatedFiles || []) {
      if (targetsForCounter.some((t) => t.key === file.owner)) continue;
      const match = String(file.path || "").match(/(?:^|\/)attack_counter\/c(\d+)\.lua$/i);
      if (match) occupied.add(Number(match[1]));
    }
    for (const table of ["passive_skills", "active_skills", "standby_skills", "finish_skills"]) for (const row of ((_a = p.tables) == null ? void 0 : _a[table]) || []) {
      if (table === "passive_skills" && ((_b = p.animationAssignments) == null ? void 0 : _b["counter:" + row.id])) continue;
      for (const value of numbersFromAbility(row, table)) occupied.add(value);
    }
    let changed = false;
    for (const target of targetsForCounter) {
      const old = (_c = p.animationAssignments) == null ? void 0 : _c[target.key], reserved = (_e = (_d = p.counterScriptReservations) == null ? void 0 : _d.numbers) == null ? void 0 : _e[target.key], match = String((old == null ? void 0 : old.file) || "").match(/\/c(\d+)\.lua$/), previous = (_f = old == null ? void 0 : old.scriptNumber) != null ? _f : match ? Number(match[1]) : reserved;
      let value = previous;
      if (!Number.isInteger(value) || value < 1 || value > 16777215 || occupied.has(value)) {
        let hash = 2166136261;
        const seed = String(p.key) + "|" + p.targetId + "|" + target.key;
        for (let i = 0; i < seed.length; i++) hash = Math.imul(hash ^ seed.charCodeAt(i), 16777619) >>> 0;
        value = 1 + hash % 16777215;
        let attempts = 0;
        while (occupied.has(value)) {
          if (++attempts > 1e5) throw new Error("Could not reserve a free counter animation. Remove unused imported scripts or saved units and retry.");
          value = value === 16777215 ? 1 : value + 1;
        }
      }
      occupied.add(value);
      numbers[target.key] = value;
      if (value !== reserved) changed = true;
    }
    p.counterScriptReservations = { version: 1, numbers };
    return { numbers, changed };
  }
  function applyComposition(p, schema, clips, targetKey, name, options = {}) {
    const target = targets(p).find((t) => t.key === targetKey);
    if (!target) throw new Error("Choose an existing supported move slot.");
    clips = MovieModel.refreshClips(p, clips);
    const text = Motion.compile(clips, { damage: target.damage, recover: target.recover, role: target.role || "attacker", music: options.music });
    const assigned = assignAnimationText(p, schema, target, text, clips, name);
    if(options.music)assigned.music=Forge.clone(options.music);
    return assigned;
  }
  // Whole-original reuse is deliberately separate from the retiming compiler.
  // The catalog's exact native kind is required; a label or a filename alone
  // cannot establish that a script belongs to a compatible gameplay slot.
  const originalKinds = new Set(["super", "ultra", "ex", "fullpower", "active", "standby", "finish", "normal", "counter", "intro", "nullify", "revival", "transform", "giant"]);
  function checkOriginal(source, target) {
    if (!source || typeof source !== "object" || Array.isArray(source) || !target || !originalKinds.has(target.kind) || source.catalog?.kind !== target.kind) throw new Error("Reuse an original only in an existing move slot with the exact same native animation kind.");
    if (source.source || source.clips || ["from", "to", "x", "y", "zoom", "rotation", "opacity", "mirror", "mute", "actor"].some((field) => Object.prototype.hasOwnProperty.call(source, field))) throw new Error("Whole-original reuse cannot trim, transform, swap fighters or mute a section. Choose the original source itself.");
    if ((source.context && source.context !== "battle") || (source.catalog.context && source.catalog.context !== "battle") || source.movieBindingKey) throw new Error("Choose an original combat animation, rather than an item-screen scene or an authored movie section.");
    const path = source.path;
    if (typeof path !== "string" || !/^(?:lua\/)?ab_script\/[a-z][a-z0-9_]*\/[A-Za-z0-9_]+\.lua$/.test(path) || !Forge.safePath(path) || /\/common\/|\/training\/|\/awaken(?:ing)?\/|\/dg0001\.lua$/.test(path)) throw new Error("Choose an original animation with a safe, canonical combat script path.");
    if (source.catalog.path && (typeof source.catalog.path !== "string" || source.catalog.path.replace(/^lua\//, "") !== path.replace(/^lua\//, ""))) throw new Error("The original animation path does not match its catalog entry.");
    if (typeof source.text !== "string" || !source.text.trim() || source.text.length > 2 * 1024 * 1024 || new TextEncoder().encode(source.text).byteLength > 2 * 1024 * 1024) throw new Error("The original animation must contain at most 2 MB of source text.");
    const report = Motion.analyze(source.text);
    if (report.training || report.awakening) throw new Error("Training and awakening scenes cannot be reused in a combat move.");
    if (target.phase && source.catalog.phase && target.phase !== source.catalog.phase) throw new Error("Choose the same native form-animation phase for whole-original reuse.");
  }
  function canReuseOriginal(source, target) {
    try { checkOriginal(source, target); return true; } catch { return false; }
  }
  function applyOriginal(p, schema, source, targetKey, name) {
    const target = targets(p).find((t) => t.key === targetKey);
    if (!target) throw new Error("Choose an existing supported move slot.");
    checkOriginal(source, target);
    const next = Forge.clone(p), copy = Forge.clone(source), clip = Motion.createClip(copy);
    const assignment = assignAnimationText(next, schema, targets(next).find((t) => t.key === targetKey), copy.text, [clip], name, true);
    assignment.mode = "original";
    assignment.originalSource = Forge.clone(copy);
    Object.assign(p, next);
    return p.animationAssignments[targetKey];
  }
  function assignAnimationText(p, schema, target, text, clips, name, original = false) {
    var _a, _b, _c;
    p.animationAssignments = p.animationAssignments || {};
    const old = p.animationAssignments[target.key], index = (_a = old == null ? void 0 : old.index) != null ? _a : Math.max(-1, ...Object.values(p.animationAssignments).map((a) => a.index)) + 1, number = target.kind === "counter" ? (_c = (_b = p.counterScriptReservations) == null ? void 0 : _b.numbers) == null ? void 0 : _c[target.key] : Number(p.targetId) + 500 + index;
    if (target.kind === "counter" && (!Number.isInteger(number) || number < 1 || number > 16777215)) throw new Error("Reserve a counter animation using the current game database, Library and imported scripts, then apply the sequence again.");
    if (index > 100) throw new Error("Use no more than 100 assigned sequences in one unit.");
    if (original && (!Number.isSafeInteger(index) || index < 0 || !Number.isSafeInteger(number) || number < 1 || !Number.isSafeInteger(Number(p.targetId)) || Number(p.targetId) < 1e6 || Number(p.targetId) > 1999999000)) throw new Error("Reserve a valid private unit and animation slot before reusing an original move.");
    const prefix = target.kind === "normal" ? { 10001: "a", 10002: "ak", 10003: "b", 10004: "bk" }[target.category] : target.kind === "intro" ? "pse" : target.kind === "counter" ? "c" : target.kind === "nullify" ? "as" : target.kind === "revival" ? "rev" : target.kind === "transform" ? "tf" : target.kind === "giant" ? "enl" : "sp", folder = target.kind === "normal" ? { 10001: "attack_low", 10002: "attack_low_kidan", 10003: "attack_high", 10004: "attack_high_kidan" }[target.category] : target.kind === "intro" ? "passive_skill_effect" : target.kind === "counter" ? "attack_counter" : target.kind === "nullify" ? "ab_sys" : target.kind === "revival" ? "revival" : target.kind === "transform" ? "transformation" : target.kind === "giant" ? "enlarge" : "attack_sp", script = prefix + (target.kind === "counter" ? String(number).padStart(4, "0") : number), file = "lua/ab_script/" + folder + "/" + script + ".lua";
    if (original && ((p.assets || []).some((a) => a.path === file) || (p.generatedFiles || []).some((f) => f.path === file && f.owner !== target.key) || Object.entries(p.animationAssignments).some(([key, a]) => key !== target.key && a.file === file))) throw new Error("Another resource already owns this private animation file. Reserve a different unit slot before reusing it.");
    let id;
    if (["revival", "transform", "giant"].includes(target.kind)) {
      id = applyAbilityAnimation(p, schema, target, script);
    } else if (target.kind === "nullify") {
      referenceAbility(p, target, null, number);
      id = number;
    } else if (target.kind === "normal") {
      const list = ensure(p, schema, "card_motions");
      let row = list.find((r) => r.id === target.row);
      if (!row) {
        row = Object.assign(Forge.rowDefault(p.schema.card_motions), { id: Forge.localId(p, "card_motions"), card_id: p.source.cardId, category: target.category, filename: script });
        list.push(row);
      }
      row.filename = script;
      id = number;
    } else if (target.kind === "counter") {
      referenceAbility(p, target, null, number);
      id = number;
    } else {
      const table = target.kind === "intro" ? "passive_skill_effects" : "special_views", list = ensure(p, schema, table);
      const soleOwned = original && old && old.id < 0 && old.file === file && (p.generatedFiles || []).some((f) => f.owner === target.key && f.path === file) && !targets(p).some((t) => t.key !== target.key && (t.kind === "intro") === (target.kind === "intro") && (p.tables[t.table] || []).some((r) => r.id === t.row && r[t.kind === "intro" ? "passive_skill_effect_id" : t.field] === old.id));
      let record = old && (!original || soleOwned) && list.find((r) => r.id === old.id);
      if (!record) {
        const targetRow = (p.tables[target.table] || []).find((r) => r.id === target.row), previousView = original && list.find((r) => r.id === targetRow?.[target.kind === "intro" ? "passive_skill_effect_id" : target.field]);
        record = Object.assign(Forge.rowDefault(p.schema[table]), previousView ? Forge.clone(previousView) : original ? { lite_flicker_rate: 70, ...table === "special_views" ? { special_category_id: 1, cut_in_card_id: p.source.cardId } : {} } : {}, { id: Forge.localId(p, table) });
        list.push(record);
      }
      Object.assign(record, { script_name: script, ...!original ? { lite_flicker_rate: 70 } : {} });
      if (table === "special_views" && !original) Object.assign(record, { special_category_id: 1, cut_in_card_id: p.source.cardId });
      id = record.id;
      if (target.kind === "intro") {
        const effect = (p.tables.passive_skills || []).find((r) => r.id === target.row);
        if (!effect) throw new Error("Choose a start-of-turn ability to trigger the intro.");
        const base = Forge.primaryPassive(p), baseIds = new Set((p.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === (base == null ? void 0 : base.id)).map((r) => r.passive_skill_id));
        if (!original) for (const r of p.tables.passive_skills) if (r.id !== effect.id && baseIds.has(r.id)) r.passive_skill_effect_id = null;
        effect.passive_skill_effect_id = id;
        target.triggerId = effect.id;
      } else p.tables[target.table].find((r) => r.id === target.row)[target.field] = id;
    }
    p.generatedFiles = (p.generatedFiles || []).filter((f) => f.owner !== target.key);
    p.generatedFiles.push({ owner: target.key, path: file, text });
    p.animationAssignments[target.key] = { id, index, file, name, ...target.kind === "counter" ? { scriptNumber: number } : {}, triggerId: target.triggerId || (old == null ? void 0 : old.triggerId), clips: Forge.clone(clips), target: target.name };
    return p.animationAssignments[target.key];
  }
  const effectNames = { 1: "ATK", 2: "DEF", 3: "ATK & DEF", 4: "Recover HP", 5: "Ki", 9: "Stun", 13: "Damage reduction", 16: "Type-specific ATK", 17: "Type-specific DEF", 18: "Type-specific ATK & DEF", 20: "Type-specific Ki", 48: "Seal Super Attack", 50: "Prevent status effects", 51: "Change Ki Sphere colors", 59: "ATK per Ki Sphere", 60: "DEF per Ki Sphere", 61: "ATK & DEF per Ki Sphere", 64: "ATK per matching-color Ki Sphere", 65: "DEF per matching-color Ki Sphere", 66: "ATK & DEF per matching-color Ki Sphere", 76: "Attacks effective against all Types", 78: "Guard", 79: "Giant form", 81: "Additional attack", 86: "Super Attack power", 90: "Critical hit chance", 91: "Dodge chance", 97: "Absorb or nullify Super Attack", 103: "Transformation", 119: "Absorb or nullify an attack", 120: "Counterattack", 128: "Dodge counterattack" };
  function effectSummary(r) {
if(battleBuffKinds.some(([id])=>id===r.efficacy_type))return battleBuffKinds.find(([id])=>id===r.efficacy_type)[1]+' · '+r.probability+'% chance';if(colorSphereKinds.some(([id])=>id===r.efficacy_type)){if(!canEditColorSphereBonus(r))return 'Inherited color-filtered Ki Sphere bonus';return sphereTypes[r.eff_value1]+' characters: '+colorSphereKinds.find(([id])=>id===r.efficacy_type)[1]+' +'+r.eff_value2+'% per '+sphereTypes[r.eff_value3]+' Ki Sphere obtained';}if(sphereBonusKinds.some(([id])=>id===r.efficacy_type)){const kind=sphereBonusKinds.find(([id])=>id===r.efficacy_type)[1],sign=[1,3].includes(r.calc_option)?'−':r.calc_option===4?' = ':'+',unit=[2,3].includes(r.calc_option)?'%':'';return (r.efficacy_type===61?'ATK '+sign+r.eff_value1+unit+' and DEF '+sign+r.eff_value2+unit:kind+' '+sign+r.eff_value1+unit)+' per Ki Sphere obtained';}if(typeSupportKinds.some(([id])=>id===r.efficacy_type)){const kind=typeSupportKinds.find(([id])=>id===r.efficacy_type)[1],sign=[1,3].includes(r.calc_option)?'−':r.calc_option===4?' = ':'+',unit=[2,3].includes(r.calc_option)?'%':'';return (sphereTypes[r.eff_value1]||'Inherited type')+' · '+(r.efficacy_type===18?'ATK '+sign+r.eff_value2+unit+' and DEF '+sign+r.eff_value3+unit:kind+' '+sign+r.eff_value2+unit);}if(r.efficacy_type===51)return 'Change '+(sphereTypes[r.eff_value1]||'inherited')+' Ki Spheres to '+(sphereTypes[r.eff_value2]||'inherited')+' Ki Spheres';

    const name = effectNames[r.efficacy_type] || "Inherited gameplay effect", sign = [1, 3].includes(r.calc_option) ? "−" : r.calc_option === 4 ? " = " : "+", unit = [2, 3].includes(r.calc_option) ? "%" : "";
    if (r.efficacy_type === 13) return 100 - Number(r.eff_value1) + "% damage reduction";
    if ([78, 9, 48].includes(r.efficacy_type)) return name + " · " + r.probability + "% chance";
    if ([90, 91].includes(r.efficacy_type)) return name + " " + r.eff_value1 + "%";
    if (r.efficacy_type === 3) return "ATK " + sign + r.eff_value1 + unit + " and DEF " + sign + r.eff_value2 + unit;
    if ([1, 2, 4, 5, 86].includes(r.efficacy_type)) return name + " " + sign + r.eff_value1 + unit;
    return name;
  }
  return { battleBuffKinds, addBattleBuff, colorSphereKinds, colorSphereProfiles, colorSphereOptions, canEditColorSphereBonus, setColorSphereBonus, addColorSphereBonus, sphereBonusKinds, setSphereBonus, addSphereBonus, typeSupportKinds, setTypeSupport, addTypeSupport, sphereTypes, addKiSphereChange, setKiSphereChange, normalAttackStyle, setNormalAttackStyle, conditionGroup, categoryLeader, abilityStages, stageAbilityId, stageSet, setStageAbility, editStage, isolateAbilityStage, references, ensure, conditionLabel, describeCondition, setCondition, importOwned, allocateId, targets, numbersFromAbility, counterNumbers, reserveCounterScripts, applyComposition, canReuseOriginal, applyOriginal, restoreAbilityAnimation, effectSummary, effectNames };
});
