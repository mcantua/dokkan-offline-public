#!/usr/bin/env python3
"""Read-only local copy inventory. No deletion, network, installs or credentials."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import sys

PROTECTED = {'.git', '.svn', 'private-build', 'signing', 'app-installer',
             'App Installer', 'Keychains', '.ssh', 'node_modules', '__pycache__',
             'Sparking', 'Sparking Full Data', 'Eclipse'}
SECRET_SUFFIXES = {'.key', '.jks', '.p12', '.p8', '.pem', '.mobileprovision'}


def sha_file(path):
    flags = os.O_RDONLY | getattr(os, 'O_NOFOLLOW', 0)
    fd = os.open(path, flags)
    with os.fdopen(fd, 'rb') as stream:
        before = os.fstat(stream.fileno())
        if not stat.S_ISREG(before.st_mode) or getattr(before, 'st_flags', 0) & 0x40000000:
            raise ValueError('Not an available regular local file')
        h = hashlib.sha256()
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
        after = os.fstat(stream.fileno())
        if (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns,
            before.st_ctime_ns) != (after.st_dev, after.st_ino, after.st_size,
                                    after.st_mtime_ns, after.st_ctime_ns):
            raise ValueError('File changed during inventory')
        return h.hexdigest(), after


def cloud_path(path):
    parts = path.parts
    return any(x in parts for x in ('CloudStorage', 'Mobile Documents',
                                    'FileProviderStorage', 'GoogleDrive'))


def scan(catalog, home, output):
    by_size = {}
    for item in catalog['contents']:
        by_size.setdefault(item['size'], {})[item['sha256']] = item
    hints = set(catalog['download_names'])
    roots = [('Unit Creator', home / 'AI-Workspace/Dokkan-Unit-Creator'),
             ('Offline Dokkan', home / 'AI-Workspace/Offline Dokkan Battle')]
    report = {'schema': 1, 'read_only': True, 'deleted_files': 0,
              'catalog_sha256': catalog['catalog_identity'], 'roots': [],
              'matches': [], 'unreadable_or_changed': 0, 'skipped_cloud_placeholders': 0,
              'needs_fresh_drive_verification_before_deletion': True}
    local = []
    def examine(path, label, base):
        try:
            if path.is_symlink() or path.suffix.lower() in SECRET_SUFFIXES or path.name.startswith('.env') or 'password' in path.name.lower() or path.name == '.pw':
                return
            st = path.lstat()
            if getattr(st, 'st_flags', 0) & 0x40000000:
                report['skipped_cloud_placeholders'] += 1
                return
            if not stat.S_ISREG(st.st_mode) or st.st_size not in by_size:
                return
            digest, st = sha_file(path)
            item = by_size[st.st_size].get(digest)
            if item is None:
                return
            relative = str(path.relative_to(base))
            identity = hashlib.sha256((label + '\0' + relative).encode()).hexdigest()
            public = {'candidate_id': identity, 'root': label, 'size': st.st_size,
                      'sha256': digest, 'backing': item['backing']}
            report['matches'].append(public)
            local.append({**public, 'path': str(path), 'root_path': str(base),
                          'device': st.st_dev, 'inode': st.st_ino,
                          'mtime_ns': st.st_mtime_ns, 'ctime_ns': st.st_ctime_ns})
        except (OSError, ValueError):
            report['unreadable_or_changed'] += 1
    for label, base in roots:
        available = base.is_dir() and not base.is_symlink() and not cloud_path(base.resolve())
        report['roots'].append({'root': label, 'available': available})
        if not available:
            continue
        for current, dirs, files in os.walk(base, followlinks=False):
            dirs[:] = [d for d in dirs if d not in PROTECTED and not (Path(current) / d).is_symlink()]
            for name in files:
                examine(Path(current) / name, label, base)
    downloads = home / 'Downloads'
    if downloads.is_dir() and not downloads.is_symlink() and not cloud_path(downloads.resolve()):
        for path in downloads.iterdir():
            if path.name in hints:
                examine(path, 'Known project downloads', downloads)
    if cloud_path(output.resolve()) or any(p.is_symlink() for p in (output, *output.parents)):
        raise ValueError('Report location must be local and unsynchronized')
    output.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(output, 0o700)
    private = {'schema': 1, 'matches': local}
    payload = json.dumps(private, sort_keys=True, indent=2) + '\n'
    report['local_plan_sha256'] = hashlib.sha256(payload.encode()).hexdigest()
    report['matched_bytes'] = sum(x['size'] for x in local)
    for name, data in [('local-plan.json', payload),
                       ('report.json', json.dumps(report, indent=2) + '\n')]:
        target = output / name
        if target.is_symlink() or target.with_suffix('.part').exists():
            raise ValueError('Output is not a plain current report location')
        temporary = target.with_suffix('.part')
        with temporary.open('x') as stream:
            os.chmod(temporary, 0o600)
            stream.write(data)
        temporary.replace(target)
    print('Read-only scan finished. No files were deleted and no network was used.')
    print('Matched %.2f GB across %d local files.' % (report['matched_bytes'] / 1e9, len(local)))
    print('Attach report.json from AI-Workspace/Dokkan-Unit-Creator/evidence/drive-cleanup.')
    print('Keep local-plan.json on this Mac. It contains private local paths.')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--catalog', required=True, type=Path)
    p.add_argument('--catalog-sha256', required=True)
    args = p.parse_args()
    try:
        data = args.catalog.read_bytes()
        if hashlib.sha256(data).hexdigest() != args.catalog_sha256:
            raise ValueError('Wrong catalog')
        catalog = json.loads(data)
        home = Path.home()
        scan(catalog, home, home / 'AI-Workspace/Dokkan-Unit-Creator/evidence/drive-cleanup')
    except (OSError, ValueError, KeyError, TypeError):
        raise SystemExit('Scan stopped: input, permission or output problem. No files were deleted.')


if __name__ == '__main__':
    main()
