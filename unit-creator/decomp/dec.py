import sys, os, logging
from loguru import logger; logger.remove()
from androguard.misc import AnalyzeDex
from androguard.decompiler.decompile import DvClass
out = sys.argv[2]; os.makedirs(out, exist_ok=True)
h, d, dx = AnalyzeDex(sys.argv[1])
for c in d.get_classes():
    n = c.get_name()
    if not n.startswith("Lcom/personal/"): continue
    try:
        dc = DvClass(c, dx); dc.process()
        src = dc.get_source()
    except Exception as e:
        src = "// FAILED " + str(e)
    p = os.path.join(out, n[1:-1].replace("/", "_") + ".java")
    open(p, "w").write(src)
    print(n, len(src))
