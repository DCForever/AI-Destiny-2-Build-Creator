# Data Model: Catalog Universal Search

**Feature**: 027-catalog-universal-search  
**Date**: 2026-07-23

Ephemeral search/session DTOs over existing entity cache and library tables. **No new durable tables in v1.**

## CompositionKind

| Value | Display label | Primary identity |
|-------|---------------|------------------|
| `weapon` | Weapon | item hash |
| `exotic_weapon` | Exotic weapon | item hash |
| `armor` | Armor | item hash |
| `exotic_armor` | Exotic armor | item hash |
| `mod` | Mod | item hash |
| `weapon_perk` | Weapon perk | perk hash |
| `origin_trait` | Origin trait | trait hash |
| `armor_set_bonus` | Armor set bonus | set hash + requiredCount |
| `artifact_perk` | Artifact perk | perk hash + artifact |
| `aspect` | Aspect | hash |
| `fragment` | Fragment | hash |
| `ability` | Ability | hash |

## UniversalSearchQuery

| Field | Type | Rules |
|-------|------|-------|
| `q` | string | trim; max ~80; whitespace-only → need query |
| `kinds` | CompositionKind[] optional | omit = all v1 kinds |
| `limit` | number optional | default ~48; max ~100 |
| `includeOwned` | boolean optional | annotate ownership when authed |

## CompositionSearchHit

| Field | Type | Notes |
|-------|------|-------|
| `kind` | CompositionKind | required |
| `id` | string | stable key e.g. `weapon_perk:123` |
| `name` | string | non-empty |
| `description` | string | may be empty |
| `icon` | string or null | |
| `hash` | number optional | when single-hash identity |
| `meta` | object optional | slot, class, element, energy, bonusPieces, etc. |
| `matchField` | name / description / other / null | ranking |
| `owned` | `{ count }` or null | |
| `actions` | `{ set, synergy }` booleans | eligibility |

## CatalogDetailContext (client)

Hit selection + query snapshot + optional instances + set/synergy wizard state.

## SetPlacementIntent

mode create|add; setType; setId?; name?; slot; itemHash; itemName; instanceId?; selectedPerks? — maps to existing set item writes. Transitions: create/add → set → slot → optional instance → replace confirm → persist. Blocked by existing exotic/slot rules.

## SynergyLinkIntent

mode create|add; synergyId?; type/subType for create; link payload as SynergyLinkInput. Dedupe one evidence target per synergy (BR-SYN-011). Designation immutable after create (DBR-SYN-012).

## Relationships

UniversalSearchQuery → CompositionSearchHit[] → CatalogDetailContext → SetPlacementIntent | SynergyLinkIntent → existing library records.

## Non-goals

No search history table; no denormalized universal index unless later perf requires it.
