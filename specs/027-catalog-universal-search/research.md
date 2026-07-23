# Research: Catalog Universal Search

**Feature**: 027-catalog-universal-search  
**Date**: 2026-07-23

## R1 — Single mixed-kind API vs multi-fetch client

**Decision**: Add **`GET /api/catalog/universal-search`** backed by a pure `searchCompositionCatalog` that queries multiple entity-cache stores in one request and returns a mixed `hits[]` with `kind` labels.

**Rationale**:
- Spec requires one Catalog entry point and mixed results (FR-001–FR-003), not weapons-only.
- Today `/api/manifest/search` is **single-category**; client would need N parallel calls and inconsistent ranking.
- Catalog weapons/armor routes are facet-heavy and gear-shaped; perks/traits/artifacts do not fit `CatalogItem` cleanly.
- Server composition keeps ranking, limits, and manifest-ready checks consistent (FR-009).

**Alternatives considered**:
- Client fan-out to multiple endpoints — divergent limits/ranking; harder empty/manifest handling.
- Extend `/api/manifest/search` with `category=all` — couples single-store filters; muddy contract.
- Full-text DB index — unnecessary at current entity-cache scale.

## R2 — Which stores/kinds are in scope

**Decision**: v1 kinds map to existing stores / picker kinds:

| Kind id | Source | Set action | Synergy action |
|---------|--------|------------|----------------|
| `weapon` | `weapons` | Weapon Set | `weapon` when applicable |
| `exotic_weapon` | `exotic-weapons` | Weapon/Pair Set | `weapon` |
| `armor` | legendary projection / catalog armor | Armor Set | via set bonus / exotic |
| `exotic_armor` | `exotic-armor` | Armor/Pair Set | `exotic_armor` |
| `mod` | `mods` | Mod Set | generally none |
| `weapon_perk` | `weapon-perks` | none | `weapon_perk` |
| `origin_trait` | `origin-traits` | none | `origin_trait` |
| `armor_set_bonus` | `set-bonuses` tiers | none as item | `armor_set_bonus` |
| `artifact_perk` | `artifacts` perks | none | `artifact_perk` |
| `aspect` / `fragment` / `ability` | respective stores | none as Sets | none unless already linkable |

**Rationale**: Matches FR-002 and DBR composition. Fashion excluded per spec.

## R3 — Match and rank algorithm

**Decision**: Reuse `matchDescriptionQuery` / `sortByMatchRankThenName` from `src/lib/search/descriptionMatch.ts` (009). Name before description-only; soft per-kind caps; total limit ~48–60.

## R4 — Detail + composition actions

**Decision**: Client detail from hit; Set/Synergy mutations via existing user APIs; eligibility in `compositionKinds.ts`.

## R5 — Ownership

**Decision**: Annotate equippable hits when signed in + inventory synced; default search includes unowned catalog identity.

## R6 — UI placement

**Decision**: Production Catalog (`CatalogScreen`); keep specialized weapon/armor facets; preserve query on back from detail.

## R7 — Auth

**Decision**: Search browse optional auth; mutations require session.

## Cross-cutting

- No new SQLite tables.
- Gate after each story.
