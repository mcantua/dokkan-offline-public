#!/usr/bin/env python3
"""Select an installed, genuine iOS27.1+ Xcode. Never downloads or accepts licenses."""
import json
import os
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[2]
evidence = root / 'app-installer/cloud-ui/work/evidence'
evidence.mkdir(parents=True, exist_ok=True)
paths = [Path('/Applications/Xcode_27.1.app/Contents/Developer')]
paths += sorted(Path('/Applications').glob('Xcode*.app/Contents/Developer'))
seen, probes, candidates = set(), [], []
def version(text):
    return tuple(int(part) for part in re.findall(r'\d+', text)[:3])
for path in paths:
    if not path.is_dir() or str(path.resolve()) in seen:
        continue
    seen.add(str(path.resolve()))
    env = dict(os.environ, DEVELOPER_DIR=str(path))
    try:
        xcode = subprocess.check_output(['/usr/bin/xcodebuild', '-version'], env=env, text=True, stderr=subprocess.DEVNULL).strip()
        simulator = subprocess.check_output(['/usr/bin/xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version'], env=env, text=True, stderr=subprocess.DEVNULL).strip()
        device = subprocess.check_output(['/usr/bin/xcrun', '--sdk', 'iphoneos', '--show-sdk-version'], env=env, text=True, stderr=subprocess.DEVNULL).strip()
        probe = {'developer_dir': str(path), 'xcode': xcode, 'simulator_sdk': simulator, 'device_sdk': device}
        probes.append(probe)
        if version(simulator) >= (27, 1) and version(device) >= (27, 1):
            candidates.append(probe)
    except subprocess.CalledProcessError:
        probes.append({'developer_dir': str(path), 'ready': False, 'reason': 'Installed toolchain SDK query failed; no license or install changes attempted.'})
selected = next((item for item in candidates if version(item['simulator_sdk']) == (27, 1)), None)
if not selected and candidates:
    selected = max(candidates, key=lambda item: version(item['simulator_sdk']))
report = {'required_minimum_sdk': '27.1', 'selected': selected, 'installed_probes': probes,
 'official_runner_manifest': 'https://github.com/actions/runner-images/blob/09456acd2718d935451373231c236286f861fd9c/images/macos/xcode-27-arm64-Readme.md',
 'sdk_mark_overridden': False, 'sdk_download_or_license_bypass': False}
(evidence / 'toolchain-discovery.json').write_text(json.dumps(report, indent=2) + '\n')
if not selected:
    sys.exit('No installed genuine iOS27.1+ Xcode is ready. See toolchain-discovery.json; refusing an older/synthetic SDK.')
print(selected['developer_dir'])
