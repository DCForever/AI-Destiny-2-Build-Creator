# Tasks: DART-049 Cutover Parity Checklist

**Input**: Design documents from `/specs/dart-049-cutover-parity-checklist/`

**Prerequisites**: plan.md, spec.md, research.md

## Phase 1: Setup

- [x] T001 Create `specs/dart-049-cutover-parity-checklist/` artifacts (spec/plan/research/tasks/checklist/quickstart) and set `.specify/feature.json` → `specs/dart-049-cutover-parity-checklist`

---

## Phase 2: Canonical checklist (US1–US3)

- [x] T002 [P] [US1] Write `docs/multiplatform-dart-cutover-parity-checklist.md` with production nav parity matrix (AppShell keys × Windows/mobile/web)
- [x] T003 [P] [US1] Add capability matrix (intent→compose→soft→equip-ready→equip/DIM→auth/sync→import→domain hard/soft)
- [x] T004 [US2] Add dual verdict section with `PROGRAM_GATE:` and `PRODUCTION_CUTOVER:` markers + residual blockers
- [x] T005 [US3] Add Next retirement criteria `RC-*` with pass conditions and evidence pointers
- [x] T006 [P] Mark non-goals (`/debug/*`, LLM primary, dim.gg, Flutter Web, Node sidecar) as N/A

---

## Phase 3: Validator (FR-007)

- [x] T007 Implement `tool/cutover_parity_checklist_validate.dart` (required headings + markers)
- [x] T008 Write `tool/test/cutover_parity_checklist_validate_test.dart`
- [x] T009 Run validator tests — green

---

## Phase 4: Finish

- [x] T010 Write `specs/dart-049-cutover-parity-checklist/quickstart.md`
- [x] T011 Mark tasks complete; update roadmap row DART-049 **done**; Current pointer program complete; commit + merge to `feature/multiplatform-dart`

---

## Dependencies & Execution Order

- T001 → T002–T006 → T007–T009 → T010–T011
- T002/T003/T006 may parallelize after T001

## Notes

- Soft never auto-applies; no CLIENT_SECRET
- Do not implement residual product gaps in this branch
- Honest PRODUCTION_CUTOVER NO-GO is success if PROGRAM_GATE is GO
- Evidence: `dart test tool/test/cutover_parity_checklist_validate_test.dart` → 7 passed
