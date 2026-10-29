#!/bin/zsh
# Lists the phones this Mac can see. Writes evidence/phone-check.txt
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/evidence"
{
echo "== devicectl"; xcrun devicectl list devices 2>&1
echo "== xctrace"; xcrun xctrace list devices 2>&1 | head -30
echo "== USB"; system_profiler SPUSBDataType 2>/dev/null | grep -i -A3 "iphone"
echo "== done $(date)"
} > "$ROOT/evidence/phone-check.txt" 2>&1
echo "saved $ROOT/evidence/phone-check.txt"
