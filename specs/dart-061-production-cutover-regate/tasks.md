# Tasks: DART-061 Production Cutover Re-Gate

**Input**: Design documents from `/specs/dart-061-production-cutover-regate/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first where practical; mark complete only with green evidence.

## Phase 1: Setup

- [x] T001 Write specs (spec/plan/research/quickstart/checklist) + set `.specify/feature.json` → `specs/dart-061-production-cutover-regate`

## Phase 2: Re-gate tool (US1, US2)

- [x] T002 [US1][US2] Add `tool/production_cutover/markers.dart` + `tool/production_cutover_regate.dart`
- [x] T003 [US1] Tests `tool/test/production_cutover_regate_test.dart`; gate fails without GO / RC PASS markers

## Phase 3: Cutover verdict + branch policy (US2, US3)

- [x] T004 [US2] Update cutover checklist: PRODUCTION_CUTOVER GO + date/rationale; all RC-* PASS including RC-BRANCH; residual formal GO
- [x] T005 [US3] Update branching.md RC-BRANCH merge-after-GO policy
- [x] T006 [US3] Keep GAP-FEAT-02 non-goal; close GAP-CUT-01; FEAT-OPS-CUTOVER shipped in feature-gaps
- [x] T007 Update port-decisions open cutover item to GO reference

## Phase 4: Validate

- [x] T008 Run production_cutover_regate + cutover validator + dual_run_ops_gate + inventory_fidelity_gate + client_secret_scan

## Phase 5: Finish

- [x] T009 Update roadmap DART-061 done; Current pointer program complete
- [ ] T010 Mark tasks complete; commit; merge `--no-edit` into `feature/multiplatform-dart`; commit base

## Dependencies & Execution Order

- T001 → T002–T003 → T004–T007 → T008 → T009–T010

## Notes

- Soft never auto-applies; no CLIENT_SECRET
- Do not merge to main in this slice
- Do not implement dim.gg share

## Evidence (2026-07-25)

```text
dart test tool/test/production_cutover_regate_test.dart tool/test/cutover_parity_checklist_validate_test.dart tool/test/dual_run_ops_gate_test.dart  → All tests passed
dart run tool/production_cutover_regate.dart → OK (PRODUCTION_CUTOVER: GO; all RC-* PASS)
dart run tool/dual_run_ops_gate.dart → OK
dart run tool/client_secret_scan.dart → OK
dart run tool/inventory_fidelity_gate.dart → PASSED
dart run tool/cutover_parity_checklist_validate.dart → OK
```
