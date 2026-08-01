# Research: DART-031 Flutter Synergy Library UI

**Date**: 2026-07-24

## Decisions

### R1 — Mirror DART-030 dual-pane + local-library user

**Decision**: Reuse Sets library patterns: `kFlapLibraryRailWidth`, ChangeNotifier controller, `kLocalLibraryMembershipId` / `resolveLibraryUserId` shape, memory-DB widget tests.

**Rationale**: Same library UX contract; DART-029 already defines `kFlapColumnsSynergy`.

### R2 — Designation immutability is use-case + UI

**Decision**: UI never exposes type/subtype editors after create. Use cases already throw `UseCaseErrorCode.designationImmutable` when `hasType`/`hasSubType` change values. Controller may optionally surface that error if called incorrectly.

**Rationale**: Exit criterion requires both create and immutability; product parity with DART-027.

### R3 — Evidence links as full-list replace

**Decision**: Detail drafts `List<SynergyLinkWrite>`; Save links calls `updateUserSynergy` with full list (repo replaces links).

**Rationale**: Matches `UpdateSynergyCommand.links` and existing use-case tests.

### R4 — No catalog pick required for MVP links

**Decision**: Add-link form: kind dropdown + displayName + optional itemHash text field. Catalog pick for weapon/exotic is optional polish, not exit-critical.

**Rationale**: Exit criteria focus on create + designation; evidence links UI is list/add/remove.

### R5 — Nav order

**Decision**: Catalog → Sets → Synergies → Settings.

**Rationale**: Library surfaces grouped; Settings last (matches prior shell).
