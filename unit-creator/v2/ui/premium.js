/* Premium look (v2.36): small motion + colour hooks for premium.css. No feature logic lives here.
   - a screen change lets the new content rise in (#main.p-enter for one moment)
   - a builder tab change does the same for the tab body (.bld-main.p-enter)
   - the open unit's type colours the builder glow (html[data-type]) */
(function () {
  "use strict";
  const root = document.documentElement;
  function pulse(el, cls, ms) {
    if (!el || root.classList.contains("lite") || root.classList.contains("reduce-motion")) return;
    el.classList.remove(cls);
    void el.offsetWidth;   // restart the animation
    el.classList.add(cls);
    clearTimeout(el.__pTimer);
    el.__pTimer = setTimeout(() => el.classList.remove(cls), ms);
  }
  function syncType() {
    const card = document.querySelector("#bld-card .bld-card");
    const m = card && /\bt(\d)\b/.exec(card.className);
    if (m) root.setAttribute("data-type", m[1]); else root.removeAttribute("data-type");
  }
  let queued = false;
  function soon() {
    if (queued) return;
    queued = true;
    requestAnimationFrame(() => { queued = false; syncType(); });
  }
  function wrapNavigate() {
    const orig = window.navigate;
    if (typeof orig !== "function" || orig.__premium) return;
    const wrapped = async function (view) {
      const result = await orig.apply(this, arguments);
      pulse(document.getElementById("main"), "p-enter", 520);
      soon();
      return result;
    };
    wrapped.__premium = true;
    window.navigate = wrapped;
  }
  document.addEventListener("click", (e) => {
    const t = e.target.closest && e.target.closest('[data-b^="tab:"]');
    if (t) requestAnimationFrame(() => pulse(document.querySelector(".bld-main"), "p-enter", 420));
    soon();
  }, true);
  document.addEventListener("change", soon, true);
  // Quick chance picks next to an ability's "Chance to activate" slider: set the slider, then let the
  // builder save it through its normal change handler.
  document.addEventListener("click", (e) => {
    const b = e.target.closest && e.target.closest("[data-pf-chance]");
    if (!b) return;
    const label = b.closest("label");
    const range = label && label.querySelector('input[type=range][data-bf="s.chance"]');
    if (!range) return;
    e.preventDefault();
    range.value = b.getAttribute("data-pf-chance");
    range.dispatchEvent(new Event("input", { bubbles: true }));
    range.dispatchEvent(new Event("change", { bubbles: true }));
  });

  // ---- drawn icons (replace the plain symbols in the side menu, tab bar and main menu) ----
  const P = (d) => '<svg class="p-ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + d + "</svg>";
  const ICONS = {
    home: P('<path d="M3 11.5 12 4l9 7.5"/><path d="M5.5 10v9.5h5v-5h3v5h5V10"/>'),
    source: P('<path d="M12 2.5l2.6 5.6 6.1.7-4.5 4.2 1.2 6.1L12 16.1 6.6 19.1l1.2-6.1-4.5-4.2 6.1-.7z"/><path d="M12 9v5M9.5 11.5h5"/>'),
    animations: P('<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M10 9.2v5.6l4.8-2.8z" fill="currentColor"/><path d="M3 9h2M3 15h2M19 9h2M19 15h2"/>'),
    library: P('<rect x="4" y="6" width="11" height="15" rx="2" transform="rotate(-8 9.5 13.5)"/><rect x="9" y="3" width="11" height="15" rx="2"/><path d="M12.5 8h4M12.5 11h4"/>'),
    combat: P('<path d="M4 20l9-9M13 11l2-6 4 4-6 2"/><path d="M20 20l-9-9M11 11 9 5 5 9l6 2"/>'),
    movies: P('<rect x="3" y="7" width="18" height="13" rx="2"/><path d="M3 7l2.5-4h4L7 7M10 7l2.5-4h4L14 7M17 7l2.5-4"/>'),
    assets: P('<path d="M12 3l8 4.5v9L12 21l-8-4.5v-9z"/><path d="M12 12l8-4.5M12 12v9M12 12 4 7.5"/>'),
    ai: P('<path d="M12 3v3M12 18v3M3 12h3M18 12h3"/><path d="M12 7.5l1.6 2.9 2.9 1.6-2.9 1.6L12 16.5l-1.6-2.9L7.5 12l2.9-1.6z" fill="currentColor"/>'),
    templates: P('<path d="M12 3l2.7 5.5 6 .9-4.4 4.2 1 6L12 16.8 6.7 19.6l1-6L3.3 9.4l6-.9z"/>'),
    offline: P('<path d="M12 3v11M7.5 9.5 12 14l4.5-4.5"/><path d="M4 15v4.5h16V15"/>'),
    settings: P('<circle cx="12" cy="12" r="3.2"/><path d="M12 2.8v2.4M12 18.8v2.4M2.8 12h2.4M18.8 12h2.4M5.5 5.5l1.7 1.7M16.8 16.8l1.7 1.7M5.5 18.5l1.7-1.7M16.8 7.2l1.7-1.7"/>'),
    help: P('<circle cx="12" cy="12" r="9"/><path d="M9.5 9.3a2.6 2.6 0 0 1 5 .9c0 1.8-2.5 2.2-2.5 3.8"/><path d="M12 17.2h.01"/>'),
    more: P('<rect x="3.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="3.5" width="7" height="7" rx="1.5"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.5"/><rect x="13.5" y="13.5" width="7" height="7" rx="1.5"/>'),
    eza: P('<path d="M12 2.5 14.2 8l5.8.4-4.5 3.7 1.5 5.7L12 14.7 7 17.8l1.5-5.7L4 8.4 9.8 8z"/><path d="M5 21h14"/>'),
    sparking: P('<path d="M13 2 5 13.5h6L10 22l9-12h-6.5z"/>'),
  };
  function iconize() {
    document.querySelectorAll(".sidebar nav [data-nav] .nav-icon, .shell-side-extra [data-side-go] .nav-icon, .mobile-nav .nav-glyph").forEach((el) => {
      if (el.querySelector(".p-ico")) return;
      const b = el.closest("[data-nav],[data-side-go],.shell-more-button");
      const key = b && (b.dataset.nav || b.dataset.sideGo || (b.classList.contains("shell-more-button") ? "more" : ""));
      if (ICONS[key]) el.innerHTML = ICONS[key];
    });
  }
  // ---- Home: a game-style main menu under the banner (shortcuts to features that already exist) ----
  const MENU = [
    ["sparking", "Sparking characters", "Build from Sparking units", () => window.navigate("library").then(() => setTimeout(() => { const f = document.querySelector('[data-library-filter="sparking"]'); if (f) f.click(); }, 80))],
    ["offline", "Downloads", "Game data for offline use", () => window.ForgeShell && ForgeShell.go("offline")],
  ];
  function homeMenu() {
    const hero = document.querySelector("#main .db-hero");   // the Dokkan-style home has its own banners now
    if (!hero || document.querySelector("#main .p-menu, #main .dk-stage")) return;
    const box = document.createElement("nav");
    box.className = "p-menu"; box.setAttribute("aria-label", "Main menu");
    for (const [key, title, sub, act] of MENU) {
      if (key === "sparking" && document.documentElement.classList.contains("web-version")) continue;
      const b = document.createElement("button");
      b.type = "button"; b.dataset.pm = key;
      b.innerHTML = (ICONS[key === "animate" ? "animations" : key] || "") + '<span class="p-txt"><span>' + title + "</span><small>" + sub + "</small></span>";
      b.onclick = () => { try { const r = act(); if (r && r.catch) r.catch(() => {}); } catch (e) {} };
      box.append(b);
    }
    hero.after(box);
  }
  let iconQueued = false;
  const refresh = () => { if (iconQueued) return; iconQueued = true; requestAnimationFrame(() => { iconQueued = false; iconize(); homeMenu(); }); };
  window.addEventListener("load", () => {
    refresh();
    try { new MutationObserver(refresh).observe(document.body, { childList: true, subtree: true }); } catch (e) {}
  });
  window.addEventListener("load", () => { wrapNavigate(); soon(); });
  if (document.readyState !== "loading") wrapNavigate();
  else document.addEventListener("DOMContentLoaded", wrapNavigate);
})();
