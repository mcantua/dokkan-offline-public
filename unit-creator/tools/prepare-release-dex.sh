#!/usr/bin/env bash
# Patch verified base or explicit replacement dex with current narrow native hooks.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
W="$(cd "$HERE/.." && pwd)"
ROOT="$(cd "$W/.." && pwd)"
SOURCE="${1:?source classes.dex}"
DESTINATION="${2:?output classes.dex}"
test -s "$SOURCE" || { echo 'Missing input classes.dex' >&2; exit 1; }
test ! -e "$DESTINATION" || { echo 'Output already exists; previous dex preserved' >&2; exit 1; }
python3 "$HERE/setup-smali.py" --check
mkdir -p "$(dirname "$DESTINATION")"
TEMP="$(mktemp -d "$(dirname "$DESTINATION")/.dex-patch-XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
CLASSPATH="$ROOT/downloads/unit-creator-smali/*"
java -cp "$CLASSPATH" org.jf.baksmali.Main disassemble --api 26 "$SOURCE" -o "$TEMP/source"
python3 "$W/patch/sparking_setup_smali.py" "$TEMP/source"
python3 "$W/patch/master_database_smali.py" "$TEMP/source"
java -cp "$CLASSPATH" org.jf.smali.Main assemble --api 26 "$TEMP/source" -o "$TEMP/patched.dex"
test -s "$TEMP/patched.dex" || { echo 'Assembler produced no patched dex' >&2; exit 1; }
# Round-trip only the two touched classes and require the patchers to see byte-for-byte idempotent hooks.
java -cp "$CLASSPATH" org.jf.baksmali.Main disassemble --api 26 --use-locals --classes 'Lcom/personal/aihub/SprkCodec;,Lcom/personal/aihub/GameDataStore;' "$TEMP/patched.dex" -o "$TEMP/verify"
python3 - "$W" "$TEMP/verify" <<'PY'
import pathlib,subprocess,sys
w,folder=map(pathlib.Path,sys.argv[1:])
def code():
    # baksmali normalizes whitespace; the patch must leave all resulting instructions/labels intact.
    return {p.relative_to(folder):[s.strip() for s in p.read_text().splitlines() if s.strip() and not s.lstrip().startswith(('.', '#'))] for p in folder.rglob('*.smali')}
before=code()
if len(before)!=2: raise SystemExit('Patched dex did not preserve both target classes')
for script in ('sparking_setup_smali.py','master_database_smali.py'): subprocess.run([sys.executable,str(w/'patch'/script),str(folder)],check=True)
if before!=code(): raise SystemExit('Dex round-trip changed required native hook instructions')
PY
mv "$TEMP/patched.dex" "$DESTINATION"
echo 'Current Sparking setup and master-database hooks verified in release dex.'
