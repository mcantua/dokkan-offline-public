#!/usr/bin/env bash
# Build unsigned review artifacts only. Never contacts Apple or installs on a device.
set -euo pipefail
source "$(dirname "$0")/env.sh"
variant="${1:-iphone}"
case "$variant" in iphone) sdk_mark=16.5;; duo) sdk_mark=27.1;; *) echo 'Use iphone or duo' >&2; exit 2;; esac
[[ -x "$AI_CLANG" && -d "$IOS_SDK_PATH" && -x "$AR_aarch64_apple_ios" ]] || {
  echo 'Missing Linux clang, llvm-ar or iOS SDK; run setup-linux.py or see build-notes.md.' >&2; exit 1;
}
work="$AI_ROOT/app-installer/build/work/$variant"
# A same-variant build owns one atomic lock directory, removed with its staging area.
mkdir -p "$AI_ROOT/app-installer/build/work" "$AI_BUILD_OUTPUT_DIR"
lock="$AI_ROOT/app-installer/build/work/$variant.lock"
mkdir "$lock" 2>/dev/null || { echo "Another $variant build or an interrupted lock exists" >&2; exit 1; }
trap 'python3 "$AI_ROOT/app-installer/build/cleanup-work.py" "$variant"' EXIT
python3 "$AI_ROOT/app-installer/build/cleanup-work.py" "$variant" --stage-only
mkdir -p "$work/Payload/AppInstaller.app"
app="$work/Payload/AppInstaller.app"
"$CARGO_HOME/bin/cargo" build --manifest-path "$AI_ROOT/app-installer/core/Cargo.toml" --locked --release --target aarch64-apple-ios
python3 - "$AI_ROOT" "$app" "$sdk_mark" "$variant" <<'PY'
import json,os,pathlib,plistlib,shutil,subprocess,sys
root,app,mark,variant=sys.argv[1:]
root,app=pathlib.Path(root),pathlib.Path(app)
p=plistlib.loads((root/'app-installer/ios/Info.plist').read_bytes())
p.update(DTPlatformName='iphoneos',DTSDKName='iphoneos'+mark,DTPlatformVersion=mark)
# Both variants preserve one stable bundle ID; no second app identity is created.
p['CFBundleDisplayName']='Installer Preview' + (' Duo' if variant=='duo' else '')
(app/'Info.plist').write_bytes(plistlib.dumps(p))
(app/'LICENSE.txt').write_bytes((root/'app-installer/LICENSE').read_bytes())
for size,scale in [(120,2),(180,3)]:
    source=root/f'app-installer/ios/assets/AppIcon{size}.png'
    if not source.is_file(): raise FileNotFoundError('Missing original app icon: '+str(source))
    shutil.copy2(source,app/f'AppIcon60x60@{scale}x.png')
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
dirty=bool(subprocess.check_output(['git','status','--porcelain','--untracked-files=normal','--','app-installer','downloads','.gitignore',':!app-installer/build/work'],cwd=root))
metadata={'source_commit':head,'source_has_uncommitted_changes':dirty,'variant':variant,
          'unsigned':True,'compilation_sdk':'16.5','requested_sdk_mark':mark,
          'duo_device_layout_verified':False,'phone_install_attempted':False,
          'toolchain_downloads_prefix':str(pathlib.Path(os.environ['AI_DOWNLOADS_ROOT']).resolve().relative_to(root)),
          'cargo_target_prefix':str(pathlib.Path(os.environ['CARGO_TARGET_DIR']).resolve().relative_to(root)),
          'rustc_version':subprocess.check_output([str(pathlib.Path(os.environ['CARGO_HOME'])/'bin/rustc'),'--version'],text=True).strip(),
          'clang_version':subprocess.check_output([os.environ['AI_CLANG'],'--version'],text=True).splitlines()[0],
          'source_tree_sha256':subprocess.check_output([sys.executable,str(root/'app-installer/build/source-fingerprint.py')],cwd=root,text=True).strip()}
(app/'BuildMetadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
PY
python3 "$AI_ROOT/app-installer/build/third-party-notices.py" "$app/ThirdPartyNotices.txt" "$app/ThirdPartyNoticeReport.json"
native=("$AI_ROOT"/app-installer/ios/*.m)
[[ -f "${native[0]}" ]] || { echo 'No native source files found' >&2; exit 1; }
"$AI_CLANG" -target arm64-apple-ios16.4 -isysroot "$IOS_SDK_PATH" -fobjc-arc -fmodules \
  -fmodules-cache-path="$work/modules" -fuse-ld=lld -B"$AI_LLVM/bin" \
  -Werror=return-type -Werror=implicit-function-declaration \
  "${native[@]}" "$CARGO_TARGET_DIR/aarch64-apple-ios/release/libapp_installer_core.a" \
  -framework QuartzCore -framework UIKit -framework Foundation -framework Security -framework LocalAuthentication \
  -framework UniformTypeIdentifiers -framework BackgroundTasks -framework UserNotifications \
  -framework CoreFoundation -framework SystemConfiguration -liconv -lSystem -lobjc -lz \
  -Wl,-platform_version,ios,16.4,"$sdk_mark" -o "$app/AppInstaller"
chmod 755 "$app/AppInstaller"
python3 - "$AI_ROOT" "$app" <<'PYVERIFY'
import json,pathlib,subprocess,sys
root,app=map(pathlib.Path,sys.argv[1:])
expected=json.loads((app/'BuildMetadata.json').read_text())['source_tree_sha256']
actual=subprocess.check_output([sys.executable,str(root/'app-installer/build/source-fingerprint.py')],cwd=root,text=True).strip()
if actual != expected: raise RuntimeError('Build source changed during compilation; refusing to package mismatched artifact')
PYVERIFY
staged="$work/AppInstaller-$variant-preview.ipa"
python3 - "$work" "$staged" <<'PY'
import pathlib,sys,zipfile
work,out=map(pathlib.Path,sys.argv[1:])
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted((work/'Payload').rglob('*')):
  if p.is_file(): z.write(p,p.relative_to(work))
PY
# Gate staging before replacing the current working artifact. Failure preserves the prior one.
python3 "$AI_ROOT/app-installer/build/check-artifact.py" "$staged" "$variant" --source-root "$AI_ROOT"
output="$AI_BUILD_OUTPUT_DIR/AppInstaller-$variant-preview.ipa"
mv -f "$staged" "$output"
printf 'Unsigned review artifact built: %s\n' "$output"
