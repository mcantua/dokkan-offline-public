#!/usr/bin/env python3
"""Reassemble checksum-pinned cloud transfer pieces without changing originals."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat


def assemble(manifest_path, parts_root, output, expected_source_id, expected_bytes):
    manifest_path, parts_root, output = Path(manifest_path), Path(parts_root), Path(output)
    raw = manifest_path.read_bytes()
    if len(raw) > 1024 * 1024:
        raise ValueError('Manifest too large')
    m = json.loads(raw)
    if (m.get('schema') != 1 or m.get('source_drive_id') != expected_source_id or
            m.get('source_bytes') != expected_bytes or
            not re.fullmatch('[0-9a-f]{64}', m.get('source_sha256', '')) or
            not isinstance(m.get('parts'), list) or not 1 <= len(m['parts']) <= 1024):
        raise ValueError('Transfer identity mismatch')
    total = 0
    for index, part in enumerate(m['parts'], 1):
        if (part.get('name') != 'iphone-client.part-%04d' % index or
                type(part.get('size')) is not int or not 0 < part['size'] <= 96 * 1024 * 1024 or
                not re.fullmatch('[0-9a-f]{64}', part.get('sha256', ''))):
            raise ValueError('Invalid ordered transfer part')
        total += part['size']
    if total != expected_bytes:
        raise ValueError('Wrong total transfer length')
    if output.exists() or output.is_symlink():
        if output.is_symlink() or not output.is_file() or output.stat().st_size != expected_bytes:
            raise ValueError('An existing output was preserved')
        h = hashlib.sha256()
        with output.open('rb') as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                h.update(chunk)
        if h.hexdigest() != m['source_sha256']:
            raise ValueError('An existing output was preserved')
        return {'bytes': expected_bytes, 'sha256': h.hexdigest(), 'reused': True}
    temporary = output.with_name(output.name + '.assembling')
    output.parent.mkdir(parents=True, exist_ok=True)
    h = hashlib.sha256()
    created = False
    try:
        with temporary.open('xb') as destination:
            created = True
            os.chmod(temporary, 0o600)
            for part in m['parts']:
                fd = os.open(parts_root / part['name'], os.O_RDONLY | os.O_NOFOLLOW)
                with os.fdopen(fd, 'rb') as source:
                    before = os.fstat(source.fileno())
                    if not stat.S_ISREG(before.st_mode) or before.st_size != part['size']:
                        raise ValueError('Transfer part length/type mismatch')
                    ph, count = hashlib.sha256(), 0
                    for data in iter(lambda: source.read(1024 * 1024), b''):
                        count += len(data)
                        ph.update(data)
                        h.update(data)
                        destination.write(data)
                    after = os.fstat(source.fileno())
                    if (count != part['size'] or ph.hexdigest() != part['sha256'] or
                            (before.st_size, before.st_mtime_ns, before.st_ino) !=
                            (after.st_size, after.st_mtime_ns, after.st_ino)):
                        raise ValueError('Changed/corrupt transfer part')
            if h.hexdigest() != m['source_sha256']:
                raise ValueError('Reassembled source checksum mismatch')
            destination.flush()
            os.fsync(destination.fileno())
        os.chmod(temporary, 0o400)
        # Never replace a concurrently created candidate or original file.
        os.link(temporary, output, follow_symlinks=False)
        temporary.unlink()
    except BaseException:
        if created and temporary.exists():
            temporary.unlink()
        raise
    return {'bytes': expected_bytes, 'sha256': h.hexdigest(), 'reused': False}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('manifest', type=Path)
    p.add_argument('parts_root', type=Path)
    p.add_argument('output', type=Path)
    p.add_argument('--source-id', required=True)
    p.add_argument('--source-bytes', type=int, required=True)
    args = p.parse_args()
    try:
        print(json.dumps(assemble(args.manifest, args.parts_root, args.output,
                                  args.source_id, args.source_bytes)))
    except (ValueError, OSError, KeyError, TypeError):
        raise SystemExit('Assembly failed; original input, parts and prior candidates were preserved.')


if __name__ == '__main__':
    main()
