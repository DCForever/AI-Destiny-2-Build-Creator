# Tasks: DART-060 Dual-Run + Rollback Ops

**Input**: Design documents from `/specs/dart-060-dual-run-rollback-ops/`

**Prerequisites**: plan.md, spec.md, research.md

**Tests**: Test-first where practical; mark complete only with green evidence.

## Phase 1: Setup

- [x] T001 Write specs (spec/plan/research/quickstart/checklist) + set `.specify/feature.json` → `specs/dart-060-dual-run-rollback-ops`

## Phase 2: Runbook + gate (US1, US3)

- [x] T002 [US1] Publish `docs/multiplatform-dart-dual-run-rollback-runbook.md` (dual-run, compose→equip, ROLLBACK_PROCEDURE, markers)
- [x] T003 [US1] Add `tool/dual_run_ops/markers.dart` + `tool/dual_run_ops_gate.dart`
- [x] T004 [US1] Tests `tool/test/dual_run_ops_gate_test.dart`; gate fails without markers

## Phase 3: Execute once + re-verify (US2)

- [x] T005 [US2] Re-run compose→equip automated evidence (Windows equip/DIM tests; web equip/DIM tests; pure equip-ready)
- [x] T006 [US2][US3] Fill EXECUTION_NOTES in runbook (dated EXECUTED_ONCE, shells, re-verify results, rollback confirmation)

## Phase 4: Cutover / gaps (US3)

- [x] T007 [US3] Update cutover checklist: RB-04 cleared, RC-OPS PASS + execution notes link; PRODUCTION_CUTOVER stays NO-GO
- [x] T008 Close GAP-OPS-01 in feature-gaps; update FEAT-OPS-DUAL-RUN shipped
- [x] T009 Ensure cutover validator still green; dual_run_ops_gate green

## Phase 5: Finish

- [x] T010 Update roadmap DART-060 done; Current → DART-061
- [x] T011 Mark tasks complete; commit; merge `--no-edit` into `feature/multiplatform-dart`; commit base

## Dependencies & Execution Order

- T001 → T002–T004 → T005–T006 → T007–T009 → T010–T011

## Notes

- Soft never auto-applies; no CLIENT_SECRET
- Do not implement DART-061 in this branch
- Inventory dual-run remains DART-054 (link only)

## Evidence (2026-07-25)

```text
dart test tool/test/dual_run_ops_gate_test.dart tool/test/cutover_parity_checklist_validate_test.dart  → All tests passed
dart run tool/dual_run_ops_gate.dart → OK
dart run tool/client_secret_scan.dart → OK
dart test packages/domain/test --name equip → green (equip_ready, equip_plan, dim)
apps/web_host equip/DIM tests → 15 green
apps/windows_host equip/DIM tests → 18 green
```
