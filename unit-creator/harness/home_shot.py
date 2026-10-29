import os, sys
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
W,H=(int(x) for x in os.environ.get("VIEW","412x915").split("x"))
s=Session(viewport=(W,H)).open(); pg=s.page; pg.wait_for_timeout(2500)
pg.screenshot(path=f"shots/home-{W}.png", full_page=True)
print(pg.inner_text("main")[:600])
s.report("home"); s.close()
