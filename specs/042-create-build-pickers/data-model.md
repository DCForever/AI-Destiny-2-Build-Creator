# Data Model: 042-create-build-pickers

No persistent schema changes.

## View models (client)

### ManifestPick (extended usage)

| Field | Notes |
|-------|--------|
| hash, name, icon, kind, description | existing |
| slot | used for exotic armor grouping |
| linkedSynergies? | `{ id, label }[]` attached after batch lookup |

### ExoticArmorSearchGroup

| Field | Notes |
|-------|--------|
| key | slot enum string |
| label | human slot label |
| items | ManifestPick[] name-sorted |

### LinkedSynergyChip

| Field | Notes |
|-------|--------|
| id | synergy id |
| label | designation string (type + subtype) |

## Relationships

- Exotic armor hash → many library synergies via `synergy_links.kind = exotic_armor`
- Super pick stores name only (existing); no synergy link kind for abilities
