import glob, subprocess
from harness import Session
from util import snap, buttons
s = Session().open(); s.page.wait_for_timeout(1500)
s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(2000)
s.page.locator('main button:has-text("Add a transformation form")').first.click(); s.page.wait_for_timeout(2000)
print(s.page.inner_text('#dialog')[:1500]); print(buttons(s.page))
s.report("form-dialog")
