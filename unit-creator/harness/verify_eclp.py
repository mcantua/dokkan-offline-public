import json, sys, subprocess, pathlib, shutil, hashlib
req = json.load(open(sys.argv[1])); eclp = sys.argv[1].replace(".request.json", "")
out = pathlib.Path("/tmp/claude-0/eclp-verify"); shutil.rmtree(out, ignore_errors=True)
jo = "-XX:+UnlockDiagnosticVMOptions -XX:-BytecodeVerificationRemote -XX:-BytecodeVerificationLocal -Djava.library.path=/home/claude/tools".split()
r = subprocess.run(["java", *jo, "-cp", "/home/claude/work/jvm/stubout:/home/claude/work/jvm/app.jar", "com.personal.aihub.EclpVerify", eclp, str(out / "x")], capture_output=True, text=True)
print(r.stdout[-3000:], r.stderr[-1500:] if r.returncode else "")
ok = True
for e in req["entries"]:
    f = out / "x" / e["path"]
    if not f.is_file(): print("MISSING", e["path"]); ok = False; continue
    if "text" in e and f.read_bytes() != e["text"].encode(): print("MISMATCH", e["path"]); ok = False
print("ROUNDTRIP OK" if ok else "ROUNDTRIP FAILED")
