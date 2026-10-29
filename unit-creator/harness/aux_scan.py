"""For source cards, list DB rows in other tables that reference rows the app copies, but which the app doesn't copy."""
import sqlite3, json, sys
c = sqlite3.connect('file:/home/claude/work/apk/assets/reference.db?mode=ro', uri=True)
tables = [r[0] for r in c.execute("select name from sqlite_master where type='table'")]
cols = {t: [r[1] for r in c.execute(f'pragma table_info("{t}")')] for t in tables}
# what the app copies (from loadTemplate)
def copied(card):
    out = {}
    def add(t, ids): out.setdefault(t, set()).update(i for i in ids if i is not None)
    q = lambda s, a=(): [r[0] for r in c.execute(s, a)]
    add('cards', [card])
    for t in ["card_card_categories","card_specials","card_active_skills","card_standby_skill_set_relations","card_finish_skill_set_relations","card_motions","passive_skill_set_additions"]:
        if t in cols: add(t, q(f'select id from "{t}" where card_id=?', (card,)))
    cr = c.execute('select passive_skill_set_id, leader_skill_set_id, optimal_awakening_grow_type from cards where id=?', (card,)).fetchone()
    ps = {cr[0]}; ls = {cr[1]}
    if cr[2]:
        for a, b in c.execute('select passive_skill_set_id, leader_skill_set_id from optimal_awakening_growths where optimal_awakening_grow_type=?', (cr[2],)): ps.add(a); ls.add(b)
        add('optimal_awakening_growths', q('select id from optimal_awakening_growths where optimal_awakening_grow_type=?', (cr[2],)))
    add('passive_skill_sets', ps); add('leader_skill_sets', ls)
    for p in ps: add('passive_skills', q('select passive_skill_id from passive_skill_set_relations where passive_skill_set_id=?', (p,)))
    for l in ls: add('leader_skills', q('select id from leader_skills where leader_skill_set_id=?', (l,)))
    sp = q('select special_set_id from card_specials where card_id=?', (card,)); add('special_sets', sp)
    for s in sp: add('specials', q('select id from specials where special_set_id=?', (s,)))
    asets = q('select active_skill_set_id from card_active_skills where card_id=?', (card,)); add('active_skill_sets', asets)
    for a in asets: add('active_skills', q('select id from active_skills where active_skill_set_id=?', (a,)))
    if 'card_standby_skill_set_relations' in cols:
        ss = q('select standby_skill_set_id from card_standby_skill_set_relations where card_id=?', (card,)); add('standby_skill_sets', ss)
        for s in ss: add('standby_skills', q('select id from standby_skills where standby_skill_set_id=?', (s,)))
    return out
REF = {'passive_skills': ['passive_skill_id'], 'passive_skill_sets': ['passive_skill_set_id','target_passive_skill_set_id','additional_passive_skill_set_id'], 'leader_skill_sets': ['leader_skill_set_id'],
       'card_specials': ['card_special_id'], 'special_sets': ['special_set_id'], 'specials': ['special_id'], 'active_skill_sets': ['active_skill_set_id'], 'active_skills': ['active_skill_id'],
       'standby_skill_sets': ['standby_skill_set_id'], 'standby_skills': ['standby_skill_id'], 'cards': ['card_id','awaked_card_id','cut_in_card_id'], 'leader_skills': ['leader_skill_id']}
from collections import Counter
missing = Counter(); examples = {}
cards = [int(x) for x in sys.argv[1].split(',')]
for card in cards:
    cp = copied(card)
    for t, ids in cp.items():
        for col in REF.get(t, []):
            for ot in tables:
                if ot in cp and ot != 'transformation_descriptions' and col in cols[ot] and ot in ('card_card_categories','card_specials','card_active_skills','passive_skill_set_relations','optimal_awakening_growths','leader_skills','specials','active_skills','standby_skills','card_standby_skill_set_relations','card_motions'): continue
                if col in cols[ot] and ids:
                    n = c.execute(f'select count(*) from "{ot}" where "{col}" in ({",".join(map(str, ids))})').fetchone()[0]
                    if n: missing[(ot, col)] += 1; examples.setdefault((ot, col), card)
    # transformation descriptions
    for st, t in [('PassiveSkill','passive_skills'),('ActiveSkill','active_skills'),('StandbySkill','standby_skills')]:
        ids = cp.get(t, set())
        if ids:
            n = c.execute(f"select count(*) from transformation_descriptions where skill_type=? and skill_id in ({','.join(map(str,ids))})", (st,)).fetchone()[0]
            if n: missing[('transformation_descriptions', st)] += 1; examples.setdefault(('transformation_descriptions', st), card)
for k, v in missing.most_common(): print(f"{v:4d} cards  {k}  e.g. {examples[k]}")
