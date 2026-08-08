# COMPARE — 004 EntityInfoHotspot

**Slice status:** structure + matrix PNGs on disk (stylized canvas capture)  
**Date:** 2026-08-08  
**Generator:** `flutter test test/entity_info_capture_canvas_test.dart` (pure `dart:ui` — system fonts; content dual-truth for desc/empty/unknown/compare/gestures)

| Scenario (matrix id) | must | Mockup | Implementation shot | Residual |
| --- | --- | --- | --- | --- |
| desktop-info-desc-present | true | `mockups/004-entity-info-hotspot-desktop.html` | `desktop-info-desc-present.png` | Live Flap chrome / real perk icons not in canvas shot |
| desktop-info-honest-empty | true | same | `desktop-info-honest-empty.png` | Fixed `No catalog description` proven |
| desktop-click-selects-not-info | true | same | `desktop-click-selects-not-info.png` | Gesture proven in widget tests + diagram |
| mobile-longpress-info-sheet | true | `mockups/004-entity-info-hotspot-mobile.html` | `mobile-longpress-info-sheet.png` | Sticky multi-perk sheet still OOS |
| desktop-unknown-no-hash-primary | true | same | `desktop-unknown-no-hash-primary.png` | Unknown label + `#hash` footer only |
| desktop-enhanced-selected-info | true* | same | `desktop-enhanced-selected-info.png` | *must in workflow plan |
| desktop-enhance-compare | true* | same | `desktop-enhance-compare.png` | Base/Enhanced columns |
| desktop-roll-target-hover-info | true* | same | `desktop-roll-target-hover-info.png` | W/A residual + info |
| desktop-missing-icon-info | true* | same | `desktop-missing-icon-info.png` | Letter fallback |

\*Workflow plan must-rows; brief plan listed a subset as must — all present.

## Structure proof (widget tests)

`flutter test test/entity_info_hotspot_test.dart` — 7 passed (hover info, primary click, sheet long-press, empty, single-open, grid wire).

## Dual-truth notes

- **Content rules** (empty copy, no invent, unknown, compare, gesture model) closed via structure tests + these PNGs.
- **Pixel Neon/Flap ship chrome** on live host may still differ slightly from canvas diagrams — optional Driver re-shot later with `main_entity_info_capture` if added.
- **blocks_dual_truth** gaps for entity-desc: none open in `DUAL-TRUTH-GAPS.md`.

## Matrix coverage

| id | status | path |
| --- | --- | --- |
| desktop-info-desc-present | captured | `desktop-info-desc-present.png` |
| desktop-info-honest-empty | captured | `desktop-info-honest-empty.png` |
| desktop-click-selects-not-info | captured | `desktop-click-selects-not-info.png` |
| mobile-longpress-info-sheet | captured | `mobile-longpress-info-sheet.png` |
| desktop-unknown-no-hash-primary | captured | `desktop-unknown-no-hash-primary.png` |
| desktop-enhanced-selected-info | captured | `desktop-enhanced-selected-info.png` |
| desktop-enhance-compare | captured | `desktop-enhance-compare.png` |
| desktop-roll-target-hover-info | captured | `desktop-roll-target-hover-info.png` |
| desktop-missing-icon-info | captured | `desktop-missing-icon-info.png` |
| desktop-single-open-structure | skipped | widget-test-only |
| mobile-sheet-structure | skipped | widget-test-only |

**dual_truth_ok:** true (must PNGs present; no blocking gap log entries)  
**launch_method:** none (canvas generator)  
**slice_status:** closed (content dual-truth; optional live-Driver residual)
