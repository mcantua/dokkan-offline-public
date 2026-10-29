"""Use another character's animation for one move: picker banner, ✓ Use, compatibility note, back to the editor."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-animpick"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/ucopy/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(800)
pg.evaluate("document.querySelector('[data-b=\"tab:look\"]').click()"); w(1200)
before = pg.evaluate("state.project.tables.card_specials.map(r=>r.view_id)")
row = pg.locator(".bld-anim", has_text="Super Attack").first
row.locator(".simplify-change").click(); w(400)
print("change sheet:", pg.evaluate("[...document.querySelectorAll('.simplify-choice')].map(b=>b.textContent)"))
pg.locator(".simplify-choice", has_text="another character").first.click(); w(2500)
print("picker banner:", pg.evaluate("document.querySelector('.anim-pick-for')?.innerText"))
pg.select_option("#studio-kind", "all"); w(800); pg.fill("#studio-search", "Kamehameha"); w(2200)
print("tile buttons:", pg.evaluate("[...document.querySelectorAll('#studio-results .animation-tile')].slice(0,1).map(t=>[...t.querySelectorAll('button')].map(b=>b.textContent))"))
pg.screenshot(path=SP + "pick-1.png")
pg.locator('#studio-results [data-studio^="use:"]').first.click(); w(2500)
print("fit note:", pg.evaluate("document.getElementById('studio-use-fit')?.className+' | '+document.getElementById('studio-use-fit')?.textContent"))
pg.screenshot(path=SP + "pick-2.png")
opts = pg.evaluate("[...document.querySelectorAll('#studio-use-slot option')].map(o=>o.value)")
notes = {}
for v in opts[:12]:
    pg.select_option("#studio-use-slot", v); w(150)
    notes[v] = pg.evaluate("document.getElementById('studio-use-fit').className.split(' ').pop()+': '+document.getElementById('studio-use-fit').textContent.slice(0,70)")
for k, v in notes.items(): print("   ", k, "→", v)
pg.select_option("#studio-use-slot", opts[0]); w(200)
pg.click("#studio-use-confirm"); w(2500)
print("back in editor:", pg.evaluate("state.view"), "| views:", before, "->", pg.evaluate("state.project.tables.card_specials.map(r=>r.view_id)"))
print("errors:", errs[:4])
