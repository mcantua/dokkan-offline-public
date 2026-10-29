#!/usr/bin/env python3
"""Build two tiny unsigned test IPAs, cloud-only; default dry-run."""
import argparse,hashlib,json,os,pathlib,plistlib,shutil,stat,struct,subprocess,sys,tempfile,zipfile
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[2]
APP_ID='org.tin.installationcheck'
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--execute',action='store_true');args=parser.parse_args()
    if not args.execute:
        print('PLAN ONLY: would compile two unsigned, owned install/update fixtures with existing cloud LLVM/iPhoneOS16.5 SDK; no download, signing or device use.');return 0
    if sys.platform!='linux':raise RuntimeError('This recipe runs only in the cloud Linux workspace, never on Tin’s Mac.')
    llvm=ROOT/'downloads/llvm/root/usr/lib/llvm-19';sdk=ROOT/'downloads/apple-sdk/source/iPhoneOS16.5.sdk'
    if not (llvm/'bin/clang').is_file() or not sdk.is_dir():raise RuntimeError('Existing cloud LLVM/16.5 SDK required; no download is automatic.')
    outputs=ROOT/'builds';outputs.mkdir(exist_ok=True)
    environment={**os.environ,'LD_LIBRARY_PATH':str(ROOT/'downloads/llvm/root/usr/lib/x86_64-linux-gnu')}
    receipts=[]
    with tempfile.TemporaryDirectory(prefix='fixture-',dir=HERE) as temporary:
        work=pathlib.Path(temporary);binary=work/'InstallationCheck'
        subprocess.run([str(llvm/'bin/clang'),'-target','arm64-apple-ios16.4','-isysroot',str(sdk),'-fobjc-arc','-fmodules','-fmodules-cache-path='+str(work/'modules'),'-fuse-ld=lld','-B'+str(llvm/'bin'),'-Werror=return-type','-Werror=implicit-function-declaration',str(HERE/'main.m'),'-framework','UIKit','-framework','Foundation','-lSystem','-lobjc','-Wl,-platform_version,ios,16.4,16.5','-Wl,-no_adhoc_codesign','-o',str(binary)],cwd=ROOT,env=environment,check=True)
        binary.chmod(0o755)
        for number in [1,2]:
            app=work/str(number)/'Payload/InstallationCheck.app';app.mkdir(parents=True);shutil.copy2(binary,app/'InstallationCheck');shutil.copy2(HERE/'LICENSE',app/'LICENSE.txt')
            info={'CFBundleIdentifier':APP_ID,'CFBundleExecutable':'InstallationCheck','CFBundleName':'InstallationCheck','CFBundleDisplayName':'Installation Check','CFBundlePackageType':'APPL','CFBundleShortVersionString':f'{number}.0','CFBundleVersion':str(number),'MinimumOSVersion':'16.4','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1],'UILaunchScreen':{},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait','UIInterfaceOrientationLandscapeLeft','UIInterfaceOrientationLandscapeRight'],'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False,'UISceneConfigurations':{'UIWindowSceneSessionRoleApplication':[{'UISceneConfigurationName':'Default','UISceneDelegateClassName':'CheckScene'}]}}}
            (app/'Info.plist').write_bytes(plistlib.dumps(info));(app/'BuildMetadata.json').write_text(json.dumps({'test_only':True,'unsigned':True,'compilation_sdk':'16.5','deployment_target':'16.4','physical_device_verified':False,'duo_verified':False})+'\n')
            output=outputs/f'InstallationCheck-v{number}.ipa'
            with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
                for file in sorted(app.iterdir()):archive.write(file,'Payload/InstallationCheck.app/'+file.name)
            receipts.append({'file':output.name,'bytes':output.stat().st_size,'sha256':digest(output),'version':f'{number}.0','bundle_id':APP_ID})
        # One grouped structural check: both real arm64 executables, truthful SDK,
        # scene identity, permissions, no profile/code signature, and differing versions.
        versions=[]
        for receipt in receipts:
            with zipfile.ZipFile(outputs/receipt['file']) as archive:
                assert archive.testzip() is None
                names=archive.namelist();assert not any('_CodeSignature' in name or name.endswith('.mobileprovision') for name in names)
                data=archive.read('Payload/InstallationCheck.app/InstallationCheck');header=struct.unpack_from('<8I',data);assert header[0]==0xfeedfacf and header[1]==0x100000c
                offset=32;marks=[]
                for _ in range(header[4]):
                    cmd,size=struct.unpack_from('<2I',data,offset)
                    if cmd==0x32:marks.append(struct.unpack_from('<6I',data,offset)[2:5])
                    assert cmd!=0x1d,'Fixture must remain unsigned';offset+=size
                assert marks==[(2,(16<<16)|(4<<8),(16<<16)|(5<<8))]
                info=plistlib.loads(archive.read('Payload/InstallationCheck.app/Info.plist'));assert info['CFBundleIdentifier']==APP_ID and info['UIApplicationSceneManifest']['UISceneConfigurations']['UIWindowSceneSessionRoleApplication'][0]['UISceneDelegateClassName']=='CheckScene'
                assert archive.getinfo('Payload/InstallationCheck.app/InstallationCheck').external_attr>>16&stat.S_IXUSR
                versions.append((info['CFBundleShortVersionString'],info['CFBundleVersion']))
        assert versions==[('1.0','1'),('2.0','2')]
        kit=outputs/'InstallationCheck-test-fixture.zip'
        with zipfile.ZipFile(kit,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
            for file in [HERE/'main.m',HERE/'LICENSE',HERE/'README.md',HERE/'build.py']:archive.write(file,'source/'+file.name)
            for receipt in receipts:archive.write(outputs/receipt['file'],receipt['file'])
    report={'schema_version':1,'test_only':True,'unsigned':True,'artifacts':receipts,'delivery':{'file':kit.name,'bytes':kit.stat().st_size,'sha256':digest(kit)},'structural_check_passed':True,'physical_install_verified':False,'physical_update_verified':False,'data_retention_verified':False,'personal_resources_used':False}
    (outputs/'InstallationCheck-test-fixture.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2));return 0
if __name__=='__main__':raise SystemExit(main())
