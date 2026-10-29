(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./art-model"), require("./battle-poses"), require("./movie-model"));
  else root.ForgePreviewBindings = factory(root.ForgeArt, root.ForgeBattlePoses, root.ForgeMovieModel);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Art, Battle, Movies) {
  "use strict";
  const valid = (id) => Number.isSafeInteger(id) && id > 0;
  function assets(project) {
    const output = [], seen = /* @__PURE__ */ new Map();
    for (const row of [...Art.previewAssets(project), ...Battle.previewAssets(project), ...Movies.previewAssets(project), ...(project.assets || []).filter(a => a.source === "sparking" || a.owner === "forge-sequence-music").map(a => ({path:a.path,key:a.key}))]) {
      const normalized = row.path.normalize("NFC").toLowerCase(), prior = seen.get(normalized);
      if (prior) {
        if (prior.path !== row.path || prior.key !== row.key) throw Error("Two preview customizations use the same resource. Restore one before previewing.");
        continue;
      }
      const copy = { path: row.path, key: row.key };
      seen.set(normalized, copy);
      output.push(copy);
    }
    if (output.length > 2e3) throw Error("This preview has too many customized resources. Use a smaller character pack.");
    return output;
  }
  function request(project, { role = "attacker" } = {}) {
    var _a, _b;
    const actorId = Number((_a = project == null ? void 0 : project.source) == null ? void 0 : _a.cardId), artCardId = Number(((_b = project == null ? void 0 : project.uiLabels) == null ? void 0 : _b.artCardId) || actorId);
    if (!valid(actorId) || !valid(artCardId) || !["attacker", "defender"].includes(role)) throw Error("Choose the unit’s source and artwork again.");
    const other = actorId === 1000020 ? 1000010 : 1000020;
    const imports=project.sourceDependencies?.animations||[],sparkingEffectIds=[...new Set(imports.flatMap(a=>a.effectIds||[]))];
    const versions=[...new Set([...(project.source?.database==="sparking"&&project.provenance?.sourceVersion?[project.provenance.sourceVersion]:[]),...imports.map(a=>a.version)])];
    if(versions.some(v=>!Number.isSafeInteger(v)||v<=0)||versions.length>1)throw Error("Use matching Sparking content versions in one unit before previewing.");

    return { ...(versions.length?{sparkingVersion:versions[0]}:{}), ...(sparkingEffectIds.length?{sparkingEffectIds}:{}), ...(project.source?.database === "sparking" ? {sourceDatabase:"sparking"} : {}), ...role === "defender" ? { attackerId: other, enemyId: actorId } : { attackerId: actorId, enemyId: other }, previewAppearance: { actorId, artCardId }, assets: assets(project), effectPacks: Movies.previewRows(project) };
  }
  return { assets, request };
});
