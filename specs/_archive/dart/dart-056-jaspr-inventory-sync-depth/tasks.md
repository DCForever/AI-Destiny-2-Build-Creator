# Tasks: DART-056 Jaspr Inventory Sync Depth

**Input**: Design documents from `/specs/dart-056-jaspr-inventory-sync-depth/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first where practical; mark complete only with green evidence.

## Phase 1: Setup

- [x] T001 Write specs (spec/plan/research/quickstart/checklist) + set `.specify/feature.json` → `specs/dart-056-jaspr-inventory-sync-depth`

## Phase 2: Inventory sync controller + Settings (US1)

- [x] T002 [US1] Add `apps/web_host/lib/settings/inventory_sync_controller.dart` (WebOAuthSession + syncUserInventory + lookup builders + lastDiagnostics)
- [x] T003 [US1] Add `apps/web_host/lib/settings/inventory_sync_card.dart` (Sync now, meta, diagnostics)
- [x] T004 [US1] Wire controller into `app.dart` + `settings_page.dart` with `createWebEquipmentBucketLookupBuilder`
- [x] T005 [US1] Tests: `inventory_sync_controller_test.dart` vault resolve / drop without lookup; `inventory_sync_card_test.dart` smoke
- [x] T006 [US1] Extend `settings_page_test.dart` for sync surface / entity warning update

## Phase 3: Owned catalog (US2)

- [x] T007 [US2] Add `apps/web_host/lib/catalog/owned_catalog_bridge.dart`
- [x] T008 [US2] Extend `catalog_page.dart` All|Owned + badges + instance projections (instanceId)
- [x] T009 [US2] Wire bridge from App (db + session + inventorySync + entity catalog)
- [x] T010 [US2] Tests: `catalog_owned_page_test.dart`

## Phase 4: Docs + finish (US3)

- [x] T011 Update feature-gaps GAP-WEB-01 closed; GAP-INV-06 web residual closed; cutover RB-02 cleared + RC-SYNC note
- [x] T012 Update roadmap DART-056 done; packages/README note if needed
- [x] T013 Run `dart test` apps/web_host green (DART-056 suites; pre-existing flap_tokens_css_test failures unrelated)
- [x] T014 Commit; merge `--no-edit` into `feature/multiplatform-dart`; roadmap Current → DART-057; commit base
