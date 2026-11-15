import 'package:destiny2_domain/destiny2_domain.dart';

import '../builds_mock/builds_mock_models.dart';
import 'builds_optimize_apply.dart';

/// Preferred-stat bands for Builds Optimize (deterministic).
///
/// Values below [kPreferredStatPushFloor] are treated as low / very-low and
/// are **not** pushed up (excluded from closeness targets). Daniel's examples:
/// Health 30 (low), Melee 20 (very low) stay out; Weapons 110 (high/good)
/// stays in.
const int kPreferredStatPushFloor = 70;

/// Preferred stat targets derived from a build's displayed / inferred stats.
class BuildsOptimizePreferredStats {
  const BuildsOptimizePreferredStats({
    required this.targets,
    required this.priorities,
  });

  /// Soft closeness targets (never hard-filtered via requireThresholds).
  final Map<ArmorStatName, int> targets;

  /// High → low target value order for prune / secondary keys.
  final List<ArmorStatName> priorities;

  bool get isEmpty => targets.isEmpty;

  static const empty = BuildsOptimizePreferredStats(
    targets: {},
    priorities: [],
  );
}

/// Map [MockBuild.stats] into soft preferred targets for Optimize ranking.
///
/// Skips stats below [kPreferredStatPushFloor] so low / very-low rows are not
/// maximized. Empty [build.stats] → [BuildsOptimizePreferredStats.empty]
/// (caller keeps the optimizer's current ordering).
BuildsOptimizePreferredStats preferredStatTargetsFromBuild(MockBuild build) {
  final targets = <ArmorStatName, int>{};
  for (final s in build.stats) {
    final name = armorStatFromMockStatId(s.id);
    if (name == null) continue;
    if (s.value < kPreferredStatPushFloor) continue;
    if (s.value <= 0) continue;
    targets[name] = s.value;
  }
  if (targets.isEmpty) return BuildsOptimizePreferredStats.empty;
  final priorities = targets.keys.toList()
    ..sort((a, b) {
      final byValue = targets[b]!.compareTo(targets[a]!);
      if (byValue != 0) return byValue;
      return a.wireName.compareTo(b.wireName);
    });
  return BuildsOptimizePreferredStats(
    targets: Map<ArmorStatName, int>.unmodifiable(targets),
    priorities: List<ArmorStatName>.unmodifiable(priorities),
  );
}

/// Weighted L1 distance to preferred targets (lower is better).
///
/// Weight = target value so high/good prefs pull harder than mid prefs.
int preferredStatDistanceScore({
  required Map<ArmorStatName, int> estimatedStats,
  required Map<ArmorStatName, int> targets,
}) {
  if (targets.isEmpty) return 0;
  var sum = 0;
  for (final e in targets.entries) {
    final actual = estimatedStats[e.key] ?? 0;
    final delta = (actual - e.value).abs();
    sum += delta * e.value;
  }
  return sum;
}

/// Sort combinations: closer to [targets] first; ties keep relative order.
List<ArmorCombination> rankCombinationsByPreferredStatCloseness({
  required List<ArmorCombination> combinations,
  required Map<ArmorStatName, int> targets,
}) {
  if (targets.isEmpty || combinations.length < 2) {
    return List<ArmorCombination>.from(combinations);
  }
  final indexed = <({int index, ArmorCombination combo, int distance})>[
    for (var i = 0; i < combinations.length; i++)
      (
        index: i,
        combo: combinations[i],
        distance: preferredStatDistanceScore(
          estimatedStats: combinations[i].estimatedStats,
          targets: targets,
        ),
      ),
  ];
  indexed.sort((a, b) {
    final byDistance = a.distance.compareTo(b.distance);
    if (byDistance != 0) return byDistance;
    return a.index.compareTo(b.index);
  });
  return [for (final row in indexed) row.combo];
}
