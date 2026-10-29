"use strict";
// SLR and GR: the rarity icons for units above level 150.
//   SLR: Super Saiyan 2 (gold aura, lightning) with LR-icon style rainbow letters. GR: Super Saiyan God (crimson flame).
//   Level 180 → SLR (Super Legendary Rare): crimson & gold, a light sweep across it, a slow red pulse.
//   Level 200 → GR (Godly Rare): silver-blue godly aura (Ultra Instinct style), white lightning, chrome letters.
// Shown in the app (card preview, Home, Library, pickers) and drawn onto the unit's card art for Eclipse
// (draw(), used by the art studio), since the game itself only has its built-in rarities.
window.ForgeRarityBadge = (() => {
  const TIERS = { 180: "slr", 200: "gr" };
  const NAMES = { slr: "SLR", gr: "GR", ulr: "GR", lr: "LR", ur: "UR" }, LONG = { slr: "Super Legendary Rare", gr: "Godly Rare", ulr: "Godly Rare", lr: "Legendary Rare", ur: "Ultra Rare" };   // "ulr" = the earlier name, still read
  const KEY = "forge-unit-tiers";
  const read = () => { try { return JSON.parse(localStorage.getItem(KEY) || "{}") || {}; } catch { return {}; } };
  const write = (m) => { try { localStorage.setItem(KEY, JSON.stringify(m)); } catch {} };
  // tier of a card row / project / saved-unit summary
  function tier(x) {
    if (!x) return "";
    if (x.tables && x.cardOverrides) { const c = Forge.card(x); return TIERS[Number(c.lv_max)] || ""; }
    if (x.lvMax != null || x.lv_max != null) return TIERS[Number(x.lvMax != null ? x.lvMax : x.lv_max)] || "";
    if (x.key) { const k = read()[x.key] || ""; return k === "ulr" ? "gr" : k; }
    return "";
  }
  function remember(p) {
    if (!p || !p.key) return;
    const m = read(), t = tier(p);
    if ((m[p.key] || "") === t) return;
    if (t) m[p.key] = t; else delete m[p.key];
    write(m);
  }
  // Lightning bolts (SSJ2 / Ultra Instinct crackle) drawn in the badge's own box.
  const BOLTS = '<svg class="rb-bolts" viewBox="0 0 120 60" aria-hidden="true" preserveAspectRatio="none">' +
    '<path class="rb-b1" d="M10 2 L19 15 L13 17 L24 30 L17 32 L27 47 L22 48 L30 59 M19 15 L8 22 M24 30 L33 34"/>' +
    '<path class="rb-b2" d="M110 3 L100 16 L107 18 L95 31 L102 33 L91 47 L97 49 L88 59 M100 16 L112 24 M95 31 L86 35"/>' +
    '<path class="rb-b3" d="M58 0 L52 10 L59 12 L50 24 L56 25 L49 35"/>' +
    '<path class="rb-b4" d="M78 1 L84 11 L78 13 L86 25 M84 11 L92 9"/>' +
    '<path class="rb-b5" d="M34 0 L30 9 L36 11 L28 22 M30 9 L22 8"/>' +
    '<path class="rb-b6" d="M2 30 L12 36 L6 40 L18 48 M12 36 L18 32"/>' +
    '<path class="rb-b7" d="M118 28 L108 35 L114 39 L102 47"/></svg>';
  // GR: angel halo + feathered wings (Dragon Ball's angels / gods), in the badge's own box
  // a wing: three layered feather rows with crisp gold edges (left wing; the right one is mirrored)
  const WING = "M44 36 C34 22 18 15 3 18 C11 22 15 24 18 27 C9 28 4 31 0 35 C9 36 14 36 18 37 C11 40 8 44 6 48 C17 47 29 42 44 39 Z";
  const WING_PARTS = '<path d="' + WING + '" fill="url(#rbWing)" stroke="#d99a1e" stroke-width="1.1" stroke-linejoin="round"/>' +
    '<path d="M44 35 C36 27 26 23 15 23 M44 37 C35 33 24 32 12 32 M44 38 C36 39 26 41 15 44" fill="none" stroke="#e8b33c" stroke-width=".8" stroke-linecap="round" opacity=".9"/>';
  const DIVINE = '<svg class="rb-divine" viewBox="0 0 120 60" aria-hidden="true" preserveAspectRatio="none"><defs>' +
    '<linearGradient id="rbWing" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#ffe9a8"/><stop offset=".6" stop-color="#fff6d2"/><stop offset="1" stop-color="#ffffff"/></linearGradient></defs>' +
    '<g class="rb-wing rb-wl">' + WING_PARTS + '</g>' +
    '<g class="rb-wing rb-wr"><g transform="translate(120 0) scale(-1 1)">' + WING_PARTS + '</g></g>' +
    '<ellipse class="rb-halo" cx="60" cy="9" rx="19" ry="4"/></svg>';
  function html(t, size = "") {
    if (!t) return "";
    if (t === "ulr") t = "gr";
    if (t === "lr" || t === "ur")   // the game's own top rarities: same letter style, no aura or lightning
      return '<span class="rb rb-' + t + (size ? " rb-" + size : "") + '" title="' + LONG[t] + '" role="img" aria-label="' + LONG[t] + '"><span class="rb-out" aria-hidden="true">' + NAMES[t] + '</span><span class="rb-txt" data-t="' + NAMES[t] + '">' + NAMES[t] + '</span><span class="rb-spark" aria-hidden="true"></span></span>';
    return '<span class="rb rb-' + t + (size ? " rb-" + size : "") + '" title="' + LONG[t] + '" role="img" aria-label="' + LONG[t] + '">' +
      '<span class="rb-wave" aria-hidden="true"></span><span class="rb-aura" aria-hidden="true"><i></i><i></i><i></i></span>' + BOLTS +
      '<span class="rb-out" aria-hidden="true">' + NAMES[t] + '</span><span class="rb-txt" data-t="' + NAMES[t] + '">' + NAMES[t] + '</span>' +
      '<span class="rb-spark" aria-hidden="true"></span></span>';
  }
  // label for places that show plain text ("LR", "UR"…)
  const label = (x, fallback) => NAMES[tier(x)] || fallback;

  // ---- drawn version for the card art (a still frame: aura flared, lightning striking)
  const SPIKES = [[0, 1], [.04, .62], [.1, .8], [.14, .38], [.21, .7], [.27, .18], [.33, .58], [.4, .06], [.46, .5], [.5, 0], [.54, .5], [.6, .06], [.67, .58], [.73, .18], [.79, .7], [.86, .38], [.9, .8], [.96, .62], [1, 1]];
  const BOLT_PATHS = [[[10, 2], [19, 15], [13, 17], [24, 30], [17, 32], [27, 47], [22, 48], [30, 59]], [[110, 3], [100, 16], [107, 18], [95, 31], [102, 33], [91, 47], [97, 49], [88, 59]], [[58, 0], [52, 10], [59, 12], [50, 24]],
    [[34, 0], [30, 9], [36, 11], [28, 22]], [[78, 1], [84, 11], [78, 13], [86, 25]], [[2, 30], [12, 36], [6, 40], [18, 48]], [[118, 28], [108, 35], [114, 39], [102, 47]]];
  const LOOK = {
    slr: { halo: "rgba(255,200,40,.85)", layers: [["rgba(255,140,0,.75)", "rgba(255,200,30,.6)"], ["rgba(255,236,110,.85)", "rgba(255,220,60,.55)"], ["rgba(255,255,255,.95)", "rgba(255,250,200,.6)"]],
      fill: [[0, "#ff4fa3"], [.2, "#ffd23f"], [.4, "#7dff6a"], [.6, "#3fe6ff"], [.8, "#7a6bff"], [1, "#ff4fa3"]], fillAcross: true, rim: "#ffffff", dark: "#120a2e", bolt: "#eaf8ff", glow: "#6fd2ff" },
    gr: { halo: "rgba(255,40,60,.9)", layers: [["rgba(200,0,30,.9)", "rgba(255,40,40,.7)"], ["rgba(255,110,40,.9)", "rgba(255,70,50,.65)"], ["rgba(255,236,200,.95)", "rgba(255,170,120,.7)"]],
      fill: [[0, "#fff4ec"], [.22, "#ffb4a0"], [.44, "#ff5a5f"], [.64, "#e8102e"], [.84, "#a8001e"], [1, "#4a0010"]], rim: "#ffe2cf", dark: "#2a0006", bolt: "#ffe1a8", glow: "#ff3b2f", rays: "rgba(255,120,90,.35)", embers: "#ffb070", tall: true }
  };
  function draw(g, t, x, y, height) {
    if (!t) return;
    if (t === "ulr") t = "gr";
    const L = LOOK[t], text = NAMES[t], h = height;
    g.save();
    g.font = Math.round(h * 0.78) + "px 'DB Russo', 'Russo One', Impact, sans-serif";
    const tw = g.measureText(text).width, w = tw + h * 0.55;
    // aura: halo + three spiky flame layers rising behind the letters, faded into an oval like the app's
    const ax = x - h * 0.3, aw = w + h * 0.6, ab = y + h * 1.05, ah = h * (L.tall ? 2.1 : 1.85);
    const ox = Math.floor(ax - h * 0.35), oy = Math.floor(ab - ah - h * 0.25), ow = Math.ceil(aw + h * 0.7), oh = Math.ceil(ah + h * 0.45);
    const off = document.createElement("canvas"); off.width = Math.max(1, ow); off.height = Math.max(1, oh);
    const o = off.getContext("2d");
    const halo = o.createRadialGradient(x + w / 2 - ox, y + h * 0.65 - oy, h * 0.1, x + w / 2 - ox, y + h * 0.65 - oy, w * 0.62);
    halo.addColorStop(0, L.halo); halo.addColorStop(1, "rgba(0,0,0,0)");
    o.fillStyle = halo; o.fillRect(0, 0, ow, oh);
    [[0, 0, 1, 1], [0.1, 0.18, 0.8, 0.82], [0.22, 0.42, 0.56, 0.58]].forEach(([ix, iy, sw, sh], i) => {
      const lx = ax + aw * ix - ox, lw = aw * sw, lh = ah * sh, base = ab - oy, top = base - lh;
      const grad = o.createLinearGradient(0, base, 0, top);
      grad.addColorStop(0, L.layers[i][0]); grad.addColorStop(0.5, L.layers[i][1]); grad.addColorStop(1, "rgba(255,255,255,0)");
      o.beginPath();
      SPIKES.forEach(([px, py], k) => { const X = lx + lw * px, Y = top + lh * py; k ? o.lineTo(X, Y) : o.moveTo(X, Y); });
      o.closePath(); o.fillStyle = grad; o.fill();
    });
    // oval fade (keeps the flame tips, softens the sides and bottom)
    o.globalCompositeOperation = "destination-in";
    o.save(); o.translate(ow / 2, oh * 0.55); o.scale(1, (oh * 0.56) / (ow * 0.54));
    const fade = o.createRadialGradient(0, 0, 0, 0, 0, ow * 0.54);
    fade.addColorStop(0, "#000"); fade.addColorStop(0.55, "#000"); fade.addColorStop(0.95, "rgba(0,0,0,0)");
    o.fillStyle = fade; o.fillRect(-ow, -ow * 2, ow * 2, ow * 4); o.restore();
    g.drawImage(off, ox, oy);
    // GR: golden god rays behind everything and rising embers; SLR: lightning
    g.lineCap = "round"; g.lineJoin = "round";
    if (L.rays) {
      const cx = x + w / 2, cy = y + h * 0.6, r0 = h * 0.5, r1 = h * 1.25;
      g.save(); g.globalCompositeOperation = "destination-over";
      for (let k = 0; k < 18; k++) {
        const a = (Math.PI * 2 * k) / 18, d = Math.PI / 70, grad = g.createRadialGradient(cx, cy, r0, cx, cy, r1);
        grad.addColorStop(0, L.rays); grad.addColorStop(1, "rgba(255,215,120,0)");
        g.beginPath(); g.moveTo(cx + Math.cos(a - d) * r0, cy + Math.sin(a - d) * r0); g.lineTo(cx + Math.cos(a - d * 2) * r1, cy + Math.sin(a - d * 2) * r1);
        g.lineTo(cx + Math.cos(a + d * 2) * r1, cy + Math.sin(a + d * 2) * r1); g.lineTo(cx + Math.cos(a + d) * r0, cy + Math.sin(a + d) * r0); g.closePath();
        g.fillStyle = grad; g.fill();
      }
      g.restore();
      g.fillStyle = L.embers; g.shadowColor = L.embers; g.shadowBlur = h * 0.15;
      for (const [ex, ey, er] of [[0.12, 0.05, 0.05], [0.3, -0.25, 0.035], [0.72, -0.18, 0.045], [0.9, 0.1, 0.035], [0.55, -0.4, 0.03]]) { g.beginPath(); g.arc(x + w * ex, y + h * ey, h * er, 0, Math.PI * 2); g.fill(); }
      g.shadowBlur = 0;
    }
    if (L.divine) {
      const dx = x - h * 0.8, dw = w + h * 1.6, dy = y - h * 0.42, dh = h * 1.47;   // like the app (GR has extra room for its wings)
      g.save(); g.translate(dx, dy); g.scale(dw / 120, dh / 60);
      const wing = new Path2D(WING), feathers = new Path2D("M44 35 C36 27 26 23 15 23 M44 37 C35 33 24 32 12 32 M44 38 C36 39 26 41 15 44");
      for (const mirror of [false, true]) {
        g.save(); if (mirror) { g.translate(120, 0); g.scale(-1, 1); }
        const wg = g.createLinearGradient(0, 0, 44, 0); wg.addColorStop(0, "#ffe9a8"); wg.addColorStop(0.6, "#fff6d2"); wg.addColorStop(1, "#ffffff");
        g.shadowColor = "rgba(255,210,90,.8)"; g.shadowBlur = h * 0.12;
        g.fillStyle = wg; g.fill(wing); g.shadowBlur = 0;
        g.lineJoin = "round"; g.lineCap = "round"; g.strokeStyle = "#d99a1e"; g.lineWidth = 1.1; g.stroke(wing);
        g.strokeStyle = "#e8b33c"; g.lineWidth = 0.8; g.stroke(feathers);
        g.restore();
      }
      g.beginPath(); g.ellipse(60, 9, 19, 4, 0, 0, Math.PI * 2);
      g.shadowColor = "#ffc83a"; g.shadowBlur = h * 0.15; g.strokeStyle = "#ffe9a0"; g.lineWidth = 2.4; g.stroke(); g.shadowBlur = 0;
      g.restore();
    }
    // power-up shockwave ring
    g.save(); g.beginPath(); g.ellipse(x + w / 2, y + h * 0.82, w * 0.62, h * 0.32, 0, 0, Math.PI * 2);
    g.strokeStyle = L.rays ? "rgba(255,110,80,.75)" : "rgba(255,230,120,.75)"; g.lineWidth = h * 0.05; g.shadowColor = g.strokeStyle; g.shadowBlur = h * 0.2; g.stroke(); g.restore();
    for (const path of BOLT_PATHS) {
      g.beginPath();
      path.forEach(([px, py], k) => { const X = ax + aw * px / 120, Y = (ab - ah) + ah * py / 60; k ? g.lineTo(X, Y) : g.moveTo(X, Y); });
      g.shadowColor = L.glow; g.shadowBlur = h * 0.25; g.strokeStyle = L.bolt; g.lineWidth = Math.max(2, h * 0.06); g.stroke(); g.stroke();
    }
    g.shadowBlur = 0;
    // letters: slanted, heavy dark outline, metal fill, bright rim
    const tx = x + (w - tw) / 2, ty = y + h * 0.78;
    g.setTransform(g.getTransform().multiply(new DOMMatrix([1, 0, -0.19, 1, ty * 0.19, 0])));
    g.lineJoin = "round";
    g.fillStyle = L.dark; g.fillText(text, tx, ty + h * 0.09);
    g.strokeStyle = L.dark; g.lineWidth = h * 0.24; g.strokeText(text, tx, ty);
    g.strokeStyle = L.rim; g.lineWidth = h * 0.07; g.strokeText(text, tx, ty);
    const fill = L.fillAcross ? g.createLinearGradient(tx, ty - h * 0.62, tx + tw, ty) : g.createLinearGradient(0, ty - h * 0.62, 0, ty);
    L.fill.forEach(([o, c]) => fill.addColorStop(o, c));
    g.fillStyle = fill; g.fillText(text, tx, ty);
    if (L.fillAcross) {   // the LR icon's glossy top
      const gloss = g.createLinearGradient(0, ty - h * 0.62, 0, ty);
      gloss.addColorStop(0, "rgba(255,255,255,.8)"); gloss.addColorStop(0.42, "rgba(255,255,255,.1)"); gloss.addColorStop(0.58, "rgba(255,255,255,0)"); gloss.addColorStop(1, "rgba(30,0,60,.3)");
      g.fillStyle = gloss; g.fillText(text, tx, ty);
    }
    g.restore();
    return { width: w, height: h };
  }
  // width of the drawn icon for a given height (the aura reaches about 0.55 × height above it)
  function measure(g, t, height) { g.save(); g.font = Math.round(height * 0.78) + "px 'DB Russo', 'Russo One', Impact, sans-serif"; const w = g.measureText(NAMES[t] || "").width + height * 0.55 ; g.restore(); return w; }
  const ready = () => (document.fonts && document.fonts.load ? document.fonts.load("40px 'DB Russo'").catch(() => {}) : Promise.resolve());
  // icon for any unit / card: SLR or GR by level, otherwise LR or UR by rarity ("" for lower rarities)
  function iconFor(x) {
    const t = tier(x);
    if (t) return t;
    const r = Number(x && (x.tables && x.cardOverrides ? Forge.card(x).rarity : x.rarity));
    return r === 5 ? "lr" : r === 4 ? "ur" : "";
  }
  return { tier, iconFor, html, label, remember, draw, measure, ready, NAMES, LONG, TIERS };
})();
