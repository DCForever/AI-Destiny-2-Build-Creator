# Requirements checklist: DART-060 dual-run-rollback-ops

**Feature**: dual-run-rollback-ops  
**Branch**: `dart-060-dual-run-rollback-ops`  
**Date**: 2026-07-25

## Completeness

- [x] Spec scoped only to GAP-OPS-01 / RB-04 / RC-OPS exit criteria
- [x] Out of scope lists DART-061 cutover GO and product feature work
- [x] Assumptions A1–A6 document defaults (no NEEDS CLARIFICATION retained)
- [x] Soft never auto-applies and no CLIENT_SECRET called out as non-regressions

## Exit criteria coverage

- [x] Written dual-run runbook (Next + Dart web/Windows)
- [x] Executed once with execution notes
- [x] Live re-verify compose→equip (equip-ready, equip partial OK, DIM jsonOnly)
- [x] Rollback = keep Next sole production
- [x] Notes attached to cutover checklist
- [x] RC-OPS PASS / RB-04 cleared / GAP-OPS-01 closed

## Quality

- [x] Offline gate for CI (markers + shells + notes)
- [x] PRODUCTION_CUTOVER remains NO-GO
- [x] Parallel workstream IDs DART-NNN only
