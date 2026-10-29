from harness import Session
from util import snap, buttons
s = Session().open(); s.page.wait_for_timeout(1500)
s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(2000)
s.page.locator('main button:has-text("Import / edit artwork")').first.click(); s.page.wait_for_timeout(2500)
print(s.page.inner_text('#dialog')[:2500] if s.page.evaluate("document.getElementById('dialog').open") else s.page.inner_text('main')[:2500])
print(buttons(s.page))
s.page.screenshot(path="shots/art1.png")
s.report("art")
