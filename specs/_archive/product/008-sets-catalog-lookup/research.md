# Research: Sets Catalog-Style Item Lookup

**Feature**: 008-sets-catalog-lookup  
**Date**: 2026-06-29

## R1: API surface — extend Catalog vs dedicated Sets lookup

**Decision**: Extend **`GET /api/catalog/weapons`** and **`GET /api/catalog/armor`** with new query parameters. Debug Sets UI and future production set editor call the same endpoints as Catalog.

**Rationale**: Spec requires "the same way of lookup that the Catalog supports" (FR-001, FR-005). Avoids divergent filter logic and duplicate DTOs.

**Alternatives considered**:
- New `/api/user/sets/lookup` — rejected (parallel maintenance, behavioral drift).
- Client-side full manifest download — rejected (performance, constitution V).

---

## R2: Weapon perk filter implementation

**Decision**: Add optional query param `perk` (display name substring or numeric hash). Resolve name via `weapon-perks` store (same substring rules as synergy picker). Filter catalog rows to weapons present in `perkWeaponIndex.byPerk[perkHash]`. Combine with existing `q`, `slot`, `scope`, fuse name search.

**Rationale**: `perkWeaponIndex` already built at entity cache rebuild; used by `suggestRolls` and LLM tools. Covers curated + randomized columns per spec edge case.

**Alternatives considered**:
- Scan all `WeaponRecord.perkColumns` per request — rejected (O(weapons × perks) on every search).
- Only intrinsic/exotic perks — rejected (spec includes rollable legendaries).

---

## R3: Weapon origin trait filter implementation

**Decision**: Add optional query param `originTrait` (name substring or hash). Resolve hash via `origin-traits` store. Filter weapons where `WeaponRecord.originTraitHashes` includes resolved hash. Exotic weapons included when trait is intrinsic.

**Rationale**: Origin traits already denormalized on weapon records at extract time; no new index required at v1 scale.

**Alternatives considered**:
- New `originTraitWeaponIndex` artifact — deferred (YAGNI unless perf fails gate).

---

## R4: Armor catalog gap — legendary set pieces

**Decision**: Introduce `buildLegendaryArmorCatalogRows(setBonuses, manifestItemLoader)` producing `CatalogItem`-compatible rows for each hash in `SetBonusRecord.itemHashes`, with fields: `hash`, `name`, `icon`, `slot`, `classType`, `setBonusName`, `setBonusHash`, `isExotic: false`. Merge with existing `exotic-armor` rows in `filterArmorCatalog`.

**Rationale**: Current `ArmorCatalogSource` is exotic-only (`filterItems.ts`). Set bonus families are legendary; `set-bonuses` store already lists member `itemHashes`.

**Alternatives considered**:
- New `legendary-armor` entity store — deferred (projection at filter time sufficient for v1).
- Inventory-only armor browse — rejected (fails unowned manifest browse, FR-005).

---

## R5: Armor set bonus filter

**Decision**: Add optional query param `setBonus` (set name substring or `set-bonuses` hash). Resolve to one or more `SetBonusRecord` entries; restrict catalog rows to union of matching sets' `itemHashes` (plus slot/class/`q` filters). Exotics excluded when filter active unless hash is in set (rare; spec edge case).

**Rationale**: Aligns with synergy picker `armor_set_bonus` vocabulary; user searches by family name (e.g. *Eutechnology*).

**Alternatives considered**:
- Reuse `/api/catalog/synergy-pickers/links?kind=armor_set_bonus` for item list — rejected (returns bonus perk rows, not attachable armor pieces).

---

## R6: Armor instance stat capture

**Decision**: During inventory sync, parse Bungie profile `itemComponents.stats.data[instanceId].stats[]` for armor buckets. Map known stat hashes (from `dimLoadout.ts` / manifest `stats` store) to six `ArmorStatName` keys. Persist as JSON `stat_values` on `inventory_items`. Re-sync backfills existing rows.

**Rationale**: `OwnedInstanceDetail` has no stats today; FR-007 cannot be met without persistence. Sync-time capture matches plug capture pattern (003).

**Alternatives considered**:
- Compute from mod plugs only — rejected (inaccurate vs actual rolled stats).
- Query Bungie at instance list time — rejected (latency, rate limits).

---

## R7: Armor instance stat sorting

**Decision**: Add optional `sortBy` query param on `GET /api/user/inventory/instances`:
- `total` (default when param omitted for armor stat pickers)
- `Health` | `Melee` | `Grenade` | `Super` | `Class` | `Weapons`

Sort descending; tie-break: total stats → power → `instanceId`. Rows with missing `stat_values` sort last and include `statsIncomplete: true` on DTO.

**Rationale**: Spec acceptance scenarios; weapon instances keep power-only sort (unchanged).

**Alternatives considered**:
- Client-side sort only — rejected (API must be consistent for future production UI).

---

## R8: Instance perk/trait drill-down for weapons

**Decision**: Reuse existing instance API `q` param (resolved plug name substring) after catalog row select. Debug Sets passes active `perk` or `originTrait` filter text as `q` when fetching instances so only matching copies appear (FR-004).

**Rationale**: 003 already implements perk text filter on projected plugs; no new instance filter param needed for v1.

**Alternatives considered**:
- Separate `perkHash` instance filter — deferred (name `q` sufficient for debug; hash param can be added if needed).

---

## R9: Debug Sets UI composition

**Decision**: Add **Item lookup** fieldset to `SetsDebugPage.tsx` mirroring `CatalogDebugPage` filter controls (scope, q, slot locked to set slot, weapon: perk + originTrait; armor: setBonus + class + stat sort on instance panel). On catalog row select → auto-fetch instances (`includeInstancePointer` pattern). On instance select → populate `itemForm` and call existing `PUT /api/user/sets/:id/items`. Collapse manual hash inputs under "Advanced / fallback".

**Rationale**: US4; maximizes reuse; JSON panel shows same URLs as Catalog.

**Alternatives considered**:
- Extract shared React component now — optional refactor in US4 if duplication exceeds ~80 lines; start inline, extract if needed during implement.

---

## R10: Set bonus name autocomplete (optional UX)

**Decision**: Armor set bonus text input may call existing **`GET /api/catalog/synergy-pickers/links?kind=armor_set_bonus&q=`** for name suggestions; catalog armor search uses resolved `setBonus` string. Picker returns set names; armor route resolves to items.

**Rationale**: Reuses 006 picker without conflating synergy link rows with armor catalog rows.

**Alternatives considered**:
- Hard-coded set list — rejected (manifest-driven).
