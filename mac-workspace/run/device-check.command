#!/bin/zsh
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/tools/duo-device-test.sh" "" check
