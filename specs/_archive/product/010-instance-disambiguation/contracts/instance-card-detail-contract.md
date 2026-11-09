# Contract: Instance Card Detail (armor Tier + Set Bonus)

**Feature**: 010-instance-disambiguation
**Type**: Additive extension to the owned inventory instance list/detail DTO (003/008)
**Auth**: Signed-in user (existing 003 rules)

## Purpose

Give each carousel card the kind-aware detail it needs to disambiguate copies (US2). Weapons already carry equipped perks and armor already carries the six stats; this contract adds **armor Tier** and **armor Set Bonus (2pc & 4pc)** to the existing instance projection so a single instances fetch powers the whole carousel.

---

## GET `/api/user/inventory/instances` (extended) and `/api/user/inventory/instances/{instanceId}`

No new query params. Existing params unchanged: `itemHash`, `bucket`, `kind`, `q`, `sortBy`.

### Response 200 — extended armor instance object

Each **armor** instance in `instances[]` (and the detail object) gains two optional fields; weapon instances are unchanged.

```json
{
  "instanceId": "6917529…",
  "itemHash": 123,
  "kind": "armor",
  "power": 2010,
  "statValues": { "Health": 30, "Melee": 25, "Grenade": 20, "Super": 6, "Class": 5, "Weapons": 4 },
  "totalStats": 90,
  "statsIncomplete": false,
  "tier": { "tier": 5, "label": "Tier 5", "source": "api", "approximate": false, "available": true },
  "setBonus": {
    "hash": 456,
    "name": "First Ascent",
    "tiers": [
      { "requiredCount": 2, "name": "…", "description": "2-piece effect text" },
      { "requiredCount": 4, "name": "…", "description": "4-piece effect text" }
    ]
  },
  "plugs": []
}
```

| Field | Type | Notes |
|-------|------|-------|
| `tier` | object? | Armor only. `{ tier: 1..5\|null, label, source: "api"\|"estimated"\|"none", approximate, available }`. See data-model §2. |
| `setBonus` | object \| null | Armor only. `null` when the item is in no set (exotic/standalone). See data-model §3. |

**Weapon instances**: `tier` and `setBonus` are omitted. Equipped perks remain in `plugs[]` (unchanged; unresolved plug shown by hash).

### Tier source & degradation rules

`tier` is resolved from the Bungie **`gearTier`** field (instance component 300, captured during sync) first, then a stat-band fallback, then unavailable:

| Condition | `tier` |
|-----------|--------|
| Armor with API `gearTier` 1–5 | `{ tier: N, label: "Tier N", source: "api", approximate: false, available: true }` |
| Armor, exotic (rarity), no numeric `gearTier` | `{ tier: null, label: "Exotic", source: "api", approximate: false, available: true }` |
| Armor, legendary, `gearTier` null, complete stats | `{ tier: N, label: "~Tier N", source: "estimated", approximate: true, available: true }` (stat-band fallback) |
| Armor, `gearTier` null, `statsIncomplete: true` | `{ tier: null, label: "Tier unavailable", source: "none", approximate: false, available: false }` |
| Item in no set | `setBonus: null` (card shows "no set bonus") |

`setBonus` resolves to the item's set (2pc & 4pc) or `null`.

### Errors

Unchanged from 003: `401` unsigned; `200` empty + `syncPrompt` when never synced; `404` on unknown instance (detail route).

---

## Internal resolution

- `tier` ← `resolveArmorTier({ gearTier, totalStats, isExotic, statsComplete })` (`src/data/rules/armorTiers.ts`). `gearTier` comes from `inventory_items.gear_tier` (captured in `parseInventoryItemAttempt` from `DestinyItemInstanceComponent.gearTier`, component 300 — already fetched via `INVENTORY_COMPONENTS`).
- `setBonus` ← `armorSetBonus.ts` `Map<itemHash, SetBonusRecord>` built from the `set-bonuses` store, passed via the instance projection context (`loadInstanceContext.ts` → `projectInstance.ts`).
- `isExotic` comes from the per-`itemHash` armor-metadata lookup built in `loadInstanceContext` (exotic-armor store / `tierType === 6`) and passed into `projectInstance`; projection performs no per-item manifest fetch.

## Test expectations

- Armor copy with `gearTier` 5 → `tier === { tier: 5, source: "api", approximate: false, available: true }`.
- Armor copy, legendary, `gearTier` null, complete stats → `tier.source === "estimated"`, `tier.approximate === true`, numeric `tier.tier` (stat-band fallback).
- Armor copy, `gearTier` null, `statsIncomplete` → `tier.source === "none"`, `tier.available === false`.
- Exotic armor without a numeric tier → `tier.label === "Exotic"`, `tier.tier === null`, `tier.source === "api"`.
- Armor in a set → `setBonus.tiers` contains entries for `requiredCount` 2 and 4 with non-empty `description`.
- Armor not in a set → `setBonus === null`.
- Weapon instance → no `tier`/`setBonus` keys; `plugs[]` unchanged.
- Existing 003/008 response fields unchanged (regression).
