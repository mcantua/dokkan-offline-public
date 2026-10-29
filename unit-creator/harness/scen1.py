import glob, subprocess, json, sys
from harness import Session
from util import buttons
s = Session().open(); s.page.wait_for_timeout(1500)
def openunit():
    s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(2000)
def dlg(): return s.page.evaluate("document.getElementById('dialog').open ? document.getElementById('dialog').innerText : ''")
openunit()
s.page.locator('main button:has-text("2. Power")').click(); s.page.wait_for_timeout(1200)
for section, act in [("Battle abilities", "Copy a character’s passive"), ("Team leader bonus", "Copy a character’s leader skill")]:
    s.page.locator('main button:has-text("2. Power")').click(); s.page.wait_for_timeout(1200)
    loc = s.page.locator(f'main summary:has-text("{section}"), main button:has-text("{section}")')
    print("section", section, loc.count(), [x[:30] for x in buttons(s.page)])
    loc.first.click(); s.page.wait_for_timeout(1000)
    b = s.page.locator(f'main button:has-text("{act}")')
    print(section, "->", act, b.count())
    if not b.count(): print(buttons(s.page)); continue
    b.first.click(); s.page.wait_for_timeout(1500)
    print("DIALOG:", dlg()[:600])
    inp = s.page.locator('dialog[open] input').first
    if inp.count(): inp.fill("Broly"); s.page.wait_for_timeout(2000)
    tiles = s.page.locator('dialog[open] .guide-pick')
    print("tiles", tiles.count(), buttons(s.page)[-12:])
    if tiles.count(): tiles.first.click(); s.page.wait_for_timeout(2500)
    print("AFTER:", dlg()[:500]); print("TOAST:", s.page.inner_text('#toast'))
    s.report(act)
    if s.page.evaluate("document.getElementById('dialog').open"): s.page.click('#dialog-close'); s.page.wait_for_timeout(500)
# export + integrity
s.page.locator('main button:has-text("4. Save")').click(); s.page.wait_for_timeout(1200)
s.page.locator('main button:has-text("Save game file (.eclp)")').click(); s.page.wait_for_timeout(8000)
print("EXPORT TOAST:", s.page.inner_text('#toast')); print("DIALOG:", dlg()[:800])
s.report("export")
import sqlite3; sys.path.insert(0, '.')
from integrity import check
for f in sorted(glob.glob(s.native.__class__.__module__ and __import__('native_mock').STATE.as_posix() + "/exports/*.request.json")):
    r = json.load(open(f)); sql = [e for e in r['entries'] if e['path'].endswith('.sql')][0]['text']
    w = sqlite3.connect('work.db'); w.execute('BEGIN'); print(f.split('/')[-1], "integrity:", check(w, sql)[:8]); w.execute('ROLLBACK')
    print(subprocess.run(["python3", "verify_eclp.py", f], capture_output=True, text=True).stdout[-200:])
