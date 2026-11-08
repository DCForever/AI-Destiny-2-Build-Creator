# Feature Specification: DART-020 Flutter Catalog Offline

**Feature Branch**: `dart-020-flutter-catalog-offline`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Catalog facets + browse offline from entity stores. Browse/filter without inventory; P1 phase gate."

**Program ID**: DART-020  
**Phase**: P1  
**Depends**: DART-017 (entity stores), DART-019 (Flutter Windows host skeleton)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Pure **catalog facet filter** (include/exclude chips + free-text) ported from product `filterCatalogClient` semantics
- **Project** MVP entity stores (weapons, exotic-armor, aspects, fragments, abilities, mods) into a unified **CatalogItem** list offline via `FileEntityCache` / StorageRoot (no inventory, no Bungie network)
- **OfflineCatalog** service: load base items for current entity-cache version; apply filters in-process
- **Flutter Catalog browse UI** on Windows host: category/store selection, facet chips (element, ammo, slot, class, exotic), free-text query, results list
- Simple host navigation so Catalog is reachable alongside Settings
- Unit tests for pure filter + projector + offline load; widget tests for Catalog page with fixture entities
- This slice is the **P1 phase gate** (Drift DB open + entity stores + offline catalog facets)

**Out of scope (later slices):**

- Owned / all-vs-owned inventory filter (DART-026)
- OAuth / inventory sync (DART-022–025)
- Synergy id / hash allowlist facets that need library DB (may accept pure hash sets in filter model; no UI wire to synergies)
- Universal search multi-kind ranking / Fuse parity (simple substring is enough)
- Design tokens / FlapBoard polish (DART-029)
- Set slot-fill picker polish (DART-030)
- Legendary armor non-exotic store expansion (MVP has exotic-armor only for armor)
- Node sidecar, CLIENT_SECRET
- Soft guidance auto-apply

### Assumptions

- **A1**: Catalog filter lives in `packages/manifest` (`src/catalog/`) next to entity stores — pure filter functions need no Flutter; offline loader uses `FileEntityCache` + `current-version.json`.
- **A2**: `owned` / `ownedCount` on CatalogItem are always `false` / `0` in this slice (no inventory).
- **A3**: When no entity cache / version exists, Catalog UI shows empty state with guidance to refresh manifest in Settings (refresh itself remains optional host action; may already exist from later polish — not required to download in this slice).
- **A4**: MVP armor rows come from **exotic-armor** only; weapons from **weapons**; subclass pieces and mods projected with appropriate slot/element fields.
- **A5**: Facet semantics match product Phase Now: across dimensions AND; within include OR; any exclude match drops; free-text AND after facets.
- **A6**: Soft guidance never auto-applies; no hard DBR evaluation in Catalog UI.
- **A7**: Single DB connection from DART-019 remains; catalog does not open a second SQLite connection (entities are file JSON).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pure facet filter offline (Priority: P1)

As a multiplatform data layer, I can filter a list of catalog items with include/exclude facets and free-text without inventory or network so pickers and browse share one pure predicate.

**Why this priority**: Roadmap exit — “Catalog facets … offline”; pure engine is the shared foundation.

**Independent Test**: Unit tests with in-memory CatalogItem fixtures (no disk); cycleFacetValue / matchesFacet / filterCatalogClient parity with product mix-and-match cases.

**Acceptance Scenarios**:

1. **Given** items with elements Solar/Arc/Void, **When** include Solar|Arc and exclude Special ammo, **Then** only matching items remain (AND across facets).
2. **Given** exotic and legendary items, **When** `exotic: false`, **Then** only non-exotic remain.
3. **Given** facet chips, **When** cycling a value, **Then** state goes off → include → exclude → off.
4. **Given** free-text `query`, **When** applied after facets, **Then** name/description fields match substring case-insensitively.

---

### User Story 2 - Project entity stores to catalog rows (Priority: P1)

As a host, I can load MVP entity JSON under StorageRoot and obtain a unified CatalogItem list (weapons + exotic armor + aspects + fragments + abilities + mods) without inventory.

**Why this priority**: Roadmap exit — “browse offline from entity stores.”

**Independent Test**: Write fixture entity JSON; OfflineCatalog / projector returns expected hashes and facet fields; missing version yields empty or typed empty state.

**Acceptance Scenarios**:

1. **Given** fixture weapons + exotic-armor entity stores for a version, **When** base catalog is loaded, **Then** items include weapon and exotic armor rows with slot/element/ammo/classType/isExotic set.
2. **Given** no current version, **When** load is requested, **Then** result is empty with a clear “no entity cache” signal (no crash).
3. **Given** base items loaded, **When** filters are applied, **Then** filtering uses pure filter and does not read inventory tables.

---

### User Story 3 - Flutter Catalog browse UI (Priority: P1)

As a Windows user, I can open Catalog in the host, apply facets/query, and see offline results without signing in or syncing inventory.

**Why this priority**: Roadmap exit — “Browse/filter without inventory”; first user-visible catalog.

**Independent Test**: Widget tests inject OfflineCatalog with fixture data; assert list rows and filter chips update results; assert no OAuth.

**Acceptance Scenarios**:

1. **Given** fixture catalog items, **When** Catalog page loads, **Then** results list shows item names.
2. **Given** user toggles an element include chip, **When** filters apply, **Then** list narrows.
3. **Given** empty entity cache, **When** Catalog loads, **Then** empty-state message is shown (not a crash).
4. **Given** host shell, **When** user navigates Catalog ↔ Settings, **Then** both screens are reachable without OAuth.

---

### Edge Cases

- Partial stores (only weapons present): project what exists; skip missing stores without failing whole load when optional; document that missing required MVP files may yield partial list.
- Malformed JSON in one store: surface error for that load path; do not leave UI hung.
- Large item counts: pure filter is O(n) in-process; no virtualization requirement for P1 MVP (list is fine for fixture-scale; product-scale polish later).
- Soft guidance never auto-applies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide pure `FacetFilter` helpers (`emptyFacet`, `normalizeFacet`, `cycleFacetValue`, `facetChipState`, `matchesFacet`) with product Phase Now semantics.
- **FR-002**: System MUST provide pure `filterCatalogClient(items, filters)` supporting query, slots, elements, ammos, archetypes, classNames, and exotic tri-state without inventory.
- **FR-003**: System MUST project MVP entity store records into `CatalogItem` rows offline (`owned: false`, `ownedCount: 0`).
- **FR-004**: System MUST load base catalog from entity cache for the current StorageRoot version (or inject version for tests).
- **FR-005**: Flutter host MUST expose a Catalog browse screen with free-text + facet chips and results list.
- **FR-006**: Catalog MUST work without OAuth and without inventory sync.
- **FR-007**: Host MUST NOT embed CLIENT_SECRET.
- **FR-008**: Catalog MUST NOT open a second Drift DB connection for entity reads (file JSON only).

### Key Entities

- **CatalogItem**: Unified browse row (hash, name, icon, slot, element, ammo, itemTypeName, frame, classType, description, isExotic, owned, ownedCount).
- **FacetFilter**: `{ include: string[], exclude: string[] }` per dimension.
- **CatalogClientFilters**: Combined filter model for pure predicate.
- **OfflineCatalog**: Loads + filters; inventory-agnostic.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pure filter unit tests cover include/exclude mix, exotic flag, free-text, chip cycle (product parity cases).
- **SC-002**: Offline load from fixture entity stores returns browsable items without network/inventory.
- **SC-003**: Flutter Catalog page filters list client-side with injectable catalog service.
- **SC-004**: P1 phase gate met: Drift open (DART-019) + entity stores (DART-017/018) + offline catalog facets (this slice).
- **SC-005**: `dart test packages/manifest` and `flutter test` (windows_host) green for new tests.

## Assumptions

See Scope boundary Assumptions A1–A7. Defaults chosen to avoid NEEDS CLARIFICATION:

- Synergy facet API may exist on pure filter for future use; Catalog UI for DART-020 does not require synergy chips.
- Category tabs optional: default show all projected kinds; filter by type via free-text/archetype/slot is enough.
