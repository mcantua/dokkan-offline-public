/* Speed settings and small runtime optimizations. Loaded after every other script so it wraps
   the final versions of the shared functions. */
(function() {
  "use strict";
  const root = document.documentElement;
  const LITE_KEY = "forge-lite";
  const read = (key) => { try { return localStorage.getItem(key); } catch { return null; } };
  const write = (key, value) => { try { value == null ? localStorage.removeItem(key) : localStorage.setItem(key, value); } catch {} };
  const lite = () => root.classList.contains("lite");
  function setLite(on, remember = true) {
    root.classList.toggle("lite", !!on);
    if (remember) write(LITE_KEY, on ? "1" : "0");
  }
  setLite(read(LITE_KEY) === "1", false);
  // Phones with 4 GB of memory or less (many Galaxy A models, older Pixels): Lite effects from the
  // start, until you choose yourself in Settings → Speed.
  if (read(LITE_KEY) == null && window.__forgeDevice && window.__forgeDevice.low) setLite(true, false);

  // ---------------------------------------------------------------- bottom navigation height
  // The phone's bottom bar can be taller than the CSS default (bigger fonts, gesture area), which
  // hid the last button of a screen behind it. Its real height drives the bottom spacing.
  function measureNav() {
    const nav = document.querySelector(".mobile-nav");
    if (!nav) return;
    // iPhone Duo: the bar stands in the side status column instead (web/src/ios.css .duo-rail), nothing at the bottom
    if (root.classList.contains("duo-rail")) { root.style.setProperty("--nav-h", "0px"); return; }
    const height = nav.getBoundingClientRect().height;
    if (height > 0) root.style.setProperty("--nav-h", Math.ceil(height) + "px");
  }
  const watchNav = () => {
    measureNav();
    const nav = document.querySelector(".mobile-nav");
    if (nav && window.ResizeObserver) new ResizeObserver(measureNav).observe(nav);
    window.addEventListener("resize", measureNav);
    window.addEventListener("forgedisplay", measureNav);
  };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", watchNav, { once: true });
  else watchNav();

  // ---------------------------------------------------------------- crash backup throttle
  // The crash backup copied the whole unit into storage on every keystroke. It now runs at most
  // about once a second while typing, and immediately when the app goes to the background.
  if (typeof stashDraft === "function") {
    const stashNow = stashDraft;
    let timer = 0, last = 0;
    const run = () => { clearTimeout(timer); timer = 0; last = Date.now(); stashNow(); };
    stashDraft = function() {
      const wait = 1000 - (Date.now() - last);
      if (wait <= 0) return run();
      if (!timer) timer = setTimeout(run, wait);
    };
    window.forgePersist = () => {
      run();
      flushSave().catch(() => {});
    };
    window.addEventListener("pagehide", () => window.forgePersist());
  }

  // ---------------------------------------------------------------- preview batching
  // Several edits in the same moment now redraw the unit preview once per frame.
  if (typeof renderPreview === "function") {
    const previewNow = renderPreview;
    let frame = 0;
    renderPreview = function() {
      if (frame) return;
      frame = requestAnimationFrame(() => {
        frame = 0;
        try { previewNow(); } catch (error) { console.error(error); }
      });
    };
  }

  // ---------------------------------------------------------------- settings
  async function renderMode(set) {
    try { return await Native.call("renderMode", set ? { set } : {}); } catch { return null; }
  }
  function choice(name, value, current, title, text) {
    return '<label class="perf-choice' + (value === current ? " on" : "") + '"><input type="radio" name="' + name + '" value="' + value + '"' + (value === current ? " checked" : "") + '><span><strong>' + title + "</strong><small>" + text + "</small></span></label>";
  }
  async function open() {
    const mode = await renderMode();
    const gpu = !mode || mode.mode !== "software" ? "gpu" : "software";
    dialog("App speed", '<p>Make the app smoother on your phone.</p>' +
      '<h3>Visual effects</h3><div class="perf-choices">' +
      choice("perf-fx", "full", lite() ? "lite" : "full", "Full Dragon Ball style", "Glows, shadows and effects. Best on newer phones.") +
      choice("perf-fx", "lite", lite() ? "lite" : "full", "Lite (fastest)", "Same layout and colors without the heavy glows and animations. Best on older phones.") + "</div>" +
      (mode ? '<h3>Graphics</h3><div class="perf-choices">' +
        choice("perf-gpu", "gpu", gpu, "Fast (GPU)", "Uses your phone’s graphics chip. Recommended.") +
        choice("perf-gpu", "software", gpu, "Compatibility", "Slower, but use this if the screen flickers, stays blank or the app keeps closing.") + "</div>" +
        (mode.auto ? '<p class="notice warning">Compatibility graphics were turned on automatically after the display stopped working twice. Try Fast (GPU) again if your phone was updated.</p>' : "") : "") +
      '<p class="hint">Changes apply straight away and are kept on this device.</p>');
    const box = document.getElementById("dialog-content");
    box.querySelectorAll('input[name="perf-fx"]').forEach((input) => input.addEventListener("change", () => {
      setLite(input.value === "lite");
      mark(box, "perf-fx");
      toast(input.value === "lite" ? "Lite effects on. The app will feel lighter." : "Full Dragon Ball effects on.");
    }));
    box.querySelectorAll('input[name="perf-gpu"]').forEach((input) => input.addEventListener("change", async () => {
      const result = await renderMode(input.value);
      mark(box, "perf-gpu");
      toast(result ? (result.mode === "software" ? "Compatibility graphics on." : "Fast GPU graphics on.") : "Could not change graphics right now.", !result);
    }));
  }
  function mark(box, name) {
    box.querySelectorAll('input[name="' + name + '"]').forEach((input) => input.closest(".perf-choice").classList.toggle("on", input.checked));
  }

  // Add the "App speed" button to the home screen tools.
  if (typeof renderHome === "function") {
    const homeBefore = renderHome;
    renderHome = function() {
      const result = homeBefore.apply(this, arguments);
      const tools = document.getElementById("db-tools");
      if (tools && !tools.querySelector("[data-perf]")) {
        const button = document.createElement("button");
        button.type = "button";
        button.className = "button ghost small";
        button.dataset.perf = "open";
        button.textContent = "⚡ App speed";
        button.onclick = () => open().catch((e) => toast(e.message, true));
        tools.prepend(button);
      }
      return result;
    };
  }

  // If the app had to fall back to compatibility graphics, also use lite effects so it stays usable.
  (async () => {
    for (let i = 0; i < 200 && window.__forgeWorkspaceStartup === "loading"; i++) await new Promise((r) => setTimeout(r, 100));
    const mode = await renderMode();
    if (mode && mode.mode === "software" && mode.auto && read(LITE_KEY) == null) {
      setLite(true);
      toast("The app switched to compatibility graphics after a display problem, so lite effects were turned on. Change this in App speed.");
    }
  })();

  // ---------------------------------------------------------------- automatic smoothness
  // Until you choose Full or Lite yourself, the app watches how smoothly it scrolls and taps on
  // this phone. If many frames take too long (over 3 seconds of use), it turns Lite effects on by
  // itself, once, and says so. Nothing is measured while the app is idle.
  (() => {
    if (read(LITE_KEY) != null || read("forge-lite-auto") === "done") return;
    let sampling = false, frames = 0, slow = 0, last = 0, until = 0, total = 0;
    const tick = (t) => {
      if (last) { const gap = t - last; frames++; total++; if (gap > 40) slow++; }
      last = t;
      if (t < until) requestAnimationFrame(tick); else { sampling = false; last = 0; judge(); }
    };
    const judge = () => {
      if (frames < 90 || lite() || read(LITE_KEY) != null) return;
      if (slow / frames >= 0.3) {
        setLite(true, false);
        write("forge-lite-auto", "done");
        toast("Lite effects were turned on to keep the app smooth on this phone. You can change it in Settings → Speed.");
        stop();
      }
    };
    const start = () => {
      if (document.hidden || window.__forgeWorkspaceStartup !== "ready") return;
      until = performance.now() + 1500;
      if (!sampling) { sampling = true; requestAnimationFrame(tick); }
    };
    const opts = { passive: true, capture: true };
    const stop = () => { removeEventListener("pointerdown", start, opts); removeEventListener("scroll", start, opts); };
    addEventListener("pointerdown", start, opts);
    addEventListener("scroll", start, opts);
    // reset the window every 600 frames so one slow moment long ago doesn't decide
    setInterval(() => { if (!sampling && frames > 600) { frames = 0; slow = 0; } }, 5000);
  })();

  window.ForgePerf = { open, setLite, lite, renderMode };
})();
