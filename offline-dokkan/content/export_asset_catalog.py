#!/usr/bin/env python3
"""Index an imported game-file manifest for the shared native content resolver."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import sqlite3


def canonical(path):
    if (not isinstance(path, str) or not path or len(path.encode()) > 1024 or
            path.startswith('/') or '\\' in path or '\0' in path or
            any(part in ('', '.', '..') for part in path.split('/')) or
            str(PurePosixPath(path)) != path):
        raise ValueError('Invalid manifest path')
    return path


def build_catalog(manifest, destination, package, version):
    if not re.fullmatch(r'[A-Za-z0-9_.]+', package) or not re.fullmatch(r'[0-9.]+', version):
        raise ValueError('Invalid source identity')
    manifest, destination = Path(manifest), Path(destination)
    if (manifest.stat().st_size > 32 * 1024 * 1024 or destination.is_symlink() or
            manifest.resolve() == destination.resolve()):
        raise ValueError('Invalid catalog input/output')
    raw = manifest.read_bytes()
    entries = json.loads(raw)
    if not isinstance(entries, list) or len(entries) > 200000:
        raise ValueError('Invalid manifest entries')
    prefix = 'user/0/' + package + '/files/'
    selected, seen, private = [], set(), 0
    for row in entries:
        if not isinstance(row, dict):
            raise ValueError('Invalid manifest record')
        original = canonical(row.get('path'))
        if original in seen:
            raise ValueError('Duplicate source path')
        seen.add(original)
        if not original.startswith(prefix + 'assets/'):
            continue
        path = original[len(prefix):]
        # This tree contains player settings/patcher state, not a game master.
        if path == 'assets/User' or path.startswith('assets/User/'):
            private += 1
            continue
        size, digest = row.get('size'), row.get('sha256')
        if type(size) is not int or not 0 <= size <= 8 * 1024**3 or not isinstance(digest, str) or not re.fullmatch('[0-9a-f]{64}', digest):
            raise ValueError('Invalid asset size/hash')
        selected.append((path, size, digest, PurePosixPath(path).suffix.lower()))
    if not selected:
        raise ValueError('No asset references found')
    temporary = destination.with_name(destination.name + '.partial')
    if temporary.exists() or temporary.is_symlink():
        raise ValueError('A staged catalog already exists')
    destination.parent.mkdir(parents=True, exist_ok=True)
    connection = None
    try:
        connection = sqlite3.connect(temporary)
        connection.executescript('CREATE TABLE metadata(key TEXT PRIMARY KEY,value TEXT NOT NULL);'
                                 'CREATE TABLE assets(path TEXT PRIMARY KEY,bytes INTEGER NOT NULL,sha256 TEXT NOT NULL,extension TEXT NOT NULL);')
        metadata = {'schema': '1', 'manifest_sha256': hashlib.sha256(raw).hexdigest(),
                    'source_package': package, 'source_version': version,
                    'asset_bytes_verified': 'false', 'ios_compatibility_verified': 'false',
                    'private_user_records_excluded': str(private)}
        with connection:
            connection.executemany('INSERT INTO metadata VALUES(?,?)', metadata.items())
            connection.executemany('INSERT INTO assets VALUES(?,?,?,?)', selected)
        connection.close()
        connection = None
        os.chmod(temporary, 0o400)
        temporary.replace(destination)
    except BaseException:
        if connection is not None:
            connection.close()
        if temporary.exists():
            temporary.unlink()
        raise
    return {'assets': len(selected), 'bytes': sum(row[1] for row in selected),
            'private_user_records_excluded': private, 'manifest_sha256': metadata['manifest_sha256']}


def lookup_ref(catalog, path, manifest_sha256):
    path = canonical(path)
    with sqlite3.connect(Path(catalog).resolve().as_uri() + '?mode=ro', uri=True) as db:
        metadata = dict(db.execute('SELECT key,value FROM metadata'))
        if metadata.get('schema') != '1' or metadata.get('manifest_sha256') != manifest_sha256:
            raise ValueError('The selected source catalog changed')
        row = db.execute('SELECT path,bytes,sha256 FROM assets WHERE path=?', (path,)).fetchone()
        if row is None:
            raise ValueError('Asset is not in the selected game-content manifest')
        # Same field semantics as od_content_ref. Actual bytes must still pass
        # od_content_resolve; index presence never claims an asset is ready.
        return {'path': row[0], 'bytes': row[1], 'sha256': row[2]}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest', type=Path)
    p.add_argument('destination', type=Path)
    p.add_argument('--package', required=True)
    p.add_argument('--version', required=True)
    args = p.parse_args()
    try:
        print(json.dumps(build_catalog(args.manifest, args.destination, args.package, args.version)))
    except (ValueError, OSError, sqlite3.Error):
        raise SystemExit('Catalog import failed. Original data and existing catalog were preserved.')


if __name__ == '__main__':
    main()
