# Research: DART-030 Flutter Sets Library UI

**Date**: 2026-07-24

## Decisions

### D1 — Dual-pane = list + detail on Sets page

**Decision**: Left library rail (`kFlapLibraryRailWidth` 320) lists sets; right pane edits identity + slots. Catalog pick is a **dialog**, not a third permanent pane.

**Rationale**: Roadmap says “Windows dual-pane”; FlapBoard contracts define library rail width. Catalog already has its own screen; reusing a modal picker avoids bloating nav.

**Alternatives**: Embed full CatalogPage as third column — heavier, harder to test, duplicates DART-026 UI.

### D2 — Local-library user when signed out

**Decision**: `ensureUser(bungieMembershipId: 'local-library', …)` for offline library ownership.

**Rationale**: Set CRUD requires `userId` FK; compose without OAuth must still work for offline MVP.

### D3 — Persistence-level set items only

**Decision**: No hard exotic/mod-energy gates on fill (DART-027 use cases). Soft never auto-applies.

**Rationale**: Roadmap places kit gates with build save / later polish; exit criteria are create/edit + fill from catalog/owned.

### D4 — Slot mapping parity with product

**Decision**: Port `slotsForSetType` + Kinetic/Energy/Power and armor bucket maps from `setPlacementFromHit.ts` / `schemas.ts` as pure Dart in host.

**Rationale**: Correct fill targets for weapon/armor without pulling TS.

## Dependencies used

- DART-027 `createUserSet` / `updateUserSet` / `listUserSets` / `getSetDetail` / `upsertUserSetItem` / `removeUserSetItem`
- DART-026 `OwnedCatalogBridge`, `CatalogScope`, instance projections
- DART-029 `kFlapLibraryRailWidth`, flap theme (already on app)

## Open items deferred

- Fashion entity stores for meaningful fashion pick
- Linked mod set + optimizer constraints UI
- Attach set to variant (DART-033)
