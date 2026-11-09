# Feature Specification: DART-025 Flutter Inventory Sync UI

**Feature Branch**: `dart-025-flutter-inventory-sync-ui`

**Created**: 2026-07-24

**Status**: Done (merged to `feature/multiplatform-dart`)

**Input**: User description: "Settings inventory sync card + busy/error UX. User can sync; P2 phase gate (owned data local)."

**Program ID**: DART-025  
**Phase**: P2  
**Depends**: DART-023 (Windows OAuth), DART-024 (profile + inventory sync algorithm)  
**Integration base**: `feature/multiplatform-dart`  
**Architecture**: [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)

## Scope boundary

**In scope:**

- Flutter Windows host **Settings inventory sync card**:
  - Show last sync metadata (item count, sync version, last full sync time) when available
  - Show fresh / stale hint using 60s window (`isInventoryFresh` / DBR-EQP-007)
  - **Sync now** action that runs DART-024 `syncUserInventory` into the host Drift DB
- **Busy / error UX**:
  - Disable Sync while a sync is in flight; show progress indicator
  - Surface `SyncInProgressError` as a clear busy message
  - Surface network/profile/auth failures without crashing the shell
- Wire **local user ensure** (`ensureUser` from OAuth Bungie membership id) so sync has a FK owner row
- Host injects `BungieProfileClient` (default `HttpBungieProfileClient` + public API key) — **no CLIENT_SECRET**
- Widget/controller tests with fake profile client + memory DB + signed-in session (no live Bungie)

**Out of scope (later slices):**

- Catalog all-vs-owned filter UI (DART-026)
- Equip orchestration / post-equip auto-sync (DART-037+)
- Token refresh orchestration when access token expired (show error; refresh may already exist on session later)
- Equipment-bucket lookup from entity stores (optional inject; default empty map → transfer items dropped per DART-024 A2)
- Jaspr / mobile Settings parity
- Soft guidance auto-apply (forbidden)
- Node sidecar / CLIENT_SECRET (forbidden)

### Assumptions

- **A1**: Explicit **Sync now** always runs a full replace (`syncUserInventory`), not only `syncIfStale`. Freshness is **display-only** so the user can force refresh after vault transfers.
- **A2**: Local user is resolved like product `requireUser`: `ensureUser(db, tokens.bungieMembershipId, membershipType: 0, displayName: '')`; DART-024 sync updates membership type/display from Destiny memberships.
- **A3**: Sync card is disabled / explanatory when signed out; OAuth remains on the account card (DART-023).
- **A4**: Access token is read from `WindowsOAuthSession.tokens`; expired tokens surface as Bungie HTTP errors in the error UX (no new refresh pipeline this slice).
- **A5**: Public API key is the same host-injected `BUNGIE_API_KEY` / bootstrap `apiKey` used for manifest; missing key → Sync fails with clear config error when HTTP client needs it.
- **A6**: Soft guidance never auto-applies; this slice does not touch domain save paths.
- **A7**: Completing this slice closes **P2 phase gate**: Public+PKCE OAuth + inventory full-replace so owned inventory can live in local Drift.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sync inventory from Settings (Priority: P1)

As a signed-in Windows user, I open Settings and use the inventory sync card to pull my Bungie profile inventory into the local database, then see item count and last-sync time update.

**Why this priority**: Roadmap exit “User can sync”; P2 gate “owned data local”.

**Independent Test**: Widget/controller test with signed-in session + fake profile client + memory DB → tap Sync → inventory rows + meta present; card shows counts.

**Acceptance Scenarios**:

1. **Given** signed-in session with access token and a fake profile returning N equipment items, **When** user taps Sync now, **Then** Drift inventory for the local user has N items, syncVersion ≥ 1, and the card shows item count + last sync timestamp.
2. **Given** a prior successful sync, **When** user syncs again with a different item set, **Then** inventory is replaced (orphans gone) and the card reflects the new count / higher sync version.
3. **Given** signed-out session, **When** Settings is shown, **Then** Sync now is disabled (or absent as primary CTA) and the card explains that sign-in is required.

---

### User Story 2 - Busy and error UX (Priority: P1)

As a user, while a sync is running I see busy feedback and cannot start a duplicate UI-driven sync; if sync fails (busy lock, no memberships, HTTP error), I see an error message and can retry after the failure clears.

**Why this priority**: Roadmap goal “busy/error UX”.

**Independent Test**: Controller unit/widget tests for in-flight busy, `SyncInProgressError`, and thrown profile errors.

**Acceptance Scenarios**:

1. **Given** sync in flight, **When** UI renders, **Then** a progress indicator is visible and Sync now is disabled.
2. **Given** exclusive lock busy (`SyncInProgressError`), **When** sync is attempted, **Then** the card shows a clear “already in progress” style error and does not crash.
3. **Given** profile client throws (e.g. no memberships / HTTP error), **When** sync runs, **Then** the card shows a short error message and prior inventory (if any) remains.

---

### User Story 3 - Freshness display (Priority: P2)

As a user, I can see whether the last full sync is considered fresh within 60 seconds so I understand whether another sync is likely needed before equip-style flows.

**Why this priority**: Surfaces DART-024 / DBR-EQP-007 freshness without blocking force-sync.

**Independent Test**: Seed `lastFullSyncAt` within/outside 60s; assert fresh vs stale label on card.

**Acceptance Scenarios**:

1. **Given** lastFullSyncAt within 60s, **When** card loads, **Then** freshness shows fresh (or equivalent).
2. **Given** lastFullSyncAt older than 60s or missing, **When** card loads, **Then** freshness shows stale / never synced.

---

### Edge Cases

- Signed in but empty inventory: success with itemCount=0, syncVersion increments.
- Concurrent second Sync tap while first in flight: ignored or surfaces busy; no double-replace corruption (DART-016 lock).
- Sign-out after sync: card returns to signed-out messaging; tokens remain out of SQLite.
- Soft guidance never auto-applies via sync UI.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Settings MUST show an inventory sync card (in addition to OAuth + manifest status).
- **FR-002**: Signed-in users MUST be able to trigger a full inventory sync that persists via DART-024 `syncUserInventory` into the host’s single `AppDatabase`.
- **FR-003**: After successful sync, the card MUST display at least item count and last full sync time (and ideally sync version).
- **FR-004**: While sync is in progress, UI MUST show busy state and MUST NOT start a second concurrent UI sync.
- **FR-005**: Sync failures MUST surface a user-visible error string; the app MUST remain usable.
- **FR-006**: Signed-out users MUST NOT be able to run a successful sync; UI MUST indicate sign-in is required.
- **FR-007**: Freshness display MUST use the 60s window (`isInventoryFresh` / `kEquipSyncFreshMs`).
- **FR-008**: No CLIENT_SECRET; tokens stay in secure `TokenStore` / session only (not SQLite plaintext).
- **FR-009**: Soft guidance MUST never auto-apply.
- **FR-010**: Completing this slice documents **P2 phase gate** closed (OAuth + owned inventory local).

### Key Entities

- **InventorySyncController**: session + db + profile client orchestration; busy/error/status for UI
- **InventorySyncCard**: Settings presentation of sync status + Sync now
- **InventorySyncStatus / SyncInventoryResult**: existing DART-016/024 meta (itemCount, syncVersion, lastFullSyncAt)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- User can sync from Settings in the Windows host (mocked E2E in tests)
- Busy and error paths covered by tests
- `flutter test` in `apps/windows_host` green
- No CLIENT_SECRET in host sources
- Soft never auto-applies
- Roadmap: DART-025 **done**; **P2 phase gate** noted complete; pointer → DART-026
