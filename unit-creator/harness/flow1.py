import sys
from harness import Session
s = Session().open()
s.page.wait_for_timeout(2000)
s.page.evaluate("document.querySelector('.sidebar [data-nav=source]').click()")
s.page.wait_for_timeout(1500)
s.page.fill('input[placeholder^="For example"]', 'Goku')
s.page.select_option('select', label='LR') if 'LR' in s.page.inner_text('select') else None
s.page.wait_for_timeout(2000)
s.page.screenshot(path="shots/f1-search.png", full_page=False)
print(s.page.inner_text('main')[:1500])
s.report("search")
