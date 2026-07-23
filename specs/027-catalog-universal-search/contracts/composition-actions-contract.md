# Contract: Composition Actions from Catalog Detail

**Feature**: 027-catalog-universal-search  
**Type**: UI orchestration over existing mutation APIs (no required new write endpoint)

## Principle

Catalog detail **orchestrates** existing authenticated routes. Do not fork validation.

## Set create

1. `POST /api/user/sets` with name, type, optional tags.
2. Upsert set item with slot + itemHash (+ instanceId/perks).

Preconditions: session; `actions.set`; legal type for kind; unique name.

Slot mapping: reuse 008 set-slot ↔ catalog bucket table.

## Set add

1. List user sets; filter compatible type.
2. Pick set + slot.
3. Upsert; occupied slot → existing replace confirmation.

Hard blocks: exotic exclusivity, slot fitness, mod energy — existing error codes.

## Synergy create

1. `POST /api/user/synergies` with type/subType (immutable after create).
2. Add link derived from hit.

## Synergy add link

1. Pick synergy from list.
2. Add link via existing synergy edit/link path.
3. Duplicate target → no duplicate row (already linked).

### Link derivation (examples)

| Hit kind | Link kind |
|----------|-----------|
| weapon_perk | weapon_perk |
| origin_trait | origin_trait |
| armor_set_bonus | armor_set_bonus |
| exotic_armor | exotic_armor |
| artifact_perk | artifact_perk |
| weapon / exotic_weapon | weapon |

Hide synergy CTA when `actions.synergy` is false.

## Success UX

Confirm with target name; optional navigate to Sets/Synergies.

## Auth

Mutations require signed-in user.
