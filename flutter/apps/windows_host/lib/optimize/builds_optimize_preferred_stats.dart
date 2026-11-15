import 'package:destiny2_domain/destiny2_domain.dart';

import '../builds_mock/builds_mock_models.dart';
import 'builds_optimize_apply.dart';

/// Preferred stat targets derived from a build's displayed / inferred stats.
class BuildsOptimizePreferredStats {
  const BuildsOptimizePreferredStats({
    required this.targets,
    required this.priorities,
  });

  /// Soft closeness targets (never hard-filtered via requireThresholds).
  ///
  /// Includes every preferred row with value &gt; 0 — high and low alike
  /// (e.g. Weapons 110, Health 30, Melee 20).
  final Map<ArmorStatName, int> targets;

  /// High → low target value order (seed / prune hint only; final rank is
  /// [rankCombinationsByPreferredStatCloseness]).
  final List<ArmorStatName> priorities;

  bool get isEmpty => targets.isEmpty;

  static const empty = BuildsOptimizePreferredStats(
    targets: {},
    priorities: [],
  );
}

/// Map [MockBuild.stats] into soft preferred targets for Optimize ranking.
///
/// Every positive preferred value is a closeness target (Daniel Nov 15 2026:
/// Health 30 and Melee 20 must count — overshooting them ranks worse).
/// Empty [build.stats] → [BuildsOptimizePreferredStats.empty] (caller keeps
/// the optimizer's current ordering).
BuildsOptimizePreferredStats preferredStatTargetsFromBuild(MockBuild build) {
  final targets = <ArmorStatName, int>{};
  for (final s in build.stats) {
    final name = armorStatFromMockStatId(s.id);
    if (name == null) continue;
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
/// Distance is absolute (undershoot and overshoot both hurt). Weight = target
/// value so high-priority prefs (e.g. Weapons 110) pull harder than low ones
/// (e.g. Melee 20), while wasted points on overshooting Melee still count.
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
