# Implementation Plan: DART-053 Inventory Sync Diagnostics UI

**Branch**: `dart-053-inventory-sync-diagnostics-ui` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-053-inventory-sync-diagnostics-ui/spec.md`

## Summary

Close **GAP-INV-04** by retaining full `SyncInventoryResult.diagnostics` on the inventory sync controller and surfacing raw/parsed/dropped/resolution counts on Windows Settings (Next `formatSyncDiagnostics` parity). Close **GAP-INV-06** UX half with entity-cache empty warnings on Settings and Catalog Owned so empty Owned is not blamed solely on inventory sync. Web Settings gets a parity Owned/entity warning path; full web sync UI remains DART-056.

## Technical Context

**Language/Version**: Dart SDK ^3.5  

**Primary Dependencies**: `destiny2_bungie` (diagnostics types + pure formatter); Flutter Windows Settings; Jaspr web Settings  

**Storage**: Diagnostics session-ephemeral only (no new Drift columns)  

**Testing**: `dart test packages/bungie`; `flutter test` apps/windows_host; `dart test` apps/web_host  

**Target Platform**: Windows Settings primary; web Settings parity warning  

**Project Type**: Host UI + pure format helper  

**Performance Goals**: Format is O(unknownBuckets) with top-N cap; no network  

**Constraints**: Pure Dart I/O; no CLIENT_SECRET; soft never auto-applies; do not implement DART-054+  

**Scale/Scope**: One pure format module, controller fields, InventorySyncCard, Settings/Catalog warnings, web Settings copy  

## Constitution Check

- I. Small Testable Increments: US1 format/controller → US2 card → US3 entity warnings  
- II. Test-First: format + controller tests first; then card/catalog widgets  
- III. Green Commit Checkpoints: bungie green, then windows_host, then web_host  
- IV-V. Co-located package/host tests  

No complexity violations.

## Project Structure

### Documentation (this feature)

```text
specs/dart-053-inventory-sync-diagnostics-ui/
├── plan.md
├── research.md
├── quickstart.md
├── checklists/requirements.md
├── spec.md
└── tasks.md
```

### Source Code (touched)

```text
packages/bungie/lib/src/sync/format_sync_diagnostics.dart   # NEW pure format
packages/bungie/lib/destiny2_bungie.dart                    # export
packages/bungie/test/format_sync_diagnostics_test.dart      # NEW
apps/windows_host/lib/settings/inventory_sync_controller.dart
apps/windows_host/lib/settings/inventory_sync_card.dart
apps/windows_host/lib/settings/settings_page.dart           # entity-cache warning
apps/windows_host/lib/catalog/catalog_page.dart             # Owned empty message
apps/windows_host/test/inventory_sync_controller_test.dart
apps/windows_host/test/inventory_sync_card_test.dart
apps/windows_host/test/settings_page_test.dart              # entity warning key
apps/windows_host/test/catalog_page_test.dart               # owned entity message
apps/web_host/lib/pages/settings_page.dart                  # Owned/entity warning
apps/web_host/test/settings_page_test.dart
docs/multiplatform-dart-feature-gaps.md
docs/multiplatform-dart-slice-roadmap.md  # finish only
packages/README.md  # diagnostics UI note
```

**Structure Decision**: Pure formatter lives in `destiny2_bungie` next to sync types so Windows/web/tests share one string shape without Flutter/Jaspr deps.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
