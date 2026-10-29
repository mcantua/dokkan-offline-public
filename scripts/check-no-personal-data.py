#!/usr/bin/env python3
"""Block tracked personal data, private addresses, and signing material."""
import re
import subprocess
import sys

UDID = re.compile(r"\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{16}\b")
EMAIL = re.compile(r"[A-Za-z0-9._%+\-]{1,64}@[A-Za-z0-9.\-]{1,255}\.[A-Za-z]{2,24}")
PRIVATE_IP = re.compile(
    r"(?<![\d.])(?:10(?:\.\d{1,3}){3}|192\.168(?:\.\d{1,3}){2}|172\.(?:1[6-9]|2\d|3[01])(?:\.\d{1,3}){2})(?!\d)"
)
PRIVATE_KEY = re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----")
EMAIL_ALLOW_PREFIXES = (
    "downloads/license-notices/",
    "downloads/isideload/",
    "downloads/idevice/",
    "unit-creator/v2/ui/licenses/",
    "unit-creator/v2/ui/vendor/",
    "unit-creator/decomp/",
    "mac-workspace/research/",
)
SIGNING_SUFFIXES = (
    ".p12", ".p8", ".pem", ".key", ".mobileprovision", ".mobiledevicepairing",
    ".keystore", ".jks", ".pfx",
)


def listed_files():
    if "--staged" in sys.argv:
        cmd = ["git", "diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR"]
    else:
        cmd = ["git", "ls-files", "-z"]
    raw = subprocess.check_output(cmd)
    return [p.decode() for p in raw.split(b"\0") if p]


def show(path):
    if "--staged" in sys.argv:
        return subprocess.check_output(["git", "show", ":" + path])
    return subprocess.check_output(["git", "show", "HEAD:" + path])


def udid_allowed(value):
    return len(set(value.replace("-", "").upper())) <= 1


def email_allowed(path, address):
    domain = address.rsplit("@", 1)[-1].lower().strip(".")
    tld = domain.rsplit(".", 1)[-1]
    if tld in {"png", "jpg", "jpeg", "gif", "js", "css", "json", "html", "svg", "wasm", "xml", "txt", "md"}:
        return True
    if domain == "users.noreply.github.com":
        return True
    return path.startswith(EMAIL_ALLOW_PREFIXES)


def main():
    failures = []
    for path in listed_files():
        lower = path.lower()
        base = lower.rsplit("/", 1)[-1]
        if path == "test-page/UnitCreator-test.html":
            failures.append(("regenerable-html", path))
        if lower.endswith(".ips"):
            failures.append(("crash-log", path))
        if path.startswith("builds/") and lower.endswith(".ipa"):
            failures.append(("ipa", path))
        if any(part == "save" for part in path.split("/")):
            failures.append(("save-dir", path))
        if lower.endswith(SIGNING_SUFFIXES):
            failures.append(("signing-file", path))
        if "sparking" in lower and lower.endswith(SIGNING_SUFFIXES):
            failures.append(("sparking-key", path))
        if path.startswith("mac-workspace/run/") or path.startswith("mac-workspace/tools/"):
            pass
        try:
            data = show(path)
        except subprocess.CalledProcessError:
            failures.append(("unreadable", path))
            continue
        if b"\x00" in data[:8192]:
            continue
        text = data.decode("utf-8", "replace")
        if path.startswith(("mac-workspace/run/", "mac-workspace/tools/")) and "/Users/" in text:
            failures.append(("machine-home", path))
        if PRIVATE_KEY.search(text):
            failures.append(("private-key", path))
        for match in UDID.finditer(text):
            if not udid_allowed(match.group()):
                failures.append(("udid", path))
                break
        if PRIVATE_IP.search(text):
            failures.append(("private-ip", path))
        for match in EMAIL.finditer(text):
            if not email_allowed(path, match.group()):
                failures.append(("email", path))
                break
    if failures:
        for kind, path in failures:
            print(f"{kind}\t{path}")
        return 1
    print("clean")
    return 0


if __name__ == "__main__":
    sys.exit(main())
