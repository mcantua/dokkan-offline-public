import os
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
SP="/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s=Session(viewport=(412,915)).open(); pg=s.page
while pg.evaluate("window.__forgeWorkspaceStartup")!="ready": pg.wait_for_timeout(100)
pg.wait_for_timeout(300)
pg.click("[data-perf]"); pg.wait_for_timeout(500)
pg.screenshot(path=SP+"speed.png")
pg.click('input[name="perf-fx"][value="lite"]'); pg.wait_for_timeout(300)
print("lite:", pg.evaluate("document.documentElement.classList.contains('lite')"), pg.evaluate("localStorage.getItem('forge-lite')"))
pg.click('input[name="perf-gpu"][value="software"]'); pg.wait_for_timeout(300)
print("mode:", pg.evaluate("ForgePerf.renderMode()"), pg.inner_text("#toast"))
pg.click('input[name="perf-gpu"][value="gpu"]'); pg.click('input[name="perf-fx"][value="full"]'); pg.wait_for_timeout(300)
print("after:", pg.evaluate("ForgePerf.renderMode()"), pg.evaluate("document.documentElement.classList.contains('lite')"))
pg.click("#dialog-close"); pg.wait_for_timeout(200)
pg.evaluate("ForgePerf.setLite(true)"); pg.locator("[data-open]").first.click(); pg.wait_for_selector("#bld"); pg.wait_for_timeout(800)
pg.screenshot(path=SP+"lite-builder.png"); pg.evaluate("ForgePerf.setLite(false)")
s.report("speed"); s.close()
