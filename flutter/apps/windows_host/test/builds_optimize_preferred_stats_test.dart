import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_preferred_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MockBuild buildWithStats(List<MockStatTotal> stats) {
    return MockBuild(
      id: 's1',
      name: 'Stats',
      subclass: 'Strand',
      exoticArmor: 'Swarmers',
      exoticWeapon: '',
      slots: const [],
      loop: '',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: const [],
      stats: stats,
    );
  }

  ArmorCombination combo(Map<ArmorStatName, int> stats, {required int score}) {
    return ArmorCombination(
      pieces: const [],
      estimatedStats: stats,
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: score,
      meetsSoftThresholds: true,
    );
  }

  test('every preferred stat including low Health/Melee is a target', () {
    final preferred = preferredStatTargetsFromBuild(
      buildWithStats(const [
        MockStatTotal(id: MockStatId.health, value: 30),
        MockStatTotal(id: MockStatId.melee, value: 20),
        MockStatTotal(id: MockStatId.weapons, value: 110),
      ]),
    );
    expect(
      preferred.targets,
      {
        ArmorStatName.health: 30,
        ArmorStatName.melee: 20,
        ArmorStatName.weapons: 110,
      },
    );
    // High target first in priority order.
    expect(preferred.priorities.first, ArmorStatName.weapons);
  });

  test('no preferred stats → empty (regression)', () {
    expect(
      preferredStatTargetsFromBuild(buildWithStats(const [])).isEmpty,
      isTrue,
    );
  });

  test('Melee target 20: candidate at 20 ranks before 80', () {
    final overshoot = combo(
      const {ArmorStatName.melee: 80, ArmorStatName.weapons: 50},
      score: 130,
    );
    final onTarget = combo(
      const {ArmorStatName.melee: 20, ArmorStatName.weapons: 50},
      score: 70,
    );
    final ranked = rankCombinationsByPreferredStatCloseness(
      combinations: [overshoot, onTarget],
      targets: const {ArmorStatName.melee: 20},
    );
    expect(ranked.first, same(onTarget));
    expect(ranked.last, same(overshoot));
  });

  test('Health target 30: candidate at 30 ranks before 80', () {
    final overshoot = combo(
      const {ArmorStatName.health: 80, ArmorStatName.weapons: 50},
      score: 130,
    );
    final onTarget = combo(
      const {ArmorStatName.health: 30, ArmorStatName.weapons: 50},
      score: 80,
    );
    final ranked = rankCombinationsByPreferredStatCloseness(
      combinations: [overshoot, onTarget],
      targets: const {ArmorStatName.health: 30},
    );
    expect(ranked.first, same(onTarget));
    expect(ranked.last, same(overshoot));
  });

  test('closer candidate ranks first among otherwise-equal kits', () {
    final far = combo(
      const {
        ArmorStatName.weapons: 40,
        ArmorStatName.health: 80,
      },
      score: 200,
    );
    final close = combo(
      const {
        ArmorStatName.weapons: 108,
        ArmorStatName.health: 80,
      },
      score: 200,
    );
    final ranked = rankCombinationsByPreferredStatCloseness(
      combinations: [far, close],
      targets: const {ArmorStatName.weapons: 110},
    );
    expect(ranked.first, same(close));
    expect(ranked.last, same(far));
  });

  test('empty targets keep input order (regression)', () {
    final a = combo(const {ArmorStatName.health: 10}, score: 1);
    final b = combo(const {ArmorStatName.health: 99}, score: 2);
    final ranked = rankCombinationsByPreferredStatCloseness(
      combinations: [a, b],
      targets: const {},
    );
    expect(ranked, [a, b]);
  });
}
