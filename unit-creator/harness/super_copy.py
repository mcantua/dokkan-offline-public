"""Copy a single Super Attack (including an EX attack) from another character and export."""
import os, subprocess
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-scopy"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(100):
    if pg.evaluate("state.view==='editor' && document.getElementById('busy').hidden"): break
    w(200)
w(800)
pg.locator('[data-b="tab:supers"]').first.click(); w(800)
before = pg.evaluate("state.project.tables.card_specials.length")
EX = pg.evaluate("(async()=>{const r=await Native.call('query',{table:'extra_special_options',limit:1});const cs=await Native.call('query',{table:'card_specials',ids:[r[0].card_special_id],limit:1});const c=await Native.call('query',{table:'cards',ids:[cs[0].card_id],limit:1});return {cs:cs[0],card:c[0]}})()")
print("EX donor:", EX["card"]["name"], EX["card"]["id"], EX["cs"]["style"])
for donor, style in [(EX["card"]["name"], "Extra"), ("Vegito", None)]:
    pg.locator('[data-b="super-copy"]').first.click(); w(800)
    pg.check("#guide-unit-all") if pg.locator("#guide-unit-all").count() and not pg.is_checked("#guide-unit-all") else None
    pg.fill("#fd-root [data-fd-text]", donor.split("(")[0].strip()[:20] if style else donor); w(2500)
    picks = pg.locator("#fd-root .fd-tile")
    target = None
    if style:
        for i in range(picks.count()):
            if picks.nth(i).get_attribute("data-fd-pick") == str(EX["card"]["id"]): target = picks.nth(i)
    (target or picks.first).click(); w(2000)
    attacks = pg.locator("[data-copy-super]")
    print(donor, "attacks:", attacks.count(), pg.locator("#dialog-content").inner_text()[:200].replace("\n", " | "))
    chosen = None
    if style:
        for i in range(attacks.count()):
            if "EX" in attacks.nth(i).inner_text(): chosen = attacks.nth(i)
    (chosen or attacks.first).click(); w(2500)
    print("  toast:", pg.inner_text("#toast")[:150])
print("card_specials:", before, "->", pg.evaluate("state.project.tables.card_specials.map(r=>[r.id,r.style,r.card_id])"))
print("ex options:", pg.evaluate("(state.project.tables.extra_special_options||[]).map(r=>[r.id,r.card_special_id])"))
print("errors:", pg.evaluate("Forge.validate(state.project).errors"))
sql = pg.evaluate("Forge.sql(state.project)"); open(SP + "scopy.sql", "w").write(sql)
print(subprocess.run(["python3", "apply_sql.py", SP + "scopy.sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:])
print(subprocess.run(["python3", "-c", f"exec(open('overwrite_check.py').read().split('def main')[0]);print(check(open('{SP}scopy.sql').read()))"], capture_output=True, text=True).stdout.strip())
import re
print("exported card_specials card ids:", sorted(set(re.findall(r'INSERT OR REPLACE INTO "card_specials" \("id", "card_id"[^)]*\) VALUES \(-?\d+, (\d+)', sql)))[:5])
s.report("scopy"); s.close()
