# Data Model: Bungie Equip

## EquipRequest

| Field | Type | Notes |
|-------|------|-------|
| characterId | string | Required; must match build class |

## EquipStep

| Field | Type | Notes |
|-------|------|-------|
| id | string | Stable step id |
| kind | transfer \| equip \| artifact \| fashion | |
| slot / itemHash / instanceId | optional | Context |
| ok | boolean | |
| error | string? | |

## EquipStatus

Aggregate of steps + `allowed` precondition already passed.

## No new DB tables

Uses inventory instances, sync meta, resolved variant.
