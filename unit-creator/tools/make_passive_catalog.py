"""Builds v2/ui/data/passive-catalog.json: every passive ability the game really uses (effect x boost/lower x
target, used by 3+ passives), with balanced defaults taken from real cards (the most common real setting among
recent LR/UR units, so every value - including ids - is one the game already uses)."""
import sqlite3, json, collections, sys
DB = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/work/web/ios-db/reference.db"
OUT = "/home/claude/work/v2/ui/data/passive-catalog.json"
mech = json.load(open("/home/claude/work/v2/ui/data/mechanics.json"))
EFF = {e["id"]: e for e in mech["efficacies"]}
TGT = {t["id"]: t["name"] for t in mech["target-types"]}
SKIP = {0, 103, 1009, 1011}   # 0/1009/1011: unnamed internals; 103 transformations live on the Transform tab
GROUP = {}
for e in (1, 2, 3, 16, 17, 18, 19, 44, 71, 72, 73, 82, 87, 93, 98, 104, 118): GROUP[e] = "Stats"
for e in (5, 20, 30, 51, 59, 60, 61, 63, 64, 65, 66, 67, 68, 69, 70, 77, 83, 96, 105, 127): GROUP[e] = "Ki & Ki Spheres"
for e in (13, 21, 22, 28, 50, 52, 78, 91, 94, 97, 99, 100, 101, 109, 112, 119, 120, 128, 129): GROUP[e] = "Defense & survival"
for e in (53, 76, 81, 86, 88, 90, 92): GROUP[e] = "Offense"
for e in (4, 84): GROUP[e] = "HP"
for e in (8, 9, 11, 24, 47, 48, 75, 107, 111, 114, 121, 122, 123, 124, 125, 126): GROUP[e] = "Enemy & battle effects"
for e in (79, 110, 115, 117, 131): GROUP[e] = "Character exclusive"
WHO = {1: "self", 2: "allies", 3: "the attacked enemy", 4: "all enemies", 12: "Super Class allies", 13: "Extreme Class allies",
       14: "Super Class enemies", 15: "Extreme Class enemies", 16: "allies (not self)"}
def label(e, calc, t):
    name = EFF.get(e, {}).get("name", "Game effect %d" % e)
    base = name.replace(" Boost/Reduction", "").replace("Boost/Reduction", "").strip()
    if calc == 3: verb = "Lower " + base
    elif calc == 1: verb = "Lower " + base
    elif calc == 4: verb = "Set " + base
    elif "Boost/Reduction" in name: verb = "Raise " + base
    else: verb = name
    who = WHO.get(t, TGT.get(t, ""))
    return verb + (" — " + who if who else "")
c = sqlite3.connect(DB)
cards = {r[0]: r for r in c.execute("select id, rarity, passive_skill_set_id from cards where id % 10 = 1")}
recent_sets = {r[2] for r in cards.values() if r[2] is not None and r[1] >= 4 and r[0] >= 1022000 and r[0] < 3000000}
set_of = collections.defaultdict(set)
for sid, pid in c.execute("select passive_skill_set_id, passive_skill_id from passive_skill_set_relations"): set_of[pid].add(sid)
cols = [r[1] for r in c.execute("pragma table_info(passive_skills)")]
rows = [dict(zip(cols, r)) for r in c.execute("select * from passive_skills")]
by = collections.defaultdict(list)
for r in rows:
    if r["efficacy_type"] in SKIP: continue
    sub = r["eff_value3"] if r["efficacy_type"] == 98 else r["eff_value2"] if r["efficacy_type"] == 68 else r["eff_value1"] if r["efficacy_type"] == 99 else None
    by[(r["efficacy_type"], r["calc_option"], r["target_type"], sub)].append(r)
out = []
STACK = {0: "ATK", 1: "DEF", 2: "critical hit chance", 3: "dodge chance", 4: "damage reduction", 5: "Ki"}
SPHERE = {1: "ATK", 2: "HP", 3: "DEF", 4: "critical hit chance", 5: "dodge chance", 6: "damage reduction"}
PREVENT = {1: "ATK", 2: "DEF", 3: "ATK & DEF"}
WORDS = {"Incremental": "", "Type/Class": "Type/Class"}
for (e, calc, t, sub), rs in by.items():
    # every variant the game has, even ones only one character uses
    plain = [r for r in rs if not r["sub_target_type_set_id"]] or rs
    recent = [r for r in plain if set_of[r["id"]] & recent_sets] or plain
    mode = lambda key, pool=recent: collections.Counter(r[key] for r in pool).most_common(1)[0][0]
    vals = collections.Counter((r["eff_value1"], r["eff_value2"], r["eff_value3"], r["efficacy_values"] or "{}") for r in recent).most_common(1)[0][0]
    name = label(e, calc, t)
    if e == 98: name = "Grows with each attack: " + STACK.get(sub, "stat") + (" (fixed)" if calc in (0, 1) else "") + " — " + WHO.get(t, "")
    elif e == 68: name = "Boost per Ki Sphere type: " + SPHERE.get(sub, "stat") + " — " + WHO.get(t, "")
    elif e == 99: name = "Can't have " + PREVENT.get(sub, "stats") + " lowered — " + WHO.get(t, "")
    elif calc in (0, 1) and e in (1, 2, 3, 13, 16, 17, 18, 90, 91): name += " (fixed amount)"
    out.append({"id": "%d.%d.%d.%s" % (e, calc, t, sub), "eff": e, "calc": calc, "target": t, "group": GROUP.get(e, "Special"), "label": name,
                "about": EFF.get(e, {}).get("description", ""), "values": EFF.get(e, {}).get("values", ["", "", "", "", ""]),
                "uses": len(rs), "defaults": {"exec_timing_type": mode("exec_timing_type"), "turn": mode("turn"), "probability": mode("probability"), "is_once": mode("is_once"),
                "eff_value1": vals[0], "eff_value2": vals[1], "eff_value3": vals[2], "efficacy_values": vals[3]}})
order = ["Stats", "Ki & Ki Spheres", "Offense", "Defense & survival", "HP", "Enemy & battle effects", "Character exclusive", "Special"]
out.sort(key=lambda x: (order.index(x["group"]), -x["uses"]))
seen = collections.Counter()
CALCNAME = {0: "fixed amount", 1: "fixed amount", 2: "percentage", 3: "percentage", 4: "set value"}
AMOUNT_MATTERS = {4, 28, 61, 68}   # HP, absorption and per-sphere boosts: fixed vs % really differs
keep = []
for x in out:
    seen[x["label"]] += 1
    if seen[x["label"]] > 1:
        x["label"] += " (%s)" % CALCNAME.get(x["calc"], "alternate setting")
    keep.append(x)
out = keep
# Rows whose game target doesn't match what they do (they always hit the attacked enemy) or that undo a debuff only bosses use.
for x in out:   # event-only spheres (Candy, Carrots) make a poor default: any Ki Sphere instead
    if x["eff"] == 68 and x["defaults"]["eff_value1"] in (448, 450, 4096): x["defaults"]["eff_value1"] = 63

seen = collections.Counter()
for x in out:
    seen[x["label"]] += 1
    if seen[x["label"]] > 1: x["label"] += " (alternate setting %d)" % seen[x["label"]]
# Character-exclusive effects point at real game cards / params: list every real setting with whose it is,
# so the editor can offer "Great Ape Vegeta (from Vegeta)" instead of card IDs.
names = dict(c.execute("select id, name from cards"))
owner_of_set = collections.defaultdict(list)
for cid, sid in c.execute("select id, passive_skill_set_id from cards where passive_skill_set_id is not null"): owner_of_set[sid].append(cid)
def owner(pid):
    for sid in sorted(set_of[pid]):
        for cid in sorted(owner_of_set[sid]):
            if names.get(cid): return names[cid]
    return ""
for x in out:
    if x["eff"] not in (79, 131): continue
    seen = {}
    for r in by[(x["eff"], x["calc"], x["target"], None)]:
        key = (r["eff_value1"], r["eff_value2"], r["eff_value3"])
        if key in seen: continue
        who = owner(r["id"])
        if x["eff"] in (79, 131): label_ = (names.get(r["eff_value1"]) or "Card %d" % r["eff_value1"]).replace("\n", " ") + (" (from " + who.replace("\n", " ") + ")" if who and who != names.get(r["eff_value1"]) else "")
        seen[key] = label_
    one = {}
    for k, v in seen.items():   # one per card (game ids ending 0 and 1 are the same card)
        if v not in one or k[0] % 10 == 1: one[v] = k
    x["choices"] = sorted(([list(k), v] for v, k in one.items()), key=lambda z: z[1])
json.dump({"source": "game passive_skills", "count": len(out), "abilities": out}, open(OUT, "w"), separators=(",", ":"))
print(len(out), "abilities;", collections.Counter(x["group"] for x in out))
# The app loads this as a script (bundled with the rest of the UI on every platform).
open(OUT.replace(".json", "").replace("data/passive-catalog", "passive-catalog-data") + ".js", "w").write("window.ForgePassiveCatalogData=" + json.dumps({"count": len(out), "abilities": out}, separators=(",", ":")) + ";\n")
