#!/usr/bin/env python3
"""Google Colab only: restore one exact, unsigned diagnostic IPA in private Drive.

No source game inputs, credentials, signing material, or device data are used.
Parts and the manifest remain unchanged. This does not build or sign an app.
"""

import hashlib
import json
import os
from pathlib import Path
import stat
import tempfile


DIRECTORY = Path('/content/drive/MyDrive/AI-Workspace/Offline Dokkan + Unit Creator/Builds')
MANIFEST_NAME = 'diagnostic-download-manifest.json'
MANIFEST_SHA256 = 'd98070f1a506ef3354aa746f25fbc14dbb437c4d27553665c639f96e4b67b822'
OUTPUT_NAME = 'OfflineDokkan-Duo-Diagnostic-2.36.3.ipa'
EXPECTED_SIZE = 795503162
EXPECTED_SHA256 = '8299b3fc2f306d58a891e3baa5c1b0e64afb9b55269c5e91bdcb6a4086506008'
PARTS = (
    ('OfflineDokkan-Duo-Diagnostic-2.36.3.ipa.part-01', 100663296, '70b6ea7f48254cc73247409c3d009db4b1b6df6185fd7ac960ad9eb21e9170cd'),
    ('OfflineDokkan-Duo-Diagnostic-2.36.3.ipa.part-02', 100663296, '5b5cda315e2f60b63dc8411fe7d6c6259b51866318306cbc33cad834644b9416'),
    ('OfflineDokkan-Duo-Diagnostic-2.36.3.ipa.part-03', 100663296, 'bf5f904238885a5320e6a3136f5bab7ce37ec59479871eb5fb575f97a3b37966'),
    ('OfflineDokkan-Duo-Diagnostic-2.36.3.ipa.part-04', 100663296, 'aaf7e1ea9226a7b6f7cdbb4b9e1a6e5630ff0199ead03eac5bd55e762659fd0c'),
    ('OfflineDokkan-Duo-Diagnostic-2.36.3.ipa.part-05', 100663296, 'ef0e98afece6f27fe9d7937386460de6f76421243e12317fce3783400c1e71d3'),
    ('OfflineDokkan-Duo-Diagnostic-2.36.3.ipa.part-06', 100663296, '2744328d0433ea345342ab4a69160598780fc061c1f29adfe4510ddd6cac788c'),
    ('OfflineDokkan-Duo-Diagnostic-2.36.3.ipa.part-07', 100663296, 'fbc0fb206f21e235002efa08a4f6e9a2e5de1c0eb9a3f1bd6b9355eb75ed434d'),
    ('OfflineDokkan-Duo-Diagnostic-2.36.3.ipa.part-08', 90860090, '59c7c16225c21fc8f11eb6870047f22b48731a25647d739513ed1df4e5fef763'),
)
BLOCK = 1024 * 1024


def open_regular(path):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    if not stat.S_ISREG(os.fstat(fd).st_mode):
        os.close(fd)
        raise RuntimeError('Expected a regular file; nothing has been replaced.')
    return os.fdopen(fd, 'rb')


def digest_file(path):
    size = 0
    digest = hashlib.sha256()
    with open_regular(path) as source:
        while block := source.read(BLOCK):
            size += len(block)
            if size > EXPECTED_SIZE:
                raise RuntimeError('Existing file exceeds the pinned size; preserved unchanged.')
            digest.update(block)
    return size, digest.hexdigest()


def restore():
    # Fail before data I/O outside the Google-hosted Colab runtime.
    from google.colab import drive
    drive.mount('/content/drive')

    if not DIRECTORY.is_dir() or any(p.is_symlink() for p in (DIRECTORY, *DIRECTORY.parents)):
        raise RuntimeError('The exact private Builds folder is unavailable; no folders were created.')
    with open_regular(DIRECTORY / MANIFEST_NAME) as source:
        raw = source.read(65537)
    if len(raw) > 65536 or hashlib.sha256(raw).hexdigest() != MANIFEST_SHA256:
        raise RuntimeError('Manifest checksum differs; all files preserved.')
    manifest = json.loads(raw)
    expected_parts = [{'name': n, 'size': s, 'sha256': h} for n, s, h in PARTS]
    if (manifest.get('parts') != expected_parts or manifest.get('bytes') != EXPECTED_SIZE
            or manifest.get('sha256') != EXPECTED_SHA256 or manifest.get('signed') is not False
            or manifest.get('playable') is not False):
        raise RuntimeError('Manifest does not describe the pinned unsigned diagnostic.')

    output = DIRECTORY / OUTPUT_NAME
    if os.path.lexists(output):
        if digest_file(output) != (EXPECTED_SIZE, EXPECTED_SHA256):
            raise RuntimeError('A different output already exists; it was preserved unchanged.')
        print('The verified single IPA already exists in Builds. No files changed.')
        print('Unsigned diagnostic only. Signing is required; gameplay is not verified.')
        return

    # Google runtime scratch only; no local Mac download. Each source is verified
    # while concatenating, then the complete IPA is pinned before Drive publication.
    with tempfile.TemporaryFile(dir='/content') as assembled:
        combined = hashlib.sha256()
        total = 0
        for name, expected_size, expected_hash in PARTS:
            digest = hashlib.sha256()
            count = 0
            with open_regular(DIRECTORY / name) as source:
                if os.fstat(source.fileno()).st_size != expected_size:
                    raise RuntimeError('Part size mismatch; no output was published.')
                while block := source.read(BLOCK):
                    count += len(block)
                    if count > expected_size:
                        raise RuntimeError('Part grew; no output was published.')
                    digest.update(block)
                    combined.update(block)
                    assembled.write(block)
            if count != expected_size or digest.hexdigest() != expected_hash:
                raise RuntimeError('Part checksum mismatch; no output was published.')
            total += count
        if total != EXPECTED_SIZE or combined.hexdigest() != EXPECTED_SHA256:
            raise RuntimeError('Final checksum mismatch; no output was published.')

        assembled.seek(0)
        fd = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
        identity = os.fstat(fd)
        try:
            with os.fdopen(fd, 'wb') as target:
                while block := assembled.read(BLOCK):
                    target.write(block)
                target.flush()
                os.fsync(target.fileno())
            if digest_file(output) != (EXPECTED_SIZE, EXPECTED_SHA256):
                raise RuntimeError('Drive output verification failed.')
        except BaseException:
            # Remove only the new file this invocation exclusively created.
            current = os.lstat(output) if os.path.lexists(output) else None
            if current and (current.st_dev, current.st_ino) == (identity.st_dev, identity.st_ino):
                os.unlink(output)
            raise
    print('Single IPA restored and checksum verified in the private Builds folder:')
    print(OUTPUT_NAME)
    print(f'{EXPECTED_SIZE:,} bytes; SHA-256 {EXPECTED_SHA256}')
    print('All eight parts and the manifest are preserved.')
    print('Unsigned diagnostic only. Signing is required; gameplay is not verified.')


if __name__ == '__main__':
    restore()
