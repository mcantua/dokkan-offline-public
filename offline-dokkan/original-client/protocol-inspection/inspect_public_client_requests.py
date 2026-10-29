#!/usr/bin/env python3
"""Value-free historical request evidence from a pinned licensed client source.

Parses Python AST only. Never imports/executes source, contacts game servers,
copies credentials, or promotes historical request shapes to current contracts.
"""
import argparse
import ast
import hashlib
import json
from pathlib import Path
import re

SOURCE_SHA256 = '1fd1821782f50c35bb0471369d35e928aefd7bd78f44ed8af557b1983cf67404'
FIELDS = frozenset(('selected_team_num', 'friend_id', 'cpu_friend_id',
    'is_playing_script', 'difficulty', 'eventkagi_item_id', 'sign', 'token',
    'steps', 'actual_steps', 'is_cleared', 'elapsed_time', 'quest_finished_at_ms',
    'quest_started_at_ms', 'has_player_been_taken_damage', 'is_defeated_boss',
    'is_player_special_attack_only', 'min_turn_in_boss_battle', 'max_damage_to_boss',
    'energy_ball_counts_in_boss_battle', 'is_cheat_user'))
RESPONSE_FIELDS = frozenset(('amount', 'card_id', 'cards', 'code', 'error', 'events',
    'gasha_point', 'id', 'is_cpu', 'item_id', 'item_type', 'items', 'quantity',
    'quest_clear_rewards', 'rank', 'sign', 'stone', 'sugoroku', 'token', 'user',
    'user_items', 'zeni'))


def type_only(node):
    if isinstance(node, ast.Constant):
        value = node.value
        if value is None:return 'null'
        if type(value) is bool:return 'boolean'
        if type(value) is int:return 'integer'
        if type(value) is float:return 'number'
        if type(value) is str:return 'string'
    if isinstance(node, (ast.List, ast.Tuple)):return 'array'
    if isinstance(node, ast.Dict):return 'object'
    return 'unresolved_expression'


def inspect(path):
    if not 1 <= path.stat().st_size <= 512 * 1024:
        raise ValueError('Source size invalid')
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != SOURCE_SHA256:
        raise ValueError('Source changed; provenance and allowlists require review')
    tree = ast.parse(raw)
    functions = [x for x in tree.body if isinstance(x, ast.FunctionDef) and x.name == 'complete_stage']
    if len(functions) != 1:
        raise ValueError('Expected one reviewed historical function')
    function = functions[0]
    dictionaries, reads = [], set()
    for node in ast.walk(function):
        if isinstance(node, ast.Dict):
            fields = []
            for key, value in zip(node.keys, node.values):
                if isinstance(key, ast.Constant) and key.value in FIELDS:
                    fields.append({'field': key.value, 'literal_source_type': type_only(value)})
            if fields:
                dictionaries.append({'source_line': node.lineno, 'fields': fields,
                    'required_at_runtime': 'not_established', 'conditional_variants_possible': True})
        if (isinstance(node, ast.Subscript) and isinstance(node.slice, ast.Constant)
                and node.slice.value in RESPONSE_FIELDS):
            reads.add(node.slice.value)
    return {'kind': 'historical-public-client-interface-evidence',
        'repository': 'https://github.com/pawelorzech/dokkan-battle-bot',
        'upstream_path': 'commands.py', 'source_sha256': SOURCE_SHA256,
        'upstream_license': 'LGPL-3.0', 'function': 'complete_stage',
        'request_dictionary_literals': sorted(dictionaries, key=lambda x: x['source_line']),
        'indexed_field_names': sorted(reads),
        'limits': 'Indexed fields may refer to local/intermediate objects. Dictionaries are historical client construction, not server implementations or complete response schemas. Unknown expressions are not inferred. No scalar sample values retained.',
        'source_executed': False, 'game_api_contacted': False,
        'selected_6_6_client_contract_verified': False, 'transport_admission_granted': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.input.resolve() == args.out.resolve():raise ValueError('Input preserved')
        result = inspect(args.input)
        args.out.parent.mkdir(parents=True, exist_ok=True)
        with args.out.open('x') as stream:stream.write(json.dumps(result, indent=2) + '\n')
    except (OSError, ValueError, SyntaxError, UnicodeError):
        raise SystemExit('Historical source inspection failed; source and prior output preserved.')
    print('Historical value-free request evidence written; current-client admission remains closed.')


if __name__ == '__main__':
    main()
