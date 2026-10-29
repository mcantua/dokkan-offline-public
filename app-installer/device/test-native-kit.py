#!/usr/bin/env python3
"""Two grouped native-kit boundaries; cloud fixtures are never physical-device evidence."""
import contextlib, hashlib, importlib.util, io, json, pathlib, stat, tempfile, types, unittest, zipfile
from unittest.mock import patch
HERE=pathlib.Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('workflow',HERE/'device-workflow.py')
workflow=importlib.util.module_from_spec(spec);spec.loader.exec_module(workflow)

class NativeKitBoundary(unittest.TestCase):
    def fixture(self,root):
        values={'README.md':b'fixture rules','app-installer/LICENSE':b'fixture license','app-installer/licensing-signing.md':b'fixture relink rights',
                'app-installer/device/.gitignore':b'/private/\n','app-installer/device/device-workflow.py':b'fixture script',
                'app-installer/ios/Info.plist':b'fixture info','app-installer/ios/Fixture.m':b'fixture source',
                'app-installer/core/app_installer.h':b'fixture API','app-installer/core/secure_storage.h':b'fixture storage API',
                'app-installer/device/private/input/libapp_installer_core.a':b'not a linkable archive; parser fixture only',
                'app-installer/device/private/input/cloud-device-library-manifest.json':b'{}'}
        entries=[]
        for name,data in values.items():
            path=root/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            entries.append({'path':name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
        manifest={'schema_version':1,'test_fixture':False,'project':'claude-chatg','source_commit':'a'*40,'bootstrap_tool_commit':'d'*40,'source_tree_sha256':'b'*64,
                  'files':entries,'native_sources':['app-installer/ios/Fixture.m'],'rust_library':'app-installer/device/private/input/libapp_installer_core.a',
                  'library_manifest':'app-installer/device/private/input/cloud-device-library-manifest.json',
                  'review_resources':'app-installer/device/private/input/review-resources',
                  'corresponding_source':{'file':'AppInstaller-corresponding-source.tar.xz','sha256':'c'*64,'bytes':123,
                                         'delivery':'separate-cloud-companion-artifact','artifact':'app-installer-cloud-ui-latest','path':'candidates/AppInstaller-corresponding-source.tar.xz'}}
        (root/'BootstrapKitManifest.json').write_text(json.dumps(manifest));return manifest

    def test_minimal_kit_hash_private_path_and_no_git_cargo_requirements(self):
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='native-kit-',dir=base) as temporary:
            root=pathlib.Path(temporary);manifest=self.fixture(root);private=root/'app-installer/device/private'
            with patch.object(workflow,'ROOT',root),patch.object(workflow,'PRIVATE',private):
                with patch.object(workflow.subprocess,'run',side_effect=AssertionError('minimal kit unexpectedly required Git/Cargo/device command')):
                    self.assertEqual(workflow.bootstrap_kit()['source_commit'],'a'*40);workflow.private_directory()
                    self.assertEqual(workflow.bootstrap_kit()['bootstrap_tool_commit'],'d'*40)
                builder_spec=importlib.util.spec_from_file_location('kit_builder',HERE/'make-bootstrap-kit.py')
                builder=importlib.util.module_from_spec(builder_spec);builder_spec.loader.exec_module(builder)
                with patch.object(builder.workflow,'command',return_value=b'') as git:
                    builder.verify_source_revision(manifest,'d'*40,'b'*64)
                    self.assertEqual(git.call_args.args[0],['git','merge-base','--is-ancestor','a'*40,'d'*40])
                    with self.assertRaises(builder.workflow.WorkflowError):builder.verify_source_revision(manifest,'d'*40,'e'*64)
                with patch.object(builder.workflow,'command',side_effect=builder.workflow.WorkflowError('Missing/shallow/unrelated local history fixture')):
                    with self.assertRaises(builder.workflow.WorkflowError):builder.verify_source_revision(manifest,'d'*40,'b'*64)
                del manifest['bootstrap_tool_commit'];(root/'BootstrapKitManifest.json').write_text(json.dumps(manifest))
                with self.assertRaises(workflow.WorkflowError):workflow.bootstrap_kit()
                manifest['bootstrap_tool_commit']='d'*40;(root/'BootstrapKitManifest.json').write_text(json.dumps(manifest))
                self.assertEqual(stat.S_IMODE(private.stat().st_mode),0o700)
                source=root/'app-installer/ios/Fixture.m';source.write_bytes(b'tampered')
                with self.assertRaises(workflow.WorkflowError):workflow.bootstrap_kit()
                source.write_bytes(b'fixture source')
                extra=root/'app-installer/ios/Unlisted.m';extra.write_bytes(b'unlisted native compilation input')
                with self.assertRaises(workflow.WorkflowError):workflow.bootstrap_kit()
                extra.unlink()
                secret=root/'app-installer/device/private/input/pairing.mobiledevicepairing';secret.write_bytes(b'FAKE KEY SHAPE; NO ACTUAL KEY')
                manifest['files'].append({'path':str(secret.relative_to(root)),'bytes':secret.stat().st_size,'sha256':workflow.sha256(secret)})
                (root/'BootstrapKitManifest.json').write_text(json.dumps(manifest))
                with self.assertRaises(workflow.WorkflowError):workflow.bootstrap_kit()

    def test_duo_model_guard_and_private_signed_zip_permissions_without_claiming_real_signature(self):
        base=workflow.ROOT/'app-installer/core/target';base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='native-device-fixture-',dir=base) as temporary:
            private=pathlib.Path(temporary)/'private';private.mkdir()
            args=types.SimpleNamespace(variant='duo',device='NOT-A-REAL-DEVICE')
            physical_udid='00000000-0000000000000000'  # Non-device fixture, never hardware evidence.
            fake={'result':{'deviceProperties':{'osVersionNumber':'27.1'},'hardwareProperties':{'productType':'iPhone18,1','udid':physical_udid}}}
            with patch.object(workflow,'PRIVATE',private),patch.object(workflow,'command',return_value=b'27.1'),patch.object(workflow,'device_json',return_value=fake):
                with self.assertRaises(workflow.WorkflowError):workflow.diagnose(args)
                self.assertFalse((private/'diagnosis.json').exists())
                fake['result']['hardwareProperties']['productType']='unknown-model'
                with self.assertRaises(workflow.WorkflowError):workflow.diagnose(args)
                fake['result']['hardwareProperties']['productType']='iPhone19,4'
                diagnosis=workflow.diagnose(args)
                self.assertEqual(diagnosis['phone_model'],'iPhone19,4')
                self.assertEqual(args.physical_udid,physical_udid)
                self.assertNotIn(physical_udid,json.dumps(diagnosis))
                wizard_spec=importlib.util.spec_from_file_location('wizard',HERE/'setup-wizard.py')
                wizard=importlib.util.module_from_spec(wizard_spec);wizard_spec.loader.exec_module(wizard)
                selected={'identifier':'11111111-2222-3333-4444-555555555555','hardwareProperties':{'productType':'iPhone19,4','udid':physical_udid}}
                def list_devices(argv,*,step):
                    pathlib.Path(argv[argv.index('--json-output')+1]).write_text(json.dumps({'result':{'devices':[selected]}}));return b''
                with patch.object(wizard.workflow,'PRIVATE',private),patch.object(wizard.workflow,'command',side_effect=list_devices):
                    self.assertEqual(wizard.choose_device(),(physical_udid,'duo'))
                    del selected['hardwareProperties']['udid']
                    with self.assertRaises(wizard.workflow.WorkflowError):wizard.choose_device()
                    selected['hardwareProperties']['udid']=selected['identifier']
                    with self.assertRaises(wizard.workflow.WorkflowError):wizard.choose_device()
                # ZIP writer fixture only: no signature/profile verification or Mac command is called.
                app=private/'DerivedData/Build/Products/Release-iphoneos/AppInstaller.app';app.mkdir(parents=True)
                (app/'AppInstaller').write_bytes(b'NOT AN EXECUTABLE; ZIP PERMISSION FIXTURE ONLY');(app/'AppInstaller').chmod(0o755)
                (app/'embedded.mobileprovision').write_bytes(b'NOT A PROFILE; UNIT FIXTURE ONLY')
                (app/'_CodeSignature').mkdir();(app/'_CodeSignature/CodeResources').write_bytes(b'NOT A SIGNATURE; UNIT FIXTURE ONLY')
                receipt=workflow.export_signed_ipa(args,{'unit_fixture_only':True})
                path=private/'builds'/receipt['signed_ipa_file']
                with zipfile.ZipFile(path) as archive:
                    self.assertTrue((archive.getinfo('Payload/AppInstaller.app/AppInstaller').external_attr>>16)&stat.S_IXUSR)
                    self.assertEqual(archive.read('Payload/AppInstaller.app/AppInstaller'),(app/'AppInstaller').read_bytes())
                self.assertFalse(receipt['device_install_attempted']);self.assertTrue(receipt['unit_fixture_only'])
                for file in (private/'builds').iterdir():file.unlink()
                (private/'builds').rmdir();elsewhere=private/'other';elsewhere.mkdir();(private/'builds').symlink_to(elsewhere,target_is_directory=True)
                with self.assertRaises(workflow.WorkflowError):workflow.export_signed_ipa(args,{'unit_fixture_only':True})

if __name__=='__main__':unittest.main()
