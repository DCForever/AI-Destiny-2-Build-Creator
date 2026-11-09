# Requirements Checklist: DART-012 Storage Root

**Purpose**: Validate specification completeness for StorageRoot + Windows app-support layout  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Scope limited to StorageRoot abstraction, Windows path_provider layout docs, fake-FS unit tests
- [x] CHK002 Out of scope excludes Drift open, manifest refresh, Flutter app shell, legacy import
- [x] CHK003 Depends on DART-011 called out; pure packages stay pure

## Requirements coverage

- [x] CHK004 FR-001 workspace storage package + StorageRoot type
- [x] CHK005 FR-002 paths for app.db, manifest, entities, users, current-version
- [x] CHK006 FR-003 version dir sanitization
- [x] CHK007 FR-004 Windows app-support construction documented (path_provider host step)
- [x] CHK008 FR-005 no CWD/`.cache` production default
- [x] CHK009 FR-006 unit tests with fake/injected base path
- [x] CHK010 FR-007 paths documented
- [x] CHK011 FR-008 pure packages remain free of storage/path_provider deps
- [x] CHK012 FR-009 no SQLite/manifest/app shells in this slice

## Success criteria

- [x] CHK013 SC measurable (tests, docs, no `.cache` default, workspace resolve + pure guard)
- [x] CHK014 Assumptions document path_provider injection and segment naming

## Notes

- Soft guidance never auto-applies; hard DBR blocks remain in domain evaluators only.
- Pure Dart I/O only; no Node sidecar; no CLIENT_SECRET in clients.
