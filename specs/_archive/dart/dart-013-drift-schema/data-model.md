# Data Model: DART-013 Drift Schema

**Source of truth (product):** `src/lib/db/schema.ts` + current columns from `src/lib/db/client.ts`  
**Dart package:** `destiny2_db`  
**schemaVersion:** `1` (greenfield create-all; migrations = DART-014)

## Entity relationship (core)

```text
users 1──* inventory_items
users 1──1 inventory_sync_meta
users 1──* sets 1──* set_items
             └──* set_tags
users 1──* synergies 1──* synergy_links
users 1──* builds 1──* build_variants 1──* variant_set_attachments *──1 sets (RESTRICT)
             ├──* build_tags
             └──* build_synergy_types
users 1──* loadouts
```

## Critical uniques (must enforce)

| Table | Unique key | Product name / note |
| ----- | ---------- | ------------------- |
| `users` | `bungie_membership_id` | column UNIQUE |
| `inventory_items` | `(user_id, instance_id)` | table UNIQUE |
| `sets` | `(user_id, type, name)` | `idx_sets_user_type_name` |
| `set_tags` | `(set_id, tag_id)` | table UNIQUE |
| `build_tags` | `(build_id, tag_id)` | table UNIQUE |
| `build_synergy_types` | `(build_id, type, sub_type)` | table UNIQUE |
| `inventory_sync_meta` | `user_id` PK | one meta row |

## Supporting indexes

| Name (product) | Table | Columns |
| -------------- | ----- | ------- |
| `idx_inventory_user_hash` | inventory_items | user_id, item_hash |
| `idx_inventory_user_bucket` | inventory_items | user_id, bucket |
| `idx_inventory_user_location` | inventory_items | user_id, location |
| `idx_set_tags_tag` | set_tags | tag_id, set_id |
| `idx_set_items_set` | set_items | set_id |
| `idx_synergy_links_synergy` | synergy_links | synergy_id |
| `idx_variant_attachments_set` | variant_set_attachments | set_id |
| `idx_loadouts_user_updated` | loadouts | user_id, updated_at |

## FK / delete policy highlights

| Child | Parent | ON DELETE |
| ----- | ------ | --------- |
| Most user-owned rows | users | CASCADE |
| set_items / set_tags | sets | CASCADE |
| synergy_links | synergies | CASCADE |
| build_* / variants | builds | CASCADE |
| variant_set_attachments | build_variants | CASCADE |
| **variant_set_attachments.set_id** | **sets** | **RESTRICT** |

## Column notes (parity highlights)

- Timestamps: ISO text (same as product).
- JSON blobs: TEXT (`plug_hashes`, `artifact_config`, `optimizer_constraints`, `soft_stat_targets`, …).
- Booleans as INTEGER 0/1 (`is_masterwork`, `is_default`, …).
- Nullable identity fields on builds: exotic hashes/names, `pinned_super`, `soft_stat_targets`.
- Inventory extras: `stat_values`, `gear_tier`, `socket_plugs` (nullable).
- Set items: nullable `instance_id`, `removed_at`.
- Synergies: nullable `sub_type`.

## Out of scope fields

No new columns beyond product current schema. No soft-evaluator side tables.
