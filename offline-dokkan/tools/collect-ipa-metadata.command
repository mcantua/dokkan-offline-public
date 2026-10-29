#!/bin/bash
# Run on Tin's Mac only after he approves this exact read-only collection step.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
osascript -e 'display dialog "This reads one IPA you choose. It saves only app version/hash and allowlisted hook names in AI-Workspace. It does not change the IPA, launch an app, connect to the internet, or extract keys. Continue?" buttons {"Cancel", "Continue"} default button "Continue" cancel button "Cancel"' >/dev/null
IPA=$(osascript -e 'POSIX path of (choose file with prompt "Choose your Eclipse or Sparking IPA")')
OUT="$HOME/AI-Workspace/Offline Dokkan Battle/evidence/ipa-metadata.json"
python3 "$HERE/collect_protocol_evidence.py" metadata "$IPA" --out "$OUT"
printf '%s\n' 'Saved AI-Workspace/Offline Dokkan Battle/evidence/ipa-metadata.json. Attach that small JSON in chat.'
