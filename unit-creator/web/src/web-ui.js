/* Web version adjustments, loaded after the app's own scripts:
 * - Android-only tools are hidden (animation previews, offline packs, APK imports, AI app links).
 * - The Animate screen explains that animations come in a later web update.
 * - Offline support and "Add to Home Screen" (keeps your units safe on iPhone). */
(function () {
  "use strict";
  if (!window.forgeNative || !window.forgeNative.web) return;
  const hosted = !!window.__forgeArtifact;
  document.documentElement.classList.toggle("web-hosted", hosted);
  if (hosted) { const pill = document.querySelector(".local-pill"); if (pill) pill.lastChild.textContent = " Saved to your Claude account"; }
  // the iPhone app (.ipa) has everything built in: no service worker, no "Add to Home Screen" tip
  const iosApp = !!(window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ForgeFiles);
  document.documentElement.classList.toggle("web-ios-app", iosApp);
  if (iosApp) { const pill = document.querySelector(".local-pill"); if (pill) pill.lastChild.textContent = " Saved on this iPhone"; }
  // offline support (not available inside Claude)
  if (!hosted && !iosApp && "serviceWorker" in navigator) addEventListener("load", () => navigator.serviceWorker.register("sw.js").catch(() => {}));
  const standalone = iosApp || matchMedia("(display-mode: standalone)").matches || navigator.standalone === true;
  document.documentElement.classList.toggle("web-standalone", standalone);

  // Animate: not in the web version yet
  if (typeof renderStudio === "function") {
    renderStudio = async function () {
      document.documentElement.classList.remove("tl-active");
      main('<section class="web-note"><div class="web-note-art" aria-hidden="true">▶</div><h1>Animations are coming to the web version</h1>' +
        '<p>Making animations needs the animation player, which only runs in the Android app for now. Everything else works here: find characters, build and edit units, save them and export .eclp files for Eclipse.</p>' +
        '<button type="button" class="button" id="web-note-create">＋ Create a unit</button></section>');
      document.getElementById("web-note-create").onclick = () => navigate("source");
    };
  }
  // movies need the player too
  const baseNavigate = typeof navigate === "function" ? navigate : null;
  if (baseNavigate) navigate = async function (view) { if (view === "movies" || view === "assets" || view === "ai" || view === "combat-movies") view = view === "movies" ? "animations" : "home"; return baseNavigate.apply(this, [view].concat([].slice.call(arguments, 1))); };

  // iPhone: suggest Add to Home Screen once (it also keeps your units from being cleared by Safari)
  const ios = /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
  let told = false;
  try { told = localStorage.getItem("web-install-told") === "1"; } catch (e) {}
  if (!hosted && ios && !standalone && !told) {
    addEventListener("load", () => setTimeout(() => {
      const box = document.createElement("div");
      box.id = "web-install";
      box.setAttribute("role", "note");
      box.innerHTML = '<strong>Add it to your Home Screen</strong><p>Tap <b>Share</b> <span aria-hidden="true">⬆︎</span> then <b>Add to Home Screen</b>. It opens like an app, works offline, and Safari won\'t clear your saved units.</p><button type="button" class="button small">Got it</button>';
      document.body.append(box);
      box.querySelector("button").onclick = () => { try { localStorage.setItem("web-install-told", "1"); } catch (e) {} box.remove(); };
    }, 2500));
  }
})();
