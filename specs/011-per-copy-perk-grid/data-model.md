# Data Model: Per-Copy Weapon Perk Grid

**Feature**: 011-per-copy-perk-grid | **Date**: 2026-07-04 | **Phase**: 1

Derived from the spec Key Entities and Phase 0 research. Extends 010/003 inventory and instance types; one additive DB column. Types are TypeScript-oriented but implementation-agnostic in intent.

---

## 1. Extended: `inventory_items` (sync storage)

Per-copy socket plug capture persisted at sync time.

| Column | Type | Rules |
|--------|------|-------|
| `socket_plugs` | `TEXT NULL` (JSON) | Array of `StoredSocketPlug` (entity 2). `NULL` for rows synced before this feature or when capture not yet run. |
| `plug_hashes` | unchanged | Flat equipped plug list (backward compatible); carousel + equipped fallback. |

**`UserInventoryItem`** adds:

| Field | Type | Rules |
|-------|------|-------|
| `socketPlugs` | `StoredSocketPlug[] \| null` | Parsed from `socket_plugs`; `null` ⇒ capture pending. |

Migration: idempotent `ensureSocketPlugsColumn` in `src/lib/db/client.ts` (mirrors `ensureGearTierColumn`).

---

## 2. `StoredSocketPlug` (sync capture, persisted)

Raw per-socket state captured from Bungie components 305 + 310 + plug-set resolution.

| Field | Type | Rules |
|-------|------|-------|
| `socketIndex` | `number` | Index into item socket array (305 order). |
| `equippedPlugHash` | `number` | Enabled socket's current `plugHash`. |
| `reusablePlugHashes` | `number[]` | De-duplicated alternates the copy can insert (from 310 + plug sets). May be empty for static single-option sockets. |
| `columnKind` | `SocketColumnKind` | Assigned at sync or first projection from manifest classification. |
| `columnLabel` | `string` | Human label, e.g. `"Barrel"`, `"Magazine"`, `"Trait 1"`, `"Intrinsic"`, `"Origin Trait"`, `"Masterwork"`, `"Catalyst"`. |

`SocketColumnKind` = `"barrel" | "magazine" | "trait" | "intrinsic" | "origin" | "masterwork" | "catalyst"`.

**Rules**:
- Non-perk sockets (shader, tracker, ornament, empty cosmetic) are **not stored** (FR-021).
- `reusablePlugHashes` includes equipped hash if also listed as reusable; projection de-dupes.
- Capture considered **complete** for a weapon when every stored perk socket has been evaluated (reusable array present, possibly empty for fixed rolls) — drives `captureStatus`.

---

## 3. `InstancePerkGrid` (API response, projected)

DIM-style grid for one weapon copy. Returned by `GET .../perk-grid`.

| Field | Type | Rules |
|-------|------|-------|
| `instanceId` | `string` | The copy this grid describes. |
| `itemHash` | `number` | Manifest item hash. |
| `captureStatus` | `"complete" \| "pending" \| "unavailable"` | See entity 6. |
| `columns` | `InstancePerkColumn[]` | Ordered: barrel → magazine → traits → intrinsic → origin → masterwork → catalyst. |

`InstancePerkColumn`:

| Field | Type | Rules |
|-------|------|-------|
| `columnKind` | `SocketColumnKind` | Category of this column. |
| `label` | `string` | Display label (from `StoredSocketPlug.columnLabel`). |
| `socketIndex` | `number` | Source socket index (for debugging/tests). |
| `equippedPlugHash` | `number` | Currently equipped plug in this column. |
| `options` | `InstancePerkOption[]` | De-duplicated perks the copy can slot here. |

`InstancePerkOption`:

| Field | Type | Rules |
|-------|------|-------|
| `hash` | `number` | Plug item hash. |
| `name` | `string \| null` | Resolved name; null only if unresolved pipeline returns null. |
| `displayName` | `string` | `name ?? String(hash)`; enhanced variants append `" (Enhanced)"` when `isEnhanced` (FR-017). |
| `isEnhanced` | `boolean` | True for enhanced-tier plug variants. |
| `isEquipped` | `boolean` | True when hash === column's `equippedPlugHash`. |

**Rules**:
- When `captureStatus !== "complete"`, `options` contains **only the equipped plug** per column (degraded grid, FR-015).
- Columns with zero options after projection are omitted.
- Two copies of same `itemHash` with different rolls MUST produce different `columns[].options` when alternates differ (FR-007, SC-002).
- MUST NOT include options from weapon-type `perkColumns` pool (FR-002).

---

## 4. `PerkGridSelection` (client session, ephemeral)

User's in-progress column choices on the debug Sets page.

| Field | Type | Rules |
|-------|------|-------|
| `byColumnKind` or `bySocketIndex` | `Record<string, number>` | Chosen plug hash per column key; defaults to each column's `equippedPlugHash`. |
| `selectedPerks` (derived) | `number[]` | Ordered hash list sent to `PUT` — **grid column order** (FR-010). |

**Transitions**:
- Grid load → initialize selection from equipped hashes.
- User changes one column → only that column's hash updates.
- Copy switch in carousel → discard selection; reload grid for new `instanceId` (FR-013).

---

## 5. Extended: Set Item attachment (unchanged shape, clarified semantics)

No schema change from 010. Clarify ordering:

| Field | Type | Rules |
|-------|------|-------|
| `instanceId` | `string`, optional | Specific copy (010). |
| `selectedPerks` | `number[]`, optional | **One hash per grid column in column display order** — equipped defaults for untouched columns (FR-009, FR-010). |

---

## 6. Capture lifecycle / `captureStatus`

| Status | Meaning | UI behavior |
|--------|---------|---------------|
| `pending` | Row lacks `socket_plugs` or incomplete capture | Trigger auto re-sync once (FR-018); show loading + equipped-only preview if needed |
| `complete` | All perk sockets captured | Full grid with alternates |
| `unavailable` | Re-sync failed or unrecoverable parse gap | Equipped-only + clear indicator; no type-pool fallback (FR-015) |

**Guards**:
- Client: max **one** sync attempt per `instanceId` per carousel session.
- Server: GET perk-grid is read-only; sync via existing `POST /bungie/sync`.

---

## 7. `PerkGridRefreshSession` (client-only, ephemeral)

Dedupe auto re-sync (research R5).

| Field | Type | Rules |
|-------|------|-------|
| `syncAttemptedFor` | `Set<string>` | Instance IDs already auto-synced this session |
| `inFlight` | `boolean` | True while sync POST pending |

---

## Validation summary

| Rule | Source | Enforced by |
|------|--------|-------------|
| Grid shows copy-specific options only | FR-002 | `resolveInstancePerkGrid`; no catalog pool in Sets UI |
| Equipped marked + preselected | FR-003 | `InstancePerkOption.isEquipped`; client default state |
| Enhanced labeled separately | FR-017 | `isEnhanced` + `displayName` suffix |
| Exotic same grid layout | FR-016 | `classifyWeaponSocket` includes catalyst/intrinsic |
| No type-pool fallback | FR-015 | route + UI never call perk-options for grid |
| Auto re-sync bounded | FR-018 | `PerkGridRefreshSession` + `captureStatus` |
| Non-perk sockets excluded | FR-021 | sync capture + classifier |
| Set attach regression | FR-020 | existing `upsertSetItem` tests extended |
