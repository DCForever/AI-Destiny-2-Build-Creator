# Requirements checklist: DART-027 app-use-cases-library

**Feature**: `dart-027-app-use-cases-library`  
**Date**: 2026-07-24

## Completeness

- [x] Scope limited to set/synergy CRUD + attach (in-process) — no HTTP/UI/build hard-gate pipeline
- [x] Exit criteria explicit: use cases call repos + pure domain; tests with in-memory/Drift
- [x] Out of scope lists DART-028+ UI and hard save pipeline
- [x] Assumptions documented (A1–A8)

## Clarity

- [x] User stories independently testable
- [x] Designation immutability and fashion max-one unambiguous
- [x] Soft guidance non-auto-apply restated

## Traceability

- [x] FR-001…012 map to plan/tasks/tests
- [x] Product TS setService / synergyService / attachmentService cited as behavioral reference (not runtime dep)
