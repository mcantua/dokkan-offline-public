# Pinned Ghidra static-analysis tool

Selected prebuilt release: **Ghidra12.1.4**, official NSA tag
`Ghidra_12.1.4_build`, published September21,2026.

- Official metadata: https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/tags/Ghidra_12.1.4_build
- Archive: `ghidra_12.1.4_PUBLIC_20260921.zip`,569,649,598bytes.
- Official published SHA-256: `ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db`.
- URL: https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20260921.zip
- License: Apache-2.0 plus the third-party notices/licenses inside the unchanged
  release ZIP. Root LICENSE is retained here too.

## Why this version

The official12.2 README requires64-bit JDK25. The official12.1.4 README and
its packaged `application.properties` require64-bit JDK21. This cloud already
has genuine OpenJDK21.0.12.1 and the `jdk.compiler` module, so no newer JDK was
downloaded. Reference:
https://github.com/NationalSecurityAgency/ghidra/blob/Ghidra_12.1.4_build/README.md

Only its native `bin/javac` launcher was absent. `java -m
jdk.compiler/com.sun.tools.javac.Main -version` returned genuine
`javac21.0.12.1`. `setup.py` supplies a local command-line view forwarding to
that real module and sets Ghidra's documented `JAVA_HOME_OVERRIDE` accordingly.
The module/runtime/release versions are unchanged; this is not a version
substitution or a copied JDK. The managed cloud Java runtime is a service
prerequisite, not another project download. No system Java files are changed.

## Restore and retain once

`python3 downloads/ghidra/setup.py --parts` verifies the published ZIP hash,
extracts bounded safe members with official executable permissions, configures
the Java21 tool view, and writes ordered96MiB transfer parts plus
`transfer-manifest.json`. The six parts reconstruct exactly the verified ZIP;
check its complete SHA before extracting. Upload/update those parts in the
existing Drive Tools and Dependencies folder once; do not upload a duplicate
whole ZIP too. The public provenance/setup/scripts belong in Git. Archive,
parts, expanded runtime and Java tool view are ignored. Existing extracted
runtime is preserved on setup reuse; a complete expanded-byte recheck is not
claimed each time.

## Actual analysis boundary

`run-scoped.py` launches official headless Ghidra with `-noanalysis`, no external
library loading and at most two CPU workers. `ScopedAuthDecompile.java` verifies
source/body identities and requests at most eight specifically configured
entries, each bounded to16KiB and45seconds. Ghidra can follow a tail branch
beyond the requested body, including unwind cleanup into neighboring functions.
The script records every high-pcode instruction site and the count outside the
requested body. The launcher then maps those sites to exact original function
start/size/hash identities in a private `scope-audit.private.json`, without a
second decompile run. An observed extra body is not implicitly admitted as a
reviewed contract. Claims must name the actual used scope, rather than describe
a116-byte wrapper as the full parser it tails into. The tool may compile that
small authored Java analysis script internally. Neither an app nor native game
code is compiled or executed. Nothing is sent to an external analysis service.

For later cohorts, exact imported standard runtime `_Unwind_Resume` and
`__stack_chk_fail` functions are marked non-returning in the analysis project's
metadata. This prevents false fallthrough into neighboring functions after
exception/stack-failure exits. Import identities are matched exactly; no game
function is given a guessed non-returning contract. The supplied binary is
unchanged. Earlier outputs are not rerun merely to reduce their scope receipts.

All imported projects, private addresses, C/pcode output, logs, user settings and
scope configuration stay under ignored `offline-dokkan/private/ghidra`. The
original supplied prepared engine remains readonly/unmodified. User `HOME`
and system Java settings are not changed; child-JVM tool preferences use the
private tool directory. Supported launcher options and the script disassembly
API were checked against the exact official12.1.4 source/docs before use.

Decompiler output is a hypothesis until checked against exact C++ ABI and
actual dataflow. It does not admit an auth response, verify a body envelope,
execute the original client, establish gameplay or produce a playable build.
