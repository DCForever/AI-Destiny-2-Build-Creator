# Requirements Checklist: DART-048 Legacy DB Import

**Purpose**: Validate scope and exit criteria for legacy Next `app.db` → StorageRoot import  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Exit criteria

- [x] CHK001 One documented migration path in `docs/multiplatform-dart-legacy-db-import.md`
- [x] CHK002 Dry-run API validates source and reports counts / canApply
- [x] CHK003 Apply API backups target, copies source, runs ensure* open
- [x] CHK004 Automated tests cover dry-run + apply
- [x] CHK005 Windows Settings UX for dry-run + apply with confirm

## Architecture / hard rules

- [x] CHK006 Pure Dart I/O only (no Node sidecar)
- [x] CHK007 Destination is StorageRoot app-support `app.db`, not repo `.cache` as production root
- [x] CHK008 No CLIENT_SECRET in importer or Settings card
- [x] CHK009 Soft guidance never auto-applies (import is data-only)

## Scope control

- [x] CHK010 No merge import / no DART-049 cutover checklist work in this slice
- [x] CHK011 Web OPFS picker deferred (documented)

## Notes

- Evidence: `dart test packages/db` (55 incl. 8 import); `flutter test` legacy import controller+card (5)
