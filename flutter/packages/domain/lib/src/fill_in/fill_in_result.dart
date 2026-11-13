import '../models/equipment.dart';

/// Why Fill In shows (or omits) a Solipsism / Prismatic warning.
enum FillInSolipsismFlag {
  /// No warning.
  none,

  /// Exotic armor is literally Solipsism on a known non-Prismatic subclass.
  notPrismatic,

  /// Warlock fail-closed: exotic armor name missing or subclass unknown —
  /// cannot confirm Solipsism/Prismatic. Never silent OK on Warlock.
  exoticArmorUnknown,
}

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
    required this.solipsismFlag,
    required this.slots,
  });

  final String buildId;

  /// Solipsism / Prismatic gate outcome (never silent OK on Warlock unknown).
  final FillInSolipsismFlag solipsismFlag;

  /// True only when exotic is Solipsism on a known non-Prismatic subclass.
  bool get solipsismNotPrismatic =>
      solipsismFlag == FillInSolipsismFlag.notPrismatic;

  /// Warlock fail-closed when exotic armor (or subclass) cannot be confirmed.
  bool get exoticArmorUnknown =>
      solipsismFlag == FillInSolipsismFlag.exoticArmorUnknown;

  /// Any Solipsism-related warning (Prismatic mismatch or unknown exotic).
  bool get hasSolipsismWarning =>
      solipsismFlag != FillInSolipsismFlag.none;

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
