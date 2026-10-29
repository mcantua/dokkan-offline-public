"""Original background art for the v2.36 look (procedural, no outside images). Writes WebP files
to /home/claude/work/art-src/out and v2/ui/premium-art.css (data URIs)."""
import numpy as np, base64, io, pathlib
from PIL import Image, ImageFilter
rng = np.random.default_rng(7)
OUT = pathlib.Path("/home/claude/work/art-src/out"); OUT.mkdir(exist_ok=True)

def fbm(h, w, octaves=6, seed=1):
    r = np.random.default_rng(seed); acc = np.zeros((h, w)); amp = 1.0; tot = 0
    for o in range(octaves):
        s = 2 ** (o + 2)
        g = r.random((s + 1, int(s * w / h) + 2))
        im = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        acc += np.asarray(im, float) / 255 * amp; tot += amp; amp *= 0.5
    return acc / tot

def sky(w=1600, h=1000):
    y, x = np.mgrid[0:h, 0:w].astype(float)
    cx, cy = w * 0.78, h * 0.18
    dx, dy = (x - cx) / w, (y - cy) / w
    r = np.sqrt(dx * dx + dy * dy); a = np.arctan2(dy, dx)
    # base vertical gradient: royal blue to deep indigo
    t = y / h
    top = np.array([12, 58, 150]); mid = np.array([7, 32, 100]); bot = np.array([4, 12, 46])
    base = np.where(t[..., None] < .5, top + (mid - top) * (t[..., None] / .5), mid + (bot - mid) * ((t[..., None] - .5) / .5))
    # light burst
    glow = np.exp(-r * 3.2)[..., None]
    core = np.exp(-r * 14)[..., None]
    rays = (0.5 + 0.5 * np.sin(a * 46 + np.sin(a * 7) * 2.2)) ** 6
    rays *= np.clip(1 - r * 1.1, 0, 1)
    img = base + glow * np.array([60, 120, 210]) * .55 + core * np.array([255, 240, 200]) * .55 + rays[..., None] * np.array([110, 170, 240]) * .16
    # cloud bank (bottom) and wisps
    n = fbm(h, w, 6, 3)
    band = np.clip((y / h - 0.62) * 3.0, 0, 1)
    cloud = np.clip((n - 0.48) * 4.0, 0, 1) * band
    img = img * (1 - cloud[..., None] * .75) + cloud[..., None] * np.array([90, 130, 200]) * .6
    wisps = np.clip((fbm(h, w, 5, 9) - 0.6) * 3, 0, 1) * np.clip(1 - y / h * 1.4, 0, 1)
    img += wisps[..., None] * np.array([60, 110, 200]) * .25
    # sparkles
    for _ in range(260):
        px, py = rng.integers(0, w), rng.integers(0, int(h * .8)); s = rng.random() ** 3 * 2.2 + .4
        yy, xx = np.ogrid[-6:7, -6:7]; k = np.exp(-(xx * xx + yy * yy) / (2 * s * s)) * (rng.random() * 110 + 40)
        y0, y1, x0, x1 = max(0, py - 6), min(h, py + 7), max(0, px - 6), min(w, px + 7)
        img[y0:y1, x0:x1] += k[(y0 - py + 6):(y1 - py + 6), (x0 - px + 6):(x1 - px + 6), None] * np.array([1, 1, 1])
    # vignette
    v = np.clip(1 - ((x / w - .5) ** 2 + (y / h - .45) ** 2) * 0.9, .55, 1)
    img *= v[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))

def burst(w=900, h=520):
    """Card-sized art for the big Create tile: an energy sphere with a ring of rays (no characters)."""
    y, x = np.mgrid[0:h, 0:w].astype(float); cx, cy = w * .72, h * .5
    dx, dy = (x - cx) / h, (y - cy) / h; r = np.sqrt(dx * dx + dy * dy); a = np.arctan2(dy, dx)
    base = np.array([255, 120, 0]) * np.clip(1 - x / w * .2, 0, 1)[..., None]
    base = base * 0 + np.array([226, 92, 0]) + (np.array([255, 196, 40]) - np.array([226, 92, 0])) * np.exp(-r * 2)[..., None]
    rays = (0.5 + 0.5 * np.sin(a * 36)) ** 8 * np.clip(1.4 - r, 0, 1)
    sphere = np.clip(1 - r / .2, 0, 1) ** .6
    img = base + rays[..., None] * np.array([255, 230, 150]) * .55 + sphere[..., None] * np.array([255, 255, 230]) * .9
    ring = np.exp(-((r - .26) / .012) ** 2) * .8
    img += ring[..., None] * np.array([255, 255, 200])
    img *= np.clip(.4 + x / w * .45, 0, 1)[..., None]   # darker on the left, where the words sit
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))

def uri(im, q):
    b = io.BytesIO(); im.save(b, "WEBP", quality=q, method=6); d = b.getvalue()
    return "data:image/webp;base64," + base64.b64encode(d).decode(), len(d)

s = sky(); s.save(OUT / "sky.png"); u1, n1 = uri(s.resize((1280, 800), Image.LANCZOS), 62)
bu = burst(); bu.save(OUT / "burst.png"); u2, n2 = uri(bu, 66)
css = ("/* v2.36 original background art (made by art-src/make_art.py, procedural; no outside images) */\n"
       "html.dbz{--p-art-sky:url(" + u1 + ");--p-art-burst:url(" + u2 + ")}\n")
pathlib.Path("/home/claude/work/v2/ui/premium-art.css").write_text(css)
print("sky", n1, "burst", n2)
