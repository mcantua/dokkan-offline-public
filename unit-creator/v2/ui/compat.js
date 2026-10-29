/* Phone compatibility, loaded first and written in old JavaScript so it runs everywhere.
 * - Array/String .at() for older Android System WebView versions.
 * - Phone tier: phones with 4 GB of memory or less (or 4 processor cores or less), such as many
 *   Galaxy A models, get lighter defaults (see perf.js and the animation player).
 * - Out-of-date Android System WebView: a clear message with a button to update it, because the
 *   app's screens, colours and animation player need a recent version. */
(function () {
  "use strict";
  function at(n) {
    n = Math.trunc(n) || 0;
    if (n < 0) n += this.length;
    if (n < 0 || n >= this.length) return undefined;
    return this[n];
  }
  try {
    if (!Array.prototype.at) Object.defineProperty(Array.prototype, "at", { value: at, writable: true, configurable: true });
    if (!String.prototype.at) Object.defineProperty(String.prototype, "at", { value: at, writable: true, configurable: true });
  } catch (e) {}
  var nav = window.navigator || {};
  var memory = Number(nav.deviceMemory) || 0, cores = Number(nav.hardwareConcurrency) || 0;
  var low = (memory > 0 && memory <= 4) || (cores > 0 && cores <= 4);
  var match = /Chrome\/(\d+)/.exec(nav.userAgent || ""), chrome = match ? Number(match[1]) : 0;
  window.__forgeDevice = { memory: memory, cores: cores, low: low, webview: chrome, ratio: window.devicePixelRatio || 1 };
  var root = document.documentElement;
  if (low) root.className += " tier-low";
  if (!chrome || chrome >= 111) return;
  // Old WebView: say so once per version, with a one-tap update.
  var key = "forge-webview-warned-" + chrome;
  try { if (localStorage.getItem(key)) return; } catch (e) {}
  function show() {
    var box = document.createElement("div");
    box.id = "webview-update";
    box.setAttribute("role", "alert");
    box.innerHTML = "<strong>Update needed for a smooth app</strong><p>Your phone's <b>Android System WebView</b> is version " + chrome +
      ". This app needs version 111 or newer to look right and play animations smoothly. Update it (and Chrome) in the Play Store, then reopen the app.</p>" +
      '<div class="row"><button type="button" class="button" id="webview-update-go">Update in Play Store</button><button type="button" class="button ghost" id="webview-update-later">Later</button></div>';
    document.body.appendChild(box);
    document.getElementById("webview-update-later").onclick = function () { try { localStorage.setItem(key, "1"); } catch (e) {} box.parentNode.removeChild(box); };
    document.getElementById("webview-update-go").onclick = function () {
      if (window.Native && Native.call) Native.call("openStore", { app: "webview" }).catch(function () {});
    };
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", show); else show();
})();
