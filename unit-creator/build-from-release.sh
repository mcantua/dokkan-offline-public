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
W=${W:-/home/claude/work}; cd $W
CODE=${1:?versionCode}; NAME=${2:?versionName}
BASE=${BASE:-$W/base/Dokkan-Unit-Creator-v2.30.0.apk}
KS=${KS:-$W/signing/dokkan-unit-creation-release.jks}; KSALIAS=${KSALIAS:-dokkanunitcreation}; KSPASS=${KSPASS:-$(cat $W/signing/.pw)}
OUT=$W/out; rm -rf $OUT/tmp && mkdir -p $OUT/tmp/classes
# 1. classes2.dex from dock/src (Java 8 bytecode; the stubs stand in for Android + the app's own classes)
javac -nowarn --release 8 -cp dock/build/stubs:dock/app-v2.jar -d $OUT/tmp/classes dock/src/com/personal/aihub/*.java 2>&1 | grep -v JAVA_TOOL || true
test -f $OUT/tmp/classes/com/personal/aihub/ForgeFixes.class || { echo "javac failed"; exit 1; }
(cd $OUT/tmp/classes && jar cf ../fixes.jar com)
java -cp tools/dx-30.0.2.jar com.android.dx.command.Main --dex --no-strict --output=$OUT/tmp/classes2.dex $OUT/tmp/fixes.jar 2>&1 | grep -v JAVA_TOOL || true
# 2. manifest with the new version
python3 patch/axml_version.py patch/AndroidManifest-v96.xml $OUT/tmp/AndroidManifest.xml "$CODE" "$NAME"
# 3. new APK: base APK with assets/ui replaced by v2/ui, new classes2.dex and manifest
python3 - "$BASE" "$OUT/tmp/unsigned.apk" v2/ui "$OUT/tmp" <<'PY'
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
# 4. sign (uber-apk-signer also zip-aligns and verifies)
java -jar tools/uber.jar -a $OUT/tmp/unsigned.apk -o $OUT/tmp/signed --ks "$KS" --ksAlias "$KSALIAS" --ksPass "$KSPASS" --ksKeyPass "$KSPASS" 2>&1 | grep -E "VERIFY|verified|ERROR|error|Success" || true
mv $OUT/tmp/signed/*.apk "$OUT/Dokkan-Unit-Creator-v$NAME.apk"
echo "built $OUT/Dokkan-Unit-Creator-v$NAME.apk"
