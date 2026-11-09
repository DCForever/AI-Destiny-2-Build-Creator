# Capture package: Sets Armor (001)

**Status:** Capture complete — must shot_matrix rows on disk; dual-truth closed for matrix  
**Brief:** `docs/ux-redesign/sets/001-armor-brief.md`  
**COMPARE:** [`COMPARE.md`](COMPARE.md)  
**Capture entry:** `flutter/apps/windows_host/lib/main_sets_armor_capture.dart`  
**Fixtures:** `flutter/apps/windows_host/lib/sets/sets_armor_capture_fixtures.dart`  
**Smoke:** `flutter/apps/windows_host/test/sets_armor_host_smoke_test.dart`  
**Sequence:** `capture-sequence.json`

## Must rows (`drive: host-fixture`)

| id | proves | PNG |
| --- | --- | --- |
| desktop-library-armor | dual-pane, Armor columns, used-by | `desktop-library-armor.png` |
| desktop-signed-out-honesty | signed-out empty, no fake owned | `desktop-signed-out-honesty.png` |
| desktop-create-type-class | Type+Class lock; pieces hidden | `desktop-create-type-class.png` |
| desktop-empty-board | Optimize primary; five Pick; Σ zeros | `desktop-empty-board.png` |
| desktop-filled-board-coverage | layout A totals; hard+soft coverage | `desktop-filled-board-coverage.png` |
| desktop-owned-compare | owned-only; instance ids; no Catalog embed | `desktop-owned-compare.png` |
| desktop-optimize-confirm | kit matrix; confirm-only; replace-all if pins | `desktop-optimize-confirm.png` |
| desktop-delete-set-in-use | confirm + SET_IN_USE used-by | `desktop-delete-set-in-use.png` |

## Optional rows

| id | PNG |
| --- | --- |
| desktop-tags-blocked | `desktop-tags-blocked.png` |
| desktop-need-sync | `desktop-need-sync.png` |
| desktop-non-armor-thin | `desktop-non-armor-thin.png` |

## Surface keys

See `kSetsArmorCaptureSurfaceKeys` in capture fixtures.

## Re-capture

```text
cd flutter/apps/windows_host
# background shell only — never foreground-block
$env:ENABLE_FLUTTER_DRIVER='1'
flutter run -d windows -t lib/main_sets_armor_capture.dart
# then:
dart run tool/capture_driver_shots.dart <vm-service-url> \
  ../../../../docs/ux-redesign/sets/implementation-shots/001-armor \
  ../../../../docs/ux-redesign/sets/implementation-shots/001-armor/capture-sequence.json
```

## Note

Host product-page cutover residuals (god-page, empty live compare, OptimizerWorkspace primary) are COMPARE reopen items — not open `blocks_dual_truth` gap IDs. Mobile remains structure-only.
