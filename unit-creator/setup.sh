#!/bin/bash
# One-time setup in a fresh workspace. Put these next to this script first:
#   base/Dokkan-Unit-Creator-v2.30.0.apk   (the user's last released APK)
#   signing-key.zip                         (the user's release key: .jks + KEY-INFO.txt with the password)
set -euo pipefail
W=${W:-/home/claude/work}; cd "$W"
APK=base/Dokkan-Unit-Creator-v2.30.0.apk
test -f "$APK" || { echo "Missing $APK — ask the user to attach Dokkan-Unit-Creator-v2.30.0.apk"; exit 1; }
# 1. game databases (used by the test harness and the web build)
mkdir -p apk/assets && unzip -o -q -j "$APK" assets/reference.db assets/sparking-reference.db -d apk/assets
# 2. large player files left out of the bundle: restore them from the APK
missing=0
while IFS= read -r f; do
  [ -f "v2/ui/$f" ] && continue
  mkdir -p "v2/ui/$(dirname "$f")"
  if unzip -p "$APK" "assets/ui/$f" > "v2/ui/$f" 2>/dev/null && [ -s "v2/ui/$f" ]; then echo "restored v2/ui/$f"; else rm -f "v2/ui/$f"; echo "MISSING v2/ui/$f"; missing=1; fi
done < v2/ui-files.txt
# 3. signing key
if [ -f signing-key.zip ]; then
  mkdir -p signing && unzip -o -q signing-key.zip -d signing
  sed -n 's/^Store password: *//p' signing/KEY-INFO.txt | tr -d '\r\n' > signing/.pw && chmod 600 signing/.pw
  echo "signing key ready"
else echo "No signing-key.zip yet — needed only to build a release APK"; fi
chmod +x build-from-release.sh
# 4. tools check
for t in python3 java javac jar unzip node; do command -v $t >/dev/null || echo "MISSING TOOL: $t"; done
python3 -c "import playwright" 2>/dev/null || echo "MISSING: python playwright (pip install playwright --break-system-packages; the browser may already be installed)"
[ $missing = 0 ] && echo "setup OK"
