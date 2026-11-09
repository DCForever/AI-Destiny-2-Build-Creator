# Requirements checklist: DART-009 Static Sandbox Data

**Feature**: `dart-009-static-sandbox-data`  
**Updated**: 2026-07-24

## Completeness

- [x] Scope limited to pure constants package + update process (no UI/IO/meta pack)
- [x] User stories cover core tables, supporting tables, update process
- [x] Functional requirements FR-001–FR-008 map to exit criteria
- [x] Success criteria testable via `dart test packages/sandbox_data`
- [x] Assumptions documented (separate package; soft-only; meta deferred)

## Domain alignment

- [x] Soft tables never auto-apply / hard-block
- [x] Wire names match product (Armor 3.0 stats, class_item not required here)
- [x] Zero IO/UI in sandbox_data package (D-IO)
- [x] DBR-SUB-005 table shape preserved for exotic ability requirements

## Test plan

- [x] computeBenefitsAt enhanced / base / omit-enhanced cases
- [x] Verb aliases, plurals, element prefix, agnostic null element
- [x] Exotic lookup null + hasAbilityRequirements
- [x] Champion base + overrides + unknown null
- [x] Archetypes count / find / by-stat
- [x] Artifact allowed / blocked activities
- [x] Ability timing fallback + format

## Out of scope verified

- [x] No subclasses.meta full port
- [x] No meta/renderMetaPack
- [x] No Flutter/Jaspr/Drift
- [x] No Node sidecar
