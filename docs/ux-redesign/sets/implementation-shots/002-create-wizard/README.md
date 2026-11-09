# Capture package: Sets Create wizard (002)

**Status:** Capture complete — must shot_matrix rows on disk; dual-truth closed for matrix  
**Brief:** `docs/ux-redesign/sets/002-create-wizard-brief.md`  
**COMPARE:** [`COMPARE.md`](COMPARE.md)  
**Capture entry:** `flutter/apps/windows_host/lib/main_sets_armor_capture.dart`  
**Fixtures:** `flutter/apps/windows_host/lib/sets/sets_armor_capture_fixtures.dart`  
  (`kSetsCreateWizardMustShotIds`, `kSetsCreateWizardCaptureSurfaceKeys`)  
**Smoke:** `flutter/apps/windows_host/test/sets_armor_host_smoke_test.dart`  
**Widget:** `flutter/packages/ui_flutter/test/sets_armor_widgets_test.dart` (step machine)  
**Sequence:** `capture-sequence.json`

## Must rows (`drive: host-fixture`)

| id | proves | PNG |
| --- | --- | --- |
| desktop-create-step-type | step-dots; type-grid; continue gated; one-step | `desktop-create-step-type.png` |
| desktop-create-step-class | class-grid; pieces-hidden; back-visible | `desktop-create-step-class.png` |
| desktop-create-step-bonus | bonus-editor-only; searchable-catalog; entity-info-hotspot | `desktop-create-step-bonus.png` |
| desktop-create-step-name | name-field; auto-name-preview; create-primary | `desktop-create-step-name.png` |
| desktop-create-post-board | empty-board-layout-a; optimize-primary; five-pick | `desktop-create-post-board.png` |
| desktop-create-no-quick-create | library-new-only; no-quick-create-rail | `desktop-create-no-quick-create.png` |

## Optional

| id | PNG |
| --- | --- |
| desktop-create-non-armor-thin | `desktop-create-non-armor-thin.png` |

## Surface keys

See `kSetsCreateWizardCaptureSurfaceKeys` in capture fixtures.

## Re-capture

```text
cd flutter/apps/windows_host
# background shell only — never foreground-block
$env:ENABLE_FLUTTER_DRIVER='1'
flutter run -d windows -t lib/main_sets_armor_capture.dart
# then:
dart run tool/capture_driver_shots.dart <vm-service-url> \
  ../../../../docs/ux-redesign/sets/implementation-shots/002-create-wizard \
  ../../../../docs/ux-redesign/sets/implementation-shots/002-create-wizard/capture-sequence.json
```

Scenario rail includes both 001-armor and 002-create-wizard ids (002 appended; 001 not undone).  
`capture_driver_shots.dart` uses `runUnsynchronized` + `scrollIntoView` so late rail chips are tappable.
