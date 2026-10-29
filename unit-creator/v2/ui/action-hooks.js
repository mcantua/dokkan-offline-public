(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./core"), require("./motion"));
  else root.ForgeActionHooks = factory(root.Forge, root.ForgeMotion);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Forge, Motion) {
  "use strict";
  const path = "lua/ab_script/ab_sys/dg0001.lua";
  function verifiedOriginal(original) {
    if (!original || original.path !== "ab_script/ab_sys/dg0001.lua" || typeof original.text !== "string" || !original.text.trim() || original.text.length > 2 * 1024 ** 2) throw new Error("A verified original dodge script is needed for the fallback.");
    return { path: original.path, text: original.text };
  }
  function projectFiles(p) {
    if (!p || typeof p !== "object" || Array.isArray(p) || p.actionHooks != null && (typeof p.actionHooks !== "object" || Array.isArray(p.actionHooks)) || p.generatedFiles != null && !Array.isArray(p.generatedFiles) || p.assets != null && !Array.isArray(p.assets)) throw new Error("Repair this project's saved action settings before changing its Dodge animation.");
    const files = p.generatedFiles || [];
    if (files.some((file) => !file || typeof file !== "object" || Array.isArray(file))) throw new Error("Repair this project's generated files before changing its Dodge animation.");
    return files;
  }
  function build(projects) {
    if (!Array.isArray(projects) || projects.length > 1e4 || projects.some((p) => !p || typeof p !== "object" || Array.isArray(p))) throw new Error("Load the saved unit Library before preparing shared actions.");
    const enabled = projects.filter((p) => {
      var _a;
      return (_a = p.actionHooks) == null ? void 0 : _a.dodge;
    }), seen = /* @__PURE__ */ new Set();
    if (!enabled.length) return null;
    const original = verifiedOriginal(enabled[0].actionHooks.dodge.original);
    let text = "-- Dokkan Unit Creator per-unit dodge dispatcher. Experimental: test in Eclipse.\n-- Non-matching defenders run the original game script.\nlocal function __duc_original_dodge()\n" + original.text + "\nend\n";
    for (const [i, p] of enabled.sort((a, b) => a.targetId - b.targetId).entries()) {
      if (!Number.isSafeInteger(p.targetId) || p.targetId < 1 || seen.has(p.targetId)) throw new Error("Dodge hooks have duplicate or invalid unit IDs.");
      seen.add(p.targetId);
      if (verifiedOriginal(p.actionHooks.dodge.original).text !== original.text) throw new Error("Dodge hooks use different game versions. Reapply them using the same current source.");
      text += (i ? "elseif" : "if") + " _DEFENDER_CARD_ID_ == " + p.targetId + " then\nsetPhase(9)\nonDodgeExecuted(0)\n" + Motion.compile(p.actionHooks.dodge.clips, { damage: false, role: "defender", music:p.actionHooks.dodge.music }) + "\n";
    }
    text += "else\n__duc_original_dodge()\nend\n";
    if (text.length > 2 * 1024 ** 2) throw new Error("The combined Library dodge hook exceeds 2 MB. Reduce its sections.");
    return { owner: "dodge:unit", path, text };
  }
  const supportUuid = "1d3b1b24-3c28-4a4e-a87d-f04e5a001001";
  function support(projects, { original } = {}) {
    var _a;
    if (!Array.isArray(projects) || projects.length > 1e4) throw new Error("Load the saved unit Library before exporting Shared Actions.");
    const enabled = projects.filter((p) => {
      var _a2;
      return (_a2 = p == null ? void 0 : p.actionHooks) == null ? void 0 : _a2.dodge;
    });
    for (const p of enabled) {
      const check = Forge.validate(p);
      if (check.errors.length) throw new Error("Finish or repair " + (Forge.card(p).name || "a saved unit") + " before exporting Shared Actions: " + check.errors[0]);
      if (original && ((_a = p.actionHooks.dodge.original) == null ? void 0 : _a.text) !== original.text) throw new Error("Saved dodge animations use a different original game version. Reapply them using the same current source before exporting Shared Actions.");
    }
    let file;
    if (enabled.length) file = build(enabled);
    else {
      const fallback = verifiedOriginal(original);
      file = { path, text: fallback.text };
    }
    const unitIds = enabled.map((p) => p.targetId).sort((a, b) => a - b), metadata = { uuid: supportUuid, author: "Dokkan Unit Creator", name: "Unit Creator Shared Actions", version: "1.0.0", dependencies: [], game_version: "", description: "Shared per-unit dodge dispatcher for " + unitIds.length + " custom unit" + (unitIds.length === 1 ? "" : "s") + ". Replace this same patch and restart Eclipse after changing enabled dodge animations. Legacy unit patches that contain dg0001.lua must first be removed and re-exported.", unity: false, created: Math.floor(Date.now() / 1e3) };
    return { uuid: supportUuid, name: metadata.name, filename: "Unit-Creator-Shared-Actions.eclp", unitIds, projectKeys: enabled.map((p) => p.key), entries: [{ path: "metadata.json", text: JSON.stringify(metadata, null, 2) }, { path: "files/" + path, text: file.text }], requiresRestart: true, legacyMigration: "Remove older custom unit patches containing lua/ab_script/ab_sys/dg0001.lua once, then reinstall their newly exported unit patches and Unit Creator Shared Actions. Other mods owning that same global file must be resolved separately." };
  }
  function apply(p, clips, original, name, options = {}) {
    const files = projectFiles(p), source = verifiedOriginal(original);
    const errors = Motion.validate(clips);
    if (errors.length) throw new Error(errors.join("\n"));
    if (files.some((file) => file.path === path && file.owner !== "dodge:unit") || (p.assets || []).some((file) => file && file.path === path)) throw new Error("Another attached or generated file already owns Eclipse's shared Dodge script. Remove that conflict before applying custom Dodge.");
    const hooks = { ...p.actionHooks, dodge: { clips: Forge.clone(clips), original: source, name, music: options.music ? Forge.clone(options.music) : null, experimental: true } };
    const generated = files.filter((file) => file.owner !== "dodge:unit");
    // Compile the complete candidate before committing either project field.
    const file = build([{ ...p, actionHooks: hooks, generatedFiles: generated }]);
    p.actionHooks = hooks;
    p.generatedFiles = [...generated, file];
  }
  function remove(p) {
    const files = projectFiles(p), owned = files.some((file) => file.owner === "dodge:unit"), hooked = Boolean(p.actionHooks && Object.prototype.hasOwnProperty.call(p.actionHooks, "dodge"));
    if (!owned && !hooked) return false;
    const hooks = { ...p.actionHooks }, generated = files.filter((file) => file.owner !== "dodge:unit");
    delete hooks.dodge;
    if (p.actionHooks) p.actionHooks = hooks;
    if (p.generatedFiles || owned) p.generatedFiles = generated;
    p.sharedActionsUpdateRequired = true;
    return true;
  }
  return { path, supportUuid, support, build, apply, remove };
});
