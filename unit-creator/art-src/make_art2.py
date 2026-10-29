"""v2.36 'Dragon Ball intensity' art (procedural, original): a dark battlefield sky with a fiery ki aura, speed lines and
blue lightning; plus a golden Super-Saiyan-style aura for the Home banner. Writes v2/ui/premium-art.css (data URIs)."""
import numpy as np, base64, io, pathlib
from PIL import Image, ImageDraw, ImageFilter
rng = np.random.default_rng(11)
OUT = pathlib.Path("/home/claude/work/art-src/out"); OUT.mkdir(exist_ok=True)

def fbm(h, w, octaves=6, seed=1, sx=1.0, sy=1.0):
    r = np.random.default_rng(seed); acc = np.zeros((h, w)); amp = 1.0; tot = 0
    for o in range(octaves):
        s = 2 ** (o + 2)
        g = r.random((max(2, int(s * sy)) + 1, max(2, int(s * sx * w / h)) + 1))
        im = Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
        acc += np.asarray(im, float) / 255 * amp; tot += amp; amp *= 0.5
    return acc / tot

FIRE = np.array([[0, 0, 0], [90, 6, 10], [200, 30, 0], [255, 110, 0], [255, 200, 40], [255, 250, 210]], float)
def ramp(t, stops=FIRE):
    t = np.clip(t, 0, 1) * (len(stops) - 1); i = np.clip(t.astype(int), 0, len(stops) - 2); f = (t - i)[..., None]
    return stops[i] * (1 - f) + stops[i + 1] * f

def lightning(draw, x0, y0, x1, y1, w, seg=14, jitter=26):
    pts = [(x0, y0)]
    for k in range(1, seg):
        t = k / seg; pts.append((x0 + (x1 - x0) * t + rng.normal(0, jitter), y0 + (y1 - y0) * t + rng.normal(0, jitter)))
    pts.append((x1, y1)); draw.line(pts, fill=(255, 255, 255), width=w, joint="curve")

def battlefield(w=1280, h=800):
    y, x = np.mgrid[0:h, 0:w].astype(float)
    t = y / h
    base = np.array([16, 8, 34]) * (1 - t[..., None]) + np.array([30, 10, 14]) * t[..., None]
    cx, cy = w * .78, h * 1.05
    dx, dy = (x - cx) / h, (y - cy) / h; r = np.sqrt(dx * dx + dy * dy); a = np.arctan2(dy, dx)
    n = fbm(h, w, 6, 4, sx=1.6, sy=0.6)            # stretched: tall flame tongues
    flame = np.clip((1.05 - r * 1.25) + (n - .5) * 1.3, 0, 1) ** 1.6
    img = base * (1 - flame[..., None] * .9) + ramp(flame * .92) * flame[..., None] ** .5
    rays = (0.5 + 0.5 * np.sin(a * 70)) ** 30 * np.clip(r - .25, 0, 1) * .16
    img += rays[..., None] * np.array([255, 220, 180])
    # embers
    for _ in range(320):
        px, py = rng.integers(0, w), rng.integers(0, h); s = rng.random() ** 3 * 2 + .5
        yy, xx = np.ogrid[-6:7, -6:7]; k = np.exp(-(xx * xx + yy * yy) / (2 * s * s)) * (rng.random() * 170 + 50)
        y0, y1, x0, x1 = max(0, py - 6), min(h, py + 7), max(0, px - 6), min(w, px + 7)
        img[y0:y1, x0:x1] += k[(y0 - py + 6):(y1 - py + 6), (x0 - px + 6):(x1 - px + 6), None] * np.array([1, .7, .3])
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    # electric blue lightning (SSJ2 sparks) with glow
    layer = Image.new("RGB", (w, h)); d = ImageDraw.Draw(layer)
    for _ in range(3):
        x0 = rng.integers(int(w * .55), w - 30); y0 = rng.integers(0, int(h * .3))
        lightning(d, x0, y0, x0 + rng.integers(-90, 90), y0 + rng.integers(220, 380), 2, 9, 12)
    glow = layer.filter(ImageFilter.GaussianBlur(6))
    blue = np.asarray(glow, float)[..., :1] / 255 * np.array([60, 170, 255]) * 2.2 + np.asarray(layer, float)[..., :1] / 255 * np.array([200, 240, 255])
    out = np.asarray(im, float) + blue
    v = np.clip(1.15 - ((x / w - .6) ** 2 + (y / h - .55) ** 2) * 1.1, .45, 1)
    return Image.fromarray(np.clip(out * v[..., None], 0, 255).astype(np.uint8))

GOLD = np.array([[0, 0, 0], [120, 40, 0], [235, 120, 0], [255, 200, 30], [255, 240, 140], [255, 255, 240]], float)
def aura(w=960, h=540):
    y, x = np.mgrid[0:h, 0:w].astype(float); cx, cy = w * .74, h * .62
    dx, dy = (x - cx) / h, (y - cy) / h * .8; r = np.sqrt(dx * dx + dy * dy); a = np.arctan2(dy, dx)
    n = fbm(h, w, 6, 21, sx=1.2, sy=.5)
    up = np.clip(-dy * 1.2 + .4, 0, 1)             # aura rises
    flame = np.clip((.95 - r * 1.5) + (n - .5) * 1.4 + up * .25, 0, 1) ** 1.3
    base = np.array([28, 10, 4]) + np.array([40, 12, 0]) * (x / w)[..., None]
    img = base * (1 - flame[..., None]) + ramp(flame, GOLD) * flame[..., None] ** .45
    lines = (0.5 + 0.5 * np.sin(a * 90)) ** 30 * np.clip(r - .3, 0, 1) * .3
    img += lines[..., None] * np.array([255, 230, 170])
    img *= np.clip(.35 + x / w * .75, 0, 1)[..., None]
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    layer = Image.new("RGB", (w, h)); d = ImageDraw.Draw(layer)
    for _ in range(3): x0 = rng.integers(int(w * .55), w - 40); lightning(d, x0, rng.integers(10, 120), x0 + rng.integers(-80, 80), rng.integers(260, 470), 2, 9, 11)
    glow = np.asarray(layer.filter(ImageFilter.GaussianBlur(5)), float)[..., :1] / 255
    out = np.asarray(im, float) + glow * np.array([70, 180, 255]) * 2 + np.asarray(layer, float)[..., :1] / 255 * np.array([210, 245, 255])
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))

def uri(im, q):
    b = io.BytesIO(); im.save(b, "WEBP", quality=q, method=6); d = b.getvalue()
    return "data:image/webp;base64," + base64.b64encode(d).decode(), len(d)
s = battlefield(); s.save(OUT / "battlefield.png"); u1, n1 = uri(s, 64)
a = aura(); a.save(OUT / "aura.png"); u2, n2 = uri(a, 68)
pathlib.Path("/home/claude/work/v2/ui/premium-art.css").write_text(
    "/* v2.36 original art (art-src/make_art2.py, procedural; no outside images) */\n"
    "html.dbz{--p-art-sky:url(" + u1 + ");--p-art-burst:url(" + u2 + ")}\n")
print(n1, n2)
