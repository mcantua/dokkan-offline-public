from harness import Session
s = Session().open()
s.page.wait_for_timeout(3000)
s.page.screenshot(path="shots/home.png")
s.report("home")
print(s.native.log)
for nav in ["library","source","animations","combat","movies","assets","ai","home"]:
    s.page.evaluate(f"document.querySelector('.sidebar [data-nav={nav}]').click()")
    s.page.wait_for_timeout(2500)
    s.page.screenshot(path=f"shots/{nav}.png")
    s.report(nav)
s.close()
