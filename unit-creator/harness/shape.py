"""Eclipse-shape checks for exported unit SQL (compares against the structure of a unit known to load in Eclipse)."""
import re, sqlite3, json, sys
sys.path.insert(0, '/home/claude/work/gohan')
from parse import parse
ref = sqlite3.connect('file:/home/claude/work/apk/assets/reference.db?mode=ro', uri=True)
SK = {"passive_skills": "eff_value", "active_skills": "eff_val", "standby_skills": "eff_val", "finish_skills": "eff_val"}
def check(sql, source_ids):
    probs = []
    rows, other = parse(sql)
    if re.search(r'^INSERT INTO', sql, re.M): probs.append("plain INSERT (re-import would fail)")
    for t, rs in rows.items():
        for r in rs:
            if r.get('id') is not None and abs(int(r['id'])) > 99_999_999: probs.append(f"{t} id {r['id']} > 8 digits"); break
    cards = {r['id'] for r in rows.get('cards', [])}
    for r in rows.get('cards', []):
        if r['id'] % 10 not in (0, 1): probs.append(f"card id {r['id']} does not end in 0/1")
        if r['id'] % 10 == 1 and r.get('optimal_awakening_grow_type'):
            src_has = True
            if not any(x['card_id'] == r['id'] and x['type'] == 'CardAwakeningRoute::Optimal' for x in rows.get('card_awakening_routes', [])): probs.append(f"card {r['id']} has EZA stages but no EZA route")
    params = {}
    for p in rows.get('battle_params', []): params.setdefault(p['param_no'], []).append(p)
    desc = {(d['skill_type'], d['skill_id']) for d in rows.get('transformation_descriptions', [])}
    for t, prefix in SK.items():
        stype = {"passive_skills": "PassiveSkill", "active_skills": "ActiveSkill", "standby_skills": "StandbySkill", "finish_skills": "FinishSkill"}[t]
        for r in rows.get(t, []):
            if r['efficacy_type'] not in (79, 103): continue
            try: vals = json.loads(r.get('efficacy_values') or '{}')
            except Exception: vals = {}
            v = vals if isinstance(vals, list) else [r.get(prefix + '1'), r.get(prefix + '2'), r.get(prefix + '3')]
            if r['efficacy_type'] == 103 and (stype, r['id']) not in desc: probs.append(f"{t} {r['id']} transformation has no description")
            g = v[2]
            if g and g > 0:
                group = params.get(g)
                if group is None:
                    vals_ = [x[0] for x in ref.execute('select value from battle_params where param_no=?', (g,))]
                    if any(x in source_ids for x in vals_): probs.append(f"{t} {r['id']} uses shared battle params {g} that return to official card")
                elif any(p['value'] in source_ids for p in group): probs.append(f"{t} {r['id']} private params still name official card")
            if r['efficacy_type'] == 103 and v[0] in source_ids: probs.append(f"{t} {r['id']} transforms into its own official source card")
    # idempotency: apply twice
    db = sqlite3.connect('/home/claude/work/harness/work.db'); db.execute('BEGIN')
    try:
        from integrity import stmts
        for _ in range(2):
            for st in stmts(sql): db.execute(st)
    except Exception as e: probs.append("apply twice failed: " + str(e))
    db.execute('ROLLBACK')
    return probs
if __name__ == '__main__':
    from collections import Counter
    tot = Counter(); n = 0
    for f in sys.argv[1:]:
        for r in json.load(open(f)):
            if not r.get('sql'): continue
            n += 1
            for p in check(r['sql'], {r['id'], r['id'] - 1}): tot[re.sub(r'\d+', 'N', p)] += 1
    print("units:", n); [print(f"{v:5d}  {k}") for k, v in tot.most_common()]
