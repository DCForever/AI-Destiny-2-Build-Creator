# Requirements Checklist: DART-028 App Use Cases Build

**Purpose**: Validate spec completeness and exit criteria coverage  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope & exit criteria

- [x] CHK001 Scope limited to build/variant save pipeline + soft coverage query (no Flutter UI)
- [x] CHK002 Illegal kits hard-block captured in US1/US2
- [x] CHK003 Soft misses do not block non-default captured in US2/US3
- [x] CHK004 Soft never auto-applies stated in assumptions + FR-010
- [x] CHK005 Hard gate order documented (identity then equipment resolve path)

## Requirements quality

- [x] CHK006 FR list testable and mapped to pure domain codes
- [x] CHK007 Injectable ports for manifest-backed data documented (A4)
- [x] CHK008 Rollback parity for failed equipment saves documented (FR-007)
- [x] CHK009 Out of scope lists later DART slices explicitly

## Testing

- [x] CHK010 In-memory Drift required
- [x] CHK011 Acceptance scenarios cover create block, equipment conflict, soft query non-block

## Notes

- Implementation must not expand into DART-029+ UI or equip slices.
