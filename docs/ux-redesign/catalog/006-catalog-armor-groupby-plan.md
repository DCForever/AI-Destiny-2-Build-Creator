# Plan: Catalog Armor group-by + highest-stat rank

**Status:** planned (not locked brief / not implemented)  
**Date:** 2026-08-09  
**Area:** catalog / armor residual (post-C8)  
**Hosts:** windows (exit gate); mobile structure-only  
**Related:** C8 Armor brief [`001-armor-brief.md`](./001-armor-brief.md) · nested group-by [`005-catalog-nested-groupby-brief.md`](./005-catalog-nested-groupby-brief.md) · pure `groupCatalogItemsNested` / `armorGroupDimensions` · path [`../REDESIGN-PATH.md`](../REDESIGN-PATH.md)

## Intent

Enable Armor Catalog browse that supports:

1. **Structural groups** — e.g. Warlock → Helmet (Class → Slot nested sections).  
2. **Highest X stat rank** — e.g. among Warlock helmets, order identities by **best owned base Super** (or any of the EoF six / base total).

These compose: *filter or group Class + Slot, then rank by base stat X*.  
Group-by alone does **not** express “highest Super.”

**Out of scope:** armor optimizer/kits; Universal (C9); Set/Build pick embeds; inventing unowned base stats; list-row six-stat strips (C8 honesty); weapons residual; live-modded totals as default rank.

## Current state

| Layer | Status |
| --- | --- |
| Pure nested tree API | Done — `groupCatalogItemsNested` + `CatalogGroupNode` |
| `armorGroupDimensions` | Declared — Class, Slot, “Archetype” (`frame`) |
| Host group chrome | **Hidden** in armor mode (`_mode != armor`); intentional C8 skip |
| `CatalogArmorGrid` | Flat `items` only — no tree / outline / collapse |
| Per-instance base boards | Done — `armorStats` / plug base (`preferArmorBaseRollBoard`) |
| Identity “best Super among copies” for browse sort | **Missing** pure API + host index |
| Armor extractors | Fill **class + slot** only — **not** `frame` / archetype |

**Data caveat:** offering Archetype/`frame` group for armor today buckets nearly everything as “Unknown frame.” **Do not ship** that dim until data exists.

## Product model

### A. Structural group-by (Phase 1)

| Decision | Plan |
| --- | --- |
| Dims offered | **Class**, **Slot** only (v1) |
| Nesting | Multi-dim ordered chips → nested tree (reuse DART-072 / weapons chrome) |
| Default | **Flat** (no auto-group) |
| Outline | When group-by active **and** ≥2 top-level groups |
| Collapse / JUMP | View-only; BR-CAT-007 (never rewrites filters) |
| Facets | Still apply first (BR-CAT-006); group partitions filtered list only |
| Mode switch | Sanitize dims: drop Element/Ammo/weapon Archetype when entering armor |
| Filter collections | Apply only armor-legal dims when in armor mode |

### B. Stat rank — “highest X” (Phase 2)

| Decision | Plan |
| --- | --- |
| Stat board for rank | **Base roll only** (DBR-STAT-008 / vault Destiny Armor) — not live modded |
| Keys | EoF six: Health · Melee · Grenade · Super · Class · Weapons (`armorBaseStatKeys`) **+ base total** |
| Rank unit | **Identity card** = best **owned copy** of that definition for the chosen key |
| Unowned / missing base | Sort **last** (or Unknown bucket under groups) — never invent numbers |
| All vs Owned | Owned: all visible rows can rank. All: owned rank by best copy; unowned trail |
| List chrome | Keep C8: **no six-stat strip on cards** in v1; order is the signal |
| Detail | Unchanged Base\|Live + instance strip (default highest base total remains) |
| UI control | **Rank by** under More / Sort & Group: total · each of six · default identity sort |
| Compose with groups | Rank applies **within** leaf groups (or globally when flat) |

**Example:** Warlock helmet highest Super ≈ facets or groups Class=Warlock + Slot=Helmet + **Rank by Super**.

### C. Optional peak-stat group dim (Phase 4 — defer)

Group by **argmax base stat** of best owned copy (“Super-spiked” vs “Weapons-spiked”). Secondary to explicit Rank by X.

## Architecture

```text
Facets (class / slot / exotic / query)
        ↓
  filtered identities (_results)
        ↓
  optional groupCatalogItemsNested(Class, Slot)
        ↓
  optional rankLeavesByBestBaseStat(statKey, ownedIndex)
        ↓
  CatalogArmorGrid (flat or tree) + outline
        ↓
  Detail: instances / Base|Live (unchanged)
```

### Owned best-base index

```text
Map<itemHash, BestArmorBaseStats>
  bestTotal,
  bestByKey[Health|Melee|Grenade|Super|Class|Weapons],
  winningInstanceId (optional)
```

- Built from inventory projections on sync / inventory change (not per keystroke).  
- Memoize with results + inventory snapshot hash (GAP-PERF awareness).

### Package placement

| Concern | Place |
| --- | --- |
| Nested tree | Existing `packages/manifest` (`group_catalog.dart`) — no fork |
| Armor dim list | Trim `armorGroupDimensions` → Class + Slot |
| Best-base sort / peak key | Pure helper next to `sort_armor.dart` (manifest) |
| Board build | Existing `db` / `bungie` projectors |
| Grid + outline chrome | `packages/ui_flutter` — extend `CatalogArmorGrid`; reuse `CatalogGroupHeader` / outline rail |
| Wire + index | `apps/windows_host` catalog |
| `domain` / `sandbox_data` | Stay pure; no inventory IO |

## Phased delivery

### Phase 1 — Structural group-by (S–M)

1. Product grill lock (dims Class+Slot, flat default, outline gates).  
2. Pure: trim armor dims; tests Class→Slot nested armor fixtures + armor slot order.  
3. UI: `CatalogArmorGrid` tree API (itemTree, collapse, scroll-spy, group keys) — mirror weapons item path.  
4. Host: unhide group-by under More for armor with **armor** dim list; nested branch + outline.  
5. Mode / collection dim sanitization.  
6. Widget + host smoke tests; light Capture must-rows (flat, 1-dim, 2-dim nested, outline).

**Suggested slice:** `area-ux-component` → brief `006-catalog-armor-groupby`.

### Phase 2 — Highest X rank (M)

1. Grill: base-only, six keys + total, unowned trail, compose with groups.  
2. System: best-base index per definition; pure comparator; unit tests (best-of-copies, ties, missing last).  
3. Host: build index; **Rank by** control; apply after filter, within leaf groups.  
4. Collections: persist rank key when schema allows (session-only first OK).  
5. Capture: Warlock + Helmet + Rank Super; multi-copy identity wins by Super.

**Suggested slice:** `007-catalog-armor-stat-rank` (or same brief with Phase 2 must-follow).

### Phase 3 — Presets / collections (S)

- Named collection: Owned + class Warlock + slot Helmet + rank Super.  
- Optional later “vault recipes” (not optimizer).

### Phase 4 — Peak-stat group dim (optional)

- Dim = peak base stat label of best owned copy; Unknown last.

## Acceptance sketches

1. **Structural:** Group Class → Slot → expand Warlock → Helmet → identity grid.  
2. **Highest Super:** Rank by Super → owned highest base Super first; unowned last.  
3. **Combined:** Group Class → Slot + Rank Super → under `Warlock · Helmet`, order by best Super.  
4. **Compare copies:** Select identity → instance strip multi-copy; Base board rebinds (C8).  
5. **No invent:** Definition without base projections never ranks above real rolls.

## Risks

| Risk | Mitigation |
| --- | --- |
| Rank on live (mods inflate) | Base only for rank v1 |
| Full-vault index every refilter | Snapshot index; debounce; memo |
| Cards look stat-blind while sorted by Super | Accept honesty; optional peak badge residual |
| Rank vs Group confusion | Separate controls + short chrome copy |
| Shipping Archetype group → Unknown | Drop frame dim until extractors fill a field |
| God `CatalogPage` growth | Tree API on `CatalogArmorGrid`; pure sort not only in host |

## Process (D-LANES)

| Work | Lane |
| --- | --- |
| Class/Slot group chrome | `area-ux-component` (not full C8 redesign) |
| Stat rank chrome | Same or follow-on component |
| Best-base index + sort | Pure + host; Spec Kit only if tracked DART slice desired |
| Optimizer / set fill | Out |

**Next actions when scheduling:**

1. Lock open decisions (below) in grill.  
2. Run `area-ux-component` for `006-catalog-armor-groupby` (or combined brief).  
3. Implement Phase 1 → Phase 2 → Capture.  
4. Update vault `UX Catalog — Armor.md` residual when brief locks.

## Open decisions (lock in grill)

1. **Rank unit** — best owned copy of definition (**recommended**) vs instance-as-row (breaks identity grid / C8).  
2. **v1 dims** — Class+Slot only, or also Exotic/Legendary section?  
3. **Process** — one combined UX brief vs group-by first then stat-rank?

## Non-goals (repeat)

- Reimplement nested group pure logic in the host  
- Group-by as substitute for class/slot **filters**  
- Invent set-bonus / energy grouping without projectable fields  
- Armor optimizer in Catalog  
- Claiming C8 incomplete solely for missing group-by (this is a **residual**, not C8 re-open)

## Pointers for implementers

| Need | Where |
| --- | --- |
| Armor C8 product lock | `001-armor-brief.md` |
| Nested tree contracts | `005-catalog-nested-groupby-brief.md`, `packages/manifest/.../group_catalog.dart` |
| Host armor short-circuit | `apps/windows_host/lib/catalog/catalog_page.dart` (armor grid branch; group row skip) |
| Instance base boards | `armor_detail_projection.dart`, `db` `instance_projection.dart` |
| Path residual | `docs/ux-redesign/REDESIGN-PATH.md` §6 |
