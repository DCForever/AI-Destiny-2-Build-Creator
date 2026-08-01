# Tasks: DART-014 Drift Migrations

**Input**: Design documents from `/specs/dart-014-drift-migrations/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Empty→current + ensure upgrades required (constitution Test-First).

## Phase 1: Setup

- [x] T001 Update `.specify/feature.json` `feature_directory` to `specs/dart-014-drift-migrations`
- [x] T002 Confirm branch `dart-014-drift-migrations` from `feature/multiplatform-dart`

---

## Phase 2: Foundational — version table + ensure API

- [x] T003 [P] Add `packages/db/lib/src/migration_version_table.dart` (Drift v1 + ensure step catalog)
- [x] T004 Add `packages/db/lib/src/ensure_upgrades.dart` (executor interface + applyEnsureUpgrades mirroring product ensure*)
- [x] T005 Wire `MigrationStrategy` in `packages/db/lib/src/app_database.dart` (onCreate, onUpgrade stub, beforeOpen FK + ensure)
- [x] T006 Export new modules from `packages/db/lib/destiny2_db.dart`

**Checkpoint**: Package analyzes

---

## Phase 3: User Story 1 — Empty → current (P1) 🎯 MVP

**Goal**: New DB lands on current schema with late columns  
**Independent Test**: migration_test empty open

- [x] T007 [US1] Write empty→current migration tests in `packages/db/test/migration_test.dart`
- [x] T008 [US1] Confirm late columns present after memory open; schema_test still green

**Checkpoint**: US1 green

---

## Phase 4: User Story 2 — Documented version table (P1)

**Goal**: Catalog matches product ensure* list  
**Independent Test**: catalog completeness test

- [x] T009 [US2] Assert ensureStepCatalog IDs / product function names in tests
- [x] T010 [US2] Align `data-model.md` / schema_notes cross-link if needed

**Checkpoint**: US2 green

---

## Phase 5: User Story 3 — Partial ensure upgrades (P1)

**Goal**: Missing columns healed idempotently  
**Independent Test**: partial inventory/synergies fixtures

- [x] T011 [US3] Partial schema fixtures + applyEnsureUpgrades tests
- [x] T012 [US3] Idempotent second-run test

**Checkpoint**: US3 green

---

## Phase 6: Polish & finish

- [x] T013 Run `dart test packages/db`; pure graph guard still green
- [x] T014 Mark all tasks [x]; commit remaining work
- [x] T015 Checkout `feature/multiplatform-dart`; merge `dart-014-drift-migrations` --no-edit
- [x] T016 Update `docs/multiplatform-dart-slice-roadmap.md` (DART-014 done, pointer → DART-015); commit on base

---

## Dependencies & Execution Order

- Setup → Foundational → US1 → US2 → US3 → Polish/finish
- Finish-spec merges **only** onto `feature/multiplatform-dart`

## Implementation Strategy

1. Version table + ensure port  
2. Wire MigrationStrategy  
3. Empty→current tests  
4. Partial ensure tests  
5. Merge + roadmap  
