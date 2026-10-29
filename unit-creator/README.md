# Dokkan Unit Creator source

This ChatGPT chat continues Claude's Unit Creator and Offline Dokkan work; the other chat owns App Installer. Read root README.md and HANDOFF.md, especially §10.

Latest release: 2.36.2/code127. Current development: 2.36.3/code128. Duo first (both displays), then iPhone and Android, with the same features. The cloud IPA is ad-hoc, not device-ready; An actual isolated Android development APK is now built from retained real code; emulator/physical checks and release signing remain pending.

Run `python3 web/build.py` after a logical change batch; it overwrites `../test-page/UnitCreator-test.html` with all local dependencies inside. See `../test-page/README.md` for verified coverage and gaps. Raw game inputs, databases, signing secrets and native packages are excluded from Git. Do not commit `../test-page/UnitCreator-test.html`; `python3 web/build.py` rebuilds it.
