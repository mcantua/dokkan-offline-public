(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./core"), require("./guide-model"), require("./art-model"), require("./battle-poses"), require("./action-hooks"), require("./movie-model"));
  else root.ForgeUnitRebase = factory(root.Forge, root.ForgeGuide, root.ForgeArt, root.ForgeBattlePoses, root.ForgeActionHooks, root.ForgeMovieModel);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Forge, Guide, Art, Battle, Hooks, Movies) {
  "use strict";
  const fail = (message) => {
    throw Error(message);
  };
  function namespace(path, id) {
    const art = String(Math.floor(id / 10) * 10), fighter = String(id);
    path = String(path).normalize("NFC").toLowerCase();
    const script = path.match(/(?:^|\/)lua\/ab_script\/.+\/[a-z_]*([0-9]+)\.lua$/);
    return path.includes("movie/ingame/battle/sp_effect/forge_movie_" + id + "_") || path.includes("movie/ingame/battle/effect/forge_movie_" + id + "_") || Boolean(script && Number(script[1]) >= id + 500 && Number(script[1]) <= id + 601) || path.includes("character/card/" + art + "/") || path.endsWith("character/card/" + art + ".cpk") || path.includes("character/card_bg/" + art + "/") || path.endsWith("character/card_bg/" + art + ".cpk") || path.includes("character/thumb/card_" + art + "_thumb") || path.includes("ingame/battle/character/" + fighter + "/") || path.endsWith("ingame/battle/character/" + fighter + ".cpk");
  }
  async function reserve(original, { query, projects, schema, readAsset, storeLwf, storeDecoration, listAssets, prepareCounters } = {}) {
    var _a, _b, _c;
    const before = JSON.stringify(original), project = Forge.clone(original), createdAssets = [];
    try {
      if (Object.keys(project.animationAssignments || {}).some((key) => key.startsWith("counter:"))) {
        if (typeof prepareCounters !== "function") fail("Check available counter animations before moving this unit.");
        await prepareCounters(project);
        for (const [key, a] of Object.entries(project.animationAssignments)) if (key.startsWith("counter:")) (a.mode === "original" ? Guide.applyOriginal(project, schema || project.schema, a.originalSource || a.clips?.[0]?.source, key, a.name) : Guide.applyComposition(project, schema || project.schema, a.clips, key, a.name, {music:a.music}));
      }
      const initial = Forge.validate(project);
      if (initial.errors.length) fail(initial.errors[0]);
      if (typeof query !== "function" || !Array.isArray(projects)) fail("The game database and saved units must be available before reserving a unit slot.");
      const reservations = Forge.clone(projects);
      let assets = [], reserved = false;
      for (let attempt = 0; attempt < 100; attempt++) {
        await Guide.allocateId(project, query, reservations);
        const id = project.targetId, art = Math.floor(id / 10) * 10;
        let collision = false;
        if (project.artBinding) {
          collision = (await query({ table: "cards", filters: { resource_id: art }, limit: 1 })).length > 0 || (await query({ table: "cards", ids: Array.from({ length: 10 }, (_, i) => art + i), limit: 1 })).length > 0;
        }
        if (!collision && project.battlePoseBinding) collision = (await query({ table: "characters", ids: [id], limit: 1 })).length > 0;
        if (!collision && ((_a = project.movieBindings) == null ? void 0 : _a.length)) for (const binding of project.movieBindings) {
          if ((await query({ table: "effect_packs", filters: { pack_name: "forge_movie_" + id + "_" + binding.slot + "_" + binding.storageTag }, limit: 1 })).length) {
            collision = true;
            break;
          }
        }
        assets = [];
        if (!collision && typeof listAssets === "function") {
          const prefixes = /* @__PURE__ */ new Set([String(Math.floor(id / 1e3)), String(Math.floor((id + 600) / 1e3))]);
          for (const prefix of prefixes) {
            let ended = false;
            for (let offset = 0; offset < 1e5; offset += 500) {
              const page = await listAssets({ query: prefix, offset, limit: 500 });
              if (!Array.isArray(page)) fail("The imported resource list could not be checked.");
              assets.push(...page);
              if (page.length < 500) {
                ended = true;
                break;
              }
            }
            if (!ended) fail("Too many matching imported resources to safely reserve a unit slot.");
          }
          const owned = new Set((project.assets || []).filter((a) => ["forge-card-art", "forge-battle-poses", "forge-authored-movie"].includes(a.owner)).map((a) => a.key));
          collision = assets.some((a) => !owned.has(a.key) && namespace(a.path || a.key, id));
        }
        if (!collision) {
          reserved = true;
          break;
        }
        reservations.push({ key: "reserved-resource-" + id, targetId: id });
      }
      if (!reserved) fail("Could not reserve a free unit and resource namespace. Refresh the game data and retry.");
      if ((_b = project.movieBindings) == null ? void 0 : _b.length) Movies.rebase(project, { buildDodge: (items) => Hooks.build(items) });
      if (Object.keys(project.animationAssignments || {}).some((key) => key.startsWith("counter:"))) await prepareCounters(project);
      for (const [key, assignment] of Object.entries(project.animationAssignments || {})) (assignment.mode === "original" ? Guide.applyOriginal(project, schema || project.schema, assignment.originalSource || assignment.clips?.[0]?.source, key, assignment.name) : Guide.applyComposition(project, schema || project.schema, assignment.clips, key, assignment.name, {music:assignment.music}));
      if ((_c = project.actionHooks) == null ? void 0 : _c.dodge) {
        project.generatedFiles = (project.generatedFiles || []).filter((f) => f.owner !== "dodge:unit");
        project.generatedFiles.push(Hooks.build([project]));
      }
      assets = [...assets, ...(project.assets || []).map((a) => ({ key: a.key, path: a.path }))];
      if (project.artBinding) {
        const previousArt=Forge.clone(project.artBinding);
        const plan = await Art.plan(project, assets, { group: "saved-custom-artwork", replacements: Art.replacements(project), readAsset, storeDecoration: async text => {
          if (typeof storeDecoration !== "function") fail("Update the artwork storage bridge before moving this card.");
          const stored = await storeDecoration(text);
          if (stored?.key) createdAssets.push(stored.key);
          return stored;
        } });
        Art.apply(project, plan);
        if(previousArt.staticBackground){project.cardOverrides.bg_effect_id=null;project.artBinding.staticBackground=true;}
        if(Object.prototype.hasOwnProperty.call(previousArt,"previousPreviewKey"))project.artBinding.previousPreviewKey=previousArt.previousPreviewKey;
      }
      if (project.battlePoseBinding) {
        let legacy = 0;
        for (const type of [22, 29]) legacy += (await query({ table: "skill_causalities", filters: { causality_type: type }, limit: 1 })).length;
        const assignments = Forge.clone(project.battlePoseBinding.bindings), plan = await Battle.plan(project, assets, { group: "saved-custom-fighter", assignments, identityAudit: { checked: true, legacyRawCharacterConditions: legacy }, readAsset, storeLwf: async (bytes, options) => {
          const stored = await storeLwf(bytes, options);
          if (stored == null ? void 0 : stored.key) createdAssets.push(stored.key);
          return stored;
        } });
        Battle.apply(project, plan);
      }
      const check = Forge.validate(project);
      if (check.errors.length) fail(check.errors[0]);
      if (JSON.stringify(original) !== before) fail("Your unit changed while its new slot was prepared. Export again.");
      return { project, before, createdAssets };
    } catch (error) {
      error.createdAssets = createdAssets.slice();
      throw error;
    }
  }
  return { reserve, namespace };
});
