# Quickstart: Sets Catalog-Style Item Lookup

**Feature**: 008-sets-catalog-lookup  
**Prerequisites**: `npm run dev`, manifest loaded, signed-in user, inventory synced

## 1. Weapon set — find by perk

1. Open `/debug/sets`.
2. Create or select a **weapon** set; choose slot `primary`.
3. In **Item lookup**, set scope `owned` (or `all`).
4. Enter perk filter `Incandescent` (or another known perk).
5. Click **Search catalog** — confirm results show only weapons that can roll the perk.
6. Select a row with `ownedCount > 0` — instance list auto-fetches.
7. Confirm instances filtered by perk text (`q` in request URL).
8. Select an instance → **Put item** — verify JSON panel shows `PUT` with `itemHash` and `selectedPerks` populated (no manual hash entry).

**API check**:

```http
GET /api/catalog/weapons?scope=owned&slot=Kinetic&perk=Incandescent&includeInstancePointer=1
```

## 2. Weapon set — find by origin trait

1. Same set; clear perk; set origin trait `Cast No Shadows`.
2. Search — weapons with that origin trait only.
3. Attach as in step 1.

```http
GET /api/catalog/weapons?scope=all&originTrait=Cast%20No%20Shadows
```

## 3. Armor set — find by set bonus

1. Create or select an **armor** set; slot `helmet`.
2. Set set bonus filter `Eutechnology` (or known set name).
3. Search catalog — legendary helmet pieces from that set appear.
4. Select row → attach (exotic helmets from other sets excluded).

```http
GET /api/catalog/armor?scope=owned&slot=Helmet&setBonus=Eutechnology
```

## 4. Armor set — pick highest stat copy

1. Requires armor with multiple owned copies and post-008 sync (stats captured).
2. After selecting armor catalog row, set instance sort `Melee` (or `total`).
3. Confirm instance list ordered highest-first.
4. Select top instance → attach.

```http
GET /api/user/inventory/instances?itemHash={hash}&kind=armor&sortBy=Melee
```

## 5. Regression checks

- Tag filter on set list still works (`GET /api/user/sets?tags=…`).
- Occupied slot: attach without confirm → `409 SLOT_OCCUPIED`; confirm replace succeeds.
- Manual hash fallback still works under **Advanced / fallback** (debug only).

## 6. Automated verification

```bash
npm run gate
```

Key test files (after implement):

- `src/lib/catalog/perkTraitFilters.test.ts`
- `src/lib/catalog/filterItems.test.ts` (extended)
- `src/lib/inventory/instances/sortInstances.test.ts`
- `src/lib/bungie/profile.test.ts` (stat parse)
- `src/app/api/catalog/weapons/route.test.ts`
- `src/app/api/catalog/armor/route.test.ts`

## Expected outcomes

| Scenario | Pass criteria |
|----------|---------------|
| Perk search | ≥1 matching owned weapon in &lt;5s; empty message when no match |
| Origin trait | Only trait-bearing weapons returned |
| Set bonus | Only set member armor for slot returned |
| Stat sort | Highest `sortBy` copy first when stats present |
| Debug Sets | Add-item without typing `itemHash` on happy path |

See [spec.md](../spec.md) success criteria SC-001–SC-006.
