# Requirements Checklist: DART-029 Flutter Design Tokens

**Purpose**: Validate spec completeness and exit criteria coverage  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope & exit criteria

- [x] CHK001 Scope limited to tokens + FlapBoard layout contracts + Windows theme stub (no full brand rewrite)
- [x] CHK002 “Documented tokens” covered by US1 + FR-005
- [x] CHK003 FlapBoard layout contracts covered by US2 + FR-004
- [x] CHK004 “Windows theme stub without Material-card default” covered by US3 + FR-006/007
- [x] CHK005 Full FlapRow widget library and Jaspr CSS deferred (out of scope)

## Requirements quality

- [x] CHK006 Pure Dart token package (no Flutter runtime) stated (A1, FR-001)
- [x] CHK007 DESIGN.md / globals.css hex parity required under test
- [x] CHK008 Card widgets may remain; theme overrides Material defaults (A2)
- [x] CHK009 Out of scope lists DART-030+ compose UI and DART-042 Jaspr tokens

## Testing

- [x] CHK010 `dart test packages/ui_tokens` required
- [x] CHK011 Windows host theme test for card elevation/radius required

## Notes

- Implementation must not expand into DART-030 Sets library UI or full brand rewrite.
