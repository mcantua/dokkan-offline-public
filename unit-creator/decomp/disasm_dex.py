import sys, os
from loguru import logger; logger.remove()
from androguard.misc import AnalyzeDex
out = sys.argv[2]; os.makedirs(out, exist_ok=True)
h, d, dx = AnalyzeDex(sys.argv[1])
for c in d.get_classes():
    n = c.get_name()
    if not n.startswith("Lcom/personal/"): continue
    lines = [".class " + n, ".super " + str(c.get_superclassname())]
    for f in c.get_fields(): lines.append(".field %s %s" % (f.get_name(), f.get_descriptor()))
    for m in c.get_methods():
        lines.append("\n.method %s%s" % (m.get_name(), m.get_descriptor()))
        code = m.get_code()
        if code:
            off = 0
            for ins in m.get_instructions():
                lines.append("  %04x %s %s" % (off, ins.get_name(), ins.get_output()))
                off += ins.get_length()
        lines.append(".end method")
    open(os.path.join(out, n[1:-1].replace("/", "_") + ".smali"), "w").write("\n".join(lines))
