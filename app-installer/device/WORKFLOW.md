# Operator workflow for the approved update and trusted USB pairing

Read the root README first. Tin has already reported native signing/export/install and manual launch on the physical phone; the app later reached Signed in and saved its old pairing import. Mac LAN Lockdown validation worked, while the phone’s own pairing session still failed. These observations do not verify the full account/sign/install/update/refresh workflow.

Tin’s explicit approval for routine MacBook/USB Duo/network/current-kit/pairing/trusted dependencies persists; do not ask again for those same steps. Significantly larger Xcode installations and Apple-credential changes retain their separate approval boundary. The cloud agent has no direct USB or Mac-control access; approved execution can be guided manually. The new strict version-2 helper described below must be delivered in a matching, hash-verified new kit before use; prepared source alone is not a delivered binary.

`device-workflow.py` always prints a plan unless `--execute` is present. Dry-run invokes no subprocess, network request, device query or filesystem write. The switch records operator intent; it is not evidence of Tin's approval. The assistant must respect the existing scope recorded in STATUS.md and obtain additional approval only for a newly required action outside it. All commands below are examples for the operator after that approval; do not ask Tin to paste account secrets or device identifiers into chat.

## Why native Xcode is the bootstrap path

A hosted macOS runner already compiled the actual UIKit app and ran simulator tests. It has no configured development identity/account in this session and cannot answer this physical phone's Trust/Developer Mode/pairing prompts. Signing on a cloud Mac would still require a legitimate signing identity/profile and registered device setup; no private key, Apple password, API key or session token should be uploaded to this repo or its artifacts to create that access.

The minimum current physical path is USB plus Xcode's own account UI and OS Keychain on the approved Mac. Automatic provisioning supports a free Personal Team or paid development team. Xcode may create/reuse a development certificate, register the selected phone and provision this app through Apple. The workflow never exports a signing private key or revokes a certificate. If Xcode reports a certificate/app-ID/app-slot quota, stop and ask Tin for the specific account/device decision; do not remove unrelated apps or reset certificates.

Native bootstrap compiles all production Objective-C files with the actual selected Xcode iPhoneOS SDK and links the already cloud-built iOS Rust archive. No Rust toolchain or dependency compilation is needed on Tin's Mac. This avoids treating a Linux binary's synthetic Duo SDK mark as evidence of actual SDK compatibility. For Duo, the workflow requires a real SDK 27.1+ and a supported device OS generation. Native SDK metadata is rechecked in the Mach-O binary before install. Physical folding/rail behavior remains a separate check.

## Cloud archive handoff, before asking for local use

Root packages the current `aarch64-apple-ios/release/libapp_installer_core.a` as `libapp_installer_core.a` in one cloud handoff artifact, never a signed app, pairing record or profile. The manifest has this schema:

```json
{
  "schema_version": 1,
  "target": "aarch64-apple-ios",
  "file": "libapp_installer_core.a",
  "bytes": 123,
  "sha256": "<actual 64-character lowercase SHA-256>",
  "source_commit": "<actual reviewed 40-character commit>",
  "source_tree_sha256": "<actual 64-character production-source fingerprint>"
}
```

The example numbers/fields above are not a real artifact. Root supplies actual byte count/hash/commit from the final cloud build before a transfer is approved. Any artifact over 50 MB stays out of git. The artifact contains no Apple signing credentials; root must not upload profiles/private keys/pairing exports with it. Keep one latest handoff artifact and delete an obsolete one after replacement succeeds.

On Tin’s approved Mac, the confirmed existing project is `~/AI-Workspace/AI-Workspace/claude-chatg`; preserve that location rather than creating another copy. Download the one cloud archive, its manifest, and the same-source unsigned candidate IPA to `app-installer/device/private/input/` in that checkout. That folder is ignored and protected by the parent directory's 0700 permissions. No second repo is created. The library and review IPA source commit/fingerprint must match, and the review IPA must have zero notice gaps. The exact current transfer size/hash must be verified before directing download. The new kit contains the required Mac remote-pairing helper; the old idevice_pair DMG is not required. Actual Apple provisioning traffic/App Store size cannot be predicted exactly; state those purposes instead of inventing a byte count.

## Operator commands after approval

Use the **same** team and stable bundle ID for every step. Values below are local operator placeholders, not real credentials/identifiers. Select the actual phone in Xcode **Device Hub**; keep its identifier local. The team ID is chosen from the account already signed in within Xcode. Run relative commands from the actual existing repository folder selected by the update chooser; do not assume a former nested Mac path. For routine retries, the launcher’s **Pair only** choice is simpler than these advanced operator commands.

```bash
python3 app-installer/device/device-workflow.py diagnose
```

That command is a dry-run. For approved execution, the operator supplies `--execute`, `--device`, `--team`, and `--variant iphone` or `duo`:

```bash
python3 app-installer/device/device-workflow.py diagnose --execute --device "$TIN_DEVICE" --variant iphone
python3 app-installer/device/device-workflow.py prepare --execute --device "$TIN_DEVICE" --team "$TIN_TEAM" --variant iphone --manifest app-installer/device/private/input/manifest.json --rust-library app-installer/device/private/input/libapp_installer_core.a --review-ipa app-installer/device/private/input/AppInstaller-iphone-candidate.ipa
python3 app-installer/device/device-workflow.py build --execute --device "$TIN_DEVICE" --team "$TIN_TEAM" --variant iphone
python3 app-installer/device/device-workflow.py install --execute --device "$TIN_DEVICE" --team "$TIN_TEAM" --variant iphone
python3 app-installer/device/device-workflow.py launch --execute --device "$TIN_DEVICE" --team "$TIN_TEAM" --variant iphone
```

The assistant fills local variables from the approved device/team UI without printing them or writing them into a tracked file. Do not place Apple passwords/codes/tokens in shell variables. If this installer already exists, add `--bundle-id` with that exact existing ID to **every** prepare/build/install/launch command; this preserves the existing app/Keychain identity. Otherwise, the generated ID is `org.tin.appinstaller.t<lowercase team ID>`, and it stays fixed thereafter. The phone and Duo variants share that one installed identity.

Prepared Xcode project: `app-installer/device/private/project/AppInstallerDevice.xcodeproj`. It has one Release configuration and shared AppInstaller scheme. Open it in Xcode if its account/automatic-signing UI needs action. Project build products/DerivedData and any provisioning profile embedded in the signed app stay beneath ignored `private/`. The scripts capture raw tool output in memory, not repo logs. Failed steps return fixed safe error messages. No raw device list, account email, signing identity, full profile, certificate bytes or UDID is copied into the non-secret report.

## Exact capabilities and identity checks

The generated project requests only `keychain-access-groups = [$(AppIdentifierPrefix)$(PRODUCT_BUNDLE_IDENTIFIER)]`. Xcode supplies development `application-identifier`, `com.apple.developer.team-identifier` and `get-task-allow`. Signature verification permits only those four keys and verifies their values against the selected team, bundle and embedded provisioning profile. The profile must explicitly cover the chosen physical device and be unexpired. Profile wildcards may authorize the exact final app identity, but final signed Keychain group is the exact application identifier, never a wildcard. This is needed so initial Xcode signing and later self-refresh preserve access to the same Keychain items.

The development profile must grant `get-task-allow=true`; a Release signature may reduce this to `false` or omit it. Nonboolean values are rejected. The build uses Xcode automatic provisioning, with no imported profile option. Before export/install, `codesign --verify --deep --strict -R='anchor apple generic'` checks code integrity and the Apple issuer requirement. Public-only certificate extraction then requires the exact signing leaf DER bytes in the profile's `DeveloperCertificates`; `security verify-cert -p codeSign` verifies that supplied chain with macOS trust policy. Any unsupported command or trust failure stops setup. Temporary public certificates stay in a protected owned directory and are removed immediately; no private key is exported. CMS decoding alone does not establish Apple's profile-signing authority. The sanitized report explicitly leaves `apple_profile_authority_verified=false` and physical signature acceptance pending until the separate real profile-authority/device validation is completed. Cloud unsigned project compilation cannot exercise these signed checks.

Background fetch is an Info.plist capability (`UIBackgroundModes=[fetch]`), with the permitted task ID rewritten to the actual installed bundle ID plus `.refresh`. Local notifications need no APNs entitlement; Face ID uses its purpose string. There is no network-extension, app-group, push, associated-domain, JIT or private entitlement. LocalDevVPN supplies its own separately approved App Store VPN entitlement.

## Strict version-2 pairing and VPN within the approved setup

Use the matching new native kit’s `app-installer-rp-bootstrap`, not an old idevice_pair Remote export. The old tool’s unpinned Remote format is rejected. Legacy Lockdown export and successful Mac LAN validation remain useful history, but do not establish the on-phone remote-pairing session. Keep existing Lockdown private keys/exports while the replacement is verified.

The reviewed wizard verifies the whole kit, its helper binary/receipt/source/notice bindings, universal Mac architectures and signature integrity before running the helper. Ad-hoc signature integrity is not an Apple notarization claim. Normal macOS security checks remain enabled. The helper permits only the locally selected physical USB iPhone through the system usbmuxd socket, verifies the existing authenticated Lockdown session and live hardware identity, and performs explicit remote pairing on that trusted USB control channel. The official protocol uses its trusted-USB consent value without a user six-digit dialog; this is not an Apple-credential or untrusted-device authentication bypass. SRP-M6 accessory signature verification captures the required peer identity pin; subsequent connections must verify that exact pin.

The only new export is `app-installer/device/private/secure-rp/pairing.mobiledevicepairing`. Its directories are private 0700 and the file is 0600, atomically published without overwriting another file or symlink. Existing bounded, strict version-2 credentials are checked before any new pairing/key generation, then reused only after pinned validation against the selected authenticated USB phone. Failed validation does not fall back to pairing or rotate keys; preserve the file for reviewed recovery. No private record, code, identifier or raw device error is printed.

After one successful same-identity app update, pairing can resume independently:

```bash
/usr/bin/python3 "$HOME/AI-Workspace/AI-Workspace/claude-chatg/app-installer/device/setup-wizard.py" --execute --pairing-only
```

Pairing-only retains the same kit/helper, installed-tool preflight and USB-phone checks, but skips Apple signing-identity discovery/team selection. It does not prepare/build/sign/install the app or require an Apple account change. Full setup attempts launch after successful install; if automatic launch fails, open the app manually and continue pairing. Do not repeat an already successful install to fix a launch timeout.

The wizard opens the private export folder. Use the approved direct local transfer, such as AirDrop, to this same iPhone and choose **Replace pairing file** in App Installer. Do not upload through chat, GitHub, cloud artifacts, shared drives or email. App Installer stores a protected Keychain primary and one authenticated encrypted backup. Keep the old Lockdown export and the new strict record until protected import and a real on-phone connection succeed. Only then use the reviewed cleanup command if the designated temporary copies are no longer needed:

```bash
/usr/bin/python3 "$HOME/AI-Workspace/AI-Workspace/claude-chatg/app-installer/device/device-workflow.py" remove-pairing-export --execute
```

That cleanup removes both designated temporary export paths. It must not run while either record is still needed for validation/recovery. Normal unlinking does not promise forensic erasure on APFS/SSD. Remove an extra phone Downloads transfer copy only after confirmed import. Do not delete OS usbmuxd pairing stores or certificate/Keychain records needed by Xcode.

LocalDevVPN official App Store link: https://apps.apple.com/us/app/localdevvpn/id6755608044 . Keep the phone on Wi-Fi with VPN connected and the defaults interface `configured-address/32`, peer `configured-address/32`. The device host remains that VPN peer; authenticated Bonjour selection may supply its remote-pairing port, and the pinned handshake still decides trust. A VPN Connected label or successful Mac LAN validation alone is not an on-phone connection pass. Apple sign-in/provisioning separately requires internet. Do not disable TLS, reset privacy/trust or delete pairing/signing records as a workaround.

## Two functional runs on the phone, not repeated blind tests

Run 1 — initial setup and update:
- Launch this actual signed app; verify empty login fields, Settings own expiry, correct responsive bounds and no occluded controls. On Duo, inspect outer/inner orientations and one fold/unfold using real reserved regions.
- Sign in on the phone only, complete 2FA and team selection, authorize Face ID, and import the strict version-2 pairing record with VPN on and Wi-Fi connected. Confirm actual installed list and actual provisioning expiry. Declining/cancelling authentication must not sign/install or report success.
- Install a small permitted test app, then its second version with the same original bundle ID. Confirm exactly one installed app remains, updated version is visible, source mapping stays stable and quota messaging is accurate. Do not remove unrelated apps to make space without Tin's decision.

Run 2 — refresh and persistence:
- Refresh the test app and then the installer. Verify real profile expiry advances, the same app identities remain, and closing/relaunching the installer can unlock the saved account and reuse the pairing. Confirm its Keychain survives self-update.
- Allow local alerts from the explicit Settings button, review the Shortcuts guide, cancel an operation and confirm no false Done/stuck spinner. Background scheduling can be inspected through app state/Xcode during this authorized run, but it is not evidence of a guaranteed daily run. Keep before/after expiry timestamps and boolean outcomes; no raw credentials/logs are needed.

If a run fails, fix the exact cause and perform only its necessary follow-up. These two runs are the target, not permission to declare untested hardware behavior complete. Apple free-account limits (3 apps including installer, 10 App IDs/week including relevant extensions) and server/OS policy still apply.

## Evidence and cleanup

`private/diagnosis.json`, `signature-evidence.json`, and `device-evidence.json` hold minimal local evidence. The first includes only Xcode/SDK, actual model/OS and scope; signature data includes expiry and verified booleans, not raw identities/profiles. Review an intentionally sanitized subset before moving any evidence into tracked VERIFICATION.md. Launch command success proves a process launch, not that signing, refresh, Face ID or Duo behavior passed.

Do not commit or upload private runtime files, Xcode DerivedData, signed products, pairing exports, Apple identifiers, profiles or keys. OS-managed Xcode account Keychain, provisioning stores, usbmuxd trust and App Store installations are outside the project folder because those tools require them; that unavoidable local scope must be disclosed/approved, and they are not extra project copies. Keep only the newest local working product per variant and one current private generated project; never delete tools needed to rebuild. The recorded local-use approval and user-reported physical install are separate from the remaining on-phone connection, signing/update/refresh and recovery evidence; these source files do not establish those results.

## Cloud validation of this native project generator

`validate-cloud-project.py` defaults to a dry-run and refuses execution outside the selected macOS GitHub Actions job. With `--execute`, the hosted workflow provides the actual arm64 iOS archive and `cloud-device-library-manifest.json`. The check requires matching commit and production-source fingerprint, an actual iPhoneOS SDK 27.1+, and a successful unsigned build of the generated shared scheme. It verifies genuine Mach-O SDK/platform marks, the rewritten stable identity/background identifier, scene metadata and absence of a provisioning profile. `CODE_SIGNING_ALLOWED=NO` and `CODE_SIGNING_REQUIRED=NO` remain explicit; no provisioning update/registration flag or device command is used. Its report/build log contain only account-free cloud fixture data. The owned project/DerivedData are deleted afterward.

This actual native project build is separate from physical signing/Keychain/pairing/device evidence. A passing cloud build does not expand the recorded Mac/network approval or complete the remaining physical workflow.

## Minimal native kit and one-click launcher

The preferred Mac transfer is `AppInstaller-native-bootstrap-kit.zip` plus its external exact size/SHA-256 receipt. It contains native Objective-C source, C headers, icons/plist, licensing/notice resources, the cloud Rust static library and its manifest, a strict per-file `BootstrapKitManifest.json`, and `Run-App-Installer-Setup.command`. The new remote-pairing kit must additionally contain the source-bound universal Mac helper, its receipt, matching source and complete target notices; do not infer these are present in an older kit. No Unit Creator source, Git history, Rust/Cargo installation or duplicate IPA executable is needed. The complete source/relink tar remains available in the companion `app-installer-cloud-ui-latest` cloud artifact at `candidates/AppInstaller-corresponding-source.tar.xz`, with its exact hash/size referenced by the kit. Publish the small kit as a separate latest-only artifact so downloading it does not force the 78+ MB complete source download; maintain access to that companion source for recipients. It is not replaced with a private-repo URL.

The archive has one destination prefix, `AI-Workspace/claude-chatg/`. Within Tin’s existing transfer/setup approval, inspect/reconcile the confirmed nested Mac project folder before extraction; never overwrite unrelated or locally edited work blindly. Existing Unit Creator content is not part of the kit and is preserved. The kit's runtime validator hashes every payload file and refuses extra native compilation inputs, missing files or changed content. An existing Git checkout must still ignore/untrack private runtime data. A kit without Git validates the same explicit `/private/` exclusion and protected directory policy instead of requiring a full checkout or Cargo. The library's commit/fingerprint/source-archive hash must match the kit and notice resources. No profile/key/pairing record is accepted as an ordinary kit payload merely because a private path is allowed.

Helper-only fixes may be packaged after the compiled app's commit without rebuilding unchanged app/Rust inputs. The cloud kit builder requires the exact same complete production fingerprint and proves the compiled commit is an ancestor of the current clean tool commit using local Git history; shallow/missing/unrelated history stops packaging without fetching. `source_commit` remains the compiled library/candidate commit; the required `bootstrap_tool_commit` identifies the newer tool revision in the kit, receipt and native signed app's BuildMetadata. Complete updated bootstrap-tool source is inside the kit with exact per-file hashes. The separate corresponding-source archive remains the original matching compiled app/Rust source closure. This exception applies only to minimal kit packaging, not IPA validation or compiled artifact source attribution.

The `.command` launcher shows a plan by default. Its **Run approved setup** button is an explicit execution choice, not inferred permission and not a substitute for the prior approval recorded in STATUS.md. Full setup chooses a local connected iPhone and a development team with an existing signing key. Pairing-only selects the phone but does not discover signing identities or choose a team. Only public certificate subjects are inspected in memory to read the actual Team ID from OU; private keys are not exported and account/identity labels are not printed to chat/repo logs. The wizard now checks the selected full Xcode, genuine iPhoneOS SDK27.1+ and required local tools before querying the phone or inspecting signing identities. It never installs Xcode or accepts a license automatically. Missing/CLI-only/old SDK errors give the exact existing-Xcode selection action. If an existing signing identity is absent, it stops and identifies the needed Xcode Settings → Accounts action; Tin’s latest authorization reserves Apple-credential changes and significantly larger Xcode downloads for separate approval. Do not create/replace certificates or request passwords in chat. Existing installer bundle identity is kept; no other app is removed. The user still handles normal Trust/Developer Mode and on-phone Apple/biometric prompts. Initial trusted-USB remote pairing does not require a separate displayed-code dialog.

The confirmed Duo allowlist currently contains `iPhone19,4`. `--variant duo` refuses another or unknown model even with SDK27.1 installed. Future hardware needs an explicit verified allowlist update. Neither a forced window size nor a model label invented by a fixture is physical Duo evidence.

## Properly signed private IPA output

After native Xcode signing and actual profile/entitlement/Mach-O verification, the `build` step exports `app-installer/device/private/builds/AppInstaller-<variant>-signed.ipa`. It packages the verified `.app` beneath `Payload/AppInstaller.app/`, preserves executable permissions, CRC-checks the ZIP and checks every payload file's SHA-256 against the signed bundle before replacing the sole latest IPA for that variant. `export --execute` can repeat that packaging from an already verified signed app without rebuilding or installing. A redacted sibling JSON receipt records exact IPA bytes/hash and whether packaging checks passed. The original profile and signature bytes remain intact in the private IPA; no private key is exported. That IPA contains the provisioning profile/device information needed by iOS, so it must not be committed or uploaded to GitHub/cloud artifacts. Physical install/launch/account/refresh evidence remains separate; packaging does not mark hardware tests complete or make a candidate final by itself.

No new Xcode/SDK installation is automatic. Diagnosis uses the already selected installed SDK. If it is incompatible, stop, explain the exact required update/transfer and obtain any additional resource approval before downloading an SDK or changing the Mac's toolchain.

## Install/launch receipt integrity

The canonical org.tin.appinstaller ID and its project-owned child IDs are accepted for stable updates. Verified signed receipts include the checked source commit, production fingerprint and bootstrap-tool commit. Before a USB install command, a sanitized durable in-progress receipt replaces any older success. Failure leaves failed_or_unknown; a crash leaves in_progress, neither is treated as success. Launch requires a successful exact-device/build/source binding and preserves the install outcome while separately recording launch success/failure. The opaque binding contains no raw phone/team/bundle identifier. These receipts remain under ignored private/ and do not prove in-app account/signing/update/refresh behavior.
