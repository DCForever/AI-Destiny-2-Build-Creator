# Requirements checklist: DART-016 repos-inventory

**Feature**: `dart-016-repos-inventory`  
**Date**: 2026-07-24

## Completeness

- [x] Scope limited to inventory repo + full-replace + sync meta + busy lock — no Bungie network
- [x] Exit criteria explicit: composite unique; batch insert in one transaction; busy lock hook
- [x] Out of scope lists DART-024+ profile sync and UI
- [x] Assumptions documented (A1–A6)

## Clarity

- [x] User stories independently testable
- [x] Full-replace transaction contents unambiguous (upsert + orphan delete + meta + users.last_sync_at)
- [x] Soft guidance non-auto-apply restated

## Traceability

- [x] FR-001…010 map to plan/tasks/tests
- [x] Product `inventoryRepository.ts` + `syncLocks` cited as behavioral reference (not runtime dep)
