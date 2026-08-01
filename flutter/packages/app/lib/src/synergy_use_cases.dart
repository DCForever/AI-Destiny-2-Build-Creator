import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';

import 'clock_ids.dart';
import 'errors.dart';
import 'mappers.dart';
import 'validate_synergy_link.dart';

/// Create input for a library synergy.
class CreateSynergyCommand {
  const CreateSynergyCommand({
    this.id,
    required this.name,
    required this.type,
    this.subType,
    this.description = '',
    this.links = const [],
  });

  final String? id;
  final String name;

  /// Synergy type wire name (must be creatable on create).
  final String type;
  final String? subType;
  final String description;
  final List<SynergyLinkWrite> links;
}

/// Link write DTO (validated kinds).
class SynergyLinkWrite {
  const SynergyLinkWrite({
    this.id,
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
  });

  final String? id;
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
}

/// Partial update — designation (type + subType) is immutable after create.
///
/// [hasType] / [hasSubType] distinguish "field not sent" from "sent as null/empty"
/// (product `input.subType !== undefined` parity).
class UpdateSynergyCommand {
  const UpdateSynergyCommand({
    this.name,
    this.description,
    this.links,
    this.hasType = false,
    this.type,
    this.hasSubType = false,
    this.subType,
  });

  final String? name;
  final String? description;
  final List<SynergyLinkWrite>? links;
  final bool hasType;
  final String? type;
  final bool hasSubType;
  final String? subType;
}

String _requireNonEmptyName(String name) {
  final t = name.trim();
  if (t.isEmpty) {
    throw UseCaseException(
      UseCaseErrorCode.invalidArgument,
      'Synergy name must not be empty',
    );
  }
  return t;
}

String? _normalizeSubType(String? subType) {
  final t = subType?.trim() ?? '';
  return t.isEmpty ? null : t;
}

void _assertCreatableType(String typeWire) {
  if (!creatableSynergyTypeWires.contains(typeWire)) {
    throw UseCaseException(
      UseCaseErrorCode.invalidSynergyType,
      'Synergy type is not creatable: $typeWire',
      details: {'type': typeWire},
    );
  }
}

List<SynergyLinkInput> _validateLinks(List<SynergyLinkWrite> links) {
  // Kind enum + displayName + BR-SYN-005 required fields / optional hash checks.
  assertSynergyLinksValid(links);

  final out = <SynergyLinkInput>[];
  for (final link in links) {
    final kind = SynergyLinkKind.tryParse(link.kind);
    if (kind == null) {
      throw UseCaseException(
        UseCaseErrorCode.invalidSynergyLinkKind,
        'Invalid synergy link kind: ${link.kind}',
        details: {'kind': link.kind},
      );
    }
    final display = link.displayName.trim();
    if (display.isEmpty) {
      throw UseCaseException(
        UseCaseErrorCode.invalidArgument,
        'Synergy link displayName must not be empty',
      );
    }
    out.add(
      SynergyLinkInput(
        id: link.id,
        kind: kind.wireName,
        displayName: display,
        itemHash: link.itemHash,
        perkHash: link.perkHash,
        parentItemHash: link.parentItemHash,
        originTraitName: link.originTraitName,
        originTraitHash: link.originTraitHash,
        armorSetName: link.armorSetName,
        bonusPieces: link.bonusPieces,
        bonusName: link.bonusName,
        armorSetHash: link.armorSetHash,
      ),
    );
  }
  return out;
}

/// List synergies for [userId], optional type wire filter.
Future<List<SynergyWithLinks>> listUserSynergies(
  AppDatabase db,
  int userId, {
  String? type,
}) {
  return listSynergies(db, userId, type: type);
}

/// Get synergy; null if missing.
Future<SynergyWithLinks?> getUserSynergy(
  AppDatabase db,
  int userId,
  String synergyId,
) {
  return getSynergy(db, userId, synergyId);
}

/// Domain mapping helper for a loaded row.
Synergy mapSynergyDomain(SynergyWithLinks row) => synergyFromRecord(row);

/// Create synergy with creatable type + valid link kinds.
Future<SynergyWithLinks> createUserSynergy(
  AppDatabase db,
  int userId,
  CreateSynergyCommand command, {
  NowClock now = defaultNow,
  IdGenerator newId = defaultNewId,
}) async {
  final name = _requireNonEmptyName(command.name);
  final typeWire = command.type.trim();
  _assertCreatableType(typeWire);
  final links = _validateLinks(command.links);
  final id = command.id ?? newId();
  final ts = now();
  return createSynergyRecord(
    db,
    userId,
    id: id,
    name: name,
    type: typeWire,
    subType: _normalizeSubType(command.subType),
    description: command.description,
    links: links,
    now: ts,
  );
}

/// Update synergy; null if missing. Designation immutable when type/subType sent.
Future<SynergyWithLinks?> updateUserSynergy(
  AppDatabase db,
  int userId,
  String synergyId,
  UpdateSynergyCommand command, {
  NowClock now = defaultNow,
}) async {
  final existing = await getSynergy(db, userId, synergyId);
  if (existing == null) return null;

  if (command.hasType) {
    final requested = command.type?.trim() ?? '';
    if (requested != existing.type) {
      throw UseCaseException(
        UseCaseErrorCode.designationImmutable,
        'Synergy type cannot be changed after create',
        details: {'existing': existing.type, 'requested': command.type},
      );
    }
  }
  if (command.hasSubType) {
    final next = _normalizeSubType(command.subType);
    final prev = _normalizeSubType(existing.subType);
    if (next != prev) {
      throw UseCaseException(
        UseCaseErrorCode.designationImmutable,
        'Synergy subtype cannot be changed after create',
        details: {'existing': prev, 'requested': next},
      );
    }
  }

  List<SynergyLinkInput>? links;
  if (command.links != null) {
    links = _validateLinks(command.links!);
  }

  String? name;
  if (command.name != null) {
    name = _requireNonEmptyName(command.name!);
  }

  return updateSynergyRecord(
    db,
    userId,
    synergyId,
    name: name,
    type: existing.type,
    description: command.description,
    links: links,
    now: now(),
  );
}

/// Delete synergy; false if missing.
Future<bool> deleteUserSynergy(
  AppDatabase db,
  int userId,
  String synergyId,
) {
  return deleteSynergyRecord(db, userId, synergyId);
}

/// Reverse-lookup synergies for a catalog/inventory target (BR-SYN-004).
Future<List<SynergyWithLinks>> listUserSynergiesByTarget(
  AppDatabase db,
  int userId,
  SynergyTargetQuery query,
) {
  return findSynergiesByTarget(db, userId, query);
}

/// Batch reverse-lookup by item hashes for a link [kind].
Future<Map<int, List<SynergyWithLinks>>> listUserSynergiesByItemHashes(
  AppDatabase db,
  int userId,
  String kind,
  List<int> itemHashes,
) {
  return findSynergiesByItemHashes(db, userId, kind, itemHashes);
}

