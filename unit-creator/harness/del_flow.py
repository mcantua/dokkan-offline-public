from harness import Session
import os
s = Session().open(); s.page.wait_for_timeout(1500)
print("projects before:", [p["name"] for p in s.native.m_projects({})])
s.page.evaluate("document.querySelector('.sidebar [data-nav=library]').click()"); s.page.wait_for_timeout(1500)
s.page.screenshot(path="shots/del-1.png")
print("delete buttons:", s.page.locator(".tile-delete").count())
s.page.locator(".tile-delete").first.click(); s.page.wait_for_timeout(600)
print(s.page.inner_text("#dialog")[:400])
s.page.click("#library-delete-confirm"); s.page.wait_for_timeout(2000)
print("TOAST:", s.page.inner_text("#toast"))
print("projects after:", [p["name"] for p in s.native.m_projects({})])
s.page.screenshot(path="shots/del-2.png")
s.report("delete")
