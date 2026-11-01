#!/usr/bin/env python3
"""Transfer one already-verified cloud candidate/source/kit to its private draft.

No compilation, tests, signing, installation, publication or release creation.
The pinned artifact digests and immutable source revision define this transfer.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys
import tarfile
import tempfile
import urllib.parse
import urllib.request
import zipfile

REPOSITORY = 'mcantua/claude-chatg'
RUN = 40747677006
WORKFLOW = 399573334
SOURCE_COMMIT = '0e48c9e183990b045eb134cb7fa6f5da30f7506c'
RELEASE = 427060273
TAG = 'app-installer-current-candidate'
ARTIFACTS = (
    (12841413501, 'app-installer-cloud-ui-latest', 89322188,
     'cfb379950437abd4975b23011807f714a97948dd0e07f329cf1267a0ddc925ef'),
    (12841029310, 'app-installer-native-kit-latest', 34811096,
     '3abba922baeb2d2bb7092d2656d7350cf4a73b2a7a31795f1491d7160246d95f'),
)
# Binary and receipt bytes were independently downloaded and verified from RUN.
EXPECTED = {
    'AppInstaller-corresponding-source.tar.xz': (78296336, '454d82da382075a20e39f65994e2426e8e84e02a0ae9efff4ef4fa7e443edc82'),
    'AppInstaller-iphone-candidate.ipa': (5525901, '30c2f766ec489143b2060521a89a50d1dfaec6937ac3b015fbe63442d80d0d0b'),
    'AppInstaller-duo-candidate.ipa': (5525907, 'e1b9276878c376dd87e8fdad317a7b872bfd69447d11b7c5df7042b60f22d768'),
    'AppInstaller-native-bootstrap-kit.zip': (35116256, '65543a43831371c5eabca6bd60567b1b04a04e7e8b29cfa75124179b221ff559'),
    'AppInstaller-candidate-manifest.json': (2206, 'd730b44bb9786a6fa47df33b77e1c4c2a12284bf993f1219a8df33a720c343cf'),
    'AppInstaller-native-bootstrap-kit.json': (892, 'd5c7e00c87699cb67e4a1d1a32fa8828bb80771410c540e245a3ea794e5874c3'),
    'cloud-device-library-manifest.json': (1331, 'ae1aec917a35373bb9a312dbf163a8850e3e4a66959f75aef669ee84ea91f65b'),
    'InstallationCheck-test-fixture.zip': (26007, 'd3c5560c02cb5a3cd18e80d35cb7e26f2e7c9703c18a88fe6fe80d9c49b92654'),
    'InstallationCheck-test-fixture.json': (906, '4153e4678f90147cb950623564d58842913aa1b03cd047ca6671c48898d26f18'),
}
FIXTURE_NAMES = frozenset(name for name in EXPECTED if name.startswith('InstallationCheck'))
CANDIDATE_NAMES = frozenset(name for name in EXPECTED if name not in FIXTURE_NAMES and 'bootstrap-kit' not in name)
KIT_NAMES = frozenset(name for name in EXPECTED if 'bootstrap-kit' in name)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha_file(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def validate_file(path, size, digest):
    require(path.is_file() and not path.is_symlink() and path.stat().st_size == size
            and sha_file(path) == digest, 'Transferred asset hash/size mismatch: ' + path.name)


class PublicRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        require(urllib.parse.urlsplit(newurl).scheme == 'https', 'Insecure artifact redirect')
        # Artifact API redirects to a signed public-storage URL. Never forward
        # the repository token to that host (or to any redirect destination).
        return urllib.request.Request(newurl, headers={'User-Agent': 'AppInstaller-draft-transfer'})


class GitHub:
    def __init__(self, token):
        # This retained transport is bound to the frozen private backup's
        # release IDs and receipts. It must never contact that repository from
        # the public continuation, even if old workflow variables are present.
        # A future public release needs its own reviewed destination contract;
        # changing an owner/name alone cannot safely migrate these asset pins.
        raise ValueError(
            'Legacy private-repository transfer is retired. '
            'No network request or release change was performed. '
            'A reviewed public-repository delivery contract is required.'
        )

    def get(self, suffix):
        request = urllib.request.Request(self.base + suffix, headers=self.headers)
        with self.opener.open(request, timeout=60) as response:
            raw = response.read(8 * 1024 * 1024 + 1)
        require(len(raw) <= 8 * 1024 * 1024, 'Oversized GitHub API response')
        return json.loads(raw)

    def download(self, identity, destination, expected_size):
        request = urllib.request.Request(self.base + f'/actions/artifacts/{identity}/zip', headers=self.headers)
        total = 0
        with self.opener.open(request, timeout=120) as response, destination.open('wb') as output:
            while True:
                block = response.read(1024 * 1024)
                if not block:
                    break
                total += len(block)
                require(total <= expected_size, 'Artifact transfer exceeds expected size')
                output.write(block)
        require(total == expected_size, 'Artifact transfer is incomplete')

    def upload(self, path):
        # Fixed original release ID and host; no server-supplied upload endpoint.
        url = f'https://uploads.github.com/repos/{REPOSITORY}/releases/{RELEASE}/assets?'
        url += urllib.parse.urlencode({'name': path.name})
        headers = {**self.headers, 'Content-Type': 'application/octet-stream'}
        request = urllib.request.Request(url, data=path.read_bytes(), headers=headers, method='POST')
        with self.opener.open(request, timeout=240) as response:
            raw = response.read(1024 * 1024 + 1)
        require(len(raw) <= 1024 * 1024, 'Oversized upload response')
        return json.loads(raw)


def zip_index(archive, max_member=128 * 1024 * 1024, max_total=512 * 1024 * 1024):
    require(len(archive.infolist()) <= 20000, 'Too many ZIP members')
    result = {}
    canonical = set()
    files = set()
    directories = set()
    total = 0
    for info in archive.infolist():
        path = PurePosixPath(info.filename)
        name = str(path)
        require(not path.is_absolute() and '..' not in path.parts and '\\' not in info.filename
                and name == info.filename.rstrip('/') and name not in ('', '.'), 'Unsafe ZIP path')
        import unicodedata
        key = unicodedata.normalize('NFC', name).casefold()
        require(key not in canonical, 'Duplicate or aliased ZIP path')
        canonical.add(key)
        ancestors = [str(PurePosixPath(key).parent)]
        while ancestors[-1] not in ('.', '/'):
            ancestors.append(str(PurePosixPath(ancestors[-1]).parent))
        require(not any(parent in files for parent in ancestors), 'ZIP file used as directory')
        mode = stat.S_IFMT(info.external_attr >> 16)
        require(mode in (0, stat.S_IFREG, stat.S_IFDIR), 'ZIP special file is forbidden')
        require(not info.flag_bits & 1, 'Encrypted ZIP member is forbidden')
        total += info.file_size
        require(0 <= info.file_size <= max_member and total <= max_total, 'ZIP expansion limit exceeded')
        require(info.file_size <= 1024 * 1024 or info.file_size <= max(1, info.compress_size) * 1000,
                'Excessive ZIP compression ratio')
        if info.is_dir():
            require(key not in files, 'ZIP type conflict')
            directories.add(key)
        else:
            require(key not in directories, 'ZIP file/directory conflict')
            files.add(key)
            directories.update(parent for parent in ancestors if parent != '.')
            result[name] = info
    return result


def extract_selected(archive_path, names, destination, kit=False):
    with zipfile.ZipFile(archive_path) as archive:
        index = zip_index(archive)
        selected = {}
        for name in names:
            expected_path = name if kit else 'candidates/' + name
            # upload-artifact computes a common root; kit has the two bare names.
            require(expected_path in index, 'Expected artifact member absent: ' + expected_path)
            selected[name] = index[expected_path]
        if kit:
            require(set(index) == set(names), 'Unexpected native-kit artifact payload')
        for name, info in selected.items():
            size, digest = EXPECTED[name]
            require(info.file_size == size, 'Artifact member size differs from reviewed receipt')
            out = destination / name
            with archive.open(info) as source, out.open('wb') as target:
                while True:
                    block = source.read(1024 * 1024)
                    if not block:
                        break
                    target.write(block)
            validate_file(out, size, digest)


def verify_assets(directory):
    for name, (size, digest) in EXPECTED.items():
        validate_file(directory / name, size, digest)
    load = lambda name: json.loads((directory / name).read_text())
    candidate = load('AppInstaller-candidate-manifest.json')
    kit = load('AppInstaller-native-bootstrap-kit.json')
    library = load('cloud-device-library-manifest.json')
    fixture = load('InstallationCheck-test-fixture.json')
    require(candidate.get('classification') == 'unsigned-candidate' and candidate.get('release_ready') is False,
            'Candidate classification must remain unsigned and unreleased')
    for metadata in (candidate, kit, library):
        require(metadata['source_commit'] == SOURCE_COMMIT
                and metadata['source_tree_sha256'] == candidate['source_tree_sha256'], 'Asset source revision mismatch')
    for artifact in candidate['ipa_artifacts']:
        require((artifact['bytes'], artifact['sha256']) == EXPECTED[artifact['file']], 'Candidate IPA receipt mismatch')
    require({item['file'] for item in candidate['ipa_artifacts']} ==
            {'AppInstaller-iphone-candidate.ipa', 'AppInstaller-duo-candidate.ipa'}, 'Candidate variants missing')
    source = candidate['source_bundle']
    require((source['bytes'], source['sha256']) == EXPECTED[source['file']]
            and source['corresponding_source_verified'] is True and source['relink_instructions_verified'] is True,
            'Source companion receipt mismatch')
    require(kit['corresponding_source']['sha256'] == source['sha256']
            and kit['corresponding_source']['bytes'] == source['bytes']
            and library['source_bundle_sha256'] == source['sha256']
            and library['source_bundle_bytes'] == source['bytes'], 'Kit/library source companion mismatch')
    require(kit['personal_resources_used'] is False and kit['device_install_attempted'] is False,
            'Unexpected personal-resource or installation claim')
    with tarfile.open(directory / source['file'], 'r|xz') as archive:
        first = next(iter(archive))
        require(first.name == 'AppInstaller-source/SourceBundleManifest.json' and first.isfile()
                and first.size <= 32 * 1024 * 1024, 'Source manifest missing or oversized')
        delivered = json.load(archive.extractfile(first))
    for key in ('source_commit', 'source_tree_sha256', 'locked_dependency_graph_hash'):
        require(delivered[key] == candidate[key], 'Delivered corresponding-source binding mismatch')
    require(delivered['source_has_uncommitted_changes'] is False, 'Source bundle was not a clean committed build')
    with zipfile.ZipFile(directory / kit['file']) as archive:
        index = zip_index(archive, max_total=256 * 1024 * 1024)
        prefix = 'AI-Workspace/claude-chatg/'
        manifest_name = prefix + 'BootstrapKitManifest.json'
        require(manifest_name in index and index[manifest_name].file_size <= 4 * 1024 * 1024, 'Inner kit manifest missing')
        payload = json.loads(archive.read(manifest_name))
        require(payload.get('test_fixture') is False and payload['source_commit'] == SOURCE_COMMIT
                and payload['source_tree_sha256'] == candidate['source_tree_sha256']
                and payload['corresponding_source'] == kit['corresponding_source']
                and payload['personal_resources_used'] is False and payload['device_install_attempted'] is False,
                'Inner native-kit provenance mismatch')
        listed = {prefix + item['path']: item for item in payload['files']}
        require(len(listed) == len(payload['files']) and set(index) == set(listed) | {manifest_name}, 'Inner kit closure mismatch')
        for name, entry in listed.items():
            require(PurePosixPath(name).suffix not in {'.p12', '.p8', '.key', '.mobileprovision', '.mobiledevicepairing'},
                    'Credential-shaped file in native kit')
            require(index[name].file_size == entry['bytes']
                    and hashlib.sha256(archive.read(name)).hexdigest() == entry['sha256'], 'Inner native-kit payload mismatch')
        require(archive.read(prefix + payload['library_manifest']) == (directory / 'cloud-device-library-manifest.json').read_bytes(),
                'Inner/external Rust library receipts differ')
    require(fixture.get('test_only') is True and fixture.get('unsigned') is True
            and fixture.get('physical_install_verified') is False and fixture.get('physical_update_verified') is False
            and fixture.get('personal_resources_used') is False, 'Owned fixture classification changed')
    require((fixture['delivery']['bytes'], fixture['delivery']['sha256']) == EXPECTED[fixture['delivery']['file']], 'Fixture delivery receipt mismatch')
    with zipfile.ZipFile(directory / fixture['delivery']['file']) as archive:
        index = zip_index(archive, max_member=1024 * 1024, max_total=4 * 1024 * 1024)
        require(set(index) == {'source/main.m', 'source/LICENSE', 'source/README.md', 'source/build.py',
                               'InstallationCheck-v1.ipa', 'InstallationCheck-v2.ipa'}, 'Owned fixture closure mismatch')
        for entry in fixture['artifacts']:
            data = archive.read(entry['file'])
            require(len(data) == entry['bytes'] and hashlib.sha256(data).hexdigest() == entry['sha256'], 'Owned fixture IPA mismatch')
    return candidate


def validate_release(api):
    repository = api.get('')
    require(repository.get('private') is True and repository.get('full_name') == REPOSITORY, 'Destination must be the private project repository')
    release = api.get(f'/releases/{RELEASE}')
    require(release['id'] == RELEASE and release['draft'] is True and release['tag_name'] == TAG
            and release['target_commitish'] == SOURCE_COMMIT, 'Existing private draft identity changed')
    return release


def asset_matches(item):
    expected = EXPECTED.get(item.get('name'))
    return (expected is not None and item.get('size') == expected[0]
            and item.get('digest') == 'sha256:' + expected[1] and item.get('state') == 'uploaded')


def transfer(root, api):
    validate_release(api)
    run = api.get(f'/actions/runs/{RUN}')
    require(run['id'] == RUN and run['workflow_id'] == WORKFLOW and run['head_sha'] == SOURCE_COMMIT
            and run['path'] == '.github/workflows/app-installer-cloud-ui.yml'
            and run['event'] == 'workflow_dispatch' and run['status'] == 'completed' and run['conclusion'] == 'success'
            and run['repository']['full_name'] == REPOSITORY and run['head_repository']['full_name'] == REPOSITORY,
            'Original cloud build provenance mismatch')
    work = root / 'app-installer/cloud-ui/work'
    work.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='draft-transfer-', dir=work) as temporary:
        stage = Path(temporary)
        for identity, name, size, digest in ARTIFACTS:
            metadata = api.get(f'/actions/artifacts/{identity}')
            require(metadata['id'] == identity and metadata['name'] == name and metadata['expired'] is False
                    and metadata['workflow_run']['id'] == RUN and metadata['size_in_bytes'] == size
                    and metadata['digest'] == 'sha256:' + digest, 'Pinned artifact identity/digest mismatch')
            path = stage / (str(identity) + '.zip')
            api.download(identity, path, size)
            validate_file(path, size, digest)
            extract_selected(path, KIT_NAMES if identity == ARTIFACTS[1][0] else CANDIDATE_NAMES,
                             stage, kit=identity == ARTIFACTS[1][0])
            path.unlink()
        for name in FIXTURE_NAMES:
            data = (root / 'builds' / name).read_bytes()
            (stage / name).write_bytes(data)
        candidate = verify_assets(stage)
        # Everything verifies before any release mutation. Never replace a
        # conflicting asset, delete an asset, publish, tag, or create a release.
        release = validate_release(api)
        existing = release['assets']
        require(len({item['name'] for item in existing}) == len(existing), 'Duplicate draft asset names')
        require(all(asset_matches(item) for item in existing), 'Existing draft has foreign or conflicting assets')
        existing_names = {item['name'] for item in existing}
        order = ['AppInstaller-corresponding-source.tar.xz'] + sorted(set(EXPECTED) - {'AppInstaller-corresponding-source.tar.xz'})
        for name in order:
            if name in existing_names:
                continue
            require(validate_release(api)['draft'] is True, 'Draft state changed during transfer')
            require(asset_matches(api.upload(stage / name)), 'Uploaded asset digest/size mismatch')
            print('Uploaded verified draft asset: ' + name)
        final = validate_release(api)
        require({item['name'] for item in final['assets']} == set(EXPECTED)
                and all(asset_matches(item) for item in final['assets']), 'Final draft asset closure mismatch')
        report = {'schema_version': 1, 'release_id': RELEASE, 'tag_name': TAG, 'draft': True,
                  'classification': 'unsigned-candidate', 'release_ready': False,
                  'original_build_run': RUN, 'original_source_commit': SOURCE_COMMIT,
                  'source_tree_sha256': candidate['source_tree_sha256'],
                  'compilation_performed': False, 'tests_repeated': False,
                  'personal_resources_used': False, 'device_install_attempted': False,
                  'assets': [{'file': name, 'bytes': size, 'sha256': digest} for name, (size, digest) in sorted(EXPECTED.items())]}
        (work / 'draft-transfer-report.json').write_text(json.dumps(report, indent=2) + '\n')
        summary = os.environ.get('GITHUB_STEP_SUMMARY')
        if summary:
            with open(summary, 'a') as stream:
                stream.write('Transferred nine hash-verified assets to the existing private draft. Both apps remain unsigned candidates; `release_ready=false`. Source is retained with its matching native kit. No compile, repeated tests, signing or phone install.\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-local', type=Path, help='Integrity check of existing local files only; no API or release mutation')
    args = parser.parse_args()
    try:
        if args.verify_local:
            verify_assets(args.verify_local.resolve())
            print('Existing nine assets and their source/kit/fixture bindings verified; no API mutation.')
            return 0
        require(os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('GITHUB_REPOSITORY') == REPOSITORY
                and os.environ.get('GITHUB_EVENT_NAME') == 'workflow_dispatch'
                and os.environ.get('GITHUB_WORKFLOW_REF') == REPOSITORY + '/.github/workflows/app-installer-draft-assets.yml@refs/heads/main',
                'Upload is permitted only through the scoped manual hosted workflow')
        transfer(Path(__file__).resolve().parents[2], GitHub(os.environ['GH_TOKEN']))
        return 0
    except Exception as error:
        # Report public validation reasons, never HTTP bodies/headers/tokens.
        print(str(error) if isinstance(error, ValueError) else 'Draft transfer failed; draft remains unpublished. Retry only this transfer after inspecting the failed step.', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
