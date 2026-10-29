/* The iPhone app's native services, for the app's own code (ios-native.js).
 * Routes are served by the app (Host.m) at the page's own origin:
 *   /__net?u=URL   any web address, fetched by the phone itself (no cross-site limits)
 *   /__file/PATH   the app's storage on the phone (GET with Range, PUT, DELETE)
 *   /__mirror/HOST/PATH  a saved copy of https://HOST/PATH (downloaded on first use)
 * and webkit.messageHandlers.ForgeHost for files, downloads, the Keychain and the Share sheet. */
(function () {
  "use strict";
  const handler = () => window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ForgeHost;
  if (!handler()) return;
  const ORIGIN = location.origin;
  const enc = (p) => String(p).split("/").map(encodeURIComponent).join("/");
  const listeners = new Map();   // download id -> progress callback
  addEventListener("forge-host", (e) => {
    const d = e.detail || {};
    if (d.type === "progress" && listeners.has(d.id)) { try { listeners.get(d.id)(d); } catch (x) {} }
  });
  let seq = 0;
  const host = {
    available: true,
    origin: ORIGIN,
    call(op, args) { return handler().postMessage(Object.assign({ op }, args || {})); },
    fileUrl: (path) => ORIGIN + "/__file/" + enc(path),
    mirrorUrl: (url) => { const u = new URL(url); return ORIGIN + "/__mirror/" + u.host + u.pathname + u.search; },
    netUrl: (url) => ORIGIN + "/__net?u=" + encodeURIComponent(url),
    /** fetch() any web address. headers are passed on by the app. */
    net(url, opts) {
      opts = opts || {};
      const h = {};
      for (const [k, v] of Object.entries(opts.headers || {})) {
        const lk = k.toLowerCase();
        if (lk === "content-type" || lk === "range" || lk === "accept") h[k] = v; else h["X-Forge-Header-" + k] = v;
      }
      return fetch(host.netUrl(url), { method: opts.method || "GET", headers: h, body: opts.body, signal: opts.signal });
    },
    async readBytes(path) { const r = await fetch(host.fileUrl(path)); if (!r.ok) return null; return new Uint8Array(await r.arrayBuffer()); },
    async readText(path) { const r = await fetch(host.fileUrl(path)); if (!r.ok) return null; return r.text(); },
    async readJson(path) { const t = await host.readText(path); if (t == null) return null; try { return JSON.parse(t); } catch (e) { return null; } },
    async exists(path) { return !!(await host.call("stat", { path })); },
    stat: (path) => host.call("stat", { path }),
    list: (path, deep) => host.call("list", { path, deep: !!deep }),
    usage: (path) => host.call("usage", { path }),
    remove: (path) => host.call("remove", { path }),
    move: (path, to) => host.call("move", { path, to }),
    mkdir: (path) => host.call("mkdir", { path }),
    writeText: (path, text) => host.call("write", { path, text: String(text) }),
    writeJson: (path, value) => host.call("write", { path, text: JSON.stringify(value) }),
    /** Saves bytes (Uint8Array / ArrayBuffer / Blob). Big files go straight through the app; if this
     *  iOS version doesn't pass request bodies to the app, they're sent in pieces instead. */
    async writeBytes(path, data) {
      const blob = data instanceof Blob ? data : new Blob([data]);
      if (!host._noBody) {
        try {
          const r = await fetch(host.fileUrl(path), { method: "PUT", body: blob });
          if (r.ok) return blob.size;
          if (r.headers.get("X-Forge-No-Body")) host._noBody = true; else throw new Error("Couldn't save the file. Is the phone full?");
        } catch (e) { if (!host._noBody) throw e; }
      }
      const CHUNK = 3 * 1024 * 1024;
      for (let off = 0, first = true; off < blob.size || first; off += CHUNK, first = false) {
        const part = new Uint8Array(await blob.slice(off, off + CHUNK).arrayBuffer());
        await host.call("write", { path, base64: toBase64(part), append: !first });
      }
      return blob.size;
    },
    /** Downloads a web address straight to a file. onProgress({bytes,total}). */
    download(url, path, opts) {
      opts = opts || {};
      const id = "d" + (++seq) + "-" + Date.now().toString(36);
      if (opts.onProgress) listeners.set(id, opts.onProgress);
      if (opts.signal) opts.signal.addEventListener("abort", () => host.call("cancel", { id }), { once: true });
      return host.call("download", { url, path, id, headers: opts.headers || {}, keepErrors: !!opts.keepErrors, progress: !!opts.onProgress })
        .finally(() => listeners.delete(id));
    },
    secretGet: (key) => host.call("secretGet", { key }),
    secretSet: (key, value) => host.call("secretSet", { key, value: String(value) }),
    secretDelete: (key) => host.call("secretDelete", { key }),
    share: (path, name) => host.call("share", { path, name }),
    openURL: (url) => host.call("openURL", { url }),
    keepAwake: (on) => host.call("keepAwake", { on: !!on }),
    info: () => host.call("info"),
  };
  function toBase64(bytes) {
    let bin = "";
    for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
    return btoa(bin);
  }
  host.toBase64 = toBase64;
  window.ForgeHost = host;
})();
