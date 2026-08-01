# Research: DART-041 Flutter Mobile Compose

**Date**: 2026-07-25  
**Slice**: DART-041 / P4 phase gate

## Decisions

### R1 — Sheets + linear detail (not dual-pane)

**Decision**: Create and attach use `showModalBottomSheet`; compose is one scrolling Focus Swap detail.  
**Rationale**: Roadmap “reduced-density compose on phone (sheets, linear finish)”; DESIGN Focus Swap already on DART-040.  
**Alternatives rejected**: Port Windows dual-pane; add permanent Catalog/Sets tabs (later).

### R2 — Extend BuildsController vs new controller

**Decision**: Extend `BuildsController` with compose/soft APIs (local-library only).  
**Rationale**: Avoid OAuth/session coupling from Windows `BuildsLibraryController`; single injectable controller for tests.  
**Alternatives rejected**: Depend on windows_host package; duplicate second controller type without need.

### R3 — Soft guidance display-only

**Decision**: Same DBR-GUID rules as DART-034: `queryVariantCoverage` never writes kit; soft targets only via explicit `saveSoftStatTargets`.  
**Rationale**: Port decisions + exit criterion “soft guidance”; P4 gate must not regress hard/soft separation.

### R4 — Attach prefers non-default in tests

**Decision**: Document and test attach primarily on non-default variants (default completeness hard-gate).  
**Rationale**: Matches Windows DART-033 test practice and product hard rules.

### R5 — Format helpers copied locally

**Decision**: `variant_compose_format.dart` + `soft_guidance_format.dart` live under mobile_host (same pure logic as Windows).  
**Rationale**: Shells must not import each other; pure helpers are small.

## Open items resolved by assumption

- No mobile catalog: attachable sets = `listUserSets` only.
- Soft estimate optional (`softStatEstimateOverride` for tests); null estimate → empty warnings.

## References

- `docs/multiplatform-dart-port-decisions.md` (D-PATH mobile density, soft never auto-apply)
- `specs/dart-033-flutter-variant-compose-ui/`, `dart-034-flutter-soft-guidance-ui/`, `dart-040-flutter-mobile-shell-nav/`
