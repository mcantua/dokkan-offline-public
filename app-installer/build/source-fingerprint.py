#!/usr/bin/env python3
"""Fingerprint all native/Rust/build/assets and vendored engine source used by this build.

The digest excludes generated target/work trees and compiler logs. Tool binaries,
SDKs and platform runtime behavior are separate provenance/verification concerns.
"""
import hashlib
import sys
sys.dont_write_bytecode=True
from licensing import load_graph
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOTS = [ROOT/'app-installer/ios', ROOT/'app-installer/core', ROOT/'app-installer/build',
                ROOT/'downloads/isideload/isideload-0.5.0', ROOT/'downloads/idevice/idevice-0.1.68', ROOT/'downloads/license-notices',ROOT/'downloads/apple-trust']
SUFFIXES = {'.m','.h','.rs','.toml','.lock','.sh','.py','.plist','.png','.json','.md','.cer'}


def source_files():
    files = {ROOT/'app-installer/LICENSE',ROOT/'app-installer/licensing-signing.md'}
    roots=list(SOURCE_ROOTS)
    # Recipient LGPL replacements are valid path dependencies and must be fingerprinted too.
    _,packages,_,_=load_graph()
    for package in packages:
        if not package.get('source'):
            path=Path(package['manifest_path']).resolve().parent
            path.relative_to(ROOT)
            if path not in roots:roots.append(path)
    for base in roots:
        for path in base.rglob('*'):
            relative = path.relative_to(ROOT)
            if ('target' in relative.parts or 'work' in relative.parts or '__pycache__' in relative.parts):
                continue
            if not path.is_file():
                continue
            if path.suffix in SUFFIXES or path.name.startswith(('LICENSE','LICENCE','COPYING','NOTICE','COPYRIGHT')):
                if path.is_symlink():
                    raise ValueError('Source symlink cannot be fingerprinted reproducibly: ' + str(relative))
                files.add(path)
    return sorted(files, key=lambda p: str(p.relative_to(ROOT)))


def fingerprint():
    digest = hashlib.sha256(b'AppInstaller source fingerprint v1\n')
    for path in source_files():
        name = str(path.relative_to(ROOT)).encode('utf-8')
        content = path.read_bytes()
        digest.update(struct.pack('>Q',len(name)));digest.update(name)
        digest.update(struct.pack('>Q',len(content)));digest.update(content)
    return digest.hexdigest()


if __name__ == '__main__': print(fingerprint())
