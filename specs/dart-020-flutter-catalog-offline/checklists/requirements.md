# Requirements Checklist: DART-020 Flutter Catalog Offline

**Purpose**: Validate spec completeness and testability for offline catalog facets/browse  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope & exit criteria

- [x] CHK001 Scope limited to offline facets + browse from entity stores (no inventory/OAuth)
- [x] CHK002 Exit criteria: browse/filter without inventory; P1 phase gate
- [x] CHK003 Out of scope lists DART-026 owned mode and later UI polish
- [x] CHK004 Soft guidance never auto-applies; no CLIENT_SECRET

## User stories

- [x] CHK005 US1 pure filter independently testable with fixtures
- [x] CHK006 US2 offline projection from entity stores independently testable
- [x] CHK007 US3 Flutter Catalog UI independently testable with injectable service

## Requirements quality

- [x] CHK008 FR-001–008 are testable and non-ambiguous
- [x] CHK009 Facet semantics documented (AND across / OR include / exclude drops)
- [x] CHK010 owned always false documented for this slice
- [x] CHK011 Assumptions A1–A7 remove NEEDS CLARIFICATION

## Success criteria

- [x] CHK012 SC measurable via dart test / flutter test
- [x] CHK013 P1 phase gate called out explicitly
