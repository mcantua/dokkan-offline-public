#!/usr/bin/env python3
"""Prepare one owned hosted simulator before any App Installer code is installed."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

sys.dont_write_bytecode = True
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--evidence', type=Path, required=True)
args = parser.parse_args()
if sys.platform != 'darwin' or os.environ.get('GITHUB_ACTIONS') != 'true':
    sys.exit('Simulator preparation requires the selected GitHub-hosted Mac job.')
evidence = args.evidence.resolve()
evidence.mkdir(parents=True, exist_ok=True)
report_path = evidence / 'source-report.json'
report = json.loads(report_path.read_text())
frontend = Path(os.environ['DEVELOPER_DIR']) / 'Applications/Simulator.app'
frontend_available = frontend.is_dir()
report['simulator_frontend_mode'] = 'explicit-xcode-bundle' if frontend_available else 'headless-supported-simctl'
report['simulator_frontend_bundle_available'] = frontend_available
attempts = []


def command(argv, log, timeout=60):
    with log.open('wb') as output:
        output.write(('COMMAND ' + ' '.join(map(str, argv)) + '\n').encode())
        output.flush()
        result = subprocess.run(list(map(str, argv)), stdout=output,
                                stderr=subprocess.STDOUT, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f'{argv[0]} exited {result.returncode}; see {log.name}')
    return log.read_text(errors='replace').split('\n', 1)[1].strip()


def version(text):
    return tuple(map(int, re.findall(r'\d+', text)))


inventory = subprocess.check_output(['xcrun', 'simctl', 'list', '-j'], text=True)
(evidence / 'simulator-inventory.json').write_text(inventory)
items = json.loads(inventory)
runtimes = [r for r in items['runtimes'] if r.get('isAvailable')
            and r.get('name', '').startswith('iOS') and version(r['version']) >= (27, 1)]
if not runtimes:
    sys.exit('No available genuine iOS27.1+ simulator runtime.')
runtime = next((r for r in runtimes if version(r['version']) == (27, 1)),
               max(runtimes, key=lambda r: version(r['version'])))
rv = version(runtime['version']) + (0, 0)
encoded_runtime = (rv[0] << 16) | (rv[1] << 8) | rv[2]


def compatible(device):
    return (int(device.get('minRuntimeVersion', 0)) <= encoded_runtime
            <= int(device.get('maxRuntimeVersion', 0xFFFFFFFF)))


devices = [d for d in items['devicetypes'] if compatible(d)]
duo = next((d for d in devices if d.get('name') == 'iPhone Duo'), None)
regular = [d for d in devices if d.get('productFamily') == 'iPhone'
           and 'duo' not in d.get('name', '').lower()]
fallback = max(regular, key=lambda d: (version(d['name']), d['name']), default=None)
for index, device in enumerate([duo, fallback]):
    label = 'duo' if index == 0 else 'regular-iphone-fallback'
    directory = evidence / ('preapp-' + label)
    directory.mkdir(exist_ok=True)
    owned = None
    entry = {'selection': label, 'device_type': device, 'runtime': runtime['identifier'],
             'preapp_only': True, 'physical_hardware_verified': False}
    attempts.append(entry)
    try:
        if not device:
            raise RuntimeError('No compatible ' + label + ' device type is installed.')
        owned = command(['xcrun', 'simctl', 'create',
            'App Installer Preapp ' + os.environ.get('GITHUB_RUN_ID', 'hosted') + ' ' + label,
            device['identifier'], runtime['identifier']], directory / 'create.log')
        if not re.fullmatch(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', owned):
            owned = None
            raise RuntimeError('Creation did not return a valid owned simulator UUID.')
        entry['simulator_id'] = owned
        command(['xcrun', 'simctl', 'boot', owned], directory / 'boot.log')
        if frontend_available:
            command(['open', str(frontend), '--args', '-CurrentDeviceUDID', owned], directory / 'frontend.log')
        else:
            (directory / 'frontend.log').write_text('Selected Xcode has no Simulator.app frontend. Using supported headless simctl boot, bootstatus and UI appearance query; no GUI installation or display mutation.\n')
        command(['xcrun', 'simctl', 'bootstatus', owned, '-b'], directory / 'bootstatus.log', 180)
        appearance = command(['xcrun', 'simctl', 'ui', owned, 'appearance'], directory / 'shell-appearance.log')
        if appearance not in ('light', 'dark'):
            raise RuntimeError('Pre-app shell appearance did not return a supported healthy value.')
        entry['status'] = 'bare-os-ready'
        report.update(simulator_id=owned, simulator_runtime=runtime['identifier'],
            simulator_device_type=device['identifier'], simulator_name=device['name'],
            simulator_preapp_attempts=attempts, simulator_regular_fallback_used=bool(index),
            duo_os_verified=(index == 0), duo_native_tests_verified=False,
            physical_hardware_verified=False, actual_panel_transition_probe_executed=False,
            scope=('Genuine iOS27.1+ hosted ' + device['name'] + ' simulator; default display configuration unchanged. Physical folds unverified.'),
            panel_transition_scope='No panel power/configuration mutations. Duo native tests remain unverified until their actual results; regular fallback never counts as Duo proof.',
            simulator_storage='New owned OS-managed ephemeral hosted CoreSimulator device; caller must shut down and delete this UUID on exit.')
        report_path.write_text(json.dumps(report, indent=2) + '\n')
        print(owned)
        sys.exit(0)
    except Exception as error:
        entry.update(status='preapp-os-failed', error=str(error))
        if owned:
            try:
                command([sys.executable, Path(__file__).with_name('capture-simulator-failure.py'),
                    '--simulator', owned, '--evidence', evidence], directory / 'diagnostics.log', 40)
                failure = evidence / 'simulator-failure'
                if failure.exists():
                    failure.rename(directory / 'simulator-failure')
            except Exception as diagnostic_error:
                entry['diagnostic_error'] = str(diagnostic_error)
            finally:
                for action in ['shutdown', 'delete']:
                    try:
                        command(['xcrun', 'simctl', action, owned], directory / (action + '.log'))
                    except Exception as cleanup_error:
                        entry[action + '_error'] = str(cleanup_error)
        report.update(simulator_preapp_attempts=attempts, duo_os_verified=False,
                      duo_native_tests_verified=False, physical_hardware_verified=False)
        report_path.write_text(json.dumps(report, indent=2) + '\n')
sys.exit('Both supported pre-app simulator OS baselines failed; see preapp evidence.')
