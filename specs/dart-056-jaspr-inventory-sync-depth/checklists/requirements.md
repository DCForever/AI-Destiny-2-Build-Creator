# Requirements Checklist: DART-056 Jaspr Inventory Sync Depth

**Purpose**: Validate spec completeness and exit criteria coverage  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Scope limited to Jaspr Settings sync + Owned catalog depth (not mobile / DART-057+)
- [x] CHK002 Exit criteria cite vault resolution + Owned pin depth (not only “sync button”)
- [x] CHK003 Soft never auto-applies; no CLIENT_SECRET; pure Dart I/O

## Functional

- [x] CHK004 FR-001 Settings sync wires equipmentBucketLookupBuilder
- [x] CHK005 FR-002 Diagnostics surface resolvedFromTransfer
- [x] CHK006 FR-003 Vault host tests fail without lookup / pass with lookup
- [x] CHK007 FR-004 All|Owned catalog scope
- [x] CHK008 FR-005 Instance projections with instanceId
- [x] CHK009 FR-008 Docs close GAP-WEB-01 / clear RB-02 / RC-SYNC

## Assumptions

- [x] CHK010 A1–A5 documented; no NEEDS CLARIFICATION retained
