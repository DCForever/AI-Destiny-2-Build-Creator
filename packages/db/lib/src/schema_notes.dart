/// Documented critical uniques and indexes for the Drift schema (DART-013).
///
/// Product sources: `src/lib/db/schema.ts`, `src/lib/db/client.ts` CREATE TABLE /
/// index statements. Drift index **names** may differ slightly; column sets and
/// uniqueness behavior must match.
///
/// PRAGMA policy on open: `foreign_keys = ON`.
///
/// Migration / ensure* version table: see [migration_version_table.dart] (DART-014).
library;

/// Expected core table names after clean create.
const expectedCoreTables = <String>[
  'users',
  'inventory_items',
  'inventory_sync_meta',
  'loadouts',
  'sets',
  'set_tags',
  'set_items',
  'synergies',
  'synergy_links',
  'builds',
  'build_tags',
  'build_variants',
  'build_synergy_types',
  'variant_set_attachments',
];

/// Critical unique constraints (logical).
///
/// | Table | Columns | Product note |
/// | ----- | ------- | ------------ |
/// | users | bungie_membership_id | column UNIQUE |
/// | inventory_items | user_id, instance_id | table UNIQUE |
/// | sets | user_id, type, name | idx_sets_user_type_name |
/// | set_tags | set_id, tag_id | table UNIQUE |
/// | build_tags | build_id, tag_id | table UNIQUE |
/// | build_synergy_types | build_id, type, sub_type | table UNIQUE |
/// | inventory_sync_meta | user_id | PRIMARY KEY |
const criticalUniqueNotes = <String, List<String>>{
  'users': ['bungie_membership_id'],
  'inventory_items': ['user_id', 'instance_id'],
  'sets': ['user_id', 'type', 'name'],
  'set_tags': ['set_id', 'tag_id'],
  'build_tags': ['build_id', 'tag_id'],
  'build_synergy_types': ['build_id', 'type', 'sub_type'],
  'inventory_sync_meta': ['user_id'],
};

/// Supporting non-unique indexes (product names).
const supportingIndexNotes = <String, String>{
  'idx_inventory_user_hash': 'inventory_items(user_id, item_hash)',
  'idx_inventory_user_bucket': 'inventory_items(user_id, bucket)',
  'idx_inventory_user_location': 'inventory_items(user_id, location)',
  'idx_set_tags_tag': 'set_tags(tag_id, set_id)',
  'idx_set_items_set': 'set_items(set_id)',
  'idx_synergy_links_synergy': 'synergy_links(synergy_id)',
  'idx_variant_attachments_set': 'variant_set_attachments(set_id)',
  'idx_loadouts_user_updated': 'loadouts(user_id, updated_at)',
};

/// Product index name used in PRAGMA index_list for sets uniqueness.
const setsUserTypeNameIndex = 'idx_sets_user_type_name';

/// Product RESTRICT: cannot delete a set that is attached to a variant.
const variantSetAttachmentRestrictNote =
    'variant_set_attachments.set_id REFERENCES sets(id) ON DELETE RESTRICT';
