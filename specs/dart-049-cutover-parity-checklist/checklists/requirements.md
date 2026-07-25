# Requirements Checklist: DART-049 Cutover Parity Checklist

**Purpose**: Validate scope and exit criteria for cutover parity checklist / P5 program gate  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Exit criteria

- [x] CHK001 Checklist in repo at `docs/multiplatform-dart-cutover-parity-checklist.md`
- [x] CHK002 Explicit dual go/no-go (`PROGRAM_GATE` + `PRODUCTION_CUTOVER`)
- [x] CHK003 Next retirement criteria (`RC-*`) documented
- [x] CHK004 Production nav matrix covers AppShell keys
- [x] CHK005 Validator test green
- [x] CHK006 P5 / program gate closed on roadmap (DART-049 done)

## Architecture / hard rules

- [x] CHK007 Pure Dart I/O only for tooling; no Node sidecar
- [x] CHK008 No CLIENT_SECRET in clients (non-regression criterion)
- [x] CHK009 Soft guidance never auto-applies (non-regression criterion)
- [x] CHK010 Next not deleted / main not force-cutover in this slice

## Scope control

- [x] CHK011 No new compose/equip UI features
- [x] CHK012 Non-goals marked N/A (debug, LLM primary, dim.gg, Flutter Web)

## Notes

- Evidence: `dart test tool/test/cutover_parity_checklist_validate_test.dart` (7 green); `PROGRAM_GATE: GO` / `PRODUCTION_CUTOVER: NO-GO` with residual RB-01…05
