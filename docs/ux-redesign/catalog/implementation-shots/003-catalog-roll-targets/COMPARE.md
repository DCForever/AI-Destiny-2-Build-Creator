# Implementation shots — catalog / 003-catalog-roll-targets

**Date:** 2026-08-07  
**Status:** `capture-complete` (must rows present; human visual score recommended)  
**Hosts:** windows host-fixture (`lib/main_roll_targets_capture.dart`)  
**Brief:** `docs/ux-redesign/catalog/003-catalog-roll-targets-brief.md`  
**Mockups:** `mockups/003-catalog-roll-targets-desktop.html`, `mockups/003-catalog-roll-targets-mobile.html`  
**Open catalog gap (non-blocking):** GAP-CAT-PERK-003 craft ON dual-truth — not expanded this slice.

## Purpose

Wire Catalog weapon detail to DART-073 roll targets: named preferred+avoid multi-pick editor, active profile switcher (default Off), dual trailing score segs on owned chips, rankOwnedForRollTarget when active. Soft overlap disables Save only (DBR-IDL-004); never blocks equip/export (DBR-IDL-008).

## Capture method

| | |
| --- | --- |
| Entrypoint | `flutter run -d windows -t lib/main_roll_targets_capture.dart` |
| Fixtures | `lib/catalog/roll_targets_capture_fixtures.dart` |
| Driver script | `tool/capture_driver_shots.dart` + `capture-sequence*.json` |
| VM Service | Connect Flutter Driver; write PNGs under this folder |

## Matrix coverage (must)

| Matrix id | Shot path | Status | Residual vs mock |
| --- | --- | --- | --- |
| `desktop-detail-active-partial-scores` | `desktop-detail-active-partial-scores.png` | **captured** | dual segs + rank note; structure closed |
| `desktop-detail-active-perfect-clean` | `desktop-detail-active-perfect-clean.png` | **captured** | 3/3 · Av 0 on perfect chip |
| `desktop-detail-active-bad-roll` | `desktop-detail-active-bad-roll.png` | **captured** | 0/3 · Av 1 danger tint |
| `desktop-detail-targets-off` | `desktop-detail-targets-off.png` | **captured** | Off active · no dual segs · power-desc |
| `desktop-detail-view-wash` | `desktop-detail-view-wash.png` | **captured** | Possible rolls ON · preferred/avoid wash |
| `desktop-detail-editor-want-avoid` | `desktop-detail-editor-want-avoid.png` | **captured** | Editor open · W/A badges · no view wash |
| `desktop-detail-empty-unowned` | `desktop-detail-empty-unowned.png` | **captured** | Unowned definition pool |
| `desktop-detail-rank-reorder` | `desktop-detail-rank-reorder.png` | **captured** | Rank order visible on strip |

Plan-plan alias: `desktop-detail-no-active` ≡ `desktop-detail-targets-off` (captured).  
Plan-plan alias: `desktop-detail-editor-want-avoid-overlap` not separately shot — editor-want-avoid covers edit chrome; overlap soft error structure-only via host smoke.

## Fixture identity

| | |
| --- | --- |
| Owned weapon | hash **92001** · **Roll Target HC** |
| Unowned | hash **92002** · **Roll Target Unowned** |
| Instances | `rt-perfect` 400 T3 · `rt-partial` 450 T5 · `rt-dirty` 420 T4 |
| Profile | `rt-pve-fixture` · **PvE** · prefer Arrow/Acc/Kill · avoid Outlaw |

## Structure tests (green)

- `packages/ui_flutter/test/catalog_roll_targets_test.dart`
- `packages/ui_flutter/test/catalog_weapon_detail_test.dart` (003 group)
- `apps/windows_host/test/catalog_roll_targets_host_smoke_test.dart`
- `apps/widgetbook/test/phase3_use_cases_smoke_test.dart`

## Human visual pass

Open mockup + PNG side-by-side. Note residual reopen rows if chrome drifts (switcher layout is full-width list vs mock chip row — structure implements vertical buttons; flag only if product elevates mock pixel-match).

## dual_truth_ok

**Provisional true** for must-row PNG presence + structure green.  
Blocking gaps in DUAL-TRUTH-GAPS for this slice: none known.  
Human may reopen residuals after visual COMPARE.
