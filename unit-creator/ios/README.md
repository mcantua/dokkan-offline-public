# Unit Creator for iPhone

The Dokkan Unit Creator as an iPhone app. It runs fully offline: the whole app and the game
data are inside it, and your units are saved on the phone.

- `site/` is the app's screens and game data (built from the web version: `python3 web/build.py` → `web/site-ios`).
- `App/` is the small iPhone shell around it (Swift). Saving a file opens the iPhone's Save / Share sheet.
- Every push to `main` builds `UnitCreator.ipa` on GitHub (Actions tab → newest run → Artifacts).

## Install on the iPhone (free Apple ID)

1. On the PC, install **Sideloadly** and plug in the iPhone (tap **Trust** on the phone).
2. Drag `UnitCreator.ipa` into Sideloadly, type your Apple ID, press **Start**.
3. On the iPhone: **Settings → General → VPN & Device Management** → tap your Apple ID → **Trust**.
4. If asked, turn on **Settings → Privacy & Security → Developer Mode** and restart.

With a free Apple ID the app has to be re-signed every 7 days (Sideloadly can do it automatically
while the PC is on). Your units stay saved when you re-sign.
