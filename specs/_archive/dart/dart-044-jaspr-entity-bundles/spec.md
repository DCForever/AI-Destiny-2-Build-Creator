# Feature Specification: DART-044 Jaspr Entity Bundles

**Feature Branch**: `dart-044-jaspr-entity-bundles`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Load prebuilt entity bundles (no full raw rebuild in browser). Offline catalog facets on web."

**Program ID**: DART-044  
**Phase**: P5  
**Depends**: DART-017 (entity stores), DART-042 (Jaspr skeleton); DART-043 optional for co-hosting with DB  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) — **D-WEB-DB** prefer prebuilt entity bundles on web

## Scope boundary

**In scope:**

- **Prebuilt entity bundle** format + pure parse/decode for MVP stores (weapons, exotic-armor, aspects, fragments, abilities, mods) — no raw Bungie table rebuild in the browser
- **Memory / bundle entity cache** reader (no `dart:io` required) that can feed the same projectors as `FileEntityCache`
- **Web-safe** paths so `destiny2_manifest` catalog + bundle APIs compile for Jaspr web (conditional IO for file-backed refresh paths)
- **Offline catalog facets on web**: load prebuilt bundle → project `CatalogItem` → pure `filterCatalogClient` facets/query in Jaspr Catalog UI
- Ship a **fixture prebuilt bundle** under `apps/web_host/web/entities/` (static URL load) for offline demo/tests
- Settings or Catalog status showing loaded bundle version / empty / error
- Automated tests: pure bundle parse + catalog facets; Jaspr Catalog page component tests with injected items

**Out of scope (later slices):**

- Browser Public+PKCE OAuth (DART-045)
- Compose spine UI (DART-046)
- Equip / DIM on web (DART-047)
- Legacy `app.db` import (DART-048)
- Full raw manifest download/rebuild **in browser** (desktop Windows remains DART-018 path)
- CDN production distribution channel decision (fixture + static web path is enough; document assumption)
- Owned inventory filter on web (needs sync; Flutter has DART-026)
- Node sidecar, `CLIENT_SECRET` in clients
- Soft guidance auto-apply (forbidden)

### Assumptions

- **A1**: Prebuilt bundle is a single JSON document with `manifestVersion`, `builtAt`, `counts`, and `stores` map (store stem → JSON array of records). Multi-file layout under `entities/<version>/` remains valid for native `FileEntityCache`; web loads the single-file prebuilt document by default.
- **A2**: Bundle distribution for this slice is **ship-with-web-assets** (`web/entities/prebuilt/bundle.json` fetched via same origin). CDN is deferred (open product detail).
- **A3**: No full raw rebuild in browser — `rebuild` / isolate rebuild stay native/desktop; web uses load-only APIs.
- **A4**: Catalog facets reuse pure `filterCatalogClient` / `FacetFilter` from DART-020 (element, ammo, exotic, free-text at minimum).
- **A5**: Soft guidance never auto-applies; no OAuth / inventory owned scope on web in this slice.
- **A6**: Pure Dart I/O only; no Next.js runtime dependency; no `CLIENT_SECRET`.
- **A7**: `apps/web_host` remains outside root pub workspace; path-depends on `destiny2_manifest` (+ existing deps).
- **A8**: When bundle missing or fetch fails, Catalog shows empty/error state without crashing the shell.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Parse prebuilt entity bundle offline (Priority: P1)

As the multiplatform data layer, I can parse a prebuilt MVP entity bundle into typed stores and catalog rows without reading raw Bungie tables or using `dart:io`.

**Why this priority**: Roadmap exit — “Load prebuilt entity bundles (no full raw rebuild in browser).”

**Independent Test**: Unit tests parse fixture JSON → `EntityCacheMeta` + store records → `projectMvpStores` / offline load result; missing stores handled gracefully.

**Acceptance Scenarios**:

1. **Given** a valid prebuilt bundle JSON with weapons + exotic-armor, **When** parsed, **Then** meta version and record counts match and projector yields catalog rows with facet fields.
2. **Given** a bundle with only some MVP stores, **When** projected, **Then** available stores appear and missing stores contribute zero rows (no crash).
3. **Given** invalid JSON / wrong shape, **When** parse is attempted, **Then** a typed error is returned (no uncaught crash).

---

### User Story 2 - Offline catalog facets on web (Priority: P1)

As a browser user on the Jaspr host, I can open Catalog, load the prebuilt entity bundle, and filter by facets/query offline (no inventory, no OAuth).

**Why this priority**: Roadmap exit — “Offline catalog facets on web.”

**Independent Test**: Component tests inject catalog items or a memory bundle; assert list rows and facet/query narrowing; no Bungie network / CLIENT_SECRET.

**Acceptance Scenarios**:

1. **Given** prebuilt catalog items, **When** Catalog page loads, **Then** results list shows item names and bundle version status.
2. **Given** user includes an element facet (or free-text query), **When** filters apply, **Then** list narrows using pure facet rules.
3. **Given** bundle load failure or empty, **When** Catalog loads, **Then** empty/error state is shown (shell remains usable).
4. **Given** host shell, **When** user navigates Catalog ↔ Settings, **Then** both screens are reachable.

---

### User Story 3 - No browser raw rebuild (Priority: P1)

As a web host, I must not run full raw manifest extract/rebuild in the browser; only prebuilt load paths are used for catalog.

**Why this priority**: Architecture D-WEB-DB + slice goal.

**Independent Test**: Code review / API surface: web Catalog bootstrap calls bundle loader only; unit test documents that `MemoryEntityCache` / bundle load has no rebuild method required for catalog.

**Acceptance Scenarios**:

1. **Given** web Catalog bootstrap, **When** entities are loaded, **Then** path is prebuilt fetch/parse (or injected memory), not isolate raw-table rebuild.
2. **Given** docs/README, **When** read, **Then** they state web uses prebuilt bundles; full rebuild is desktop (Windows) first.

---

### Edge Cases

- Fetch 404 / network error for bundle URL → error state, not crash.
- Partial stores in bundle → partial catalog OK.
- Soft guidance never auto-applies.
- Second-tab DB lock (DART-043) is independent of entity bundle load (bundles are static JSON, not SQLite writers).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST define a prebuilt entity bundle document format covering MVP stores + meta.
- **FR-002**: System MUST parse bundle JSON into typed MVP records without raw-table extractors.
- **FR-003**: System MUST project bundle stores into `CatalogItem` rows for offline facets.
- **FR-004**: Jaspr web host MUST load a prebuilt bundle (static asset or injected) and expose Catalog browse with offline facets.
- **FR-005**: Web catalog path MUST NOT perform full raw manifest rebuild in the browser.
- **FR-006**: Catalog MUST support free-text query and at least element (and preferably ammo/exotic) facets via pure filter APIs.
- **FR-007**: Host MUST NOT embed `CLIENT_SECRET` or depend on Next.js / Node sidecar for entities.
- **FR-008**: Automated tests MUST cover bundle parse + facet filtering and Catalog UI status/list with fixtures.
- **FR-009**: `destiny2_manifest` catalog/bundle APIs used by web MUST be web-compilable (file IO paths conditional/stubbed).

### Key Entities

- **EntityBundleDocument**: version, builtAt, counts, stores map
- **MemoryEntityCache / EntityCacheReader**: in-memory store reader
- **OfflineCatalogLoadResult / CatalogItem**: existing catalog projection
- **WebCatalogBootstrap**: host load status for bundle

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Unit tests prove prebuilt bundle → catalog rows without disk/raw rebuild.
- **SC-002**: Web Catalog shows offline results from fixture bundle and narrows with facets/query.
- **SC-003**: No CLIENT_SECRET / no Node sidecar in web entity path.
- **SC-004**: `dart test` green for `packages/manifest` and `apps/web_host` for this slice.

## Assumptions

Listed under Scope boundary (A1–A8).
