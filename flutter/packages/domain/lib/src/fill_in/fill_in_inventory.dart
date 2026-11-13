import '../models/equipment.dart';

/// One physical inventory copy held for Fill In matching.
///
/// Shaped so DIM Armor / Weapons CSV parsers can map columns directly:
/// `Id` → [instanceId], `Hash` → [itemHash], `Name` → [name], Equippable/Class →
/// [guardianClass] (armor only; weapons leave this null), Type/Category →
/// [slot] (armor Type → slot; weapons Category → slot), weapons `Type` →
/// [weaponType], weapons `Element` → [damageType], set membership →
/// [armorSetHash] (armor legendaries only).
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
    );
  }
}
