# Quickstart: Description Search for Pickers

**Feature**: 009-description-search  
**Prerequisites**: `npm run dev`, manifest loaded

## 1. Weapon perk — search by description keyword

1. Open `/debug/synergies`.
2. Choose link kind **weapon_perk**.
3. Search `melee` (or another keyword known to appear in a perk description but not its name).
4. Confirm results include matching perks with **description visible in the list**.
5. Select one — description remains in preview panel.

```http
GET /api/catalog/synergy-pickers/links?kind=weapon_perk&q=melee
```

**Pass**: At least one result matched via description only (verify against manifest fixture or known perk).

## 2. Origin trait — description match

1. Same page; kind **origin_trait**.
2. Search keyword from a trait's description text.
3. Confirm trait appears with description in list.

```http
GET /api/catalog/synergy-pickers/links?kind=origin_trait&q=suspend
```

## 3. Set bonus — tier description match

1. Kind **armor_set_bonus**.
2. Search keyword appearing in a **4-piece or 2-piece bonus description** but not the set family name.
3. Confirm flattened row shows tier description.

```http
GET /api/catalog/synergy-pickers/links?kind=armor_set_bonus&q=overshield
```

## 4. Melee subtype — ability description

1. Create synergy category **Melee**; open sub-type picker.
2. Search word from an ability description.
3. Confirm ability listed with description.

```http
GET /api/catalog/synergy-pickers/subtypes?category=melee&q=arc
```

## 5. Catalog weapons — exotic intrinsic via `q`

1. Open `/debug/catalog` or call API.
2. Search `q` with keyword from an exotic intrinsic description (e.g. javelin, beam).
3. Confirm exotic weapon returned.

```http
GET /api/catalog/weapons?scope=all&q=javelin
```

## 6. Catalog weapons — perk filter by description

1. Open `/debug/sets` or `/debug/catalog`.
2. Set perk filter to keyword that matches perk **description** only.
3. Confirm weapons that roll that perk appear.

```http
GET /api/catalog/weapons?scope=owned&perk=melee
```

## 7. Catalog armor — set bonus filter by tier text

1. Armor catalog or Sets lookup; set `setBonus` to tier-description keyword.
2. Confirm matching set armor pieces returned.

```http
GET /api/catalog/armor?scope=all&setBonus=scorch&slot=Chest
```

## 8. Manifest search — exotic intrinsic

1. Use build sheet `WeaponPicker` or:

```http
GET /api/manifest/search?category=exotic-weapons&q=sunspot
```

2. Confirm exotic whose intrinsic description matches.

## 9. Regression

- Name-only search still returns expected rows (e.g. `q=thorn`, `perk=Incandescent` by exact name).
- Entity scoping: weapon perk picker does not return origin traits for same keyword.
- Catalog `q` does **not** return weapons based on rollable perk description alone (use `perk` param).

## Automated gate

```bash
npm run gate
```

Co-located tests: `descriptionMatch.test.ts`, extended `perkTraitFilters.test.ts`, `setBonusFilter.test.ts`, `synergyPickerLinks` route tests, `filterItems.test.ts`.
