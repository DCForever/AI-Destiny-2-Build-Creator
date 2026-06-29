# Data Model: Full Inventory Plug Resolution

**Feature**: 004-full-plug-resolution  
**Source**: Feature 003 models unchanged; this feature adds **derived** resolution artifacts only.

## Entities

### Plug Name Map (derived, per request)

In-memory `Map<number, string>` built at instance list/detail time. Not persisted.

| Aspect | Description |
|--------|-------------|
| Keys | Manifest plug item hashes (`DestinyInventoryItemDefinition.hash`) |
| Values | Display name string (`displayProperties.name`, normalized via `projectBase`) |
| Layers | (1) Entity store merge, (2) manifest batch fallback for missing keys |
| Lifetime | One HTTP request; discarded after response |

**Validation**: Names only when `isUsable(item)` passes (non-redacted, non-empty name).

---

### Resolved Plug (API DTO — unchanged)

From feature 003. No field additions in 004.

| Field | Type | Notes |
|-------|------|-------|
| hash | number | Stored plug hash from sync |
| name | string \| null | Resolved name when found |
| displayName | string | `name ?? String(hash)` |
| resolved | boolean | `name !== null` |

---

### Inventory Instance (stored — unchanged)

`UserInventoryItem.plugHashes: number[]` remains the resolution input. No schema migration.

---

### Manifest Plug Definition (external)

Row in `DestinyInventoryItemDefinition` for a plug hash. Supplies display name when usable. Includes intrinsics, mods, masterwork, shaders, ornaments, trackers, and roll perks.

---

## Relationships

```text
UserInventoryItem.plugHashes[]
        │
        ▼
  Plug Name Map (derived)
        │
        ▼
  resolvePlugs() → ResolvedPlug[]
        │
        ▼
  OwnedInstanceDetail.plugs (API)
```

---

## Resolution rules

1. For each hash in `plugHashes`, look up in Plug Name Map.
2. If found → `{ name, displayName: name, resolved: true }`.
3. If not found → `{ name: null, displayName: String(hash), resolved: false }`.
4. Never omit a stored hash (FR-005, FR-006).

---

## Filter interaction (`q`)

Perk text search runs on projected `OwnedInstanceDetail` rows after step 1–3. Expanded map increases match surface; no separate search index.

---

## State transitions

Not applicable — read-only enhancement over sync snapshot and manifest cache.
