# Research: Owned Inventory Instance Detail

**Feature**: 003-owned-inventory-instances  
**Date**: 2026-06-28

## R1: Source of truth for instance data

**Decision**: Read synced rows from `inventory_items` via existing `inventoryRepository` functions; no Bungie API calls at list/detail time.

**Rationale**: Spec assumptions state sync already populates `instanceId`, `itemHash`, `bucket`, `location`, `power`, flags, `plugHashes`, `rollTags`, `syncedAt`. FR-013 forbids re-sync on search.

**Alternatives considered**:
- Live Bungie profile fetch per request — rejected (latency, rate limits, violates FR-013).
- New normalized plug table — rejected (schema change unnecessary; plugs stored as JSON array).

---

## R2: Plug name resolution strategy

**Decision**: Build an in-memory `Map<number, string>` at request time from manifest entity stores: `weapon-perks`, `mods`, `origin-traits` (and `abilities`/`aspects`/`fragments` if needed for armor intrinsics). Unresolved hashes return `{ hash, name: null, displayName: String(hash) }`. **v1 lists every plug hash from sync** (no roll-only filter). Plug DTO allows future optional `socketType` without breaking v1 clients (Session 2026-06-28).

**Rationale**: Sync pipeline already uses `weapon-perks` for roll tags (`buildPerkNameMap` in `syncInventory.ts`). Armor mod plugs align with `mods` store. FR-005/FR-006 require readable names with hash fallback. Full plug list aids QA sync verification; socket typing deferred.

**Alternatives considered**:
- Roll-relevant-only filter — rejected for v1 (classification rules, risk of hiding plugs).
- Persist resolved names at sync time — rejected (manifest drift; duplicates data).
- Full `ItemResolver` name search per plug — rejected (plugs are hashes; hash lookup is O(1)).

---

## R3: Instance list API shape and filters

**Decision**: Single `GET /api/user/inventory/instances` with optional query params:
- `itemHash` — all copies of one manifest item (US3)
- `bucket` — inventory bucket label (`Kinetic`, `Helmet`, etc.)
- `kind` — `weapons` | `armor` (maps to bucket sets from `filterItems.ts`)
- `q` — case-insensitive substring match on **resolved** plug display names (FR-003)

Optional `GET /api/user/inventory/instances/:instanceId` for single-row detail (same DTO).

**Rationale**: Mirrors catalog filter vocabulary; stable `instanceId` in response supports future set attachment (FR-012). Full list without pagination matches existing policy.

**Alternatives considered**:
- Embed instances only inside catalog API — rejected as sole surface (US3 needs direct access).
- GraphQL — rejected (no GraphQL in project).

---

## R4: Auth, empty, and sync-prompt behavior

**Decision**: Reuse `requireAuthenticatedUser` → `401` when unsigned. When signed in but `inventory_sync_meta.itemCount === 0`, return `{ instances: [], syncPrompt: true, message: "…" }` with `200` (consistent with owned catalog `syncPrompt`).

**Rationale**: FR-007, FR-008, SC-005; matches `resolveOwnedCatalogContext` patterns in `_ownedFilter.ts`.

**Alternatives considered**:
- `404` for empty sync — rejected (clients treat as error).

---

## R5: Catalog browse backward compatibility (US4)

**Decision**: Add optional query `includeInstancePointer=1` (owned scope only). When set, each owned catalog row gains `instancesHref` pointing to `GET /api/user/inventory/instances?itemHash={hash}`. **No inline instance arrays** on catalog rows. Debug catalog **auto-fetches** from `instancesHref` when user selects a row.

**Rationale**: FR-011 clarified (Session 2026-06-28): pointer-only keeps catalog payloads small; auto-fetch preserves one-step UX in debug without manual second action.

**Alternatives considered**:
- Inline full `ownedInstances` on each row — rejected (payload bloat with many copies × many catalog rows).
- Inline cap + pointer — rejected (user chose pointer-only).

---

## R6: Debug UI delivery

**Decision**: Extend `CatalogDebugPage`: after owned catalog search, clicking a result row fetches `GET /api/user/inventory/instances?itemHash={hash}` and renders structured instance cards beside JSON panel.

**Rationale**: FR-009; same auth/production rules as existing `/debug/*` layout.

**Alternatives considered**:
- New `/debug/inventory` page — rejected (spec says extend catalog experience).

---

## R7: Perk text search implementation

**Decision**: Load candidate instances from DB (by user + optional hash/bucket/kind), project plugs, filter in memory where any `displayName` or `name` contains `q` (normalized).

**Rationale**: Plug names not in SQLite; household-scale inventory fits in-memory filter. Consistent with `queryInventoryByTags` pattern.

**Alternatives considered**:
- SQLite JSON search on plug hashes only — rejected (cannot search by resolved name without manifest).

---

## R8: Future set attachment identifier

**Decision**: Use Bungie `instanceId` string (already unique per user in DB) as `instanceId` in API responses. Document in contract for `set_items` future `instanceId` field.

**Rationale**: FR-012; `annotateWeaponsWithInventory` already surfaces `matchingInstanceId`.

**Alternatives considered**:
- `characterId` only — rejected (user clarification: full label for multi-character households).
- Class without display name — rejected (user chose class + Bungie display name).

---

## R9: Character association on instance rows

**Decision**: When `location` is `character` or `equipped`, enrich instance DTO with `characterId`, `className` (Titan/Hunter/Warlock), and `characterDisplayName` from Bungie character roster via existing `getCharacters` profile client (Session 2026-06-28). Use account-level Bungie display name when per-character name is unavailable in API response. Omit display fields when vault or roster lookup fails.

**Rationale**: FR-004 clarified; helps distinguish copies across characters in SC-003/SC-004.

**Alternatives considered**:
- Persist character labels on `inventory_items` — rejected (no schema change v1).
- `characterId` only — rejected per clarification.
