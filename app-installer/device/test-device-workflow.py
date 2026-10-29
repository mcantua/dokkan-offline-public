#!/usr/bin/env python3
"""Two grouped cloud-only checks. No macOS, Apple, network or device calls."""
import contextlib, copy, datetime as dt, hashlib, importlib.util, io, json, pathlib, tempfile, unittest
from unittest.mock import patch

HERE=pathlib.Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location("device_workflow",HERE/"device-workflow.py")
workflow=importlib.util.module_from_spec(spec);spec.loader.exec_module(workflow)

class WorkflowTests(unittest.TestCase):
    def test_every_default_step_is_side_effect_free_and_native_project_preserves_identity(self):
        with patch.object(workflow,"command",side_effect=AssertionError("dry-run invoked a command")), patch.object(workflow,"private_directory",side_effect=AssertionError("dry-run created private output")), patch.object(workflow,"mac_only",side_effect=AssertionError("dry-run inspected a Mac")):
            for step in ["diagnose","prepare","build","install","launch","fetch-pairing-tool","remove-pairing-export"]:
                out=io.StringIO()
                with contextlib.redirect_stdout(out): self.assertEqual(workflow.main([step]),0)
                self.assertIn("DRY RUN",out.getvalue())
        base=workflow.ROOT/"app-installer/core/target";base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="device-workflow-test-",dir=base) as temporary:
            private=pathlib.Path(temporary)/"private";library=private/"input/AppInstallerCore-ios.a"
            library.parent.mkdir(parents=True);library.write_bytes(b"offline archive fixture")
            import zipfile
            review=library.with_name("review.ipa")
            with zipfile.ZipFile(review,"w") as z:
                z.writestr("Payload/AppInstaller.app/ThirdPartyNotices.txt","Offline notice fixture")
                z.writestr("Payload/AppInstaller.app/ThirdPartyNoticeReport.json",json.dumps({"notice_gap_count":0,"notice_obligations_satisfied":True}))
                z.writestr("Payload/AppInstaller.app/BuildMetadata.json",json.dumps({"unsigned":True,"variant":"iphone"}))
            with patch.object(workflow,"PRIVATE",private):
                project=workflow.generate_project("TESTTEAM01","org.tin.appinstaller.ttestteam01","iphone",library,review_ipa=review)
            import plistlib,xml.etree.ElementTree as ET
            info=plistlib.loads((project.parent/"Info.plist").read_bytes())
            self.assertEqual(info["CFBundleIdentifier"],"org.tin.appinstaller.ttestteam01")
            self.assertEqual(info["BGTaskSchedulerPermittedIdentifiers"],["org.tin.appinstaller.ttestteam01.refresh"])
            self.assertNotIn("UIRequiresFullScreen",info)
            self.assertFalse(any(key.startswith("DT") for key in info),"native Xcode must supply genuine SDK marks")
            requested=plistlib.loads((project.parent/"AppInstaller.entitlements").read_bytes())
            self.assertEqual(requested,{"keychain-access-groups":["$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)"]})
            source=(project/"project.pbxproj").read_text()
            self.assertIn('"CODE_SIGN_STYLE" = "Automatic"',source)
            self.assertIn('"DEVELOPMENT_TEAM" = "TESTTEAM01"',source)
            for native in (workflow.ROOT/"app-installer/ios").glob("*.m"): self.assertIn(native.name,source)
            scheme=ET.parse(project/"xcshareddata/xcschemes/AppInstaller.xcscheme")
            self.assertEqual(scheme.find(".//BuildableReference").attrib["BlueprintName"],"AppInstaller")

    def test_cloud_archive_integrity_and_profile_device_capability_boundaries(self):
        base=workflow.ROOT/"app-installer/core/target";base.mkdir(parents=True,exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="device-handoff-test-",dir=base) as temporary:
            private=pathlib.Path(temporary)/"private";library=private/"input/AppInstallerCore-ios.a";library.parent.mkdir(parents=True)
            library.write_bytes(b"exact reviewed cloud input")
            manifest=library.with_name("manifest.json")
            data={"schema_version":1,"target":"aarch64-apple-ios","file":library.name,"bytes":library.stat().st_size,"sha256":hashlib.sha256(library.read_bytes()).hexdigest(),"source_commit":"a"*40,"source_tree_sha256":"b"*64}
            manifest.write_text(json.dumps(data))
            with patch.object(workflow,"PRIVATE",private):
                self.assertEqual(workflow.load_handoff(manifest,library)["sha256"],data["sha256"])
                library.write_bytes(b"same path but changed contents")
                with self.assertRaises(workflow.WorkflowError): workflow.load_handoff(manifest,library)
                library.write_bytes(b"exact reviewed cloud input")
                link=library.with_name("alias.a");link.symlink_to(library)
                with self.assertRaises(workflow.WorkflowError): workflow.load_handoff(manifest,link)
        team,bundle,device="TESTTEAM01","org.tin.appinstaller.ttestteam01","LOCAL-DEVICE-FIXTURE"
        now=dt.datetime(2026,10,28,tzinfo=dt.timezone.utc);appid=team+"."+bundle
        entitlements={"application-identifier":appid,"com.apple.developer.team-identifier":team,"keychain-access-groups":[appid],"get-task-allow":True}
        profile={"TeamIdentifier":[team],"ProvisionedDevices":[device],"ApplicationIdentifierPrefix":[team],"ExpirationDate":now+dt.timedelta(days=7),"Entitlements":{**entitlements,"application-identifier":team+".*","keychain-access-groups":[team+".*"]}}
        report=workflow.verify_profile(profile,entitlements,team=team,bundle=bundle,device=device,now=now)
        self.assertTrue(report["profile_covers_selected_device"])
        self.assertNotIn(device,json.dumps(report));self.assertNotIn(team,json.dumps(report))
        for reduced in [{**entitlements,"get-task-allow":False},{key:value for key,value in entitlements.items() if key!="get-task-allow"}]:
            self.assertTrue(workflow.verify_profile(profile,reduced,team=team,bundle=bundle,device=device,now=now)["development_profile_capabilities_verified"])
        invalid=[]
        p=copy.deepcopy(profile);p["ProvisionedDevices"]=[];invalid.append((p,entitlements))
        p=copy.deepcopy(profile);p["ExpirationDate"]=now-dt.timedelta(seconds=1);invalid.append((p,entitlements))
        p=copy.deepcopy(profile);p["Entitlements"]["application-identifier"]=team+".other.app";invalid.append((p,entitlements))
        e={**entitlements,"com.apple.developer.networking.networkextension":["packet-tunnel-provider"]};invalid.append((profile,e))
        e={**entitlements,"keychain-access-groups":[team+".*"]};invalid.append((profile,e))
        for nonbool in [0,1,None,"true"]: invalid.append((profile,{**entitlements,"get-task-allow":nonbool}))
        p=copy.deepcopy(profile);p["Entitlements"]["get-task-allow"]=False;invalid.append((p,entitlements))
        for p,e in invalid:
            with self.assertRaises(workflow.WorkflowError): workflow.verify_profile(p,e,team=team,bundle=bundle,device=device,now=now)
        # Public-certificate fixture only: no real codesign, trust store or Apple call.
        with tempfile.TemporaryDirectory(prefix="public-cert-fixture-",dir=base) as temporary:
            private=pathlib.Path(temporary);app=private/"fixture.app";calls=[]
            def fake_command(argv,*,step):
                calls.append(argv)
                if argv[0]=="codesign":
                    prefix=pathlib.Path(next(value.split("=",1)[1] for value in argv if value.startswith("--extract-certificates=")))
                    pathlib.Path(str(prefix)+"0").write_bytes(b"public DER leaf fixture")
                    pathlib.Path(str(prefix)+"1").write_bytes(b"public DER intermediate fixture")
                return b""
            valid={"DeveloperCertificates":[b"public DER leaf fixture"]}
            with patch.object(workflow,"PRIVATE",private),patch.object(workflow,"command",side_effect=fake_command):
                self.assertTrue(workflow.verify_signing_certificate(app,valid)["signing_leaf_matches_profile"])
                self.assertEqual(calls[-1][:4],["security","verify-cert","-p","codeSign"])
                self.assertEqual(list(private.iterdir()),[],"public cert temporary files must be deleted")
                for certificates in [None,[],["not DER"],[b"foreign leaf"]]:
                    with self.assertRaises(workflow.WorkflowError):workflow.verify_signing_certificate(app,{"DeveloperCertificates":certificates})
                def failed_trust(argv,*,step):
                    if argv[0]=="security":raise workflow.WorkflowError("OS trust fixture rejected")
                    return fake_command(argv,step=step)
                with patch.object(workflow,"command",side_effect=failed_trust):
                    with self.assertRaises(workflow.WorkflowError):workflow.verify_signing_certificate(app,valid)
                self.assertEqual(list(private.iterdir()),[],"failed trust must also remove public cert temporary files")

if __name__=="__main__": unittest.main()
