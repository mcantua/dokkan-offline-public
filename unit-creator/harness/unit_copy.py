"""Copy from a unit: whole kit from game cards and from one of my units; validate, SQL applies, no overwrites; undo."""
import os, json, subprocess
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-ucopy"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/ucopy/"; os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
def create(cid):
    pg.evaluate(f"createUnit({cid})")
    for _ in range(200):
        if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
        w(100)
    w(800)
def check(tag):
    info = pg.evaluate("""()=>{const p=state.project;const v=Forge.validate(p);let sql='',err='';try{sql=Forge.sql(p)}catch(e){err=e.message}
      return {errors:v.errors.slice(0,4),sqlErr:err,sql}}""")
    open(SP + tag + ".sql", "w").write(info["sql"])
    a = subprocess.run(["python3", "apply_sql.py", SP + tag + ".sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:]
    o = subprocess.run(["python3", "-c", f"exec(open('overwrite_check.py').read().split('def main')[0]);print(check(open('{SP}{tag}.sql').read()))"], capture_output=True, text=True)
    print("  ", tag, "errors:", info["errors"], info["sqlErr"], "| apply:", a, "| overwrite:", (o.stdout or o.stderr).strip()[-120:])
actives = pg.evaluate("Native.call('query',{table:'card_active_skills',limit:400}).then(r=>[...new Set(r.map(x=>x.card_id))].filter(i=>i<2000000&&i%10===1).slice(-6))")
print("cards with active skills:", actives)
create(1018721)
base = pg.evaluate("JSON.stringify(state.project).length")
for donor in [1014761] + actives[-2:]:
    name = pg.evaluate(f"Native.call('query',{{table:'cards',ids:[{donor}],limit:1}}).then(r=>r[0]?.name)")
    res = pg.evaluate(f"""async()=>{{const d=await ForgeUnitCopy.gameDonor({{id:{donor},name:{json.dumps(name)}}});const inv=ForgeUnitCopy.inventory(d);
      const pick=new Set(Object.keys(inv).filter(k=>inv[k].ok&&k!=='transform'&&k!=='animations'));
      const r=ForgeUnitCopy.build(d,pick,{{passive:'replace',supers:'replace'}});
      return {{inv:Object.fromEntries(Object.entries(inv).map(([k,v])=>[k,v.ok])),changes:r.changes.map(c=>c[0]+': '+String(c[2]).slice(0,110)),notes:r.notes}}}}""")
    print(donor, name, "| available:", [k for k, v in res["inv"].items() if v])
    for c in res["changes"]: print("    -", c)
    # apply through the real dialog flow
    pg.evaluate(f"""async()=>{{const d=await ForgeUnitCopy.gameDonor({{id:{donor},name:{json.dumps(name)}}});window.__ud=d;}}""")
    w(300)
    pg.evaluate("""()=>{const p=state.project;const d=window.__ud;const inv=ForgeUnitCopy.inventory(d);const pick=new Set(Object.keys(inv).filter(k=>inv[k].ok&&k!=='transform'&&k!=='animations'));const r=ForgeUnitCopy.build(d,pick,{passive:'replace',supers:'replace'});Object.assign(p,r.work);ForgeBuilderUI?.refreshTexts?.();scheduleSave();renderEditor();}""")
    w(1200)
    check(f"kit-{donor}")
# the dialog flow itself (UI), animations-only + transform, from a game card
pg.click(".ucopy-button"); w(400); pg.screenshot(path=SP + "01-source.png")
pg.click("#ucopy-game"); w(1200)
pg.fill("#fd-root [data-fd-text], .guide-unit-search input, #dialog input[type=search]", "Super Saiyan Goku"); w(1500)
pg.locator("#fd-root [data-fd-pick]").first.click(); w(2500)
pg.screenshot(path=SP + "02-features.png")
print("features shown:", pg.evaluate("[...document.querySelectorAll('[data-ucopy]')].map(b=>b.dataset.ucopy+(b.disabled?'(off)':''))"))
for k in ["animations", "transform", "links"]:
    if pg.locator(f'[data-ucopy="{k}"]:not([disabled])').count(): pg.check(f'[data-ucopy="{k}"]')
pg.click("#ucopy-preview"); w(800)
pg.screenshot(path=SP + "03-preview.png")
print("preview:", pg.evaluate("[...document.querySelectorAll('.ucopy-change strong')].map(e=>e.textContent)"))
pg.click("#ucopy-apply"); w(1500)
print("toast:", pg.inner_text("#toast")[:160])
check("ui-anim-transform")
beforeUndo = pg.evaluate("JSON.stringify(Forge.card(state.project).link_skill1_id)+'|'+(state.project.tables.card_motions||[]).length")
pg.evaluate("ForgeGuideUI.undo()"); w(1200)
print("undo:", beforeUndo, "->", pg.evaluate("JSON.stringify(Forge.card(state.project).link_skill1_id)+'|'+(state.project.tables.card_motions||[]).length"))
# from one of my units
pg.evaluate("flushSave()"); w(500)
create(1014761)
key = pg.evaluate("Native.call('projects').then(r=>r.find(x=>x.key!==state.project.key).key)")
res = pg.evaluate(f"""async()=>{{const d=await ForgeUnitCopy.myDonor({json.dumps(key)});const inv=ForgeUnitCopy.inventory(d);const pick=new Set(Object.keys(inv).filter(k=>inv[k].ok&&k!=='transform'));const r=ForgeUnitCopy.build(d,pick,{{passive:'add',supers:'add'}});Object.assign(state.project,r.work);ForgeBuilderUI?.refreshTexts?.();scheduleSave();renderEditor();return r.changes.map(c=>c[0])}}""")
print("from my unit:", res); w(1200)
check("from-mine")
print("errors:", errs[:5])
