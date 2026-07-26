# Feature Specification: DART-062 Catalog Browse Semantics

**Feature Branch**: `dart-062-catalog-browse-semantics`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Catalog multi-facet, group-by, alpha sort, exotic weapons + legendary armor defs. Exit: GAP-UI-CATALOG-01, 02, 04, 05, 07. Windows+Jaspr multi-value include/exclude (slot/class/archetype/element/ammo/exotic); optional multi-dim group-by without changing filter semantics; alpha sort by display name; weapon browse exotic+legendary; armor browse legendary+exotic; DAC-NME-003 + BR-CAT-001/003/006/007. Cutover GO unchanged. Soft never auto-applies; no CLIENT_SECRET."

**Program ID**: DART-062  
**Phase**: P9  
**Depends**: DART-061 (PRODUCTION_CUTOVER GO)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-UI-CATALOG-01, 02, 04, 05, 07**  
**Fidelity**: [docs/multiplatform-dart-ui-fidelity.md](../../docs/multiplatform-dart-ui-fidelity.md)

## Scope boundary

**In scope:**

- Multi-value include/exclude facet UI on **Windows Flutter** and **Jaspr web** for **slot, class, archetype, element, ammo, exotic** with OR-within / AND-across / exclude-drop (DAC-NME-003, BR-CAT-006, DBR-ROLL-010)
- Optional multi-dimension **group-by** (element, ammo, archetype, frame, slot, class) that partitions filtered results without changing filter semantics (BR-CAT-007)
- **Alpha sort** by display name on catalog results (PRODUCT-CAT-ALPHA-SORT / GAP-UI-CATALOG-07)
- Entity extract + project **exotic weapons** into catalog (BR-CAT-001 / GAP-UI-CATALOG-04)
- Entity extract + project **legendary armor** into catalog (BR-CAT-003 / GAP-UI-CATALOG-05)
- Pure Dart I/O only; soft guidance never auto-applies; no `CLIENT_SECRET`
- **Cutover GO unchanged** (not a re-gate)

**Out of scope (do not implement in this slice):**

- Universal mode / Set-Synergy composition actions (DART-063 / GAP-UI-CATALOG-03, 10)
- Synergy membership filter wiring + reverse tags UI (DART-063 / GAP-UI-CATALOG-06)
- Owned instance perk/stat cards (DART-063 / GAP-UI-CATALOG-08)
- Item icons + dense meta polish (DART-068 / GAP-UI-CATALOG-09)
- Weapons | Armor kind mode chrome separation beyond defs present in base list (DART-063)
- Full set-bonus tree enrichment on legendary armor rows (optional residual; browse defs required)
- Production cutover re-gate; Next retirement; mobile catalog (N/A matrix)

## Assumptions

- **A1**: Pure filter engine already supports slot/class/archetype facets (`CatalogClientFilters`); gap is **host UI wiring** + sort/group pure APIs.
- **A2**: Exotic weapons = new MVP store `exotic-weapons` (product parity with Next extractor), projected as `isExotic: true` weapon rows.
- **A3**: Legendary armor = new MVP store `legendary-armor` extracted as tier-5 armor definitions with slot + class (and optional archetype when present). Set-bonus metadata is **not** required for GAP-UI-CATALOG-05 exit (defs present + filterable).
- **A4**: Alpha sort uses case-insensitive display-name order (`compareDisplayName`) applied after filter (and within group buckets).
- **A5**: Group-by is optional and multi-select; empty dimensions → single "All results" bucket. Group-by never re-filters.
- **A6**: Soft never auto-applies; no OAuth/secret work; pure Dart I/O only.
- **A7**: Existing entity cache versions without new stores remain valid: missing stores load as empty lists (no hard fail).
- **A8**: Web prebuilt/prod sample bundles gain at least one exotic weapon + one legendary armor row so offline Catalog demos show expanded defs without desktop rebuild.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-facet include/exclude on hosts (Priority: P1)

As a Windows or Jaspr user browsing Catalog, I can multi-select include/exclude chips for slot, class, archetype, element, ammo, and exotic. Results use OR within a dimension, AND across dimensions, and drop any exclude match; free-text further ANDs (DAC-NME-003).

**Why this priority**: GAP-UI-CATALOG-01; BR-CAT-006; core atlas browse fidelity.

**Independent Test**: Host widget/component tests cycle slot/class/archetype chips; pure `filterCatalogClient` suite already covers semantics — host asserts chips affect visible rows.

**Acceptance Scenarios**:

1. **Given** catalog base items, **When** user includes Solar OR Arc and excludes Special ammo, **Then** only matching rows remain (AND across / exclude drop).
2. **Given** Windows Catalog, **When** user cycles a Slot chip Kinetic → include → exclude → off, **Then** chip state and results update without reload.
3. **Given** Jaspr Catalog, **When** user cycles Class Titan include and Archetype Auto Rifle include, **Then** results respect both facets.
4. **Given** free-text + facets, **When** both applied, **Then** free-text further narrows the facet-matched set.

---

### User Story 2 - Group-by without changing filter semantics (Priority: P1)

As a user, I can optionally group filtered catalog results by one or more dimensions (element, ammo, archetype, frame, slot, class). Grouping partitions the list; it does not replace or alter facet semantics (BR-CAT-007).

**Why this priority**: GAP-UI-CATALOG-02.

**Independent Test**: Pure unit tests for `groupCatalogItems`; host tests toggle a group dimension and assert section headers.

**Acceptance Scenarios**:

1. **Given** filtered rows and no group dimensions, **When** grouped, **Then** a single "All results" bucket with alpha-sorted items.
2. **Given** dimensions `["ammo", "archetype"]`, **When** grouped, **Then** composite keys partition rows; filter count equals sum of group sizes.
3. **Given** active facets, **When** group-by is toggled, **Then** the same filter set is shown, only partitioned.

---

### User Story 3 - Alpha sort by display name (Priority: P2)

As a user, catalog result lists (and group buckets) are ordered alphabetically by display name (case-insensitive).

**Why this priority**: GAP-UI-CATALOG-07.

**Independent Test**: Pure unit tests for `compareDisplayName` / filter finalize sort; host status or list order assertion.

**Acceptance Scenarios**:

1. **Given** unsorted base items, **When** filtered with empty facets, **Then** results are alpha by name.
2. **Given** grouped results, **When** inspected, **Then** items within each group are alpha; group labels are alpha.

---

### User Story 4 - Exotic weapons in weapon catalog defs (Priority: P1)

As a user, weapon catalog definitions include **exotic** weapons (not legendary-only).

**Why this priority**: GAP-UI-CATALOG-04; BR-CAT-001.

**Independent Test**: Extractor fixture projects Gjallarhorn-like exotic; OfflineCatalog / bundle projection includes `isExotic: true` weapon rows; exotic-only facet returns them.

**Acceptance Scenarios**:

1. **Given** raw fixture with exotic weapon, **When** exotic-weapons extractor runs, **Then** record has slot/element/ammo/frame/intrinsic.
2. **Given** OfflineCatalog load with exotic-weapons store, **When** browse with exotic only, **Then** exotic weapons appear among results.
3. **Given** web sample bundle with exotic-weapons, **When** projected, **Then** catalog items include that exotic weapon.

---

### User Story 5 - Legendary armor in armor catalog defs (Priority: P1)

As a user, armor catalog definitions include **legendary** armor (not exotic-only).

**Why this priority**: GAP-UI-CATALOG-05; BR-CAT-003.

**Independent Test**: Extractor fixture projects legendary armor; OfflineCatalog / bundle includes non-exotic armor rows; class/slot facets filter them.

**Acceptance Scenarios**:

1. **Given** raw fixture with legendary armor, **When** legendary-armor extractor runs, **Then** record has slot/class (optional archetype).
2. **Given** OfflineCatalog with legendary-armor store, **When** browse, **Then** legendary armor rows appear with `isExotic: false`.
3. **Given** class facet Titan, **When** applied, **Then** legendary Titan armor remains if matching.

---

### Edge Cases

- Missing new store files on older entity caches → empty list for that store, other stores still load
- Item missing a group dimension value → "Unknown …" bucket label
- Empty include + empty exclude on a facet → no constraint
- Soft suggestions never auto-apply on any catalog path
- No `CLIENT_SECRET` in any host or package change

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST expose multi-value include/exclude chips on Windows+Jaspr for slot, class, archetype, element, ammo, and exotic with OR-within / AND-across / exclude-drop semantics (DAC-NME-003, BR-CAT-006).
- **FR-002**: System MUST provide pure `groupCatalogItems(items, dimensions)` that partitions without re-filtering (BR-CAT-007).
- **FR-003**: Hosts MUST offer optional multi-dimension group-by UI that applies only after filter.
- **FR-004**: Filtered catalog results MUST be alpha-sorted by display name (case-insensitive).
- **FR-005**: MVP entity pipeline MUST extract and store **exotic-weapons** and project them as exotic catalog weapon rows (BR-CAT-001).
- **FR-006**: MVP entity pipeline MUST extract and store **legendary-armor** and project them as non-exotic catalog armor rows (BR-CAT-003).
- **FR-007**: OfflineCatalog and EntityBundle projection MUST merge weapons + exotic-weapons + exotic-armor + legendary-armor (+ existing subclass/mod stores) into base catalog items.
- **FR-008**: Soft guidance MUST never auto-apply; no `CLIENT_SECRET` in clients; pure Dart I/O only.
- **FR-009**: PRODUCTION_CUTOVER GO status MUST remain unchanged by this slice.

### Non-Functional / Parity

- Exit criteria are parity-specific (exotic+legendary defs present; multi-facet UI wired; group-by partitions; alpha order), not merely "button works".
- Intentional thinning residual: set-bonus perks on legendary armor rows, synergy membership chips, Universal mode → leave open under later GAP-UI / DART-063+.

## Success Criteria

| ID | Criterion | Evidence |
| -- | --------- | -------- |
| SC-01 | GAP-UI-CATALOG-01 closed on Windows+Jaspr | Host tests + filter semantics tests |
| SC-02 | GAP-UI-CATALOG-02 closed | `groupCatalogItems` tests + host group headers |
| SC-03 | GAP-UI-CATALOG-04 closed | Extractor + projector + bundle rows |
| SC-04 | GAP-UI-CATALOG-05 closed | Extractor + projector + bundle rows |
| SC-05 | GAP-UI-CATALOG-07 closed | Alpha sort tests on filter output |
| SC-06 | DAC-NME-003 / BR-CAT-001/003/006/007 covered | Spec + tests map |
| SC-07 | Cutover GO unchanged; no CLIENT_SECRET | Docs + scan unchanged |

## Traceability

| Exit / Rule | Implementation |
| ----------- | -------------- |
| GAP-UI-CATALOG-01 | Host facet chips + existing `filterCatalogClient` |
| GAP-UI-CATALOG-02 | `group_catalog.dart` + host group UI |
| GAP-UI-CATALOG-04 | `ExoticWeaponsExtractor` + store + projector |
| GAP-UI-CATALOG-05 | `LegendaryArmorExtractor` + store + projector |
| GAP-UI-CATALOG-07 | `compareDisplayName` + sort in filter finalize |
| DAC-NME-003 | US1 + filter tests |
| BR-CAT-001/003/006/007 | US1–5 |

## Out of scope residuals (PROC-06)

| Residual | Track |
| -------- | ----- |
| Universal mode / kind modes | DART-063 GAP-UI-CATALOG-03/10 |
| Synergy membership UI | DART-063 GAP-UI-CATALOG-06 |
| Owned perk/stat cards | DART-063 GAP-UI-CATALOG-08 |
| Icons/dense meta | DART-068 GAP-UI-CATALOG-09 |
| Set-bonus fields on legendary armor rows | optional later enrichment |
