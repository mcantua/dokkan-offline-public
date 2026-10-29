from harness import Session
s = Session().open(); s.page.wait_for_timeout(1500)
s.page.locator('main [data-open]').first.click(); s.page.wait_for_timeout(1500)
if s.page.locator('button:has-text("Advanced controls")').count(): s.page.locator('button:has-text("Advanced controls")').first.click(); s.page.wait_for_timeout(800)
for t in ["2Stats", "2 Stats", "Stats"]:
    print(repr(t), s.page.locator(f'main button:has-text("{t}")').count())
