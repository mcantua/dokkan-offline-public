(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./core"), require("./unit-rebase"));
  else root.ForgeForms = factory(root.Forge, root.ForgeUnitRebase);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Forge, UnitRebase) {
  "use strict";
  const TABLES = ["passive_skills", "active_skills", "standby_skills", "finish_skills"];
  function list(project) { return project ? [project, ...(Array.isArray(project.formProjects) ? project.formProjects : [])] : []; }
  function target(row, table) {
    let values;
    try { const parsed = JSON.parse(row.efficacy_values || "{}"); if (Array.isArray(parsed)) values = parsed; } catch {}
    const field = table === "passive_skills" ? "eff_value1" : "eff_val1";
    return { field, values, targetId: Number(values ? values[0] : row[field]) };
  }
  // Where a passive row is used (base kit and/or Extreme Z-Awakening stages), so identical
  // transformation names from different awakening stages can be told apart.
  function passiveStageLabel(project, rowId) {
    const tables = project.tables || {}, sets = new Set((tables.passive_skill_set_relations || []).filter(r => r.passive_skill_id === rowId).map(r => r.passive_skill_set_id));
    const base = Forge.card(project).passive_skill_set_id, labels = [];
    if (sets.has(base)) labels.push("before EZA");
    const steps = (tables.optimal_awakening_growths || []).filter(r => sets.has(r.passive_skill_set_id)).map(r => Number(r.step)).sort((a, b) => a - b);
    if (steps.length) labels.push("EZA stage" + (steps.length > 1 ? "s " + steps[0] + "–" + steps[steps.length - 1] : " " + steps[0]));
    return labels.join(", ");
  }
  function slots(project) {
    if (!project || !project.tables) return [];
    const list = TABLES.flatMap(table => (project.tables[table] || []).filter(row => Number(row.efficacy_type) === 103).map(row => {
      const link = (project.transformLinks || []).find(link => link.table === table && link.row === row.id), child = link && (project.formProjects || []).find(child => child.key === link.targetKey);
      return { table, row: row.id, targetId: target(row, table).targetId, name: row.name || (table === "active_skills" ? "Active Skill transformation" : table === "passive_skills" ? "Automatic transformation" : table === "standby_skills" ? "Standby transformation" : "Finish transformation"), linkedKey: child && child.key || null, linkedName: child ? Forge.card(child).name : null };
    }));
    const counts = new Map();
    for (const slot of list) counts.set(slot.name, (counts.get(slot.name) || 0) + 1);
    for (const slot of list) if (counts.get(slot.name) > 1) {
      let detail = "";
      try { detail = slot.table === "passive_skills" ? passiveStageLabel(project, slot.row) : ""; } catch {}
      slot.name += " · " + (detail || (slot.table === "active_skills" ? "Active Skill" : slot.table === "standby_skills" ? "Standby" : slot.table === "finish_skills" ? "Finish" : "ability #" + slot.row));
    }
    const totals = new Map(), seen = new Map();
    for (const slot of list) totals.set(slot.name, (totals.get(slot.name) || 0) + 1);
    for (const slot of list) if (totals.get(slot.name) > 1) { const base = slot.name, n = (seen.get(base) || 0) + 1; seen.set(base, n); slot.name = base + " (" + n + ")"; }
    return list;
  }
  // Forms kept in a unit: those chosen by a starting-form transformation link, plus forms reached
  // through a transformation of another kept form (for example base → form 2 → form 3, or a form
  // that turns back). Those rows keep the original card's ID and are moved to the custom form's
  // ID at export, so the whole chain uses the unit's own cards.
  function chained(project) {
    const forms = Array.isArray(project && project.formProjects) ? project.formProjects : [];
    const keep = new Set((project && project.transformLinks || []).map(link => link.targetKey));
    const bySource = new Map(forms.map(form => [Number(form.source && form.source.cardId), form]));
    for (let changed = true; changed;) {
      changed = false;
      for (const member of [project, ...forms.filter(form => keep.has(form.key))]) for (const table of TABLES) for (const row of member.tables && member.tables[table] || []) {
        if (Number(row.efficacy_type) !== 103) continue;
        const form = bySource.get(target(row, table).targetId);
        if (form && form.key !== member.key && !keep.has(form.key)) { keep.add(form.key); changed = true; }
      }
    }
    return keep;
  }
  function prune(project) {
    if (!project || !Array.isArray(project.formProjects)) return project;
    const keep = chained(project);
    project.formProjects = project.formProjects.filter(form => keep.has(form.key));
    if (project.transformLinks && !project.transformLinks.length) delete project.transformLinks;
    if (!project.formProjects.length && !project.transformLinks) delete project.formProjects;
    return project;
  }
  function attach(base, child, selection) {
    if (!base || !child || !selection || !TABLES.includes(selection.table) || !Number.isSafeInteger(selection.row)) throw Error("Choose an existing transformation ability and the unit it becomes.");
    if (child === base || child.key === base.key || child.formProjects !== undefined || child.transformLinks !== undefined) throw Error("Choose a separate standalone form. Nested transformations and form cycles are not supported.");
    const oldSlot = slots(base).find(slot => slot.table === selection.table && slot.row === selection.row);
    if (!oldSlot) throw Error("This unit has no supported transformation in that move. Start with a transforming character; the original transformation rules are preserved.");
    const root = Forge.clone(base), snapshot = Forge.clone(child), row = root.tables[selection.table].find(row => row.id === selection.row), info = target(row, selection.table);
    row[info.field] = Number(snapshot.targetId);
    if (info.values) { info.values[0] = Number(snapshot.targetId); row.efficacy_values = JSON.stringify(info.values); }
    root.transformLinks = (root.transformLinks || []).filter(link => !(link.table === selection.table && link.row === selection.row));
    root.transformLinks.push({ table: selection.table, row: selection.row, targetKey: snapshot.key, targetId: Number(snapshot.targetId) });
    root.formProjects = (root.formProjects || []).filter(form => form.key !== snapshot.key);
    root.formProjects.push(snapshot);
    prune(root);
    const result = Forge.validate(root);
    if (result.errors.length) throw Error(result.errors.join("\n"));
    return root;
  }
  async function reserve(original, options = {}) {
    const createdAssets = [], before = JSON.stringify(original);
    try {
      const check = Forge.validate(original);
      if (check.errors.length) throw Error(check.errors.join("\n"));
      if (!UnitRebase || typeof UnitRebase.reserve !== "function") throw Error("The unit slot reservation tool is unavailable. Reopen the app.");
      if (!Array.isArray(options.projects)) throw Error("Load the saved unit library before reserving transformation slots.");
      const members = list(original), reservations = Forge.clone(options.projects), usedKeys = new Set([...reservations, ...members].map(p => p.key));
      // Keep every old block reserved under a distinct key. The single-unit
      // allocator normally excludes its caller's key, which must not release
      // another old form's records while the bundle is being migrated.
      for (let i = 0; i < members.length; i++) {
        let key = "forge-form-reserved-" + i;
        while (usedKeys.has(key)) key += "-reserved";
        usedKeys.add(key); reservations.push({ key, targetId: members[i].targetId });
      }
      const nextMembers = [];
      for (const member of members) {
        const standalone = Forge.clone(member);
        delete standalone.formProjects; delete standalone.transformLinks;
        const result = await UnitRebase.reserve(standalone, { ...options, projects: reservations });
        createdAssets.push(...result.createdAssets || []);
        nextMembers.push(result.project);
        reservations.push({ key: result.project.key, targetId: result.project.targetId });
      }
      const project = nextMembers[0];
      // Unlinked copies of a transformation (made when an ability stage is edited) also follow
      // their form to its new slot.
      const moved = new Map(members.map((member, i) => [Number(member.targetId), Number(nextMembers[i].targetId)]));
      for (const member of nextMembers) for (const table of TABLES) for (const row of member.tables && member.tables[table] || []) {
        if (Number(row.efficacy_type) !== 103) continue;
        const info = target(row, table);
        if (!moved.has(info.targetId) || moved.get(info.targetId) === info.targetId) continue;
        row[info.field] = moved.get(info.targetId);
        if (info.values) { info.values[0] = moved.get(info.targetId); row.efficacy_values = JSON.stringify(info.values); }
      }
      if (original.formProjects !== undefined || original.transformLinks !== undefined) {
        project.formProjects = nextMembers.slice(1);
        project.transformLinks = (original.transformLinks || []).map(link => {
          const child = project.formProjects.find(form => form.key === link.targetKey), row = (project.tables[link.table] || []).find(row => row.id === link.row);
          if (!child || !row || Number(row.efficacy_type) !== 103) throw Error("A transformation ability changed while its new unit slots were prepared. Choose its form again.");
          const info = target(row, link.table);
          row[info.field] = Number(child.targetId);
          if (info.values) { info.values[0] = Number(child.targetId); row.efficacy_values = JSON.stringify(info.values); }
          return { ...link, targetId: Number(child.targetId) };
        });
      }
      const final = Forge.validate(project);
      if (final.errors.length) throw Error(final.errors.join("\n"));
      if (JSON.stringify(original) !== before) throw Error("Your unit changed while its transformation slots were prepared. Export again.");
      return { project, before, createdAssets: [...new Set(createdAssets)] };
    } catch (error) {
      error.createdAssets = [...new Set([...createdAssets, ...error.createdAssets || []])];
      throw error;
    }
  }
  function validate(project) { return Forge.validate(project); }
  return { MAX_FORMS: 4, list, all: list, slots, target, attach, reserve, validate, chained, prune };
});
