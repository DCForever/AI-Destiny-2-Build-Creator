import '../models/equipment.dart';

/// Per-slot Fill In outcome for one build.
///
/// [overCapLabel] is display-only. There is no action, callback, or write
/// hook on this type — over-cap never triggers inventory mutation.
class FillInSlotMatch {
  const FillInSlotMatch({
    required this.slot,
    required this.isHeld,
    required this.poolHeldCount,
    required this.cap,
    required this.exceedsCap,
    this.overCapLabel,
  });

  final EquipmentSlot slot;

  /// True when at least one matching physical copy exists in inventory.
  final bool isHeld;

  /// How many matching copies the shared pool holds for this need.
  final int poolHeldCount;

  /// Effective inventory cap used for the over-cap label.
  final int cap;

  /// True when [poolHeldCount] is greater than [cap].
  final bool exceedsCap;

  /// [moreThanHeldLabel] when [exceedsCap]; otherwise null. Label only.
  final String? overCapLabel;
}

/// Fill In outcome for one build.
class FillInBuildResult {
  const FillInBuildResult({
    required this.buildId,
    required this.solipsismNotPrismatic,
    required this.slots,
  });

  final String buildId;

  /// Solipsism on a known non-Prismatic subclass — flagged, never silent OK.
  final bool solipsismNotPrismatic;

  final List<FillInSlotMatch> slots;
}

/// Aggregate Fill In report for one or more builds against one inventory.
class FillInMatchReport {
  const FillInMatchReport({
    required this.cap,
    required this.builds,
  });

  final int cap;
  final List<FillInBuildResult> builds;
}
