export const ITEM_LWF = "outgame/effect/anim_160000/anim_160000.lwf";
const ITEM_BASE = "/assets/outgame/effect/anim_160000/";
const FRAME_NAMES = ["bronze", "silver", "gold", "rainbow", "superoptimal"];
export function normalizeTraining(request) {
  if (!request || !["training", "awakening"].includes(request.mode)) return null;
  const folder = request.mode === "training" ? "training" : "awaken";
  if (typeof request.path !== "string" || !new RegExp("^ab_script/" + folder + "/a[0-9]{4}\\.lua$").test(request.path)) throw Error("Choose a matching training or awakening scene.");
  if (!Array.isArray(request.trainingItems) || request.trainingItems.length > 5) throw Error("Choose up to five item types for this scene.");
  const items = request.trainingItems.map((item) => {
    if (!item || !Number.isSafeInteger(item.id) || item.id < 1 || item.id > 9999999 || !Number.isInteger(item.rarity) || item.rarity < 0 || item.rarity > 4) throw Error("An item choice is invalid. Select it again from the item list.");
    return { id: item.id, rarity: item.rarity };
  });
  return { mode: request.mode, path: request.path, items };
}
export function itemTexture(mode, item) {
  const id = String(item.id);
  if (mode === "training") return "/assets/item/training_item/thumb_training_items_" + id.padStart(7, "0") + ".png";
  if (mode !== "awakening") throw Error("Unknown item scene.");
  const name = "thumb_awaken_items_" + id.padStart(5, "0");
  return "/assets/item/awaken/en/thumb/" + name + "/" + name + ".png";
}
export function frameTexture(rarity) {
  return "/assets/layout/en/image/item/awaken/awaken_thumb_bg/thumb_awaken_" + FRAME_NAMES[rarity] + ".png";
}
function integer(value, name, min, max) {
  const n = Math.trunc(Number(value) || 0);
  if (n < min || n > max) throw Error("Invalid " + name + " in this item scene.");
  return n;
}
export function planTrainingItems(context, kind, frame, interval, attr, phase, nextId) {
  if (!context || context.mode !== kind) throw Error("This command needs its matching item scene.");
  frame = integer(frame, "start time", 0, 1e6);
  interval = integer(interval, "item interval", 0, 1e6);
  attr = integer(attr, "draw flags", -2147483648, 4294967295);
  return context.items.map((item, index) => ({ type: "forgeTrainingItem", kind, frame: frame + interval * index, phase: phase || 0, attr: (attr | 1) >>> 0, workId: nextId(), scene: "ef_" + String((kind === "awakening" ? 11 : 1) + index).padStart(3, "0"), texture: itemTexture(kind, item), frameTexture: kind === "awakening" ? frameTexture(item.rarity) : null, itemId: item.id, life: -1, lifeLimited: false }));
}
export function installTrainingBinders(host, bank, nextId, num, request = globalThis.__forgeAnimation) {
  const context = normalizeTraining(request);
  if (!context) return;
  for (const [name, kind] of [["entryEffectTraining", "training"], ["entryEffectAwaken", "awakening"]]) host.register(name, (L) => {
    const commands = planTrainingItems(context, kind, num(L, 1), num(L, 2), num(L, 3), bank.phase, nextId);
    bank.commands.push(...commands);
    return commands.length;
  });
}
export function sceneTextureDependencies(input, scene) {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input);
  const fail = () => {
    throw Error("This item animation uses a newer or invalid visual format. Update Dokkan Unit Creator to preview it.");
  };
  if (bytes.length < 332 || bytes.length > 4 * 1024 * 1024 || bytes[0] !== 76 || bytes[1] !== 87 || bytes[2] !== 70 || bytes[4] !== 20 || bytes[5] !== 18 || bytes[6] !== 17 || bytes[7] !== 0) fail();
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength), word = (at) => {
    if (at < 0 || at + 4 > bytes.length) fail();
    return view.getUint32(at, true);
  };
  const table = (header, stride, cap) => {
    const start = word(header), count = word(header + 4);
    if (start < 332 || count > cap || start + count * stride > bytes.length) fail();
    return { count, at: (index) => {
      if (!Number.isInteger(index) || index < 0 || index >= count) fail();
      return start + index * stride;
    } };
  };
  const strings = table(320, 8, 16384), stringStart = word(32), stringLength = word(36);
  if (stringStart < 332 || stringLength > 1024 * 1024 || stringStart + stringLength > bytes.length) fail();
  const string = (id) => {
    const at = strings.at(id), offset = word(at), length = word(at + 4);
    if (offset + length > stringLength || length > 500) fail();
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes.subarray(stringStart + offset, stringStart + offset + length));
  };
  const links = table(312, 8, 4096), movies = table(304, 28, 4096), frames = table(288, 8, 2e5), controls = table(280, 8, 3e5), places = table(240, 16, 16384), objects = table(88, 8, 16384), bitmaps = table(112, 8, 16384), fragments = table(104, 44, 16384), textures = table(96, 20, 1024);
  let root = -1;
  for (let i = 0; i < links.count; i++) {
    const at = links.at(i);
    if (string(word(at)) === scene) {
      if (root !== -1) fail();
      root = word(at + 4);
    }
  }
  if (root < 0) fail();
  const used = /* @__PURE__ */ new Set(), visited = /* @__PURE__ */ new Set(), queue = [root];
  let examined = 0;
  while (queue.length) {
    const id = queue.pop();
    if (visited.has(id)) continue;
    visited.add(id);
    const movie = movies.at(id), begin = word(movie + 12), count = word(movie + 16);
    if (count > frames.count || begin + count > frames.count) fail();
    for (let frame = begin; frame < begin + count; frame++) {
      const f = frames.at(frame), cb = word(f), cn = word(f + 4);
      if (cb + cn > controls.count || cn > 16384) fail();
      for (let index = cb; index < cb + cn; index++) {
        if (++examined > 1e6) fail();
        const c = controls.at(index), type = word(c), ref = word(c + 4);
        let place;
        if (type === 0) place = ref;
        else if (type === 4) continue;
        else if (type >= 1 && type <= 3) place = word(table([0, 248, 256, 264][type], [0, 8, 8, 12][type], 1e5).at(ref));
        else if (type === 5) place = word(table(272, 16, 1e5).at(ref));
        else fail();
        const object = objects.at(word(places.at(place) + 4)), kind = word(object), value = word(object + 4);
        if (kind === 2) {
          queue.push(value);
          continue;
        }
        if (kind !== 3) fail();
        const fragment = fragments.at(word(bitmaps.at(value) + 4)), texture = textures.at(word(fragment + 4));
        const name = string(word(texture));
        if (!/^[A-Za-z0-9_.-]+\.(?:png|jpe?g)$/i.test(name)) fail();
        used.add(name);
      }
    }
  }
  return [...used].sort();
}
async function readItemLwf() {
  var _a;
  const response = await fetch("/assets/" + ITEM_LWF);
  if (!response.ok) throw Error("The item-screen visual resource is unavailable. Import its game assets and try again.");
  const limit = 4 * 1024 * 1024;
  if (Number(response.headers.get("content-length")) > limit) throw Error("The item-screen visual resource exceeds its supported size.");
  if (!((_a = response.body) == null ? void 0 : _a.getReader)) {
    const b = new Uint8Array(await response.arrayBuffer());
    if (b.length > limit) throw Error("The item-screen visual resource exceeds its supported size.");
    return b;
  }
  const reader = response.body.getReader(), parts = [];
  let total = 0;
  try {
    for (; ; ) {
      const part = await reader.read();
      if (part.done) break;
      total += part.value.length;
      if (total > limit) {
        await reader.cancel();
        throw Error("The item-screen visual resource exceeds its supported size.");
      }
      parts.push(part.value);
    }
  } finally {
    reader.releaseLock();
  }
  const bytes = new Uint8Array(total);
  let at = 0;
  for (const part of parts) {
    bytes.set(part, at);
    at += part.length;
  }
  return bytes;
}
export async function prepareTrainingItems(runner, makeCardTextureImageMapAsync) {
  const commands = runner.commands.filter((c) => c.type === "forgeTrainingItem");
  runner._forgeTrainingPrepared = /* @__PURE__ */ new Map();
  if (!commands.length) return;
  const bytes = await readItemLwf();
  for (const cmd of commands) {
    const dependencies = new Set(sceneTextureDependencies(bytes, cmd.scene));
    const map = (name) => {
      const clean = String(name).replace(/^\.\//, "");
      if (!dependencies.has(clean)) return ITEM_BASE + "Images_empty.png";
      if (clean === "Images_k_kyouka_item_dummy.png" || clean === "thumb_awaken_items.png") return cmd.texture;
      if (clean === "thumb_awaken_frame.png" && cmd.frameTexture) return cmd.frameTexture;
      return ITEM_BASE + clean;
    };
    const player = await runner.lwf.addEffect({ lwfUrl: "/assets/" + ITEM_LWF, baseUrl: ITEM_BASE, sceneName: cmd.scene, zIndex: 200, instanceKey: cmd.workId + "_forge_item", imageMap: map, startPhase: cmd.phase, startFrame: cmd.frame, life: -1, lifeLimited: false, disposeOnEnd: true, attr: cmd.attr, dormant: true });
    if (player.wrap) {
      player.wrap.dataset.forgeItem = String(cmd.itemId);
      player.wrap.dataset.forgeItemScene = cmd.scene;
    }
    runner._forgeTrainingPrepared.set(cmd.workId, player);
    runner.log("Item scene prepared · " + cmd.kind + " item " + cmd.itemId + " · " + cmd.scene + " @f" + cmd.frame);
  }
}
export function activateTrainingItem(runner, cmd) {
  var _a;
  const player = (_a = runner._forgeTrainingPrepared) == null ? void 0 : _a.get(cmd.workId);
  if (!(player == null ? void 0 : player.lwf)) throw Error("This item scene did not finish preparing.");
  player.startFrame = cmd.frame;
  player.disposeOnEnd = true;
  player.life = -1;
  player.lifeLimited = false;
  player.followParent = false;
  player.followScaleZ = false;
  runner.lwf.activatePlayer(player);
  runner.log("Item scene · " + cmd.kind + " item " + cmd.itemId + " · " + cmd.scene + " @f" + cmd.frame);
}
