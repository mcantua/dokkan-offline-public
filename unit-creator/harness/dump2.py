import os
os.environ["FORGE_STATE"] = "/home/claude/work/harness/state-cat"; os.environ["FRESH"] = "1"
from harness import Session
s = Session(viewport=(412, 915)).open(); pg = s.page
while pg.evaluate("window.__forgeWorkspaceStartup") != "ready": pg.wait_for_timeout(100)
print(pg.evaluate("JSON.stringify([ForgeBuilder.CLASSES, ForgeBuilder.TYPES, typeof ForgeBuilder.elementParts, typeof ForgeBuilder.passiveLine, Forge.rarities, (D=>D&&D.damageProfiles&&D.damageProfiles.map(p=>p.key))(window.ForgeMechanics||window.FORGE_MECHANICS)])"))
print(pg.evaluate("Object.keys(ForgeBuilderUI).join(',')"))
s.close()
