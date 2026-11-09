# Data Model: Instance Disambiguation Picker

**Feature**: 010-instance-disambiguation | **Date**: 2026-07-03 | **Phase**: 1

Derived from the spec Key Entities and the Phase 0 research. Reuses existing types where possible; only additive fields and one nullable DB column are introduced. Types are TypeScript-oriented but implementation-agnostic in intent.

---

## 1. Extended: `OwnedInstanceDetail` (armor fields)

The instance list/detail DTO (`src/lib/inventory/instances/types.ts`) is the per-copy card source. It gains two **optional, armor-only** fields; all existing fields are unchanged.

| Field | Type | Rules |
|-------|------|-------|
| `tier` | `ArmorTier?` | Present only for armor copies; see entity 2. Omitted for weapons. |
| `setBonus` | `ArmorSetBonusSummary \| null` (armor only) | `null` when the item belongs to no set (exotic/standalone). Omitted for weapons. |

Existing fields relied upon by the carousel (no change): `instanceId`, `itemHash`, `kind`, `bucket`, `location`, `characterId`/`className`/`characterDisplayName`, `power`, `isMasterwork`, `isCrafted`, `plugs[]` (weapon equipped perks), `statValues`/`totalStats`/`statsIncomplete` (armor stats), `syncedAt`.

**Backward compatibility**: additive optional fields — existing consumers (003/008) unaffected.

---

## 2. `ArmorTier` (new)

Represents the Armor 3.0 tier for an armor copy. **Primary source is the Bungie API `gearTier`** (instance component 300); a curated stat-band heuristic is the fallback for legacy copies. Produced by `resolveArmorTier({ gearTier, totalStats, isExotic, statsComplete })` (`src/data/rules/armorTiers.ts`). See research R1.

| Field | Type | Rules |
|-------|------|-------|
| `tier` | `1 \| 2 \| 3 \| 4 \| 5 \| null` | Numeric tier; `null` for exotics (no numeric tier) or when unavailable. |
| `label` | `string` | Display label: `"Tier N"`, `"~Tier N"` (estimated), `"Exotic"` (optionally `"Exotic · Tier N"`), or `"Tier unavailable"`. |
| `source` | `"api" \| "estimated" \| "none"` | `api` = exact from `gearTier`; `estimated` = stat-band fallback; `none` = unavailable. |
| `approximate` | `boolean` | `true` only for `source: "estimated"` (masterwork-inflated total). Always `false` for `api`. |
| `available` | `boolean` | `false` only when `source: "none"`. |

**Resolution precedence** (first match wins):
1. `gearTier` in `1..5` → `{ tier: gearTier, label: "Tier N", source: "api", approximate: false, available: true }` (exotic-with-tier may render `"Exotic · Tier N"`).
2. `gearTier` null AND `isExotic` → `{ tier: null, label: "Exotic", source: "api", approximate: false, available: true }`.
3. `gearTier` null, legendary, `statsComplete` → stat-band fallback via `ARMOR_TIER_BANDS`, clamp above T5 → `{ tier: N, label: "~Tier N", source: "estimated", approximate: true, available: true }`.
4. otherwise (`gearTier` null, stats incomplete) → `{ tier: null, label: "Tier unavailable", source: "none", approximate: false, available: false }`.

**`ARMOR_TIER_BANDS`** (fallback only; curated, source-cited; GamesRadar/TheGamer consensus):

| Tier | Total stat band (inclusive lower) |
|------|-----------------------------------|
| 1 | ≤ 57 |
| 2 | 58–63 |
| 3 | 64–69 |
| 4 | 70–74 |
| 5 | ≥ 75 |

### Storage: `inventory_items.gear_tier` (new)

`gearTier` is captured during sync so the projection can read it from the DB (instance listing is not per-request synced — 003 FR-013).

| Location | Field/Column | Type | Rules |
|----------|--------------|------|-------|
| `inventory_items` (DB) | `gear_tier` | `INTEGER NULL` | Per-copy `gearTier` from component 300; `NULL` for pre-v9.0.0 items and rows synced before this feature. |
| `UserInventoryItem` | `gearTier` | `number \| null` | Parsed from `DestinyItemInstanceComponent.gearTier` in `parseInventoryItemAttempt` (`profile.ts`). |

Migration: idempotent `ensureGearTierColumn` in `src/lib/db/client.ts` (mirrors `ensureStatValuesColumn`). Nullable → backward compatible; requires a one-time re-sync to backfill.

---

## 3. `ArmorSetBonusSummary` (new)

The item's set bonus surfaced on armor cards. Built from `SetBonusRecord` via `armorSetBonus.ts` (invert `itemHashes` → `Map<itemHash, SetBonusRecord>`).

| Field | Type | Rules |
|-------|------|-------|
| `hash` | `number` | Set bonus (equipable item set) hash. |
| `name` | `string` | Set name. |
| `tiers` | `SetBonusTier[]` | The set's bonus tiers, ordered by `requiredCount` ascending. |

`SetBonusTier`:

| Field | Type | Rules |
|-------|------|-------|
| `requiredCount` | `number` | Pieces required (2 = 2-piece, 4 = 4-piece). |
| `name` | `string` | Tier perk name. |
| `description` | `string` | Tier perk effect text (from sandbox perk). |

**Rules**: For the card, both the 2-piece and 4-piece entries are shown when present (FR-007). `null` summary → card renders "no set bonus" (FR-009).

---

## 4. `WeaponPerkOptions` (new, lazy)

Available per-socket options for a weapon itemHash, from `resolveWeaponPerkOptions(itemHash)` (`src/lib/catalog/weaponPerkOptions.ts`). Fetched only at the weapon perk-selection step.

| Field | Type | Rules |
|-------|------|-------|
| `itemHash` | `number` | The weapon whose options these are. |
| `columns` | `WeaponPerkColumnOptions[]` | One per perk socket/column, in column order. |

`WeaponPerkColumnOptions`:

| Field | Type | Rules |
|-------|------|-------|
| `column` | `number` | Socket/column index. |
| `options` | `{ hash: number; name: string }[]` | Union of curated + randomized plugs the copy can hold, de-duplicated, name-resolved. |

**Rules**:
- Options are the weapon's item-level pool (identical across copies); the **equipped** option per column is marked client-side by intersecting with the chosen copy's `plugs[].hash`.
- Empty `columns` (unavailable weapon record) → UI degrades to selecting from the copy's equipped perks only.

---

## 5. Extended: Set Item (`instanceId`)

`set_items` table + `SetItemRecord` + `setItemInputSchema` gain one nullable/optional field.

**DB (`set_items`)**:

| Column | Type | Rules |
|--------|------|-------|
| `instance_id` | `TEXT NULL` | Specific owned copy attached; `NULL` for legacy/unspecified attachments. |

**`setItemInputSchema` (request)** adds:

| Field | Type | Rules |
|-------|------|-------|
| `instanceId` | `string` (min 1), optional | The chosen copy's instance identity. |

Existing request fields unchanged: `slot`, `itemHash`, `itemName?`, `selectedPerks?` (perk plug hashes — used to store the user's selected weapon perks), `masterworkHash?`, `modHashes?`, `confirmReplace?`.

**`SetItemRecord` (read)** adds `instanceId: string | null`.

**Rules**:
- `selectedPerks` stores the recorded weapon roll — defaults to the copy's equipped plug hashes when the user makes no explicit selection (FR-013).
- Slot compatibility and occupied-slot replace confirmation are unchanged (FR-019).

---

## 6. Candidate Session (ephemeral, client-only)

Not persisted. Held in React state on the debug Sets page; pure logic in `candidateSession.ts`.

| Field | Type | Rules |
|-------|------|-------|
| `itemHash` | `number` | The single selected item being disambiguated. |
| `kind` | `"weapons" \| "armor"` | Drives kind-aware card rendering. |
| `all` | `OwnedInstanceDetail[]` | Full fetched candidate list (ordering as returned; no cap). |
| `removedInstanceIds` | `Set<string>` | Session-only removals. |
| `activeIndex` | `number` | Current carousel position among visible candidates. |
| `selectedInstanceId` | `string \| null` | The copy chosen for attachment. |

**Derived**: `visible = all.filter(i => !removedInstanceIds.has(i.instanceId))`.

**Transitions** (pure reducer):

| Action | Effect | Guards |
|--------|--------|--------|
| `open(itemHash, kind, all)` | initialize session | requires `all` from instances fetch; empty → empty state (FR-018) |
| `removeCandidate(instanceId)` | add to `removedInstanceIds` | never mutates inventory (FR-016); clears `selectedInstanceId` if it was removed |
| `resetCandidates()` | clear `removedInstanceIds` | restores all copies (FR-017) |
| `select(instanceId)` | set `selectedInstanceId` | must be in `visible` |
| `next()` / `prev()` | move `activeIndex` within `visible` | wraps or clamps; no-op when 0 visible |

**States**: `loading` → `browsing` (≥1 visible) → `selected` → `attaching` → `attached`; plus `empty` (never synced / no copies / all removed) and `sync-required` (unsigned/unsynced) reusing existing prompts.

---

## Validation summary

| Rule | Source | Enforced by |
|------|--------|-------------|
| `instanceId` non-empty when provided | FR-012 | `setItemInputSchema` (zod) |
| Weapon perk options scoped to the copy's pool (not full manifest) | FR-013 | `resolveWeaponPerkOptions` (curated ∪ randomized only) |
| Tier from API `gearTier` when present; heuristic fallback; else "unavailable" | FR-005/FR-008/FR-009 | `resolveArmorTier` (gearTier → stat-band → none), `statsIncomplete` |
| No set membership → "no set bonus" | FR-009 | `armorSetBonus` lookup returns `null` |
| Candidate removal never mutates inventory | FR-016 | `candidateSession` reducer (no API calls) |
| All copies shown, no cap | FR-021 | carousel renders full `visible[]` |
| Slot compat + replace confirm preserved | FR-019 | existing `upsertSetItem` (unchanged) |
