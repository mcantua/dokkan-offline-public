#!/usr/bin/env python3
"""Extract value-free resource-response schema from a user-provided TAR in memory.

Never extracts a raw member, imports player state, contacts game/account servers,
or emits private paths/scalar payloads. This is schema evidence, not app content.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import tarfile

TOOLS = Path(__file__).resolve().parents[2] / 'tools'
sys.path.insert(0, str(TOOLS))
import collect_protocol_evidence as evidence

MAX_TAR = 32 * 1024 * 1024
MAX_JSON = 8 * 1024 * 1024
NAME = 'resources_login_response.json'
KNOWN_ANDROID_EXPORT_SHA256 = 'bd46997a0fcae532138baf1fd2b4456f7dc8ed7cf290449072337defed2bb32f'


def extract(source, expected_archive_hash):
    if not 1 <= source.stat().st_size <= MAX_TAR:
        raise ValueError('Archive outside bounds')
    h = hashlib.sha256()
    with source.open('rb') as stream:
        for b in iter(lambda: stream.read(1024 * 1024), b''):h.update(b)
    if h.hexdigest() != expected_archive_hash:
        raise ValueError('Archive identity changed')
    with tarfile.open(source, 'r:*') as archive:
        selected, count = [], 0
        for member in archive:
            count += 1
            if count > 20000:raise ValueError('Too many headers')
            if member.name.replace('\\', '/').rsplit('/', 1)[-1] == NAME:
                if not member.isfile() or not 1 <= member.size <= MAX_JSON:
                    raise ValueError('Invalid bounded cache member')
                selected.append(member)
        if len(selected) != 1:raise ValueError('Expected one named response cache')
        member = selected[0]
        with archive.extractfile(member) as stream:raw = stream.read(MAX_JSON + 1)
        if len(raw) != member.size:raise ValueError('Changed/truncated member')
        value = json.loads(raw)
        if not isinstance(value, dict):raise ValueError('Expected response object')
        vocabulary = json.loads(Path(__file__).with_name('cache_field_vocabulary.json').read_text())
        fields = [x['field'] for x in vocabulary['fields']]
        if len(fields) != len(set(fields)):raise ValueError('Ambiguous reviewed vocabulary')
        original = evidence.PROTOCOL_FIELDS
        try:
            evidence.PROTOCOL_FIELDS = original | frozenset(fields)
            schema = evidence.structure(value)
        finally:
            evidence.PROTOCOL_FIELDS = original
        return {'kind': 'own-export-cached-resource-response-schema-only',
            'source_archive_sha256': h.hexdigest(), 'member_sha256': hashlib.sha256(raw).hexdigest(),
            'member_bytes': len(raw), 'member_path_sha256': hashlib.sha256(member.name.encode()).hexdigest(),
            'known_fixed_cache_basename': NAME, 'route_filename_binding': '/resources/login',
            'http_method_verified': False,
            'source_platform': ('Android export6.6.0/code351' if h.hexdigest() == KNOWN_ANDROID_EXPORT_SHA256
                                else 'unverified caller-selected archive'),
            'cache_client_version_independently_recorded': False,
            'iphone_runtime_compatibility_verified': False,
            'observed_fields_are_required': False, 'unknown_names_remain_redacted': True,
            'all_scalar_values_removed': True, 'player_state_adopted': False,
            'vocabulary_sha256': hashlib.sha256(Path(__file__).with_name('cache_field_vocabulary.json').read_bytes()).hexdigest(),
            'structure': schema}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('input', type=Path)
    p.add_argument('--archive-sha256', required=True)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()
    try:
        if args.input.resolve() == args.out.resolve():raise ValueError('Input preserved')
        result = extract(args.input, args.archive_sha256)
        args.out.parent.mkdir(parents=True, exist_ok=True)
        with args.out.open('x') as stream:stream.write(json.dumps(result, indent=2) + '\n')
    except (OSError, ValueError, UnicodeError, tarfile.TarError):
        raise SystemExit('Schema-only cache extraction failed; originals and prior output preserved.')
    print('Reviewed schema written; no raw payload/player values extracted or adopted.')


if __name__ == '__main__':
    main()
