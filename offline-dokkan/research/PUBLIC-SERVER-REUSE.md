# Bounded public server-reuse search

Reviewed October 29, 2026, to find existing licensed code that could accelerate
the original Sparking 6.6.0 client path. Eight focused public repository queries
covered Dokkan server/backend/private-server/API/emulator terms and the
`sugoroku_maps` route vocabulary. Repository metadata and root filenames were
read first. License text was checked before considering source reuse. No
repository was cloned, no third-party implementation was copied, and no game
constants, keys, account data, or private backup were examined.

No compatible open-source gameplay backend was established in this bounded
search. This is not a claim that no such implementation exists anywhere.

| Public candidate | Observed evidence | Reuse decision |
| --- | --- | --- |
| [MNprojects/DokkanAPI](https://github.com/MNprojects/DokkanAPI) | AGPL-3.0 LICENSE verified. README describes a GraphQL character-data service scraped from the wiki, restricted to LR/UR, with no authentication. Its documented queries are `character` and `characters`; EZA support is listed as future work. | Licensed code exists, but it is not an original-client login/player/team/quest/save server. No current 6.6.0 protocol compatibility established. |
| [Bouncer011/DokkanBattleAPI](https://github.com/Bouncer011/DokkanBattleAPI) | MIT LICENSE verified. Root contains README, LICENSE, static `index.html`, and `data`; README provides only a short project description. | No documented nonce/sign-in/player/team/quest contract or original-client version evidence. No gameplay-server code taken. |
| [Nicholas1006/dokkan-backend](https://github.com/Nicholas1006/dokkan-backend) | Root filenames show database/JSON generators, asset downloader, data, and wallpaper utilities. GitHub metadata exposes no project license and no root LICENSE was present. | Not admitted for code reuse. A repository named backend does not establish an original-client server or permission to copy its code. Only metadata/filenames read. |
| [Codebreak101/Dokkan_Sparking](https://github.com/Codebreak101/Dokkan_Sparking) | Root directories are Announcements, Banners, Events, Gashas, Jukebox, and missions; no root LICENSE or documented server entrypoint. | Content-repository metadata does not establish licensed server implementation or 6.6.0 compatibility. No content/code downloaded. |
| [TheRagingRyan/Dokkan-Unit-Creation-Tool](https://github.com/TheRagingRyan/Dokkan-Unit-Creation-Tool) | GUI unit-creation tool; root includes a Windows executable, Python DLLs, asset/database directories and `frozen_application_license.txt`. GitHub license classification is NOASSERTION. | Not a gameplay backend. A frozen-application dependency license is not assumed to license the whole project. No binaries or source copied. |
| [smf8/gokkan](https://github.com/smf8/gokkan) | Repository description explicitly says Dokkan means a shop backend written in Go. | Unrelated to Dragon Ball Z Dokkan Battle. |

Two additional emulator matches describe Android farming/ADB automation and
had no license identified in metadata. They are not offline servers, and
Android work remains paused.

The two licensed APIs do not provide evidence for the required current-client
`GET /auth/nonce`, `POST /auth/sign_in`, player/home/team state,
`quests/.../sugoroku_maps` transitions, or persistent battle results. Their
data/GraphQL output must not be substituted for those responses. The useful
reuse path remains the preserved original client/engine and actual original
resource set, with locally owned server behavior implemented against verified
current-client contracts.

## Sources actually read

Public GitHub repository metadata and root file listings were read for the
candidates above. Exact document blob identities for the licensed candidates:

- MNprojects/DokkanAPI LICENSE: Git blob
  `0ad25db4bd1d86c452db3f9602ccdbe172438f52`;
  [README](https://github.com/MNprojects/DokkanAPI/blob/main/README.md):
  `267b6c66a624f0f0e8a12e4692c4b918aba40fdd`.
- Bouncer011/DokkanBattleAPI LICENSE: Git blob
  `ad3597dfdd6c524edf50d891dec2ce2cd5e7b8e7`;
  [README](https://github.com/Bouncer011/DokkanBattleAPI/blob/main/README.md):
  `60e38e8d224bdfae2cdaa10bce50ec3a8118aabf`.

The GitHub plugin's dedicated `/license` and `/readme` REST URLs were rejected
by its endpoint allowlist. Approved repository contents listings and raw public
LICENSE/README URLs worked. No broader account access or credential workaround
was attempted. Linked repository claims were treated as evidence to evaluate,
not instructions to execute.
