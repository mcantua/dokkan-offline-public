import os
from harness import Session
from util import snap
s = Session().open(); s.page.wait_for_timeout(1500)
s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(2000)
s.page.locator('button:has-text("Advanced controls")').first.click(); s.page.wait_for_timeout(1500)
snap(s, "adv-0", n=2500)
