#!/bin/bash
# Builds UnitCreator.ipa on Linux: clang + the public iPhoneOS SDK (from github.com/theos/sdks).
#   ./build-ipa.sh            -> /home/claude/work/out/UnitCreator-<version>.ipa
# Needs: clang/lld 18 (ld64.lld), python3 + Pillow, and web/site-ios (python3 web/build.py).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
W=/home/claude/work
VERSION="${VERSION:-2.30.1}"
BUILD="${BUILD:-88}"
# Compiled and linked with the iPhoneOS16.5 SDK (the public 27.x SDK copies only ship arm64e library stubs, which
# can't link a normal arm64 app). The app is *marked* as built for SDK 27.1 (LC_BUILD_VERSION + Info.plist):
# iPhone Duo only gives the full inner display to apps built for iOS 27.1; older ones are letterboxed.
# The app uses no API newer than iOS 16.4, so the mark only opts it into the new full-screen behaviour.
SDKV="${SDKV:-27.1}"
SDKS=/home/claude/iosbuild/sdks
SDK="$SDKS/iPhoneOS16.5.sdk"
if [ ! -d "$SDK/System/Library/Frameworks/WebKit.framework" ]; then
  mkdir -p "$(dirname "$SDKS")"
  [ -d "$SDKS/.git" ] || git clone -q --filter=blob:none --no-checkout --depth 1 https://github.com/theos/sdks "$SDKS"
  (cd "$SDKS" && git sparse-checkout set --no-cone /iPhoneOS16.5.sdk/ && git checkout -q HEAD)
fi
[ -f "$W/web/site-ios/index.html" ] || { echo "run: python3 $W/web/build.py"; exit 1; }

T="$(mktemp -d)"; APP="$T/Payload/App.app"; mkdir -p "$APP"
clang -target arm64-apple-ios16.4 -isysroot "$SDK" -fobjc-arc -fmodules -O2 -Wall -Werror=objc-method-access \
  -fuse-ld=lld -Wl,-adhoc_codesign -Wl,-dead_strip \
  -framework UIKit -framework WebKit -framework Foundation -framework Security -framework Network -framework UniformTypeIdentifiers -lsqlite3 -Wl,-platform_version,ios,16.4,"$SDKV" \
  "$HERE/main.m" "$HERE/Host.m" "$HERE/Player.m" -o "$APP/App"
cp -R "$W/web/site-ios" "$APP/site"
mkdir -p "$APP/db" && cp "$W"/web/ios-db/*.db "$APP/db/"
printf 'APPL????' > "$APP/PkgInfo"

python3 - "$APP" "$VERSION" "$BUILD" "$SDKV" <<'EOF'
import plistlib, sys, pathlib
from PIL import Image
app, version, build, sdkv = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
src = Image.open("/home/claude/work/ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png").convert("RGB")
for name, px in [("AppIcon60x60@2x.png", 120), ("AppIcon60x60@3x.png", 180),
                 ("AppIcon76x76@2x~ipad.png", 152), ("AppIcon83.5x83.5@2x~ipad.png", 167)]:
    src.resize((px, px), Image.LANCZOS).save(app / name)
info = {
    "CFBundleDevelopmentRegion": "en",
    "CFBundleExecutable": "App",
    "CFBundleIdentifier": "com.dokkanunitcreator.ios",
    "CFBundleInfoDictionaryVersion": "6.0",
    "CFBundleName": "Unit Creator",
    "CFBundleDisplayName": "Unit Creator",
    "CFBundlePackageType": "APPL",
    "CFBundleShortVersionString": version,
    "CFBundleVersion": build,
    "CFBundleSupportedPlatforms": ["iPhoneOS"],
    "MinimumOSVersion": "16.4",
    "LSRequiresIPhoneOS": True,
    "UIDeviceFamily": [1, 2],
    "UIRequiredDeviceCapabilities": ["arm64"],
    "DTPlatformName": "iphoneos",
    "DTPlatformVersion": sdkv,
    "DTSDKName": "iphoneos" + sdkv,
    "CFBundleIcons": {"CFBundlePrimaryIcon": {"CFBundleIconFiles": ["AppIcon60x60"], "CFBundleIconName": "AppIcon"}},
    "CFBundleIcons~ipad": {"CFBundlePrimaryIcon": {"CFBundleIconFiles": ["AppIcon60x60", "AppIcon76x76", "AppIcon83.5x83.5"], "CFBundleIconName": "AppIcon"}},
    "UILaunchScreen": {},
    "UIUserInterfaceStyle": "Dark",
    "UIStatusBarStyle": "UIStatusBarStyleLightContent",
    "UIViewControllerBasedStatusBarAppearance": True,
    "UIApplicationSceneManifest": {
        "UIApplicationSupportsMultipleScenes": False,
        "UISceneConfigurations": {"UIWindowSceneSessionRoleApplication": [
            {"UISceneConfigurationName": "Default", "UISceneDelegateClassName": "SceneDelegate"}]},
    },
    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
    "UISupportedInterfaceOrientations~ipad": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
    "ITSAppUsesNonExemptEncryption": False,
    "NSCameraUsageDescription": "Lets you take a photo to use as unit artwork.",
    "NSPhotoLibraryUsageDescription": "Lets you pick a picture to use as unit artwork.",
    "NSPhotoLibraryAddUsageDescription": "Lets you save pictures you export.",
    "NSAppTransportSecurity": {"NSAllowsLocalNetworking": True, "NSAllowsArbitraryLoads": True},
    "UIFileSharingEnabled": True,                 # Files app: On My iPhone › Dokkan Unit Creator (downloads only)
    "LSSupportsOpeningDocumentsInPlace": True,
}
with open(app / "Info.plist", "wb") as f: plistlib.dump(info, f, fmt=plistlib.FMT_BINARY)
EOF

mkdir -p "$W/out"; OUTF="$W/out/UnitCreator-$VERSION.ipa"; rm -f "$OUTF"
(cd "$T" && zip -qry "$OUTF" Payload)
rm -rf "$T"
# iPhone Duo full-screen gate (docs/IPHONE-DUO-DISPLAY.md): a build that would bring back black bars is not kept
bash "$HERE/check-duo.sh" "$OUTF" || { rm -f "$OUTF"; echo "IPA removed: fix the iPhone Duo display check above"; exit 1; }
echo "built $OUTF ($(du -h "$OUTF" | cut -f1))"
