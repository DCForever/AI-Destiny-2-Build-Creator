# Implement report: CatalogRollTargets (003)

**Status:** structure green after fix (workflow had stopped on analyze)  
**Date:** 2026-08-07  
**Brief:** `003-catalog-roll-targets-brief.md`  
**Plan:** `003-catalog-roll-targets-implement-plan.md`

## Workflow outcome

`area-implement` completed with **`ok: false`** — **structure gate failed** (tests_ok true, analyze_ok false).

| Gate | Workflow | After fix |
| --- | --- | --- |
| Tests | pass | pass |
| Analyze (slice files) | fail (unused import on host smoke) | **pass** |
| Full `windows_host` analyze | fail (pre-existing host warnings) | pre-existing only — not introduced by 003 |
| Dual-truth Capture | not run (structure stop) | still open |

### Fix applied

- Removed unused import in `windows_host/test/catalog_roll_targets_host_smoke_test.dart`.

### Verify (post-fix)

```text
cd flutter/packages/ui_flutter && flutter test test/catalog_roll_targets_test.dart test/catalog_weapon_detail_test.dart
# → 55 passed

cd flutter/apps/windows_host && dart analyze lib/catalog/catalog_page.dart test/catalog_roll_targets_*.dart
# → No issues found

flutter test test/catalog_roll_targets_host_smoke_test.dart
# → 2 passed

cd flutter/apps/widgetbook && flutter test test/phase3_use_cases_smoke_test.dart
# → 8 passed
```

## Shipped (structure)

- UI: switcher/editor, dual segs, rank props, view diagonal wash, edit W/A/Off
- Host: app roll-target use cases wired on Catalog
- Tests + Widgetbook knobs for desktop 400 / mobile 390

## Dual-truth Capture (post structure fix)

| | |
| --- | --- |
| Entrypoint | `lib/main_roll_targets_capture.dart` |
| Driver | `tool/capture_driver_shots.dart` |
| Shots dir | `implementation-shots/003-catalog-roll-targets/` |
| COMPARE | updated with **captured** must rows |
| Status | **capture-complete** (PNG presence); human visual score optional |

Must-row PNGs: partial-scores, perfect-clean, bad-roll, targets-off, view-wash, editor-want-avoid, empty-unowned, rank-reorder.

## Residual

- Optional: product-map ID attach; mobile 390 live shots; dedicated overlap soft-error PNG.
- Full `windows_host` package analyze still has pre-existing unrelated warnings.

## STE map (as planned)

See implement plan STE table — architecture → file mapping unchanged.
