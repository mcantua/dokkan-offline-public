from harness import Session
from util import snap, buttons
import json
s = Session().open()
s.page.wait_for_timeout(1500)
# open existing project from My units
print(s.native.m_projects({}))
s.page.evaluate("document.querySelector('.sidebar [data-nav=home]').click()")
s.page.wait_for_timeout(1500)
snap(s, "f3-home", n=800)
