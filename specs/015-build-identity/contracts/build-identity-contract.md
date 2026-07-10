# Contract: Build Identity Fields

**Feature**: 015-build-identity  
**Type**: API create/update + resolve behavior  
**Related**: [data-model.md](../data-model.md), [build-create-designation-contract.md](../../012-build-pipeline-consistency/contracts/build-create-designation-contract.md)

## Purpose

Define how identity fields are accepted on create/update and how build-shared exotic weapon participates in variant resolve. Tags remain non-identity.

## POST `/api/user/builds`

### Request (identity-focused)

```json
{
  "name": "",
  "className": "Warlock",
  "subclass": {
    "name": "Stormcaller",
    "super": "Chaos Reach",
    "classAbility": "Healing Rift",
    "movement": "Burst Glide",
    "melee": "Ball Lightning",
    "grenade": "Storm Grenade",
    "aspects": ["Electrostatic Mind"],
    "fragments": ["Spark of Shock"]
  },
  "exoticArmorHash": null,
  "exoticArmorName": null,
  "exoticWeaponHash": 1234567890,
  "exoticWeaponName": "Riskrunner",
  "pinnedSuper": "Chaos Reach",
  "tagIds": ["pve", "arc"],
  "synergyIds": ["<synergy-uuid>"],
  "defaultVariant": { "name": "Default" }
}
```

### Behavior changes vs 012

| Rule | Before | After |
|------|--------|-------|
| `exoticArmorHash` | Required positive int | **Optional / nullable** — omit or `null` = no exotic armor identity |
| `exoticWeaponHash` (build) | N/A (variant only) | **Optional** — when set, build-shared identity |
| `pinnedSuper` | N/A | **Optional** — when set, Super is identity |
| `name` | Required non-empty | **Optional** — blank/omit → server derives default name |
| `synergyIds` | ≥1 (`NO_SYNERGY`) | Unchanged |
| `tagIds` | Optional | Unchanged; **not** identity |

### Response

Build detail includes new fields: `exoticWeaponHash`, `exoticWeaponName`, `pinnedSuper`, nullable `exoticArmorHash`.

## Resolve: exotic weapon preference

When resolving a variant’s equipment:

1. If build `exoticWeaponHash` is set → claim that weapon for the variant (build-shared).
2. Else if variant `exoticWeaponHash` is set → claim variant weapon.
3. Else → no exotic weapon claim from identity fields (sets may still supply weapons).

## Tags

PATCH `{ "tagIds": [...] }` alone MUST NOT require `identityAction` and MUST NOT fork.
