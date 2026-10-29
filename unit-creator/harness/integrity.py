import json, re, sqlite3
FK = {"card_category_id":"card_categories","special_category_id":"special_categories","view_id":"special_views","special_view_id":"special_views","bonus_view_id1":"special_views","bonus_view_id2":"special_views","cut_in_card_id":"cards","card_id":"cards","passive_skill_set_id":"passive_skill_sets","passive_skill_id":"passive_skills","target_passive_skill_set_id":"passive_skill_sets","additional_passive_skill_set_id":"passive_skill_sets","leader_skill_set_id":"leader_skill_sets","special_set_id":"special_sets","active_skill_set_id":"active_skill_sets","standby_skill_set_id":"standby_skill_sets","finish_skill_set_id":"finish_skill_sets","dokkan_field_id":"dokkan_fields","finish_special_id":"finish_specials","sub_target_type_set_id":"sub_target_type_sets","passive_skill_effect_id":"passive_skill_effects","character_id":"characters","card_unique_info_id":"card_unique_infos","special_bonus_id1":"special_bonuses","special_bonus_id2":"special_bonuses","ultimate_special_id":"ultimate_specials","awaked_card_id":"cards","card_special_id":"card_specials"}
for i in range(1,8): FK[f"link_skill{i}_id"]="link_skills"
def stmts(sql):
    buf = ""
    for line in sql.splitlines(keepends=True):
        if not buf and line.startswith("--"): continue
        buf += line
        if sqlite3.complete_statement(buf): yield buf; buf = ""
def check(db, sql):
    """db: connection inside a transaction. returns list of problems (and applies SQL)."""
    tables = {r[0] for r in db.execute("select name from sqlite_master where type='table'")}
    ins = []
    for st in stmts(sql):
        db.execute(st)
        m = re.match(r'\s*INSERT (?:OR REPLACE )?INTO "(\w+)"', st)
        if m: ins.append((m.group(1), db.execute("select last_insert_rowid()").fetchone()[0]))
    probs = []
    for t, rid in ins:
        cur = db.execute(f'SELECT * FROM "{t}" WHERE rowid=?', (rid,)); cols = [d[0] for d in cur.description]; row = dict(zip(cols, cur.fetchone()))
        for col, v in row.items():
            if col in FK and FK[col] in tables and v not in (None, 0, "0", ""):
                if not db.execute(f'SELECT 1 FROM "{FK[col]}" WHERE id=?', (v,)).fetchone(): probs.append(f"{t}#{row.get('id')}.{col}={v} missing in {FK[col]}")
            if col == "causality_conditions" and v:
                try:
                    j = json.loads(v); src = str(j.get("source", "")) if isinstance(j, dict) else ""
                except Exception: probs.append(f"{t}#{row.get('id')}.causality_conditions not JSON: {v[:60]}"); continue
                for n in re.findall(r"\d+", src):
                    if not db.execute("SELECT 1 FROM skill_causalities WHERE id=?", (int(n),)).fetchone(): probs.append(f"{t}#{row.get('id')} condition #{n} missing")
            if col in ("efficacy_values",) and v not in (None, ""):
                try: json.loads(v)
                except Exception: probs.append(f"{t}#{row.get('id')}.{col} not JSON: {str(v)[:60]}")
    # transformation descriptions point at real skill rows
    TYPES = {"PassiveSkill":"passive_skills","ActiveSkill":"active_skills","StandbySkill":"standby_skills","FinishSkill":"finish_skills"}
    for t, rid in ins:
        if t == "transformation_descriptions":
            st, sid = db.execute('select skill_type, skill_id from transformation_descriptions where rowid=?', (rid,)).fetchone()
            if TYPES.get(st) in tables and not db.execute(f'select 1 from "{TYPES[st]}" where id=?', (sid,)).fetchone(): probs.append(f"transformation description -> missing {st} {sid}")
    return probs
