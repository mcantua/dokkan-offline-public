/* iPhone app: small screen adjustments, loaded after the app's own scripts. */
(function () {
  "use strict";
  if (!window.forgeNative || !window.forgeNative.ios || !window.ForgeHost) return;
  // Character thumbnails come from the saved previews (instant, and they work offline), like Android.
  const PREFIX = "https://dokkan-eclipse.com/cdn/uncompressed/character/thumb/";
  const route = (src) => ForgeHost.origin + "/__thumb?u=" + encodeURIComponent(src);
  // decoding="async": pictures are decoded off the main thread, so scrolling a list of characters
  // doesn't stutter while new thumbnails come in (measured: slowest frames 87 ms -> ~23 ms).
  const fix = (img) => { if (img.decoding !== "async") img.decoding = "async"; const s = img.getAttribute("src"); if (s && s.startsWith(PREFIX) && s.endsWith(".png")) img.setAttribute("src", route(s)); };
  const scan = (root) => { if (root.tagName === "IMG") fix(root); if (root.querySelectorAll) root.querySelectorAll("img").forEach(fix); };
  new MutationObserver((list) => {
    for (const m of list) {
      if (m.type === "attributes") fix(m.target);
      else m.addedNodes.forEach((n) => n.nodeType === 1 && scan(n));
    }
  }).observe(document.documentElement, { subtree: true, childList: true, attributes: true, attributeFilter: ["src"] });
  scan(document.documentElement);

  // ---------------------------------------------------------------- folding / unfolding / rotating
  // The app is never reloaded: the native side calls begin() before the size changes and end() after.
  // We keep your place in whatever list you were scrolling, and pause decorative CSS animations while
  // the layout changes so the switch stays smooth.
  let saved = null, settleTimer = 0, active = false;
  function scrollers() {
    const list = [document.scrollingElement || document.documentElement];
    document.querySelectorAll("main, dialog[open], .sheet-body, [data-scroll], .fd-grid, .library-grid").forEach((e) => { if (e.scrollHeight > e.clientHeight + 4) list.push(e); });
    return list;
  }
  function anchorFor(el) {
    const r = el === document.scrollingElement ? { top: 0, left: 0, width: innerWidth } : el.getBoundingClientRect();
    const probeY = Math.max(0, r.top) + 12, probeX = Math.min(innerWidth - 1, Math.max(0, r.left + Math.min(r.width, innerWidth) / 2));
    let a = document.elementFromPoint(probeX, probeY);
    while (a && a !== el && a.parentElement !== el && a.getBoundingClientRect().height > (el.clientHeight || innerHeight) * 0.8) a = a.parentElement;
    return a && a !== el ? { el: a, top: a.getBoundingClientRect().top } : null;
  }
  const fold = (window.__forgeFold = {
    begin() {
      clearTimeout(settleTimer);
      if (active) return;
      active = true;
      document.documentElement.classList.add("forge-resizing");
      saved = scrollers().filter((el) => el.scrollTop > 0).map((el) => ({ el, scrollTop: el.scrollTop, ratio: el.scrollTop / Math.max(1, el.scrollHeight - el.clientHeight), anchor: anchorFor(el) }));
    },
    end() {
      requestAnimationFrame(() => requestAnimationFrame(() => {
        for (const s of saved || []) {
          if (!s.el.isConnected) continue;
          if (s.anchor && s.anchor.el.isConnected) s.el.scrollTop += s.anchor.el.getBoundingClientRect().top - s.anchor.top;
          else s.el.scrollTop = s.ratio * Math.max(0, s.el.scrollHeight - s.el.clientHeight);
        }
        saved = null; active = false;
        document.documentElement.classList.remove("forge-resizing");
        dispatchEvent(new CustomEvent("forge-fold", { detail: { width: innerWidth, height: innerHeight } }));
      }));
    },
  });
  // Without a native transition (e.g. split view), resize events do the same with a short settle time.
  let lastW = innerWidth, lastH = innerHeight;
  addEventListener("resize", () => {
    if (innerWidth === lastW && innerHeight === lastH) return;
    lastW = innerWidth; lastH = innerHeight;
    if (!active) fold.begin();
    clearTimeout(settleTimer);
    settleTimer = setTimeout(() => fold.end(), 220);
  }, { passive: true });

  // ---------------------------------------------------------------- display check (Settings → This iPhone's screen)
  function measureFps(ms) {
    return new Promise((resolve) => {
      let n = 0, start = 0, worst = 0, last = 0;
      const tick = (t) => { if (!start) start = last = t; else { worst = Math.max(worst, t - last); last = t; n++; } if (t - start < ms) requestAnimationFrame(tick); else resolve({ fps: Math.round((n * 1000) / (t - start)), worstFrameMs: Math.round(worst) }); };
      requestAnimationFrame(tick);
    });
  }
  async function displayReport() {
    const d = await ForgeHost.call("display").catch(() => ({}));
    const f = await measureFps(1000);
    return Object.assign({ page: { width: innerWidth, height: innerHeight, devicePixelRatio: devicePixelRatio }, tier: document.documentElement.classList.contains("tier-low") ? "low" : "normal",
      lite: document.documentElement.classList.contains("lite") }, d, { measured: f });
  }
  window.__forgeDisplayReport = displayReport;
  // Pop-up menus (like the builder's "⋯ More") stay fully on screen on narrow outer displays.
  const clampMenu = (d) => {
    const menu = d.querySelector(":scope > [class*='menu']");
    if (!menu) return;
    menu.style.translate = "";
    const r = menu.getBoundingClientRect(), pad = 8;
    const shift = r.left < pad ? pad - r.left : r.right > innerWidth - pad ? innerWidth - pad - r.right : 0;
    if (shift) menu.style.translate = Math.round(shift) + "px 0";
  };
  document.addEventListener("toggle", (ev) => { if (ev.target instanceof HTMLDetailsElement && ev.target.open) clampMenu(ev.target); }, true);
  addEventListener("forge-fold", () => document.querySelectorAll("details[open]").forEach(clampMenu));
  const baseOpen = window.ForgeSettings && ForgeSettings.open;
  if (baseOpen) {
    ForgeSettings.open = async function () {
      const r = await baseOpen.apply(this, arguments);
      const sheet = document.querySelector("dialog.settings-sheet");
      const after = sheet && sheet.querySelector("#set-speed");
      if (after && !sheet.querySelector("#set-iphone")) {
        const sec = document.createElement("section");
        sec.className = "set-section"; sec.id = "set-iphone";
        sec.innerHTML = '<div class="set-head"><h3>📱 This iPhone’s screen</h3></div><p class="hint">What the app sees on this display. Fold or unfold, then tap Check again.</p><div class="ios-display" role="status">Checking…</div><button type="button" class="button ghost small" data-ios-recheck>Check again</button> <button type="button" class="button ghost small" data-ios-copy>Copy report</button>';
        after.after(sec);
        const box = sec.querySelector(".ios-display");
        let last = null;
        const show = async () => {
          box.textContent = "Checking…";
          last = await displayReport();
          const w = last.window || {}, sc = last.screen || {}, nat = last.native || {};
          box.innerHTML = "";
          const rows = [["Window", Math.round(w.width) + " × " + Math.round(w.height) + " points"], ["Screen", Math.round(sc.width) + " × " + Math.round(sc.height) + " points (" + nat.width + " × " + nat.height + " pixels, ×" + last.scale + ")"],
            ["Refresh", "up to " + last.maxFps + " fps · measured " + last.measured.fps + " fps (slowest frame " + last.measured.worstFrameMs + " ms)"], ["Device", (last.machine || "") + " · " + (last.memoryGB ? last.memoryGB.toFixed(1) : "?") + " GB · " + last.cores + " cores · iOS " + last.system],
            ["Speed mode", last.lite ? "Lite effects" : "Full effects"]];
          const e = last.edges || {}, sa = last.safeArea || {};
          if (e.edges) rows.splice(2, 0, ["Screen edges kept clear", ["top", "right", "bottom", "left"].map(k => k + " " + Math.round(e.edges[k])).join(" · ") + " points" +
            ((e.regions || []).length ? " (" + e.regions.map(r => r.kind === "division" ? "fold" : "camera").join(", ") + ")" : "")]);
          else rows.splice(2, 0, ["Screen edges kept clear", ["top", "right", "bottom", "left"].map(k => k + " " + Math.round(sa[k] || 0)).join(" · ") + " points"]);
          rows.splice(3, 0, ["Full screen", (Math.round(w.width) === Math.round(sc.width) && Math.round(w.height) === Math.round(sc.height)) ? "Yes — the app fills this display" : "No — the window is smaller than the display"]);
          if (last.lowPower) rows.push(["Note", "Low Power Mode is on: iOS limits animations to 30 fps."]);
          for (const [k, v] of rows) { const p = document.createElement("p"); const b = document.createElement("b"); b.textContent = k + ": "; p.append(b, document.createTextNode(v)); box.append(p); }
        };
        sec.querySelector("[data-ios-recheck]").onclick = show;
        sec.querySelector("[data-ios-copy]").onclick = async () => { if (!last) await show(); await ForgeHost.call("copyText", { text: JSON.stringify(last, null, 1) }); window.toast && toast("Screen report copied."); };
        show();
      }
      return r;
    };
  }
})();
