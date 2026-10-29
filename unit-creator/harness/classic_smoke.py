import os, shutil
os.environ["FORGE_STATE"]="/home/claude/work/harness/state-classic"; shutil.rmtree(os.environ["FORGE_STATE"], ignore_errors=True)
from harness import Session
s=Session(viewport=(412,915)).open(); pg=s.page; pg.wait_for_timeout(1500)
pg.evaluate("localStorage.setItem('forge-builder','off')"); pg.reload(); pg.wait_for_load_state("networkidle"); pg.wait_for_timeout(1500)
pg.evaluate("createUnit(1018721)"); pg.wait_for_timeout(2500)
print("builder:", pg.locator("#bld").count(), "open btn:", pg.locator("#bld-open").count())
for i in range(4):
    b=pg.locator("main .step-footer button").last
    print("step:", pg.inner_text("main h1")); b.click(); pg.wait_for_timeout(800)
pg.screenshot(path="shots/classic.png")
for nav in ["library","source","animations","home"]:
    pg.evaluate(f"document.querySelector('[data-nav={nav}]').click()"); pg.wait_for_timeout(1500)
s.report("classic"); s.close()
