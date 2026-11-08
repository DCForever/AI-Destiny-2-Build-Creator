# Feature Specification: DART-026 Flutter Catalog Owned

**Feature Branch**: `dart-026-flutter-catalog-owned`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Catalog all-vs-owned + instance projections for pickers. Owned filter works after sync."

**Program ID**: DART-026  
**Phase**: P2  
**Depends**: DART-020 (offline catalog), DART-025 (inventory sync UI / local owned data)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- **All vs owned scope** on catalog browse: annotate base `CatalogItem` rows with `owned` / `ownedCount` from local Drift inventory (post-sync), and filter to owned-only when scope is `owned`
- Pure helpers: count owned copies by `itemHash`, annotate catalog rows, filter by scope (product `scope: "all" | "owned"` intent)
- **Instance projections for pickers**: pure projection of owned `InventoryItemRecord` → picker-facing instance rows (instanceId, itemHash, power, location, characterId, flags, plugHashes, rollTags, bucket), sorted power-desc for a hash (or all)
- Flutter Catalog UI on Windows host:
  - All | Owned scope toggle
  - Owned badge / count on list rows when annotated
  - Selecting an owned row shows instance projections for that hash (list of copies)
  - Empty owned guidance when no inventory synced / no matches
- Unit tests for pure annotate/filter/project; widget tests with memory DB + preloaded catalog + seeded inventory

**Out of scope (later slices):**

- Full product `InventoryHashProjection` manifest name resolution for orphan hashes (MVP: optional stub "Unknown (hash)" when hash not in base catalog and owned scope needs a row)
- Legendary armor non-exotic store expansion
- Set slot-fill picker polish (DART-030) — this slice only provides projections + owned catalog for later pickers
- Plug name resolution / perk grid (product 011) — project raw plug hashes only
- Character class/display name labels for instances
- Equip / set attach UI
- Soft guidance auto-apply (forbidden)
- Node sidecar / CLIENT_SECRET (forbidden)

### Assumptions

- **A1**: Owned counts are **instance counts per `itemHash`** from `listInventoryItems` for the signed-in local user (all buckets). No searchName aggregation / orphan projection sophistication this slice (MVP hash match only).
- **A2**: When signed out or no local user / empty inventory, **All** scope still works offline; **Owned** scope shows empty with clear guidance to sign in and sync.
- **A3**: Local user id comes from `InventorySyncController.localUserId` after status/sync, or host ensures user via membership id when session is signed in (same as DART-025).
- **A4**: Instance projection is **in-process pure** over already-synced rows — no Bungie network on catalog browse.
- **A5**: Soft guidance never auto-applies; catalog does not run hard DBR evaluators.
- **A6**: Single Drift connection remains on `AppServices.db`; catalog entities stay file JSON.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Annotate and filter owned catalog (Priority: P1)

As a signed-in user who has synced inventory, I can browse the catalog in **All** mode (everything, with ownership counts) or **Owned** mode (only definition hashes I own) so pickers can prefer items I can equip.

**Why this priority**: Roadmap exit — “Owned filter works after sync.”

**Independent Test**: Seed inventory rows for known catalog hashes; pure annotate + filter returns correct ownedCount and owned-only list; no network.

**Acceptance Scenarios**:

1. **Given** base catalog hashes 1,2,3 and inventory two copies of hash 1 and one of hash 2, **When** annotate runs, **Then** hash 1 has `ownedCount: 2`, hash 2 has `1`, hash 3 has `0` / `owned: false`.
2. **Given** annotated items, **When** scope is `owned`, **Then** only items with `ownedCount > 0` remain; facets/query still apply as AND.
3. **Given** empty inventory map, **When** scope is `owned`, **Then** result list is empty (no crash).

---

### User Story 2 - Instance projections for a definition hash (Priority: P1)

As a picker consumer (and Catalog UI), I can list owned **instances** for a selected item hash with power, location, and plug hashes so a specific copy can be chosen later.

**Why this priority**: Roadmap “instance projections for pickers.”

**Independent Test**: Pure project function over fixture `InventoryItemRecord`s; power-desc sort; empty when no copies.

**Acceptance Scenarios**:

1. **Given** three inventory rows with same itemHash different powers, **When** projecting for that hash, **Then** three projections sorted by power descending with distinct instanceIds.
2. **Given** no rows for a hash, **When** projecting, **Then** empty list (not error).
3. **Given** a row with plugHashes and masterwork/crafted flags, **When** projected, **Then** those fields appear on the projection DTO.

---

### User Story 3 - Flutter Catalog All/Owned UI (Priority: P1)

As a Windows user, I open Catalog, toggle All vs Owned, see ownership on rows after sync, and expand/select a row to view instance projections.

**Why this priority**: User-visible exit criteria.

**Independent Test**: Widget tests with preloaded catalog + memory DB inventory + signed-in session / local user id.

**Acceptance Scenarios**:

1. **Given** synced inventory including a fixture hash present in preloaded catalog, **When** Catalog loads and user selects **Owned**, **Then** only owned definition rows show.
2. **Given** **All** scope, **When** list renders, **Then** owned rows show a count badge (or subtitle ownership) and unowned still appear.
3. **Given** user selects an owned row, **When** instance panel loads, **Then** power/location/instanceId for each copy are shown.
4. **Given** no inventory / signed out, **When** user selects **Owned**, **Then** empty guidance mentions sync (not a crash).

---

### Edge Cases

- Inventory has hashes not in base catalog (e.g. legendary armor): MVP may omit them from owned list (no unknown-row requirement for pass); document that full orphan rows wait for legendary store / hash projections.
- Concurrent re-sync while Catalog open: Reload / re-annotate on refresh; no live subscription required this slice.
- Soft guidance never auto-applies.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST count owned copies by `itemHash` from local inventory records.
- **FR-002**: System MUST annotate catalog items with `owned` (`ownedCount > 0`) and `ownedCount`.
- **FR-003**: System MUST support catalog scope `all` | `owned` in client filters; owned keeps only `ownedCount > 0`.
- **FR-004**: System MUST project inventory rows to picker instance DTOs (instanceId, itemHash, bucket, location, characterId, power, isMasterwork, isCrafted, plugHashes, rollTags) sorted power-desc.
- **FR-005**: Flutter Catalog MUST expose All | Owned scope toggle and apply it after annotate.
- **FR-006**: Flutter Catalog MUST show instance projections for a selected catalog hash when copies exist.
- **FR-007**: Catalog owned path MUST use local Drift inventory only (no live Bungie fetch on browse).
- **FR-008**: Host MUST NOT embed CLIENT_SECRET.
- **FR-009**: Soft suggestions MUST NOT auto-apply.

### Key Entities

- **CatalogScope**: `all` | `owned`.
- **OwnedCounts**: `Map<itemHash, count>`.
- **CatalogItem**: existing; `owned` / `ownedCount` now populated post-annotate.
- **CatalogInstanceProjection**: per-copy picker row from inventory.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pure unit tests cover annotate, owned filter, empty owned, instance sort.
- **SC-002**: Widget test: after seeding inventory, Owned scope shows only owned fixture items.
- **SC-003**: Widget test: selecting owned item lists instance projections.
- **SC-004**: `dart test packages/manifest` (owned helpers) + `dart test packages/db` (instance project if there) + `flutter test` windows_host green for new tests.
- **SC-005**: Roadmap exit: “Owned filter works after sync.”

## Assumptions

See A1–A6 above.
