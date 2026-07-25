# Tasks: DART-048 Legacy DB Import

**Input**: Design documents from `/specs/dart-048-legacy-db-import/`

**Prerequisites**: plan.md, spec.md, research.md

## Phase 1: Setup

- [x] T001 Create `specs/dart-048-legacy-db-import/` artifacts (spec/plan/research/tasks/checklist/quickstart) and set `.specify/feature.json` → `specs/dart-048-legacy-db-import`

---

## Phase 2: Foundational (packages/db importer)

- [x] T002 [P] Add `packages/db/lib/src/legacy_import/` models + conditional export (`legacy_db_import.dart` / `_io` / `_stub`)
- [x] T003 Implement `LegacyDbImporter.dryRun` + `apply` in `legacy_db_import_io.dart` (sqlite3 read-only source; backup; copy; AppDatabase.file ensure*)
- [x] T004 Export legacy import API from `packages/db/lib/destiny2_db.dart`
- [x] T005 Write `packages/db/test/legacy_db_import_test.dart` (dry-run success/fail, apply + backup, ensure heal)
- [x] T006 Run `dart test` in `packages/db` — green

---

## Phase 3: User Story 3 — Windows Settings UX

- [x] T007 [P] Add `legacy_db_import_controller.dart` (injectable importer, phases, confirm flag)
- [x] T008 [P] Add `legacy_db_import_card.dart` UI (path field, Dry-run, Apply, report)
- [x] T009 Wire card into `settings_page.dart`
- [x] T010 Widget/unit tests for controller + card
- [x] T011 Run `flutter test` for new windows_host import tests — green

---

## Phase 4: Docs + CLI polish

- [x] T012 Write `docs/multiplatform-dart-legacy-db-import.md` (single migration path)
- [x] T013 Add `tool/legacy_db_import.dart` dry-run/apply CLI
- [x] T014 Write `specs/dart-048-legacy-db-import/quickstart.md`
- [x] T015 Mark tasks complete; update roadmap row on finish-spec merge

---

## Dependencies & Execution Order

- T001 → T002–T006 → T007–T011 → T012–T015
- T002/T007/T008 may parallelize after T001; apply logic (T003) before host wire if controller depends on types

## Notes

- Soft never auto-applies; no CLIENT_SECRET
- Do not implement DART-049 in this branch
