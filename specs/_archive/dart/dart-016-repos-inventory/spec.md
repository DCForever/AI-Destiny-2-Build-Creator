# Feature Specification: DART-016 Repos Inventory

**Feature Branch**: `dart-016-repos-inventory`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Inventory repository + full-replace transaction shape + sync metadata fields. Composite unique; batch insert in one transaction; busy lock hook."

**Program ID**: DART-016  
**Phase**: P1  
**Depends**: DART-014 (schema + migrations); tables already include inventory (DART-013)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Drift-backed **inventory repository** in `packages/db` for:
  - **Full-replace batch write** (`replaceInventoryBatch` / product `upsertInventoryBatch` shape): upsert all items for a user, delete orphans not in the batch, bump `inventory_sync_meta` (`itemCount`, `syncVersion`, `lastFullSyncAt`), set `users.last_sync_at` — **all in one SQLite transaction**
  - **Composite unique** `(user_id, instance_id)` respected by conflict upsert and proven in tests
  - **Sync metadata read** (`getInventoryStatus`)
  - **Query helpers** used by later catalog/owned paths: list, by bucket, by item hashes, by instance ids, optional roll-tag filter
  - **Busy lock hook**: in-process per-user exclusive gate so concurrent full-replace for the same user fails fast with a typed busy error (mirrors product `syncLocks` / `SyncInProgressError` intent; no network)
- Pure Dart I/O only (Drift/sqlite3); co-located tests under `packages/db/test/`

**Out of scope (later slices):**

- Bungie profile fetch / HTTP inventory sync algorithm (DART-024)
- OAuth / tokens (DART-022+)
- Flutter Settings sync UI (DART-025)
- Manifest / entity enrichment of inventory rows (DART-017+)
- Library build/set/synergy CRUD (DART-015 done)
- Application use cases / hard gates (DART-027+)
- Soft guidance evaluation or auto-apply (forbidden)
- Node sidecar / CLIENT_SECRET (forbidden)

### Assumptions

- **A1**: Persistence record types live in `destiny2_db` (not pure domain). Mapping to domain later is use-case work.
- **A2**: Full-replace is the only write path this slice needs; no partial single-item upsert API required beyond what the batch path uses internally.
- **A3**: Callers supply ISO-8601 `syncedAt` / `now` strings; repo does not invent wall-clock when tests pass fixed timestamps.
- **A4**: Busy lock is **in-process** (Map/Completer per isolate). Cross-process SQLite locking is OS-level and out of scope; single-writer product rule still applies.
- **A5**: Empty batch deletes all inventory rows for the user and still bumps `syncVersion` (product parity).
- **A6**: Soft guidance never auto-applies; inventory repos are pure persistence.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Full-replace inventory in one transaction (Priority: P1)

As a multiplatform data layer, I can replace a user's owned inventory instances in a single transaction so a failed mid-write never leaves half-old half-new rows, and sync metadata (`itemCount`, `syncVersion`, `lastFullSyncAt`) advances atomically with the items.

**Why this priority**: Roadmap exit — “batch insert in one transaction” + “sync metadata fields.”

**Independent Test**: Memory DB + user → replace with N items → list matches; replace with different set → orphans gone; meta.itemCount/syncVersion/lastFullSyncAt updated; empty replace clears items.

**Acceptance Scenarios**:

1. **Given** a user with no inventory, **When** `replaceInventoryBatch` with two items, **Then** list returns both; status has itemCount=2, syncVersion=1, lastFullSyncAt set.
2. **Given** existing items A,B, **When** replace with B',C (same instance B updated, A orphan), **Then** A is gone, B fields updated, C present; syncVersion increments by 1.
3. **Given** any prior inventory, **When** replace with empty list, **Then** no items remain; itemCount=0; syncVersion still increments.
4. **Given** a replace, **When** transaction would fail mid-way (e.g. simulated bad FK), **Then** prior inventory/meta remain unchanged (all-or-nothing).

---

### User Story 2 - Composite unique (user_id, instance_id) (Priority: P1)

As a data layer, inventory rows are uniquely identified by `(userId, instanceId)` so full-replace upserts update in place rather than duplicating instances.

**Why this priority**: Roadmap exit — “Composite unique.”

**Independent Test**: Insert same (user, instance) twice outside replace → unique violation; replace upsert updates fields without duplicate rows.

**Acceptance Scenarios**:

1. **Given** an inventory row for (user, inst-1), **When** raw second insert of same pair, **Then** SQLite unique constraint fails.
2. **Given** an inventory row for (user, inst-1) with power=10, **When** replace batch includes inst-1 with power=20, **Then** exactly one row remains with power=20.

---

### User Story 3 - Busy lock hook (Priority: P1)

As a host coordinating inventory sync, concurrent full-replace for the same user is rejected with a typed busy error so UI can show “sync already in progress” without interleaving two replace transactions.

**Why this priority**: Roadmap exit — “busy lock hook.”

**Independent Test**: Hold exclusive lock / start slow replace for user A; second exclusive replace for A throws busy; replace for user B still allowed; after first completes, A can replace again.

**Acceptance Scenarios**:

1. **Given** user A lock held (or first exclusive replace in flight), **When** second exclusive replace for A starts, **Then** `InventoryReplaceBusyException` (or equivalent) is thrown and first completes successfully.
2. **Given** lock held for A, **When** exclusive replace for B runs, **Then** B succeeds.
3. **Given** lock released, **When** A exclusive replace runs again, **Then** it succeeds.
4. **Given** `isInventoryReplaceBusy(userId)`, **When** lock held, **Then** true; after release, false.

---

### User Story 4 - Query helpers (Priority: P2)

As later catalog/owned and pin enrichment code, I can list inventory by user, filter by bucket/hashes/instance ids, and read sync status without re-implementing SQL.

**Why this priority**: Enables DART-024/026 without expanding this slice into network.

**Independent Test**: Seed via replace; query filters return expected subsets only for that user.

**Acceptance Scenarios**:

1. **Given** mixed buckets, **When** `queryInventoryByBucket`, **Then** only matching bucket rows.
2. **Given** hashes subset, **When** `queryInventoryByHashes`, **Then** only matching hashes; empty hash list → empty result.
3. **Given** instance ids, **When** `queryInventoryByInstanceIds`, **Then** only those instances.
4. **Given** two users, **When** list for user A, **Then** never includes user B rows.

---

### Edge Cases

- JSON columns (`plugHashes`, `rollTags`, `statValues`, `socketPlugs`) round-trip; null optional fields stay null.
- `location` stored as string (`vault` | `character` | `equipped`); invalid strings not validated this slice.
- User without sync meta → `getInventoryStatus` returns null until first replace.
- Soft never auto-applies via repository methods.
- Busy lock is per isolate/process; not a durable DB lock table.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST expose inventory repository APIs on `AppDatabase` for full-replace batch write and status/query reads.
- **FR-002**: Full-replace MUST run item upserts, orphan deletes, `inventory_sync_meta` upsert, and `users.last_sync_at` update in **one** transaction.
- **FR-003**: Full-replace MUST bump `syncVersion` by 1 per successful replace (from 0 if no prior meta).
- **FR-004**: Schema/repo MUST enforce composite unique `(user_id, instance_id)`; tests MUST prove uniqueness and upsert-in-place.
- **FR-005**: Package MUST expose a **busy lock hook** for per-user exclusive full-replace that throws when already busy.
- **FR-006**: Query helpers MUST support list, by bucket, by hashes, by instance ids (user-scoped).
- **FR-007**: Pure packages MUST remain free of Drift; inventory code lives in `destiny2_db`.
- **FR-008**: No Bungie network, no CLIENT_SECRET, no Node sidecar.
- **FR-009**: Soft guidance never auto-applies.
- **FR-010**: Bungie profile parse / HTTP sync algorithm MUST NOT be implemented in this slice (DART-024).

### Key Entities

- **InventoryItemRecord**: owned instance row (instanceId, itemHash, bucket, location, plugs, tags, stats, socketPlugs, syncedAt, …)
- **InventorySyncStatus**: itemCount, syncVersion, lastFullSyncAt
- **InventoryReplaceBusyException**: concurrent exclusive replace rejected
- **InventoryBusyLock**: in-process exclusive gate hook

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `dart test packages/db` passes including full-replace transaction, composite unique, busy lock, and query tests.
- **SC-002**: Specs under `specs/dart-016-repos-inventory/`; branch merges to `feature/multiplatform-dart` only.
- **SC-003**: Exit criteria satisfied: composite unique + batch insert in one transaction + busy lock hook.
- **SC-004**: No pure-package Drift dependency regression.
