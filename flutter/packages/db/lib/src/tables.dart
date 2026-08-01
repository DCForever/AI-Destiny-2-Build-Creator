import 'package:drift/drift.dart';

/// Product `users` table.
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bungieMembershipId => text()();
  IntColumn get membershipType => integer()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get lastSyncAt => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {bungieMembershipId},
      ];
}

/// Product `inventory_items` — owned instance rows.
@TableIndex(name: 'idx_inventory_user_hash', columns: {#userId, #itemHash})
@TableIndex(name: 'idx_inventory_user_bucket', columns: {#userId, #bucket})
@TableIndex(name: 'idx_inventory_user_location', columns: {#userId, #location})
class InventoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer()();
  TextColumn get instanceId => text()();
  IntColumn get itemHash => integer()();
  TextColumn get bucket => text()();
  TextColumn get location => text()();
  TextColumn get characterId => text().nullable()();
  IntColumn get power => integer().withDefault(const Constant(0))();
  IntColumn get isMasterwork => integer().withDefault(const Constant(0))();
  IntColumn get isCrafted => integer().withDefault(const Constant(0))();
  TextColumn get plugHashes => text().withDefault(const Constant('[]'))();
  TextColumn get rollTags => text().withDefault(const Constant('[]'))();
  TextColumn get statValues => text().nullable()();
  IntColumn get gearTier => integer().nullable()();
  TextColumn get socketPlugs => text().nullable()();
  TextColumn get syncedAt => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, instanceId},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE',
      ];
}

/// Product `inventory_sync_meta`.
class InventorySyncMeta extends Table {
  IntColumn get userId => integer()();
  IntColumn get itemCount => integer().withDefault(const Constant(0))();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();
  TextColumn get lastFullSyncAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE',
      ];
}

/// Product `loadouts` (schema parity).
@TableIndex(name: 'idx_loadouts_user_updated', columns: {#userId, #updatedAt})
class Loadouts extends Table {
  TextColumn get id => text()();
  IntColumn get userId => integer()();
  TextColumn get name => text()();
  TextColumn get source => text()();
  TextColumn get manifestVersion => text()();
  TextColumn get buildRequest => text().nullable()();
  TextColumn get generatedBuild => text()();
  TextColumn get resolvedSheet => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE',
      ];
}

/// Product `sets`.
///
/// Data class is [LibrarySet] (not `Set`) so generated code does not shadow
/// `dart:core.Set`.
@DataClassName('LibrarySet')
@TableIndex(
  name: 'idx_sets_user_type_name',
  columns: {#userId, #type, #name},
  unique: true,
)
class Sets extends Table {
  TextColumn get id => text()();
  IntColumn get userId => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get optimizerConstraints => text().nullable()();
  TextColumn get linkedModSetId => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE',
      ];
}

/// Product `set_tags`.
@TableIndex(name: 'idx_set_tags_tag', columns: {#tagId, #setId})
class SetTags extends Table {
  TextColumn get setId => text()();
  TextColumn get tagId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {setId, tagId},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (set_id) REFERENCES sets (id) ON DELETE CASCADE',
      ];
}

/// Product `set_items`.
@TableIndex(name: 'idx_set_items_set', columns: {#setId})
class SetItems extends Table {
  TextColumn get id => text()();
  TextColumn get setId => text()();
  TextColumn get slot => text()();
  IntColumn get itemHash => integer()();
  TextColumn get itemName => text()();
  TextColumn get selectedPerks => text().withDefault(const Constant('[]'))();
  IntColumn get masterworkHash => integer().nullable()();
  TextColumn get modHashes => text().nullable()();
  TextColumn get instanceId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get removedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (set_id) REFERENCES sets (id) ON DELETE CASCADE',
      ];
}

/// Product `synergies`.
class Synergies extends Table {
  TextColumn get id => text()();
  IntColumn get userId => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get subType => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE',
      ];
}

/// Product `synergy_links`.
@TableIndex(name: 'idx_synergy_links_synergy', columns: {#synergyId})
class SynergyLinks extends Table {
  TextColumn get id => text()();
  TextColumn get synergyId => text()();
  TextColumn get kind => text()();
  TextColumn get displayName => text()();
  IntColumn get itemHash => integer().nullable()();
  IntColumn get perkHash => integer().nullable()();
  IntColumn get parentItemHash => integer().nullable()();
  TextColumn get originTraitName => text().nullable()();
  IntColumn get originTraitHash => integer().nullable()();
  TextColumn get armorSetName => text().nullable()();
  IntColumn get bonusPieces => integer().nullable()();
  TextColumn get bonusName => text().nullable()();
  IntColumn get armorSetHash => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (synergy_id) REFERENCES synergies (id) ON DELETE CASCADE',
      ];
}

/// Product `builds`.
class Builds extends Table {
  TextColumn get id => text()();
  IntColumn get userId => integer()();
  TextColumn get name => text()();
  TextColumn get className => text()();
  TextColumn get subclass => text()();
  IntColumn get exoticArmorHash => integer().nullable()();
  TextColumn get exoticArmorName => text().nullable()();
  IntColumn get exoticWeaponHash => integer().nullable()();
  TextColumn get exoticWeaponName => text().nullable()();
  TextColumn get pinnedSuper => text().nullable()();
  TextColumn get softStatTargets => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE',
      ];
}

/// Product `build_tags`.
class BuildTags extends Table {
  TextColumn get buildId => text()();
  TextColumn get tagId => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {buildId, tagId},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (build_id) REFERENCES builds (id) ON DELETE CASCADE',
      ];
}

/// Product `build_variants`.
class BuildVariants extends Table {
  TextColumn get id => text()();
  TextColumn get buildId => text()();
  TextColumn get name => text()();
  IntColumn get isDefault => integer().withDefault(const Constant(0))();
  IntColumn get exoticWeaponHash => integer().nullable()();
  TextColumn get exoticWeaponName => text().nullable()();
  IntColumn get artifactHash => integer().nullable()();
  TextColumn get artifactName => text().nullable()();
  TextColumn get artifactConfig => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (build_id) REFERENCES builds (id) ON DELETE CASCADE',
      ];
}

/// Product `build_synergy_types`.
class BuildSynergyTypes extends Table {
  TextColumn get buildId => text()();
  TextColumn get type => text()();
  TextColumn get subType => text().nullable()();
  TextColumn get attachedAt => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {buildId, type, subType},
      ];

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (build_id) REFERENCES builds (id) ON DELETE CASCADE',
      ];
}

/// Product `variant_set_attachments` — set delete RESTRICT.
@TableIndex(name: 'idx_variant_attachments_set', columns: {#setId})
class VariantSetAttachments extends Table {
  TextColumn get id => text()();
  TextColumn get variantId => text()();
  TextColumn get setId => text()();
  TextColumn get mode => text()();
  TextColumn get snapshotConfigs => text().nullable()();
  TextColumn get attachedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (variant_id) REFERENCES build_variants (id) ON DELETE CASCADE',
        'FOREIGN KEY (set_id) REFERENCES sets (id) ON DELETE RESTRICT',
      ];
}
