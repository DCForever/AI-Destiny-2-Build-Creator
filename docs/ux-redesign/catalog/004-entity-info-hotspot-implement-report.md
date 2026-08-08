# Implement report: EntityInfoHotspot (004)

**Date:** 2026-08-08  
**Brief:** `004-entity-info-hotspot-brief.md`  
**Plan:** approved → implement  
**Structure gate:** green (widget tests + analyze; Capture pending)

## Shipped

| Area | Change |
| --- | --- |
| UI primitive | `packages/ui_flutter/lib/src/catalog/entity_info_hotspot.dart` — `EntityInfoData`, portal Flap, sheet, `EntityInfoHotspot` trigger |
| Perk grid | Hover/focus → info; tap/long-press/Alt per brief; residual chrome unchanged |
| Detail | `entityInfoByHash` prop on `CatalogWeaponDetail` |
| Host maps | `buildPerkDescriptionMapFromItemDefs` + bridge/sync builders; resolve via DART-071 → DTO |
| Catalog page | `_entityInfoByHashForDetail()` wires presentations into detail |
| Widgetbook | `EntityInfoHotspot · knobs` use case |
| Tests | `entity_info_hotspot_test.dart` (7) — empty, body, hover+primary, sheet long-press, unknown, single-open, grid wire |

## Interaction (as shipped)

- **Desktop:** hover/focus opens ~280 popover; **click = primary** (select/cycle)
- **Mobile / sheet:** long-press ≥450ms or Alt+tap opens sheet; **tap = primary**
- Empty body: **`No catalog description`**
- Never invents Destiny text; host maps only

## Verify

```text
flutter test packages/ui_flutter/test/entity_info_hotspot_test.dart  → 7 passed
dart analyze packages/ui_flutter/lib  → no errors (pre-existing infos only)
dart analyze apps/windows_host/lib/catalog + host settings → No issues found
```

## Capture / dual-truth

| Status | Notes |
| --- | --- |
| **matrix captured** | 9 must PNGs under `implementation-shots/004-entity-info-hotspot/` |
| Generator | `flutter test test/entity_info_capture_canvas_test.dart` (pure dart:ui; content dual-truth) |
| COMPARE | `implementation-shots/004-entity-info-hotspot/COMPARE.md` |
| Blocking dual-truth gaps | none |
| **dual_truth_ok** | **true** (content + structure; optional live Flap Driver residual) |

## Residual

- Sticky multi-perk inspect sheet (out of scope)
- Optional live Windows Driver re-shot for pixel Neon/Flap host chrome
- Widgetbook codegen regen if annotation runner required for new use case

## Next

Slice can close. Optional: live Driver capture harness for pixel Flap parity.
