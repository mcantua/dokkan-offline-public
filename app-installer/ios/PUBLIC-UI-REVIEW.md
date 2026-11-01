# Public App Installer UI review

Reviewed 2026-10-29 on `chatgpt/app-installer-pairing-repair`. This is a read-only source review. No app run, screenshot generation, native build, test, device access, or code change was performed for this review.

Later source follow-up, authorized in the same session: `main.m` now bases columns on usable content width, places ongoing task progress and Cancel in a native material panel outside the app-list scroll view, and captures one Home-view/window diagnostic observation before navigation detaches Home. Reduce Transparency uses an opaque grouped background; Dynamic Type and the keyboard guide remain active. Only long status text scrolls within the panel, leaving progress and Cancel pinned. The existing `test02ResponsiveMainUsesLabelledTestOnlyFixture` method was extended to cover the narrow usable-width case, pinned cancellation after list scrolling, maximum accessibility text size, and diagnostic coordinate consistency. These changes have not been compiled, executed, or visually verified. The findings below describe the original source review; the first three have source fixes pending native verification.

## Actual visual evidence

No original `production-default-display.png` or other launched-app screenshot is available from the two current public native runs. Their saved `source-report.json` files record pre-app failures:

| Run | Actual attempted runtime | Result relevant to this review |
| --- | --- | --- |
| 40916969403 | Duo, iOS 27.1 | Pre-app OS health failed; no App Installer appearance captured. |
| 40919528305 | Regular iPhone component fallback, iOS 27.0 | Pre-app OS health timed out; no App Installer appearance captured. This run cannot establish Duo behavior. |

Evidence is under `downloads/completion-verification/public-pairing/run<run-number>/source-report.json`. The builds agent independently confirmed neither run reached the app screenshot command. No image from an older/private repository was opened or reused. No concept image, forced viewport, or source description is presented as actual app appearance.

## Source findings and concrete follow-up

| Finding | Source evidence | Action / confidence |
| --- | --- | --- |
| Wide layout uses the root width, before accounting for content insets. | `main.m:588` selects two equal columns at root width 600 points. Content already loses 48 points to margins (`main.m:183–187`), plus safe areas and any additional camera avoidance (`main.m:625–631`). | Base the decision on available content width and a minimum useful column width. This mismatch exists in source; cramped text or clipping on a specific display is unverified. |
| Progress and Cancel can leave the visible viewport when the user scrolls. | Native `UIActivityIndicatorView`, `UIProgressView`, status text and Cancel are arranged inside the scrolling actions stack (`main.m:269–284`, `main.m:456`). There is no persistent task HUD. | If the intended design requires task visibility throughout the list, keep a compact native status region in the visible safe area. Current controls are already native UIKit. No claim that a custom HUD appears in a running build. |
| Display report mixes the report page's geometry with home-page layout frames. | `main.m:644` captures home scroll/content/rail frames, while `main.m:647` calls `geometryForView:` and `reportForView:` with the report controller's view. The home page is underneath the pushed report page. | Add separately named home geometry or consistently report the home view when diagnosing its rail/content. Current JSON alone cannot establish that the reported safe area and home layout were observed in the same visible page state. |
| Fold division rectangles are recorded but do not choose column positions. | `DisplayDiagnostics.m:63–70` keeps divisions separate; only occlusions enter content avoidance. `main.m:588–590` uses width alone for column layout. | Check a real current division report before deciding whether controls need placement on either side. A division is not itself proof of an occlusion. No hinge overlap is established. |

The source already provides multiline labels and buttons, Dynamic Type support, 52-point minimum primary buttons, 44-point square rail controls, keyboard-aware scrolling, and validated camera-occlusion avoidance. The rail is optional: it requires an actual reserved camera rectangle wholly within a left/right safe-area strip at least 56 points wide, with space for its 106-point stack. It is intentionally hidden when those conditions cannot be established. Absence of that rail on a regular iPhone or an older runtime would not itself show a defect.

## User-reported dimensions

The reported outer 466 × 678 and inner 951 × 669 point dimensions are planning inputs, not a current app geometry report. If those were the actual root bounds, the source would choose stacked outer layout and two inner columns at ordinary text sizes; accessibility text sizes choose stacked layout. Ignoring unknown safe-area/camera insets, the maximum content widths would be 418 and 903 points, respectively, and the inner columns would be 437.5 points each after their 28-point gap. Actual available widths can be smaller.

No current screenshot or physical display report establishes clipping, overlap, full-display coverage, rendering scale, rail location, touch mapping, or fold behavior. A genuine launched-app capture remains the next evidence needed for an appearance review; physical acceptance remains separate.
