# Requirements checklist: DART-015 repos-library

**Feature**: `dart-015-repos-library`  
**Date**: 2026-07-24

## Completeness

- [x] Scope limited to builds/sets/synergies/variants (+ set items persistence) CRUD — no Bungie/inventory
- [x] Exit criteria explicit: round-trip fixtures; RESTRICT on set delete
- [x] Out of scope lists DART-016+ and UI
- [x] Assumptions documented (A1–A6)

## Clarity

- [x] User stories independently testable
- [x] RESTRICT semantics unambiguous vs CASCADE on variant delete
- [x] Soft guidance non-auto-apply restated

## Traceability

- [x] FR-001…010 map to plan/tasks/tests
- [x] Product TS repos cited as behavioral reference (not runtime dep)
