# Research: DART-025 Flutter Inventory Sync UI

## Decisions

### R1 — Force sync vs syncIfStale

**Decision**: Settings **Sync now** always calls `syncUserInventory` (full replace).  
**Rationale**: Users expect a manual button to refresh after vault changes even within 60s. Freshness is informational (equip paths may use `syncIfStale` later).  
**Alternatives**: Only `syncIfStale` — rejected for Settings UX.

### R2 — Local user key

**Decision**: `ensureUser(db, bungieMembershipId: tokens.bungieMembershipId, membershipType: 0, displayName: '')` matching product `requireUser.ts`.  
**Rationale**: DART-024 already updates membership type/display during sync.

### R3 — Profile client injection

**Decision**: `AppServices` holds `BungieProfileClient`; bootstrap builds `HttpBungieProfileClient` from public API key; tests inject fakes.  
**Rationale**: Matches DART-023 OAuth client injection pattern; no live Bungie in CI.

### R4 — Busy model

**Decision**: Controller-level `_syncing` flag for UI; DART-016 exclusive lock still protects concurrent replaces; map `SyncInProgressError` to user message.  
**Rationale**: Double-tap must not hang UI; lock is data-layer backstop.

## References

- DART-023 OAuth account card patterns
- DART-024 `syncUserInventory` / `isInventoryFresh`
- Product `src/lib/auth/requireUser.ts`
