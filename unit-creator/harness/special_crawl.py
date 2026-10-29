"""Tap every button on the Special Skills step and in each dialog it opens (closing them again); report errors."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-spcrawl"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
for cid in (1018721, 1026391, 1018651):
    pg.evaluate(f"createUnit({cid})")
    for _ in range(200):
        if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
        w(100)
    w(800)
    pg.evaluate("document.querySelector('[data-b=\"tab:special\"]').click()"); w(800)
    acts = pg.evaluate("[...document.querySelectorAll('[data-sp]')].map(b=>b.dataset.sp)")
    print(cid, pg.evaluate("Forge.card(state.project).name"), acts)
    for a in acts:
        if a.startswith("go:") or a.endswith("-del") or "-del:" in a: continue
        pg.evaluate("(a)=>ForgeSpecial.action(a)", a); w(1200)
        if pg.locator("#dialog[open]").count():
            # press the main button if it is a form with defaults (Add), else close
            if pg.locator("#sp-save").count() and a in ("counter-add", "revive-add", "domain-add"): pg.locator("#sp-save").click(); w(800)
            pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())"); w(300)
        if pg.evaluate("state.view") != "editor":
            pg.evaluate("navigate('editor')"); w(1200)
        pg.evaluate("document.querySelector('[data-b=\"tab:special\"]').click()"); w(500)
    v = pg.evaluate("""()=>{const p=state.project,v=Forge.validate(p);let e='';try{Forge.sql(p)}catch(x){e=x.message}return [v.errors.slice(0,3),e]}""")
    print("   validate:", v)
print("errors:", errs[:5])
