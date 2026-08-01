# Requirements checklist — DART-062 catalog-browse-semantics

**Feature**: DART-062  
**Branch**: `dart-062-catalog-browse-semantics`  
**Updated**: 2026-07-25

## Completeness

- [x] Scope limited to GAP-UI-CATALOG-01, 02, 04, 05, 07
- [x] Out of scope lists DART-063/068 residuals
- [x] Assumptions documented (A1–A8)
- [x] Soft never auto-applies; no CLIENT_SECRET; pure Dart I/O
- [x] Cutover GO unchanged stated
- [x] Exit criteria parity-specific (defs, facets, group-by, alpha)

## Domain alignment

- [x] DAC-NME-003 multi-facet OR/AND/exclude
- [x] BR-CAT-001 exotic+legendary weapons defs
- [x] BR-CAT-003 legendary+exotic armor defs
- [x] BR-CAT-006 facet semantics
- [x] BR-CAT-007 group-by without filter replace
- [x] DBR-ROLL-010 affirmed via catalog facets

## Testability

- [x] Pure unit tests for filter sort, group-by, extractors
- [x] Windows Catalog widget tests for new facets / group
- [x] Jaspr Catalog component tests for new facets / group
- [x] Bundle fixtures include exotic weapons + legendary armor samples

## Non-goals verified

- [x] No Universal mode
- [x] No synergy membership host wiring
- [x] No owned instance perk cards
- [x] No cutover re-gate
