#!/bin/bash
# iPhone Duo full-screen regression gate. build-ipa.sh runs it on every IPA; a failure stops the build.
#   ios-objc/check-duo.sh out/UnitCreator-<ver>.ipa
# What it guards (see docs/IPHONE-DUO-DISPLAY.md for why each rule exists):
#   1. executable marked as built with the iOS 27.1+ SDK (LC_BUILD_VERSION sdk) -> optimized full-screen tier
#   2. Info.plist: DTSDKName/DTPlatformVersion 27.1+, UILaunchScreen, scene manifest, all iPhone orientations,
#      no UIRequiresFullScreen / no fixed launch storyboard size / no UIScreen-sized window
#   3. web page: viewport-fit=cover, page edges come from --sa-* (native) with env() fallback
#   4. native source: window from the scene, no UIScreen.main sizing, edges pushed to the page
set -uo pipefail
IPA="${1:?Pass an IPA to inspect}"; HERE="$(cd "$(dirname "$0")" && pwd)"; W="$(cd "$HERE/.." && pwd)"
MIN_SDK="${MIN_SDK:-27.1}"
fail=0; ok(){ echo "  ok    $1"; }; bad(){ echo "  FAIL  $1"; fail=1; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
unzip -q "$IPA" 'Payload/*/App' 'Payload/*/Info.plist' 'Payload/*/site/index.html' 'Payload/*/site/web/ios.css' 'Payload/*/site/web/web.css' -d "$T" || { echo "cannot read $IPA"; exit 1; }
APP="$(echo "$T"/Payload/*.app)"
echo "iPhone Duo display check: $(basename "$IPA")"

sdk="$(python3 "$HERE/macho_sdk.py" "$APP/App")" || { echo "cannot read arm64 iOS executable SDK"; exit 1; }
python3 -c "import sys;a=[int(x) for x in sys.argv[1].split('.')];b=[int(x) for x in sys.argv[2].split('.')];sys.exit(0 if a>=b else 1)" "${sdk:-0}" "$MIN_SDK" \
  && ok "executable built for SDK $sdk (needs >= $MIN_SDK)" || bad "executable SDK is '${sdk:-missing}', needs >= $MIN_SDK (iPhone Duo would letterbox the app)"

python3 - "$APP/Info.plist" "$MIN_SDK" <<'EOF' || fail=1
import plistlib, sys
d = plistlib.load(open(sys.argv[1], "rb")); need = [int(x) for x in sys.argv[2].split(".")]
bad = []
v = lambda s: [int(x) for x in str(s).replace("iphoneos", "").split(".") if x.isdigit()]
if v(d.get("DTPlatformVersion", "0")) < need: bad.append("DTPlatformVersion %s" % d.get("DTPlatformVersion"))
if v(d.get("DTSDKName", "0")) < need: bad.append("DTSDKName %s" % d.get("DTSDKName"))
if "UILaunchScreen" not in d and "UILaunchStoryboardName" not in d: bad.append("no launch screen (iOS would use a legacy fixed-size mode)")
if d.get("UIRequiresFullScreen"): bad.append("UIRequiresFullScreen is set (letterboxes in unsupported orientations)")
sm = d.get("UIApplicationSceneManifest", {})
if not sm.get("UISceneConfigurations", {}).get("UIWindowSceneSessionRoleApplication"): bad.append("no UIScene manifest (27.x apps must use scenes)")
o = set(d.get("UISupportedInterfaceOrientations", []))
for k in ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"]:
    if k not in o: bad.append("orientation missing: " + k)
if 1 not in d.get("UIDeviceFamily", []): bad.append("not an iPhone app")
for b in bad: print("  FAIL  Info.plist: " + b)
if not bad: print("  ok    Info.plist: 27.1 SDK keys, launch screen, scene manifest, all orientations, no UIRequiresFullScreen")
sys.exit(1 if bad else 0)
EOF

grep -q 'viewport-fit=cover' "$APP/site/index.html" && ok "page viewport: width=device-width, viewport-fit=cover" || bad "index.html lost viewport-fit=cover (page would stop at the safe area and show bars)"
grep -q 'width=device-width' "$APP/site/index.html" || bad "index.html viewport is not width=device-width"
if grep -h -o 'env(safe-area-inset-[a-z]*)' "$APP/site/web/ios.css" "$APP/site/web/web.css" | grep -q . && \
   grep -h -o '[^(]env(safe-area-inset-[a-z]*)' "$APP/site/web/ios.css" "$APP/site/web/web.css" | grep -v -- ',env(' | grep -q .; then
  bad "a bare env(safe-area-inset-*) in ios.css/web.css: use var(--sa-t|r|b|l,env(...)) so the iPhone Duo camera regions are kept clear"
else ok "page edges use the app's --sa-* values (env() only as fallback)"; fi

grep -q 'duo-rail' "$APP/site/web/ios.css" && ok "tab bar moves into the iPhone Duo status column (.duo-rail)" || bad "ios.css lost the .duo-rail rules (the status column would stay an empty black strip)"

S="$HERE"
grep -n -E 'UIScreen +mainScreen\]? *\.?bounds|mainScreen\.bounds|initWithFrame:\[\[UIScreen' "$S"/*.m && bad "native code sizes something from UIScreen.mainScreen (use the view/window/scene)" || ok "no UIScreen.mainScreen sizing in native code"
grep -q 'initWithWindowScene' "$S/main.m" && ok "window is created from its scene" || bad "window not created with initWithWindowScene"
grep -q 'pushGeometry' "$S/main.m" && grep -q 'reservedRegionsOfKind' "$S/main.m" && ok "screen edges + reserved regions are sent to the page" || bad "main.m no longer sends screen edges (pushGeometry / reserved regions)"
grep -q 'UIScrollViewContentInsetAdjustmentNever' "$S/main.m" && ok "web view fills the window (no automatic inset)" || bad "web view content inset adjustment changed"

[ $fail = 0 ] && echo "iPhone Duo display check passed" || { echo "iPhone Duo display check FAILED"; exit 1; }
