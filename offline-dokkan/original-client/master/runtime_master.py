"""Insert-only per-save derived master built with the existing Creator Forge.

Trusted host input must be an immutable accepted project, not an editable draft.
This cloud compiler does not install a game DB hook or admit a resource response.
"""
import hashlib
import fcntl
import json
import math
import os
from pathlib import Path
import re
import sqlite3
import stat
import subprocess
import tempfile

from master_contract import MasterContract, fail
from overlay_store import REFERENCES, canonical, key

FLOOR, CEILING = 97000001, 98999001
HASH = re.compile(r'[0-9a-f]{64}\Z')
NAME = re.compile(r'[A-Za-z_][A-Za-z0-9_]*\Z')
WORKER = Path(__file__).with_name('runtime_forge.js')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def quote(name):
    if not isinstance(name, str) or not NAME.fullmatch(name):
        fail('RUNTIME_IDENTIFIER_INVALID')
    return '"' + name + '"'


def parsed(data, expected):
    if not isinstance(data, bytes) or len(data) > 20 * 1024 * 1024 or digest(data) != expected:
        fail('RUNTIME_IMMUTABLE_DOCUMENT_MISMATCH')
    def unique(pairs):
        out = {}
        for k, v in pairs:
            if k in out:
                fail('RUNTIME_DUPLICATE_JSON_KEY')
            out[k] = v
        return out
    return json.loads(data, object_pairs_hook=unique,
                      parse_constant=lambda _: fail('RUNTIME_NONFINITE_JSON'))


def compile_forge(project, ids, reservations, floor):
    try:
        result = subprocess.run(['node', str(WORKER)], input=canonical({
            'project': project, 'runtimeIds': ids, 'reservations': reservations,
            'floor': floor}), text=True, capture_output=True, timeout=30, check=False)
    except (OSError, subprocess.TimeoutExpired):
        fail('RUNTIME_FORGE_UNAVAILABLE')
    if result.returncode or len(result.stdout) > 32 * 1024 * 1024:
        fail('RUNTIME_FORGE_REJECTED')
    return json.loads(result.stdout)


class RuntimeMaster:
    """Private cold-attach artifact; never opens or changes the canonical save.

    Source is independently hash-pinned by an active MasterContract. Scope must
    come from the trusted native projection, not from a WebView request. Each
    definition/version receives a fresh existing-Forge private block; old rows
    remain for pinned runs. This is compilation evidence, not engine execution.
    """
    def __init__(self, path, master, scope):
        self.path, self.master, self.scope = Path(path).absolute(), master, scope
        if (not isinstance(master, MasterContract) or master.db is None or
                not isinstance(scope, str) or not HASH.fullmatch(scope)):
            fail('RUNTIME_HOST_CONTEXT_INVALID')
        if self.path == master.path or any(p.is_symlink() for p in [self.path, *self.path.parents]):
            fail('RUNTIME_PATH_UNSAFE')
        self.path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)

    def _blueprint(self, project, definition):
        self.master.validate_settings(definition)
        if (not isinstance(project, dict) or project.get('format') != 'dokkan-unit-forge' or
                project.get('version') != 1 or project.get('awaken') or project.get('formProjects') or
                project.get('formLinks') or project.get('source', {}).get('cardId') != definition['source']['master_id']):
            fail('RUNTIME_ACCEPTED_BUNDLE_REQUIRED')
        card = dict(project.get('tables', {}).get('cards', [{}])[0])
        card.update(project.get('cardOverrides', {}))
        if card != definition['card']:
            fail('RUNTIME_DEFINITION_PROJECT_MISMATCH')
        for table, rows in definition['tables'].items():
            if project.get('tables', {}).get(table) != rows:
                fail('RUNTIME_DEFINITION_PROJECT_MISMATCH')
        # Omitted source dependencies must be unchanged actual source records.
        # New/modified content cannot hide outside the strict accepted definition.
        for table, rows in project.get('tables', {}).items():
            if table == 'cards' or table in definition['tables']:
                continue
            cols = self.master.db.execute('PRAGMA table_info(' + quote(table) + ')').fetchall()
            names = [r[1] for r in cols]
            if not names or not isinstance(rows, list):
                fail('RUNTIME_UNADMITTED_TABLE')
            for row in rows:
                if not isinstance(row, dict) or set(row) != set(names):
                    fail('RUNTIME_UNADMITTED_ROW')
                actual = self.master.db.execute('SELECT * FROM ' + quote(table) + ' WHERE id=?', (row.get('id'),)).fetchone()
                if actual is None or dict(zip(names, actual)) != row:
                    fail('RUNTIME_UNADMITTED_ROW')

    def _metadata(self, db):
        db.execute('CREATE TABLE od_runtime_meta(key TEXT PRIMARY KEY,value TEXT NOT NULL) STRICT')
        db.execute('CREATE TABLE od_runtime_versions(definition_id TEXT NOT NULL,version INTEGER NOT NULL,project_sha256 TEXT NOT NULL,definition_sha256 TEXT NOT NULL,runtime_id INTEGER NOT NULL UNIQUE,project BLOB NOT NULL,definition BLOB NOT NULL,accepted_binding TEXT NOT NULL CHECK(json_valid(accepted_binding)),receipt TEXT NOT NULL,PRIMARY KEY(definition_id,version)) STRICT')
        db.execute('CREATE TABLE od_runtime_rows(table_name TEXT NOT NULL,row_id INTEGER NOT NULL,definition_id TEXT NOT NULL,version INTEGER NOT NULL,PRIMARY KEY(table_name,row_id)) STRICT')
        db.executemany('INSERT INTO od_runtime_meta VALUES(?,?)', [
            ('format', 'od-derived-original-master-v1'), ('scope', self.scope),
            ('content_id', self.master.content_id), ('source_sha256', self.master.expected)])

    def _check_meta(self, db):
        actual = dict(db.execute('SELECT key,value FROM od_runtime_meta'))
        if actual != {'format': 'od-derived-original-master-v1', 'scope': self.scope,
                      'content_id': self.master.content_id, 'source_sha256': self.master.expected}:
            fail('RUNTIME_IDENTITY_MISMATCH')

    def _rows(self, db, result):
        tables = result['tables']; total = 0
        for table, rows in tables.items():
            cols = {r[1]: r for r in db.execute('PRAGMA table_info(' + quote(table) + ')')}
            if not cols or not isinstance(rows, list):
                fail('RUNTIME_SCHEMA_MISMATCH')
            seen = set()
            for row in rows:
                total += 1
                if total > 50000 or not isinstance(row, dict) or set(row) != set(cols):
                    fail('RUNTIME_ROW_SCHEMA_MISMATCH')
                rid = row.get('id')
                if type(rid) is not int or rid < 1 or rid > 2**53-1 or rid in seen:
                    fail('RUNTIME_ROW_ID_INVALID')
                seen.add(rid)
                if db.execute('SELECT 1 FROM '+quote(table)+' WHERE id=?', (rid,)).fetchone():
                    return False
                for name, value in row.items():
                    spec = cols[name]
                    if value is None:
                        if spec[3] or spec[5]: fail('RUNTIME_NULL_INVALID')
                    elif type(value) not in (str, int, float) or isinstance(value, float) and not math.isfinite(value):
                        fail('RUNTIME_VALUE_INVALID')
                    elif isinstance(value, str) and ('\0' in value or len(value.encode()) > 1024*1024):
                        fail('RUNTIME_VALUE_INVALID')
                    elif 'INT' in spec[2].upper() and (type(value) is not int or abs(value)>2**53-1):
                        fail('RUNTIME_INTEGER_INVALID')
        return True

    def _references(self, db, result):
        tables = result['tables']; refs = {**result['foreign'], **REFERENCES}
        for table, rows in tables.items():
            for row in rows:
                for field, value in row.items():
                    target = refs.get(field)
                    if target and value not in (None, 0):
                        if type(value) is not int or not db.execute('SELECT 1 FROM '+quote(target)+' WHERE id=?', (value,)).fetchone():
                            fail('RUNTIME_REFERENCE_MISSING')
        if db.execute('PRAGMA foreign_key_check').fetchone():
            fail('RUNTIME_FOREIGN_KEY_FAILED')

    def _accepted(self, binding, definition, project_sha256, definition_sha256):
        expected = {'format', 'content_id', 'save_scope', 'definition_id', 'version',
                    'project_sha256', 'definition_sha256', 'instance_id', 'accepted'}
        if (not isinstance(binding, dict) or set(binding) != expected or
                binding['format'] != 'od-accepted-creator-project-v1' or
                binding['accepted'] is not True or type(binding['instance_id']) is not int or
                binding['instance_id'] < 1 or binding['instance_id'] > 2**53-1 or
                binding['content_id'] != self.master.content_id or binding['save_scope'] != self.scope or
                binding['definition_id'] != definition.get('definition_id') or
                type(binding['version']) is not int or binding['version'] != definition.get('version') or
                binding['project_sha256'] != project_sha256 or
                binding['definition_sha256'] != definition_sha256):
            fail('RUNTIME_ACCEPTED_RECEIPT_MISMATCH')

    def compile(self, accepted_binding, project_bytes, project_sha256, definition_bytes, definition_sha256):
        """Native accepted packet only; never a draft/client-supplied receipt.

        Call from Session's native-only immutable accepted-version export. The
        receipt's shape is checked here; native authority is the caller's duty.
        """
        project, definition = parsed(project_bytes, project_sha256), parsed(definition_bytes, definition_sha256)
        self._accepted(accepted_binding, definition, project_sha256, definition_sha256)
        self._blueprint(project, definition)
        pair = (key(definition['definition_id']), definition['version'])
        lock = self.path.with_suffix(self.path.suffix+'.lock')
        fd = os.open(lock, os.O_CREAT | os.O_WRONLY | os.O_NOFOLLOW, 0o600)
        try:
            info = os.fstat(fd)
            if not stat.S_ISREG(info.st_mode) or info.st_mode & 0o077:
                fail('RUNTIME_LOCK_UNSAFE')
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BaseException:
            os.close(fd)
            raise
        temp = None; db = None
        try:
            existing = self.path.exists()
            before = self.path.stat(follow_symlinks=False) if existing else None
            if before and (not stat.S_ISREG(before.st_mode) or before.st_mode & 0o077):
                fail('RUNTIME_PATH_UNSAFE')
            handle, raw = tempfile.mkstemp(prefix='.runtime-', suffix='.db', dir=self.path.parent)
            os.close(handle); temp = Path(raw)
            db = sqlite3.connect(temp, isolation_level=None)
            source = sqlite3.connect(self.path.as_uri()+'?mode=ro&immutable=1', uri=True) if existing else self.master.db
            try: source.backup(db)
            finally:
                if existing: source.close()
            db.execute('PRAGMA synchronous=FULL');db.execute('PRAGMA foreign_keys=ON')
            db.execute('BEGIN IMMEDIATE')
            if existing: self._check_meta(db)
            else: self._metadata(db)
            prior = db.execute('SELECT project_sha256,definition_sha256,accepted_binding,receipt FROM od_runtime_versions WHERE definition_id=? AND version=?', pair).fetchone()
            if prior:
                if prior[:2] != (project_sha256,definition_sha256) or json.loads(prior[2]) != accepted_binding: fail('RUNTIME_VERSION_CONFLICT')
                return json.loads(prior[3])
            reservations = [{'key': str(i), 'targetId': r[0]} for i,r in enumerate(db.execute('SELECT runtime_id FROM od_runtime_versions'))]
            floor = FLOOR
            while floor <= CEILING:
                # Existing approved allocator computes the actual candidate.
                probe = compile_forge(project, [floor], reservations, floor)
                candidate = probe['next']
                result = probe if candidate == floor else compile_forge(project, [candidate], reservations, candidate)
                if self._rows(db, result): break
                floor = candidate+1000
            else: fail('RUNTIME_PRIVATE_BLOCKS_FULL')
            runtime_id = result['runtimeIds'][0]
            for table, rows in result['tables'].items():
                for row in rows:
                    db.execute('INSERT INTO '+quote(table)+' ('+','.join(map(quote,row))+') VALUES ('+','.join('?' for _ in row)+')', tuple(row.values()))
                    db.execute('INSERT INTO od_runtime_rows VALUES(?,?,?,?)', (table,row['id'],*pair))
            self._references(db,result)
            receipt = {'definition_id':pair[0], 'version':pair[1], 'runtime_card_id':runtime_id,
                       'project_sha256':project_sha256,'definition_sha256':definition_sha256,
                       'content_id':self.master.content_id,'save_scope':self.scope,
                       'accepted_instance_id':accepted_binding['instance_id'],
                       'original_client_attached':False,'resource_admission_complete':False}
            db.execute('INSERT INTO od_runtime_versions VALUES(?,?,?,?,?,?,?,?,?)', (*pair,project_sha256,definition_sha256,runtime_id,project_bytes,definition_bytes,canonical(accepted_binding),canonical(receipt)))
            db.execute('COMMIT');db.close();db=None
            self.master.verify_unchanged()
            if before and self.path.stat(follow_symlinks=False) != before: fail('RUNTIME_CONCURRENT_REPLACEMENT')
            if not before and self.path.exists(): fail('RUNTIME_CONCURRENT_REPLACEMENT')
            with temp.open('rb') as persisted: os.fsync(persisted.fileno())
            os.chmod(temp,0o400);os.replace(temp,self.path);temp=None
            dfd=os.open(self.path.parent,os.O_RDONLY|os.O_DIRECTORY)
            try:os.fsync(dfd)
            finally:os.close(dfd)
            return receipt
        finally:
            if db is not None: db.close()
            if temp is not None: temp.unlink(missing_ok=True)
            fcntl.flock(fd, fcntl.LOCK_UN)
            os.close(fd)
