# Capstone static analysis dependency

Version: 5.0.6. Official PyPI metadata was read from https://pypi.org/pypi/capstone/5.0.6/json.

Wheel: `capstone-5.0.6-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl` (1,481,605bytes).
SHA-256: `0358855773100bb91ae6681fabce7299df83156945ba943f6211061a592c54a6`.
Source URL: https://files.pythonhosted.org/packages/78/7f/ec0687bbe8f6b128f1d41d90ec7cedfd1aaaa4ecb1ae8d334acc7dad8013/capstone-5.0.6-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
License reported by the package: None.

Used only for bounded static arm64 decoding of the supplied original Dokkan
client. It does not execute the game, build an app, contact a game service or
extract keys/account values. The original game image remains private and
readonly. This x86-64 cloud dependency is not shipped inside the app.

Restore the wheel from the existing shared Tools and Dependencies folder, then
verify its hash and install without network/dependencies/bytecode compilation:

```sh
python3 -m pip install --no-index --no-deps --no-compile \
  --target downloads/capstone/runtime downloads/capstone/capstone-5.0.6-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
```

Prepend `downloads/capstone/runtime` to the inspection script's Python path.
Retain the package license distributed in the wheel. Only the small provenance
files belong in Git; runtime expansion and the retained wheel are ignored.
