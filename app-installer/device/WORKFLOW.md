# Operator workflow for authorized first install

These tools are prepared in the cloud. **No physical-device step has run.** Read the root README first. Obtain and record Tin's explicit approval for the exact Mac, selected internet connection and device action before executing on his Mac. A usable remote/local execution connection is also required; the cloud agent currently has no USB access or configured Mac signing identity. Source approval alone is not the remaining technical issue: actual Apple/device trust and physical validation are.

`device-workflow.py` always prints a plan unless `--execute` is present. Dry-run invokes no subprocess, network request, device query or filesystem write. The switch records operator intent; it is not evidence of Tin's approval. The assistant must obtain approval first and record it in STATUS.md. All commands below are examples for the operator after that approval; do not ask Tin to paste account secrets or device identifiers into chat.

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

On the approved Mac, the checkout remains `~/AI-Workspace/claude-chatg`. Download the one cloud archive, its manifest, and the same-source unsigned candidate IPA to `app-installer/device/private/input/` in that checkout. That folder is ignored and protected by the parent directory's 0700 permissions. No second repo is created. The library and review IPA source commit/fingerprint must match, and the review IPA must have zero notice gaps. The exact transfer size and the optional pairing-tool download (57,690,695 bytes) belong in the local-use approval description. Actual Apple provisioning traffic/App Store size cannot be predicted exactly; state those purposes instead of inventing a byte count.

## Operator commands after approval

Use the **same** team and stable bundle ID for every step. Values below are local operator placeholders, not real credentials/identifiers. Select the actual phone in Xcode → Window → Devices and Simulators; keep its identifier local. The team ID is chosen from the account already signed in within Xcode.

```bash
cd ~/AI-Workspace/claude-chatg
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

## Pairing and VPN — only after approved local setup

Official pairing tool: idevice_pair v1.1.0, hash/size recorded in `downloads/idevice-pair-macos/SOURCE.md`. The helper can fetch the exact DMG after explicit approval:

```bash
python3 app-installer/device/device-workflow.py fetch-pairing-tool --execute
```

Open the verified distribution locally. Its USB flow: unlock phone → Trust → select phone → **Lockdown** → Load/Create → Validate. Lockdown reuses OS usbmuxd trust when available. Do not choose Remote/RPPairing; the current engine expects a Lockdown PairingFile. idevice_pair's direct known-app locations do not yet include this custom app, so do not pretend it can already write directly into our Keychain. An upstream direct-app integration would need implementation and verification.

For the existing supported path, save exactly one export to `app-installer/device/private/pairing.mobiledevicepairing`. It contains private keys in a normal export file: directory permissions/temporary ignored storage are protections, **not** a claim that the export is Keychain-only. Use only a user-approved direct local transfer such as AirDrop; do not upload through chat, GitHub, cloud artifacts, shared drives or email. App Installer imports it to Keychain and stores one authenticated encrypted backup. Confirm a real on-device connection succeeds before deleting the source export:

```bash
python3 app-installer/device/device-workflow.py remove-pairing-export --execute
```

Normal unlinking removes the working copy; it does not promise forensic erasure on APFS/SSD or OS-managed trust stores. Remove any extra transfer copy from the phone's Downloads after confirmed import; keep the app's protected primary/encrypted backup. Do not delete OS usbmuxd pairing stores or certificate/Keychain records needed by Xcode.

LocalDevVPN official App Store link: https://apps.apple.com/us/app/localdevvpn/id6755608044. Verified upstream defaults are interface configured-address/32, peer configured-address/32; the engine's current device host is configured-address. Install/allow/configure it on the actual phone within approved use. The app keeps traffic on the local tunnel; Apple sign-in/provisioning still needs internet. A privacy reset can invalidate pairing and needs a new approved physical pairing step.

## Two functional runs on the phone, not repeated blind tests

Run 1 — initial setup and update:
- Launch this actual signed app; verify empty login fields, Settings own expiry, correct responsive bounds and no occluded controls. On Duo, inspect outer/inner orientations and one fold/unfold using real reserved regions.
- Sign in on the phone only, complete 2FA and team selection, authorize Face ID, and import Lockdown pairing with VPN on. Confirm actual installed list and actual provisioning expiry. Declining/cancelling authentication must not sign/install or report success.
- Install a small permitted test app, then its second version with the same original bundle ID. Confirm exactly one installed app remains, updated version is visible, source mapping stays stable and quota messaging is accurate. Do not remove unrelated apps to make space without Tin's decision.

Run 2 — refresh and persistence:
- Refresh the test app and then the installer. Verify real profile expiry advances, the same app identities remain, and closing/relaunching the installer can unlock the saved account and reuse the pairing. Confirm its Keychain survives self-update.
- Allow local alerts from the explicit Settings button, review the Shortcuts guide, cancel an operation and confirm no false Done/stuck spinner. Background scheduling can be inspected through app state/Xcode during this authorized run, but it is not evidence of a guaranteed daily run. Keep before/after expiry timestamps and boolean outcomes; no raw credentials/logs are needed.

If a run fails, fix the exact cause and perform only its necessary follow-up. These two runs are the target, not permission to declare untested hardware behavior complete. Apple free-account limits (3 apps including installer, 10 App IDs/week including relevant extensions) and server/OS policy still apply.

## Evidence and cleanup

`private/diagnosis.json`, `signature-evidence.json`, and `device-evidence.json` hold minimal local evidence. The first includes only Xcode/SDK, actual model/OS and scope; signature data includes expiry and verified booleans, not raw identities/profiles. Review an intentionally sanitized subset before moving any evidence into tracked VERIFICATION.md. Launch command success proves a process launch, not that signing, refresh, Face ID or Duo behavior passed.

Do not commit or upload private runtime files, Xcode DerivedData, signed products, pairing exports, Apple identifiers, profiles or keys. OS-managed Xcode account Keychain, provisioning stores, usbmuxd trust and App Store installations are outside the project folder because those tools require them; that unavoidable local scope must be disclosed/approved, and they are not extra project copies. Keep only the newest local working product per variant and one current private generated project; never delete tools needed to rebuild. No local-use approval, physical install or successful account workflow is claimed by these source files.

## Cloud validation of this native project generator

`validate-cloud-project.py` defaults to a dry-run and refuses execution outside the selected macOS GitHub Actions job. With `--execute`, the hosted workflow provides the actual arm64 iOS archive and `cloud-device-library-manifest.json`. The check requires matching commit and production-source fingerprint, an actual iPhoneOS SDK 27.1+, and a successful unsigned build of the generated shared scheme. It verifies genuine Mach-O SDK/platform marks, the rewritten stable identity/background identifier, scene metadata and absence of a provisioning profile. `CODE_SIGNING_ALLOWED=NO` and `CODE_SIGNING_REQUIRED=NO` remain explicit; no provisioning update/registration flag or device command is used. Its report/build log contain only account-free cloud fixture data. The owned project/DerivedData are deleted afterward.

This actual native project build is separate from physical signing/Keychain/pairing/device evidence. A passing cloud build does not approve Mac/network use or complete the first installation.

## Minimal native kit and one-click launcher

The preferred Mac transfer is `AppInstaller-native-bootstrap-kit.zip` plus its external exact size/SHA-256 receipt. It contains native Objective-C source, C headers, icons/plist, licensing/notice resources, the cloud Rust static library and its manifest, a strict per-file `BootstrapKitManifest.json`, and `Run-App-Installer-Setup.command`. No Unit Creator source, Git history, Rust/Cargo installation or duplicate IPA executable is needed. The complete source/relink tar remains available in the companion `app-installer-cloud-ui-latest` cloud artifact at `candidates/AppInstaller-corresponding-source.tar.xz`, with its exact hash/size referenced by the kit. Publish the small kit as a separate latest-only artifact so downloading it does not force the 78+ MB complete source download; maintain access to that companion source for recipients. It is not replaced with a private-repo URL.

The archive has one destination prefix, `AI-Workspace/claude-chatg/`. After Tin approves the transfer/setup, inspect/reconcile that same project folder before extraction; never overwrite unrelated or locally edited work blindly. Existing Unit Creator content is not part of the kit and is preserved. The kit's runtime validator hashes every payload file and refuses extra native compilation inputs, missing files or changed content. An existing Git checkout must still ignore/untrack private runtime data. A kit without Git validates the same explicit `/private/` exclusion and protected directory policy instead of requiring a full checkout or Cargo. The library's commit/fingerprint/source-archive hash must match the kit and notice resources. No profile/key/pairing record is accepted as an ordinary kit payload merely because a private path is allowed.

Helper-only fixes may be packaged after the compiled app's commit without rebuilding unchanged app/Rust inputs. The cloud kit builder requires the exact same complete production fingerprint and proves the compiled commit is an ancestor of the current clean tool commit using local Git history; shallow/missing/unrelated history stops packaging without fetching. `source_commit` remains the compiled library/candidate commit; the required `bootstrap_tool_commit` identifies the newer tool revision in the kit, receipt and native signed app's BuildMetadata. Complete updated bootstrap-tool source is inside the kit with exact per-file hashes. The separate corresponding-source archive remains the original matching compiled app/Rust source closure. This exception applies only to minimal kit packaging, not IPA validation or compiled artifact source attribution.

The `.command` launcher shows a plan by default. Its **Run approved setup** button is an explicit execution choice, not inferred permission and not a substitute for the prior approval recorded in STATUS.md. The wizard chooses a local connected iPhone and a development team with an existing signing key. Only public certificate subjects are inspected in memory to read the actual Team ID from OU; private keys are not exported and account/identity labels are not printed to chat/repo logs. The wizard now checks the selected full Xcode, genuine iPhoneOS SDK27.1+ and required local tools before querying the phone or inspecting signing identities. It never installs Xcode or accepts a license automatically. Missing/CLI-only/old SDK errors give the exact existing-Xcode selection action. If an existing signing identity is absent, it stops and identifies the needed Xcode Settings → Accounts action; Tin’s latest authorization reserves Apple-credential changes and significantly larger Xcode downloads for separate approval. Do not create/replace certificates or request passwords in chat. Existing installer bundle identity is kept; no other app is removed. The user still handles Trust/Developer Mode and on-phone account/pairing dialogs.

The confirmed Duo allowlist currently contains `iPhone19,4`. `--variant duo` refuses another or unknown model even with SDK27.1 installed. Future hardware needs an explicit verified allowlist update. Neither a forced window size nor a model label invented by a fixture is physical Duo evidence.

## Properly signed private IPA output

After native Xcode signing and actual profile/entitlement/Mach-O verification, the `build` step exports `app-installer/device/private/builds/AppInstaller-<variant>-signed.ipa`. It packages the verified `.app` beneath `Payload/AppInstaller.app/`, preserves executable permissions, CRC-checks the ZIP and checks every payload file's SHA-256 against the signed bundle before replacing the sole latest IPA for that variant. `export --execute` can repeat that packaging from an already verified signed app without rebuilding or installing. A redacted sibling JSON receipt records exact IPA bytes/hash and whether packaging checks passed. The original profile and signature bytes remain intact in the private IPA; no private key is exported. That IPA contains the provisioning profile/device information needed by iOS, so it must not be committed or uploaded to GitHub/cloud artifacts. Physical install/launch/account/refresh evidence remains separate; packaging does not mark hardware tests complete or make a candidate final by itself.

No new Xcode/SDK installation is automatic. Diagnosis uses the already selected installed SDK. If it is incompatible, stop, explain the exact required update/transfer and obtain any additional resource approval before downloading an SDK or changing the Mac's toolchain.

## Install/launch receipt integrity

The canonical org.tin.appinstaller ID and its project-owned child IDs are accepted for stable updates. Verified signed receipts include the checked source commit, production fingerprint and bootstrap-tool commit. Before a USB install command, a sanitized durable in-progress receipt replaces any older success. Failure leaves failed_or_unknown; a crash leaves in_progress, neither is treated as success. Launch requires a successful exact-device/build/source binding and preserves the install outcome while separately recording launch success/failure. The opaque binding contains no raw phone/team/bundle identifier. These receipts remain under ignored private/ and do not prove in-app account/signing/update/refresh behavior.
