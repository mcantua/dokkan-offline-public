# Cloud UIKit evidence — latest only

Source run: https://github.com/mcantua/claude-chatg/actions/runs/40719541467
Workflow source: 1bdb7260b9c2a39667b44a71db10a0971002404d
Artifact ID:12828209822, app-installer-cloud-ui-latest. GitHub API: https://api.github.com/repos/mcantua/claude-chatg/actions/artifacts/12828209822/zip
Purpose: review actual UIKit startup, Settings and fixture-based responsive layout without Tin's MacBook, personal connection or a physical phone.

Both XCTest methods passed (0 failures,1.208seconds) on GitHub-hosted arm64 macOS, Xcode16.4/iOS18.5 simulator. The runner created/deleted only its own simulator. OS-managed disposable CoreSimulator state is not a personal device. All saved evidence is in this folder.

Original PNG attachments were extracted losslessly from the XCResult's zstd-compressed data objects with the host zstd library. No pixels edited or generated. Raw XCResult/build log scratch was removed after extraction; the current complete archive remains the workflow's sole exact-named artifact. Prior matching artifacts were pruned by the workflow. source-report.json is the actual job provenance.

Screenshots:
- cloud-ui-1.png: TEST-ONLY fixture,669x951point main view.
- cloud-ui-2.png: actual production Settings, captured after navigation settled.
- cloud-ui-3.png: TEST-ONLY fixture,390x844point main view.
- cloud-ui-4.png: actual production initial login, empty credential fields.
- cloud-ui-5.png: TEST-ONLY fixture,466x678point main view.
- cloud-ui-6.png: TEST-ONLY fixture,951x669point main view.

Fixture screens visibly say TEST-ONLY and prove layout only. No Apple authentication, signing/install, real Keychain/Face ID interaction, VPN, physical Duo rail/fold or phone operation is claimed. Unsigned production IPAs are in builds/ and come from the separately verified Linux build source5cc3490.

SHA-256 of original screenshots:
- cloud-ui-1.png: 36bb810b0fc11c5d41f4fb8bc3376fd55c9b0394d3586bf4ea0c4343cbc011d5
- cloud-ui-2.png: df5bfda055532ce3ee625031b7d9105d286c7082924eea8b660650fda3f58a83
- cloud-ui-3.png: 85b56696d34ed6ac297b975df5be543c10a96eb194eec7ea21a89b2a9c6a0a15
- cloud-ui-4.png: 4619370181e6010d341276d2c27c1542e2c48432a2e1953d6218210c91615c09
- cloud-ui-5.png: ca8345f768fe7367e0e8777529d15ebd8d0906e5adf7eed2e2ccd6ffe23a0585
- cloud-ui-6.png: 25893b5616b507d6f0045a2164ce63efc134bb33414d3fcdd30295a6a1680f92

Superseded UI images removed2026-10-28 after genuine SDK27.1 Duo execution passed the current6 native methods. Historical source/run metadata remain; current original rendered screenshots and focused raw result proof are in downloads/native-ci-evidence/.
