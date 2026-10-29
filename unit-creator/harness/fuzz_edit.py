"""Advanced-mode edit fuzzer: change form controls on each step, then export and verify SQL."""
import json, random, shutil, sys, os, subprocess, glob
from harness import Session
SEED = int(sys.argv[1]) if len(sys.argv) > 1 else 1
STEPS = ["Name", "Stats", "Abilities for the team", "Battle abilities", "Moves", "Teams & links", "Appearance"]
st = os.environ["FORGE_STATE"]
shutil.rmtree(st, ignore_errors=True); shutil.copytree("/home/claude/work/harness/base-state", st)
s = Session().open(); s.page.wait_for_timeout(1500)
s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(2000)
if s.page.locator('button:has-text("Advanced controls")').count(): s.page.locator('button:has-text("Advanced controls")').first.click(); s.page.wait_for_timeout(1200)
FUZZ = """(seed) => {
  let x = seed; const rnd = () => (x = (x * 1103515245 + 12345) % 2147483648) / 2147483648;
  const changed = [];
  const ctrls = [...document.querySelectorAll('main input, main select, main textarea')].filter(e => e.offsetParent !== null && !e.disabled && !e.readOnly);
  for (const el of ctrls) {
    if (rnd() < 0.5) continue;
    const label = (el.labels?.[0]?.innerText || el.getAttribute('aria-label') || el.name || el.id || '').trim().slice(0, 40);
    if (el.tagName === 'SELECT') { if (el.options.length < 2) continue; el.selectedIndex = Math.floor(rnd() * el.options.length); }
    else if (el.type === 'checkbox' || el.type === 'radio') { el.checked = !el.checked; }
    else if (el.type === 'number' || el.inputMode === 'numeric') { const min = el.min !== '' ? +el.min : 0, max = el.max !== '' ? +el.max : Math.max(10, (+el.value || 10) * 2); el.value = String(Math.round(min + rnd() * (max - min))); }
    else if (el.type === 'file') continue;
    else if (el.type === 'search') continue;
    else { el.value = (el.value || '') + (rnd() < 0.5 ? ' X' : " O'Neil \\u00e9"); }
    changed.push(el.tagName + ':' + label + '=' + String(el.value).slice(0, 30));
    el.dispatchEvent(new Event('input', { bubbles: true })); el.dispatchEvent(new Event('change', { bubbles: true }));
  }
  return changed;
}"""
for i, step in enumerate(STEPS):
    s.page.locator(f'main button:has-text("{i+1}"):has-text("{step}")').first.click(); s.page.wait_for_timeout(1500)
    for rnd_i in range(2):
        try:
            ch = s.page.evaluate(FUZZ, SEED * 100 + i * 10 + rnd_i)
        except Exception as e:
            ch = ["EVAL-FAIL " + str(e)[:200]]
        s.page.wait_for_timeout(900)
        print(f"[{step}] changed {len(ch)}: {ch[:6]}")
    s.report(step)
s.page.locator('main button:has-text("8"):has-text("Save & play")').first.click(); s.page.wait_for_timeout(1500)
btn = s.page.locator('main button:has-text(".eclp")')
print("export buttons:", btn.count())
before = set(glob.glob(st + "/exports/*"))
if btn.count(): btn.first.click(); s.page.wait_for_timeout(8000)
print("TOAST:", s.page.inner_text('#toast'))
print("DIALOG:", (s.page.evaluate("document.getElementById('dialog').open && document.getElementById('dialog').innerText") or "")[:800])
s.report("export")
new = sorted(set(glob.glob(st + "/exports/*")) - before)
for f in new: print(subprocess.run(["python3", "checksql.py", f], capture_output=True, text=True).stdout[-1500:])
s.close()
