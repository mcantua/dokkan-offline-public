"""Depth-limited crawler: for each editor step, click every visible button in a fresh state and record errors."""
import json, shutil, sys, os
from harness import Session
import native_mock

BASE = "/home/claude/work/harness/base-state"
LIVE = os.environ.get("FORGE_STATE", "/home/claude/work/harness/state")
ADV = os.environ.get("ADV") == "1"

def fresh():
    shutil.rmtree(LIVE, ignore_errors=True); shutil.copytree(BASE, LIVE)
    os.makedirs(LIVE + "/assets", exist_ok=True); os.makedirs(LIVE + "/projects", exist_ok=True)

def open_editor(s, step):
    s.page.evaluate("try{localStorage.clear()}catch(e){}"); s.page.reload(); s.page.wait_for_timeout(1500)
    s.page.locator('main [data-open]').first.click()
    s.page.wait_for_timeout(1800)
    if ADV and s.page.locator('button:has-text("Advanced controls")').count():
        s.page.locator('button:has-text("Advanced controls")').first.click(); s.page.wait_for_timeout(1000)
    if step:
        s.page.locator(f'main button:has-text("{step}")').first.click(); s.page.wait_for_timeout(1200)

VIS_BTNS = """(scope) => { const root = scope === 'dialog' ? document.querySelector('dialog[open]') : document.querySelector('main');
  if (!root) return [];
  return [...root.querySelectorAll('button, summary, [role=button], a[href]')].filter(b => b.offsetParent !== null && !b.disabled).map((b, i) => ({ i, text: (b.innerText || b.getAttribute('aria-label') || b.title || '').trim().replace(/\\s+/g, ' ').slice(0, 50), id: b.id })) }"""

def click_nth(s, scope, i):
    return s.page.evaluate("""([scope, i]) => { const root = scope === 'dialog' ? document.querySelector('dialog[open]') : document.querySelector('main');
      const els = [...root.querySelectorAll('button, summary, [role=button], a[href]')].filter(b => b.offsetParent !== null && !b.disabled);
      const el = els[i]; if (!el) return false; el.scrollIntoView(); el.click(); return true; }""", [scope, i])

def collect(s):
    out = [e[:600] for e in s.errors]
    out += [c[:400] for c in s.console if ("TOAST-ERROR" in c and "(mock)" not in c) or c.startswith("error:") and not any(q in c for q in s.quiet) and "Failed to load resource" not in c]
    out += [l for l in s.native.log if l.startswith("ERR")]
    s.errors.clear(); s.console.clear(); s.native.log = [l for l in s.native.log if not l.startswith("ERR")]
    return out

def main(steps, depth2=False):
    findings = []
    s = Session()
    for step in steps:
        fresh(); s.page.goto("https://forge.local/index.html"); s.page.wait_for_timeout(2000)
        open_editor(s, step)
        btns = s.page.evaluate(VIS_BTNS, "main")
        print(f"## step {step!r}: {len(btns)} buttons", flush=True)
        for b in btns:
            fresh(); s.page.goto("https://forge.local/index.html"); s.page.wait_for_timeout(1800)
            open_editor(s, step); collect(s)
            if not click_nth(s, "main", b["i"]): continue
            s.page.wait_for_timeout(1500)
            errs = collect(s)
            if errs: findings.append({"step": step, "button": b["text"], "errors": errs}); print("  !!", b["text"], errs, flush=True)
            if depth2 and s.page.evaluate("!!document.querySelector('dialog[open]')"):
                dbtns = s.page.evaluate(VIS_BTNS, "dialog")
                for d in dbtns:
                    if d["text"] in ("Close",): continue
                    fresh(); s.page.goto("https://forge.local/index.html"); s.page.wait_for_timeout(1800)
                    open_editor(s, step); click_nth(s, "main", b["i"]); s.page.wait_for_timeout(1200); collect(s)
                    if not s.page.evaluate("!!document.querySelector('dialog[open]')"): break
                    click_nth(s, "dialog", d["i"]); s.page.wait_for_timeout(1500)
                    errs = collect(s)
                    if errs: findings.append({"step": step, "button": b["text"] + " > " + d["text"], "errors": errs}); print("  !!", b["text"], ">", d["text"], errs, flush=True)
    print("unknown native:", sorted(set(s.native.unknown)))
    s.close()
    json.dump(findings, open("crawl-findings-%d.json" % os.getpid(), "w"), indent=1)

if __name__ == "__main__":
    main(sys.argv[1].split("|"), depth2=len(sys.argv) > 2)
