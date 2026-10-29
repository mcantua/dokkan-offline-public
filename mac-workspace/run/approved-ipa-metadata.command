#!/bin/bash
# Tin already approved this read-only scope. File selection is not a repeat permission question.
set -euo pipefail
umask 077
HERE="$(cd "$(dirname "$0")" && pwd)"
COLLECTOR="$HERE/../tools/collect_protocol_evidence.py"
if [ ! -f "$COLLECTOR" ]; then COLLECTOR="$HERE/../../offline-dokkan/tools/collect_protocol_evidence.py"; fi
test -f "$COLLECTOR" || { echo 'Collector source is missing from this bundle.'; exit 1; }
OUT="$HOME/AI-Workspace/Offline Dokkan Battle/evidence"
mkdir -p "$OUT"
for KIND in eclipse sparking; do
  if [ "$KIND" = eclipse ]; then
    IPA="$(osascript -e 'POSIX path of (choose file with prompt "Choose Eclipse Patcher v3.0.0.ipa for read-only metadata")')"
  else
    IPA="$(osascript -e 'POSIX path of (choose file with prompt "Choose Sparking 6.6.ipa for read-only metadata")')"
  fi
  python3 "$COLLECTOR" metadata "$IPA" --out "$OUT/$KIND-ipa-metadata.json"
done
echo 'Saved two small metadata JSON files in AI-Workspace/Offline Dokkan Battle/evidence.'
echo 'Attach eclipse-ipa-metadata.json and sparking-ipa-metadata.json in chat. Do not send IPAs, keys or profiles.'
