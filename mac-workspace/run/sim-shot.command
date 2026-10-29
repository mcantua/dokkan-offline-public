#!/bin/zsh
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "$ROOT/tools/duo-sim-test.sh" "" shot
