// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _bungieMembershipIdMeta =
      const VerificationMeta('bungieMembershipId');
  @override
  late final GeneratedColumn<String> bungieMembershipId =
      GeneratedColumn<String>('bungie_membership_id', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _membershipTypeMeta =
      const VerificationMeta('membershipType');
  @override
  late final GeneratedColumn<int> membershipType = GeneratedColumn<int>(
      'membership_type', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _lastSyncAtMeta =
      const VerificationMeta('lastSyncAt');
  @override
  late final GeneratedColumn<String> lastSyncAt = GeneratedColumn<String>(
      'last_sync_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, bungieMembershipId, membershipType, displayName, lastSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bungie_membership_id')) {
      context.handle(
          _bungieMembershipIdMeta,
          bungieMembershipId.isAcceptableOrUnknown(
              data['bungie_membership_id']!, _bungieMembershipIdMeta));
    } else if (isInserting) {
      context.missing(_bungieMembershipIdMeta);
    }
    if (data.containsKey('membership_type')) {
      context.handle(
          _membershipTypeMeta,
          membershipType.isAcceptableOrUnknown(
              data['membership_type']!, _membershipTypeMeta));
    } else if (isInserting) {
      context.missing(_membershipTypeMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
          _lastSyncAtMeta,
          lastSyncAt.isAcceptableOrUnknown(
              data['last_sync_at']!, _lastSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {bungieMembershipId},
      ];
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bungieMembershipId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}bungie_membership_id'])!,
      membershipType: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}membership_type'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      lastSyncAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_sync_at']),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String bungieMembershipId;
  final int membershipType;
  final String displayName;
  final String? lastSyncAt;
  const User(
      {required this.id,
      required this.bungieMembershipId,
      required this.membershipType,
      required this.displayName,
      this.lastSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['bungie_membership_id'] = Variable<String>(bungieMembershipId);
    map['membership_type'] = Variable<int>(membershipType);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<String>(lastSyncAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      bungieMembershipId: Value(bungieMembershipId),
      membershipType: Value(membershipType),
      displayName: Value(displayName),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      bungieMembershipId:
          serializer.fromJson<String>(json['bungieMembershipId']),
      membershipType: serializer.fromJson<int>(json['membershipType']),
      displayName: serializer.fromJson<String>(json['displayName']),
      lastSyncAt: serializer.fromJson<String?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bungieMembershipId': serializer.toJson<String>(bungieMembershipId),
      'membershipType': serializer.toJson<int>(membershipType),
      'displayName': serializer.toJson<String>(displayName),
      'lastSyncAt': serializer.toJson<String?>(lastSyncAt),
    };
  }

  User copyWith(
          {int? id,
          String? bungieMembershipId,
          int? membershipType,
          String? displayName,
          Value<String?> lastSyncAt = const Value.absent()}) =>
      User(
        id: id ?? this.id,
        bungieMembershipId: bungieMembershipId ?? this.bungieMembershipId,
        membershipType: membershipType ?? this.membershipType,
        displayName: displayName ?? this.displayName,
        lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      bungieMembershipId: data.bungieMembershipId.present
          ? data.bungieMembershipId.value
          : this.bungieMembershipId,
      membershipType: data.membershipType.present
          ? data.membershipType.value
          : this.membershipType,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      lastSyncAt:
          data.lastSyncAt.present ? data.lastSyncAt.value : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('bungieMembershipId: $bungieMembershipId, ')
          ..write('membershipType: $membershipType, ')
          ..write('displayName: $displayName, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, bungieMembershipId, membershipType, displayName, lastSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.bungieMembershipId == this.bungieMembershipId &&
          other.membershipType == this.membershipType &&
          other.displayName == this.displayName &&
          other.lastSyncAt == this.lastSyncAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> bungieMembershipId;
  final Value<int> membershipType;
  final Value<String> displayName;
  final Value<String?> lastSyncAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.bungieMembershipId = const Value.absent(),
    this.membershipType = const Value.absent(),
    this.displayName = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String bungieMembershipId,
    required int membershipType,
    this.displayName = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  })  : bungieMembershipId = Value(bungieMembershipId),
        membershipType = Value(membershipType);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? bungieMembershipId,
    Expression<int>? membershipType,
    Expression<String>? displayName,
    Expression<String>? lastSyncAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bungieMembershipId != null)
        'bungie_membership_id': bungieMembershipId,
      if (membershipType != null) 'membership_type': membershipType,
      if (displayName != null) 'display_name': displayName,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? bungieMembershipId,
      Value<int>? membershipType,
      Value<String>? displayName,
      Value<String?>? lastSyncAt}) {
    return UsersCompanion(
      id: id ?? this.id,
      bungieMembershipId: bungieMembershipId ?? this.bungieMembershipId,
      membershipType: membershipType ?? this.membershipType,
      displayName: displayName ?? this.displayName,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bungieMembershipId.present) {
      map['bungie_membership_id'] = Variable<String>(bungieMembershipId.value);
    }
    if (membershipType.present) {
      map['membership_type'] = Variable<int>(membershipType.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<String>(lastSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('bungieMembershipId: $bungieMembershipId, ')
          ..write('membershipType: $membershipType, ')
          ..write('displayName: $displayName, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _instanceIdMeta =
      const VerificationMeta('instanceId');
  @override
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
      'instance_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemHashMeta =
      const VerificationMeta('itemHash');
  @override
  late final GeneratedColumn<int> itemHash = GeneratedColumn<int>(
      'item_hash', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bucketMeta = const VerificationMeta('bucket');
  @override
  late final GeneratedColumn<String> bucket = GeneratedColumn<String>(
      'bucket', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _characterIdMeta =
      const VerificationMeta('characterId');
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
      'character_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _powerMeta = const VerificationMeta('power');
  @override
  late final GeneratedColumn<int> power = GeneratedColumn<int>(
      'power', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isMasterworkMeta =
      const VerificationMeta('isMasterwork');
  @override
  late final GeneratedColumn<int> isMasterwork = GeneratedColumn<int>(
      'is_masterwork', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isCraftedMeta =
      const VerificationMeta('isCrafted');
  @override
  late final GeneratedColumn<int> isCrafted = GeneratedColumn<int>(
      'is_crafted', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _plugHashesMeta =
      const VerificationMeta('plugHashes');
  @override
  late final GeneratedColumn<String> plugHashes = GeneratedColumn<String>(
      'plug_hashes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _rollTagsMeta =
      const VerificationMeta('rollTags');
  @override
  late final GeneratedColumn<String> rollTags = GeneratedColumn<String>(
      'roll_tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _statValuesMeta =
      const VerificationMeta('statValues');
  @override
  late final GeneratedColumn<String> statValues = GeneratedColumn<String>(
      'stat_values', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _gearTierMeta =
      const VerificationMeta('gearTier');
  @override
  late final GeneratedColumn<int> gearTier = GeneratedColumn<int>(
      'gear_tier', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _socketPlugsMeta =
      const VerificationMeta('socketPlugs');
  @override
  late final GeneratedColumn<String> socketPlugs = GeneratedColumn<String>(
      'socket_plugs', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<String> syncedAt = GeneratedColumn<String>(
      'synced_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        instanceId,
        itemHash,
        bucket,
        location,
        characterId,
        power,
        isMasterwork,
        isCrafted,
        plugHashes,
        rollTags,
        statValues,
        gearTier,
        socketPlugs,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
          _instanceIdMeta,
          instanceId.isAcceptableOrUnknown(
              data['instance_id']!, _instanceIdMeta));
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('item_hash')) {
      context.handle(_itemHashMeta,
          itemHash.isAcceptableOrUnknown(data['item_hash']!, _itemHashMeta));
    } else if (isInserting) {
      context.missing(_itemHashMeta);
    }
    if (data.containsKey('bucket')) {
      context.handle(_bucketMeta,
          bucket.isAcceptableOrUnknown(data['bucket']!, _bucketMeta));
    } else if (isInserting) {
      context.missing(_bucketMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
          _characterIdMeta,
          characterId.isAcceptableOrUnknown(
              data['character_id']!, _characterIdMeta));
    }
    if (data.containsKey('power')) {
      context.handle(
          _powerMeta, power.isAcceptableOrUnknown(data['power']!, _powerMeta));
    }
    if (data.containsKey('is_masterwork')) {
      context.handle(
          _isMasterworkMeta,
          isMasterwork.isAcceptableOrUnknown(
              data['is_masterwork']!, _isMasterworkMeta));
    }
    if (data.containsKey('is_crafted')) {
      context.handle(_isCraftedMeta,
          isCrafted.isAcceptableOrUnknown(data['is_crafted']!, _isCraftedMeta));
    }
    if (data.containsKey('plug_hashes')) {
      context.handle(
          _plugHashesMeta,
          plugHashes.isAcceptableOrUnknown(
              data['plug_hashes']!, _plugHashesMeta));
    }
    if (data.containsKey('roll_tags')) {
      context.handle(_rollTagsMeta,
          rollTags.isAcceptableOrUnknown(data['roll_tags']!, _rollTagsMeta));
    }
    if (data.containsKey('stat_values')) {
      context.handle(
          _statValuesMeta,
          statValues.isAcceptableOrUnknown(
              data['stat_values']!, _statValuesMeta));
    }
    if (data.containsKey('gear_tier')) {
      context.handle(_gearTierMeta,
          gearTier.isAcceptableOrUnknown(data['gear_tier']!, _gearTierMeta));
    }
    if (data.containsKey('socket_plugs')) {
      context.handle(
          _socketPlugsMeta,
          socketPlugs.isAcceptableOrUnknown(
              data['socket_plugs']!, _socketPlugsMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {userId, instanceId},
      ];
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      instanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instance_id'])!,
      itemHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_hash'])!,
      bucket: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bucket'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location'])!,
      characterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}character_id']),
      power: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}power'])!,
      isMasterwork: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_masterwork'])!,
      isCrafted: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_crafted'])!,
      plugHashes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plug_hashes'])!,
      rollTags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}roll_tags'])!,
      statValues: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stat_values']),
      gearTier: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}gear_tier']),
      socketPlugs: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}socket_plugs']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synced_at'])!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  final int id;
  final int userId;
  final String instanceId;
  final int itemHash;
  final String bucket;
  final String location;
  final String? characterId;
  final int power;
  final int isMasterwork;
  final int isCrafted;
  final String plugHashes;
  final String rollTags;
  final String? statValues;
  final int? gearTier;
  final String? socketPlugs;
  final String syncedAt;
  const InventoryItem(
      {required this.id,
      required this.userId,
      required this.instanceId,
      required this.itemHash,
      required this.bucket,
      required this.location,
      this.characterId,
      required this.power,
      required this.isMasterwork,
      required this.isCrafted,
      required this.plugHashes,
      required this.rollTags,
      this.statValues,
      this.gearTier,
      this.socketPlugs,
      required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['instance_id'] = Variable<String>(instanceId);
    map['item_hash'] = Variable<int>(itemHash);
    map['bucket'] = Variable<String>(bucket);
    map['location'] = Variable<String>(location);
    if (!nullToAbsent || characterId != null) {
      map['character_id'] = Variable<String>(characterId);
    }
    map['power'] = Variable<int>(power);
    map['is_masterwork'] = Variable<int>(isMasterwork);
    map['is_crafted'] = Variable<int>(isCrafted);
    map['plug_hashes'] = Variable<String>(plugHashes);
    map['roll_tags'] = Variable<String>(rollTags);
    if (!nullToAbsent || statValues != null) {
      map['stat_values'] = Variable<String>(statValues);
    }
    if (!nullToAbsent || gearTier != null) {
      map['gear_tier'] = Variable<int>(gearTier);
    }
    if (!nullToAbsent || socketPlugs != null) {
      map['socket_plugs'] = Variable<String>(socketPlugs);
    }
    map['synced_at'] = Variable<String>(syncedAt);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      userId: Value(userId),
      instanceId: Value(instanceId),
      itemHash: Value(itemHash),
      bucket: Value(bucket),
      location: Value(location),
      characterId: characterId == null && nullToAbsent
          ? const Value.absent()
          : Value(characterId),
      power: Value(power),
      isMasterwork: Value(isMasterwork),
      isCrafted: Value(isCrafted),
      plugHashes: Value(plugHashes),
      rollTags: Value(rollTags),
      statValues: statValues == null && nullToAbsent
          ? const Value.absent()
          : Value(statValues),
      gearTier: gearTier == null && nullToAbsent
          ? const Value.absent()
          : Value(gearTier),
      socketPlugs: socketPlugs == null && nullToAbsent
          ? const Value.absent()
          : Value(socketPlugs),
      syncedAt: Value(syncedAt),
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      instanceId: serializer.fromJson<String>(json['instanceId']),
      itemHash: serializer.fromJson<int>(json['itemHash']),
      bucket: serializer.fromJson<String>(json['bucket']),
      location: serializer.fromJson<String>(json['location']),
      characterId: serializer.fromJson<String?>(json['characterId']),
      power: serializer.fromJson<int>(json['power']),
      isMasterwork: serializer.fromJson<int>(json['isMasterwork']),
      isCrafted: serializer.fromJson<int>(json['isCrafted']),
      plugHashes: serializer.fromJson<String>(json['plugHashes']),
      rollTags: serializer.fromJson<String>(json['rollTags']),
      statValues: serializer.fromJson<String?>(json['statValues']),
      gearTier: serializer.fromJson<int?>(json['gearTier']),
      socketPlugs: serializer.fromJson<String?>(json['socketPlugs']),
      syncedAt: serializer.fromJson<String>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'instanceId': serializer.toJson<String>(instanceId),
      'itemHash': serializer.toJson<int>(itemHash),
      'bucket': serializer.toJson<String>(bucket),
      'location': serializer.toJson<String>(location),
      'characterId': serializer.toJson<String?>(characterId),
      'power': serializer.toJson<int>(power),
      'isMasterwork': serializer.toJson<int>(isMasterwork),
      'isCrafted': serializer.toJson<int>(isCrafted),
      'plugHashes': serializer.toJson<String>(plugHashes),
      'rollTags': serializer.toJson<String>(rollTags),
      'statValues': serializer.toJson<String?>(statValues),
      'gearTier': serializer.toJson<int?>(gearTier),
      'socketPlugs': serializer.toJson<String?>(socketPlugs),
      'syncedAt': serializer.toJson<String>(syncedAt),
    };
  }

  InventoryItem copyWith(
          {int? id,
          int? userId,
          String? instanceId,
          int? itemHash,
          String? bucket,
          String? location,
          Value<String?> characterId = const Value.absent(),
          int? power,
          int? isMasterwork,
          int? isCrafted,
          String? plugHashes,
          String? rollTags,
          Value<String?> statValues = const Value.absent(),
          Value<int?> gearTier = const Value.absent(),
          Value<String?> socketPlugs = const Value.absent(),
          String? syncedAt}) =>
      InventoryItem(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        instanceId: instanceId ?? this.instanceId,
        itemHash: itemHash ?? this.itemHash,
        bucket: bucket ?? this.bucket,
        location: location ?? this.location,
        characterId: characterId.present ? characterId.value : this.characterId,
        power: power ?? this.power,
        isMasterwork: isMasterwork ?? this.isMasterwork,
        isCrafted: isCrafted ?? this.isCrafted,
        plugHashes: plugHashes ?? this.plugHashes,
        rollTags: rollTags ?? this.rollTags,
        statValues: statValues.present ? statValues.value : this.statValues,
        gearTier: gearTier.present ? gearTier.value : this.gearTier,
        socketPlugs: socketPlugs.present ? socketPlugs.value : this.socketPlugs,
        syncedAt: syncedAt ?? this.syncedAt,
      );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      instanceId:
          data.instanceId.present ? data.instanceId.value : this.instanceId,
      itemHash: data.itemHash.present ? data.itemHash.value : this.itemHash,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      location: data.location.present ? data.location.value : this.location,
      characterId:
          data.characterId.present ? data.characterId.value : this.characterId,
      power: data.power.present ? data.power.value : this.power,
      isMasterwork: data.isMasterwork.present
          ? data.isMasterwork.value
          : this.isMasterwork,
      isCrafted: data.isCrafted.present ? data.isCrafted.value : this.isCrafted,
      plugHashes:
          data.plugHashes.present ? data.plugHashes.value : this.plugHashes,
      rollTags: data.rollTags.present ? data.rollTags.value : this.rollTags,
      statValues:
          data.statValues.present ? data.statValues.value : this.statValues,
      gearTier: data.gearTier.present ? data.gearTier.value : this.gearTier,
      socketPlugs:
          data.socketPlugs.present ? data.socketPlugs.value : this.socketPlugs,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('instanceId: $instanceId, ')
          ..write('itemHash: $itemHash, ')
          ..write('bucket: $bucket, ')
          ..write('location: $location, ')
          ..write('characterId: $characterId, ')
          ..write('power: $power, ')
          ..write('isMasterwork: $isMasterwork, ')
          ..write('isCrafted: $isCrafted, ')
          ..write('plugHashes: $plugHashes, ')
          ..write('rollTags: $rollTags, ')
          ..write('statValues: $statValues, ')
          ..write('gearTier: $gearTier, ')
          ..write('socketPlugs: $socketPlugs, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      instanceId,
      itemHash,
      bucket,
      location,
      characterId,
      power,
      isMasterwork,
      isCrafted,
      plugHashes,
      rollTags,
      statValues,
      gearTier,
      socketPlugs,
      syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.instanceId == this.instanceId &&
          other.itemHash == this.itemHash &&
          other.bucket == this.bucket &&
          other.location == this.location &&
          other.characterId == this.characterId &&
          other.power == this.power &&
          other.isMasterwork == this.isMasterwork &&
          other.isCrafted == this.isCrafted &&
          other.plugHashes == this.plugHashes &&
          other.rollTags == this.rollTags &&
          other.statValues == this.statValues &&
          other.gearTier == this.gearTier &&
          other.socketPlugs == this.socketPlugs &&
          other.syncedAt == this.syncedAt);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<int> id;
  final Value<int> userId;
  final Value<String> instanceId;
  final Value<int> itemHash;
  final Value<String> bucket;
  final Value<String> location;
  final Value<String?> characterId;
  final Value<int> power;
  final Value<int> isMasterwork;
  final Value<int> isCrafted;
  final Value<String> plugHashes;
  final Value<String> rollTags;
  final Value<String?> statValues;
  final Value<int?> gearTier;
  final Value<String?> socketPlugs;
  final Value<String> syncedAt;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.itemHash = const Value.absent(),
    this.bucket = const Value.absent(),
    this.location = const Value.absent(),
    this.characterId = const Value.absent(),
    this.power = const Value.absent(),
    this.isMasterwork = const Value.absent(),
    this.isCrafted = const Value.absent(),
    this.plugHashes = const Value.absent(),
    this.rollTags = const Value.absent(),
    this.statValues = const Value.absent(),
    this.gearTier = const Value.absent(),
    this.socketPlugs = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required String instanceId,
    required int itemHash,
    required String bucket,
    required String location,
    this.characterId = const Value.absent(),
    this.power = const Value.absent(),
    this.isMasterwork = const Value.absent(),
    this.isCrafted = const Value.absent(),
    this.plugHashes = const Value.absent(),
    this.rollTags = const Value.absent(),
    this.statValues = const Value.absent(),
    this.gearTier = const Value.absent(),
    this.socketPlugs = const Value.absent(),
    required String syncedAt,
  })  : userId = Value(userId),
        instanceId = Value(instanceId),
        itemHash = Value(itemHash),
        bucket = Value(bucket),
        location = Value(location),
        syncedAt = Value(syncedAt);
  static Insertable<InventoryItem> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<String>? instanceId,
    Expression<int>? itemHash,
    Expression<String>? bucket,
    Expression<String>? location,
    Expression<String>? characterId,
    Expression<int>? power,
    Expression<int>? isMasterwork,
    Expression<int>? isCrafted,
    Expression<String>? plugHashes,
    Expression<String>? rollTags,
    Expression<String>? statValues,
    Expression<int>? gearTier,
    Expression<String>? socketPlugs,
    Expression<String>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (instanceId != null) 'instance_id': instanceId,
      if (itemHash != null) 'item_hash': itemHash,
      if (bucket != null) 'bucket': bucket,
      if (location != null) 'location': location,
      if (characterId != null) 'character_id': characterId,
      if (power != null) 'power': power,
      if (isMasterwork != null) 'is_masterwork': isMasterwork,
      if (isCrafted != null) 'is_crafted': isCrafted,
      if (plugHashes != null) 'plug_hashes': plugHashes,
      if (rollTags != null) 'roll_tags': rollTags,
      if (statValues != null) 'stat_values': statValues,
      if (gearTier != null) 'gear_tier': gearTier,
      if (socketPlugs != null) 'socket_plugs': socketPlugs,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  InventoryItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? userId,
      Value<String>? instanceId,
      Value<int>? itemHash,
      Value<String>? bucket,
      Value<String>? location,
      Value<String?>? characterId,
      Value<int>? power,
      Value<int>? isMasterwork,
      Value<int>? isCrafted,
      Value<String>? plugHashes,
      Value<String>? rollTags,
      Value<String?>? statValues,
      Value<int?>? gearTier,
      Value<String?>? socketPlugs,
      Value<String>? syncedAt}) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      instanceId: instanceId ?? this.instanceId,
      itemHash: itemHash ?? this.itemHash,
      bucket: bucket ?? this.bucket,
      location: location ?? this.location,
      characterId: characterId ?? this.characterId,
      power: power ?? this.power,
      isMasterwork: isMasterwork ?? this.isMasterwork,
      isCrafted: isCrafted ?? this.isCrafted,
      plugHashes: plugHashes ?? this.plugHashes,
      rollTags: rollTags ?? this.rollTags,
      statValues: statValues ?? this.statValues,
      gearTier: gearTier ?? this.gearTier,
      socketPlugs: socketPlugs ?? this.socketPlugs,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (itemHash.present) {
      map['item_hash'] = Variable<int>(itemHash.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<String>(bucket.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (power.present) {
      map['power'] = Variable<int>(power.value);
    }
    if (isMasterwork.present) {
      map['is_masterwork'] = Variable<int>(isMasterwork.value);
    }
    if (isCrafted.present) {
      map['is_crafted'] = Variable<int>(isCrafted.value);
    }
    if (plugHashes.present) {
      map['plug_hashes'] = Variable<String>(plugHashes.value);
    }
    if (rollTags.present) {
      map['roll_tags'] = Variable<String>(rollTags.value);
    }
    if (statValues.present) {
      map['stat_values'] = Variable<String>(statValues.value);
    }
    if (gearTier.present) {
      map['gear_tier'] = Variable<int>(gearTier.value);
    }
    if (socketPlugs.present) {
      map['socket_plugs'] = Variable<String>(socketPlugs.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<String>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('instanceId: $instanceId, ')
          ..write('itemHash: $itemHash, ')
          ..write('bucket: $bucket, ')
          ..write('location: $location, ')
          ..write('characterId: $characterId, ')
          ..write('power: $power, ')
          ..write('isMasterwork: $isMasterwork, ')
          ..write('isCrafted: $isCrafted, ')
          ..write('plugHashes: $plugHashes, ')
          ..write('rollTags: $rollTags, ')
          ..write('statValues: $statValues, ')
          ..write('gearTier: $gearTier, ')
          ..write('socketPlugs: $socketPlugs, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $InventorySyncMetaTable extends InventorySyncMeta
    with TableInfo<$InventorySyncMetaTable, InventorySyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventorySyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _itemCountMeta =
      const VerificationMeta('itemCount');
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
      'item_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _syncVersionMeta =
      const VerificationMeta('syncVersion');
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
      'sync_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastFullSyncAtMeta =
      const VerificationMeta('lastFullSyncAt');
  @override
  late final GeneratedColumn<String> lastFullSyncAt = GeneratedColumn<String>(
      'last_full_sync_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [userId, itemCount, syncVersion, lastFullSyncAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_sync_meta';
  @override
  VerificationContext validateIntegrity(
      Insertable<InventorySyncMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('item_count')) {
      context.handle(_itemCountMeta,
          itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta));
    }
    if (data.containsKey('sync_version')) {
      context.handle(
          _syncVersionMeta,
          syncVersion.isAcceptableOrUnknown(
              data['sync_version']!, _syncVersionMeta));
    }
    if (data.containsKey('last_full_sync_at')) {
      context.handle(
          _lastFullSyncAtMeta,
          lastFullSyncAt.isAcceptableOrUnknown(
              data['last_full_sync_at']!, _lastFullSyncAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  InventorySyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventorySyncMetaData(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      itemCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_count'])!,
      syncVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sync_version'])!,
      lastFullSyncAt: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_full_sync_at']),
    );
  }

  @override
  $InventorySyncMetaTable createAlias(String alias) {
    return $InventorySyncMetaTable(attachedDatabase, alias);
  }
}

class InventorySyncMetaData extends DataClass
    implements Insertable<InventorySyncMetaData> {
  final int userId;
  final int itemCount;
  final int syncVersion;
  final String? lastFullSyncAt;
  const InventorySyncMetaData(
      {required this.userId,
      required this.itemCount,
      required this.syncVersion,
      this.lastFullSyncAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['item_count'] = Variable<int>(itemCount);
    map['sync_version'] = Variable<int>(syncVersion);
    if (!nullToAbsent || lastFullSyncAt != null) {
      map['last_full_sync_at'] = Variable<String>(lastFullSyncAt);
    }
    return map;
  }

  InventorySyncMetaCompanion toCompanion(bool nullToAbsent) {
    return InventorySyncMetaCompanion(
      userId: Value(userId),
      itemCount: Value(itemCount),
      syncVersion: Value(syncVersion),
      lastFullSyncAt: lastFullSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFullSyncAt),
    );
  }

  factory InventorySyncMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventorySyncMetaData(
      userId: serializer.fromJson<int>(json['userId']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
      lastFullSyncAt: serializer.fromJson<String?>(json['lastFullSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'itemCount': serializer.toJson<int>(itemCount),
      'syncVersion': serializer.toJson<int>(syncVersion),
      'lastFullSyncAt': serializer.toJson<String?>(lastFullSyncAt),
    };
  }

  InventorySyncMetaData copyWith(
          {int? userId,
          int? itemCount,
          int? syncVersion,
          Value<String?> lastFullSyncAt = const Value.absent()}) =>
      InventorySyncMetaData(
        userId: userId ?? this.userId,
        itemCount: itemCount ?? this.itemCount,
        syncVersion: syncVersion ?? this.syncVersion,
        lastFullSyncAt:
            lastFullSyncAt.present ? lastFullSyncAt.value : this.lastFullSyncAt,
      );
  InventorySyncMetaData copyWithCompanion(InventorySyncMetaCompanion data) {
    return InventorySyncMetaData(
      userId: data.userId.present ? data.userId.value : this.userId,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      syncVersion:
          data.syncVersion.present ? data.syncVersion.value : this.syncVersion,
      lastFullSyncAt: data.lastFullSyncAt.present
          ? data.lastFullSyncAt.value
          : this.lastFullSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventorySyncMetaData(')
          ..write('userId: $userId, ')
          ..write('itemCount: $itemCount, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('lastFullSyncAt: $lastFullSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, itemCount, syncVersion, lastFullSyncAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventorySyncMetaData &&
          other.userId == this.userId &&
          other.itemCount == this.itemCount &&
          other.syncVersion == this.syncVersion &&
          other.lastFullSyncAt == this.lastFullSyncAt);
}

class InventorySyncMetaCompanion
    extends UpdateCompanion<InventorySyncMetaData> {
  final Value<int> userId;
  final Value<int> itemCount;
  final Value<int> syncVersion;
  final Value<String?> lastFullSyncAt;
  const InventorySyncMetaCompanion({
    this.userId = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.lastFullSyncAt = const Value.absent(),
  });
  InventorySyncMetaCompanion.insert({
    this.userId = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.lastFullSyncAt = const Value.absent(),
  });
  static Insertable<InventorySyncMetaData> custom({
    Expression<int>? userId,
    Expression<int>? itemCount,
    Expression<int>? syncVersion,
    Expression<String>? lastFullSyncAt,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (itemCount != null) 'item_count': itemCount,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (lastFullSyncAt != null) 'last_full_sync_at': lastFullSyncAt,
    });
  }

  InventorySyncMetaCompanion copyWith(
      {Value<int>? userId,
      Value<int>? itemCount,
      Value<int>? syncVersion,
      Value<String?>? lastFullSyncAt}) {
    return InventorySyncMetaCompanion(
      userId: userId ?? this.userId,
      itemCount: itemCount ?? this.itemCount,
      syncVersion: syncVersion ?? this.syncVersion,
      lastFullSyncAt: lastFullSyncAt ?? this.lastFullSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (lastFullSyncAt.present) {
      map['last_full_sync_at'] = Variable<String>(lastFullSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventorySyncMetaCompanion(')
          ..write('userId: $userId, ')
          ..write('itemCount: $itemCount, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('lastFullSyncAt: $lastFullSyncAt')
          ..write(')'))
        .toString();
  }
}

class $LoadoutsTable extends Loadouts with TableInfo<$LoadoutsTable, Loadout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoadoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _manifestVersionMeta =
      const VerificationMeta('manifestVersion');
  @override
  late final GeneratedColumn<String> manifestVersion = GeneratedColumn<String>(
      'manifest_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _buildRequestMeta =
      const VerificationMeta('buildRequest');
  @override
  late final GeneratedColumn<String> buildRequest = GeneratedColumn<String>(
      'build_request', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _generatedBuildMeta =
      const VerificationMeta('generatedBuild');
  @override
  late final GeneratedColumn<String> generatedBuild = GeneratedColumn<String>(
      'generated_build', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resolvedSheetMeta =
      const VerificationMeta('resolvedSheet');
  @override
  late final GeneratedColumn<String> resolvedSheet = GeneratedColumn<String>(
      'resolved_sheet', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        source,
        manifestVersion,
        buildRequest,
        generatedBuild,
        resolvedSheet,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loadouts';
  @override
  VerificationContext validateIntegrity(Insertable<Loadout> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('manifest_version')) {
      context.handle(
          _manifestVersionMeta,
          manifestVersion.isAcceptableOrUnknown(
              data['manifest_version']!, _manifestVersionMeta));
    } else if (isInserting) {
      context.missing(_manifestVersionMeta);
    }
    if (data.containsKey('build_request')) {
      context.handle(
          _buildRequestMeta,
          buildRequest.isAcceptableOrUnknown(
              data['build_request']!, _buildRequestMeta));
    }
    if (data.containsKey('generated_build')) {
      context.handle(
          _generatedBuildMeta,
          generatedBuild.isAcceptableOrUnknown(
              data['generated_build']!, _generatedBuildMeta));
    } else if (isInserting) {
      context.missing(_generatedBuildMeta);
    }
    if (data.containsKey('resolved_sheet')) {
      context.handle(
          _resolvedSheetMeta,
          resolvedSheet.isAcceptableOrUnknown(
              data['resolved_sheet']!, _resolvedSheetMeta));
    } else if (isInserting) {
      context.missing(_resolvedSheetMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Loadout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Loadout(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      manifestVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}manifest_version'])!,
      buildRequest: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}build_request']),
      generatedBuild: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}generated_build'])!,
      resolvedSheet: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resolved_sheet'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $LoadoutsTable createAlias(String alias) {
    return $LoadoutsTable(attachedDatabase, alias);
  }
}

class Loadout extends DataClass implements Insertable<Loadout> {
  final String id;
  final int userId;
  final String name;
  final String source;
  final String manifestVersion;
  final String? buildRequest;
  final String generatedBuild;
  final String resolvedSheet;
  final String createdAt;
  final String updatedAt;
  const Loadout(
      {required this.id,
      required this.userId,
      required this.name,
      required this.source,
      required this.manifestVersion,
      this.buildRequest,
      required this.generatedBuild,
      required this.resolvedSheet,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    map['name'] = Variable<String>(name);
    map['source'] = Variable<String>(source);
    map['manifest_version'] = Variable<String>(manifestVersion);
    if (!nullToAbsent || buildRequest != null) {
      map['build_request'] = Variable<String>(buildRequest);
    }
    map['generated_build'] = Variable<String>(generatedBuild);
    map['resolved_sheet'] = Variable<String>(resolvedSheet);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LoadoutsCompanion toCompanion(bool nullToAbsent) {
    return LoadoutsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      source: Value(source),
      manifestVersion: Value(manifestVersion),
      buildRequest: buildRequest == null && nullToAbsent
          ? const Value.absent()
          : Value(buildRequest),
      generatedBuild: Value(generatedBuild),
      resolvedSheet: Value(resolvedSheet),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Loadout.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Loadout(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      source: serializer.fromJson<String>(json['source']),
      manifestVersion: serializer.fromJson<String>(json['manifestVersion']),
      buildRequest: serializer.fromJson<String?>(json['buildRequest']),
      generatedBuild: serializer.fromJson<String>(json['generatedBuild']),
      resolvedSheet: serializer.fromJson<String>(json['resolvedSheet']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'name': serializer.toJson<String>(name),
      'source': serializer.toJson<String>(source),
      'manifestVersion': serializer.toJson<String>(manifestVersion),
      'buildRequest': serializer.toJson<String?>(buildRequest),
      'generatedBuild': serializer.toJson<String>(generatedBuild),
      'resolvedSheet': serializer.toJson<String>(resolvedSheet),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Loadout copyWith(
          {String? id,
          int? userId,
          String? name,
          String? source,
          String? manifestVersion,
          Value<String?> buildRequest = const Value.absent(),
          String? generatedBuild,
          String? resolvedSheet,
          String? createdAt,
          String? updatedAt}) =>
      Loadout(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        source: source ?? this.source,
        manifestVersion: manifestVersion ?? this.manifestVersion,
        buildRequest:
            buildRequest.present ? buildRequest.value : this.buildRequest,
        generatedBuild: generatedBuild ?? this.generatedBuild,
        resolvedSheet: resolvedSheet ?? this.resolvedSheet,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Loadout copyWithCompanion(LoadoutsCompanion data) {
    return Loadout(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      source: data.source.present ? data.source.value : this.source,
      manifestVersion: data.manifestVersion.present
          ? data.manifestVersion.value
          : this.manifestVersion,
      buildRequest: data.buildRequest.present
          ? data.buildRequest.value
          : this.buildRequest,
      generatedBuild: data.generatedBuild.present
          ? data.generatedBuild.value
          : this.generatedBuild,
      resolvedSheet: data.resolvedSheet.present
          ? data.resolvedSheet.value
          : this.resolvedSheet,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loadout(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('manifestVersion: $manifestVersion, ')
          ..write('buildRequest: $buildRequest, ')
          ..write('generatedBuild: $generatedBuild, ')
          ..write('resolvedSheet: $resolvedSheet, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, source, manifestVersion,
      buildRequest, generatedBuild, resolvedSheet, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loadout &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.source == this.source &&
          other.manifestVersion == this.manifestVersion &&
          other.buildRequest == this.buildRequest &&
          other.generatedBuild == this.generatedBuild &&
          other.resolvedSheet == this.resolvedSheet &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LoadoutsCompanion extends UpdateCompanion<Loadout> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String> name;
  final Value<String> source;
  final Value<String> manifestVersion;
  final Value<String?> buildRequest;
  final Value<String> generatedBuild;
  final Value<String> resolvedSheet;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LoadoutsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.source = const Value.absent(),
    this.manifestVersion = const Value.absent(),
    this.buildRequest = const Value.absent(),
    this.generatedBuild = const Value.absent(),
    this.resolvedSheet = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoadoutsCompanion.insert({
    required String id,
    required int userId,
    required String name,
    required String source,
    required String manifestVersion,
    this.buildRequest = const Value.absent(),
    required String generatedBuild,
    required String resolvedSheet,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        source = Value(source),
        manifestVersion = Value(manifestVersion),
        generatedBuild = Value(generatedBuild),
        resolvedSheet = Value(resolvedSheet),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Loadout> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? name,
    Expression<String>? source,
    Expression<String>? manifestVersion,
    Expression<String>? buildRequest,
    Expression<String>? generatedBuild,
    Expression<String>? resolvedSheet,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (source != null) 'source': source,
      if (manifestVersion != null) 'manifest_version': manifestVersion,
      if (buildRequest != null) 'build_request': buildRequest,
      if (generatedBuild != null) 'generated_build': generatedBuild,
      if (resolvedSheet != null) 'resolved_sheet': resolvedSheet,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoadoutsCompanion copyWith(
      {Value<String>? id,
      Value<int>? userId,
      Value<String>? name,
      Value<String>? source,
      Value<String>? manifestVersion,
      Value<String?>? buildRequest,
      Value<String>? generatedBuild,
      Value<String>? resolvedSheet,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return LoadoutsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      source: source ?? this.source,
      manifestVersion: manifestVersion ?? this.manifestVersion,
      buildRequest: buildRequest ?? this.buildRequest,
      generatedBuild: generatedBuild ?? this.generatedBuild,
      resolvedSheet: resolvedSheet ?? this.resolvedSheet,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (manifestVersion.present) {
      map['manifest_version'] = Variable<String>(manifestVersion.value);
    }
    if (buildRequest.present) {
      map['build_request'] = Variable<String>(buildRequest.value);
    }
    if (generatedBuild.present) {
      map['generated_build'] = Variable<String>(generatedBuild.value);
    }
    if (resolvedSheet.present) {
      map['resolved_sheet'] = Variable<String>(resolvedSheet.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoadoutsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('source: $source, ')
          ..write('manifestVersion: $manifestVersion, ')
          ..write('buildRequest: $buildRequest, ')
          ..write('generatedBuild: $generatedBuild, ')
          ..write('resolvedSheet: $resolvedSheet, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetsTable extends Sets with TableInfo<$SetsTable, LibrarySet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _optimizerConstraintsMeta =
      const VerificationMeta('optimizerConstraints');
  @override
  late final GeneratedColumn<String> optimizerConstraints =
      GeneratedColumn<String>('optimizer_constraints', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkedModSetIdMeta =
      const VerificationMeta('linkedModSetId');
  @override
  late final GeneratedColumn<String> linkedModSetId = GeneratedColumn<String>(
      'linked_mod_set_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        type,
        optimizerConstraints,
        linkedModSetId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sets';
  @override
  VerificationContext validateIntegrity(Insertable<LibrarySet> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('optimizer_constraints')) {
      context.handle(
          _optimizerConstraintsMeta,
          optimizerConstraints.isAcceptableOrUnknown(
              data['optimizer_constraints']!, _optimizerConstraintsMeta));
    }
    if (data.containsKey('linked_mod_set_id')) {
      context.handle(
          _linkedModSetIdMeta,
          linkedModSetId.isAcceptableOrUnknown(
              data['linked_mod_set_id']!, _linkedModSetIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LibrarySet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibrarySet(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      optimizerConstraints: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}optimizer_constraints']),
      linkedModSetId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}linked_mod_set_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SetsTable createAlias(String alias) {
    return $SetsTable(attachedDatabase, alias);
  }
}

class LibrarySet extends DataClass implements Insertable<LibrarySet> {
  final String id;
  final int userId;
  final String name;
  final String type;
  final String? optimizerConstraints;
  final String? linkedModSetId;
  final String createdAt;
  final String updatedAt;
  const LibrarySet(
      {required this.id,
      required this.userId,
      required this.name,
      required this.type,
      this.optimizerConstraints,
      this.linkedModSetId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || optimizerConstraints != null) {
      map['optimizer_constraints'] = Variable<String>(optimizerConstraints);
    }
    if (!nullToAbsent || linkedModSetId != null) {
      map['linked_mod_set_id'] = Variable<String>(linkedModSetId);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SetsCompanion toCompanion(bool nullToAbsent) {
    return SetsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      optimizerConstraints: optimizerConstraints == null && nullToAbsent
          ? const Value.absent()
          : Value(optimizerConstraints),
      linkedModSetId: linkedModSetId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedModSetId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LibrarySet.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibrarySet(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      optimizerConstraints:
          serializer.fromJson<String?>(json['optimizerConstraints']),
      linkedModSetId: serializer.fromJson<String?>(json['linkedModSetId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'optimizerConstraints': serializer.toJson<String?>(optimizerConstraints),
      'linkedModSetId': serializer.toJson<String?>(linkedModSetId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LibrarySet copyWith(
          {String? id,
          int? userId,
          String? name,
          String? type,
          Value<String?> optimizerConstraints = const Value.absent(),
          Value<String?> linkedModSetId = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      LibrarySet(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        optimizerConstraints: optimizerConstraints.present
            ? optimizerConstraints.value
            : this.optimizerConstraints,
        linkedModSetId:
            linkedModSetId.present ? linkedModSetId.value : this.linkedModSetId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LibrarySet copyWithCompanion(SetsCompanion data) {
    return LibrarySet(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      optimizerConstraints: data.optimizerConstraints.present
          ? data.optimizerConstraints.value
          : this.optimizerConstraints,
      linkedModSetId: data.linkedModSetId.present
          ? data.linkedModSetId.value
          : this.linkedModSetId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibrarySet(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('optimizerConstraints: $optimizerConstraints, ')
          ..write('linkedModSetId: $linkedModSetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, type, optimizerConstraints,
      linkedModSetId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibrarySet &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.optimizerConstraints == this.optimizerConstraints &&
          other.linkedModSetId == this.linkedModSetId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SetsCompanion extends UpdateCompanion<LibrarySet> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> optimizerConstraints;
  final Value<String?> linkedModSetId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SetsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.optimizerConstraints = const Value.absent(),
    this.linkedModSetId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetsCompanion.insert({
    required String id,
    required int userId,
    required String name,
    required String type,
    this.optimizerConstraints = const Value.absent(),
    this.linkedModSetId = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LibrarySet> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? optimizerConstraints,
    Expression<String>? linkedModSetId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (optimizerConstraints != null)
        'optimizer_constraints': optimizerConstraints,
      if (linkedModSetId != null) 'linked_mod_set_id': linkedModSetId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetsCompanion copyWith(
      {Value<String>? id,
      Value<int>? userId,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? optimizerConstraints,
      Value<String?>? linkedModSetId,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return SetsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      optimizerConstraints: optimizerConstraints ?? this.optimizerConstraints,
      linkedModSetId: linkedModSetId ?? this.linkedModSetId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (optimizerConstraints.present) {
      map['optimizer_constraints'] =
          Variable<String>(optimizerConstraints.value);
    }
    if (linkedModSetId.present) {
      map['linked_mod_set_id'] = Variable<String>(linkedModSetId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('optimizerConstraints: $optimizerConstraints, ')
          ..write('linkedModSetId: $linkedModSetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetTagsTable extends SetTags with TableInfo<$SetTagsTable, SetTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
      'set_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [setId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_tags';
  @override
  VerificationContext validateIntegrity(Insertable<SetTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('set_id')) {
      context.handle(
          _setIdMeta, setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta));
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {setId, tagId},
      ];
  @override
  SetTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetTag(
      setId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $SetTagsTable createAlias(String alias) {
    return $SetTagsTable(attachedDatabase, alias);
  }
}

class SetTag extends DataClass implements Insertable<SetTag> {
  final String setId;
  final String tagId;
  const SetTag({required this.setId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['set_id'] = Variable<String>(setId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  SetTagsCompanion toCompanion(bool nullToAbsent) {
    return SetTagsCompanion(
      setId: Value(setId),
      tagId: Value(tagId),
    );
  }

  factory SetTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetTag(
      setId: serializer.fromJson<String>(json['setId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setId': serializer.toJson<String>(setId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  SetTag copyWith({String? setId, String? tagId}) => SetTag(
        setId: setId ?? this.setId,
        tagId: tagId ?? this.tagId,
      );
  SetTag copyWithCompanion(SetTagsCompanion data) {
    return SetTag(
      setId: data.setId.present ? data.setId.value : this.setId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetTag(')
          ..write('setId: $setId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(setId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetTag &&
          other.setId == this.setId &&
          other.tagId == this.tagId);
}

class SetTagsCompanion extends UpdateCompanion<SetTag> {
  final Value<String> setId;
  final Value<String> tagId;
  final Value<int> rowid;
  const SetTagsCompanion({
    this.setId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetTagsCompanion.insert({
    required String setId,
    required String tagId,
    this.rowid = const Value.absent(),
  })  : setId = Value(setId),
        tagId = Value(tagId);
  static Insertable<SetTag> custom({
    Expression<String>? setId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (setId != null) 'set_id': setId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetTagsCompanion copyWith(
      {Value<String>? setId, Value<String>? tagId, Value<int>? rowid}) {
    return SetTagsCompanion(
      setId: setId ?? this.setId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (setId.present) {
      map['set_id'] = Variable<String>(setId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetTagsCompanion(')
          ..write('setId: $setId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetItemsTable extends SetItems with TableInfo<$SetItemsTable, SetItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
      'set_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
      'slot', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemHashMeta =
      const VerificationMeta('itemHash');
  @override
  late final GeneratedColumn<int> itemHash = GeneratedColumn<int>(
      'item_hash', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _itemNameMeta =
      const VerificationMeta('itemName');
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
      'item_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _selectedPerksMeta =
      const VerificationMeta('selectedPerks');
  @override
  late final GeneratedColumn<String> selectedPerks = GeneratedColumn<String>(
      'selected_perks', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _masterworkHashMeta =
      const VerificationMeta('masterworkHash');
  @override
  late final GeneratedColumn<int> masterworkHash = GeneratedColumn<int>(
      'masterwork_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _modHashesMeta =
      const VerificationMeta('modHashes');
  @override
  late final GeneratedColumn<String> modHashes = GeneratedColumn<String>(
      'mod_hashes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _instanceIdMeta =
      const VerificationMeta('instanceId');
  @override
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
      'instance_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _removedAtMeta =
      const VerificationMeta('removedAt');
  @override
  late final GeneratedColumn<String> removedAt = GeneratedColumn<String>(
      'removed_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        setId,
        slot,
        itemHash,
        itemName,
        selectedPerks,
        masterworkHash,
        modHashes,
        instanceId,
        sortOrder,
        removedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_items';
  @override
  VerificationContext validateIntegrity(Insertable<SetItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('set_id')) {
      context.handle(
          _setIdMeta, setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta));
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
          _slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('item_hash')) {
      context.handle(_itemHashMeta,
          itemHash.isAcceptableOrUnknown(data['item_hash']!, _itemHashMeta));
    } else if (isInserting) {
      context.missing(_itemHashMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(_itemNameMeta,
          itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta));
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('selected_perks')) {
      context.handle(
          _selectedPerksMeta,
          selectedPerks.isAcceptableOrUnknown(
              data['selected_perks']!, _selectedPerksMeta));
    }
    if (data.containsKey('masterwork_hash')) {
      context.handle(
          _masterworkHashMeta,
          masterworkHash.isAcceptableOrUnknown(
              data['masterwork_hash']!, _masterworkHashMeta));
    }
    if (data.containsKey('mod_hashes')) {
      context.handle(_modHashesMeta,
          modHashes.isAcceptableOrUnknown(data['mod_hashes']!, _modHashesMeta));
    }
    if (data.containsKey('instance_id')) {
      context.handle(
          _instanceIdMeta,
          instanceId.isAcceptableOrUnknown(
              data['instance_id']!, _instanceIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('removed_at')) {
      context.handle(_removedAtMeta,
          removedAt.isAcceptableOrUnknown(data['removed_at']!, _removedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      setId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_id'])!,
      slot: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot'])!,
      itemHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_hash'])!,
      itemName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_name'])!,
      selectedPerks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}selected_perks'])!,
      masterworkHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}masterwork_hash']),
      modHashes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mod_hashes']),
      instanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instance_id']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      removedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}removed_at']),
    );
  }

  @override
  $SetItemsTable createAlias(String alias) {
    return $SetItemsTable(attachedDatabase, alias);
  }
}

class SetItem extends DataClass implements Insertable<SetItem> {
  final String id;
  final String setId;
  final String slot;
  final int itemHash;
  final String itemName;
  final String selectedPerks;
  final int? masterworkHash;
  final String? modHashes;
  final String? instanceId;
  final int sortOrder;
  final String? removedAt;
  const SetItem(
      {required this.id,
      required this.setId,
      required this.slot,
      required this.itemHash,
      required this.itemName,
      required this.selectedPerks,
      this.masterworkHash,
      this.modHashes,
      this.instanceId,
      required this.sortOrder,
      this.removedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['set_id'] = Variable<String>(setId);
    map['slot'] = Variable<String>(slot);
    map['item_hash'] = Variable<int>(itemHash);
    map['item_name'] = Variable<String>(itemName);
    map['selected_perks'] = Variable<String>(selectedPerks);
    if (!nullToAbsent || masterworkHash != null) {
      map['masterwork_hash'] = Variable<int>(masterworkHash);
    }
    if (!nullToAbsent || modHashes != null) {
      map['mod_hashes'] = Variable<String>(modHashes);
    }
    if (!nullToAbsent || instanceId != null) {
      map['instance_id'] = Variable<String>(instanceId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || removedAt != null) {
      map['removed_at'] = Variable<String>(removedAt);
    }
    return map;
  }

  SetItemsCompanion toCompanion(bool nullToAbsent) {
    return SetItemsCompanion(
      id: Value(id),
      setId: Value(setId),
      slot: Value(slot),
      itemHash: Value(itemHash),
      itemName: Value(itemName),
      selectedPerks: Value(selectedPerks),
      masterworkHash: masterworkHash == null && nullToAbsent
          ? const Value.absent()
          : Value(masterworkHash),
      modHashes: modHashes == null && nullToAbsent
          ? const Value.absent()
          : Value(modHashes),
      instanceId: instanceId == null && nullToAbsent
          ? const Value.absent()
          : Value(instanceId),
      sortOrder: Value(sortOrder),
      removedAt: removedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(removedAt),
    );
  }

  factory SetItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetItem(
      id: serializer.fromJson<String>(json['id']),
      setId: serializer.fromJson<String>(json['setId']),
      slot: serializer.fromJson<String>(json['slot']),
      itemHash: serializer.fromJson<int>(json['itemHash']),
      itemName: serializer.fromJson<String>(json['itemName']),
      selectedPerks: serializer.fromJson<String>(json['selectedPerks']),
      masterworkHash: serializer.fromJson<int?>(json['masterworkHash']),
      modHashes: serializer.fromJson<String?>(json['modHashes']),
      instanceId: serializer.fromJson<String?>(json['instanceId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      removedAt: serializer.fromJson<String?>(json['removedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setId': serializer.toJson<String>(setId),
      'slot': serializer.toJson<String>(slot),
      'itemHash': serializer.toJson<int>(itemHash),
      'itemName': serializer.toJson<String>(itemName),
      'selectedPerks': serializer.toJson<String>(selectedPerks),
      'masterworkHash': serializer.toJson<int?>(masterworkHash),
      'modHashes': serializer.toJson<String?>(modHashes),
      'instanceId': serializer.toJson<String?>(instanceId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'removedAt': serializer.toJson<String?>(removedAt),
    };
  }

  SetItem copyWith(
          {String? id,
          String? setId,
          String? slot,
          int? itemHash,
          String? itemName,
          String? selectedPerks,
          Value<int?> masterworkHash = const Value.absent(),
          Value<String?> modHashes = const Value.absent(),
          Value<String?> instanceId = const Value.absent(),
          int? sortOrder,
          Value<String?> removedAt = const Value.absent()}) =>
      SetItem(
        id: id ?? this.id,
        setId: setId ?? this.setId,
        slot: slot ?? this.slot,
        itemHash: itemHash ?? this.itemHash,
        itemName: itemName ?? this.itemName,
        selectedPerks: selectedPerks ?? this.selectedPerks,
        masterworkHash:
            masterworkHash.present ? masterworkHash.value : this.masterworkHash,
        modHashes: modHashes.present ? modHashes.value : this.modHashes,
        instanceId: instanceId.present ? instanceId.value : this.instanceId,
        sortOrder: sortOrder ?? this.sortOrder,
        removedAt: removedAt.present ? removedAt.value : this.removedAt,
      );
  SetItem copyWithCompanion(SetItemsCompanion data) {
    return SetItem(
      id: data.id.present ? data.id.value : this.id,
      setId: data.setId.present ? data.setId.value : this.setId,
      slot: data.slot.present ? data.slot.value : this.slot,
      itemHash: data.itemHash.present ? data.itemHash.value : this.itemHash,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      selectedPerks: data.selectedPerks.present
          ? data.selectedPerks.value
          : this.selectedPerks,
      masterworkHash: data.masterworkHash.present
          ? data.masterworkHash.value
          : this.masterworkHash,
      modHashes: data.modHashes.present ? data.modHashes.value : this.modHashes,
      instanceId:
          data.instanceId.present ? data.instanceId.value : this.instanceId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      removedAt: data.removedAt.present ? data.removedAt.value : this.removedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetItem(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('slot: $slot, ')
          ..write('itemHash: $itemHash, ')
          ..write('itemName: $itemName, ')
          ..write('selectedPerks: $selectedPerks, ')
          ..write('masterworkHash: $masterworkHash, ')
          ..write('modHashes: $modHashes, ')
          ..write('instanceId: $instanceId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('removedAt: $removedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      setId,
      slot,
      itemHash,
      itemName,
      selectedPerks,
      masterworkHash,
      modHashes,
      instanceId,
      sortOrder,
      removedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetItem &&
          other.id == this.id &&
          other.setId == this.setId &&
          other.slot == this.slot &&
          other.itemHash == this.itemHash &&
          other.itemName == this.itemName &&
          other.selectedPerks == this.selectedPerks &&
          other.masterworkHash == this.masterworkHash &&
          other.modHashes == this.modHashes &&
          other.instanceId == this.instanceId &&
          other.sortOrder == this.sortOrder &&
          other.removedAt == this.removedAt);
}

class SetItemsCompanion extends UpdateCompanion<SetItem> {
  final Value<String> id;
  final Value<String> setId;
  final Value<String> slot;
  final Value<int> itemHash;
  final Value<String> itemName;
  final Value<String> selectedPerks;
  final Value<int?> masterworkHash;
  final Value<String?> modHashes;
  final Value<String?> instanceId;
  final Value<int> sortOrder;
  final Value<String?> removedAt;
  final Value<int> rowid;
  const SetItemsCompanion({
    this.id = const Value.absent(),
    this.setId = const Value.absent(),
    this.slot = const Value.absent(),
    this.itemHash = const Value.absent(),
    this.itemName = const Value.absent(),
    this.selectedPerks = const Value.absent(),
    this.masterworkHash = const Value.absent(),
    this.modHashes = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetItemsCompanion.insert({
    required String id,
    required String setId,
    required String slot,
    required int itemHash,
    required String itemName,
    this.selectedPerks = const Value.absent(),
    this.masterworkHash = const Value.absent(),
    this.modHashes = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        setId = Value(setId),
        slot = Value(slot),
        itemHash = Value(itemHash),
        itemName = Value(itemName);
  static Insertable<SetItem> custom({
    Expression<String>? id,
    Expression<String>? setId,
    Expression<String>? slot,
    Expression<int>? itemHash,
    Expression<String>? itemName,
    Expression<String>? selectedPerks,
    Expression<int>? masterworkHash,
    Expression<String>? modHashes,
    Expression<String>? instanceId,
    Expression<int>? sortOrder,
    Expression<String>? removedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setId != null) 'set_id': setId,
      if (slot != null) 'slot': slot,
      if (itemHash != null) 'item_hash': itemHash,
      if (itemName != null) 'item_name': itemName,
      if (selectedPerks != null) 'selected_perks': selectedPerks,
      if (masterworkHash != null) 'masterwork_hash': masterworkHash,
      if (modHashes != null) 'mod_hashes': modHashes,
      if (instanceId != null) 'instance_id': instanceId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (removedAt != null) 'removed_at': removedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? setId,
      Value<String>? slot,
      Value<int>? itemHash,
      Value<String>? itemName,
      Value<String>? selectedPerks,
      Value<int?>? masterworkHash,
      Value<String?>? modHashes,
      Value<String?>? instanceId,
      Value<int>? sortOrder,
      Value<String?>? removedAt,
      Value<int>? rowid}) {
    return SetItemsCompanion(
      id: id ?? this.id,
      setId: setId ?? this.setId,
      slot: slot ?? this.slot,
      itemHash: itemHash ?? this.itemHash,
      itemName: itemName ?? this.itemName,
      selectedPerks: selectedPerks ?? this.selectedPerks,
      masterworkHash: masterworkHash ?? this.masterworkHash,
      modHashes: modHashes ?? this.modHashes,
      instanceId: instanceId ?? this.instanceId,
      sortOrder: sortOrder ?? this.sortOrder,
      removedAt: removedAt ?? this.removedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (setId.present) {
      map['set_id'] = Variable<String>(setId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (itemHash.present) {
      map['item_hash'] = Variable<int>(itemHash.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (selectedPerks.present) {
      map['selected_perks'] = Variable<String>(selectedPerks.value);
    }
    if (masterworkHash.present) {
      map['masterwork_hash'] = Variable<int>(masterworkHash.value);
    }
    if (modHashes.present) {
      map['mod_hashes'] = Variable<String>(modHashes.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (removedAt.present) {
      map['removed_at'] = Variable<String>(removedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetItemsCompanion(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('slot: $slot, ')
          ..write('itemHash: $itemHash, ')
          ..write('itemName: $itemName, ')
          ..write('selectedPerks: $selectedPerks, ')
          ..write('masterworkHash: $masterworkHash, ')
          ..write('modHashes: $modHashes, ')
          ..write('instanceId: $instanceId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('removedAt: $removedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SynergiesTable extends Synergies
    with TableInfo<$SynergiesTable, Synergy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SynergiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subTypeMeta =
      const VerificationMeta('subType');
  @override
  late final GeneratedColumn<String> subType = GeneratedColumn<String>(
      'sub_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, name, type, subType, description, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synergies';
  @override
  VerificationContext validateIntegrity(Insertable<Synergy> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('sub_type')) {
      context.handle(_subTypeMeta,
          subType.isAcceptableOrUnknown(data['sub_type']!, _subTypeMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Synergy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Synergy(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      subType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sub_type']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SynergiesTable createAlias(String alias) {
    return $SynergiesTable(attachedDatabase, alias);
  }
}

class Synergy extends DataClass implements Insertable<Synergy> {
  final String id;
  final int userId;
  final String name;
  final String type;
  final String? subType;
  final String description;
  final String createdAt;
  final String updatedAt;
  const Synergy(
      {required this.id,
      required this.userId,
      required this.name,
      required this.type,
      this.subType,
      required this.description,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || subType != null) {
      map['sub_type'] = Variable<String>(subType);
    }
    map['description'] = Variable<String>(description);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SynergiesCompanion toCompanion(bool nullToAbsent) {
    return SynergiesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      type: Value(type),
      subType: subType == null && nullToAbsent
          ? const Value.absent()
          : Value(subType),
      description: Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Synergy.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Synergy(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      subType: serializer.fromJson<String?>(json['subType']),
      description: serializer.fromJson<String>(json['description']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'subType': serializer.toJson<String?>(subType),
      'description': serializer.toJson<String>(description),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Synergy copyWith(
          {String? id,
          int? userId,
          String? name,
          String? type,
          Value<String?> subType = const Value.absent(),
          String? description,
          String? createdAt,
          String? updatedAt}) =>
      Synergy(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        type: type ?? this.type,
        subType: subType.present ? subType.value : this.subType,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Synergy copyWithCompanion(SynergiesCompanion data) {
    return Synergy(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      subType: data.subType.present ? data.subType.value : this.subType,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Synergy(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('subType: $subType, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, name, type, subType, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Synergy &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.type == this.type &&
          other.subType == this.subType &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SynergiesCompanion extends UpdateCompanion<Synergy> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> subType;
  final Value<String> description;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SynergiesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.subType = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SynergiesCompanion.insert({
    required String id,
    required int userId,
    required String name,
    required String type,
    this.subType = const Value.absent(),
    this.description = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Synergy> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? subType,
    Expression<String>? description,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (subType != null) 'sub_type': subType,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SynergiesCompanion copyWith(
      {Value<String>? id,
      Value<int>? userId,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? subType,
      Value<String>? description,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return SynergiesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subType.present) {
      map['sub_type'] = Variable<String>(subType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SynergiesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('subType: $subType, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SynergyLinksTable extends SynergyLinks
    with TableInfo<$SynergyLinksTable, SynergyLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SynergyLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _synergyIdMeta =
      const VerificationMeta('synergyId');
  @override
  late final GeneratedColumn<String> synergyId = GeneratedColumn<String>(
      'synergy_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemHashMeta =
      const VerificationMeta('itemHash');
  @override
  late final GeneratedColumn<int> itemHash = GeneratedColumn<int>(
      'item_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _perkHashMeta =
      const VerificationMeta('perkHash');
  @override
  late final GeneratedColumn<int> perkHash = GeneratedColumn<int>(
      'perk_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _parentItemHashMeta =
      const VerificationMeta('parentItemHash');
  @override
  late final GeneratedColumn<int> parentItemHash = GeneratedColumn<int>(
      'parent_item_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _originTraitNameMeta =
      const VerificationMeta('originTraitName');
  @override
  late final GeneratedColumn<String> originTraitName = GeneratedColumn<String>(
      'origin_trait_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originTraitHashMeta =
      const VerificationMeta('originTraitHash');
  @override
  late final GeneratedColumn<int> originTraitHash = GeneratedColumn<int>(
      'origin_trait_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _armorSetNameMeta =
      const VerificationMeta('armorSetName');
  @override
  late final GeneratedColumn<String> armorSetName = GeneratedColumn<String>(
      'armor_set_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _bonusPiecesMeta =
      const VerificationMeta('bonusPieces');
  @override
  late final GeneratedColumn<int> bonusPieces = GeneratedColumn<int>(
      'bonus_pieces', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bonusNameMeta =
      const VerificationMeta('bonusName');
  @override
  late final GeneratedColumn<String> bonusName = GeneratedColumn<String>(
      'bonus_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _armorSetHashMeta =
      const VerificationMeta('armorSetHash');
  @override
  late final GeneratedColumn<int> armorSetHash = GeneratedColumn<int>(
      'armor_set_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _requiredMeta =
      const VerificationMeta('required');
  @override
  late final GeneratedColumn<int> required = GeneratedColumn<int>(
      'required', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        synergyId,
        kind,
        displayName,
        itemHash,
        perkHash,
        parentItemHash,
        originTraitName,
        originTraitHash,
        armorSetName,
        bonusPieces,
        bonusName,
        armorSetHash,
        required
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synergy_links';
  @override
  VerificationContext validateIntegrity(Insertable<SynergyLink> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('synergy_id')) {
      context.handle(_synergyIdMeta,
          synergyId.isAcceptableOrUnknown(data['synergy_id']!, _synergyIdMeta));
    } else if (isInserting) {
      context.missing(_synergyIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('item_hash')) {
      context.handle(_itemHashMeta,
          itemHash.isAcceptableOrUnknown(data['item_hash']!, _itemHashMeta));
    }
    if (data.containsKey('perk_hash')) {
      context.handle(_perkHashMeta,
          perkHash.isAcceptableOrUnknown(data['perk_hash']!, _perkHashMeta));
    }
    if (data.containsKey('parent_item_hash')) {
      context.handle(
          _parentItemHashMeta,
          parentItemHash.isAcceptableOrUnknown(
              data['parent_item_hash']!, _parentItemHashMeta));
    }
    if (data.containsKey('origin_trait_name')) {
      context.handle(
          _originTraitNameMeta,
          originTraitName.isAcceptableOrUnknown(
              data['origin_trait_name']!, _originTraitNameMeta));
    }
    if (data.containsKey('origin_trait_hash')) {
      context.handle(
          _originTraitHashMeta,
          originTraitHash.isAcceptableOrUnknown(
              data['origin_trait_hash']!, _originTraitHashMeta));
    }
    if (data.containsKey('armor_set_name')) {
      context.handle(
          _armorSetNameMeta,
          armorSetName.isAcceptableOrUnknown(
              data['armor_set_name']!, _armorSetNameMeta));
    }
    if (data.containsKey('bonus_pieces')) {
      context.handle(
          _bonusPiecesMeta,
          bonusPieces.isAcceptableOrUnknown(
              data['bonus_pieces']!, _bonusPiecesMeta));
    }
    if (data.containsKey('bonus_name')) {
      context.handle(_bonusNameMeta,
          bonusName.isAcceptableOrUnknown(data['bonus_name']!, _bonusNameMeta));
    }
    if (data.containsKey('armor_set_hash')) {
      context.handle(
          _armorSetHashMeta,
          armorSetHash.isAcceptableOrUnknown(
              data['armor_set_hash']!, _armorSetHashMeta));
    }
    if (data.containsKey('required')) {
      context.handle(_requiredMeta,
          required.isAcceptableOrUnknown(data['required']!, _requiredMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SynergyLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SynergyLink(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      synergyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}synergy_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      itemHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_hash']),
      perkHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}perk_hash']),
      parentItemHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_item_hash']),
      originTraitName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}origin_trait_name']),
      originTraitHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}origin_trait_hash']),
      armorSetName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}armor_set_name']),
      bonusPieces: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bonus_pieces']),
      bonusName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bonus_name']),
      armorSetHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}armor_set_hash']),
      required: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}required'])!,
    );
  }

  @override
  $SynergyLinksTable createAlias(String alias) {
    return $SynergyLinksTable(attachedDatabase, alias);
  }
}

class SynergyLink extends DataClass implements Insertable<SynergyLink> {
  final String id;
  final String synergyId;
  final String kind;
  final String displayName;
  final int? itemHash;
  final int? perkHash;
  final int? parentItemHash;
  final String? originTraitName;
  final int? originTraitHash;
  final String? armorSetName;
  final int? bonusPieces;
  final String? bonusName;
  final int? armorSetHash;

  /// 1 = required evidence link (default hard gate); 0 = soft evidence only.
  final int required;
  const SynergyLink(
      {required this.id,
      required this.synergyId,
      required this.kind,
      required this.displayName,
      this.itemHash,
      this.perkHash,
      this.parentItemHash,
      this.originTraitName,
      this.originTraitHash,
      this.armorSetName,
      this.bonusPieces,
      this.bonusName,
      this.armorSetHash,
      required this.required});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['synergy_id'] = Variable<String>(synergyId);
    map['kind'] = Variable<String>(kind);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || itemHash != null) {
      map['item_hash'] = Variable<int>(itemHash);
    }
    if (!nullToAbsent || perkHash != null) {
      map['perk_hash'] = Variable<int>(perkHash);
    }
    if (!nullToAbsent || parentItemHash != null) {
      map['parent_item_hash'] = Variable<int>(parentItemHash);
    }
    if (!nullToAbsent || originTraitName != null) {
      map['origin_trait_name'] = Variable<String>(originTraitName);
    }
    if (!nullToAbsent || originTraitHash != null) {
      map['origin_trait_hash'] = Variable<int>(originTraitHash);
    }
    if (!nullToAbsent || armorSetName != null) {
      map['armor_set_name'] = Variable<String>(armorSetName);
    }
    if (!nullToAbsent || bonusPieces != null) {
      map['bonus_pieces'] = Variable<int>(bonusPieces);
    }
    if (!nullToAbsent || bonusName != null) {
      map['bonus_name'] = Variable<String>(bonusName);
    }
    if (!nullToAbsent || armorSetHash != null) {
      map['armor_set_hash'] = Variable<int>(armorSetHash);
    }
    map['required'] = Variable<int>(required);
    return map;
  }

  SynergyLinksCompanion toCompanion(bool nullToAbsent) {
    return SynergyLinksCompanion(
      id: Value(id),
      synergyId: Value(synergyId),
      kind: Value(kind),
      displayName: Value(displayName),
      itemHash: itemHash == null && nullToAbsent
          ? const Value.absent()
          : Value(itemHash),
      perkHash: perkHash == null && nullToAbsent
          ? const Value.absent()
          : Value(perkHash),
      parentItemHash: parentItemHash == null && nullToAbsent
          ? const Value.absent()
          : Value(parentItemHash),
      originTraitName: originTraitName == null && nullToAbsent
          ? const Value.absent()
          : Value(originTraitName),
      originTraitHash: originTraitHash == null && nullToAbsent
          ? const Value.absent()
          : Value(originTraitHash),
      armorSetName: armorSetName == null && nullToAbsent
          ? const Value.absent()
          : Value(armorSetName),
      bonusPieces: bonusPieces == null && nullToAbsent
          ? const Value.absent()
          : Value(bonusPieces),
      bonusName: bonusName == null && nullToAbsent
          ? const Value.absent()
          : Value(bonusName),
      armorSetHash: armorSetHash == null && nullToAbsent
          ? const Value.absent()
          : Value(armorSetHash),
      required: Value(required),
    );
  }

  factory SynergyLink.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SynergyLink(
      id: serializer.fromJson<String>(json['id']),
      synergyId: serializer.fromJson<String>(json['synergyId']),
      kind: serializer.fromJson<String>(json['kind']),
      displayName: serializer.fromJson<String>(json['displayName']),
      itemHash: serializer.fromJson<int?>(json['itemHash']),
      perkHash: serializer.fromJson<int?>(json['perkHash']),
      parentItemHash: serializer.fromJson<int?>(json['parentItemHash']),
      originTraitName: serializer.fromJson<String?>(json['originTraitName']),
      originTraitHash: serializer.fromJson<int?>(json['originTraitHash']),
      armorSetName: serializer.fromJson<String?>(json['armorSetName']),
      bonusPieces: serializer.fromJson<int?>(json['bonusPieces']),
      bonusName: serializer.fromJson<String?>(json['bonusName']),
      armorSetHash: serializer.fromJson<int?>(json['armorSetHash']),
      required: serializer.fromJson<int>(json['required']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'synergyId': serializer.toJson<String>(synergyId),
      'kind': serializer.toJson<String>(kind),
      'displayName': serializer.toJson<String>(displayName),
      'itemHash': serializer.toJson<int?>(itemHash),
      'perkHash': serializer.toJson<int?>(perkHash),
      'parentItemHash': serializer.toJson<int?>(parentItemHash),
      'originTraitName': serializer.toJson<String?>(originTraitName),
      'originTraitHash': serializer.toJson<int?>(originTraitHash),
      'armorSetName': serializer.toJson<String?>(armorSetName),
      'bonusPieces': serializer.toJson<int?>(bonusPieces),
      'bonusName': serializer.toJson<String?>(bonusName),
      'armorSetHash': serializer.toJson<int?>(armorSetHash),
      'required': serializer.toJson<int>(required),
    };
  }

  SynergyLink copyWith(
          {String? id,
          String? synergyId,
          String? kind,
          String? displayName,
          Value<int?> itemHash = const Value.absent(),
          Value<int?> perkHash = const Value.absent(),
          Value<int?> parentItemHash = const Value.absent(),
          Value<String?> originTraitName = const Value.absent(),
          Value<int?> originTraitHash = const Value.absent(),
          Value<String?> armorSetName = const Value.absent(),
          Value<int?> bonusPieces = const Value.absent(),
          Value<String?> bonusName = const Value.absent(),
          Value<int?> armorSetHash = const Value.absent(),
          int? required}) =>
      SynergyLink(
        id: id ?? this.id,
        synergyId: synergyId ?? this.synergyId,
        kind: kind ?? this.kind,
        displayName: displayName ?? this.displayName,
        itemHash: itemHash.present ? itemHash.value : this.itemHash,
        perkHash: perkHash.present ? perkHash.value : this.perkHash,
        parentItemHash:
            parentItemHash.present ? parentItemHash.value : this.parentItemHash,
        originTraitName: originTraitName.present
            ? originTraitName.value
            : this.originTraitName,
        originTraitHash: originTraitHash.present
            ? originTraitHash.value
            : this.originTraitHash,
        armorSetName:
            armorSetName.present ? armorSetName.value : this.armorSetName,
        bonusPieces: bonusPieces.present ? bonusPieces.value : this.bonusPieces,
        bonusName: bonusName.present ? bonusName.value : this.bonusName,
        armorSetHash:
            armorSetHash.present ? armorSetHash.value : this.armorSetHash,
        required: required ?? this.required,
      );
  SynergyLink copyWithCompanion(SynergyLinksCompanion data) {
    return SynergyLink(
      id: data.id.present ? data.id.value : this.id,
      synergyId: data.synergyId.present ? data.synergyId.value : this.synergyId,
      kind: data.kind.present ? data.kind.value : this.kind,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      itemHash: data.itemHash.present ? data.itemHash.value : this.itemHash,
      perkHash: data.perkHash.present ? data.perkHash.value : this.perkHash,
      parentItemHash: data.parentItemHash.present
          ? data.parentItemHash.value
          : this.parentItemHash,
      originTraitName: data.originTraitName.present
          ? data.originTraitName.value
          : this.originTraitName,
      originTraitHash: data.originTraitHash.present
          ? data.originTraitHash.value
          : this.originTraitHash,
      armorSetName: data.armorSetName.present
          ? data.armorSetName.value
          : this.armorSetName,
      bonusPieces:
          data.bonusPieces.present ? data.bonusPieces.value : this.bonusPieces,
      bonusName: data.bonusName.present ? data.bonusName.value : this.bonusName,
      armorSetHash: data.armorSetHash.present
          ? data.armorSetHash.value
          : this.armorSetHash,
      required: data.required.present ? data.required.value : this.required,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SynergyLink(')
          ..write('id: $id, ')
          ..write('synergyId: $synergyId, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('itemHash: $itemHash, ')
          ..write('perkHash: $perkHash, ')
          ..write('parentItemHash: $parentItemHash, ')
          ..write('originTraitName: $originTraitName, ')
          ..write('originTraitHash: $originTraitHash, ')
          ..write('armorSetName: $armorSetName, ')
          ..write('bonusPieces: $bonusPieces, ')
          ..write('bonusName: $bonusName, ')
          ..write('armorSetHash: $armorSetHash, ')
          ..write('required: $required')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      synergyId,
      kind,
      displayName,
      itemHash,
      perkHash,
      parentItemHash,
      originTraitName,
      originTraitHash,
      armorSetName,
      bonusPieces,
      bonusName,
      armorSetHash,
      required);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SynergyLink &&
          other.id == this.id &&
          other.synergyId == this.synergyId &&
          other.kind == this.kind &&
          other.displayName == this.displayName &&
          other.itemHash == this.itemHash &&
          other.perkHash == this.perkHash &&
          other.parentItemHash == this.parentItemHash &&
          other.originTraitName == this.originTraitName &&
          other.originTraitHash == this.originTraitHash &&
          other.armorSetName == this.armorSetName &&
          other.bonusPieces == this.bonusPieces &&
          other.bonusName == this.bonusName &&
          other.armorSetHash == this.armorSetHash &&
          other.required == this.required);
}

class SynergyLinksCompanion extends UpdateCompanion<SynergyLink> {
  final Value<String> id;
  final Value<String> synergyId;
  final Value<String> kind;
  final Value<String> displayName;
  final Value<int?> itemHash;
  final Value<int?> perkHash;
  final Value<int?> parentItemHash;
  final Value<String?> originTraitName;
  final Value<int?> originTraitHash;
  final Value<String?> armorSetName;
  final Value<int?> bonusPieces;
  final Value<String?> bonusName;
  final Value<int?> armorSetHash;
  final Value<int> required;
  final Value<int> rowid;
  const SynergyLinksCompanion({
    this.id = const Value.absent(),
    this.synergyId = const Value.absent(),
    this.kind = const Value.absent(),
    this.displayName = const Value.absent(),
    this.itemHash = const Value.absent(),
    this.perkHash = const Value.absent(),
    this.parentItemHash = const Value.absent(),
    this.originTraitName = const Value.absent(),
    this.originTraitHash = const Value.absent(),
    this.armorSetName = const Value.absent(),
    this.bonusPieces = const Value.absent(),
    this.bonusName = const Value.absent(),
    this.armorSetHash = const Value.absent(),
    this.required = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SynergyLinksCompanion.insert({
    required String id,
    required String synergyId,
    required String kind,
    required String displayName,
    this.itemHash = const Value.absent(),
    this.perkHash = const Value.absent(),
    this.parentItemHash = const Value.absent(),
    this.originTraitName = const Value.absent(),
    this.originTraitHash = const Value.absent(),
    this.armorSetName = const Value.absent(),
    this.bonusPieces = const Value.absent(),
    this.bonusName = const Value.absent(),
    this.armorSetHash = const Value.absent(),
    this.required = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        synergyId = Value(synergyId),
        kind = Value(kind),
        displayName = Value(displayName);
  static Insertable<SynergyLink> custom({
    Expression<String>? id,
    Expression<String>? synergyId,
    Expression<String>? kind,
    Expression<String>? displayName,
    Expression<int>? itemHash,
    Expression<int>? perkHash,
    Expression<int>? parentItemHash,
    Expression<String>? originTraitName,
    Expression<int>? originTraitHash,
    Expression<String>? armorSetName,
    Expression<int>? bonusPieces,
    Expression<String>? bonusName,
    Expression<int>? armorSetHash,
    Expression<int>? required,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (synergyId != null) 'synergy_id': synergyId,
      if (kind != null) 'kind': kind,
      if (displayName != null) 'display_name': displayName,
      if (itemHash != null) 'item_hash': itemHash,
      if (perkHash != null) 'perk_hash': perkHash,
      if (parentItemHash != null) 'parent_item_hash': parentItemHash,
      if (originTraitName != null) 'origin_trait_name': originTraitName,
      if (originTraitHash != null) 'origin_trait_hash': originTraitHash,
      if (armorSetName != null) 'armor_set_name': armorSetName,
      if (bonusPieces != null) 'bonus_pieces': bonusPieces,
      if (bonusName != null) 'bonus_name': bonusName,
      if (armorSetHash != null) 'armor_set_hash': armorSetHash,
      if (required != null) 'required': required,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SynergyLinksCompanion copyWith(
      {Value<String>? id,
      Value<String>? synergyId,
      Value<String>? kind,
      Value<String>? displayName,
      Value<int?>? itemHash,
      Value<int?>? perkHash,
      Value<int?>? parentItemHash,
      Value<String?>? originTraitName,
      Value<int?>? originTraitHash,
      Value<String?>? armorSetName,
      Value<int?>? bonusPieces,
      Value<String?>? bonusName,
      Value<int?>? armorSetHash,
      Value<int>? required,
      Value<int>? rowid}) {
    return SynergyLinksCompanion(
      id: id ?? this.id,
      synergyId: synergyId ?? this.synergyId,
      kind: kind ?? this.kind,
      displayName: displayName ?? this.displayName,
      itemHash: itemHash ?? this.itemHash,
      perkHash: perkHash ?? this.perkHash,
      parentItemHash: parentItemHash ?? this.parentItemHash,
      originTraitName: originTraitName ?? this.originTraitName,
      originTraitHash: originTraitHash ?? this.originTraitHash,
      armorSetName: armorSetName ?? this.armorSetName,
      bonusPieces: bonusPieces ?? this.bonusPieces,
      bonusName: bonusName ?? this.bonusName,
      armorSetHash: armorSetHash ?? this.armorSetHash,
      required: required ?? this.required,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (synergyId.present) {
      map['synergy_id'] = Variable<String>(synergyId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (itemHash.present) {
      map['item_hash'] = Variable<int>(itemHash.value);
    }
    if (perkHash.present) {
      map['perk_hash'] = Variable<int>(perkHash.value);
    }
    if (parentItemHash.present) {
      map['parent_item_hash'] = Variable<int>(parentItemHash.value);
    }
    if (originTraitName.present) {
      map['origin_trait_name'] = Variable<String>(originTraitName.value);
    }
    if (originTraitHash.present) {
      map['origin_trait_hash'] = Variable<int>(originTraitHash.value);
    }
    if (armorSetName.present) {
      map['armor_set_name'] = Variable<String>(armorSetName.value);
    }
    if (bonusPieces.present) {
      map['bonus_pieces'] = Variable<int>(bonusPieces.value);
    }
    if (bonusName.present) {
      map['bonus_name'] = Variable<String>(bonusName.value);
    }
    if (armorSetHash.present) {
      map['armor_set_hash'] = Variable<int>(armorSetHash.value);
    }
    if (required.present) {
      map['required'] = Variable<int>(required.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SynergyLinksCompanion(')
          ..write('id: $id, ')
          ..write('synergyId: $synergyId, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('itemHash: $itemHash, ')
          ..write('perkHash: $perkHash, ')
          ..write('parentItemHash: $parentItemHash, ')
          ..write('originTraitName: $originTraitName, ')
          ..write('originTraitHash: $originTraitHash, ')
          ..write('armorSetName: $armorSetName, ')
          ..write('bonusPieces: $bonusPieces, ')
          ..write('bonusName: $bonusName, ')
          ..write('armorSetHash: $armorSetHash, ')
          ..write('required: $required, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BuildsTable extends Builds with TableInfo<$BuildsTable, Build> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classNameMeta =
      const VerificationMeta('className');
  @override
  late final GeneratedColumn<String> className = GeneratedColumn<String>(
      'class_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subclassMeta =
      const VerificationMeta('subclass');
  @override
  late final GeneratedColumn<String> subclass = GeneratedColumn<String>(
      'subclass', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exoticArmorHashMeta =
      const VerificationMeta('exoticArmorHash');
  @override
  late final GeneratedColumn<int> exoticArmorHash = GeneratedColumn<int>(
      'exotic_armor_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _exoticArmorNameMeta =
      const VerificationMeta('exoticArmorName');
  @override
  late final GeneratedColumn<String> exoticArmorName = GeneratedColumn<String>(
      'exotic_armor_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exoticWeaponHashMeta =
      const VerificationMeta('exoticWeaponHash');
  @override
  late final GeneratedColumn<int> exoticWeaponHash = GeneratedColumn<int>(
      'exotic_weapon_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _exoticWeaponNameMeta =
      const VerificationMeta('exoticWeaponName');
  @override
  late final GeneratedColumn<String> exoticWeaponName = GeneratedColumn<String>(
      'exotic_weapon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pinnedSuperMeta =
      const VerificationMeta('pinnedSuper');
  @override
  late final GeneratedColumn<String> pinnedSuper = GeneratedColumn<String>(
      'pinned_super', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _softStatTargetsMeta =
      const VerificationMeta('softStatTargets');
  @override
  late final GeneratedColumn<String> softStatTargets = GeneratedColumn<String>(
      'soft_stat_targets', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        name,
        className,
        subclass,
        exoticArmorHash,
        exoticArmorName,
        exoticWeaponHash,
        exoticWeaponName,
        pinnedSuper,
        softStatTargets,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'builds';
  @override
  VerificationContext validateIntegrity(Insertable<Build> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('class_name')) {
      context.handle(_classNameMeta,
          className.isAcceptableOrUnknown(data['class_name']!, _classNameMeta));
    } else if (isInserting) {
      context.missing(_classNameMeta);
    }
    if (data.containsKey('subclass')) {
      context.handle(_subclassMeta,
          subclass.isAcceptableOrUnknown(data['subclass']!, _subclassMeta));
    } else if (isInserting) {
      context.missing(_subclassMeta);
    }
    if (data.containsKey('exotic_armor_hash')) {
      context.handle(
          _exoticArmorHashMeta,
          exoticArmorHash.isAcceptableOrUnknown(
              data['exotic_armor_hash']!, _exoticArmorHashMeta));
    }
    if (data.containsKey('exotic_armor_name')) {
      context.handle(
          _exoticArmorNameMeta,
          exoticArmorName.isAcceptableOrUnknown(
              data['exotic_armor_name']!, _exoticArmorNameMeta));
    }
    if (data.containsKey('exotic_weapon_hash')) {
      context.handle(
          _exoticWeaponHashMeta,
          exoticWeaponHash.isAcceptableOrUnknown(
              data['exotic_weapon_hash']!, _exoticWeaponHashMeta));
    }
    if (data.containsKey('exotic_weapon_name')) {
      context.handle(
          _exoticWeaponNameMeta,
          exoticWeaponName.isAcceptableOrUnknown(
              data['exotic_weapon_name']!, _exoticWeaponNameMeta));
    }
    if (data.containsKey('pinned_super')) {
      context.handle(
          _pinnedSuperMeta,
          pinnedSuper.isAcceptableOrUnknown(
              data['pinned_super']!, _pinnedSuperMeta));
    }
    if (data.containsKey('soft_stat_targets')) {
      context.handle(
          _softStatTargetsMeta,
          softStatTargets.isAcceptableOrUnknown(
              data['soft_stat_targets']!, _softStatTargetsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Build map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Build(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      className: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_name'])!,
      subclass: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subclass'])!,
      exoticArmorHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exotic_armor_hash']),
      exoticArmorName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exotic_armor_name']),
      exoticWeaponHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exotic_weapon_hash']),
      exoticWeaponName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exotic_weapon_name']),
      pinnedSuper: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pinned_super']),
      softStatTargets: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}soft_stat_targets']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BuildsTable createAlias(String alias) {
    return $BuildsTable(attachedDatabase, alias);
  }
}

class Build extends DataClass implements Insertable<Build> {
  final String id;
  final int userId;
  final String name;
  final String className;
  final String subclass;
  final int? exoticArmorHash;
  final String? exoticArmorName;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final String? pinnedSuper;
  final String? softStatTargets;
  final String createdAt;
  final String updatedAt;
  const Build(
      {required this.id,
      required this.userId,
      required this.name,
      required this.className,
      required this.subclass,
      this.exoticArmorHash,
      this.exoticArmorName,
      this.exoticWeaponHash,
      this.exoticWeaponName,
      this.pinnedSuper,
      this.softStatTargets,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    map['name'] = Variable<String>(name);
    map['class_name'] = Variable<String>(className);
    map['subclass'] = Variable<String>(subclass);
    if (!nullToAbsent || exoticArmorHash != null) {
      map['exotic_armor_hash'] = Variable<int>(exoticArmorHash);
    }
    if (!nullToAbsent || exoticArmorName != null) {
      map['exotic_armor_name'] = Variable<String>(exoticArmorName);
    }
    if (!nullToAbsent || exoticWeaponHash != null) {
      map['exotic_weapon_hash'] = Variable<int>(exoticWeaponHash);
    }
    if (!nullToAbsent || exoticWeaponName != null) {
      map['exotic_weapon_name'] = Variable<String>(exoticWeaponName);
    }
    if (!nullToAbsent || pinnedSuper != null) {
      map['pinned_super'] = Variable<String>(pinnedSuper);
    }
    if (!nullToAbsent || softStatTargets != null) {
      map['soft_stat_targets'] = Variable<String>(softStatTargets);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BuildsCompanion toCompanion(bool nullToAbsent) {
    return BuildsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      className: Value(className),
      subclass: Value(subclass),
      exoticArmorHash: exoticArmorHash == null && nullToAbsent
          ? const Value.absent()
          : Value(exoticArmorHash),
      exoticArmorName: exoticArmorName == null && nullToAbsent
          ? const Value.absent()
          : Value(exoticArmorName),
      exoticWeaponHash: exoticWeaponHash == null && nullToAbsent
          ? const Value.absent()
          : Value(exoticWeaponHash),
      exoticWeaponName: exoticWeaponName == null && nullToAbsent
          ? const Value.absent()
          : Value(exoticWeaponName),
      pinnedSuper: pinnedSuper == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedSuper),
      softStatTargets: softStatTargets == null && nullToAbsent
          ? const Value.absent()
          : Value(softStatTargets),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Build.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Build(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      className: serializer.fromJson<String>(json['className']),
      subclass: serializer.fromJson<String>(json['subclass']),
      exoticArmorHash: serializer.fromJson<int?>(json['exoticArmorHash']),
      exoticArmorName: serializer.fromJson<String?>(json['exoticArmorName']),
      exoticWeaponHash: serializer.fromJson<int?>(json['exoticWeaponHash']),
      exoticWeaponName: serializer.fromJson<String?>(json['exoticWeaponName']),
      pinnedSuper: serializer.fromJson<String?>(json['pinnedSuper']),
      softStatTargets: serializer.fromJson<String?>(json['softStatTargets']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'name': serializer.toJson<String>(name),
      'className': serializer.toJson<String>(className),
      'subclass': serializer.toJson<String>(subclass),
      'exoticArmorHash': serializer.toJson<int?>(exoticArmorHash),
      'exoticArmorName': serializer.toJson<String?>(exoticArmorName),
      'exoticWeaponHash': serializer.toJson<int?>(exoticWeaponHash),
      'exoticWeaponName': serializer.toJson<String?>(exoticWeaponName),
      'pinnedSuper': serializer.toJson<String?>(pinnedSuper),
      'softStatTargets': serializer.toJson<String?>(softStatTargets),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  Build copyWith(
          {String? id,
          int? userId,
          String? name,
          String? className,
          String? subclass,
          Value<int?> exoticArmorHash = const Value.absent(),
          Value<String?> exoticArmorName = const Value.absent(),
          Value<int?> exoticWeaponHash = const Value.absent(),
          Value<String?> exoticWeaponName = const Value.absent(),
          Value<String?> pinnedSuper = const Value.absent(),
          Value<String?> softStatTargets = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      Build(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        className: className ?? this.className,
        subclass: subclass ?? this.subclass,
        exoticArmorHash: exoticArmorHash.present
            ? exoticArmorHash.value
            : this.exoticArmorHash,
        exoticArmorName: exoticArmorName.present
            ? exoticArmorName.value
            : this.exoticArmorName,
        exoticWeaponHash: exoticWeaponHash.present
            ? exoticWeaponHash.value
            : this.exoticWeaponHash,
        exoticWeaponName: exoticWeaponName.present
            ? exoticWeaponName.value
            : this.exoticWeaponName,
        pinnedSuper: pinnedSuper.present ? pinnedSuper.value : this.pinnedSuper,
        softStatTargets: softStatTargets.present
            ? softStatTargets.value
            : this.softStatTargets,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Build copyWithCompanion(BuildsCompanion data) {
    return Build(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      className: data.className.present ? data.className.value : this.className,
      subclass: data.subclass.present ? data.subclass.value : this.subclass,
      exoticArmorHash: data.exoticArmorHash.present
          ? data.exoticArmorHash.value
          : this.exoticArmorHash,
      exoticArmorName: data.exoticArmorName.present
          ? data.exoticArmorName.value
          : this.exoticArmorName,
      exoticWeaponHash: data.exoticWeaponHash.present
          ? data.exoticWeaponHash.value
          : this.exoticWeaponHash,
      exoticWeaponName: data.exoticWeaponName.present
          ? data.exoticWeaponName.value
          : this.exoticWeaponName,
      pinnedSuper:
          data.pinnedSuper.present ? data.pinnedSuper.value : this.pinnedSuper,
      softStatTargets: data.softStatTargets.present
          ? data.softStatTargets.value
          : this.softStatTargets,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Build(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('className: $className, ')
          ..write('subclass: $subclass, ')
          ..write('exoticArmorHash: $exoticArmorHash, ')
          ..write('exoticArmorName: $exoticArmorName, ')
          ..write('exoticWeaponHash: $exoticWeaponHash, ')
          ..write('exoticWeaponName: $exoticWeaponName, ')
          ..write('pinnedSuper: $pinnedSuper, ')
          ..write('softStatTargets: $softStatTargets, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      name,
      className,
      subclass,
      exoticArmorHash,
      exoticArmorName,
      exoticWeaponHash,
      exoticWeaponName,
      pinnedSuper,
      softStatTargets,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Build &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.className == this.className &&
          other.subclass == this.subclass &&
          other.exoticArmorHash == this.exoticArmorHash &&
          other.exoticArmorName == this.exoticArmorName &&
          other.exoticWeaponHash == this.exoticWeaponHash &&
          other.exoticWeaponName == this.exoticWeaponName &&
          other.pinnedSuper == this.pinnedSuper &&
          other.softStatTargets == this.softStatTargets &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BuildsCompanion extends UpdateCompanion<Build> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String> name;
  final Value<String> className;
  final Value<String> subclass;
  final Value<int?> exoticArmorHash;
  final Value<String?> exoticArmorName;
  final Value<int?> exoticWeaponHash;
  final Value<String?> exoticWeaponName;
  final Value<String?> pinnedSuper;
  final Value<String?> softStatTargets;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const BuildsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.className = const Value.absent(),
    this.subclass = const Value.absent(),
    this.exoticArmorHash = const Value.absent(),
    this.exoticArmorName = const Value.absent(),
    this.exoticWeaponHash = const Value.absent(),
    this.exoticWeaponName = const Value.absent(),
    this.pinnedSuper = const Value.absent(),
    this.softStatTargets = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildsCompanion.insert({
    required String id,
    required int userId,
    required String name,
    required String className,
    required String subclass,
    this.exoticArmorHash = const Value.absent(),
    this.exoticArmorName = const Value.absent(),
    this.exoticWeaponHash = const Value.absent(),
    this.exoticWeaponName = const Value.absent(),
    this.pinnedSuper = const Value.absent(),
    this.softStatTargets = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        className = Value(className),
        subclass = Value(subclass),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Build> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? name,
    Expression<String>? className,
    Expression<String>? subclass,
    Expression<int>? exoticArmorHash,
    Expression<String>? exoticArmorName,
    Expression<int>? exoticWeaponHash,
    Expression<String>? exoticWeaponName,
    Expression<String>? pinnedSuper,
    Expression<String>? softStatTargets,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (className != null) 'class_name': className,
      if (subclass != null) 'subclass': subclass,
      if (exoticArmorHash != null) 'exotic_armor_hash': exoticArmorHash,
      if (exoticArmorName != null) 'exotic_armor_name': exoticArmorName,
      if (exoticWeaponHash != null) 'exotic_weapon_hash': exoticWeaponHash,
      if (exoticWeaponName != null) 'exotic_weapon_name': exoticWeaponName,
      if (pinnedSuper != null) 'pinned_super': pinnedSuper,
      if (softStatTargets != null) 'soft_stat_targets': softStatTargets,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildsCompanion copyWith(
      {Value<String>? id,
      Value<int>? userId,
      Value<String>? name,
      Value<String>? className,
      Value<String>? subclass,
      Value<int?>? exoticArmorHash,
      Value<String?>? exoticArmorName,
      Value<int?>? exoticWeaponHash,
      Value<String?>? exoticWeaponName,
      Value<String?>? pinnedSuper,
      Value<String?>? softStatTargets,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return BuildsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      className: className ?? this.className,
      subclass: subclass ?? this.subclass,
      exoticArmorHash: exoticArmorHash ?? this.exoticArmorHash,
      exoticArmorName: exoticArmorName ?? this.exoticArmorName,
      exoticWeaponHash: exoticWeaponHash ?? this.exoticWeaponHash,
      exoticWeaponName: exoticWeaponName ?? this.exoticWeaponName,
      pinnedSuper: pinnedSuper ?? this.pinnedSuper,
      softStatTargets: softStatTargets ?? this.softStatTargets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (className.present) {
      map['class_name'] = Variable<String>(className.value);
    }
    if (subclass.present) {
      map['subclass'] = Variable<String>(subclass.value);
    }
    if (exoticArmorHash.present) {
      map['exotic_armor_hash'] = Variable<int>(exoticArmorHash.value);
    }
    if (exoticArmorName.present) {
      map['exotic_armor_name'] = Variable<String>(exoticArmorName.value);
    }
    if (exoticWeaponHash.present) {
      map['exotic_weapon_hash'] = Variable<int>(exoticWeaponHash.value);
    }
    if (exoticWeaponName.present) {
      map['exotic_weapon_name'] = Variable<String>(exoticWeaponName.value);
    }
    if (pinnedSuper.present) {
      map['pinned_super'] = Variable<String>(pinnedSuper.value);
    }
    if (softStatTargets.present) {
      map['soft_stat_targets'] = Variable<String>(softStatTargets.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('className: $className, ')
          ..write('subclass: $subclass, ')
          ..write('exoticArmorHash: $exoticArmorHash, ')
          ..write('exoticArmorName: $exoticArmorName, ')
          ..write('exoticWeaponHash: $exoticWeaponHash, ')
          ..write('exoticWeaponName: $exoticWeaponName, ')
          ..write('pinnedSuper: $pinnedSuper, ')
          ..write('softStatTargets: $softStatTargets, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BuildTagsTable extends BuildTags
    with TableInfo<$BuildTagsTable, BuildTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _buildIdMeta =
      const VerificationMeta('buildId');
  @override
  late final GeneratedColumn<String> buildId = GeneratedColumn<String>(
      'build_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [buildId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_tags';
  @override
  VerificationContext validateIntegrity(Insertable<BuildTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('build_id')) {
      context.handle(_buildIdMeta,
          buildId.isAcceptableOrUnknown(data['build_id']!, _buildIdMeta));
    } else if (isInserting) {
      context.missing(_buildIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {buildId, tagId},
      ];
  @override
  BuildTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BuildTag(
      buildId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}build_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $BuildTagsTable createAlias(String alias) {
    return $BuildTagsTable(attachedDatabase, alias);
  }
}

class BuildTag extends DataClass implements Insertable<BuildTag> {
  final String buildId;
  final String tagId;
  const BuildTag({required this.buildId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['build_id'] = Variable<String>(buildId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  BuildTagsCompanion toCompanion(bool nullToAbsent) {
    return BuildTagsCompanion(
      buildId: Value(buildId),
      tagId: Value(tagId),
    );
  }

  factory BuildTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BuildTag(
      buildId: serializer.fromJson<String>(json['buildId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'buildId': serializer.toJson<String>(buildId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  BuildTag copyWith({String? buildId, String? tagId}) => BuildTag(
        buildId: buildId ?? this.buildId,
        tagId: tagId ?? this.tagId,
      );
  BuildTag copyWithCompanion(BuildTagsCompanion data) {
    return BuildTag(
      buildId: data.buildId.present ? data.buildId.value : this.buildId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BuildTag(')
          ..write('buildId: $buildId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(buildId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuildTag &&
          other.buildId == this.buildId &&
          other.tagId == this.tagId);
}

class BuildTagsCompanion extends UpdateCompanion<BuildTag> {
  final Value<String> buildId;
  final Value<String> tagId;
  final Value<int> rowid;
  const BuildTagsCompanion({
    this.buildId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildTagsCompanion.insert({
    required String buildId,
    required String tagId,
    this.rowid = const Value.absent(),
  })  : buildId = Value(buildId),
        tagId = Value(tagId);
  static Insertable<BuildTag> custom({
    Expression<String>? buildId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (buildId != null) 'build_id': buildId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildTagsCompanion copyWith(
      {Value<String>? buildId, Value<String>? tagId, Value<int>? rowid}) {
    return BuildTagsCompanion(
      buildId: buildId ?? this.buildId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (buildId.present) {
      map['build_id'] = Variable<String>(buildId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildTagsCompanion(')
          ..write('buildId: $buildId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BuildVariantsTable extends BuildVariants
    with TableInfo<$BuildVariantsTable, BuildVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _buildIdMeta =
      const VerificationMeta('buildId');
  @override
  late final GeneratedColumn<String> buildId = GeneratedColumn<String>(
      'build_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isDefaultMeta =
      const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<int> isDefault = GeneratedColumn<int>(
      'is_default', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _exoticWeaponHashMeta =
      const VerificationMeta('exoticWeaponHash');
  @override
  late final GeneratedColumn<int> exoticWeaponHash = GeneratedColumn<int>(
      'exotic_weapon_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _exoticWeaponNameMeta =
      const VerificationMeta('exoticWeaponName');
  @override
  late final GeneratedColumn<String> exoticWeaponName = GeneratedColumn<String>(
      'exotic_weapon_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _artifactHashMeta =
      const VerificationMeta('artifactHash');
  @override
  late final GeneratedColumn<int> artifactHash = GeneratedColumn<int>(
      'artifact_hash', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _artifactNameMeta =
      const VerificationMeta('artifactName');
  @override
  late final GeneratedColumn<String> artifactName = GeneratedColumn<String>(
      'artifact_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _artifactConfigMeta =
      const VerificationMeta('artifactConfig');
  @override
  late final GeneratedColumn<String> artifactConfig = GeneratedColumn<String>(
      'artifact_config', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _subclassKitMeta =
      const VerificationMeta('subclassKit');
  @override
  late final GeneratedColumn<String> subclassKit = GeneratedColumn<String>(
      'subclass_kit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        buildId,
        name,
        isDefault,
        exoticWeaponHash,
        exoticWeaponName,
        artifactHash,
        artifactName,
        artifactConfig,
        subclassKit,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_variants';
  @override
  VerificationContext validateIntegrity(Insertable<BuildVariant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('build_id')) {
      context.handle(_buildIdMeta,
          buildId.isAcceptableOrUnknown(data['build_id']!, _buildIdMeta));
    } else if (isInserting) {
      context.missing(_buildIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta,
          isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    if (data.containsKey('exotic_weapon_hash')) {
      context.handle(
          _exoticWeaponHashMeta,
          exoticWeaponHash.isAcceptableOrUnknown(
              data['exotic_weapon_hash']!, _exoticWeaponHashMeta));
    }
    if (data.containsKey('exotic_weapon_name')) {
      context.handle(
          _exoticWeaponNameMeta,
          exoticWeaponName.isAcceptableOrUnknown(
              data['exotic_weapon_name']!, _exoticWeaponNameMeta));
    }
    if (data.containsKey('artifact_hash')) {
      context.handle(
          _artifactHashMeta,
          artifactHash.isAcceptableOrUnknown(
              data['artifact_hash']!, _artifactHashMeta));
    }
    if (data.containsKey('artifact_name')) {
      context.handle(
          _artifactNameMeta,
          artifactName.isAcceptableOrUnknown(
              data['artifact_name']!, _artifactNameMeta));
    }
    if (data.containsKey('artifact_config')) {
      context.handle(
          _artifactConfigMeta,
          artifactConfig.isAcceptableOrUnknown(
              data['artifact_config']!, _artifactConfigMeta));
    }
    if (data.containsKey('subclass_kit')) {
      context.handle(
          _subclassKitMeta,
          subclassKit.isAcceptableOrUnknown(
              data['subclass_kit']!, _subclassKitMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BuildVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BuildVariant(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      buildId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}build_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      isDefault: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}is_default'])!,
      exoticWeaponHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exotic_weapon_hash']),
      exoticWeaponName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}exotic_weapon_name']),
      artifactHash: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}artifact_hash']),
      artifactName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artifact_name']),
      artifactConfig: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}artifact_config'])!,
      subclassKit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subclass_kit'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BuildVariantsTable createAlias(String alias) {
    return $BuildVariantsTable(attachedDatabase, alias);
  }
}

class BuildVariant extends DataClass implements Insertable<BuildVariant> {
  final String id;
  final String buildId;
  final String name;
  final int isDefault;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final int? artifactHash;
  final String? artifactName;
  final String artifactConfig;

  /// Variant-owned subclass kit JSON (aspects/fragments/abilities).
  ///
  /// Tree/element lives on [Builds.subclass] only (DBR-SUB-001 / DBR-SUB-003).
  final String subclassKit;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  const BuildVariant(
      {required this.id,
      required this.buildId,
      required this.name,
      required this.isDefault,
      this.exoticWeaponHash,
      this.exoticWeaponName,
      this.artifactHash,
      this.artifactName,
      required this.artifactConfig,
      required this.subclassKit,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['build_id'] = Variable<String>(buildId);
    map['name'] = Variable<String>(name);
    map['is_default'] = Variable<int>(isDefault);
    if (!nullToAbsent || exoticWeaponHash != null) {
      map['exotic_weapon_hash'] = Variable<int>(exoticWeaponHash);
    }
    if (!nullToAbsent || exoticWeaponName != null) {
      map['exotic_weapon_name'] = Variable<String>(exoticWeaponName);
    }
    if (!nullToAbsent || artifactHash != null) {
      map['artifact_hash'] = Variable<int>(artifactHash);
    }
    if (!nullToAbsent || artifactName != null) {
      map['artifact_name'] = Variable<String>(artifactName);
    }
    map['artifact_config'] = Variable<String>(artifactConfig);
    map['subclass_kit'] = Variable<String>(subclassKit);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BuildVariantsCompanion toCompanion(bool nullToAbsent) {
    return BuildVariantsCompanion(
      id: Value(id),
      buildId: Value(buildId),
      name: Value(name),
      isDefault: Value(isDefault),
      exoticWeaponHash: exoticWeaponHash == null && nullToAbsent
          ? const Value.absent()
          : Value(exoticWeaponHash),
      exoticWeaponName: exoticWeaponName == null && nullToAbsent
          ? const Value.absent()
          : Value(exoticWeaponName),
      artifactHash: artifactHash == null && nullToAbsent
          ? const Value.absent()
          : Value(artifactHash),
      artifactName: artifactName == null && nullToAbsent
          ? const Value.absent()
          : Value(artifactName),
      artifactConfig: Value(artifactConfig),
      subclassKit: Value(subclassKit),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BuildVariant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BuildVariant(
      id: serializer.fromJson<String>(json['id']),
      buildId: serializer.fromJson<String>(json['buildId']),
      name: serializer.fromJson<String>(json['name']),
      isDefault: serializer.fromJson<int>(json['isDefault']),
      exoticWeaponHash: serializer.fromJson<int?>(json['exoticWeaponHash']),
      exoticWeaponName: serializer.fromJson<String?>(json['exoticWeaponName']),
      artifactHash: serializer.fromJson<int?>(json['artifactHash']),
      artifactName: serializer.fromJson<String?>(json['artifactName']),
      artifactConfig: serializer.fromJson<String>(json['artifactConfig']),
      subclassKit: serializer.fromJson<String>(json['subclassKit']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'buildId': serializer.toJson<String>(buildId),
      'name': serializer.toJson<String>(name),
      'isDefault': serializer.toJson<int>(isDefault),
      'exoticWeaponHash': serializer.toJson<int?>(exoticWeaponHash),
      'exoticWeaponName': serializer.toJson<String?>(exoticWeaponName),
      'artifactHash': serializer.toJson<int?>(artifactHash),
      'artifactName': serializer.toJson<String?>(artifactName),
      'artifactConfig': serializer.toJson<String>(artifactConfig),
      'subclassKit': serializer.toJson<String>(subclassKit),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  BuildVariant copyWith(
          {String? id,
          String? buildId,
          String? name,
          int? isDefault,
          Value<int?> exoticWeaponHash = const Value.absent(),
          Value<String?> exoticWeaponName = const Value.absent(),
          Value<int?> artifactHash = const Value.absent(),
          Value<String?> artifactName = const Value.absent(),
          String? artifactConfig,
          String? subclassKit,
          Value<String?> notes = const Value.absent(),
          String? createdAt,
          String? updatedAt}) =>
      BuildVariant(
        id: id ?? this.id,
        buildId: buildId ?? this.buildId,
        name: name ?? this.name,
        isDefault: isDefault ?? this.isDefault,
        exoticWeaponHash: exoticWeaponHash.present
            ? exoticWeaponHash.value
            : this.exoticWeaponHash,
        exoticWeaponName: exoticWeaponName.present
            ? exoticWeaponName.value
            : this.exoticWeaponName,
        artifactHash:
            artifactHash.present ? artifactHash.value : this.artifactHash,
        artifactName:
            artifactName.present ? artifactName.value : this.artifactName,
        artifactConfig: artifactConfig ?? this.artifactConfig,
        subclassKit: subclassKit ?? this.subclassKit,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BuildVariant copyWithCompanion(BuildVariantsCompanion data) {
    return BuildVariant(
      id: data.id.present ? data.id.value : this.id,
      buildId: data.buildId.present ? data.buildId.value : this.buildId,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      exoticWeaponHash: data.exoticWeaponHash.present
          ? data.exoticWeaponHash.value
          : this.exoticWeaponHash,
      exoticWeaponName: data.exoticWeaponName.present
          ? data.exoticWeaponName.value
          : this.exoticWeaponName,
      artifactHash: data.artifactHash.present
          ? data.artifactHash.value
          : this.artifactHash,
      artifactName: data.artifactName.present
          ? data.artifactName.value
          : this.artifactName,
      artifactConfig: data.artifactConfig.present
          ? data.artifactConfig.value
          : this.artifactConfig,
      subclassKit:
          data.subclassKit.present ? data.subclassKit.value : this.subclassKit,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BuildVariant(')
          ..write('id: $id, ')
          ..write('buildId: $buildId, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('exoticWeaponHash: $exoticWeaponHash, ')
          ..write('exoticWeaponName: $exoticWeaponName, ')
          ..write('artifactHash: $artifactHash, ')
          ..write('artifactName: $artifactName, ')
          ..write('artifactConfig: $artifactConfig, ')
          ..write('subclassKit: $subclassKit, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      buildId,
      name,
      isDefault,
      exoticWeaponHash,
      exoticWeaponName,
      artifactHash,
      artifactName,
      artifactConfig,
      subclassKit,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuildVariant &&
          other.id == this.id &&
          other.buildId == this.buildId &&
          other.name == this.name &&
          other.isDefault == this.isDefault &&
          other.exoticWeaponHash == this.exoticWeaponHash &&
          other.exoticWeaponName == this.exoticWeaponName &&
          other.artifactHash == this.artifactHash &&
          other.artifactName == this.artifactName &&
          other.artifactConfig == this.artifactConfig &&
          other.subclassKit == this.subclassKit &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BuildVariantsCompanion extends UpdateCompanion<BuildVariant> {
  final Value<String> id;
  final Value<String> buildId;
  final Value<String> name;
  final Value<int> isDefault;
  final Value<int?> exoticWeaponHash;
  final Value<String?> exoticWeaponName;
  final Value<int?> artifactHash;
  final Value<String?> artifactName;
  final Value<String> artifactConfig;
  final Value<String> subclassKit;
  final Value<String?> notes;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const BuildVariantsCompanion({
    this.id = const Value.absent(),
    this.buildId = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.exoticWeaponHash = const Value.absent(),
    this.exoticWeaponName = const Value.absent(),
    this.artifactHash = const Value.absent(),
    this.artifactName = const Value.absent(),
    this.artifactConfig = const Value.absent(),
    this.subclassKit = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildVariantsCompanion.insert({
    required String id,
    required String buildId,
    required String name,
    this.isDefault = const Value.absent(),
    this.exoticWeaponHash = const Value.absent(),
    this.exoticWeaponName = const Value.absent(),
    this.artifactHash = const Value.absent(),
    this.artifactName = const Value.absent(),
    this.artifactConfig = const Value.absent(),
    this.subclassKit = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        buildId = Value(buildId),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BuildVariant> custom({
    Expression<String>? id,
    Expression<String>? buildId,
    Expression<String>? name,
    Expression<int>? isDefault,
    Expression<int>? exoticWeaponHash,
    Expression<String>? exoticWeaponName,
    Expression<int>? artifactHash,
    Expression<String>? artifactName,
    Expression<String>? artifactConfig,
    Expression<String>? subclassKit,
    Expression<String>? notes,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (buildId != null) 'build_id': buildId,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (exoticWeaponHash != null) 'exotic_weapon_hash': exoticWeaponHash,
      if (exoticWeaponName != null) 'exotic_weapon_name': exoticWeaponName,
      if (artifactHash != null) 'artifact_hash': artifactHash,
      if (artifactName != null) 'artifact_name': artifactName,
      if (artifactConfig != null) 'artifact_config': artifactConfig,
      if (subclassKit != null) 'subclass_kit': subclassKit,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildVariantsCompanion copyWith(
      {Value<String>? id,
      Value<String>? buildId,
      Value<String>? name,
      Value<int>? isDefault,
      Value<int?>? exoticWeaponHash,
      Value<String?>? exoticWeaponName,
      Value<int?>? artifactHash,
      Value<String?>? artifactName,
      Value<String>? artifactConfig,
      Value<String>? subclassKit,
      Value<String?>? notes,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return BuildVariantsCompanion(
      id: id ?? this.id,
      buildId: buildId ?? this.buildId,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      exoticWeaponHash: exoticWeaponHash ?? this.exoticWeaponHash,
      exoticWeaponName: exoticWeaponName ?? this.exoticWeaponName,
      artifactHash: artifactHash ?? this.artifactHash,
      artifactName: artifactName ?? this.artifactName,
      artifactConfig: artifactConfig ?? this.artifactConfig,
      subclassKit: subclassKit ?? this.subclassKit,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (buildId.present) {
      map['build_id'] = Variable<String>(buildId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<int>(isDefault.value);
    }
    if (exoticWeaponHash.present) {
      map['exotic_weapon_hash'] = Variable<int>(exoticWeaponHash.value);
    }
    if (exoticWeaponName.present) {
      map['exotic_weapon_name'] = Variable<String>(exoticWeaponName.value);
    }
    if (artifactHash.present) {
      map['artifact_hash'] = Variable<int>(artifactHash.value);
    }
    if (artifactName.present) {
      map['artifact_name'] = Variable<String>(artifactName.value);
    }
    if (artifactConfig.present) {
      map['artifact_config'] = Variable<String>(artifactConfig.value);
    }
    if (subclassKit.present) {
      map['subclass_kit'] = Variable<String>(subclassKit.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildVariantsCompanion(')
          ..write('id: $id, ')
          ..write('buildId: $buildId, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('exoticWeaponHash: $exoticWeaponHash, ')
          ..write('exoticWeaponName: $exoticWeaponName, ')
          ..write('artifactHash: $artifactHash, ')
          ..write('artifactName: $artifactName, ')
          ..write('artifactConfig: $artifactConfig, ')
          ..write('subclassKit: $subclassKit, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BuildSynergyTypesTable extends BuildSynergyTypes
    with TableInfo<$BuildSynergyTypesTable, BuildSynergyType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildSynergyTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _buildIdMeta =
      const VerificationMeta('buildId');
  @override
  late final GeneratedColumn<String> buildId = GeneratedColumn<String>(
      'build_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subTypeMeta =
      const VerificationMeta('subType');
  @override
  late final GeneratedColumn<String> subType = GeneratedColumn<String>(
      'sub_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attachedAtMeta =
      const VerificationMeta('attachedAt');
  @override
  late final GeneratedColumn<String> attachedAt = GeneratedColumn<String>(
      'attached_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [buildId, type, subType, attachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_synergy_types';
  @override
  VerificationContext validateIntegrity(Insertable<BuildSynergyType> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('build_id')) {
      context.handle(_buildIdMeta,
          buildId.isAcceptableOrUnknown(data['build_id']!, _buildIdMeta));
    } else if (isInserting) {
      context.missing(_buildIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('sub_type')) {
      context.handle(_subTypeMeta,
          subType.isAcceptableOrUnknown(data['sub_type']!, _subTypeMeta));
    }
    if (data.containsKey('attached_at')) {
      context.handle(
          _attachedAtMeta,
          attachedAt.isAcceptableOrUnknown(
              data['attached_at']!, _attachedAtMeta));
    } else if (isInserting) {
      context.missing(_attachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {buildId, type, subType},
      ];
  @override
  BuildSynergyType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BuildSynergyType(
      buildId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}build_id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      subType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sub_type']),
      attachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attached_at'])!,
    );
  }

  @override
  $BuildSynergyTypesTable createAlias(String alias) {
    return $BuildSynergyTypesTable(attachedDatabase, alias);
  }
}

class BuildSynergyType extends DataClass
    implements Insertable<BuildSynergyType> {
  final String buildId;
  final String type;
  final String? subType;
  final String attachedAt;
  const BuildSynergyType(
      {required this.buildId,
      required this.type,
      this.subType,
      required this.attachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['build_id'] = Variable<String>(buildId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || subType != null) {
      map['sub_type'] = Variable<String>(subType);
    }
    map['attached_at'] = Variable<String>(attachedAt);
    return map;
  }

  BuildSynergyTypesCompanion toCompanion(bool nullToAbsent) {
    return BuildSynergyTypesCompanion(
      buildId: Value(buildId),
      type: Value(type),
      subType: subType == null && nullToAbsent
          ? const Value.absent()
          : Value(subType),
      attachedAt: Value(attachedAt),
    );
  }

  factory BuildSynergyType.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BuildSynergyType(
      buildId: serializer.fromJson<String>(json['buildId']),
      type: serializer.fromJson<String>(json['type']),
      subType: serializer.fromJson<String?>(json['subType']),
      attachedAt: serializer.fromJson<String>(json['attachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'buildId': serializer.toJson<String>(buildId),
      'type': serializer.toJson<String>(type),
      'subType': serializer.toJson<String?>(subType),
      'attachedAt': serializer.toJson<String>(attachedAt),
    };
  }

  BuildSynergyType copyWith(
          {String? buildId,
          String? type,
          Value<String?> subType = const Value.absent(),
          String? attachedAt}) =>
      BuildSynergyType(
        buildId: buildId ?? this.buildId,
        type: type ?? this.type,
        subType: subType.present ? subType.value : this.subType,
        attachedAt: attachedAt ?? this.attachedAt,
      );
  BuildSynergyType copyWithCompanion(BuildSynergyTypesCompanion data) {
    return BuildSynergyType(
      buildId: data.buildId.present ? data.buildId.value : this.buildId,
      type: data.type.present ? data.type.value : this.type,
      subType: data.subType.present ? data.subType.value : this.subType,
      attachedAt:
          data.attachedAt.present ? data.attachedAt.value : this.attachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BuildSynergyType(')
          ..write('buildId: $buildId, ')
          ..write('type: $type, ')
          ..write('subType: $subType, ')
          ..write('attachedAt: $attachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(buildId, type, subType, attachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuildSynergyType &&
          other.buildId == this.buildId &&
          other.type == this.type &&
          other.subType == this.subType &&
          other.attachedAt == this.attachedAt);
}

class BuildSynergyTypesCompanion extends UpdateCompanion<BuildSynergyType> {
  final Value<String> buildId;
  final Value<String> type;
  final Value<String?> subType;
  final Value<String> attachedAt;
  final Value<int> rowid;
  const BuildSynergyTypesCompanion({
    this.buildId = const Value.absent(),
    this.type = const Value.absent(),
    this.subType = const Value.absent(),
    this.attachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BuildSynergyTypesCompanion.insert({
    required String buildId,
    required String type,
    this.subType = const Value.absent(),
    required String attachedAt,
    this.rowid = const Value.absent(),
  })  : buildId = Value(buildId),
        type = Value(type),
        attachedAt = Value(attachedAt);
  static Insertable<BuildSynergyType> custom({
    Expression<String>? buildId,
    Expression<String>? type,
    Expression<String>? subType,
    Expression<String>? attachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (buildId != null) 'build_id': buildId,
      if (type != null) 'type': type,
      if (subType != null) 'sub_type': subType,
      if (attachedAt != null) 'attached_at': attachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BuildSynergyTypesCompanion copyWith(
      {Value<String>? buildId,
      Value<String>? type,
      Value<String?>? subType,
      Value<String>? attachedAt,
      Value<int>? rowid}) {
    return BuildSynergyTypesCompanion(
      buildId: buildId ?? this.buildId,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      attachedAt: attachedAt ?? this.attachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (buildId.present) {
      map['build_id'] = Variable<String>(buildId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subType.present) {
      map['sub_type'] = Variable<String>(subType.value);
    }
    if (attachedAt.present) {
      map['attached_at'] = Variable<String>(attachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildSynergyTypesCompanion(')
          ..write('buildId: $buildId, ')
          ..write('type: $type, ')
          ..write('subType: $subType, ')
          ..write('attachedAt: $attachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VariantSetAttachmentsTable extends VariantSetAttachments
    with TableInfo<$VariantSetAttachmentsTable, VariantSetAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VariantSetAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _variantIdMeta =
      const VerificationMeta('variantId');
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
      'variant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
      'set_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _snapshotConfigsMeta =
      const VerificationMeta('snapshotConfigs');
  @override
  late final GeneratedColumn<String> snapshotConfigs = GeneratedColumn<String>(
      'snapshot_configs', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _attachedAtMeta =
      const VerificationMeta('attachedAt');
  @override
  late final GeneratedColumn<String> attachedAt = GeneratedColumn<String>(
      'attached_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, variantId, setId, mode, snapshotConfigs, attachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'variant_set_attachments';
  @override
  VerificationContext validateIntegrity(
      Insertable<VariantSetAttachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(_variantIdMeta,
          variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta));
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('set_id')) {
      context.handle(
          _setIdMeta, setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta));
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('snapshot_configs')) {
      context.handle(
          _snapshotConfigsMeta,
          snapshotConfigs.isAcceptableOrUnknown(
              data['snapshot_configs']!, _snapshotConfigsMeta));
    }
    if (data.containsKey('attached_at')) {
      context.handle(
          _attachedAtMeta,
          attachedAt.isAcceptableOrUnknown(
              data['attached_at']!, _attachedAtMeta));
    } else if (isInserting) {
      context.missing(_attachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VariantSetAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VariantSetAttachment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      variantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}variant_id'])!,
      setId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_id'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      snapshotConfigs: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}snapshot_configs']),
      attachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attached_at'])!,
    );
  }

  @override
  $VariantSetAttachmentsTable createAlias(String alias) {
    return $VariantSetAttachmentsTable(attachedDatabase, alias);
  }
}

class VariantSetAttachment extends DataClass
    implements Insertable<VariantSetAttachment> {
  final String id;
  final String variantId;
  final String setId;
  final String mode;
  final String? snapshotConfigs;
  final String attachedAt;
  const VariantSetAttachment(
      {required this.id,
      required this.variantId,
      required this.setId,
      required this.mode,
      this.snapshotConfigs,
      required this.attachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['variant_id'] = Variable<String>(variantId);
    map['set_id'] = Variable<String>(setId);
    map['mode'] = Variable<String>(mode);
    if (!nullToAbsent || snapshotConfigs != null) {
      map['snapshot_configs'] = Variable<String>(snapshotConfigs);
    }
    map['attached_at'] = Variable<String>(attachedAt);
    return map;
  }

  VariantSetAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return VariantSetAttachmentsCompanion(
      id: Value(id),
      variantId: Value(variantId),
      setId: Value(setId),
      mode: Value(mode),
      snapshotConfigs: snapshotConfigs == null && nullToAbsent
          ? const Value.absent()
          : Value(snapshotConfigs),
      attachedAt: Value(attachedAt),
    );
  }

  factory VariantSetAttachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VariantSetAttachment(
      id: serializer.fromJson<String>(json['id']),
      variantId: serializer.fromJson<String>(json['variantId']),
      setId: serializer.fromJson<String>(json['setId']),
      mode: serializer.fromJson<String>(json['mode']),
      snapshotConfigs: serializer.fromJson<String?>(json['snapshotConfigs']),
      attachedAt: serializer.fromJson<String>(json['attachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'variantId': serializer.toJson<String>(variantId),
      'setId': serializer.toJson<String>(setId),
      'mode': serializer.toJson<String>(mode),
      'snapshotConfigs': serializer.toJson<String?>(snapshotConfigs),
      'attachedAt': serializer.toJson<String>(attachedAt),
    };
  }

  VariantSetAttachment copyWith(
          {String? id,
          String? variantId,
          String? setId,
          String? mode,
          Value<String?> snapshotConfigs = const Value.absent(),
          String? attachedAt}) =>
      VariantSetAttachment(
        id: id ?? this.id,
        variantId: variantId ?? this.variantId,
        setId: setId ?? this.setId,
        mode: mode ?? this.mode,
        snapshotConfigs: snapshotConfigs.present
            ? snapshotConfigs.value
            : this.snapshotConfigs,
        attachedAt: attachedAt ?? this.attachedAt,
      );
  VariantSetAttachment copyWithCompanion(VariantSetAttachmentsCompanion data) {
    return VariantSetAttachment(
      id: data.id.present ? data.id.value : this.id,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      setId: data.setId.present ? data.setId.value : this.setId,
      mode: data.mode.present ? data.mode.value : this.mode,
      snapshotConfigs: data.snapshotConfigs.present
          ? data.snapshotConfigs.value
          : this.snapshotConfigs,
      attachedAt:
          data.attachedAt.present ? data.attachedAt.value : this.attachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VariantSetAttachment(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('setId: $setId, ')
          ..write('mode: $mode, ')
          ..write('snapshotConfigs: $snapshotConfigs, ')
          ..write('attachedAt: $attachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, variantId, setId, mode, snapshotConfigs, attachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VariantSetAttachment &&
          other.id == this.id &&
          other.variantId == this.variantId &&
          other.setId == this.setId &&
          other.mode == this.mode &&
          other.snapshotConfigs == this.snapshotConfigs &&
          other.attachedAt == this.attachedAt);
}

class VariantSetAttachmentsCompanion
    extends UpdateCompanion<VariantSetAttachment> {
  final Value<String> id;
  final Value<String> variantId;
  final Value<String> setId;
  final Value<String> mode;
  final Value<String?> snapshotConfigs;
  final Value<String> attachedAt;
  final Value<int> rowid;
  const VariantSetAttachmentsCompanion({
    this.id = const Value.absent(),
    this.variantId = const Value.absent(),
    this.setId = const Value.absent(),
    this.mode = const Value.absent(),
    this.snapshotConfigs = const Value.absent(),
    this.attachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VariantSetAttachmentsCompanion.insert({
    required String id,
    required String variantId,
    required String setId,
    required String mode,
    this.snapshotConfigs = const Value.absent(),
    required String attachedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        variantId = Value(variantId),
        setId = Value(setId),
        mode = Value(mode),
        attachedAt = Value(attachedAt);
  static Insertable<VariantSetAttachment> custom({
    Expression<String>? id,
    Expression<String>? variantId,
    Expression<String>? setId,
    Expression<String>? mode,
    Expression<String>? snapshotConfigs,
    Expression<String>? attachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (variantId != null) 'variant_id': variantId,
      if (setId != null) 'set_id': setId,
      if (mode != null) 'mode': mode,
      if (snapshotConfigs != null) 'snapshot_configs': snapshotConfigs,
      if (attachedAt != null) 'attached_at': attachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VariantSetAttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? variantId,
      Value<String>? setId,
      Value<String>? mode,
      Value<String?>? snapshotConfigs,
      Value<String>? attachedAt,
      Value<int>? rowid}) {
    return VariantSetAttachmentsCompanion(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      setId: setId ?? this.setId,
      mode: mode ?? this.mode,
      snapshotConfigs: snapshotConfigs ?? this.snapshotConfigs,
      attachedAt: attachedAt ?? this.attachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (setId.present) {
      map['set_id'] = Variable<String>(setId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (snapshotConfigs.present) {
      map['snapshot_configs'] = Variable<String>(snapshotConfigs.value);
    }
    if (attachedAt.present) {
      map['attached_at'] = Variable<String>(attachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VariantSetAttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('setId: $setId, ')
          ..write('mode: $mode, ')
          ..write('snapshotConfigs: $snapshotConfigs, ')
          ..write('attachedAt: $attachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponRollTargetsTable extends WeaponRollTargets
    with TableInfo<$WeaponRollTargetsTable, WeaponRollTargetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponRollTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weaponKeyMeta =
      const VerificationMeta('weaponKey');
  @override
  late final GeneratedColumn<String> weaponKey = GeneratedColumn<String>(
      'weapon_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _columnsJsonMeta =
      const VerificationMeta('columnsJson');
  @override
  late final GeneratedColumn<String> columnsJson = GeneratedColumn<String>(
      'columns_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, weaponKey, name, columnsJson, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_roll_targets';
  @override
  VerificationContext validateIntegrity(
      Insertable<WeaponRollTargetRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('weapon_key')) {
      context.handle(_weaponKeyMeta,
          weaponKey.isAcceptableOrUnknown(data['weapon_key']!, _weaponKeyMeta));
    } else if (isInserting) {
      context.missing(_weaponKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('columns_json')) {
      context.handle(
          _columnsJsonMeta,
          columnsJson.isAcceptableOrUnknown(
              data['columns_json']!, _columnsJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeaponRollTargetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponRollTargetRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      weaponKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weapon_key'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      columnsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}columns_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WeaponRollTargetsTable createAlias(String alias) {
    return $WeaponRollTargetsTable(attachedDatabase, alias);
  }
}

class WeaponRollTargetRow extends DataClass
    implements Insertable<WeaponRollTargetRow> {
  final String id;
  final int userId;
  final String weaponKey;
  final String name;
  final String columnsJson;
  final String createdAt;
  final String updatedAt;
  const WeaponRollTargetRow(
      {required this.id,
      required this.userId,
      required this.weaponKey,
      required this.name,
      required this.columnsJson,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    map['weapon_key'] = Variable<String>(weaponKey);
    map['name'] = Variable<String>(name);
    map['columns_json'] = Variable<String>(columnsJson);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  WeaponRollTargetsCompanion toCompanion(bool nullToAbsent) {
    return WeaponRollTargetsCompanion(
      id: Value(id),
      userId: Value(userId),
      weaponKey: Value(weaponKey),
      name: Value(name),
      columnsJson: Value(columnsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WeaponRollTargetRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponRollTargetRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      weaponKey: serializer.fromJson<String>(json['weaponKey']),
      name: serializer.fromJson<String>(json['name']),
      columnsJson: serializer.fromJson<String>(json['columnsJson']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'weaponKey': serializer.toJson<String>(weaponKey),
      'name': serializer.toJson<String>(name),
      'columnsJson': serializer.toJson<String>(columnsJson),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  WeaponRollTargetRow copyWith(
          {String? id,
          int? userId,
          String? weaponKey,
          String? name,
          String? columnsJson,
          String? createdAt,
          String? updatedAt}) =>
      WeaponRollTargetRow(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        weaponKey: weaponKey ?? this.weaponKey,
        name: name ?? this.name,
        columnsJson: columnsJson ?? this.columnsJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WeaponRollTargetRow copyWithCompanion(WeaponRollTargetsCompanion data) {
    return WeaponRollTargetRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      weaponKey: data.weaponKey.present ? data.weaponKey.value : this.weaponKey,
      name: data.name.present ? data.name.value : this.name,
      columnsJson:
          data.columnsJson.present ? data.columnsJson.value : this.columnsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponRollTargetRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('weaponKey: $weaponKey, ')
          ..write('name: $name, ')
          ..write('columnsJson: $columnsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, weaponKey, name, columnsJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponRollTargetRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.weaponKey == this.weaponKey &&
          other.name == this.name &&
          other.columnsJson == this.columnsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WeaponRollTargetsCompanion extends UpdateCompanion<WeaponRollTargetRow> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String> weaponKey;
  final Value<String> name;
  final Value<String> columnsJson;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const WeaponRollTargetsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.weaponKey = const Value.absent(),
    this.name = const Value.absent(),
    this.columnsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponRollTargetsCompanion.insert({
    required String id,
    required int userId,
    required String weaponKey,
    required String name,
    this.columnsJson = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        weaponKey = Value(weaponKey),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<WeaponRollTargetRow> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? weaponKey,
    Expression<String>? name,
    Expression<String>? columnsJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (weaponKey != null) 'weapon_key': weaponKey,
      if (name != null) 'name': name,
      if (columnsJson != null) 'columns_json': columnsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponRollTargetsCompanion copyWith(
      {Value<String>? id,
      Value<int>? userId,
      Value<String>? weaponKey,
      Value<String>? name,
      Value<String>? columnsJson,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return WeaponRollTargetsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weaponKey: weaponKey ?? this.weaponKey,
      name: name ?? this.name,
      columnsJson: columnsJson ?? this.columnsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (weaponKey.present) {
      map['weapon_key'] = Variable<String>(weaponKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (columnsJson.present) {
      map['columns_json'] = Variable<String>(columnsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponRollTargetsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('weaponKey: $weaponKey, ')
          ..write('name: $name, ')
          ..write('columnsJson: $columnsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeaponRollTargetActiveTable extends WeaponRollTargetActive
    with TableInfo<$WeaponRollTargetActiveTable, WeaponRollTargetActiveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeaponRollTargetActiveTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weaponKeyMeta =
      const VerificationMeta('weaponKey');
  @override
  late final GeneratedColumn<String> weaponKey = GeneratedColumn<String>(
      'weapon_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetIdMeta =
      const VerificationMeta('targetId');
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
      'target_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [userId, weaponKey, targetId, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weapon_roll_target_active';
  @override
  VerificationContext validateIntegrity(
      Insertable<WeaponRollTargetActiveRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('weapon_key')) {
      context.handle(_weaponKeyMeta,
          weaponKey.isAcceptableOrUnknown(data['weapon_key']!, _weaponKeyMeta));
    } else if (isInserting) {
      context.missing(_weaponKeyMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(_targetIdMeta,
          targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta));
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, weaponKey};
  @override
  WeaponRollTargetActiveRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeaponRollTargetActiveRow(
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      weaponKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weapon_key'])!,
      targetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_id'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $WeaponRollTargetActiveTable createAlias(String alias) {
    return $WeaponRollTargetActiveTable(attachedDatabase, alias);
  }
}

class WeaponRollTargetActiveRow extends DataClass
    implements Insertable<WeaponRollTargetActiveRow> {
  final int userId;
  final String weaponKey;
  final String targetId;
  final String updatedAt;
  const WeaponRollTargetActiveRow(
      {required this.userId,
      required this.weaponKey,
      required this.targetId,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    map['weapon_key'] = Variable<String>(weaponKey);
    map['target_id'] = Variable<String>(targetId);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  WeaponRollTargetActiveCompanion toCompanion(bool nullToAbsent) {
    return WeaponRollTargetActiveCompanion(
      userId: Value(userId),
      weaponKey: Value(weaponKey),
      targetId: Value(targetId),
      updatedAt: Value(updatedAt),
    );
  }

  factory WeaponRollTargetActiveRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeaponRollTargetActiveRow(
      userId: serializer.fromJson<int>(json['userId']),
      weaponKey: serializer.fromJson<String>(json['weaponKey']),
      targetId: serializer.fromJson<String>(json['targetId']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'weaponKey': serializer.toJson<String>(weaponKey),
      'targetId': serializer.toJson<String>(targetId),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  WeaponRollTargetActiveRow copyWith(
          {int? userId,
          String? weaponKey,
          String? targetId,
          String? updatedAt}) =>
      WeaponRollTargetActiveRow(
        userId: userId ?? this.userId,
        weaponKey: weaponKey ?? this.weaponKey,
        targetId: targetId ?? this.targetId,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  WeaponRollTargetActiveRow copyWithCompanion(
      WeaponRollTargetActiveCompanion data) {
    return WeaponRollTargetActiveRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      weaponKey: data.weaponKey.present ? data.weaponKey.value : this.weaponKey,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeaponRollTargetActiveRow(')
          ..write('userId: $userId, ')
          ..write('weaponKey: $weaponKey, ')
          ..write('targetId: $targetId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, weaponKey, targetId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeaponRollTargetActiveRow &&
          other.userId == this.userId &&
          other.weaponKey == this.weaponKey &&
          other.targetId == this.targetId &&
          other.updatedAt == this.updatedAt);
}

class WeaponRollTargetActiveCompanion
    extends UpdateCompanion<WeaponRollTargetActiveRow> {
  final Value<int> userId;
  final Value<String> weaponKey;
  final Value<String> targetId;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const WeaponRollTargetActiveCompanion({
    this.userId = const Value.absent(),
    this.weaponKey = const Value.absent(),
    this.targetId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeaponRollTargetActiveCompanion.insert({
    required int userId,
    required String weaponKey,
    required String targetId,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : userId = Value(userId),
        weaponKey = Value(weaponKey),
        targetId = Value(targetId),
        updatedAt = Value(updatedAt);
  static Insertable<WeaponRollTargetActiveRow> custom({
    Expression<int>? userId,
    Expression<String>? weaponKey,
    Expression<String>? targetId,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (weaponKey != null) 'weapon_key': weaponKey,
      if (targetId != null) 'target_id': targetId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeaponRollTargetActiveCompanion copyWith(
      {Value<int>? userId,
      Value<String>? weaponKey,
      Value<String>? targetId,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return WeaponRollTargetActiveCompanion(
      userId: userId ?? this.userId,
      weaponKey: weaponKey ?? this.weaponKey,
      targetId: targetId ?? this.targetId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (weaponKey.present) {
      map['weapon_key'] = Variable<String>(weaponKey.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeaponRollTargetActiveCompanion(')
          ..write('userId: $userId, ')
          ..write('weaponKey: $weaponKey, ')
          ..write('targetId: $targetId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogFilterCollectionsTable extends CatalogFilterCollections
    with TableInfo<$CatalogFilterCollectionsTable, CatalogFilterCollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogFilterCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
      'user_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _browseModeMeta =
      const VerificationMeta('browseMode');
  @override
  late final GeneratedColumn<String> browseMode = GeneratedColumn<String>(
      'browse_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _filtersJsonMeta =
      const VerificationMeta('filtersJson');
  @override
  late final GeneratedColumn<String> filtersJson = GeneratedColumn<String>(
      'filters_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, browseMode, name, filtersJson, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_filter_collections';
  @override
  VerificationContext validateIntegrity(
      Insertable<CatalogFilterCollectionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('browse_mode')) {
      context.handle(
          _browseModeMeta,
          browseMode.isAcceptableOrUnknown(
              data['browse_mode']!, _browseModeMeta));
    } else if (isInserting) {
      context.missing(_browseModeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('filters_json')) {
      context.handle(
          _filtersJsonMeta,
          filtersJson.isAcceptableOrUnknown(
              data['filters_json']!, _filtersJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogFilterCollectionRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogFilterCollectionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}user_id'])!,
      browseMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}browse_mode'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      filtersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filters_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CatalogFilterCollectionsTable createAlias(String alias) {
    return $CatalogFilterCollectionsTable(attachedDatabase, alias);
  }
}

class CatalogFilterCollectionRow extends DataClass
    implements Insertable<CatalogFilterCollectionRow> {
  final String id;
  final int userId;
  final String browseMode;
  final String name;
  final String filtersJson;
  final String createdAt;
  final String updatedAt;
  const CatalogFilterCollectionRow(
      {required this.id,
      required this.userId,
      required this.browseMode,
      required this.name,
      required this.filtersJson,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<int>(userId);
    map['browse_mode'] = Variable<String>(browseMode);
    map['name'] = Variable<String>(name);
    map['filters_json'] = Variable<String>(filtersJson);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CatalogFilterCollectionsCompanion toCompanion(bool nullToAbsent) {
    return CatalogFilterCollectionsCompanion(
      id: Value(id),
      userId: Value(userId),
      browseMode: Value(browseMode),
      name: Value(name),
      filtersJson: Value(filtersJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CatalogFilterCollectionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogFilterCollectionRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      browseMode: serializer.fromJson<String>(json['browseMode']),
      name: serializer.fromJson<String>(json['name']),
      filtersJson: serializer.fromJson<String>(json['filtersJson']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<int>(userId),
      'browseMode': serializer.toJson<String>(browseMode),
      'name': serializer.toJson<String>(name),
      'filtersJson': serializer.toJson<String>(filtersJson),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CatalogFilterCollectionRow copyWith(
          {String? id,
          int? userId,
          String? browseMode,
          String? name,
          String? filtersJson,
          String? createdAt,
          String? updatedAt}) =>
      CatalogFilterCollectionRow(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        browseMode: browseMode ?? this.browseMode,
        name: name ?? this.name,
        filtersJson: filtersJson ?? this.filtersJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CatalogFilterCollectionRow copyWithCompanion(
      CatalogFilterCollectionsCompanion data) {
    return CatalogFilterCollectionRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      browseMode:
          data.browseMode.present ? data.browseMode.value : this.browseMode,
      name: data.name.present ? data.name.value : this.name,
      filtersJson:
          data.filtersJson.present ? data.filtersJson.value : this.filtersJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogFilterCollectionRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('browseMode: $browseMode, ')
          ..write('name: $name, ')
          ..write('filtersJson: $filtersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, userId, browseMode, name, filtersJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogFilterCollectionRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.browseMode == this.browseMode &&
          other.name == this.name &&
          other.filtersJson == this.filtersJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CatalogFilterCollectionsCompanion
    extends UpdateCompanion<CatalogFilterCollectionRow> {
  final Value<String> id;
  final Value<int> userId;
  final Value<String> browseMode;
  final Value<String> name;
  final Value<String> filtersJson;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CatalogFilterCollectionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.browseMode = const Value.absent(),
    this.name = const Value.absent(),
    this.filtersJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogFilterCollectionsCompanion.insert({
    required String id,
    required int userId,
    required String browseMode,
    required String name,
    this.filtersJson = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        browseMode = Value(browseMode),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CatalogFilterCollectionRow> custom({
    Expression<String>? id,
    Expression<int>? userId,
    Expression<String>? browseMode,
    Expression<String>? name,
    Expression<String>? filtersJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (browseMode != null) 'browse_mode': browseMode,
      if (name != null) 'name': name,
      if (filtersJson != null) 'filters_json': filtersJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogFilterCollectionsCompanion copyWith(
      {Value<String>? id,
      Value<int>? userId,
      Value<String>? browseMode,
      Value<String>? name,
      Value<String>? filtersJson,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return CatalogFilterCollectionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      browseMode: browseMode ?? this.browseMode,
      name: name ?? this.name,
      filtersJson: filtersJson ?? this.filtersJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (browseMode.present) {
      map['browse_mode'] = Variable<String>(browseMode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (filtersJson.present) {
      map['filters_json'] = Variable<String>(filtersJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogFilterCollectionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('browseMode: $browseMode, ')
          ..write('name: $name, ')
          ..write('filtersJson: $filtersJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $InventorySyncMetaTable inventorySyncMeta =
      $InventorySyncMetaTable(this);
  late final $LoadoutsTable loadouts = $LoadoutsTable(this);
  late final $SetsTable sets = $SetsTable(this);
  late final $SetTagsTable setTags = $SetTagsTable(this);
  late final $SetItemsTable setItems = $SetItemsTable(this);
  late final $SynergiesTable synergies = $SynergiesTable(this);
  late final $SynergyLinksTable synergyLinks = $SynergyLinksTable(this);
  late final $BuildsTable builds = $BuildsTable(this);
  late final $BuildTagsTable buildTags = $BuildTagsTable(this);
  late final $BuildVariantsTable buildVariants = $BuildVariantsTable(this);
  late final $BuildSynergyTypesTable buildSynergyTypes =
      $BuildSynergyTypesTable(this);
  late final $VariantSetAttachmentsTable variantSetAttachments =
      $VariantSetAttachmentsTable(this);
  late final $WeaponRollTargetsTable weaponRollTargets =
      $WeaponRollTargetsTable(this);
  late final $WeaponRollTargetActiveTable weaponRollTargetActive =
      $WeaponRollTargetActiveTable(this);
  late final $CatalogFilterCollectionsTable catalogFilterCollections =
      $CatalogFilterCollectionsTable(this);
  late final Index idxInventoryUserHash = Index('idx_inventory_user_hash',
      'CREATE INDEX idx_inventory_user_hash ON inventory_items (user_id, item_hash)');
  late final Index idxInventoryUserBucket = Index('idx_inventory_user_bucket',
      'CREATE INDEX idx_inventory_user_bucket ON inventory_items (user_id, bucket)');
  late final Index idxInventoryUserLocation = Index(
      'idx_inventory_user_location',
      'CREATE INDEX idx_inventory_user_location ON inventory_items (user_id, location)');
  late final Index idxLoadoutsUserUpdated = Index('idx_loadouts_user_updated',
      'CREATE INDEX idx_loadouts_user_updated ON loadouts (user_id, updated_at)');
  late final Index idxSetsUserTypeName = Index('idx_sets_user_type_name',
      'CREATE UNIQUE INDEX idx_sets_user_type_name ON sets (user_id, type, name)');
  late final Index idxSetTagsTag = Index('idx_set_tags_tag',
      'CREATE INDEX idx_set_tags_tag ON set_tags (tag_id, set_id)');
  late final Index idxSetItemsSet = Index('idx_set_items_set',
      'CREATE INDEX idx_set_items_set ON set_items (set_id)');
  late final Index idxSynergyLinksSynergy = Index('idx_synergy_links_synergy',
      'CREATE INDEX idx_synergy_links_synergy ON synergy_links (synergy_id)');
  late final Index idxVariantAttachmentsSet = Index(
      'idx_variant_attachments_set',
      'CREATE INDEX idx_variant_attachments_set ON variant_set_attachments (set_id)');
  late final Index idxWeaponRollTargetsUserWeapon = Index(
      'idx_weapon_roll_targets_user_weapon',
      'CREATE INDEX idx_weapon_roll_targets_user_weapon ON weapon_roll_targets (user_id, weapon_key)');
  late final Index idxWeaponRollTargetsUserWeaponName = Index(
      'idx_weapon_roll_targets_user_weapon_name',
      'CREATE UNIQUE INDEX idx_weapon_roll_targets_user_weapon_name ON weapon_roll_targets (user_id, weapon_key, name)');
  late final Index idxCatalogFilterCollectionsUserMode = Index(
      'idx_catalog_filter_collections_user_mode',
      'CREATE INDEX idx_catalog_filter_collections_user_mode ON catalog_filter_collections (user_id, browse_mode)');
  late final Index idxCatalogFilterCollectionsUserModeName = Index(
      'idx_catalog_filter_collections_user_mode_name',
      'CREATE UNIQUE INDEX idx_catalog_filter_collections_user_mode_name ON catalog_filter_collections (user_id, browse_mode, name)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        users,
        inventoryItems,
        inventorySyncMeta,
        loadouts,
        sets,
        setTags,
        setItems,
        synergies,
        synergyLinks,
        builds,
        buildTags,
        buildVariants,
        buildSynergyTypes,
        variantSetAttachments,
        weaponRollTargets,
        weaponRollTargetActive,
        catalogFilterCollections,
        idxInventoryUserHash,
        idxInventoryUserBucket,
        idxInventoryUserLocation,
        idxLoadoutsUserUpdated,
        idxSetsUserTypeName,
        idxSetTagsTag,
        idxSetItemsSet,
        idxSynergyLinksSynergy,
        idxVariantAttachmentsSet,
        idxWeaponRollTargetsUserWeapon,
        idxWeaponRollTargetsUserWeaponName,
        idxCatalogFilterCollectionsUserMode,
        idxCatalogFilterCollectionsUserModeName
      ];
}

typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String bungieMembershipId,
  required int membershipType,
  Value<String> displayName,
  Value<String?> lastSyncAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> bungieMembershipId,
  Value<int> membershipType,
  Value<String> displayName,
  Value<String?> lastSyncAt,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bungieMembershipId => $composableBuilder(
      column: $table.bungieMembershipId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get membershipType => $composableBuilder(
      column: $table.membershipType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bungieMembershipId => $composableBuilder(
      column: $table.bungieMembershipId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get membershipType => $composableBuilder(
      column: $table.membershipType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bungieMembershipId => $composableBuilder(
      column: $table.bungieMembershipId, builder: (column) => column);

  GeneratedColumn<int> get membershipType => $composableBuilder(
      column: $table.membershipType, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get lastSyncAt => $composableBuilder(
      column: $table.lastSyncAt, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> bungieMembershipId = const Value.absent(),
            Value<int> membershipType = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String?> lastSyncAt = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            bungieMembershipId: bungieMembershipId,
            membershipType: membershipType,
            displayName: displayName,
            lastSyncAt: lastSyncAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String bungieMembershipId,
            required int membershipType,
            Value<String> displayName = const Value.absent(),
            Value<String?> lastSyncAt = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            bungieMembershipId: bungieMembershipId,
            membershipType: membershipType,
            displayName: displayName,
            lastSyncAt: lastSyncAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;
typedef $$InventoryItemsTableCreateCompanionBuilder = InventoryItemsCompanion
    Function({
  Value<int> id,
  required int userId,
  required String instanceId,
  required int itemHash,
  required String bucket,
  required String location,
  Value<String?> characterId,
  Value<int> power,
  Value<int> isMasterwork,
  Value<int> isCrafted,
  Value<String> plugHashes,
  Value<String> rollTags,
  Value<String?> statValues,
  Value<int?> gearTier,
  Value<String?> socketPlugs,
  required String syncedAt,
});
typedef $$InventoryItemsTableUpdateCompanionBuilder = InventoryItemsCompanion
    Function({
  Value<int> id,
  Value<int> userId,
  Value<String> instanceId,
  Value<int> itemHash,
  Value<String> bucket,
  Value<String> location,
  Value<String?> characterId,
  Value<int> power,
  Value<int> isMasterwork,
  Value<int> isCrafted,
  Value<String> plugHashes,
  Value<String> rollTags,
  Value<String?> statValues,
  Value<int?> gearTier,
  Value<String?> socketPlugs,
  Value<String> syncedAt,
});

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemHash => $composableBuilder(
      column: $table.itemHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bucket => $composableBuilder(
      column: $table.bucket, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isMasterwork => $composableBuilder(
      column: $table.isMasterwork, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isCrafted => $composableBuilder(
      column: $table.isCrafted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plugHashes => $composableBuilder(
      column: $table.plugHashes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rollTags => $composableBuilder(
      column: $table.rollTags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statValues => $composableBuilder(
      column: $table.statValues, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gearTier => $composableBuilder(
      column: $table.gearTier, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get socketPlugs => $composableBuilder(
      column: $table.socketPlugs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemHash => $composableBuilder(
      column: $table.itemHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bucket => $composableBuilder(
      column: $table.bucket, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isMasterwork => $composableBuilder(
      column: $table.isMasterwork,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isCrafted => $composableBuilder(
      column: $table.isCrafted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plugHashes => $composableBuilder(
      column: $table.plugHashes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rollTags => $composableBuilder(
      column: $table.rollTags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statValues => $composableBuilder(
      column: $table.statValues, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gearTier => $composableBuilder(
      column: $table.gearTier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get socketPlugs => $composableBuilder(
      column: $table.socketPlugs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => column);

  GeneratedColumn<int> get itemHash =>
      $composableBuilder(column: $table.itemHash, builder: (column) => column);

  GeneratedColumn<String> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
      column: $table.characterId, builder: (column) => column);

  GeneratedColumn<int> get power =>
      $composableBuilder(column: $table.power, builder: (column) => column);

  GeneratedColumn<int> get isMasterwork => $composableBuilder(
      column: $table.isMasterwork, builder: (column) => column);

  GeneratedColumn<int> get isCrafted =>
      $composableBuilder(column: $table.isCrafted, builder: (column) => column);

  GeneratedColumn<String> get plugHashes => $composableBuilder(
      column: $table.plugHashes, builder: (column) => column);

  GeneratedColumn<String> get rollTags =>
      $composableBuilder(column: $table.rollTags, builder: (column) => column);

  GeneratedColumn<String> get statValues => $composableBuilder(
      column: $table.statValues, builder: (column) => column);

  GeneratedColumn<int> get gearTier =>
      $composableBuilder(column: $table.gearTier, builder: (column) => column);

  GeneratedColumn<String> get socketPlugs => $composableBuilder(
      column: $table.socketPlugs, builder: (column) => column);

  GeneratedColumn<String> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$InventoryItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryItemsTable,
    InventoryItem,
    $$InventoryItemsTableFilterComposer,
    $$InventoryItemsTableOrderingComposer,
    $$InventoryItemsTableAnnotationComposer,
    $$InventoryItemsTableCreateCompanionBuilder,
    $$InventoryItemsTableUpdateCompanionBuilder,
    (
      InventoryItem,
      BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem>
    ),
    InventoryItem,
    PrefetchHooks Function()> {
  $$InventoryItemsTableTableManager(
      _$AppDatabase db, $InventoryItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> instanceId = const Value.absent(),
            Value<int> itemHash = const Value.absent(),
            Value<String> bucket = const Value.absent(),
            Value<String> location = const Value.absent(),
            Value<String?> characterId = const Value.absent(),
            Value<int> power = const Value.absent(),
            Value<int> isMasterwork = const Value.absent(),
            Value<int> isCrafted = const Value.absent(),
            Value<String> plugHashes = const Value.absent(),
            Value<String> rollTags = const Value.absent(),
            Value<String?> statValues = const Value.absent(),
            Value<int?> gearTier = const Value.absent(),
            Value<String?> socketPlugs = const Value.absent(),
            Value<String> syncedAt = const Value.absent(),
          }) =>
              InventoryItemsCompanion(
            id: id,
            userId: userId,
            instanceId: instanceId,
            itemHash: itemHash,
            bucket: bucket,
            location: location,
            characterId: characterId,
            power: power,
            isMasterwork: isMasterwork,
            isCrafted: isCrafted,
            plugHashes: plugHashes,
            rollTags: rollTags,
            statValues: statValues,
            gearTier: gearTier,
            socketPlugs: socketPlugs,
            syncedAt: syncedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int userId,
            required String instanceId,
            required int itemHash,
            required String bucket,
            required String location,
            Value<String?> characterId = const Value.absent(),
            Value<int> power = const Value.absent(),
            Value<int> isMasterwork = const Value.absent(),
            Value<int> isCrafted = const Value.absent(),
            Value<String> plugHashes = const Value.absent(),
            Value<String> rollTags = const Value.absent(),
            Value<String?> statValues = const Value.absent(),
            Value<int?> gearTier = const Value.absent(),
            Value<String?> socketPlugs = const Value.absent(),
            required String syncedAt,
          }) =>
              InventoryItemsCompanion.insert(
            id: id,
            userId: userId,
            instanceId: instanceId,
            itemHash: itemHash,
            bucket: bucket,
            location: location,
            characterId: characterId,
            power: power,
            isMasterwork: isMasterwork,
            isCrafted: isCrafted,
            plugHashes: plugHashes,
            rollTags: rollTags,
            statValues: statValues,
            gearTier: gearTier,
            socketPlugs: socketPlugs,
            syncedAt: syncedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventoryItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventoryItemsTable,
    InventoryItem,
    $$InventoryItemsTableFilterComposer,
    $$InventoryItemsTableOrderingComposer,
    $$InventoryItemsTableAnnotationComposer,
    $$InventoryItemsTableCreateCompanionBuilder,
    $$InventoryItemsTableUpdateCompanionBuilder,
    (
      InventoryItem,
      BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItem>
    ),
    InventoryItem,
    PrefetchHooks Function()>;
typedef $$InventorySyncMetaTableCreateCompanionBuilder
    = InventorySyncMetaCompanion Function({
  Value<int> userId,
  Value<int> itemCount,
  Value<int> syncVersion,
  Value<String?> lastFullSyncAt,
});
typedef $$InventorySyncMetaTableUpdateCompanionBuilder
    = InventorySyncMetaCompanion Function({
  Value<int> userId,
  Value<int> itemCount,
  Value<int> syncVersion,
  Value<String?> lastFullSyncAt,
});

class $$InventorySyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $InventorySyncMetaTable> {
  $$InventorySyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemCount => $composableBuilder(
      column: $table.itemCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastFullSyncAt => $composableBuilder(
      column: $table.lastFullSyncAt,
      builder: (column) => ColumnFilters(column));
}

class $$InventorySyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $InventorySyncMetaTable> {
  $$InventorySyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemCount => $composableBuilder(
      column: $table.itemCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastFullSyncAt => $composableBuilder(
      column: $table.lastFullSyncAt,
      builder: (column) => ColumnOrderings(column));
}

class $$InventorySyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventorySyncMetaTable> {
  $$InventorySyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<int> get syncVersion => $composableBuilder(
      column: $table.syncVersion, builder: (column) => column);

  GeneratedColumn<String> get lastFullSyncAt => $composableBuilder(
      column: $table.lastFullSyncAt, builder: (column) => column);
}

class $$InventorySyncMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventorySyncMetaTable,
    InventorySyncMetaData,
    $$InventorySyncMetaTableFilterComposer,
    $$InventorySyncMetaTableOrderingComposer,
    $$InventorySyncMetaTableAnnotationComposer,
    $$InventorySyncMetaTableCreateCompanionBuilder,
    $$InventorySyncMetaTableUpdateCompanionBuilder,
    (
      InventorySyncMetaData,
      BaseReferences<_$AppDatabase, $InventorySyncMetaTable,
          InventorySyncMetaData>
    ),
    InventorySyncMetaData,
    PrefetchHooks Function()> {
  $$InventorySyncMetaTableTableManager(
      _$AppDatabase db, $InventorySyncMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventorySyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventorySyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventorySyncMetaTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            Value<int> itemCount = const Value.absent(),
            Value<int> syncVersion = const Value.absent(),
            Value<String?> lastFullSyncAt = const Value.absent(),
          }) =>
              InventorySyncMetaCompanion(
            userId: userId,
            itemCount: itemCount,
            syncVersion: syncVersion,
            lastFullSyncAt: lastFullSyncAt,
          ),
          createCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            Value<int> itemCount = const Value.absent(),
            Value<int> syncVersion = const Value.absent(),
            Value<String?> lastFullSyncAt = const Value.absent(),
          }) =>
              InventorySyncMetaCompanion.insert(
            userId: userId,
            itemCount: itemCount,
            syncVersion: syncVersion,
            lastFullSyncAt: lastFullSyncAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InventorySyncMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InventorySyncMetaTable,
    InventorySyncMetaData,
    $$InventorySyncMetaTableFilterComposer,
    $$InventorySyncMetaTableOrderingComposer,
    $$InventorySyncMetaTableAnnotationComposer,
    $$InventorySyncMetaTableCreateCompanionBuilder,
    $$InventorySyncMetaTableUpdateCompanionBuilder,
    (
      InventorySyncMetaData,
      BaseReferences<_$AppDatabase, $InventorySyncMetaTable,
          InventorySyncMetaData>
    ),
    InventorySyncMetaData,
    PrefetchHooks Function()>;
typedef $$LoadoutsTableCreateCompanionBuilder = LoadoutsCompanion Function({
  required String id,
  required int userId,
  required String name,
  required String source,
  required String manifestVersion,
  Value<String?> buildRequest,
  required String generatedBuild,
  required String resolvedSheet,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$LoadoutsTableUpdateCompanionBuilder = LoadoutsCompanion Function({
  Value<String> id,
  Value<int> userId,
  Value<String> name,
  Value<String> source,
  Value<String> manifestVersion,
  Value<String?> buildRequest,
  Value<String> generatedBuild,
  Value<String> resolvedSheet,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$LoadoutsTableFilterComposer
    extends Composer<_$AppDatabase, $LoadoutsTable> {
  $$LoadoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get manifestVersion => $composableBuilder(
      column: $table.manifestVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get buildRequest => $composableBuilder(
      column: $table.buildRequest, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generatedBuild => $composableBuilder(
      column: $table.generatedBuild,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resolvedSheet => $composableBuilder(
      column: $table.resolvedSheet, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$LoadoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $LoadoutsTable> {
  $$LoadoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get manifestVersion => $composableBuilder(
      column: $table.manifestVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get buildRequest => $composableBuilder(
      column: $table.buildRequest,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generatedBuild => $composableBuilder(
      column: $table.generatedBuild,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resolvedSheet => $composableBuilder(
      column: $table.resolvedSheet,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LoadoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoadoutsTable> {
  $$LoadoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get manifestVersion => $composableBuilder(
      column: $table.manifestVersion, builder: (column) => column);

  GeneratedColumn<String> get buildRequest => $composableBuilder(
      column: $table.buildRequest, builder: (column) => column);

  GeneratedColumn<String> get generatedBuild => $composableBuilder(
      column: $table.generatedBuild, builder: (column) => column);

  GeneratedColumn<String> get resolvedSheet => $composableBuilder(
      column: $table.resolvedSheet, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LoadoutsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LoadoutsTable,
    Loadout,
    $$LoadoutsTableFilterComposer,
    $$LoadoutsTableOrderingComposer,
    $$LoadoutsTableAnnotationComposer,
    $$LoadoutsTableCreateCompanionBuilder,
    $$LoadoutsTableUpdateCompanionBuilder,
    (Loadout, BaseReferences<_$AppDatabase, $LoadoutsTable, Loadout>),
    Loadout,
    PrefetchHooks Function()> {
  $$LoadoutsTableTableManager(_$AppDatabase db, $LoadoutsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoadoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoadoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoadoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> manifestVersion = const Value.absent(),
            Value<String?> buildRequest = const Value.absent(),
            Value<String> generatedBuild = const Value.absent(),
            Value<String> resolvedSheet = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LoadoutsCompanion(
            id: id,
            userId: userId,
            name: name,
            source: source,
            manifestVersion: manifestVersion,
            buildRequest: buildRequest,
            generatedBuild: generatedBuild,
            resolvedSheet: resolvedSheet,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int userId,
            required String name,
            required String source,
            required String manifestVersion,
            Value<String?> buildRequest = const Value.absent(),
            required String generatedBuild,
            required String resolvedSheet,
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LoadoutsCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            source: source,
            manifestVersion: manifestVersion,
            buildRequest: buildRequest,
            generatedBuild: generatedBuild,
            resolvedSheet: resolvedSheet,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LoadoutsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LoadoutsTable,
    Loadout,
    $$LoadoutsTableFilterComposer,
    $$LoadoutsTableOrderingComposer,
    $$LoadoutsTableAnnotationComposer,
    $$LoadoutsTableCreateCompanionBuilder,
    $$LoadoutsTableUpdateCompanionBuilder,
    (Loadout, BaseReferences<_$AppDatabase, $LoadoutsTable, Loadout>),
    Loadout,
    PrefetchHooks Function()>;
typedef $$SetsTableCreateCompanionBuilder = SetsCompanion Function({
  required String id,
  required int userId,
  required String name,
  required String type,
  Value<String?> optimizerConstraints,
  Value<String?> linkedModSetId,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$SetsTableUpdateCompanionBuilder = SetsCompanion Function({
  Value<String> id,
  Value<int> userId,
  Value<String> name,
  Value<String> type,
  Value<String?> optimizerConstraints,
  Value<String?> linkedModSetId,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$SetsTableFilterComposer extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optimizerConstraints => $composableBuilder(
      column: $table.optimizerConstraints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkedModSetId => $composableBuilder(
      column: $table.linkedModSetId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SetsTableOrderingComposer extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optimizerConstraints => $composableBuilder(
      column: $table.optimizerConstraints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkedModSetId => $composableBuilder(
      column: $table.linkedModSetId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get optimizerConstraints => $composableBuilder(
      column: $table.optimizerConstraints, builder: (column) => column);

  GeneratedColumn<String> get linkedModSetId => $composableBuilder(
      column: $table.linkedModSetId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SetsTable,
    LibrarySet,
    $$SetsTableFilterComposer,
    $$SetsTableOrderingComposer,
    $$SetsTableAnnotationComposer,
    $$SetsTableCreateCompanionBuilder,
    $$SetsTableUpdateCompanionBuilder,
    (LibrarySet, BaseReferences<_$AppDatabase, $SetsTable, LibrarySet>),
    LibrarySet,
    PrefetchHooks Function()> {
  $$SetsTableTableManager(_$AppDatabase db, $SetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> optimizerConstraints = const Value.absent(),
            Value<String?> linkedModSetId = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SetsCompanion(
            id: id,
            userId: userId,
            name: name,
            type: type,
            optimizerConstraints: optimizerConstraints,
            linkedModSetId: linkedModSetId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int userId,
            required String name,
            required String type,
            Value<String?> optimizerConstraints = const Value.absent(),
            Value<String?> linkedModSetId = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SetsCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            type: type,
            optimizerConstraints: optimizerConstraints,
            linkedModSetId: linkedModSetId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SetsTable,
    LibrarySet,
    $$SetsTableFilterComposer,
    $$SetsTableOrderingComposer,
    $$SetsTableAnnotationComposer,
    $$SetsTableCreateCompanionBuilder,
    $$SetsTableUpdateCompanionBuilder,
    (LibrarySet, BaseReferences<_$AppDatabase, $SetsTable, LibrarySet>),
    LibrarySet,
    PrefetchHooks Function()>;
typedef $$SetTagsTableCreateCompanionBuilder = SetTagsCompanion Function({
  required String setId,
  required String tagId,
  Value<int> rowid,
});
typedef $$SetTagsTableUpdateCompanionBuilder = SetTagsCompanion Function({
  Value<String> setId,
  Value<String> tagId,
  Value<int> rowid,
});

class $$SetTagsTableFilterComposer
    extends Composer<_$AppDatabase, $SetTagsTable> {
  $$SetTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get setId => $composableBuilder(
      column: $table.setId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnFilters(column));
}

class $$SetTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetTagsTable> {
  $$SetTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get setId => $composableBuilder(
      column: $table.setId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnOrderings(column));
}

class $$SetTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetTagsTable> {
  $$SetTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$SetTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SetTagsTable,
    SetTag,
    $$SetTagsTableFilterComposer,
    $$SetTagsTableOrderingComposer,
    $$SetTagsTableAnnotationComposer,
    $$SetTagsTableCreateCompanionBuilder,
    $$SetTagsTableUpdateCompanionBuilder,
    (SetTag, BaseReferences<_$AppDatabase, $SetTagsTable, SetTag>),
    SetTag,
    PrefetchHooks Function()> {
  $$SetTagsTableTableManager(_$AppDatabase db, $SetTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> setId = const Value.absent(),
            Value<String> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SetTagsCompanion(
            setId: setId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String setId,
            required String tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              SetTagsCompanion.insert(
            setId: setId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SetTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SetTagsTable,
    SetTag,
    $$SetTagsTableFilterComposer,
    $$SetTagsTableOrderingComposer,
    $$SetTagsTableAnnotationComposer,
    $$SetTagsTableCreateCompanionBuilder,
    $$SetTagsTableUpdateCompanionBuilder,
    (SetTag, BaseReferences<_$AppDatabase, $SetTagsTable, SetTag>),
    SetTag,
    PrefetchHooks Function()>;
typedef $$SetItemsTableCreateCompanionBuilder = SetItemsCompanion Function({
  required String id,
  required String setId,
  required String slot,
  required int itemHash,
  required String itemName,
  Value<String> selectedPerks,
  Value<int?> masterworkHash,
  Value<String?> modHashes,
  Value<String?> instanceId,
  Value<int> sortOrder,
  Value<String?> removedAt,
  Value<int> rowid,
});
typedef $$SetItemsTableUpdateCompanionBuilder = SetItemsCompanion Function({
  Value<String> id,
  Value<String> setId,
  Value<String> slot,
  Value<int> itemHash,
  Value<String> itemName,
  Value<String> selectedPerks,
  Value<int?> masterworkHash,
  Value<String?> modHashes,
  Value<String?> instanceId,
  Value<int> sortOrder,
  Value<String?> removedAt,
  Value<int> rowid,
});

class $$SetItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SetItemsTable> {
  $$SetItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get setId => $composableBuilder(
      column: $table.setId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemHash => $composableBuilder(
      column: $table.itemHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectedPerks => $composableBuilder(
      column: $table.selectedPerks, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get masterworkHash => $composableBuilder(
      column: $table.masterworkHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modHashes => $composableBuilder(
      column: $table.modHashes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get removedAt => $composableBuilder(
      column: $table.removedAt, builder: (column) => ColumnFilters(column));
}

class $$SetItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetItemsTable> {
  $$SetItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get setId => $composableBuilder(
      column: $table.setId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slot => $composableBuilder(
      column: $table.slot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemHash => $composableBuilder(
      column: $table.itemHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemName => $composableBuilder(
      column: $table.itemName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectedPerks => $composableBuilder(
      column: $table.selectedPerks,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get masterworkHash => $composableBuilder(
      column: $table.masterworkHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modHashes => $composableBuilder(
      column: $table.modHashes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get removedAt => $composableBuilder(
      column: $table.removedAt, builder: (column) => ColumnOrderings(column));
}

class $$SetItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetItemsTable> {
  $$SetItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get itemHash =>
      $composableBuilder(column: $table.itemHash, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get selectedPerks => $composableBuilder(
      column: $table.selectedPerks, builder: (column) => column);

  GeneratedColumn<int> get masterworkHash => $composableBuilder(
      column: $table.masterworkHash, builder: (column) => column);

  GeneratedColumn<String> get modHashes =>
      $composableBuilder(column: $table.modHashes, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
      column: $table.instanceId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => column);
}

class $$SetItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SetItemsTable,
    SetItem,
    $$SetItemsTableFilterComposer,
    $$SetItemsTableOrderingComposer,
    $$SetItemsTableAnnotationComposer,
    $$SetItemsTableCreateCompanionBuilder,
    $$SetItemsTableUpdateCompanionBuilder,
    (SetItem, BaseReferences<_$AppDatabase, $SetItemsTable, SetItem>),
    SetItem,
    PrefetchHooks Function()> {
  $$SetItemsTableTableManager(_$AppDatabase db, $SetItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> setId = const Value.absent(),
            Value<String> slot = const Value.absent(),
            Value<int> itemHash = const Value.absent(),
            Value<String> itemName = const Value.absent(),
            Value<String> selectedPerks = const Value.absent(),
            Value<int?> masterworkHash = const Value.absent(),
            Value<String?> modHashes = const Value.absent(),
            Value<String?> instanceId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> removedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SetItemsCompanion(
            id: id,
            setId: setId,
            slot: slot,
            itemHash: itemHash,
            itemName: itemName,
            selectedPerks: selectedPerks,
            masterworkHash: masterworkHash,
            modHashes: modHashes,
            instanceId: instanceId,
            sortOrder: sortOrder,
            removedAt: removedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String setId,
            required String slot,
            required int itemHash,
            required String itemName,
            Value<String> selectedPerks = const Value.absent(),
            Value<int?> masterworkHash = const Value.absent(),
            Value<String?> modHashes = const Value.absent(),
            Value<String?> instanceId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> removedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SetItemsCompanion.insert(
            id: id,
            setId: setId,
            slot: slot,
            itemHash: itemHash,
            itemName: itemName,
            selectedPerks: selectedPerks,
            masterworkHash: masterworkHash,
            modHashes: modHashes,
            instanceId: instanceId,
            sortOrder: sortOrder,
            removedAt: removedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SetItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SetItemsTable,
    SetItem,
    $$SetItemsTableFilterComposer,
    $$SetItemsTableOrderingComposer,
    $$SetItemsTableAnnotationComposer,
    $$SetItemsTableCreateCompanionBuilder,
    $$SetItemsTableUpdateCompanionBuilder,
    (SetItem, BaseReferences<_$AppDatabase, $SetItemsTable, SetItem>),
    SetItem,
    PrefetchHooks Function()>;
typedef $$SynergiesTableCreateCompanionBuilder = SynergiesCompanion Function({
  required String id,
  required int userId,
  required String name,
  required String type,
  Value<String?> subType,
  Value<String> description,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$SynergiesTableUpdateCompanionBuilder = SynergiesCompanion Function({
  Value<String> id,
  Value<int> userId,
  Value<String> name,
  Value<String> type,
  Value<String?> subType,
  Value<String> description,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$SynergiesTableFilterComposer
    extends Composer<_$AppDatabase, $SynergiesTable> {
  $$SynergiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subType => $composableBuilder(
      column: $table.subType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SynergiesTableOrderingComposer
    extends Composer<_$AppDatabase, $SynergiesTable> {
  $$SynergiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subType => $composableBuilder(
      column: $table.subType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SynergiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SynergiesTable> {
  $$SynergiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subType =>
      $composableBuilder(column: $table.subType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SynergiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SynergiesTable,
    Synergy,
    $$SynergiesTableFilterComposer,
    $$SynergiesTableOrderingComposer,
    $$SynergiesTableAnnotationComposer,
    $$SynergiesTableCreateCompanionBuilder,
    $$SynergiesTableUpdateCompanionBuilder,
    (Synergy, BaseReferences<_$AppDatabase, $SynergiesTable, Synergy>),
    Synergy,
    PrefetchHooks Function()> {
  $$SynergiesTableTableManager(_$AppDatabase db, $SynergiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SynergiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SynergiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SynergiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> subType = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SynergiesCompanion(
            id: id,
            userId: userId,
            name: name,
            type: type,
            subType: subType,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int userId,
            required String name,
            required String type,
            Value<String?> subType = const Value.absent(),
            Value<String> description = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SynergiesCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            type: type,
            subType: subType,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SynergiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SynergiesTable,
    Synergy,
    $$SynergiesTableFilterComposer,
    $$SynergiesTableOrderingComposer,
    $$SynergiesTableAnnotationComposer,
    $$SynergiesTableCreateCompanionBuilder,
    $$SynergiesTableUpdateCompanionBuilder,
    (Synergy, BaseReferences<_$AppDatabase, $SynergiesTable, Synergy>),
    Synergy,
    PrefetchHooks Function()>;
typedef $$SynergyLinksTableCreateCompanionBuilder = SynergyLinksCompanion
    Function({
  required String id,
  required String synergyId,
  required String kind,
  required String displayName,
  Value<int?> itemHash,
  Value<int?> perkHash,
  Value<int?> parentItemHash,
  Value<String?> originTraitName,
  Value<int?> originTraitHash,
  Value<String?> armorSetName,
  Value<int?> bonusPieces,
  Value<String?> bonusName,
  Value<int?> armorSetHash,
  Value<int> required,
  Value<int> rowid,
});
typedef $$SynergyLinksTableUpdateCompanionBuilder = SynergyLinksCompanion
    Function({
  Value<String> id,
  Value<String> synergyId,
  Value<String> kind,
  Value<String> displayName,
  Value<int?> itemHash,
  Value<int?> perkHash,
  Value<int?> parentItemHash,
  Value<String?> originTraitName,
  Value<int?> originTraitHash,
  Value<String?> armorSetName,
  Value<int?> bonusPieces,
  Value<String?> bonusName,
  Value<int?> armorSetHash,
  Value<int> required,
  Value<int> rowid,
});

class $$SynergyLinksTableFilterComposer
    extends Composer<_$AppDatabase, $SynergyLinksTable> {
  $$SynergyLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get synergyId => $composableBuilder(
      column: $table.synergyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemHash => $composableBuilder(
      column: $table.itemHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get perkHash => $composableBuilder(
      column: $table.perkHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parentItemHash => $composableBuilder(
      column: $table.parentItemHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originTraitName => $composableBuilder(
      column: $table.originTraitName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get originTraitHash => $composableBuilder(
      column: $table.originTraitHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get armorSetName => $composableBuilder(
      column: $table.armorSetName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bonusPieces => $composableBuilder(
      column: $table.bonusPieces, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bonusName => $composableBuilder(
      column: $table.bonusName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get armorSetHash => $composableBuilder(
      column: $table.armorSetHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get required => $composableBuilder(
      column: $table.required, builder: (column) => ColumnFilters(column));
}

class $$SynergyLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $SynergyLinksTable> {
  $$SynergyLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get synergyId => $composableBuilder(
      column: $table.synergyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemHash => $composableBuilder(
      column: $table.itemHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get perkHash => $composableBuilder(
      column: $table.perkHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parentItemHash => $composableBuilder(
      column: $table.parentItemHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originTraitName => $composableBuilder(
      column: $table.originTraitName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get originTraitHash => $composableBuilder(
      column: $table.originTraitHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get armorSetName => $composableBuilder(
      column: $table.armorSetName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bonusPieces => $composableBuilder(
      column: $table.bonusPieces, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bonusName => $composableBuilder(
      column: $table.bonusName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get armorSetHash => $composableBuilder(
      column: $table.armorSetHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get required => $composableBuilder(
      column: $table.required, builder: (column) => ColumnOrderings(column));
}

class $$SynergyLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SynergyLinksTable> {
  $$SynergyLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get synergyId =>
      $composableBuilder(column: $table.synergyId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<int> get itemHash =>
      $composableBuilder(column: $table.itemHash, builder: (column) => column);

  GeneratedColumn<int> get perkHash =>
      $composableBuilder(column: $table.perkHash, builder: (column) => column);

  GeneratedColumn<int> get parentItemHash => $composableBuilder(
      column: $table.parentItemHash, builder: (column) => column);

  GeneratedColumn<String> get originTraitName => $composableBuilder(
      column: $table.originTraitName, builder: (column) => column);

  GeneratedColumn<int> get originTraitHash => $composableBuilder(
      column: $table.originTraitHash, builder: (column) => column);

  GeneratedColumn<String> get armorSetName => $composableBuilder(
      column: $table.armorSetName, builder: (column) => column);

  GeneratedColumn<int> get bonusPieces => $composableBuilder(
      column: $table.bonusPieces, builder: (column) => column);

  GeneratedColumn<String> get bonusName =>
      $composableBuilder(column: $table.bonusName, builder: (column) => column);

  GeneratedColumn<int> get armorSetHash => $composableBuilder(
      column: $table.armorSetHash, builder: (column) => column);

  GeneratedColumn<int> get required =>
      $composableBuilder(column: $table.required, builder: (column) => column);
}

class $$SynergyLinksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SynergyLinksTable,
    SynergyLink,
    $$SynergyLinksTableFilterComposer,
    $$SynergyLinksTableOrderingComposer,
    $$SynergyLinksTableAnnotationComposer,
    $$SynergyLinksTableCreateCompanionBuilder,
    $$SynergyLinksTableUpdateCompanionBuilder,
    (
      SynergyLink,
      BaseReferences<_$AppDatabase, $SynergyLinksTable, SynergyLink>
    ),
    SynergyLink,
    PrefetchHooks Function()> {
  $$SynergyLinksTableTableManager(_$AppDatabase db, $SynergyLinksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SynergyLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SynergyLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SynergyLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> synergyId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<int?> itemHash = const Value.absent(),
            Value<int?> perkHash = const Value.absent(),
            Value<int?> parentItemHash = const Value.absent(),
            Value<String?> originTraitName = const Value.absent(),
            Value<int?> originTraitHash = const Value.absent(),
            Value<String?> armorSetName = const Value.absent(),
            Value<int?> bonusPieces = const Value.absent(),
            Value<String?> bonusName = const Value.absent(),
            Value<int?> armorSetHash = const Value.absent(),
            Value<int> required = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SynergyLinksCompanion(
            id: id,
            synergyId: synergyId,
            kind: kind,
            displayName: displayName,
            itemHash: itemHash,
            perkHash: perkHash,
            parentItemHash: parentItemHash,
            originTraitName: originTraitName,
            originTraitHash: originTraitHash,
            armorSetName: armorSetName,
            bonusPieces: bonusPieces,
            bonusName: bonusName,
            armorSetHash: armorSetHash,
            required: required,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String synergyId,
            required String kind,
            required String displayName,
            Value<int?> itemHash = const Value.absent(),
            Value<int?> perkHash = const Value.absent(),
            Value<int?> parentItemHash = const Value.absent(),
            Value<String?> originTraitName = const Value.absent(),
            Value<int?> originTraitHash = const Value.absent(),
            Value<String?> armorSetName = const Value.absent(),
            Value<int?> bonusPieces = const Value.absent(),
            Value<String?> bonusName = const Value.absent(),
            Value<int?> armorSetHash = const Value.absent(),
            Value<int> required = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SynergyLinksCompanion.insert(
            id: id,
            synergyId: synergyId,
            kind: kind,
            displayName: displayName,
            itemHash: itemHash,
            perkHash: perkHash,
            parentItemHash: parentItemHash,
            originTraitName: originTraitName,
            originTraitHash: originTraitHash,
            armorSetName: armorSetName,
            bonusPieces: bonusPieces,
            bonusName: bonusName,
            armorSetHash: armorSetHash,
            required: required,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SynergyLinksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SynergyLinksTable,
    SynergyLink,
    $$SynergyLinksTableFilterComposer,
    $$SynergyLinksTableOrderingComposer,
    $$SynergyLinksTableAnnotationComposer,
    $$SynergyLinksTableCreateCompanionBuilder,
    $$SynergyLinksTableUpdateCompanionBuilder,
    (
      SynergyLink,
      BaseReferences<_$AppDatabase, $SynergyLinksTable, SynergyLink>
    ),
    SynergyLink,
    PrefetchHooks Function()>;
typedef $$BuildsTableCreateCompanionBuilder = BuildsCompanion Function({
  required String id,
  required int userId,
  required String name,
  required String className,
  required String subclass,
  Value<int?> exoticArmorHash,
  Value<String?> exoticArmorName,
  Value<int?> exoticWeaponHash,
  Value<String?> exoticWeaponName,
  Value<String?> pinnedSuper,
  Value<String?> softStatTargets,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$BuildsTableUpdateCompanionBuilder = BuildsCompanion Function({
  Value<String> id,
  Value<int> userId,
  Value<String> name,
  Value<String> className,
  Value<String> subclass,
  Value<int?> exoticArmorHash,
  Value<String?> exoticArmorName,
  Value<int?> exoticWeaponHash,
  Value<String?> exoticWeaponName,
  Value<String?> pinnedSuper,
  Value<String?> softStatTargets,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$BuildsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildsTable> {
  $$BuildsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get className => $composableBuilder(
      column: $table.className, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subclass => $composableBuilder(
      column: $table.subclass, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get exoticArmorHash => $composableBuilder(
      column: $table.exoticArmorHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exoticArmorName => $composableBuilder(
      column: $table.exoticArmorName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get exoticWeaponHash => $composableBuilder(
      column: $table.exoticWeaponHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exoticWeaponName => $composableBuilder(
      column: $table.exoticWeaponName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pinnedSuper => $composableBuilder(
      column: $table.pinnedSuper, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get softStatTargets => $composableBuilder(
      column: $table.softStatTargets,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BuildsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildsTable> {
  $$BuildsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get className => $composableBuilder(
      column: $table.className, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subclass => $composableBuilder(
      column: $table.subclass, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get exoticArmorHash => $composableBuilder(
      column: $table.exoticArmorHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exoticArmorName => $composableBuilder(
      column: $table.exoticArmorName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get exoticWeaponHash => $composableBuilder(
      column: $table.exoticWeaponHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exoticWeaponName => $composableBuilder(
      column: $table.exoticWeaponName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pinnedSuper => $composableBuilder(
      column: $table.pinnedSuper, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get softStatTargets => $composableBuilder(
      column: $table.softStatTargets,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BuildsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildsTable> {
  $$BuildsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get className =>
      $composableBuilder(column: $table.className, builder: (column) => column);

  GeneratedColumn<String> get subclass =>
      $composableBuilder(column: $table.subclass, builder: (column) => column);

  GeneratedColumn<int> get exoticArmorHash => $composableBuilder(
      column: $table.exoticArmorHash, builder: (column) => column);

  GeneratedColumn<String> get exoticArmorName => $composableBuilder(
      column: $table.exoticArmorName, builder: (column) => column);

  GeneratedColumn<int> get exoticWeaponHash => $composableBuilder(
      column: $table.exoticWeaponHash, builder: (column) => column);

  GeneratedColumn<String> get exoticWeaponName => $composableBuilder(
      column: $table.exoticWeaponName, builder: (column) => column);

  GeneratedColumn<String> get pinnedSuper => $composableBuilder(
      column: $table.pinnedSuper, builder: (column) => column);

  GeneratedColumn<String> get softStatTargets => $composableBuilder(
      column: $table.softStatTargets, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BuildsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BuildsTable,
    Build,
    $$BuildsTableFilterComposer,
    $$BuildsTableOrderingComposer,
    $$BuildsTableAnnotationComposer,
    $$BuildsTableCreateCompanionBuilder,
    $$BuildsTableUpdateCompanionBuilder,
    (Build, BaseReferences<_$AppDatabase, $BuildsTable, Build>),
    Build,
    PrefetchHooks Function()> {
  $$BuildsTableTableManager(_$AppDatabase db, $BuildsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> className = const Value.absent(),
            Value<String> subclass = const Value.absent(),
            Value<int?> exoticArmorHash = const Value.absent(),
            Value<String?> exoticArmorName = const Value.absent(),
            Value<int?> exoticWeaponHash = const Value.absent(),
            Value<String?> exoticWeaponName = const Value.absent(),
            Value<String?> pinnedSuper = const Value.absent(),
            Value<String?> softStatTargets = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BuildsCompanion(
            id: id,
            userId: userId,
            name: name,
            className: className,
            subclass: subclass,
            exoticArmorHash: exoticArmorHash,
            exoticArmorName: exoticArmorName,
            exoticWeaponHash: exoticWeaponHash,
            exoticWeaponName: exoticWeaponName,
            pinnedSuper: pinnedSuper,
            softStatTargets: softStatTargets,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int userId,
            required String name,
            required String className,
            required String subclass,
            Value<int?> exoticArmorHash = const Value.absent(),
            Value<String?> exoticArmorName = const Value.absent(),
            Value<int?> exoticWeaponHash = const Value.absent(),
            Value<String?> exoticWeaponName = const Value.absent(),
            Value<String?> pinnedSuper = const Value.absent(),
            Value<String?> softStatTargets = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BuildsCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            className: className,
            subclass: subclass,
            exoticArmorHash: exoticArmorHash,
            exoticArmorName: exoticArmorName,
            exoticWeaponHash: exoticWeaponHash,
            exoticWeaponName: exoticWeaponName,
            pinnedSuper: pinnedSuper,
            softStatTargets: softStatTargets,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BuildsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BuildsTable,
    Build,
    $$BuildsTableFilterComposer,
    $$BuildsTableOrderingComposer,
    $$BuildsTableAnnotationComposer,
    $$BuildsTableCreateCompanionBuilder,
    $$BuildsTableUpdateCompanionBuilder,
    (Build, BaseReferences<_$AppDatabase, $BuildsTable, Build>),
    Build,
    PrefetchHooks Function()>;
typedef $$BuildTagsTableCreateCompanionBuilder = BuildTagsCompanion Function({
  required String buildId,
  required String tagId,
  Value<int> rowid,
});
typedef $$BuildTagsTableUpdateCompanionBuilder = BuildTagsCompanion Function({
  Value<String> buildId,
  Value<String> tagId,
  Value<int> rowid,
});

class $$BuildTagsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildTagsTable> {
  $$BuildTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get buildId => $composableBuilder(
      column: $table.buildId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnFilters(column));
}

class $$BuildTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildTagsTable> {
  $$BuildTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get buildId => $composableBuilder(
      column: $table.buildId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagId => $composableBuilder(
      column: $table.tagId, builder: (column) => ColumnOrderings(column));
}

class $$BuildTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildTagsTable> {
  $$BuildTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get buildId =>
      $composableBuilder(column: $table.buildId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$BuildTagsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BuildTagsTable,
    BuildTag,
    $$BuildTagsTableFilterComposer,
    $$BuildTagsTableOrderingComposer,
    $$BuildTagsTableAnnotationComposer,
    $$BuildTagsTableCreateCompanionBuilder,
    $$BuildTagsTableUpdateCompanionBuilder,
    (BuildTag, BaseReferences<_$AppDatabase, $BuildTagsTable, BuildTag>),
    BuildTag,
    PrefetchHooks Function()> {
  $$BuildTagsTableTableManager(_$AppDatabase db, $BuildTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> buildId = const Value.absent(),
            Value<String> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BuildTagsCompanion(
            buildId: buildId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String buildId,
            required String tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              BuildTagsCompanion.insert(
            buildId: buildId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BuildTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BuildTagsTable,
    BuildTag,
    $$BuildTagsTableFilterComposer,
    $$BuildTagsTableOrderingComposer,
    $$BuildTagsTableAnnotationComposer,
    $$BuildTagsTableCreateCompanionBuilder,
    $$BuildTagsTableUpdateCompanionBuilder,
    (BuildTag, BaseReferences<_$AppDatabase, $BuildTagsTable, BuildTag>),
    BuildTag,
    PrefetchHooks Function()>;
typedef $$BuildVariantsTableCreateCompanionBuilder = BuildVariantsCompanion
    Function({
  required String id,
  required String buildId,
  required String name,
  Value<int> isDefault,
  Value<int?> exoticWeaponHash,
  Value<String?> exoticWeaponName,
  Value<int?> artifactHash,
  Value<String?> artifactName,
  Value<String> artifactConfig,
  Value<String> subclassKit,
  Value<String?> notes,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$BuildVariantsTableUpdateCompanionBuilder = BuildVariantsCompanion
    Function({
  Value<String> id,
  Value<String> buildId,
  Value<String> name,
  Value<int> isDefault,
  Value<int?> exoticWeaponHash,
  Value<String?> exoticWeaponName,
  Value<int?> artifactHash,
  Value<String?> artifactName,
  Value<String> artifactConfig,
  Value<String> subclassKit,
  Value<String?> notes,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$BuildVariantsTableFilterComposer
    extends Composer<_$AppDatabase, $BuildVariantsTable> {
  $$BuildVariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get buildId => $composableBuilder(
      column: $table.buildId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get exoticWeaponHash => $composableBuilder(
      column: $table.exoticWeaponHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exoticWeaponName => $composableBuilder(
      column: $table.exoticWeaponName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get artifactHash => $composableBuilder(
      column: $table.artifactHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artifactName => $composableBuilder(
      column: $table.artifactName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artifactConfig => $composableBuilder(
      column: $table.artifactConfig,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subclassKit => $composableBuilder(
      column: $table.subclassKit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BuildVariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildVariantsTable> {
  $$BuildVariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get buildId => $composableBuilder(
      column: $table.buildId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isDefault => $composableBuilder(
      column: $table.isDefault, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get exoticWeaponHash => $composableBuilder(
      column: $table.exoticWeaponHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exoticWeaponName => $composableBuilder(
      column: $table.exoticWeaponName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get artifactHash => $composableBuilder(
      column: $table.artifactHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artifactName => $composableBuilder(
      column: $table.artifactName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artifactConfig => $composableBuilder(
      column: $table.artifactConfig,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subclassKit => $composableBuilder(
      column: $table.subclassKit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BuildVariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildVariantsTable> {
  $$BuildVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get buildId =>
      $composableBuilder(column: $table.buildId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get exoticWeaponHash => $composableBuilder(
      column: $table.exoticWeaponHash, builder: (column) => column);

  GeneratedColumn<String> get exoticWeaponName => $composableBuilder(
      column: $table.exoticWeaponName, builder: (column) => column);

  GeneratedColumn<int> get artifactHash => $composableBuilder(
      column: $table.artifactHash, builder: (column) => column);

  GeneratedColumn<String> get artifactName => $composableBuilder(
      column: $table.artifactName, builder: (column) => column);

  GeneratedColumn<String> get artifactConfig => $composableBuilder(
      column: $table.artifactConfig, builder: (column) => column);

  GeneratedColumn<String> get subclassKit => $composableBuilder(
      column: $table.subclassKit, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BuildVariantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BuildVariantsTable,
    BuildVariant,
    $$BuildVariantsTableFilterComposer,
    $$BuildVariantsTableOrderingComposer,
    $$BuildVariantsTableAnnotationComposer,
    $$BuildVariantsTableCreateCompanionBuilder,
    $$BuildVariantsTableUpdateCompanionBuilder,
    (
      BuildVariant,
      BaseReferences<_$AppDatabase, $BuildVariantsTable, BuildVariant>
    ),
    BuildVariant,
    PrefetchHooks Function()> {
  $$BuildVariantsTableTableManager(_$AppDatabase db, $BuildVariantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> buildId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> isDefault = const Value.absent(),
            Value<int?> exoticWeaponHash = const Value.absent(),
            Value<String?> exoticWeaponName = const Value.absent(),
            Value<int?> artifactHash = const Value.absent(),
            Value<String?> artifactName = const Value.absent(),
            Value<String> artifactConfig = const Value.absent(),
            Value<String> subclassKit = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BuildVariantsCompanion(
            id: id,
            buildId: buildId,
            name: name,
            isDefault: isDefault,
            exoticWeaponHash: exoticWeaponHash,
            exoticWeaponName: exoticWeaponName,
            artifactHash: artifactHash,
            artifactName: artifactName,
            artifactConfig: artifactConfig,
            subclassKit: subclassKit,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String buildId,
            required String name,
            Value<int> isDefault = const Value.absent(),
            Value<int?> exoticWeaponHash = const Value.absent(),
            Value<String?> exoticWeaponName = const Value.absent(),
            Value<int?> artifactHash = const Value.absent(),
            Value<String?> artifactName = const Value.absent(),
            Value<String> artifactConfig = const Value.absent(),
            Value<String> subclassKit = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BuildVariantsCompanion.insert(
            id: id,
            buildId: buildId,
            name: name,
            isDefault: isDefault,
            exoticWeaponHash: exoticWeaponHash,
            exoticWeaponName: exoticWeaponName,
            artifactHash: artifactHash,
            artifactName: artifactName,
            artifactConfig: artifactConfig,
            subclassKit: subclassKit,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BuildVariantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BuildVariantsTable,
    BuildVariant,
    $$BuildVariantsTableFilterComposer,
    $$BuildVariantsTableOrderingComposer,
    $$BuildVariantsTableAnnotationComposer,
    $$BuildVariantsTableCreateCompanionBuilder,
    $$BuildVariantsTableUpdateCompanionBuilder,
    (
      BuildVariant,
      BaseReferences<_$AppDatabase, $BuildVariantsTable, BuildVariant>
    ),
    BuildVariant,
    PrefetchHooks Function()>;
typedef $$BuildSynergyTypesTableCreateCompanionBuilder
    = BuildSynergyTypesCompanion Function({
  required String buildId,
  required String type,
  Value<String?> subType,
  required String attachedAt,
  Value<int> rowid,
});
typedef $$BuildSynergyTypesTableUpdateCompanionBuilder
    = BuildSynergyTypesCompanion Function({
  Value<String> buildId,
  Value<String> type,
  Value<String?> subType,
  Value<String> attachedAt,
  Value<int> rowid,
});

class $$BuildSynergyTypesTableFilterComposer
    extends Composer<_$AppDatabase, $BuildSynergyTypesTable> {
  $$BuildSynergyTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get buildId => $composableBuilder(
      column: $table.buildId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subType => $composableBuilder(
      column: $table.subType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachedAt => $composableBuilder(
      column: $table.attachedAt, builder: (column) => ColumnFilters(column));
}

class $$BuildSynergyTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $BuildSynergyTypesTable> {
  $$BuildSynergyTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get buildId => $composableBuilder(
      column: $table.buildId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subType => $composableBuilder(
      column: $table.subType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachedAt => $composableBuilder(
      column: $table.attachedAt, builder: (column) => ColumnOrderings(column));
}

class $$BuildSynergyTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BuildSynergyTypesTable> {
  $$BuildSynergyTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get buildId =>
      $composableBuilder(column: $table.buildId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subType =>
      $composableBuilder(column: $table.subType, builder: (column) => column);

  GeneratedColumn<String> get attachedAt => $composableBuilder(
      column: $table.attachedAt, builder: (column) => column);
}

class $$BuildSynergyTypesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BuildSynergyTypesTable,
    BuildSynergyType,
    $$BuildSynergyTypesTableFilterComposer,
    $$BuildSynergyTypesTableOrderingComposer,
    $$BuildSynergyTypesTableAnnotationComposer,
    $$BuildSynergyTypesTableCreateCompanionBuilder,
    $$BuildSynergyTypesTableUpdateCompanionBuilder,
    (
      BuildSynergyType,
      BaseReferences<_$AppDatabase, $BuildSynergyTypesTable, BuildSynergyType>
    ),
    BuildSynergyType,
    PrefetchHooks Function()> {
  $$BuildSynergyTypesTableTableManager(
      _$AppDatabase db, $BuildSynergyTypesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildSynergyTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildSynergyTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildSynergyTypesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> buildId = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> subType = const Value.absent(),
            Value<String> attachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BuildSynergyTypesCompanion(
            buildId: buildId,
            type: type,
            subType: subType,
            attachedAt: attachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String buildId,
            required String type,
            Value<String?> subType = const Value.absent(),
            required String attachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BuildSynergyTypesCompanion.insert(
            buildId: buildId,
            type: type,
            subType: subType,
            attachedAt: attachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BuildSynergyTypesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BuildSynergyTypesTable,
    BuildSynergyType,
    $$BuildSynergyTypesTableFilterComposer,
    $$BuildSynergyTypesTableOrderingComposer,
    $$BuildSynergyTypesTableAnnotationComposer,
    $$BuildSynergyTypesTableCreateCompanionBuilder,
    $$BuildSynergyTypesTableUpdateCompanionBuilder,
    (
      BuildSynergyType,
      BaseReferences<_$AppDatabase, $BuildSynergyTypesTable, BuildSynergyType>
    ),
    BuildSynergyType,
    PrefetchHooks Function()>;
typedef $$VariantSetAttachmentsTableCreateCompanionBuilder
    = VariantSetAttachmentsCompanion Function({
  required String id,
  required String variantId,
  required String setId,
  required String mode,
  Value<String?> snapshotConfigs,
  required String attachedAt,
  Value<int> rowid,
});
typedef $$VariantSetAttachmentsTableUpdateCompanionBuilder
    = VariantSetAttachmentsCompanion Function({
  Value<String> id,
  Value<String> variantId,
  Value<String> setId,
  Value<String> mode,
  Value<String?> snapshotConfigs,
  Value<String> attachedAt,
  Value<int> rowid,
});

class $$VariantSetAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $VariantSetAttachmentsTable> {
  $$VariantSetAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get variantId => $composableBuilder(
      column: $table.variantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get setId => $composableBuilder(
      column: $table.setId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get snapshotConfigs => $composableBuilder(
      column: $table.snapshotConfigs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachedAt => $composableBuilder(
      column: $table.attachedAt, builder: (column) => ColumnFilters(column));
}

class $$VariantSetAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $VariantSetAttachmentsTable> {
  $$VariantSetAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get variantId => $composableBuilder(
      column: $table.variantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get setId => $composableBuilder(
      column: $table.setId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get snapshotConfigs => $composableBuilder(
      column: $table.snapshotConfigs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachedAt => $composableBuilder(
      column: $table.attachedAt, builder: (column) => ColumnOrderings(column));
}

class $$VariantSetAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VariantSetAttachmentsTable> {
  $$VariantSetAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get snapshotConfigs => $composableBuilder(
      column: $table.snapshotConfigs, builder: (column) => column);

  GeneratedColumn<String> get attachedAt => $composableBuilder(
      column: $table.attachedAt, builder: (column) => column);
}

class $$VariantSetAttachmentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VariantSetAttachmentsTable,
    VariantSetAttachment,
    $$VariantSetAttachmentsTableFilterComposer,
    $$VariantSetAttachmentsTableOrderingComposer,
    $$VariantSetAttachmentsTableAnnotationComposer,
    $$VariantSetAttachmentsTableCreateCompanionBuilder,
    $$VariantSetAttachmentsTableUpdateCompanionBuilder,
    (
      VariantSetAttachment,
      BaseReferences<_$AppDatabase, $VariantSetAttachmentsTable,
          VariantSetAttachment>
    ),
    VariantSetAttachment,
    PrefetchHooks Function()> {
  $$VariantSetAttachmentsTableTableManager(
      _$AppDatabase db, $VariantSetAttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VariantSetAttachmentsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$VariantSetAttachmentsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VariantSetAttachmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> variantId = const Value.absent(),
            Value<String> setId = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<String?> snapshotConfigs = const Value.absent(),
            Value<String> attachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VariantSetAttachmentsCompanion(
            id: id,
            variantId: variantId,
            setId: setId,
            mode: mode,
            snapshotConfigs: snapshotConfigs,
            attachedAt: attachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String variantId,
            required String setId,
            required String mode,
            Value<String?> snapshotConfigs = const Value.absent(),
            required String attachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VariantSetAttachmentsCompanion.insert(
            id: id,
            variantId: variantId,
            setId: setId,
            mode: mode,
            snapshotConfigs: snapshotConfigs,
            attachedAt: attachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VariantSetAttachmentsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $VariantSetAttachmentsTable,
        VariantSetAttachment,
        $$VariantSetAttachmentsTableFilterComposer,
        $$VariantSetAttachmentsTableOrderingComposer,
        $$VariantSetAttachmentsTableAnnotationComposer,
        $$VariantSetAttachmentsTableCreateCompanionBuilder,
        $$VariantSetAttachmentsTableUpdateCompanionBuilder,
        (
          VariantSetAttachment,
          BaseReferences<_$AppDatabase, $VariantSetAttachmentsTable,
              VariantSetAttachment>
        ),
        VariantSetAttachment,
        PrefetchHooks Function()>;
typedef $$WeaponRollTargetsTableCreateCompanionBuilder
    = WeaponRollTargetsCompanion Function({
  required String id,
  required int userId,
  required String weaponKey,
  required String name,
  Value<String> columnsJson,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$WeaponRollTargetsTableUpdateCompanionBuilder
    = WeaponRollTargetsCompanion Function({
  Value<String> id,
  Value<int> userId,
  Value<String> weaponKey,
  Value<String> name,
  Value<String> columnsJson,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$WeaponRollTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $WeaponRollTargetsTable> {
  $$WeaponRollTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weaponKey => $composableBuilder(
      column: $table.weaponKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get columnsJson => $composableBuilder(
      column: $table.columnsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WeaponRollTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeaponRollTargetsTable> {
  $$WeaponRollTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weaponKey => $composableBuilder(
      column: $table.weaponKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get columnsJson => $composableBuilder(
      column: $table.columnsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WeaponRollTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeaponRollTargetsTable> {
  $$WeaponRollTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get weaponKey =>
      $composableBuilder(column: $table.weaponKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get columnsJson => $composableBuilder(
      column: $table.columnsJson, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WeaponRollTargetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeaponRollTargetsTable,
    WeaponRollTargetRow,
    $$WeaponRollTargetsTableFilterComposer,
    $$WeaponRollTargetsTableOrderingComposer,
    $$WeaponRollTargetsTableAnnotationComposer,
    $$WeaponRollTargetsTableCreateCompanionBuilder,
    $$WeaponRollTargetsTableUpdateCompanionBuilder,
    (
      WeaponRollTargetRow,
      BaseReferences<_$AppDatabase, $WeaponRollTargetsTable,
          WeaponRollTargetRow>
    ),
    WeaponRollTargetRow,
    PrefetchHooks Function()> {
  $$WeaponRollTargetsTableTableManager(
      _$AppDatabase db, $WeaponRollTargetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponRollTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponRollTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeaponRollTargetsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> weaponKey = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> columnsJson = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WeaponRollTargetsCompanion(
            id: id,
            userId: userId,
            weaponKey: weaponKey,
            name: name,
            columnsJson: columnsJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int userId,
            required String weaponKey,
            required String name,
            Value<String> columnsJson = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WeaponRollTargetsCompanion.insert(
            id: id,
            userId: userId,
            weaponKey: weaponKey,
            name: name,
            columnsJson: columnsJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeaponRollTargetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WeaponRollTargetsTable,
    WeaponRollTargetRow,
    $$WeaponRollTargetsTableFilterComposer,
    $$WeaponRollTargetsTableOrderingComposer,
    $$WeaponRollTargetsTableAnnotationComposer,
    $$WeaponRollTargetsTableCreateCompanionBuilder,
    $$WeaponRollTargetsTableUpdateCompanionBuilder,
    (
      WeaponRollTargetRow,
      BaseReferences<_$AppDatabase, $WeaponRollTargetsTable,
          WeaponRollTargetRow>
    ),
    WeaponRollTargetRow,
    PrefetchHooks Function()>;
typedef $$WeaponRollTargetActiveTableCreateCompanionBuilder
    = WeaponRollTargetActiveCompanion Function({
  required int userId,
  required String weaponKey,
  required String targetId,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$WeaponRollTargetActiveTableUpdateCompanionBuilder
    = WeaponRollTargetActiveCompanion Function({
  Value<int> userId,
  Value<String> weaponKey,
  Value<String> targetId,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$WeaponRollTargetActiveTableFilterComposer
    extends Composer<_$AppDatabase, $WeaponRollTargetActiveTable> {
  $$WeaponRollTargetActiveTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weaponKey => $composableBuilder(
      column: $table.weaponKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetId => $composableBuilder(
      column: $table.targetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$WeaponRollTargetActiveTableOrderingComposer
    extends Composer<_$AppDatabase, $WeaponRollTargetActiveTable> {
  $$WeaponRollTargetActiveTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weaponKey => $composableBuilder(
      column: $table.weaponKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetId => $composableBuilder(
      column: $table.targetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$WeaponRollTargetActiveTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeaponRollTargetActiveTable> {
  $$WeaponRollTargetActiveTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get weaponKey =>
      $composableBuilder(column: $table.weaponKey, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WeaponRollTargetActiveTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WeaponRollTargetActiveTable,
    WeaponRollTargetActiveRow,
    $$WeaponRollTargetActiveTableFilterComposer,
    $$WeaponRollTargetActiveTableOrderingComposer,
    $$WeaponRollTargetActiveTableAnnotationComposer,
    $$WeaponRollTargetActiveTableCreateCompanionBuilder,
    $$WeaponRollTargetActiveTableUpdateCompanionBuilder,
    (
      WeaponRollTargetActiveRow,
      BaseReferences<_$AppDatabase, $WeaponRollTargetActiveTable,
          WeaponRollTargetActiveRow>
    ),
    WeaponRollTargetActiveRow,
    PrefetchHooks Function()> {
  $$WeaponRollTargetActiveTableTableManager(
      _$AppDatabase db, $WeaponRollTargetActiveTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeaponRollTargetActiveTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$WeaponRollTargetActiveTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeaponRollTargetActiveTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> userId = const Value.absent(),
            Value<String> weaponKey = const Value.absent(),
            Value<String> targetId = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WeaponRollTargetActiveCompanion(
            userId: userId,
            weaponKey: weaponKey,
            targetId: targetId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int userId,
            required String weaponKey,
            required String targetId,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WeaponRollTargetActiveCompanion.insert(
            userId: userId,
            weaponKey: weaponKey,
            targetId: targetId,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WeaponRollTargetActiveTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $WeaponRollTargetActiveTable,
        WeaponRollTargetActiveRow,
        $$WeaponRollTargetActiveTableFilterComposer,
        $$WeaponRollTargetActiveTableOrderingComposer,
        $$WeaponRollTargetActiveTableAnnotationComposer,
        $$WeaponRollTargetActiveTableCreateCompanionBuilder,
        $$WeaponRollTargetActiveTableUpdateCompanionBuilder,
        (
          WeaponRollTargetActiveRow,
          BaseReferences<_$AppDatabase, $WeaponRollTargetActiveTable,
              WeaponRollTargetActiveRow>
        ),
        WeaponRollTargetActiveRow,
        PrefetchHooks Function()>;
typedef $$CatalogFilterCollectionsTableCreateCompanionBuilder
    = CatalogFilterCollectionsCompanion Function({
  required String id,
  required int userId,
  required String browseMode,
  required String name,
  Value<String> filtersJson,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$CatalogFilterCollectionsTableUpdateCompanionBuilder
    = CatalogFilterCollectionsCompanion Function({
  Value<String> id,
  Value<int> userId,
  Value<String> browseMode,
  Value<String> name,
  Value<String> filtersJson,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $$CatalogFilterCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogFilterCollectionsTable> {
  $$CatalogFilterCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get browseMode => $composableBuilder(
      column: $table.browseMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filtersJson => $composableBuilder(
      column: $table.filtersJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CatalogFilterCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogFilterCollectionsTable> {
  $$CatalogFilterCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get browseMode => $composableBuilder(
      column: $table.browseMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filtersJson => $composableBuilder(
      column: $table.filtersJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CatalogFilterCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogFilterCollectionsTable> {
  $$CatalogFilterCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get browseMode => $composableBuilder(
      column: $table.browseMode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get filtersJson => $composableBuilder(
      column: $table.filtersJson, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CatalogFilterCollectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CatalogFilterCollectionsTable,
    CatalogFilterCollectionRow,
    $$CatalogFilterCollectionsTableFilterComposer,
    $$CatalogFilterCollectionsTableOrderingComposer,
    $$CatalogFilterCollectionsTableAnnotationComposer,
    $$CatalogFilterCollectionsTableCreateCompanionBuilder,
    $$CatalogFilterCollectionsTableUpdateCompanionBuilder,
    (
      CatalogFilterCollectionRow,
      BaseReferences<_$AppDatabase, $CatalogFilterCollectionsTable,
          CatalogFilterCollectionRow>
    ),
    CatalogFilterCollectionRow,
    PrefetchHooks Function()> {
  $$CatalogFilterCollectionsTableTableManager(
      _$AppDatabase db, $CatalogFilterCollectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogFilterCollectionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogFilterCollectionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogFilterCollectionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> userId = const Value.absent(),
            Value<String> browseMode = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> filtersJson = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CatalogFilterCollectionsCompanion(
            id: id,
            userId: userId,
            browseMode: browseMode,
            name: name,
            filtersJson: filtersJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int userId,
            required String browseMode,
            required String name,
            Value<String> filtersJson = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CatalogFilterCollectionsCompanion.insert(
            id: id,
            userId: userId,
            browseMode: browseMode,
            name: name,
            filtersJson: filtersJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CatalogFilterCollectionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CatalogFilterCollectionsTable,
        CatalogFilterCollectionRow,
        $$CatalogFilterCollectionsTableFilterComposer,
        $$CatalogFilterCollectionsTableOrderingComposer,
        $$CatalogFilterCollectionsTableAnnotationComposer,
        $$CatalogFilterCollectionsTableCreateCompanionBuilder,
        $$CatalogFilterCollectionsTableUpdateCompanionBuilder,
        (
          CatalogFilterCollectionRow,
          BaseReferences<_$AppDatabase, $CatalogFilterCollectionsTable,
              CatalogFilterCollectionRow>
        ),
        CatalogFilterCollectionRow,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$InventorySyncMetaTableTableManager get inventorySyncMeta =>
      $$InventorySyncMetaTableTableManager(_db, _db.inventorySyncMeta);
  $$LoadoutsTableTableManager get loadouts =>
      $$LoadoutsTableTableManager(_db, _db.loadouts);
  $$SetsTableTableManager get sets => $$SetsTableTableManager(_db, _db.sets);
  $$SetTagsTableTableManager get setTags =>
      $$SetTagsTableTableManager(_db, _db.setTags);
  $$SetItemsTableTableManager get setItems =>
      $$SetItemsTableTableManager(_db, _db.setItems);
  $$SynergiesTableTableManager get synergies =>
      $$SynergiesTableTableManager(_db, _db.synergies);
  $$SynergyLinksTableTableManager get synergyLinks =>
      $$SynergyLinksTableTableManager(_db, _db.synergyLinks);
  $$BuildsTableTableManager get builds =>
      $$BuildsTableTableManager(_db, _db.builds);
  $$BuildTagsTableTableManager get buildTags =>
      $$BuildTagsTableTableManager(_db, _db.buildTags);
  $$BuildVariantsTableTableManager get buildVariants =>
      $$BuildVariantsTableTableManager(_db, _db.buildVariants);
  $$BuildSynergyTypesTableTableManager get buildSynergyTypes =>
      $$BuildSynergyTypesTableTableManager(_db, _db.buildSynergyTypes);
  $$VariantSetAttachmentsTableTableManager get variantSetAttachments =>
      $$VariantSetAttachmentsTableTableManager(_db, _db.variantSetAttachments);
  $$WeaponRollTargetsTableTableManager get weaponRollTargets =>
      $$WeaponRollTargetsTableTableManager(_db, _db.weaponRollTargets);
  $$WeaponRollTargetActiveTableTableManager get weaponRollTargetActive =>
      $$WeaponRollTargetActiveTableTableManager(
          _db, _db.weaponRollTargetActive);
  $$CatalogFilterCollectionsTableTableManager get catalogFilterCollections =>
      $$CatalogFilterCollectionsTableTableManager(
          _db, _db.catalogFilterCollections);
}
