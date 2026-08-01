import 'equipment.dart';
import 'kit.dart';
import 'soft_stats.dart';
import 'synergy.dart';

/// Evaluator-facing build identity (not a full DB row).
class Build {
  const Build({
    required this.id,
    required this.name,
    required this.className,
    this.subclass = const SubclassKit(),
    this.exoticArmorHash,
    this.exoticArmorName,
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.pinnedSuper,
    this.softStatTargets = const SoftStatTargets(),
    this.synergyTypes = const [],
    this.tagIds = const [],
  });

  final String id;
  final String name;
  final GuardianClass className;
  final SubclassKit subclass;
  final int? exoticArmorHash;
  final String? exoticArmorName;
  final int? exoticWeaponHash;
  final String? exoticWeaponName;
  final String? pinnedSuper;
  final SoftStatTargets softStatTargets;
  final List<SynergyTypeDesignation> synergyTypes;
  final List<String> tagIds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Build) return false;
    return other.id == id &&
        other.name == name &&
        other.className == className &&
        other.subclass == subclass &&
        other.exoticArmorHash == exoticArmorHash &&
        other.exoticArmorName == exoticArmorName &&
        other.exoticWeaponHash == exoticWeaponHash &&
        other.exoticWeaponName == exoticWeaponName &&
        other.pinnedSuper == pinnedSuper &&
        other.softStatTargets == softStatTargets &&
        _desigListEquals(other.synergyTypes, synergyTypes) &&
        _strListEquals(other.tagIds, tagIds);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        className,
        subclass,
        exoticArmorHash,
        exoticArmorName,
        exoticWeaponHash,
        exoticWeaponName,
        pinnedSuper,
        softStatTargets,
        Object.hashAll(synergyTypes),
        Object.hashAll(tagIds),
      );
}

/// Build variant (default or alternate) with optional exotic/artifact pins.
class Variant {
  const Variant({
    required this.id,
    required this.buildId,
    required this.name,
    this.isDefault = false,
    this.exoticWeaponHash,
    this.exoticWeaponName,
    this.artifactHash,
    this.artifactName,
    this.artifactConfig = const [],
    this.notes,
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
  final String? notes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Variant &&
        other.id == id &&
        other.buildId == buildId &&
        other.name == name &&
        other.isDefault == isDefault &&
        other.exoticWeaponHash == exoticWeaponHash &&
        other.exoticWeaponName == exoticWeaponName &&
        other.artifactHash == artifactHash &&
        other.artifactName == artifactName &&
        _intListEquals(other.artifactConfig, artifactConfig) &&
        other.notes == notes;
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
        Object.hashAll(artifactConfig),
        notes,
      );
}

/// Frozen slot config when attachment mode is snapshot.
class SnapshotConfig {
  const SnapshotConfig({
    required this.slot,
    required this.itemHash,
    required this.itemName,
    this.selectedPerks,
    this.masterworkHash,
    this.modHashes,
    this.instanceId,
  });

  final String slot;
  final int itemHash;
  final String itemName;
  final List<int>? selectedPerks;
  final int? masterworkHash;
  final List<int>? modHashes;
  final String? instanceId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SnapshotConfig &&
        other.slot == slot &&
        other.itemHash == itemHash &&
        other.itemName == itemName &&
        _intListEqualsNullable(other.selectedPerks, selectedPerks) &&
        other.masterworkHash == masterworkHash &&
        _intListEqualsNullable(other.modHashes, modHashes) &&
        other.instanceId == instanceId;
  }

  @override
  int get hashCode => Object.hash(
        slot,
        itemHash,
        itemName,
        Object.hashAll(selectedPerks ?? const []),
        masterworkHash,
        Object.hashAll(modHashes ?? const []),
        instanceId,
      );
}

/// Variant ↔ set attachment.
class Attachment {
  const Attachment({
    required this.id,
    required this.variantId,
    required this.setId,
    required this.mode,
    this.snapshotConfigs,
  });

  final String id;
  final String variantId;
  final String setId;
  final AttachmentMode mode;
  final List<SnapshotConfig>? snapshotConfigs;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Attachment) return false;
    if (other.id != id ||
        other.variantId != variantId ||
        other.setId != setId ||
        other.mode != mode) {
      return false;
    }
    final a = other.snapshotConfigs;
    final b = snapshotConfigs;
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        variantId,
        setId,
        mode,
        Object.hashAll(snapshotConfigs ?? const []),
      );
}

/// Product "Set" library entity (named GearSet to avoid Dart [Set]).
class GearSet {
  const GearSet({
    required this.id,
    required this.name,
    required this.type,
    this.tagIds = const [],
    this.linkedModSetId,
  });

  final String id;
  final String name;
  final SetType type;
  final List<String> tagIds;
  final String? linkedModSetId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GearSet &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        _strListEquals(other.tagIds, tagIds) &&
        other.linkedModSetId == linkedModSetId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        Object.hashAll(tagIds),
        linkedModSetId,
      );
}

/// Active item in a gear set (evaluator-facing subset).
class SetItem {
  const SetItem({
    required this.id,
    required this.setId,
    required this.slot,
    required this.itemHash,
    required this.itemName,
    this.instanceId,
    this.selectedPerks = const [],
    this.masterworkHash,
    this.modHashes,
    this.stale = false,
  });

  final String id;
  final String setId;

  /// Slot key (equipment wire name, fashion slot, or mod key `helmet:hash`).
  final String slot;
  final int itemHash;
  final String itemName;
  final String? instanceId;
  final List<int> selectedPerks;
  final int? masterworkHash;
  final List<int>? modHashes;
  final bool stale;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetItem &&
        other.id == id &&
        other.setId == setId &&
        other.slot == slot &&
        other.itemHash == itemHash &&
        other.itemName == itemName &&
        other.instanceId == instanceId &&
        _intListEquals(other.selectedPerks, selectedPerks) &&
        other.masterworkHash == masterworkHash &&
        _intListEqualsNullable(other.modHashes, modHashes) &&
        other.stale == stale;
  }

  @override
  int get hashCode => Object.hash(
        id,
        setId,
        slot,
        itemHash,
        itemName,
        instanceId,
        Object.hashAll(selectedPerks),
        masterworkHash,
        Object.hashAll(modHashes ?? const []),
        stale,
      );
}

bool _strListEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _intListEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _intListEqualsNullable(List<int>? a, List<int>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  return _intListEquals(a, b);
}

bool _desigListEquals(
  List<SynergyTypeDesignation> a,
  List<SynergyTypeDesignation> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
