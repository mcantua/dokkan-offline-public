(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./action-hooks"));
  else root.ForgeExportFlow = factory(root.ForgeActionHooks);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Hooks) {
  "use strict";
  const clone = (value) => JSON.parse(JSON.stringify(value));
  async function prepare(project, { listProjects, loadProject } = {}) {
    var _a, _b;
    if (!((_a = project == null ? void 0 : project.actionHooks) == null ? void 0 : _a.dodge) && !(project == null ? void 0 : project.sharedActionsUpdateRequired)) return null;
    if (typeof listProjects !== "function" || typeof loadProject !== "function") throw new Error("Your saved units must be available before preparing shared actions.");
    const before = JSON.stringify(project), current = clone(project), saved = await listProjects();
    if (!Array.isArray(saved)) throw new Error("Your saved units could not be checked. Export again.");
    const projects = [current], seen = /* @__PURE__ */ new Set([current.key]);
    for (const meta of saved) {
      if (!(meta == null ? void 0 : meta.key) || seen.has(meta.key)) continue;
      seen.add(meta.key);
      const other = await loadProject(meta.key);
      if (!other || other.key !== meta.key) throw new Error("A saved unit could not be opened. Check your Library before exporting shared actions.");
      if ((_b = other.actionHooks) == null ? void 0 : _b.dodge) projects.push(clone(other));
    }
    if (JSON.stringify(project) !== before) throw new Error("Your unit changed while shared actions were prepared. Export again.");
    return finish(projects);
  }
  function finish(projects) {
    const enabled = projects.filter((p) => {
      var _a;
      return (_a = p == null ? void 0 : p.actionHooks) == null ? void 0 : _a.dodge;
    });
    return enabled.length ? { ...Hooks.support(enabled), units: enabled.map((p) => {
      var _a, _b, _c;
      return { key: p.key, name: ((_a = p.patch) == null ? void 0 : _a.name) || ((_b = p.cardOverrides) == null ? void 0 : _b.name) || ((_c = p.source) == null ? void 0 : _c.name) || "Saved unit" };
    }) } : { removeRequired: true, name: "Unit Creator Shared Actions", unitIds: [] };
  }
  async function refresh({ listProjects, loadProject } = {}) {
    if (typeof listProjects !== "function" || typeof loadProject !== "function") throw new Error("Your saved units must be available before updating shared actions.");
    const saved = await listProjects();
    if (!Array.isArray(saved)) throw new Error("Your Library could not be checked. Try again.");
    const projects = [], seen = /* @__PURE__ */ new Set();
    for (const meta of saved) {
      if (!(meta == null ? void 0 : meta.key) || seen.has(meta.key)) continue;
      seen.add(meta.key);
      const p = await loadProject(meta.key);
      if (!p || p.key !== meta.key) throw new Error("A saved unit could not be opened. Check your Library before updating shared actions.");
      projects.push(clone(p));
    }
    const latest = await listProjects();
    if (JSON.stringify(saved) !== JSON.stringify(latest)) throw new Error("Your Library changed while shared actions were prepared. Try again.");
    return finish(projects);
  }
  function supportRequest(support) {
    if (!support || typeof support.filename !== "string" || !Array.isArray(support.entries)) throw new Error("Prepare the shared actions file before saving.");
    return { kind: "eclp", name: support.filename, entries: clone(support.entries) };
  }
  async function savePair(unit, support, save) {
    if (typeof save !== "function") throw new Error("The export service is unavailable.");
    const outcome = { unitSaved: false, supportSaved: false, unitName: unit.name, supportName: support.filename };
    let result;
    try {
      result = await save(unit);
    } catch (error) {
      return { ...outcome, stage: "unit-error", error: error.message || String(error) };
    }
    if ((result == null ? void 0 : result.saved) !== true) return { ...outcome, stage: "unit-canceled" };
    outcome.unitSaved = true;
    try {
      result = await save(supportRequest(support));
    } catch (error) {
      return { ...outcome, stage: "support-error", error: error.message || String(error) };
    }
    return { ...outcome, supportSaved: (result == null ? void 0 : result.saved) === true, stage: (result == null ? void 0 : result.saved) === true ? "complete" : "support-canceled" };
  }
  return { prepare, refresh, supportRequest, savePair };
});
