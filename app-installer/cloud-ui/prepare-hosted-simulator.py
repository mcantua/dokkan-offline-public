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


inventory = subprocess.check_output(['xcrun', 'simctl', 'list', '-j'], text=True, timeout=60)
(evidence / 'simulator-inventory.json').write_text(inventory)
items = json.loads(inventory)
runtimes = [r for r in items['runtimes'] if r.get('isAvailable')
            and r.get('name', '').startswith('iOS') and version(r['version']) >= (27, 1)]
if not runtimes:
    sys.exit('No available genuine iOS27.1+ simulator runtime.')
runtime = next((r for r in runtimes if version(r['version']) == (27, 1)),
               max(runtimes, key=lambda r: version(r['version'])))
def supported_devices(selected_runtime):
    rv = version(selected_runtime['version']) + (0, 0)
    encoded = (rv[0] << 16) | (rv[1] << 8) | rv[2]
    # A model's min/max range is insufficient: the Duo27.1 runtime explicitly
    # excludes regular iPhones even though their version ranges include27.1.
    supported = {d['identifier'] for d in selected_runtime.get('supportedDeviceTypes', [])}
    return [d for d in items['devicetypes'] if d['identifier'] in supported
            and int(d.get('minRuntimeVersion', 0)) <= encoded
            <= int(d.get('maxRuntimeVersion', 0xFFFFFFFF))]


def regular_phone(selected_runtime):
    phones = [d for d in supported_devices(selected_runtime)
              if d.get('productFamily') == 'iPhone' and 'duo' not in d.get('name', '').lower()]
    return max(phones, key=lambda d: (version(d['name']), d['name']), default=None)


devices = supported_devices(runtime)
duo = next((d for d in devices if d.get('name') == 'iPhone Duo'), None)
selections = [('duo', duo, runtime), ('regular-iphone-fallback', regular_phone(runtime), runtime)]
# This exact hosted runtime failed migration before any app in run40916969403.
# Only the selected Files/schema and labelled geometry-fixture checks may use regular27.0
# runtime. Compilation still uses genuine SDK27.1+; this is never Duo/UI proof.
component_runtime = next((r for r in items['runtimes'] if r.get('isAvailable')
                          and r.get('name', '').startswith('iOS')
                          and version(r['version']) == (27, 0) and regular_phone(r)), None)
if (os.environ.get('AI_NATIVE_TEST_SCOPE') == 'pairing-public'
        and runtime.get('buildversion') == '24A94425' and version(runtime['version']) == (27, 1)
        and component_runtime):
    selections = [('regular-iphone-component-fallback', regular_phone(component_runtime), component_runtime)]
    report['native_component_runtime_fallback'] = {
        'prior_run_id': 40916969403, 'prior_runtime_build': '24A94425',
        'reason': 'Duo27.1 terminal data migration failure and unavailable shell before any app. '
                  'Its supported-device list excludes regular iPhones.',
        'checks': ['coordinated Files reads', 'pinned record/discovery metadata guards',
                   'responsive UIKit geometry fixtures (not physical Duo geometry)'],
        'runtime_version': '27.0', 'duo_runtime_verified': False,
        'os27_1_runtime_verified': False, 'sdk_minimum_unchanged': '27.1',
        'scope': 'Generic component checks only; no Duo display/fold/physical-device claim.'}
for label, device, runtime in selections:
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
            (directory / 'frontend.log').write_text('Selected Xcode has no Simulator.app frontend. Using supported headless simctl boot/bootstatus; shell query/test-host handling recorded separately. No GUI installation or display mutation.\n')
        bootstatus = command(['xcrun', 'simctl', 'bootstatus', owned, '-b'], directory / 'bootstatus.log', 180)
        if 'Data Migration Failed' in bootstatus or re.search(r'Status=3\b', bootstatus):
            raise RuntimeError('Simulator reported terminal data migration failure despite process exit0.')
        managed_components = (os.environ.get('AI_NATIVE_TEST_SCOPE') == 'pairing-public'
                              and label == 'regular-iphone-component-fallback')
        if managed_components:
            (directory / 'shell-appearance.log').write_text('Not queried: this headless heuristic timed out in run40919528305. Xcode-managed test-host launch and the actual selected XCTest results decide native success.\n')
            entry.update(status='booted-shell-unconfirmed', shell_appearance_verified=False,
                         xcode_managed_test_host_required=True)
        else:
            appearance = command(['xcrun', 'simctl', 'ui', owned, 'appearance'], directory / 'shell-appearance.log')
            if appearance not in ('light', 'dark'):
                raise RuntimeError('Pre-app shell appearance did not return a supported healthy value.')
            entry.update(status='bare-os-ready', shell_appearance_verified=True)
        report.update(simulator_id=owned, simulator_runtime=runtime['identifier'],
            simulator_device_type=device['identifier'], simulator_name=device['name'],
            simulator_preapp_attempts=attempts, simulator_regular_fallback_used=(label != 'duo'),
            native_component_runtime=runtime['version'],
            production_launch_preflight=False if managed_components else None,
            os27_1_runtime_verified=(version(runtime['version']) >= (27, 1)),
            duo_os_verified=(label == 'duo'), duo_native_tests_verified=False,
            physical_hardware_verified=False, actual_panel_transition_probe_executed=False,
            scope=('Genuine SDK27.1+ compilation; hosted iOS' + runtime['version'] + ' ' + device['name']
                   + ' simulator. Default display configuration unchanged. '
                   + ('Generic component checks only; Duo runtime/display unverified. ' if label != 'duo' else '')
                   + 'Physical folds unverified.'),
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
sys.exit('The selected supported pre-app simulator OS baseline(s) failed; see preapp evidence.')
