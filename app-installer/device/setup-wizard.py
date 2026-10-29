#!/usr/bin/env python3
"""One-click approved setup helper. Default is a side-effect-free explanation.

Run --execute only after Tin explicitly approves this session's exact Mac, selected
connection, Apple provisioning, USB installation and pairing-tool setup. Passwords
and 2FA stay in Xcode/Apple UI or on the phone; nothing is asked in chat or this helper.
"""
import argparse, hashlib, importlib.util, json, pathlib, re, ssl, subprocess, sys, tempfile
sys.dont_write_bytecode=True
HERE=pathlib.Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('workflow',HERE/'device-workflow.py')
workflow=importlib.util.module_from_spec(spec);spec.loader.exec_module(workflow)

PICK='''on run argv
set promptText to item 1 of argv
set optionsList to items 2 thru -1 of argv
set choice to choose from list optionsList with title "App Installer setup" with prompt promptText without multiple selections allowed
if choice is false then error number -128
return item 1 of choice
end run'''
NOTE='''on run argv
display dialog (item 1 of argv) buttons {"Cancel", "Continue"} default button "Continue" cancel button "Cancel" with title "App Installer setup"
end run'''


def choose(message,choices):
    if not choices:raise workflow.WorkflowError('No supported choice is available yet.')
    if len(choices)==1:return choices[0]
    result=subprocess.run(['osascript','-e',PICK,'--',message,*choices],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    if result.returncode:raise workflow.WorkflowError('Setup was cancelled. No next step was started.')
    selected=result.stdout.decode().strip()
    if selected not in choices:raise workflow.WorkflowError('A supported local selection was not returned.')
    return selected


def note(message):
    result=subprocess.run(['osascript','-e',NOTE,'--',message],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    if result.returncode:raise workflow.WorkflowError('Setup was cancelled. No next step was started.')


def teams_with_signing_keys():
    identities=workflow.command(['security','find-identity','-v','-p','codesigning'],step='Available development signing identity discovery').decode()
    valid=set(re.findall(r'\b[0-9A-Fa-f]{40}\b',identities))
    if not valid:return []
    certificates=workflow.command(['security','find-certificate','-a','-p','-c','Apple Development'],step='Development certificate team discovery').decode()
    teams=set()
    for pem in re.findall(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----',certificates,re.S):
        # Public certificate/subject are read only in local memory, never printed/saved.
        # The actual Team ID is certificate OU, not a guessed common-name suffix.
        der=ssl.PEM_cert_to_DER_cert(pem)
        if hashlib.sha1(der).hexdigest().upper() not in {v.upper() for v in valid}:continue
        result=subprocess.run(['/usr/bin/openssl','x509','-noout','-subject','-nameopt','RFC2253'],input=pem.encode(),stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        if result.returncode:continue
        match=re.search(r'(?:^|,)\s*OU=([A-Z0-9]{10})(?:,|$)',result.stdout.decode().replace('subject=','').strip())
        if match:teams.add(match.group(1))
    return sorted(teams)


def choose_device():
    with tempfile.TemporaryDirectory(prefix='device-selection-',dir=workflow.PRIVATE) as temporary:
        response=pathlib.Path(temporary)/'devices.json'
        workflow.command(['xcrun','devicectl','list','devices','--json-output',str(response)],step='Local iPhone selection')
        try:devices=json.loads(response.read_text())['result']['devices']
        except (ValueError,KeyError,OSError):raise workflow.WorkflowError('Open Xcode Device Hub to connect and trust the iPhone first.') from None
    if not isinstance(devices,list):
        raise workflow.WorkflowError('Xcode returned an unsupported device list. Review the physical iPhone in Xcode before setup.')
    rows={}
    for index,device in enumerate(devices):
        if not isinstance(device,dict):continue
        hardware=device.get('hardwareProperties',{});properties=device.get('deviceProperties',{})
        if not isinstance(hardware,dict) or not isinstance(properties,dict):continue
        model=hardware.get('productType') or hardware.get('model')
        identifier=device.get('identifier')
        if not isinstance(model,str) or not re.fullmatch(r'iPhone[0-9]+,[0-9]+',model) or not isinstance(identifier,str):continue
        try:
            physical=workflow.hardware_udid(hardware)
        except workflow.WorkflowError:
            # A simulator can share an iPhone productType. A CoreDevice UUID is
            # only a query alias, never proof that this row is a physical phone.
            try:
                details=workflow.device_json(argparse.Namespace(device=identifier),'device','info','details')
                result=details.get('result') if isinstance(details,dict) else None
                actual=result.get('hardwareProperties') if isinstance(result,dict) else None
                if not isinstance(actual,dict) or (actual.get('productType') or actual.get('model'))!=model:continue
                physical=workflow.hardware_udid(actual)
            except (workflow.WorkflowError,OSError,ValueError,KeyError,TypeError):
                # Offline/unqueryable/simulator rows are omitted without logging
                # identifiers. No account discovery or provisioning takes place.
                continue
        # Device labels remain in the local selection dialog, not stdout/chat/repo logs.
        name=properties.get('name') if isinstance(properties.get('name'),str) else 'iPhone'
        rows[f'{index+1}. {name} — {model}']=(identifier,model,physical)
    if not rows:
        raise workflow.WorkflowError('No connected physical iPhone with a valid hardware identity is available. Unlock and trust the phone, then review Xcode → Open Developer Tool → Device Hub. Simulator rows are not supported for this setup.')
    identifier,model,physical=rows[choose('Choose the physical iPhone connected for this approved USB setup.',list(rows))]
    # Recheck after the selection dialog: a changed/offline alias must not silently
    # authorize another phone or turn simulator metadata into a physical identity.
    details=workflow.device_json(argparse.Namespace(device=identifier),'device','info','details')
    result=details.get('result') if isinstance(details,dict) else None
    actual=result.get('hardwareProperties') if isinstance(result,dict) else None
    if not isinstance(actual,dict):
        raise workflow.WorkflowError('Xcode did not return this iPhone’s hardware details. Keep it connected and unlocked, then review it in Xcode Device Hub.')
    actual_model=actual.get('productType') or actual.get('model')
    actual_physical=workflow.hardware_udid(actual)
    if actual_model!=model or actual_physical!=physical:
        raise workflow.WorkflowError('The selected iPhone’s current hardware differs from the device list. Reconnect and select the intended physical phone again before setup.')
    return actual_physical,'duo' if actual_model in workflow.DUO_MODELS else 'iphone'



def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--execute',action='store_true')
    p.add_argument('--pairing-only',action='store_true',help='Create or validate the private trusted-USB pairing export without rebuilding, signing or installing the app.')
    args=p.parse_args(argv)
    if not args.execute:
        print('PLAN ONLY — no account, Mac inspection, network, device query or installation was performed.')
        print('After Tin approves the exact setup scope, this helper can verify the cloud kit, use Xcode’s existing Keychain signing identity, check the real phone/SDK, build/sign/install/launch only App Installer, and create a private authenticated pairing file over trusted USB. Pairing-only mode does not rebuild or install.')
        print('You handle Apple sign-in/Trust/Developer Mode and on-phone authentication. Passwords and codes are never requested here. Daily background refresh is not guaranteed.')
        return 0
    try:
        if sys.version_info < (3,9):raise workflow.WorkflowError('Python 3.9 or newer is required. Use a compatible existing local Python or install trusted Python within the already approved dependency setup scope.')
        print('Starting pairing-only checks…' if args.pairing_only else 'Starting approved setup checks…',flush=True)
        workflow.mac_only();workflow.private_directory()
        kit=workflow.bootstrap_kit()
        if not kit:raise workflow.WorkflowError('Use the reviewed minimal native kit for one-click setup; the full source checkout does not provide its prepared archive handoff automatically.')
        print('Verified setup files. Checking existing Xcode tools…',flush=True)
        workflow.local_preflight()
        print('Finding the connected physical iPhone…',flush=True)
        device,variant=choose_device()
        if args.pairing_only:
            if workflow.main(['create-remote-pairing','--execute','--device',device,'--variant',variant])!=0:return 1
            pairing_export_instructions()
            return 0
        teams=teams_with_signing_keys()
        if not teams:
            raise workflow.WorkflowError('An existing Apple Development signing identity is not available. Stop before changing Apple account credentials or creating/replacing a certificate. Review Xcode → Settings → Accounts locally, then obtain separate approval for the exact needed account/certificate step; keep passwords and verification codes in Apple’s UI.')
        team=choose('Choose the same development team you will use inside App Installer.',teams)
        local=workflow.parser().parse_args(['diagnose','--execute','--device',device,'--team',team,'--variant',variant])
        # Preserve an existing installer identity rather than silently creating a second app.
        apps_response=workflow.device_json(local,'device','info','apps')
        apps=apps_response.get('result',{}).get('apps')
        if not isinstance(apps,list):raise workflow.WorkflowError('The installed-app query needs local Xcode review before choosing a stable update identity.')
        existing=sorted({app.get('bundleIdentifier') for app in apps if isinstance(app,dict) and isinstance(app.get('bundleIdentifier'),str) and (app['bundleIdentifier']==workflow.BUNDLE_PREFIX or app['bundleIdentifier'].startswith(workflow.BUNDLE_PREFIX+'.'))})
        bundle=choose('Choose the existing App Installer identity to update; no app will be removed.',existing) if existing else None
        base=['--execute','--device',device,'--team',team,'--variant',variant]
        if bundle:base+=['--bundle-id',bundle]
        for step in ['prepare','build','install']:
            print({'prepare':'Checking actual iPhone/SDK and verified cloud files…','build':'Building/signing this one app with Xcode…','install':'Installing the verified App Installer over the approved connection…','launch':'Launching App Installer…'}[step])
            if workflow.main([step,*base])!=0:return 1
        print('Launching App Installer…')
        if workflow.main(['launch',*base])!=0:
            # The preceding install must succeed; an optional launch timeout must
            # not strand the independent, already approved USB pairing step.
            print('The verified app was installed, but automatic launch was not confirmed. Open App Installer manually on this iPhone. Continuing trusted USB pairing; no reinstall is needed for a launch timeout.')
        if workflow.main(['create-remote-pairing','--execute','--device',device,'--variant',variant])!=0:return 1
        pairing_export_instructions()
        return 0
    except (workflow.WorkflowError,OSError,ValueError,KeyError,TypeError):
        error=sys.exc_info()[1]
        print(str(error) if isinstance(error,workflow.WorkflowError) else 'Setup could not finish safely. Review the current step locally; no raw private output was saved.',file=sys.stderr)
        return 1

def pairing_export_instructions():
    directory=workflow.private_path(workflow.PRIVATE/'secure-rp')
    workflow.command(['open',str(directory)],step='Opening the private pairing-export folder')
    note('The private pairing.mobiledevicepairing file is ready. AirDrop that file directly to this iPhone, then in App Installer choose Replace pairing file and import it. Keep LocalDevVPN connected and the iPhone on Wi-Fi, then unlock and check the connection. Do not paste or upload the file to chat or GitHub. Keep the Mac copy until the phone connection succeeds; then remove the temporary export. Installation, updates and refresh are not verified by this setup message.')

if __name__=='__main__':raise SystemExit(main())
