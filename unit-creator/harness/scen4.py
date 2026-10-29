from harness import Session
from util import buttons
s = Session().open(); s.page.wait_for_timeout(1500); ev = s.page.evaluate
s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(2000)
s.page.locator('main button:has-text("Saved versions")').first.click(); s.page.wait_for_timeout(1500)
print(ev("document.getElementById('dialog').innerText")[:300])
s.page.fill('#version-label', 'Original design'); s.page.click('#save-named-version'); s.page.wait_for_timeout(2000)
print("after save:", ev("document.getElementById('dialog').innerText")[:400])
ev("document.getElementById('dialog').close()"); s.page.wait_for_timeout(500)
# change name
s.page.fill('[data-bind="card:name"]', 'Renamed Unit'); s.page.wait_for_timeout(1500)
s.page.locator('main button:has-text("Saved versions")').first.click(); s.page.wait_for_timeout(1500)
s.page.locator('[data-version-review]').first.click(); s.page.wait_for_timeout(1500)
print("review:", ev("document.getElementById('dialog').innerText")[:300])
s.page.click('#restore-named-version'); s.page.wait_for_timeout(2500)
print("dialog open:", ev("document.getElementById('dialog').open"), "name now:", s.page.input_value('[data-bind="card:name"]'))
print("toast:", s.page.inner_text('#toast')); s.report("versions")
print([l for l in s.native.log if 'JVMERR' in l or 'ERR' in l])
