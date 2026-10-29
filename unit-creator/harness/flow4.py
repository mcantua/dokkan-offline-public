from harness import Session
from util import snap, buttons
s = Session().open()
s.page.wait_for_timeout(1500)
s.page.locator('main [data-open]').first.click()
s.page.wait_for_timeout(2500)
s.page.fill('main input >> nth=0', 'Test Gogeta Prime')
s.page.wait_for_timeout(500)
for i in range(4):
    nxt = s.page.locator('main button:has-text("Next")')
    if nxt.count()==0: break
    nxt.first.click(); s.page.wait_for_timeout(2500)
    snap(s, f"f4-step{i+2}", n=2500)
