/// Pure armor-optimizer candidate / kit types (TS `src/lib/optimizer/types.ts` core).
///
/// No IO. Used by enumerate / prune / score (DART-008) and the pure optimize
/// pipeline / combination DTOs (DART-035). Isolate hosting lives in the app layer.
library;

import 'equipment.dart';
import 'soft_stats.dart';

/// Five armor slots a complete kit must fill, in canonical product order.
///
/// Wire-equivalent of TS `ARMOR_OPTIMIZER_SLOTS`.
const List<EquipmentSlot> armorOptimizerSlots = EquipmentSlot.armorSlots;

/// Set membership annotation used for reuse counting (excludes the searched Set).
class ReuseSetRef {
  const ReuseSetRef({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReuseSetRef && other.id == id && other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

/// Internal optimizer representation of one owned armor instance.
class CandidatePiece {
  const CandidatePiece({
    required this.slot,
    required this.itemHash,
    required this.instanceId,
    this.itemName,
    required this.isExotic,
    this.setBonusKey,
    this.statValues = const {},
    this.energyCapacity = 10,
    this.usedInSets = const [],
  });

  final EquipmentSlot slot;
  final int itemHash;
  final String instanceId;
  final String? itemName;
  final bool isExotic;
  final String? setBonusKey;
  final Map<ArmorStatName, int> statValues;

  /// Per-piece armor mod energy capacity (DBR-MOD-002); carried for later slices.
  final int energyCapacity;

  /// Other Armor Sets already using this active instance (excludes searched Set).
  final List<ReuseSetRef> usedInSets;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CandidatePiece) return false;
    return other.slot == slot &&
        other.itemHash == itemHash &&
        other.instanceId == instanceId &&
        other.itemName == itemName &&
        other.isExotic == isExotic &&
        other.setBonusKey == setBonusKey &&
        other.energyCapacity == energyCapacity &&
        _mapEq(other.statValues, statValues) &&
        _listEq(other.usedInSets, usedInSets);
  }

  @override
  int get hashCode => Object.hash(
        slot,
        itemHash,
        instanceId,
        itemName,
        isExotic,
        setBonusKey,
        energyCapacity,
        Object.hashAll(
          statValues.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hashAll(usedInSets),
      );
}

/// Goal for armor set-bonus piece coverage (TS `SetBonusCoverageGoal`).
class SetBonusCoverageGoal {
  const SetBonusCoverageGoal({
    required this.setBonusKey,
    required this.minPieces,
  });

  final String setBonusKey;

  /// Product schema allows 2 or 4; core treats as minimum piece count.
  final int minPieces;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetBonusCoverageGoal &&
        other.setBonusKey == setBonusKey &&
        other.minPieces == minPieces;
  }

  @override
  int get hashCode => Object.hash(setBonusKey, minPieces);
}

/// Hard constraints applied to every enumerated kit (TS `KitConstraints`).
class KitConstraints {
  const KitConstraints({
    this.lockedExoticItemHash,
    this.requireExotic,
    this.setBonusGoals,
  });

  final int? lockedExoticItemHash;
  final bool? requireExotic;
  final List<SetBonusCoverageGoal>? setBonusGoals;
}

/// Options for [enumerateKits] (TS `EnumerateOptions`).
class EnumerateOptions {
  const EnumerateOptions({
    this.constraints = const KitConstraints(),
    this.maxCombinations,
  });

  final KitConstraints constraints;
  final int? maxCombinations;
}

/// Result of pure kit enumeration (TS `EnumerateResult`).
class EnumerateResult {
  const EnumerateResult({
    required this.kits,
    required this.evaluatedCount,
    required this.truncated,
  });

  final List<List<CandidatePiece>> kits;
  final int evaluatedCount;
  final bool truncated;
}

/// Options for per-slot prune (TS `PruneOptions`).
class PruneOptions {
  const PruneOptions({
    this.priorities,
    this.k,
    this.lockedExoticItemHash,
    this.setBonusGoals,
  });

  final List<ArmorStatName>? priorities;
  final int? k;
  final int? lockedExoticItemHash;
  final List<SetBonusCoverageGoal>? setBonusGoals;
}

/// A kit reduced to the fields needed for ranking (TS `RankableCombination`).
class RankableCombination {
  const RankableCombination({
    required this.estimatedStats,
    required this.reusePieceCount,
  });

  final Map<ArmorStatName, int> estimatedStats;
  final int reusePieceCount;
}

/// Set-bonus activation summary for a kit (TS `SetBonusSummaryEntry`).
class SetBonusSummaryEntry {
  const SetBonusSummaryEntry({
    required this.setBonusKey,
    required this.pieceCount,
    required this.active2pc,
    required this.active4pc,
  });

  final String setBonusKey;
  final int pieceCount;
  final bool active2pc;
  final bool active4pc;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetBonusSummaryEntry &&
        other.setBonusKey == setBonusKey &&
        other.pieceCount == pieceCount &&
        other.active2pc == active2pc &&
        other.active4pc == active4pc;
  }

  @override
  int get hashCode =>
      Object.hash(setBonusKey, pieceCount, active2pc, active4pc);
}

/// API-facing piece on a scored combination (TS `ArmorOptimizePiece`).
class ArmorOptimizePiece {
  const ArmorOptimizePiece({
    required this.slot,
    required this.itemHash,
    required this.instanceId,
    this.itemName,
    required this.isExotic,
    this.setBonusKey,
    this.statValues = const {},
    this.usedInOtherSets = const [],
  });

  final EquipmentSlot slot;
  final int itemHash;
  final String instanceId;
  final String? itemName;
  final bool isExotic;
  final String? setBonusKey;
  final Map<ArmorStatName, int> statValues;
  final List<ReuseSetRef> usedInOtherSets;
}

/// Optional assumed armor mod from auto-stat estimates (empty in DART-035).
class AssumedMod {
  const AssumedMod({
    required this.armorSlot,
    required this.itemHash,
    this.name,
    required this.energyCost,
    this.statDeltas = const {},
  });

  final EquipmentSlot armorSlot;
  final int itemHash;
  final String? name;
  final int energyCost;
  final Map<ArmorStatName, int> statDeltas;
}

/// Scored complete kit (TS `ArmorCombination`).
class ArmorCombination {
  const ArmorCombination({
    required this.pieces,
    required this.estimatedStats,
    required this.incompleteEstimate,
    required this.setBonusSummary,
    this.assumedMods = const [],
    required this.reusePieceCount,
    required this.score,
    required this.meetsSoftThresholds,
  });

  final List<ArmorOptimizePiece> pieces;
  final Map<ArmorStatName, int> estimatedStats;
  final bool incompleteEstimate;
  final List<SetBonusSummaryEntry> setBonusSummary;
  final List<AssumedMod> assumedMods;
  final int reusePieceCount;
  final int score;
  final bool meetsSoftThresholds;

  RankableCombination get asRankable => RankableCombination(
        estimatedStats: estimatedStats,
        reusePieceCount: reusePieceCount,
      );
}

/// Empty-result reason codes (TS `ArmorOptimizeEmptyReasonCode`).
enum ArmorOptimizeEmptyReasonCode {
  noInventory('NO_INVENTORY'),
  noClassArmor('NO_CLASS_ARMOR'),
  exoticUnavailable('EXOTIC_UNAVAILABLE'),
  setBonusUnsatisfiable('SET_BONUS_UNSATISFIABLE'),
  thresholdsUnmet('THRESHOLDS_UNMET'),
  noValidKits('NO_VALID_KITS');

  const ArmorOptimizeEmptyReasonCode(this.wireName);
  final String wireName;
}

/// Explain why combinations is empty.
class ArmorOptimizeEmptyReason {
  const ArmorOptimizeEmptyReason({
    required this.code,
    required this.message,
    this.details = const {},
  });

  final ArmorOptimizeEmptyReasonCode code;
  final String message;
  final Map<String, Object?> details;
}

/// Seed echo for hosts (class + soft priorities).
class ArmorOptimizeSeed {
  const ArmorOptimizeSeed({
    this.classType,
    this.lockedExoticItemHash,
    this.statThresholds,
    this.statPriorities,
    this.preferReuse,
  });

  final String? classType;
  final int? lockedExoticItemHash;
  final Map<ArmorStatName, int>? statThresholds;
  final List<ArmorStatName>? statPriorities;
  final bool? preferReuse;
}

/// Input for pure [optimizeArmorCore] (candidates injected; no inventory IO).
class ArmorOptimizeRequest {
  const ArmorOptimizeRequest({
    required this.candidates,
    this.constraints = const KitConstraints(),
    this.statPriorities = const [],
    this.statThresholds,
    this.requireThresholds = false,
    this.preferReuse = false,
    this.maxResults = 25,
    this.maxCombinations,
    this.classType,
    this.hasInventory = true,
  });

  final List<CandidatePiece> candidates;
  final KitConstraints constraints;
  final List<ArmorStatName> statPriorities;
  final Map<ArmorStatName, int>? statThresholds;
  final bool requireThresholds;
  final bool preferReuse;

  /// Cap on returned combinations (product clamps 1..50).
  final int maxResults;
  final int? maxCombinations;
  final String? classType;

  /// When false and candidates empty, empty reason prefers NO_INVENTORY.
  final bool hasInventory;
}

/// Result of pure optimize pipeline (TS `ArmorOptimizeResponse` core).
class ArmorOptimizeResponse {
  const ArmorOptimizeResponse({
    required this.combinations,
    required this.truncated,
    required this.evaluatedCount,
    this.emptyReason,
    this.seed,
  });

  final List<ArmorCombination> combinations;
  final bool truncated;
  final int evaluatedCount;
  final ArmorOptimizeEmptyReason? emptyReason;
  final ArmorOptimizeSeed? seed;
}

/// Minimal piece identity for materialize / apply validation.
class CombinationPieceInput {
  const CombinationPieceInput({
    required this.slot,
    required this.itemHash,
    required this.instanceId,
  });

  final EquipmentSlot slot;
  final int itemHash;
  final String instanceId;
}

bool _mapEq(Map<ArmorStatName, int> a, Map<ArmorStatName, int> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

bool _listEq(List<ReuseSetRef> a, List<ReuseSetRef> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
