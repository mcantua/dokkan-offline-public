#!/usr/bin/env python3
"""Two grouped cloud regressions; fake payloads/OS calls are never device proof."""
import contextlib, copy, hashlib, importlib.util, io, json, os, pathlib, subprocess, sys, tempfile, time, unittest
from contextlib import ExitStack
from unittest.mock import patch
sys.dont_write_bytecode=True
HERE=pathlib.Path(__file__).resolve().parent
def load(name,file):
    spec=importlib.util.spec_from_file_location(name,HERE/file)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
workflow=load('rp_workflow','device-workflow.py')
wizard=load('rp_wizard','setup-wizard.py')

class PairingWorkflowTests(unittest.TestCase):
    def test_pairing_codes_and_failed_helper_do_not_expose_private_output_or_reinstall(self):
        marker="TEST_ONLY_SECRET_OR_DEVICE_IDENTIFIER"
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='pairing-code-fixture-',dir=base) as temporary:
            binary=pathlib.Path(temporary)/'app-installer-rp-bootstrap';binary.touch();binary.chmod(0o700)
            for message,code in workflow.REMOTE_PAIRING_REASON_CODES.items():
                result=subprocess.CompletedProcess([str(binary)],1,
                    (marker+'\nRP_BOOTSTRAP_USB_SELECTED\nRP_BOOTSTRAP_USB_TRUST_VERIFIED\n').encode(),
                    ('RP_BOOTSTRAP_STOPPED: '+message+'\n'+marker+'\n').encode())
                args=workflow.parser().parse_args(['create-remote-pairing','--execute','--device','TEST-ONLY'])
                def diagnosed(selected):selected.physical_udid=marker;return {}
                output=io.StringIO()
                with patch.object(workflow,'bootstrap_kit',return_value={}),patch.object(workflow,'validate_remote_pairing_tool',return_value=binary),patch.object(workflow,'command',return_value=b'arm64 x86_64'),patch.object(workflow,'diagnose',side_effect=diagnosed),patch.object(workflow,'run_remote_pairing',return_value=result) as launched,contextlib.redirect_stdout(output):
                    with self.assertRaises(workflow.WorkflowError) as error:workflow.create_remote_pairing(args)
                self.assertEqual(output.getvalue().splitlines(),['PAIRING_EXIT: 1','PAIRING_STAGE: RP_BOOTSTRAP_USB_TRUST_VERIFIED','PAIRING_REASON: '+code])
                self.assertNotIn(marker,str(error.exception));self.assertNotIn(marker,output.getvalue())
                self.assertEqual(launched.call_count,1)
                self.assertEqual(pathlib.Path(launched.call_args.args[0][0]),binary)
                self.assertNotIn('xcodebuild',launched.call_args.args[0]);self.assertNotIn('install',launched.call_args.args[0])
            for raw in [marker.encode(),b'\xff',b'x'*8193]:
                self.assertEqual(workflow.remote_pairing_codes(1,raw,raw),('NO_STAGE','UNCLASSIFIED'))
            self.assertEqual(workflow.remote_pairing_codes(-9,b'',marker.encode()),('NO_STAGE','PROCESS_STOPPED'))
            duplicate=b'RP_BOOTSTRAP_STOPPED: '+next(iter(workflow.REMOTE_PAIRING_FAILURES)).encode()+b'\n'
            self.assertEqual(workflow.remote_pairing_codes(1,b'',duplicate*2),('NO_STAGE','UNCLASSIFIED'))

    def test_live_pairing_stages_are_streamed_before_exit_without_forwarding_private_output(self):
        marker='TEST_ONLY_PRIVATE_CONTENT'
        stage='RP_BOOTSTRAP_PAIR_SRP_PROOF_PENDING'
        failure='remote-pairing SRP proof could not be authenticated; no new export was committed.'
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='pairing-live-fixture-',dir=base) as temporary:
            ack=pathlib.Path(temporary)/'stage-observed'
            class Observed(io.StringIO):
                def write(self,text):
                    if text==workflow.REMOTE_PAIRING_PROGRESS[stage]:ack.touch()
                    return super().write(text)
            code='''import os,pathlib,sys,time
ack=pathlib.Path(sys.argv[1])
os.write(1,b'RP_BOOTSTRAP_PAIR_');os.write(1,b'SRP_PROOF_PENDING\\r\\n')
deadline=time.monotonic()+3
while not ack.exists() and time.monotonic()<deadline:time.sleep(.01)
if not ack.exists():raise SystemExit(9)
os.write(1,b'TEST_ONLY_PRIVATE_CONTENT\\nnot-a-stage\\n')
os.write(2,b'TEST_ONLY_PRIVATE_CONTENT\\nRP_BOOTSTRAP_STOPPED: '+sys.argv[2].encode()+b'\\n')
raise SystemExit(1)
'''
            output=Observed()
            with contextlib.redirect_stdout(output):
                result=workflow.run_remote_pairing([sys.executable,'-u','-c',code,str(ack),failure])
            self.assertTrue(ack.is_file(),'Stage must be displayed while the child is still running.')
            self.assertEqual(result.returncode,1)
            self.assertEqual(workflow.remote_pairing_codes(result.returncode,result.stdout,result.stderr),(stage,'PAIR_SRP_PROOF'))
            self.assertNotIn(marker,output.getvalue());self.assertNotIn('not-a-stage',output.getvalue())
            self.assertEqual(output.getvalue().count(workflow.REMOTE_PAIRING_PROGRESS[stage]),1)
            self.assertIn('pairing proof',workflow.remote_pairing_failure(result.returncode,result.stderr))
            for source,message in workflow.REMOTE_PAIRING_FAILURES.items():
                raw=('RP_BOOTSTRAP_STOPPED: '+source+'\n').encode()
                self.assertEqual(workflow.remote_pairing_failure(1,raw),message)
                self.assertNotIn(marker,workflow.remote_pairing_failure(1,raw+marker.encode()))
                self.assertNotEqual(workflow.remote_pairing_codes(1,b'',raw+raw)[1],workflow.REMOTE_PAIRING_REASON_CODES[source])

    def test_live_pairing_deadline_and_output_bound_stop_only_the_owned_child(self):
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='pairing-deadline-fixture-',dir=base) as temporary:
            pid=pathlib.Path(temporary)/'nonsecret-child-pid'
            code="import os,pathlib,sys,time;pathlib.Path(sys.argv[1]).write_text(str(os.getpid()));print('RP_BOOTSTRAP_PAIR_CONSENT_PENDING',flush=True);time.sleep(10)"
            output=io.StringIO();start=time.monotonic()
            with patch.object(workflow,'REMOTE_PAIRING_WALL_SECONDS',.5),contextlib.redirect_stdout(output):
                result=workflow.run_remote_pairing([sys.executable,'-u','-c',code,str(pid)])
            self.assertLess(time.monotonic()-start,4)
            self.assertEqual(result.returncode,124)
            self.assertEqual(workflow.remote_pairing_codes(result.returncode,result.stdout,result.stderr),('RP_BOOTSTRAP_PAIR_CONSENT_PENDING','HELPER_WALL_TIMEOUT'))
            with self.assertRaises(ProcessLookupError):os.kill(int(pid.read_text()),0)
            # A process cannot flood memory/Terminal even if its output violates
            # the signed helper's fixed public protocol. No raw output is shown.
            output=io.StringIO()
            with contextlib.redirect_stdout(output):
                result=workflow.run_remote_pairing([sys.executable,'-u','-c',"import os;os.write(1,b'X'*9000)"])
            self.assertEqual(result.returncode,125)
            self.assertEqual(workflow.remote_pairing_codes(result.returncode,result.stdout,result.stderr)[1],'HELPER_OUTPUT_LIMIT')
            self.assertLessEqual(len(result.stdout),8192);self.assertNotIn('XXX',output.getvalue())

    def test_actual_launcher_routes_pair_only_without_full_setup_and_preserves_explicit_flags(self):
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        source=(HERE/'Run-App-Installer-Setup.command').read_text()
        subprocess.run(['bash','-n'],input=source.encode(),check=True,capture_output=True)
        with tempfile.TemporaryDirectory(prefix='pairing-launch-fixture-',dir=base) as temporary:
            root=pathlib.Path(temporary)
            # Execute the actual shell branches with only the two Mac programs
            # substituted. No wizard is imported and no AppleScript/device runs.
            python=root/'python-fixture';osascript=root/'osascript-fixture';launcher=root/'Setup.command';log=root/'calls'
            python.write_text('#!/bin/bash\nprintf "%s\\n" "$*" >> "$PAIR_TEST_LOG"\n')
            osascript.write_text('#!/bin/bash\n[[ "${PAIR_TEST_CHOICE}" == "CANCEL" ]] && exit 1\nprintf "%s\\n" "$PAIR_TEST_CHOICE"\n')
            python.chmod(0o700);osascript.chmod(0o700)
            launcher.write_text(source.replace('/usr/bin/python3',str(python)).replace('/usr/bin/osascript',str(osascript)))
            for choice,arguments,suffixes in [
                ('Pair only',[],['setup-wizard.py','setup-wizard.py --execute --pairing-only']),
                ('Install/update app',[],['setup-wizard.py','setup-wizard.py --execute']),
                ('Show plan',[],['setup-wizard.py']),('CANCEL',[],['setup-wizard.py']),
                ('unused',['--execute','--pairing-only'],['setup-wizard.py --execute --pairing-only']),
                ('unused',['--unknown'],['setup-wizard.py --unknown'])]:
                log.unlink(missing_ok=True)
                subprocess.run(['bash',str(launcher),*arguments],env={**os.environ,'PAIR_TEST_LOG':str(log),'PAIR_TEST_CHOICE':choice},check=True,capture_output=True)
                self.assertEqual(log.read_text().splitlines(),[str(root/name) for name in suffixes])

    def test_pairing_failure_messages_are_exact_allowlist_and_never_expose_raw_output(self):
        private_marker="TEST_ONLY_SECRET_OR_DEVICE_IDENTIFIER"
        for source,message in workflow.REMOTE_PAIRING_FAILURES.items():
            safe=("RP_BOOTSTRAP_STOPPED: "+source+"\n").encode()
            self.assertEqual(workflow.remote_pairing_failure(1,safe),message)
            self.assertNotIn(private_marker,workflow.remote_pairing_failure(1,safe+private_marker.encode()))
            # Matching words within arbitrary/prefixed/suffixed output must not
            # become an accepted device result or expose private tool output.
            for raw in [b"prefix "+safe,safe.rstrip()+private_marker.encode(),private_marker.encode(),b"\xff"+safe,safe+safe]:
                result=workflow.remote_pairing_failure(1,raw)
                self.assertNotIn(private_marker,result);self.assertNotEqual(result,message)
        self.assertIn("stopped before returning",workflow.remote_pairing_failure(-9,private_marker.encode()))

    def test_helper_rejects_tampered_binary_unpinned_source_and_missing_notices(self):
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='rp-kit-fixture-',dir=base) as temporary:
            root=pathlib.Path(temporary)
            source={'sha256':'c'*64,'bytes':123,'file':'source.tar.xz'}
            paths={'binary':'app-installer/device/tools/app-installer-rp-bootstrap',
                   'manifest':'app-installer/device/tools/RPBootstrapBuildManifest.json',
                   'notices':'app-installer/device/tools/RPBootstrapThirdPartyNotices.txt',
                   'notice_report':'app-installer/device/tools/RPBootstrapThirdPartyNoticeReport.json'}
            tool={**paths,'source_commit':'a'*40,'source_tree_sha256':'b'*64,'version':'0.1.0',
                  'architectures':['arm64','x86_64'],'protocol_record_version':2,'ad_hoc_signed':True,'notarized':False}
            graph={'aarch64-apple-darwin':'d'*64,'x86_64-apple-darwin':'e'*64}
            report={'notice_obligations_satisfied':True,'notice_gap_count':0,'locked_dependency_graph_hash':'f'*64,
                    'target_graph_hashes':graph,'targets':list(graph)}
            receipt={**{k:tool[k] for k in ['source_commit','source_tree_sha256','version','architectures','protocol_record_version','ad_hoc_signed','notarized']},
                     'schema_version':1,'test_fixture':False,'tool':'app-installer-rp-bootstrap','build_succeeded':True,
                     'targets':list(graph),'minimum_macos':'12.0','apple_developer_identity_used':False,'version_only_executed':True,
                     'usb_or_pairing_executed':False,'personal_resources_used':False,'corresponding_source_delivery_pending':False,
                     'source_bundle_sha256':source['sha256'],'source_bundle_file':source['file'],'source_bundle_bytes':source['bytes'],
                     'source_bundle_delivery':'separate-cloud-companion-artifact','locked_dependency_graph_hash':'f'*64,'target_graph_hashes':graph}
            payload={'binary':b'NOT AN EXECUTABLE: UNIT FIXTURE ONLY','notices':b'FAKE LICENSE FIXTURE ONLY',
                     'notice_report':json.dumps(report).encode()}
            def write_receipt():
                entries=[]
                for field,data in payload.items():
                    path=root/paths[field];path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
                    record={'file':path.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
                    receipt[field]=record;entries.append({'path':paths[field],**{k:record[k] for k in ['bytes','sha256']}})
                data=json.dumps(receipt).encode();(root/paths['manifest']).write_bytes(data)
                entries.append({'path':paths['manifest'],'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
                return {'secure_rp_tool':copy.deepcopy(tool),'source_commit':'a'*40,'source_tree_sha256':'b'*64,'corresponding_source':source,'files':entries}
            kit=write_receipt()
            with patch.object(workflow,'ROOT',root):
                self.assertEqual(workflow.validate_remote_pairing_tool(kit),root/paths['binary'])
                (root/paths['binary']).write_bytes(b'TAMPERED')
                with self.assertRaises(workflow.WorkflowError):workflow.validate_remote_pairing_tool(kit)
                kit=write_receipt()
                for key,value in [('source_commit','9'*40),('protocol_record_version',1),('notarized',True),('binary','../other')]:
                    altered=copy.deepcopy(kit);altered['secure_rp_tool'][key]=value
                    with self.assertRaises(workflow.WorkflowError):workflow.validate_remote_pairing_tool(altered)
                # Rehashed transfer metadata must not excuse a notice gap or a
                # helper receipt bound to a different corresponding source.
                payload['notice_report']=json.dumps({**report,'notice_gap_count':1}).encode();kit=write_receipt()
                with self.assertRaises(workflow.WorkflowError):workflow.validate_remote_pairing_tool(kit)
                payload['notice_report']=json.dumps(report).encode();receipt['source_bundle_sha256']='0'*64;kit=write_receipt()
                with self.assertRaises(workflow.WorkflowError):workflow.validate_remote_pairing_tool(kit)
                receipt['source_bundle_sha256']=source['sha256'];kit=write_receipt()
                path=root/paths['binary'];path.unlink();path.symlink_to(root/paths['notices'])
                with self.assertRaises(workflow.WorkflowError):workflow.validate_remote_pairing_tool(kit)

    def test_pairing_only_skips_account_install_and_launch_timeout_does_not_block_pairing(self):
        calls=[];fail_step=None
        def step(argv):calls.append(argv[0]);return 1 if argv[0]==fail_step else 0
        with ExitStack() as stack:
            for method in ['mac_only','private_directory','local_preflight']:
                stack.enter_context(patch.object(wizard.workflow,method,return_value=None))
            stack.enter_context(patch.object(wizard.workflow,'bootstrap_kit',return_value={'TEST_ONLY':True}))
            stack.enter_context(patch.object(wizard,'choose_device',return_value=('TEST-ONLY-DEVICE','duo')))
            account=stack.enter_context(patch.object(wizard,'teams_with_signing_keys',return_value=['TESTTEAM01']))
            stack.enter_context(patch.object(wizard.workflow,'device_json',return_value={'result':{'apps':[]}}))
            stack.enter_context(patch.object(wizard.workflow,'main',side_effect=step))
            instructions=stack.enter_context(patch.object(wizard,'pairing_export_instructions'))
            stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
            self.assertEqual(wizard.main(['--execute','--pairing-only']),0)
            self.assertEqual(calls,['create-remote-pairing']);account.assert_not_called();instructions.assert_called_once()
            calls.clear();instructions.reset_mock();fail_step='launch'
            self.assertEqual(wizard.main(['--execute']),0)
            self.assertEqual(calls,['prepare','build','install','launch','create-remote-pairing']);instructions.assert_called_once()
            calls.clear();instructions.reset_mock();fail_step='install'
            self.assertEqual(wizard.main(['--execute']),1)
            self.assertEqual(calls,['prepare','build','install']);instructions.assert_not_called()

if __name__=='__main__':unittest.main()
