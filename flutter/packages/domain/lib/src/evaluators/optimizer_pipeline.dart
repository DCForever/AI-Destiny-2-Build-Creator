/// Pure armor optimize pipeline (TS `optimizeArmor.ts` core without inventory IO).
///
/// prune → enumerate → score/rank → maxResults. Soft thresholds filter only when
/// [ArmorOptimizeRequest.requireThresholds] is true. Assumed mods empty (DART-035).
library;

import '../models/equipment.dart';
import '../models/optimizer.dart';
import '../models/soft_stats.dart';
import 'optimizer_constraints.dart';
import 'optimizer_enumerate.dart';
import 'optimizer_explain_empty.dart';
import 'optimizer_prune.dart';
import 'optimizer_score.dart';

/// Map a candidate piece to the API combination piece DTO.
ArmorOptimizePiece toCombinationPiece(CandidatePiece piece) {
  return ArmorOptimizePiece(
    slot: piece.slot,
    itemHash: piece.itemHash,
    instanceId: piece.instanceId,
    itemName: piece.itemName,
    isExotic: piece.isExotic,
    setBonusKey: piece.setBonusKey,
    statValues: Map<ArmorStatName, int>.from(piece.statValues),
    usedInOtherSets: List<ReuseSetRef>.from(piece.usedInSets),
  );
}

/// Assemble a scored combination from a validated complete kit (base armor only).
ArmorCombination buildCombination(
  List<CandidatePiece> kit, {
  Map<ArmorStatName, int>? thresholds,
}) {
  final estimated = estimateKitStats(kit);
  return ArmorCombination(
    pieces: kit.map(toCombinationPiece).toList(),
    estimatedStats: estimated,
    incompleteEstimate: isEstimateIncomplete(kit),
    setBonusSummary: buildSetBonusSummary(kit),
    assumedMods: const [],
    reusePieceCount: kit.where((p) => p.usedInSets.isNotEmpty).length,
    score: sumAllStats(estimated),
    meetsSoftThresholds: meetsSoftThresholds(estimated, thresholds),
  );
}

int _clampMaxResults(int maxResults) {
  if (maxResults < 1) return 1;
  if (maxResults > 50) return 50;
  return maxResults;
}

/// Pure optimize: no IO, no isolate. Safe to call from [Isolate.run] via maps.
ArmorOptimizeResponse optimizeArmorCore(ArmorOptimizeRequest request) {
  final maxResults = _clampMaxResults(request.maxResults);
  final candidates = request.candidates;
  final constraints = request.constraints;

  final pruned = prunePiecesBySlot(
    groupBySlot(candidates),
    PruneOptions(
      priorities: request.statPriorities,
      lockedExoticItemHash: constraints.lockedExoticItemHash,
      setBonusGoals: constraints.setBonusGoals,
    ),
  );

  final enumeration = enumerateKits(
    pruned,
    EnumerateOptions(
      constraints: constraints,
      maxCombinations: request.maxCombinations,
    ),
  );

  var combos = enumeration.kits
      .map(
        (kit) => buildCombination(
          kit,
          thresholds: request.statThresholds,
        ),
      )
      .toList();

  final beforeThresholdCount = combos.length;
  if (request.requireThresholds) {
    combos = combos.where((c) => c.meetsSoftThresholds).toList();
  }

  combos.sort(
    (a, b) => compareCombinations(
      a.asRankable,
      b.asRankable,
      request.statPriorities,
      request.preferReuse,
    ),
  );

  final truncated =
      enumeration.truncated || combos.length > maxResults;
  final combinations = combos.length > maxResults
      ? combos.sublist(0, maxResults)
      : combos;

  final seed = ArmorOptimizeSeed(
    classType: request.classType,
    lockedExoticItemHash: constraints.lockedExoticItemHash,
    statThresholds: request.statThresholds,
    statPriorities:
        request.statPriorities.isEmpty ? null : request.statPriorities,
    preferReuse: request.preferReuse,
  );

  ArmorOptimizeEmptyReason? emptyReason;
  if (combinations.isEmpty) {
    final goals = constraints.setBonusGoals ?? const <SetBonusCoverageGoal>[];
    emptyReason = explainEmpty(
      EmptyReasonInput(
        hasInventory: request.hasInventory,
        classArmorCount: candidates.length,
        lockedExoticItemHash: constraints.lockedExoticItemHash,
        lockedExoticAvailable: constraints.lockedExoticItemHash == null ||
            candidates.any(
              (c) => c.itemHash == constraints.lockedExoticItemHash,
            ),
        setBonusGoals: goals,
        setBonusReachable: goalsReachable(candidates, goals),
        requireThresholds: request.requireThresholds,
        thresholdsFilteredAll:
            request.requireThresholds && beforeThresholdCount > 0,
      ),
    );
  }

  return ArmorOptimizeResponse(
    combinations: combinations,
    truncated: truncated,
    evaluatedCount: enumeration.evaluatedCount,
    emptyReason: emptyReason,
    seed: seed,
  );
}

/// Validate five distinct armor optimizer slots (materialize / apply).
///
/// Returns null when valid; otherwise a short error message.
String? validateCombinationPieces(List<CombinationPieceInput> pieces) {
  if (pieces.length != armorOptimizerSlots.length) {
    return 'Combination must fill all five distinct armor slots';
  }
  final seen = <EquipmentSlot>{};
  for (final piece in pieces) {
    if (!armorOptimizerSlots.contains(piece.slot)) {
      return 'Invalid armor slot: ${piece.slot.wireName}';
    }
    if (!seen.add(piece.slot)) {
      return 'Combination must fill all five distinct armor slots';
    }
  }
  if (seen.length != armorOptimizerSlots.length) {
    return 'Combination must fill all five distinct armor slots';
  }
  return null;
}
