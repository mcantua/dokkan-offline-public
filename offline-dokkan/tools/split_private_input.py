#!/usr/bin/env python3
"""Cloud-only, bounded transfer parts for an unchanged private input file."""
from pathlib import Path
import hashlib
import json
import os
import plistlib
import re
import zipfile


def split_input(source, destination, source_id, expected_size, chunk_bytes=96 * 1024 * 1024):
    source, destination = Path(source), Path(destination)
    if (not source.is_file() or source.stat().st_size != expected_size or
            not 32768 <= chunk_bytes <= 96 * 1024 * 1024 or
            not re.fullmatch(r'[A-Za-z0-9_-]+', source_id) or
            destination.is_symlink() or source.resolve() == destination.resolve()):
        raise ValueError('Input, output or chunk size is invalid')
    identity = {'schema': 1, 'source_drive_id': source_id, 'source_name': source.name}
    destination.mkdir(parents=True, exist_ok=True)
    marker = destination / 'transfer-owner.json'
    if marker.exists():
        if marker.is_symlink() or json.loads(marker.read_text()) != identity:
            raise ValueError('The output folder belongs to a different transfer')
    elif any(destination.iterdir()):
        raise ValueError('Refusing an existing nonempty unowned folder')
    else:
        marker.write_text(json.dumps(identity, indent=2) + '\n')
    info = {}
    if source.suffix.lower() == '.ipa':
        with zipfile.ZipFile(source) as z:
            candidates = [x for x in z.infolist()
                          if re.fullmatch(r'Payload/[^/]+\.app/Info\.plist', x.filename)]
            if len(candidates) != 1 or candidates[0].file_size > 2 * 1024 * 1024:
                raise ValueError('Expected one bounded iPhone app Info.plist')
            p = plistlib.loads(z.read(candidates[0]))
            for key in ('CFBundleIdentifier', 'CFBundleShortVersionString',
                        'CFBundleVersion', 'MinimumOSVersion', 'CFBundleExecutable'):
                value = p.get(key)
                if isinstance(value, str) and re.fullmatch(r'[A-Za-z0-9_. -]{1,160}', value):
                    info[key] = value
            info['contains_iphone_app'] = 'iPhoneOS' in p.get('CFBundleSupportedPlatforms', [])
    before = source.stat()
    whole, parts, total = hashlib.sha256(), [], 0
    with source.open('rb') as stream:
        index = 1
        while True:
            data = stream.read(chunk_bytes)
            if not data:
                break
            name = 'iphone-client.part-%04d' % index
            output = destination / name
            expected = hashlib.sha256(data).hexdigest()
            if output.is_symlink():
                raise ValueError('A part is not a regular transfer file')
            existing_ok = output.is_file() and output.stat().st_size == len(data)
            if existing_ok:
                existing_ok = hashlib.sha256(output.read_bytes()).hexdigest() == expected
            if not existing_ok:
                partial = destination / (name + '.partial')
                if partial.exists() or partial.is_symlink():
                    raise ValueError('Remove only this transfer’s stale .partial file before retrying')
                with partial.open('xb') as out:
                    out.write(data)
                    out.flush()
                    os.fsync(out.fileno())
                partial.replace(output)
            if hashlib.sha256(output.read_bytes()).hexdigest() != expected:
                raise ValueError('Cloud part verification failed; source was preserved')
            whole.update(data)
            total += len(data)
            parts.append({'name': name, 'size': len(data), 'sha256': expected})
            print('Prepared part %d (%.1f MB)' % (index, len(data) / 1e6))
            index += 1
    after = source.stat()
    if ((before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns)
            or total != expected_size):
        raise ValueError('Source changed while reading; it was not modified by this notebook')
    manifest = {**identity, 'source_bytes': total, 'source_sha256': whole.hexdigest(),
                'chunk_bytes': chunk_bytes, 'parts': parts, 'client_info': info,
                'source_modified': False, 'mac_project_storage_used': False}
    temporary = destination / 'manifest.json.partial'
    if temporary.exists() or temporary.is_symlink() or (destination / 'manifest.json').is_symlink():
        raise ValueError('Unexpected manifest location')
    temporary.write_text(json.dumps(manifest, indent=2) + '\n')
    temporary.replace(destination / 'manifest.json')
    print('Finished %d parts. Original IPA unchanged. Return to ChatGPT and say the cloud split finished.' % len(parts))
    print(json.dumps(info, indent=2))
    return manifest
