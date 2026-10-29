#!/usr/bin/env python3
"""Inspect only source-master structure relevant to a fresh offline account.

Output contains schema names, counts, hashes and admission booleans, never row
values. A table that describes tutorial content is not a user tutorial state.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sqlite3
import stat

SOURCE_SHA256 = '1a8f5a823a6efa7343ff463b92197a574898e03569e2067f3daf8a4f282be4f4'
SOURCE_BYTES = 114827264
REQUIRED = {
    'rank_statuses': ('id', 'rank', 'exp_total', 'act_max', 'friends_capacity'),
    'tutorial_phases': ('id', 'tutorial_scene_url', 'parameters', 'number'),
    'tutorial_steps': ('id', 'phase_id', 'is_resume_point', 'number'),
    'tutorial_processes': ('id', 'step_id', 'process_type', 'parameters', 'number'),
    'client_settings': ('id', 'key', 'value'),
}
UNRESOLVED = (
    'tutorial.progress', 'tutorial.contents_lv', 'tutorial.is_finished',
    'card_capacity', 'total_card_capacity', 'support_item_capacity',
    'is_support_item_capacity_extended',
)
SHOP_KEYS = frozenset(('shop_expand_card_capacity_max',
                      'shop_expand_card_capacity_use_stone'))


def quote(name):
    if not isinstance(name, str) or not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', name):
        raise ValueError('Unsupported schema identifier')
    return '"' + name + '"'


def pinned_identity(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    try:
        before = os.fstat(fd)
        if not stat.S_ISREG(before.st_mode) or before.st_size != SOURCE_BYTES:
            raise ValueError('Unexpected source identity')
        with os.fdopen(os.dup(fd), 'rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        after = os.fstat(fd)
        identity = lambda x: (x.st_dev, x.st_ino, x.st_size, x.st_mtime_ns)
        if identity(before) != identity(after) or digest != SOURCE_SHA256:
            raise ValueError('Source hash or identity changed')
        return identity(after)
    finally:
        os.close(fd)


def inspect(path):
    path = Path(path).absolute()
    identity = pinned_identity(path)
    db = sqlite3.connect(path.as_uri() + '?mode=ro&immutable=1', uri=True)
    try:
        db.execute('PRAGMA query_only=ON')
        db.execute('PRAGMA trusted_schema=OFF')
        schemas = {}
        counts = {}
        for table, needed in REQUIRED.items():
            columns = [row[1] for row in db.execute('PRAGMA table_info(' + quote(table) + ')')]
            if not set(needed).issubset(columns):
                raise ValueError('Required source schema is unavailable')
            schemas[table] = columns
            counts[table] = db.execute('SELECT count(*) FROM ' + quote(table)).fetchone()[0]
        ranks = list(db.execute('SELECT rank,exp_total,act_max,friends_capacity '
                               'FROM rank_statuses WHERE rank=1 LIMIT 2'))
        valid_rank = len(ranks) == 1 and all(type(x) is int for x in ranks[0])
        rank_admitted = valid_rank and ranks[0][0] == 1 and ranks[0][1] == 0 and ranks[0][2] > 0 and ranks[0][3] >= 0
        if not rank_admitted:
            raise ValueError('Fresh rank source cannot be admitted')
        orphan_steps = db.execute('SELECT count(*) FROM tutorial_steps s LEFT JOIN '
                                  'tutorial_phases p ON p.id=s.phase_id WHERE p.id IS NULL').fetchone()[0]
        orphan_processes = db.execute('SELECT count(*) FROM tutorial_processes p LEFT JOIN '
                                      'tutorial_steps s ON s.id=p.step_id WHERE s.id IS NULL').fetchone()[0]
        phase_duplicates = db.execute('SELECT count(*) FROM (SELECT number FROM tutorial_phases '
                                     'GROUP BY number HAVING count(*)>1)').fetchone()[0]
        step_duplicates = db.execute('SELECT count(*) FROM (SELECT phase_id,number FROM tutorial_steps '
                                    'GROUP BY phase_id,number HAVING count(*)>1)').fetchone()[0]
        process_duplicates = db.execute('SELECT count(*) FROM (SELECT step_id,number FROM tutorial_processes '
                                       'GROUP BY step_id,number HAVING count(*)>1)').fetchone()[0]
        zero_phases = db.execute('SELECT count(*) FROM tutorial_phases WHERE number=0').fetchone()[0]
        field_names = {name.rsplit('.', 1)[-1] for name in UNRESOLVED}
        field_matches = []
        tables = [row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table'")]
        for table in tables:
            for column in db.execute('PRAGMA table_info(' + quote(table) + ')'):
                if column[1] in field_names:
                    field_matches.append({'table': table, 'column': column[1]})
        settings = [row[0] for row in db.execute('SELECT key FROM client_settings')]
        relevant = [key for key in settings if isinstance(key, str) and
                    re.search(r'tutorial|capacity|initial|first|beginner|default', key, re.I)]
        admitted_shop_keys = sorted(key for key in relevant if key in SHOP_KEYS)
        return {
            'kind': 'actual-current-fresh-master-structural-contract',
            'source_sha256': SOURCE_SHA256,
            'source_bytes': SOURCE_BYTES,
            'source_rows_exported': False,
            'schemas': schemas,
            'row_counts': counts,
            'source_rank': {
                'fresh_rank_row_unique': len(ranks) == 1,
                'rank_experience_zero': ranks[0][1] == 0,
                'act_max_positive': ranks[0][2] > 0,
                'friends_capacity_nonnegative': ranks[0][3] >= 0,
                'native_snapshot_fields': ['rank', 'exp_total', 'act_max', 'friends_capacity'],
                'new_fields_beyond_existing_core_projection': [],
                'values_exported': False,
            },
            'tutorial_definition_topology': {
                'orphan_steps': orphan_steps,
                'orphan_processes': orphan_processes,
                'duplicate_phase_numbers': phase_duplicates,
                'duplicate_step_numbers_per_phase': step_duplicates,
                'duplicate_process_numbers_per_step': process_duplicates,
                'zero_numbered_phase_count': zero_phases,
                'definition_to_user_progress_mapping_verified': False,
                'definition_to_contents_lv_mapping_verified': False,
                'first_server_tutorial_state_verified': False,
            },
            'starting_policy_evidence': {
                'unresolved_user_fields': list(UNRESOLVED),
                'matching_master_columns': field_matches,
                'relevant_client_setting_key_count': len(relevant),
                'shop_expansion_keys': admitted_shop_keys,
                'unreviewed_relevant_setting_key_count': len(relevant) - len(admitted_shop_keys),
                'shop_expansion_values_exported': False,
                'shop_expansion_setting_is_starting_capacity': False,
                'tutorial_initial_policy_admitted': False,
                'capacity_initial_policy_admitted': False,
            },
            'source_identity_unchanged': True,
            'played_account_cache_read': False,
            'credentials_or_keys_read': False,
            'runtime_execution_verified': False,
            'http_route_admitted': False,
            'limitation': 'Master rank facts are already used by Core. Tutorial definitions '
                          'and shop expansion settings do not establish a new user tutorial '
                          'state or starting capacities. Keep the existing policy gates.',
        }
    finally:
        db.close()
        current = path.stat(follow_symlinks=False)
        if (current.st_dev, current.st_ino, current.st_size, current.st_mtime_ns) != identity:
            raise ValueError('Source identity changed during inspection')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('master', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if args.output.suffix != '.json' or args.output.absolute() == args.master.absolute():
        raise SystemExit('A separate JSON evidence file is required')
    try:
        report = inspect(args.master)
        args.output.write_text(json.dumps(report, indent=2) + '\n')
    except (ValueError, OSError, sqlite3.Error, TypeError):
        raise SystemExit('Fresh-master inspection failed; source preserved, no state admitted.')
    print('Fresh-master structure inspected; no row values exported or new startup policy admitted.')


if __name__ == '__main__':
    main()
