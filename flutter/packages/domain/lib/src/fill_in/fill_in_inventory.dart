import '../models/equipment.dart';

/// One physical inventory copy held for Fill In matching.
///
/// Shaped so DIM Armor / Weapons CSV parsers can map columns directly:
/// `Id` → [instanceId], `Hash` → [itemHash], Equippable/Class →
/// [guardianClass] (armor only; weapons leave this null), Type/Category →
/// [slot], set membership → [armorSetHash] (armor legendaries only).
class FillInInventoryItem {
  const FillInInventoryItem({
    required this.instanceId,
    required this.itemHash,
    required this.slot,
    required this.isExotic,
    this.guardianClass,
    this.armorSetHash,
  });

  /// Stable id of this physical copy (DIM `Id` / instance id).
  final String instanceId;

  /// Destiny inventory item hash (DIM `Hash`).
  final int itemHash;

  /// Class that can equip this piece. Null for weapons (no class).
  final GuardianClass? guardianClass;

  /// Equipment slot for this copy (armor or weapon).
  final EquipmentSlot slot;

  /// True when this copy is exotic.
  final bool isExotic;

  /// Legendary armor set hash; null for exotic, weapons, or non-set pieces.
  final int? armorSetHash;
}
