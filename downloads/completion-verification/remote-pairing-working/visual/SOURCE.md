# Original native view captures, not hardware verification

Source5855c7a2c0c9face341c28f6b7312705516962ce, successful hosted run40798347194, candidate artifact12865656228. These are unchanged PNG bytes extracted directly from XCTest xcresult Data attachments in the hash-verified artifact. No image edits or generated composites.

Pairing outer1398×2034 (466×678pt) and inner2853×2007 (951×669pt) use explicitly labelled test-only geometry. Main inner2853×2007 is the synthetic progress/managed-app fixture; “Connection verified” and42% are fake UI state, not device evidence. The updated test attaches actual safe-area, frame, typography and pre-reset scroll metadata alongside top-overview PNGs. Simulated left/right insets can combine with inherited UIKit insets; do not infer real physical panel widths from mixed fixtures.

Root visually inspected the pairing/card layout and latest main top overview. An earlier scrolled narrow card was a mixed-inset fixture capture; no established production layout failure was found. Blank immediate production-launch capture is not settled login proof and is not retained as such. Real outer/inner touch and folds remain unverified.
