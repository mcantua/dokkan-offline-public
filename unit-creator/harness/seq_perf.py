"""Measure the Animations clip editor: render, trim change, save."""
import os, time
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-seqperf"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    w(200)
pg.evaluate("navigate('animations')"); w(1500)
def add(term):
    pg.locator('[data-studio="browse"]').first.click(); w(1200)
    pg.select_option("#studio-kind", "all"); w(800)
    pg.fill("#studio-search", term); w(2000)
    pg.locator('#studio-results [data-studio^="add:"]').first.click(); w(1200)
    pg.evaluate("document.querySelectorAll('dialog.sequence-picker[open]').forEach(d=>d.querySelector('[aria-label=\"Close picker\"]')?.click())"); w(300)
for t in ["Kamehameha", "Final Flash", "Galick", "Spirit Bomb", "Big Bang", "Masenko"]: add(t)
print(pg.inner_text("#simple-sequence-summary"))
print("project JSON KB:", pg.evaluate("Math.round(JSON.stringify(state.project).length/1024)"))
print("clip text KB:", pg.evaluate("studioProject().clips.map(c=>Math.round((c.source.text||'').length/1024))"))
t = pg.evaluate("""async()=>{const a=performance.now();for(let i=0;i<10;i++)renderStudioTimeline();return (performance.now()-a)/10}""")
print("render ms:", round(t, 1))
t = pg.evaluate("""()=>{const a=performance.now();for(let i=0;i<10;i++)ForgeMotion.validate(studioProject().clips);return (performance.now()-a)/10}""")
print("validate ms:", round(t, 1))
t = pg.evaluate("""async()=>{const a=performance.now();renderStudioTimeline();return performance.now()-a}""")
print("trim change ms:", round(t, 1))
s.close()
