import os, shutil, json
os.environ["FORGE_STATE"]="/home/claude/work/harness/state-aipaste"; shutil.rmtree(os.environ["FORGE_STATE"], ignore_errors=True)
from harness import Session
import native_mock
s=Session(viewport=(1280,900)).open(); pg=s.page; w=lambda ms=700: pg.wait_for_timeout(ms)
w(1500); pg.evaluate("createUnit(1018721)"); w(2500)
pg.locator('[data-b="ai-helper"]').click(); w(800)
pg.fill("#aic-input","Make it an LR Gogeta"); pg.locator("#aic-copy").click(); w(1500)
print("status:", pg.inner_text("#aic-status-h"))
print("copied chars:", len(s.native.log))
reply="Sure!\n```json\n"+json.dumps(native_mock.AI_ACTIONS)+"\n```"
pg.fill("#aic-reply", reply); pg.locator("#aic-use").click(); w(2000)
print("review items:", pg.locator("#aic-review li").count())
pg.locator("#aic-apply").click(); w(2000)
print("name:", pg.inner_text("#bld h1"))
pg.locator('[data-guide="undo"]').first.click(); w(800); print("after undo:", pg.inner_text("#bld h1"))
pg.evaluate("navigate('ai')"); w(2500)
print("AI page:", pg.inner_text("main")[:400].replace("\n"," | "))
pg.screenshot(path="shots/ai-page.png")
s.report("ai-paste"); s.close()
