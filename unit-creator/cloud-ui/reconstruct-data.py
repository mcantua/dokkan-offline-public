#!/usr/bin/env python3
"""Reconstruct cloud-only SQLite tables from the committed browser snapshot (never original DB bytes)."""
import argparse
import base64
import gzip
import hashlib
import json
import pathlib
import re
import sqlite3

ROOT = pathlib.Path(__file__).resolve().parents[2]
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\Z")


def embedded_files(path):
    page = path.read_text()
    outer = re.search(r'<script id="standalone-payload" type="application/octet-stream">([^<]+)</script>', page)
    if outer:
        page = gzip.decompress(base64.b64decode(outer[1], validate=True)).decode()
    marker = "const files = "
    start = page.index(marker) + len(marker)
    files, _ = json.JSONDecoder().raw_decode(page[start:])
    if not isinstance(files, dict):
        raise ValueError("Missing standalone resource map")
    return files


def snapshot(files, prefix, base=None):
    def read(name):
        item = files[prefix + name + ".b64.txt"]
        if item[2:] != ["text"]:
            raise ValueError("Expected bundled base64-text database resource")
        return json.loads(gzip.decompress(base64.b64decode(item[1], validate=True)))
    manifest = read("manifest.json.gz")
    tables = {}
    for chunk in sorted(set(manifest["files"].values())):
        if pathlib.PurePosixPath(chunk).name != chunk:
            raise ValueError("Invalid database chunk path")
        raw = base64.b64decode(files[prefix + chunk + ".b64.txt"][1], validate=True)
        expected = re.search(r"\.([a-f0-9]{10})\.json\.gz$", chunk)
        if not expected or hashlib.sha256(raw).hexdigest()[:10] != expected[1]:
            raise ValueError("Bundled chunk hash mismatch")
        for table, payload in read(chunk).items():
            if table in tables or manifest["files"].get(table) != chunk:
                raise ValueError("Duplicate/unexpected bundled table")
            columns = payload["c"]
            if payload.get("base"):
                if base is None or columns != base[table]["c"]:
                    raise ValueError("Delta base columns differ")
                original = base[table]["r"]
                rows = []
                for entry in payload["r"]:
                    if type(entry) is int:
                        if not 0 <= entry < len(original): raise ValueError("Delta base row out of range")
                        rows.append(original[entry])
                    elif isinstance(entry, list) and entry and entry[0] == -1:
                        rows.append(entry[1:])
                    elif isinstance(entry, list) and len(entry) % 2 == 1 and type(entry[0]) is int and 0 <= entry[0] < len(original):
                        row = list(original[entry[0]])
                        seen = set()
                        for index, value in zip(entry[1::2], entry[2::2]):
                            if type(index) is not int or not 0 <= index < len(row) or index in seen:
                                raise ValueError("Invalid delta column")
                            seen.add(index); row[index] = value
                        rows.append(row)
                    else: raise ValueError("Invalid delta row")
                payload = {"c": columns, "r": rows}
            if not all(isinstance(row, list) and len(row) == len(columns) for row in payload["r"]):
                raise ValueError("Snapshot row width differs from columns")
            tables[table] = payload
    if set(tables) != set(manifest["schema"]):
        raise ValueError("Snapshot tables differ from schema")
    if len(tables["cards"]["r"]) != manifest["count"]:
        raise ValueError("Snapshot character count differs")
    return manifest, tables


def create_database(path, manifest, tables):
    if path.exists():
        raise FileExistsError("Use a fresh cloud-only output directory; existing DB is preserved")
    con = sqlite3.connect(path)
    try:
        with con:
            sequence = tables.get("sqlite_sequence")
            autoincrement = {row[0] for row in sequence["r"]} if sequence else set()
            for table, payload in tables.items():
                if table == "sqlite_sequence": continue # SQLite creates its own reserved table below.
                if not IDENT.fullmatch(table): raise ValueError("Invalid table name")
                schema = manifest["schema"][table]
                if [column["name"] for column in schema] != payload["c"]:
                    raise ValueError("Schema columns differ")
                definitions = []
                primary = []
                for column in schema:
                    name, kind = column["name"], column["type"]
                    if not IDENT.fullmatch(name) or not re.fullmatch(r"[A-Za-z0-9_ (),]*", kind):
                        raise ValueError("Unsupported column declaration")
                    decl = '"' + name + '" ' + kind
                    if column["notnull"]: decl += " NOT NULL"
                    default = column["dflt_value"]
                    if default is not None:
                        # SQLite accepts one CREATE statement only; PRAGMA default text stays inside parentheses.
                        if not isinstance(default, str) or ";" in default or "--" in default or "/*" in default:
                            raise ValueError("Unsupported default expression")
                        decl += " DEFAULT (" + default + ")"
                    definitions.append(decl)
                    if column["pk"]:
                        if table in autoincrement:
                            if kind.upper() != "INTEGER" or column["pk"] != 1 or sum(bool(c["pk"]) for c in schema) != 1:
                                raise ValueError("Unsupported AUTOINCREMENT declaration")
                            definitions[-1] += " PRIMARY KEY AUTOINCREMENT"
                        else: primary.append((column["pk"], name))
                if primary:
                    definitions.append("PRIMARY KEY (" + ",".join('"' + name + '"' for _, name in sorted(primary)) + ")")
                con.execute('CREATE TABLE "' + table + '" (' + ",".join(definitions) + ")")
                con.executemany('INSERT INTO "' + table + '" VALUES (' + ",".join("?" for _ in schema) + ")", payload["r"])
            if sequence:
                if not autoincrement:
                    # Empty sqlite_sequence still needs to exist; this temporary owned table creates it.
                    con.execute('CREATE TABLE cloud_sequence_init(id INTEGER PRIMARY KEY AUTOINCREMENT)')
                    con.execute('DROP TABLE cloud_sequence_init')
                con.execute('DELETE FROM sqlite_sequence')
                con.executemany('INSERT INTO sqlite_sequence(name,seq) VALUES (?,?)', sequence["r"])
            if con.execute("PRAGMA integrity_check").fetchone() != ("ok",):
                raise ValueError("Reconstructed database integrity failure")
        counts = {table: con.execute('SELECT count(*) FROM "' + table + '"').fetchone()[0] for table in tables}
        if any(counts[t] != len(tables[t]["r"]) for t in tables):
            raise ValueError("Reconstructed row count differs")
        return {"tables": len(tables), "rows": counts, "cards": counts["cards"],
                "original_snapshot_id": manifest.get("snapshotId"),
                "reconstructed_sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    finally:
        con.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--html", type=pathlib.Path, default=ROOT / "test-page/UnitCreator-test.html")
    parser.add_argument("--output", type=pathlib.Path, required=True)
    parser.add_argument("--report", type=pathlib.Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    files = embedded_files(args.html)
    eclipse_meta, eclipse = snapshot(files, "data/db/")
    sparking_meta, sparking = snapshot(files, "data/sparking-db/", eclipse)
    report = {"source_html_sha256": hashlib.sha256(args.html.read_bytes()).hexdigest(),
              "source": "Committed browser table snapshots, reconstructed for hosted native UI checks only",
              "limitations": ["Not byte-identical to original SQLite files", "Indexes, triggers, views and foreign-key declarations absent from browser snapshot", "Original BLOB values were UTF-8 decoded by web/build.py; binary fidelity is not recoverable", "Not an installable release database or encryption/import/export validation"],
              "eclipse": create_database(args.output / "reference.db", eclipse_meta, eclipse),
              "sparking": create_database(args.output / "sparking-reference.db", sparking_meta, sparking)}
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n")
    print("Reconstructed actual bundled table rows for cloud native SQL/UI checks; originals were not restored.")


if __name__ == "__main__":
    main()
