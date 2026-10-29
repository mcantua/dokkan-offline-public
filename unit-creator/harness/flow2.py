from harness import Session
from util import snap, buttons
s = Session().open()
s.page.wait_for_timeout(2000)
s.page.evaluate("document.querySelector('.sidebar [data-nav=source]').click()")
s.page.wait_for_timeout(1500)
s.page.fill('input[placeholder^="For example"]', 'Super Saiyan Goku & Super Saiyan Vegeta')
s.page.select_option('select', label='LR')
s.page.wait_for_timeout(1500)
s.page.locator('main :text("HP 19,663")').first.click()
s.page.wait_for_timeout(4000)
snap(s, "f2-after-pick", n=3000)
