/* One complete shell+data snapshot per worker version. An incomplete update never activates.
 * No skipWaiting/clients.claim: the browser waits for old controlled pages to close before
 * activating the new worker, so existing scripts keep their matching immutable snapshot. */
const VERSION = "__VERSION__";
const SHELL = __SHELL__;
const DATA = __DATA__;
const INTEGRITY = __INTEGRITY__;
const PREFIX = "dokkan-unit-creator-v2-" + encodeURIComponent(self.registration.scope) + "-";
const CACHE = PREFIX + VERSION;
const FILES = [...new Set([...SHELL, ...DATA].map((path) => new URL(path, self.registration.scope).href))];
const REQUIRED = new Set(FILES);
const HASHES = new Map(Object.entries(INTEGRITY).map(([path, hash]) => [new URL(path, self.registration.scope).href, hash]));
// Only content-addressed files can be copied from an older cache. Mutable manifests/HTML
// always come from this install's network snapshot; they never come from a shared old cache.
const immutable = (url) => /\/(?:data\/(?:db|sparking-db)\/(?:part|delta)\d+\.[a-f0-9]+\.json\.gz|(?:start|app)\.[a-f0-9]+\.(?:js|css))$/.test(url);

self.addEventListener("install", (e) => {
  e.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    try {
      // Writes go only to the unactivated version. Wait for every write before cleaning up
      // a failed install, so a late completion cannot leave a partial snapshot behind.
      const results = await Promise.allSettled(FILES.map(async (url) => {
        const reused = immutable(url) ? await caches.match(url) : null;
        const response = reused && reused.ok ? reused : await fetch(new Request(url, { cache: "reload" }));
        if (!response.ok || response.type === "opaque") throw new Error("Offline update is missing " + new URL(url).pathname);
        const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", await response.clone().arrayBuffer()));
        const actual = Array.from(digest, (byte) => byte.toString(16).padStart(2, "0")).join("");
        if (actual !== HASHES.get(url)) throw new Error("Offline update checksum mismatch: " + new URL(url).pathname);
        await cache.put(url, response);
      }));
      const failure = results.find((r) => r.status === "rejected");
      if (failure) throw failure.reason;
    } catch (error) {
      await caches.delete(CACHE);
      throw error;
    }
  })());
});

self.addEventListener("activate", (e) => {
  // Normal activation happens after old clients close. Only prune this app/scope's owned
  // version caches. Legacy generic "data"/"shell-*" caches may belong to another scope.
  e.waitUntil(caches.keys().then((keys) => Promise.all(keys.filter((name) => name.startsWith(PREFIX) && name !== CACHE).map((name) => caches.delete(name)))));
});

self.addEventListener("fetch", (e) => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET" || url.origin !== location.origin) return;
  e.respondWith((async () => {
    const cache = await caches.open(CACHE), hit = await cache.match(e.request, { ignoreSearch: true });
    if (hit) return hit;
    url.search = "";
    // Do not recover a missing mutable manifest from a newer online version into an old
    // running client. A complete update/reload is needed if the browser evicted a snapshot.
    if (REQUIRED.has(url.href)) return new Response("Offline content is missing. Reload to update the application.", { status: 503, headers: { "Content-Type": "text/plain; charset=utf-8" } });
    return fetch(e.request);
  })());
});
