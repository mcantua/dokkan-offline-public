#!/bin/bash
# Compatibility route only: every install/check uses the reviewed fail-closed helper.
set -euo pipefail
R="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$R/../config/private.local" ]]; then
  set -a
  source "$R/../config/private.local"
  set +a
fi
case "${2:-install}" in
  install) if [ -n "${1:-}" ]; then exec "$R/run/approved-duo-check.command" "$1"; else exec "$R/run/approved-duo-check.command"; fi ;;
  check) exec "$R/run/approved-duo-check.command" --check-installed ;;
  *) echo "Use install or check." >&2; exit 1 ;;
esac
