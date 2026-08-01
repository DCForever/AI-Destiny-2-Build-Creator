# Requirements Checklist: DART-014 Drift Migrations

**Purpose**: Validate specification completeness for Drift migration strategy  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Scope limited to migrations strategy, version table, empty→current, ensure* port
- [x] CHK002 Out of scope excludes repos, full import UX, Flutter host, WASM, new columns
- [x] CHK003 Depends on DART-013; pure packages stay pure

## Requirements coverage

- [x] CHK004 FR-001 documented version table
- [x] CHK005 FR-002 empty→current green
- [x] CHK006 FR-003 idempotent ensure upgrades
- [x] CHK007 FR-004 MigrationStrategy wiring
- [x] CHK008 FR-005 re-run safe
- [x] CHK009 FR-006 pure packages free of Drift
- [x] CHK010 FR-007 no sidecar / no CLIENT_SECRET
- [x] CHK011 FR-008 soft never auto-applies
- [x] CHK012 FR-009 no CRUD / full import

## Success criteria

- [x] CHK013 SC measurable (tests, docs, merge base)
- [x] CHK014 Assumptions A1–A5 documented

## Notes

- Soft guidance never auto-applies; hard DBR blocks remain domain-only.
- Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET in clients.
