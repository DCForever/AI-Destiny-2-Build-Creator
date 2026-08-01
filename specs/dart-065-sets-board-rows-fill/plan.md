# Implementation Plan: DART-065 Sets Board, Dense Rows, Slot Fill

**Branch**: `dart-065-sets-board-rows-fill` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `specs/dart-065-sets-board-rows-fill/spec.md`

## Summary

Close Sets UI fidelity gaps on Windows Flutter + Jaspr: armor EoF base-roll six-stat board + totals; dense item rows (meta, traits, Instance|Wishlist, linked synergies); embedded catalog slot-fill density (Jaspr retires hash-only); occupied-slot replace confirm; weapon fill persists/shows selectedPerks. Soft never auto-applies; no CLIENT_SECRET; cutover GO unchanged.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_app`, `destiny2_domain`, `destiny2_db`, `destiny2_manifest`, Flutter Windows host, Jaspr web host  

**Storage**: Drift set_items (`selectedPerks` JSON array); inventory `statValues` / `socketPlugs` for enrichment  

**Testing**: `dart test` packages; Flutter widget tests; Jaspr controller/component tests  

**Target Platform**: Windows Flutter + Jaspr web  

**Constraints**: Pure Dart I/O; no Node sidecar; no CLIENT_SECRET; soft never auto-applies; no cutover re-gate  

## Constitution Check

- I. Small Testable Increments: US1–US5 independently testable  
- II. Test-First: pure board/trait/replace helpers + host tests with implementation  
- III. Green Commit: package + host tests green before merge  
- IV–V. Co-located tests; exit criteria map  

## Project Structure

### Documentation (this feature)

```text
specs/dart-065-sets-board-rows-fill/
├── plan.md
├── research.md
├── spec.md
├── tasks.md
└── checklists/requirements.md
```

### Source Code

```text
packages/db/lib/src/repos/
  armor_set_stats.dart          # NEW pure sumArmorSetStats
  instance_projection.dart      # reuse buildArmorBaseStatBoard, plug cards
packages/app/lib/src/
  set_board_presentation.dart   # NEW pure presentation helpers
apps/windows_host/lib/sets/
  sets_library_controller.dart  # selectedPerks + replace
  sets_library_page.dart        # dense rows + board + confirm
  set_catalog_picker.dart       # denser meta + trait perks on pin
  set_item_presentation_host.dart # host enrichment wiring
apps/web_host/lib/sets/
  sets_controller.dart
  sets_page.dart                # catalog fill + dense rows + board + confirm
  set_slot_fill_panel.dart      # NEW embedded catalog fill
```

## Implementation approach

1. **Pure armor totals**: `sumArmorSetStats` over pieces with optional `ArmorBaseStatBoard` / stat maps (EoF keys, grandTotal, incomplete, piecesWithStats).
2. **Pure trait + fill helpers**: extract trait perk hashes from `CatalogInstanceProjection` / socket plugs; `slotNeedsReplaceConfirm`; meta chip list builder.
3. **SetSlotPickResult**: add `selectedPerks`; controllers pass through to `UpsertSetItemCommand`.
4. **Windows detail**: dense slot rows; armor board for armor sets; replace dialog before fill when occupied.
5. **Windows picker**: show element/type/exotic meta; on instance pin, extract trait selectedPerks.
6. **Jaspr**: replace hash-only form with search+list fill panel (catalog bridge when available); dense rows; board; confirm step.
7. **Docs**: close GAP rows; roadmap done; pointer → DART-066.

## Risks / mitigations

| Risk | Mitigation |
| ---- | ---------- |
| No plug defs for true armor_stats base | Use stored statValues board (A1 residual) |
| Empty catalog offline | Empty fill state + secondary residual |
| Jaspr without inventory bridge | Named catalog from OfflineCatalog / compose services; Owned when bridge present |
| Scope creep into library filters | Explicitly out of scope (DART-066) |
