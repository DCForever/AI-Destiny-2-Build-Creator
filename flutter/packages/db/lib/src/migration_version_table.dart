/// Documented Drift schema version + product ensure* step catalog (DART-014).
///
/// Product source: `src/lib/db/client.ts` (`runMigrations`, `ensure*`).
/// Greenfield create-all is [driftSchemaVersionCurrent] = 1 (DART-013 current columns).
/// Ensure steps heal partial / legacy table shapes for later import (DART-048).
library;

/// Current Drift [schemaVersion] for [AppDatabase].
///
/// Unchanged from DART-013: full current product column set via `onCreate`.
const int driftSchemaVersionCurrent = 1;

/// One row in the logical migration / ensure version table.
class EnsureStepInfo {
  const EnsureStepInfo({
    required this.id,
    required this.productFunction,
    required this.targetTable,
    required this.description,
  });

  /// Stable step id (code + docs).
  final String id;

  /// Product `ensure*` function name in `src/lib/db/client.ts`.
  final String productFunction;

  /// Primary table affected.
  final String targetTable;

  /// Human-readable SQL intent.
  final String description;
}

/// Catalog of ensure steps in the same order as product `runMigrations` ensure block.
const List<EnsureStepInfo> ensureStepCatalog = [
  EnsureStepInfo(
    id: 'synergy_sub_type',
    productFunction: 'ensureSynergySubTypeColumn',
    targetTable: 'synergies',
    description: 'ADD COLUMN sub_type TEXT if missing',
  ),
  EnsureStepInfo(
    id: 'inventory_stat_values',
    productFunction: 'ensureStatValuesColumn',
    targetTable: 'inventory_items',
    description: 'ADD COLUMN stat_values TEXT if missing',
  ),
  EnsureStepInfo(
    id: 'inventory_gear_tier',
    productFunction: 'ensureGearTierColumn',
    targetTable: 'inventory_items',
    description: 'ADD COLUMN gear_tier INTEGER if missing',
  ),
  EnsureStepInfo(
    id: 'inventory_socket_plugs',
    productFunction: 'ensureSocketPlugsColumn',
    targetTable: 'inventory_items',
    description: 'ADD COLUMN socket_plugs TEXT if missing',
  ),
  EnsureStepInfo(
    id: 'set_item_instance_id',
    productFunction: 'ensureSetItemInstanceIdColumn',
    targetTable: 'set_items',
    description: 'ADD COLUMN instance_id TEXT if missing',
  ),
  EnsureStepInfo(
    id: 'builds_identity',
    productFunction: 'ensureBuildsIdentityColumns',
    targetTable: 'builds',
    description:
        'ADD exotic_weapon_hash/name, pinned_super; rebuild builds if '
        'exotic_armor_hash NOT NULL',
  ),
  EnsureStepInfo(
    id: 'variant_artifact',
    productFunction: 'ensureVariantArtifactColumns',
    targetTable: 'build_variants',
    description:
        'ADD artifact_hash/name; ADD artifact_config TEXT NOT NULL DEFAULT \'[]\'',
  ),
  EnsureStepInfo(
    id: 'builds_soft_stat_targets',
    productFunction: 'ensureSoftStatTargetsColumn',
    targetTable: 'builds',
    description: 'ADD COLUMN soft_stat_targets TEXT if missing',
  ),
  EnsureStepInfo(
    id: 'sets_optimizer',
    productFunction: 'ensureSetOptimizerColumns',
    targetTable: 'sets',
    description:
        'ADD optimizer_constraints TEXT, linked_mod_set_id TEXT if missing',
  ),
  EnsureStepInfo(
    id: 'build_synergy_types',
    productFunction: 'ensureBuildSynergyTypesTable',
    targetTable: 'build_synergy_types',
    description:
        'CREATE build_synergy_types if missing; migrate/drop legacy build_synergies',
  ),
  EnsureStepInfo(
    id: 'synergy_link_required',
    productFunction: 'ensureSynergyLinkRequiredColumn',
    targetTable: 'synergy_links',
    description:
        'ADD COLUMN required INTEGER NOT NULL DEFAULT 0 (DBR-SYN-007–010a)',
  ),
  EnsureStepInfo(
    id: 'variant_subclass_kit',
    productFunction: 'ensureVariantSubclassKitColumn',
    targetTable: 'build_variants',
    description:
        'ADD subclass_kit TEXT DEFAULT \'{}\'; seed kit pieces from builds.subclass '
        '(pkg-variant-subclass-kit / DBR-SUB-003)',
  ),
  EnsureStepInfo(
    id: 'weapon_roll_targets',
    productFunction: 'ensureWeaponRollTargetsTables',
    targetTable: 'weapon_roll_targets',
    description:
        'CREATE weapon_roll_targets + weapon_roll_target_active (DART-073 / DBR-IDL-*)',
  ),
];

/// Expected step ids (for tests / completeness checks).
const List<String> expectedEnsureStepIds = [
  'synergy_sub_type',
  'inventory_stat_values',
  'inventory_gear_tier',
  'inventory_socket_plugs',
  'set_item_instance_id',
  'builds_identity',
  'variant_artifact',
  'builds_soft_stat_targets',
  'sets_optimizer',
  'build_synergy_types',
  'synergy_link_required',
  'variant_subclass_kit',
  'weapon_roll_targets',
];
