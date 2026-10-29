"""Leader step: combine leader skills from characters (within today's meta) + random skill names."""
import os, json, subprocess, sys
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-leader"; os.environ["FRESH"] = "1"
from harness import Session
SP = "/tmp/claude-0/sim/leader/"; os.makedirs(SP, exist_ok=True)
s = Session(viewport=(412, 915)).open(); pg = s.page; w = lambda ms=600: pg.wait_for_timeout(ms)
errs = []; pg.on("pageerror", lambda e: errs.append(str(e)))
def ok(name, cond, extra=""): print(("PASS " if cond else "FAIL ") + name, extra)
def wait_for(sel, n=200):
    for _ in range(n):
        if pg.locator(sel).count(): return True
        w(200)
    return False
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": w(100)
pg.evaluate("createUnit(1018721)")
for _ in range(200):
    if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
    w(100)
w(1000)
pg.locator('[data-b="tab:leader"]').first.click(); w(1200)
ok("leader button", pg.locator(".porg-leaders").count() == 1)
ok("dice next to leader name", pg.locator(".dice-wrap .dice-button").count() >= 1)
before_name = pg.evaluate("(state.project.tables.leader_skill_sets||[]).find(x=>x.id===Forge.card(state.project).leader_skill_set_id)?.name")
pg.locator(".dice-wrap .dice-button").first.click(); w(400)
after_name = pg.evaluate("(state.project.tables.leader_skill_sets||[]).find(x=>x.id===Forge.card(state.project).leader_skill_set_id)?.name")
ok("dice renames leader", after_name and after_name != before_name, (before_name, after_name))
for who in sys.argv[1:] or ["Vegito", "Super Saiyan Goku"]:
    pg.locator(".porg-leaders").first.click(); w(500)
    pg.fill("#porg-search", who); w(1500)
    pg.locator(f'[data-porg-name="{who}"]').click(); wait_for("#porg-go")
    print(who, "| hero:", pg.inner_text(".porg-hero").replace("\n", " "), "|", pg.inner_text("#porg-go"))
    pg.screenshot(path=SP + who.replace(" ", "_") + "-1.png")
    pg.locator("#porg-go").click(); wait_for("#porg-apply", 1500)
    print(pg.inner_text("#dialog-content")[:1500])
    pg.screenshot(path=SP + who.replace(" ", "_") + "-2.png")
    pg.locator("#porg-apply").click(); w(1500)
    r = pg.evaluate("""()=>{const p=state.project,c=Forge.card(p),set=p.tables.leader_skill_sets.find(x=>x.id===c.leader_skill_set_id),rows=p.tables.leader_skills.filter(x=>x.leader_skill_set_id===set.id);
      const g=null;const v=Forge.validate(p);let sql='',err='';try{sql=Forge.sql(p)}catch(e){err=e.message}
      return {name:set.name,desc:set.description,groups:g,errors:v.errors.slice(0,3),err,sql}}""")
    open(SP + "l.sql", "w").write(r.pop("sql"))
    tot = pg.evaluate("""()=>{const p=state.project,c=Forge.card(p),rows=p.tables.leader_skills.filter(x=>x.leader_skill_set_id===c.leader_skill_set_id);const t={ki:0,hp:0,atk:0,def:0};
      const seen=new Map();for(const r of rows){const v=JSON.parse(r.efficacy_values),k=r.sub_target_type_set_id;const e=Number(r.efficacy_type);const a=seen.get(k)||{ki:0,hp:0,atk:0,def:0};
      if(e===5)a.ki+=v[0];if(e===83)a.ki+=v[1];if(e===82){a.hp+=v[1];a.atk+=v[1];a.def+=v[1]}if(e===104){a.hp+=v[0];a.atk+=v[1];a.def+=v[2]}seen.set(k,a)}
      /* worst case: the biggest main row plus the biggest extra row */const list=[...seen.values()].sort((x,y)=>y.hp-x.hp);
      const main=list.reduce((m,a)=>a.ki>0?(a.hp>m.hp?a:m):m,{ki:0,hp:0,atk:0,def:0}),extra=list.filter(a=>!a.ki).reduce((m,a)=>a.hp>m.hp?a:m,{ki:0,hp:0,atk:0,def:0});
      return {ki:main.ki+extra.ki,hp:main.hp+extra.hp,atk:main.atk+extra.atk,def:main.def+extra.def}}""")
    pg.locator('[data-b="tab:leader"]').first.click(); w(1200)
    ok(who + ": editable in the builder", pg.locator(".bld-group").count() > 0, pg.locator(".bld-group").count())
    ok(who + ": within meta", tot["ki"] <= 4 and tot["hp"] <= 250 and tot["atk"] <= 220 and tot["def"] <= 220, tot)
    print("   name:", r["name"], "| errors:", r["errors"], r["err"], "| apply:", subprocess.run(["python3", "apply_sql.py", SP + "l.sql"], capture_output=True, text=True).stdout.strip().splitlines()[-1:])
pg.evaluate("ForgeGuideUI.undo()"); w(1200)
# all skill names at once
names0 = pg.evaluate("['leader_skill_sets','passive_skill_sets','active_skill_sets'].map(t=>(state.project.tables[t]||[]).map(x=>x.name).join('|'))")
pg.evaluate("document.querySelector('.bld-more').open=true"); pg.locator(".dice-all").first.click(); w(800)
names1 = pg.evaluate("['leader_skill_sets','passive_skill_sets','active_skill_sets'].map(t=>(state.project.tables[t]||[]).map(x=>x.name).join('|'))")
ok("new skill names for all", names0 != names1, (names0, names1))
print("errors:", errs[:3])
