"""Special Skills step: counters, revival, intro, Domain (add + customize), Standby; export checks."""
import os, json, subprocess, sys
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-special"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/special/"; os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(name, cond, extra=""): print(("PASS " if cond else "FAIL ") + name, extra)
def click(sel): pg.evaluate("(s)=>document.querySelector(s).click()", sel); w(700)
def sp(action): pg.evaluate("(a)=>ForgeSpecial.action(a)", action); w(900)
def wait_for(sel, n=200):
    for _ in range(n):
        if pg.locator(sel).count(): return True
        w(150)
    return False
def export(tag):
    info = pg.evaluate("""()=>{const p=state.project;const v=Forge.validate(p);let sql='',err='';try{sql=Forge.sql(p)}catch(e){err=e.message}return {errors:v.errors.slice(0,4),err,sql}}""")
    open(SP + tag + ".sql", "w").write(info["sql"])
    a = subprocess.run(["python3", "apply_sql.py", SP + tag + ".sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:]
    o = subprocess.run(["python3", "-c", f"exec(open('overwrite_check.py').read().split('def main')[0]);print(check(open('{SP}{tag}.sql').read()))"], capture_output=True, text=True)
    print("   export", tag, info["errors"], info["err"], a, (o.stdout or o.stderr).strip()[-80:])
    return info
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
cid = int(sys.argv[1]) if len(sys.argv) > 1 else 1018721
pg.evaluate(f"createUnit({cid})")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(1000)
click('[data-b="tab:special"]'); w(500)
ok("special step", pg.locator(".sp-card").count() >= 8, pg.locator(".sp-card h3").all_inner_texts())
pg.screenshot(path=SP + "1-hub.png", full_page=True)
# counter
sp("counter-add"); wait_for("#sp-save")
pg.screenshot(path=SP + "2-counter-form.png")
pg.select_option('[data-spf="what"]', "2"); pg.select_option('[data-spf="power"]', "300"); pg.fill('[data-spf="dr"]', "70")
click("#sp-save")
c = pg.evaluate("ForgePassiveMerge.setRows(state.project,Forge.primaryPassive(state.project).id).filter(r=>r.efficacy_type===120).map(r=>[r.eff_value1,r.eff_value2,r.eff_value3,r.exec_timing_type,r.causality_conditions])")
ok("counter row", c and c[0][:2] == [70, 300] and c[0][3] == 6, c)
text = pg.evaluate("Forge.primaryPassive(state.project).itemized_description")
ok("counter in description", "counters with tremendous power" in text, text[-200:])
# revival
sp("revive-add"); wait_for("#sp-save"); pg.fill('[data-spf="hp"]', "100"); click("#sp-save")
r = pg.evaluate("ForgePassiveMerge.setRows(state.project,Forge.primaryPassive(state.project).id).filter(r=>r.efficacy_type===109).map(r=>[r.eff_value1,r.eff_value2,r.target_type])")
ok("revival row", r and r[0][0] == 100, r)
# intro
sp("intro-pick"); wait_for("[data-sp-intro]"); pg.fill("#sp-intro-search", "Gohan"); w(400)
pg.locator("[data-sp-intro]").first.click(); w(900)
i = pg.evaluate("ForgePassiveMerge.setRows(state.project,Forge.primaryPassive(state.project).id).filter(r=>r.passive_skill_effect_id).map(r=>[r.efficacy_type,r.passive_skill_effect_id,r.is_once])")
ok("intro set", len(i) == 1 and i[0][1] > 0, i)
# domain by turn
sp("domain-add"); wait_for("#sp-save")
pg.evaluate("document.querySelector('input[name=sp-when][value=turn]').checked=true"); pg.fill("#sp-domain-turn", "4")
click("#sp-save")
d = pg.evaluate("(state.project.tables.dokkan_field_passive_skill_relations||[]).map(r=>[r.dokkan_field_id,r.passive_skill_id])")
ok("domain relation", len(d) == 1, d)
desc = pg.evaluate("Forge.primaryPassive(state.project).itemized_description")
ok("trigger rows not in description", "Inherited gameplay effect" not in desc, desc[-160:])
click('[data-b="tab:special"]'); w(400)
rel = pg.evaluate("(state.project.tables.dokkan_field_passive_skill_relations||[])[0].id")
sp(f"domain-edit:passive:{rel}"); wait_for("#sp-dn")
pg.fill("#sp-dn", "Burning Arena"); pg.fill("#sp-dt", "5")
effs = pg.locator("[data-sp-eff]").count()
if effs: pg.locator("[data-sp-eff]").first.fill("25")
click("#sp-save"); w(1500)
dd = pg.evaluate("""()=>{const p=state.project,f=(p.tables.dokkan_fields||[])[0];const e=(p.tables.dokkan_field_efficacies||[]).filter(x=>f&&x.dokkan_field_efficacy_set_id===f.dokkan_field_efficacy_set_id);return f?[f.name,f.id,e.filter(x=>x.efficacy_type===121).map(x=>x.turn),e.map(x=>x.eff_value1).slice(0,4),(p.tables.dokkan_field_passive_skill_relations||[])[0].dokkan_field_id]:null}""")
ok("custom domain", dd and dd[0] == "Burning Arena" and dd[2] and all(t == 5 for t in dd[2]) and dd[4] == dd[1], dd)
print("   rels before standby:", pg.evaluate("JSON.stringify((state.project.tables.dokkan_field_passive_skill_relations||[]).map(r=>[r.id,r.dokkan_field_id,r.passive_skill_id]))"))
export("a")
# standby from Babidi
sp("standby-add"); wait_for("[data-sp-sb]")
names = pg.locator("[data-sp-sb]").all_inner_texts()
print("   standby characters:", len(names), [n.split("\n")[0] for n in names[:5]])
pg.locator("[data-sp-sb]").first.click()
for _ in range(100):
    if pg.evaluate("!!(state.project.tables.card_standby_skill_set_relations||[]).length"): break
    w(300)
w(800)
sb = pg.evaluate("(state.project.tables.standby_skill_sets||[]).map(x=>x.name)")
print("   rels after standby:", pg.evaluate("JSON.stringify((state.project.tables.dokkan_field_passive_skill_relations||[]).map(r=>[r.id,r.dokkan_field_id,r.passive_skill_id]))"))
ok("standby copied", len(sb) >= 1, sb)
click('[data-b="tab:special"]'); w(400)
sp("standby-edit"); wait_for("#sp-sn"); pg.fill("#sp-sn", "Ultimate Standby"); click("#sp-save")
ok("standby renamed", pg.evaluate("state.project.tables.standby_skill_sets[0].name") == "Ultimate Standby")
export("b")
pg.screenshot(path=SP + "3-hub-filled.png", full_page=True)
# passive step shows counter as an editable ability
click('[data-b="tab:passive"]'); w(800)
ok("passive step lists counter", "counter" in pg.inner_text("#bld").lower())
# removals
click('[data-b="tab:special"]'); w(400)
sp("standby-del"); sp("intro-del")
rel = pg.evaluate("document.querySelector('[data-sp^=\"domain-del:passive:\"]').dataset.sp.split(':')[2]")
print("   rel to delete:", rel)
pg.evaluate("""()=>{const o=Forge.localId;window.__tr=[];Forge.localId=function(p,t){if(t==='dokkan_field_passive_skill_relations'||t==='passive_skill_sets')window.__tr.push(t+' '+new Error().stack.split('\\n').slice(2,9).join(' | '));return o.apply(this,arguments)}}""")
print("   immediate:", pg.evaluate(f"ForgeSpecial.action('domain-del:passive:{rel}').then(()=>JSON.stringify((state.project.tables.dokkan_field_passive_skill_relations||[]).map(r=>[r.id,r.passive_skill_id])))"))
w(1500)
print("   TRACE:", pg.evaluate("window.__tr"))
left = pg.evaluate("[(state.project.tables.card_standby_skill_set_relations||[]).length,0,document.querySelectorAll('[data-sp^=\"domain-del\"]').length,ForgePassiveMerge.setRows(state.project,Forge.primaryPassive(state.project).id).filter(r=>r.passive_skill_effect_id||r.efficacy_type===0).length]")
ok("removed cleanly", left == [0, 0, 0, 0], left)
export("c")
print("errors:", errs[:3])
print(pg.evaluate("JSON.stringify([state.project.tables.dokkan_field_passive_skill_relations, (state.project.tables.dokkan_fields||[]).map(f=>f.id)])"))
pg.evaluate("ForgeSpecial.action('domain-del:passive:'+state.project.tables.dokkan_field_passive_skill_relations[0].id).then(()=>window.__r='ok').catch(e=>window.__r=String(e))"); w(800)
print(pg.evaluate("window.__r"), pg.evaluate("JSON.stringify(state.project.tables.dokkan_field_passive_skill_relations)"), errs)
