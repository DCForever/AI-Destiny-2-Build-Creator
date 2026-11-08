# Requirements Checklist: DART-067

**Purpose**: Validate slice exit criteria for finish walkthrough, armor improve, post-sync banner  
**Created**: 2026-07-25  
**Feature**: [spec.md](../spec.md)

## Gaps

- [x] CHK001 GAP-UI-BUILD-03: one-tap Create/Capture/fill on Windows + Jaspr
- [x] CHK002 GAP-UI-BUILD-04: Windows Build Finish Find kits → confirm apply
- [x] CHK003 GAP-UI-SETTINGS-04: Windows post-sync Confirm/Dismiss only

## Safety

- [x] CHK004 Soft / kit suggestions never auto-apply
- [x] CHK005 No CLIENT_SECRET in clients
- [x] CHK006 PRODUCTION_CUTOVER not re-opened

## Rules

- [x] CHK007 BR-BLD-008 slot-first Create/Capture/fill
- [x] CHK008 BR-BLD-009 Finish Armor improve confirm path (Windows)
- [x] CHK009 BR-OPT-004 post-sync suggest-then-confirm

## Tests

- [x] CHK010 createSetAndAttach / capture use-case tests
- [x] CHK011 detectImprovement + improvement suggestions tests
- [x] CHK012 Host tests: Finish actions + post-sync banner no auto-apply
