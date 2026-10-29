import os, json
os.environ.setdefault("FORGE_STATE","/home/claude/work/harness/state-builder")
from harness import Session
s=Session(viewport=(412,915)).open(); pg=s.page
while pg.evaluate("window.__forgeWorkspaceStartup")!="ready": pg.wait_for_timeout(100)
for q in ["Gohan (Beast)","Super Saiyan Goku","Legendary Super Saiyan Broly"]:
    r=pg.evaluate("""async (q)=>{const rows=await Native.call('query',{table:'cards',search:{column:'name',text:q},order:'id',limit:400});
      const c=await ForgeCardVersions.collapse(rows);return [rows.length,c.map(x=>[x.id,x.rarity,x.element,ForgeCardVersions.status(x)])]}""", q)
    print(q, "raw", r[0], "shown", len(r[1]), r[1][:12])
# Source screen
pg.evaluate("navigate('source')"); pg.wait_for_timeout(800)
pg.fill("#source-query","Gohan (Beast)"); pg.wait_for_timeout(1500)
print("source:", pg.inner_text("#source-results")[:400].replace("\n"," | "))
print("pages:", pg.inner_text("#source-pages"))
pg.screenshot(path="/tmp/claude-0/-home-claude/fc61b99f-cb57-56bc-b827-ee4cb4796a4c/scratchpad/source.png")
pg.check("#source-all"); pg.wait_for_timeout(1200)
print("all versions count:", pg.locator(".source-tile").count())
s.report("versions"); s.close()
