# Tasks: DART-054 Inventory Live Parity Harness

**Input**: Design documents from `/specs/dart-054-inventory-live-parity-harness/`

**Prerequisites**: plan.md, spec.md, research.md

## Phase 1: Setup

- [x] T001 Create `specs/dart-054-inventory-live-parity-harness/` artifacts and set `.specify/feature.json`

---

## Phase 2: Compare library + fixtures (US2)

- [x] T002 [P] [US2] Implement `tool/inventory_fidelity/snapshot.dart` (parse/serialize)
- [x] T003 [P] [US2] Implement `tool/inventory_fidelity/compare.dart` (tolerance, diffs, membership)
- [x] T004 [P] [US2] Add matching fixtures `tool/fixtures/inventory_fidelity/next_match.json` + `dart_match.json`
- [x] T005 [US2] Implement CLI `tool/inventory_fidelity_compare.dart`
- [x] T006 [US2] Write `tool/test/inventory_fidelity_compare_test.dart` (match, mismatch location/bucket/resolution, membership, malformed)

---

## Phase 3: Procedure doc + gate (US1, US3)

- [x] T007 [US1] Write `docs/multiplatform-dart-inventory-live-parity-harness.md` (dual-run, schema, tolerance, gate ≠ p0)
- [x] T008 [US3] Implement `tool/inventory_fidelity/markers.dart` + `tool/inventory_fidelity_gate.dart`
- [x] T009 [US3] Write `tool/test/inventory_fidelity_gate_test.dart`
- [x] T010 Run compare + gate tests green; run `dart run tool/inventory_fidelity_gate.dart`

---

## Phase 4: Cutover / gaps (US4)

- [x] T011 [US4] Update cutover checklist RC-SYNC evidence + clear RB-06; keep honest RC-SYNC status if RB-02 remains
- [x] T012 [US4] Update feature-gaps: GAP-INV-05 closed, PROC-03/04/05 closed, FEAT-INV-HARNESS shipped
- [x] T013 [P] Write `specs/dart-054-inventory-live-parity-harness/quickstart.md`
- [x] T014 Ensure cutover validator still green

---

## Phase 5: Finish

- [x] T015 Mark tasks complete; update roadmap DART-054 **done**; Current pointer → DART-055; commit + merge to `feature/multiplatform-dart`

---

## Dependencies & Execution Order

- T001 → T002–T006 → T007–T010 → T011–T014 → T015
- T002/T003/T004 may parallelize after T001

## Notes

- Soft never auto-applies; no CLIENT_SECRET
- Do not implement DART-055+ in this branch
- Inventory fidelity gate must remain separate from p0_parity_gate
- Evidence: `dart test tool/test/inventory_fidelity_*.dart` (+ cutover validator) → all passed; `dart run tool/inventory_fidelity_gate.dart` → PASS
