#!/usr/bin/env python3
"""Overlay only an externally hash-pinned public native kit; never download it.

Default is a description, without inspecting files or invoking Mac tools/UI.
--execute requires explicit expected ZIP bytes/SHA-256/source revision. --choose
optionally supplies missing ZIP/destination paths through macOS choosers.
Uses the existing scoped approval and advance-use notice; it never requests or
changes Apple credentials, runs the helper, installs an app or invokes Cargo.
"""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import subprocess
import sys
import tempfile
import unicodedata
import zipfile

sys.dont_write_bytecode = True
PREFIX = 'AI-Workspace/dokkan-offline-public/'
MANIFEST = 'BootstrapKitManifest.json'
MAX_MEMBER = 256 * 1024 * 1024
MAX_KIT = 512 * 1024 * 1024
INPUT = 'app-installer/device/private/input/'
HELPER = {
    'binary': 'app-installer/device/tools/app-installer-rp-bootstrap',
    'manifest': 'app-installer/device/tools/RPBootstrapBuildManifest.json',
    'notices': 'app-installer/device/tools/RPBootstrapThirdPartyNotices.txt',
    'notice_report': 'app-installer/device/tools/RPBootstrapThirdPartyNoticeReport.json',
}
PRIVATE_INPUTS = {INPUT + name for name in ('libapp_installer_core.a', 'cloud-device-library-manifest.json',
    'review-resources/ThirdPartyNotices.txt', 'review-resources/ThirdPartyNoticeReport.json', 'review-resources/BuildMetadata.json')}
PUBLIC_FILES = {'README.md', 'app-installer/LICENSE', 'app-installer/licensing-signing.md',
    'app-installer/core/app_installer.h', 'app-installer/core/secure_storage.h'} | {
    'app-installer/device/' + name for name in ('.gitignore', 'device-workflow.py', 'setup-wizard.py',
    'Run-App-Installer-Setup.command', 'PUBLIC-CONTINUATION.md', 'PUBLIC-QUICK-START.md',
    'USER-ACTIONS.md', 'UPDATE-EXISTING-KIT.md', 'update-public-kit.py')}
REQUIRED_NATIVE = {'app-installer/ios/' + name for name in ('main.m', 'InstallerService.m', 'SecureStore.m',
    'PairingStore.m', 'RefreshCoordinator.m', 'Info.plist')}
TARGETS = ['aarch64-apple-darwin', 'x86_64-apple-darwin']


class UpdateError(ValueError):
    pass


def need(condition, message):
    if not condition:
        raise UpdateError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def valid_digest(value, length=64):
    return isinstance(value, str) and re.fullmatch('[0-9a-f]{' + str(length) + '}', value) is not None


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':')).encode())


def relative(name):
    need(isinstance(name, str) and '\\' not in name and '\x00' not in name, 'Invalid managed path')
    path = PurePosixPath(name)
    need(not path.is_absolute() and str(path) == name and '..' not in path.parts
         and name not in ('', '.') and not re.match(r'^[A-Za-z]:', name), 'Unsafe managed path')
    return name


def allowed(name):
    relative(name)
    if name.startswith('app-installer/device/private/'):
        return name in PRIVATE_INPUTS
    return name in PUBLIC_FILES or name in HELPER.values() or (
        name.startswith('app-installer/ios/') and PurePosixPath(name).suffix in {'.m', '.h', '.plist', '.png'}
        and all(not part.startswith('.') for part in PurePosixPath(name).parts))


def absolute_path(value):
    path = Path(value)
    # Refuse the frozen folder lexically, before touching any of its ancestors.
    need(not any(unicodedata.normalize('NFC', part).casefold() in {'claude-chatg', 'claude-chatgpt'}
                 for part in path.parts), 'The frozen backup is not an update source or destination')
    return Path(os.path.abspath(os.fspath(path)))


def open_directory(path, create=False):
    """Walk using descriptor-relative O_NOFOLLOW, including every ancestor."""
    fd = os.open('/', os.O_RDONLY | os.O_DIRECTORY)
    try:
        for part in path.parts[1:]:
            if create:
                try:
                    os.mkdir(part, 0o700, dir_fd=fd)
                    os.fsync(fd)
                except FileExistsError:
                    pass
            new = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
            os.close(fd); fd = new
        return fd
    except BaseException:
        os.close(fd); raise


def parent_fd(root_fd, name, create=False):
    parts = PurePosixPath(relative(name)).parts
    fd = os.dup(root_fd)
    try:
        for part in parts[:-1]:
            if create:
                try:
                    os.mkdir(part, 0o700, dir_fd=fd)
                    os.fsync(fd)
                except FileExistsError:
                    pass
            new = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
            os.close(fd); fd = new
        return fd, parts[-1]
    except BaseException:
        os.close(fd); raise


def read_managed(root_fd, name, bound=MAX_MEMBER):
    try:
        parent, leaf = parent_fd(root_fd, name)
    except FileNotFoundError:
        return None
    try:
        try:
            fd = os.open(leaf, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=parent)
        except FileNotFoundError:
            return None
        try:
            info = os.fstat(fd)
            need(stat.S_ISREG(info.st_mode) and 0 <= info.st_size <= bound, 'Managed destination is not a bounded regular file')
            with os.fdopen(fd, 'rb', closefd=False) as stream:
                data = stream.read(bound + 1)
            need(len(data) <= bound, 'Managed file exceeds bound')
            return data
        finally:
            os.close(fd)
    finally:
        os.close(parent)


def entries_from_manifest(manifest):
    need(type(manifest) is dict and manifest.get('schema_version') == 1 and manifest.get('test_fixture') is False
         and manifest.get('project') == 'dokkan-offline-public' and manifest.get('source_repository') == 'mcantua/dokkan-offline-public'
         and valid_digest(manifest.get('source_commit'), 40) and valid_digest(manifest.get('bootstrap_tool_commit'), 40)
         and valid_digest(manifest.get('source_tree_sha256')), 'Invalid public kit manifest identity')
    rows = manifest.get('files')
    need(type(rows) is list and 0 < len(rows) <= 3000, 'Invalid managed file manifest')
    result, aliases = {}, set()
    for item in rows:
        name = relative(item['path'])
        folded = unicodedata.normalize('NFC', name).casefold()
        need(name != MANIFEST and allowed(name) and name not in result and folded not in aliases
             and type(item.get('bytes')) is int and 0 <= item['bytes'] <= MAX_MEMBER
             and valid_digest(item.get('sha256')), 'Unexpected, duplicate or private managed payload')
        result[name] = item; aliases.add(folded)
    return result


def read_archive(file, source):
    with zipfile.ZipFile(file) as archive:
        infos = archive.infolist()
        need(0 < len(infos) <= 3001, 'Too many kit ZIP members')
        names, aliases, total = {}, set(), 0
        for info in infos:
            need(info.filename.startswith(PREFIX), 'Kit ZIP belongs to another project root')
            name = relative(info.filename[len(PREFIX):])
            folded = unicodedata.normalize('NFC', name).casefold()
            mode = info.external_attr >> 16
            total += info.file_size
            need(name not in names and folded not in aliases and not info.is_dir()
                 and stat.S_IFMT(mode) == stat.S_IFREG and not info.flag_bits & 1
                 and not mode & 0o7022 and mode & 0o400
                 and 0 <= info.file_size <= MAX_MEMBER and total <= 768 * 1024 * 1024,
                 'Unsafe, aliased, oversized or special kit ZIP entry')
            need(info.file_size <= 1024 * 1024 or info.file_size <= max(1, info.compress_size) * 1000, 'Excessive ZIP expansion')
            need(name == MANIFEST or allowed(name), 'Unapproved/private kit payload')
            names[name] = info; aliases.add(folded)
        need(MANIFEST in names and names[MANIFEST].file_size <= 4 * 1024 * 1024, 'Kit manifest is missing or oversized')
        raw_manifest = archive.read(names[MANIFEST])
        manifest = json.loads(raw_manifest)
        entries = entries_from_manifest(manifest)
        need(manifest['source_commit'] == source and manifest['bootstrap_tool_commit'] == source,
             'The kit source/tool revisions do not match the reviewed source pin')
        need(set(names) == set(entries) | {MANIFEST}, 'Kit ZIP and managed manifest differ')
        need(PUBLIC_FILES <= set(entries) and REQUIRED_NATIVE <= set(entries)
             and PRIVATE_INPUTS <= set(entries) and set(HELPER.values()) <= set(entries), 'Public/native/library/helper closure is incomplete')
        native = manifest.get('native_sources', [])
        expected_native = {name for name in entries if name.startswith('app-installer/ios/') and name.endswith(('.m', '.h'))}
        need(type(native) is list and len(native) == len(set(native)) and set(native) == expected_native, 'Native source closure mismatch')
        modes = {}
        for name, item in entries.items():
            data = archive.read(names[name])
            need(len(data) == item['bytes'] and sha(data) == item['sha256'], 'Kit payload hash/size mismatch')
            modes[name] = stat.S_IMODE(names[name].external_attr >> 16)
            if 'mode' in item:
                need(item['mode'] == modes[name], 'Managed executable mode differs from manifest')
        need(modes[HELPER['binary']] == 0o755, 'Helper executable mode must remain 0755')
        metadata = {name: json.loads(archive.read(names[name])) for name in
                    (INPUT + 'cloud-device-library-manifest.json', INPUT + 'review-resources/BuildMetadata.json',
                     INPUT + 'review-resources/ThirdPartyNoticeReport.json', HELPER['manifest'], HELPER['notice_report'])}
        validate_bindings(manifest, entries, metadata)
        verify_macho(archive.read(names[HELPER['binary']]), metadata[HELPER['manifest']])
        return manifest, entries, modes, raw_manifest


def validate_bindings(kit, entries, metadata):
    library = metadata[INPUT + 'cloud-device-library-manifest.json']
    build = metadata[INPUT + 'review-resources/BuildMetadata.json']
    notices = metadata[INPUT + 'review-resources/ThirdPartyNoticeReport.json']
    receipt, helper_notices = metadata[HELPER['manifest']], metadata[HELPER['notice_report']]
    source = kit.get('corresponding_source', {})
    need(source.get('file') == 'AppInstaller-corresponding-source.tar.xz' and type(source.get('bytes')) is int
         and source['bytes'] > 0 and valid_digest(source.get('sha256')), 'Missing cloud corresponding-source binding')
    graph = library.get('locked_dependency_graph_hash')
    need(valid_digest(graph), 'Missing locked source graph')
    for item in (library, build, receipt):
        need(item.get('source_commit') == kit['source_commit'] and item.get('source_tree_sha256') == kit['source_tree_sha256']
             and item.get('locked_dependency_graph_hash') == graph, 'Library/native/helper source or graph mismatch')
    need(kit.get('personal_resources_used') is False and kit.get('device_install_attempted') is False
         and kit.get('release_ready', False) is False, 'Kit claims personal execution or final release status')
    need(kit.get('rust_library') == INPUT + 'libapp_installer_core.a' and kit.get('library_manifest') == INPUT + 'cloud-device-library-manifest.json'
         and kit.get('review_resources') == INPUT + 'review-resources', 'Unexpected private input locations')
    need(library.get('target') == 'aarch64-apple-ios' and library.get('unsigned') is True
         and all(library.get(key) == entries[kit['rust_library']][key] for key in ('bytes', 'sha256'))
         and library.get('source_bundle_sha256') == source['sha256'] and library.get('source_bundle_bytes') == source['bytes'], 'Cloud library receipt mismatch')
    need(build.get('unsigned') is True and build.get('designation') == 'unsigned-candidate'
         and build.get('synthetic_sdk_marker') is False and build.get('source_bundle_sha256') == source['sha256']
         and build.get('phone_install_attempted') is False, 'Review resource classification/source mismatch')
    need(notices.get('notice_obligations_satisfied') is True and notices.get('notice_gap_count') == 0
         and notices.get('release_license_ready') is True and notices.get('locked_dependency_graph_hash') == graph, 'Core notice/source obligations are unresolved')
    all_graphs = notices.get('distribution_graphs', [])
    need(type(all_graphs) is list and len(all_graphs) == 3 and canonical(all_graphs) == graph,
         'The delivered notice graph does not bind the complete device/helper closure')
    tool = kit.get('secure_rp_tool', {})
    need(all(tool.get(key) == path for key, path in HELPER.items()) and tool.get('source_commit') == kit['bootstrap_tool_commit']
         and tool.get('source_tree_sha256') == kit['source_tree_sha256'] and tool.get('version') == '0.1.68'
         and tool.get('format_key') == 'format_version' and tool.get('protocol_record_version') == 2
         and tool.get('peer_pin_required') is True, 'Unpinned or mismatched helper declaration')
    need(receipt.get('schema_version') == 1 and receipt.get('project') == 'dokkan-offline-public'
         and receipt.get('test_fixture') is False and receipt.get('tool') == 'app-installer-rp-bootstrap'
         and receipt.get('version') == '0.1.68' and receipt.get('targets') == TARGETS
         and receipt.get('architectures') == ['arm64', 'x86_64'] and receipt.get('minimum_macos') == '12.0'
         and receipt.get('ad_hoc_signed') is True and receipt.get('notarized') is False
         and receipt.get('build_succeeded') is True and receipt.get('version_output') == 'app-installer-rp-bootstrap 0.1.68'
         and receipt.get('version_only_executed') is True and receipt.get('usb_or_pairing_executed') is False
         and receipt.get('personal_resources_used') is False and receipt.get('notice_delivery_pending') is False
         and receipt.get('corresponding_source_delivery_pending') is False, 'Helper seal/provenance receipt is incomplete')
    need(all(receipt.get('corresponding_source', {}).get(key) == source[key] for key in ('file', 'bytes', 'sha256')), 'Helper source companion differs')
    graphs = receipt.get('target_graph_hashes', {})
    rows = receipt.get('distribution_graphs', [])
    need(set(graphs) == set(TARGETS) and len(rows) == 2 and {row.get('target') for row in rows} == set(TARGETS)
         and all(graphs[row['target']] == canonical(row) for row in rows)
         and rows == [row for row in all_graphs if row.get('target') in TARGETS]
         and helper_notices.get('distribution_graphs') == all_graphs
         and helper_notices.get('target_graph_hashes') == graphs and helper_notices.get('notice_obligations_satisfied') is True
         and helper_notices.get('notice_gap_count') == 0, 'Helper graph/notices are incomplete')
    for row in rows:
        packages = row.get('packages', [])
        tracing = [item for item in packages if item.get('name') == 'tracing']
        need(row.get('manifest') == 'downloads/idevice/idevice-0.1.68/Cargo.toml'
             and row.get('lock_path') == 'downloads/idevice/idevice-0.1.68/Cargo.lock'
             and valid_digest(row.get('lock_sha256')) and row.get('no_default_features') is True
             and row.get('features') == ['app-installer-rp-bootstrap']
             and len([item for item in packages if item.get('name') == 'idevice' and item.get('version') == '0.1.68']) == 1
             and len(tracing) == 1 and {'max_level_off', 'release_max_level_off'} <= set(tracing[0].get('features', [])),
             'Helper build graph does not preserve its source/privacy feature selection')
    for key in ('binary', 'notices', 'notice_report'):
        pin = receipt.get(key, {}); entry = entries[HELPER[key]]
        need(pin.get('file') == PurePosixPath(HELPER[key]).name and all(pin.get(field) == entry[field] for field in ('bytes', 'sha256')), 'Helper receipt/file binding mismatch')
    need(receipt['binary'].get('mode') == 0o755, 'Helper seal executable mode mismatch')


def verify_macho(data, receipt):
    need(len(data) >= 48 and data[:4] == b'\xca\xfe\xba\xbe', 'Helper must be a universal Mach-O file')
    count = struct.unpack_from('>I', data, 4)[0]
    need(count == 2, 'Helper must contain exactly two architectures')
    toolchain = receipt.get('genuine_toolchain', {})
    need(type(toolchain) is dict and all(isinstance(toolchain.get(key), str) and toolchain[key]
         for key in ('rustc', 'xcode', 'clang', 'macos_sdk', 'sdk_settings_sha256'))
         and re.match(r'^rustc 1\.99\.1 ', toolchain['rustc']) is not None
         and re.search(r'(?m)^Xcode \d+(?:\.\d+)*$', toolchain['xcode']) is not None
         and valid_digest(toolchain['sdk_settings_sha256']), 'Helper compiler/SDK provenance is incomplete')
    sdk_text = toolchain['macos_sdk']
    need(isinstance(sdk_text, str) and re.fullmatch(r'\d+\.\d+(?:\.\d+)?', sdk_text), 'Helper SDK provenance missing')
    sdk = tuple(int(part) for part in sdk_text.split('.'))[:2]
    seen, intervals = set(), []
    for index in range(2):
        cpu, subtype, offset, size, alignment = struct.unpack_from('>IIIII', data, 8 + 20 * index)
        need(cpu in (0x100000C, 0x1000007) and cpu not in seen and alignment <= 20
             and offset >= 48 and offset % (1 << alignment) == 0 and size >= 32 and offset + size <= len(data), 'Invalid universal helper architecture bounds')
        seen.add(cpu); intervals.append((offset, offset + size))
        magic, inner_cpu, inner_subtype, file_type, commands, command_bytes, _, _ = struct.unpack_from('<8I', data, offset)
        need(magic == 0xFEEDFACF and inner_cpu == cpu and inner_subtype == subtype and file_type == 2
             and commands <= 256 and 32 + command_bytes <= size, 'Invalid helper Mach-O header')
        cursor, end = offset + 32, offset + 32 + command_bytes
        build_version, signature = False, False
        for _ in range(commands):
            need(cursor + 8 <= end, 'Truncated helper load command')
            command, length = struct.unpack_from('<II', data, cursor)
            need(length >= 8 and cursor + length <= end, 'Invalid helper load command bounds')
            if command == 0x32:
                need(not build_version and length >= 24, 'Invalid helper build-version command')
                platform, minimum, actual_sdk = struct.unpack_from('<III', data, cursor + 8)
                need(platform == 1 and minimum == (12 << 16) and ((actual_sdk >> 16), (actual_sdk >> 8) & 255) == sdk,
                     'Helper Mach-O platform/minimum/SDK differs from receipt')
                build_version = True
            if command == 0x1D:
                need(not signature and length == 16, 'Invalid helper signature command')
                start, amount = struct.unpack_from('<II', data, cursor + 8)
                need(amount > 0 and start >= 32 + command_bytes and start + amount <= size, 'Helper signature bounds invalid')
                signature = True
            cursor += length
        need(cursor == end and build_version and signature, 'Helper build/seal commands incomplete')
    intervals.sort()
    need(intervals[0][1] <= intervals[1][0], 'Overlapping universal helper slices')


def verify_local_seal(path, receipt):
    need(sys.platform == 'darwin', 'Actual helper signature verification requires macOS')
    # Verification reads the helper only. It does not execute it, pair, install,
    # request credentials or download a dependency.
    result = subprocess.run(['/usr/bin/codesign', '--verify', '--strict', '--all-architectures', str(path)],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
    need(result.returncode == 0, 'The helper cryptographic signature seal failed verification')
    for architecture in receipt['architectures']:
        result = subprocess.run(['/usr/bin/codesign', '--display', '--verbose=4', '--architecture', architecture, str(path)],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30)
        need(result.returncode == 0 and len(result.stdout) <= 65536
             and b'Signature=adhoc' in result.stdout.splitlines(), 'The helper is not sealed with the reviewed ad-hoc identity')


def apply_update(kit, destination, expected_sha, expected_bytes, source, *, _seal_verifier=None):
    """Internal test seam may replace only codesign, never production CLI guards."""
    need(valid_digest(expected_sha) and type(expected_bytes) is int and 0 < expected_bytes <= MAX_KIT
         and valid_digest(source, 40), 'Explicit verified kit SHA/size/source pins are required')
    destination = absolute_path(destination); kit = absolute_path(kit)
    need(destination.parts[-2:] == ('AI-Workspace', 'dokkan-offline-public'), 'Choose only the new public project folder')
    kit_parent = open_directory(kit.parent)
    try:
        fd = os.open(kit.name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=kit_parent)
    finally:
        os.close(kit_parent)
    try:
        info = os.fstat(fd)
        need(stat.S_ISREG(info.st_mode) and info.st_size == expected_bytes, 'Kit byte count differs from reviewed receipt')
        with os.fdopen(fd, 'rb', closefd=False) as file:
            # Parse and stage the SAME immutable bytes that passed the external
            # whole-ZIP pin. A concurrently modified download cannot substitute
            # a different self-consistent manifest between these operations.
            blob = file.read(MAX_KIT + 1)
            need(len(blob) == expected_bytes and sha(blob) == expected_sha, 'Kit SHA-256 differs from reviewed receipt')
            snapshot = io.BytesIO(blob)
            manifest, entries, modes, raw_manifest = read_archive(snapshot, source)
            # Destination creation/staging happens only after the complete ZIP,
            # manifest, member hashes and safe payload closure have verified.
            root_fd = open_directory(destination, create=True)
            try:
                old_raw = read_managed(root_fd, MANIFEST, 4 * 1024 * 1024)
                old = entries_from_manifest(json.loads(old_raw)) if old_raw else {}
                for name in set(entries) | set(old):
                    current = read_managed(root_fd, name)
                    if current is not None:
                        permitted = {pin['sha256'] for pin in (entries.get(name), old.get(name)) if pin}
                        need(sha(current) in permitted, 'A managed file was locally modified; no managed file was replaced')
                with tempfile.TemporaryDirectory(prefix='.public-kit-update-', dir=destination) as temporary:
                    stage = Path(temporary)
                    for name, item in entries.items():
                        target = stage / name; target.parent.mkdir(parents=True, exist_ok=True)
                        with target.open('xb') as output:
                            output.write(file_member(snapshot, PREFIX + name))
                            os.fchmod(output.fileno(), modes[name]); output.flush(); os.fsync(output.fileno())
                    receipt = json.loads((stage / HELPER['manifest']).read_bytes())
                    (_seal_verifier or verify_local_seal)(stage / HELPER['binary'], receipt)
                    # Recheck before the first managed replacement. The local
                    # old manifest must not have changed while staging/verifying.
                    need(read_managed(root_fd, MANIFEST, 4 * 1024 * 1024) == old_raw, 'Existing kit manifest changed during update')
                    for name in set(entries) | set(old):
                        current = read_managed(root_fd, name)
                        if current is not None:
                            need(sha(current) in {pin['sha256'] for pin in (entries.get(name), old.get(name)) if pin}, 'Managed files changed while verifying; update stopped')
                    for name, pin in entries.items():
                        parent, leaf = parent_fd(root_fd, name, create=True)
                        try:
                            current = read_managed(root_fd, name)
                            if current is not None:
                                need(sha(current) in {entry['sha256'] for entry in (pin, old.get(name)) if entry}, 'Managed file changed during replacement')
                            os.replace(stage / name, leaf, dst_dir_fd=parent)
                            if name.endswith('.a') or (name.startswith('app-installer/ios/') and name.endswith(('.m', '.h'))):
                                os.utime(leaf, None, dir_fd=parent, follow_symlinks=False)
                            os.fsync(parent)
                        finally:
                            os.close(parent)
                    for name, pin in entries.items():
                        need(sha(read_managed(root_fd, name)) == pin['sha256'], 'Updated managed file failed final verification')
                    for name, pin in old.items():
                        if name not in entries and not name.startswith('app-installer/device/private/'):
                            current = read_managed(root_fd, name)
                            if current is not None:
                                need(sha(current) == pin['sha256'], 'Obsolete managed file changed; it was retained')
                                parent, leaf = parent_fd(root_fd, name)
                                try:
                                    os.unlink(leaf, dir_fd=parent)
                                    os.fsync(parent)
                                finally: os.close(parent)
                    committed = stage / MANIFEST
                    with committed.open('xb') as output:
                        output.write(raw_manifest); os.fchmod(output.fileno(), 0o600)
                        output.flush(); os.fsync(output.fileno())
                    # Persist managed directory entries before publishing their
                    # manifest. A failed sync keeps the old manifest available
                    # so a pinned rerun can still recognize old OR new bytes.
                    os.fsync(root_fd)
                    os.replace(committed, MANIFEST, dst_dir_fd=root_fd)
                    os.fsync(root_fd)
            finally:
                os.close(root_fd)
    finally:
        os.close(fd)
    return manifest


def file_member(file, name):
    file.seek(0)
    with zipfile.ZipFile(file) as archive:
        return archive.read(name)


def choose(kind):
    script = 'POSIX path of (choose ' + kind + ' with prompt "Choose the verified public kit ' + ('ZIP' if kind == 'file' else 'project folder') + '")'
    result = subprocess.run(['/usr/bin/osascript', '-e', script], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, timeout=120)
    need(result.returncode == 0, 'Chooser cancelled; no update performed')
    return result.stdout.strip()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--execute', action='store_true')
    parser.add_argument('--choose', action='store_true')
    parser.add_argument('--kit')
    parser.add_argument('--destination')
    parser.add_argument('--expected-sha256')
    parser.add_argument('--expected-bytes', type=int)
    parser.add_argument('--source-commit')
    args = parser.parse_args(argv)
    if not args.execute:
        print('Plan only. No files inspected or changed; no chooser, download, signing or device action. Execution needs the reviewed ZIP SHA-256/bytes/source, approved Mac step and advance connection notice.')
        return 0
    try:
        need(valid_digest(args.expected_sha256) and type(args.expected_bytes) is int and 0 < args.expected_bytes <= MAX_KIT
             and valid_digest(args.source_commit, 40), 'Actual verified kit SHA/size/source pins are required before execution')
        need(sys.platform == 'darwin', 'The approved local updater requires macOS')
        kit = args.kit or (choose('file') if args.choose else None)
        destination = args.destination or (choose('folder') if args.choose else None)
        need(kit and destination, 'Choose/provide the verified ZIP and the new public destination')
        apply_update(kit, destination, args.expected_sha256, args.expected_bytes, args.source_commit)
        print('Public managed kit files verified and updated; unlisted local/private files preserved. Manifest committed last; interruption requires a verified rerun, not a rollback. No Rust build, pairing, signing or installation was performed.')
        return 0
    except UpdateError as error:
        print(str(error), file=sys.stderr)
    except Exception:
        print('Public kit update stopped. Do not run a mixed kit; rerun only with the same verified ZIP after reviewing the failure locally.', file=sys.stderr)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
