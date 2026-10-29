#!/usr/bin/env python3
"""Promote one pinned successful cloud package into the existing private draft.

Transfer/integrity checks only: no compiler, repeated test run, signing, device
access, new release, publication, or deletion of the two owned fixture assets.
Fill promotion-contract.json from the reviewed successful package run first.
"""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import sys
import tarfile
import tempfile
import urllib.request
import zipfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


transport = load_module('draft_transport', HERE / 'upload-draft-assets.py')
require = transport.require
FIXTURES = transport.FIXTURE_NAMES
CHANGED = frozenset(transport.EXPECTED) - FIXTURES
KIT_NAMES = transport.KIT_NAMES
CANDIDATE_NAMES = CHANGED - KIT_NAMES
SOURCE = 'AppInstaller-corresponding-source.tar.xz'
KIT = 'AppInstaller-native-bootstrap-kit.zip'
KIT_RECEIPT = 'AppInstaller-native-bootstrap-kit.json'


class API(transport.GitHub):
    def mutate(self, suffix, method, body=None):
        data = json.dumps(body).encode() if body is not None else None
        request = urllib.request.Request(self.base + suffix, data=data,
                                         headers={**self.headers, 'Content-Type': 'application/json'}, method=method)
        with self.opener.open(request, timeout=60) as response:
            raw = response.read(1024 * 1024 + 1)
        require(len(raw) <= 1024 * 1024, 'Oversized GitHub mutation response')
        return json.loads(raw) if raw else None


def digest_valid(value):
    return isinstance(value, str) and re.fullmatch(r'[0-9a-f]{64}', value) is not None


def positive(value, bound=1024 * 1024 * 1024):
    return type(value) is int and 0 < value <= bound


def contract():
    value = json.loads((HERE / 'promotion-contract.json').read_text())
    require(value.get('schema_version') == 1 and value.get('release_id') == transport.RELEASE
            and value.get('tag_name') == transport.TAG, 'Unsupported promotion destination')
    require(set(value['old_assets']) == set(transport.EXPECTED), 'Old draft asset closure differs')
    for name, item in value['old_assets'].items():
        require(positive(item['id'], 10**15) and positive(item['bytes'], 256 * 1024 * 1024)
                and digest_valid(item['sha256']), 'Invalid old draft asset pin: ' + name)
    for name in FIXTURES:
        require((value['old_assets'][name]['bytes'], value['old_assets'][name]['sha256']) == transport.EXPECTED[name],
                'Owned fixture bytes cannot change during candidate promotion')
    new = value['new']
    require(isinstance(new['source_commit'], str) and re.fullmatch(r'[0-9a-f]{40}', new['source_commit'])
            and new['source_commit'] != value['old_source_commit'] and positive(new['run_id'], 10**15),
            'Promotion requires the reviewed new source commit and successful package run')
    require(set(new['artifacts']) == {'candidate', 'kit'} and set(new['assets']) == CHANGED, 'New artifact/asset closure differs')
    for item in new['artifacts'].values():
        require(positive(item['id'], 10**15) and positive(item['bytes'], 512 * 1024 * 1024)
                and digest_valid(item['sha256']), 'Complete both reviewed artifact ZIP pins first')
    for name, item in new['assets'].items():
        require(positive(item['bytes'], 256 * 1024 * 1024) and digest_valid(item['sha256']),
                'Complete the reviewed new asset pin: ' + name)
    return value


def matches(item, name, pin, old=False):
    return (item.get('name') == name and item.get('size') == pin['bytes']
            and item.get('digest') == 'sha256:' + pin['sha256'] and item.get('state') == 'uploaded'
            and (not old or item.get('id') == pin['id']))


def release(api, value, temporary):
    repository = api.get('')
    require(repository.get('private') is True and repository.get('full_name') == transport.REPOSITORY, 'Destination must remain private')
    result = api.get(f'/releases/{transport.RELEASE}')
    require(result['id'] == transport.RELEASE and result['draft'] is True and result['tag_name'] == transport.TAG
            and result['target_commitish'] in (value['old_source_commit'], value['new']['source_commit']),
            'Private draft identity or target changed')
    assets = {item['name']: item for item in result['assets']}
    require(len(assets) == len(result['assets']) and set(assets) <= set(value['old_assets']) | set(temporary.values()),
            'Unexpected or duplicate draft asset')
    for name in FIXTURES:
        require(name in assets and matches(assets[name], name, value['old_assets'][name], old=True),
                'Owned fixture ID/bytes changed')
    for name in CHANGED:
        if name in assets:
            require(matches(assets[name], name, value['old_assets'][name], old=True)
                    or matches(assets[name], name, value['new']['assets'][name]), 'Conflicting current draft asset: ' + name)
        pending = temporary[name]
        if pending in assets:
            require(matches(assets[pending], pending, value['new']['assets'][name]), 'Conflicting staged draft asset: ' + name)
    return assets


def extract(archive_path, selected, stage, expected, kit):
    with zipfile.ZipFile(archive_path) as archive:
        index = transport.zip_index(archive)
        if kit:
            require(set(index) == set(selected), 'Unexpected native-kit artifact payload')
        for name in selected:
            path = name if kit else 'candidates/' + name
            require(path in index and index[path].file_size == expected[name]['bytes'], 'Required new asset missing/oversized: ' + name)
            with archive.open(path) as source, (stage / name).open('wb') as target:
                for block in iter(lambda: source.read(1024 * 1024), b''):
                    target.write(block)
            transport.validate_file(stage / name, expected[name]['bytes'], expected[name]['sha256'])


def verify_stage(stage, value):
    expected = value['new']['assets']
    for name in CHANGED:
        transport.validate_file(stage / name, expected[name]['bytes'], expected[name]['sha256'])
    # This is the existing actual source/IPA/license integrity gate, not a new
    # test run. It inspects the delivered archive and actual Mach-O candidates.
    build = ROOT / 'app-installer/build'
    sys.path.insert(0, str(build))
    verifier = load_module('candidate_integrity', build / 'verify-candidate.py')
    report = verifier.verify(stage / 'AppInstaller-candidate-manifest.json', stage)
    require(report['source_commit'] == value['new']['source_commit'] and report['release_ready'] is False,
            'New candidates do not match the reviewed compiled commit')
    read = lambda name: json.loads((stage / name).read_text())
    candidate = read('AppInstaller-candidate-manifest.json')
    receipt = read(KIT_RECEIPT)
    library = read('cloud-device-library-manifest.json')
    for metadata in (receipt, library):
        require(metadata['source_commit'] == report['source_commit']
                and metadata['source_tree_sha256'] == report['source_tree_sha256'], 'New kit/library source identity differs')
    source = candidate['source_bundle']
    require(receipt['file'] == KIT and receipt['bytes'] == expected[KIT]['bytes'] and receipt['sha256'] == expected[KIT]['sha256']
            and receipt['corresponding_source']['file'] == SOURCE and receipt['corresponding_source']['sha256'] == source['sha256']
            and receipt['corresponding_source']['bytes'] == source['bytes']
            and library['source_bundle_sha256'] == source['sha256'] and library['source_bundle_bytes'] == source['bytes']
            and library['locked_dependency_graph_hash'] == report['locked_dependency_graph_hash']
            and receipt['minimal_bootstrap_kit'] is True and receipt['personal_resources_used'] is False
            and receipt['device_install_attempted'] is False, 'New kit/library/source receipt binding differs')
    with tarfile.open(stage / SOURCE, 'r|xz') as archive:
        first = next(iter(archive))
        require(first.name == 'AppInstaller-source/SourceBundleManifest.json' and first.isfile()
                and first.size <= 32 * 1024 * 1024, 'Delivered source manifest missing')
        source_manifest = json.load(archive.extractfile(first))
    source_files = {entry['path']: entry for entry in source_manifest['files']}
    with zipfile.ZipFile(stage / KIT) as archive:
        index = transport.zip_index(archive, max_total=256 * 1024 * 1024)
        prefix = 'AI-Workspace/claude-chatg/'
        manifest_name = prefix + 'BootstrapKitManifest.json'
        require(manifest_name in index and index[manifest_name].file_size <= 4 * 1024 * 1024, 'New kit manifest missing')
        manifest = json.loads(archive.read(manifest_name))
        entries = {prefix + entry['path']: entry for entry in manifest['files']}
        require(len(entries) == len(manifest['files']) and set(index) == set(entries) | {manifest_name}, 'New kit file closure differs')
        require(manifest.get('test_fixture') is False and manifest['source_commit'] == report['source_commit']
                and manifest['source_tree_sha256'] == report['source_tree_sha256']
                and manifest['bootstrap_tool_commit'] == receipt['bootstrap_tool_commit'] == report['source_commit']
                and manifest['corresponding_source'] == receipt['corresponding_source']
                and manifest['personal_resources_used'] is False and manifest['device_install_attempted'] is False,
                'New kit provenance differs')
        for name, entry in entries.items():
            require(index[name].file_size == entry['bytes'] and Path(name).suffix not in
                    {'.p12', '.p8', '.key', '.mobileprovision', '.mobiledevicepairing'}, 'New kit member size/type differs')
            digest = hashlib.sha256()
            with archive.open(name) as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b''):
                    digest.update(block)
            require(digest.hexdigest() == entry['sha256'], 'New kit payload digest differs: ' + name)
            relative = entry['path']
            if relative.startswith('app-installer/ios/') or relative in {
                    'app-installer/core/app_installer.h', 'app-installer/core/secure_storage.h'}:
                require(relative in source_files and source_files[relative]['sha256'] == entry['sha256'],
                        'New kit native source differs from the delivered corresponding source')
        require(archive.read(prefix + manifest['library_manifest']) == (stage / 'cloud-device-library-manifest.json').read_bytes(),
                'New inner/external library receipts differ')
        rust_entry = entries[prefix + manifest['rust_library']]
        require(rust_entry['bytes'] == library['bytes'] and rust_entry['sha256'] == library['sha256'], 'New kit Rust library receipt differs')
        resources = prefix + manifest['review_resources'] + '/'
        with zipfile.ZipFile(stage / 'AppInstaller-duo-candidate.ipa') as ipa:
            for name in ('BuildMetadata.json', 'ThirdPartyNoticeReport.json', 'ThirdPartyNotices.txt'):
                require(archive.read(resources + name) == ipa.read('Payload/AppInstaller.app/' + name), 'Kit review metadata differs from the genuine Duo candidate')
    return report


def promote(api, value):
    new = value['new']
    temporary = {name: name + '.pending-' + new['source_commit'][:12] for name in CHANGED}
    release(api, value, temporary)
    run = api.get(f'/actions/runs/{new["run_id"]}')
    require(run['id'] == new['run_id'] and run['workflow_id'] == transport.WORKFLOW
            and run['path'] == '.github/workflows/app-installer-cloud-ui.yml' and run['event'] == 'workflow_dispatch'
            and run['head_sha'] == new['source_commit'] and run['status'] == 'completed' and run['conclusion'] == 'success'
            and run['repository']['full_name'] == transport.REPOSITORY and run['head_repository']['full_name'] == transport.REPOSITORY,
            'New package run is not the pinned successful trusted workflow/head')
    work = HERE / 'work'
    work.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='candidate-promotion-', dir=work) as temporary_dir:
        stage = Path(temporary_dir)
        for label, names in (('candidate', CANDIDATE_NAMES), ('kit', KIT_NAMES)):
            pin = new['artifacts'][label]
            expected_name = 'app-installer-cloud-ui-latest' if label == 'candidate' else 'app-installer-native-kit-latest'
            item = api.get(f'/actions/artifacts/{pin["id"]}')
            require(item['id'] == pin['id'] and item['name'] == expected_name and item['expired'] is False
                    and item['workflow_run']['id'] == new['run_id'] and item['size_in_bytes'] == pin['bytes']
                    and item['digest'] == 'sha256:' + pin['sha256'], 'New artifact ZIP identity/digest differs')
            path = stage / (label + '.zip')
            api.download(pin['id'], path, pin['bytes'])
            transport.validate_file(path, pin['bytes'], pin['sha256'])
            extract(path, names, stage, new['assets'], kit=label == 'kit')
            path.unlink()
        report = verify_stage(stage, value)
        # No mutation occurred until the complete actual new distribution passed.
        assets = release(api, value, temporary)
        for name in sorted(CHANGED):
            if name in assets and matches(assets[name], name, new['assets'][name]):
                continue
            pending = temporary[name]
            if pending not in assets:
                path = stage / pending
                (stage / name).replace(path)
                require(matches(api.upload(path), pending, new['assets'][name]), 'New staged asset server digest differs')
                print('Staged verified new draft asset: ' + name)
            else:
                require(matches(assets[pending], pending, new['assets'][name]), 'Pending draft asset changed')
        assets = release(api, value, temporary)
        for name in CHANGED:
            require((name in assets and matches(assets[name], name, new['assets'][name]))
                    or (temporary[name] in assets and matches(assets[temporary[name]], temporary[name], new['assets'][name])),
                    'All seven new server assets must verify before any old asset is deleted')
        # Remove old native binaries first and their old source companion last.
        deletion_order = [KIT, 'AppInstaller-iphone-candidate.ipa', 'AppInstaller-duo-candidate.ipa',
                          KIT_RECEIPT, 'cloud-device-library-manifest.json', 'AppInstaller-candidate-manifest.json', SOURCE]
        for name in deletion_order:
            assets = release(api, value, temporary)
            if name in assets and matches(assets[name], name, value['old_assets'][name], old=True):
                api.mutate('/releases/assets/' + str(value['old_assets'][name]['id']), 'DELETE')
        for name in [SOURCE] + sorted(CHANGED - {SOURCE}):
            assets = release(api, value, temporary)
            if name not in assets:
                item = assets[temporary[name]]
                require(matches(item, temporary[name], new['assets'][name]), 'Staged asset changed before rename')
                require(matches(api.mutate('/releases/assets/' + str(item['id']), 'PATCH', {'name': name}), name, new['assets'][name]),
                        'Promoted asset rename digest differs')
        assets = release(api, value, temporary)
        require(set(assets) == set(value['old_assets']) and all(matches(assets[name], name, new['assets'][name]) for name in CHANGED),
                'Promoted nine-asset closure differs')
        # GitHub can reset an unpublished draft to a generated untagged name
        # when tag_name is omitted from a release edit. Preserve it explicitly.
        result = api.mutate(f'/releases/{transport.RELEASE}', 'PATCH', {
            'tag_name': transport.TAG, 'target_commitish': new['source_commit'], 'draft': True})
        require(result['draft'] is True and result['tag_name'] == transport.TAG
                and result['target_commitish'] == new['source_commit'], 'Private draft retarget failed')
        release(api, value, temporary)
        report.update(draft=True, release_id=transport.RELEASE, original_package_run=new['run_id'],
                      compilation_performed=False, tests_repeated=False, device_install_attempted=False,
                      preserved_fixture_asset_ids={name: value['old_assets'][name]['id'] for name in FIXTURES},
                      promoted_assets=new['assets'])
        (work / 'candidate-promotion-report.json').write_text(json.dumps(report, indent=2) + '\n')
    print('Promoted seven integrity-verified assets in the existing private draft; two owned fixture assets unchanged. release_ready=false.')


def main():
    try:
        value = contract()  # Incomplete pins fail before the first API call.
        require(os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('GITHUB_REPOSITORY') == transport.REPOSITORY
                and os.environ.get('GITHUB_EVENT_NAME') == 'workflow_dispatch'
                and os.environ.get('GITHUB_WORKFLOW_REF') == transport.REPOSITORY + '/.github/workflows/app-installer-promote-draft.yml@refs/heads/main',
                'Promotion requires the scoped manual hosted workflow')
        promote(API(os.environ['GH_TOKEN']), value)
        return 0
    except Exception as error:
        print(str(error) if isinstance(error, ValueError) else 'Candidate promotion stopped; draft remains unpublished. Inspect the failed step before retrying this transfer only.', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
