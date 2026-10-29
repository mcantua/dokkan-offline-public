#!/bin/zsh
# Dokkan Unit Creator on Apple's iPhone Duo simulator (Xcode 27.1) — builds a simulator copy of the app
# with the real iOS 27.1 SDK from source/ios-objc + the site/db inside the IPA, runs it, records what it sees.
#   tools/duo-sim-test.sh <UnitCreator-x.y.z.ipa>
setopt nullglob; set -u
R="$(cd "$(dirname "$0")/.." && pwd)"
IPA="${1:-}"; MODE="${2:-full}"; SIMNAME="${SIMNAME:-iPhone Duo}"
E="$R/evidence/sim-$(date +%Y%m%d-%H%M%S)"; mkdir -p "$E"
exec > >(tee "$E/run.log") 2>&1
st(){ echo "=== $(date '+%I:%M:%S %p') $1"; echo "sim: $1" > "$R/evidence/status.txt"; }
fail(){ st "FAILED: $1"; exit 1; }
UDID="$(xcrun simctl list devices available | grep -m1 "    $SIMNAME (" | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
[[ -n "$UDID" ]] || fail "no $SIMNAME simulator"
BID=com.dokkanunitcreator.ios
to(){ perl -e 'alarm shift; exec @ARGV' "$@"; }   # run with a time limit (macOS has no timeout)
shot(){  # screenshot of each powered display + the app's display log + app state
  pkill -f "simctl io $UDID screenshot" 2>/dev/null
  for d in primary primary-1; do to 25 xcrun simctl io "$UDID" screenshot --display=$d "$E/screenshot-$1-$d.png" >/dev/null 2>&1 || rm -f "$E/screenshot-$1-$d.png"; done
  C="$(to 20 xcrun simctl get_app_container "$UDID" "$BID" data)"; cp "$C/Library/display-log.jsonl" "$E/display-log.jsonl" 2>/dev/null
  to 20 xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -i dokkan > "$E/app-running-$1.txt"
  to 40 xcrun simctl spawn "$UDID" log show --last 3m --style compact --predicate 'process == "App" AND (messageType == error OR messageType == fault)' > "$E/app-errors-$1.txt" 2>&1
}
fold(){  # $1 = outer | inner
  if [[ $1 == inner ]]; then xcrun simctl io "$UDID" screenConfig --display=primary-1 power on; xcrun simctl io "$UDID" screenConfig --display=primary power off
  else xcrun simctl io "$UDID" screenConfig --display=primary power on; xcrun simctl io "$UDID" screenConfig --display=primary-1 power off; fi
}
if [[ $MODE == inner || $MODE == outer ]]; then st "fold -> $MODE"; fold $MODE; sleep 6; shot $MODE; st "DONE $E"; exit 0; fi
if [[ $MODE == shot ]]; then xcrun simctl io "$UDID" enumerate > "$E/enumerate.txt" 2>&1; xcrun simctl ui "$UDID" help > "$E/ui-help.txt" 2>&1; shot now; st "DONE $E"; exit 0; fi
W="$R/tmp-sim"; rm -rf "$W"; mkdir -p "$W"; (cd "$W" && unzip -q "$IPA") || fail unzip
APP="$(echo "$W"/Payload/*.app)"
[[ -d "$R/source/site-ios" ]] && { rm -rf "$APP/site"; cp -R "$R/source/site-ios" "$APP/site"; }
st "compiling for the simulator (iOS $(xcrun --sdk iphonesimulator --show-sdk-version) SDK)"
S="$R/source/ios-objc"
xcrun --sdk iphonesimulator clang -target arm64-apple-ios16.4-simulator -fobjc-arc -fmodules -O2 \
  -framework UIKit -framework WebKit -framework Foundation -framework Security -framework Network -lsqlite3 \
  "$S/main.m" "$S/Host.m" "$S/Player.m" -o "$APP/App" || fail compile
/usr/libexec/PlistBuddy -c "Set :CFBundleSupportedPlatforms:0 iPhoneSimulator" -c "Set :DTPlatformName iphonesimulator" "$APP/Info.plist"
codesign --force --sign - "$APP" || fail sign
st "booting $SIMNAME ($UDID)"
xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl bootstatus "$UDID" -b >/dev/null
open -a Simulator --args -CurrentDeviceUDID "$UDID"
xcrun simctl install "$UDID" "$APP" || fail install
xcrun simctl help > "$E/simctl-help.txt" 2>&1; xcrun simctl io "$UDID" help >> "$E/simctl-help.txt" 2>&1
st "launching"
xcrun simctl terminate "$UDID" "$BID" 2>/dev/null
xcrun simctl launch "$UDID" "$BID" || fail launch
sleep 20; shot 20s
sleep 25; shot 45s
rm -rf "$W"
st "DONE $E"
