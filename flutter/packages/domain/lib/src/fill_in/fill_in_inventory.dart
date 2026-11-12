import '../models/equipment.dart';

/// One physical armor copy held in inventory.
///
/// Shaped so a DIM Armor CSV parser (PR2) can map columns directly:
/// `Id` → [instanceId], `Hash` → [itemHash], Equippable/Class →
/// [guardianClass], Type/slot → [slot], set membership → [armorSetHash].
class FillInInventoryItem {
  const FillInInventoryItem({
    required this.instanceId,
    required this.itemHash,
    required this.guardianClass,
    required this.slot,
    required this.isExotic,
    this.armorSetHash,
  });

  /// Stable id of this physical copy (DIM `Id` / instance id).
  final String instanceId;

  /// Destiny inventory item hash (DIM `Hash`).
  final int itemHash;

  /// Class that can equip this piece.
  final GuardianClass guardianClass;

  /// Armor equipment slot for this copy.
  final EquipmentSlot slot;

  /// True when this copy is exotic armor.
  final bool isExotic;

  /// Legendary armor set hash; null for exotic or non-set pieces.
  final int? armorSetHash;
}
