/* Offline support: the app's files and the game data are kept on the phone after the first visit,
 * so it opens instantly and works without Internet. A new website version replaces them. */
const VERSION = "__VERSION__";
const SHELL = __SHELL__;
const DATA = __DATA__;   // all game data files: saved on the first visit so everything works offline
self.addEventListener("install", (e) => {
  e.waitUntil(caches.open("shell-" + VERSION).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
async function saveData() {
  const c = await caches.open("data");
  for (const f of DATA) { try { if (!(await c.match(f))) { const r = await fetch(f); if (r.ok) await c.put(f, r); } } catch (e) {} }
  // drop game data from older versions
  const keep = new Set(DATA.map((f) => new URL(f, location.href).href));
  for (const req of await c.keys()) if (!keep.has(req.url)) await c.delete(req);
}
self.addEventListener("activate", (e) => {
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== "shell-" + VERSION && k !== "data").map((k) => caches.delete(k)))).then(() => self.clients.claim()).then(saveData));
});
self.addEventListener("fetch", (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET" || url.origin !== location.origin) return;
  if (url.pathname.includes("/data/db/")) {
    // game data files have the content in their name: once saved, always valid
    e.respondWith(caches.open("data").then(async (c) => (await c.match(e.request)) || fetch(e.request).then((r) => { if (r.ok) c.put(e.request, r.clone()); return r; })));
    return;
  }
  e.respondWith(caches.match(e.request, { ignoreSearch: true }).then((hit) => hit || fetch(e.request)));
});
