/// Persistence DTOs for library repositories (DART-015).
///
/// These mirror product `*Repository.ts` shapes, not pure domain models.

/// Build row + tags + synergy type designations.
class BuildRecord {
  const BuildRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.className,
    required this.subclass,
    this.exoticArmorHash,
    this.exoticArmorName,
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.pinnedSuper,
    this.softStatTargets = const {},
    this.tagIds = const [],
    this.synergyTypes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final String name;
  final String className;

  /// Parsed JSON (Map/List/…) from builds.subclass.
  final Object? subclass;
  final int? exoticArmorHash;
  final String? exoticArmorName;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final String? pinnedSuper;
  final Map<String, Object?> softStatTargets;
  final List<String> tagIds;
  final List<SynergyTypeDesignationRecord> synergyTypes;
  final String createdAt;
  final String updatedAt;
}

class SynergyTypeDesignationRecord {
  const SynergyTypeDesignationRecord({
    required this.type,
    this.subType,
  });

  final String type;
  final String? subType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SynergyTypeDesignationRecord &&
        other.type == type &&
        other.subType == subType;
  }

  @override
  int get hashCode => Object.hash(type, subType);
}

class SetRecord {
  const SetRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.tagIds = const [],
    this.optimizerConstraints,
    this.linkedModSetId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final String name;
  final String type;
  final List<String> tagIds;
  final String? optimizerConstraints;
  final String? linkedModSetId;
  final String createdAt;
  final String updatedAt;
}

class SetAttachmentRef {
  const SetAttachmentRef({
    required this.buildId,
    required this.buildName,
    required this.variantId,
    required this.variantName,
  });

  final String buildId;
  final String buildName;
  final String variantId;
  final String variantName;
}

class SetItemRecord {
  const SetItemRecord({
    required this.id,
    required this.setId,
    required this.slot,
    required this.itemHash,
    required this.itemName,
    this.instanceId,
    this.selectedPerks = const [],
    this.masterworkHash,
    this.modHashes,
    this.sortOrder = 0,
    this.removedAt,
  });

  final String id;
  final String setId;
  final String slot;
  final int itemHash;
  final String itemName;
  final String? instanceId;
  final List<int> selectedPerks;
  final int? masterworkHash;
  final List<int>? modHashes;
  final int sortOrder;
  final String? removedAt;

  bool get isActive => removedAt == null;
}

class SynergyRecord {
  const SynergyRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.subType,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int userId;
  final String name;
  final String type;
  final String? subType;
  final String description;
  final String createdAt;
  final String updatedAt;
}

class SynergyLinkRecord {
  const SynergyLinkRecord({
    required this.id,
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
    this.required = false,
  });

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

  /// Required evidence link (DBR-SYN-007–010a). False = soft evidence only.
  final bool required;
}

class SynergyWithLinks {
  const SynergyWithLinks({
    required this.record,
    this.links = const [],
  });

  final SynergyRecord record;
  final List<SynergyLinkRecord> links;

  String get id => record.id;
  int get userId => record.userId;
  String get name => record.name;
  String get type => record.type;
  String? get subType => record.subType;
  String get description => record.description;
  String get createdAt => record.createdAt;
  String get updatedAt => record.updatedAt;
}

class VariantRecord {
  const VariantRecord({
    required this.id,
    required this.buildId,
    required this.name,
    this.isDefault = false,
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.artifactHash,
    this.artifactName,
    this.artifactConfig = const [],
    this.subclassKit,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String buildId;
  final String name;
  final bool isDefault;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final int? artifactHash;
  final String? artifactName;
  final List<int> artifactConfig;

  /// Parsed JSON from build_variants.subclass_kit (kit pieces; tree on Build).
  final Object? subclassKit;
  final String? notes;
  final String createdAt;
  final String updatedAt;
}

class AttachmentRecord {
  const AttachmentRecord({
    required this.id,
    required this.variantId,
    required this.setId,
    required this.mode,
    this.snapshotConfigs,
    required this.attachedAt,
  });

  final String id;
  final String variantId;
  final String setId;

  /// `live` or `snapshot`.
  final String mode;
  final List<Map<String, Object?>>? snapshotConfigs;
  final String attachedAt;
}

/// Thrown when deleting a set that is still attached to one or more variants.
class SetInUseException implements Exception {
  SetInUseException(this.setId, this.attachments);

  final String setId;
  final List<SetAttachmentRef> attachments;

  @override
  String toString() =>
      'SetInUseException: set $setId is attached to ${attachments.length} variant(s)';
}
