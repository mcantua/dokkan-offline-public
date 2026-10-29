#!/usr/bin/env python3
"""Owned Duo simulator display-power driver for XCTest, using documented simctl IO.

Only TEST-ONLY phase/nonce files are exchanged through the fresh app's Documents.
No account data is read, no private hinge APIs are called, no physical device is used.
"""
import argparse
import json
from pathlib import Path
import re
import signal
import subprocess
import time


def parse_screens(text):
    """Parse the Connected Screens + Display ports format observed in discovery40727203024."""
    ports = re.split(r'(?m)^Port:\s*$', text)
    powers = {}
    for port in ports:
        def field(name):
            match = re.search(r'^    ' + re.escape(name) + r':\s*(.+)$', port, re.M)
            return match.group(1).strip() if match else None
        if field('Class') == 'Display' and field('Display class') == '0':
            width, height, power = field('Default width'), field('Default height'), field('Power state')
            if width and height and width.isdecimal() and height.isdecimal() and power in ('On', 'Off'):
                powers[(int(width), int(height))] = power == 'On'
    screens = []
    for match in re.finditer(r'^    \(\d+\) [^\n]+:\n(.*?)(?=^    \(\d+\) |^Port:|\Z)', text, re.M | re.S):
        block = match.group(1)
        def field(name):
            item = re.search(r'^        ' + re.escape(name) + r':\s*(.+)$', block, re.M)
            return item.group(1).strip() if item else None
        if field('Screen Type') != 'Integrated':
            continue
        screen_id, name, device = field('Screen ID'), field('Name'), field('Device Name')
        size = re.fullmatch(r'\{(\d+),\s*(\d+)\}', field('Pixel Size') or '')
        scale = field('Preferred UI Scale')
        if not screen_id or not screen_id.isdecimal() or not size or not scale or not scale.isdecimal():
            raise ValueError('An integrated screen has an unsupported descriptor format.')
        pixels = tuple(map(int, size.groups()))
        if pixels not in powers:
            raise ValueError('Integrated screen power could not be matched to its display port.')
        screens.append({'id': screen_id, 'name': name, 'device': device, 'pixels': list(pixels),
                        'scale': int(scale), 'power_on': powers[pixels]})
    if len(screens) != 2 or sum(item['device'] == 'primary' for item in screens) != 1:
        raise ValueError('Exactly two integrated Duo screens and one primary descriptor are required.')
    return screens


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--simulator', required=True)
    parser.add_argument('--bundle-id', required=True)
    parser.add_argument('--evidence', type=Path, required=True)
    args = parser.parse_args()
    evidence = args.evidence / 'display-transitions'
    evidence.mkdir(parents=True, exist_ok=True)
    stopped = False
    def stop(_signum, _frame):
        nonlocal stopped
        stopped = True
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    def run(*operation):
        return subprocess.check_output(['xcrun', 'simctl', *operation], text=True, stderr=subprocess.PIPE, timeout=30)
    def enumerate_to(name):
        raw = run('io', args.simulator, 'enumerate')
        (evidence / f'{name}.txt').write_text(raw)
        return parse_screens(raw)
    def power(screen, on):
        run('io', args.simulator, 'screenConfig', f'--display={screen["id"]}', 'power', 'on' if on else 'off')
    def write(path, value):
        pending = path.with_suffix('.pending')
        pending.write_text(json.dumps(value, indent=2) + '\n')
        pending.replace(path)
    original = []
    try:
        original = enumerate_to('initial')
        primary = next(item for item in original if item['device'] == 'primary')
        secondary = next(item for item in original if item['device'] != 'primary')
        # Start the app with only the descriptor-labelled primary panel powered.
        power(primary, True)
        power(secondary, False)
        baseline = enumerate_to('baseline')
        write(evidence / 'ready.json', {'status': 'ready', 'scope': 'Owned simulator power controls; not hinge or physical hardware', 'screens': baseline})
        deadline, seen = time.monotonic() + 900, set()
        while not stopped and time.monotonic() < deadline:
            try:
                container = Path(run('get_app_container', args.simulator, args.bundle_id, 'data').strip())
                directory = container / 'Documents' / 'CloudDisplayControl'
                request_path = directory / 'request.json'
                if not request_path.is_file():
                    time.sleep(0.5)
                    continue
                request = json.loads(request_path.read_text())
                nonce, phase = request.get('nonce'), request.get('phase')
                if not isinstance(nonce, str) or not re.fullmatch(r'[A-Za-z0-9-]{1,64}', nonce) or nonce in seen:
                    time.sleep(0.2)
                    continue
                seen.add(nonce)
                if phase not in ('switch_secondary', 'restore_primary'):
                    raise ValueError('Unsupported test display phase.')
                response = {'nonce': nonce, 'phase': phase, 'scope': 'Actual owned simulator documented screenConfig power API; not hardware folding'}
                before = enumerate_to(f'{len(seen):02}-{phase}-before')
                target, other = (secondary, primary) if phase == 'switch_secondary' else (primary, secondary)
                try:
                    power(target, True)
                    power(other, False)
                    after = enumerate_to(f'{len(seen):02}-{phase}-after')
                    matching = {item['id']: item['power_on'] for item in after}
                    accepted = matching.get(target['id']) is True and matching.get(other['id']) is False
                    response.update(status='ok' if accepted else 'unverified', before=before, after=after,
                                    target_screen=target, power_state_confirmed=accepted)
                except (subprocess.SubprocessError, ValueError) as error:
                    response.update(status='error', reason=type(error).__name__ + ': documented display operation failed')
                write(evidence / f'{len(seen):02}-{phase}.json', response)
                write(directory / 'response.json', response)
                # Reply before optional framebuffer capture so XCTest never waits on a slow screenshot.
                for screen in response.get('after', []):
                    if not screen['power_on']:
                        continue
                    try:
                        run('io', args.simulator, 'screenshot', f'--display={screen["id"]}', str(evidence / f'{len(seen):02}-{phase}-display-{screen["id"]}.png'))
                    except subprocess.SubprocessError:
                        pass
            except subprocess.CalledProcessError:
                time.sleep(0.5)  # The test host app has not yet been installed by xcodebuild.
            except (OSError, ValueError, json.JSONDecodeError):
                time.sleep(0.2)
    except (subprocess.SubprocessError, ValueError) as error:
        write(evidence / 'ready.json', {'status': 'error', 'reason': str(error) if isinstance(error, ValueError) else 'Documented IO discovery/power command failed.'})
        raise
    finally:
        for screen in original:
            try:
                power(screen, screen['power_on'])
            except subprocess.SubprocessError:
                pass

if __name__ == '__main__':
    main()
