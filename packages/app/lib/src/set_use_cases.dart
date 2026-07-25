import 'package:destiny2_db/destiny2_db.dart' hide SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:drift/drift.dart' show Value;

import 'clock_ids.dart';
import 'errors.dart';
import 'mappers.dart';

/// Set row + items + attachment usage for library detail.
class SetDetail {
  const SetDetail({
    required this.set,
    this.items = const [],
    this.activeItems = const [],
    this.usedBy = const [],
  });

  final SetRecord set;
  final List<SetItemRecord> items;
  final List<SetItemRecord> activeItems;
  final List<SetAttachmentRef> usedBy;

  GearSet get domain => gearSetFromRecord(set);
}

/// Create input for a library set.
class CreateSetCommand {
  const CreateSetCommand({
    this.id,
    required this.name,
    required this.type,
    this.tagIds = const [],
    this.optimizerConstraints,
    this.linkedModSetId,
  });

  final String? id;
  final String name;
  final SetType type;
  final List<String> tagIds;
  final String? optimizerConstraints;
  final String? linkedModSetId;
}

/// Partial update for a library set.
///
/// Use [setOptimizerConstraints] / [setLinkedModSetId] when you need to write
/// null or a new value; leave them absent to keep existing.
class UpdateSetCommand {
  const UpdateSetCommand({
    this.name,
    this.type,
    this.tagIds,
    this.setOptimizerConstraints = false,
    this.optimizerConstraints,
    this.setLinkedModSetId = false,
    this.linkedModSetId,
  });

  final String? name;
  final SetType? type;
  final List<String>? tagIds;
  final bool setOptimizerConstraints;
  final String? optimizerConstraints;
  final bool setLinkedModSetId;
  final String? linkedModSetId;
}

/// Input for persistence-level set item upsert (no hard domain kit gates).
class UpsertSetItemCommand {
  const UpsertSetItemCommand({
    this.id,
    required this.slot,
    required this.itemHash,
    required this.itemName,
    this.instanceId,
    this.selectedPerks = const [],
    this.masterworkHash,
    this.modHashes,
    this.sortOrder = 0,
    this.replaceExisting = true,
  });

  final String? id;
  final String slot;
  final int itemHash;
  final String itemName;
  final String? instanceId;
  final List<int> selectedPerks;
  final int? masterworkHash;
  final List<int>? modHashes;
  final int sortOrder;
  final bool replaceExisting;
}

String _requireNonEmptyName(String name) {
  final t = name.trim();
  if (t.isEmpty) {
    throw UseCaseException(
      UseCaseErrorCode.invalidArgument,
      'Set name must not be empty',
    );
  }
  return t;
}

SetType parseSetTypeWire(String wire) {
  final t = SetType.tryParse(wire);
  if (t == null) {
    throw UseCaseException(
      UseCaseErrorCode.invalidSetType,
      'Unknown set type: $wire',
      details: {'type': wire},
    );
  }
  return t;
}

/// List sets for [userId], optional type filter.
Future<List<SetRecord>> listUserSets(
  AppDatabase db,
  int userId, {
  SetType? type,
}) {
  return listSets(db, userId, type: type?.wireName);
}

/// Get set detail with items + attachment refs; null if missing.
Future<SetDetail?> getSetDetail(
  AppDatabase db,
  int userId,
  String setId,
) async {
  final set = await getSet(db, userId, setId);
  if (set == null) return null;
  final items = await listSetItems(db, setId);
  final active = await listActiveSetItems(db, setId);
  final usedBy = await findAttachmentsBySetId(db, setId);
  return SetDetail(
    set: set,
    items: items,
    activeItems: active,
    usedBy: usedBy,
  );
}

/// Create a user set; throws on duplicate name or invalid name.
Future<SetDetail> createUserSet(
  AppDatabase db,
  int userId,
  CreateSetCommand command, {
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
}) async {
  final name = _requireNonEmptyName(command.name);
  final typeWire = command.type.wireName;

  if (await findDuplicateSetName(
    db,
    userId,
    type: typeWire,
    name: name,
  )) {
    throw UseCaseException(
      UseCaseErrorCode.duplicateSetName,
      'Set name already in use for this type',
      details: {'type': typeWire, 'name': name},
    );
  }

  final id = command.id ?? newId();
  final ts = now();
  await createSetRecord(
    db,
    userId,
    id: id,
    name: name,
    type: typeWire,
    tagIds: command.tagIds,
    optimizerConstraints: command.optimizerConstraints,
    linkedModSetId: command.linkedModSetId,
    now: ts,
  );
  return (await getSetDetail(db, userId, id))!;
}

/// Update a user set; null if not found.
Future<SetDetail?> updateUserSet(
  AppDatabase db,
  int userId,
  String setId,
  UpdateSetCommand command, {
  NowClock now = defaultNow,
}) async {
  final existing = await getSet(db, userId, setId);
  if (existing == null) return null;

  final nextName =
      command.name != null ? _requireNonEmptyName(command.name!) : existing.name;
  final nextType = command.type?.wireName ?? existing.type;

  if (await findDuplicateSetName(
    db,
    userId,
    type: nextType,
    name: nextName,
    excludeId: setId,
  )) {
    throw UseCaseException(
      UseCaseErrorCode.duplicateSetName,
      'Set name already in use for this type',
      details: {'type': nextType, 'name': nextName},
    );
  }

  final ts = now();
  await updateSetRecord(
    db,
    userId,
    setId,
    name: command.name != null ? nextName : null,
    type: command.type?.wireName,
    tagIds: command.tagIds,
    optimizerConstraints: command.setOptimizerConstraints
        ? Value(command.optimizerConstraints)
        : const Value.absent(),
    linkedModSetId: command.setLinkedModSetId
        ? Value(command.linkedModSetId)
        : const Value.absent(),
    now: ts,
  );
  return getSetDetail(db, userId, setId);
}

/// Delete set; returns false if missing. Throws [UseCaseException] if in use.
Future<bool> deleteUserSet(
  AppDatabase db,
  int userId,
  String setId,
) async {
  final existing = await getSet(db, userId, setId);
  if (existing == null) return false;
  try {
    return await deleteSetRecord(db, userId, setId);
  } on SetInUseException catch (e) {
    throw UseCaseException(
      UseCaseErrorCode.setInUse,
      'Set is attached to build variants',
      details: {
        'setId': e.setId,
        'buildIds': e.attachments.map((a) => a.buildId).toSet().toList(),
        'variantIds': e.attachments.map((a) => a.variantId).toList(),
      },
    );
  }
}

/// Upsert set item if set owned by user; null if set missing.
Future<SetDetail?> upsertUserSetItem(
  AppDatabase db,
  int userId,
  String setId,
  UpsertSetItemCommand command, {
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
}) async {
  final set = await getSet(db, userId, setId);
  if (set == null) return null;
  final slot = command.slot.trim();
  if (slot.isEmpty) {
    throw UseCaseException(
      UseCaseErrorCode.invalidArgument,
      'Set item slot must not be empty',
    );
  }
  final itemName = command.itemName.trim();
  if (itemName.isEmpty) {
    throw UseCaseException(
      UseCaseErrorCode.invalidArgument,
      'Set item name must not be empty',
    );
  }
  final ts = now();
  await upsertSetItemRecord(
    db,
    id: command.id ?? newId(),
    setId: setId,
    slot: slot,
    itemHash: command.itemHash,
    itemName: itemName,
    instanceId: command.instanceId,
    selectedPerks: command.selectedPerks,
    masterworkHash: command.masterworkHash,
    modHashes: command.modHashes,
    sortOrder: command.sortOrder,
    replaceExisting: command.replaceExisting,
    now: ts,
  );
  return getSetDetail(db, userId, setId);
}

/// Soft-remove set item if set owned; null if set missing.
Future<SetDetail?> removeUserSetItem(
  AppDatabase db,
  int userId,
  String setId,
  String itemId, {
  NowClock now = defaultNow,
}) async {
  final set = await getSet(db, userId, setId);
  if (set == null) return null;
  await softRemoveSetItem(
    db,
    setId: setId,
    itemId: itemId,
    now: now(),
  );
  return getSetDetail(db, userId, setId);
}
