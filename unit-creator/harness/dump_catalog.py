import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-cat"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": pg.wait_for_timeout(100)
B = "ForgeBuilderModel"
print(pg.evaluate("Object.keys(window).filter(k=>/^Forge/.test(k)).join(' ')"))
print(pg.evaluate("""(()=>{const B=window.ForgeBuilderModel||window.ForgeBuilder;return B?['PASSIVE:'+B.PASSIVE.map(e=>e.key+'['+e.label+']{'+e.fields.map(f=>f.name).join(',')+'}').join('; '),'COND:'+B.CONDITIONS.map(c=>c.key+'['+c.label+']{'+c.fields.map(f=>f.name).join(',')+'}').join('; '),'SA:'+B.SA_EFFECTS.map(e=>e.key+'['+e.label+']').join('; '),'ACT:'+B.ACTIVE_EFFECTS.map(e=>e.key).join(',')].join('\\n'):'none'})()"""))
s.close()
