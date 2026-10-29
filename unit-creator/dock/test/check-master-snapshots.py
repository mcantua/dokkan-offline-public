#!/usr/bin/env python3
"""One focused native-source master snapshot check against real, synthetic SQLite databases."""
import os
import pathlib
import sqlite3
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
TABLES = {
    "cards": "id,name,rarity,element,resource_id,hp_max,atk_max,def_max,passive_skill_set_id,leader_skill_set_id",
    "card_categories": "id,name", "link_skills": "id,name", "leader_skill_sets": "id",
    "leader_skills": "id,leader_skill_set_id", "passive_skill_sets": "id", "passive_skills": "id",
    "passive_skill_set_relations": "id,passive_skill_set_id,passive_skill_id",
}
with tempfile.TemporaryDirectory(prefix="dokkan-master-source-check-") as temporary:
    tmp = pathlib.Path(temporary)
    fixtures = []
    for version in [7, 8]:
        fixture = tmp / f"fixture-{version}.db"
        with sqlite3.connect(fixture) as db:
            for name, columns in TABLES.items():
                db.execute(f"CREATE TABLE {name} ({','.join(c + ' INTEGER' for c in columns.split(','))})")
            db.executemany("INSERT INTO cards (id,name) VALUES (?,?)", [(i, "Synthetic character") for i in range(1001)])
            db.execute(f"PRAGMA user_version={version}")
        fixtures.append(str(fixture))
    classes = tmp / "classes"
    classes.mkdir()
    classpath = os.pathsep.join(str(ROOT / p) for p in ["dock/build/stubs", "dock/app-v2.jar"])
    sources = list((ROOT / "dock/src/com/personal/aihub").glob("*.java"))
    sources += [ROOT / "dock/test/master-runtime/android/database/sqlite/SQLiteDatabase.java", ROOT / "dock/test/com/personal/aihub/MasterDatabaseSnapshotsTest.java"]
    subprocess.run([str(ROOT / "tools/javac"), "--release", "8", "-Xlint:-options", "-cp", classpath, "-d", str(classes), *map(str, sources)], check=True)
    subprocess.run(["java", "-cp", str(classes) + os.pathsep + classpath, "com.personal.aihub.MasterDatabaseSnapshotsTest", *fixtures, *(["numbered"] if "--numbered" in sys.argv else [])], check=True)
