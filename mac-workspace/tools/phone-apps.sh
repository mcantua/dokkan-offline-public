#!/bin/zsh
# Lists the apps on the iPhone Duo and what Sparking's Documents folder holds (read-only). Output: evidence/<time>-apps/
setopt nullglob; set -u
R="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$R/../config/private.local" ]]; then
  set -a
  source "$R/../config/private.local"
  set +a
fi
DEV="${DUO_UDID:-00000000-0000000000000000}"
E="$R/evidence/$(date +%Y%m%d-%H%M%S)-apps"; mkdir -p "$E"
exec > >(tee "$E/run.log") 2>&1
echo "$(date '+%I:%M %p') listing apps" > "$R/evidence/status.txt"
xcrun devicectl device info apps --device "$DEV" --json-output "$E/apps.json" > "$E/apps.txt" 2>&1
for b in $(python3 -c "import json,sys;d=json.load(open('$E/apps.json'));[print(a.get('bundleIdentifier','')) for a in d['result']['apps'] if 'park' in (a.get('bundleIdentifier','')+a.get('name','')).lower() or 'clipse' in (a.get('bundleIdentifier','')+a.get('name','')).lower()]"); do
  echo "== $b"
  xcrun devicectl device info files --device "$DEV" --domain-type appDataContainer --domain-identifier "$b" --subdirectory Documents > "$E/files-$b.txt" 2>&1
  head -60 "$E/files-$b.txt"
done
echo "$(date '+%I:%M %p') DONE $E" > "$R/evidence/status.txt"
