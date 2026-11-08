# Requirements Checklist: DART-033 Flutter Variant Compose UI

**Purpose**: Verify functional requirements and exit criteria for variant compose  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Exit criteria

- [x] CHK001 Attach set to selected variant and see attachment listed
- [x] CHK002 Pin slot shows wishlist vs instance and can toggle
- [x] CHK003 Slot conflict on dual-primary attach is surfaced as error
- [x] CHK004 Create/select non-default variant works

## Functional requirements

- [x] CHK005 FR-001 Variant list + select on build detail
- [x] CHK006 FR-002 Create variant via `createUserVariant`
- [x] CHK007 FR-003 Attach set with hard gates
- [x] CHK008 FR-004 Detach set
- [x] CHK009 FR-005 Slot pin labels wishlist | instance
- [x] CHK010 FR-006 Pin/clear instance on live set items
- [x] CHK011 FR-007 Hard errors surfaced; soft never auto-applies
- [x] CHK012 FR-008 No CLIENT_SECRET / no Node sidecar
- [x] CHK013 FR-009 Tests cover attach, pin, conflict

## Notes

- Evidence: `flutter test test/variant_compose_format_test.dart test/variant_compose_page_test.dart` (+ builds suite green).
