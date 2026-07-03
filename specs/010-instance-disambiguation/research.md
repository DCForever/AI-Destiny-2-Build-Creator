# Research: Instance Disambiguation Picker

**Feature**: 010-instance-disambiguation | **Date**: 2026-07-03 | **Phase**: 0

Resolves the unknowns in `plan.md` Technical Context. Existing infrastructure (owned-instances API + DTO, catalog `ownedCount`/`instancesHref`, set-item `PUT` with `selectedPerks`, debug Sets picker) is reused as-is; this document records the four decisions that require new work.

---

## R1 — How to source Armor 3.0 "Tier" (1–5)

**Question**: The spec (FR-005) requires showing each armor copy's Tier. Where does Tier come from?

**Findings**:
- The raw Bungie item definition captured by the manifest pipeline exposes only `inventory.tierType` = **rarity** (5 = Legendary, 6 = Exotic) — see `src/lib/manifest/extractors/rawTypes.ts:38` and usages in `weapons.ts`/`exoticArmor.ts`. There is **no Armor 3.0 gear-tier (1–5) field** on item definitions, instance components, DTOs, or the DB.
- Community sources map gear tier to **total stat points**, but the bands **conflict**: GamesRadar/TheGamer/video → T1 52–57, T2 58–63, T3 64–69, T4 70–75, T5 75; skycoach → T1 48–53, T2 53–58, T3 59–64, T4 65–72, T5 73–75.
- The synced `statValues`/`totalStats` (from Bungie stats component 300) **include masterwork and mods**, so a copy's stored total is inflated above its base roll (TheGamer: fully-masterworked ≈ 78; exotics roll ≈ T2 range, +15 masterworked). Base vs. masterworked totals are **not separable** from stored data (`is_masterwork` is a boolean, not a level).

**Decision**: Derive an **approximate** tier from the copy's synced total armor stats via a curated, source-cited band table in `src/data/rules/armorTiers.ts`, exposed as a pure function:

```
deriveArmorTier(totalStats: number, opts: { isExotic: boolean; statsComplete: boolean })
  → { label: string; tier: 1|2|3|4|5|null; approximate: boolean; available: boolean }
```

- Legendary armor: map `totalStats` to a tier using the **GamesRadar/TheGamer consensus bands** (the majority/most-cited set), clamping above T5.
- Exotic armor (`isExotic`): return `{ label: "Exotic", tier: null, available: true }` (exotics are outside the 1–5 system).
- `statsComplete === false`: return `{ label: "Tier unavailable", available: false }` (satisfies FR-009).
- `approximate: true` whenever the value is inferred from a masterwork-inflated total (i.e., all legendary derivations), so the card can mark it (e.g., "~T4").

**Rationale**: Honors the user's explicit need to *see* a tier while staying deterministic and testable (pure `total → tier`), and honestly signals imprecision instead of asserting a wrong exact tier. Fits Constitution V (curated, validated, degrades explicitly).

**Alternatives considered**:
- *Extract a tier field from the manifest*: rejected for v1 — no such field exists in the current definition shape; would require confirming an undocumented Bungie signal.
- *Subtract a masterwork constant before banding*: rejected — masterwork level isn't stored (only a boolean), so the correction would itself be a guess.
- *Show "unavailable" for all tiers*: rejected — fails the headline user requirement when a reasonable estimate is available.

**Follow-on**: Replace the estimate with a precise value if a stable manifest/API gear-tier signal is later confirmed (extract during manifest build, resolve by itemHash).

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
