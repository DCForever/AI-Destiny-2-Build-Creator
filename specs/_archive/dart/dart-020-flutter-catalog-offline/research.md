# Research: DART-020 Flutter Catalog Offline

**Date**: 2026-07-24

## Product sources

| Topic | Source |
| ----- | ------ |
| Facet model + filter | `src/lib/catalog/filterCatalogClient.ts` |
| CatalogItem shape | `src/lib/catalog/types.ts` |
| Chip option constants | `src/lib/catalog/filterOptions.ts` |
| Entity stores | DART-017 `FileEntityCache` + MVP records |
| Host shell | DART-019 `apps/windows_host` |

## Decisions

### R1 — Where does pure filter live?

**Decision**: `packages/manifest/lib/src/catalog/`  
**Rationale**: Filter is pure but projector depends on entity record types already in manifest. Domain package must stay IO/UI-free and not grow entity coupling.  
**Alternative rejected**: New `packages/catalog` package — extra workspace member for one slice of thin code.

### R2 — Inventory fields

**Decision**: Always `owned: false`, `ownedCount: 0` until DART-026.  
**Rationale**: Roadmap splits offline catalog (P1) from owned mode (P2).

### R3 — Armor coverage

**Decision**: Exotic armor only from MVP `exotic-armor` store.  
**Rationale**: DART-017 MVP extractors do not include legendary armor store; do not invent one here.

### R4 — Synergy facets

**Decision**: Pure filter accepts optional `synergies` / hash include-exclude for API parity; Catalog UI does **not** expose synergy chips in this slice.  
**Rationale**: Synergies live in Drift library; catalog offline must not require DB join.

### R5 — Empty cache UX

**Decision**: Empty state copy points user to Settings for manifest; no auto-download on Catalog open.  
**Rationale**: DART-019/018 keep refresh explicit; network optional.

### R6 — Free-text

**Decision**: Case-insensitive substring over name, slot, element, ammo, type, frame, class, description (product filterCatalogClient haystack subset).  
**Rationale**: Fuse ranking deferred; exit criteria only need browse/filter.

## Parity notes

- `matchesArchetypeFacet` uses itemTypeName + frame with Frame-suffix stripping — ported.
- Legacy `slot` / `className` / `onlyExotic` aliases supported on filter model for TS parity.
