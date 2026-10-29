# Duo display evidence and remaining physical checks

Researched October 28, 2026 using public Apple documentation and official GitHub runner manifests. This document does not claim that App Installer was installed or verified on Tin's physical phone.

## Official evidence

- [Apple technical specifications](https://www.apple.com/iphone-duo/specs/) report outer1398×2034 and inner1878×2670 native panels. These are panel pixels, not hardcoded UIKit window dimensions. The app reads current scene/view geometry and scale instead.
- [Apple's preparation guide](https://developer.apple.com/iphone-duo/prepare/) requires adaptive scene/view layout and explains the full-display behavior of genuine iOS27.1-SDK builds. It recommends `traitCollection.displayScale` and scene-backed windows. Replacing an older binary's reported SDK number is not the same as compiling it with that SDK.
- [Apple's Tech Talk](https://developer.apple.com/videos/play/tech-talks/111461/) shows supported open/close/rotate/fold controls in Device Hub. No documented equivalent pose-changing `simctl` command was found in Apple's public command-line reference. The hosted job captures installed `simctl` help for supported-control discovery; it does not invent a fold command or claim forced view sizing is a physical fold.
- [GitHub's official hosted-runner table](https://github.com/actions/runner-images/blob/09456acd2718d935451373231c236286f861fd9c/README.md) provides the `xcode-27` arm64 preview label. Its [pinned image manifest](https://github.com/actions/runner-images/blob/09456acd2718d935451373231c236286f861fd9c/images/macos/xcode-27-arm64-Readme.md) lists Xcode27.1 build27A9275 at `/Applications/Xcode_27.1.app`, real iphoneos/iphonesimulator27.1 SDKs, and an iPhone Duo iOS27.1 simulator. Runtime discovery must confirm this on the actual allocated runner; unavailable prerequisites fail rather than falling back to an older iPhone or a synthetic SDK label.

The source manifest is pinned for evidence, while runner allocation remains GitHub-managed. The selected toolchain version/path and simulator runtime are captured for each run. No developer-download authentication or license bypass is attempted.

## Public runtime signatures

The following Apple DocC declarations were fetched successfully and show introduction in iOS27.1:

- [reservedRegionsOfKind:](https://developer.apple.com/documentation/uikit/uiview/reservedregionsofkind:) returns an array of UIViewReservedRegion objects for a UIViewReservedRegionKind object.
- [occlusionRegionKind](https://developer.apple.com/documentation/uikit/uiviewreservedregionkind/occlusionregionkind) is an Objective-C class method returning the kind object; `divisionRegionKind` is queried separately for fold divisions.
- [active](https://developer.apple.com/documentation/uikit/uiviewreservedregion/active) is a readonly BOOL property with getter `isActive`.
- [frame](https://developer.apple.com/documentation/uikit/uiviewreservedregion/frame) is a readonly CGRect in the queried view's coordinate space, including its margins.

`DisplayDiagnostics.m` checks availability, argument/return encodings and structure sizes before runtime invocation. NSInvocation reads CGRect safely across CPU ABIs. It rejects NaN/infinite/negative, impossible oversized, non-intersecting or whole-view obstruction data. Camera geometry can increase content padding; division regions are reported independently. Rail controls occupy only validated free space under the actual reported camera/status area. If APIs are unavailable, UIKit safe areas remain the fallback. No private selectors, unique region identifiers or arbitrary KVC are used.

## In-app evidence

Settings → Display report shows model family/code, OS, current scene/window/view/native-screen geometry, safe areas, active reserved rectangles, scale, layout mode and nonsecret operation/navigation state. Sharing happens only after the user taps Share. Reports are not automatically logged or sent. They exclude serial/UDID, Apple ID, form contents, app list, credentials, tokens, pairing data and file paths.

`windowMatchesSceneBounds` is a geometry observation; it does not certify physical native rendering, accurate touch behavior or hardware fold transitions. `physicalTouchOrFoldVerified` remains false until a separate human review records evidence.

## Cloud coverage

Hosted tests launch the real app on the actual available Duo simulator with the genuine SDK. Explicitly labelled geometry/service fixtures additionally exercise ordinary, outer-like and inner-like view widths; left/right camera rails; safe-area avoidance;44-point touch targets; logical hit-testing; invalid geometry rejection; progress retention; nonsecret unsent field retention; and navigation retention across a resize sequence. These fixtures never authenticate, sign or install an app. Secure-storage tests use only their own dummy items in the disposable simulator.

Simulator tests use normal Xcode ad-hoc simulator signing, without an Apple account or Team identity. Device candidates stay unsigned. Simulator Keychain success is not evidence of real Apple provisioning or a signed-device release.

## Physical actions still needed — ask Tin first

The root README requires explaining the exact local step and waiting for explicit approval before using Tin's Mac or personal network. Being connected is not approval. The current stop before the first real iPhone install remains in force.

After separate approval for first signing/install/pairing and the needed Mac/phone/Apple-network use:

1. Record only the real model name and OS version; do not collect serial, UDID or account details.
2. Open the signed candidate on the outer display and inner display, both supported orientations. Check edge-to-edge presentation against the live scene/window and panel/native-scale data. Confirm text/icons are crisp, not stretched, and every interactive area is reachable and at least44points.
3. Open Display report before and after folding; share only its sanitized JSON. Check that camera/status rectangles have no overlapping labels or touch targets and that rail controls remain below them.
4. Enter only a clearly nonsecret unsent marker, fold/unfold, open Settings and return. Confirm the marker, navigation position and list state survive. Clear the marker afterward. Do not capture password/2FA screens.
5. Only when Tin separately authorizes a real sign/install/refresh operation, fold during it and verify the operation continues without duplicated tasks, lost progress or input mismatch. Cloud fixture progress is not a substitute for that account/device test.

Keep only the newest sanitized hardware-evidence set. No hardware step has been performed by the cloud agents.

## Supported display controls discovered on the hosted image

Actual owned-simulator discovery is preserved in downloads/sdk-discovery/duo-display-enumeration.txt with its run/source provenance. It exposes two Integrated Connected Screens, descriptor names primary/LCD and primary-1/LCD-1, alongside unrelated TVOut/CarPlay/Scene outputs. The automation parses those actual descriptors and matches their power state to the Display-class0 ports; it does not hardcode numeric screen IDs or touch unrelated outputs. Its published simulator render modes differ from physical panel pixels, so they are not treated as hardware-native resolution evidence.

The installed tool's own help documents screenConfig --display=<selector> power on/off. The test driver uses only those controls on its newly created simulator, initializes one powered primary panel, and exchanges nonce/phase-only test requests through the disposable app's Documents. Tests require the requested real panel's scene/window geometry and functional UI state to be observed. Accepted power commands without the expected scene change fail this check and remain unverified; they are never labelled a physical hinge fold. The driver's original power states are restored before the owned simulator is deleted.
