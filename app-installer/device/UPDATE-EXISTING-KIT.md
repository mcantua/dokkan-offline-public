# Update Tin’s existing reviewed setup kit

**Retired for this continuation:** the hashes/commands below describe a historical private-repository kit. The private backup is frozen. No corrected public-repository kit exists yet; do not run these commands or change a manifest to bypass its source checks. See [PUBLIC-CONTINUATION.md](PUBLIC-CONTINUATION.md).

For the current7059c85 kit only. This preserves the existing project folder and unlisted private build/signing outputs. It does not sign, install, access Keychain or send an Apple request. Existing local-use approval covers this update; new Apple-account changes/large Xcode remain separate decisions.

After downloading the corrected native kit ZIP from the existing private draft, paste only this block into a new Terminal window. The file chooser avoids assumptions about the browser’s download filename. Its exact size/SHA is verified before extraction; macOS ditto merges the known archive into the existing folder. The known nested path is the path Tin actually used. Do not substitute a different root without reviewing it.

```bash
/usr/bin/python3 - <<'UPDATE_KIT'
import hashlib, json, pathlib, subprocess
root = pathlib.Path.home() / 'AI-Workspace/AI-Workspace/claude-chatg'
if not (root / 'BootstrapKitManifest.json').is_file():
    raise SystemExit('Existing setup folder not found; no update performed.')
chosen = subprocess.check_output(['/usr/bin/osascript', '-e', 'POSIX path of (choose file with prompt "Choose the NEW AppInstaller native setup kit ZIP")'], text=True).strip()
kit = pathlib.Path(chosen)
if kit.stat().st_size != 35149949 or hashlib.sha256(kit.read_bytes()).hexdigest() != 'e814dd588ff46be402d0372e2f66ce2154f5e3661a3ded93224bb0f1bfe41bf6':
    raise SystemExit('This is not the corrected kit. No project files were changed.')
subprocess.run(['/usr/bin/ditto', '-x', '-k', str(kit), str(root.parent.parent)], check=True)
(root / 'app-installer/device/private/input/libapp_installer_core.a').touch()
manifest = json.loads((root / 'BootstrapKitManifest.json').read_text())
if manifest.get('bootstrap_tool_commit') != '7059c85ad55645ef57db9f8de287e6a66b8c122e':
    raise SystemExit('Updated setup identity did not match. Stop before running setup.')
print('Corrected kit merged; existing private outputs preserved. Ready to rerun setup on the physical phone.')
UPDATE_KIT
```

The library touch changes only modification time, not bytes. It ensures Xcode relinks the replacement static library despite deterministic ZIP timestamps. The normal helper then verifies all managed payload hashes before signing. Choose the same physical Tin phone and existing installed identity. Do not uninstall the app or remove its phone data. Observe normal macOS prompts; no quarantine removal/security disabling.

If the copy is interrupted, do not run a mixed kit: repeat this exact verified extraction, then let bootstrap-kit integrity checks pass. No rollback copy is created. Remove obsolete downloaded archives after successful update; preserve the sole matching source companion in the private repository. Real sign-in/2FA/refresh/display acceptance is still separate.
