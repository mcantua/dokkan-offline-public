#!/bin/bash
# Build a new Android release from the last released APK.
#   ./build-from-release.sh <versionCode> <versionName>     e.g.  ./build-from-release.sh 88 2.30.1-android
# Inputs (paths relative to /home/claude/work):
#   base/Dokkan-Unit-Creator-v2.30.0.apk   last released APK (already has the smali hooks, icon, resources)
#   v2/ui/                                  the app's screens (copied into assets/ui/)
#   dock/src/com/personal/aihub/*.java      native additions (compiled into classes2.dex)
#   patch/AndroidManifest-v96.xml           binary manifest (v2.30.0 + All files access + download service; version is rewritten)
#   signing/dokkan-unit-creation-release.jks + signing/.pw (password, one line)   ← from signing-key.zip
# Optional: CLASSES_DEX=/path/classes.dex replaces the main code (only for smali hook changes; see HANDOFF.md).
# Output: out/Dokkan-Unit-Creator-v<versionName>.apk (signed, zip-aligned)
# versionName must have the same number of characters as "2.30.0-android" (binary manifest limit), e.g. 2.30.1-android, 2.31.0-android.
set -euo pipefail
W="${W:-$(cd "$(dirname "$0")" && pwd)}"; cd "$W"
CODE=${1:?versionCode}; NAME=${2:?versionName}
BASE=${BASE:-$W/base/Dokkan-Unit-Creator-v2.30.0.apk}
KS=${KS:-$W/signing/dokkan-unit-creation-release.jks}; KSALIAS=${KSALIAS:-dokkanunitcreation}
KSPASS_FILE="${KSPASS_FILE:-$W/signing/.pw}"
JAVAC="${JAVAC:-$W/tools/javac}"; JAR="${JAR:-$W/tools/jar}"
EXPECTED_CERT=9d274247a6284dfa28b867439cbc2b7f9b87530ba4dd79e84f8423676b99fafa
for input in "$BASE" "$KS" tools/uber.jar tools/dx-30.0.2.jar dock/app-v2.jar patch/AndroidManifest-v96.xml; do
  test -f "$input" || { echo "Missing required Android release input: $input" >&2; exit 1; }
done
if [ -n "${KSPASS:-}" ]; then
  export UC_ANDROID_STORE_PASSWORD="$KSPASS"
  PASS_SOURCE=env:UC_ANDROID_STORE_PASSWORD
else
  test -s "$KSPASS_FILE" || { echo "Missing private keystore password file" >&2; exit 1; }
  PASS_SOURCE="file:$KSPASS_FILE"
fi
for tool in java python3 unzip; do command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }; done
test -x "$JAVAC" && test -x "$JAR" || { echo "Missing Java compiler/jar launchers" >&2; exit 1; }
python3 - "$CODE" "$NAME" "$BASE" <<'PY'
import pathlib,re,sys,zipfile
assert sys.argv[1].isdigit() and 0 < int(sys.argv[1]) < 2147483648, "Invalid versionCode"
assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+-android", sys.argv[2]) and len(sys.argv[2]) == len("2.30.0-android"), "Invalid/same-length Android versionName"
with zipfile.ZipFile(sys.argv[3]) as apk:
    assert {'AndroidManifest.xml','classes.dex','classes2.dex'}.issubset(apk.namelist()), "Base APK lacks original code/manifest"
PY
if [ -n "${CLASSES_DEX:-}" ]; then test -s "$CLASSES_DEX" || { echo "Missing replacement classes.dex" >&2; exit 1; }; fi
OUT="$W/out"; mkdir -p "$OUT"
T="$(mktemp -d "$OUT/.android-XXXXXX")"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/classes"
# Reject a wrong base before compiling or signing. Certificate fingerprints are public, not secrets.
java -cp tools/uber.jar com.android.apksigner.ApkSignerTool verify --print-certs "$BASE" > "$T/base-cert.txt"
python3 - "$T/base-cert.txt" "$EXPECTED_CERT" <<'PY'
import pathlib,re,sys
found=re.findall(r'certificate SHA-256 digest:\s*([0-9a-fA-F]+)',pathlib.Path(sys.argv[1]).read_text())
assert sys.argv[2] in [x.lower() for x in found], "Base APK does not have Tin's expected release certificate"
PY
# Apply narrow classes.dex hooks even when the caller supplies unrelated replacement code.
# No private input is downloaded or fabricated; public pinned tools are prepared separately.
if [ -n "${CLASSES_DEX:-}" ]; then
  DEX_SOURCE="$CLASSES_DEX"
else
  unzip -p "$BASE" classes.dex > "$T/base-classes.dex"
  DEX_SOURCE="$T/base-classes.dex"
fi
bash "$W/tools/prepare-release-dex.sh" "$DEX_SOURCE" "$T/classes.dex"
export CLASSES_DEX="$T/classes.dex"
# 1. classes2.dex from dock/src (Java 8 bytecode; the stubs stand in for Android + the app's own classes)
"$JAVAC" -nowarn --release 8 -cp dock/build/stubs:dock/app-v2.jar -d "$T/classes" dock/src/com/personal/aihub/*.java
test -f "$T/classes/com/personal/aihub/ForgeFixes.class" || { echo "javac produced no ForgeFixes.class"; exit 1; }
(cd "$T/classes" && "$JAR" cf ../fixes.jar com)
java -cp tools/dx-30.0.2.jar com.android.dx.command.Main --dex --no-strict --output="$T/classes2.dex" "$T/fixes.jar"
test -s "$T/classes2.dex" || { echo "No classes2.dex produced" >&2; exit 1; }
# 2. manifest with the new version
python3 patch/axml_version.py patch/AndroidManifest-v96.xml "$T/AndroidManifest.xml" "$CODE" "$NAME"
# 3. new APK: base APK with assets/ui replaced by v2/ui, new classes2.dex and manifest
python3 - "$BASE" "$T/unsigned.apk" v2/ui "$T" <<'PY'
import sys, zipfile, pathlib, os
src, dst, ui, tmp = sys.argv[1:5]
ui = pathlib.Path(ui); zin = zipfile.ZipFile(src); zout = zipfile.ZipFile(dst, "w"); seen = set(); changed = []
for info in zin.infolist():
    n = info.filename
    if n.startswith("META-INF/") and n.endswith((".RSA", ".SF", ".MF", ".DSA", ".EC")): continue
    if n.startswith("assets/ui/"):
        p = ui / n[len("assets/ui/"):]
        if not p.is_file(): changed.append(n + " (removed)"); continue
        data = p.read_bytes()
        if data != zin.read(n): changed.append(n)
    elif n == "AndroidManifest.xml": data = open(tmp + "/AndroidManifest.xml", "rb").read(); changed.append(n)
    elif n == "classes.dex" and os.environ.get("CLASSES_DEX"): data = open(os.environ["CLASSES_DEX"], "rb").read(); changed.append(n + " (from CLASSES_DEX)")
    elif n == "classes2.dex": data = open(tmp + "/classes2.dex", "rb").read(); changed.append(n) if data != zin.read(n) else None
    else: data = zin.read(n)
    zi = zipfile.ZipInfo(n, date_time=info.date_time); zi.compress_type = info.compress_type; zi.external_attr = info.external_attr
    zout.writestr(zi, data); seen.add(n)
for p in sorted(ui.rglob("*")):
    n = "assets/ui/" + p.relative_to(ui).as_posix()
    if p.is_file() and n not in seen:
        zi = zipfile.ZipInfo(n, date_time=(1980, 1, 1, 0, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED
        zout.writestr(zi, p.read_bytes()); changed.append(n + " (new)")
zout.close(); print("changed:", *changed, sep="\n  ")
PY
# 4. Align and sign with apksigner's password-source support: no password value in process arguments.
case "$(uname -s)" in
  Linux) ALIGN_RESOURCE=linux-zipalign-33_0_2 ;;
  Darwin) ALIGN_RESOURCE=mac-zipalign-33_0_2 ;;
  *) echo "Unsupported zipalign host" >&2; exit 1 ;;
esac
unzip -p tools/uber.jar "$ALIGN_RESOURCE" > "$T/zipalign"; chmod 700 "$T/zipalign"
"$T/zipalign" -f 4 "$T/unsigned.apk" "$T/aligned.apk"
java -cp tools/uber.jar com.android.apksigner.ApkSignerTool sign --ks "$KS" --ks-key-alias "$KSALIAS" --ks-pass "$PASS_SOURCE" --out "$T/signed.apk" "$T/aligned.apk"
java -cp tools/uber.jar com.android.apksigner.ApkSignerTool verify --print-certs "$T/signed.apk" > "$T/final-cert.txt"
"$T/zipalign" -c 4 "$T/signed.apk"
python3 - "$T/final-cert.txt" "$EXPECTED_CERT" <<'PY'
import pathlib,re,sys
found=re.findall(r'certificate SHA-256 digest:\s*([0-9a-fA-F]+)',pathlib.Path(sys.argv[1]).read_text())
assert sys.argv[2] in [x.lower() for x in found], "Signed APK has the wrong release certificate"
PY
mv "$T/signed.apk" "$OUT/Dokkan-Unit-Creator-v$NAME.apk"
echo "built $OUT/Dokkan-Unit-Creator-v$NAME.apk"
