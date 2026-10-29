import json, shutil, sys, os
from harness import Session
from crawl import VIS_BTNS, click_nth, collect
ST = os.environ["FORGE_STATE"]
def fresh():
    shutil.rmtree(ST, ignore_errors=True); shutil.copytree("/home/claude/work/harness/base-state", ST)
    os.makedirs(ST + "/assets", exist_ok=True)
SKIP = {"Close"}
def goto(s, view):
    s.page.goto("https://forge.local/index.html"); s.page.wait_for_timeout(1800)
    s.page.evaluate(f"document.querySelector('.sidebar [data-nav={view}]').click()"); s.page.wait_for_timeout(1800)
findings = []
s = Session()
for view in sys.argv[1].split(","):
    fresh(); goto(s, view); collect(s)
    btns = s.page.evaluate(VIS_BTNS, "main")
    print(f"## {view}: {len(btns)} buttons", flush=True)
    for b in btns[:60]:
        fresh(); goto(s, view); collect(s)
        if not click_nth(s, "main", b["i"]): continue
        s.page.wait_for_timeout(1500)
        errs = collect(s)
        if errs: findings.append([view, b["text"], errs]); print("  !!", b["text"], errs, flush=True)
        if s.page.evaluate("!!document.querySelector('dialog[open]')"):
            dbtns = s.page.evaluate(VIS_BTNS, "dialog")
            for d in dbtns[:25]:
                if d["text"] in SKIP: continue
                fresh(); goto(s, view); click_nth(s, "main", b["i"]); s.page.wait_for_timeout(1300); collect(s)
                if not s.page.evaluate("!!document.querySelector('dialog[open]')"): break
                click_nth(s, "dialog", d["i"]); s.page.wait_for_timeout(1500)
                errs = collect(s)
                if errs: findings.append([view, b["text"] + " > " + d["text"], errs]); print("  !!", b["text"], ">", d["text"], errs, flush=True)
print("unknown native:", sorted(set(s.native.unknown)))
json.dump(findings, open(f"views-{os.getpid()}.json", "w"), indent=1)
