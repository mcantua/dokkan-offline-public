#!/usr/bin/env python3
"""Reuse saved passing Rust checks only for identical inputs and hosted context.

A mismatch returns 1, asking the caller to run the checks normally. This helper
never creates baseline proof or represents reused results as a fresh test run.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

PREFIXES = ('app-installer/core/', 'downloads/isideload/isideload-0.5.0/',
            'downloads/idevice/idevice-0.1.68/', 'downloads/apple-trust/')
EXPECTED_CONTEXT = {'os': 'Darwin', 'architecture': 'arm64',
                    'rustc_prefix': 'rustc 1.99.1 ',
                    'xcode': 'Xcode 27.1\nBuild version 27A9275'}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args], stderr=subprocess.DEVNULL)


def committed_files(repo, commit):
    entries = git(repo, 'ls-tree', '-r', '-z', commit, '--', *PREFIXES).split(b'\0')
    blobs = []
    for entry in filter(None, entries):
        metadata, path = entry.split(b'\t', 1)
        mode, kind, identity = metadata.split()
        if mode not in (b'100644', b'100755') or kind != b'blob':
            raise ValueError('Source contains unsupported Git entry')
        blobs.append((path.decode('utf-8'), identity))
    if not blobs:
        raise ValueError('Source commit has no selected files')
    # One local Git process, preserving exact bytes without checkout/network.
    response = subprocess.run(['git', '-C', str(repo), 'cat-file', '--batch'],
                              input=b''.join(identity + b'\n' for _, identity in blobs),
                              stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=True).stdout
    result = {}
    offset = 0
    for path, identity in blobs:
        end = response.index(b'\n', offset)
        returned, kind, size = response[offset:end].split()
        if returned != identity or kind != b'blob':
            raise ValueError('Source Git object mismatch')
        size = int(size)
        start = end + 1
        data = response[start:start + size]
        if len(data) != size or response[start + size:start + size + 1] != b'\n':
            raise ValueError('Truncated source Git object')
        result[path] = sha(data)
        offset = start + size + 1
    if offset != len(response):
        raise ValueError('Unexpected Git output')
    return result


def current_files(repo):
    # Nonignored new files are also inputs: Cargo discovers new modules/build
    # files. Ignored target directories remain outside this tracked closure.
    paths = git(repo, 'ls-files', '-z', '--cached', '--others', '--exclude-standard',
                '--', *PREFIXES).decode('utf-8').split('\0')
    result = {}
    for path in filter(None, paths):
        file = repo / path
        if file.is_symlink() or not file.is_file():
            raise ValueError('Current input is missing or not a regular file')
        result[path] = sha(file.read_bytes())
    return result


def runtime_context():
    def command(*args):
        return subprocess.check_output(args, text=True, stderr=subprocess.DEVNULL).strip()
    return {'os': command('uname', '-s'), 'architecture': command('uname', '-m'),
            'rustc_version': command('rustc', '--version'),
            'xcode': command('xcodebuild', '-version')}


def verify(repo, proof, context):
    manifest_bytes = (proof / 'manifest.json').read_bytes()
    manifest = json.loads(manifest_bytes)
    if manifest.get('schema_version') != 1 or manifest.get('prefixes') != list(PREFIXES):
        raise ValueError('Proof schema or selected inputs differ')
    commit = manifest['source_commit']
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise ValueError('Invalid proof source commit')
    if not re.fullmatch(r'https://github\.com/mcantua/claude-chatg/actions/runs/[1-9][0-9]*',
                        manifest['workflow_run_url']):
        raise ValueError('Missing original hosted workflow provenance')
    if manifest.get('context') != EXPECTED_CONTEXT:
        raise ValueError('Unsupported proof execution context')
    for key in ('os', 'architecture', 'xcode'):
        if context.get(key) != EXPECTED_CONTEXT[key]:
            raise ValueError('Execution context changed')
    if not context.get('rustc_version', '').startswith(EXPECTED_CONTEXT['rustc_prefix']):
        raise ValueError('Rust compiler changed')
    files = manifest['files']
    if not isinstance(files, list) or not files:
        raise ValueError('Missing proof input list')
    declared = {}
    for item in files:
        path, digest = item['path'], item['sha256']
        if (path in declared or not path.startswith(PREFIXES)
                or not re.fullmatch(r'[0-9a-f]{64}', digest)):
            raise ValueError('Invalid proof input entry')
        declared[path] = digest
    if declared != current_files(repo):
        raise ValueError('Rust input closure or bytes changed')
    # Hosted checkout is shallow. The committed proof and exact current file
    # closure suffice; additionally check the old tree when locally available.
    old_available = subprocess.run(['git', '-C', str(repo), 'cat-file', '-e', commit + '^{commit}'],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    if old_available and declared != committed_files(repo, commit):
        raise ValueError('Proof does not match the available original source tree')
    logs = {}
    for name, expected_count, filtered, filename in (
            ('core', 19, 0, 'coretests.log'),
            ('tls', 2, 5, 'tls-tests.log'),
            ('installation_response', 1, 7, 'installation-response-tests.log')):
        check = manifest['checks'][name]
        if (check.get('passed') != expected_count or check.get('failed') != 0
                or check.get('log') != filename):
            raise ValueError('Proof success counts differ')
        data = (proof / filename).read_bytes()
        if sha(data) != check.get('sha256'):
            raise ValueError('Raw test log digest mismatch')
        text = data.decode('utf-8')
        summaries = re.findall(r'^test result: (.+)$', text, re.M)
        expected = (rf'ok\. {expected_count} passed; 0 failed; 0 ignored; 0 measured; '
                    rf'{filtered} filtered out; finished in [0-9.]+s')
        passed = re.findall(r'^test ([^\n]+) \.\.\. ok$', text, re.M)
        if (len(summaries) != 1 or not re.fullmatch(expected, summaries[0])
                or len(passed) != expected_count or len(set(passed)) != expected_count
                or re.search(r'^error(?:\[|:)|^test .* \.\.\. FAILED$', text, re.M)):
            raise ValueError('Raw log does not prove the required successful checks')
        logs[filename] = data
    source_bytes = (proof / 'source-report.json').read_bytes()
    source = json.loads(source_bytes)
    if (source.get('source_commit') != commit or source.get('architecture') != 'arm64'
            or source.get('xcode') != EXPECTED_CONTEXT['xcode']
            or source.get('rust_target') != 'aarch64-apple-ios-sim'
            or source.get('simulator_sdk') != '27.1'):
        raise ValueError('Original hosted source report differs')
    return manifest, {'manifest.json': manifest_bytes, 'source-report.json': source_bytes, **logs}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--proof', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        repo, proof, output = args.repo.resolve(), args.proof.resolve(), args.output.resolve()
        if proof == output or proof.is_relative_to(output) or output.is_relative_to(proof):
            raise ValueError('Proof and evidence output must be separate')
        context = runtime_context()
        manifest, files = verify(repo, proof, context)
        output.mkdir(parents=True, exist_ok=True)
        for name, data in files.items():
            (output / name).write_bytes(data)
        report = {'schema_version': 1, 'reused': True, 'new_test_execution': False,
                  'original_source_commit': manifest['source_commit'],
                  'current_source_commit': git(repo, 'rev-parse', 'HEAD').decode().strip(),
                  'original_workflow_run_url': manifest['workflow_run_url'],
                  'verified_input_count': len(manifest['files']),
                  'checks': manifest['checks'], 'current_context': context,
                  'scope': 'Reused unchanged Rust core/TLS/installation-response checks only. Native execution and physical acceptance require their own evidence.'}
        (output / 'reuse-report.json').write_text(json.dumps(report, indent=2) + '\n')
    except Exception:
        print('Saved Rust proof is not reusable; run the current Rust checks.', file=sys.stderr)
        return 1
    print('Reused verified prior 19 core + 2 TLS + 1 installation-response successes; no new Rust test execution.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
