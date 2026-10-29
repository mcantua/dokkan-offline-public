#!/usr/bin/env python3
"""Run one private selected-function headless analysis, never an original app.

Ghidra compiles its small analysis script internally. No Ghidra source build,
app/native game compilation, full-program autoanalysis or external service.
"""
import argparse
import bisect
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PRIVATE = ROOT / 'offline-dokkan/private/ghidra'
SOURCE_SHA = 'efaabfc9b3cdb0e2eeb550b6ea616f5eeb565c6584ad838b765f34539648d222'


def audit_footprint(source, config, output):
    """Account for tail-followed instructions, without another decompile run."""
    sys.path.insert(0, str(ROOT / 'offline-dokkan/tools'))
    sys.path.insert(0, str(ROOT / 'offline-dokkan/original-client/protocol-inspection'))
    from objc_runtime_metadata import Image
    from inspect_handler_fields import function_starts, sections_and_symbols
    raw = source.read_bytes()
    image = Image(raw)
    starts = function_starts(image)
    sections, _, _ = sections_and_symbols(image)
    text, size, _, _ = sections[b'__text']
    ends = dict(zip(starts, starts[1:] + [text + size]))
    reports = []
    for receipt in json.loads((output / 'results.private.json').read_text()):
        bodies = {}
        for address in receipt.get('private_high_pcode_instruction_sites', []):
            site = int(address, 16)
            index = bisect.bisect_right(starts, site) - 1
            start = starts[index] if index >= 0 else None
            end = ends.get(start)
            if start is None or not text <= start <= site < end <= text + size:
                # A followed import thunk can live in __stubs rather than
                # __text. Keep its exact observed instruction identity, never
                # invent a whole function boundary for that site.
                offset = image.offset(site, 4)
                bodies[site] = dict(private_start=site, bytes=4,
                    sha256=hashlib.sha256(raw[offset:offset + 4]).hexdigest(),
                    declared=False, source_text=False, high_pcode_sites=1)
                continue
            if start not in bodies:
                offset = image.offset(start, end - start)
                bodies[start] = dict(private_start=start, bytes=end - start,
                    sha256=hashlib.sha256(raw[offset:offset + end - start]).hexdigest(),
                    declared=any(int(f['address'], 16) == start and f['bytes'] == end - start
                        for f in config['functions']), high_pcode_sites=0)
            bodies[start]['high_pcode_sites'] += 1
        reports.append(dict(label=receipt['label'], observed_source_bodies=list(bodies.values()),
            high_pcode_sites_outside_declared_body=receipt.get('high_pcode_sites_outside_declared_body')))
    (output / 'scope-audit.private.json').write_text(json.dumps(dict(
        source_sha256=SOURCE_SHA, results=reports,
        meaning='Observed instruction sites only; whole callee bodies are not implicitly admitted.'), indent=2) + '\n')
    return sum(not b['declared'] for report in reports for b in report['observed_source_bodies'])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('private_scope', type=Path)
    args = parser.parse_args()
    source = args.source.resolve()
    scope = args.private_scope.resolve()
    if not source.is_file() or source.stat().st_size != 55697728:
        raise SystemExit('Exact admitted prepared engine required')
    with source.open('rb') as stream:
        if hashlib.file_digest(stream, 'sha256').hexdigest() != SOURCE_SHA:
            raise SystemExit('Prepared source identity changed')
    if not scope.is_relative_to(ROOT / 'offline-dokkan/private'):
        raise SystemExit('Scope must stay in private workspace')
    config = json.loads(scope.read_text())
    if config.get('expected_source_sha256') != SOURCE_SHA or not 1 <= len(config.get('functions', [])) <= 8:
        raise SystemExit('Invalid bounded private function scope')
    version = json.loads((HERE / 'artifact.json').read_text())['version']
    launcher = HERE / 'runtime' / ('ghidra_' + version + '_PUBLIC') / 'support/analyzeHeadless'
    if not launcher.is_file():
        raise SystemExit('Run the pinned setup helper first')
    projects, logs, base_output, user = [PRIVATE / name for name in ('projects', 'logs', 'decompiled', 'user')]
    cohort_name = scope.stem.replace('.private', '')
    if not cohort_name.replace('-', '').replace('_', '').isalnum():
        raise SystemExit('Invalid private cohort name')
    output = base_output / cohort_name
    for directory in (projects, logs, output, user):
        directory.mkdir(parents=True, exist_ok=True)
    name = 'original-auth-scoped'
    existing = (projects / (name + '.gpr')).exists()
    command = [str(launcher), str(projects), name]
    command += ['-process', source.name] if existing else ['-import', str(source), '-loader-loadLibraries', 'false']
    command += ['-noanalysis', '-max-cpu', '2', '-scriptPath', str(HERE / 'scripts'),
                '-postScript', 'ScopedAuthDecompile.java', str(scope), str(output),
                '-log', str(logs / 'application.log'), '-scriptlog', str(logs / 'script.log')]
    environment = os.environ.copy()
    environment['JAVA_TOOL_OPTIONS'] = (environment.get('JAVA_TOOL_OPTIONS', '') +
        ' -Duser.home=' + str(user) + ' -Djava.awt.headless=true').strip()
    print(json.dumps({'status': 'running scoped static tool', 'selected_functions': len(config['functions']),
                      'reuses_import': existing, 'full_autoanalysis': False, 'original_execution': False}), flush=True)
    started_ns = time.time_ns()
    with (logs / 'headless.log').open('ab') as log:
        try:
            process = subprocess.run(command, cwd=ROOT, env=environment, stdout=log, stderr=log,
                                     timeout=600, check=False)
            result = process.returncode
        except subprocess.TimeoutExpired:
            result = 'bounded-tool-timeout'
    cohort = output / 'cohort.private.json'
    completed = None
    fresh_cohort = result == 0 and cohort.exists() and cohort.stat().st_mtime_ns >= started_ns
    if fresh_cohort:
        completed = sum(x.get('completed', False) for x in json.loads(cohort.read_text()).get('selected_results', []))
    undeclared_footprints = audit_footprint(source, config, output) if completed else None
    print(json.dumps({'headless_exit': result, 'private_cohort_written': fresh_cohort,
                      'decompiled_functions': completed, 'original_execution': False,
                      'tail_followed_undeclared_body_observations': undeclared_footprints,
                      'app_or_native_game_build': False}), flush=True)


if __name__ == '__main__':
    main()
