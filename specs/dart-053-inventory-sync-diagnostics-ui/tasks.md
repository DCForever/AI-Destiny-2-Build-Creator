# Tasks: DART-053 Inventory Sync Diagnostics UI

**Input**: Design documents from `/specs/dart-053-inventory-sync-diagnostics-ui/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first where practical; mark complete only with green evidence.

## Phase 1: Setup

- [x] T001 Write specs (spec/plan/research/quickstart/checklist) + set `.specify/feature.json` → `specs/dart-053-inventory-sync-diagnostics-ui`

## Phase 2: Foundational — pure format (US1)

- [x] T002 [P] [US1] Add `packages/bungie/lib/src/sync/format_sync_diagnostics.dart` + export from `destiny2_bungie.dart`
- [x] T003 [P] [US1] Add `packages/bungie/test/format_sync_diagnostics_test.dart` (raw/parsed/dropped/resolution lines)
- [x] T004 [US1] Run `dart test packages/bungie` for format suite green

## Phase 3: Controller retention (US1)

- [x] T005 [US1] Extend `InventorySyncController` with `lastDiagnostics` + getters (raw/parsed/dropped/storedTotal); clear on signed-out; keep on success only
- [x] T006 [US1] Update `apps/windows_host/test/inventory_sync_controller_test.dart` for retention + vault resolution fields
- [x] T007 [US1] Controller tests green

## Phase 4: Windows Settings card (US2)

- [x] T008 [US2] Surface diagnostics in `inventory_sync_card.dart` (stable keys)
- [x] T009 [US2] Widget tests in `inventory_sync_card_test.dart` for diagnostics after sync
- [x] T010 [US2] Card tests green

## Phase 5: Entity-cache warnings (US3)

- [x] T011 [US3] Settings entity-cache empty warning on `settings_page.dart`
- [x] T012 [US3] Catalog Owned empty prefers entity-cache message in `catalog_page.dart`
- [x] T013 [US3] Tests: settings_page + catalog_page entity/owned warnings
- [x] T014 [US3] Web Settings Owned/entity parity warning + test

## Phase 6: Docs + finish

- [x] T015 Update `docs/multiplatform-dart-feature-gaps.md` GAP-INV-04 closed; GAP-INV-06 UX closed/partial as appropriate
- [x] T016 Update `packages/README.md` diagnostics UI note (DART-053)
- [x] T017 Run full relevant tests (bungie + windows_host inventory/settings/catalog + web settings)
- [x] T018 Commit; merge `--no-edit` into `feature/multiplatform-dart`; roadmap DART-053 **done**; Current → DART-054; commit base
