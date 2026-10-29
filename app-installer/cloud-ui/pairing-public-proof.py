#!/usr/bin/env python3
"""Record/reuse only the new public pairing checks; never compile or contact devices."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tempfile
import zipfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
REPOSITORY = 'mcantua/dokkan-offline-public'
BRANCH = 'chatgpt/app-installer-pairing-repair'
WORKFLOW = 400819284
ARTIFACT = 'app-installer-pairing-public-proof'
EVIDENCE = ROOT / 'app-installer/cloud-ui/work/evidence'
PROOF = EVIDENCE / 'pairing-proof'
COMMON = ('.github/workflows/app-installer-cloud-ui.yml', 'app-installer/cloud-ui/run.sh',
          'app-installer/cloud-ui/pairing-public-proof.py')
PREFIXES = {
    'vendor': ('downloads/idevice/idevice-0.1.68/',),
    'helper': ('downloads/idevice/idevice-0.1.68/',),
    'transport': ('app-installer/core/', 'downloads/idevice/idevice-0.1.68/',
                  'downloads/isideload/isideload-0.5.0/', 'downloads/apple-trust/'),
    'recovery': ('app-installer/core/', 'downloads/idevice/idevice-0.1.68/',
                 'downloads/isideload/isideload-0.5.0/', 'downloads/apple-trust/'),
    'native': ('app-installer/ios/', 'app-installer/core/', 'downloads/isideload/isideload-0.5.0/',
               'downloads/idevice/idevice-0.1.68/', 'downloads/apple-trust/',
               'app-installer/cloud-ui/Tests/', 'app-installer/cloud-ui/project.yml',
               'app-installer/cloud-ui/select-xcode.py', 'app-installer/cloud-ui/prepare-hosted-simulator.py'),
}
RUST = {
    'rust-authentication.log': [
        'remote_pairing::authentication_tests::authenticated_m6_requires_exact_identity_and_valid_signature',
        'remote_pairing::authentication_tests::m6_aead_failure_is_an_error_and_long_identity_fragments_authenticate',
        'remote_pairing::authentication_tests::pair_verify_m2_checks_pin_signature_and_both_ephemerals',
        'remote_pairing::authentication_tests::short_or_non_ascii_pin_is_rejected_without_slicing',
        'remote_pairing::authentication_tests::message_state_and_cryptographic_field_lengths_fail_closed'],
    'rust-record.log': ['remote_pairing::rp_pairing_file::tests::pinned_v2_round_trip_and_legacy_rejection',
                        'remote_pairing::rp_pairing_file::tests::invalid_keys_identifiers_and_version_fail_closed'],
    'rust-tlv.log': ['remote_pairing::tlv::tests::pairing_fields_use_canonical_fragments_and_reject_ambiguous_values'],
}
RUST = {
    'vendor': {'rust-pairing.log': [method for methods in RUST.values() for method in methods]},
    'helper': {'rust-helper.log': ['tests::explicit_arguments_and_plan_have_no_device_actions',
                                 'tests::private_export_never_replaces_existing_file_or_symlink']},
    'transport': {'rust-transport.log': [
        'engine::transport::tests::public_remote_transport_psk_requires_matching_secret_and_real_tls_finished',
        'engine::transport::tests::public_remote_transport_tunnel_frames_are_bounded_and_preserve_following_ip_bytes']},
    'recovery': {'rust-recovery.log': [
        'engine::tests::recovery_failed_first_install_keeps_latest_input_after_empty_lookup_and_restart',
        'engine::tests::recovery_refresh_continues_local_failures_but_stops_auth_cancel_or_uncertain_install']},
}
NATIVE = ['PairingDocumentReadTests testCoordinatedPairingDocumentAcceptsMaterializedBytesAndRejectsUnsafeReads']
if os.environ.get('AI_NATIVE_TEST_SCOPE') == 'pairing-public':
    NATIVE.append('PairingConnectionGuardTests testPinnedFormatAndDiscoveryMetadataRejectMixedOrUnpinnedInputs')
    NATIVE.append('AppInstallerCloudUITests test02ResponsiveMainUsesLabelledTestOnlyFixture')
FEATURES = {'vendor': ['--no-default-features', '--features', 'ring,remote_pairing'],
            'helper': ['--no-default-features', '--features', 'app-installer-rp-bootstrap'],
            'transport': ['production core Cargo.toml default features'],
            'recovery': ['production core Cargo.toml default features'],
            'native': [os.environ.get('AI_NATIVE_TEST_SCOPE', 'pairing-document')]}

SUFFIXES = {'.rs', '.toml', '.lock', '.m', '.h', '.c', '.cc', '.cpp', '.plist', '.png', '.cer', '.yml', '.py', '.sh'}


def sha(data): return hashlib.sha256(data).hexdigest()


def require(value, message):
    if not value: raise ValueError(message)


def command(*args):
    return subprocess.check_output(list(map(str, args)), cwd=ROOT, text=True, stderr=subprocess.PIPE).strip()


def guard():
    require(ROOT.name == 'dokkan-offline-public' and os.environ.get('GITHUB_REPOSITORY') == REPOSITORY
            and os.environ.get('GITHUB_ACTIONS') == 'true'
            and os.environ.get('GITHUB_REF_NAME') == BRANCH, 'Public repair workflow context required')


def inputs(group):
    names = command('git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard', '--',
                    *PREFIXES[group], *COMMON).split('\0')
    result = {}
    for name in sorted(set(filter(None, names))):
        p = ROOT / name
        if any(part in {'target', 'work', '__pycache__'} for part in PurePosixPath(name).parts): continue
        if p.suffix not in SUFFIXES: continue
        require(p.is_file() and not p.is_symlink(), 'Proof input missing or not regular')
        result[name] = sha(p.read_bytes())
    require(bool(result) and all(name in result for name in COMMON), 'Proof source closure missing')
    return result


def context():
    return {'os': sys.platform, 'architecture': os.uname().machine,
            'rustc': command('rustc', '--version'), 'xcode': command('xcodebuild', '-version'),
            'macos_sdk': command('xcrun', '--sdk', 'macosx', '--show-sdk-version'),
            'simulator_sdk': command('xcrun', '--sdk', 'iphonesimulator', '--show-sdk-version')}


def logs_for(group): return ['native.log'] if group == 'native' else list(RUST[group])


def verify_logs(group, files):
    if group != 'native':
        for name, expected in RUST[group].items():
            value = files[name].decode('utf-8')
            passed = re.findall(r'^test ([^\n]+) \.\.\. ok$', value, re.M)
            summaries = re.findall(r'^test result: (.+)$', value, re.M)
            require(sorted(passed) == sorted(expected) and len(passed) == len(set(passed)), 'Wrong Rust method selection')
            require(len(summaries) == 1 and re.fullmatch(
                rf'ok\. {len(expected)} passed; 0 failed; 0 ignored; 0 measured; \d+ filtered out; finished in [0-9.]+s', summaries[0]),
                'Selected Rust methods did not all pass')
            require(not re.search(r'^error(?:\[|:)|^test .* \.\.\. FAILED$', value, re.M), 'Rust log reports a failure')
        return sum(len(methods) for methods in RUST[group].values())
    value = files['native.log'].decode('utf-8')
    passed = re.findall(r"Test Case '-\[([^\]]+)\]' passed \([0-9.]+ seconds\)\.", value)
    require(sorted(passed) == sorted(NATIVE) and not re.search(r"Test Case .* failed|\*\* TEST .* FAILED", value), 'Wrong native method/result')
    counts = re.findall(r'Executed (\d+) tests?, with (\d+) failures?', value)
    require((str(len(NATIVE)), '0') in counts
            and all(1 <= int(number) <= len(NATIVE) and failed == '0' for number, failed in counts),
            'Native aggregate/class summaries differ from exact selected passing methods')
    return len(NATIVE)


def snapshot(group):
    guard(); PROOF.mkdir(parents=True, exist_ok=True)
    record = {'schema_version': 1, 'repository': REPOSITORY, 'branch': BRANCH, 'workflow_id': WORKFLOW,
              'run_id': int(os.environ['GITHUB_RUN_ID']), 'source_commit': command('git', 'rev-parse', 'HEAD'),
              'group': group, 'features': FEATURES[group], 'inputs': inputs(group), 'context': context()}
    (PROOF / (group + '-before.json')).write_text(json.dumps(record, indent=2) + '\n')


def finish(group):
    guard(); record = json.loads((PROOF / (group + '-before.json')).read_text())
    require(record['inputs'] == inputs(group) and record['context'] == context(), 'Inputs/context changed during selected checks')
    files = {name: (PROOF / name).read_bytes() for name in logs_for(group)}
    count = verify_logs(group, files)
    record.update(passed=count, failed=0, inputs_unchanged=True, test_fixture=False,
                  logs={name: {'bytes': len(data), 'sha256': sha(data)} for name, data in files.items()},
                  scope={'vendor': 'Only eight new vendor cryptographic/record/TLV methods; standalone ring,remote_pairing feature graph.',
                         'helper': 'Only two explicit helper argument/private-file methods; no USB or account action.',
                         'transport': 'Only two production PSK/tunnel/teardown methods with synthetic peers and cloud loopback; no external service or phone.',
                         'recovery': 'Only two production install-source/refresh recovery methods; synthetic service boundaries, no account or phone.',
                         'native': 'Only selected nonsecret Files/schema and labelled responsive geometry fixtures; no real provider, Keychain account, phone pairing or physical Duo proof.'}[group])
    (PROOF / (group + '.json')).write_text(json.dumps(record, indent=2) + '\n')
    print(f'Recorded {group}: {count} new public checks passed; exact pre/post source and raw logs saved.')


def api(path):
    try: return json.loads(command('gh', 'api', 'repos/' + REPOSITORY + path))
    except (subprocess.CalledProcessError, json.JSONDecodeError): raise ValueError('Public proof API request failed safely') from None


def compare_inputs(record, group, current):
    previous = record.get('inputs')
    if previous == current: return []
    # Reviewed harness-only migrations. Every production input still has to
    # match exactly; native results never inherit these Rust exceptions.
    approved = {'vendor': (40916969403, '24f2809c3001c474d0ea885afc1aef00aa388fd0'),
                'helper': (40916969403, '24f2809c3001c474d0ea885afc1aef00aa388fd0'),
                'transport': (40926780346, '80f5e35efbefc7299fe1fd20b4e00b7a86a968ca'),
                'recovery': (40926780346, '80f5e35efbefc7299fe1fd20b4e00b7a86a968ca')}
    require(group in approved and (record.get('run_id'), record.get('source_commit')) == approved[group],
            'Source changes require new affected checks')
    require(isinstance(previous, dict) and set(previous) == set(current), 'Proof input inventory changed')
    changed = [name for name in current if current[name] != previous[name]]
    require(set(changed) <= set(COMMON),
            'Production source, features or workflow changed')
    # Bind old recipe bytes to the actual original public run commit, rather
    # than trusting an artifact's self-declared harness hashes.
    for name in COMMON:
        entry = api('/contents/' + name + '?ref=' + record['source_commit'])
        require(entry.get('type') == 'file' and entry.get('encoding') == 'base64'
                and 0 < entry.get('size', 0) <= 256 * 1024, 'Original harness source missing')
        content = base64.b64decode(entry['content'])
        require(len(content) == entry['size'] and sha(content) == previous[name],
                'Original harness differs from actual public run source')
    return [{'path': name, 'original_sha256': previous[name], 'current_sha256': current[name]} for name in changed]


def reuse(group, run_id):
    guard(); require(re.fullmatch(r'[1-9][0-9]*', run_id) is not None, 'Invalid public proof run ID')
    run = api('/actions/runs/' + run_id)
    require(run.get('workflow_id') == WORKFLOW and run.get('status') == 'completed'
            and run.get('conclusion') in {'success', 'failure'} and run.get('event') == 'workflow_dispatch'
            and run.get('head_branch') == BRANCH and run.get('path') == '.github/workflows/app-installer-cloud-ui.yml'
            and run.get('repository', {}).get('full_name') == REPOSITORY
            and run.get('head_repository', {}).get('full_name') == REPOSITORY, 'Proof is not from this public repair workflow')
    found = [a for a in api('/actions/runs/' + run_id + '/artifacts?per_page=100')['artifacts'] if a['name'] == ARTIFACT and a.get('expired') is False]
    require(len(found) == 1, 'One current public proof artifact required')
    artifact = found[0]
    require(0 < artifact['size_in_bytes'] <= 4 * 1024 * 1024 and re.fullmatch(r'sha256:[0-9a-f]{64}', artifact.get('digest', '')), 'Proof artifact bounds/digest missing')
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='public-proof-', dir=EVIDENCE.parent) as temporary:
        archive = Path(temporary) / 'proof.zip'
        with archive.open('wb') as output:
            result = subprocess.run(['gh', 'api', 'repos/' + REPOSITORY + '/actions/artifacts/' + str(artifact['id']) + '/zip'],
                                    cwd=ROOT, stdout=output, stderr=subprocess.PIPE)
        require(result.returncode == 0 and archive.stat().st_size == artifact['size_in_bytes']
                and 'sha256:' + sha(archive.read_bytes()) == artifact['digest'], 'Public proof archive transfer differs')
        wanted = [group + '.json', *logs_for(group)]
        with zipfile.ZipFile(archive) as z:
            infos = z.infolist(); require(len(infos) <= 24 and len({i.filename for i in infos}) == len(infos), 'Proof archive duplicate/count limit')
            require(sum(i.file_size for i in infos) <= 8 * 1024 * 1024 and all(0 <= i.file_size <= 4 * 1024 * 1024 for i in infos), 'Proof archive expansion limit')
            require(all(PurePosixPath(i.filename).name == i.filename and not i.flag_bits & 1 for i in infos), 'Unsafe proof archive path/encryption')
            files = {name: z.read(name) for name in wanted}
        record = json.loads(files[group + '.json'])
        require(record.get('schema_version') == 1 and record.get('test_fixture') is False and record.get('repository') == REPOSITORY
                and record.get('workflow_id') == WORKFLOW and record.get('branch') == BRANCH and record.get('run_id') == int(run_id)
                and record.get('source_commit') == run['head_sha'] and record.get('group') == group
                and record.get('features') == FEATURES[group] and record.get('inputs_unchanged') is True
                and record.get('context') == context() and record.get('failed') == 0, 'Public proof source/context differs')
        harness_changes = compare_inputs(record, group, inputs(group))
        for name in logs_for(group):
            require(record['logs'][name] == {'bytes': len(files[name]), 'sha256': sha(files[name])}, 'Public proof raw log changed')
        count = verify_logs(group, files); require(record.get('passed') == count, 'Public proof count differs')
        output = EVIDENCE / ('reused-pairing-public-' + group); output.mkdir(exist_ok=True)
        for name, data in files.items(): (output / name).write_bytes(data)
        (output / 'reuse-report.json').write_text(json.dumps({'schema_version': 1, 'reused': True, 'new_test_execution': False,
            'repository': REPOSITORY, 'original_run_id': int(run_id), 'original_source_commit': record['source_commit'],
            'current_source_commit': command('git', 'rev-parse', 'HEAD'), 'group': group, 'passed': count, 'failed': 0,
            'input_bytes_match_current': not harness_changes, 'production_input_bytes_match_current': True,
            'reviewed_harness_changes': harness_changes, 'original_context': record['context'],
            'scope': record['scope']}, indent=2) + '\n')
    print(f'Reused {group}: {count} actual public checks; matching production bytes/context, reviewed harness changes recorded, no new test execution.')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('action', choices=['snapshot', 'finish', 'reuse'])
    p.add_argument('--group', required=True, choices=PREFIXES)
    p.add_argument('--run-id')
    args = p.parse_args()
    try:
        if args.action == 'snapshot': snapshot(args.group)
        elif args.action == 'finish': finish(args.group)
        else: reuse(args.group, args.run_id or '')
        return 0
    except (ValueError, OSError, KeyError, TypeError, zipfile.BadZipFile, subprocess.CalledProcessError):
        print('Public pairing proof failed closed; review the changed source/result/context before selecting a new affected test run.', file=sys.stderr)
        return 1


if __name__ == '__main__': raise SystemExit(main())
