#!/usr/bin/env python3
"""Remove only unchanged local copies covered by a pinned cleanup receipt."""
import argparse
import ctypes
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import time
import uuid

BLOCKED = {'.git', '.svn', 'private-build', 'signing', 'app-installer',
           'App Installer', 'Keychains', '.ssh', 'CloudStorage', 'GoogleDrive',
           'Mobile Documents', 'FileProviderStorage', 'Sparking',
           'Sparking Full Data', 'Eclipse'}
SECRET = {'.key', '.jks', '.p12', '.p8', '.pem', '.mobileprovision'}
ORDINARY_ATTRIBUTES = {'com.apple.quarantine', 'com.apple.lastuseddate#PS',
                       'com.apple.provenance'}
DIR_FLAGS = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
FILE_FLAGS = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK


def directory(path):
    path = Path(path)
    if not path.is_absolute() or any(p in BLOCKED or p == '..' for p in path.parts):
        raise ValueError('Unsafe directory')
    fd = os.open('/', DIR_FLAGS)
    try:
        for part in path.parts[1:]:
            next_fd = os.open(part, DIR_FLAGS, dir_fd=fd)
            os.close(fd)
            fd = next_fd
        return fd
    except BaseException:
        os.close(fd)
        raise


def subdirectory(fd, parts, create=False):
    current = os.dup(fd)
    device = os.fstat(fd).st_dev
    try:
        for part in parts:
            if part in BLOCKED or part in ('', '.', '..') or '/' in part:
                raise ValueError('Unsafe component')
            if create:
                try:
                    os.mkdir(part, 0o700, dir_fd=current)
                except FileExistsError:
                    pass
            next_fd = os.open(part, DIR_FLAGS, dir_fd=current)
            os.close(current)
            current = next_fd
            if os.fstat(current).st_dev != device:
                raise ValueError('Different filesystem')
        return current
    except BaseException:
        os.close(current)
        raise


def read_at(fd, name, limit):
    handle = os.open(name, FILE_FLAGS, dir_fd=fd)
    with os.fdopen(handle, 'rb') as stream:
        st = os.fstat(stream.fileno())
        if not stat.S_ISREG(st.st_mode) or st.st_size > limit:
            raise ValueError('Invalid control file')
        data = stream.read(limit + 1)
        if len(data) > limit:
            raise ValueError('Oversized control file')
        return data


def identity(st):
    return st.st_dev, st.st_ino, st.st_size, st.st_mtime_ns, st.st_ctime_ns, st.st_nlink


def digest_fd(fd):
    before = os.fstat(fd)
    os.lseek(fd, 0, os.SEEK_SET)
    h = hashlib.sha256()
    for data in iter(lambda: os.read(fd, 1024 * 1024), b''):
        h.update(data)
    after = os.fstat(fd)
    if identity(before) != identity(after):
        raise ValueError('Changed during verification')
    return h.hexdigest()


def metadata_supported(fd):
    if sys.platform == 'darwin':
        # macOS CPython does not consistently expose os.listxattr. Darwin's
        # fd API takes a fourth options argument; never use Linux's signature.
        fn = ctypes.CDLL(None, use_errno=True).flistxattr
        fn.argtypes = (ctypes.c_int, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_int)
        fn.restype = ctypes.c_ssize_t
        size = fn(fd, None, 0, 0)
        if size < 0 or size > 1024 * 1024:
            return False
        if not size:
            return True
        buf = ctypes.create_string_buffer(size)
        count = fn(fd, buf, size, 0)
        if count < 0 or count > size:
            return False
        names = {x.decode('utf-8', 'replace') for x in buf.raw[:count].split(b'\0') if x}
    elif hasattr(os, 'listxattr'):
        names = set(os.listxattr(fd))
    else:
        return False
    return not (names - ORDINARY_ATTRIBUTES)


def restore_claim(claim_fd, parent_fd, name):
    # A hard link restores a regular file/symlink only if its old name is free.
    # It never overwrites another file created concurrently at the old name.
    try:
        os.link('copy', name, src_dir_fd=claim_fd, dst_dir_fd=parent_fd,
                follow_symlinks=False)
        os.unlink('copy', dir_fd=claim_fd)
        return True
    except (OSError, NotImplementedError):
        return False


def remove_one(item, base, root_fd, held_fd):
    relative = Path(item['path']).relative_to(base)
    parent_fd = file_fd = claim_fd = None
    claimed = False
    claim_created = False
    outcome = 'error'
    try:
        parent_fd = subdirectory(root_fd, relative.parts[:-1])
        name = relative.name
        before = os.stat(name, dir_fd=parent_fd, follow_symlinks=False)
        expected = (item['device'], item['inode'], item['size'], item['mtime_ns'],
                    item['ctime_ns'], 1)
        if (not stat.S_ISREG(before.st_mode) or identity(before) != expected or
                before.st_uid != os.getuid() or getattr(before, 'st_flags', 0) & 0x40000000):
            return 'changed_or_shared'
        file_fd = os.open(name, FILE_FLAGS, dir_fd=parent_fd)
        fcntl.flock(file_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if identity(os.fstat(file_fd)) != expected:
            return 'changed_or_shared'
        if not metadata_supported(file_fd):
            return 'preserved_extra_metadata'
        if digest_fd(file_fd) != item['sha256']:
            return 'changed_content'
        if identity(os.stat(name, dir_fd=parent_fd, follow_symlinks=False)) != expected:
            return 'changed_or_shared'
        os.mkdir(item['candidate_id'], 0o700, dir_fd=held_fd)
        claim_created = True
        claim_fd = os.open(item['candidate_id'], DIR_FLAGS, dir_fd=held_fd)
        os.rename(name, 'copy', src_dir_fd=parent_fd, dst_dir_fd=claim_fd)
        claimed = True
        moved = os.stat('copy', dir_fd=claim_fd, follow_symlinks=False)
        current = os.fstat(file_fd)
        if ((moved.st_dev, moved.st_ino, moved.st_size, moved.st_mtime_ns, moved.st_nlink) !=
                (item['device'], item['inode'], item['size'], item['mtime_ns'], 1) or
                identity(moved) != identity(current) or
                not metadata_supported(file_fd) or digest_fd(file_fd) != item['sha256']):
            outcome = 'changed_during_claim'
        else:
            os.unlink('copy', dir_fd=claim_fd)
            claimed = False
            outcome = 'deleted'
    except FileNotFoundError:
        outcome = 'missing'
    except BlockingIOError:
        outcome = 'busy'
    except (OSError, ValueError):
        outcome = 'preserved_error'
    finally:
        if claimed:
            outcome = ('preserved_concurrent_change' if restore_claim(claim_fd, parent_fd, relative.name)
                       else 'retained_in_held_folder')
        for fd in (file_fd, claim_fd, parent_fd):
            if fd is not None:
                os.close(fd)
        if claim_created:
            try:
                os.rmdir(item['candidate_id'], dir_fd=held_fd)
            except OSError:
                pass
    return outcome


def cleanup(receipt, home):
    if (receipt.get('schema') != 1 or receipt.get('purpose') != 'authorized-permanent-local-copy-cleanup'
            or receipt.get('recovery', {}).get('byte_readback_verified') is not True
            or not receipt['issued_epoch'] - 300 <= time.time() <= receipt['expires_epoch']
            or receipt['expires_epoch'] - receipt['issued_epoch'] > 86400):
        raise ValueError('Invalid or expired receipt')
    roots = {'Unit Creator': home / 'AI-Workspace/Dokkan-Unit-Creator',
             'Offline Dokkan': home / 'AI-Workspace/Offline Dokkan Battle',
             'Known project downloads': home / 'Downloads'}
    control_root = directory(roots['Unit Creator'])
    output_fd = held_fd = None
    opened = {}
    try:
        output_fd = subdirectory(control_root, ('evidence', 'drive-cleanup'))
        data = read_at(output_fd, 'local-plan.json', 8 * 1024 * 1024)
        if hashlib.sha256(data).hexdigest() != receipt['local_plan_sha256']:
            raise ValueError('The local plan changed')
        plan = json.loads(data)
        approved = {x['candidate_id']: x for x in receipt['approved']}
        items = plan['matches']
        if (plan['schema'] != 1 or len(approved) != len(receipt['approved']) or
                len(items) != len(approved) or len({x['candidate_id'] for x in items}) != len(items)
                or receipt['maximum_bytes'] != sum(x['size'] for x in receipt['approved'])):
            raise ValueError('Plan/receipt mismatch')
        # Validate every path and permission before removing the first file.
        for item in items:
            expected = approved[item['candidate_id']]
            if (not re.fullmatch('[0-9a-f]{64}', item['candidate_id']) or
                    any(item[k] != expected[k] for k in ('root', 'sha256', 'size', 'backing')) or
                    any(type(item[k]) is not int for k in ('device', 'inode', 'size', 'mtime_ns', 'ctime_ns'))):
                raise ValueError('Invalid approved item')
            base = roots[item['root']]
            path = Path(item['path'])
            relative = path.relative_to(base)
            if (item['root_path'] != str(base) or not relative.parts or
                    any(x in BLOCKED or x == '..' for x in relative.parts) or
                    path.suffix.lower() in SECRET or path.name.startswith('.env') or
                    'password' in path.name.lower() or path.name == '.pw' or
                    relative.parts[:2] == ('evidence', 'drive-cleanup') or
                    (item['root'] == 'Known project downloads' and len(relative.parts) != 1) or
                    hashlib.sha256((item['root'] + '\0' + str(relative)).encode()).hexdigest() != item['candidate_id']):
                raise ValueError('Unsafe approved path')
        previous = {}
        try:
            old = json.loads(read_at(output_fd, 'cleanup-result.json', 4 * 1024 * 1024))
            if old.get('tool') != 'drive-copy-delete' or old.get('local_plan_sha256') != receipt['local_plan_sha256']:
                raise ValueError('Unrelated existing result')
            previous = {x['candidate_id']: x for x in old['items'] if x['status'] == 'deleted'}
        except FileNotFoundError:
            pass
        held_fd = subdirectory(output_fd, ('held',), create=True)
        result = {'schema': 1, 'tool': 'drive-copy-delete', 'local_plan_sha256': receipt['local_plan_sha256'],
                  'recovery_file_id': receipt['recovery']['file_id'], 'items': []}
        home_device = os.stat(home, follow_symlinks=False).st_dev
        for item in items:
            if item['candidate_id'] in previous:
                result['items'].append(previous[item['candidate_id']])
                continue
            try:
                if item['root'] not in opened:
                    fd = directory(roots[item['root']])
                    if os.fstat(fd).st_dev != home_device:
                        os.close(fd)
                        raise ValueError('Nonlocal filesystem')
                    opened[item['root']] = fd
                status = remove_one(item, roots[item['root']], opened[item['root']], held_fd)
            except (OSError, ValueError):
                status = 'preserved_unsafe_location'
            result['items'].append({'candidate_id': item['candidate_id'], 'status': status, 'size': item['size']})
        result['deleted_files'] = sum(x['status'] == 'deleted' for x in result['items'])
        result['logical_bytes_removed'] = sum(x['size'] for x in result['items'] if x['status'] == 'deleted')
        result['skipped_files'] = len(items) - result['deleted_files']
        temporary = '.cleanup-result-' + uuid.uuid4().hex
        fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=output_fd)
        with os.fdopen(fd, 'w') as stream:
            json.dump(result, stream, indent=2)
            stream.write('\n')
        os.replace(temporary, 'cleanup-result.json', src_dir_fd=output_fd, dst_dir_fd=output_fd)
        print('Permanent cleanup finished: %d files removed (%.2f MB); %d preserved/skipped.' %
              (result['deleted_files'], result['logical_bytes_removed'] / 1e6, result['skipped_files']))
        print('Send cleanup-result.json from AI-Workspace/Dokkan-Unit-Creator/evidence/drive-cleanup.')
        if any(x['status'] == 'retained_in_held_folder' for x in result['items']):
            print('A concurrent change was preserved in evidence/drive-cleanup/held. Do not delete that folder.')
        return result
    finally:
        for fd in [*opened.values(), held_fd, output_fd, control_root]:
            if fd is not None:
                os.close(fd)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--receipt', required=True, type=Path)
    p.add_argument('--receipt-sha256', required=True)
    args = p.parse_args()
    if sys.platform != 'darwin':
        raise SystemExit('This command is for the Mac that produced the scan.')
    try:
        raw = args.receipt.read_bytes()
        if len(raw) > 1024 * 1024 or hashlib.sha256(raw).hexdigest() != args.receipt_sha256:
            raise ValueError('Receipt mismatch')
        cleanup(json.loads(raw), Path.home())
    except (OSError, ValueError, KeyError, TypeError, OverflowError):
        raise SystemExit('Cleanup stopped. The plan, clock, receipt or local files changed. Do not remove protected/held files manually.')


if __name__ == '__main__':
    main()
