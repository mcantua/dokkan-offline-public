/* Settings-only projection of the real Unit Creator project into the persisted offline core.
 * Native host pins content/source identity and definition revision; the core validates master
 * columns, values, references and fully-awakened eligibility again before saving. */
(function (root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.OfflineDokkanCreator = factory();
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";
  const TABLES = new Set([
    "leader_skill_sets", "leader_skills", "passive_skill_sets", "passive_skill_set_relations", "passive_skills",
    "card_specials", "special_sets", "specials", "extra_special_options", "card_active_skills", "active_skill_sets",
    "active_skills", "card_standby_skill_set_relations", "standby_skill_sets", "standby_skills",
    "standby_skill_set_finish_skill_set_relations", "card_finish_skill_set_relations", "finish_skill_sets",
    "finish_skills", "finish_specials", "card_card_categories", "card_categories", "dokkan_fields",
    "dokkan_field_active_skill_set_relations", "dokkan_field_passive_skill_relations", "link_skills",
    "skill_causalities", "sub_target_types", "transformation_descriptions"
  ]);
  const fail = (code) => { const e = new Error(code); e.code = code; throw e; };
  const record = (x) => x && typeof x === "object" && !Array.isArray(x);
  const scalar = (x) => x === null || typeof x === "string" || Number.isFinite(x) && typeof x === "number";
  function rowCopy(row) {
    if (!record(row)) fail("INVALID_SETTINGS_ROW");
    const out = Object.create(null);
    for (const key of Object.keys(row)) {
      if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(key) || key === "__proto__" || key === "constructor" || key === "prototype" || !scalar(row[key])) fail("INVALID_SETTINGS_ROW");
      if (typeof row[key] === "number" && Number.isInteger(row[key]) && !Number.isSafeInteger(row[key])) fail("UNSAFE_SETTINGS_INTEGER");
      out[key] = row[key];
    }
    return out;
  }
  async function copyTables(project, host, allowed) {
    const tables = Object.create(null);
    for (const [table, rows] of Object.entries(project.tables)) {
      if (!/^[a-z][a-z0-9_]*$/.test(table) || table === "constructor" || table === "prototype") fail("INVALID_SETTINGS_TABLE");
      if (table === "cards") continue;
      if (!Array.isArray(rows)) fail("INVALID_SETTINGS_TABLE");
      if (!rows.length) continue;
      const copy = rows.map(rowCopy);
      if (!allowed.has(table)) {
        if (typeof host.isUnchangedMasterRows !== "function" || await host.isUnchangedMasterRows(table, copy) !== true) fail("UNSUPPORTED_MODIFIED_TABLE");
        continue;
      }
      tables[table] = copy;
    }
    return tables;
  }
  function checkUnsupportedRuntime(project) {
    for (const key of ["formProjects", "transformLinks"]) {
      if (project[key] !== undefined && (!Array.isArray(project[key]) || project[key].length)) fail("MULTIFORM_INTEGRATION_REQUIRED");
    }
    for (const key of ["assets", "packedAssets", "generatedFiles"]) {
      if (project[key] !== undefined && (!Array.isArray(project[key]) || project[key].length)) fail("CUSTOM_ASSET_INTEGRATION_REQUIRED");
    }
    for (const key of ["actionHooks", "animationAssignments"]) {
      if (project[key] != null && (!record(project[key]) || Object.keys(project[key]).length)) fail("CUSTOM_RUNTIME_INTEGRATION_REQUIRED");
    }
    if (project.sourceDependencies != null || project.battlePoseBinding != null) fail("CUSTOM_RUNTIME_INTEGRATION_REQUIRED");
  }
  function pinStatPolicy(definition, host, project) {
    if (host.statPolicy !== undefined && project.statPolicy !== undefined && host.statPolicy !== project.statPolicy) fail("STAT_POLICY_MISMATCH");
    const policy = host.statPolicy === undefined ? project.statPolicy : host.statPolicy;
    if (policy !== undefined) {
      if (!["master-coefficient-linear-floor-v1", "creator-cap-normalized-v1"].includes(policy)) fail("UNSUPPORTED_STAT_POLICY");
      definition.stat_policy = policy;
    }
  }
  async function projectToDefinition(project, host) {
    if (!record(project) || project.format !== "dokkan-unit-forge" || project.version !== 1 || !record(project.tables) || !record(project.source)) fail("UNSUPPORTED_CREATOR_PROJECT");
    if (!record(host) || typeof host.contentId !== "string" || !host.contentId || !["eclipse", "sparking"].includes(host.sourceDatabase) || !Number.isSafeInteger(host.version) || host.version < 1) fail("INVALID_HOST_CONTEXT");
    if ((project.source.database || "eclipse") !== host.sourceDatabase) fail("SOURCE_DATABASE_MISMATCH");
    if (project.awaken) fail("OFFICIAL_AWAKENING_NOT_SHAREABLE");
    checkUnsupportedRuntime(project);
    const roots = project.tables.cards;
    if (!Array.isArray(roots) || roots.length !== 1 || !record(project.cardOverrides)) fail("INVALID_ROOT_CARD");
    const card = Object.assign(Object.create(null), rowCopy(roots[0]), rowCopy(project.cardOverrides));
    if (!Number.isSafeInteger(project.source.cardId) || project.source.cardId < 1 || card.id !== project.source.cardId) fail("SOURCE_CARD_MISMATCH");
    const rarity = host.rarity;
    if (!["UR", "LR", "SLR", "GR"].includes(rarity) || (rarity === "UR" ? card.rarity !== 4 : card.rarity !== 5)) fail("RARITY_MISMATCH");
    if (rarity === "SLR" && card.lv_max !== 180 || rarity === "GR" && card.lv_max !== 200) fail("RARITY_LEVEL_MISMATCH");
    // Master-only baseline rows may be omitted only with content-pinned host proof.
    const tables = await copyTables(project, host, TABLES);
    const id = host.definitionId || project.patch && project.patch.uuid || project.key;
    if (typeof id !== "string" || !/^[a-zA-Z0-9_.:-]{1,100}$/.test(id)) fail("INVALID_DEFINITION_ID");
    const definition = { format: "offline-dokkan-definition", schema_version: 1, definition_id: id,
      version: host.version, source: { content_id: host.contentId, master_id: project.source.cardId },
      rarity, fully_awakened: true, card, tables };
    if (card.lv_max > 150) definition.progression_policy = "creator-lr-extended-v1";
    pinStatPolicy(definition, host, project);
    if (host.creatorId !== undefined || host.creatorName !== undefined) {
      if (typeof host.creatorId !== "string" || !/^[a-zA-Z0-9_.:-]{1,100}$/.test(host.creatorId) || typeof host.creatorName !== "string" || !host.creatorName.trim() || host.creatorName !== host.creatorName.trim() || host.creatorName.length > 80 || host.creatorName.includes("\0")) fail("INVALID_CREATOR_CREDIT");
      definition.creator = { id: host.creatorId, name: host.creatorName };
    }
    return definition;
  }
  async function projectToOfficialUpgrade(project, host) {
    if (!record(project) || project.format !== "dokkan-unit-forge" || project.version !== 1 || !record(project.tables) || !record(project.source) || !record(project.awaken)) fail("UNSUPPORTED_OFFICIAL_UPGRADE");
    if (!record(host) || typeof host.contentId !== "string" || !host.contentId || !["eclipse", "sparking"].includes(host.sourceDatabase) || !Number.isSafeInteger(host.version) || host.version < 1) fail("INVALID_HOST_CONTEXT");
    if ((project.source.database || "eclipse") !== host.sourceDatabase) fail("SOURCE_DATABASE_MISMATCH");
    if (!["eza", "seza"].includes(project.awaken.kind) || project.awaken.cardId !== project.source.cardId) fail("UNSUPPORTED_OFFICIAL_UPGRADE");
    checkUnsupportedRuntime(project);
    if (!Array.isArray(project.tables.cards) || project.tables.cards.length !== 1 || !record(project.cardOverrides)) fail("INVALID_ROOT_CARD");
    const card = Object.assign(Object.create(null), rowCopy(project.tables.cards[0]), rowCopy(project.cardOverrides));
    if (!Number.isSafeInteger(project.source.cardId) || project.source.cardId < 1 || card.id !== project.source.cardId) fail("SOURCE_CARD_MISMATCH");
    const step = project.awaken.kind === "eza" ? 7 : 8;
    const growth = project.tables.optimal_awakening_growths;
    if (!Array.isArray(growth) || growth.length !== step || growth.some(row => !record(row))) fail("INCOMPLETE_AWAKENING_GRAPH");
    const growTypes = new Set(growth.map(row => row.optimal_awakening_grow_type));
    if (growTypes.size !== 1 || !Number.isSafeInteger(growth[0].optimal_awakening_grow_type) || growth[0].optimal_awakening_grow_type === 0) fail("INVALID_AWAKENING_GROW_TYPE");
    card.optimal_awakening_grow_type = growth[0].optimal_awakening_grow_type;
    const stages = new Set(growth.map(row => row.step));
    if (stages.size !== step || growth.some(row => !Number.isSafeInteger(row.step) || row.step < 1 || row.step > step)) fail("INCOMPLETE_AWAKENING_GRAPH");
    const final = growth.filter(row => row.step === step);
    for (const key of ["lv_max", "skill_lv_max", "leader_skill_set_id", "passive_skill_set_id"]) {
      if (!Number.isSafeInteger(final[0][key]) || final[0][key] === 0 || (key.endsWith("_max") && final[0][key] < 1)) fail("INVALID_FINAL_AWAKENING_STAGE");
      card[key] = final[0][key];
    }
    const allowed = new Set(TABLES);
    allowed.add("optimal_awakening_growths"); allowed.add("card_awakening_routes");
    const definition = { format: "offline-dokkan-official-upgrade", schema_version: 1, version: host.version,
      source: { content_id: host.contentId, master_id: project.source.cardId },
      kind: step === 7 ? "custom_eza" : "custom_super_eza", card,
      tables: await copyTables(project, host, allowed) };
    if (card.lv_max > 150) definition.progression_policy = "creator-lr-extended-v1";
    pinStatPolicy(definition, host, project);
    return definition;
  }
  async function importProject(execute, project, host, profile, command) {
    if (typeof execute !== "function" || typeof command !== "string" || !command) fail("INVALID_HOST_CONTEXT");
    const definition = await projectToDefinition(project, host);
    const result = await execute("creator.import", profile, command, JSON.stringify({ definition }));
    return typeof result === "string" ? JSON.parse(result) : result;
  }
  async function applyOfficialUpgrade(execute, project, host, profile, command, instanceId) {
    if (typeof execute !== "function" || typeof command !== "string" || !command || !Number.isSafeInteger(instanceId) || instanceId < 1) fail("INVALID_HOST_CONTEXT");
    const definition = await projectToOfficialUpgrade(project, host);
    const result = await execute("upgrade.apply", profile, command, JSON.stringify({instance_id: instanceId, kind: definition.kind, definition}));
    return typeof result === "string" ? JSON.parse(result) : result;
  }
  return Object.freeze({ projectToDefinition, projectToOfficialUpgrade, importProject, applyOfficialUpgrade, supportedTables: Object.freeze(Array.from(TABLES)) });
});
