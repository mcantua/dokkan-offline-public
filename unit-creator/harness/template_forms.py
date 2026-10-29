import os, json, subprocess
os.environ["FORGE_STATE"]="/home/claude/work/harness/state-tforms"; os.environ["FRESH"]="1"
from harness import Session
SP="/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/"
s=Session(viewport=(412,915)).open(); pg=s.page
while pg.evaluate("window.__forgeWorkspaceStartup")!="ready": pg.wait_for_timeout(100)
for cid in [1014821, 1018651, 1017631, 1019741, 1018721, 1014761]:
    pg.evaluate(f"createUnit({cid})")
    for _ in range(200):
        if pg.evaluate("state.view==='editor' && !!state.project && document.getElementById('busy').hidden"): break
        pg.wait_for_timeout(100)
    pg.wait_for_timeout(600)
    info=pg.evaluate("""()=>{const p=state.project;const v=Forge.validate(p);
      const forms=(p.formProjects||[]).map(f=>[Forge.card(f).name,f.source.cardId,f.targetId]);
      let sql='',err='';try{sql=Forge.sql(p)}catch(e){err=e.message}
      return {name:Forge.card(p).name,target:p.targetId,forms,links:(p.transformLinks||[]).length,errors:v.errors.slice(0,3),sqlErr:err,sql}}""")
    open(SP+f"tf-{cid}.sql","w").write(info["sql"])
    a=subprocess.run(["python3","apply_sql.py",SP+f"tf-{cid}.sql"],capture_output=True,text=True).stdout.strip().splitlines()[-1:]
    o=subprocess.run(["python3","-c",f"exec(open('overwrite_check.py').read().split('def main')[0]);print(check(open('{SP}tf-{cid}.sql').read()))"],capture_output=True,text=True)
    # transformation targets in exported SQL
    print(cid, info["name"], info["target"], "forms:", info["forms"], "links:", info["links"], "errors:", info["errors"], info["sqlErr"], "| apply:", a, "| overwrite:", (o.stdout or o.stderr).strip()[-200:])
    print("   toast:", pg.inner_text("#toast")[:200])
pg.locator('[data-b="tab:transform"]').first.click(); pg.wait_for_timeout(600)
pg.screenshot(path=SP+"tf-tab.png", full_page=True)
s.report("tforms"); s.close()
