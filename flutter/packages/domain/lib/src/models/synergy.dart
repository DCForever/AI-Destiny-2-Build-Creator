/// Creatable synergy type wire names (TS `CREATABLE_SYNERGY_TYPES`).
const List<String> creatableSynergyTypeWires = [
  'melee',
  'verb',
  'grenade',
  'super',
  'element',
  'primary_weapon',
  'special_weapon',
  'heavy_weapon',
  'dps',
  'healing',
  'solo',
  'damage_resist',
  'general_weapon',
  'weapon_archetype',
  'team',
];

/// Legacy synergy types still readable from storage.
const List<String> legacySynergyTypeWires = [
  'kinetic_weapon',
  'damage',
];

/// All known synergy type wires (creatable + legacy).
const List<String> allSynergyTypeWires = [
  ...creatableSynergyTypeWires,
  ...legacySynergyTypeWires,
];

/// Synergy type value object (string wire for forward-compat with product schema).
class SynergyType {
  const SynergyType(this.wireName);

  final String wireName;

  bool get isLegacy => legacySynergyTypeWires.contains(wireName);
  bool get isCreatable => creatableSynergyTypeWires.contains(wireName);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SynergyType && other.wireName == wireName;
  }

  @override
  int get hashCode => wireName.hashCode;

  @override
  String toString() => 'SynergyType($wireName)';
}

/// Evidence link kinds (TS synergy link schema).
enum SynergyLinkKind {
  weapon('weapon'),
  weaponPerk('weapon_perk'),
  originTrait('origin_trait'),
  armorSetBonus('armor_set_bonus'),
  exoticArmor('exotic_armor'),
  artifactPerk('artifact_perk');

  const SynergyLinkKind(this.wireName);
  final String wireName;

  static SynergyLinkKind? tryParse(String wire) {
    for (final v in SynergyLinkKind.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

/// Build designation of a synergy type (+ optional subtype).
class SynergyTypeDesignation {
  const SynergyTypeDesignation({
    required this.type,
    this.subType,
  });

  final SynergyType type;
  final String? subType;

  /// Product designation key: `type` or `type::subType`.
  String get designationKey {
    final sub = subType?.trim();
    if (sub == null || sub.isEmpty) return type.wireName;
    return '${type.wireName}::$sub';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SynergyTypeDesignation &&
        other.type == type &&
        other.subType == subType;
  }

  @override
  int get hashCode => Object.hash(type, subType);
}

/// Pure synergy library shape (evaluator-facing; not a DB row).
class Synergy {
  const Synergy({
    required this.id,
    required this.name,
    required this.type,
    this.subType,
    this.description = '',
    this.links = const [],
  });

  final String id;
  final String name;
  final SynergyType type;
  final String? subType;
  final String description;
  final List<SynergyLink> links;

  SynergyTypeDesignation get designation =>
      SynergyTypeDesignation(type: type, subType: subType);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Synergy) return false;
    if (other.id != id ||
        other.name != name ||
        other.type != type ||
        other.subType != subType ||
        other.description != description) {
      return false;
    }
    if (other.links.length != links.length) return false;
    for (var i = 0; i < links.length; i++) {
      if (other.links[i] != links[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        type,
        subType,
        description,
        Object.hashAll(links),
      );
}

/// Evidence link on a synergy.
class SynergyLink {
  const SynergyLink({
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
  final SynergyLinkKind kind;
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

  /// Required evidence (DBR-SYN-007–010a): hard on default save; soft warn only
  /// on non-default. False = soft evidence only.
  final bool required;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SynergyLink &&
        other.id == id &&
        other.synergyId == synergyId &&
        other.kind == kind &&
        other.displayName == displayName &&
        other.itemHash == itemHash &&
        other.perkHash == perkHash &&
        other.parentItemHash == parentItemHash &&
        other.originTraitName == originTraitName &&
        other.originTraitHash == originTraitHash &&
        other.armorSetName == armorSetName &&
        other.bonusPieces == bonusPieces &&
        other.bonusName == bonusName &&
        other.armorSetHash == armorSetHash &&
        other.required == required;
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
        required,
      );
}
