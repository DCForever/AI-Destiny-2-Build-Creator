# Research: DART-062 Catalog Browse Semantics

**Date**: 2026-07-25

## Product reference

| Concern | Next location | Dart target |
| ------- | ------------- | ----------- |
| Multi-facet filter | `src/lib/catalog/filterItems.ts`, facet chips in Catalog UI | `filter_catalog.dart` (exists) + host chips |
| Group-by | `src/lib/catalog/groupCatalogItems.ts` | NEW `group_catalog.dart` |
| Alpha sort | `src/lib/sortByName.ts` `compareDisplayName` | NEW `sort_by_name.dart` |
| Exotic weapons | `src/lib/manifest/extractors/exoticWeapons.ts` store `exotic-weapons` | NEW extractor + store |
| Legendary armor | `src/lib/catalog/legendaryArmor.ts` (via set bonuses) | NEW `legendary-armor` tier-5 extract (A3: no set-bonus required for GAP close) |

## Current Dart gaps

- Hosts only wire element / ammo / exotic chips; filter accepts slots/class/archetypes unused by UI.
- No group-by API or UI.
- `filterCatalogClient` preserves input order (not alpha).
- Weapons extractor is legendary-only (`tierType == 5`); exotic weapons absent.
- Armor path is exotic-only (`exotic-armor` store).

## Decisions

1. **Legendary armor extract without set-bonus store** — full tier-5 armor defs for browse; set-bonus fields residual.
2. **Alpha sort inside `filterCatalogClient`** — all browse callers get consistent order.
3. **Group-by pure + host-owned UI** — hosts call `groupCatalogItems` after filter; empty dims → single bucket.
4. **Missing store = empty** — offline load tries new stores; exceptions → `[]`.

## Non-goals confirmed

Universal, synergy membership UI, owned perk cards, icons polish → DART-063/068.
