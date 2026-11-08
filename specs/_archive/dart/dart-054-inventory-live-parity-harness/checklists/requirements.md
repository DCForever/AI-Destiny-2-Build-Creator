# Requirements Checklist: DART-054 Inventory Live Parity Harness

**Purpose**: Validate spec completeness against GAP-INV-05 / PROC-03/04/05 exit criteria  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Scope & process

- [x] CHK001 Scope limited to harness/docs/gate — no new vault algorithm or host UI
- [x] CHK002 Exit criteria map to GAP-INV-05, PROC-03, PROC-04, PROC-05
- [x] CHK003 Soft never auto-applies; no CLIENT_SECRET
- [x] CHK004 Pure Dart I/O only; no Node sidecar / live tokens in CI

## Dual-run & tool

- [x] CHK005 Dual-run procedure doc required (FR-001)
- [x] CHK006 Snapshot schema includes byLocation/byBucket + resolution metrics (FR-002)
- [x] CHK007 Compare tool + tolerance policy documented (FR-003, A1)
- [x] CHK008 Offline fixture gate separate from p0_parity_gate (FR-004, PROC-05)

## Cutover & residuals

- [x] CHK009 RC-SYNC fidelity evidence update (PROC-04)
- [x] CHK010 RB-06 clearance when combined with DART-050–053 evidence
- [x] CHK011 GAP-INV-05 / PROC-03 closed on finish

## Notes

- Live Bungie dual-run is operator evidence; CI uses fixtures only (A2).
