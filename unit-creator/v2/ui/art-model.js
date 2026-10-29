(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory();
  else root.ForgeArt = factory();
})(typeof globalThis !== "undefined" ? globalThis : this, function() {
  "use strict";
  const OWNER = "forge-card-art", clone = (x) => JSON.parse(JSON.stringify(x)), plans = /* @__PURE__ */ new WeakSet();
  const safe = (x) => typeof x === "string" && x.length > 0 && x.length <= 500 && !/[\\:\x00-\x1f\x7f%]/.test(x) && !x.startsWith("/") && x.split("/").every((p) => p && p !== "." && p !== ".." && !p.startsWith("."));
  function fail(message) {
    throw new Error(message);
  }
  function resource(value) {
    const n = Number(value);
    if (!Number.isSafeInteger(n) || n < 10 || n > 2147483647) fail("Choose a valid custom unit before creating game artwork.");
    return Math.floor(n / 10) * 10;
  }
  function normalize(item) {
    if (!item || !safe(item.key)) fail("An imported artwork file has an invalid storage key.");
    const parts = item.key.split("/"), group = parts.shift();
    if (parts[0] === "files") parts.shift();
    if (parts[0] === "tutorial0") parts.shift();
    const path = parts.join("/");
    if (!safe(path)) fail("An imported artwork file has an invalid game path.");
    return { ...item, group, path };
  }
  function original(project) {
    var _a, _b, _c, _d, _e, _f, _g;
    const c = (_b = (_a = project == null ? void 0 : project.tables) == null ? void 0 : _a.cards) == null ? void 0 : _b[0];
    if (!c || !project.source) fail("Choose a source unit first.");
    const binding = project.artBinding, chosen = project.cardOverrides || {}, sourceId = resource((_g = (_f = (_e = (_d = (_c = binding == null ? void 0 : binding.sourceId) != null ? _c : chosen.resource_id) != null ? _d : project.source.resourceId) != null ? _e : c.resource_id) != null ? _f : project.source.cardId) != null ? _g : c.id), bgValue = binding && Object.prototype.hasOwnProperty.call(binding, "bgSourceId") ? binding.bgSourceId : chosen.bg_effect_id !== void 0 ? chosen.bg_effect_id : c.bg_effect_id, bgSourceId = Number(bgValue) > 0 ? resource(bgValue) : null;
    return { card: c, sourceId, bgSourceId, resourceId: resource(project.targetId) };
  }
  function owned(a, binding) {
    var _a;
    return a.owner === OWNER && ((_a = binding == null ? void 0 : binding.paths) == null ? void 0 : _a.includes(a.path));
  }
  function fingerprint(project) {
    return JSON.stringify([project.targetId, project.source, project.tables.cards, project.cardOverrides, project.assets, project.packedAssets, project.artBinding]);
  }
  function replacements(project) {
    var _a;
    return (((_a = project.artBinding) == null ? void 0 : _a.replacements) || []).map((ref) => {
      if (ref.assetPath) {
        const asset = (project.assets || []).find((a) => a.path === ref.assetPath);
        if (!asset) fail("A saved artwork layer is missing. Restore the original artwork or import the complete project again.");
        return { role: ref.role, key: asset.key };
      }
      return { role: ref.role, key: ref.key };
    });
  }
  function previewAssets(project) {
    const binding = project == null ? void 0 : project.artBinding;
    if (!binding) return [];
    if (!Array.isArray(binding.sourceMap) || binding.sourceMap.length < 1 || binding.sourceMap.length > 2e3) fail("The saved artwork preview mapping is missing or too large. Apply the artwork again.");
    const { sourceId, bgSourceId } = original(project), stem = String(sourceId).padStart(7, "0"), bg = String(bgSourceId || sourceId).padStart(7, "0"), prefixes = ["character/card/" + stem + "/", "character/card_bg/" + bg + "/", "character/thumb/card_" + stem + "_thumb/"], thumb = "character/thumb/card_" + stem + "_thumb.png", aliases = [], seen = /* @__PURE__ */ new Set();
    for (const ref of binding.sourceMap) {
      if (!ref || !safe(ref.path) || !(ref.path === thumb || prefixes.some((p) => ref.path.startsWith(p)))) fail("A saved artwork preview path is invalid.");
      const asset = (project.assets || []).find((a) => a.path === ref.assetPath && owned(a, binding));
      if (!asset || !safe(asset.key)) fail("A saved artwork preview file is missing. Restore the original artwork or import the complete project again.");
      const extension = (value) => value.slice(value.lastIndexOf(".")).toLowerCase();
      if (extension(asset.key) !== extension(ref.path)) fail("A saved artwork preview file has the wrong resource type.");
      const folded = ref.path.normalize("NFC").toLowerCase();
      if (seen.has(folded)) fail("The saved artwork preview contains conflicting paths.");
      seen.add(folded);
      aliases.push({ path: ref.path, key: asset.key });
    }
    return aliases;
  }
  function inspect(project, assets, { group } = {}) {
    var _a;
    const { card, sourceId, bgSourceId, resourceId } = original(project), stem = String(sourceId).padStart(7, "0"), cardRoot = "character/card/" + stem + "/", bgRoot = "character/card_bg/" + String(bgSourceId || sourceId).padStart(7, "0") + "/", thumbFlat = "character/thumb/card_" + stem + "_thumb.png", thumbRoot = "character/thumb/card_" + stem + "_thumb/";
    const all = (assets || []).map(normalize), savedGroup = "saved-custom-artwork";
    for (const ref of ((_a = project.artBinding) == null ? void 0 : _a.sourceMap) || []) {
      const asset = (project.assets || []).find((a) => a.path === ref.assetPath && owned(a, project.artBinding));
      if (asset && safe(ref.path) && safe(asset.key)) all.push({ ...asset, path: ref.path, group: savedGroup });
    }
    const relevant = (a) => a.path.startsWith(cardRoot) || a.path.startsWith(bgRoot) || a.path === thumbFlat || a.path.startsWith(thumbRoot), groups = [...new Set(all.filter(relevant).map((a) => a.group))].sort();
    if (!group && groups.includes(savedGroup)) group = savedGroup;
    if (!group && groups.length === 1) group = groups[0];
    if (group && !groups.includes(group)) fail("Choose an imported resource group that contains this source unit.");
    const sourceAssets = group ? all.filter((a) => a.group === group && relevant(a) && !a.path.endsWith(".cpk")) : [], seen = /* @__PURE__ */ new Set();
    for (const a of sourceAssets) {
      const key = a.path.normalize("NFC").toLowerCase();
      if (seen.has(key)) fail("Imported artwork contains conflicting resource paths.");
      seen.add(key);
    }
    const roles = [], missing = [], labels = { character: "Character artwork", bg: "Card background", effect: "Card effect layer", circle: "Circle portrait", cutin: "Attack cut-in", sp_cutin: "Super Attack cut-in", thumb: "Team portrait" };
    const add = (id, label, path) => {
      const file = sourceAssets.find((a) => a.path === path);
      if (file) roles.push({ id, label, key: file.key, path: file.path });
      else missing.push(label);
    };
    for (const role of ["character", "bg", "effect", "circle", "cutin"]) add(role, labels[role], cardRoot + "card_" + stem + "_" + role + ".png");
    add("sp_cutin", labels.sp_cutin, cardRoot + "card_" + stem + "sp_cutin_1.png");
    const thumb = sourceAssets.find((a) => a.path === thumbFlat) || sourceAssets.find((a) => a.path === thumbRoot + "card_" + stem + "_thumb.png");
    if (thumb) roles.push({ id: "thumb", label: labels.thumb, key: thumb.key, path: thumb.path });
    else missing.push(labels.thumb);
    for (const a of sourceAssets) {
      if (!a.path.endsWith(".png") || roles.some((r) => r.key === a.key)) continue;
      const animated = a.path.startsWith(bgRoot), relative = animated ? a.path.slice(bgRoot.length) : a.path.slice(cardRoot.length), texture = /^lwf_image([0-9]+)\.png$/.exec(relative), text = /^(?:([a-z]{2})\/)?card_[0-9]+_sp([0-9]*)_(name|phrase)\.png$/.exec(relative);
      let label = animated ? "Animated card texture" : "Additional card layer";
      if (animated && /_character\.png$/.test(relative)) label = "Animated card character artwork";
      else if (animated && texture) label = "Animated background texture " + (Number(texture[1]) + 1);
      else if (/_piece\.png$/.test(relative)) label = "Small portrait piece";
      else if (text) label = (text[1] === "en" ? "English " : text[1] ? text[1].toUpperCase() + " " : "") + "Super Attack " + (text[3] === "name" ? "title" : "quote") + (text[2] ? " · variation " + Number(text[2]) : "");
      roles.push({ id: (animated ? "animated:" : "extra:") + relative, label, key: a.key, path: a.path });
    }
    if (bgSourceId && !sourceAssets.some((a) => [".lwf", ".usm"].some(extension => a.path === bgRoot + "card_" + String(bgSourceId).padStart(7, "0") + extension))) missing.push("Animated card background (LWF texture pack or USM movie)");
    return { sourceId, bgSourceId, resourceId, groups, group: group || null, roles, missing, sourceAssets, cardRoot, bgRoot, thumbFlat, thumbRoot };
  }
  function pngInfo(input) {
    const b = input instanceof Uint8Array ? input : new Uint8Array(input || []);
    if (b.length < 45 || b.length > 32 * 1024 * 1024 || [137, 80, 78, 71, 13, 10, 26, 10].some((v, i) => b[i] !== v)) fail("Artwork must be a PNG image of 32 MB or less.");
    const view = new DataView(b.buffer, b.byteOffset, b.byteLength);
    if (view.getUint32(8) !== 13 || String.fromCharCode(...b.slice(12, 16)) !== "IHDR") fail("This PNG has an invalid image header.");
    const width = view.getUint32(16), height = view.getUint32(20);
    if (!width || !height || width > 8192 || height > 8192) fail("Artwork dimensions must be between 1 and 8192 pixels.");
    let at = 8, ended = false;
    while (at < b.length) {
      if (at + 12 > b.length) fail("This PNG is truncated.");
      const n = view.getUint32(at);
      if (n > b.length - at - 12) fail("This PNG is truncated.");
      const type = String.fromCharCode(...b.slice(at + 4, at + 8));
      at += n + 12;
      if (type === "IEND") {
        ended = n === 0 && at === b.length;
        break;
      }
    }
    if (!ended) fail("This PNG is incomplete.");
    return { width, height };
  }
  function lwfTextures(input) {
    const b = input instanceof Uint8Array ? input : new Uint8Array(input || []), version = b.length >= 8 ? b[4] << 16 | b[5] << 8 | b[6] : 0;
    if (b.length < 324 || String.fromCharCode(...b.slice(0, 4)) !== "LWF\0" || ![1183760, 1249809, 1315345].includes(version) || b[7] & 4) fail("This animated artwork uses an unsupported or compressed LWF header.");
    const view = new DataView(b.buffer, b.byteOffset, b.byteLength), header = version === 1315345 ? 332 : 324;
    if (b.length < header) fail("The animated artwork file is truncated.");
    function range(offset, length) {
      if (!Number.isSafeInteger(offset) || !Number.isSafeInteger(length) || offset < header || length < 0 || offset > b.length || length > b.length - offset) fail("The animated artwork file is truncated.");
    }
    const stringOffset = view.getUint32(32, true), stringLength = view.getUint32(36, true), textureOffset = view.getUint32(96, true), textureCount = view.getUint32(100, true), strings = view.getUint32(header - 12, true), count = view.getUint32(header - 8, true);
    range(stringOffset, stringLength);
    range(textureOffset, textureCount * 20);
    range(strings, count * 8);
    const result = [];
    for (let i = 0; i < textureCount; i++) {
      const id = view.getUint32(textureOffset + i * 20, true);
      if (id >= count) fail("An animated artwork texture name is invalid.");
      const at = view.getUint32(strings + id * 8, true), length = view.getUint32(strings + id * 8 + 4, true);
      if (at > stringLength || length > stringLength - at) fail("An animated artwork texture name is truncated.");
      const name = new TextDecoder("utf-8", { fatal: true }).decode(b.slice(stringOffset + at, stringOffset + at + length));
      if (!safe(name)) fail("An animated artwork texture references an unsafe path.");
      result.push(name);
    }
    return result;
  }
  function decoration(input, project, info) {
    const bytes = input instanceof Uint8Array ? input : new Uint8Array(input || []);
    if (!bytes.length || bytes.length > 131072) fail("The card decoration metadata is missing or too large.");
    let data;
    try { data = JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes)); }
    catch { fail("The card decoration metadata is damaged. Import the original artwork again."); }
    if (!data || Array.isArray(data) || !Number.isSafeInteger(data.card_id) || data.card_id < 1 || data.card_id > 2147483647 || !safe(data.shader_file) || !Array.isArray(data.parameters) || data.parameters.length > 128) fail("This card decoration format is not supported safely.");
    const ids = [...new Set([info.sourceId, info.bgSourceId, project.artBinding?.resourceId].filter(Boolean).map(id => String(id).padStart(7, "0")))];
    for (const parameter of data.parameters) {
      if (!parameter || typeof parameter.type !== "string" || typeof parameter.name !== "string") fail("A card decoration parameter is invalid.");
      if (parameter.type !== "sampler2D") continue;
      if (!safe(parameter.value)) fail("A card decoration texture path is invalid.");
      for (const id of ids) for (const kind of ["card", "card_bg"]) {
        const prefix = "character/" + kind + "/" + id + "/";
        if (parameter.value.startsWith(prefix)) {
          parameter.value = "character/" + kind + "/" + info.resourceId + "/" + parameter.value.slice(prefix.length).split("card_" + id).join("card_" + info.resourceId);
          break;
        }
      }
    }
    data.card_id = Number(project.targetId);
    return JSON.stringify(data);
  }
  async function plan(project, assets, { group, replacements: replacements2 = [], readAsset, storeDecoration, occupiedResourceIds = [] } = {}) {
    var _a;
    const before = fingerprint(project), info = inspect(project, assets, { group });
    if (!info.group) fail(info.groups.length ? "Choose which imported build supplies the source artwork." : "Import the source unit’s complete card, thumbnail and animated background resources first.");
    if (info.sourceId === info.resourceId) fail("Choose a custom unit ID with its own artwork namespace.");
    if (info.missing.length) fail("Import the missing source artwork: " + info.missing.join(", ") + ".");
    if (occupiedResourceIds.some((id) => resource(id) === info.resourceId)) fail("Another unit already uses this artwork namespace. Choose a different custom unit ID.");
    if (typeof readAsset !== "function") fail("The imported artwork reader is unavailable.");
    if (!Array.isArray(replacements2) || !replacements2.length) fail("Choose at least one artwork layer to replace.");
    const all = (assets || []).map(normalize), ownedKeys = new Set((project.assets || []).filter((a) => owned(a, project.artBinding)).map((a) => a.key)), targetStem = String(info.resourceId).padStart(7, "0");
    if (all.some((a) => !ownedKeys.has(a.key) && (a.path.startsWith("character/card/" + targetStem + "/") || a.path.startsWith("character/card_bg/" + targetStem + "/") || a.path === "character/thumb/card_" + targetStem + "_thumb.png" || a.path.startsWith("character/thumb/card_" + targetStem + "_thumb/")))) fail("Imported resources already use this custom artwork namespace.");
    for (const file of info.sourceAssets.filter((a) => a.path.endsWith(".lwf"))) {
      const directory = file.path.slice(0, file.path.lastIndexOf("/") + 1);
      for (const texture of lwfTextures(await readAsset(file.key))) if (!info.sourceAssets.some((a) => a.path === directory + texture)) fail("Import the complete animated artwork pack. Missing texture: " + texture);
    }
    const replacementKeys = /* @__PURE__ */ new Map();
    for (const replacement of replacements2) {
      const role = info.roles.find((r) => r.id === replacement.role);
      if (!role || replacementKeys.has(role.key)) fail("Choose each artwork layer once.");
      if (!safe(replacement.key) || !all.some((a2) => a2.key === replacement.key)) fail("Import the replacement PNG before applying game artwork.");
      const [source2, newImage] = await Promise.all([readAsset(role.key), readAsset(replacement.key)]), a = pngInfo(source2), b = pngInfo(newImage);
      if (a.width !== b.width || a.height !== b.height) fail(role.label + " needs " + a.width + " × " + a.height + " pixels. Fit the image before applying it.");
      replacementKeys.set(role.key, replacement.key);
    }
    const files = /* @__PURE__ */ new Map(), sourceMap = [], target = String(info.resourceId).padStart(7, "0"), source = String(info.sourceId).padStart(7, "0"), metadataKeys = new Map();
    for (const item of info.sourceAssets.filter(a => /\/card_[0-9]+_decoration_[0-9]+\.json$/.test(a.path))) {
      if (typeof storeDecoration !== "function") fail("Update the artwork storage bridge before exporting card decorations.");
      const text = decoration(await readAsset(item.key), project, info), stored = await storeDecoration(text);
      if (!stored || !safe(stored.key) || !stored.key.endsWith(".json")) fail("The updated card decoration could not be saved.");
      metadataKeys.set(item.key, stored.key);
    }
    function add(path, item) {
      if (!safe(path)) fail("Artwork has an unsafe output path.");
      const normalized = path.normalize("NFC").toLowerCase(), prior = files.get(normalized);
      const key = metadataKeys.get(item.key) || replacementKeys.get(item.key) || item.key;
      if (prior && prior.key !== key) fail("Two artwork files would use the same output path.");
      files.set(normalized, { key, path, owner: OWNER });
    }
    for (const item of info.sourceAssets) {
      let destination;
      if (item.path.startsWith(info.cardRoot)) destination = "character/card/" + target + "/" + item.path.slice(info.cardRoot.length);
      else if (item.path.startsWith(info.bgRoot)) destination = "character/card_bg/" + target + "/" + item.path.slice(info.bgRoot.length);
      else destination = "character/thumb/card_" + target + "_thumb/" + item.path.split("/").slice(-1)[0];
      sourceMap.push({ path: item.path, assetPath: destination });
      add(destination, item);
      const alias = destination.split("card_" + (item.path.startsWith(info.bgRoot) ? String(info.bgSourceId || info.sourceId).padStart(7, "0") : source)).join("card_" + target);
      add(alias, item);
      if (item.path === info.thumbFlat || item.path === info.thumbRoot + "card_" + source + "_thumb.png") add("character/thumb/card_" + target + "_thumb.png", item);
    }
    const existing = (project.assets || []).filter((a) => !owned(a, project.artBinding));
    for (const file of files.values()) if (existing.some((a) => a.path.normalize("NFC").toLowerCase() === file.path.normalize("NFC").toLowerCase())) fail("A patch attachment already uses an artwork output path.");
    if (before !== fingerprint(project)) fail("The unit changed while preparing its artwork. Apply the image again.");
    const output = [...files.values()], packedAssets = [];
    for (const [folder, container] of [["character/card/" + target + "/", "character/card/" + target + ".cpk"], ["character/card_bg/" + target + "/", "character/card_bg/" + target + ".cpk"], ["character/thumb/card_" + target + "_thumb/", "character/thumb/card_" + target + "_thumb.cpk"]]) {
      const entries = output.filter((a) => a.path.startsWith(folder)).map((a) => ({ path: a.path.slice(folder.length), assetPath: a.path }));
      if (entries.length) packedAssets.push({ path: container, entries, owner: OWNER });
    }
    for (const item of packedAssets) if ((project.packedAssets || []).some((a) => {
      var _a2, _b;
      return a.path === item.path && !(a.owner === OWNER && ((_b = (_a2 = project.artBinding) == null ? void 0 : _a2.packedPaths) == null ? void 0 : _b.includes(a.path)));
    })) fail("A patch archive already uses this artwork namespace.");
    const originalOverrides = ((_a = project.artBinding) == null ? void 0 : _a.originalOverrides) || Object.fromEntries(["resource_id", "bg_effect_id"].map((field) => {
      var _a2;
      return [field, { present: Object.prototype.hasOwnProperty.call(project.cardOverrides || {}, field), value: (_a2 = project.cardOverrides) == null ? void 0 : _a2[field] }];
    }));
    const portableReplacements = replacements2.map((ref) => ({ role: ref.role, assetPath: sourceMap.find((mapping) => mapping.path === info.roles.find((role) => role.id === ref.role).path).assetPath }));
    const result = { resourceId: info.resourceId, sourceId: info.sourceId, group: info.group, assets: output, packedAssets, cardOverrides: { resource_id: info.resourceId, ...info.bgSourceId ? { bg_effect_id: info.resourceId } : {} }, ownership: { format: 1, metadataVersion: 1, owner: OWNER, resourceId: info.resourceId, sourceId: info.sourceId, bgSourceId: info.bgSourceId, group: info.group, paths: output.map((a) => a.path), packedPaths: packedAssets.map((a) => a.path), sourceMap, replacements: portableReplacements, originalOverrides }, before };
    plans.add(result);
    return result;
  }
  function apply(project, result) {
    if (!plans.has(result) || fingerprint(project) !== result.before) fail("The unit changed before its artwork could be applied. Prepare the artwork again.");
    project.assets = [...(project.assets || []).filter((a) => !owned(a, project.artBinding)), ...clone(result.assets)];
    project.packedAssets = [...(project.packedAssets || []).filter((a) => {
      var _a, _b;
      return !(a.owner === OWNER && ((_b = (_a = project.artBinding) == null ? void 0 : _a.packedPaths) == null ? void 0 : _b.includes(a.path)));
    }), ...clone(result.packedAssets)];
    project.cardOverrides = { ...project.cardOverrides || {}, ...result.cardOverrides };
    project.artBinding = clone(result.ownership);
    plans.delete(result);
    return project;
  }
  async function repairMetadata(originalProject, { readAsset, storeDecoration } = {}) {
    const before = JSON.stringify(originalProject), project = clone(originalProject), createdAssets = [];
    let changed = false;
    try {
      for (const member of [project, ...(project.formProjects || [])]) {
        if (!member.artBinding || member.artBinding.metadataVersion === 1) continue;
        const info = original(member), rewritten = new Map();
        for (const asset of (member.assets || []).filter(a => owned(a, member.artBinding) && /\/card_[0-9]+_decoration_[0-9]+\.json$/.test(a.path))) {
          if (typeof readAsset !== "function" || typeof storeDecoration !== "function") fail("Update the artwork storage bridge before exporting this saved card.");
          if (!rewritten.has(asset.key)) {
            const text = decoration(await readAsset(asset.key), member, info), stored = await storeDecoration(text);
            if (!stored || !safe(stored.key) || !stored.key.endsWith(".json")) fail("The repaired card decoration could not be saved.");
            createdAssets.push(stored.key); rewritten.set(asset.key, stored.key);
          }
          asset.key = rewritten.get(asset.key);
        }
        member.artBinding.metadataVersion = 1;
        changed = true;
      }
      if (JSON.stringify(originalProject) !== before) fail("The unit changed while repairing its artwork. Export again.");
      return { project: changed ? project : originalProject, before, changed, createdAssets };
    } catch (error) { error.createdAssets = createdAssets.slice(); throw error; }
  }
  function restore(project) {
    var _a;
    const binding = project.artBinding;
    if (!binding) return project;
    const assets = (project.assets || []).filter((a) => !owned(a, binding)), packed = (project.packedAssets || []).filter((a) => {
      var _a2;
      return !(a.owner === OWNER && ((_a2 = binding.packedPaths) == null ? void 0 : _a2.includes(a.path)));
    }), overrides = { ...project.cardOverrides || {} };
    for (const field of ["resource_id", "bg_effect_id"]) if (overrides[field] === binding.resourceId || field === "bg_effect_id" && binding.staticBackground && overrides[field] === null) {
      const previous = ((_a = binding.originalOverrides) == null ? void 0 : _a[field]) || (field === "resource_id" ? binding.originalResource : null);
      if (previous == null ? void 0 : previous.present) overrides[field] = previous.value;
      else delete overrides[field];
    }
    if((project.assets||[]).some(a=>owned(a,binding)&&a.key===project.previewKey)){if(binding.previousPreviewKey)project.previewKey=binding.previousPreviewKey;else delete project.previewKey;}
    project.assets = assets;
    if (packed.length) project.packedAssets = packed;
    else delete project.packedAssets;
    project.cardOverrides = overrides;
    delete project.artBinding;
    return project;
  }
  return { inspect, plan, apply, restore, replacements, previewAssets, pngInfo, lwfTextures, decoration, repairMetadata };
});
