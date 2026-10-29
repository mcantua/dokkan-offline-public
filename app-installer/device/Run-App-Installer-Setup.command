#!/bin/bash
# Run only after Tin approves the exact Mac/network/device setup. No automatic execution.
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
if [[ "$#" -gt 0 ]]; then
  # Preserve an explicitly selected pairing-only mode. Unknown arguments must
  # fail in argparse rather than silently falling through to a full reinstall.
  exec /usr/bin/python3 "$script_dir/setup-wizard.py" "$@"
fi
/usr/bin/python3 "$script_dir/setup-wizard.py"
choice="$(/usr/bin/osascript -e 'display dialog "Use only within Tin’s approved Mac/USB setup scope. If App Installer is already updated, choose Pair only: no build, signing, app installation or account lookup. Install/update app performs the full setup. Passwords/codes stay in Apple’s UI or on the phone." buttons {"Show plan", "Pair only", "Install/update app"} default button "Show plan" cancel button "Show plan" with title "App Installer setup"' -e 'button returned of result')" || exit 0
if [[ "$choice" == "Pair only" ]]; then
  exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute --pairing-only
elif [[ "$choice" == "Install/update app" ]]; then
  exec /usr/bin/python3 "$script_dir/setup-wizard.py" --execute
fi
