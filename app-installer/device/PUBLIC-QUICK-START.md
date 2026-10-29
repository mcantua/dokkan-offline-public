# App Installer: public kit quick start

Use only the reviewed public delivery from **mcantua/dokkan-offline-public**, on branch `chatgpt/app-installer-pairing-repair`. The review draft is named **app-installer-public-review**. A draft and a successful cloud build are not proof that the app works on your phone.

**Download gate:** the current kit's actual download link, exact byte count, SHA-256 and source revision must first be provided from the reviewed public delivery receipt. Those values are not available in this guide yet. Do not substitute an older kit, guess a hash, use a private-repository link or download anything before that review is complete.

## Before each Mac or internet step

The assistant must describe the next task **before it starts**: which Mac/phone resources it uses, which connection it uses, what is transferred, and the verified size or an explicit statement that the amount is unknown. This applies to Wi-Fi and cellular/hotspot use too.

Routine setup/update/pairing approval already granted by Tin remains in effect. Advance notice is still required; it does not mean asking for the same approval again. A change to Apple credentials/certificates or a substantially larger Xcode installation keeps its separate approval boundary. If one is required, stop before making that change.

| Next task | What the advance notice must say |
|---|---|
| Download the native kit | Exact public asset, verified byte count and SHA-256; selected internet connection. Download only this small kit, not the full repository or corresponding-source archive. |
| Check and overlay the kit | Mac filesystem use; no planned download or Apple request. Preserve unlisted local private files and the installed app. |
| Prepare/sign/update the app, if needed | Mac/Xcode/USB use. Existing development identity/team/bundle must be retained. Apple registration, certificate/profile and provisioning traffic may be needed; its amount is unknown. |
| Pair only | Mac and USB use, creating a private export locally. This helper action does not request an Apple-account change, app build/install or dependency download. Background OS traffic cannot be promised to be zero. |
| Transfer/import the private export | Approved direct local method; private size is unknown until creation and stays local. No chat, GitHub, email or cloud upload. |
| App sign-in, connection check or refresh | Phone/VPN and any reviewed internet services needed by that action. Internet usage is not a known fixed amount. |

Do not promise that macOS, Xcode or iOS will make no unrelated background requests. Report a genuine unknown instead of calling a step “zero data.”

## 1. Get the smallest verified kit

After the advance notice and actual delivery pins are available, download **AppInstaller-native-bootstrap-kit.zip** once from the named public review draft. Check its exact size and SHA-256 before opening or copying it. A renamed browser download is acceptable only if its bytes match those pins.

The cloud supplies the matching Rust static library and trusted USB helper already built. Do not clone/download the whole repository, install Rust/Cargo on the Mac, compile Rust source there or fetch the complete source archive just to perform setup. The corresponding-source archive remains available separately for source/relink obligations.

Follow [Update the existing kit](UPDATE-EXISTING-KIT.md). The concrete local tool is **update-public-kit.py**. Its default is a plan without file inspection or changes; actual execution requires the reviewed ZIP size/hash/source pins. The delivery instruction can enable its file/folder chooser with `--execute --choose`; do not run it until the assistant supplies the real pins and binds the updater itself to the verified download. It must target **AI-Workspace/dokkan-offline-public**. Do not browse, read, merge, rename or modify the frozen old backup. If the new public folder does not exist, create that new folder; do not import files from the backup.

## 2. Decide whether an app update is needed

The verified delivery must identify its source revision and which installed app it supports. Strict pinned version-2 import cannot be assumed to work in an older installed App Installer. Check the installed source/version using the app's local information and the delivery instructions.

If a compatible update is needed, use the verified kit's **Run-App-Installer-Setup.command** and review its plan first. The native setup uses existing Xcode plus the supplied cloud Rust library/helper. It may prepare/sign the native app, but it does not need a Mac Rust build.

Select the physical phone and **the same existing development team and App Installer bundle identity**. This is an update in place. Do not uninstall the app, clear its data, reset privacy/trust, create a second installer identity or remove Keychain entries to fix pairing. If the existing identity cannot be confirmed, stop for review. Keep local signing products and ignored private files already in the new public folder.

If the helper reports a missing local prerequisite, stop at that report. Any required trusted dependency download needs its own advance transfer notice; do not start an unannounced toolchain/Xcode download or substitute an old kit.

Apple passwords and verification codes belong only in Apple's local UI or the app/phone where requested. Do not paste them into chat. Any new Apple-account/certificate change requires its separate approval first.

An install reported as successful still needs manual opening and source/version confirmation. A launch timeout alone is not a reason to reinstall.

## 3. Pair without reinstalling

Once the installed build is confirmed compatible, use the verified kit's **pairing-only** action. Keep the phone unlocked and connected by USB. Follow local Trust/Developer Mode prompts if required; never bypass a trust or signature check.

The supplied launcher supports a `--pairing-only` execution option. Use only the exact source-bound chooser/launcher instruction provided for the verified kit; do not reuse a historical command with a guessed path. Pairing-only must skip Apple-account/team discovery and app preparation, signing, installation and launch.

The helper creates a private **format_version=2** export containing an authenticated peer pin. It opens the new public folder's private export location locally. A successful export is not proof of an on-phone connection. Do not replace it with an unpinned/legacy remote record, edit its fields or upload it for inspection. A failure must remain a failure; never turn off TLS or peer verification.

Transfer the file directly to the same phone through the approved local method. Import or replace pairing in the compatible App Installer. Keep existing private outputs until secure import and a real connection check succeed. Then remove only the now-unneeded temporary transfer copy; do not erase the app's protected primary/backup or create multiple backups.

## 4. Check the actual phone connection

Keep LocalDevVPN configured and connected as described in the verified delivery. If installing/downloading that app is necessary, give the advance internet notice first; its current App Store transfer size must be checked or reported unknown.

In App Installer Settings, enter the numeric local/VPN connection address **locally only**. Do not put the address, device identifier, pairing file or account details into chat or repository files. Keep this host setting separate from the automatically discovered service port.

Choose **Unlock and check connection**. The app must authenticate the saved peer and complete the real device lookup. A file being saved, an advertisement being found or a successful cloud test is not a verified connection. If discovery or verification fails, preserve the current app/data and collect only the fixed safe stage/reason codes the assistant requests. Do not scan ports or weaken verification.

## What still needs real verification

Actual sign-in, signing, installation, same-app update, refresh, restart/session recovery, encrypted-backup recovery and physical Duo display/touch/fold behavior remain separate acceptance steps. Free and paid account modes are separate too. Run only the next necessary check and report what actually happened.

Face ID and iOS background scheduling cannot guarantee unattended daily self-refresh. The app may need opening and unlocking. Once its provisioning expires, recovery may require a computer. The review remains **unsigned / release_ready=false** until the appropriate final acceptance is established.
