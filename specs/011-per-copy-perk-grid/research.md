# Research: Per-Copy Weapon Perk Grid

**Feature**: 011-per-copy-perk-grid | **Date**: 2026-07-04 | **Phase**: 0

Resolves the unknowns in `plan.md` Technical Context. This feature **reopens 010's deferred R2** (per-instance reusable plugs + true per-column grouping) and replaces the weapon-type `perk-options` approximation with per-copy data.

---

## R1 — Capturing per-copy alternate plugs during inventory sync

**Question**: Where do a copy's real per-column alternates come from, and what must sync capture?

**Findings**:
- Today sync requests `INVENTORY_COMPONENTS = "102,201,205,300,305"` (`profile.ts:44`) and `parsePlugHashes` (`profile.ts:524`) keeps only the **enabled `plugHash` per socket** — alternates are discarded.
- Bungie **`DestinyItemReusablePlugsComponent` (component 310)** returns, per instance ID and socket index, the logic-driven plugs that instance **can insert** (`canInsert` / `enabled` on each reusable plug entry). This is the primary source for crafted weapons and many multi-perk columns.
- Component 310 alone is **incomplete**: randomized-roll sockets and profile/character-scoped plug sets require combining 310 with **`profilePlugSets`** and **`characterPlugSets`** on the profile response (returned when ItemSockets is requested; may also need explicit profile components `104` / `402` — verify in fixture tests during implementation).
- DIM uses this combination; our manifest extractors already resolve plug sets from definitions (`socketPlugHashes` in `common.ts`) but only at **item-definition** level for `WeaponRecord.perkColumns`, not per instance.

**Decision**: Extend sync to:
1. Add **`310`** to `INVENTORY_COMPONENTS`.
2. Parse `itemComponents.reusablePlugs.data[instanceId].plugs[socketIndex]` into `{ plugHash, canInsert?, enabled? }[]`, keeping only insertable hashes.
3. During sync parse, for each weapon/exotic weapon socket, also resolve **randomized / profile / character plug-set** alternates using the same profile plug-set maps returned with the inventory fetch (mirror DIM's `SocketPlugSources` flags: `ReusablePlugItems | ProfilePlugSet | CharacterPlugSet`).
4. Persist the merged per-socket result to a new **`socket_plugs` JSON column** on `inventory_items` (see data-model §2). Keep existing flat `plug_hashes` for backward compatibility and carousel equipped display.

**Rationale**: Per-copy alternates are instance state; they cannot be derived from `WeaponRecord.perkColumns`. Storing at sync time keeps instance listing/grid projection free of live Bungie calls (003 FR-013 pattern, same as 010's `gear_tier` decision).

**Degradation**: Rows with `socket_plugs = null` or empty reusable arrays for all perk sockets → `captureStatus: "pending"` until re-sync; after failed re-sync → `"unavailable"` with equipped-only grid (FR-015, FR-018).

**Alternatives considered**:
- *Live Bungie fetch on grid open*: rejected — violates DB-backed instance model; complicates auth/rate limits; auto re-sync is the one bounded exception.
- *Keep weapon-type `perk-options` as fallback*: rejected — contradicts FR-015 (must never show type pool as copy perks).
- *Separate `instance_socket_plugs` table*: rejected — JSON column matches existing `plug_hashes` / `stat_values` pattern; fewer joins for single-row instance fetch.

**To confirm at implementation**: Live profile fixture proving 310 + plug-set maps populate for a crafted weapon and a random-roll legendary; document final component string in `sync-socket-plugs-contract.md`.

---

## R2 — Grouping sockets into labeled columns (DIM-style)

**Question**: How do we map raw socket indexes to barrel / magazine / trait / intrinsic / origin / masterwork / catalyst columns?

**Findings**:
- Manifest weapon extractors already classify sockets: `getPerkSocketIndexes(item, WEAPON_PERKS_CATEGORY_HASH)` for trait/barrel/mag columns (`weapons.ts:85`), `isOriginSocket`, `isExcludedPerkSocket`, frame/intrinsic detection via `plugCategoryIdentifier` patterns (`common.ts:172–202`).
- 010 deferred column labels because `OwnedInstanceDetail.plugs[]` is flat socket-order with no category. With per-socket capture we can attach **`columnKind`** + **`columnLabel`** at sync or projection time using manifest item definition for the copy's `itemHash` (legendary via `weapons` store patterns; exotic via `exotic-weapons` + raw socket categories).
- FR-006 / FR-016 require intrinsic, origin, and masterwork as **separate columns** even when single-option; FR-021 excludes cosmetics (shaders, trackers, ornaments).

**Decision**: Add `classifyWeaponSocket(itemHash, socketIndex, manifestContext) → { columnKind, columnLabel, includeInGrid }` where:
- `columnKind` ∈ `barrel | magazine | trait | intrinsic | origin | masterwork | catalyst | other`
- `includeInGrid = false` for excluded categories (shader, tracker, ornament, empty cosmetic)
- Column **display order**: barrel → magazine → trait(s) in socket order → intrinsic → origin → masterwork → catalyst (when present)
- Grid columns with zero options after resolution are **omitted** (spec edge case)

**Rationale**: Reuses proven manifest classification from extractors; keeps grid labels stable across copies of the same weapon type while **options** differ per copy.

**Alternatives considered**:
- *Numeric column index only (010 style)*: rejected — fails FR-001 DIM-style layout and US1 acceptance.
- *Store column labels only in UI*: rejected — API should return labels for testability and future build UI reuse.

---

## R3 — Resolving the per-copy grid DTO

**Question**: What function assembles the grid from stored sync data + manifest names?

**Findings**:
- 010's `resolveWeaponPerkOptions(itemHash)` unions curated ∪ randomized at **type** level — wrong source for this feature.
- Instance row already has `plugHashes[]` (equipped) and will gain `socketPlugs[]`.
- Plug names resolve via existing `buildPlugNameMap` / `resolvePlugs` pipeline.

**Decision**: Add `resolveInstancePerkGrid({ item, socketPlugs, plugMap, manifestContext }) → InstancePerkGrid`:
- For each included socket: `equippedPlugHash` from socket row (must match enabled 305 plug), `options[]` = de-duplicated union of equipped + reusable alternates, each `{ hash, name, displayName, isEnhanced, isEquipped }`.
- **`isEquipped`**: true when hash === equipped plug for that column.
- Default selection: equipped hash per column (FR-003, FR-008).
- **`captureStatus`**: `complete` when all perk-bearing sockets for the item have been captured (reusable arrays present or confirmed single-option static roll); `pending` when row predates capture; `unavailable` after re-sync failure or unrecoverable parse gap.

**Rationale**: Pure, unit-testable projection; route handler loads DB row + manifest context then calls resolver.

**Alternatives considered**:
- *Embed grid on `OwnedInstanceDetail` list response*: rejected — bloats carousel fetch; grid stays lazy (010 perk-options pattern).

---

## R4 — Enhanced vs base perk labeling (FR-017)

**Question**: How do we detect and label enhanced perk variants?

**Findings**:
- Crafted/enhanced perks are distinct plug item hashes in Bungie data; both can appear in the same column's reusable set.
- Manifest plug items carry category identifiers and display names; enhanced variants often include "Enhanced" in the name but not reliably.
- DIM shows separate entries with enhanced styling based on plug investment tier / plug category.

**Decision**: When building grid options, set `isEnhanced: true` when plug item metadata indicates enhanced tier (implementation: check manifest plug `plugCategoryIdentifier` for enhanced patterns **or** `plugItemCategoryHash` membership in a small curated enhanced set — validate against one crafted fixture). Display name: **`${name} (Enhanced)`** when `isEnhanced` and name does not already contain "Enhanced" (FR-017). Both base and enhanced hashes remain separate selectable options.

**Rationale**: User explicitly chose separate labeled options; avoids collapsing distinct hashes.

**Alternatives considered**:
- *Name-only heuristic*: acceptable fallback when category metadata missing; tests cover at least one crafted weapon fixture.

---

## R5 — Auto re-sync when capture data is missing (FR-018)

**Question**: How to trigger re-sync on grid open without violating 003's DB-backed listing model or looping?

**Findings**:
- Full inventory sync already exposed at `POST /api/bungie/sync` with per-user **`SyncInProgressError`** lock (`syncInventory.ts:26`).
- Copies synced before this feature have `socket_plugs = null`.
- Spec requires automatic re-sync when grid opens for stale copy; equipped-only while pending/failed; no infinite loop.

**Decision**: Two-layer dedupe:
1. **Client** (`SetsDebugPage` / `perkGridRefresh.ts`): when grid returns `captureStatus: "pending"`, call `POST /api/bungie/sync` **at most once per `instanceId` per carousel session**; show loading state; re-fetch grid after sync completes (poll or await sync response then retry GET).
2. **Server**: grid endpoint never triggers sync inline (keeps GET idempotent). After sync attempt, if still incomplete → `captureStatus: "unavailable"` + equipped-only columns + indicator message. Never return weapon-type pool.

**Rationale**: Reuses existing sync pipeline; bounded client dedupe prevents loops; server stays cache-friendly.

**Alternatives considered**:
- *Server-side sync inside GET perk-grid*: rejected — surprising side effect on GET; harder to test.
- *Passive indicator only (no auto sync)*: rejected — user chose auto re-sync in clarification session.

---

## R6 — API surface and 010 migration

**Question**: New endpoint vs extend existing routes? What happens to `perk-options`?

**Findings**:
- `GET /api/user/inventory/instances/[instanceId]` exists but returns flat `OwnedInstanceDetail` without alternates.
- `GET /api/catalog/weapons/perk-options` is itemHash-scoped type pool (010 US4).
- Sets debug currently calls perk-options in `loadWeaponPerkOptions` (`SetsDebugPage.tsx:202`).

**Decision**:
- **New** `GET /api/user/inventory/instances/:instanceId/perk-grid` returning `InstancePerkGrid` (see contract).
- **Stop using** catalog perk-options in Sets debug; leave route in place for other/debug consumers until explicitly removed.
- `selectedPerks` on set attach remains ordered array of chosen hashes — **column order** matches grid column order (document in contract; same as today's column-index ordering).

**Rationale**: Clear ownership: per-copy data is inventory-scoped, not catalog-scoped.

---

## Cross-cutting decisions

- **Exotics in scope** (FR-016): same grid resolver; include catalyst column when socket present; trait/random columns when exotic has them.
- **Tests**: co-located unit tests for parse, classify, resolve, route; integration fixture with multi-perk crafted copy + two different random rolls proving SC-002.
- **Docs**: update `DEBUG.md` (perk-grid endpoint, auto re-sync flow, remove perk-options from Sets flow description).
