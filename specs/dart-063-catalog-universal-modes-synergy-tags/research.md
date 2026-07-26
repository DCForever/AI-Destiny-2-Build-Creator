# Research: DART-063

**Date**: 2026-07-25

## Product references

| Concern | Next source |
| ------- | ----------- |
| Browse modes | `CatalogScreen` Weapons\|Armor\|Universal; `catalogScreenTypes.ts` |
| Universal actions | `UniversalHitDetail`, `UniversalSetActions`, `UniversalSynergyActions`, `compositionKinds.ts` |
| Synergy membership | `filterCatalogClient` synergies facet + CatalogScreen allowlists |
| Reverse tags | `/api/user/synergies/by-target` → `findSynergiesByTarget` |
| Owned detail | `OwnedInstanceCard`, `InstancePerkGridView`, `ArmorStatsPanel` |

## Dart baseline (DART-062)

- Multi-facet + group-by + alpha sort already on hosts
- Exotic weapons + legendary armor in projector
- `linkedSynergyIds` on `CatalogItem` + pure filter support; hosts unwired
- Instance projection: raw plug hashes only

## Decisions

| ID | Decision | Rationale |
| -- | -------- | --------- |
| R1 | Mode filter by `sourceStore` | Already projected; no re-extract |
| R2 | ItemHash primary for membership annotate | Matches by-target weapon/exotic_armor links without perk index |
| R3 | Reverse tags on detail (not every row) | Matches Next selection fetch; cheaper |
| R4 | Minimal Universal create CTAs | Close BR-CAT-009 without DART-065/066 scope |
| R5 | Enrich projection from stored fields | DART-050–052 already persist sockets/stats |

## Residuals

- Perk→weapon allowlists without entity perk index
- Full socket column grid chrome when capture incomplete
- Icons polish → DART-068
