#!/usr/bin/env python3
"""Reuse the exact-source, focused Linux RP checks without claiming hosted tests.

A missing or changed proof returns 1, so the caller runs only that two-method
check on the hosted executor. This script never creates a passing proof.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

PREFIXES=('app-installer/core/','downloads/idevice/idevice-0.1.68/',
          'downloads/isideload/isideload-0.5.0/','downloads/apple-trust/',
          'app-installer/device/secure-rp-bootstrap/')
GROUPS={
 'rp_setup_wire': {'filter':'rp_setup_wire_', 'methods':[
  'remote_pairing::tlv::setup_wire_tests::rp_setup_wire_fragments_full_width_without_length_wrap_or_lost_bytes',
  'remote_pairing::setup_wire_tests::rp_setup_wire_actual_srp_and_m6_require_canonical_fragments_and_authenticated_peer']},
 'helper_handshake': {'filter':'pairing_progress_and_failure_routing_are_fixed_and_private', 'methods':[
  'tests::pairing_progress_and_failure_routing_are_fixed_and_private']},
 'rp_connectivity': {'filter':'rp_connectivity_', 'methods':[
  'connectivity_tests::rp_connectivity_rsd_rejection_never_establishes_service',
  'remote_pairing::rp_pairing_file::connectivity_tests::rp_connectivity_optional_discovery_key_is_absent_or_exact_data']},
 'helper_publication': {'filter':'new_record_verification_gates_private_publication_without_retry', 'methods':[
  'tests::new_record_verification_gates_private_publication_without_retry']},
 'refresh_recovery': {'filter':'refresh_recovery_', 'methods':[
  'engine::tests::refresh_recovery_preinstall_failure_still_refreshes_other_apps_and_self_last',
  'engine::tests::refresh_recovery_auth_cancel_and_unconfirmed_install_stop_without_discarding_source']},
 'core_connection': {'filter':'connection_diagnostics_', 'methods':[
  'engine::tests::connection_diagnostics_keep_stages_and_redact_all_raw_details',
  'engine::tests::connection_diagnostics_timeout_preserves_failure_and_successful_lookup']},
 'peer_auth': {'filter':'rp_auth_', 'methods':[
  'remote_pairing::security_tests::rp_auth_trusted_setup_signature_and_strict_export_reject_substitution',
  'remote_pairing::security_tests::rp_auth_verify_requires_pinned_peer_and_authenticates_exact_ephemeral_transcript']},
 'tunnel_security': {'filter':'security_', 'methods':[
  'remote_pairing::tls_psk::tests::rp_tls_security_authenticated_finished_records_and_framing',
  'remote_pairing::tunnel::tests::rp_tunnel_security_fragmentation_truncation_and_endpoint_bounds']},
 'pinned_tls': {'filter':'sni::tests::', 'methods':[
  'sni::tests::trusted_pairing_and_real_signature_complete_tls12_and_tls13',
  'sni::tests::substituted_identity_and_tampered_signature_fail_tls12_and_tls13']},
 'helper': {'filter':'tests::', 'methods':[
  'tests::private_atomic_export_never_overwrites_existing_file_or_symlink',
  'tests::requires_explicit_consent_valid_physical_selection_and_exact_arguments']}}


def sha(data):return hashlib.sha256(data).hexdigest()


def inputs(repo):
    raw=subprocess.check_output(['git','-C',str(repo),'ls-files','-z','--cached','--others','--exclude-standard','--',*PREFIXES])
    result={}
    for name in sorted(set(filter(None,raw.decode().split('\0')))):
        p=repo/name
        if p.is_symlink() or not p.is_file():raise ValueError('Proof source is absent or not regular')
        result[name]=sha(p.read_bytes())
    if not result:raise ValueError('Missing proof source closure')
    return result


def verify_log(path,group):
    data=path.read_bytes()
    if len(data)>16*1024*1024:raise ValueError('Focused test log exceeds bound')
    value=data.decode('utf-8')
    passed=re.findall(r'^test ([^\n]+) \.\.\. ok$',value,re.M)
    # The exact suffixes avoid depending on an upstream module's private name;
    # the full expected module prefix is still checked below where stable.
    expected=GROUPS[group]['methods']
    if len(passed)!=len(expected) or len(set(passed))!=len(expected) or sorted(p.split('::')[-1] for p in passed)!=sorted(m.split('::')[-1] for m in expected):
        raise ValueError('Expected exactly the selected method successes')
    for actual in passed:
        if group in {'rp_connectivity','helper_publication','rp_setup_wire','helper_handshake'}:valid=actual in expected
        elif group=='helper':valid=actual.startswith('tests::')
        elif group=='pinned_tls':valid=actual.startswith('sni::tests::')
        elif group in {'core_connection','refresh_recovery'}:valid=actual.startswith('engine::tests::')
        else:valid=actual.startswith('remote_pairing::')
        if not valid:raise ValueError('Unexpected test module')
    summaries=re.findall(r'^test result: (.+)$',value,re.M)
    summary_pattern=r'ok\. ([12]) passed; 0 failed; 0 ignored; 0 measured; \d+ filtered out; finished in [0-9.]+s'
    counts=[re.fullmatch(summary_pattern,entry) for entry in summaries]
    if (not counts or any(entry is None for entry in counts) or sum(int(entry[1]) for entry in counts)!=len(expected)
        or re.search(r'^error(?:\[|:)|^test .* \.\.\. FAILED$',value,re.M)):
        raise ValueError('Focused test log does not prove only the selected successful methods')
    return data,passed


def verify_core_scoped(repo,proof):
    filename='linux-core-diagnostics-proof.json'
    manifest=json.loads((proof/filename).read_text())
    check=manifest['tests']
    if (manifest.get('schema')!=1 or not manifest.get('environment','').startswith('cloud Linux')
        or check.get('filter')!='connection_diagnostics_' or check.get('passed')!=2 or check.get('failed')!=0):
        raise ValueError('Scoped Linux diagnostic proof is incomplete')
    compiler=proof/manifest['compiler_verbose_file']
    if compiler.name!=manifest['compiler_verbose_file'] or sha(compiler.read_bytes())!=manifest['compiler_verbose_sha256']:
        raise ValueError('Original Linux compiler receipt changed')
    if not compiler.read_text().startswith('rustc 1.99.1 '):raise ValueError('Wrong original Linux compiler')
    relevant=manifest['unchanged_relevant_inputs_observed_after_execution']
    required={'app-installer/core/Cargo.toml','app-installer/core/Cargo.lock','app-installer/core/src/engine.rs',
              'app-installer/core/src/lib.rs','downloads/idevice/idevice-0.1.68/src/services/lockdown.rs'}
    if not required<=set(relevant):raise ValueError('Missing diagnostic inputs')
    for name,digest in relevant.items():
        path=(repo/name).resolve();path.relative_to(repo)
        if not name.startswith(PREFIXES) or path.is_symlink() or sha(path.read_bytes())!=digest:
            raise ValueError('Relevant scoped diagnostic inputs changed')
    change=manifest['post_execution_change']
    if (change.get('path')!='app-installer/core/src/transport.rs'
        or sha((repo/change['path']).read_bytes())!=change.get('current_sha256')):
        raise ValueError('Reviewed post-test transport-only change changed again')
    record=manifest['raw_log'];name=record['path']
    if Path(name).name!=name:raise ValueError('Unsafe diagnostic proof log')
    data,methods=verify_log(proof/name,'core_connection')
    if sha(data)!=record['sha256']:raise ValueError('Diagnostic proof raw log changed')
    # This is explicitly selected diagnostic semantics, NOT an exact whole-tree
    # compile proof: the real hosted target build must cover the disclosed Drop fix.
    context={'os':'Linux','rustc_version':compiler.read_text().splitlines()[0],
             'proof_scope':'Selected engine/Lockdown diagnostic paths only',
             'post_execution_change':change,
             'requires_current_target_compilation':True}
    normalized={'context':context,'original_proof':manifest,'original_proof_file':filename,
                'compiler_file':compiler.name}
    return normalized,name,data,methods


def checked_inputs(repo,declared,required):
    if not required<=set(declared):raise ValueError('Missing relevant focused-check source inputs')
    for name,digest in declared.items():
        path=(repo/name).resolve();path.relative_to(repo)
        if not name.startswith(PREFIXES) or path.is_symlink() or sha(path.read_bytes())!=digest:
            raise ValueError('Focused-check source input changed')


def verify_refresh_scoped(repo,proof):
    filename='refresh-recovery-proof.json'
    manifest=json.loads((proof/filename).read_text())
    tests=manifest['tests']
    if (manifest.get('schema')!=1 or not manifest.get('environment','').startswith('cloud Linux')
        or tests.get('filter')!='refresh_recovery_' or tests.get('passed')!=2 or tests.get('failed')!=0
        or manifest.get('exit_code')!=0 or tests.get('result')!='ok'
        or manifest.get('source_unchanged') is not True
        or manifest.get('source_sha256_before')!=manifest.get('source_sha256_after')):
        raise ValueError('Exact-source Linux refresh recovery proof required')
    command=manifest.get('command')
    if (not isinstance(command,list) or command[:2]!=['cargo','test'] or '--locked' not in command
        or '--lib' not in command or 'refresh_recovery_' not in command):
        raise ValueError('Refresh proof lacks its actual locked selected command')
    required={'app-installer/core/'+part for part in ['Cargo.toml','Cargo.lock','src/engine.rs','src/lib.rs','src/transport.rs','src/cleanup.rs']}
    checked_inputs(repo,manifest['source_sha256_after'],required)
    rustc=(manifest.get('rustc','').splitlines() or [''])[0]
    if not rustc.startswith('rustc 1.99.1 '):raise ValueError('Wrong original Linux refresh compiler')
    record=manifest['raw_log'];log=record['path']
    if Path(log).name!=log:raise ValueError('Unsafe original refresh proof log')
    data,methods=verify_log(proof/log,'refresh_recovery')
    if sha(data)!=record['sha256']:raise ValueError('Refresh proof raw log digest mismatch')
    graph=manifest['feature_graph'];graph_file=graph['path']
    if Path(graph_file).name!=graph_file or sha((proof/graph_file).read_bytes())!=graph['sha256']:
        raise ValueError('Refresh proof original target-feature graph digest mismatch')
    return {'context':{'os':'Linux','rustc_version':rustc,'proof_scope':'Selected partial-refresh recovery tests; exact pre/post source hashes',
             'pre_and_post_source_hashes_equal':True,'requires_current_target_compilation':True},
             'original_proof_file':filename,'feature_graph_file':graph_file},log,data,methods


def verify_pairing_scoped(repo,proof,group):
    filename='rp-connectivity-proof.json' if group=='rp_connectivity' else 'helper-publication-proof.json'
    manifest=json.loads((proof/filename).read_text())
    if (manifest.get('schema')!=1 or not manifest.get('environment','').startswith('cloud Linux')
        or manifest.get('exit_code')!=0 or not manifest.get('rustc','').startswith('rustc 1.99.1 ')):
        raise ValueError('Current scoped cloud Linux pairing proof required')
    command=manifest.get('command')
    if (not isinstance(command,list) or command[:2]!=['cargo','test'] or '--locked' not in command
        or GROUPS[group]['filter'] not in command):raise ValueError('Pairing proof lacks its exact locked selected command')
    if group=='rp_connectivity':
        tests=manifest['tests']
        if (tests.get('filter')!=GROUPS[group]['filter'] or tests.get('passed')!=2 or tests.get('failed')!=0
            or manifest.get('source_unchanged') is not True
            or manifest.get('source_sha256_before')!=manifest.get('source_sha256_after')
            or 'ring,tcp,remote_pairing,openssl,tunnel_tcp_stack,rsd' not in command):
            raise ValueError('Vendor pairing connectivity proof source/features/count differ')
        required={'downloads/idevice/idevice-0.1.68/'+part for part in ['Cargo.toml','Cargo.lock','src/lib.rs','src/remote_pairing/rp_pairing_file.rs']}
        checked_inputs(repo,manifest['source_sha256_after'],required)
        limits={'pre_and_post_source_hashes_equal':True,'proof_scope':manifest['scope']}
    else:
        if (manifest.get('method')!=GROUPS[group]['methods'][0] or manifest.get('filter')!=GROUPS[group]['filter']
            or manifest.get('passed')!=1 or manifest.get('failed')!=0
            or manifest.get('pre_run_hashes_captured') is not False
            or manifest.get('vendor_inputs_unchanged_claim') is not False
            or '--bin' not in command or 'app-installer-rp-bootstrap' not in command):
            raise ValueError('Helper publication proof scope/count/limitations differ')
        required={'app-installer/device/secure-rp-bootstrap/'+part for part in ['Cargo.toml','Cargo.lock','src/main.rs']}
        checked_inputs(repo,manifest['files'],required)
        limits={'pre_run_source_hashes_available':False,'source_capture_limit':manifest['hash_capture'],
                'vendor_inputs_unchanged_claim':False,'vendor_edit_limit':manifest['vendor_edit_limit'],
                'proof_scope':manifest['scope']}
    record=manifest['raw_log'];log=record['path']
    if Path(log).name!=log:raise ValueError('Unsafe pairing proof raw log name')
    data,methods=verify_log(proof/log,group)
    if sha(data)!=record['sha256']:raise ValueError('Pairing proof raw log digest mismatch')
    return {'context':{'os':'Linux','rustc_version':manifest['rustc'],
             'requires_current_target_compilation':True,**limits},'original_proof_file':filename},log,data,methods


def verify_handshake_scoped(repo,proof,group):
    filename='rp-setup-wire-proof.json' if group=='rp_setup_wire' else 'helper-handshake-proof.json'
    manifest=json.loads((proof/filename).read_text())
    if (manifest.get('schema')!=1 or not manifest.get('environment','').startswith('cloud Linux')
        or manifest.get('exit_code')!=0 or not manifest.get('rustc','').startswith('rustc 1.99.1 ')):
        raise ValueError('Current cloud Linux pairing handshake proof required')
    command=manifest.get('command')
    if (not isinstance(command,list) or command[:2]!=['cargo','test'] or '--locked' not in command
        or GROUPS[group]['filter'] not in command):raise ValueError('Handshake proof lacks its exact locked command')
    if group=='rp_setup_wire':
        tests=manifest['tests']
        if (tests.get('filter')!=GROUPS[group]['filter'] or tests.get('passed')!=2 or tests.get('failed')!=0
            or manifest.get('source_unchanged') is not True
            or manifest.get('source_sha256_before')!=manifest.get('source_sha256_after')
            or 'ring,tcp,remote_pairing,openssl,tunnel_tcp_stack,rsd' not in command):
            raise ValueError('Vendor TLV/SRP proof source/features/count differ')
        required={'downloads/idevice/idevice-0.1.68/'+part for part in ['Cargo.toml','Cargo.lock','src/remote_pairing/mod.rs','src/remote_pairing/tlv.rs']}
        checked_inputs(repo,manifest['source_sha256_after'],required)
        limits={'pre_and_post_source_hashes_equal':True,'proof_scope':manifest['scope'],
                'physical_failure_cause_confirmed':False}
    else:
        if (manifest.get('method')!=GROUPS[group]['methods'][0] or manifest.get('filter')!=GROUPS[group]['filter']
            or manifest.get('passed')!=1 or manifest.get('failed')!=0
            or manifest.get('pre_run_hashes_captured') is not True or manifest.get('inputs_unchanged') is not True
            or manifest.get('files_before')!=manifest.get('files_after')
            or manifest.get('vendor_inputs_unchanged_claim') is not False
            or '--bin' not in command or 'app-installer-rp-bootstrap' not in command):
            raise ValueError('Helper typed handshake diagnostics proof source/scope/count differ')
        required={'app-installer/device/secure-rp-bootstrap/'+part for part in ['Cargo.toml','Cargo.lock','src/main.rs']}
        checked_inputs(repo,manifest['files_after'],required)
        limits={'pre_and_post_source_hashes_equal':True,'vendor_inputs_unchanged_claim':False,
                'proof_scope':manifest['scope']}
    record=manifest['raw_log'];log=record['path']
    if Path(log).name!=log:raise ValueError('Unsafe handshake proof raw log name')
    data,methods=verify_log(proof/log,group)
    if sha(data)!=record['sha256']:raise ValueError('Handshake proof raw log digest mismatch')
    return {'context':{'os':'Linux','rustc_version':manifest['rustc'],
             'requires_current_target_compilation':True,**limits},'original_proof_file':filename},log,data,methods


def verify(repo,proof,group):
    if group in {'rp_setup_wire','helper_handshake'}:return verify_handshake_scoped(repo,proof,group)
    if group in {'rp_connectivity','helper_publication'}:return verify_pairing_scoped(repo,proof,group)
    if group=='refresh_recovery':return verify_refresh_scoped(repo,proof)
    if group=='core_connection':return verify_core_scoped(repo,proof)
    names={'peer_auth':'linux-peer-auth-proof.json','tunnel_security':'rp-security-tests.json','helper':'helper-tests-proof.json','pinned_tls':'pinned-tls-both-features.json'}
    filename=names[group];manifest=json.loads((proof/filename).read_text())
    if group=='peer_auth':
        tests=manifest['tests']
        if (manifest.get('schema')!=1 or not manifest.get('environment','').startswith('cloud Linux')
            or not tests.get('filter','').endswith('rp_auth_') or tests.get('passed')!=2 or tests.get('failed')!=0
            or '--locked' not in manifest.get('command','')):raise ValueError('Invalid Linux peer-auth proof')
        compiler=proof/manifest['compiler_verbose_file']
        if compiler.name!=manifest['compiler_verbose_file'] or sha(compiler.read_bytes())!=manifest['compiler_verbose_sha256']:
            raise ValueError('Original Linux compiler receipt mismatch')
        rustc=compiler.read_text().splitlines()[0]
        declared=manifest['inputs_unchanged_during_run'];record=manifest['raw_log'];log=record['path'];digest=record['sha256']
        required={'downloads/idevice/idevice-0.1.68/'+part for part in ['Cargo.toml','Cargo.lock','src/remote_pairing/mod.rs','src/remote_pairing/rp_pairing_file.rs','src/remote_pairing/socket.rs']}
        context={'os':'Linux','rustc_version':rustc,'proof_scope':'Selected pinned-peer authentication semantics; vendor standalone locked graph',
                 'scope_limits':manifest.get('scope_limits',[]),'requires_current_target_compilation':True}
    elif group=='tunnel_security':
        if (not manifest.get('scope','').startswith('Linux') or len(manifest.get('results',[]))!=2
            or any(result.get('exit_code')!=0 or result.get('one_test_passed') is not True for result in manifest['results'])):
            raise ValueError('Invalid Linux security proof')
        if len(manifest.get('commands',[]))!=2 or any('--locked' not in command or 'ring,tcp,remote_pairing,openssl,tunnel_tcp_stack,rsd' not in command for command in manifest['commands']):
            raise ValueError('Security proof lacks actual vendored OpenSSL feature selection')
        declared=manifest['source_sha256'];log=Path(manifest['log']).name;digest=manifest['log_sha256']
        required={'downloads/idevice/idevice-0.1.68/'+part for part in ['Cargo.toml','Cargo.lock','src/remote_pairing/tunnel.rs','src/remote_pairing/tls_psk.rs','src/remote_pairing/socket.rs']}
        rustc=manifest.get('rustc','').splitlines()[0] if isinstance(manifest.get('rustc'),str) else ''
        context={'os':'Linux','rustc_version':rustc,'proof_scope':'Selected in-memory TLS-PSK/framing semantics; exact current post-execution source hashes',
                 'pre_run_source_hashes_available':False,'source_capture_limit':manifest.get('source_capture_limit',manifest.get('source_hash_capture','After execution only; no pre-run hash attestation.')),
                 'requires_current_target_compilation':True}
    elif group=='pinned_tls':
        if (not manifest.get('scope','').startswith('Linux') or manifest.get('exit_code')!=0
            or manifest.get('counts')!={'passed':2,'failed':0} or manifest.get('source_unchanged') is not True
            or manifest.get('source_sha256_before')!=manifest.get('source_sha256_after')
            or '--locked' not in manifest.get('command',[])
            or 'ring,tcp,remote_pairing,openssl,tunnel_tcp_stack,rsd' not in manifest.get('command',[])):
            raise ValueError('Invalid both-features pinned TLS proof')
        declared=manifest['source_sha256_after'];log=Path(manifest['log']).name;digest=manifest['log_sha256']
        required={'downloads/idevice/idevice-0.1.68/'+part for part in ['Cargo.toml','Cargo.lock','src/lib.rs','src/sni.rs','src/pairing_file.rs']}
        rustc=manifest['rustc'].splitlines()[0]
        context={'os':'Linux','rustc_version':rustc,'proof_scope':manifest['scope'],
                 'pre_and_post_source_hashes_equal':True,'requires_current_target_compilation':True}
    else:
        if (manifest.get('schema')!=1 or manifest.get('context',{}).get('os')!='Linux' or manifest.get('exit_code')!=0
            or manifest.get('passed')!=2 or manifest.get('failed')!=0 or manifest.get('live_mac_or_device_test') is not False
            or '--locked' not in manifest.get('command','')):raise ValueError('Invalid Linux helper proof')
        declared={entry['path']:entry['sha256'] for entry in manifest['files']};log=manifest['log'];digest=manifest['log_sha256']
        required={'app-installer/device/secure-rp-bootstrap/'+part for part in ['Cargo.toml','Cargo.lock','src/main.rs']}
        rustc=manifest['context']['rustc']
        context={'os':'Linux','rustc_version':rustc,'proof_scope':'Pure helper argument/private-file semantics; current recorded inputs',
                 'pre_run_source_hashes_available':False,'source_capture_limit':manifest['source_integrity_limit'],
                 'log_collection':manifest['log_collection'],'requires_current_target_compilation':True}
    if not rustc.startswith('rustc 1.99.1 '):raise ValueError('Wrong original Linux compiler')
    checked_inputs(repo,declared,required)
    if Path(log).name!=log:raise ValueError('Unsafe original focused test log name')
    data,methods=verify_log(proof/log,group)
    if sha(data)!=digest:raise ValueError('Original focused test log digest mismatch')
    normalized={'context':context,'original_proof':manifest,'original_proof_file':filename}
    if group=='peer_auth':normalized['compiler_file']=compiler.name
    return normalized,log,data,methods


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo',type=Path)
    p.add_argument('--proof',type=Path)
    p.add_argument('--group',choices=GROUPS,required=True)
    p.add_argument('--output',type=Path)
    p.add_argument('--verify-log',type=Path)
    p.add_argument('--print-inputs',action='store_true')
    a=p.parse_args()
    if a.print_inputs:
        print(json.dumps(inputs(a.repo.resolve()),sort_keys=True,indent=2));return 0
    if a.verify_log:
        verify_log(a.verify_log,a.group);return 0
    try:
        repo=a.repo.resolve();proof=a.proof.resolve();output=a.output.resolve()
        proof.relative_to(repo);output.relative_to(repo)
        if proof==output or proof.is_relative_to(output) or output.is_relative_to(proof):raise ValueError('Separate proof/evidence required')
        manifest,filename,data,methods=verify(repo,proof,a.group)
        output.mkdir(parents=True,exist_ok=True)
        (output/filename).write_bytes(data)
        shutil.copy2(proof/manifest.get('original_proof_file','manifest.json'),output/'original-manifest.json')
        for field in ('compiler_file','feature_graph_file'):
            if manifest.get(field):shutil.copy2(proof/manifest[field],output/manifest[field])
        (output/'reuse-report.json').write_text(json.dumps({
            'schema_version':1,'reused':True,'new_test_execution':False,
            'original_platform':'Linux','current_platform':sys.platform,
            'current_execution_scope':'Receipt verification only; no new tests run',
            'current_source_commit':subprocess.check_output(['git','-C',str(repo),'rev-parse','HEAD'],text=True).strip(),
            'group':a.group,'filter':GROUPS[a.group]['filter'],'methods':methods,'passed':len(methods),'failed':0,
            'original_context':manifest['context'],'log':filename,'log_sha256':sha(data),
            'scope':'Selected Linux test semantics reused with exact current relevant file hashes and original evidence limitations preserved. This is not a fresh hosted test or whole-current-tree compile claim. Current genuine Apple-target compilation is mandatory; UIKit/physical acceptance are separate.'},indent=2)+'\n')
    except (OSError,ValueError,KeyError,TypeError,AttributeError):
        message=('Required current Linux recovery proof unavailable; stop this run without repeating passing tests.' if a.group in {'refresh_recovery','rp_connectivity','helper_publication','rp_setup_wire','helper_handshake'} else 'Exact focused Linux RP proof unavailable; run only the affected two-method hosted check.')
        print(message,file=sys.stderr);return 1
    print('Reused '+a.group+': '+str(len(methods))+' Linux successes, current recorded inputs match; original scope limits retained; no new hosted test execution.');return 0


if __name__=='__main__':raise SystemExit(main())
