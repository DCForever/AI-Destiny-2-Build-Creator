# Requirements Checklist: DART-065 Sets Board, Dense Rows, Slot Fill

**Purpose**: Validate spec completeness and exit criteria coverage  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Exit criteria map only GAP-UI-SETS-01, 02, 03, 07, 10
- [x] CHK002 Out of scope lists DART-066/067/068 items explicitly
- [x] CHK003 Soft never auto-applies + no CLIENT_SECRET stated
- [x] CHK004 Cutover GO unchanged stated

## Domain alignment

- [x] CHK005 DAC-NME-004 / BR-SET-010 / BR-SET-011 / DBR-STAT-008 for armor board
- [x] CHK006 BR-SLOT-006 replace confirm
- [x] CHK007 BR-ROLL-001 selectedPerks / trait display

## Testability

- [x] CHK008 Each user story has independent test path
- [x] CHK009 Parity-specific success (board totals, selectedPerks stored, Jaspr non-hash)
- [x] CHK010 PROC-06 residual for plug-def armor_stats documented

## Shells

- [x] CHK011 Windows Flutter in scope
- [x] CHK012 Jaspr web in scope (hash-only retired)
- [x] CHK013 Mobile sets polish out of scope
