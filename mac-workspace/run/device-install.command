#!/bin/zsh
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/tools/duo-device-test.sh" "$(ls -t "$ROOT"/build/UnitCreator-*.ipa | head -1)" install
