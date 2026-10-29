"""Package the actual site-artifact output, including data, workers and fonts, into one HTML.

This preserves the browser version's capabilities; it does not emulate native phone services.
"""
import base64
import gzip
import html
import json
import mimetypes
import pathlib
import re


def bundle(site, output, version, changes, compression_threshold=14 * 1024 * 1024):
    site, output = pathlib.Path(site).resolve(), pathlib.Path(output)
    if not (site / "data/db/manifest.json.gz.b64.txt").is_file():
        raise ValueError("Build site-artifact with real game data first; no placeholder page will be exported.")

    def read(name, parent=""):
        if re.match(r"[a-zA-Z][\w+.-]*:|//", name):
            raise ValueError("External dependency cannot be bundled: " + name)
        p = (site / parent / name.split("?", 1)[0].split("#", 1)[0]).resolve()
        if not p.is_relative_to(site) or not p.is_file():
            raise ValueError("Missing local dependency: " + name)
        return p

    def data_url(p):
        mime = mimetypes.guess_type(p.name)[0] or "application/octet-stream"
        if p.suffix == ".js": mime = "text/javascript"
        return "data:" + mime + ";base64," + base64.b64encode(p.read_bytes()).decode()

    def css(p):
        def replace(m):
            target = m[1].strip(" \t\r\n\"'")
            if target.startswith(("data:", "#")): return m[0]
            return 'url("' + data_url(read(target, p.relative_to(site).parent)) + '")'
        text = p.read_text()
        if re.search(r"@import\b", text): raise ValueError("CSS imports must be bundled before export")
        return re.sub(r"url\(([^)]+)\)", replace, text, flags=re.I).replace("</style", "<\\/style")

    page = (site / "index.html").read_text()
    # Scripts/styles already embedded in the document do not need another copy in the fetch map.
    embedded = set(re.findall(r'<script\b[^>]*\bsrc="([^"]+)"', page, re.I))
    embedded.update(re.findall(r'<link\b[^>]*rel="stylesheet"[^>]*href="([^"]+)"', page, re.I))
    resources = {}
    for p in sorted(site.rglob("*")):
        if p.is_file() and p.name != "index.html":
            name = p.relative_to(site).as_posix()
            if name in embedded: continue
            mime = mimetypes.guess_type(p.name)[0] or "application/octet-stream"
            if p.suffix == ".js": mime = "text/javascript"
            # Artifact data is already base64 text; encoding it again wastes space and phone memory.
            resources[name] = [mime, p.read_text(), "text"] if name.endswith(".b64.txt") else [mime, base64.b64encode(p.read_bytes()).decode()]
    # Blob workers have no directory. Inline every static import of our known
    # workers, including both dependencies of the existing instant movie editor.
    for worker in ("web/argon2-worker.js", "vendor/media/instant-worker.js", "web/web-compat-worker.js"):
        if worker not in resources: continue
        def inline_imports(match):
            args = match[1]
            if not re.fullmatch(r'''\s*(["'])[^"'\r\n]+\1(?:\s*,\s*(["'])[^"'\r\n]+\2)*\s*''', args):
                raise ValueError("Worker imports must use static local paths: " + worker)
            names = re.findall(r'''["']([^"']+)["']''', args)
            return "importScripts(" + ",".join(json.dumps(data_url(read(name, pathlib.PurePosixPath(worker).parent))) for name in names) + ")"
        script = re.sub(r'importScripts\(([^()]*)\)', inline_imports, (site / worker).read_text())
        resources[worker][1] = base64.b64encode(script.encode()).decode()
    runtime = r'''
(() => {
  const files = __FILES__, base = 'https://unit-creator.invalid/';
  window.__forgeStandaloneBase = base;
  const bytes = (name) => files[name][2] === 'text' ? new TextEncoder().encode(files[name][1]) : Uint8Array.from(atob(files[name][1]), c => c.charCodeAt(0));
  const key = (value) => {
    try { const u = new URL(value instanceof Request ? value.url : String(value), base);
      if (u.origin === new URL(base).origin) return decodeURIComponent(u.pathname.slice(1));
      const here = new URL('.', location.href);
      if (u.protocol !== here.protocol || u.host !== here.host || !u.pathname.startsWith(here.pathname)) return null;
      const name = decodeURIComponent(u.pathname.slice(here.pathname.length));
      return Object.prototype.hasOwnProperty.call(files, name) ? name : null;
    } catch { return null; }
  };
  const originalFetch = window.fetch.bind(window);
  window.fetch = async (input, init) => {
    const name = key(input);
    if (name !== null) return files[name] ? new Response(bytes(name), {headers: {'Content-Type': files[name][0]}}) : new Response('Not bundled', {status: 404});
    return originalFetch(input, init);
  };
  if (window.Worker) {
    const OriginalWorker = window.Worker;
    window.Worker = class extends OriginalWorker {
      constructor(url, options) {
        const name = key(url), local = name && files[name];
        const objectURL = local ? URL.createObjectURL(new Blob([bytes(name)], {type: local[0]})) : null;
        try { super(objectURL || url, options); }
        catch (e) { if (objectURL) URL.revokeObjectURL(objectURL); throw e; }
        this.objectURL = objectURL;
      }
      terminate() { super.terminate(); if (this.objectURL) URL.revokeObjectURL(this.objectURL); }
    };
  }
})();
'''.replace("__FILES__", json.dumps(resources, separators=(",", ":")))
    # Artifact HTML is a head/body fragment. Retain external-script defer semantics using embedded data URLs.
    scripts = re.compile(r'<script\b([^>]*?)\bsrc="([^"]+)"([^>]*)>\s*</script>', re.I)
    page = scripts.sub(lambda m: '<script' + m[1] + 'src="' + data_url(read(m[2])) + '"' + m[3] + '></script>', page)
    page = re.sub(r'<link\b[^>]*rel="stylesheet"[^>]*>', lambda m: '<style>' + css(read(re.search(r'href="([^"]+)"', m[0])[1])) + '</style>', page, flags=re.I)
    page = re.sub(r'(<(?:img|source)\b[^>]*\bsrc=")([^"]+)(")',
                  lambda m: m[0] if m[2].startswith("data:") else m[1] + data_url(read(m[2])) + m[3], page, flags=re.I)
    # The original fragment starts with head elements and then the app shell.
    boundary = page.find('<a class="skip-link"')
    if boundary < 0: raise ValueError("Unrecognized artifact page structure")
    head, body = page[:boundary], page[boundary:]
    banner = '<header id="test-page-info" role="note"><strong>Unit Creator ' + html.escape(version) + '</strong><br>' + html.escape(changes) + '</header>'
    result = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">' + \
        '<script>' + runtime + '</script>' + head + \
        '<style>#test-page-info{position:relative;z-index:1;padding:10px 16px;background:#101525;color:#fff;font:14px/1.4 system-ui}</style></head><body>' + banner + body + '</body></html>'
    raw = result.encode()
    if len(raw) > compression_threshold:
        # A single compressed payload avoids encoding duplicate base64 entropy in large data packs.
        # Native DecompressionStream is already required by the artifact data loader (Safari 16.4+).
        payload = base64.b64encode(gzip.compress(raw, compresslevel=9, mtime=0)).decode()
        loader = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><title>Unit Creator test page</title></head><body style="background:#101525;color:white;font:16px system-ui">''' + banner + '''<p id="standalone-loading">Opening Unit Creator…</p><script id="standalone-payload" type="application/octet-stream">''' + payload + '''</script><script>
(async () => {
  try {
    const encoded = document.getElementById('standalone-payload').textContent;
    const bytes = Uint8Array.from(atob(encoded), c => c.charCodeAt(0));
    const page = await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).text();
    document.open(); document.write(page); document.close();
  } catch (_) {
    document.getElementById('standalone-loading').textContent = 'Could not open the test page. Use Safari 16.4 or newer, or a current browser.';
  }
})();
</script></body></html>'''
        if len(loader.encode()) < len(raw) * 0.95:
            result = loader
    output.parent.mkdir(parents=True, exist_ok=True)
    part = output.with_suffix(".part")
    try:
        part.write_text(result)
        part.replace(output)
    finally:
        part.unlink(missing_ok=True)
    print(f"standalone: {output} ({output.stat().st_size / 1e6:.1f} MB)")
