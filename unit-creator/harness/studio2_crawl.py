"""Crawl the new simple Animation editor and gallery: click every visible studio button, record errors."""
import os, json
os.environ.setdefault("FORGE_STATE", "/home/claude/work/harness/state-studio2"); os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s = Session(viewport=(412, 915)).open(); pg = s.page
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": pg.wait_for_timeout(100)
seen = set()
def errs(): return [e.split("\n")[0][:200] for e in s.errors]
def crawl(label, rounds=2):
    for _ in range(rounds):
        btns = pg.evaluate("""[...document.querySelectorAll('[data-studio]')].filter(b=>b.offsetParent&&!b.disabled).map(b=>b.dataset.studio)""")
        for a in btns:
            if a in seen or a in ("save-video", "backup"): continue
            seen.add(a)
            before = len(s.errors)
            try:
                pg.locator(f'[data-studio="{a}"]').first.click(timeout=3000); pg.wait_for_timeout(900)
            except Exception as e:
                print("  click fail", a, str(e).split("\n")[0][:100]); pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>d.close())"); continue
            new = s.errors[before:]
            print(f"  {label}:{a} -> view={pg.evaluate('state.view')} dialogs={pg.locator('dialog[open]').count()}" + (" ERR " + new[0][:200] if new else ""))
            # close any picker/dialog
            opened = pg.evaluate("[...document.querySelectorAll('dialog[open]')].map(d=>d.className+'|'+(d.innerText||'').slice(0,120).replace(/\\n/g,' '))")
            if opened: print("     dialogs:", opened)
            pg.evaluate("document.querySelectorAll('dialog[open]').forEach(d=>{const c=d.querySelector('[aria-label=\"Close picker\"],#dialog-close,[data-close],.dialog-close');if(c)c.click();if(d.open)d.close()})"); pg.wait_for_timeout(300)
            if pg.evaluate("state.view") != "animations":
                pg.evaluate("navigate('animations')"); pg.wait_for_timeout(1200)
# 1. no unit: independent gallery
pg.evaluate("navigate('animations')"); pg.wait_for_timeout(2000)
pg.screenshot(path=SP + "studio2-empty.png", full_page=True)
print("empty view text:", pg.inner_text("#main")[:300].replace("\n", " | "))
crawl("nounit")
# 2. with a unit
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    pg.wait_for_timeout(200)
pg.wait_for_timeout(800)
pg.evaluate("navigate('animations')"); pg.wait_for_timeout(2000)
pg.screenshot(path=SP + "studio2-unit.png", full_page=True)
print("unit view text:", pg.inner_text("#main")[:400].replace("\n", " | "))
seen.clear(); crawl("unit")
# add a clip through the picker
pg.evaluate("navigate('animations')"); pg.wait_for_timeout(1500)
if pg.locator('[data-studio="browse"]').count():
    pg.locator('[data-studio="browse"]').first.click(); pg.wait_for_timeout(2500)
    pg.screenshot(path=SP + "studio2-browse.png")
    print("picker:", pg.locator("dialog[open]").first.inner_text()[:400].replace("\n", " | ") if pg.locator("dialog[open]").count() else "none")
print("errors total:", len(s.errors)); print("\n".join(errs()[:10]))
s.report("studio2"); s.close()
