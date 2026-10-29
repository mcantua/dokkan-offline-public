#!/usr/bin/env python3
"""Refresh only pinned committed setup files around the existing compiled Rust kit.

Hosted manual workflow only. No compiler, SDK, tests, account or device action.
Original source/IPA assets remain unchanged in the existing private draft.
"""
import argparse
import copy
import hashlib
import importlib.util
import json
import os
import re
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
import zipfile

sys.dont_write_bytecode = True
SPEC = importlib.util.spec_from_file_location('draft_transfer', Path(__file__).with_name('upload-draft-assets.py'))
transfer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(transfer)
require = transfer.require
ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'app-installer/cloud-ui/work/native-kit-refresh'
KIT = 'AppInstaller-native-bootstrap-kit.zip'
RECEIPT = 'AppInstaller-native-bootstrap-kit.json'
PREFIX = 'AI-Workspace/claude-chatg/'
MANIFEST = PREFIX + 'BootstrapKitManifest.json'
CONTRACT = json.loads(Path(__file__).with_name('refresh-contract.json').read_text())
require(CONTRACT['schema_version']==1 and CONTRACT['release_id']==transfer.RELEASE
        and CONTRACT['tag_name']==transfer.TAG, 'Unsupported kit-refresh destination')
SOURCE_COMMIT = CONTRACT['source_commit']
SOURCE_FINGERPRINT = CONTRACT['source_tree_sha256']
PACKAGE_RUN = CONTRACT['package_run_id']
SOURCE_ARTIFACT = CONTRACT['source_artifact']['id']
OLD_ASSETS = CONTRACT['assets']
require(set(OLD_ASSETS)==set(transfer.EXPECTED), 'Pinned refresh asset closure differs')
OLD_EXPECTED = {name:(pin['bytes'],pin['sha256']) for name,pin in OLD_ASSETS.items()}
require(re.fullmatch(r'[0-9a-f]{40}',SOURCE_COMMIT) is not None
        and re.fullmatch(r'[0-9a-f]{40}',CONTRACT['bootstrap_tool_commit']) is not None
        and re.fullmatch(r'[0-9a-f]{64}',SOURCE_FINGERPRINT) is not None
        and type(PACKAGE_RUN) is int and PACKAGE_RUN>0, 'Invalid pinned compiled-source identity')
for pin in [*OLD_ASSETS.values(),CONTRACT['source_artifact'],CONTRACT['kit_artifact']]:
    require(type(pin['id']) is int and pin['id']>0 and type(pin['bytes']) is int
            and 0<pin['bytes']<=512*1024*1024 and re.fullmatch(r'[0-9a-f]{64}',pin['sha256']) is not None,
            'Invalid pinned current artifact/asset identity')
require(len({pin['id'] for pin in OLD_ASSETS.values()})==9
        and SOURCE_ARTIFACT!=CONTRACT['kit_artifact']['id'], 'Pinned current artifact IDs collide')
REPLACEMENTS = tuple(CONTRACT['replacements'])
require(REPLACEMENTS==('app-installer/device/setup-wizard.py',), 'This refresh replaces only the setup wizard')
PROTECTED = ('app-installer/ios', 'app-installer/core', 'app-installer/build',
             'downloads/isideload/isideload-0.5.0', 'downloads/idevice/idevice-0.1.68',
             'downloads/license-notices', 'downloads/apple-trust',
             'app-installer/LICENSE', 'app-installer/licensing-signing.md')
OTHERS = {name: value for name, value in OLD_EXPECTED.items() if name not in (KIT, RECEIPT)}


class API(transfer.GitHub):
    def mutate(self, suffix, method, body=None):
        data = json.dumps(body).encode() if body is not None else None
        headers = {**self.headers, 'Content-Type': 'application/json'}
        request = urllib.request.Request(self.base + suffix, data=data, headers=headers, method=method)
        with self.opener.open(request, timeout=60) as response:
            result = response.read(1024 * 1024 + 1)
        require(len(result) <= 1024 * 1024, 'Oversized GitHub mutation response')
        return json.loads(result) if result else None


def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args], stderr=subprocess.DEVNULL)


def check_source():
    head = git('rev-parse', 'HEAD').decode().strip()
    require(head == os.environ['GITHUB_SHA'], 'Checkout is not the dispatched source revision')
    git('merge-base', '--is-ancestor', SOURCE_COMMIT, head)
    require(not git('diff', '--name-only', SOURCE_COMMIT, head, '--', *PROTECTED),
            'Compiled production/license/path-dependency inputs changed; kit-only refresh is forbidden')
    require(not git('status', '--porcelain', '--untracked-files=normal', '--', *PROTECTED, *REPLACEMENTS),
            'Compiled inputs or setup replacements are not clean committed files')
    for name in REPLACEMENTS:
        require((ROOT / name).read_bytes() == git('show', 'HEAD:' + name), 'Setup replacement differs from dispatched commit')
    return head


def matches(item, name, expected):
    return (item.get('name') == name and item.get('size') == expected[0]
            and item.get('digest') == 'sha256:' + expected[1] and item.get('state') == 'uploaded')


def by_name(release):
    result = {item['name']: item for item in release['assets']}
    require(len(result) == len(release['assets']), 'Duplicate draft asset names')
    return result


def validate_destination(api):
    repository=api.get('')
    require(repository.get('private') is True and repository.get('full_name')==transfer.REPOSITORY,
            'Kit-refresh destination must be the private project repository')
    release=api.get(f'/releases/{transfer.RELEASE}')
    require(release['id']==transfer.RELEASE and release['draft'] is True
            and release['tag_name']==transfer.TAG and release['target_commitish']==SOURCE_COMMIT,
            'Existing private draft identity or compiled source changed')
    return release


def release_state(api, new_expected=None, temporary=None):
    assets = by_name(validate_destination(api))
    allowed = set(OLD_EXPECTED) | set((temporary or {}).values())
    require(set(assets) <= allowed, 'Draft contains an unexpected asset')
    for name, expected in OTHERS.items():
        require(name in assets and matches(assets[name], name, expected) and assets[name]['id']==OLD_ASSETS[name]['id'],
                'Existing candidate/source/fixture asset ID or bytes changed: ' + name)
    for name in (KIT, RECEIPT):
        if name in assets:
            require((matches(assets[name], name, OLD_EXPECTED[name]) and assets[name]['id']==OLD_ASSETS[name]['id'])
                    or (new_expected and matches(assets[name], name, new_expected[name])),
                    'Current native-kit asset does not match the old or refreshed receipt')
    return assets


def validate_old_artifact(api):
    pin=CONTRACT['kit_artifact']
    identity,name,size,digest=pin['id'],'app-installer-native-kit-latest',pin['bytes'],pin['sha256']
    metadata = api.get(f'/actions/artifacts/{identity}')
    require(metadata['id'] == identity and metadata['name'] == name and metadata['expired'] is False
            and metadata['workflow_run']['id'] == PACKAGE_RUN and metadata['size_in_bytes'] == size
            and metadata['digest'] == 'sha256:' + digest, 'Original native-kit artifact identity changed')
    return identity, size, digest


def extract_old_kit(archive_path,stage):
    with zipfile.ZipFile(archive_path) as archive:
        index=transfer.zip_index(archive)
        require(set(index)=={KIT,RECEIPT}, 'Original native-kit artifact closure differs')
        for name in (KIT,RECEIPT):
            size,digest=OLD_EXPECTED[name]
            require(index[name].file_size==size, 'Original native-kit member size differs')
            with archive.open(name) as source,(stage/name).open('wb') as target:
                for block in iter(lambda:source.read(1024*1024),b''):
                    target.write(block)
            transfer.validate_file(stage/name,size,digest)


def verify_payload(archive):
    index = transfer.zip_index(archive, max_total=256 * 1024 * 1024)
    require(MANIFEST in index and index[MANIFEST].file_size <= 4 * 1024 * 1024, 'Native-kit manifest absent')
    manifest = json.loads(archive.read(MANIFEST))
    entries = {PREFIX + item['path']: item for item in manifest['files']}
    require(len(entries) == len(manifest['files']) and set(index) == set(entries) | {MANIFEST}, 'Native-kit payload closure differs')
    require(manifest['source_commit'] == SOURCE_COMMIT
            and manifest['source_tree_sha256'] == SOURCE_FINGERPRINT
            and manifest.get('test_fixture') is False and manifest['personal_resources_used'] is False
            and manifest['device_install_attempted'] is False, 'Native-kit compiled-source provenance differs')
    for name, entry in entries.items():
        require(index[name].file_size == entry['bytes'], 'Native-kit file size differs')
        digest = hashlib.sha256()
        with archive.open(name) as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                digest.update(block)
        require(digest.hexdigest() == entry['sha256'], 'Native-kit payload digest differs: ' + name)
    return manifest, index


def rebuild(stage, head):
    old_receipt = json.loads((stage / RECEIPT).read_text())
    with zipfile.ZipFile(stage / KIT) as old:
        manifest, index = verify_payload(old)
        require(manifest['bootstrap_tool_commit'] == CONTRACT['bootstrap_tool_commit']
                and manifest['corresponding_source'] == old_receipt['corresponding_source'], 'Original native-kit tool/source provenance differs')
        require(old.read(PREFIX + manifest['library_manifest']) == (ROOT / 'builds/cloud-device-library-manifest.json').read_bytes(),
                'Original native-kit Rust library receipt differs')
        library = json.loads(old.read(PREFIX + manifest['library_manifest']))
        library_entry=next(entry for entry in manifest['files'] if entry['path']==manifest['rust_library'])
        require(library_entry['bytes']==library['bytes'] and library_entry['sha256']==library['sha256']
                and library['source_bundle_sha256'] == OLD_EXPECTED['AppInstaller-corresponding-source.tar.xz'][1],
                'Original native-kit Rust bytes/source companion differs')
        updated = copy.deepcopy(manifest)
        updated['bootstrap_tool_commit'] = head
        replacements = {PREFIX + name: (ROOT / name).read_bytes() for name in REPLACEMENTS}
        require(set(replacements) <= set(index), 'Setup helper is not part of the original native kit')
        payload = []
        output_zip = stage / 'refreshed.zip'
        with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as output:
            for name in sorted(set(index) - {MANIFEST}):
                data = replacements.get(name)
                if data is None:
                    data = old.read(name)
                payload.append({'path': name[len(PREFIX):], 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
                info = copy.copy(index[name])
                info.compress_type = zipfile.ZIP_DEFLATED
                output.writestr(info, data)
            updated['files'] = payload
            info = copy.copy(index[MANIFEST])
            output.writestr(info, (json.dumps(updated, indent=2) + '\n').encode())
    with zipfile.ZipFile(output_zip) as archive:
        verified, _ = verify_payload(archive)
        require(verified == updated and verified['bootstrap_tool_commit'] == head, 'Refreshed native-kit verification failed')
        for name, data in replacements.items():
            require(archive.read(name) == data, 'Refreshed setup helper was not replaced')
    output_zip.replace(stage / KIT)
    receipt = copy.deepcopy(old_receipt)
    receipt.update(bytes=(stage / KIT).stat().st_size, sha256=transfer.sha_file(stage / KIT), bootstrap_tool_commit=head)
    (stage / RECEIPT).write_text(json.dumps(receipt, indent=2) + '\n')
    return {name: ((stage / name).stat().st_size, transfer.sha_file(stage / name)) for name in (KIT, RECEIPT)}


def replace_pair(api, stage, expected, head):
    temporary = {KIT: 'AppInstaller-native-bootstrap-kit.pending-' + head[:12] + '.zip',
                 RECEIPT: 'AppInstaller-native-bootstrap-kit.pending-' + head[:12] + '.json'}
    assets = release_state(api, expected, temporary)
    other_ids = {name: assets[name]['id'] for name in OTHERS}
    for name in (KIT, RECEIPT):
        temp_name = temporary[name]
        if name in assets and matches(assets[name], name, expected[name]):
            continue
        if temp_name in assets:
            require(matches(assets[temp_name], temp_name, expected[name]), 'Conflicting pending native-kit asset')
        else:
            path = stage / temp_name
            path.write_bytes((stage / name).read_bytes())
            require(matches(api.upload(path), temp_name, expected[name]), 'Pending native-kit upload digest/size mismatch')
            path.unlink()
    assets = release_state(api, expected, temporary)
    for name in (KIT, RECEIPT):
        require((name in assets and matches(assets[name], name, expected[name]))
                or (temporary[name] in assets and matches(assets[temporary[name]], temporary[name], expected[name])),
                'Both refreshed draft assets must verify before replacing the previous pair')
    # The two new server digests verify before either old asset is deleted.
    for name in (KIT, RECEIPT):
        assets = release_state(api, expected, temporary)
        if name in assets and matches(assets[name], name, OLD_EXPECTED[name]) and assets[name]['id']==OLD_ASSETS[name]['id']:
            api.mutate('/releases/assets/' + str(OLD_ASSETS[name]['id']), 'DELETE')
    for name in (KIT, RECEIPT):
        assets = release_state(api, expected, temporary)
        if name not in assets:
            item = assets[temporary[name]]
            require(matches(item, temporary[name], expected[name]), 'Pending replacement changed')
            require(matches(api.mutate('/releases/assets/' + str(item['id']), 'PATCH', {'name': name}), name, expected[name]),
                    'Replacement native-kit rename verification failed')
    assets = release_state(api, expected, temporary)
    require(set(assets) == set(OLD_EXPECTED), 'Final draft must contain one current asset pair')
    require(all(matches(assets[name], name, expected[name]) for name in (KIT, RECEIPT)), 'Final refreshed kit pair differs')
    require(all(assets[name]['id'] == identity for name, identity in other_ids.items()), 'A non-kit release asset was replaced')


def refresh(api):
    head = check_source()
    validate_destination(api)
    run = api.get(f'/actions/runs/{PACKAGE_RUN}')
    require(run['id']==PACKAGE_RUN and run['workflow_id'] == transfer.WORKFLOW
            and run['path']=='.github/workflows/app-installer-cloud-ui.yml' and run['event']=='workflow_dispatch'
            and run['head_sha'] == SOURCE_COMMIT
            and run['status'] == 'completed' and run['conclusion'] == 'success'
            and run['repository']['full_name'] == transfer.REPOSITORY and run['head_repository']['full_name'] == transfer.REPOSITORY,
            'Original build provenance differs')
    identity, size, digest = validate_old_artifact(api)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='kit-refresh-', dir=OUTPUT.parent) as temporary:
        stage = Path(temporary)
        archive = stage / 'artifact.zip'
        api.download(identity, archive, size)
        transfer.validate_file(archive, size, digest)
        extract_old_kit(archive,stage)
        archive.unlink()
        expected = rebuild(stage, head)
        replace_pair(api, stage, expected, head)
        for name in (KIT, RECEIPT):
            (stage / name).replace(OUTPUT / name)
        report = {'schema_version': 1, 'classification': 'unsigned-candidate', 'release_ready': False,
                  'release_id': transfer.RELEASE, 'draft': True, 'source_commit': SOURCE_COMMIT,
                  'bootstrap_tool_commit': head, 'replaced_helpers': list(REPLACEMENTS),
                  'source_artifact_preserved': SOURCE_ARTIFACT, 'old_kit_artifact_id': identity,
                  'production_inputs_unchanged': True, 'compiled_rust_reused': True,
                  'compilation_performed': False, 'tests_repeated': False,
                  'personal_resources_used': False, 'device_install_attempted': False,
                  'assets': {name: {'bytes': values[0], 'sha256': values[1]} for name, values in expected.items()}}
        (OUTPUT / 'kit-refresh-report.json').write_text(json.dumps(report, indent=2) + '\n')
    print('Refreshed only the committed setup wizard; verified one private draft kit pair. No production rebuild or tests.')


def retire_original(api):
    report = json.loads((OUTPUT / 'kit-refresh-report.json').read_text())
    require(report['bootstrap_tool_commit'] == os.environ['GITHUB_SHA'] and report['release_ready'] is False,
            'Refresh report does not belong to this workflow revision')
    expected = {name: (report['assets'][name]['bytes'], report['assets'][name]['sha256']) for name in (KIT, RECEIPT)}
    for name, values in expected.items():
        transfer.validate_file(OUTPUT / name, *values)
    assets = release_state(api, expected)
    require(set(assets) == set(OLD_EXPECTED)
            and all(matches(assets[name], name, expected[name]) for name in (KIT, RECEIPT)), 'Durable replacement pair is not verified')
    new_id = int(os.environ['NEW_KIT_ARTIFACT_ID'])
    new = api.get(f'/actions/artifacts/{new_id}')
    require(new['id'] == new_id and new['name'] == 'app-installer-native-kit-latest'
            and new['workflow_run']['id'] == int(os.environ['GITHUB_RUN_ID']) and new['expired'] is False
            and new['digest'] == 'sha256:' + os.environ['NEW_KIT_ARTIFACT_DIGEST'], 'Refreshed Actions artifact is not verified')
    identity, _, _ = validate_old_artifact(api)
    api.mutate('/actions/artifacts/' + str(identity), 'DELETE')
    print('Removed only the superseded original kit artifact; original source/candidate artifact remains.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--retire-original', action='store_true')
    args = parser.parse_args()
    try:
        require(os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('GITHUB_REPOSITORY') == transfer.REPOSITORY
                and os.environ.get('GITHUB_EVENT_NAME') == 'workflow_dispatch'
                and os.environ.get('GITHUB_WORKFLOW_REF') == transfer.REPOSITORY + '/.github/workflows/app-installer-refresh-kit.yml@refs/heads/main',
                'Kit refresh requires its scoped manual hosted workflow')
        api = API(os.environ['GH_TOKEN'])
        retire_original(api) if args.retire_original else refresh(api)
        return 0
    except Exception as error:
        print(str(error) if isinstance(error, ValueError) else 'Native-kit refresh failed; no publish or device action occurred.', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
