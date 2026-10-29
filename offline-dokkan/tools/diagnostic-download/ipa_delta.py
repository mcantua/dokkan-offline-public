#!/usr/bin/env python3
"""Exact compressed-ZIP span reuse; stdlib only, no unpacking game content.

The delta contains literal ZIP bytes plus bounded copy operations against one
hash-pinned baseline. It never modifies its inputs or overwrites an output.
"""
import hashlib
import json
import os
from pathlib import Path
import stat
import struct
import tempfile
import zipfile

MAGIC = b'ODIPAD1\n'
BLOCK = 1024 * 1024
MAX_FILE = 4 * 1024 ** 3
MAX_RECIPE = 8 * 1024 ** 2
MAX_PATCH = 512 * 1024 ** 2


def regular(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    if not stat.S_ISREG(os.fstat(fd).st_mode):
        os.close(fd)
        raise ValueError('Expected a regular input file')
    return os.fdopen(fd, 'rb')


def file_pin(source):
    source.seek(0)
    size = os.fstat(source.fileno()).st_size
    if not 0 < size <= MAX_FILE:
        raise ValueError('Input size outside bounded delivery contract')
    digest = hashlib.file_digest(source, 'sha256').hexdigest()
    return size, digest


def span_hash(source, offset, length):
    source.seek(offset)
    digest = hashlib.sha256()
    left = length
    while left:
        block = source.read(min(BLOCK, left))
        if not block:
            raise ValueError('Truncated compressed span')
        digest.update(block)
        left -= len(block)
    return digest.hexdigest()


def zip_spans(source):
    size = os.fstat(source.fileno()).st_size
    result = {}
    with zipfile.ZipFile(source) as archive:
        if len(archive.infolist()) > 20000:
            raise ValueError('Unexpected archive member count')
        for item in archive.infolist():
            names = item.filename.split('/')
            if len(names) < 3 or names[0] != 'Payload' or not names[1].endswith('.app'):
                raise ValueError('Only a conventional own IPA is admitted')
            name = '/'.join(names[2:])
            if name in result or item.flag_bits & 1:
                raise ValueError('Duplicate or ZIP-encrypted member refused')
            source.seek(item.header_offset)
            header = source.read(30)
            if len(header) != 30 or header[:4] != b'PK\x03\x04':
                raise ValueError('Invalid local ZIP header')
            filename_length, extra_length = struct.unpack_from('<HH', header, 26)
            start = item.header_offset + 30 + filename_length + extra_length
            if not 0 <= start <= start + item.compress_size <= size:
                raise ValueError('Compressed ZIP span outside input')
            result[name] = (start, item.compress_size)
    return result


def copy_span(source, target, offset, length, digest=None):
    source.seek(offset)
    while length:
        block = source.read(min(BLOCK, length))
        if not block:
            raise ValueError('Truncated delivery input')
        target.write(block)
        if digest is not None:
            digest.update(block)
        length -= len(block)


def make_delta(base_path, target_path, output_path, base_pin, target_pin):
    with regular(base_path) as base, regular(target_path) as target:
        if file_pin(base) != base_pin or file_pin(target) != target_pin:
            raise ValueError('Exact baseline/target pin mismatch')
        originals = zip_spans(base)
        candidates = sorted(zip_spans(target).items(), key=lambda item: item[1][0])
        ops = []
        literal_size = reused = cursor = 0
        with tempfile.TemporaryFile() as literals:
            def literal(start, length):
                nonlocal literal_size
                if not length:
                    return
                if ops and ops[-1][0] == 'literal':
                    ops[-1][2] += length
                else:
                    ops.append(['literal', literal_size, length])
                copy_span(target, literals, start, length)
                literal_size += length

            for name, (start, length) in candidates:
                original = originals.get(name)
                if not length or original is None or original[1] != length:
                    continue
                if span_hash(target, start, length) != span_hash(base, *original):
                    continue
                if start < cursor:
                    raise ValueError('Overlapping compressed spans')
                literal(cursor, start - cursor)
                ops.append(['base', original[0], length])
                reused += length
                cursor = start + length
            literal(cursor, target_pin[0] - cursor)
            recipe = {'format':'od-ipa-compressed-delta-v1',
                'base_bytes':base_pin[0], 'base_sha256':base_pin[1],
                'target_bytes':target_pin[0], 'target_sha256':target_pin[1],
                'literal_bytes':literal_size, 'operations':ops}
            raw = json.dumps(recipe, separators=(',', ':')).encode('ascii')
            if len(raw) > MAX_RECIPE or len(ops) > 40000 or 16 + len(raw) + literal_size > MAX_PATCH:
                raise ValueError('Delta exceeds delivery bounds')
            # Exclusive creation preserves an existing delivery artifact.
            with open(output_path, 'xb') as output:
                output.write(MAGIC + struct.pack('>Q', len(raw)) + raw)
                copy_span(literals, output, 0, literal_size)
            with regular(output_path) as output:
                patch_pin = file_pin(output)
            return {'base_bytes':base_pin[0], 'base_sha256':base_pin[1],
                'target_bytes':target_pin[0], 'target_sha256':target_pin[1],
                'patch_bytes':patch_pin[0], 'patch_sha256':patch_pin[1],
                'reused_compressed_bytes':reused, 'literal_bytes':literal_size,
                'operations':len(ops)}


def apply_delta(base_path, patch_path, output_path, base_pin, patch_pin, target_pin):
    """Verify every input, reconstruct in scratch, then publish exclusively."""
    output_path = Path(output_path)
    if os.path.lexists(output_path):
        with regular(output_path) as existing:
            if file_pin(existing) == target_pin:
                return {'already_present':True, 'bytes':target_pin[0], 'sha256':target_pin[1]}
        raise ValueError('Different existing output preserved')
    if not 0 < patch_pin[0] <= MAX_PATCH or not 0 < target_pin[0] <= MAX_FILE:
        raise ValueError('Pinned delivery size outside bounds')
    with regular(base_path) as base, regular(patch_path) as patch:
        if file_pin(base) != base_pin or file_pin(patch) != patch_pin:
            raise ValueError('Baseline or delta checksum mismatch')
        patch.seek(0)
        header = patch.read(16)
        if len(header) != 16 or header[:8] != MAGIC:
            raise ValueError('Invalid delta magic')
        count = struct.unpack('>Q', header[8:])[0]
        if not 0 < count <= MAX_RECIPE or 16 + count > patch_pin[0]:
            raise ValueError('Invalid recipe size')
        recipe = json.loads(patch.read(count))
        literal_start = 16 + count
        if (recipe.get('format') != 'od-ipa-compressed-delta-v1'
                or (recipe.get('base_bytes'), recipe.get('base_sha256')) != base_pin
                or (recipe.get('target_bytes'), recipe.get('target_sha256')) != target_pin
                or type(recipe.get('literal_bytes')) is not int
                or literal_start + recipe['literal_bytes'] != patch_pin[0]):
            raise ValueError('Recipe pins differ from reviewed delivery')
        ops = recipe.get('operations')
        if not isinstance(ops, list) or not 1 <= len(ops) <= 40000:
            raise ValueError('Invalid operation count')
        total = literal_cursor = 0
        for op in ops:
            if (not isinstance(op, list) or len(op) != 3 or op[0] not in ('base', 'literal')
                    or type(op[1]) is not int or type(op[2]) is not int or op[1] < 0 or op[2] <= 0):
                raise ValueError('Invalid bounded copy operation')
            limit = base_pin[0] if op[0] == 'base' else recipe['literal_bytes']
            if op[1] + op[2] > limit:
                raise ValueError('Copy operation outside input')
            if op[0] == 'literal':
                if op[1] != literal_cursor:
                    raise ValueError('Noncontiguous literal stream')
                literal_cursor += op[2]
            total += op[2]
            if total > target_pin[0]:
                raise ValueError('Reconstruction exceeds target')
        if total != target_pin[0] or literal_cursor != recipe['literal_bytes']:
            raise ValueError('Incomplete reconstruction coverage')
        with tempfile.TemporaryFile() as assembled:
            digest = hashlib.sha256()
            for kind, offset, length in ops:
                copy_span(base if kind == 'base' else patch, assembled,
                    offset if kind == 'base' else literal_start + offset, length, digest)
            if digest.hexdigest() != target_pin[1]:
                raise ValueError('Reconstructed target checksum mismatch')
            # Publish only after exact complete reconstruction. Any different
            # pre-existing output is preserved by exclusive creation.
            fd = os.open(output_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
            identity = os.fstat(fd)
            try:
                with os.fdopen(fd, 'wb') as output:
                    copy_span(assembled, output, 0, target_pin[0])
                    output.flush()
                    os.fsync(output.fileno())
                with regular(output_path) as result:
                    if file_pin(result) != target_pin:
                        raise ValueError('Published output checksum mismatch')
            except BaseException:
                now = os.lstat(output_path) if os.path.lexists(output_path) else None
                if now and (now.st_dev, now.st_ino) == (identity.st_dev, identity.st_ino):
                    os.unlink(output_path)
                raise
    return {'already_present':False, 'bytes':target_pin[0], 'sha256':target_pin[1]}
