import '../models/equipment.dart';
import '../models/soft_stats.dart';

/// One physical inventory copy held for Fill In matching.
///
/// Shaped so DIM Armor / Weapons CSV parsers can map columns directly:
/// `Id` → [instanceId], `Hash` → [itemHash], `Name` → [name], Equippable/Class →
/// [guardianClass] (armor only; weapons leave this null), Type/Category →
/// [slot] (armor Type → slot; weapons Category → slot), weapons `Type` →
/// [weaponType], weapons `Element` → [damageType], set membership →
/// [armorSetHash] (armor legendaries only). Optional Optimize fields:
/// `Owner` → [location], armor stat columns → [statValues], weapons
/// `Perks 0`–`Perks 18` / offline perk names → [perkTags].
class FillInInventoryItem {
  const FillInInventoryItem({
    required this.instanceId,
    required this.itemHash,
    required this.slot,
    required this.isExotic,
    this.guardianClass,
    this.armorSetHash,
    this.name,
    this.weaponType,
    this.damageType,
    this.location,
    this.statValues = const <ArmorStatName, int>{},
    this.perkTags = const <String>[],
  });

  /// Stable id of this physical copy (DIM `Id` / instance id).
  final String instanceId;

  /// Destiny inventory item hash (DIM `Hash`).
  final int itemHash;

  /// Display name from DIM `Name` (used to resolve build exotic / piece names).
  final String? name;

  /// Class that can equip this piece. Null for weapons (no class).
  final GuardianClass? guardianClass;

  /// Equipment slot for this copy (armor or weapon).
  final EquipmentSlot slot;

  /// True when this copy is exotic.
  final bool isExotic;

  /// Legendary armor set hash; null for exotic, weapons, or non-set pieces.
  final int? armorSetHash;

  /// DIM Weapons `Type` (e.g. Hand Cannon). Null for armor.
  final String? weaponType;

  /// DIM Weapons `Element` / damage type (e.g. Solar). Null for armor.
  final String? damageType;

  /// Inventory location wire: `vault` / `character` / `postmaster` when known.
  final String? location;

  /// Per-piece Armor 3.0 stats from DIM CSV columns when present.
  final Map<ArmorStatName, int> statValues;

  /// Offline perk / synergy tags (DIM `Perks N` or cached offline names).
  ///
  /// Never populated from network — CSV import or offline store only.
  final List<String> perkTags;

  /// Copy with selected fields replaced (host-side set-hash stamping).
  FillInInventoryItem copyWith({
    String? instanceId,
    int? itemHash,
    String? name,
    GuardianClass? guardianClass,
    EquipmentSlot? slot,
    bool? isExotic,
    int? armorSetHash,
    bool clearArmorSetHash = false,
    String? weaponType,
    String? damageType,
    String? location,
    bool clearLocation = false,
    Map<ArmorStatName, int>? statValues,
    List<String>? perkTags,
  }) {
    return FillInInventoryItem(
      instanceId: instanceId ?? this.instanceId,
      itemHash: itemHash ?? this.itemHash,
      name: name ?? this.name,
      guardianClass: guardianClass ?? this.guardianClass,
      slot: slot ?? this.slot,
      isExotic: isExotic ?? this.isExotic,
      armorSetHash:
          clearArmorSetHash ? null : (armorSetHash ?? this.armorSetHash),
      weaponType: weaponType ?? this.weaponType,
      damageType: damageType ?? this.damageType,
      location: clearLocation ? null : (location ?? this.location),
      statValues: statValues ?? this.statValues,
      perkTags: perkTags ?? this.perkTags,
    );
  }
}
