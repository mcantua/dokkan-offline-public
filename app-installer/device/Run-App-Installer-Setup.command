#!/bin/bash
# Run only after Tin approves the exact Mac/network/device setup. No automatic execution.
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ "${1:-}" == "--execute" ]]; then
  shift
  if [[ $# -eq 0 || ( $# -eq 1 && "${1:-}" == "--pairing-only" ) ]]; then
    exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute "$@"
  fi
  echo 'Unsupported setup arguments. No action started.' >&2
  exit 1
fi
if [[ $# -ne 0 ]]; then
  echo 'Use no arguments for the plan, or --execute [--pairing-only] within the approved scope.' >&2
  exit 1
fi
/usr/bin/python3 "$script_dir/setup-wizard.py"
choice="$(/usr/bin/osascript -e 'display dialog "This only shows the plan by default. Run setup only if Tin already explicitly approved this session’s MacBook, selected internet connection, the selected USB setup, and optional Apple provisioning/install steps. Pairing-only uses no Apple account or app installation. Apple passwords/codes stay in Apple’s UI or on the phone." buttons {"Cancel", "Show plan", "Run approved setup"} default button "Show plan" cancel button "Cancel" with title "App Installer setup"' -e 'button returned of result')"
if [[ "$choice" == "Run approved setup" ]]; then
  exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute
fi
