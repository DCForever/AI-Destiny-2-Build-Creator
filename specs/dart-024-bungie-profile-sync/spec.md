# Feature Specification: DART-024 Bungie Profile Sync

**Feature Branch**: `dart-024-bungie-profile-sync`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Profile fetch + inventory sync algorithm into Drift. Full replace + sync_version; 60s freshness helper."

**Program ID**: DART-024  
**Phase**: P2  
**Depends**: DART-021 (Bungie HTTP), DART-016 (inventory full-replace + busy lock + sync meta)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- **Bungie profile client** (on `destiny2_bungie`) using shared `BungieHttpClient`:
  - `getMemberships` (`/User/GetMembershipsForCurrentUser/`)
  - `getFullInventory` / `getFullInventoryWithDiagnostics` (`GetProfile` inventory components)
- **Inventory parse** of vault / character inventory / character equipment into raw items + diagnostics (product `profile.ts` shape, MVP fields)
- **Inventory bucket constants** + equipment vs transfer-container classification
- **Sync algorithm** that:
  - Resolves Destiny membership (first / primary-sorted membership)
  - Updates local user `membershipType` + `displayName` when changed
  - Fetches full inventory, maps to `InventoryItemRecord`
  - Optionally resolves transfer-container (vault/postmaster) items via injectable equipment-bucket lookup
  - Performs **full replace** via DART-016 `replaceInventoryBatchExclusive` (bumps `sync_version`, `itemCount`, `lastFullSyncAt`)
  - Surfaces concurrent sync as typed busy error
- **60s freshness helper** (`isInventoryFresh` + `syncIfStale`) per DBR-EQP-007 / product `EQUIP_SYNC_FRESH_MS = 60_000`
- Unit tests with **mocked HTTP** + in-memory Drift (no live Bungie; no CLIENT_SECRET)

**Out of scope (later slices):**

- Flutter Settings inventory sync UI (DART-025)
- Catalog all-vs-owned projections (DART-026)
- Full roll-tag enrichment via entity perk catalog (optional minimal Crafted tag only)
- Full `buildStoredSocketPlugs` columnKind enrichment (store simplified socket capture maps when present)
- Manifest download / equipment lookup construction (host may inject hash→bucket map; no raw manifest load required here)
- Equip write orchestration (DART-037)
- OAuth UI / token storage (DART-022/023)
- Node sidecar / CLIENT_SECRET (forbidden)
- Soft guidance auto-apply (forbidden)

### Assumptions

- **A1**: Sync orchestration lives in `packages/bungie` and depends on `destiny2_db` for full-replace + status reads. Profile parse remains transport/DTO-only; write path is explicit.
- **A2**: Without an equipment-bucket lookup, transfer-container items (vault General / Postmaster) are **dropped** after parse (product parity when resolution fails). Equipment + subclass buckets always stored.
- **A3**: `rollTags` default empty; if `isCrafted`, include `"Crafted"`. Full perk-name roll tags deferred until entity cache wiring is required by a later slice.
- **A4**: `socketPlugs` stores simplified capture maps `{socketIndex, equippedPlugHash, reusablePlugHashes}` when sockets present for weapons/transfer items; columnKind labels deferred.
- **A5**: Fresh window is **60_000 ms** (DBR-EQP-007). Callers inject `nowMs` for tests.
- **A6**: Primary membership sort uses Bungie `primaryMembershipId` when present (product `parseMembershipsResponse`).
- **A7**: Soft guidance never auto-applies; this slice has no domain save path.
- **A8**: No CLIENT_SECRET / no token persistence in this package (tokens are runtime arguments).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Profile memberships + full inventory fetch (Priority: P1)

As a multiplatform data layer, I can call a Bungie profile client with an access token to list Destiny memberships and fetch a parsed full inventory (vault + character inventory + equipped) with diagnostics, using the shared HTTP client (mocked in tests).

**Why this priority**: Roadmap goal “Profile fetch”; foundation for sync.

**Independent Test**: Mock transport returns memberships + GetProfile fixture; assert memberships order, item fields, diagnostics totals.

**Acceptance Scenarios**:

1. **Given** memberships response with primaryMembershipId, **When** `getMemberships`, **Then** primary membership is first and display names map from bungieGlobalDisplayName/displayName.
2. **Given** full inventory fixture with vault/character/equipped items + instance/sockets, **When** `getFullInventory`, **Then** items include correct location, power, plugs, isMasterwork/isCrafted.
3. **Given** items with unknown/non-parsable buckets or missing instance ids, **When** parse, **Then** they are dropped and diagnostics count reasons.

---

### User Story 2 - Full-replace inventory sync + sync_version (Priority: P1)

As a multiplatform host, I can run `syncUserInventory` for a local user id + access token so inventory is fully replaced in Drift and `inventory_sync_meta.syncVersion` / `lastFullSyncAt` / `itemCount` advance atomically with the replace.

**Why this priority**: Roadmap exit “Full replace + sync_version”.

**Independent Test**: Memory DB user + mock profile client → sync → list inventory + status; second sync bumps version; concurrent exclusive sync busy.

**Acceptance Scenarios**:

1. **Given** a user and mock inventory of N equipment items, **When** `syncUserInventory`, **Then** Drift has N items, status.itemCount=N, syncVersion=1, lastFullSyncAt set.
2. **Given** a prior sync, **When** sync again with a different set, **Then** orphans gone, syncVersion increments by 1.
3. **Given** empty memberships, **When** sync, **Then** throws clear error and inventory unchanged.
4. **Given** sync already in flight for user, **When** second sync starts, **Then** busy error; first still completes.
5. **Given** membership type/display differs from stored user, **When** sync, **Then** user row membership fields update.

---

### User Story 3 - 60s freshness helper (Priority: P1)

As equip / Settings callers, I can ask whether inventory is fresh within 60 seconds and run `syncIfStale` to skip network when fresh or perform a full sync when stale/missing.

**Why this priority**: Roadmap exit “60s freshness helper”; DBR-EQP-007.

**Independent Test**: Seed meta lastFullSyncAt; assert isInventoryFresh edges; syncIfStale skips vs runs.

**Acceptance Scenarios**:

1. **Given** lastFullSyncAt 30s ago, **When** `isInventoryFresh`, **Then** true.
2. **Given** lastFullSyncAt 61s ago or null/invalid, **When** `isInventoryFresh`, **Then** false.
3. **Given** fresh meta, **When** `syncIfStale`, **Then** synced=false and profile inventory is not fetched.
4. **Given** stale meta, **When** `syncIfStale`, **Then** synced=true and full replace runs.

---

### Edge Cases

- Empty inventory still full-replaces (itemCount=0, syncVersion increments).
- Transfer-container items without equipment lookup are dropped (not stored as Unknown).
- Transfer-container items with lookup map to equipment bucket labels and are stored.
- Soft guidance never auto-applies via sync.
- Access tokens never written to SQLite by this slice.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Package MUST expose a profile client capable of memberships + full inventory parse via `BungieHttpClient` (injectable transport).
- **FR-002**: Sync MUST call DART-016 full-replace exclusive path so concurrent per-user sync is rejected.
- **FR-003**: Successful sync MUST bump `syncVersion` by 1 and set `lastFullSyncAt` + `itemCount` consistently with stored rows.
- **FR-004**: Package MUST expose `isInventoryFresh` with default fresh window **60_000 ms**.
- **FR-005**: Package MUST expose `syncIfStale` that skips sync when fresh and otherwise runs `syncUserInventory`.
- **FR-006**: No CLIENT_SECRET fields; tokens are call arguments only.
- **FR-007**: Soft guidance never auto-applies.
- **FR-008**: Flutter Settings UI MUST NOT be implemented in this slice (DART-025).

### Key Entities

- **DestinyMembership**: membershipType, membershipId, displayName
- **RawInventoryItem**: instanceId, itemHash, bucketHash, location, power, plugs, flags, optional stats/socketCapture
- **InventoryParseDiagnostics**: raw/parsed/dropped counters
- **SyncInventoryResult**: itemCount, syncVersion, lastFullSyncAt, diagnostics
- **SyncIfStaleResult**: synced flag + optional result

## Success Criteria *(mandatory)*

### Measurable Outcomes

- `dart test packages/bungie` green with profile + sync + freshness coverage
- Full replace proven via Drift list/status after sync
- `syncVersion` increments across successive syncs
- Freshness helper honors 60s window with injectable clock
- No CLIENT_SECRET in package sources
- Soft never auto-applies
)
