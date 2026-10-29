(function(root, factory) {
  "use strict";
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else api.install(root);
})(typeof window === "object" ? window : globalThis, function() {
  "use strict";
  const MAX_BYTES = 16 * 1024 * 1024, MAX_PIXELS = 16 * 1024 * 1024;
  const PUBLIC_EFFECT = { path: "outgame/effect/anim_50000/en/anim_50000.lwf", bytes: 232304, sha256: "5f1334aaa5ecacd0ebf150c40047a0c06e8157f752712ac282dec118c00646c5", scenes: { 31011: "ef_012", 31012: "ef_013" } };
  const PUBLIC_TEXTURE_ALIASES = Object.freeze({ "ingame/battle/sp_effect/sp_effect_a1_00176/en/Images_card_4017640_sp02_phrase01.png": { "path": "ingame/battle/sp_effect/sp_effect_a1_00176/en/images_card_4017640_sp02_phrase01.png", "bytes": 20453, "sha256": "79ff28eb37fe83899c2bffc17ee9d6aea389fec731417208f0fabcef70009a00" }, "ingame/battle/sp_effect/sp_effect_a1_00176/en/Images_card_4017640_sp02_phrase02.png": { "path": "ingame/battle/sp_effect/sp_effect_a1_00176/en/images_card_4017640_sp02_phrase02.png", "bytes": 16588, "sha256": "2743091baefb701eb90f99d335fae5e96826e9bb0e7d00b28c371ed2107e598e" }, "ingame/battle/sp_effect/sp_effect_a1_00176/en/Images_txt_bou.png": { "path": "ingame/battle/sp_effect/sp_effect_a1_00176/en/images_txt_bou.png", "bytes": 10871, "sha256": "35411379e9a8e59fe0111c9e3ac0466f439e6e419f91a26fefeb67432517f02e" }, "ingame/battle/sp_effect/sp_effect_a1_00176/en/Images_txt_dou.png": { "path": "ingame/battle/sp_effect/sp_effect_a1_00176/en/images_txt_dou.png", "bytes": 23594, "sha256": "ac37c1d1e411c114345e649bf561549d1030da48cbb210153886a12dc5d1b7b8" }, "ingame/battle/sp_effect/sp_effect_a1_00176/en/Images_txt_zu.png": { "path": "ingame/battle/sp_effect/sp_effect_a1_00176/en/images_txt_zu.png", "bytes": 18186, "sha256": "b9476c59bcd2e17b4e86be579be8b4bf37c680e3e26d72ba920b160aae2c57db" }, "ingame/battle/sp_effect/sp_effect_a1_00176/en/Images_txt_zua.png": { "path": "ingame/battle/sp_effect/sp_effect_a1_00176/en/images_txt_zua.png", "bytes": 21649, "sha256": "9bfd7eefecc78a5e201dc79739414527dc18b79f48e88f0fa10157141562f3ef" }, "ingame/battle/sp_effect/sp_effect_a1_00176/en/Images_txt_zuoo.png": { "path": "ingame/battle/sp_effect/sp_effect_a1_00176/en/images_txt_zuoo.png", "bytes": 18067, "sha256": "21530aa46050d6c16d6a88174da0f9eaee8798b54492914bcff4cb6f47d48a9d" }, "ingame/battle/sp_effect/sp_effect_a1_00256/en/Images_txt_zua.png": { "path": "ingame/battle/sp_effect/sp_effect_a1_00256/en/images_txt_zua.png", "bytes": 6326, "sha256": "18730e00596119a72de8f78847276287f8be37b146eb94f713fc6abd98a194c4" } });
  function textureCaseAlias(url) {
    if (!url || url.searchParams.has("patch")) return null;
    const match = /^\/(assets|cdn\/uncompressed)\/(.+)$/.exec(url.pathname);
    return match && Object.prototype.hasOwnProperty.call(PUBLIC_TEXTURE_ALIASES, match[2]) ? { ...PUBLIC_TEXTURE_ALIASES[match[2]], prefix: "/" + match[1] + "/" } : null;
  }
  const timelineCache = /* @__PURE__ */ new WeakMap(), lastTimelineFrame = /* @__PURE__ */ new WeakMap();
  function descendant(node, parent) {
    for (let depth = 0; node && depth <= 32; depth++, node = node.parent) if (node === parent) return true;
    return false;
  }
  function primaryTimeline(player) {
    var _a, _b;
    const movie = player == null ? void 0 : player.movie;
    if (!movie || Number(movie.totalFrames) > 1) return movie;
    const cached = timelineCache.get(movie);
    if (cached && cached.lwf === player.lwf && descendant(cached, movie)) return cached;
    let primary = movie;
    (_b = (_a = player.lwf) == null ? void 0 : _a.inspect) == null ? void 0 : _b.call(_a, (object) => {
      if ((object == null ? void 0 : object.isMovie) && descendant(object, movie) && Number(object.totalFrames) > Number(primary.totalFrames)) primary = object;
    });
    if (primary !== movie) timelineCache.set(movie, primary);
    return primary;
  }
  function timelineState(player) {
    var _a;
    const timeline = primaryTimeline(player);
    return { current: Math.max(0, Number(timeline == null ? void 0 : timeline.currentFrame) || 0), total: Math.max(0, Number(timeline == null ? void 0 : timeline.totalFrames) || 0), name: (player == null ? void 0 : player.clip) || "", fps: ((_a = player == null ? void 0 : player.fps) == null ? void 0 : _a.call(player)) || 30 };
  }
  function seekNestedFrame(player, frame) {
    const primary = primaryTimeline(player);
    if (!primary || primary === player.movie || Number(primary.totalFrames) <= 1) return null;
    const next = Math.max(1, Math.min(Number(primary.totalFrames), Math.round(Number(frame) || 1)));
    if (next > 1e4) throw Error("This nested timeline exceeds the 10,000-frame interactive seeking limit.");
    const current = timelineState(player).current;
    player.pause();
    let start = current;
    if (next < current) {
      if (!player.setMovie(player.clip, { play: false })) throw Error("The selected animation could not be rewound");
      start = timelineState(player).current;
    }
    player.movie.playing = false;
    if (player.lwf.rootMovie) player.lwf.rootMovie.playing = true;
    for (let i = start; i < next; i++) {
      if (player.lwf.forceExec) player.lwf.forceExec();
      else player.lwf.exec(0);
    }
    player.movie.playing = false;
    player.playing = false;
    player.lwf.render();
    return player._emitFrame();
  }
  function checkNestedEnd(player) {
    var _a, _b;
    const primary = primaryTimeline(player);
    if (!primary || primary === player.movie || Number(primary.totalFrames) <= 1) return false;
    if (player._advancing) return true;
    const state = timelineState(player), previous = lastTimelineFrame.get(player), wrapped = (previous == null ? void 0 : previous.movie) === player.movie && previous.current > state.current;
    lastTimelineFrame.set(player, { movie: player.movie, current: state.current });
    if (state.current < state.total && !wrapped) return true;
    if (player.autoProgress) {
      player._advancing = true;
      player.pause();
      try {
        (_a = player.onEnded) == null ? void 0 : _a.call(player, "auto");
      } finally {
        player._advancing = false;
      }
      return true;
    }
    if (player.loopMovie) {
      seekNestedFrame(player, 1);
      player.play();
      return true;
    }
    seekNestedFrame(player, state.total);
    (_b = player.onEnded) == null ? void 0 : _b.call(player, "stop");
    return true;
  }
  function knownPublicEffect(metadata, id) {
    var _a;
    return typeof PUBLIC_EFFECT.scenes[id] === "string" && !!metadata && metadata.found === true && Number(metadata.id) === Number(id) && Number(metadata.category) === 3 && metadata.pack_name === "anim_50000" && metadata.scene_name === PUBLIC_EFFECT.scenes[id] && !((_a = metadata.lwf) == null ? void 0 : _a.url);
  }
  function dimensions(bytes) {
    if (bytes.byteLength < 24) throw Error("Imported text image is truncated");
    const b = new Uint8Array(bytes), signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (signature.some((n, i) => b[i] !== n) || String.fromCharCode(...b.slice(12, 16)) !== "IHDR") throw Error("Imported text image must be PNG");
    const d = new DataView(bytes), width = d.getUint32(16), height = d.getUint32(20);
    if (width < 1 || height < 1 || width > 4096 || height > 4096 || width * height > MAX_PIXELS) throw Error("Imported text image dimensions exceed the preview limit");
    return { width, height };
  }
  function plan(sourceWidth, sourceHeight, width, height) {
    if (![sourceWidth, sourceHeight, width, height].every(Number.isInteger) || Math.min(sourceWidth, sourceHeight, width, height) < 1 || width > 2048 || height > 2048 || width * height > 4 * 1024 * 1024) throw Error("Invalid text fitting dimensions");
    const scale = Math.min(width / sourceWidth, height / sourceHeight), w = sourceWidth * scale, h = sourceHeight * scale;
    return { x: (width - w) / 2, y: (height - h) / 2, width: w, height: h };
  }
  function address(value, base) {
    try {
      return new URL(typeof value === "string" ? value : value.url, base);
    } catch {
      return null;
    }
  }
  function fitRoute(url) {
    if (!url || url.searchParams.has("patch")) return null;
    const m = /^\/api\/card\/([1-9][0-9]{0,14})\/fit\/(sp_name|sp_phrase)\.png$/.exec(url.pathname);
    if (!m) return null;
    const width = Number(url.searchParams.get("w") || 1024), height = Number(url.searchParams.get("h") || (m[2] === "sp_name" ? 256 : 512));
    try {
      plan(1, 1, width, height);
    } catch {
      return null;
    }
    return { id: m[1], kind: m[2], width, height };
  }
  async function boundedBytes(response) {
    var _a;
    const length = Number(response.headers.get("Content-Length"));
    if (length > MAX_BYTES) throw Error("Imported text image exceeds the preview limit");
    if (!((_a = response.body) == null ? void 0 : _a.getReader)) {
      const bytes = await response.arrayBuffer();
      if (bytes.byteLength > MAX_BYTES) throw Error("Imported text image exceeds the preview limit");
      return bytes;
    }
    const reader = response.body.getReader(), parts = [];
    let size = 0;
    try {
      while (true) {
        const next = await reader.read();
        if (next.done) break;
        size += next.value.byteLength;
        if (size > MAX_BYTES) throw Error("Imported text image exceeds the preview limit");
        parts.push(next.value);
      }
    } finally {
      await reader.cancel().catch(() => {
      });
    }
    const result = new Uint8Array(size);
    let offset = 0;
    for (const part of parts) {
      result.set(part, offset);
      offset += part.byteLength;
    }
    return result.buffer;
  }
  async function recoverTextureCase(root, fetchRaw, url, alias, init, originalResponse) {
    var _a, _b;
    if (!((_a = root.crypto) == null ? void 0 : _a.subtle)) return originalResponse;
    try {
      const response = await fetchRaw(alias.prefix + alias.path + url.search, init);
      if (!response.ok) return originalResponse;
      const bytes = await boundedBytes(response);
      if (bytes.byteLength !== alias.bytes) return originalResponse;
      dimensions(bytes);
      const hash = [...new Uint8Array(await root.crypto.subtle.digest("SHA-256", bytes))].map((n) => n.toString(16).padStart(2, "0")).join("");
      if (hash !== alias.sha256) return originalResponse;
      return new Response(bytes, { headers: { "Content-Type": "image/png", "Cache-Control": "no-store", "X-Forge-Verified-Texture": "sha256:" + hash } });
    } catch (error) {
      if ((_b = init == null ? void 0 : init.signal) == null ? void 0 : _b.aborted) throw error;
      return originalResponse;
    }
  }
  async function fitted(root, fetchRaw, url, fit, init) {
    const response = await fetchRaw(url, init);
    if (!response.ok) return response;
    const bytes = await boundedBytes(response), source = dimensions(bytes), blob = new Blob([bytes], { type: "image/png" });
    if (source.width === fit.width && source.height === fit.height) return new Response(blob, { headers: { "Content-Type": "image/png", "Cache-Control": "no-store" } });
    const image = new root.Image(), objectURL = root.URL.createObjectURL(blob);
    try {
      await new Promise((resolve, reject) => {
        image.onload = resolve;
        image.onerror = () => reject(Error("Imported text image could not be decoded"));
        image.src = objectURL;
      });
      const canvas = root.document.createElement("canvas");
      canvas.width = fit.width;
      canvas.height = fit.height;
      const context = canvas.getContext("2d");
      if (!context) throw Error("PNG fitting is unavailable in this WebView");
      const target = plan(source.width, source.height, fit.width, fit.height);
      context.drawImage(image, target.x, target.y, target.width, target.height);
      const output = await new Promise((resolve) => canvas.toBlob(resolve, "image/png"));
      if (!output) throw Error("PNG fitting could not finish");
      return new Response(output, { headers: { "Content-Type": "image/png", "Cache-Control": "no-store" } });
    } finally {
      root.URL.revokeObjectURL(objectURL);
    }
  }
  function appearance(value) {
    if (!value || typeof value !== "object") return null;
    const { actorId, artCardId } = value;
    if (!Number.isSafeInteger(actorId) || !Number.isSafeInteger(artCardId) || actorId < 1 || artCardId < 1 || actorId === artCardId) return null;
    return { actorId, artCardId };
  }
  function appearanceCard(actor, art, selection) {
    var _a, _b, _c;
    if (!actor || actor.found !== true || Number(actor.id) !== selection.actorId) throw Error("The original battle character is unavailable.");
    if (!art || art.found !== true || Number(art.id) !== selection.artCardId || !Number.isSafeInteger(Number(art.art_id)) || Number(art.art_id) < 1) throw Error("The selected card artwork is unavailable. Download or import its assets before previewing.");
    const textures = art.textures && typeof art.textures === "object" ? art.textures : {};
    if (!Object.values(textures).some((texture) => typeof (texture == null ? void 0 : texture.url) === "string" && texture.url) || !(art.card_bg == null || typeof art.card_bg === "object")) throw Error("The selected card artwork has no available textures. Download or import its assets before previewing.");
    return { ...actor, art_id: art.art_id, resource_id: (_a = art.resource_id) != null ? _a : null, bg_effect_id: (_b = art.bg_effect_id) != null ? _b : null, textures: { ...textures }, card_bg: (_c = art.card_bg) != null ? _c : null, forge_local: actor.forge_local === true || art.forge_local === true, forge_appearance: { actorId: selection.actorId, artCardId: selection.artCardId } };
  }
  async function readPublicCard(fetchRaw, input, init) {
    var _a;
    const signal = (init == null ? void 0 : init.signal) || (typeof input === "object" ? input.signal : null);
    for (let attempt = 0; ; attempt++) {
      if (signal == null ? void 0 : signal.aborted) throw signal.reason || new DOMException("Preview closed", "AbortError");
      const response = await fetchRaw(input, init);
      if (attempt >= 2 || ![502, 503, 504].includes(response.status)) return response;
      await ((_a = response.body) == null ? void 0 : _a.cancel().catch(() => {
      }));
      await new Promise((resolve, reject) => {
        let timer;
        const aborted = () => {
          clearTimeout(timer);
          signal == null ? void 0 : signal.removeEventListener("abort", aborted);
          reject(signal.reason || new DOMException("Preview closed", "AbortError"));
        };
        timer = setTimeout(() => {
          signal == null ? void 0 : signal.removeEventListener("abort", aborted);
          resolve();
        }, attempt === 0 ? 250 : 750);
        signal == null ? void 0 : signal.addEventListener("abort", aborted, { once: true });
        if (signal == null ? void 0 : signal.aborted) aborted();
      });
    }
  }
  function install(root) {
    var _a, _b;
    if (root.__forgeImportedPreviewInstalled || typeof root.fetch !== "function") return;
    const location = root.location, local = (location == null ? void 0 : location.protocol) === "http:" && location.hostname === "127.0.0.1" && ((_a = root.__forgeAnimation) == null ? void 0 : _a.localPreview) === true;
    if (!local && !(((location == null ? void 0 : location.protocol) === "https:" || (location == null ? void 0 : location.protocol) === "forge-preview:") && location.hostname === "dokkan-eclipse.com")) return;
    if (!/^\/tools\/(lua|lwf)-player\//.test(location.pathname)) return;
    if (((_b = root.__forgeAnimation) == null ? void 0 : _b.path) === "ab_script/attack_sp/sp2516.lua") import(new URL("/_forge/media/preview-official-revision.js", location.href).href).then((module2) => module2.mountOfficialRevision(root)).catch(() => {
      var _a2, _b2;
      (_b2 = (_a2 = root.console) == null ? void 0 : _a2.warn) == null ? void 0 : _b2.call(_a2, "The optional official revision preview could not load. Selected assets were preserved.");
    });
    root.__forgeImportedPreviewInstalled = true;
    root.ForgeLwfTimeline = { state: timelineState, seek: seekNestedFrame, checkEnd: checkNestedEnd, appearance, appearanceCard };
    const original = root.fetch.bind(root), cards = /* @__PURE__ */ new Map();
    let publicEffect;
    const verifiedEffect = async () => {
      var _a2;
      if (!((_a2 = root.crypto) == null ? void 0 : _a2.subtle)) return null;
      if (!publicEffect) publicEffect = (async () => {
        const response = await original("/cdn/uncompressed/" + PUBLIC_EFFECT.path);
        if (!response.ok) throw Error("The original aura resource is unavailable");
        const bytes = await boundedBytes(response);
        if (bytes.byteLength !== PUBLIC_EFFECT.bytes) throw Error("The original aura resource changed");
        const hash = [...new Uint8Array(await root.crypto.subtle.digest("SHA-256", bytes))].map((n) => n.toString(16).padStart(2, "0")).join("");
        if (hash !== PUBLIC_EFFECT.sha256) throw Error("The original aura resource changed");
        return { rel: PUBLIC_EFFECT.path, url: "/cdn/uncompressed/" + PUBLIC_EFFECT.path, bytes: PUBLIC_EFFECT.bytes, source: "verified-public", stamp: "sha256:" + hash };
      })();
      try {
        return await publicEffect;
      } catch {
        publicEffect = null;
        return null;
      }
    };
    root.fetch = async function(input, init) {
      var _a2, _b2, _c, _d;
      const url = address(input, location.href), sameOrigin = url && url.protocol === location.protocol && url.hostname === location.hostname && url.port === location.port, method = String((init == null ? void 0 : init.method) || typeof input === "object" && input.method || "GET").toUpperCase(), fit = sameOrigin && method === "GET" ? fitRoute(url) : null;
      if (fit) {
        const texture = (_b2 = (_a2 = cards.get(fit.id)) == null ? void 0 : _a2.textures) == null ? void 0 : _b2[fit.kind], raw = texture == null ? void 0 : texture.url;
        if ((texture == null ? void 0 : texture.source) === "imported" && typeof raw === "string" && /^\/assets\/character\/[A-Za-z0-9_./-]+\.png$/.test(raw) && !raw.split("/").some((x) => x === "." || x === "..")) return fitted(root, original, raw, fit, init);
      }
      const selection = appearance((_c = root.__forgeAnimation) == null ? void 0 : _c.previewAppearance), card = sameOrigin && method === "GET" && !url.searchParams.has("patch") && /^\/api\/card\/([1-9][0-9]{0,14})$/.exec(url.pathname);
      let response = await (card ? readPublicCard(original, input, init) : original(input, init));
      const alias = sameOrigin && method === "GET" && !response.ok ? textureCaseAlias(url) : null;
      if (alias) response = await recoverTextureCase(root, original, url, alias, init, response);
      if (card && response.ok) {
        try {
          let data = await response.clone().json();
          if (selection && Number(card[1]) === selection.actorId) {
            const donor = await readPublicCard(original, "/api/card/" + selection.artCardId, { signal: (init == null ? void 0 : init.signal) || (typeof input === "object" ? input.signal : void 0) });
            if (!donor.ok) throw Error("The selected card artwork is unavailable. Download or import its assets before previewing.");
            data = appearanceCard(data, await donor.json(), selection);
            response = new Response(JSON.stringify(data), { headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
          }
          if (data.forge_local === true) {
            if (cards.size >= 32 && !cards.has(card[1])) cards.delete(cards.keys().next().value);
            cards.set(card[1], data);
          } else cards.delete(card[1]);
        } catch (error) {
          cards.delete(card[1]);
          if (selection && Number(card[1]) === selection.actorId) return new Response(JSON.stringify({ found: false, id: selection.actorId, error: String((error == null ? void 0 : error.message) || error) }), { status: 503, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
        }
      }
      const effect = sameOrigin && method === "GET" && !url.searchParams.has("patch") && /^\/api\/effect-pack\/(31011|31012)$/.exec(url.pathname);
      if (effect && response.ok) {
        try {
          const metadata = await response.clone().json();
          if (knownPublicEffect(metadata, effect[1])) {
            const lwf = await verifiedEffect();
            if (lwf) return new Response(JSON.stringify({ ...metadata, lwf, media: ((_d = metadata.usm) == null ? void 0 : _d.url) ? "both" : "lwf", forge_verified_public: true }), { headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
          }
        } catch {
        }
      }
      return response;
    };
  }
  return { dimensions, plan, fitRoute, install, MAX_BYTES, textureCaseAlias, PUBLIC_TEXTURE_ALIASES, knownPublicEffect, PUBLIC_EFFECT, primaryTimeline, timelineState, seekNestedFrame, checkNestedEnd, appearance, appearanceCard };
});
