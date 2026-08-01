# Requirements Checklist: DART-055 In-Game Loadouts Surface

**Purpose**: Validate spec completeness for GAP-NAV-01 / RB-01 / RC-NAV  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Scope

- [x] CHK001 Exit criteria limited to in-game loadouts surface (not DART-056+)
- [x] CHK002 Windows-first UI + Jaspr route called out
- [x] CHK003 Product demote path documented as alternate not chosen
- [x] CHK004 Mobile reduced nav explicitly out of scope for RC-NAV

## Parity

- [x] CHK005 Component 206 parse parity with Next characterLoadouts
- [x] CHK006 Presentation tables DestinyLoadout* already in downloadRawTables
- [x] CHK007 Filters: class + hide empty

## Non-goals / constraints

- [x] CHK008 Soft never auto-applies
- [x] CHK009 No CLIENT_SECRET / Node sidecar
- [x] CHK010 Local generated loadout library deferred

## Cutover

- [x] CHK011 RB-01 / RC-NAV / GAP-NAV-01 update path defined
- [x] CHK012 Host greps for Loadouts nav/routes required

## Notes

- Ship UI (not demote) per A1.
