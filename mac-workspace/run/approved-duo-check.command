#!/bin/bash
# Tin approved this exact signing/install/display-check scope; no repeat permission dialog.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$HERE/../tools/approved_duo_check.py" "$@"
