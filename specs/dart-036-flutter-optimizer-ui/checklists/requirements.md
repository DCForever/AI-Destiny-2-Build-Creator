# Requirements Checklist: DART-036 Flutter Optimizer UI

**Purpose**: Validate scope and exit criteria before/during implement  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Exit criteria

- [x] CHK001 Find kits suggests combinations without writing sets
- [x] CHK002 Apply / Materialize require explicit user confirmation
- [x] CHK003 Cancel confirm leaves set items unchanged
- [x] CHK004 Confirm apply updates five armor slots (or materialize creates set)
- [x] CHK005 Soft goals never auto-apply kits
- [x] CHK006 Advisory caption states never silent apply

## Scope

- [x] CHK007 Workspace only for armor sets on Sets detail
- [x] CHK008 Empty-reason / errors surfaced
- [x] CHK009 No CLIENT_SECRET / no Node sidecar
- [x] CHK010 No equip/DIM / no later DART slices

## Tests

- [x] CHK011 Format unit tests
- [x] CHK012 Widget/controller tests: suggest-no-write, cancel, confirm-apply

## Notes

- Evidence: `flutter test test/optimizer_format_test.dart test/optimizer_workspace_test.dart` (18 passed)
