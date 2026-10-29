"""Guided-mode kit-copy scenarios: copy passive/leader/moves/conditions from donors, then export + verify."""
import glob, json, sqlite3, subprocess, sys
from harness import Session
from integrity import check
from native_mock import STATE
donors = sys.argv[1].split("|")
s = Session().open(); s.page.wait_for_timeout(1500)
def ev(js, arg=None): return s.page.evaluate(js, arg)
def invalid(): return ev("[...document.querySelectorAll('#main input, #main select, #main textarea')].filter(e=>!e.checkValidity()).map(e=>(e.closest('label')?.innerText||'').split('\\n')[0]+' value='+e.value+' ['+e.min+','+e.max+'] '+e.validationMessage)")
def goto_step(sub):
    # sub: 2 leader, 3 passive, 4 moves(route step "3. Moves"), 5 links
    if sub == 4:
        s.page.locator('main button:has-text("3. Moves")').click(); s.page.wait_for_timeout(1200); return
    s.page.locator('main button:has-text("2. Power")').click(); s.page.wait_for_timeout(1000)
    label = {2: "Team leader bonus", 3: "Battle abilities", 5: "Teams and links"}[sub]
    s.page.locator(f'main button:has-text("{label}")').first.click(); s.page.wait_for_timeout(1000)
def pick(name):
    s.page.fill('#guide-unit-search', name); s.page.wait_for_timeout(1300)
    n = s.page.locator('dialog[open] .guide-pick').count()
    if not n: return False
    s.page.locator('dialog[open] .guide-pick').nth(min(1, n - 1)).click(); s.page.wait_for_timeout(2500)
    # stage chooser dialogs may follow (EZA stage choice)
    for _ in range(3):
        if ev("document.getElementById('dialog').open"):
            btns = s.page.locator('dialog[open] #dialog-content button')
            if btns.count(): btns.first.click(); s.page.wait_for_timeout(2000)
            else: break
    return True
s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(2000)
problems = []
for donor in donors:
    for sub, action in [(3, "copy:passive"), (2, "copy:leader"), (4, "copy:move"), (3, "match-eza"), (3, "summarize"), (2, "leader-easy")]:
        goto_step(sub)
        el = s.page.locator(f'[data-guide="{action}"]')
        if not el.count(): print("  (no", action, "button)"); continue
        el.first.click(); s.page.wait_for_timeout(1500)
        if action.startswith("copy:"):
            if not pick(donor): print("  no donor results for", donor); ev("document.getElementById('dialog').close()"); continue
        if ev("document.getElementById('dialog').open"): ev("document.getElementById('dialog').close()")
        bad = invalid()
        toast = s.page.inner_text('#toast')
        errs = [e for e in s.errors] + [c for c in s.console if "TOAST-ERROR" in c]
        s.errors.clear(); s.console.clear()
        print(f"{donor} {action}: invalid={bad[:3]} toast={toast[:120]!r} errs={errs[:2]}")
        if bad or errs: problems.append((donor, action, bad, errs))
# export
s.page.locator('main button:has-text("4. Save")').click(); s.page.wait_for_timeout(1200)
s.page.locator('main button:has-text("Save game file (.eclp)")').click(); s.page.wait_for_timeout(9000)
print("EXPORT:", s.page.inner_text('#toast')[:300])
dlg = ev("document.getElementById('dialog').open ? document.getElementById('dialog').innerText : ''")
if dlg: print("EXPORT DIALOG:", dlg[:1200])
for f in sorted(glob.glob(str(STATE / "exports" / "*.request.json"))):
    r = json.load(open(f)); sql = [e for e in r['entries'] if e['path'].endswith('.sql')][0]['text']
    w = sqlite3.connect('work.db'); w.execute('BEGIN')
    try: print("integrity:", check(w, sql)[:8])
    except Exception as e: print("SQL ERROR", e)
    w.execute('ROLLBACK')
    print(subprocess.run(["python3", "verify_eclp.py", f], capture_output=True, text=True).stdout.strip().splitlines()[-1])
print("PROBLEMS:", problems)
