#!/usr/bin/env python3
"""Refuse final-release designation without artifact-bound verification evidence.

The evidence must come from the documented real checks. This validates reported
completeness and artifact/source correspondence; it cannot establish an operator's
honesty or replace Apple's signature verification and physical device tests.
No credentials, account IDs, keys, or device identifiers belong in these reports.
"""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path, PurePosixPath
import re
import struct
import sys
import tarfile
import zipfile
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
REQUIRED = {
    'features': ('required_capabilities_verified', 'update_same_bundle_verified', 'no_duplicate_install_verified',
                 'keychain_restore_verified', 'biometric_authorization_verified', 'pairing_backup_recovery_verified',
                 'self_refresh_verified', 'shortcut_due_refresh_verified', 'expiry_alerts_verified',
                 'background_interruption_verified'),
    'tests': ('existing_offline_tests_passed', 'additional_tests_passed', 'clean_build_passed'),
    'licensing': ('notices_verified', 'corresponding_source_verified', 'relink_instructions_verified'),
    'apple': ('live_sign_in_verified', 'apple_profile_authority_verified', 'signature_verified',
              'physical_install_verified', 'physical_launch_verified', 'refresh_verified',
              'free_account_verified', 'paid_account_verified'),
    'duo': ('physical_device_verified', 'outer_display_verified', 'inner_display_verified',
            'native_resolution_verified', 'safe_areas_verified', 'touch_verified',
            'fold_unfold_verified', 'state_preservation_verified', 'no_overlap_verified',
            'no_crashes_or_freezes_verified'),
}


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def is_hash(value, length=64):
    return isinstance(value, str) and re.fullmatch('[0-9a-f]{' + str(length) + '}', value) is not None


def unique_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value: raise ValueError('Duplicate JSON evidence/metadata field')
        value[key] = item
    return value


def json_object(data):
    value = json.loads(data, object_pairs_hook=unique_object)
    if not isinstance(value, dict): raise ValueError('Expected a JSON object')
    return value


def evaluate(report, ipa_hash, source_hash):
    if not isinstance(report, dict): return ['missing or invalid required evidence object']
    failures = []
    if type(report.get('schema_version')) is not int or report['schema_version'] != 1:
        failures.append('evidence schema')
    # Omission is not evidence that an explicitly marked test fixture is absent.
    if report.get('test_fixture') is not False: failures.append('explicit non-fixture evidence required')
    if not is_hash(report.get('artifact_sha256')) or report.get('artifact_sha256') != ipa_hash:
        failures.append('IPA evidence hash binding')
    if not is_hash(report.get('source_bundle_sha256')) or report.get('source_bundle_sha256') != source_hash:
        failures.append('source evidence hash binding')
    if not is_hash(report.get('source_commit'), 40): failures.append('source commit binding')
    if not is_hash(report.get('source_tree_sha256')): failures.append('source fingerprint binding')
    for area, fields in REQUIRED.items():
        section = report.get(area)
        for field in fields:
            if not isinstance(section, dict) or section.get(field) is not True:
                failures.append(area + '.' + field)
    licensing = report.get('licensing')
    if not isinstance(licensing, dict) or type(licensing.get('unresolved_notice_cases')) is not int or licensing['unresolved_notice_cases'] != 0:
        failures.append('unresolved license notices')
    for area, label in [('apple', 'physical Apple verification required'), ('duo', 'physical Duo verification required')]:
        section = report.get(area)
        if not isinstance(section, dict) or section.get('simulator') is not False: failures.append(label)
    features = report.get('features')
    if not isinstance(features, dict) or features.get('missing_required_capabilities') != []:
        failures.append('missing required IPA capabilities')
    return failures


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0,str(path.parent))
    try: spec.loader.exec_module(module)
    finally: sys.path.pop(0)
    return module


def verify_source_bundle(path, fingerprint, graph):
    # Reuse the actual source/relink verifier. Its verify() only reads the archive;
    # it neither calls Cargo/network nor executes any bundled source.
    build = ROOT / 'app-installer/build'
    sys.path.insert(0, str(build))
    try: module = load_module('release_source_bundle', build / 'source-bundle.py')
    finally: sys.path.pop(0)
    return module.verify(path, expected_fingerprint=fingerprint, expected_graph=graph)


def archive_fingerprint(path):
    # Recompute the production fingerprint from the delivered source bytes, rather
    # than accepting a source archive's claimed fingerprint as an independent proof.
    recipe = load_module('release_source_fingerprint', ROOT / 'app-installer/build/source-fingerprint.py')
    prefixes = tuple(str(base.relative_to(recipe.ROOT)) + '/' for base in recipe.SOURCE_ROOTS)
    selected = {}
    dynamic_prefixes = ()
    recipe_path = 'app-installer/build/source-fingerprint.py'
    with tarfile.open(path, 'r|xz') as archive:
        for member in archive:
            if not member.isfile() or not member.name.startswith('AppInstaller-source/'):
                raise ValueError('Invalid source archive member')
            relative = member.name[len('AppInstaller-source/'):]
            if relative == 'SourceBundleManifest.json':
                source_manifest=json_object(archive.extractfile(member).read())
                roots=[]
                for entry in source_manifest.get('path_sources',[]):
                    value=PurePosixPath(entry['path'])
                    if value.is_absolute() or '..' in value.parts or '\\' in str(value): raise ValueError('Unsafe fingerprint source root')
                    roots.append(str(value)+'/')
                dynamic_prefixes=tuple(roots)
                continue
            parts = PurePosixPath(relative).parts
            if ('target' in parts or 'work' in parts or '__pycache__' in parts): continue
            p = PurePosixPath(relative)
            wanted = relative in {'app-installer/LICENSE','app-installer/licensing-signing.md'} or (relative.startswith(prefixes+dynamic_prefixes) and
                     (p.suffix in recipe.SUFFIXES or p.name.startswith(('LICENSE','LICENCE','COPYING','NOTICE','COPYRIGHT'))))
            if wanted:
                if relative in selected: raise ValueError('Duplicate fingerprint source')
                selected[relative] = archive.extractfile(member).read()
    if selected.get(recipe_path) != (ROOT / recipe_path).read_bytes():
        raise ValueError('Unsupported source fingerprint recipe version')
    digest = hashlib.sha256(b'AppInstaller source fingerprint v1\n')
    for name, content in sorted(selected.items()):
        encoded = name.encode('utf-8')
        digest.update(struct.pack('>Q', len(encoded))); digest.update(encoded)
        digest.update(struct.pack('>Q', len(content))); digest.update(content)
    return digest.hexdigest()


def inspect_artifacts(report, ipa, source_bundle, source_hash):
    failures = []
    graph = None
    with zipfile.ZipFile(ipa) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Ambiguous duplicate IPA paths')
        for item in archive.infolist():
            parts = PurePosixPath(item.filename).parts
            if (item.orig_filename != item.filename or '\\' in item.filename or '..' in parts
                or '\x00' in item.filename or item.filename.startswith('/')):
                raise ValueError('Unsafe IPA path')
        roots = {PurePosixPath(name).parts[1] for name in names
                 if len(PurePosixPath(name).parts) >= 2 and PurePosixPath(name).parts[0] == 'Payload'
                 and PurePosixPath(name).parts[1].endswith('.app')}
        if len(roots) != 1: raise ValueError('One unambiguous primary app is required')
        prefix = 'Payload/' + next(iter(roots)) + '/'
        if any(name not in {'Payload/', prefix} and not name.startswith(prefix) for name in names):
            raise ValueError('Unexpected data outside the primary app')
        def packaged_json(name, limit):
            item = archive.getinfo(prefix + name)
            if not 0 < item.file_size <= limit or item.flag_bits & 1: raise ValueError('Invalid packaged JSON metadata')
            return json_object(archive.read(item))
        metadata = packaged_json('BuildMetadata.json', 64 * 1024)
        if metadata.get('source_commit') != report.get('source_commit'):
            failures.append('compiled source/evidence commit mismatch')
        if metadata.get('source_tree_sha256') != report.get('source_tree_sha256'):
            failures.append('compiled source/evidence fingerprint mismatch')
        if metadata.get('source_has_uncommitted_changes') is not False:
            failures.append('uncommitted build source')
        if metadata.get('unsigned') is not False:
            failures.append('unsigned candidate cannot be a final release')
        if metadata.get('source_bundle_sha256') != source_hash:
            failures.append('compiled artifact/corresponding-source binding mismatch')
        notices = packaged_json('ThirdPartyNoticeReport.json', 4 * 1024 * 1024)
        if (type(notices.get('notice_gap_count')) is not int or notices['notice_gap_count'] != 0
            or notices.get('notice_obligations_satisfied') is not True or notices.get('missing_notices') != []):
            failures.append('packaged notice report has unresolved or unspecified obligations')
        graph = notices.get('locked_dependency_graph_hash')
        if not is_hash(graph): failures.append('packaged locked dependency graph binding absent')
        for name, label in [('embedded.mobileprovision', 'signed provisioning profile absent from primary app'),
                            ('_CodeSignature/CodeResources', 'bundle signature resources absent from primary app')]:
            if prefix + name not in names or archive.getinfo(prefix + name).file_size == 0:
                failures.append(label)
        if any(name.endswith(('.p12','.p8','.pem','.key','.mobiledevicepairing')) for name in names):
            failures.append('private credential-shaped material included in IPA')
    fingerprint = report.get('source_tree_sha256')
    if not is_hash(fingerprint) or not is_hash(graph):
        return failures + ['corresponding-source identity cannot be verified']
    manifest = verify_source_bundle(source_bundle, fingerprint, graph)
    if (type(manifest.get('schema_version')) is not int or manifest['schema_version'] != 1
        or manifest.get('source_commit') != report.get('source_commit')
        or manifest.get('source_tree_sha256') != fingerprint
        or manifest.get('source_has_uncommitted_changes') is not False
        or manifest.get('test_fixture') is not False):
        failures.append('corresponding-source/evidence identity mismatch')
    if (manifest.get('notice_obligations_satisfied') is not True
        or type(manifest.get('notice_gap_count')) is not int or manifest['notice_gap_count'] != 0
        or manifest.get('recipient_library_modifications_permitted') is not True):
        failures.append('corresponding-source grant/relink declarations incomplete')
    if archive_fingerprint(source_bundle) != fingerprint:
        failures.append('delivered source bytes do not match compiled source fingerprint')
    return failures


def inside_repo(path):
    return path.resolve().is_relative_to(ROOT.resolve())


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--ipa', type=Path, required=True)
    p.add_argument('--source-bundle', type=Path, required=True)
    p.add_argument('--evidence', type=Path, required=True)
    p.add_argument('--output', type=Path)
    a = p.parse_args(argv)
    try:
        if not all(inside_repo(path) for path in [a.ipa, a.source_bundle, a.evidence] + ([a.output] if a.output else [])):
            raise ValueError('Release work must stay inside the single repository')
        if a.output and any(a.output.resolve()==path.resolve() for path in [a.ipa,a.source_bundle,a.evidence]):
            raise ValueError('Release output must not overwrite its required input artifacts/evidence')
        if a.evidence.stat().st_size > 2 * 1024 * 1024: raise ValueError('Evidence exceeds supported bound')
        report = json_object(a.evidence.read_bytes())
        source_hash = sha(a.source_bundle)
        failures = evaluate(report, sha(a.ipa), source_hash)
        failures.extend(inspect_artifacts(report, a.ipa, a.source_bundle, source_hash))
    except (OSError, ValueError, zipfile.BadZipFile, tarfile.TarError, AttributeError, TypeError, KeyError, ImportError):
        failures = ['missing or invalid required artifact/evidence/source closure']
    result = {'classification': 'final-release' if not failures else 'incomplete',
              'release_ready': not failures, 'unverified_requirements': list(dict.fromkeys(failures))}
    output = json.dumps(result, indent=2) + '\n'
    if a.output:
        if not inside_repo(a.output) or any(a.output.resolve()==path.resolve() for path in [a.ipa,a.source_bundle,a.evidence]):
            sys.stdout.write(output); return 1
        a.output.write_text(output)
    sys.stdout.write(output)
    return 0 if not failures else 1


if __name__ == '__main__':
    raise SystemExit(main())
