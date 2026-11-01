#!/bin/bash
# Run only after Tin approves the exact Mac/network/device setup. No automatic execution.
set -euo pipefail
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo 'Show the plan and choose Cancel, Pair only or Full setup with no arguments.'
  echo 'Use --plan for the plan without a chooser, or --execute [--pairing-only] within the approved scope.'
  exit 0
fi
script_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ $# -eq 1 && "$1" == "--plan" ]]; then
  exec /usr/bin/python3 "$script_dir/setup-wizard.py"
fi
if [[ "${1:-}" == "--execute" ]]; then
  shift
  if [[ $# -eq 0 || ( $# -eq 1 && "${1:-}" == "--pairing-only" ) ]]; then
    exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute "$@"
  fi
  echo 'Unsupported setup arguments. No action started.' >&2
  exit 1
fi
if [[ $# -ne 0 ]]; then
  echo 'Use --plan, no arguments for the plan and mode chooser, or --execute [--pairing-only] within the approved scope.' >&2
  exit 1
fi
/usr/bin/python3 "$script_dir/setup-wizard.py"
choice="$(/usr/bin/osascript -e 'display dialog "The plan is shown in Terminal. Continue only within Tin’s already approved Mac/network/device scope. Pair only creates the trusted USB export without Apple-account discovery or app build/install/launch. Full setup also updates the app using the existing signing identity. Apple passwords/codes stay in Apple’s UI or on the phone." buttons {"Cancel", "Pair only", "Full setup"} default button "Cancel" cancel button "Cancel" with title "App Installer setup"' -e 'button returned of result')"
case "$choice" in
  "Pair only") exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute --pairing-only ;;
  "Full setup") exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute ;;
esac
