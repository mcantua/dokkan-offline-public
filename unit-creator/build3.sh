#!/bin/bash
# Release build: ChatGPT "Beginner Test" APK + reviewed UI (v2/ui) + native hooks for the in-app
# animation player and offline downloads (smali hooks in classes.dex, new code in classes2.dex).
set -euo pipefail
W=/home/claude/work
OUT=$W/out3
: "${KS:=$W/signing/dokkan-unit-creation-release.jks}" "${KSALIAS:=dokkanunitcreation}" "${KSPASS:=$(cat $W/signing/.pw)}"
rm -rf $OUT && mkdir -p $OUT/dex
# classes.dex: original smali + hooks
rm -rf $W/v2/apk-build && cp -r $W/v2/apk-src-pristine $W/v2/apk-build
python3 $W/patch/dock_smali.py $W/v2/apk-build
java -jar /home/claude/tools/apktool.jar b -f -o $OUT/hooked.apk $W/v2/apk-build >/dev/null 2>&1
unzip -q -o $OUT/hooked.apk classes.dex -d $OUT/dex
# classes2.dex: ForgeFixes, ForgeAi, PreviewDock, OfflineLibrary
cd $W/dock && rm -rf build/out && mkdir -p build/out
if ! javac -nowarn --release 8 -cp build/stubs:app-v2.jar -d build/out src/com/personal/aihub/*.java > build/javac.log 2>&1; then grep -v "JAVA_TOOL" build/javac.log; echo "javac failed"; exit 1; fi
rm -f fixes.jar && (cd build/out && jar cf ../../fixes.jar com)
sh /home/claude/tools/d2j/dex-tools-v2.4/d2j-jar2dex.sh -f -o $OUT/dex/classes2.dex fixes.jar >/dev/null 2>&1
cd $W
python3 - "$W/v2/new.apk" "$OUT/unsigned.apk" "$W/v2/ui" "$W/patch/AndroidManifest-v87n.xml" "$W/v2/mine/resources.arsc" "$OUT/dex" <<'PY'
import sys, zipfile, os, pathlib
src, dst, ui, manifest, arsc, dex = sys.argv[1:7]
zin = zipfile.ZipFile(src); zout = zipfile.ZipFile(dst, "w"); names = set(); changed = []
for info in zin.infolist():
    n = info.filename
    if n.startswith("META-INF/") and n.endswith((".RSA", ".SF", ".MF", ".DSA", ".EC")): continue
    if n.startswith("assets/ui/"):
        p = os.path.join(ui, n[len("assets/ui/"):])
        if not os.path.isfile(p): changed.append(n + " (removed)"); continue
        data = open(p, "rb").read()
        if data != zin.read(n): changed.append(n)
    elif n == "AndroidManifest.xml": data = open(manifest, "rb").read(); changed.append(n)
    elif n == "resources.arsc": data = open(arsc, "rb").read(); changed.append(n)
    elif n == "res/drawable/ic_orbit.xml": data = open(os.path.join(os.path.dirname(manifest), "res", "ic_orbit.bin"), "rb").read(); changed.append(n + " (Dragon Ball icon)")
    elif n in ("classes.dex", "classes2.dex"): data = open(os.path.join(dex, n), "rb").read(); changed.append(n)
    else: data = zin.read(n)
    zi = zipfile.ZipInfo(n, date_time=info.date_time); zi.compress_type = info.compress_type; zi.external_attr = info.external_attr
    zout.writestr(zi, data); names.add(n)
for p in sorted(pathlib.Path(ui).rglob("*")):
    if p.is_file():
        n = "assets/ui/" + str(p.relative_to(ui))
        if n not in names:
            zi = zipfile.ZipInfo(n, date_time=(1980, 1, 1, 0, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED
            zout.writestr(zi, p.read_bytes()); changed.append(n + " (new)")
zout.close(); print("changed:", *changed, sep="\n  ")
PY
java -jar /home/claude/tools/uber.jar -a $OUT/unsigned.apk -o $OUT/signed --ks $KS --ksAlias $KSALIAS --ksPass $KSPASS --ksKeyPass $KSPASS 2>&1 | grep -E "VERIFY|verified|ERROR|error|Success" || true
ls -la $OUT/signed
