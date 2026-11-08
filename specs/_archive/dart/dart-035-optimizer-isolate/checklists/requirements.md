# Requirements Checklist: DART-035 Optimizer Isolate

**Purpose**: Validate spec completeness against exit criteria  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Exit criteria

- [x] CHK001 Run enumerate (optimize pipeline) specified
- [x] CHK002 Isolate / UI thread safe path specified
- [x] CHK003 Materialize Armor Set use case specified
- [x] CHK004 Confirm-only apply path (no silent write from optimize) specified

## Quality

- [x] CHK005 Scope excludes Flutter optimizer UI (DART-036)
- [x] CHK006 Soft never auto-applies; hard piece validation stays hard
- [x] CHK007 Assumptions documented (injected candidates; no auto mods this slice)
- [x] CHK008 Acceptance scenarios independently testable

## Notes

- Checklist filled at specify; implementation tasks track delivery in `tasks.md`.
