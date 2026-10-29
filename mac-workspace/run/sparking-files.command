#!/bin/zsh
# Lists Sparking's Files folder on the phone. Writes evidence/sparking-files.txt
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
if [[ -f "$REPO/config/private.local" ]]; then
  set -a
  source "$REPO/config/private.local"
  set +a
fi
DEV="${DUO_UDID:-00000000-0000000000000000}"
mkdir -p "$ROOT/evidence"
xcrun devicectl device info files --device "$DEV" --domain-type appDataContainer --domain-identifier GLB.Dkkn.Sparking.dev.P4NRE7Q8ZT --subdirectory Documents --recurse > "$ROOT/evidence/sparking-files.txt" 2>&1
echo "saved"
