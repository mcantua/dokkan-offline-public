(function(root, factory) {
  if (typeof module === "object" && module.exports) module.exports = factory(require("./core"), require("./motion"));
  else root.ForgeMovieModel = factory(root.Forge, root.ForgeMotion);
})(typeof globalThis !== "undefined" ? globalThis : this, function(Forge, Motion) {
  "use strict";
  const OWNER = "forge-authored-movie", MAX_BYTES = 96 * 1024 * 1024, plans = /* @__PURE__ */ new WeakSet();
  const fail = (message) => {
    throw Error(message);
  }, copy = (value) => Forge.clone(value), fingerprint = (p) => JSON.stringify(p);
  function metadata(value) {
    var _a, _b;
    if (!value || !Number.isSafeInteger(value.width) || !Number.isSafeInteger(value.height) || value.width < 2 || value.height < 2 || value.width > 4096 || value.height > 4096 || value.width * value.height > 16 * 1024 * 1024 || !Number.isSafeInteger(value.frames) || value.frames < 1 || value.frames > 1e4 || !Number.isSafeInteger((_a = value.rate) == null ? void 0 : _a.n) || !Number.isSafeInteger((_b = value.rate) == null ? void 0 : _b.d) || value.rate.n < 1 || value.rate.d < 1 || value.rate.n > 2147483647 || value.rate.d > 2147483647) fail("This authored movie needs complete supported dimensions, frames and frame rate.");
    const fps = value.rate.n / value.rate.d, frames60 = Math.round(value.frames * 60 / fps);
    if (fps < 1 || fps > 120 || frames60 < 1 || frames60 > 10800) fail("Keep an authored movie within three minutes at a supported frame rate.");
    return { width: value.width, height: value.height, frames: value.frames, rate: { n: value.rate.n, d: value.rate.d }, preservedAudio: value.preservedAudio === true, frames60 };
  }
  function nameFor(p, slot, storageTag) {
    if (!Number.isSafeInteger(p.targetId) || p.targetId < 1 || p.targetId > 1999999e3 || !Number.isSafeInteger(slot) || slot < 0 || slot >= 48) fail("Choose a supported custom unit slot before attaching a movie.");
    if (typeof storageTag !== "string" || !/^[0-9a-f]{32}$/.test(storageTag)) fail("Store this movie again to reserve its immutable playback resource.");
    return "forge_movie_" + p.targetId + "_" + slot + "_" + storageTag;
  }
  function pathFor(name) {
    return "movie/ingame/battle/sp_effect/" + name + ".usm";
  }
  function bindings(p) {
    const value = p.movieBindings || [];
    if (!Array.isArray(value) || value.length > 48) fail("This project has an invalid authored-movie list.");
    return value;
  }
  function owned(p, binding) {
    const row = (p.tables.effect_packs || []).find((r) => r.id === binding.rowId), asset = (p.assets || []).find((a) => a.path === binding.path && a.owner === OWNER && a.movieKey === binding.key);
    if (!row || row.category !== 5 || row.pack_name !== nameFor(p, binding.slot, binding.storageTag) || binding.path !== pathFor(row.pack_name) || binding.privateUnitId !== p.targetId || !asset || !Forge.safePath(asset.key)) fail("This authored movie lost its owned resource. Reattach it before previewing or exporting.");
    return { row, asset };
  }
  function inspect(p) {
    return bindings(p).map((binding) => {
      const { row } = owned(p, binding);
      return { ...copy(binding), effectPackId: Number(p.targetId) + (p.tables.effect_packs || []).findIndex((r) => r.id === row.id) };
    });
  }
  function plan(p, { schema = p.schema, assetKey, size, metadata: info, storageTag, name = "My edited movie", key, occupiedPackNames = [] } = {}) {
    var _a;
    if (!Forge.safePath(assetKey) || !Number.isSafeInteger(size) || size <= 1e3 || size > MAX_BYTES) fail("Store a complete authored USM movie up to96MB before attaching it.");
    if (typeof name !== "string" || !name.trim() || name.length > 120 || /[\x00-\x1f]/.test(name)) fail("Give the movie a short readable name.");
    if (!Array.isArray(schema == null ? void 0 : schema.effect_packs) || !schema.effect_packs.length) fail("This game database does not support movie effect packs.");
    if (!Array.isArray(occupiedPackNames)) fail("Check the existing movie packs before attaching this movie.");
    const before = fingerprint(p), next = copy(p), list = bindings(next), existing = key ? list.find((b) => b.key === key) : null;
    if (key && !existing) fail("Choose an owned movie from this unit.");
    if (existing) owned(next, existing);
    const slot = (_a = existing == null ? void 0 : existing.slot) != null ? _a : Array.from({ length: 48 }, (_, i) => i).find((i) => !list.some((b) => b.slot === i));
    if (slot === void 0) fail("A unit can own up to48 movies.");
    const packName = nameFor(next, slot, storageTag), path = pathFor(packName);
    if (occupiedPackNames.includes(packName)) fail("Another game movie uses this resource name. Reserve another unit slot.");
    if ((next.assets || []).some((a) => a.path === path && a.movieKey !== (existing == null ? void 0 : existing.key)) || (next.generatedFiles || []).some((a) => a.path === path)) fail("Another attached resource uses this movie path.");
    const meta = metadata(info);
    if (existing && existing.storageTag === storageTag) {
      const oldAsset = owned(next, existing).asset;
      if (oldAsset.key !== assetKey || existing.size !== size || JSON.stringify(existing.metadata) !== JSON.stringify(meta)) fail("Store the changed movie as a new upload so the game cannot reuse an older cached version.");
    }
    next.tables.effect_packs = next.tables.effect_packs || [];
    next.schema.effect_packs = copy(schema.effect_packs);
    let row = existing && (next.tables.effect_packs || []).find((r) => r.id === existing.rowId);
    const movieKey = (existing == null ? void 0 : existing.key) || "movie-" + Math.random().toString(36).slice(2);
    if (!row) {
      row = Object.assign(Forge.rowDefault(schema.effect_packs), { id: Forge.localId(next, "effect_packs") });
      next.tables.effect_packs.push(row);
    }
    const date = (/* @__PURE__ */ new Date()).toISOString().slice(0, 19).replace("T", " ");
    Object.assign(row, { category: 5, name: name.trim(), pack_name: packName, scene_name: "ef_001", red: 255, green: 255, blue: 255, alpha: 255, lite_flicker_rate: 70, created_at: row.created_at || date, updated_at: date });
    const binding = { key: movieKey, rowId: row.id, slot, privateUnitId: next.targetId, storageTag, name: name.trim(), path, size, metadata: meta };
    next.assets = (next.assets || []).filter((a) => !(a.owner === OWNER && a.movieKey === movieKey));
    next.assets.push({ path, key: assetKey, owner: OWNER, movieKey });
    next.movieBindings = [...list.filter((b) => b.key !== movieKey), binding];
    const result = { before, project: next, key: movieKey };
    plans.add(result);
    return result;
  }
  function apply(p, prepared) {
    if (!plans.has(prepared) || fingerprint(p) !== prepared.before) fail("Your unit changed while its movie was prepared. Attach it again.");
    for (const key of Object.keys(p)) delete p[key];
    Object.assign(p, prepared.project);
    plans.delete(prepared);
    return prepared.key;
  }
  function makeClip(p, key) {
    const binding = bindings(p).find((b) => b.key === key);
    if (!binding) fail("Choose a movie owned by this unit.");
    owned(p, binding);
    const info = metadata(binding.metadata), index = p.tables.effect_packs.findIndex((r) => r.id === binding.rowId), id = Number(p.targetId) + index;
    if (id > 2147483647) fail("The authored movie effect pack is outside the native ID range.");
    const clip = Motion.createClip({ path: "ab_script/forge_movie/" + binding.key + ".lua", label: binding.name, movieBindingKey: key, movieEffectPackId: id, movieFrames60: info.frames60, text: "-- Authored movie; its game profile supplies the gameplay action.\nsetupMovie(0," + id + ",0,1);\nendPhase(" + info.frames60 + ");" });
    clip.to = info.frames60 / 60;
    clip.report.frames = info.frames60;
    return clip;
  }
  function refreshClips(p, clips) {
    return clips.map((clip) => {
      var _a, _b;
      if(clip.source?.sequenceMovieBindings){
        const replacement=copy(clip);
        for(const item of replacement.source.sequenceMovieBindings){const binding=inspect(p).find(b=>b.key===item.key);if(!binding||!/^__forge_sequence_movie_[0-7]$/.test(item.variable))fail('This movie cut lost its resource. Make the cut again.');replacement.source.text=replacement.source.text.replace(new RegExp('local '+item.variable+'=\\d+'), 'local '+item.variable+'='+binding.effectPackId);}
        return replacement;
      }
      const key = (_a = clip.source) == null ? void 0 : _a.movieBindingKey;
      if (!key) return copy(clip);
      const replacement = makeClip(p, key), wasFull = Math.abs(Number(clip.to) - Number((_b = clip.report) == null ? void 0 : _b.frames) / 60) < 1e-5;
      if (clip.from !== 0) fail("Use an authored movie from its beginning or trim it in the movie editor.");
      const to = wasFull ? replacement.to : Number(clip.to);
      if (to > replacement.to + 1e-5) fail("This movie became shorter. Choose its new ending before applying the sequence.");
      return { ...copy(clip), source: replacement.source, label: replacement.label, report: replacement.report, to };
    });
  }
  function copyClips(source, destination, clips) {
    const result=copy(clips), keys=new Set(), mapped=new Map();
    for(const c of result){if(c.source?.movieBindingKey)keys.add(c.source.movieBindingKey);for(const b of c.source?.sequenceMovieBindings||[])keys.add(b.key);if(c.source?.sequenceOriginalSource?.movieBindingKey)keys.add(c.source.sequenceOriginalSource.movieBindingKey);}
    for(const key of keys){
      const original=bindings(source).find(b=>b.key===key);if(!original)fail('The animation lost its original movie.');const {asset}=owned(source,original),origin=source.key+':'+key+':'+original.storageTag;
      let target=bindings(destination).find(b=>b.sequenceOrigin===origin);
      if(!target){const prepared=plan(destination,{schema:{...destination.schema,effect_packs:destination.schema.effect_packs?.length?destination.schema.effect_packs:source.schema.effect_packs},assetKey:asset.key,size:original.size,metadata:original.metadata,storageTag:original.storageTag,name:original.name}),newKey=apply(destination,prepared);target=bindings(destination).find(b=>b.key===newKey);target.sequenceOrigin=origin;}
      mapped.set(key,target.key);
    }
    for(const c of result){if(mapped.has(c.source?.movieBindingKey))c.source.movieBindingKey=mapped.get(c.source.movieBindingKey);for(const b of c.source?.sequenceMovieBindings||[])b.key=mapped.get(b.key)||b.key;if(c.source?.sequenceOriginalSource?.movieBindingKey){const original=makeClip(destination,mapped.get(c.source.sequenceOriginalSource.movieBindingKey));c.source.sequenceOriginalSource=original.source;}}
    return refreshClips(destination,result);
  }
  function rebase(p, { buildDodge } = {}) {
    var _a, _b;
    const next = copy(p);
    for (const binding of bindings(next)) {
      const row = (next.tables.effect_packs || []).find((r) => r.id === binding.rowId), asset = (next.assets || []).find((a) => a.path === binding.path && a.owner === OWNER && a.movieKey === binding.key);
      if (!row || !asset) fail("An authored movie lost its owned resource.");
      const packName = nameFor(next, binding.slot, binding.storageTag), path = pathFor(packName);
      if ((next.assets || []).some((a) => a !== asset && a.path === path)) fail("A different resource uses this movie’s new path.");
      row.pack_name = packName;
      asset.path = path;
      binding.path = path;
      binding.privateUnitId = next.targetId;
    }
    if (Array.isArray((_a = next.animationStudio) == null ? void 0 : _a.clips)) next.animationStudio.clips = refreshClips(next, next.animationStudio.clips);
    const dodge = (_b = next.actionHooks) == null ? void 0 : _b.dodge;
    if (dodge && (dodge.clips || []).some((c) => {
      var _a2;
      return (_a2 = c.source) == null ? void 0 : _a2.movieBindingKey;
    })) {
      if (typeof buildDodge !== "function") fail("Rebuild the unit’s dodge dispatcher while reserving its authored movies.");
      dodge.clips = refreshClips(next, dodge.clips);
      const file = buildDodge([next]);
      if (!file || file.owner !== "dodge:unit" || file.path !== "lua/ab_script/ab_sys/dg0001.lua" || typeof file.text !== "string") fail("The authored-movie dodge dispatcher could not be rebuilt.");
      next.generatedFiles = (next.generatedFiles || []).filter((f) => f.owner !== "dodge:unit");
      next.generatedFiles.push(file);
    }
    for (const key of Object.keys(p)) delete p[key];
    Object.assign(p, next);
    return p;
  }
  function previewRows(p) {
    return inspect(p).map((binding) => {
      const row = (p.tables.effect_packs || []).find((r) => r.id === binding.rowId);
      return { id: binding.effectPackId, category: row.category, name: row.name, pack_name: row.pack_name, scene_name: row.scene_name, red: row.red, green: row.green, blue: row.blue, alpha: row.alpha, lite_flicker_rate: row.lite_flicker_rate };
    });
  }
  function previewAssets(p) {
    return bindings(p).map((binding) => {
      const { asset } = owned(p, binding);
      return { path: binding.path, key: asset.key };
    });
  }
  function remove(p, key) {
    var _a, _b, _c;
    const binding = bindings(p).find((b) => b.key === key);
    if (!binding) return false;
    if ([...Object.values(p.animationAssignments || {}).flatMap((a) => a.clips || []), ...((_a = p.animationStudio) == null ? void 0 : _a.clips) || [], ...((_c = (_b = p.actionHooks) == null ? void 0 : _b.dodge) == null ? void 0 : _c.clips) || []].some((c) => {
      var _a2;
      return ((_a2 = c.source) == null ? void 0 : _a2.movieBindingKey) === key;
    })) fail("Remove this movie from its assigned sequences, Studio draft and dodge animation before deleting it.");
    owned(p, binding);
    p.assets = (p.assets || []).filter((a) => !(a.owner === OWNER && a.movieKey === key));
    p.tables.effect_packs = p.tables.effect_packs.filter((r) => r.id !== binding.rowId);
    p.movieBindings = p.movieBindings.filter((b) => b.key !== key);
    return true;
  }
  return { copyClips, OWNER, MAX_BYTES, metadata, inspect, plan, apply, makeClip, refreshClips, rebase, previewRows, previewAssets, remove };
});
