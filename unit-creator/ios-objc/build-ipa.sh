#!/bin/bash
# Builds UnitCreator.ipa on Linux: clang + the public iPhoneOS SDK (from github.com/theos/sdks).
#   VERSION=x BUILD=n ./build-ipa.sh -> out/UnitCreator-<version>.ipa
# Produces a development/ad-hoc IPA; device installation still requires Apple provisioning/signing.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
W="${W:-$(cd "$HERE/.." && pwd)}"
REPO="$(cd "$W/.." && pwd)"
VERSION="${VERSION:?Set VERSION to the approved release version}"
BUILD="${BUILD:?Set BUILD to the matching Android version code}"
python3 - "$VERSION" "$BUILD" <<'PY'
import re,sys
assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", sys.argv[1]), "Invalid release version"
assert sys.argv[2].isdigit() and 0 < int(sys.argv[2]) < 2147483648, "Invalid build number"
PY
# Compiled and linked with the iPhoneOS16.5 SDK (the public 27.x SDK copies only ship arm64e library stubs, which
# can't link a normal arm64 app). The app is *marked* as built for SDK 27.1 (LC_BUILD_VERSION + Info.plist):
# iPhone Duo only gives the full inner display to apps built for iOS 27.1; older ones are letterboxed.
# The app uses no API newer than iOS 16.4, so the mark only opts it into the new full-screen behaviour.
SDKV="${SDKV:-27.1}"
TOOLS="${UC_NATIVE_TOOLS:-$REPO/downloads/unit-creator-tools}"
SDK="${IOS_SDK_PATH:-$TOOLS/apple-sdk/source/iPhoneOS16.5.sdk}"
CLANG="${CLANG:-$TOOLS/llvm/root/usr/lib/llvm-19/bin/clang}"
if [ ! -d "$SDK/System/Library/Frameworks/WebKit.framework" ]; then
  echo "Missing pinned iOS SDK. Run: python3 $W/tools/setup-native-tools.py" >&2
  exit 1
fi
test -x "$CLANG" || { echo "Missing clang. Run: python3 $W/tools/setup-native-tools.py" >&2; exit 1; }
export PATH="$(dirname "$CLANG"):$PATH"
export LD_LIBRARY_PATH="$TOOLS/llvm/root/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
for tool in python3 zip unzip; do command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }; done
python3 -c 'from PIL import Image' || { echo "Missing Pillow" >&2; exit 1; }
[ -f "$W/web/site-ios/index.html" ] || { echo "run: python3 $W/web/build.py"; exit 1; }
for database in reference.db sparking-reference.db; do
  test -f "$W/web/ios-db/$database" || { echo "Missing iOS database: $database; rebuild the web page first" >&2; exit 1; }
done

mkdir -p "$W/out"
T="$(mktemp -d "$W/out/.ipa-XXXXXX")"; trap 'rm -rf "$T"' EXIT
APP="$T/Payload/App.app"; mkdir -p "$APP"
"$CLANG" -target arm64-apple-ios16.4 -isysroot "$SDK" -fobjc-arc -fmodules -fmodules-cache-path="$T/modules" -O2 -Wall -Werror=objc-method-access \
  -fuse-ld=lld -Wl,-adhoc_codesign -Wl,-dead_strip \
  -framework UIKit -framework WebKit -framework Foundation -framework Security -framework Network -framework UniformTypeIdentifiers -lsqlite3 -Wl,-platform_version,ios,16.4,"$SDKV" \
  "$HERE/main.m" "$HERE/Host.m" "$HERE/Player.m" -o "$APP/App"
cp -R "$W/web/site-ios" "$APP/site"
mkdir -p "$APP/db" && cp "$W"/web/ios-db/*.db "$APP/db/"
printf 'APPL????' > "$APP/PkgInfo"

python3 - "$APP" "$VERSION" "$BUILD" "$SDKV" "$W" <<'EOF'
import plistlib, sys, pathlib
from PIL import Image
app, version, build, sdkv = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
src = Image.open(pathlib.Path(sys.argv[5]) / "ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png").convert("RGB")
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

OUTF="$W/out/UnitCreator-$VERSION.ipa"
CANDIDATE="$T/UnitCreator-$VERSION.ipa"
(cd "$T" && zip -qry "$CANDIDATE" Payload)
# iPhone Duo full-screen gate (docs/IPHONE-DUO-DISPLAY.md): a build that would bring back black bars is not kept
bash "$HERE/check-duo.sh" "$CANDIDATE" || { echo "Candidate rejected: fix the iPhone Duo display check; previous artifact kept"; exit 1; }
mv "$CANDIDATE" "$OUTF"
echo "built development IPA $OUTF ($(du -h "$OUTF" | cut -f1)); requires Apple provisioning before phone installation"
