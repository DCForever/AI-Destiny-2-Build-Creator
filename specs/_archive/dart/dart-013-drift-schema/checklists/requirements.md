# Requirements Checklist: DART-013 Drift Schema

**Purpose**: Validate specification completeness for Drift schema mirroring core tables  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Scope limited to Drift schema + clean create + unique/index notes
- [x] CHK002 Out of scope excludes migrations history, repos, Flutter host, WASM/OPFS, legacy import
- [x] CHK003 Depends on DART-012; pure packages stay pure

## Requirements coverage

- [x] CHK004 FR-001 workspace `destiny2_db` package
- [x] CHK005 FR-002 clean create of core tables
- [x] CHK006 FR-003 foreign_keys ON
- [x] CHK007 FR-004 critical uniques
- [x] CHK008 FR-005 supporting inventory/attachment indexes
- [x] CHK009 FR-006 memory + file factories
- [x] CHK010 FR-007 PRAGMA/index documentation
- [x] CHK011 FR-008 pure packages free of Drift
- [x] CHK012 FR-009 no full CRUD repos
- [x] CHK013 FR-010 no secrets / no sidecar / soft never auto-applies

## Success criteria

- [x] CHK014 SC measurable (tests, docs, workspace, no scope bleed)
- [x] CHK015 Assumptions A1–A4 documented (current product columns; loadouts parity; native sqlite3 tests; index name mapping)

## Notes

- Soft guidance never auto-applies; hard DBR blocks remain in domain evaluators only.
- Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET in clients.
