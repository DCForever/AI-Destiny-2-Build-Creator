# Requirements Checklist: DART-003 Hard Constraints

**Purpose**: Validate spec completeness and exit criteria for pure hard evaluators only  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Scope limited to pure hard evaluators (exotic limits, mod energy, subclass kit, exotic ability match, synergy requirement, merge)
- [x] CHK002 Out of scope lists soft coverage, resolve, equip, optimizer, IO/UI, static tables
- [x] CHK003 Integration base is `feature/multiplatform-dart` (not main)

## Exit criteria coverage

- [x] CHK004 Golden tests vs TS fixtures (FR-009, SC-001)
- [x] CHK005 Hard-block codes stable / TS parity (FR-008, SC-002)
- [x] CHK006 capacityResolved semantics documented (FR-004, SC-003)
- [x] CHK007 Soft never auto-applies; evaluators return envelopes only (FR-010)
- [x] CHK008 No IO/UI deps in domain pubspec (FR-011, SC-005)

## Architecture alignment

- [x] CHK009 Pure domain first path matches multiplatform-dart-port-decisions.md
- [x] CHK010 No Node sidecar introduced
- [x] CHK011 No CLIENT_SECRET / confidential auth in clients
- [x] CHK012 Soft guidance never auto-applies; hard DBR blocks stay hard

## Clarity

- [x] CHK013 No NEEDS CLARIFICATION markers retained in spec
- [x] CHK014 Assumptions document synergy inclusion and deferred exotic requirement tables

## Notes

- Requirements checklist completed at specify time for implementer gate.
