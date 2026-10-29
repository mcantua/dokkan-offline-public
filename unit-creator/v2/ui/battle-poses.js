(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./art-model"), require("./pose-sections"));
  else root.ForgeBattlePoses = factory(root.ForgeArt, root.ForgePoses);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Art, Poses) {
  "use strict";
  const OWNER = "forge-battle-poses", clone = (x) => JSON.parse(JSON.stringify(x)), prepared = /* @__PURE__ */ new WeakSet(), definitions = Poses.definitions;
  const safe = (x) => typeof x === "string" && x.length > 0 && x.length <= 500 && !/[\\:\x00-\x1f\x7f%]/.test(x) && !x.startsWith("/") && x.split("/").every((p) => p && !p.startsWith("."));
  const fail = (message) => {
    throw Error(message);
  }, fingerprint = (p) => JSON.stringify([p.targetId, p.source, p.tables.cards, p.tables.characters, p.tables.skill_causalities, p.schema.characters, p.cardOverrides, p.assets, p.packedAssets, p.generatedFiles, p.battlePoseBinding]);
  function inspectLwf(input) {
    const bytes = input instanceof Uint8Array ? input : new Uint8Array(input || []), version = bytes.length > 7 ? bytes[4] << 16 | bytes[5] << 8 | bytes[6] : 0, modern = version === 1315345, header = modern ? 332 : 324;
    if (bytes.length < header || bytes.length > 12 * 1024 * 1024 || String.fromCharCode(...bytes.slice(0, 4)) !== "LWF\0" || ![1183760, 1249809, 1315345].includes(version) || bytes[7] & 4) fail("Choose an uncompressed supported character LWF of 12 MB or less.");
    const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength), word = (at) => view.getUint32(at, true);
    if (word(header - 4) !== bytes.length) fail("The character animation has an invalid declared length.");
    function table(at, stride, max) {
      const start = word(at), count = word(at + 4);
      if (count > max || start < header || start > bytes.length || count * stride > bytes.length - start) fail("The character animation contains a truncated table.");
      return { start, count };
    }
    const strings = table(header - 12, 8, 16384), stringBytes = table(32, 1, 12 * 1024 * 1024), movies = table(modern ? 304 : 296, 28, 16384), links = table(modern ? 312 : 304, 8, 4096), seen = /* @__PURE__ */ new Set(), scenes = [];
    const readString = (id) => {
      if (id >= strings.count) fail("An animation name is invalid.");
      const at = strings.start + id * 8, offset = word(at), length = word(at + 4);
      if (offset > stringBytes.count || length > stringBytes.count - offset || length > 500) fail("An animation name is truncated.");
      return new TextDecoder("utf-8", { fatal: true }).decode(bytes.subarray(stringBytes.start + offset, stringBytes.start + offset + length));
    };
    for (let i = 0; i < links.count; i++) {
      const at = links.start + i * 8, name = readString(word(at)), movieId = word(at + 4);
      if (!safe(name) || seen.has(name) || movieId >= movies.count) fail("The character animation has a conflicting or invalid scene.");
      seen.add(name);
      const movie = movies.start + movieId * 28;
      scenes.push({ name, movieId, frames: word(movie + 16), offset: at + 4 });
    }
    const available = definitions.filter((d) => scenes.some((s) => s.name === d.playerScene) && scenes.some((s) => s.name === d.enemyScene)).map((d) => ({ ...d }));
    return { version, width: word(8), height: word(12), fps: word(16), scenes, available, textures: Art.lwfTextures(bytes) };
  }
  function remap(input, assignments) {
    if (!Array.isArray(assignments) || !assignments.length || assignments.length > definitions.length) fail("Choose at least one named pose replacement.");
    const info = inspectLwf(input), bytes = new Uint8Array(input), view = new DataView(bytes.buffer), seen = /* @__PURE__ */ new Set(), bindings = [];
    for (const assignment of assignments) {
      const target = info.available.find((d) => d.key === (assignment == null ? void 0 : assignment.target)), source = info.available.find((d) => d.key === (assignment == null ? void 0 : assignment.source));
      if (!target || !source || seen.has(target.key)) fail("Choose each available character pose once.");
      seen.add(target.key);
      const binding = { target: target.key, source: source.key, changes: [] };
      for (const side of ["player", "enemy"]) {
        const before = info.scenes.find((s) => s.name === target[side + "Scene"]), after = info.scenes.find((s) => s.name === source[side + "Scene"]);
        view.setUint32(before.offset, after.movieId, true);
        binding.changes.push({ side, name: before.name, originalMovieId: before.movieId, movieId: after.movieId });
      }
      bindings.push(binding);
    }
    return { bytes, bindings, info: inspectLwf(bytes) };
  }
  function sourceInfo(project) {
    var _a, _b, _c, _d, _e, _f;
    const card = (_b = (_a = project.tables) == null ? void 0 : _a.cards) == null ? void 0 : _b[0], override = (_c = project.cardOverrides) == null ? void 0 : _c.character_id, binding = project.battlePoseBinding;
    if (override !== void 0 && override !== ((_d = binding == null ? void 0 : binding.localCharacterId) != null ? _d : card == null ? void 0 : card.character_id)) fail("Restore the inherited fighter appearance before editing its named poses.");
    const sourceId = ((_f = (_e = project.battlePoseBinding) == null ? void 0 : _e.sourceCharacter) == null ? void 0 : _f.id) || Number(card == null ? void 0 : card.character_id), privateId = Number(project.targetId);
    if (!card || !Number.isSafeInteger(sourceId) || sourceId <= 0 || !Number.isSafeInteger(privateId) || privateId < 1e6 || privateId > 1999999e3 || sourceId === privateId) fail("Choose a custom unit with its own fighter resource namespace.");
    return { sourceId, privateId, stem: String(sourceId).padStart(5, "0"), privateStem: String(privateId).padStart(5, "0") };
  }
  function owned(asset, binding) {
    var _a;
    return asset.owner === OWNER && ((_a = binding == null ? void 0 : binding.paths) == null ? void 0 : _a.includes(asset.path));
  }
  function inspect(project, assets, { group } = {}) {
    var _a;
    const info = sourceInfo(project), root = "ingame/battle/character/" + info.stem + "/", all = [];
    for (const item of assets || []) {
      if (!safe(item == null ? void 0 : item.key)) fail("A fighter resource has an invalid storage key.");
      const parts = item.key.split("/"), build = parts.shift();
      if (parts[0] === "files") parts.shift();
      if (parts[0] === "tutorial0") parts.shift();
      const path = parts.join("/");
      if (path.startsWith(root) && safe(path)) all.push({ ...item, path, group: build });
    }
    for (const ref of ((_a = project.battlePoseBinding) == null ? void 0 : _a.sourceMap) || []) {
      const asset = (project.assets || []).find((a) => a.path === ref.assetPath && owned(a, project.battlePoseBinding));
      if (asset && safe(ref.path) && ref.path.startsWith(root)) all.push({ ...asset, path: ref.path, group: "saved-custom-fighter" });
    }
    const groups = [...new Set(all.map((a) => a.group))].sort();
    if (!group && groups.includes("saved-custom-fighter")) group = "saved-custom-fighter";
    if (!group && groups.length === 1) group = groups[0];
    if (group && !groups.includes(group)) fail("Choose an imported build containing this fighter.");
    const sourceAssets = all.filter((a) => a.group === group), seen = /* @__PURE__ */ new Set();
    if (sourceAssets.length > 2e3) fail("This fighter resource pack is too large. Choose a complete supported character pack.");
    for (const asset of sourceAssets) {
      const identity = asset.path.normalize("NFC").toLowerCase();
      if (seen.has(identity)) fail("This fighter resource group contains conflicting paths.");
      seen.add(identity);
    }
    const battlePath = root + "battle/battle_character_" + info.stem + ".lwf", idlePath = root + "idle/idle_character_" + info.stem + ".lwf", motion = String(Number(project.tables.cards[0].special_motion) || 0).padStart(2, "0"), spPath = root + "sp" + motion + "/sp_character_" + info.stem + "_" + motion + ".lwf", missing = [battlePath, idlePath, spPath].filter((path) => !sourceAssets.some((a) => a.path === path));
    return { ...info, root, battlePath, groups, group: group || null, sourceAssets, missing };
  }
  async function plan(project, assets, { group, assignments, sourceCharacter, characterSchema, identityAudit, occupiedCharacterIds = [], readAsset, storeLwf } = {}) {
    var _a;
    const before = fingerprint(project), info = inspect(project, assets, { group }), old = project.battlePoseBinding;
    if (!info.group || info.missing.length) fail("Import this fighter’s complete battle, idle and selected Super Attack resources first.");
    if (!(identityAudit == null ? void 0 : identityAudit.checked) || identityAudit.legacyRawCharacterConditions !== 0 || (project.tables.skill_causalities || []).some((r) => [22, 29].includes(Number(r.causality_type)))) fail("This database needs its older character-identity conditions checked before creating a private fighter.");
    sourceCharacter = (old == null ? void 0 : old.sourceCharacter) || sourceCharacter;
    characterSchema = (old == null ? void 0 : old.characterSchema) || characterSchema;
    if (!sourceCharacter || sourceCharacter.id !== info.sourceId || !Array.isArray(characterSchema) || !characterSchema.some((c) => c.name === "id")) fail("Load the source fighter record and its database fields before editing its poses.");
    if ((project.tables.characters || []).some((r) => r.id !== (old == null ? void 0 : old.localCharacterId))) fail("Advanced fighter records conflict with this private pose binding.");
    if (occupiedCharacterIds.some((id) => Number(id) === info.privateId)) fail("Another fighter already uses this custom resource ID. Choose another custom unit ID.");
    if (typeof readAsset !== "function" || typeof storeLwf !== "function") fail("The local fighter resource store is unavailable.");
    const privateRoot = "ingame/battle/character/" + info.privateStem + "/", cpkPath = "ingame/battle/character/" + info.privateStem + ".cpk";
    for (const item of assets || []) {
      const allowed = (project.assets || []).some((a) => a.key === item.key && owned(a, old));
      if (!allowed && (item.key.includes("/" + privateRoot) || item.key.endsWith("/" + cpkPath))) fail("Imported resources already occupy this fighter namespace. Choose another custom unit ID.");
    }
    const preserved = (project.assets || []).filter((a) => !owned(a, old));
    if (preserved.some((a) => a.path === cpkPath || a.path.startsWith(privateRoot)) || (project.generatedFiles || []).some((a) => a.path === cpkPath || a.path.startsWith(privateRoot)) || (project.packedAssets || []).some((a) => a.path === cpkPath && a.owner !== OWNER)) fail("Another attachment already occupies this fighter namespace.");
    let battleBytes;
    for (const asset of info.sourceAssets.filter((a) => a.path.endsWith(".lwf"))) {
      const data = await readAsset(asset.key);
      const parsed = inspectLwf(data), folder = asset.path.slice(0, asset.path.lastIndexOf("/") + 1);
      for (const texture of parsed.textures) if (!info.sourceAssets.some((a) => a.path === folder + texture)) fail("Import the missing fighter texture " + texture + " before applying poses.");
      if (asset.path === info.battlePath) battleBytes = data;
    }
    const battle = info.sourceAssets.find((a) => a.path === info.battlePath), patched = remap(battleBytes, assignments), stored = await storeLwf(patched.bytes, { name: "Custom fighter poses" });
    if (!safe(stored == null ? void 0 : stored.key) || !stored.key.toLowerCase().endsWith(".lwf")) fail("The custom fighter animation could not be stored.");
    const attached = [], mapping = [], seen = /* @__PURE__ */ new Set();
    function attach(path, key) {
      if (seen.has(path)) fail("The private fighter pack has conflicting filenames.");
      seen.add(path);
      attached.push({ path, key, owner: OWNER });
    }
    let modifiedPath;
    for (const asset of info.sourceAssets) {
      const relative = asset.path.slice(info.root.length), path = privateRoot + relative;
      attach(path, asset.key);
      mapping.push({ path: asset.path, assetPath: path });
      if (asset.path.endsWith(".lwf")) {
        const file = relative.slice(relative.lastIndexOf("/") + 1), renamed = file.split(info.stem).join(info.privateStem);
        if (renamed !== file) {
          const alias = privateRoot + relative.slice(0, relative.lastIndexOf("/") + 1) + renamed;
          attach(alias, asset === battle ? stored.key : asset.key);
          if (asset === battle) modifiedPath = alias;
        }
      }
    }
    if (!modifiedPath) fail("The fighter’s native battle animation filename could not be preserved.");
    const localCharacterId = (old == null ? void 0 : old.localCharacterId) || -1, row = { ...clone(sourceCharacter), id: localCharacterId }, pack = { path: cpkPath, owner: OWNER, entries: attached.map((a) => ({ path: a.path.slice(privateRoot.length), assetPath: a.path })) };
    const ownership = { privateCharacterId: info.privateId, sourceCharacter: clone(sourceCharacter), characterSchema: clone(characterSchema), localCharacterId, paths: attached.map((a) => a.path), archivePath: cpkPath, sourceMap: mapping, battlePath: info.battlePath, modifiedPath, bindings: patched.bindings.map((b) => ({ target: b.target, source: b.source })), identityAudit: clone(identityAudit), previousOverride: (old == null ? void 0 : old.previousOverride) || { present: Object.prototype.hasOwnProperty.call(project.cardOverrides, "character_id"), value: (_a = project.cardOverrides.character_id) != null ? _a : null }, hadPackedAssets: old ? old.hadPackedAssets : Object.prototype.hasOwnProperty.call(project, "packedAssets"), hadTable: old ? old.hadTable : Object.prototype.hasOwnProperty.call(project.tables, "characters"), hadSchema: old ? old.hadSchema : Object.prototype.hasOwnProperty.call(project.schema, "characters") };
    if (fingerprint(project) !== before) fail("The unit changed while its fighter resources were prepared. Open the pose editor again.");
    const result = { before, assets: attached, pack, row, characterSchema: clone(characterSchema), ownership };
    prepared.add(result);
    return result;
  }
  function apply(project, plan2) {
    if (!prepared.has(plan2) || fingerprint(project) !== plan2.before) fail("The unit changed. Prepare its fighter poses again.");
    const old = project.battlePoseBinding;
    project.assets = [...(project.assets || []).filter((a) => !owned(a, old)), ...clone(plan2.assets)];
    project.packedAssets = [...(project.packedAssets || []).filter((p) => p.owner !== OWNER), clone(plan2.pack)];
    project.tables.characters = [clone(plan2.row)];
    project.schema.characters = clone(plan2.characterSchema);
    project.cardOverrides.character_id = plan2.row.id;
    project.battlePoseBinding = clone(plan2.ownership);
    prepared.delete(plan2);
    return project;
  }
  function restore(project) {
    const old = project.battlePoseBinding;
    if (!old) return project;
    project.assets = (project.assets || []).filter((a) => !owned(a, old));
    project.packedAssets = (project.packedAssets || []).filter((p) => p.owner !== OWNER);
    if (!project.packedAssets.length && !old.hadPackedAssets) delete project.packedAssets;
    project.tables.characters = (project.tables.characters || []).filter((r) => r.id !== old.localCharacterId);
    if (!old.hadTable && !project.tables.characters.length) delete project.tables.characters;
    if (!old.hadSchema) delete project.schema.characters;
    if (project.cardOverrides.character_id === old.localCharacterId) {
      if (old.previousOverride.present) project.cardOverrides.character_id = old.previousOverride.value;
      else delete project.cardOverrides.character_id;
    }
    delete project.battlePoseBinding;
    return project;
  }
  function previewAssets(project) {
    const binding = project.battlePoseBinding;
    if (!binding) return [];
    const info = sourceInfo(project), root = "ingame/battle/character/" + info.stem + "/", seen = /* @__PURE__ */ new Set();
    if (!Array.isArray(binding.sourceMap) || !binding.sourceMap.length || binding.sourceMap.length > 2e3) fail("The private fighter preview mapping is invalid.");
    return binding.sourceMap.map((ref) => {
      var _a;
      const path = ref.path === binding.battlePath ? binding.modifiedPath : ref.assetPath, asset = (project.assets || []).find((a) => a.path === path && owned(a, binding)), folded = (_a = ref.path) == null ? void 0 : _a.normalize("NFC").toLowerCase();
      if (!asset || !safe(asset.key) || !safe(ref.path) || !ref.path.startsWith(root) || seen.has(folded) || asset.key.slice(asset.key.lastIndexOf(".")).toLowerCase() !== ref.path.slice(ref.path.lastIndexOf(".")).toLowerCase()) fail("A private fighter preview resource is missing or invalid. Restore or import the complete project.");
      seen.add(folded);
      return { path: ref.path, key: asset.key };
    });
  }
  return { inspectLwf, remap, inspect, plan, apply, restore, previewAssets };
});
