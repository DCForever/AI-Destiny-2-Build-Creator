import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:drift/drift.dart' show Value;

import 'clock_ids.dart';
import 'errors.dart';
import 'set_use_cases.dart';

/// Owned instance identity for optional materialize/apply validation.
class OwnedInstanceRef {
  const OwnedInstanceRef({
    required this.itemHash,
    required this.isExotic,
  });

  final int itemHash;
  final bool isExotic;
}

/// instanceId → ownership (when provided, all pieces must match).
typedef MaterializeOwnership = Map<String, OwnedInstanceRef>;

/// One armor piece to write onto a set (confirm path only).
class MaterializePiece {
  const MaterializePiece({
    required this.slot,
    required this.itemHash,
    required this.instanceId,
    this.itemName,
  });

  final EquipmentSlot slot;
  final int itemHash;
  final String instanceId;
  final String? itemName;

  CombinationPieceInput get asInput => CombinationPieceInput(
        slot: slot,
        itemHash: itemHash,
        instanceId: instanceId,
      );
}

/// Confirm-only: create a **new** armor set from an optimizer combination.
class MaterializeArmorCommand {
  const MaterializeArmorCommand({
    required this.pieces,
    required this.armorSetName,
    this.optimizerConstraintsJson,
    this.id,
  });

  final List<MaterializePiece> pieces;
  final String armorSetName;

  /// Serialized Armor Set optimizer constraints (opaque JSON string).
  final String? optimizerConstraintsJson;
  final String? id;
}

/// Confirm-only: apply combination onto an **existing** armor set id.
class ApplyArmorCombinationCommand {
  const ApplyArmorCombinationCommand({
    required this.setId,
    required this.pieces,
  });

  final String setId;
  final List<MaterializePiece> pieces;
}

/// Result of materialize.
class MaterializeArmorResult {
  const MaterializeArmorResult({required this.armorSet});

  final SetDetail armorSet;
}

/// Result of apply-in-place.
class ApplyArmorCombinationResult {
  const ApplyArmorCombinationResult({
    required this.armorSet,
    required this.itemsUpdated,
  });

  final SetDetail armorSet;
  final bool itemsUpdated;
}

void _validatePiecesOrThrow(List<MaterializePiece> pieces) {
  final inputs = pieces.map((p) => p.asInput).toList();
  final err = validateCombinationPieces(inputs);
  if (err != null) {
    throw UseCaseException(
      UseCaseErrorCode.invalidCombination,
      err,
      details: {
        'slots': pieces.map((p) => p.slot.wireName).toList(),
      },
    );
  }
  for (final p in pieces) {
    if (p.instanceId.trim().isEmpty) {
      throw UseCaseException(
        UseCaseErrorCode.invalidArgument,
        'Instance id is required for each armor piece',
      );
    }
  }
}

void _validateOwnershipOrThrow(
  List<MaterializePiece> pieces,
  MaterializeOwnership? ownership,
) {
  if (ownership == null) return;
  var exotics = 0;
  for (final piece in pieces) {
    final owned = ownership[piece.instanceId];
    if (owned == null || owned.itemHash != piece.itemHash) {
      throw UseCaseException(
        UseCaseErrorCode.instanceNotOwned,
        'Instance ${piece.instanceId} is not owned',
        details: {'instanceId': piece.instanceId},
      );
    }
    if (owned.isExotic) exotics += 1;
  }
  if (exotics > 1) {
    throw UseCaseException(
      UseCaseErrorCode.exoticLimit,
      'A kit may hold at most one exotic',
    );
  }
}

String _uniqueArmorSetName(
  // checked asynchronously by caller via findDuplicateSetName
  String preferred,
) {
  final t = preferred.trim();
  if (t.isEmpty) {
    throw UseCaseException(
      UseCaseErrorCode.invalidArgument,
      'Armor set name must not be empty',
    );
  }
  return t;
}

Future<String> _allocateUniqueSetName(
  AppDatabase db,
  int userId,
  String type,
  String preferred,
) async {
  final base = _uniqueArmorSetName(preferred);
  if (!await findDuplicateSetName(db, userId, type: type, name: base)) {
    return base;
  }
  for (var i = 2; i < 1000; i++) {
    final candidate = '$base ($i)';
    if (!await findDuplicateSetName(db, userId, type: type, name: candidate)) {
      return candidate;
    }
  }
  throw UseCaseException(
    UseCaseErrorCode.duplicateSetName,
    'Could not allocate unique set name',
    details: {'name': base},
  );
}

/// Create a new armor set from a user-confirmed combination.
///
/// **Confirm-only**: call only after the user accepts a suggestion. Optimize
/// runners never invoke this.
Future<MaterializeArmorResult> materializeArmorCombination(
  AppDatabase db,
  int userId,
  MaterializeArmorCommand command, {
  MaterializeOwnership? ownership,
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
}) async {
  _validatePiecesOrThrow(command.pieces);
  _validateOwnershipOrThrow(command.pieces, ownership);

  final name = await _allocateUniqueSetName(
    db,
    userId,
    SetType.armor.wireName,
    command.armorSetName,
  );
  final setId = command.id ?? newId();
  final ts = now();

  await createSetRecord(
    db,
    userId,
    id: setId,
    name: name,
    type: SetType.armor.wireName,
    tagIds: const [],
    optimizerConstraints: command.optimizerConstraintsJson,
    now: ts,
  );

  var order = 0;
  for (final piece in command.pieces) {
    await upsertSetItemRecord(
      db,
      id: newId(),
      setId: setId,
      slot: piece.slot.wireName,
      itemHash: piece.itemHash,
      itemName: piece.itemName?.trim().isNotEmpty == true
          ? piece.itemName!.trim()
          : 'Armor ${piece.itemHash}',
      instanceId: piece.instanceId,
      sortOrder: order++,
      replaceExisting: true,
      now: ts,
    );
  }

  final detail = await getSetDetail(db, userId, setId);
  return MaterializeArmorResult(armorSet: detail!);
}

/// Apply a user-confirmed combination onto an existing armor set (same id).
///
/// Stored optimizer constraints are left untouched. Confirm-only.
Future<ApplyArmorCombinationResult> applyArmorCombinationInPlace(
  AppDatabase db,
  int userId,
  ApplyArmorCombinationCommand command, {
  MaterializeOwnership? ownership,
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
}) async {
  final set = await getSet(db, userId, command.setId);
  if (set == null || set.type != SetType.armor.wireName) {
    throw UseCaseException(
      UseCaseErrorCode.notFound,
      'Armor set not found',
      details: {'setId': command.setId},
    );
  }

  _validatePiecesOrThrow(command.pieces);
  _validateOwnershipOrThrow(command.pieces, ownership);

  final current = await listActiveSetItems(db, command.setId);
  final bySlot = {
    for (final item in current) item.slot: item.instanceId,
  };
  final unchanged = current.length == command.pieces.length &&
      command.pieces.every(
        (p) => bySlot[p.slot.wireName] == p.instanceId,
      );

  final ts = now();
  if (!unchanged) {
    var order = 0;
    for (final piece in command.pieces) {
      await upsertSetItemRecord(
        db,
        id: newId(),
        setId: command.setId,
        slot: piece.slot.wireName,
        itemHash: piece.itemHash,
        itemName: piece.itemName?.trim().isNotEmpty == true
            ? piece.itemName!.trim()
            : 'Armor ${piece.itemHash}',
        instanceId: piece.instanceId,
        sortOrder: order++,
        replaceExisting: true,
        now: ts,
      );
    }
    // Touch updated_at without clearing optimizer constraints.
    await updateSetRecord(
      db,
      userId,
      command.setId,
      now: ts,
      optimizerConstraints: const Value.absent(),
    );
  }

  final detail = await getSetDetail(db, userId, command.setId);
  return ApplyArmorCombinationResult(
    armorSet: detail!,
    itemsUpdated: !unchanged,
  );
}
