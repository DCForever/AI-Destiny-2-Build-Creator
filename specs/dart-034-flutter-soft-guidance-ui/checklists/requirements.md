# Requirements Checklist: DART-034 Flutter Soft Guidance UI

**Purpose**: Verify functional requirements and exit criteria for soft guidance UI  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Exit criteria

- [x] CHK001 Soft coverage chips show supported/weak/missing for designated synergies
- [x] CHK002 Soft stat targets display + explicit save
- [x] CHK003 Soft never auto-applies attachments/pins/targets
- [x] CHK004 P3 phase gate: compose without equip (soft guidance display on compose path)

## Functional requirements

- [x] CHK005 FR-001 queryVariantCoverage on selected variant
- [x] CHK006 FR-002 synergy tier chips
- [x] CHK007 FR-003 set-bonus / element soft rows when present
- [x] CHK008 FR-004 soft stat targets explicit save
- [x] CHK009 FR-005 no auto-apply / no soft hard-block
- [x] CHK010 FR-006 advisory caption
- [x] CHK011 FR-007 no CLIENT_SECRET / pure Dart I/O
- [x] CHK012 FR-008 tests cover chips, targets, non-auto-apply

## Notes

- Evidence: `flutter test test/soft_guidance_format_test.dart test/soft_guidance_page_test.dart` (18 passed) + builds/compose regression suite green.
