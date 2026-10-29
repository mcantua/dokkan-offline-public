# Official hosted inventory — run40925957648

- Repository: mcantua/dokkan-offline-public; source f2ce1f714afac9b9dad0be2ef6872109b779de8f.
- Run: https://github.com/mcantua/dokkan-offline-public/actions/runs/40925957648 . Manual read-only workflow400819292; completed successfully.
- Artifact12920203506:128,834 bytes; SHA-256 `988455706527aa76f277704fd13f56267bd0796a92e425ca108f7e4b578a1f55`. Outer bytes/digest verified before bounded extraction. Download ZIP removed.
- Exact artifact inventory, decoded job log and their provenance/hashes are retained here. Temporary download URLs/tokens are not stored.

| Reported Xcode | Device / simulator / macOS SDK |
|---|---|
| Xcode 26.6; Build version 17F113 | 26.5 / 26.5 / 26.5 |
| Xcode 26.0.1; Build version 17A400 | 26.0 / 26.0 / 26.0 |
| Xcode 26.1.1; Build version 17B100 | 26.1 / 26.1 / 26.1 |
| Xcode 26.2; Build version 17C52 | 26.2 / 26.2 / 26.2 |
| Xcode 26.3; Build version 17C529 | 26.2 / 26.2 / 26.2 |
| Xcode 26.4.1; Build version 17E202 | 26.4 / 26.4 / 26.4 |
| Xcode 26.5; Build version 17F42 | 26.5 / 26.5 / 26.5 |

Host: macOS26.6.2 arm64. Fifteen developer paths (including aliases), seven reported Xcode versions; every probed path has Simulator.app. No enumerated Xcode/SDK27.1+ and no Duo device type. Available iOS runtimes:26.2/build23C54,26.4.1/build23E254a,26.5/build23F77. tvOS/watchOS/visionOS26.2/26.4/26.5 variants are also listed in summary.json. The first default Xcode.app simctl inventory call timed out after35seconds; fourteen other paths returned success. Availability does not establish a successful boot or test.

Comparison: saved xcode-27 evidence in ../run40924206527/toolchain-discovery.json reports Xcode27.1/build27A9275, device/simulatorSDK27.1 (also27.0 and27.2 installed). Its regular-iPhone preflight frontend.log explicitly reports no Simulator.app and uses headless simctl; bootstatus says already booted, which does not establish test-host/UI readiness. Those are separate runner facts. The official macos-latest image cannot satisfy the unchanged SDK27.1 candidate/Duo gate; this inventory does not justify downgrading or claiming native methods passed.

No compiler, test, simulator creation/boot, SDK download, license acceptance, personal Mac/network/device/account action or source change was performed by this retrieval.
