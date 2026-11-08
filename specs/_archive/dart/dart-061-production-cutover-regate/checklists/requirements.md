# Requirements checklist: DART-061 production-cutover-regate

**Feature**: production-cutover-regate  
**Branch**: `dart-061-production-cutover-regate`  
**Date**: 2026-07-25

## Completeness

- [x] Spec scoped only to GAP-CUT-01 / PRODUCTION_CUTOVER GO / RC-* re-gate / RC-BRANCH
- [x] Out of scope lists main merge execution, dim.gg implement, product UI
- [x] Assumptions A1–A7 document defaults (no NEEDS CLARIFICATION retained)
- [x] Soft never auto-applies and no CLIENT_SECRET called out as non-regressions
- [x] GAP-FEAT-02 remains non-goal unless elevated

## Exit criteria coverage

- [x] All RC-* pass or product-waived with written note
- [x] PRODUCTION_CUTOVER: GO with date/rationale
- [x] RC-BRANCH allows merge toward production/main only after GO
- [x] GAP-CUT-01 closed
- [x] dim.gg / GAP-FEAT-02 non-goal (jsonOnly sufficient)
- [x] Offline re-gate for CI

## Quality

- [x] Parallel workstream IDs DART-NNN only
- [x] Finish-spec base remains feature/multiplatform-dart
- [x] No product 044+ IDs
