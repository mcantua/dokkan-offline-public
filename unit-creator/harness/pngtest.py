import base64, io
from playwright.sync_api import sync_playwright
from harness import mime, UI
html = b"""<!doctype html><meta charset=utf-8><script type=module>
import {decodeNativePNGAsync, pngDecodingStatus} from '/vendor/media/preview-png-async.js';
window.run = async (b64s) => {
  const out = [];
  for (const b64 of b64s) {
    const bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
    try {
      const d = await decodeNativePNGAsync(bytes);
      // reference: browser decode via canvas (unpremultiplied compare on opaque pixels)
      const img = await createImageBitmap(new Blob([bytes], {type:'image/png'}), {premultiplyAlpha:'none', colorSpaceConversion:'none'});
      const c = new OffscreenCanvas(img.width, img.height), g = c.getContext('2d'); g.drawImage(img, 0, 0);
      const ref = g.getImageData(0, 0, img.width, img.height).data;
      let diff = 0; for (let i = 0; i < ref.length; i += 4) if (ref[i+3] === 255) for (let k = 0; k < 3; k++) diff = Math.max(diff, Math.abs(ref[i+k] - d.rgba[i+k]));
      out.push({w: d.width, h: d.height, maxDiff: diff, prem: d.metadata.premultiplied});
    } catch (e) { out.push({error: String(e)}); }
  }
  return {out, status: pngDecodingStatus()};
};
window.ready = true;
</script>"""
def route(r):
    p = r.request.url.split("forge.local/", 1)[1].split("?")[0]
    if p == "t.html": return r.fulfill(body=html, headers={"content-type": "text/html"})
    f = UI / p
    if f.is_file(): return r.fulfill(body=f.read_bytes(), headers={"content-type": mime(p)})
    return r.fulfill(status=404, body="")
# make test PNGs with PIL if available, else from assets
pngs = []
try:
    from PIL import Image
    import random
    for mode, size in [("RGBA", (64, 48)), ("RGB", (33, 17)), ("P", (40, 40)), ("L", (20, 30)), ("LA", (9, 9)), ("RGBA", (1024, 512))]:
        im = Image.new(mode if mode != "P" else "RGB", size)
        px = im.load()
        for x in range(size[0]):
            for y in range(size[1]):
                v = (x * 7 + y * 13) % 256
                px[x, y] = {"RGBA": (v, 255 - v, (v * 3) % 256, 255 if (x + y) % 3 else 128), "RGB": (v, 255 - v, 7), "P": (v, v // 2, 255 - v), "L": v, "LA": (v, 255)}[mode]
        if mode == "P": im = im.convert("P", palette=Image.ADAPTIVE, colors=200)
        b = io.BytesIO(); im.save(b, "PNG"); pngs.append(base64.b64encode(b.getvalue()).decode())
    # interlaced
    b = io.BytesIO(); Image.new("RGB", (50, 50), (10, 200, 30)).save(b, "PNG", interlace=1) if False else None
except ImportError:
    print("no PIL")
with sync_playwright() as p:
    br = p.chromium.launch(); pg = br.new_page(); pg.route("**/*", route)
    logs = []; pg.on("console", lambda m: logs.append(m.text)); pg.on("pageerror", lambda e: logs.append("ERR " + str(e)))
    pg.goto("https://forge.local/t.html"); pg.wait_for_function("window.ready === true", timeout=20000)
    print(pg.evaluate("b => window.run(b)", pngs)); print(logs[:10]); br.close()
