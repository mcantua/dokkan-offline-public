"""🎨 Card artwork wizard: button, choices, AI instructions, graceful error without the art pack."""
import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-artstudio"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/art/"; os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(name, cond, extra=""): print(("PASS " if cond else "FAIL ") + name, extra)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018651)")  # LR Vegito
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(1000)
pg.evaluate("document.querySelector('[data-b=\"tab:look\"]').click()"); w(1200)
ok("art button", pg.locator(".art-studio-button").count() == 1)
pg.screenshot(path=SP + "1-look.png")
pg.locator(".art-studio-button").click(); w(600)
ok("three choices", pg.locator(".art-choice").count() == 3, pg.locator(".art-choice strong").all_inner_texts())
ok("LR note", "animated artwork" in pg.inner_text("#dialog-content"))
pg.screenshot(path=SP + "2-choices.png")
pg.locator('[data-art="ai"]').click(); w(600)
pr = pg.evaluate("ForgeArtStudio.prompt('Vegito, blue aura','attack',true)")
ok("prompt has standards", all(k in pr for k in ["Dokkan Battle", "cel shading", "upper third", "No text"]), pr[:160])
pg.screenshot(path=SP + "3-ai.png")
pg.locator("#art-go").click(); w(1500)
ok("no AI connected → helpful", "Connect" in pg.inner_text("#dialog-content"), pg.inner_text("#art-status") if pg.locator("#art-status").count() else "")
r = pg.evaluate("""async()=>{const c=document.createElement('canvas');c.width=600;c.height=900;const g=c.getContext('2d');g.fillStyle='#f80';g.fillRect(150,100,300,700);
  try{await ForgeArtStudio.applyPicture(c,()=>{});return 'applied'}catch(e){return 'error: '+e.message}}""")
print("   apply without art pack:", r)
f = pg.evaluate("""()=>{const c=document.createElement('canvas');c.width=1024;c.height=1536;const a=ForgeArtStudio.fit(c,640,960),b=ForgeArtStudio.portrait(c,250,250);return [a.width,a.height,b.width,b.height]}""")
ok("fit sizes", f == [640, 960, 250, 250], f)
print("errors:", errs[:3])
