# Feature Specification: DART-056 Jaspr Inventory Sync Depth

**Feature Branch**: `dart-056-jaspr-inventory-sync-depth`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Web sync/owned depth match Windows resolution rules. GAP-WEB-01; RB-02. Web sync applies same vault/transfer resolution as Windows post-DART-050; Owned catalog usable to pin instances for equip/DIM on Jaspr build compose; RC-SYNC no longer fails solely for web owned depth; clears RB-02"

**Program ID**: DART-056  
**Phase**: P7  
**Depends**: DART-050 (vault/transfer resolution), DART-045 (Jaspr OAuth), DART-053 (diagnostics + entity-owned UX), DART-044 (entity bundles)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-WEB-01**, residual **GAP-INV-06** web owned depth  
**Cutover**: [docs/multiplatform-dart-cutover-parity-checklist.md](../../docs/multiplatform-dart-cutover-parity-checklist.md) — **RB-02** / **RC-SYNC**

## Scope boundary

**In scope:**

- Jaspr **Settings** inventory sync surface: Sync now + busy/error + meta (itemCount / syncVersion / lastFullSyncAt / freshness) using the same `syncUserInventory` path as Windows
- Wire **equipmentBucketLookupBuilder** (catalog/entity slot map — same rules as Windows post-DART-050 web equip path) on Settings `syncNow` so vault/postmaster resolve and store with equipment buckets
- Wire roll-tag / socket enrichment builders already available for web (frame meta from catalog; perk names empty residual OK per PROC-06 / DART-051–052 web residual notes)
- Retain **lastDiagnostics** after successful sync and surface raw/parsed/dropped + `resolvedFromTransfer` / `droppedNonEquipment` / `storedTotal` (DART-053 parity on web)
- Jaspr **Catalog** All | Owned scope: join entity definitions × Drift inventory; owned badges; instance projections (power-desc) on row select with **instanceId** visible for compose pin / equip / DIM
- App wiring: inventory sync controller shared with Settings + Catalog; equip continues to use same lookup builders
- Host tests: vault fixture asserts `resolvedFromTransfer > 0` + Kinetic (or armor) stored bucket when lookup wired; fail path without lookup drops vault; Owned filter + instance list
- Docs: close **GAP-WEB-01**; clear **RB-02**; **RC-SYNC** no longer FAIL solely for web owned depth; update roadmap DART-056 done
- Soft never auto-applies; no CLIENT_SECRET; no Node sidecar

**Out of scope (do not implement in this slice):**

- Mobile inventory sync / catalog owned (DART-057)
- Full raw DestinyInventoryItemDefinition download on web (prebuilt bundles only; slot-map lookup remains primary)
- Weapon perk **names** without raw/injected maps (documented residual from DART-051 — not intentional pure thinning)
- Socket columnKind without raw defs (DART-052 residual)
- Live dual-run execution (DART-054 harness already exists; operator dual-run remains RC-OPS)
- Soft-stat editor completeness (DART-057 / GAP-UI-01)
- Finish-gaps host UX (GAP-FEAT-06 → DART-057)
- Soft guidance auto-apply (forbidden)
- CLIENT_SECRET / confidential cookie parity
- Node sidecar
- DART-057+ slices

## Assumptions

- **A1**: Web vault/transfer resolution uses **catalog/entity slot map** (`buildEquipmentBucketLookupFromSlots`) — same as Jaspr equip DART-050 — not full raw item defs (Windows prefers raw when available). Slot coverage residual for legendary armor without slots remains PROC-06-documented if any, not an exit failure when weapons/exotics resolve.
- **A2**: "Owned catalog usable to pin instances" means Catalog Owned scope shows instance projections with **instanceId** (and power/location/bucket) so users can pin that id on build compose equip/DIM (compose already accepts free-text instance pin). Full in-compose instance picker is optional polish if time allows but not required for exit.
- **A3**: Settings sync requires writer DB + signed-in OAuth + profile client; blocked tab (non-writer) shows non-syncing state without crash.
- **A4**: Soft never auto-applies; no confidential secrets in clients.
- **A5**: Existing Windows inventory fidelity (DART-050–054) is unchanged; this slice is Jaspr depth only.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Settings sync with vault resolution (Priority: P1)

As a signed-in Guardian on Jaspr web, I open Settings and run **Sync now**; vault and postmaster weapons/armor are stored in Drift with **equipment** buckets (Kinetic/Helmet/…), not dropped as unresolved transfer containers. Diagnostics show `resolvedFromTransfer` when vault fixtures resolve.

**Why this priority**: GAP-WEB-01 / RB-02 core; RC-SYNC web depth.

**Independent Test**: Controller unit test with vault General fixture + lookup builder asserts stored Kinetic + `lastResolvedFromTransfer > 0`; without lookup, vault dropped.

**Acceptance Scenarios**:

1. **Given** signed-in session, writer DB, and vault General item with lookup to Kinetic, **When** Settings `syncNow` runs, **Then** Drift stores the instance with `bucket = Kinetic`, `location = vault`, and diagnostics `resolvedFromTransfer >= 1`.
2. **Given** the same vault item, **When** sync runs with empty/omitted lookup, **Then** item is not stored and `resolvedFromTransfer` is 0 (drop path preserved for tests).
3. **Given** signed-out session, **When** Sync now is pressed (or unavailable), **Then** error/gate without network write; no crash.
4. **Given** successful sync, **When** Settings UI renders, **Then** itemCount, last sync time, and diagnostics keys (raw/parsed/dropped/resolvedFromTransfer/storedTotal) are visible.

---

### User Story 2 - Owned catalog + instance pins (Priority: P1)

As a signed-in user with inventory synced and entity bundles loaded, I switch Catalog to **Owned**, see only owned definitions with badges, select a row, and see owned instance projections including **instanceId** usable for compose pin / equip / DIM.

**Why this priority**: Exit "Owned catalog usable to pin instances"; GAP-INV-06 web residual.

**Independent Test**: Catalog page tests with injected base items + bridge inventory assert Owned filter + instance id text.

**Acceptance Scenarios**:

1. **Given** entity catalog with items A (owned×2) and B (unowned), **When** scope is All, **Then** both appear; A shows owned badge.
2. **Given** same data, **When** scope is Owned, **Then** only A appears.
3. **Given** Owned scope and row A selected, **When** instances render, **Then** instanceIds and power are shown (power-desc).
4. **Given** empty entity base, **When** Owned is empty, **Then** UX still distinguishes entity-empty vs inventory-empty (DART-053 warning retained / catalog empty copy).

---

### User Story 3 - Cutover / gaps docs (Priority: P1)

As a cutover reviewer, I see GAP-WEB-01 closed, RB-02 cleared, RC-SYNC no longer FAIL solely for web owned depth (other RBs may still block PRODUCTION_CUTOVER).

**Why this priority**: Exit criteria for RB-02 / RC-SYNC web clause.

**Independent Test**: Doc greps + cutover validator green.

**Acceptance Scenarios**:

1. **Given** feature-gaps, **When** GAP-WEB-01 is read, **Then** status closed with DART-056 evidence.
2. **Given** cutover residual blockers, **When** RB-02 is read, **Then** cleared with web Settings sync + Owned catalog evidence.
3. **Given** RC-SYNC, **When** status is read, **Then** not FAIL solely for web owned depth (may still note live dual-run under RC-OPS if needed, but web depth blocker is gone).

---

### Edge Cases

- Writer tab blocked → Settings shows DB blocked; Sync now disabled or errors clearly; no OPFS corruption path
- Entity bundles empty after sync → Owned empty prefers entity-cache message (not “sync failed”)
- Transfer hashes without slot in prebuilt MVP → counted as droppedNonEquipment; weapons with slots still resolve
- Concurrent Sync now → SyncInProgressError surfaced; no double write corruption
- Soft guidance never auto-applies from this surface

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Jaspr MUST provide an inventory sync controller that calls `syncUserInventory` with production [equipmentBucketLookupBuilder] when entity/catalog data is available (same resolution rules as Windows post-DART-050 for web).
- **FR-002**: Settings UI MUST expose Sync now, busy, error, itemCount, sync meta, and last-sync diagnostics including `resolvedFromTransfer` when available.
- **FR-003**: Host tests MUST assert vault fixtures store equipment buckets and `resolvedFromTransfer > 0` when lookup is wired; without lookup, vault is not stored.
- **FR-004**: Catalog MUST support All | Owned scope using entity × inventory join (`annotateCatalogWithOwned` / `filterCatalogClient` with `CatalogScope.owned`).
- **FR-005**: Selecting an owned (or annotated) catalog row MUST show instance projections with instanceId for pin use.
- **FR-006**: Equip path MUST continue to use the same lookup builders (no regression of DART-050 Jaspr equip wiring).
- **FR-007**: Soft guidance MUST NOT auto-apply; clients MUST NOT embed CLIENT_SECRET.
- **FR-008**: Docs MUST close GAP-WEB-01, clear RB-02, and update RC-SYNC so it does not fail solely for web owned depth; roadmap marks DART-056 done.

### Key Entities

- **InventorySyncController** (web): phase, syncNow, refreshStatus, lastDiagnostics, localUserId
- **OwnedCatalogBridge** (web): annotatedBase, ownedCounts, instancesFor(hash)
- **EquipmentBucketLookupBuilder**: itemHash → equipment bucketHash from catalog slots

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Web Settings sync with vault fixtures + lookup stores vault weapon/armor with equipment bucket labels and `resolvedFromTransfer > 0`.
- **SC-002**: Catalog Owned filter shows only owned definitions; instance list exposes instanceId for pins.
- **SC-003**: Host tests cover vault resolution and Owned scope; web_host tests green.
- **SC-004**: GAP-WEB-01 closed; RB-02 cleared; RC-SYNC not FAIL solely for web owned depth.
- **SC-005**: Soft never auto-applies; no CLIENT_SECRET introduced.
- **SC-006**: Finish-spec rejects “sync button exists” alone — cites vault stored + Owned pin depth (PROC-01/04).

## Assumptions (summary)

See Assumptions A1–A5 above. No NEEDS CLARIFICATION retained.
