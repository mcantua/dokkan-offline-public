## Summary
The pairing diagnostic never reached the phone: the former nested setup-wizard.py path was absent on Tin’s Mac. Corrected the operator recipe to choose the actual existing setup command and verify exact5855 script hashes before import.

## Details
PAIRING-ONLY-DIAGNOSIS.md no longer assumes a fixed home path. Choose Run-App-Installer-Setup.command; both adjacent loaded scripts must match the released kit. Integrity/signature/device checks remain in the original unchanged wizard. UPDATE-EXISTING-KIT.md can similarly select the existing project when its former path is gone. Two grouped cloud-only checks passed using copied public kit scripts, fake chooser and temporary fixtures: flat/nested roots, source pin tampering, missing wizard and cancellation. No actual wizard import, Mac/USB action, download or app build/install performed. Current app remains5855 and installed; USB pairing failure cause remains unknown. No credentials/private record read or stored.

## Questions
none

## Needs Tin?
Yes: reopen the corrected pairing-only instructions, paste the entire block into a new Mac Terminal window, select the setup command in the folder they actually used, then share only the three PAIRING_ codes. Do not ask for permission again or request private pairing contents. No reinstall is needed.
