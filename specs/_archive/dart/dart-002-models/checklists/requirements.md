# Requirements Checklist: DART-002 Models

**Purpose**: Validate spec completeness and exit criteria for pure domain models only  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Scope limited to pure DTOs/models (no evaluator algorithms)
- [x] CHK002 Out of scope lists DART-003+ and IO/UI explicitly
- [x] CHK003 Integration base is `feature/multiplatform-dart` (not main)

## Exit criteria coverage

- [x] CHK004 Pins / pin status / equip-ready shapes (FR-002)
- [x] CHK005 Claims / resolved equipment (FR-001)
- [x] CHK006 Kits (subclass, ability, exotic, mod energy) (FR-003)
- [x] CHK007 Coverage results (FR-005)
- [x] CHK008 Failure codes (FR-004)
- [x] CHK009 Build/variant/set/synergy shapes (FR-006)
- [x] CHK010 Zero IO in models package (FR-007, SC-002)

## Architecture alignment

- [x] CHK011 Pure domain path matches multiplatform-dart-port-decisions.md
- [x] CHK012 Soft vs hard types kept distinct (FR-009)
- [x] CHK013 Wire-name parity for slots/set types (FR-008)
- [x] CHK014 No Node sidecar / no CLIENT_SECRET

## Clarity

- [x] CHK015 No NEEDS CLARIFICATION markers retained
- [x] CHK016 Assumptions document freezed-equivalent and models-in-domain placement

## Notes

- Checklist completed at specify time for implementer gate.
