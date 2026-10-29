# Continue setup on the approved Mac

Tin has resumed manual setup and has already signed/exported/installed App Installer and opened it on the iPhone. The app later reached Signed in and saved the old pairing import. Its on-phone connection and full in-app install/update/refresh workflow are still unverified. His existing approval for routine MacBook/USB Duo/network/kit/pairing/trusted dependencies persists. Significantly larger Xcode installation and Apple-credential changes still need separate approval.

The new strict version-2 trusted-USB pairing helper is being prepared in the cloud. **Do not treat it as delivered until the matching new kit and exact receipt are verified.** An older kit or standard idevice_pair Remote export is not a substitute.

## Use the existing folder and one update

1. Once the assistant verifies the new kit’s actual size/hash and delivery, obtain **AppInstaller-native-bootstrap-kit.zip** from the existing private draft at https://github.com/mcantua/claude-chatg/releases . Use **UPDATE-EXISTING-KIT.md** to merge it into the confirmed existing `~/AI-Workspace/AI-Workspace/claude-chatg` folder. Preserve its private files, old Lockdown pairing export, signed products and phone app data. Do not download a full repo, install Rust on the Mac, create another project copy or fetch the old idevice_pair DMG.
2. Open **app-installer/device/Run-App-Installer-Setup.command** from that folder. It shows the plan by default. Choose **Run approved setup** when ready to use the previously approved resources. Preserve normal macOS security checks; do not remove quarantine or disable Gatekeeper. If macOS blocks it, inspect the actual prompt and use a supported local response.
3. Keep the iPhone connected/unlocked. Respond locally to normal Trust/Developer Mode prompts. Full setup verifies the kit, actual installed Xcode/SDK, physical phone and existing signing identity, then performs one same-identity app update. If a large Xcode download or Apple-account/certificate change is required, stop for the separate approval. Passwords/codes stay in Apple UI or on the phone.
4. If install succeeds but automatic launch fails, open App Installer manually. Do not repeat installation just for that launch failure. The wizard can continue trusted USB pairing; if pairing needs resuming independently, use the command below.

## Pairing only after the app update

```bash
/usr/bin/python3 "$HOME/AI-Workspace/AI-Workspace/claude-chatg/app-installer/device/setup-wizard.py" --execute --pairing-only
```

This checks the same kit/helper and local USB phone, but skips Apple signing-identity discovery/team selection and does not rebuild, sign or install an app. It verifies the existing trusted USB session and creates or validates the strict version-2 peer-pinned record privately. A valid existing record is reused after pinned validation; failure does not rotate keys or overwrite the file. No Apple credentials or separate six-digit code dialog are requested.

The wizard opens `app-installer/device/private/secure-rp/`. AirDrop its `pairing.mobiledevicepairing` directly to this same iPhone and choose **Replace pairing file** in App Installer. Keep the old Lockdown export and the new private Mac copy until secure import and the on-phone connection succeed. Never upload pairing files, signing material or raw account/device logs.

Keep LocalDevVPN connected and the iPhone on Wi-Fi, using default interface `configured-address/32` and peer `configured-address/32`. Check the app’s actual connection; Mac LAN validation and a VPN Connected label alone are not proof. Then follow **USER-ACTIONS.md** for the remaining actual installed-list, expiry, in-app install/update/refresh, protected persistence/recovery and display/fold checks.

No Mac command was executed to prepare these instructions. If setup fails, share only its short reviewed error message, never a private export or raw signing/device output. Direct Mac control is not required for manually running the helper, and no unobserved remote-control button needs to be found.
