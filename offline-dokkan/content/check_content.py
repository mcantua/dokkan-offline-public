"""One targeted integrity scenario against the actual portable resolver.

Synthetic bytes only; Python hashlib independently checks the C SHA-256 path.
"""
import ctypes as C
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix="od-content-check-") as temporary:
    root = Path(temporary)
    library = root / "content.so"
    subprocess.run(["cc", "-std=c11", "-Wall", "-Wextra", "-Werror", "-O2", "-fPIC", "-shared", str(HERE / "content.c"), "-o", str(library)], check=True)
    lib = C.CDLL(str(library))
    lib.od_content_open.argtypes = [C.c_char_p, C.c_char_p, C.POINTER(C.c_void_p)]
    lib.od_content_close.argtypes = [C.c_void_p]
    lib.od_content_resolve.argtypes = [C.c_void_p, C.c_char_p, C.c_int64, C.c_char_p, C.POINTER(C.c_int)]
    lib.od_content_error.argtypes = [C.c_void_p]
    lib.od_content_error.restype = C.c_char_p
    lib.od_content_require.argtypes = [C.c_void_p, C.c_void_p, C.c_int]
    source, cache = root / "imported", root / "private-cache"
    source.mkdir(); cache.mkdir(); (source / "assets").mkdir()
    context = C.c_void_p()
    assert lib.od_content_open(os.fsencode(source), os.fsencode(cache), C.byref(context)) == 0
    def resolve(path, body, *, size=None, digest=None):
        descriptor = C.c_int(-1)
        code = lib.od_content_resolve(context, os.fsencode(path), len(body) if size is None else size,
                                      (digest or hashlib.sha256(body).hexdigest()).encode(), C.byref(descriptor))
        value = None
        if descriptor.value >= 0:
            with os.fdopen(descriptor.value, "rb") as stream: value = stream.read()
        return code, value
    try:
        for name, body in [("empty", b""), ("abc", b"abc"), ("large", bytes(range(256)) * 3000)]:
            (source / "assets" / name).write_bytes(body)
            assert resolve("assets/" + name, body) == (0, body)
            assert (source / "assets" / name).read_bytes() == body
        (source / "assets/abc").unlink()
        assert resolve("assets/abc", b"abc") == (0, b"abc"), "verified cached copy survives source removal"
        bad = b"new source bytes"
        (source / "assets/bad").write_bytes(bad)
        assert resolve("assets/bad", bad, size=len(bad) + 1)[0] != 0
        assert resolve("assets/bad", bad, digest="0" * 64)[0] != 0
        for path in ["../outside", "/outside", "assets/../outside", "assets//bad", "assets/%2e%2e/x", "assets\\bad"]:
            assert resolve(path, bad)[0] != 0
        (root / "outside").write_bytes(bad)
        (source / "link").symlink_to(root, target_is_directory=True)
        (source / "file-link").symlink_to(root / "outside")
        assert resolve("link/outside", bad)[0] != 0
        assert resolve("file-link", bad)[0] != 0
        os.mkfifo(source / "pipe")
        assert resolve("pipe", b"x")[0] != 0, "nonregular files must not block"
        assert resolve("missing", bad)[0] != 0
        assert lib.od_content_require(context, None, 0) != 0
        name = hashlib.sha256(b"abc").hexdigest()
        (cache / name).chmod(0o600); (cache / name).write_bytes(b"bad")
        assert resolve("assets/abc", b"abc")[0] != 0
        assert lib.od_content_error(context) == b"CACHE_INTEGRITY_FAILED"
        assert (cache / name).read_bytes() == b"bad", "unknown bad files are not deleted/replaced"
        assert not list(cache.glob("*.part")), "failed stages are cleaned"
        other = C.c_void_p()
        assert lib.od_content_open(os.fsencode(source), os.fsencode(source), C.byref(other)) != 0
    finally:
        lib.od_content_close(context)
print("Content resolver: checksum/cache reuse, independent SHA vectors, traversal/symlink/FIFO/partial/corrupt-cache checks passed.")
