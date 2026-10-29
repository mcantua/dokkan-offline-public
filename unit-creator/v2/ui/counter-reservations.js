(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./guide-model"));
  else root.ForgeCounterReservations = factory(root.ForgeGuide);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Guide) {
  "use strict";
  const cachedProjects = /* @__PURE__ */ new Map(), TABLES = ["passive_skills", "active_skills", "standby_skills", "finish_skills"];
  function scriptNumber(path) {
    const match = String(path || "").match(/(?:^|\/)ab_script\/attack_counter\/c([0-9]+)\.lua$/);
    return match ? Number(match[1]) : null;
  }
  async function prepare(project, { call, schema } = {}) {
    call = call || ((method, args) => Native.call(method, args));
    const before = JSON.stringify(project), occupied = /* @__PURE__ */ new Set(), info = schema ? null : await call("info", {});
    schema = schema || (info == null ? void 0 : info.schema) || project.schema;
    if (!schema || typeof schema !== "object") throw Error("Refresh the game database before assigning a counterattack.");
    for (const table of TABLES) {
      if (!schema[table]) continue;
      for (const type of [120, 128]) {
        for (let offset = 0; ; offset += 5e3) {
          const rows = await call("query", { table, filters: { efficacy_type: type }, offset, limit: 5e3 });
          if (!Array.isArray(rows)) throw Error("The game’s counterattack list could not be checked.");
          for (const row of rows) for (const number of Guide.numbersFromAbility(row, table)) occupied.add(number);
          if (rows.length < 5e3) break;
          if (offset >= 95e3) throw Error("The game has too many counterattack records to safely reserve this move.");
        }
      }
    }
    const projects = await call("projects", {});
    if (!Array.isArray(projects) || projects.length > 5e4) throw Error("The saved-unit list could not be checked.");
    const existing = new Set(projects.map((row) => row.key));
    for (const key of cachedProjects.keys()) if (!existing.has(key)) cachedProjects.delete(key);
    for (const meta of projects) {
      if (meta.key === project.key) continue;
      const prior = cachedProjects.get(meta.key);
      let numbers;
      if (prior && meta.updatedAt && prior.updatedAt === meta.updatedAt) numbers = prior.numbers;
      else {
        const saved = await call("loadProject", { key: meta.key });
        numbers = Guide.counterNumbers(saved);
        if (meta.updatedAt) cachedProjects.set(meta.key, { updatedAt: meta.updatedAt, numbers: numbers.slice() });
      }
      for (const number of numbers) occupied.add(number);
    }
    const ownedPaths = new Set((project.generatedFiles || []).filter((row) => scriptNumber(row.path) != null).map((row) => row.path.replace(/^files\//, ""))), ownedKeys = new Set((project.assets || []).filter((row) => ownedPaths.has(String(row.path || "").replace(/^files\//, ""))).map((row) => row.key));
    for (let offset = 0; ; offset += 101) {
      const rows = await call("assets", { query: "attack_counter/", offset, limit: 101 });
      if (!Array.isArray(rows)) throw Error("The imported counterattack resources could not be checked.");
      for (const row of rows) {
        if (ownedKeys.has(row.key)) continue;
        const number = scriptNumber(row.path || row.key);
        if (number != null) occupied.add(number);
      }
      if (rows.length < 101) break;
      if (offset >= 1e5) throw Error("Too many imported counterattack resources to safely reserve this move.");
    }
    if (JSON.stringify(project) !== before) throw Error("Your unit changed while its counterattack was prepared. Choose the move again.");
    const result = Guide.reserveCounterScripts(project, occupied);
    return { ...result, occupiedCount: occupied.size };
  }
  function clear() {
    cachedProjects.clear();
  }
  return { prepare, clear, scriptNumber };
});
