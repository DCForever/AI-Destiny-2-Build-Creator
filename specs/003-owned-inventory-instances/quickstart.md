# Quickstart: Owned Inventory Instance Detail

**Feature**: 003-owned-inventory-instances  
**Updated**: 2026-06-28

**Purpose**: Validate per-copy inventory listing, plug resolution, and debug catalog drill-down.

## Prerequisites

```bash
npm run dev
# http://localhost:3000
# NODE_ENV must NOT be production (debug routes 404 in production)
# Settings → Refresh manifest (BUNGIE_API_KEY)
# Sign in with Bungie
# Trigger inventory sync (Settings or POST /api/bungie/sync)
```

**Debug entry**: `/debug/catalog`  
**API entry**: `GET /api/user/inventory/instances`

## Scenario 1: List owned copies of a weapon (US1, SC-001)

1. Sign in and sync inventory.
2. On `/debug/catalog`, set **Kind** = Weapons, **Scope** = Owned, search for a weapon you own in **multiple copies** (e.g. a craftable with duplicates).
3. Note a catalog row with `ownedCount > 2`.
4. Select the row → instance panel shows **separate entries** per copy (not one collapsed row).
5. Each entry shows: `instanceId`, power, location, masterwork/crafted flags, resolved perk names.

**Pass**: Distinct `instanceId` per row; plug names readable when manifest loaded.

**API alternative**:

```http
GET /api/user/inventory/instances?itemHash=<hash from catalog row>
```

Expect `count` equal to `ownedCount` on catalog row.

## Scenario 2: Armor instances across vault and characters (US1)

1. Owned scope catalog → search exotic or legendary armor with copies on multiple characters.
2. Drill into instances → verify `location` values (`vault`, `character`, `equipped`) and `characterId` when applicable.

**Pass**: Each copy listed separately with location metadata.

## Scenario 3: Debug catalog drill-down (US2, SC-003)

1. Open `/debug/catalog`, owned scope.
2. Search and select one owned weapon and one owned armor piece.
3. Confirm instance detail panel without leaving debug page.
4. Compare power, flags, and plugs against in-game or post-sync expectations.

**Pass**: QA can verify sync correctness for weapon + armor.

## Scenario 4: Query by item identity (US3)

```http
GET /api/user/inventory/instances?itemHash=<known hash>
```

- User owns copies → full list with roll fields.
- User owns none → `{ "instances": [], "count": 0, "syncPrompt": false }` (not 500).

**Pass**: Stable `instanceId` on each row for downstream set attachment.

## Scenario 5: Perk text filter (FR-003)

```http
GET /api/user/inventory/instances?kind=weapons&q=frenzy
```

**Pass**: Only instances with a resolved plug name containing "frenzy" (case-insensitive).

## Scenario 6: Unresolved plug degradation (FR-006)

1. If any plug hash fails manifest lookup, instance still returns.
2. Unresolved plug shows `displayName` as hash string; `resolved: false`.

**Pass**: Request does not fail; plug not omitted.

## Scenario 7: Auth and never-synced (SC-005)

1. Sign out → `GET /api/user/inventory/instances` → `401`.
2. Sign in, **without** sync → `200`, `syncPrompt: true`, `instances: []`, actionable `message`.

**Pass**: No inventory data leaked when unauthorized or empty.

## Scenario 8: Catalog backward compatibility (US4, SC-006)

```http
GET /api/catalog/weapons?scope=owned&q=funnel
```

Without `includeInstances` → response shape unchanged from pre-003 (manifest fields + `ownedCount`).

```http
GET /api/catalog/weapons?scope=owned&includeInstances=1&q=funnel
```

**Pass**: Optional `ownedInstances` array present; existing fields intact.

## Scenario 9: Gate

```bash
npm run gate
```

**Pass**: typecheck, lint, test, build all green at feature checkpoint.

## Deferred (not in v1 gate)

- Stat bars, kill tracker, weapon XP (US5)
- Production `/inventory` browser page
