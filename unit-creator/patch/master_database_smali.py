#!/usr/bin/env python3
"""Add nonthrowing post-activation database snapshot hooks to baksmali output.

Usage: python3 patch/master_database_smali.py <baksmali-output-directory>
Requires the original instance root field and exactly one normal return per method.
"""
import pathlib
import re
import sys


def patch(directory):
    path = pathlib.Path(directory) / "com/personal/aihub/GameDataStore.smali"
    source = path.read_text()
    if not re.search(r"(?m)^\.field[^\n]*\broot:Ljava/io/File;", source):
        raise ValueError("GameDataStore: missing original private root field")
    changed = source
    hook = "Lcom/personal/aihub/MasterDatabaseSnapshots;->changed(Ljava/io/File;)V"
    for signature in ["commit(Ljava/io/File;Lorg/json/JSONObject;)V", "restore()V"]:
        pattern = re.compile(r"(?m)^\.method[^\n]*\b" + re.escape(signature) + r"\n.*?^\.end method", re.S)
        matches = list(pattern.finditer(changed))
        if len(matches) != 1:
            raise ValueError(signature + ": expected exactly one method")
        match = matches[0]
        body = match.group()
        if hook in body:
            if body.count(hook) != 1:
                raise ValueError(signature + ": ambiguous existing hook")
            continue
        if " static " in body.splitlines()[0]:
            raise ValueError(signature + ": expected original instance method")
        locals_match = re.search(r"(?m)^\s*\.locals\s+(\d+)\s*$", body)
        registers_match = re.search(r"(?m)^\s*\.registers\s+(\d+)\s*$", body)
        parameters = 3 if signature.startswith("commit") else 1
        count = int(locals_match.group(1)) if locals_match else int(registers_match.group(1)) - parameters if registers_match else 0
        if count < 1 or count + parameters > 16:
            raise ValueError(signature + ": unexpected original register layout")
        if len(re.findall(r"(?m)^\s*return-void\s*$", body)) != 1:
            raise ValueError(signature + ": ambiguous successful return")
        # v0 is dead at the successful void return. Do not alter any existing register numbers,
        # try/catch boundaries or monitor-exit instructions.
        replacement = "    iget-object v0, p0, Lcom/personal/aihub/GameDataStore;->root:Ljava/io/File;\n\n    invoke-static {v0}, " + hook + "\n\n    return-void"
        body = re.sub(r"(?m)^\s*return-void\s*$", replacement, body, count=1)
        changed = changed[:match.start()] + body + changed[match.end():]
    if changed != source:
        path.write_text(changed)
    print("Master database post-activation hooks ready (private activation unchanged)")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    patch(sys.argv[1])
