"""Movie editor overhaul: pick scenes, trim with handles, instant join, re-encode fallback, add to animation."""
import os, shutil, time, json, subprocess
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-movieui"; os.environ["FRESH"] = "1"
from harness import Session
from native_mock import STATE
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
(STATE / "assets" / "testpack" / "movie").mkdir(parents=True, exist_ok=True)
for n in "abc": shutil.copy(f"/tmp/claude-0/movies/test_scene_{n}.usm", STATE / "assets" / "testpack" / "movie" / f"test_scene_{n}.usm")
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    w(200)
pg.evaluate("navigate('animations')"); w(1500)
pg.click("#tl-more"); w(500)
t0 = time.time(); pg.locator('[data-studio="movie-editor"]').first.click()
pg.wait_for_selector(".movie-editor-dialog .movie-edit-source", timeout=20000); print("editor + list shown in %.1fs" % (time.time() - t0))
pg.fill("#movie-edit-search", "test_scene"); w(800)
print("sources:", pg.evaluate("[...document.querySelectorAll('.movie-edit-source strong')].map(e=>e.textContent)"))
def add(name):
    i = pg.evaluate(f"[...document.querySelectorAll('.movie-edit-source strong')].findIndex(e=>e.textContent.includes('{name}'))")
    pg.locator("[data-movie-source-add]").nth(i).click()
    for _ in range(60):
        w(250)
        if not pg.evaluate("document.querySelector('#movie-edit-build').hidden"): break
    w(300)
add("test_scene_a"); add("test_scene_b")
print("cards:", pg.evaluate("[...document.querySelectorAll('.movie-editor-dialog .clip-card')].map(c=>c.querySelector('h3').textContent+' | '+[...c.querySelectorAll('.trim-value')].map(v=>v.textContent).join('→')+' | '+c.querySelector('[data-movie-badge]').textContent)"))
print("plan:", pg.inner_text("#movie-edit-plan"))
# cut scene 1 to 1.0–3.5s (start on keyframe 30 = 1.0s) by typing; scene 2 start 0.5 (between cut points)
card = pg.locator(".movie-editor-dialog .clip-card").nth(0)
card.locator(".trim-from .trim-value").click(); pg.keyboard.press("Control+A"); pg.keyboard.type("1"); pg.keyboard.press("Enter"); w(300)
card.locator(".trim-to .trim-value").click(); pg.keyboard.press("Control+A"); pg.keyboard.type("3.5"); pg.keyboard.press("Enter"); w(300)
card2 = pg.locator(".movie-editor-dialog .clip-card").nth(1)
card2.locator(".trim-from .trim-value").click(); pg.keyboard.press("Control+A"); pg.keyboard.type("0.5"); pg.keyboard.press("Enter"); w(300)
print("after cuts:", pg.inner_text("#movie-edit-total"), "| plan:", pg.inner_text("#movie-edit-plan")[:160])
print("snap visible:", pg.evaluate("[...document.querySelectorAll('[data-movie-snap]')].map(b=>!b.hidden)"))
pg.screenshot(path=SP + "movie-editor-cut.png", full_page=False)
pg.locator('[data-movie-snap="1"]').click(); w(300)
print("after snap:", card2.locator(".trim-from .trim-value").inner_text(), "| plan:", pg.inner_text("#movie-edit-plan")[:80])
card.locator("[data-movie-play]").click(); w(400)
print("play this part request:", {k: v for k, v in (s.native.last_preview or {}).items() if k in ("mode", "resourcePath", "trim")})
t0 = time.time(); pg.click("#movie-edit-build")
for _ in range(240):
    w(500)
    if not pg.evaluate("document.querySelector('#movie-edit-done').hidden") or "rror" in pg.inner_text("#movie-edit-status"): break
print("instant build: %.1fs |" % (time.time() - t0), pg.inner_text("#movie-edit-status"))
out = subprocess.run(["node", "-e", "const I=require('/home/claude/work/v2/ui/movie-input.js');const m=I.readMovie(new Uint8Array(require('fs').readFileSync(process.argv[1])));console.log(m.kind,m.width,m.height,m.frames,m.audioKind,m.audio&&m.audio.length)", str(s.native.last_movie)], capture_output=True, text=True); print("result movie:", out.stdout.strip(), out.stderr[-200:])
pg.screenshot(path=SP + "movie-editor-done.png", full_page=False)
# re-encode path: add scene c (different size)
add("test_scene_c"); w(300)
print("plan with c:", pg.inner_text("#movie-edit-plan")[:220])
t0 = time.time(); pg.click("#movie-edit-build"); last = ""
for _ in range(600):
    w(1000)
    st = pg.inner_text("#movie-edit-status")
    if st != last: last = st
    if not pg.evaluate("document.querySelector('#movie-edit-done').hidden") or "rror" in st or "could not" in st: break
print("re-encode build: %.1fs |" % (time.time() - t0), pg.inner_text("#movie-edit-status")[:200], "|", pg.inner_text("#movie-edit-elapsed"))
out = subprocess.run(["node", "-e", "const I=require('/home/claude/work/v2/ui/movie-input.js');const m=I.readMovie(new Uint8Array(require('fs').readFileSync(process.argv[1])));console.log(m.kind,m.width,m.height,m.frames,m.audioKind)", str(s.native.last_movie)], capture_output=True, text=True); print("result movie 2:", out.stdout.strip(), out.stderr[-200:])
pg.click("#movie-edit-save"); w(3000)
print("clips now:", pg.evaluate("studioProject().clips.map(c=>c.label+' '+c.from+'-'+c.to)"), "| dialog open:", pg.locator(".movie-editor-dialog").count())
print("errors:", s.errors[:3])
s.close()
