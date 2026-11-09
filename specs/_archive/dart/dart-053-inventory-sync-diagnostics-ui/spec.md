# Feature Specification: DART-053 Inventory Sync Diagnostics UI

**Feature Branch**: `dart-053-inventory-sync-diagnostics-ui`

**Created**: 2026-07-25

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Settings UI: raw/parsed/dropped/vault resolved counts + entity-cache empty warning. GAP-INV-04, GAP-INV-06 UX. Controller retains last SyncInventoryResult diagnostics; Settings (Windows + web parity path) surfaces raw/parsed/dropped + resolution.resolvedFromTransfer/droppedNonEquipment/storedTotal; entity-cache empty warning so empty Owned is not blamed solely on inventory sync"

**Program ID**: DART-053  
**Phase**: P6  
**Depends**: DART-025, DART-050  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) (pure Dart I/O; no CLIENT_SECRET; soft never auto-applies)  
**Gaps**: [docs/multiplatform-dart-feature-gaps.md](../../docs/multiplatform-dart-feature-gaps.md) — **GAP-INV-04**, **GAP-INV-06** UX half

## Scope boundary

**In scope:**

- Controller retains last successful `SyncInventoryResult.diagnostics` (not only itemCount / partial resolution ints)
- Pure `formatSyncDiagnostics` (Next `ManifestCard` parity) for raw/parsed/dropped + resolution lines
- Windows Settings `InventorySyncCard` surfaces diagnostics after sync: raw total, parsed total, dropped unknown/missing, `resolvedFromTransfer` / `droppedNonEquipment` / `storedTotal`
- Entity-cache empty / missing warning on Settings and Catalog Owned empty states so empty Owned is not blamed solely on inventory sync (GAP-INV-06 UX)
- Web Settings parity path: entity/owned dependency warning copy + shared format helper usable when web sync lands (DART-056)
- Unit/widget tests for format + controller retention + card keys + owned empty messaging
- Gap/docs updates (GAP-INV-04 closed or partial with residual; GAP-INV-06 UX half closed)
- Soft never auto-applies; no CLIENT_SECRET

**Out of scope (do not implement in this slice):**

- Live Next-vs-Dart inventory harness (DART-054 / GAP-INV-05)
- Full web inventory sync depth / Owned pin equip (DART-056)
- New vault resolution algorithm (DART-050 done)
- Roll tags / socket enrichment (DART-051/052 done)
- Soft guidance auto-apply (forbidden)
- CLIENT_SECRET / Node sidecar

## Assumptions

- **A1**: Diagnostics are session-ephemeral (last successful `syncNow` only); not persisted to Drift beyond existing itemCount/syncVersion/lastFullSyncAt.
- **A2**: `refreshStatus` does not clear last diagnostics; sign-out / signed-out refresh clears them.
- **A3**: Manifest match sub-block in Next (`diagnostics.manifest`) is optional; Dart may omit if not populated — format still shows raw/parsed/dropped/resolution.
- **A4**: Web Settings has no full inventory sync card yet; parity path = shared pure formatter + explicit Owned/entity warning panel (full sync UI remains DART-056).
- **A5**: Soft never auto-applies; no confidential secrets in clients.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Retain and format last sync diagnostics (Priority: P1)

As a multiplatform engineer / signed-in Guardian, after inventory sync the host keeps the full parse/resolution diagnostics so drops and vault resolution are inspectable, not only `itemCount`.

**Why this priority**: GAP-INV-04 exit core; silent vault loss is the problem.

**Independent Test**: Controller unit tests after `syncNow` expose raw/parsed/dropped/resolution fields; pure `formatSyncDiagnostics` unit tests match Next line shapes.

**Acceptance Scenarios**:

1. **Given** a successful `syncUserInventory` result, **When** controller finishes `syncNow`, **Then** it retains `lastDiagnostics` with raw.total, parsed.total, dropped totals, and resolution (resolvedFromTransfer, droppedNonEquipment, storedTotal).
2. **Given** vault fixtures with lookup wired, **When** sync succeeds, **Then** `lastDiagnostics.resolution.resolvedFromTransfer > 0` and formatter includes vault/postmaster line.
3. **Given** vault fixtures without lookup, **When** sync succeeds with 0 stored, **Then** diagnostics still show raw/parsed and resolution with droppedNonEquipment / resolvedFromTransfer reflecting drop path.
4. **Given** sign-out, **When** status refreshes, **Then** retained diagnostics clear with other meta.

---

### User Story 2 - Settings surfaces diagnostics (Windows + web path) (Priority: P1)

As a Guardian on Settings, I can read last-sync raw/parsed/dropped/resolution counts without opening logs.

**Why this priority**: Exit criteria require Settings surface, not only controller fields.

**Independent Test**: Widget tests assert diagnostics keys/text after Sync now; web Settings test asserts entity/owned warning (and format helper if exposed).

**Acceptance Scenarios**:

1. **Given** signed-in Windows Settings after successful sync, **When** card rebuilds, **Then** diagnostics block shows raw total, parsed total, dropped (unknown/missing), and resolution stored/resolvedFromTransfer/droppedNonEquipment.
2. **Given** no successful sync yet this session, **When** card shows status, **Then** diagnostics block is absent or shows “no diagnostics yet” without inventing counts.
3. **Given** web Settings, **When** page renders, **Then** Owned/entity-cache dependency warning is visible (parity path for GAP-INV-06).

---

### User Story 3 - Entity-cache empty warning for Owned (Priority: P1)

As a Guardian with empty Owned catalog, I am not told “only sync inventory” when entity stores are missing/empty.

**Why this priority**: GAP-INV-06 UX half; vault fix alone is insufficient for Owned definitions.

**Independent Test**: Catalog Owned empty + Settings entity warning widget tests.

**Acceptance Scenarios**:

1. **Given** entity cache missing/empty (`noVersion` / `noStores`), **When** Catalog Owned scope is empty, **Then** message states entity stores are required and empty Owned is not solely an inventory sync problem.
2. **Given** Settings manifest status with null/empty entity cache, **When** page shows status, **Then** an explicit warning banner/key is present.
3. **Given** entity cache populated and inventory empty, **When** Owned is empty, **Then** message may still direct user to Sync now (sync is the correct action).

---

### Edge Cases

- Sync error: do not replace last successful diagnostics with partial failure state (keep previous success or leave null).
- Concurrent sync busy: no diagnostics mutation.
- Zero raw items membership: show zeros, not blank invent.
- Very large unknownBuckets map: formatter may top-N like Next (optional polish).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `InventorySyncController` MUST retain last successful `InventoryParseDiagnostics` from `SyncInventoryResult`.
- **FR-002**: Controller MUST expose resolution fields including `resolvedFromTransfer`, `droppedNonEquipment`, `storedTotal` (and raw/parsed/dropped totals via diagnostics or getters).
- **FR-003**: Pure `formatSyncDiagnostics` MUST produce human-readable lines for raw total, parsed total (+ equipment/subclass), dropped (+ unknown/missing), and resolution when present.
- **FR-004**: Windows `InventorySyncCard` MUST surface those diagnostics after a successful in-session sync.
- **FR-005**: Settings MUST warn when entity cache is missing/empty so Owned emptiness is not blamed solely on inventory sync.
- **FR-006**: Catalog Owned empty state MUST prefer entity-cache warning over inventory-only blame when emptyReason is noVersion/noStores.
- **FR-007**: Web Settings MUST include parity warning copy for Owned ↔ entity dependency (full web sync UI deferred to DART-056).
- **FR-008**: Soft guidance MUST never auto-apply; clients MUST NOT embed CLIENT_SECRET.
- **FR-009**: Tests MUST cover format, controller retention, card surface, and entity/owned warning.

### Success Criteria

- **SC-001**: GAP-INV-04 closed (or partial only if residual thinning documented with GAP/RB).
- **SC-002**: GAP-INV-06 UX half closed; docs residual from DART-050 remains documented.
- **SC-003**: Widget/unit tests green for windows_host + bungie format helper; web Settings warning test green.
- **SC-004**: Roadmap DART-053 → done; Current pointer → DART-054.
- **SC-005**: Soft never auto-applies; no CLIENT_SECRET.

## Non-goals

- Live dual-run harness (DART-054)
- Web inventory Sync now card (DART-056)
- Changing vault resolution algorithm
