/// Soft post-sync / on-open armor kit improvement suggestions (BR-OPT-004).
///
/// **Never mutates** sets — callers must confirm via [applyArmorCombinationInPlace].
library;

import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';

import 'optimizer_constraints_json.dart';
import 'set_use_cases.dart';

/// One soft suggestion for a constrained attached Armor Set.
class ImprovementSuggestion {
  const ImprovementSuggestion({
    required this.armorSetId,
    required this.armorSetName,
    required this.buildIds,
    required this.hasImprovement,
    this.betterCombination,
    this.currentSummary,
  });

  final String armorSetId;
  final String armorSetName;
  final List<String> buildIds;
  final bool hasImprovement;
  final ArmorCombination? betterCombination;
  final RankableCombination? currentSummary;
}

/// Injectable optimize for a single set (tests inject fixed response).
typedef OptimizeSetRunner = Future<ArmorOptimizeResponse> Function({
  required String setId,
  required ArmorSetOptimizerConstraints constraints,
  required List<CandidatePiece> candidates,
});

/// Build current rankable from set pieces matched against [candidates].
RankableCombination? currentRankableFromPieces({
  required List<SetItemRecord> activeItems,
  required List<CandidatePiece> candidates,
}) {
  final byInstance = {
    for (final c in candidates) c.instanceId: c,
  };
  final pieces = <CandidatePiece>[];
  for (final item in activeItems) {
    final id = item.instanceId;
    if (id == null || id.isEmpty) continue;
    final match = byInstance[id];
    if (match != null) pieces.add(match);
  }
  if (pieces.isEmpty) return null;
  final stats = estimateKitStats(pieces);
  final reuse = pieces.where((p) => p.usedInSets.isNotEmpty).length;
  return RankableCombination(
    estimatedStats: stats,
    reusePieceCount: reuse,
  );
}

/// Pure comparison gate used by suggestion builders.
bool combinationImprovesCurrent({
  required RankableCombination current,
  required ArmorCombination top,
  required ArmorSetOptimizerConstraints constraints,
}) {
  return detectImprovement(
    current,
    top.asRankable,
    constraints.statPriorities.isEmpty ? null : constraints.statPriorities,
    constraints.preferReuse,
  );
}

/// List constrained armor sets attached to ≥1 build (afterSync scan).
Future<List<SetDetail>> listConstrainedAttachedArmorSets(
  AppDatabase db,
  int userId,
) async {
  final armor = await listUserSets(db, userId, type: SetType.armor);
  final out = <SetDetail>[];
  for (final row in armor) {
    if (parseOptimizerConstraints(row.optimizerConstraints) == null) {
      continue;
    }
    final detail = await getSetDetail(db, userId, row.id);
    if (detail == null) continue;
    if (detail.usedBy.isEmpty) continue;
    out.add(detail);
  }
  return out;
}

/// Soft improvement suggestions — **never writes**.
///
/// When [afterSync] is true (default), scans all constrained attached armor
/// sets. When [armorSetId] is set, evaluates that set only (attached or not).
Future<List<ImprovementSuggestion>> buildImprovementSuggestions(
  AppDatabase db,
  int userId, {
  required List<CandidatePiece> candidates,
  OptimizeSetRunner? optimizeRunner,
  bool afterSync = true,
  String? armorSetId,
  bool hasInventory = true,
}) async {
  final runner = optimizeRunner ??
      ({
        required String setId,
        required ArmorSetOptimizerConstraints constraints,
        required List<CandidatePiece> candidates,
      }) async {
        return optimizeArmorCore(
          ArmorOptimizeRequest(
            candidates: candidates,
            constraints: KitConstraints(
              lockedExoticItemHash: constraints.lockedExoticItemHash,
              requireExotic: constraints.requireExotic,
              setBonusGoals: constraints.setBonusGoals,
            ),
            statPriorities: constraints.statPriorities,
            statThresholds: constraints.statThresholds,
            requireThresholds: constraints.requireThresholds,
            preferReuse: constraints.preferReuse,
            maxResults: 5,
            hasInventory: hasInventory,
          ),
        );
      };

  Future<ImprovementSuggestion?> suggestFor(SetDetail detail) async {
    final constraints =
        parseOptimizerConstraints(detail.set.optimizerConstraints);
    if (constraints == null) return null;

    final buildIds = <String>{
      for (final ref in detail.usedBy) ref.buildId,
    }.toList()
      ..sort();

    final response = await runner(
      setId: detail.set.id,
      constraints: constraints,
      candidates: candidates,
    );
    final top = response.combinations.isEmpty
        ? null
        : response.combinations.first;
    final current = currentRankableFromPieces(
      activeItems: detail.activeItems,
      candidates: candidates,
    );

    final hasImprovement = top != null &&
        current != null &&
        combinationImprovesCurrent(
          current: current,
          top: top,
          constraints: constraints,
        );

    return ImprovementSuggestion(
      armorSetId: detail.set.id,
      armorSetName: detail.set.name,
      buildIds: buildIds,
      hasImprovement: hasImprovement,
      betterCombination: hasImprovement ? top : null,
      currentSummary: current,
    );
  }

  if (armorSetId != null) {
    final detail = await getSetDetail(db, userId, armorSetId);
    if (detail == null || detail.set.type != SetType.armor.wireName) {
      return const [];
    }
    final s = await suggestFor(detail);
    return s == null ? const [] : [s];
  }

  if (!afterSync) return const [];

  final targets = await listConstrainedAttachedArmorSets(db, userId);
  final suggestions = <ImprovementSuggestion>[];
  for (final detail in targets) {
    final s = await suggestFor(detail);
    if (s != null && s.hasImprovement) {
      suggestions.add(s);
    }
  }
  return suggestions;
}
