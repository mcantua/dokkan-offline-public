#!/usr/bin/env python3
"""Transfer a reviewed public build to one unpublished review draft.

Default: validate/describe --contract only, without network or mutation.
--verify-local DIR checks the seven reviewed files without any API calls.
--execute is restricted to the exact manual public-repository workflow.

Contract schema 1: reviewed=true, repository, branch, source_run_id,
source_commit, source_tree_sha256, locked_dependency_graph_hash;
artifacts={candidate:{id,name,bytes,sha256},kit:{id,name,bytes,sha256}};
files={each of FILES:{bytes,sha256}}. Fill from actual reviewed artifacts.
No compiler, tests, helper execution, Apple or personal resources are used.
"""
import argparse
import contextlib
import importlib.util
import io
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import subprocess
import sys
import tarfile
import tempfile
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import zipfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
REPO = 'mcantua/dokkan-offline-public'
BRANCH = 'chatgpt/app-installer-pairing-repair'
WORKFLOW = '.github/workflows/app-installer-promote-draft.yml'
SOURCE_WORKFLOW = 400819284
DELIVERY_WORKFLOW = 400819288
SOURCE_WORKFLOW_PATH = '.github/workflows/app-installer-cloud-ui.yml'
TAG = 'app-installer-public-review'
SOURCE = 'AppInstaller-corresponding-source.tar.xz'
KIT = 'AppInstaller-native-bootstrap-kit.zip'
CANDIDATE = 'AppInstaller-candidate-manifest.json'
KIT_RECEIPT = 'AppInstaller-native-bootstrap-kit.json'
LIBRARY = 'cloud-device-library-manifest.json'
IPAS = frozenset({'AppInstaller-iphone-candidate.ipa', 'AppInstaller-duo-candidate.ipa'})
FILES = frozenset({SOURCE, KIT, CANDIDATE, KIT_RECEIPT, LIBRARY}) | IPAS
ARTIFACT_NAMES = {'candidate': 'app-installer-cloud-ui-latest', 'kit': 'app-installer-native-kit-latest'}
KIT_ROOT = 'AI-Workspace/dokkan-offline-public/'
MAX_FILE = 512 * 1024 * 1024
MAX_ARCHIVE = 768 * 1024 * 1024
SOURCE_COMPONENTS = {'corresponding-application-source', 'complete-library-source', 'exact-locked-transitive-source',
    'modified-path-dependency-source', 'universal-macos-helper-source', 'build-relink-recipes',
    'recipient-installation-information', 'complete-licenses-and-notices'}


class DeliveryError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise DeliveryError(message)


def digest(value, length=64):
    return isinstance(value, str) and re.fullmatch('[0-9a-f]{' + str(length) + '}', value) is not None


def positive(value, maximum=10**15):
    return type(value) is int and 0 < value <= maximum


def sha_file(path):
    value = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(block)
    return value.hexdigest()


def checked_relative(name):
    require(isinstance(name, str) and '\\' not in name and '\x00' not in name, 'Invalid archive path')
    path = PurePosixPath(name)
    require(not path.is_absolute() and '..' not in path.parts and str(path) == name.rstrip('/')
            and str(path) not in ('', '.') and not re.match(r'^[A-Za-z]:', name), 'Unsafe archive path')
    return str(path)


def validate_contract(value):
    require(type(value) is dict and type(value.get('schema_version')) is int and value['schema_version'] == 1 and value.get('reviewed') is True,
            'A reviewed version-1 public delivery contract is required')
    require(value.get('repository') == REPO and value.get('branch') == BRANCH, 'Contract destination is not the authorized public repository/branch')
    require(positive(value.get('source_run_id')) and digest(value.get('source_commit'), 40)
            and digest(value.get('source_tree_sha256')) and digest(value.get('locked_dependency_graph_hash')), 'Invalid source provenance pins')
    require(set(value.get('artifacts', {})) == set(ARTIFACT_NAMES), 'Exactly the candidate and kit artifacts must be pinned')
    ids = set()
    for kind, name in ARTIFACT_NAMES.items():
        artifact = value['artifacts'][kind]
        require(type(artifact) is dict and artifact.get('name') == name and positive(artifact.get('id'))
                and positive(artifact.get('bytes'), MAX_ARCHIVE) and digest(artifact.get('sha256')), 'Invalid artifact identity/digest pin')
        ids.add(artifact['id'])
    require(len(ids) == 2 and set(value.get('files', {})) == FILES, 'Artifact IDs or seven-file closure are invalid')
    for name, item in value['files'].items():
        require(type(item) is dict and positive(item.get('bytes'), MAX_FILE) and digest(item.get('sha256')), 'Invalid reviewed file digest/size')
    return value


def validate_file(path, pin):
    require(path.is_file() and not path.is_symlink() and path.stat().st_size == pin['bytes']
            and sha_file(path) == pin['sha256'], 'Reviewed file digest/size mismatch')


def zip_index(archive, max_member=MAX_FILE, max_total=1024 * 1024 * 1024):
    require(len(archive.infolist()) <= 25000, 'ZIP member count exceeds bound')
    result, names, files, directories, total = {}, set(), set(), set(), 0
    for item in archive.infolist():
        name = checked_relative(item.filename)
        folded = unicodedata.normalize('NFC', name).casefold()
        require(folded not in names, 'ZIP has duplicate or aliased paths')
        names.add(folded)
        parents = [str(parent) for parent in PurePosixPath(folded).parents if str(parent) != '.']
        require(not any(parent in files for parent in parents), 'ZIP file is used as a directory')
        mode = stat.S_IFMT(item.external_attr >> 16)
        require(mode in (0, stat.S_IFREG, stat.S_IFDIR) and not item.flag_bits & 1, 'ZIP has a special/encrypted member')
        total += item.file_size
        require(0 <= item.file_size <= max_member and total <= max_total, 'ZIP expansion exceeds bounds')
        require(item.file_size <= 1024 * 1024 or item.file_size <= max(1, item.compress_size) * 1000, 'ZIP compression ratio exceeds bound')
        if item.is_dir():
            require(folded not in files and mode in (0, stat.S_IFDIR), 'ZIP path type conflict')
            directories.add(folded)
        else:
            require(folded not in directories and mode != stat.S_IFDIR, 'ZIP path type conflict')
            files.add(folded)
            directories.update(parents)
            result[name] = item
    return result


def bounded_json(data, limit=4 * 1024 * 1024):
    require(len(data) <= limit, 'Metadata exceeds size bound')
    return json.loads(data)


_MODULES = {}


def project_module(name, relative):
    """Import only reviewed checkout validators, never code extracted from assets."""
    if name not in _MODULES:
        path = ROOT / relative
        require(path.is_file() and not path.is_symlink(), 'Reviewed verification module is unavailable')
        build = str(ROOT / 'app-installer/build')
        if build not in sys.path:
            sys.path.insert(0, build)
        spec = importlib.util.spec_from_file_location('public_delivery_' + name, path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        _MODULES[name] = module
    return _MODULES[name]


def source_manifest(path, contract):
    # This existing verifier recomputes the delivered fingerprint and full locked
    # device/helper/runtime/registry/path-source closure. Listed hashes and flags
    # alone are insufficient source-delivery evidence.
    try:
        result = project_module('source_bundle', 'app-installer/build/source-bundle.py').verify(
            path, contract['source_tree_sha256'], contract['locked_dependency_graph_hash'])
    except Exception:
        raise DeliveryError('Complete source/fingerprint/locked dependency verification failed') from None
    require(result.get('test_fixture') is False and result.get('source_has_uncommitted_changes') is False,
            'Source must be a genuine clean distribution')
    for key in ('source_commit', 'source_tree_sha256', 'locked_dependency_graph_hash'):
        require(result.get(key) == contract[key], 'Source provenance binding differs from contract')
    return result


def verify_candidate_integrity(directory, contract):
    # Includes source-bundle.verify, actual IPA structure/Mach-O checks and the
    # genuine SDK/toolchain equality checks; performs no build or Cargo metadata.
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            result = project_module('candidate', 'app-installer/build/verify-candidate.py').verify(
                directory / CANDIDATE, directory)
    except Exception:
        raise DeliveryError('Existing genuine candidate/source/Mach-O verification failed') from None
    require(result.get('candidate_integrity_verified') is True and result.get('release_ready') is False
            and result.get('source_commit') == contract['source_commit']
            and result.get('source_tree_sha256') == contract['source_tree_sha256']
            and result.get('locked_dependency_graph_hash') == contract['locked_dependency_graph_hash'],
            'Strong candidate verification differs from reviewed contract')


def verify_ipa_integrity(path, variant, metadata, toolchain):
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            project_module('artifact', 'app-installer/build/check-artifact.py').check(path, variant)
        project_module('candidate', 'app-installer/build/verify-candidate.py').require_genuine(metadata, toolchain)
    except Exception:
        raise DeliveryError('IPA executable/platform/SDK/toolchain verification failed') from None


def encoded_version(value):
    require(isinstance(value, str) and re.fullmatch(r'\d+(?:\.\d+){0,2}', value), 'Invalid genuine macOS SDK version')
    fields = list(map(int, value.split('.')))
    fields += [0] * (3 - len(fields))
    require(0 < fields[0] <= 65535 and all(0 <= part <= 255 for part in fields[1:]), 'Invalid encoded SDK version')
    return fields[0] << 16 | fields[1] << 8 | fields[2]


def verify_helper_macho(binary, receipt):
    """Check both actual universal slices against the genuine build receipt."""
    toolchain = receipt.get('genuine_toolchain')
    require(type(toolchain) is dict and all(isinstance(toolchain.get(key), str) and toolchain[key]
            for key in ('rustc', 'xcode', 'clang', 'macos_sdk', 'sdk_settings_sha256')),
            'Helper genuine toolchain receipt is incomplete')
    require(re.match(r'^rustc 1\.99\.1 ', toolchain['rustc']) is not None
            and re.search(r'(?m)^Xcode \d+(?:\.\d+)*$', toolchain['xcode']) is not None
            and digest(toolchain['sdk_settings_sha256']), 'Helper compiler/SDK provenance is invalid')
    sdk = encoded_version(toolchain['macos_sdk'])
    require(sdk >= (12 << 16), 'Helper genuine macOS SDK is too old')
    require(len(binary) >= 8, 'Truncated universal helper')
    magic, count = struct.unpack_from('>II', binary)
    require(magic in (0xCAFEBABE, 0xCAFEBABF) and count == 2, 'Helper must contain exactly two universal Mach-O slices')
    record_size = 20 if magic == 0xCAFEBABE else 32
    table_end = 8 + count * record_size
    require(len(binary) >= table_end, 'Truncated universal helper architecture table')
    wanted = {0x0100000C: 'arm64', 0x01000007: 'x86_64'}
    seen, ranges = set(), []
    for index in range(count):
        if record_size == 20:
            cpu, subtype, offset, size, alignment = struct.unpack_from('>IIIII', binary, 8 + index * record_size)
        else:
            cpu, subtype, offset, size, alignment, reserved = struct.unpack_from('>IIQQII', binary, 8 + index * record_size)
            require(reserved == 0, 'Unsupported universal helper reserved field')
        require(cpu in wanted and cpu not in seen and size >= 32 and alignment <= 30
                and offset >= table_end and offset % (1 << alignment) == 0 and offset + size <= len(binary),
                'Invalid or unexpected universal helper slice')
        require(all(offset + size <= old_start or offset >= old_end for old_start, old_end in ranges),
                'Overlapping universal helper slices')
        seen.add(cpu); ranges.append((offset, offset + size))
        data = memoryview(binary)[offset:offset + size]
        header = struct.unpack_from('<8I', data)
        require(header[0] == 0xFEEDFACF and header[1] == cpu and header[2] == subtype and header[3] == 2,
                'Helper slice is not the expected executable architecture')
        count_commands, command_bytes = header[4:6]
        require(count_commands <= 4096 and 32 + command_bytes <= len(data), 'Invalid helper load-command bounds')
        cursor, end, versions, signatures = 32, 32 + command_bytes, [], []
        for _ in range(count_commands):
            require(cursor + 8 <= end, 'Truncated helper load command')
            command, length = struct.unpack_from('<II', data, cursor)
            require(length >= 8 and length % 8 == 0 and cursor + length <= end, 'Malformed helper load command')
            if command == 0x32:
                require(length >= 24, 'Truncated helper build-version command')
                platform, minimum, actual_sdk, tools = struct.unpack_from('<IIII', data, cursor + 8)
                require(24 + tools * 8 <= length, 'Truncated helper build tools')
                versions.append((platform, minimum, actual_sdk))
            elif command == 0x1D:
                require(length == 16, 'Invalid helper code-signature command')
                start, amount = struct.unpack_from('<II', data, cursor + 8)
                require(start >= end and amount > 0 and start + amount == len(data),
                        'Helper code signature does not cover the final slice layout')
                signatures.append((start, amount))
            cursor += length
        require(cursor == end and versions == [(1, 12 << 16, sdk)] and len(signatures) == 1,
                'Helper actual platform/minimum/SDK/signature differ from receipt')
        text = receipt.get('mach_o_build_versions', {}).get(wanted[cpu])
        require(isinstance(text, str) and re.search(r'platform\s+MACOS\b', text)
                and re.search(r'minos\s+12\.0(?:\.0)?(?:\s|$)', text)
                and any(encoded_version(value) == sdk for value in re.findall(r'\bsdk\s+(\d+(?:\.\d+){0,2})', text)),
                'Helper original per-slice build receipt is missing/inconsistent')
    require(seen == set(wanted), 'Universal helper architecture closure is incomplete')


def verify_helper_signature(path):
    # Ad-hoc seal verification requires macOS's supported verifier. There is no
    # Linux skip, signature simulation, binary execution or re-signing here.
    require(sys.platform == 'darwin' and Path('/usr/bin/codesign').is_file(),
            'Public delivery requires hosted macOS for genuine helper code-signature verification')
    try:
        result = subprocess.run(['/usr/bin/codesign', '--verify', '--strict', '--all-architectures', str(path)],
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=60)
        require(result.returncode == 0, 'Helper actual code-signature integrity verification failed')
        for architecture in ('arm64', 'x86_64'):
            display = subprocess.run(['/usr/bin/codesign', '--display', '--verbose=4', '--architecture', architecture, str(path)],
                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
            require(display.returncode == 0 and b'Signature=adhoc' in display.stderr.splitlines(),
                    'Helper actual per-slice signature is not the reviewed ad-hoc seal')
    except (OSError, subprocess.TimeoutExpired):
        raise DeliveryError('Helper code-signature verification could not finish safely') from None


def verify_helper_payload(inner, listed, index, archive, contract, delivered, stage):
    workflow = project_module('device_workflow', 'app-installer/device/device-workflow.py')
    paths = workflow.RP_HELPER_PATHS
    required = {KIT_ROOT + relative for relative in paths.values()}
    require(required <= set(listed) and all(inner.get('secure_rp_tool', {}).get(key) == value
            for key, value in paths.items()), 'Required fixed helper receipt/binary/notices files are missing')
    helper_files = {}
    for key, relative in paths.items():
        name = KIT_ROOT + relative
        require(index[name].file_size <= (128 * 1024 * 1024 if key == 'binary' else 16 * 1024 * 1024),
                'Helper payload exceeds safe byte bound')
        target = stage / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        with archive.open(index[name]) as source, target.open('xb') as output:
            value, total = hashlib.sha256(), 0
            for block in iter(lambda: source.read(1024 * 1024), b''):
                total += len(block)
                require(total <= listed[name]['bytes'], 'Helper member exceeds its reviewed size')
                value.update(block); output.write(block)
        require(total == listed[name]['bytes'] and value.hexdigest() == listed[name]['sha256'], 'Staged helper file digest mismatch')
        if key == 'binary':
            require(listed[name].get('mode') == 0o755 and stat.S_IMODE(index[name].external_attr >> 16) == 0o755,
                    'Helper must retain the reviewed executable mode')
            target.chmod(0o755)
        helper_files[key] = target
    try:
        workflow.validate_remote_pairing_tool(inner, base=stage)
    except Exception:
        raise DeliveryError('Deep helper source/graph/notices/sealed-receipt validation failed') from None
    receipt = bounded_json(helper_files['manifest'].read_bytes())
    report = bounded_json(helper_files['notice_report'].read_bytes(), 16 * 1024 * 1024)
    source_files = {row['path']: row for row in delivered['files']}
    source_graphs = [row for row in delivered['distribution_graphs'] if row['target'] in ('aarch64-apple-darwin', 'x86_64-apple-darwin')]
    require(receipt.get('distribution_graphs') == source_graphs and len(source_graphs) == 2
            and receipt.get('locked_dependency_graph_hash') == contract['locked_dependency_graph_hash']
            and report.get('distribution_graphs') == delivered['distribution_graphs']
            and report.get('locked_dependency_graph_hash') == contract['locked_dependency_graph_hash'],
            'Helper/source/notice actual dependency closures disagree')
    for row in source_graphs:
        value = hashlib.sha256(json.dumps(row, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
        require(receipt['target_graph_hashes'].get(row['target']) == value, 'Helper feature graph is not the delivered locked source closure')
    require(sha_file(helper_files['notices']) == source_files['ThirdPartyNotices.txt']['sha256']
            and all(report.get('corresponding_source', {}).get(key) == contract['files'][SOURCE].get(key)
                    for key in ('bytes', 'sha256'))
            and report.get('corresponding_source', {}).get('file') == SOURCE,
            'Helper notices/source archive binding mismatch')
    verify_helper_macho(helper_files['binary'].read_bytes(), receipt)
    verify_helper_signature(helper_files['binary'])


def verify_local(directory, contract):
    for name in FILES:
        validate_file(directory / name, contract['files'][name])
    # Bound metadata before the existing verifiers read/parse it. Nothing is
    # extracted/executed; the actual executable must also be present.
    for name in IPAS:
        with zipfile.ZipFile(directory / name) as archive:
            index = zip_index(archive, max_member=128 * 1024 * 1024, max_total=512 * 1024 * 1024)
            prefix = 'Payload/AppInstaller.app/'
            for required, maximum in {'Info.plist':1024 * 1024, 'AppInstaller':128 * 1024 * 1024,
                    'BuildMetadata.json':4 * 1024 * 1024, 'ThirdPartyNoticeReport.json':16 * 1024 * 1024,
                    'ThirdPartyNotices.txt':16 * 1024 * 1024}.items():
                require(prefix + required in index and 0 < index[prefix + required].file_size <= maximum,
                        'IPA required executable/metadata is missing or oversized')
    verify_candidate_integrity(directory, contract)
    load = lambda name: bounded_json((directory / name).read_bytes())
    candidate, kit, library = load(CANDIDATE), load(KIT_RECEIPT), load(LIBRARY)
    require(candidate.get('classification') == 'unsigned-candidate' and candidate.get('release_ready') is False
            and not candidate.get('test_fixture'), 'Only unsigned unreleased candidates may be transferred')
    licensing = candidate.get('licensing', {})
    require(licensing.get('notices_verified') is True and licensing.get('unresolved_notice_cases') == 0
            and licensing.get('corresponding_source_verified') is True and licensing.get('relink_instructions_verified') is True,
            'Candidate source/relink/notice verification is incomplete')
    for item in (candidate, kit, library):
        require(item.get('source_commit') == contract['source_commit'] and item.get('source_tree_sha256') == contract['source_tree_sha256'], 'Candidate/kit/library provenance mismatch')
        require(item.get('release_ready', False) is False and item.get('unsigned', True) is True, 'A distribution receipt claims signed/release-ready products')
    require(candidate.get('locked_dependency_graph_hash') == contract['locked_dependency_graph_hash']
            and library.get('locked_dependency_graph_hash') == contract['locked_dependency_graph_hash'] and library.get('unsigned') is True,
            'Library graph or unsigned classification mismatch')
    source = candidate['source_bundle']
    require(source.get('file') == SOURCE and all(source.get(key) == contract['files'][SOURCE][key] for key in ('bytes', 'sha256'))
            and source.get('corresponding_source_verified') is True and source.get('relink_instructions_verified') is True,
            'Corresponding-source receipt mismatch')
    require(kit.get('file') == KIT and all(kit.get(key) == contract['files'][KIT][key] for key in ('bytes', 'sha256'))
            and kit.get('bootstrap_tool_commit') == contract['source_commit'] and kit.get('minimal_bootstrap_kit') is True
            and kit.get('personal_resources_used') is False and kit.get('device_install_attempted') is False,
            'Kit receipt or personal-resource scope mismatch')
    require(all(kit['corresponding_source'].get(key) == source[key] for key in ('file', 'bytes', 'sha256'))
            and library.get('source_bundle_sha256') == source['sha256'] and library.get('source_bundle_bytes') == source['bytes'], 'Source companion bindings disagree')
    delivered = source_manifest(directory / SOURCE, contract)
    source_files = {item['path']: item for item in delivered['files']}
    variants = candidate.get('ipa_artifacts', [])
    require(len(variants) == 2 and {item.get('file') for item in variants} == IPAS
            and {item.get('variant') for item in variants} == {'iphone', 'duo'}, 'Both reviewed IPA variants are required')
    for item in variants:
        require(all(item.get(key) == contract['files'][item['file']][key] for key in ('bytes', 'sha256')), 'Candidate IPA receipt mismatch')
        with zipfile.ZipFile(directory / item['file']) as archive:
            index = zip_index(archive)
            require(not any(name.endswith('.mobileprovision') or '/_CodeSignature/' in name for name in index), 'Personal signed product is forbidden')
            prefix = 'Payload/AppInstaller.app/'
            metadata = bounded_json(archive.read(index[prefix + 'BuildMetadata.json']))
            notices = bounded_json(archive.read(index[prefix + 'ThirdPartyNoticeReport.json']))
            verify_ipa_integrity(directory / item['file'], item['variant'], metadata, candidate.get('genuine_toolchain'))
            for key in ('source_commit', 'source_tree_sha256', 'locked_dependency_graph_hash'):
                require(metadata.get(key) == contract[key], 'IPA/source provenance mismatch')
            require(metadata.get('unsigned') is True and metadata.get('designation') == 'unsigned-candidate'
                    and metadata.get('source_has_uncommitted_changes') is False and metadata.get('synthetic_sdk_marker') is False
                    and metadata.get('source_bundle_sha256') == source['sha256'] and metadata.get('phone_install_attempted') is False,
                    'IPA must remain a genuine unsigned, uninstalled candidate')
            require(notices.get('release_license_ready') is True and notices.get('notice_obligations_satisfied') is True
                    and notices.get('notice_gap_count') == 0 and notices.get('locked_dependency_graph_hash') == contract['locked_dependency_graph_hash'],
                    'IPA licensing obligations are unresolved')
            require(hashlib.sha256(archive.read(index[prefix + 'ThirdPartyNotices.txt'])).hexdigest() == source_files['ThirdPartyNotices.txt']['sha256'], 'Shipped notices differ from delivered source')
    with zipfile.ZipFile(directory / KIT) as archive:
        index = zip_index(archive)
        inner_name = KIT_ROOT + 'BootstrapKitManifest.json'
        require(inner_name in index and 0 < index[inner_name].file_size <= 4 * 1024 * 1024,
                'Public native-kit manifest is missing or oversized')
        inner = bounded_json(archive.read(index[inner_name]))
        require(inner.get('project') == 'dokkan-offline-public' and inner.get('source_repository') == REPO
                and inner.get('test_fixture') is False and inner.get('source_commit') == contract['source_commit']
                and inner.get('bootstrap_tool_commit') == contract['source_commit'] and inner.get('source_tree_sha256') == contract['source_tree_sha256']
                and inner.get('corresponding_source') == kit['corresponding_source'] and inner.get('personal_resources_used') is False
                and inner.get('device_install_attempted') is False, 'Public native-kit provenance/scope mismatch')
        require(inner.get('release_ready', False) is False and inner.get('unsigned', True) is True, 'Native kit cannot claim a signed final release')
        listed = {}
        for entry in inner.get('files', []):
            name = KIT_ROOT + checked_relative(entry['path'])
            require(name not in listed and type(entry.get('bytes')) is int and 0 <= entry['bytes'] <= MAX_FILE
                    and digest(entry.get('sha256')), 'Invalid native-kit file binding')
            require(PurePosixPath(name).suffix.lower() not in {'.p12', '.p8', '.key', '.mobileprovision', '.mobiledevicepairing', '.pem'}, 'Private credential-shaped kit file is forbidden')
            listed[name] = entry
        require(set(index) == set(listed) | {inner_name}, 'Native-kit payload closure mismatch')
        for name, entry in listed.items():
            data = archive.read(index[name])
            require(len(data) == entry['bytes'] and hashlib.sha256(data).hexdigest() == entry['sha256'], 'Native-kit member digest/size mismatch')
        library_name = KIT_ROOT + checked_relative(inner['library_manifest'])
        require(archive.read(index[library_name]) == (directory / LIBRARY).read_bytes(), 'Inner/external library manifests differ')
        library_binary = KIT_ROOT + checked_relative(inner['rust_library'])
        require(library_binary in listed and library.get('target') == 'aarch64-apple-ios'
                and all(listed[library_binary][key] == library.get(key) for key in ('bytes', 'sha256')), 'Delivered native library and its receipt disagree')
        required_source = {'app-installer/LICENSE', 'app-installer/licensing-signing.md',
            'app-installer/core/app_installer.h', 'app-installer/core/secure_storage.h',
            'app-installer/device/.gitignore', 'app-installer/device/PUBLIC-CONTINUATION.md',
            'app-installer/device/device-workflow.py', 'app-installer/device/setup-wizard.py',
            'app-installer/device/Run-App-Installer-Setup.command'}
        required_source.update(name for name in source_files if name.startswith('app-installer/ios/')
                               and PurePosixPath(name).suffix in ('.m', '.h', '.plist', '.png'))
        require(required_source <= set(source_files) and {KIT_ROOT + name for name in required_source} <= set(listed),
                'Native kit omits required source/runtime marker inputs')
        for name in required_source:
            require(all(listed[KIT_ROOT + name][key] == source_files[name][key] for key in ('bytes', 'sha256')),
                    'Native kit source differs from delivered corresponding source')
        native_sources = {name for name in required_source if name.startswith('app-installer/ios/')
                          and PurePosixPath(name).suffix in ('.m', '.h')}
        require(set(inner.get('native_sources', [])) == native_sources, 'Native compilation source closure differs')
        helper = inner.get('secure_rp_tool', {})
        require(helper.get('source_commit') == contract['source_commit'] and helper.get('source_tree_sha256') == contract['source_tree_sha256']
                and helper.get('format_key') == 'format_version' and helper.get('protocol_record_version') == 2
                and helper.get('peer_pin_required') is True, 'Native helper peer-pinned format provenance is incomplete')
        work = ROOT / 'app-installer/cloud-ui/work'
        work.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='public-delivery-helper-', dir=work) as temporary:
            verify_helper_payload(inner, listed, index, archive, contract, delivered, Path(temporary))
    return candidate


class RejectRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        raise DeliveryError('Unexpected redirect from scoped GitHub API')


class ArtifactRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        parsed = urllib.parse.urlsplit(newurl)
        host = parsed.hostname or ''
        require(parsed.scheme == 'https' and parsed.port in (None, 443) and not parsed.username and not parsed.password
                and (host.endswith('.blob.core.windows.net') or host.endswith('.actions.githubusercontent.com')),
                'Artifact redirect is not approved GitHub storage')
        # Never forward the repository token, even to another GitHub hostname.
        return urllib.request.Request(newurl, headers={'User-Agent': 'AppInstaller-public-delivery'})


def require_execution_scope():
    require(os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('GITHUB_REPOSITORY') == REPO
            and os.environ.get('GITHUB_REF') == 'refs/heads/' + BRANCH and os.environ.get('GITHUB_EVENT_NAME') == 'workflow_dispatch'
            and os.environ.get('GITHUB_WORKFLOW_REF') == REPO + '/' + WORKFLOW + '@refs/heads/' + BRANCH,
            'Execution requires the exact authorized manual public workflow')


class PublicGitHub:
    def __init__(self):
        require_execution_scope()
        token = os.environ.get('GH_TOKEN')
        require(isinstance(token, str) and token, 'The scoped workflow token is unavailable')
        self.base = 'https://api.github.com/repos/' + REPO
        self.headers = {'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28', 'User-Agent': 'AppInstaller-public-delivery'}
        self.opener = urllib.request.build_opener(RejectRedirect())

    def request(self, method, suffix, body=None, optional=False):
        require(suffix.startswith('/') or suffix == '', 'Invalid scoped API path')
        require('..' not in suffix and '://' not in suffix, 'Invalid scoped API path')
        data = json.dumps(body).encode() if body is not None else None
        request = urllib.request.Request(self.base + suffix, data=data, headers={**self.headers, 'Content-Type': 'application/json'}, method=method)
        try:
            with self.opener.open(request, timeout=120) as response:
                raw = response.read(8 * 1024 * 1024 + 1)
        except urllib.error.HTTPError as error:
            if optional and error.code == 404:
                error.close(); return None
            error.close(); raise DeliveryError('Scoped GitHub API request failed') from None
        return bounded_json(raw, 8 * 1024 * 1024) if raw else None

    def download(self, identity, destination, pin):
        require(positive(identity), 'Invalid artifact identity')
        request = urllib.request.Request(self.base + f'/actions/artifacts/{identity}/zip', headers=self.headers)
        opener = urllib.request.build_opener(ArtifactRedirect())
        count = 0
        with opener.open(request, timeout=120) as response, destination.open('xb') as output:
            while True:
                block = response.read(1024 * 1024)
                if not block:
                    break
                count += len(block)
                require(count <= pin['bytes'], 'Artifact download exceeds reviewed bound')
                output.write(block)
        validate_file(destination, pin)

    def upload(self, release, path, name):
        require(positive(release), 'Invalid draft release identity')
        url = f'https://uploads.github.com/repos/{REPO}/releases/{release}/assets?' + urllib.parse.urlencode({'name': name})
        request = urllib.request.Request(url, data=path.read_bytes(), headers={**self.headers, 'Content-Type': 'application/octet-stream'}, method='POST')
        with self.opener.open(request, timeout=240) as response:
            raw = response.read(1024 * 1024 + 1)
        return bounded_json(raw, 1024 * 1024)


def asset_matches(asset, pin, name):
    return (asset.get('name') == name and asset.get('state') == 'uploaded' and asset.get('size') == pin['bytes']
            and asset.get('digest') == 'sha256:' + pin['sha256'] and positive(asset.get('id')))


def checked_release(api, identity):
    release = api.request('GET', f'/releases/{identity}')
    require(release.get('id') == identity and release.get('tag_name') == TAG and release.get('draft') is True,
            'Review release identity or draft state changed')
    return release


def verify_review_tag(api, source):
    tag = api.request('GET', '/git/ref/tags/' + TAG, optional=True)
    if tag is not None:
        require(tag.get('ref') == 'refs/tags/' + TAG and tag.get('object', {}).get('type') == 'commit'
                and tag.get('object', {}).get('sha') == source, 'Existing review tag differs from the reviewed source; no tag was retargeted')


def release_assets(api, identity):
    values = []
    for page in range(1, 11):
        batch = api.request('GET', f'/releases/{identity}/assets?per_page=100&page={page}')
        require(type(batch) is list, 'Invalid draft asset list')
        values.extend(batch)
        if len(batch) < 100:
            require(len({item.get('name') for item in values}) == len(values), 'Duplicate draft asset names')
            return values
    raise DeliveryError('Draft asset list exceeds bound')


def execute(contract, contract_sha):
    require_execution_scope()
    api = PublicGitHub()
    execution_id = int(os.environ.get('GITHUB_RUN_ID', '0'))
    require(positive(execution_id), 'Hosted delivery run identity is missing')
    execution = api.request('GET', f'/actions/runs/{execution_id}')
    require(execution.get('workflow_id') == DELIVERY_WORKFLOW and execution.get('path') == WORKFLOW
            and execution.get('event') == 'workflow_dispatch' and execution.get('head_branch') == BRANCH
            and execution.get('head_sha') == os.environ.get('GITHUB_SHA')
            and execution.get('repository', {}).get('full_name') == REPO
            and execution.get('head_repository', {}).get('full_name') == REPO, 'Hosted delivery workflow provenance mismatch')
    repo = api.request('GET', '')
    require(repo.get('full_name') == REPO and repo.get('private') is False and repo.get('archived') is False, 'Destination must be the active public repository')
    run = api.request('GET', f"/actions/runs/{contract['source_run_id']}")
    require(run.get('id') == contract['source_run_id'] and run.get('workflow_id') == SOURCE_WORKFLOW
            and run.get('path') == SOURCE_WORKFLOW_PATH and run.get('head_branch') == BRANCH and run.get('head_sha') == contract['source_commit']
            and run.get('status') == 'completed' and run.get('conclusion') == 'success' and run.get('event') == 'workflow_dispatch'
            and run.get('repository', {}).get('full_name') == REPO and run.get('head_repository', {}).get('full_name') == REPO,
            'Reviewed source build run provenance does not match')
    work = ROOT / 'app-installer/cloud-ui/work'
    work.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='public-delivery-', dir=work) as temporary:
        stage = Path(temporary)
        for kind, pin in contract['artifacts'].items():
            metadata = api.request('GET', f"/actions/artifacts/{pin['id']}")
            require(metadata.get('id') == pin['id'] and metadata.get('name') == pin['name'] and metadata.get('expired') is False
                    and metadata.get('workflow_run', {}).get('id') == contract['source_run_id']
                    and metadata.get('workflow_run', {}).get('head_sha') == contract['source_commit']
                    and metadata.get('size_in_bytes') == pin['bytes'] and metadata.get('digest') == 'sha256:' + pin['sha256'], 'Reviewed artifact metadata mismatch')
            archive_path = stage / (kind + '.zip')
            api.download(pin['id'], archive_path, pin)
            names = {KIT, KIT_RECEIPT} if kind == 'kit' else FILES - {KIT, KIT_RECEIPT}
            with zipfile.ZipFile(archive_path) as archive:
                index = zip_index(archive)
                if kind == 'kit':
                    require(set(index) == names, 'Unexpected kit artifact payload')
                for name in names:
                    member = name if kind == 'kit' else 'candidates/' + name
                    require(member in index and index[member].file_size == contract['files'][name]['bytes'], 'Reviewed artifact member is missing/mismatched')
                    with archive.open(index[member]) as source, (stage / name).open('xb') as output:
                        count = 0
                        while True:
                            block = source.read(1024 * 1024)
                            if not block:
                                break
                            count += len(block)
                            require(count <= contract['files'][name]['bytes'], 'Artifact member exceeds reviewed bound')
                            output.write(block)
            archive_path.unlink()
        candidate = verify_local(stage, contract)
        verify_review_tag(api, contract['source_commit'])
        release = api.request('GET', '/releases/tags/' + TAG, optional=True)
        if release is None:
            release = api.request('POST', '/releases', {'tag_name': TAG, 'target_commitish': contract['source_commit'], 'name': 'App Installer — unsigned public review', 'draft': True, 'prerelease': True, 'make_latest': 'false', 'body': 'Unsigned review candidates with complete corresponding source. Physical acceptance is pending; release_ready=false.'})
        identity = release['id']
        checked_release(api, identity)
        assets = release_assets(api, identity)
        pending_pattern = re.compile(r'pending-[0-9a-f]{12}--(.+)')
        require(all(item['name'] in FILES or (pending_pattern.fullmatch(item['name']) and pending_pattern.fullmatch(item['name']).group(1) in FILES) for item in assets), 'Foreign assets exist in the dedicated draft; none were changed')
        staged = {}
        for name in sorted(FILES):
            canonical = next((item for item in assets if asset_matches(item, contract['files'][name], name)), None)
            pending_name = 'pending-' + contract_sha[:12] + '--' + name
            pending = next((item for item in assets if item['name'] == pending_name), None)
            if canonical:
                staged[name] = canonical
            elif pending:
                require(asset_matches(pending, contract['files'][name], pending_name), 'Conflicting staged asset; existing draft retained')
                staged[name] = pending
            else:
                checked_release(api, identity)
                staged[name] = api.upload(identity, stage / name, pending_name)
                require(asset_matches(staged[name], contract['files'][name], pending_name), 'Staged server asset digest/size mismatch')
        # All seven replacement bytes are on the server and verified before any
        # old canonical name is deleted. An interrupted rename is resumable.
        for name, item in staged.items():
            current = api.request('GET', f"/releases/assets/{item['id']}")
            require(asset_matches(current, contract['files'][name], item['name']), 'Staged asset changed before replacement')
        for name, item in staged.items():
            if item['name'] == name:
                continue
            checked_release(api, identity)
            for old in release_assets(api, identity):
                if old['name'] == name:
                    api.request('DELETE', f"/releases/assets/{old['id']}")
            checked_release(api, identity)
            updated = api.request('PATCH', f"/releases/assets/{item['id']}", {'name': name})
            require(asset_matches(updated, contract['files'][name], name), 'Canonical draft asset verification failed')
        checked_release(api, identity)
        api.request('PATCH', f'/releases/{identity}', {'tag_name': TAG, 'target_commitish': contract['source_commit'], 'draft': True, 'prerelease': True, 'make_latest': 'false'})
        for item in release_assets(api, identity):
            if item['name'] not in FILES:
                match = pending_pattern.fullmatch(item['name'])
                require(match is not None and match.group(1) in FILES, 'A foreign draft asset appeared during transfer; it was retained')
                checked_release(api, identity)
                api.request('DELETE', f"/releases/assets/{item['id']}")
        final = checked_release(api, identity)
        verify_review_tag(api, contract['source_commit'])
        final_assets = release_assets(api, identity)
        require(final.get('target_commitish') == contract['source_commit'] and {item['name'] for item in final_assets} == FILES
                and all(asset_matches(item, contract['files'][item['name']], item['name']) for item in final_assets), 'Final seven-asset draft closure/provenance failed')
        receipt = {'schema_version': 1, 'repository': REPO, 'branch': BRANCH, 'release_id': identity, 'tag_name': TAG, 'draft': True,
            'source_workflow_id': SOURCE_WORKFLOW, 'source_run_id': contract['source_run_id'], 'source_commit': contract['source_commit'],
            'source_tree_sha256': candidate['source_tree_sha256'], 'locked_dependency_graph_hash': candidate['locked_dependency_graph_hash'],
            'contract_sha256': contract_sha, 'classification': 'unsigned-candidate', 'release_ready': False,
            'compilation_performed': False, 'tests_repeated': False, 'personal_resources_used': False, 'device_install_attempted': False,
            'assets': [{'file': item['name'], 'id': item['id'], 'bytes': item['size'], 'sha256': item['digest'][7:]} for item in final_assets]}
        (work / 'public-delivery-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
        print('Verified seven public review draft assets; unpublished and unsigned, release_ready=false.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--contract', type=Path, required=True)
    parser.add_argument('--verify-local', type=Path)
    parser.add_argument('--execute', action='store_true')
    args = parser.parse_args()
    try:
        path = args.contract.resolve()
        path.relative_to(ROOT)
        require(path.is_file() and not args.contract.is_symlink() and path.stat().st_size <= 65536, 'Reviewed repository-local contract is missing/oversized')
        raw = path.read_bytes()
        contract = validate_contract(bounded_json(raw, 65536))
        require(not (args.execute and args.verify_local), 'Choose local verification or scoped execution')
        if args.execute:
            execute(contract, hashlib.sha256(raw).hexdigest())
        elif args.verify_local:
            directory = args.verify_local.resolve(); directory.relative_to(ROOT)
            verify_local(directory, contract)
            print('Reviewed seven local files and source/kit/IPA bindings verified; no API or release mutation.')
        else:
            print('Plan only: reviewed public run ' + str(contract['source_run_id']) + ', seven pinned files, draft tag ' + TAG + '. No API calls or mutations.')
        return 0
    except DeliveryError as error:
        print(str(error), file=sys.stderr)
    except Exception:
        print('Public delivery validation/transfer failed. No release was published; inspect the scoped workflow before retrying.', file=sys.stderr)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
