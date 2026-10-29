/* When a new unit starts from a game card, bring that card's transformations along as the unit's
   own editable forms (new IDs), so the custom unit transforms into its own copies instead of the
   official cards. Follows chains (form 2 → form 3, forms that turn back) up to the form limit. */
(function() {
  "use strict";
  async function include(root, { query, schema, projects = [] } = {}) {
    const result = { project: root, added: [], skipped: [] };
    if (!root || !root.tables || (root.source && root.source.database || "eclipse") !== "eclipse") return result;
    if (root.formProjects && root.formProjects.length) return result;
    const F = window.ForgeForms, max = F.MAX_FORMS || 4;
    const forms = new Map(), queue = [], seen = new Set([Number(root.source.cardId)]);
    const enqueue = (member) => { for (const slot of F.slots(member)) if (Number.isSafeInteger(slot.targetId) && slot.targetId > 0) queue.push(slot.targetId); };
    enqueue(root);
    while (queue.length) {
      const id = queue.shift();
      if (seen.has(id)) continue;
      seen.add(id);
      if (forms.size >= max) { result.skipped.push(id); continue; }
      try {
        const form = await Forge.loadTemplate(query, schema, id, 1950000001);
        const reserved = [...projects, { key: "reserved-current-design", targetId: root.targetId }, ...[...forms.values()].map((f, i) => ({ key: "reserved-form-" + i, targetId: f.targetId }))];
        await ForgeGuide.allocateId(form, query, reserved);
        if (window.ForgeFormInheritance) ForgeFormInheritance.copy(root, form, { pending: true });
        if (Forge.validate(form).errors.length) { result.skipped.push(id); continue; }
        forms.set(id, form);
        enqueue(form);
      } catch {
        result.skipped.push(id);
      }
    }
    if (!forms.size) return result;
    let work = root;
    try {
      for (const slot of F.slots(root)) {
        const form = forms.get(slot.targetId);
        if (form) work = F.attach(work, form, { table: slot.table, row: slot.row });
      }
      work = Forge.clone(work);
      const present = new Set((work.formProjects || []).map((f) => f.key));
      for (const form of forms.values()) if (!present.has(form.key)) (work.formProjects = work.formProjects || []).push(Forge.clone(form));
      F.prune(work);
      const check = Forge.validate(work);
      if (check.errors.length) throw new Error(check.errors[0]);
    } catch (error) {
      console.warn("Transformations kept as original cards:", error);
      result.skipped.push(...forms.keys());
      return result;
    }
    result.project = work;
    result.added = (work.formProjects || []).map((f) => Forge.card(f).name);
    return result;
  }
  function message(result) {
    if (!result.added.length) return "";
    const names = [...new Set(result.added)];
    const extra = result.skipped.length ? " " + result.skipped.length + " more " + (result.skipped.length === 1 ? "transformation stays" : "transformations stay") + " as the original game card" + (result.skipped.length === 1 ? "" : "s") + " (a unit can have up to 4 custom forms)." : "";
    return "Included " + names.length + (names.length === 1 ? " transformation" : " transformations") + " as your own forms: " + names.join(", ") + ". Edit them under Transformations on the Passive Skill step." + extra;
  }
  window.ForgeTemplateForms = { include, message };
})();
