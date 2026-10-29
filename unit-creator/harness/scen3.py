"""Add a transformation form through the UI, export, verify."""
import glob, json, sqlite3, subprocess, sys
from harness import Session
from integrity import check
from native_mock import STATE
from util import buttons
s = Session().open(); s.page.wait_for_timeout(1500)
ev = s.page.evaluate
s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(2000)
s.page.locator('main button:has-text("Add a transformation form")').first.click(); s.page.wait_for_timeout(1500)
print(ev("[...document.querySelectorAll('#form-slot option')].map(o=>o.textContent)"))
s.page.select_option('#form-slot', index=1)
s.page.click('#form-pick-source'); s.page.wait_for_timeout(1500)
print("picker:", ev("document.getElementById('dialog').innerText")[:200])
inp = s.page.locator('dialog[open] input').first
inp.fill(sys.argv[1] if len(sys.argv) > 1 else "Gogeta"); s.page.wait_for_timeout(1500)
picks = s.page.locator('dialog[open] .guide-pick, dialog[open] [data-pick]')
print("picks", picks.count()); picks.nth(1).click(); s.page.wait_for_timeout(5000)
for _ in range(4):
    if ev("document.getElementById('dialog').open"):
        print("DIALOG:", ev("document.getElementById('dialog').innerText")[:600]); print(buttons(s.page)[-6:])
        b = s.page.locator('dialog[open] #dialog-content button.button:not(.ghost)')
        if b.count(): b.first.click(); s.page.wait_for_timeout(4000)
        else: break
print("TOAST:", s.page.inner_text('#toast')); print("MAIN:", s.page.inner_text('main')[:600])
s.report("form")
s.page.screenshot(path="shots/form-after.png")
proj = json.loads(open(glob.glob(str(STATE / "projects" / "*.json"))[0]).read())
print("formProjects:", [(f["targetId"], f["cardOverrides"].get("name")) for f in proj.get("formProjects", [])], "links:", proj.get("transformLinks"))
s.page.locator('main button:has-text("4. Save")').click(); s.page.wait_for_timeout(1200)
s.page.locator('main button:has-text("Save game file")').first.click(); s.page.wait_for_timeout(10000)
print("EXPORT:", s.page.inner_text('#toast')[:300])
d = ev("document.getElementById('dialog').open ? document.getElementById('dialog').innerText : ''")
if d: print("EXPORT DIALOG:", d[:1500])
s.report("export")
for f in sorted(glob.glob(str(STATE / "exports" / "*.request.json"))):
    r = json.load(open(f)); sql = [e for e in r['entries'] if e['path'].endswith('.sql')][0]['text']
    import re; print("cards:", re.findall(r'INSERT INTO "cards" \([^)]*\) VALUES \((\d+)', sql))
    w = sqlite3.connect('work.db'); w.execute('BEGIN')
    try: print("integrity:", check(w, sql)[:8])
    except Exception as e: print("SQL ERROR", e)
    w.execute('ROLLBACK')
    print(subprocess.run(["python3", "verify_eclp.py", f], capture_output=True, text=True).stdout.strip().splitlines()[-1])
