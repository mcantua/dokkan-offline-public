import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-tforms"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s = Session(viewport=(412, 915)).open(); pg = s.page
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": pg.wait_for_timeout(100)
pg.locator("[data-open]").first.click(); pg.wait_for_selector("#bld"); pg.wait_for_timeout(800)
for tab in ["basics", "passive", "save"]:
    pg.locator(f'[data-b="tab:{tab}"]').first.click(); pg.wait_for_timeout(500)
    pg.evaluate("window.scrollTo(0, document.documentElement.scrollHeight)"); pg.wait_for_timeout(300)
    print(tab, pg.evaluate("""()=>{const nav=document.querySelector('.mobile-nav').getBoundingClientRect();
      const els=[...document.querySelectorAll('#main button, #main a')].filter(e=>e.offsetParent);
      const last=els.reduce((a,e)=>{const r=e.getBoundingClientRect();return r.bottom>a.b?{b:r.bottom,t:e.textContent.trim().slice(0,30),cls:e.className}:a},{b:0});
      const m=getComputedStyle(document.querySelector('#main'));
      return {navTop:Math.round(nav.top),navH:Math.round(nav.height),last,mainPadB:m.paddingBottom,scrollH:document.documentElement.scrollHeight,inner:innerHeight,scrollY:scrollY}}"""))
    pg.screenshot(path=SP + f"scroll-{tab}.png")
s.close()
