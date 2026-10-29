# Installation Check — test fixture only

This tiny owned app provides a small live install/update target. Both IPAs are
unsigned test inputs for App Installer, not final Installer release artifacts.
No account, network, analytics, special entitlement, pairing or SDK/Duo proof is
part of this app. Its deployment target is iOS 16.4; compilation uses the existing
Linux LLVM 19 and genuine iPhoneOS16.5 SDK, with truthful 16.5 Mach-O SDK metadata.

After Tin approves physical setup and App Installer is actually working:

1. Import `InstallationCheck-v1.ipa` in App Installer and complete its genuine
   Apple signing/install workflow. Open **Installation Check v1.0** and tap
   **Add one saved tap** several times. Note the displayed count.
2. Import `InstallationCheck-v2.ipa` through the same workflow, using the same
   Apple team and the same mapped bundle identity. Update the installed app.
3. Open it: **v2.0** must appear, the saved count must remain, and there should
   still be one Installation Check app. Tap again, close/reopen, and confirm
   the count persists. Inspect actual device/app records before recording a pass.

Both sources use `org.tin.installationcheck`; versions/build numbers are 1.0/1
and 2.0/2. App Installer's authorized per-team mapping must preserve one identity.
This check alone cannot verify Installer self-update/Keychain, expiry alerts,
background cancellation, pairing recovery, free/paid account coverage or Duo.
No physical result has been observed or marked passed by creating these files.

Cloud-only rebuild from the repo root (no additional downloads):

```bash
python3 app-installer/device/acceptance-fixture/build.py --execute
```

Default invocation explains the plan. The recipe needs the already configured
`downloads/llvm/` and `downloads/apple-sdk/`; their upstream provenance/license
records remain in each `SOURCE.md`. It does not install SDKs or contact Apple.
One grouped structural check covers the two generated artifacts, followed by one
small ZIP containing both IPAs and all original fixture source/license/recipe.
The JSON receipt gives exact bytes/SHA-256 and explicitly leaves device checks
pending. All transfer/setup/device use still needs Tin's exact prior approval.
