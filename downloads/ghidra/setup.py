#!/usr/bin/env python3
"""Restore the pinned official prebuilt Ghidra compatible with cloud Java21.

This never builds Ghidra or an app, executes original code, or uses a game API.
Retain the verified ZIP as ordered96MiB Drive parts when requested.
"""
import argparse
import hashlib
import json
import shutil
import stat
import subprocess
import urllib.request
import zipfile
from pathlib import Path, PurePosixPath

HERE = Path(__file__).resolve().parent
CHUNK = 96 * 1024 * 1024


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def restore(manifest):
    archive = HERE / manifest['file']
    if not archive.exists():
        stage = archive.with_suffix('.download')
        try:
            request = urllib.request.Request(manifest['url'], headers={'User-Agent': 'DokkanOffline-Cloud-Static-Analysis'})
            with urllib.request.urlopen(request, timeout=60) as source, stage.open('xb') as out:
                count = 0
                while data := source.read(4 * 1024 * 1024):
                    count += len(data)
                    if count > manifest['bytes']:
                        raise ValueError('Archive exceeds pinned length')
                    out.write(data)
            if stage.stat().st_size != manifest['bytes'] or digest(stage) != manifest['sha256']:
                raise ValueError('Official archive pin mismatch')
            stage.replace(archive)
        except BaseException:
            if stage.exists():
                stage.unlink()
            raise
    if archive.stat().st_size != manifest['bytes'] or digest(archive) != manifest['sha256']:
        raise ValueError('Existing archive preserved: pin mismatch')
    runtime = HERE / 'runtime'
    prefix = 'ghidra_' + manifest['version'] + '_PUBLIC'
    installed = runtime / prefix
    if installed.exists():
        # Preserve an existing unpacked tool; do not replace a running instance.
        if not (installed / 'support/analyzeHeadless').is_file():
            raise ValueError('Existing runtime is incomplete; preserved for review')
        return archive, installed
    if runtime.exists():
        raise ValueError('Existing staging directory preserved')
    with zipfile.ZipFile(archive) as source:
        rows = source.infolist()
        if len(rows) > 30000 or sum(x.file_size for x in rows) > 2 * 1024**3:
            raise ValueError('Archive extraction bounds changed')
        seen = set()
        for row in rows:
            path = PurePosixPath(row.filename)
            if (path.is_absolute() or not path.parts or path.parts[0] != prefix or
                    any(x in {'..', '.'} for x in path.parts) or row.filename in seen or
                    stat.S_ISLNK(row.external_attr >> 16)):
                raise ValueError('Unsafe/duplicate extraction member')
            seen.add(row.filename)
        runtime.mkdir()
        try:
            for row in rows:
                target = runtime.joinpath(*PurePosixPath(row.filename).parts)
                if row.is_dir():
                    target.mkdir(parents=True, exist_ok=True)
                    continue
                target.parent.mkdir(parents=True, exist_ok=True)
                with source.open(row) as src, target.open('xb') as out:
                    shutil.copyfileobj(src, out, 1024 * 1024)
                mode = (row.external_attr >> 16) & 0o777
                target.chmod(mode or 0o644)
            if not (installed / 'support/analyzeHeadless').is_file():
                raise ValueError('Expected official headless launcher missing')
        except BaseException:
            shutil.rmtree(runtime)
            raise
    return archive, installed


def configure_java21_view(installed):
    # This cloud's managed runtime contains the genuine jdk.compiler module but
    # lacks only its command-line launcher. Forward to that compiler; never
    # change version metadata or download a replacement runtime.
    java = Path(shutil.which('java')).resolve()
    probe = subprocess.run([str(java), '-m', 'jdk.compiler/com.sun.tools.javac.Main', '-version'],
                           capture_output=True, text=True, check=True)
    if 'javac 21.' not in probe.stdout + probe.stderr:
        raise ValueError('Existing genuine Java21 compiler module required')
    view = HERE / 'java21-tools'
    (view / 'bin').mkdir(parents=True, exist_ok=True)
    executable = view / 'bin/java'
    if not executable.exists():
        executable.symlink_to(java)
    elif executable.resolve() != java:
        raise ValueError('Existing Java tool view preserved')
    runtime = java.parent.parent
    for name in ('lib', 'conf', 'release'):
        source, target = runtime / name, view / name
        if source.exists() and not target.exists():
            target.symlink_to(source, target_is_directory=source.is_dir())
    javac = view / 'bin/javac'
    javac.write_text('#!/bin/sh\nexec "$(dirname "$0")/java" -m jdk.compiler/com.sun.tools.javac.Main "$@"\n')
    javac.chmod(0o755)
    props = installed / 'support/launch.properties'
    lines = props.read_text().splitlines()
    if sum(line.startswith('JAVA_HOME_OVERRIDE=') for line in lines) != 1:
        raise ValueError('Official Java override configuration changed')
    props.write_text('\n'.join('JAVA_HOME_OVERRIDE=' + str(view) if line.startswith('JAVA_HOME_OVERRIDE=')
                               else line for line in lines) + '\n')
    return view


def split(archive, manifest):
    directory = HERE / 'parts'
    directory.mkdir(exist_ok=True)
    rows = []
    with archive.open('rb') as source:
        for index in range(1, 100):
            data = source.read(CHUNK)
            if not data:
                break
            name = f'ghidra-{manifest["version"]}.zip.part-{index:04d}'
            target = directory / name
            sha = hashlib.sha256(data).hexdigest()
            if target.exists():
                if target.stat().st_size != len(data) or digest(target) != sha:
                    raise ValueError('Existing transfer part preserved')
            else:
                with target.open('xb') as out:
                    out.write(data)
            rows.append({'file': name, 'bytes': len(data), 'sha256': sha})
    if sum(x['bytes'] for x in rows) != manifest['bytes']:
        raise ValueError('Split byte total mismatch')
    (HERE / 'transfer-manifest.json').write_text(json.dumps({
        'name': manifest['file'], 'bytes': manifest['bytes'], 'sha256': manifest['sha256'],
        'chunk_bytes': CHUNK, 'parts': rows,
        'reconstruct': 'Concatenate parts in numeric order; verify complete SHA-256 before extracting.',
    }, indent=2) + '\n')
    return len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--parts', action='store_true')
    args = parser.parse_args()
    manifest = json.loads((HERE / 'artifact.json').read_text())
    version = subprocess.run(['java', '-version'], capture_output=True, text=True, check=True)
    if 'version "21.' not in version.stderr + version.stdout or '64-Bit' not in version.stderr + version.stdout:
        raise SystemExit('Pinned Ghidra cohort requires existing64-bit Java21; no automatic JDK download')
    archive, installed = restore(manifest)
    configure_java21_view(installed)
    count = split(archive, manifest) if args.parts else 0
    print(json.dumps({'version': manifest['version'], 'official_archive_pin_verified': True,
                      'headless_launcher': str(installed / 'support/analyzeHeadless'),
                      'transfer_parts': count, 'app_or_original_execution': False}))


if __name__ == '__main__':
    main()
