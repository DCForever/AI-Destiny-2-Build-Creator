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

  test('low / very-low stats are not preferred targets', () {
    final preferred = preferredStatTargetsFromBuild(
      buildWithStats(const [
        MockStatTotal(id: MockStatId.health, value: 30),
        MockStatTotal(id: MockStatId.melee, value: 20),
        MockStatTotal(id: MockStatId.weapons, value: 110),
      ]),
    );
    expect(preferred.targets.keys, [ArmorStatName.weapons]);
    expect(preferred.targets[ArmorStatName.weapons], 110);
    expect(preferred.priorities, [ArmorStatName.weapons]);
  });

  test('no preferred stats → empty (regression)', () {
    expect(
      preferredStatTargetsFromBuild(buildWithStats(const [])).isEmpty,
      isTrue,
    );
    expect(
      preferredStatTargetsFromBuild(
        buildWithStats(const [
          MockStatTotal(id: MockStatId.health, value: 30),
          MockStatTotal(id: MockStatId.melee, value: 20),
        ]),
      ).isEmpty,
      isTrue,
    );
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
