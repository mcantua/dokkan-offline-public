#!/bin/bash
# Run only after Tin approves the exact Mac/network/device setup. No automatic execution.
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ "${1:-}" == "--execute" ]]; then
  exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute
fi
/usr/bin/python3 "$script_dir/setup-wizard.py"
choice="$(/usr/bin/osascript -e 'display dialog "This only shows the plan by default. Run setup only if Tin already explicitly approved this session’s MacBook, selected internet connection, Apple provisioning, USB installation and pairing-tool setup. Apple passwords/codes stay in Apple’s UI or on the phone." buttons {"Cancel", "Show plan", "Run approved setup"} default button "Show plan" cancel button "Cancel" with title "App Installer setup"' -e 'button returned of result')"
if [[ "$choice" == "Run approved setup" ]]; then
  exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute
fi
