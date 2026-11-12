import '../models/equipment.dart';

/// One armor slot a build asks Fill In to cover.
class FillInSlotRequirement {
  const FillInSlotRequirement({
    required this.slot,
    required this.isExotic,
    this.exoticItemHash,
    this.armorSetHash,
  });

  final EquipmentSlot slot;
  final bool isExotic;

  /// Exotic armor matches by item hash only.
  final int? exoticItemHash;

  /// Legendary pieces match by set hash + slot + class.
  final int? armorSetHash;
}

/// Build-level Fill In request (read-only; no store mutation).
class FillInBuildRequirement {
  const FillInBuildRequirement({
    required this.buildId,
    required this.guardianClass,
    required this.subclassKey,
    required this.slots,
    this.exoticArmorName,
  });

  final String buildId;
  final GuardianClass guardianClass;

  /// Subclass key used for Solipsism / Prismatic flagging.
  final String subclassKey;

  /// Exotic armor display name (Solipsism detection).
  final String? exoticArmorName;

  final List<FillInSlotRequirement> slots;
}
