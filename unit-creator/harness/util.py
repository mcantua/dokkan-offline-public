def buttons(page):
    return page.evaluate("""() => [...document.querySelectorAll('main button, main a.button, dialog[open] button')].filter(b=>b.offsetParent!==null).map(b=>(b.id?'#'+b.id+' ':'')+b.innerText.trim().replace(/\\s+/g,' ').slice(0,60))""")
def snap(s, name, text=True, n=1200):
    s.page.screenshot(path=f"shots/{name}.png")
    if text:
        print(f"--- {name} ---")
        print(s.page.inner_text('main')[:n])
        print("BUTTONS:", buttons(s.page))
    s.report(name)
