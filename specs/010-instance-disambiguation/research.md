# Research: Instance Disambiguation Picker

**Feature**: 010-instance-disambiguation | **Date**: 2026-07-03 | **Phase**: 0

Resolves the unknowns in `plan.md` Technical Context. Existing infrastructure (owned-instances API + DTO, catalog `ownedCount`/`instancesHref`, set-item `PUT` with `selectedPerks`, debug Sets picker) is reused as-is; this document records the four decisions that require new work.

---

## R1 — How to source Armor 3.0 "Tier" (1–5)

**Question**: The spec (FR-005) requires showing each armor copy's Tier. Where does Tier come from?

**Findings**:
- **The Bungie API exposes the exact gear tier per copy.** As of *The Edge of Fate* (API v9.0.0), `DestinyItemInstanceComponent` (profile **component 300**) has a nullable **`gearTier`** integer, `1–5` for items obtained on/after v9.0.0 and `null` for older items ([Bungie API issue #1981](https://github.com/Bungie-net/api/issues/1981)). Exotics may carry a `gearTier` on drop even though the game does not surface it. DIM reads this field directly (it does **not** compute tier from stats); tier overlay icons come from the new `DestinyInventoryItemConstantsDefinition.gearTierOverlayImagePaths`.
- **Our sync already fetches component 300** and reads the instance object: `INVENTORY_COMPONENTS = "102,201,205,300,305"` (`src/lib/bungie/profile.ts:44`), `extractInstancesMap` (`profile.ts:474`), and `parseInventoryItemAttempt` already pulls `power`/`isMasterwork`/`isCrafted` off the same `instance` map (`profile.ts:427-430`). `gearTier` sits on that object but is currently **not captured or stored** (`inventory_items` has no tier column; `UserInventoryItem` has no tier field).
- The item **definition** only exposes `inventory.tierType` = **rarity** (5 = Legendary, 6 = Exotic) — `src/lib/manifest/extractors/rawTypes.ts:38`. This is *not* the gear tier; it is only used to distinguish exotics.
- Community stat-total → tier bands exist but **conflict** (GamesRadar/TheGamer/video → T1 52–57, T2 58–63, T3 64–69, T4 70–75, T5 75; skycoach → T1 48–53, T2 53–58, …) and synced `totalStats` include masterwork/mods, so a stat-derived tier is only an approximation. This is now the **fallback**, not the primary source.

**Decision**: Make **`gearTier` (instance component 300) the primary Tier source**, captured during sync, with the stat-band heuristic as a fallback for legacy (pre-v9.0.0, `gearTier: null`) copies.

1. **Capture during sync**: read `gearTier` in `parseInventoryItemAttempt` (a `parseGearTier(instance)` helper beside `parseItemPower`), add `UserInventoryItem.gearTier?: number | null`, and persist a **nullable `gear_tier` integer column** on `inventory_items` (idempotent `ensureGearTierColumn` in `src/lib/db/client.ts`, mirroring `ensureStatValuesColumn`).
2. **Project** onto `OwnedInstanceDetail.tier` via `resolveArmorTier(...)` (`src/data/rules/armorTiers.ts`):

```
resolveArmorTier(input: {
  gearTier: number | null;        // from instance component 300
  totalStats?: number;            // fallback input
  isExotic: boolean;
  statsComplete: boolean;
}) → { tier: 1|2|3|4|5|null; label: string; source: "api"|"estimated"|"none"; approximate: boolean; available: boolean }
```

Resolution precedence:
- **`gearTier` present (1–5)** → `{ tier: gearTier, label: "Tier N", source: "api", approximate: false, available: true }` (exotics with an API tier may show `"Exotic · Tier N"`).
- **`gearTier` null, `isExotic`** → `{ tier: null, label: "Exotic", source: "api", approximate: false, available: true }`.
- **`gearTier` null, legendary, `statsComplete`** → stat-band fallback via `ARMOR_TIER_BANDS` (GamesRadar/TheGamer consensus): `{ tier: N, label: "~Tier N", source: "estimated", approximate: true, available: true }`.
- **`gearTier` null and stats incomplete** → `{ tier: null, label: "Tier unavailable", source: "none", approximate: false, available: false }` (satisfies FR-009).

**Rationale**: `gearTier` is exact, deterministic, per-copy, already in the payload we fetch, and matches how DIM does it — no masterwork-inflation caveat. The heuristic is retained only so legacy copies still show *something* (the user's headline need) instead of "unavailable", clearly flagged `approximate`. Fits Constitution V (validated instance data; explicit degradation).

**Cost/trade-off**: Requires a **one-time inventory re-sync** to backfill `gear_tier` (null → resolves via fallback/unavailable until re-synced). Adds one nullable sync column. Both are additive and backward compatible (SC-007).

**Alternatives considered**:
- *Stat-band heuristic as primary* (previous decision): rejected — the exact `gearTier` field exists in data we already fetch; a heuristic would be needlessly imprecise. Kept as fallback only.
- *Read `gearTier` live per request instead of storing*: rejected — the projection runs off the DB `UserInventoryItem`, not a live profile call; storing keeps instance listing free of per-request sync (003 FR-013).
- *Drop the heuristic entirely (null → always "unavailable")*: viable and simpler; rejected for v1 so legacy items still display an estimate. Revisit if the estimate proves confusing.

**To confirm at implementation**: verify the live profile response actually populates `gearTier` for this manifest version before relying on it; the fallback covers the null case regardless.

---

## R2 — Exposing weapon "available perk options" per socket

**Question**: US4/FR-013 (clarified) requires offering, per socket, **all plug options that copy can hold** (equipped + swappable alternatives), not just the equipped perk and not the full manifest roll pool.

**Findings**:
- Synced instances store **only equipped** plug hashes (`parsePlugHashes` in `src/lib/bungie/profile.ts:512`; component 305 reads a single `plugHash` per socket). Available/reusable options are **not** synced.
- The manifest layer already precomputes per-column available pools: `WeaponRecord.perkColumns: { column, curated: Hash[], randomized: Hash[] }` (`src/lib/manifest/types/records.ts`), built by `weapons.ts` → `socketPlugHashes` (`extractors/common.ts:155`) from `reusablePlugSetHash`/`randomizedPlugSetHash`/`singleInitialItemHash` + `DestinyPlugSetDefinition.reusablePlugItems`.
- These pools are **per weapon itemHash** (identical across copies), and names resolve via the `weapon-perks` store (pattern in `src/lib/llm/tools.ts` `perkNamesForColumn`). No REST route currently exposes them; `CatalogItem` does not carry `perkColumns`.

**Decision**: Treat "options that copy can hold" as the **weapon's per-column available pool** (curated ∪ randomized) for that itemHash, and mark the equipped option using the chosen copy's instance plug hashes (client-side cross-reference). Add:
- Domain fn `resolveWeaponPerkOptions(itemHash)` in `src/lib/catalog/weaponPerkOptions.ts` → `{ columns: [{ column, options: [{ hash, name }] }] }`, composing the `weapons` + `weapon-perks` stores.
- Read-only route `GET /api/catalog/weapons/perk-options?itemHash=` returning that shape.
- Fetched **lazily** only when the user opens perk selection for the chosen weapon copy (keeps the carousel light).

**Rationale**: The precomputed pools are the closest faithful representation of what a copy of that weapon can roll, require no sync changes, and reuse existing name resolution. Per-copy equipped state comes from the instance the user already selected.

**Degradation**: If the weapon record or `perkColumns` are unavailable, the endpoint returns empty columns and the UI falls back to selecting from the copy's **equipped** perks only (still recorded by default), per the spec's degradation clause.

**Alternatives considered**:
- *Sync per-socket reusable plugs per instance*: rejected for v1 — larger sync/schema change; pools are item-level and already available in the manifest.
- *Extend `CatalogItem` with `perkColumns`*: rejected — bloats every catalog row; options are only needed at the selection step.

**Follow-on — true per-column perk grouping (deferred)**: FR-003 / US2 acceptance say a weapon card lists perks "grouped by socket/column", but the current `OwnedInstanceDetail.plugs[]` is a **flat, socket-ordered** list with no column label, and `parsePlugHashes` (`src/lib/bungie/profile.ts:512`) captures every enabled socket's equipped `plugHash` (including non-perk sockets: masterwork/mods/cosmetics). This iteration therefore renders equipped sockets in socket order (unresolved by hash), not under labeled columns. Real column grouping needs a **sync-side change**: capture each socket's column/category index (and a perk-vs-cosmetic classification) during inventory sync (component 305 socket order + `DestinyInventoryItemDefinition.sockets.socketCategories`), persist it on `inventory_items`, and expose grouped columns on the DTO. Scope it as a separate feature (`0NN-weapon-perk-columns`) since it changes the sync/schema surface this feature intentionally avoids. Until then, the socket-order flat list satisfies "all perks shown" (FR-003/SC-002 coverage) without column headings.

---

## R3 — Recording a specific `instanceId` on a set item

**Question**: FR-012 requires the attachment to record the specific copy's instance identity. Does the set-item model support it?

**Findings**:
- `set_items` stores `itemHash`, `itemName`, `selectedPerks` (JSON), `masterworkHash`, `modHashes` — **no `instanceId`** (`src/lib/db/schema.ts:78`, `setItemInputSchema` in `src/lib/sets/schemas.ts:47`). `selectedPerks` (perk plug hashes) **is** already first-class.
- Migrations use an idempotent pattern: `PRAGMA table_info` + `ALTER TABLE ADD COLUMN` helpers in `src/lib/db/client.ts` (`ensureSynergySubTypeColumn`, `ensureStatValuesColumn`) plus the drizzle schema and a `schema.test.ts` smoke test. `createTestDb()` re-runs migrations for in-memory tests.

**Decision**: Add a **nullable** `instance_id TEXT` column to `set_items`:
- `src/lib/db/schema.ts`: `instanceId: text("instance_id")` on `setItems`.
- `src/lib/db/client.ts`: new `ensureSetItemInstanceIdColumn(db)` invoked from `runMigrations`.
- `src/lib/sets/schemas.ts`: `instanceId: z.string().min(1).optional()` on `setItemInputSchema`.
- `src/lib/sets/setItemService.ts`: persist `instanceId` in `upsertSetItem`; add to `SetItemRecord`.
- `src/lib/db/schema.test.ts`: assert the column exists after migration.

**Rationale**: Nullable + optional = fully backward compatible (existing set items and clients unaffected — SC-007). Reuses the established migration idiom. Enables FR-012 without reshaping the API.

**Alternatives considered**:
- *Encode instanceId inside `selectedPerks` or `itemName`*: rejected — abuses fields, not queryable, breaks typing.
- *New join table*: rejected — over-engineered for a single optional scalar (KISS).

---

## R4 — Resolving an armor item's Set Bonus (2pc & 4pc) by itemHash

**Question**: FR-007 requires each armor card to show the set bonus 2-piece and 4-piece effects. How is set bonus resolved from an item hash, and how is it surfaced to the carousel?

**Findings**:
- `SetBonusRecord` (`src/lib/manifest/types/records.ts:144`) already carries set `name`/`hash`/`icon`, `perks: [{ requiredCount, name, description }]` (requiredCount 2 = 2-piece, 4 = 4-piece), and `itemHashes: Hash[]` (member armor). Stored in the `set-bonuses` entity store.
- There is **no reverse index by item hash**; existing code iterates records and checks `set.itemHashes` membership (`legendaryArmor.ts`, `setBonusFilter.ts`).
- The armor instance projection (`projectInstance.ts`) does **not** currently include set bonus.

**Decision**: Add `src/lib/inventory/instances/armorSetBonus.ts` that builds a `Map<itemHash, SetBonusRecord>` by inverting `itemHashes` once, plus a lookup. Extend the instance context (`loadInstanceContext.ts`) to build this map from the `set-bonuses` store, and extend `projectInstance` (armor only) to attach:

```
setBonus?: { hash, name, tiers: { requiredCount, name, description }[] } | null
tier?: { label, tier, approximate, available }   // from R1
```

The carousel is fed by the **single existing instances-list fetch**; the set bonus is identical across copies of the same item but is rendered per card as required.

**Rationale**: Reuses existing manifest data with a one-pass inversion; one fetch powers the whole carousel (KISS, meets SC-001 flow). Nullable `setBonus`/optional `tier` keep the DTO backward compatible.

**Degradation**: Item not a member of any set → `setBonus: null` → card shows "no set bonus" (FR-009).

**Alternatives considered**:
- *Separate `GET set-bonus?itemHash` endpoint*: rejected — an extra round trip per carousel; the instances fetch already returns per-copy armor data, so co-locating is simpler.
- *Reuse `CatalogItem.setBonusName/Hash`*: insufficient — carries only the name/hash, not the 2pc/4pc effect descriptions the card needs.

---

## Cross-cutting decisions

- **Carousel session state** (US1/US5): held in React on the debug Sets page; the remove/reset logic is extracted to a pure reducer `candidateSession.ts` (`removeCandidate`, `resetCandidates`) for unit testing. Never calls inventory-mutating APIs (FR-016).
- **No cap / no pagination** (FR-021): the carousel renders the full `instances[]` for the selected itemHash (armor sorted by `sortBy`/stat, weapons by power) as returned today.
- **Docs**: `DEBUG.md` is updated in the same change per the `debug-docs` rule (new carousel flow, perk-options endpoint, prerequisites).
