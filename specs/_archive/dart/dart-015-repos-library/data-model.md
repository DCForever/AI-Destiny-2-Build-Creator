# Data model: DART-015 repository records

Records are **persistence DTOs** over Drift tables from DART-013. Not pure domain models.

## BuildRecord

| Field | Storage |
| ----- | ------- |
| id, userId, name, className | builds |
| subclass | JSON text |
| exoticArmorHash/Name, exoticWeaponHash/Name, pinnedSuper | nullable |
| softStatTargets | JSON object string (default `{}`) |
| tagIds | build_tags |
| synergyTypes | build_synergy_types (`sub_type` `""` ↔ null) |
| createdAt, updatedAt | ISO text |

## SetRecord

| Field | Storage |
| ----- | ------- |
| id, userId, name, type | sets |
| tagIds | set_tags |
| optimizerConstraints, linkedModSetId | nullable text |
| createdAt, updatedAt | ISO text |

## SetItemRecord (persistence)

| Field | Storage |
| ----- | ------- |
| id, setId, slot, itemHash, itemName | set_items |
| selectedPerks | JSON int array |
| masterworkHash, modHashes, instanceId | nullable |
| sortOrder, removedAt | int / nullable text |

## SynergyRecord + SynergyLinkRecord

Parent `synergies` + child `synergy_links` (kind, displayName, hashes, armor set bonus fields).

## VariantRecord + AttachmentRecord

`build_variants` + `variant_set_attachments` (mode `live`|`snapshot`, snapshotConfigs JSON).

## SetAttachmentRef

Join projection: buildId, buildName, variantId, variantName for a setId.

## FK semantics (unchanged)

| Edge | On delete |
| ---- | --------- |
| variant_set_attachments.set_id → sets | **RESTRICT** |
| variant_set_attachments.variant_id → build_variants | CASCADE |
| build_variants.build_id → builds | CASCADE |
| set_items.set_id → sets | CASCADE |
