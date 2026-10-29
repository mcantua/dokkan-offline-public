#!/usr/bin/env python3
"""Collect bounded diagnostics from this fresh, account-free hosted simulator job."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--simulator', required=True)
parser.add_argument('--evidence', type=Path, required=True)
args = parser.parse_args()
if sys.platform != 'darwin' or os.environ.get('GITHUB_ACTIONS') != 'true':
    raise SystemExit('Diagnostics are restricted to the selected hosted Mac job.')
out = args.evidence / 'simulator-failure'
out.mkdir(parents=True, exist_ok=True)
start = (args.evidence / 'source-report.json').stat().st_mtime
reports = Path.home() / 'Library/Logs/DiagnosticReports'
selected = []
for path in sorted(reports.glob('*.ips'), key=lambda p: p.stat().st_mtime, reverse=True):
    if len(selected) >= 8:
        break
    if (path.name.startswith(('AppInstaller-', 'SpringBoard-', 'backboardd-', 'Simulator-'))
            and not path.is_symlink() and path.stat().st_mtime >= start
            and path.stat().st_size <= 2 * 1024 * 1024):
        shutil.copy2(path, out / path.name)
        selected.append(path.name)
try:
    result = subprocess.run(['xcrun', 'simctl', 'spawn', args.simulator, 'log', 'show',
        '--last', '1m', '--style', 'compact', '--predicate',
        'process == "SpringBoard" OR process == "AppInstaller"'],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20)
    (out / 'recent-process-log.txt').write_bytes(result.stdout[:8 * 1024 * 1024])
except subprocess.TimeoutExpired:
    (out / 'recent-process-log.txt').write_text('Owned simulator log query timed out.\n')
(out / 'scope.json').write_text(json.dumps({'hosted_job_only': True,
    'physical_device_used': False, 'apple_account_used': False,
    'selected_current_job_crash_reports': selected}, indent=2) + '\n')
