"use strict";
// 🎨 Card artwork, the easy way: use a character's artwork, draw new art with your connected AI
// (written to official Dokkan Battle card-art standards), or use your own picture. The picture is
// fitted into every in-game layer automatically: the card art at its exact size, the round
// portrait, cut-ins and the thumbnail. For an LR, the picture replaces the character layer of the
// card's animated artwork, so the game's own LR animation (motion, aura, effects) moves it.
window.ForgeArtStudio = (() => {
  const MAX_BYTES = 12 * 1024 * 1024;
  const h = (s) => esc(String(s == null ? "" : s));
  const PORTRAIT_ROLES = ["circle", "cutin", "sp_cutin", "thumb"];
  const isAnimatedCharacter = (id) => /^animated:.*Images_card_\d+_character\.png$/.test(id);
  const POSES = [
    ["battle", "Battle stance", "dynamic fighting stance, fists ready, body turned three-quarters toward the viewer"],
    ["charge", "Powering up", "powering up with a blazing aura, energy crackling around the body, hair and clothes blown by the energy"],
    ["attack", "Super Attack", "firing a signature energy attack toward the viewer, glowing energy sphere in the hands, intense expression"],
    ["calm", "Confident", "confident calm pose, arms crossed, slight smirk, aura flickering softly"]
  ];
  // What official card art looks like, in words an image AI follows.
  function prompt(desc, pose, lr) {
    const p = POSES.find((x) => x[0] === pose) || POSES[0];
    return [
      "Official Dragon Ball Z Dokkan Battle card character artwork of " + (desc || "an original Dragon Ball fighter") + ".",
      "Pose: " + p[2] + ".",
      "Style: authentic Toei Animation Dragon Ball anime style exactly like Dokkan Battle card art — thick clean black lineart, cel shading with crisp two-tone shadows, saturated vivid colors, strong rim lighting, dramatic energy effects and speed lines, high detail on muscles, hair and clothing.",
      "Composition: single character only, vertical portrait, centered, the character's head in the upper third and the body visible down to the knees, filling about 85% of the image height, with a little space around the hair and aura so nothing is cut off.",
      "Correct Dragon Ball anatomy and proportions, the face clearly visible and looking toward the viewer.",
      lr ? "Legendary Rare quality: extra dramatic, lavish energy effects and a powerful heroic presence." : "",
      "No text, no logos, no card frame, no border, no watermark. Transparent or plain background with no scenery."
    ].filter(Boolean).join(" ");
  }
  const bytes = (base64) => { const t = atob(base64), d = new Uint8Array(t.length); for (let i = 0; i < t.length; i++) d[i] = t.charCodeAt(i); if (d.length > MAX_BYTES) throw Error("Choose an image of 12 MB or less."); return d; };
  async function pictureFrom(base64, mime = "image/png") {
    const img = new Image();
    img.src = "data:" + mime + ";base64," + base64;
    await img.decode();
    return img;
  }
  function fit(picture, width, height, { mode = "contain", x = 0.5, y = 0.5 } = {}) {
    const c = document.createElement("canvas");
    c.width = width; c.height = height;
    const g = c.getContext("2d"), pw = picture.naturalWidth || picture.width, ph = picture.naturalHeight || picture.height;
    g.imageSmoothingEnabled = true; g.imageSmoothingQuality = "high";
    const s = Math[mode === "cover" ? "max" : "min"](width / pw, height / ph), w = pw * s, hh = ph * s;
    g.drawImage(picture, (width - w) * x, (height - hh) * y, w, hh);
    return c;
  }
  // round portrait / cut-in / thumbnail: the upper half of the picture (the head and chest)
  function portrait(picture, width, height) {
    const top = document.createElement("canvas"), pw = picture.naturalWidth || picture.width, ph = picture.naturalHeight || picture.height;
    top.width = pw; top.height = Math.ceil(ph * 0.5);
    top.getContext("2d").drawImage(picture, 0, 0);
    return fit(top, width, height, { mode: "cover", x: 0.5, y: 0.2 });
  }
  const png = (canvas) => canvas.toDataURL("image/png").split(",")[1];

  // ---------------------------------------------------------------- the original art pack
  async function sourceFiles(project) {
    const result = [], info = ForgeArt.inspect(project, []), ids = [...new Set([info.sourceId, info.bgSourceId].filter(Boolean))];
    for (const id of ids) for (let page = 0; page < 200; page++) {
      // nothing imported into the app yet = no saved files to reuse (the originals are downloaded instead)
      const rows = await Native.call("assets", { query: String(id), offset: page * 500, limit: 500 }).catch((e) => { if (/asset folder is unavailable/i.test(e && e.message || "")) return []; throw e; });
      for (const row of rows) if (!result.some((x) => x.key === row.key)) result.push(row);
      if (rows.length < 500) break;
    }
    return result;
  }
  async function downloadOriginals(project, say) {
    const original = ForgeArt.inspect(project, []), roots = [original.cardRoot.replace(/\/$/, ""), original.thumbRoot.replace(/\/$/, "")];
    if (original.bgSourceId) roots.push(original.bgRoot.replace(/\/$/, ""));
    const files = new Map();
    for (const root of roots) {
      const queue = [root];
      let folders = 0;
      while (queue.length) {
        const folder = queue.shift();
        if (++folders > 32) throw Error("This artwork pack has too many folders. Use the Advanced artwork editor with an imported resource build.");
        const listing = await Native.call("browseAssets", { path: folder });
        if (listing.error || !Array.isArray(listing.items) || !listing.items.length) throw Error("The original artwork isn't available online right now. Try again later, or import the game's resource files (More → Game data & files).");
        for (const item of listing.items) {
          if (!Forge.safePath(item.path) || !item.path.startsWith(root + "/")) continue;
          if (item.type === "directory") { queue.push(item.path); continue; }
          if (!/\.(png|lwf|json|fnt|txt|plist|bin|fsh|vsh)$/i.test(item.path)) continue;
          if (!(Number(item.size) > 0) || Number(item.size) > MAX_BYTES) throw Error("An original artwork file is too big for the easy editor. Use the Advanced artwork editor with an imported resource build.");
          files.set(item.path, item);
        }
      }
    }
    if (!files.size) throw Error("No original artwork was found for this character.");
    const group = "art-download-" + Date.now() + "-" + Math.random().toString(36).slice(2, 12);
    let n = 0;
    for (const item of files.values()) {
      say("Getting the original card layout… " + (++n) + " of " + files.size);
      const saved = await Native.call("downloadAsset", { path: item.path, group });
      if (!saved || !String(saved.key || "").startsWith(group + "/")) throw Error("Update the app to save original artwork in its own protected collection.");
      if (Number(saved.size) !== Number(item.size)) throw Error("An original artwork file changed while downloading. Try again.");
    }
    return group;
  }
  // Saves new layer pictures as this unit's private artwork (shared by the picture and rarity-icon tools).
  async function finishArt(project, info, catalog, updates, say) {
    const read = async (key) => bytes((await Native.call("readAsset", { key, maxBytes: MAX_BYTES })).base64);
    const replaced = new Set(updates.map((u) => u.role)), replacements = [...ForgeArt.replacements(project).filter((u) => !replaced.has(u.role)), ...updates], all = [...catalog, ...replacements.map((u) => ({ key: u.key }))];
    const occupied = [];
    for (let page = 0; page < 200; page++) {
      const rows = await Native.call("query", { table: "cards", filters: { resource_id: info.resourceId }, offset: page * 5000, limit: 5000 });
      occupied.push(...rows.map((r) => r.resource_id));
      if (rows.length < 5000) break;
    }
    for (const other of await Native.call("projects")) if (other.key !== project.key && Math.floor(Number(other.targetId) / 10) * 10 === info.resourceId) occupied.push(info.resourceId);
    say("Saving your artwork…");
    const plan = await ForgeArt.plan(project, all, { group: info.group, replacements, readAsset: read, storeDecoration: (text) => Native.call("storeDecoration", { text }), occupiedResourceIds: occupied });
    if (state.project !== project) throw Error("Your unit changed. Try again.");
    const previous = project.artBinding && Object.prototype.hasOwnProperty.call(project.artBinding, "previousPreviewKey") ? project.artBinding.previousPreviewKey : (project.previewKey || null);
    ForgeArt.apply(project, plan);
    project.artBinding.previousPreviewKey = previous;
    const thumb = project.assets.find((a) => a.owner === "forge-card-art" && a.path === "character/thumb/card_" + project.artBinding.resourceId + "_thumb.png");
    if (thumb) project.previewKey = thumb.key;
    scheduleSave();
    await flushSave();
    state.previewUrl = await projectPreviewUrl(project);
  }
  // ---- SLR / GR icon on the card art (level 180 / 200). The game only knows its built-in rarities, so the
  // icon is drawn into the thumbnail and the card picture. Plain copies are kept so it can be changed or removed.
  const BADGE_ROLES = ["thumb", "character"];
  function badgeCanvas(source, role, t) {
    const c = document.createElement("canvas"), w = source.naturalWidth || source.width, hh = source.naturalHeight || source.height;
    c.width = w; c.height = hh;
    const g = c.getContext("2d"); g.drawImage(source, 0, 0);
    if (t && window.ForgeRarityBadge) {
      const size = role === "thumb" ? Math.round(hh * 0.17) : Math.round(Math.min(w, hh) * 0.085);
      const pad = Math.round(size * 0.2), bw = ForgeRarityBadge.measure(g, t, size);
      if (role === "thumb") ForgeRarityBadge.draw(g, t, pad + size * 0.35, pad + size * 1.1, size);   // room for the aura and lightning                    // top-left, aura included (the game puts LR/UR at the bottom)
      else ForgeRarityBadge.draw(g, t, w - bw - pad * 2, hh - size * 1.1 - pad * 2, size);                 // bottom-right of the card picture
    }
    return c;
  }
  async function applyBadge(say = () => {}) {
    const project = state.project;
    if (!project) throw Error("Open a unit first.");
    const t = window.ForgeRarityBadge ? ForgeRarityBadge.tier(project) : "";
    if (!t && !project.rarityBadge) throw Error("Set the Maximum level to 180 (SLR) or 200 (GR) first.");
    if (window.ForgeRarityBadge) await ForgeRarityBadge.ready();
    say("Reading the card layout…");
    let catalog = await sourceFiles(project), info = ForgeArt.inspect(project, catalog);
    const has = () => info.roles.some((r) => BADGE_ROLES.includes(r.id));
    if (!has()) { const group = await downloadOriginals(project, say); catalog = await sourceFiles(project); info = ForgeArt.inspect(project, catalog, { group }); }
    if (!has()) throw Error("This character's card layout couldn't be read. Use “Advanced artwork editor” instead.");
    const read = async (key) => bytes((await Native.call("readAsset", { key, maxBytes: MAX_BYTES })).base64);
    const current = new Map(ForgeArt.replacements(project).map((u) => [u.role, u.key]));
    const base = Object.assign({}, project.rarityBadgeBase || {}), updates = [];
    for (const role of info.roles.filter((r) => BADGE_ROLES.includes(r.id))) {
      say((t ? "Adding the " + ForgeRarityBadge.NAMES[t] + " icon: " : "Removing the icon: ") + (role.label || role.id));
      const plainKey = base[role.id] || current.get(role.id) || role.key;
      base[role.id] = plainKey;
      const rec = await Native.call("readAsset", { key: plainKey, maxBytes: MAX_BYTES });
      const img = await pictureFrom(rec.base64, rec.mime || "image/png");
      const stored = await Native.call("storeAsset", { name: "card-art-" + role.id + (t ? "-" + t : "") + ".png", data: png(badgeCanvas(img, role.id, t)) });
      updates.push({ role: role.id, key: stored.key });
    }
    await finishArt(project, info, catalog, updates, say);
    if (t) { project.rarityBadge = t; project.rarityBadgeBase = base; } else { delete project.rarityBadge; delete project.rarityBadgeBase; }
    scheduleSave(); await flushSave();
    return { tier: t, layers: updates.length };
  }
  // Puts one picture into every layer of the card, then saves it as this unit's private artwork.
  async function applyPicture(picture, say = () => {}) {
    const project = state.project;
    if (!project) throw Error("Open a unit first.");
    say("Reading the card layout…");
    let catalog = await sourceFiles(project), info = ForgeArt.inspect(project, catalog);
    const ready = () => info.roles.some((r) => r.id === "character" || isAnimatedCharacter(r.id));
    if (!ready()) {
      const group = await downloadOriginals(project, say);
      catalog = await sourceFiles(project);
      info = ForgeArt.inspect(project, catalog, { group });
    }
    if (!ready()) throw Error("This character's card layout couldn't be read. Use “Advanced artwork editor” instead.");
    const read = async (key) => bytes((await Native.call("readAsset", { key, maxBytes: MAX_BYTES })).base64);
    const updates = [], plain = {}, badge = window.ForgeRarityBadge ? ForgeRarityBadge.tier(project) : "";
    if (badge) await ForgeRarityBadge.ready();
    const roles = info.roles.filter((r) => r.id === "character" || isAnimatedCharacter(r.id) || PORTRAIT_ROLES.includes(r.id));
    for (const role of roles) {
      say("Fitting your picture: " + (role.label || role.id));
      const size = ForgeArt.pngInfo(await read(role.key));
      const canvas = PORTRAIT_ROLES.includes(role.id) ? portrait(picture, size.width, size.height) : fit(picture, size.width, size.height, { mode: "contain", x: 0.5, y: 0.55 });
      let stored = await Native.call("storeAsset", { name: "card-art-" + role.id.replace(/[^a-z0-9]+/gi, "-").slice(-40) + ".png", data: png(canvas) });
      if (badge && BADGE_ROLES.includes(role.id)) {
        plain[role.id] = stored.key;
        stored = await Native.call("storeAsset", { name: "card-art-" + role.id + "-" + badge + ".png", data: png(badgeCanvas(canvas, role.id, badge)) });
      }
      updates.push({ role: role.id, key: stored.key });
    }
    await finishArt(project, info, catalog, updates, say);
    if (badge) { project.rarityBadge = badge; project.rarityBadgeBase = plain; } else { delete project.rarityBadge; delete project.rarityBadgeBase; }
    return { animated: updates.some((u) => isAnimatedCharacter(u.role)), layers: updates.length };
  }

  // ---------------------------------------------------------------- the wizard
  function badgeRow(p) {
    const RB = window.ForgeRarityBadge, t = RB ? RB.tier(p) : "", on = p.rarityBadge || "";
    if (!t && !on) return "";
    const label = t ? (on === t ? "Redo the " + RB.NAMES[t] + " icon on the card art" : "Add the " + RB.NAMES[t] + " icon to the card art") : "Remove the " + (RB.NAMES[on] || "rarity") + " icon from the card art";
    return '<div class="art-badge-row">' + (t ? RB.html(t) : "") + '<button type="button" class="button ghost" id="art-badge">' + label + '</button><p class="hint">' + (t ? "Eclipse only has its built-in rarities, so the " + RB.NAMES[t] + " icon is drawn onto this unit's thumbnail and card picture." : "This unit is no longer level 180 or 200.") + '</p><p class="hint" id="art-badge-status" role="status" hidden></p></div>';
  }
  function closeDialog() { const d = document.getElementById("dialog"); if (d && d.open) d.close(); }
  function open() {
    const p = state.project;
    if (!p) return toast("Open a unit first.", true);
    const lr = Number(Forge.card(p).rarity) === 5;
    dialog("Card artwork", '<div data-no-ai class="ucopy-dialog"></div><p>Choose how your character should look. Your picture is fitted into every in-game layer automatically — card art, round portrait, cut-ins and thumbnail.' + (lr ? " <strong>LR:</strong> your picture is placed inside the card's animated artwork, so it moves with the game's LR animation, aura and effects." : "") + "</p>" +
      '<div class="art-choices">' +
      '<button type="button" class="art-choice" data-art="game"><span>🎴</span><span><strong>Use a character\'s artwork</strong><small>Any card in the game, animated LR art included.</small></span></button>' +
      '<button type="button" class="art-choice" data-art="ai"><span>✨</span><span><strong>Create new art with AI</strong><small>Describe your character; your connected AI draws it in official Dokkan style.</small></span></button>' +
      '<button type="button" class="art-choice" data-art="mine"><span>🖼</span><span><strong>Use my own picture</strong><small>A PNG or JPG from your phone or computer.</small></span></button>' +
      "</div><details><summary>Advanced</summary><div class=\"row\">" + '<button type="button" class="button ghost small" data-art="advanced">Advanced artwork editor</button><button type="button" class="button ghost small" data-art="aura">Use another character\'s aura</button></div></details>' +
      badgeRow(p) + '<div class="row"><button type="button" class="button ghost" id="art-cancel">Close</button></div>');
    document.getElementById("art-cancel").onclick = closeDialog;
    const bb = document.getElementById("art-badge");
    if (bb) bb.onclick = async () => {
      bb.disabled = true; const st = document.getElementById("art-badge-status");
      try { const r = await applyBadge((t) => { st.hidden = false; st.textContent = t; }); closeDialog(); renderEditor(); toast(r.tier ? "The " + ForgeRarityBadge.NAMES[r.tier] + " icon is on the card art (thumbnail and card picture). ↶ Undo takes it back." : "Rarity icon removed from the card art."); }
      catch (e) { st.hidden = false; st.textContent = e.message || String(e); st.classList.add("error"); bb.disabled = false; }
    };
    document.querySelectorAll("[data-art]").forEach((b) => b.onclick = () => choose(b.dataset.art).catch((e) => toast(e.message || String(e), true)));
  }
  async function choose(kind) {
    if (kind === "game") { closeDialog(); return document.querySelector('[data-guide="pick-art"]')?.click(); }
    if (kind === "aura") { closeDialog(); return document.querySelector('[data-guide="pick-aura"]')?.click(); }
    if (kind === "advanced") { closeDialog(); return ForgeArtEditor.open(); }
    if (kind === "mine") {
      const result = await Native.call("import");
      if (!result || !result.kind) return;
      const a = result.asset;
      if (!a || !a.image) throw Error("Choose a PNG, JPG or WebP picture.");
      const rec = await Native.call("readAsset", { key: a.key, maxBytes: MAX_BYTES });
      return review(await pictureFrom(rec.base64, rec.mime || "image/png"), rec.base64, rec.mime);
    }
    if (kind === "ai") return aiForm();
  }
  function aiForm() {
    const p = state.project, c = Forge.card(p), lr = Number(c.rarity) === 5;
    const color = ["blue", "green", "purple", "red", "orange"][Number(c.element) % 10] || "gold";
    dialog("Create new art with AI", '<div data-no-ai class="ucopy-dialog"></div><label class="field">Who is it? Describe your character<textarea id="art-desc" rows="4" maxlength="800">' + h(c.name + ", " + color + " energy aura") + '</textarea></label>' +
      '<label class="field">Pose<select id="art-pose">' + POSES.map(([k, l]) => '<option value="' + k + '">' + h(l) + "</option>").join("") + "</select></label>" +
      '<details><summary>See the full instructions sent to the AI</summary><pre id="art-prompt" class="art-prompt"></pre></details>' +
      '<p class="hint">The AI is told the exact Dokkan card-art rules: Toei anime style, cel shading, centered vertical portrait with the head in the upper third, body to the knees, no text or frame.' + (lr ? " LR art gets extra dramatic effects." : "") + '</p><p id="art-status" class="notice" role="status" hidden></p><div id="art-result"></div>' +
      '<div class="row"><button type="button" class="button" id="art-go">✨ Create artwork</button><button type="button" class="button ghost" id="art-copy">Copy instructions</button><button type="button" class="button ghost" id="art-cancel">Cancel</button></div>');
    const text = () => prompt(document.getElementById("art-desc").value.trim(), document.getElementById("art-pose").value, lr);
    const show = () => { document.getElementById("art-prompt").textContent = text(); };
    document.getElementById("art-desc").oninput = show; document.getElementById("art-pose").onchange = show; show();
    const status = (t, err) => { const n = document.getElementById("art-status"); if (!n) return; n.hidden = false; n.textContent = t; n.classList.toggle("error", !!err); };
    document.getElementById("art-cancel").onclick = closeDialog;
    document.getElementById("art-copy").onclick = () => Native.call("copy", { text: text() }).then(() => toast("Instructions copied. Paste them into any image app, then use “Use my own picture”.")).catch(() => {});
    const go = document.getElementById("art-go");
    go.onclick = async () => {
      if (!window.ForgeAIConnect) return;
      go.disabled = true;
      try {
        status("Drawing your character… this can take a minute.");
        const r = await ForgeAIConnect.generateImage(text(), { transparent: true, portrait: true }, (sec) => status("Drawing your character… " + sec + "s"));
        review(await pictureFrom(r.base64), r.base64);
      } catch (e) {
        status(e.message || String(e), true);
        if (/Connect an image-capable AI/i.test(e.message || "")) document.getElementById("art-result").innerHTML = '<button type="button" class="button ghost" id="art-connect">Connect an AI</button>';
        const cb = document.getElementById("art-connect");
        if (cb) cb.onclick = () => { closeDialog(); ForgeAIConnect.openSettings(); };
      } finally { const g = document.getElementById("art-go"); if (g) g.disabled = false; }
    };
  }
  function review(picture, base64, mime = "image/png") {
    dialog("Use this artwork?", '<div data-no-ai class="ucopy-dialog"></div><div class="art-review"><div class="art-frame"><img alt="Your artwork" src="data:' + mime + ';base64,' + base64 + '"></div><div class="art-round"><img alt="" src="data:' + mime + ';base64,' + base64 + '"></div></div><p class="hint">Left: how it sits on the card. Right: the round portrait. Everything else is fitted the same way.</p><p id="art-status" class="notice" role="status" hidden></p>' +
      '<div class="row"><button type="button" class="button" id="art-use">Use this artwork</button><button type="button" class="button ghost" id="art-back">Try something else</button></div>');
    const status = (t, err) => { const n = document.getElementById("art-status"); if (!n) return; n.hidden = false; n.textContent = t; n.classList.toggle("error", !!err); };
    document.getElementById("art-back").onclick = open;
    document.getElementById("art-use").onclick = async () => {
      const b = document.getElementById("art-use");
      b.disabled = true;
      try {
        const r = await applyPicture(picture, (t) => status(t));
        closeDialog();
        renderEditor();
        toast(r.animated ? "Artwork saved — it moves with the LR card animation. ↶ Undo takes it back." : "Artwork saved in " + r.layers + " card layers. ↶ Undo takes it back.");
      } catch (e) { status(e.message || String(e), true); b.disabled = false; }
    };
  }
  // A big "🎨 Change card artwork" button at the top of the Artwork panel on Artwork & Aura.
  let queued = false;
  function inject() {
    queued = false;
    const panel = [...document.querySelectorAll("#bld .panel")].find((s) => (s.querySelector("h2") || {}).textContent === "Artwork & aura");
    if (!panel || panel.querySelector(".art-studio-button")) return;
    const b = document.createElement("button");
    b.type = "button";
    b.className = "button art-studio-button";
    b.textContent = "🎨 Change card artwork";
    b.onclick = open;
    const row = panel.querySelector(".row");
    if (row) { row.before(b); const d = document.createElement("details"); d.className = "art-more"; d.innerHTML = "<summary>More artwork options</summary>"; row.before(d); d.append(row); const ai = panel.querySelector(".bld-ai-art"); if (ai) d.append(ai); }
    else panel.append(b);
  }
  new MutationObserver(() => { if (!queued) { queued = true; requestAnimationFrame(inject); } }).observe(document.body, { childList: true, subtree: true });
  return { open, prompt, applyPicture, applyBadge, badgeCanvas, fit, portrait };
})();
