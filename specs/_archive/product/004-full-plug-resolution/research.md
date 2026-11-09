# Research: Full Inventory Plug Resolution

**Feature**: 004-full-plug-resolution  
**Date**: 2026-06-29

## R1: Why entity stores alone are insufficient

**Decision**: Feature 003's `buildPlugNameMap` (`weapon-perks`, `mods`, `origin-traits`) intentionally indexes only roll-column perks, armor mods, and traditional origin traits. Many equipped socket plugs are excluded at extract time (intrinsics, masterwork, shader, weapon mod, tracker sockets).

**Rationale**: Observed unresolved hashes on real weapons (e.g. The Ringing Nail): Precision Frame `1636108362`, Synergy `3634656993`, Default Shader `4248210736`, Reload Speed masterwork `882794620`, Forge's Kin `2034764268`, Kill Tracker `905869860`. These exist in `DestinyInventoryItemDefinition` but not in the three entity stores.

**Alternatives considered**:
- Add many new extractors (weapon-mods, intrinsics, shaders) — rejected for v1 (high manifest maintenance; still misses edge plugs).
- Full-table entity store of all plug items at refresh — rejected (large store build; overlaps raw table).

---

## R2: Hybrid plug name map (chosen approach)

**Decision**: Build `Map<number, string>` per instance request in two layers:

1. **Entity store layer** — merge hash→name from existing stores: `weapon-perks`, `mods`, `origin-traits` (003 baseline). Optionally merge `weapons`, `exotic-weapons`, `exotic-armor` for overlap (same pattern as `loadoutText.ts`); first-wins on duplicate hashes.
2. **Manifest fallback layer** — collect unique plug hashes from the user's equipment inventory rows (or single instance's `plugHashes`), find hashes missing from layer 1, batch-resolve via `ManifestService.loadRawTable(version, "DestinyInventoryItemDefinition")` using `getRaw` + `isUsable` + `projectBase` (same as `resolveInventoryHashProjections`).

**Rationale**: O(unique plug hashes) lookups per request; table load is cached by manifest service per version; achieves ≥99% coverage without sync/schema changes (FR-008, FR-009). Aligns with spec assumption that manifest defines plug display names.

**Alternatives considered**:
- Per-plug live Bungie API — rejected (rate limits; violates 003 read model).
- Persist names at sync — rejected (FR-009; manifest drift).
- Resolve only on detail endpoint — rejected (FR-007; `q` search needs same map on list).

---

## R3: Request-scoped hash collection

**Decision**: Extend `loadInstanceListContext` (or sibling `buildPlugMapForInventory`) to accept `plugHashes: number[]` gathered from DB before projection:

- **List route**: union of `plugHashes` from all equipment-bucket rows for the user (reuse `listInventoryItems` + bucket filter).
- **Detail route**: `plugHashes` from the single row.

Pass resulting map to `listUserInstances` / `projectInstance` unchanged.

**Rationale**: Avoid loading names for entire manifest; household inventories have bounded unique plug count. Context builder stays the single orchestration point.

**Alternatives considered**:
- Global plug index built at server startup — rejected (memory; version invalidation complexity).
- Lazy per-plug fetch without batching — rejected (N table loads).

---

## R4: Perk text search (`q`)

**Decision**: No filter logic changes. `filterInstances` already matches on `displayName` / `name` after projection; expanded map automatically enables search for non-roll plugs (FR-007).

**Rationale**: DRY; search quality is a direct function of resolution coverage.

**Alternatives considered**:
- Separate search index — rejected (unnecessary).

---

## R5: Sync pipeline and roll tags

**Decision**: **Out of scope** for 004. `syncInventory` continues using `weapon-perks`-only map for `computeRollTags`. Instance display and search use the expanded hybrid map only.

**Rationale**: FR-009 forbids persist-at-sync; roll tags are orthogonal to instance plug display. Aligning sync can be a follow-up if roll-tag rules need non-roll perk names.

**Alternatives considered**:
- Share hybrid map at sync — rejected (sync has no per-user plug hash batch in one place without loading all items — already available but not required for spec success criteria).

---

## R6: Contract and backward compatibility

**Decision**: `ResolvedPlug` JSON shape unchanged. Contract addendum documents expected resolution coverage and quickstart fixture hashes; no version bump required for clients ignoring `resolved` flag.

**Rationale**: FR-004, SC-004.

**Alternatives considered**:
- Add `socketType` — deferred from 003; not required for 004.

---

## R7: Test fixtures for SC-001

**Decision**: Document **The Ringing Nail** (`4206550094`) as primary weapon fixture with known previously-unresolved plug hashes. Armor fixture: any synced legendary piece with mod + masterwork sockets. Unit tests use inline hash→name maps; integration/quickstart validates against live manifest when available.

**Rationale**: Measurable SC-001/SC-003 without brittle full inventory snapshots.

**Alternatives considered**:
- Commit cached manifest snippets — rejected (size; use live manifest in manual quickstart only).
