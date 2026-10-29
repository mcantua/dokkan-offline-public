(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./sparking-dependencies"));
  else root.Forge = factory(root.ForgeSparkingDependencies);
})(typeof globalThis !== "undefined" ? globalThis : this, function(SparkingDependencies) {
  "use strict";
  const clone = (value) => JSON.parse(JSON.stringify(value));
  const foreign = {
    card_category_id: "card_categories",
    special_category_id: "special_categories",
    view_id: "special_views",
    special_view_id: "special_views",
    bonus_view_id1: "special_views",
    bonus_view_id2: "special_views",
    cut_in_card_id: "cards",
    card_id: "cards",
    passive_skill_set_id: "passive_skill_sets",
    passive_skill_id: "passive_skills",
    target_passive_skill_set_id: "passive_skill_sets",
    additional_passive_skill_set_id: "passive_skill_sets",
    leader_skill_set_id: "leader_skill_sets",
    special_set_id: "special_sets",
    active_skill_set_id: "active_skill_sets",
    standby_skill_set_id: "standby_skill_sets",
    finish_skill_set_id: "finish_skill_sets",
    dokkan_field_id: "dokkan_fields",
    finish_special_id: "finish_specials",
    awaked_card_id: "cards"
  };
  // Eclipse-compatible ID layout (matches custom units that load correctly in Eclipse):
  // 8-digit card IDs ending in 1 (97xxx001), per-unit row IDs in the same 1,000 block, and the
  // *_skill_sets tables in the matching 7-digit block (card ID / 10). Earlier builds used
  // 10-digit IDs (1,950,000,001+), which Eclipse does not handle; those units are moved on export.
  const SLOT_FLOOR = 97000001, SLOT_CEILING = 98999001, LEGACY_SLOT = 1e8;
  const Forge_SLOT_FLOOR = SLOT_FLOOR, Forge_SLOT_CEILING = SLOT_CEILING;
  const SET_TABLES = new Set(["passive_skill_sets", "leader_skill_sets", "active_skill_sets"]);
  const SKILL_TYPES = { PassiveSkill: "passive_skills", ActiveSkill: "active_skills", StandbySkill: "standby_skills", FinishSkill: "finish_skills" };
  const legacySlot = (id) => Number(id) >= LEGACY_SLOT;
  const direct = ["card_card_categories", "card_specials", "card_active_skills", "card_standby_skill_set_relations", "card_finish_skill_set_relations", "card_motions", "passive_skill_set_additions"];
  const elements = { 0: "AGL", 1: "TEQ", 2: "INT", 3: "STR", 4: "PHY", 10: "Super AGL", 11: "Super TEQ", 12: "Super INT", 13: "Super STR", 14: "Super PHY", 20: "Extreme AGL", 21: "Extreme TEQ", 22: "Extreme INT", 23: "Extreme STR", 24: "Extreme PHY" };
  const rarities = ["N", "R", "SR", "SSR", "UR / TUR", "LR"];
  function nextUnitId(projects, ownKey, floor = SLOT_FLOOR) {
    if (!Array.isArray(projects) || !Number.isSafeInteger(floor)) throw new Error("Load the saved unit list before reserving a unit slot.");
    if (legacySlot(floor)) floor = SLOT_FLOOR;
    const ids = projects.filter((p) => p && p.key !== ownKey).flatMap((p) => [p.targetId, ...(p.formProjects || []).map((f) => f.targetId), ...(p.reservedIds || [])]).map(Number).filter((id) => Number.isSafeInteger(id) && id >= floor && id <= SLOT_CEILING);
    const base = Math.max(floor, ...ids.map((id) => id + 1e3)), candidate = Math.ceil((base - 1) / 1e3) * 1e3 + 1;
    if (candidate > SLOT_CEILING) throw new Error("The custom unit storage range is full.");
    return candidate;
  }
  function playerRosterEligibility(project, options = {}) {
    const c = card(project), id = Number(project.targetId), issues = [];
    if (!Number.isSafeInteger(id) || id % 10 !== 1) issues.push("Choose a unit slot ending in 1 so Eclipse can list this as a player character. Automatic unit slots already use this format.");
    if (!(id > 1e6 && id < 2e6 || id > 4e6 && id < 5e6 || id > 9999999)) issues.push("Choose an automatic custom unit slot; this number is outside Eclipse’s normal player-card ranges.");
    if (!(Number(c.hp_max) > 300)) issues.push("Set maximum HP above 300 in Stats to qualify for Eclipse’s player-character list.");
    if (c.leader_skill_set_id == null) issues.push("Choose a source with a leader skill, or copy a complete leader skill, before using this as a player character.");
    if (c.passive_skill_set_id == null) issues.push("Choose a source with battle abilities, or copy its complete passive, before using this as a player character.");
    const basicIssueCount = issues.length;
    const cardId = (value) => Number(value) === Number(project.source.cardId) ? id : Number(value), costumes = [...options.costumeCardIds || [], ...(Array.isArray(project.tables.card_costumes) ? project.tables.card_costumes : []).map((r) => cardId(r.card_id))], items = [...options.itemCardIds || [], ...(Array.isArray(project.tables.item_card_properties) ? project.tables.item_card_properties : []).map((r) => cardId(r.card_id))];
    if (costumes.some((value) => Number(value) === id - 1)) issues.push("This unit slot is excluded by an existing costume record in the game’s normal player-card list. Reserve a different unit slot.");
    if (items.some((value) => Number(value) === id)) issues.push("This unit slot is marked as an item card in the game’s normal player-card list. Reserve a different unit slot.");
    return { ready: issues.length === 0, issues, catalogIssues: issues.slice(basicIssueCount), catalogExclusionsChecked: options.catalogExclusionsChecked === true, scope: "Native player-card list filters only; owned-card injection and actual gameplay need separate verification." };
  }
  async function readAbilityAnimationSources(query, schema, tables, known = {}) {
    var _a, _b, _c;
    const abilityAnimationSources = clone(known);
    for (const table of ["passive_skills", "active_skills", "standby_skills", "finish_skills"]) for (const skill of tables[table] || []) {
      const effect = Number(skill.efficacy_type);
      if (![79, 103, 109].includes(effect) || abilityAnimationSources[table + ":" + skill.id]) continue;
      let values;
      try {
        const raw = JSON.parse(skill.efficacy_values || "{}");
        values = Array.isArray(raw) ? raw : null;
      } catch {
      }
      if (!values) values = table === "passive_skills" ? [skill.eff_value1, skill.eff_value2, skill.eff_value3] : [skill.eff_val1, skill.eff_val2, skill.eff_val3];
      const input = { effect, values: clone(values), cardId: (_b = (_a = tables.cards) == null ? void 0 : _a[0]) == null ? void 0 : _b.id };
      if (effect === 109 && Number(values[1]) > 0 && schema.revival_views) {
        input.view = (await query({ table: "revival_views", filters: { id: Number(values[1]) }, limit: 1 }))[0] || null;
      } else if ([79, 103].includes(effect) && Number(values[2]) > 0 && schema.battle_params) {
        input.params = await query({ table: "battle_params", filters: { param_no: Number(values[2]) }, limit: 500 });
        input.viewIndex = effect === 103 ? 11 : 12;
        input.viewTable = effect === 103 ? "transformation_views" : "metamorphic_views";
        const viewId = (_c = input.params.find((r) => r.idx === input.viewIndex)) == null ? void 0 : _c.value;
        if (viewId && schema[input.viewTable]) input.view = (await query({ table: input.viewTable, filters: { id: viewId }, limit: 1 }))[0] || null;
      }
      abilityAnimationSources[table + ":" + skill.id] = clone(input);
    }
    return abilityAnimationSources;
  }
  async function hydrateAbilityAnimations(project, query, schema) {
    project.abilityAnimationSources = await readAbilityAnimationSources(query, schema, project.tables, project.abilityAnimationSources || {});
    return project;
  }
  async function loadTemplate(query, schema, cardId, newId) {
    const tables = {}, seen = {};
    async function read(table, filters) {
      if (!schema[table]) return [];
      const rows = await query({ table, filters, limit: 5e3 });
      tables[table] = tables[table] || [];
      seen[table] = seen[table] || /* @__PURE__ */ new Set();
      for (const row of rows) if (!seen[table].has(row.id)) {
        tables[table].push(clone(row));
        seen[table].add(row.id);
      }
      return rows;
    }
    const roots = await read("cards", { id: cardId });
    if (!roots.length) throw new Error("This source card is not in the active database.");
    const card2 = roots[0];
    for (const table of direct) await read(table, { card_id: cardId });
    if (card2.optimal_awakening_grow_type) await read("optimal_awakening_growths", { optimal_awakening_grow_type: card2.optimal_awakening_grow_type });
    const passiveIds = /* @__PURE__ */ new Set([card2.passive_skill_set_id]);
    const leaderIds = /* @__PURE__ */ new Set([card2.leader_skill_set_id]);
    for (const row of tables.optimal_awakening_growths || []) {
      passiveIds.add(row.passive_skill_set_id);
      leaderIds.add(row.leader_skill_set_id);
    }
    for (const row of tables.passive_skill_set_additions || []) {
      passiveIds.add(row.target_passive_skill_set_id);
      passiveIds.add(row.additional_passive_skill_set_id);
    }
    for (const id of passiveIds) if (id) {
      await read("passive_skill_sets", { id });
      const relations = await read("passive_skill_set_relations", { passive_skill_set_id: id });
      for (const rel of relations) await read("passive_skills", { id: rel.passive_skill_id });
    }
    for (const id of leaderIds) if (id) {
      await read("leader_skill_sets", { id });
      await read("leader_skills", { leader_skill_set_id: id });
    }
    for (const row of tables.card_specials || []) {
      await read("special_sets", { id: row.special_set_id });
      await read("specials", { special_set_id: row.special_set_id });
      await read("extra_special_options", { card_special_id: row.id });
    }
    for (const row of tables.card_active_skills || []) {
      await read("active_skill_sets", { id: row.active_skill_set_id });
      await read("active_skills", { active_skill_set_id: row.active_skill_set_id });
    }
    for (const row of tables.active_skill_sets || []) await read("dokkan_field_active_skill_set_relations", { active_skill_set_id: row.id });
    for (const row of tables.passive_skills || []) await read("dokkan_field_passive_skill_relations", { passive_skill_id: row.id });
    for (const row of tables.card_standby_skill_set_relations || []) {
      await read("standby_skill_sets", { id: row.standby_skill_set_id });
      await read("standby_skills", { standby_skill_set_id: row.standby_skill_set_id });
      await read("standby_skill_set_finish_skill_set_relations", { standby_skill_set_id: row.standby_skill_set_id });
    }
    const finishIds = new Set((tables.card_finish_skill_set_relations || []).map((r) => r.finish_skill_set_id));
    for (const row of tables.standby_skill_set_finish_skill_set_relations || []) finishIds.add(row.finish_skill_set_id);
    for (const id of finishIds) {
      const sets = await read("finish_skill_sets", { id });
      await read("finish_skills", { finish_skill_set_id: id });
      for (const set of sets) if (set.finish_special_id) await read("finish_specials", { id: set.finish_special_id });
    }
    const usedSchema = {};
    for (const table of Object.keys(tables)) usedSchema[table] = clone(schema[table]);
    for (const table of ["leader_skill_sets", "leader_skills", "passive_skill_sets", "passive_skill_set_relations", "passive_skills"]) {
      tables[table] = tables[table] || [];
      usedSchema[table] = clone(schema[table] || []);
    }
    const abilityAnimationSources = await readAbilityAnimationSources(query, schema, tables);
    const stamp = (/* @__PURE__ */ new Date()).toISOString();
    // Some source cards (notably unfinished Sparking entries) store a starting stat above its
    // maximum. Clamp those starting values so a fresh copy passes validation and exports.
    const statFix = {};
    for (const stat of ["hp", "atk", "def"]) {
      const init = Number(card2[stat + "_init"]), max = Number(card2[stat + "_max"]);
      if (Number.isFinite(init) && Number.isFinite(max) && max >= 0 && (init > max || init < 0)) statFix[stat + "_init"] = Math.max(0, Math.min(init, max));
    }
    const project = {
      format: "dokkan-unit-forge",
      version: 1,
      key: "unit-" + newId + "-" + Date.now(),
      createdAt: stamp,
      updatedAt: stamp,
      source: { cardId, name: card2.name, resourceId: card2.resource_id || Math.floor(cardId / 10) * 10 },
      targetId: newId,
      patch: { name: card2.name + " — Custom Unit", author: "", version: "1.0.0", description: "", uuid: uuid() },
      tables,
      schema: usedSchema,
      abilityAnimationSources,
      assets: [],
      notes: "",
      cardOverrides: { name: card2.name, resource_id: card2.resource_id || Math.floor(cardId / 10) * 10, ...statFix }
    };
    await hydrateStatGrowth(project, query, schema);
    return project;
  }
  // Game records that Eclipse expects next to a card's skills but that are keyed by skill rows
  // rather than by the card: Extreme Z-Awakening routes, EX Super Attack options and the
  // transformation descriptions shown/used for every transformation skill. Returns true when
  // anything was added (also used to upgrade units saved by earlier versions before export).
  async function hydrateNativeRecords(project, query, schema, { gameRecords = true } = {}) {
    let changed = await hydrateStatGrowth(project, query, schema);
    const tables = project.tables, sourceId = Number(project.source.cardId);
    const has = (table, pred) => (tables[table] || []).some(pred);
    const add = (table, row) => {
      if (!schema[table]) return;
      if (!project.schema[table]) project.schema[table] = clone(schema[table]);
      tables[table] = tables[table] || [];
      if (tables[table].some((r) => r.id === row.id)) return;
      tables[table].push(clone(row));
      changed = true;
    };
    if (gameRecords && schema.card_awakening_routes && Number(card(project).optimal_awakening_grow_type) > 0 && !has("card_awakening_routes", () => true)) {
      const routes = await query({ table: "card_awakening_routes", filters: { card_id: sourceId }, limit: 100 });
      for (const route of routes) if (route.type === "CardAwakeningRoute::Optimal" && Number(route.awaked_card_id) === sourceId) add("card_awakening_routes", route);
    }
    if (gameRecords && schema.extra_special_options) for (const special of tables.card_specials || []) {
      if (!(Number(special.id) > 0) || has("extra_special_options", (r) => r.card_special_id === special.id)) continue;
      for (const option of await query({ table: "extra_special_options", filters: { card_special_id: special.id }, limit: 10 })) add("extra_special_options", option);
    }
    if (schema.transformation_descriptions) for (const [type, table] of Object.entries(SKILL_TYPES)) for (const row of tables[table] || []) {
      if (Number(row.efficacy_type) !== 103 || has("transformation_descriptions", (d) => d.skill_type === type && d.skill_id === row.id)) continue;
      const found = Number(row.id) > 0 ? await query({ table: "transformation_descriptions", filters: { skill_type: type, skill_id: row.id }, limit: 5 }) : [];
      if (found.length) found.forEach((r) => add("transformation_descriptions", r));
      else {
        if (!project.schema.transformation_descriptions) project.schema.transformation_descriptions = clone(schema.transformation_descriptions);
        add("transformation_descriptions", Object.assign(rowDefault(project.schema.transformation_descriptions), { id: localId(project, "transformation_descriptions"), skill_type: type, skill_id: row.id, description: "Transforms when its conditions are met" }));
      }
    }
    return changed;
  }
  // Our authored high-cap policy, shared with Offline Dokkan's normalized evaluator.
  // Original game rounding is not verified. These are newly generated custom curves,
  // never replacements for an official source grow_type.
  const STAT_POLICY = "creator-cap-normalized-v1";
  function sourceGrowth(project) {
    const metadata = project.sourceStatGrowth, type = Number(card(project).grow_type);
    if (!metadata || metadata.policy !== STAT_POLICY || metadata.sourceGrowType !== type || !Array.isArray(metadata.rows) || metadata.rows.length < 2 || metadata.rows.length > 5000) throw new Error("This high-level unit needs its source stat-growth curve. Reopen its source database and export again.");
    const coefficients = metadata.rows.map((row, i) => {
      const value = Number(row.coef), scaled = value * 1000, exact = Math.round(scaled);
      if (row.lv !== i + 1 || !Number.isFinite(value) || value < 0 || exact > 2147483647 || Math.abs(scaled - exact) > 0.000001) throw new Error("This source stat-growth curve is incomplete or unsupported. Reopen its source database before exporting.");
      return exact;
    });
    if (coefficients.some((v, i) => i && v < coefficients[i - 1]) || coefficients.at(-1) <= coefficients[0]) throw new Error("This source stat-growth curve does not increase. Choose a supported source.");
    return coefficients;
  }
  // Keep the derived source coefficient as its already-checked thousandth.
  // A JSON number can change by one ULP on save and come back as a different
  // value. This does not round an authored stat.
  function derivedCoefficient(value) {
    const numeric = Number(value), scaled = numeric * 1000, exact = Math.round(scaled);
    if (!Number.isFinite(numeric) || exact < 0 || exact > 2147483647 || Math.abs(scaled - exact) > 0.000001) return null;
    return Math.floor(exact / 1000) + "." + String(exact % 1000).padStart(3, "0");
  }
  async function hydrateStatGrowth(project, query, schema) {
    if (!project || project.awaken || !project.tables?.cards?.length) return false;
    const high = Number(card(project).lv_max) > 150;
    if (!schema.card_growths) {
      if (high) throw new Error("The selected database has no stat-growth table. Reopen the matching game database before exporting.");
      return false;
    }
    const type = Number(card(project).grow_type);
    if (!Number.isSafeInteger(type) || type < 0) {
      if (high) throw new Error("Choose a source card with a valid stat-growth type.");
      return false;
    }
    const rows = await query({ table: "card_growths", filters: { grow_type: type }, limit: 5000 });
    const candidate = { policy: STAT_POLICY, sourceGrowType: type, rows: rows.map(row => ({ lv: Number(row.lv), coef: derivedCoefficient(row.coef) ?? Number(row.coef) })).sort((a, b) => a.lv - b.lv) };
    try { sourceGrowth({ ...project, sourceStatGrowth: candidate }); } catch (error) { if (high) throw error; return false; }
    if (high && project.statPolicy && project.statPolicy !== STAT_POLICY) throw new Error("This unit uses a different pinned stat policy. Keep that policy or create a separate unit before changing growth.");
    const changed = JSON.stringify(project.sourceStatGrowth) !== JSON.stringify(candidate) || high && project.statPolicy !== STAT_POLICY || JSON.stringify(project.schema.card_growths) !== JSON.stringify(schema.card_growths);
    project.sourceStatGrowth = candidate;
    project.schema.card_growths = clone(schema.card_growths);
    if (high) project.statPolicy = STAT_POLICY;
    return changed;
  }
  function authoredStatGrowth(project) {
    const c = card(project), cap = Number(c.lv_max);
    if (project.awaken || cap <= 150 && project.statPolicy !== STAT_POLICY) return null;
    const id = Number(project.targetId), columns = project.schema.card_growths;
    if (!Number.isInteger(cap) || cap < 2 || cap > 200) throw new Error("Authored stat growth supports maximum levels 2 through 200.");
    if (!Number.isSafeInteger(id) || id < SLOT_FLOOR || id > SLOT_CEILING || id % 1000 !== 1) throw new Error("This high-level unit needs an automatic private unit slot before exporting.");
    if (project.statPolicy !== STAT_POLICY) throw new Error("This high-level unit needs its authored stat policy. Reopen its source database and export again.");
    if (!Array.isArray(columns) || ["id", "grow_type", "lv", "coef"].some(name => !columns.some(col => col.name === name)) || columns.filter(col => Number(col.pk) > 0).length !== 1 || !columns.some(col => col.name === "id" && Number(col.pk) === 1)) throw new Error("The source stat-growth schema is unsupported. Reopen the matching game database before exporting.");
    if ((project.tables.card_growths || []).length) throw new Error("Remove manual stat-growth rows before using the authored high-level curve.");
    const curve = sourceGrowth(project), scale = BigInt(cap - 1), start = BigInt(curve[0]), span = BigInt(curve.at(-1)) - start;
    return Array.from({ length: cap }, (_, index) => {
      const position = BigInt(index) * BigInt(curve.length - 1), low = Number(position / scale), remainder = position % scale;
      let numerator = (BigInt(curve[low]) - start) * scale;
      if (remainder) numerator += (BigInt(curve[low + 1]) - BigInt(curve[low])) * remainder;
      const coefficient = Number(numerator) / Number(span * scale);
      return { ...rowDefault(columns), id: id + index, grow_type: id, lv: index + 1, coef: coefficient };
    });
  }
  function uuid() {
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      return (c === "x" ? r : r & 3 | 8).toString(16);
    });
  }
  function card(project) {
    return Object.assign({}, project.tables.cards[0], project.cardOverrides);
  }
  function rowDefault(schema) {
    const out = {};
    for (const col of schema || []) {
      let v = col.dflt_value;
      if (v != null && /^NULL$/i.test(String(v))) v = null;
      if (v != null && /^-?\d+(\.\d+)?$/.test(String(v))) v = Number(v);
      else if (v != null && /^'.*'$/.test(v)) v = v.slice(1, -1).replace(/''/g, "'");
      else if (v != null && /CURRENT_TIMESTAMP/i.test(v)) v = (/* @__PURE__ */ new Date()).toISOString().slice(0, 19).replace("T", " ");
      else if (v == null && col.notnull) v = /INT|REAL|NUM/i.test(col.type) ? 0 : /DATE|TIME/i.test(col.type) ? (/* @__PURE__ */ new Date()).toISOString().slice(0, 19).replace("T", " ") : "";
      out[col.name] = v == null ? null : v;
    }
    return out;
  }
  function localId(project, table) {
    return Math.min(0, ...(project.tables[table] || []).map((r) => Number(r.id) || 0)) - 1;
  }
  function primaryPassive(project) {
    return (project.tables.passive_skill_sets || []).find((r) => r.id === card(project).passive_skill_set_id);
  }
  function addPassive(project, fields) {
    let set = primaryPassive(project);
    if (!set) {
      set = Object.assign(rowDefault(project.schema.passive_skill_sets), { id: localId(project, "passive_skill_sets"), name: "Custom passive", itemized_description: "" });
      project.tables.passive_skill_sets.push(set);
      project.cardOverrides.passive_skill_set_id = set.id;
    }
    const skill = Object.assign(rowDefault(project.schema.passive_skills), {
      id: localId(project, "passive_skills"),
      name: set.name,
      exec_timing_type: 1,
      exec_game_type: 0,
      efficacy_type: 3,
      target_type: 1,
      sub_target_type_set_id: 0,
      passive_skill_effect_id: null,
      calc_option: 2,
      turn: 1,
      is_once: 0,
      probability: 100,
      causality_conditions: null,
      eff_value1: 100,
      eff_value2: 100,
      eff_value3: 0,
      efficacy_values: "{}"
    }, fields);
    project.tables.passive_skills.push(skill);
    project.tables.passive_skill_set_relations.push(Object.assign(rowDefault(project.schema.passive_skill_set_relations), {
      id: localId(project, "passive_skill_set_relations"),
      passive_skill_set_id: set.id,
      passive_skill_id: skill.id
    }));
    return skill;
  }
  function removePassive(project, id) {
    project.tables.passive_skills = project.tables.passive_skills.filter((r) => r.id !== id);
    project.tables.passive_skill_set_relations = project.tables.passive_skill_set_relations.filter((r) => r.passive_skill_id !== id);
    if (project.tables.dokkan_field_passive_skill_relations) project.tables.dokkan_field_passive_skill_relations = project.tables.dokkan_field_passive_skill_relations.filter((r) => r.passive_skill_id !== id);
    project.animationReferences = (project.animationReferences || []).filter((r) => !(r.table === "passive_skills" && r.row === id));
    const sourceKey = "passive_skills:" + id;
    for (const key of Object.keys(project.animationAssignments || {})) if (["nullify", "revival", "transform", "giant"].some((k) => key === k + ":" + sourceKey || key.startsWith(k + ":" + sourceKey + ":"))) {
      delete project.animationAssignments[key];
      project.generatedFiles = (project.generatedFiles || []).filter((f) => f.owner !== key);
    }
    if (project.abilityAnimationSources) delete project.abilityAnimationSources[sourceKey];
    if (project.abilityAnimationOverrides) delete project.abilityAnimationOverrides[sourceKey];
  }
  function allTypesLeader(project, ki, stats) {
    const root = card(project);
    let set = project.tables.leader_skill_sets.find((r) => r.id === root.leader_skill_set_id);
    if (!set) {
      set = Object.assign(rowDefault(project.schema.leader_skill_sets), { id: localId(project, "leader_skill_sets") });
      project.tables.leader_skill_sets.push(set);
      project.cardOverrides.leader_skill_set_id = set.id;
    }
    set.name = "All-Type Potential";
    set.description = `All Types Ki +${ki} and HP, ATK & DEF +${stats}%`;
    project.tables.leader_skills = project.tables.leader_skills.filter((r) => r.leader_skill_set_id !== set.id);
    for (const [effect, value, calc] of [[82, stats, 2], [83, ki, 0]]) project.tables.leader_skills.push(Object.assign(rowDefault(project.schema.leader_skills), {
      id: localId(project, "leader_skills"),
      leader_skill_set_id: set.id,
      exec_timing_type: 1,
      target_type: 2,
      sub_target_type_set_id: 0,
      causality_conditions: null,
      efficacy_type: effect,
      efficacy_values: JSON.stringify([31, Number(value), 0]),
      calc_option: calc
    }));
  }
  function compileCondition(source) {
    source = String(source).trim();
    if (!source) return null;
    const tokens = source.match(/\d+|[&|!()]/g) || [];
    if (tokens.join("") !== source.replace(/\s/g, "")) throw new Error("Conditions accept numeric IDs, &, |, !, and parentheses.");
    let at = 0;
    function atom() {
      const t = tokens[at++];
      if (t === "!") return ["!", atom()];
      if (t === "(") {
        const v = or();
        if (tokens[at++] !== ")") throw new Error("Unclosed condition parentheses.");
        return v;
      }
      if (!/^\d+$/.test(t || "")) throw new Error("Expected a condition ID.");
      return Number(t);
    }
    function and() {
      let v = atom();
      while (tokens[at] === "&") {
        at++;
        v = ["&", v, atom()];
      }
      return v;
    }
    function or() {
      let v = and();
      while (tokens[at] === "|") {
        at++;
        v = ["|", v, and()];
      }
      return v;
    }
    const compiled = or();
    if (at !== tokens.length) throw new Error("Unexpected condition token.");
    return JSON.stringify({ source: source.replace(/\s/g, ""), compiled });
  }
  function animationReferenceErrors(project) {
    var _a, _b, _c;
    const errors = [];
    if (project.animationReferences !== void 0 && !Array.isArray(project.animationReferences)) return ["Gameplay animation references must be a list."];
    if ((project.animationReferences || []).length > 1e4) return ["This project contains too many gameplay animation references."];
    for (const ref of project.animationReferences || []) {
      const rows = (_a = project.tables) == null ? void 0 : _a[ref == null ? void 0 : ref.table], targets = (_b = project.tables) == null ? void 0 : _b[ref == null ? void 0 : ref.targetTable], columns = (_c = project.schema) == null ? void 0 : _c[ref == null ? void 0 : ref.table];
      if (!ref || typeof ref !== "object" || !Number.isSafeInteger(ref.row) || !Number.isSafeInteger(ref.targetId) || !Array.isArray(rows) || !Array.isArray(targets) || !Array.isArray(columns) || !rows.some((r) => r.id === ref.row) || !targets.some((r) => r.id === ref.targetId) || !columns.some((c) => c.name === ref.field) || !/^[a-z][a-z0-9_]*$/.test(ref.field || "")) {
        errors.push("An assigned gameplay animation has an invalid or missing database reference.");
        continue;
      }
      if (ref.index !== void 0 && (ref.field !== "efficacy_values" || !Number.isInteger(ref.index) || ref.index < 0 || ref.index > 15)) errors.push("A gameplay animation has an invalid ability-value position.");
    }
    return errors;
  }
  // EZA / Super EZA of an existing game card. Only rows created by this project (local, negative
  // IDs) are exported, in the project's own ID block; rows copied from the game keep pointing at
  // their official IDs and are never re-written. The single exception is the awakened card itself,
  // whose official row is re-exported unchanged except for its Extreme Z-Awakening growth type.
  function materializeAwaken(project) {
    const a = project.awaken, targetId = Number(project.targetId), cardId = Number(a && a.cardId);
    if (!Number.isSafeInteger(cardId) || cardId <= 0 || Number(project.source.cardId) !== cardId) throw new Error("This awakening project lost its card. Create the EZA again.");
    const bindingErrors = animationReferenceErrors(project);
    if (bindingErrors.length) throw new Error(bindingErrors.join("\n"));
    const tables = {}, maps = {};
    for (const [table, rows] of Object.entries(project.tables)) {
      if (table === "cards") continue;
      const local = rows.filter((row) => Number(row.id) < 0);
      if (!local.length) continue;
      if (local.length >= 1e3) throw new Error(`Too many rows in ${table}; this unit's reserved ID block holds 999 rows.`);
      const setTable = SET_TABLES.has(table);
      if (setTable && local.length >= 100) throw new Error(`Too many rows in ${table}; this unit's reserved skill-set block holds 99 rows.`);
      const base = setTable ? Math.floor(targetId / 10) : targetId;
      maps[table] = new Map(local.map((row, index) => [row.id, base + index]));
      tables[table] = clone(local);
    }
    const stamp = (/* @__PURE__ */ new Date()).toISOString().slice(0, 19).replace("T", " ");
    for (const [table, rows] of Object.entries(tables)) for (const row of rows) {
      row.id = maps[table].get(row.id);
      for (const [field, value] of Object.entries(row)) {
        if (field === "id") continue;
        const target = foreign[field] || (field.endsWith("_id") ? field.slice(0, -3) + "s" : null);
        if (target && maps[target] && maps[target].has(value)) row[field] = maps[target].get(value);
        if (Number(value) < 0 && target && !(maps[target] && maps[target].has(value)) && !["sub_target_type_set_id"].includes(field)) throw new Error("A new " + table + " record points at a missing " + target + " record. Undo the last change and try again.");
      }
      if (table === "optimal_awakening_growths") row.optimal_awakening_grow_type = targetId;
      if (table === "transformation_descriptions") {
        const skillTable = SKILL_TYPES[row.skill_type];
        if (skillTable && maps[skillTable] && maps[skillTable].has(row.skill_id)) row.skill_id = maps[skillTable].get(row.skill_id);
      }
      if (row.causality_conditions && maps.skill_causalities) {
        try {
          const condition = JSON.parse(row.causality_conditions), remap = (n) => typeof n === "number" ? (maps.skill_causalities.has(n) ? maps.skill_causalities.get(n) : n) : Array.isArray(n) ? n.map(remap) : n;
          condition.compiled = remap(condition.compiled);
          if (typeof condition.source === "string") condition.source = condition.source.replace(/-?\d+/g, (n) => String(maps.skill_causalities.has(Number(n)) ? maps.skill_causalities.get(Number(n)) : n));
          row.causality_conditions = JSON.stringify(condition);
        } catch {}
      }
      if ("updated_at" in row) row.updated_at = stamp;
    }
    for (const ref of project.animationReferences || []) {
      const sourceRow = (project.tables[ref.table] || []).find((r) => r.id === ref.row);
      if (!sourceRow || Number(sourceRow.id) >= 0) continue;
      const row = (tables[ref.table] || [])[(project.tables[ref.table] || []).filter((r) => Number(r.id) < 0).indexOf(sourceRow)], value = maps[ref.targetTable] && maps[ref.targetTable].get(ref.targetId);
      if (!row || value === void 0) continue;
      if (ref.index === void 0) row[ref.field] = value;
      else { const values = JSON.parse(row[ref.field]); values[ref.index] = value; row[ref.field] = JSON.stringify(values); }
    }
    if (tables.optimal_awakening_growths) {
      const official = clone(project.tables.cards[0]);
      if (Number(official.id) !== cardId) throw new Error("This awakening project lost its card. Create the EZA again.");
      official.optimal_awakening_grow_type = targetId;
      if ("updated_at" in official) official.updated_at = stamp;
      tables.cards = [official];
      // EZA steps above level 150 need the extended experience table too.
      if (tables.optimal_awakening_growths.some((g) => Number(g.lv_max) > 150)) {
        const top = Math.max(...tables.optimal_awakening_growths.map((g) => Number(g.lv_max) || 0));
        extendLevels({ cards: [{ lv_max: top }] });   // checks the cap
        official.exp_type = EXTENDED_EXP_TYPE;
        tables.card_exps = extendLevels({ cards: [{ lv_max: top }] }).card_exps;
      }
    }
    return tables;
  }
  function materialize(project, options = {}) {
    if (project && project.awaken) return materializeAwaken(project);
    var _a, _b, _c;
    const bindingErrors = animationReferenceErrors(project);
    if (bindingErrors.length) throw new Error(bindingErrors.join("\n"));
    const tables = clone(project.tables), maps = {};
    tables.cards[0] = card(project);
    for (const [table, rows] of Object.entries(tables)) {
      if (rows.length >= 1e3) throw new Error(`Too many rows in ${table}; this unit's reserved ID block holds 999 rows.`);
      const setTable = SET_TABLES.has(table);
      if (setTable && rows.length >= 100) throw new Error(`Too many rows in ${table}; this unit's reserved skill-set block holds 99 rows.`);
      const base = setTable ? Math.floor(Number(project.targetId) / 10) : Number(project.targetId);
      maps[table] = new Map(rows.map((row, index) => [row.id, base + index]));
    }
    const sourceId = project.tables.cards[0].id;
    for (const [table, rows] of Object.entries(tables)) for (const row of rows) {
      const oldId = row.id;
      row.id = maps[table].get(oldId);
      for (const [field, value] of Object.entries(row)) {
        if (field === "id") continue;
        const target = foreign[field] || (field.endsWith("_id") ? field.slice(0, -3) + "s" : null);
        if (target && ((_a = maps[target]) == null ? void 0 : _a.has(value))) row[field] = maps[target].get(value);
        if (field === "optimal_awakening_grow_type" && value) row[field] = Number(project.targetId);
      }
      if (table === "transformation_descriptions") {
        const skillTable = SKILL_TYPES[row.skill_type];
        if (skillTable && maps[skillTable] && maps[skillTable].has(row.skill_id)) row.skill_id = maps[skillTable].get(row.skill_id);
      }
      if (row.causality_conditions && maps.skill_causalities) {
        try {
          const condition = JSON.parse(row.causality_conditions), remap = (n) => {
            var _a2;
            return typeof n === "number" ? (_a2 = maps.skill_causalities.get(n)) != null ? _a2 : n : Array.isArray(n) ? n.map(remap) : n;
          };
          condition.compiled = remap(condition.compiled);
          if (typeof condition.source === "string") condition.source = condition.source.replace(/-?\d+/g, (n) => {
            var _a2;
            return String((_a2 = maps.skill_causalities.get(Number(n))) != null ? _a2 : n);
          });
          row.causality_conditions = JSON.stringify(condition);
        } catch {
        }
      }
      if ("updated_at" in row) row.updated_at = (/* @__PURE__ */ new Date()).toISOString().slice(0, 19).replace("T", " ");
    }
    for (const ref of project.animationReferences || []) {
      const sourceIndex = (project.tables[ref.table] || []).findIndex((r) => r.id === ref.row), row = (_b = tables[ref.table]) == null ? void 0 : _b[sourceIndex], value = (_c = maps[ref.targetTable]) == null ? void 0 : _c.get(ref.targetId);
      if (!row || value === void 0) throw new Error("An assigned gameplay animation has a missing database reference.");
      if (ref.index === void 0) row[ref.field] = value;
      else {
        const values = JSON.parse(row[ref.field]);
        if (!Array.isArray(values)) throw new Error("A gameplay animation requires its original ability values.");
        values[ref.index] = value;
        row[ref.field] = JSON.stringify(values);
      }
    }
    ownTransformationParams(project, tables, options.cardMap);
    if (tables.cards[0].id !== Number(project.targetId)) throw new Error("Invalid source card mapping.");
    if (tables.cards.length !== 1 || sourceId === Number(project.targetId)) throw new Error("Choose a new custom card ID.");
    // Native Card::getRootCard() rounds an awakened card ID down to tens.
    // Card details/resource/awakening callers can dereference that lookup
    // without a null check. Keep one editable card, but export its root row
    // and card-scoped relations as well. Both share the authored final kit.
    const rootId = Math.floor(Number(project.targetId) / 10) * 10;
    if (rootId !== Number(project.targetId)) {
      tables.cards.push({ ...clone(tables.cards[0]), id: rootId });
      for (const table of direct) {
        const rows = tables[table] || [], copies = rows.filter(row => row.card_id === Number(project.targetId));
        if (rows.length + copies.length >= 1e3) throw new Error("Too many card settings in " + table + " to reserve both native card forms safely.");
        copies.forEach(row => rows.push({ ...clone(row), id: Number(project.targetId) + rows.length, card_id: rootId }));
      }
    }
    const growth = authoredStatGrowth(project);
    if (growth) {
      tables.card_growths = growth;
      for (const row of tables.cards) row.grow_type = Number(project.targetId);
    }
    return extendLevels(tables);
  }
  // Levels above 150. The game's experience tables stop at level 150, so a unit with a higher level
  // cap gets its own experience table (type 925): the game's LR curve for levels 1-150, continued
  // smoothly to 200 (each level needs 3.5% more than the one before). Every unit writes identical rows,
  // so several such units in Eclipse share one table.
  const EXTENDED_EXP_TYPE = 925, EXTENDED_EXP = [0,78,300,707,1335,2211,3364,4816,6591,8708,11188,14050,17310,20985,25093,29649,34669,40166,46155,52650,59664,67211,75303,83954,93175,102978,113375,124377,135997,148244,161130,174666,188862,203729,219277,235516,252455,270105,288476,307576,327416,348005,369351,391464,414353,438027,462494,487763,513843,540743,568469,597032,626440,656699,687819,719807,752672,786421,821062,856602,893050,930413,968699,1007914,1048067,1089165,1131215,1174224,1218199,1263148,1309078,1355996,1403908,1452822,1502744,1553682,1605641,1658630,1712654,1767721,1823836,1881007,1939240,1998541,2058918,2120375,2182921,2246560,2311300,2377146,2444106,2512184,2581388,2651723,2723195,2795811,2869577,2944498,3020581,3097831,3176255,3255858,3336646,3418625,3501801,3586179,3671766,3758566,3846587,3935832,4026309,4118022,4210977,4305181,4400637,4497352,4595331,4694580,4795104,4896909,5000000,5115248,5283687,5505319,5780141,6108156,6489361,6923758,7411347,7952127,8546099,9193262,9893617,10647163,11453900,12313829,13226950,14193262,15212765,16285460,17411347,18590425,19822695,21108156,22446808,23838652,25283687,26781914,28333333,30000000,31725000,33510375,35358238,37270776,39250253,41299012,43419478,45614160,47885656,50236654,52669937,55188385,57794979,60492804,63285053,66175031,69166158,72261974,75466144,78782460,82214847,85767368,89444227,93249776,97188519,101265118,105484398,109851353,114371151,119049142,123890863,128902044,134088616,139456718,145012704,150763150,156714862,162874884,169250507,175849277,182679004,189747771,197063945,204636185,212473453,220585025,228980502,237669821,246663266,255971482];
  function extendLevels(tables) {
    const high = (tables.cards || []).filter((row) => Number(row.lv_max) > 150);
    if (!high.length) return tables;
    if (high.some((row) => Number(row.lv_max) > EXTENDED_EXP.length)) throw new Error("The highest level cap is " + EXTENDED_EXP.length + ".");
    for (const row of high) row.exp_type = EXTENDED_EXP_TYPE;
    const stamp = (/* @__PURE__ */ new Date()).toISOString().slice(0, 19).replace("T", " ");
    tables.card_exps = EXTENDED_EXP.map((total, i) => ({ id: EXTENDED_EXP_TYPE * 1000 + i + 1, lv: i + 1, exp_type: EXTENDED_EXP_TYPE, exp_total: total, created_at: stamp, updated_at: stamp }));
    return tables;
  }
  // Transformation (103) and giant-form (79) skills point at a shared battle_params group whose
  // values include the card the unit returns to after the form ends. Shared groups name the
  // original game card, so a custom unit would turn back into (or transform into) the official
  // card. Export a private copy of each inherited group with every bundle source card replaced
  // by the matching custom card, and retarget transformations that point at a bundle member.
  function ownTransformationParams(project, tables, cardMap) {
    cardMap = cardMap instanceof Map ? cardMap : new Map([[Number(project.source.cardId), Number(project.targetId)]]);
    const remap = (value) => cardMap.has(Number(value)) ? cardMap.get(Number(value)) : value;
    let params = tables.battle_params;
    for (const table of Object.values(SKILL_TYPES)) {
      const originals = project.tables[table] || [], rows = tables[table] || [];
      originals.forEach((original, index) => {
        const effect = Number(original.efficacy_type), row = rows[index];
        if (![79, 103].includes(effect) || !row) return;
        const prefix = table === "passive_skills" ? "eff_value" : "eff_val";
        let values = null;
        try { const parsed = JSON.parse(row.efficacy_values || "{}"); if (Array.isArray(parsed)) values = parsed; } catch {}
        const get = (i) => values ? values[i] : row[prefix + (i + 1)];
        const set = (i, v) => { if (values) { values[i] = v; row.efficacy_values = JSON.stringify(values); } else row[prefix + (i + 1)] = v; };
        if (effect === 103 && cardMap.has(Number(get(0)))) set(0, cardMap.get(Number(get(0))));
        const key = table + ":" + original.id, source = project.abilityAnimationSources && project.abilityAnimationSources[key];
        if (project.abilityAnimationOverrides && project.abilityAnimationOverrides[key]) return;
        if (!source || !Array.isArray(source.params) || !source.params.length || !Array.isArray(source.values) || Number(get(2)) !== Number(source.values[2])) return;
        if (!params) params = tables.battle_params = [];
        if (params.length + source.params.length >= 1e3) throw new Error("Too many transformation settings to reserve private battle parameters.");
        const group = Number(project.targetId) + params.length, stamp = (/* @__PURE__ */ new Date()).toISOString().slice(0, 19).replace("T", " ");
        [...source.params].sort((a, b) => Number(a.idx) - Number(b.idx)).forEach((param, k) => {
          const copy = { ...clone(param), id: group + k, param_no: group, value: remap(param.value) };
          if ("updated_at" in copy) copy.updated_at = stamp;
          params.push(copy);
        });
        set(2, group);
      });
    }
    for (const param of params || []) param.value = remap(param.value);
  }
  function counterScriptErrors(project) {
    const errors = [];
    const counterScriptIds = /* @__PURE__ */ new Set();
    for (const [key, assignment] of Object.entries(project.animationAssignments || {})) {
      if (!key.startsWith("counter:")) continue;
      const row = (project.tables.passive_skills || []).find((r) => "counter:" + r.id === key), number = assignment.scriptNumber, expected = "lua/ab_script/attack_counter/c" + String(number).padStart(4, "0") + ".lua", file = (project.generatedFiles || []).find((f) => f.owner === key);
      let values;
      try {
        values = JSON.parse((row == null ? void 0 : row.efficacy_values) || "{}");
      } catch {
      }
      const actual = Array.isArray(values) ? values[2] : row == null ? void 0 : row.eff_value3;
      if (!row || ![120, 128].includes(Number(row.efficacy_type)) || !Number.isInteger(number) || number < 1 || number > 16777215 || Math.fround(number) !== number || actual !== number || assignment.file !== expected || (file == null ? void 0 : file.path) !== expected || counterScriptIds.has(number)) errors.push("This custom counter uses an unsafe or mismatched animation number. Open the animation editor and apply its sequence again to reserve a precise, unique counter script.");
      counterScriptIds.add(number);
    }
    return [...new Set(errors)];
  }
  function validateSingle(project) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, _t, _u, _v;
    const errors = [], warnings = [];
    if (!project || project.format !== "dokkan-unit-forge" || project.version !== 1 || !((_b = (_a = project.tables) == null ? void 0 : _a.cards) == null ? void 0 : _b[0])) return { errors: ["This is not a supported Dokkan Unit Creator project."], warnings };
    errors.push(...animationReferenceErrors(project));
    warnings.push(...counterScriptErrors(project));
    if (project.movieBindings !== void 0) {
      const bindings = project.movieBindings, slots = /* @__PURE__ */ new Set(), keys = /* @__PURE__ */ new Set(), rows = /* @__PURE__ */ new Set();
      if (!Array.isArray(bindings) || bindings.length > 48) errors.push("This project has an invalid authored-movie list.");
      else for (const binding of bindings) {
        const row = (project.tables.effect_packs || []).find((r) => r.id === (binding == null ? void 0 : binding.rowId)), name = "forge_movie_" + project.targetId + "_" + (binding == null ? void 0 : binding.slot) + "_" + (binding == null ? void 0 : binding.storageTag), path = "movie/ingame/battle/sp_effect/" + name + ".usm", asset = (project.assets || []).find((a) => a.path === path && a.owner === "forge-authored-movie" && a.movieKey === (binding == null ? void 0 : binding.key)), meta = binding == null ? void 0 : binding.metadata, fps = ((_c = meta == null ? void 0 : meta.rate) == null ? void 0 : _c.n) / ((_d = meta == null ? void 0 : meta.rate) == null ? void 0 : _d.d), frames60 = Math.round((meta == null ? void 0 : meta.frames) * 60 / fps);
        if (!binding || typeof binding.key !== "string" || !/^movie-[a-z0-9]+$/.test(binding.key) || !/^[0-9a-f]{32}$/.test(binding.storageTag || "") || keys.has(binding.key) || rows.has(binding.rowId) || !Number.isInteger(binding.slot) || binding.slot < 0 || binding.slot >= 48 || slots.has(binding.slot) || binding.privateUnitId !== project.targetId || binding.path !== path || !row || row.category !== 5 || row.pack_name !== name || !asset || !safePath(asset.key) || !Number.isSafeInteger(binding.size) || binding.size <= 1e3 || binding.size > 96 * 1024 * 1024 || !Number.isSafeInteger(meta == null ? void 0 : meta.width) || !Number.isSafeInteger(meta == null ? void 0 : meta.height) || meta.width < 2 || meta.height < 2 || meta.width > 4096 || meta.height > 4096 || meta.width * meta.height > 16 * 1024 * 1024 || !Number.isSafeInteger(meta == null ? void 0 : meta.frames) || meta.frames < 1 || meta.frames > 1e4 || !Number.isSafeInteger((_e = meta == null ? void 0 : meta.rate) == null ? void 0 : _e.n) || !Number.isSafeInteger((_f = meta == null ? void 0 : meta.rate) == null ? void 0 : _f.d) || meta.rate.n < 1 || meta.rate.d < 1 || fps < 1 || fps > 120 || frames60 < 1 || frames60 > 10800) errors.push("An authored movie has missing or changed private resources. Reattach it or reserve a new unit slot before exporting.");
        keys.add(binding == null ? void 0 : binding.key);
        rows.add(binding == null ? void 0 : binding.rowId);
        slots.add(binding == null ? void 0 : binding.slot);
      }
      for (const assignment of [...Object.values(project.animationAssignments || {}), ...((_g = project.actionHooks) == null ? void 0 : _g.dodge) ? [project.actionHooks.dodge] : []]) for (const clip of assignment.clips || []) {
        const source = clip.source;
        if (!(source == null ? void 0 : source.movieBindingKey)) continue;
        const binding = Array.isArray(bindings) && bindings.find((b) => b.key === source.movieBindingKey), index = (project.tables.effect_packs || []).findIndex((r) => r.id === (binding == null ? void 0 : binding.rowId)), id2 = Number(project.targetId) + index;
        if (!binding || index < 0 || source.movieEffectPackId !== id2 || source.movieFrames60 !== Math.round(((_h = binding == null ? void 0 : binding.metadata) == null ? void 0 : _h.frames) * 60 * ((_j = (_i = binding == null ? void 0 : binding.metadata) == null ? void 0 : _i.rate) == null ? void 0 : _j.d) / ((_l = (_k = binding == null ? void 0 : binding.metadata) == null ? void 0 : _k.rate) == null ? void 0 : _l.n))) errors.push("An assigned movie changed its game reference or duration. Apply its sequence again before exporting.");
      }
    }
    const c = card(project), id = Number(project.targetId);
    if (!project.awaken && (Number(c.lv_max) > 150 || project.statPolicy === STAT_POLICY)) {
      try { authoredStatGrowth(project); } catch (error) { errors.push(error.message); }
    }
    if (project.awaken) {
      const steps = (project.tables.optimal_awakening_growths || []).map((r) => Number(r.step)).sort((a, b) => a - b);
      if (!steps.length) errors.push("Add at least one Extreme Z-Awakening step.");
      if (steps.some((step, i) => step !== i + 1)) errors.push("Extreme Z-Awakening steps must run 1, 2, 3… without gaps.");
      for (const row of project.tables.optimal_awakening_growths || []) {
        if (!row.passive_skill_set_id || !row.leader_skill_set_id) errors.push("Every EZA step needs a leader skill and a passive skill.");
        if (!(Number(row.lv_max) >= 1 && Number(row.skill_lv_max) >= 1)) errors.push("Every EZA step needs a level cap and a Super Attack level cap.");
      }
      const routes = new Set((project.tables.card_awakening_routes || []).filter((r) => r.type === "CardAwakeningRoute::Optimal" && Number(r.card_id) === Number(project.awaken.cardId)).map((r) => Number(r.optimal_awakening_step)));
      for (const step of steps) if (!routes.has(step)) errors.push("EZA step " + step + " has no awakening route (medals). Choose the awakening medals again.");
      if (!Number.isInteger(id) || id < Forge_SLOT_FLOOR || id > Forge_SLOT_CEILING) errors.push("This EZA needs a private ID block. Create it again.");
      try { materializeAwaken(project); } catch (error) { errors.push(error.message); }
    }
    if (project.tables.cards.length !== 1 || project.tables.cards[0].id !== Number(project.source.cardId) || "id" in project.cardOverrides) errors.push("Keep exactly one card row with the original source ID; set Custom card ID separately.");
    if (!Number.isInteger(id) || id < 1e6 || id > 2e9 - 1e3) errors.push("Custom card ID must be a whole number between 1,000,000 and 1,999,999,000.");
    if (id === Number(project.source.cardId)) errors.push("Custom card ID must differ from the source card.");
    if (!String(c.name || "").trim()) errors.push("Give your unit a name.");
    for (const stat of ["hp", "atk", "def"]) {
      if (!Number.isInteger(Number(c[stat + "_max"])) || c[stat + "_max"] < 1) errors.push(stat.toUpperCase() + " maximum must be a positive whole number.");
      if (c[stat + "_init"] < 0 || Number(c[stat + "_init"]) > Number(c[stat + "_max"])) errors.push(stat.toUpperCase() + " initial value must be between zero and its maximum.");
    }
    if (!elements[c.element]) errors.push("Select a valid class and type.");
    if (!Number.isInteger(Number(c.rarity)) || c.rarity < 0 || c.rarity > 5) errors.push("Select a valid rarity.");
    if (c.lv_max < 1 || c.skill_lv_max < 1) errors.push("Level and Super Attack level must be positive.");
    const links = Array.from({ length: 7 }, (_, i) => c["link_skill" + (i + 1) + "_id"]).filter(Boolean);
    if (new Set(links).size !== links.length) errors.push("A Link Skill can only be selected once.");
    for (const [table, rows] of Object.entries(project.tables)) {
      if (!/^[a-z][a-z0-9_]*$/.test(table) || !Array.isArray(rows) || !project.schema[table]) {
        errors.push("Unknown or invalid table: " + table);
        continue;
      }
      const columns = new Set(project.schema[table].map((x) => x.name)), ids = /* @__PURE__ */ new Set();
      for (const row of table === "cards" ? [c] : rows) {
        if (!row || typeof row !== "object" || Array.isArray(row)) {
          errors.push("Invalid row in " + table);
          continue;
        }
        if (!Number.isSafeInteger(row.id) || ids.has(row.id)) errors.push("Missing or duplicate row ID in " + table);
        ids.add(row.id);
        for (const column of project.schema[table]) if (column.notnull && row[column.name] == null) errors.push(`Required field ${table}.${column.name} is empty.`);
        for (const [field, value] of Object.entries(row)) {
          if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(field)) errors.push("Invalid database column name.");
          if (!columns.has(field)) errors.push(`Unknown column ${table}.${field}`);
          if (value !== null && !["string", "number", "boolean"].includes(typeof value)) errors.push(`${table}.${field} must be a scalar; encode JSON fields as JSON strings.`);
          if (typeof value === "number" && !Number.isFinite(value)) errors.push("Non-finite number in " + table);
          if ((field === "causality_conditions" || field === "efficacy_values" || field === "target_type_values") && value) {
            try {
              JSON.parse(value);
            } catch {
              errors.push(`Invalid JSON in ${table}.${field}`);
            }
          }
        }
      }
    }
    for (const row of project.tables.passive_skills || []) if (row.probability < 0 || row.probability > 100) errors.push("Passive probabilities must be between 0 and 100.");
    const pathIdentity = (value) => typeof value === "string" ? value.normalize("NFC").toLowerCase() : value;
    const assetPaths = /* @__PURE__ */ new Set([pathIdentity(filename(project) + ".sql")]);
    for (const asset of project.assets || []) {
      if (!safePath(asset.path)) errors.push("An asset has an unsafe or empty destination path.");
      if (assetPaths.has(pathIdentity(asset.path))) errors.push("Two patch files use the same destination path: " + asset.path);
      assetPaths.add(pathIdentity(asset.path));
    }
    for (const file of project.generatedFiles || []) {
      if (!safePath(file.path) || !/^lua\/ab_script\/[a-z0-9_/-]+\.lua$/i.test(file.path) || typeof file.text !== "string" || file.text.length > 2 * 1024 ** 2) errors.push("An animation file is invalid or too large.");
      if (assetPaths.has(pathIdentity(file.path))) errors.push("Two patch files use the same destination path: " + file.path);
      assetPaths.add(pathIdentity(file.path));
    }
    if (project.packedAssets !== void 0 && !Array.isArray(project.packedAssets)) errors.push("Packed resources must be a list of CPK archives.");
    else if ((project.packedAssets || []).length > 100) errors.push("A project can contain at most 100 packed resource archives.");
    else {
      const sources = new Map((project.assets || []).map((a) => [a.path, a]));
      let totalPacked = 0;
      for (const pack of project.packedAssets || []) {
        if (!pack || typeof pack !== "object" || !safePath(pack.path) || !pack.path.endsWith(".cpk")) {
          errors.push("A packed resource needs a safe .cpk destination path.");
          continue;
        }
        if (assetPaths.has(pathIdentity(pack.path))) errors.push("Two patch files use the same destination path: " + pack.path);
        assetPaths.add(pathIdentity(pack.path));
        if (!Array.isArray(pack.entries) || pack.entries.length < 1 || pack.entries.length > 5e3) {
          errors.push("A packed resource must contain between 1 and 5000 files.");
          continue;
        }
        totalPacked += pack.entries.length;
        const seen = /* @__PURE__ */ new Set();
        for (const entry of pack.entries) {
          if (!entry || !safePath(entry.path) || /[\x7f%]/.test(entry.path) || entry.path.split("/").some((p) => p.startsWith(".")) || /\.(?:db|sqlite|sqlite3)(?:[-.].*)?$/i.test(entry.path)) {
            errors.push("A packed resource contains an unsafe internal filename.");
            continue;
          }
          const key = pathIdentity(entry.path);
          if (seen.has(key)) errors.push("A packed resource contains conflicting internal filenames.");
          seen.add(key);
          const asset = sources.get(entry.assetPath);
          if (!safePath(entry.assetPath) || !asset || !safePath(asset.key)) errors.push("A packed resource references a missing or invalid attached asset.");
        }
      }
      if (totalPacked > 2e4) errors.push("Packed resources exceed the 20,000-file project limit.");
    }
    for (const owned of Object.values(project.abilityAnimationOverrides || {})) if (owned == null ? void 0 : owned.requiredPhases) {
      const view = (project.tables[owned.table] || []).find((r) => r.id === owned.viewId), labels = { begin: "enter the form", continue: "stay in giant form", end: "leave the form" };
      if (!Array.isArray(owned.requiredPhases)) {
        errors.push("A form animation has invalid completion requirements.");
        continue;
      }
      const missing = owned.requiredPhases.filter((phase) => !(view == null ? void 0 : view[phase + "_script_name"]) || view[phase + "_script_name"] === "0");
      if (missing.length) errors.push("Finish all required form animations before exporting: " + missing.map((phase) => labels[phase] || "unknown section").join(", ") + ". Apply those sections in the animation editor, or restore the inherited animations.");
    }
    if (!project.awaken) for (const issue of playerRosterEligibility(project).issues) warnings.push("Player roster: " + issue);
    if ((_m = project.animationStudio) == null ? void 0 : _m.dirty) warnings.push("The animation editor has changes that have not been applied to a move. Apply them to include those changes in the game patch.");
    if (!((_o = (_n = project.patch) == null ? void 0 : _n.name) == null ? void 0 : _o.trim())) errors.push("Give the patch a name.");
    if (!((_q = (_p = project.patch) == null ? void 0 : _p.version) == null ? void 0 : _q.trim())) errors.push("Give the patch a version.");
    if (project.battlePoseBinding) {
      const binding = project.battlePoseBinding, expected = "ingame/battle/character/" + String(id).padStart(5, "0") + ".cpk";
      if (((_r = binding.identityAudit) == null ? void 0 : _r.checked) !== true || ((_s = binding.identityAudit) == null ? void 0 : _s.legacyRawCharacterConditions) !== 0 || (Array.isArray(project.tables.skill_causalities) ? project.tables.skill_causalities : []).some((row) => [22, 29].includes(Number(row.causality_type)))) errors.push("Older named-character conditions cannot be combined with a private fighter until their identity behavior is verified. Restore inherited fighter poses or choose a supported character-identity condition.");
      if (binding.privateCharacterId !== id) errors.push("The custom unit ID changed after its fighter poses were prepared. Open Customize battle poses and apply them again, or restore the inherited poses.");
      if (c.character_id !== binding.localCharacterId || !(Array.isArray(project.tables.characters) ? project.tables.characters : []).some((row) => row.id === binding.localCharacterId)) errors.push("The private fighter record is missing or changed. Apply its poses again or restore the inherited poses.");
      if (binding.archivePath !== expected || !(Array.isArray(project.packedAssets) ? project.packedAssets : []).some((pack) => pack.path === expected && pack.owner === "forge-battle-poses")) errors.push("The private fighter resource container is missing. Apply its poses again or restore the inherited poses.");
    }
    if (c.rarity === 5 && !(project.tables.card_specials || []).some((r) => r.style === "Hyper")) warnings.push("This LR has no inherited Ultra Super Attack. Add one in the advanced table editor if intended.");
    if (((_t = project.tables.standby_skills) == null ? void 0 : _t.length) || ((_u = project.tables.active_skills) == null ? void 0 : _u.length) || ((_v = project.tables.passive_skills) == null ? void 0 : _v.some((r) => [79, 110, 115].includes(r.efficacy_type)))) warnings.push("Inherited transformations, standby forms, and domains may reference original game units or shared assets. Review these in Advanced and test in Eclipse.");
    warnings.push("SQL is checked against your selected database. Actual gameplay and ECLP installation still need an Eclipse test.");
    if (project.sourceDependencies) {
      try {
        if (!SparkingDependencies || typeof project.sourceDependencies !== "object" || Array.isArray(project.sourceDependencies)) throw Error("This Sparking project's shared dependencies need to be prepared again.");
        const issues = [...(project.sourceDependencies.issues || []), ...SparkingDependencies.validate(project.sourceDependencies)];
        const owned=materialize(project);
        for(const [table,rows] of Object.entries(project.sourceDependencies.tables||{})) {
          const ownIds=new Set((owned[table]||[]).map(row=>row.id));
          if(rows.some(row=>ownIds.has(row.id)))errors.push("Your unit's private records overlap shared animation data. Choose a different custom unit slot before exporting.");
        }
        for (const issue of issues) (issue.severity === "error" ? errors : warnings).push(String(issue.message));
      } catch (error) { errors.push(error.message); }
    }
    return { errors: [...new Set(errors)], warnings: [...new Set(warnings)] };
  }
  const formTables = new Set(["passive_skills", "active_skills", "standby_skills", "finish_skills"]);
  function transformationTarget(row, table) {
    const field = table === "passive_skills" ? "eff_value1" : "eff_val1";
    let values = null;
    try { const parsed = JSON.parse(row.efficacy_values || "{}"); if (Array.isArray(parsed)) values = parsed; } catch {}
    return { field, values, targetId: values ? Number(values[0]) : Number(row[field]) };
  }
  function formStructureErrors(project) {
    const errors = [], forms = project && project.formProjects, links = project && project.transformLinks;
    if (!project || forms === undefined && links === undefined) return errors;
    if (forms !== undefined && (!Array.isArray(forms) || forms.length > 4)) return ["A unit can contain at most four additional transformation forms."];
    if (links !== undefined && (!Array.isArray(links) || links.length > 64)) return ["Transformation links must be a list of at most 64 existing transformation abilities."];
    if (!project.tables || !project.tables.cards || !project.tables.cards[0] || !project.source || !project.cardOverrides) return ["This is not a supported Dokkan Unit Creator project."];
    const members = [project, ...(forms || [])], keys = new Set(), ranges = [], paths = new Set([filename(project).normalize("NFC").toLowerCase() + ".sql"]);
    for (const member of members) {
      if (!member || member.format !== "dokkan-unit-forge" || member.version !== 1 || !member.tables || !member.source || !member.cardOverrides) { errors.push("A transformation form is not a supported standalone unit."); continue; }
      if (member !== project && (member.formProjects !== undefined || member.transformLinks !== undefined)) errors.push("Keep forms directly inside the starting unit; nested forms and form cycles are not supported.");
      if (typeof member.key !== "string" || !member.key || member.key.length > 200 || keys.has(member.key)) errors.push("Every transformation form needs a different saved unit key.");
      keys.add(member.key);
      const id = Number(member.targetId);
      if (!Number.isSafeInteger(id) || ranges.some(([a,b]) => id <= b && id + 999 >= a)) errors.push("Transformation forms must reserve different, non-overlapping unit slots.");
      ranges.push([id,id + 999]);
      if ((member.source.database || "eclipse") !== (project.source.database || "eclipse")) errors.push("All forms must use the same source game database.");
      if (members.length > 1 && (member.sourceDependencies || member.actionHooks && member.actionHooks.dodge)) errors.push("Multi-form patches cannot yet include shared Sparking animation dependencies or a custom shared Dodge hook. Restore those shared changes before linking forms.");
      if (members.length > 1) for (const file of [...member.assets || [], ...member.generatedFiles || [], ...member.packedAssets || []]) {
        const path = typeof file.path === "string" ? file.path.normalize("NFC").toLowerCase() : "";
        if (paths.has(path)) errors.push("Transformation forms contain conflicting resource destinations: " + file.path);
        paths.add(path);
      }
    }
    if (members.length > 1) for (const [a,b] of ranges) for (const member of members) if (member && member.source && Number(member.source.cardId) >= a && Number(member.source.cardId) <= b) errors.push("A transformation unit slot overlaps an original source card. Choose automatic private slots.");
    const used = new Set(), rows = new Set();
    for (const link of links || []) {
      if (!link || !formTables.has(link.table) || !Number.isSafeInteger(link.row) || typeof link.targetKey !== "string" || !Number.isSafeInteger(link.targetId)) { errors.push("A transformation link is invalid. Choose its form again."); continue; }
      const child = (forms || []).find((f) => f && f.key === link.targetKey && f.targetId === link.targetId), row = (project.tables[link.table] || []).find((r) => r.id === link.row);
      if (!child || !row || Number(row.efficacy_type) !== 103 || rows.has(link.table + ":" + link.row)) { errors.push("A transformation link has a missing form or changed transformation ability."); continue; }
      rows.add(link.table + ":" + link.row); used.add(child.key);
      const target = transformationTarget(row, link.table);
      if (Number(row[target.field]) !== link.targetId || target.targetId !== link.targetId) errors.push("A transformation's saved target changed. Choose its form again before exporting.");
    }
    // Forms can also be reached through another form (base → form 2 → form 3, or turning back):
    // those transformations keep the original card ID and are remapped to the form at export.
    const bySource = new Map((forms || []).filter(Boolean).map((f) => [Number(f.source && f.source.cardId), f]));
    for (let changed = true; changed;) {
      changed = false;
      for (const member of members) {
        if (!member || !member.tables || member !== project && !used.has(member.key)) continue;
        for (const table of formTables) for (const row of member.tables[table] || []) {
          if (Number(row.efficacy_type) !== 103) continue;
          const form = bySource.get(transformationTarget(row, table).targetId);
          if (form && form.key !== member.key && !used.has(form.key)) { used.add(form.key); changed = true; }
        }
      }
    }
    for (const member of forms || []) if (member && !used.has(member.key)) errors.push("Every attached form must be selected by an existing transformation ability.");
    if (members.length > 1) for (const member of members) if (member && member.tables) for (const table of formTables) for (const row of member.tables[table] || []) {
      if (Number(row.efficacy_type) !== 103) continue;
      const id = transformationTarget(row, table).targetId;
      // The starting form may have several copies of one transformation (for example one per EZA
      // stage); any of them may point at an attached form.
      if (members.some(m => m && Number(m.targetId) === id) && !(member === project && ((links || []).some(link => link && link.table === table && link.row === row.id && link.targetId === id) || (forms || []).some(f => f && Number(f.targetId) === id && (links || []).some(link => link && link.targetKey === f.key))))) errors.push("A form points to another custom form without a supported transformation link. Form cycles are not supported.");
    }
    return [...new Set(errors)];
  }
  function validate(project) {
    const structure = formStructureErrors(project);
    if (structure.length) return { errors: structure, warnings: [] };
    const result = validateSingle(project);
    for (const form of project && project.formProjects || []) {
      const check = validateSingle(form), label = String(form.cardOverrides.name || form.source.name || "Transformation form");
      result.errors.push(...check.errors.map((x) => label + ": " + x));
      result.warnings.push(...check.warnings.map((x) => label + ": " + x));
    }
    return { errors: [...new Set(result.errors)], warnings: [...new Set(result.warnings)] };
  }
  function materializeAll(project) {
    const errors = formStructureErrors(project);
    if (errors.length) throw new Error(errors.join("\n"));
    const tables = {}, members = [project, ...project.formProjects || []], cardMap = new Map();
    for (const member of members) if (!cardMap.has(Number(member.source.cardId))) cardMap.set(Number(member.source.cardId), Number(member.targetId));
    for (const member of members) for (const [table, rows] of Object.entries(materialize(member, { cardMap }))) {
      tables[table] = tables[table] || [];
      const ids = new Set(tables[table].map((r) => r.id));
      for (const row of rows) {
        if (!ids.has(row.id)) { tables[table].push(row); ids.add(row.id); continue; }
        const old = tables[table].find(existing => existing.id === row.id);
        if (table !== "card_exps" || !["id", "lv", "exp_type", "exp_total"].every(field => old[field] === row[field])) throw new Error("Transformation forms overlap private database records in " + table + ".");
      }
    }
    return tables;
  }
  function quote(value) {
    if (value == null) return "NULL";
    if (typeof value === "boolean") return value ? "1" : "0";
    if (typeof value === "number") {
      if (!Number.isFinite(value)) throw new Error("Invalid SQL number");
      return String(value);
    }
    return "'" + String(value).replace(/'/g, "''").replace(/\u0000/g, "") + "'";
  }
  function sql(project, { transaction = true } = {}) {
    if (typeof transaction !== "boolean") throw new Error("Choose whether this SQL owns its transaction.");
    const result = validate(project), counterErrors = [project, ...project.formProjects || []].flatMap(counterScriptErrors);
    if (result.errors.length || counterErrors.length) throw new Error([...result.errors, ...counterErrors].join("\n"));
    if ([project, ...project.formProjects || []].some((member) => legacySlot(member.targetId))) throw new Error("This unit still uses an old 10-digit unit slot that Eclipse cannot load. Export it from the unit editor so it moves to a new slot automatically.");
    const tables = materializeAll(project);
    const header = (project.awaken ? `-- Dokkan Unit Creator
-- ${project.awaken.kind === "seza" ? "Super Extreme Z-Awakening" : "Extreme Z-Awakening"} for game card ${project.awaken.cardId}; new records use the private block ${project.targetId}.
-- Only that card's row is updated (its EZA growth type); every other row is new.
` : `-- Dokkan Unit Creator
-- Custom card ${project.targetId}; source card ${project.source.cardId}
`) + `-- Import into Eclipse's game database/patch pipeline. Rows use INSERT OR REPLACE so re-importing an updated version of this unit is safe.
` + (transaction ? "BEGIN TRANSACTION;\n" : "-- The Eclipse patch installer owns this transaction.\n");
    const order = ["passive_skill_sets", "leader_skill_sets", "special_sets", "active_skill_sets", "standby_skill_sets", "finish_specials", "finish_skill_sets", "dokkan_field_efficacy_sets", "dokkan_fields", "dokkan_field_efficacies", "cards"];
    const names = Object.keys(tables).sort((a, b) => (order.indexOf(a) < 0 ? 100 : order.indexOf(a)) - (order.indexOf(b) < 0 ? 100 : order.indexOf(b)));
    let output = header;
    // Only our own reserved growth rows are replaced. Clear a prior longer cap as well,
    // so updating200→180 or returning to a source-supported cap leaves no stale curve.
    for (const member of [project, ...project.formProjects || []]) {
      const id = Number(member.targetId);
      if (!member.awaken && Array.isArray(member.schema.card_growths) && id >= SLOT_FLOOR && id <= SLOT_CEILING && id % 1000 === 1) output += `DELETE FROM "card_growths" WHERE "grow_type"=${id} AND "id" BETWEEN ${id} AND ${id + 999};\n`;
      if (!member.awaken && member.statPolicy === STAT_POLICY) output += `-- Our authored ${STAT_POLICY} curve; source grow_type ${member.sourceStatGrowth.sourceGrowType}, configured cap ${card(member).lv_max}.\n`;
    }
    if (project.sourceDependencies) {
      if (!SparkingDependencies) throw new Error("The Sparking dependency exporter is unavailable. Reopen the app.");
      output += SparkingDependencies.sql(project.sourceDependencies);
    }
    for (const name of names) for (const row of tables[name]) {
      const cols = Object.keys(row);
      output += `INSERT OR REPLACE INTO "${name}" (${cols.map((x) => '"' + x + '"').join(",")}) VALUES (${cols.map((x) => quote(row[x])).join(",")});
`;
    }
    return output + (transaction ? "COMMIT;\n" : "");
  }
  function safePath(path) {
    return typeof path === "string" && path.length > 0 && path.length <= 500 && !path.includes("\\") && !path.startsWith("/") && !path.split("/").some((x) => !x || x === "." || x === "..") && !/[:\x00-\x1f]/.test(path);
  }
  function metadata(project) {
    return {
      ...(project.source?.database === "sparking" ? {sourceFormat:"sparking-database",compatibility:"Sparking source; matching assets and Eclipse gameplay need validation."} : project.sourceDependencies?.animations?.length ? {sourceFormat:"sparking-animation-mix",compatibility:"Original Sparking animation effects with a separate source character; Eclipse gameplay needs validation."} : {}),
      uuid: project.patch.uuid,
      author: project.patch.author || "",
      name: project.patch.name,
      version: project.patch.version,
      dependencies: [],
      game_version: "",
      description: project.patch.description || "",
      unity: false,
      created: Math.floor(Date.now() / 1e3)
    };
  }
  function exportEntries(project) {
    var _a, _b;
    const script = sql(project, { transaction: false }), slug = filename(project);
    const entries = [
      { path: "metadata.json", text: JSON.stringify(metadata(project), null, 2) },
      { path: "files/" + slug + ".sql", text: script },
      { path: "forge-project.json", text: JSON.stringify(project, null, 2) }
    ];
    for (const member of [project, ...project.formProjects || []]) for (const asset of member.assets || []) {
      if (!safePath(asset.path)) throw new Error("Invalid asset destination path");
      entries.push({ path: "files/" + asset.path, assetKey: asset.key });
    }
    for (const member of [project, ...project.formProjects || []]) {
      const attached = new Map((member.assets || []).map((a) => [a.path, a]));
      for (const pack of member.packedAssets || []) entries.push({ path: "files/" + pack.path, cpk: pack.entries.map((entry) => ({ path: entry.path, assetKey: attached.get(entry.assetPath).key })) });
    }
    const dodgePath = "lua/ab_script/ab_sys/dg0001.lua";
    if (((_a = project.actionHooks) == null ? void 0 : _a.dodge) && ((project.assets || []).some((a) => a.path === dodgePath) || (project.generatedFiles || []).some((f) => f.path === dodgePath && f.owner !== "dodge:unit"))) throw new Error("This custom-dodge unit also contains another owner of the shared dodge file. Remove that conflicting attachment before exporting its unit and Shared Actions patches.");
    for (const member of [project, ...project.formProjects || []]) for (const file of member.generatedFiles || []) {
      if (file.owner === "dodge:unit" && file.path === dodgePath) {
        if (!((_b = project.actionHooks) == null ? void 0 : _b.dodge)) throw new Error("This saved dodge dispatcher is missing its editable dodge settings. Reapply or remove the custom dodge before exporting.");
        continue;
      }
      entries.push({ path: "files/" + file.path, text: file.text });
    }
    const paths = entries.map((x) => x.path.normalize("NFC").toLowerCase());
    if (new Set(paths).size !== paths.length) throw new Error("Two exported assets use the same destination path.");
    return entries;
  }
  function filename(project) {
    return String(card(project).name || "custom-unit").replace(/[^a-zA-Z0-9_-]+/g, "-").replace(/^-|-$/g, "").slice(0, 60) + "-" + project.targetId;
  }
  function prompt(project) {
    const c = card(project), p = primaryPassive(project);
    const linked = new Set((project.tables.passive_skill_set_relations || []).filter((r) => r.passive_skill_set_id === (p == null ? void 0 : p.id)).map((r) => r.passive_skill_id));
    const records = (project.tables.passive_skills || []).filter((r) => linked.has(r.id));
    return `Help me design and review a custom Dokkan Battle unit for Eclipse.
Name: ${c.name}
Rarity: ${rarities[c.rarity]}; type: ${elements[c.element]}
HP ${c.hp_max}, ATK ${c.atk_max}, DEF ${c.def_max}
Passive: ${(p == null ? void 0 : p.name) || ""}
${(p == null ? void 0 : p.itemized_description) || ""}

Actual base passive effect records (the description may need updating):
${JSON.stringify(records, null, 2)}

My design notes:
${project.notes || ""}

Suggest a clear, balanced kit. Separate flavor text from gameplay implementation. Explain the relevant Eclipse efficacy types and conditions; do not invent undocumented IDs. I will manually apply and test changes in my creator.

Reference: https://dokkan-eclipse.com/wiki/documentation`;
  }
  return { SLOT_FLOOR, SLOT_CEILING, legacySlot, hydrateStatGrowth, authoredStatGrowth, STAT_POLICY, hydrateNativeRecords, nextUnitId, playerRosterEligibility, clone, foreign, direct, elements, rarities, loadTemplate, hydrateAbilityAnimations, card, rowDefault, localId, primaryPassive, addPassive, removePassive, allTypesLeader, compileCondition, materialize, materializeAll, formStructureErrors, validate, sql, quote, safePath, metadata, exportEntries, filename, prompt };
});
