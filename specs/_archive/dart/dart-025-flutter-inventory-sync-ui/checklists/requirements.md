# Requirements Checklist: DART-025 Flutter Inventory Sync UI

**Purpose**: Validate spec completeness for Settings inventory sync card + busy/error UX  
**Created**: 2026-07-24  
**Feature**: [spec.md](../spec.md)

## Content quality

- [x] CHK001 Scope limited to Settings sync card + busy/error (no catalog owned mode)
- [x] CHK002 Depends DART-023 + DART-024 stated
- [x] CHK003 Out of scope lists DART-026 / equip / CLIENT_SECRET
- [x] CHK004 Assumptions document force-sync vs syncIfStale and ensureUser shape

## Requirements completeness

- [x] CHK005 FR for Sync now + Drift full-replace
- [x] CHK006 FR for busy + error UX
- [x] CHK007 FR for signed-out disabled path
- [x] CHK008 FR for 60s freshness display
- [x] CHK009 FR for no CLIENT_SECRET + soft never auto-applies
- [x] CHK010 FR for P2 phase gate documentation

## Acceptance

- [x] CHK011 US1 independent test with fake profile + memory DB
- [x] CHK012 US2 busy/error scenarios
- [x] CHK013 US3 freshness display scenarios

## Notes

- Implementation lives in `apps/windows_host` only; algorithm already in `destiny2_bungie` (DART-024).
