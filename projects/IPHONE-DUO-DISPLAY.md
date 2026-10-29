# Dokkan Unit Creator — iPhone Duo full-screen display

How the iPhone app fills both iPhone Duo displays, why it once didn't, and how every future build keeps it that way.
Last verified: 27 Oct 2026, v2.35.2 (build 122), Xcode 27.1 / iOS 27.1 SDK.

## 1. The two displays (measured, not guessed)

| | Outer (closed) | Inner (open) |
|---|---|---|
| Panel (Apple spec) | 5.4″, 1398 × 2034 px, 460 ppi | 7.6″, 1878 × 2670 px, 430 ppi |
| Aspect (portrait) | 1 : 1.455 | 1 : 1.422 |
| What iOS renders | 1398 × 2034 px @3x (1 : 1) | 2007 × 2853 px @3x, shrunk to the 1878 × 2670 panel (×0.936) |
| App window (points) | **466 × 678** | **669 × 951** (landscape 951 × 669) |
| Web page (CSS px) | 466 × 678, devicePixelRatio 3 | 669 × 951, devicePixelRatio 3 |
| Refresh | up to 120 Hz | up to 120 Hz |

Sources:
- Panel sizes come from apple.com/iphone-duo/specs.
- The render sizes come from `xcrun devicectl device info displays` on his phone (`LCD` 1398×2034, `LCD-1` 2007×2853, pointScale 3) and from `simctl io enumerate` on Apple's iPhone Duo simulator.
- The outer-display window, safe area and page numbers were measured inside the app on the iPhone Duo simulator (`Library/display-log.jsonl`).

**Screen edges on the outer display (measured, iOS 27.1 layout):**
- The status bar and the cameras sit in a column on the right ("the rail").
- Safe area: top 0, right **84**, bottom **34** (home indicator), left 0.
- Reserved "occlusion" regions:
  - status/camera block x 382–466, y 0–174
  - camera 37 × 37 at (400, 29)
- Below y = 174 the right column holds nothing.

While the scene is still settling at launch, iOS briefly reports a top inset of 82 with no rail. The app updates when the final values arrive.

## 2. How iOS decides how big the app is

This is Apple's "Prepare your app for iPhone Duo" guidance (developer.apple.com/iphone-duo/prepare). The tier depends on the SDK the app is marked as built with (the LC_BUILD_VERSION `sdk` field):

| SDK mark | Result on iPhone Duo |
|---|---|
| iOS 26 or older | Open: a phone-sized window centred with black around it. Closed: the app sits left of the status bar. |
| iOS 27.0 | Fills most of the inner display, but leaves an empty strip beside the status bar. |
| **iOS 27.1+** | **Optimized: full display.** Toolbars and tab bars move into the column under the status bar. |

Other requirements:
- 27.x apps must use the UIScene life cycle.
- Windows must come from the scene, not UIScreen.
- Layout must follow the current bounds, not the device, idiom or orientation.

## 3. The cause

There were three layers to it.

**1. iOS tier.** An app marked with an SDK below 27.1 is letterboxed or pillarboxed by iOS itself. Those are the black bars.
- Our IPA is built on Linux against the iPhoneOS 16.5 SDK. It must still be marked SDK 27.1 (`-Wl,-platform_version,ios,16.4,27.1`) with matching Info.plist keys.
- This was in place from v2.30 and is now enforced by the build gate.
- Changing the "reported version" is only one part. On its own it doesn't make the app lay out correctly.

**2. Window and scene.** The app was already scene-based (`UIApplicationSceneManifest`, `initWithWindowScene:`) and had a `UILaunchScreen`.
- It has no `UIRequiresFullScreen`, so it isn't letterboxed in other orientations.
- It supports every orientation, and the web view fills the window (`contentInsetAdjustmentBehavior = Never`).
- No `UIScreen.mainScreen` sizing is used.

**3. The page's screen edges (the remaining real problem).** On the 27.1 layout the status bar and cameras form a vertical column on the side.
- UIKit leaves that whole column (84 points) outside the safe area.
- The web page stopped its content there, but its tab bar still sat along the bottom. So the column was an empty dark strip down the whole right edge: an 84-pt "black bar" (18 % of the outer display).
- WebKit's `env(safe-area-inset-*)` only knows the rectangular safe area. It doesn't know the iPhone Duo reserved regions (cameras, fold), which UIKit exposes separately (`-[UIView reservedRegionsOfKind:]`, iOS 27.1).

## 4. The fix (v2.35.2)

**Native (ios-objc/main.m)**
- `-geometry` reads the view's safe area plus the reserved regions (`occlusionRegionKind`, `divisionRegionKind`).
  - These are looked up at run time, because the app compiles against an older SDK.
  - A camera that sits **inside** the safe area near an edge widens that edge by the smallest amount needed.
  - One in the middle is left alone, and the fold (division region) is rendered through.
  - An occlusion **outside** the safe area is the rail. The app records its side, its width and where the status/camera part ends (`rail.top`, 174 on the outer display).
  - Edges are relative to the page's own web view, so they are right when the animation player is docked above it.
- `-pushGeometry` sets the page's CSS variables `--sa-t/r/b/l`, `--rail-w`, `--rail-top` and classes `duo-rail` / `duo-rail-left`. It also fires the `forgedisplay` event.
  - It runs on every layout and safe-area change, after folding or rotating, after the page loads, and when the player panel moves.
- Each new screen shape is logged to `Library/display-log.jsonl` (last ~150 lines). Each entry holds:
  - the window and screen size and scale
  - the safe area and the regions
  - what the page itself measured: innerWidth/Height, devicePixelRatio, env(), page width
- The Settings screen report ("This iPhone's screen") shows "Full screen: Yes/No" and the edges being kept clear.

**Web (web/src/ios.css, web.css, v2/ui/workbench.css, v2/ui/perf.js)**
- Every screen-edge rule uses `var(--sa-x, env(safe-area-inset-x))`. The app's values win, and env() is the fallback.
- `html.duo-rail .mobile-nav`: the tab bar stands upright in the status column, from `--rail-top` down to the home indicator. The bottom bar disappears (`--nav-h: 0`), so the content gets the full height.
- In wide layouts (inner display sideways) the same upright tab bar replaces the left sidebar, so the content also gets the sidebar's width (867 instead of 641 points).
- The body keeps its content inside the safe area. Backgrounds still run edge to edge (no stretching, no scaling: the page is laid out at the real width with devicePixelRatio 3).
- Folding and unfolding resizes the same live page with no reload: units, the open editor and your place in a list are kept (`__forgeFold`).

## 5. Rules for every screen (current and future)

1. Never size anything from the device, screen or idiom. Use the page's width and media queries; the window can be any size.
2. Fixed or sticky elements that touch a screen edge must pad with `var(--sa-t|r|b|l, env(...))`, never a bare `env()` and never a fixed number. The build gate rejects a bare `env()`.
3. Full-bleed backgrounds may run under the edges. Text, buttons and inputs may not.
4. Dialogs and sheets use `max-width: calc(100vw - ...)` / `max-height: calc(100dvh - ...)` and must scroll inside themselves.
5. Bottom-anchored UI uses `var(--nav-h)`. It is 0 when the tab bar lives in the rail.
6. Images that crop with `object-fit: cover` must be checked on both 466-wide and 669-wide layouts.
7. Native code: windows come from `initWithWindowScene:`, layout from `view.bounds` in `viewDidLayoutSubviews` / `viewWillTransitionToSize:`. No `UIScreen.mainScreen` bounds.

## 6. Guards that run automatically

- **`ios-objc/check-duo.sh`** runs at the end of every `ios-objc/build-ipa.sh`. A failure deletes the IPA. It checks:
  - SDK mark ≥ 27.1 in the executable
  - the Info.plist DT keys
  - UILaunchScreen, the scene manifest and all orientations
  - no UIRequiresFullScreen
  - viewport-fit=cover
  - no bare env()
  - the .duo-rail rules
  - no UIScreen.mainScreen sizing
  - the window comes from the scene
  - edges and reserved regions are sent to the page
- **`web/test_ios_duo.py`** is the layout regression test in Chromium with real safe-area emulation. It checks:
  - every main screen on the measured outer display and the inner display, portrait and landscape, with the rail on either side
  - the tab-bar-in-rail checks
  - camera-region edges sent by the app
  - fold/unfold without reload, keeping your place and your edits
  - no horizontal overflow and nothing under an edge
- Run it after any UI change: `python3 web/build.py && python3 web/test_ios_duo.py` (about 2 minutes, 88 checks).

## 7. Testing on the Mac (AI-Workspace/Dokkan-Unit-Creator)

These are opened from Finder (double-click in `run/`). Results go to `evidence/<time>/`.

| Launcher | What it does |
|---|---|
| `run/sim-test.command` | Builds a simulator copy with the **real Xcode 27.1 SDK** from `source/ios-objc` and `source/site-ios`. Boots Apple's **iPhone Duo simulator**, installs, launches, takes screenshots and copies `display-log.jsonl`. |
| `run/sim-shot.command` | Screenshot + log of the running simulator app. |
| `run/device-install.command` | Signs the newest `build/UnitCreator-*.ipa` with the Mac's Apple Development identity. Gets a free-account profile through `signing/DokkanSigning.xcodeproj`, installs on the phone (UDID 00000000-0000000000000000), launches, reads the log and screenshots the active display. |
| `run/device-check.command` | Relaunch + log + screenshot (app already installed). |

How to read `display-log.jsonl`:
- `width/height` = window points.
- `t/r/b/l` = edges sent to the page; `safe` = UIKit safe area; `regions` = reserved regions; `rail` = the status column.
- `page.innerWidth` should equal `width`, and `page.pageWidth` should equal `width` (no sideways scrolling).
- `page.dpr` should be 3.
- "Full screen" means `width × height` = the screen's points.

## 8. Verification status (27 Oct 2026)

- **Outer display, iPhone Duo simulator (iOS 27.1): verified.**
  - Window 466 × 678 = the whole screen, page 466 wide at ×3 (1398 × 2034 px), no sideways scrolling.
  - Edges 0/84/34/0; the tab bar is in the status column below y = 174; no bottom bar.
- **Inner display: layout verified in the regression test at the measured 669 × 951 / 951 × 669 sizes.** It was not verified on the simulator because two things are blocked:
  - The simulator's fold control is in Device Hub's window, which the remote-control tool can't operate ("could not verify which document this window is editing").
  - `simctl io screenConfig` power on/off doesn't move the app.
- **Real iPhone Duo, inner display (landscape): verified on 27 Oct 2026 at 3:11 PM** after Naruto Blazing was removed to free an app slot.
  - Window 951 × 669 = the whole screen (1878 × 2670 panel, nativeScale 2.807); page 951 wide, devicePixelRatio 3, no sideways scrolling; env() 0/84/34/0.
  - Status column on the right: 84 wide, cameras and status down to y = 178.
- **Real fold, inner → outer (3:12 PM, logged by the app on the phone): verified.**
  - The page resized live with no reload, from 951 wide to 466 wide.
  - Outer display on the real phone: safe area 0/84/34/0. The status/camera column runs down to y = **218** (the simulator says 174; the app uses whatever the phone reports).
  - For a split second mid-fold iOS reports leftover regions. Since v2.35.2 the app sends the edges again 0.6 s after every fold, so the settled values always win.
- **Earlier (before the slot was freed): blocked.** The phone is at the free Apple ID limit of 3 sideloaded apps (Naruto Blazing Online, Dokkan Eclipse, The Breaking). `devicectl` refuses a 4th ("maximum number of installed apps using a free developer profile"). Removing one of those apps is his decision.
  - Once there's room, double-click `run/device-install.command`, use the app, fold/unfold once, then `run/device-check.command`.
  - Compare the log with section 1.
