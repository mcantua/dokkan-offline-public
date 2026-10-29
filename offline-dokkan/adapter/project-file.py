#!/usr/bin/env python3
"""Project a real saved Forge file using a pinned read-only master. Never modifies the master."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
MAX_PROJECT = 16 * 1024 * 1024


def strict_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("Duplicate project field")
        result[key] = value
    return result


def invalid_constant(_):
    raise ValueError("Non-finite project number")


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path)
    parser.add_argument("master", type=Path)
    parser.add_argument("--database", required=True, choices=("eclipse", "sparking"))
    parser.add_argument("--version", required=True, type=int)
    parser.add_argument("--rarity", choices=("UR", "LR", "SLR", "GR"))
    parser.add_argument("--creator-id")
    parser.add_argument("--creator-name")
    parser.add_argument("--definition-id")
    parser.add_argument("--stat-policy", choices=("master-coefficient-linear-floor-v1", "creator-cap-normalized-v1"))
    parser.add_argument("--official-upgrade", action="store_true")
    parser.add_argument("--output", type=Path, default=HERE / "build/normalized-unit.json")
    args = parser.parse_args()
    master = args.master.resolve(strict=True)
    project_path = args.project.resolve(strict=True)
    output = args.output.resolve()
    if output in (master, project_path):
        raise ValueError("Output must differ from both input files")
    wal = Path(str(master) + "-wal")
    if wal.exists() and wal.stat().st_size:
        raise ValueError("Use an exported standalone master without an active WAL")
    if project_path.stat().st_size > MAX_PROJECT or args.version < 1:
        raise ValueError("Invalid revision or project exceeds 16 MB")
    if not args.official_upgrade and args.rarity is None:
        raise ValueError("Declare the intended rarity with --rarity")
    project = json.loads(project_path.read_text(encoding="utf-8"), object_pairs_hook=strict_object,
                         parse_constant=invalid_constant)
    if not isinstance(project, dict) or not isinstance(project.get("tables"), dict):
        raise ValueError("Expected a saved Forge project")
    before = digest(master)
    host = {"contentId": "sha256:" + before, "sourceDatabase": args.database,
            "version": args.version, "rarity": args.rarity}
    for key, value in (("creatorId", args.creator_id), ("creatorName", args.creator_name),
                       ("definitionId", args.definition_id), ("statPolicy", args.stat_policy)):
        if value is not None:
            host[key] = value
    # Independently prove only complete, byte-for-value-equivalent baseline rows.
    # Unknown/modified rows remain unproven and the JS adapter rejects them explicitly.
    unchanged = []
    with sqlite3.connect(master.as_uri() + "?mode=ro", uri=True) as db:
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA query_only=ON")
        known = {row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
        columns = {table: {row[1] for row in db.execute('PRAGMA table_info("' + table + '")')}
                   for table in known if re.fullmatch(r"[a-z][a-z0-9_]*", table)}
        for table, rows in project["tables"].items():
            if not re.fullmatch(r"[a-z][a-z0-9_]*", table) or table not in known or not isinstance(rows, list):
                continue
            if any(not isinstance(row, dict) or not isinstance(row.get("id"), int)
                   or isinstance(row.get("id"), bool) for row in rows):
                continue
            identical = True
            for row in rows:
                stored = db.execute('SELECT * FROM "' + table + '" WHERE id=?', (row["id"],)).fetchone()
                if stored is None or dict(stored) != row:
                    identical = False
                    break
            if identical:
                unchanged.append(table)
    source = r"""
const fs=require('node:fs'),helper=require(process.argv[1]);
(async()=>{const input=JSON.parse(fs.readFileSync(0,'utf8'));
 const proven=new Set(input.unchanged);
 input.host.isUnchangedMasterRows=async(table)=>proven.has(table);
 const fn=input.official?helper.projectToOfficialUpgrade:helper.projectToDefinition;
 process.stdout.write(JSON.stringify(await fn(input.project,input.host))+'\n');
})().catch(e=>{process.stderr.write((e.code||'PROJECT_PROJECTION_FAILED')+'\n');process.exit(1)});
"""
    child = subprocess.run(["node", "-e", source, str(HERE / "creator-project.js")],
                           input=json.dumps({"project": project, "host": host,
                                             "unchanged": unchanged, "official": args.official_upgrade},
                                            ensure_ascii=False, allow_nan=False),
                           encoding="utf-8", stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if child.returncode:
        # Error codes only; never print project rows, account data or arbitrary native output.
        code = child.stderr.strip()
        raise ValueError(code if re.fullmatch(r"[A-Z_]+(?::[a-z0-9_]+)?", code) else "PROJECT_PROJECTION_FAILED")
    if digest(master) != before or wal.exists() and wal.stat().st_size:
        raise ValueError("Master changed during projection; output refused")
    document = json.loads(child.stdout)
    if document.get("source", {}).get("content_id") != host["contentId"]:
        raise ValueError("Projection content identity mismatch")
    for table, rows in {"cards": [document["card"]], **document["tables"]}.items():
        if table not in columns or any(set(row) - columns[table] for row in rows):
            raise ValueError("UNSUPPORTED_SETTINGS_COLUMN")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", prefix=".projection-", dir=output.parent,
                                         delete=False) as staged:
            temporary = Path(staged.name)
            staged.write(child.stdout)
            staged.flush()
            os.fsync(staged.fileno())
        temporary.replace(output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    print("Projected real Creator settings. The native core validates the document again on import/apply.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, sqlite3.Error, RecursionError, OverflowError):
        # Preserve the useful allowlisted adapter code without exposing user data/paths.
        import sys
        error = sys.exc_info()[1]
        message = str(error)
        print(message if re.fullmatch(r"[A-Z_]+(?::[a-z0-9_]+)?", message)
              else "Could not project this file. Inputs were kept; check source, revision and supported settings.",
              file=sys.stderr)
        raise SystemExit(1)
