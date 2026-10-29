#!/usr/bin/env python3
"""Build the actual retained Unit Creator code as a coexisting development APK; never use release signing."""
import hashlib
import json
import os
import pathlib
import secrets
import shutil
import stat
import struct
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
W = ROOT / "unit-creator"
SDK = ROOT / "downloads/android-sdk"
TOOLS = SDK / "build-tools/android-15"
ANDROID = SDK / "platforms/android-35/android.jar"
PACKAGE = "com.dokkanunitcreator.development"
NS = "http://schemas.android.com/apk/res/android"
VERSION, BUILD = "2.36.3", "128"
RESOURCES = {0x7F010000: "@drawable/ic_orbit", 0x7F020000: "@style/AppTheme", 0x7F030000: "@xml/network_security_config"}


def run(args, **kwargs):
    subprocess.run([str(a) for a in args], check=True, **kwargs)


def decode_manifest(data):
    if struct.unpack_from("<HHI", data) != (3, 8, len(data)): raise ValueError("Invalid original binary manifest")
    kind, header, size, count, styles, flags, start, style_start = struct.unpack_from("<HHIIIIII", data, 8)
    if kind != 1 or styles or flags & 0x100: raise ValueError("Expected original UTF-16 manifest pool")
    strings = []
    for offset in struct.unpack_from("<%dI" % count, data, 8 + header):
        p = 8 + start + offset; length = struct.unpack_from("<H", data, p)[0]
        strings.append(data[p + 2:p + 2 + length * 2].decode("utf-16le"))
    stack, root, pos = [], None, 8
    while pos < len(data):
        kind, header, size = struct.unpack_from("<HHI", data, pos)
        if size < header or pos + size > len(data): raise ValueError("Invalid manifest chunk")
        if kind == 0x102:
            namespace, name, first, width, count = struct.unpack_from("<IIHHH", data, pos + 16)
            if width != 20: raise ValueError("Unexpected attribute width")
            element = ET.Element(strings[name])
            for i in range(count):
                a = pos + 16 + first + i * width
                space, name, raw, length, reserved, dtype, value = struct.unpack_from("<IIIHBBI", data, a)
                key = ("{" + strings[space] + "}" if space != 0xFFFFFFFF else "") + strings[name]
                if dtype == 3: text = strings[value]
                elif dtype == 0x12: text = "true" if value else "false"
                elif dtype == 1:
                    if value not in RESOURCES: raise ValueError("Unknown original resource reference")
                    text = RESOURCES[value]
                elif dtype == 0x10: text = str(value)
                elif dtype == 0x11: text = hex(value)
                else: raise ValueError("Unsupported original manifest attribute type")
                element.set(key, text)
            if stack: stack[-1].append(element)
            else: root = element
            stack.append(element)
        elif kind == 0x103:
            if not stack: raise ValueError("Unbalanced original manifest")
            stack.pop()
        pos += size
    if stack or root is None: raise ValueError("Incomplete original manifest")
    return root


def manifest():
    root = decode_manifest((W / "patch/AndroidManifest-v96.xml").read_bytes())
    if root.attrib["package"] != "com.dokkanunitcreation.app": raise ValueError("Unexpected original package")
    root.set("package", PACKAGE); root.set("{" + NS + "}versionCode", BUILD); root.set("{" + NS + "}versionName", VERSION)
    app = root.find("application"); app.set("{" + NS + "}label", "Unit Creator Development")
    app.set("{" + NS + "}debuggable", "true") # Development-only WebView CDP/run-as; release manifest unchanged.
    for provider in app.findall("provider"):
        if provider.get("{" + NS + "}authorities") != "com.dokkanunitcreation.app.patch": raise ValueError("Unexpected original provider")
        provider.set("{" + NS + "}authorities", PACKAGE + ".patch")
    # Binary flags must become symbolic names for aapt2's text-manifest parser.
    flags = {0x20:"keyboardHidden",0x80:"orientation",0x100:"screenLayout",0x400:"screenSize",0x800:"smallestScreenSize"}
    for activity in app.findall("activity"):
        key="{"+NS+"}configChanges"
        if key in activity.attrib:
            value=int(activity.attrib[key],0)
            if value & ~sum(flags): raise ValueError("Unmapped original configuration flags")
            activity.set(key,"|".join(name for bit,name in flags.items() if value & bit))
    for service in app.findall("service"):
        key="{"+NS+"}foregroundServiceType"
        if key in service.attrib:
            if int(service.attrib[key],0)!=0x40000000: raise ValueError("Unknown original foreground service type")
            service.set(key,"specialUse")
    ET.register_namespace("android", NS)
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def main():
    for path in (ANDROID, TOOLS / "aapt2", TOOLS / "lib/d8.jar", TOOLS / "lib/apksigner.jar", W / "decomp/apk/classes.dex", W / "dock/app-v2.jar", W / "apk/assets/reference.db", W / "apk/assets/sparking-reference.db"):
        if not path.is_file(): raise SystemExit("Missing required development build input: " + str(path.relative_to(ROOT)))
    # Caller explicitly provisions pinned tools first. No private data is fetched or fabricated.
    run(["python3", W / "tools/setup-android-tools.py", "--check"])
    run(["python3", W / "tools/setup-smali.py", "--check"])
    out = W / "out"; out.mkdir(exist_ok=True)
    os.umask(0o077)
    with tempfile.TemporaryDirectory(prefix=".development-", dir=out) as temp:
        work = pathlib.Path(temp); res = work / "res"
        for folder in ("drawable", "values", "xml"): (res / folder).mkdir(parents=True)
        from PIL import Image
        Image.open(W / "ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png").convert("RGBA").resize((192,192)).save(res / "drawable/ic_orbit.png")
        (res / "values/styles.xml").write_text('<resources><style name="AppTheme" parent="android:style/Theme.Material.NoActionBar"><item name="android:windowActionModeOverlay">true</item><item name="android:windowLightStatusBar">false</item><item name="android:colorAccent">#f0ad32</item><item name="android:fontFamily">sans</item></style></resources>')
        (res / "xml/network_security_config.xml").write_text('<network-security-config><base-config cleartextTrafficPermitted="false"><trust-anchors><certificates src="system"/></trust-anchors></base-config><domain-config cleartextTrafficPermitted="true"><domain includeSubdomains="false">localhost</domain><domain includeSubdomains="false">127.0.0.1</domain><domain includeSubdomains="false">::1</domain></domain-config></network-security-config>')
        (work / "AndroidManifest.xml").write_bytes(manifest())
        (work / "stable-ids.txt").write_text("\n".join(PACKAGE + ":" + value[1:] + " = " + hex(key) for key,value in RESOURCES.items()) + "\n")
        run([TOOLS / "aapt2", "compile", "--dir", res, "-o", work / "resources.zip"])
        run([TOOLS / "aapt2", "link", "-o", work / "resources.apk", "--manifest", work / "AndroidManifest.xml", "-I", ANDROID, "--stable-ids", work / "stable-ids.txt", "--min-sdk-version", "26", "--target-sdk-version", "35", work / "resources.zip"])
        run(["bash", W / "tools/prepare-release-dex.sh", W / "decomp/apk/classes.dex", work / "classes.dex"])
        # Real SDK declarations for compilation. No runtime/stub class is packaged.
        classes = work / "classes"; classes.mkdir()
        classpath = os.pathsep.join(map(str,(ANDROID,W / "dock/app-v2.jar")))
        run([W / "tools/javac", "--release", "8", "-cp", classpath, "-d", classes, *sorted((W / "dock/src/com/personal/aihub").glob("*.java"))])
        with zipfile.ZipFile(work / "fixes.jar", "w", zipfile.ZIP_DEFLATED) as jar:
            for file in sorted(classes.rglob("*.class")): jar.write(file,file.relative_to(classes).as_posix())
        dex = work / "dex"; dex.mkdir()
        run(["java", "-cp", TOOLS / "lib/d8.jar", "com.android.tools.r8.D8", "--min-api", "26", "--lib", ANDROID, "--classpath", W / "dock/app-v2.jar", "--output", dex, work / "fixes.jar"])
        if sorted(p.name for p in dex.glob("*.dex")) != ["classes.dex"]: raise ValueError("Unexpected patch multidex layout")
        shutil.copy2(work / "resources.apk", work / "unsigned.apk")
        with zipfile.ZipFile(work / "unsigned.apk", "a", zipfile.ZIP_DEFLATED, compresslevel=6) as apk:
            apk.write(work / "classes.dex", "classes.dex"); apk.write(dex / "classes.dex", "classes2.dex")
            for source,prefix in ((W / "v2/ui","assets/ui"),(W / "decomp/apk/lib","lib")):
                for file in sorted(source.rglob("*")):
                    if file.is_file(): apk.write(file,prefix+"/"+file.relative_to(source).as_posix())
            for name in ("reference.db","sparking-reference.db"): apk.write(W / "apk/assets" / name,"assets/"+name)
        run([TOOLS / "zipalign", "-f", "4", work / "unsigned.apk", work / "aligned.apk"])
        # A new private DEVELOPMENT identity allows this package to coexist; it is never Tin's release key.
        key = out / "development-signing.jks"; password = out / ".development-signing-password"
        if key.exists() != password.exists(): raise ValueError("Incomplete existing development signing inputs; originals preserved")
        if not key.exists():
            value = secrets.token_hex(32); password.write_text(value); os.chmod(password,0o600)
            env = dict(os.environ, UC_DEV_STORE_PASS=value)
            run(["keytool", "-genkeypair", "-keystore", key, "-storepass:env", "UC_DEV_STORE_PASS", "-keypass:env", "UC_DEV_STORE_PASS", "-alias", "unitcreator-development", "-dname", "CN=Unit Creator Development,O=Tin Local Development", "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000"],env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        run(["java", "-cp", TOOLS / "lib/apksigner.jar", "com.android.apksigner.ApkSignerTool", "sign", "--ks", key, "--ks-key-alias", "unitcreator-development", "--ks-pass", "file:"+str(password), "--min-sdk-version", "26", "--v1-signing-enabled", "true", "--v2-signing-enabled", "true", "--v3-signing-enabled", "true", "--v4-signing-enabled", "false", "--out", work / "signed.apk", work / "aligned.apk"])
        cert = subprocess.check_output(["java","-cp",str(TOOLS / "lib/apksigner.jar"),"com.android.apksigner.ApkSignerTool","verify","--verbose","--print-certs","--min-sdk-version","26",str(work / "signed.apk")],text=True)
        run([TOOLS / "zipalign", "-c", "4", work / "signed.apk"])
        badging = subprocess.check_output([str(TOOLS / "aapt2"),"dump","badging",str(work / "signed.apk")],text=True)
        if "name='"+PACKAGE+"'" not in badging or "versionCode='128'" not in badging or "versionName='2.36.3'" not in badging or "minSdkVersion:'26'" not in badging or "targetSdkVersion:'35'" not in badging: raise ValueError("Development package metadata mismatch")
        with zipfile.ZipFile(work / "signed.apk") as apk:
            if apk.testzip(): raise ValueError("Development APK ZIP CRC failure")
            for name in ("classes.dex","classes2.dex","assets/reference.db","assets/sparking-reference.db","assets/ui/index.html","resources.arsc"):
                if name not in apk.namelist(): raise ValueError("Required actual app input absent from package")
        candidate = out / "Dokkan-Unit-Creator-Development-2.36.3.apk"
        report = {"version":VERSION,"code":int(BUILD),"package":PACKAGE,"channel":"Coexisting development package; cannot update original release identity","sha256":hashlib.sha256((work / "signed.apk").read_bytes()).hexdigest(),"bytes":(work / "signed.apk").stat().st_size,"minimum_android_api":26,"target_android_api":35,"actual_native_code":"Retained original primary dex plus compiled current dock/src patches; real SDK35, no runtime stubs","databases":"Reconstructed committed browser table snapshots for private CI native checks; not original DB byte fidelity" if os.environ.get("UC_CLOUD_RECONSTRUCTED_DATA_REPORT") else "Supplied original Eclipse and Sparking databases; never committed","verified":["Original required hooks patched and disassembly checked","Actual SDK Java8 compilation and D8 conversion","Exact3 regenerated resource IDs","APK ZIP CRC and required assets","zipalign4 and apksigner verification for API26 minimum","Distinct package/provider/storage/signing identity"],"not_verified":["Android install/launch/runtime","All features/platform parity on hardware","Android16KB-page runtime compatibility of original zstd binaries"]}
        resources = subprocess.check_output([str(TOOLS / "aapt2"),"dump","resources",str(work / "signed.apk")],text=True)
        for key,value in RESOURCES.items():
            if ("resource "+hex(key)+" "+value[1:]) not in resources: raise ValueError("Original resource ID changed: "+value)
        (work / "signed.apk").replace(candidate)
        report_file = out / "development-android-check.json"; pending=report_file.with_suffix('.part');pending.write_text(json.dumps(report,indent=2)+'\n');pending.replace(report_file)
        print("Built coexisting development APK "+candidate.name+" ("+report['sha256']+")")


if __name__ == "__main__": main()
