import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MockBuild build({
    List<MockSetBonus> setBonuses = const [],
    List<MockStatTotal> stats = const [],
  }) {
    return MockBuild(
      id: 'opt1',
      name: 'Optimize build',
      subclass: 'Strand',
      exoticArmor: 'Swarmers',
      exoticWeapon: '',
      slots: const [
        MockSlotAssignment(
          slot: 'legs',
          setId: 'exotic',
          pieceName: 'Swarmers',
          isExoticSlot: true,
        ),
      ],
      loop: '',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: setBonuses,
      stats: stats,
    );
  }

  List<FillInInventoryItem> armorPool() {
    return [
      for (final slot in EquipmentSlot.armorSlots) ...[
        FillInInventoryItem(
          instanceId: 'tech-${slot.wireName}',
          itemHash: 5010 + slot.index,
          slot: slot,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 501,
          name: 'Techsec ${slot.wireName}',
          location: 'vault',
          statValues: const {
            ArmorStatName.weapons: 22,
            ArmorStatName.health: 18,
          },
        ),
        FillInInventoryItem(
          instanceId: 'other-${slot.wireName}',
          itemHash: 6010 + slot.index,
          slot: slot,
          isExotic: slot == EquipmentSlot.legs,
          guardianClass: GuardianClass.warlock,
          armorSetHash: slot == EquipmentSlot.legs ? null : 777,
          name: slot == EquipmentSlot.legs
              ? 'Swarmers'
              : 'Other ${slot.wireName}',
          location: 'character',
          statValues: const {
            ArmorStatName.weapons: 8,
            ArmorStatName.health: 20,
          },
        ),
      ],
    ];
  }

  test('proposed 4pc set is passed as KitConstraints.setBonusGoals', () async {
    KitConstraints? seen;
    final c = BuildsOptimizeController(
      loadArmorItems: () async => armorPool(),
      setBonusKeyByItemHash: {
        for (final item in armorPool())
          if (!item.isExotic) item.itemHash: 'Techsec',
      },
      optimizeRunner: (request) async {
        seen = request.constraints;
        return const ArmorOptimizeResponse(
          combinations: [],
          truncated: false,
          evaluatedCount: 0,
        );
      },
    );
    await c.refreshArmorCsv();
    await c.runOptimize(
      build: build(
        setBonuses: const [
          MockSetBonus(
            setId: 'Techsec',
            setName: 'Techsec',
            pieces: 4,
            tier: '4pc',
            text: '4pc Techsec',
          ),
        ],
      ),
      mode: BuildsOptimizeMode.panel,
    );
    expect(seen, isNotNull);
    expect(seen!.setBonusGoals, [
      const SetBonusCoverageGoal(setBonusKey: 'Techsec', minPieces: 4),
    ]);
  });

  test('no proposed sets → empty setBonusGoals (regression)', () async {
    KitConstraints? seen;
    final c = BuildsOptimizeController(
      loadArmorItems: () async => armorPool(),
      optimizeRunner: (request) async {
        seen = request.constraints;
        return const ArmorOptimizeResponse(
          combinations: [],
          truncated: false,
          evaluatedCount: 0,
        );
      },
    );
    await c.refreshArmorCsv();
    await c.runOptimize(
      build: build(),
      mode: BuildsOptimizeMode.panel,
    );
    expect(seen!.setBonusGoals, isNull);
  });

  test('preferred stats: closer kit ranks first; Health/Melee targets included',
      () async {
    ArmorOptimizePiece piece({
      required EquipmentSlot slot,
      required int hash,
      required Map<ArmorStatName, int> stats,
      String? setKey,
      bool exotic = false,
    }) {
      return ArmorOptimizePiece(
        slot: slot,
        itemHash: hash,
        instanceId: 'id-$hash',
        itemName: 'P$hash',
        isExotic: exotic,
        setBonusKey: setKey,
        statValues: stats,
      );
    }

    final far = ArmorCombination(
      pieces: [
        for (final slot in EquipmentSlot.armorSlots)
          piece(
            slot: slot,
            hash: 10 + slot.index,
            stats: const {ArmorStatName.weapons: 10, ArmorStatName.health: 20},
            setKey: slot == EquipmentSlot.legs ? null : 'Techsec',
            exotic: slot == EquipmentSlot.legs,
          ),
      ],
      estimatedStats: const {
        ArmorStatName.weapons: 40,
        ArmorStatName.health: 80,
        ArmorStatName.melee: 80,
      },
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 120,
      meetsSoftThresholds: true,
    );
    final close = ArmorCombination(
      pieces: far.pieces,
      estimatedStats: const {
        ArmorStatName.weapons: 108,
        ArmorStatName.health: 30,
        ArmorStatName.melee: 20,
      },
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 158,
      meetsSoftThresholds: true,
    );

    final c = BuildsOptimizeController(
      loadArmorItems: () async => armorPool(),
      optimizeRunner: (request) async {
        // Soft thresholds must not hard-filter preferred targets.
        expect(request.requireThresholds, isFalse);
        expect(request.statThresholds?[ArmorStatName.weapons], 110);
        // Low preferred stats are closeness targets too (not dropped).
        expect(request.statThresholds?[ArmorStatName.health], 30);
        expect(request.statThresholds?[ArmorStatName.melee], 20);
        // Domain order: far first; host re-ranks by closeness.
        return ArmorOptimizeResponse(
          combinations: [far, close],
          truncated: false,
          evaluatedCount: 2,
        );
      },
    );
    await c.refreshArmorCsv();
    await c.runOptimize(
      build: build(
        stats: const [
          MockStatTotal(id: MockStatId.health, value: 30),
          MockStatTotal(id: MockStatId.weapons, value: 110),
          MockStatTotal(id: MockStatId.melee, value: 20),
        ],
      ),
      mode: BuildsOptimizeMode.panel,
    );
    expect(c.combinations.first.estimatedStats[ArmorStatName.weapons], 108);
    expect(c.combinations.first.estimatedStats[ArmorStatName.melee], 20);
    expect(c.combinations.last.estimatedStats[ArmorStatName.weapons], 40);
  });

  test('Melee target 20: kit at 20 ranks before overshoot 80', () async {
    final overshoot = ArmorCombination(
      pieces: const [],
      estimatedStats: const {ArmorStatName.melee: 80},
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 80,
      meetsSoftThresholds: true,
    );
    final onTarget = ArmorCombination(
      pieces: const [],
      estimatedStats: const {ArmorStatName.melee: 20},
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 20,
      meetsSoftThresholds: true,
    );
    final c = BuildsOptimizeController(
      loadArmorItems: () async => armorPool(),
      optimizeRunner: (_) async => ArmorOptimizeResponse(
        combinations: [overshoot, onTarget],
        truncated: false,
        evaluatedCount: 2,
      ),
    );
    await c.refreshArmorCsv();
    await c.runOptimize(
      build: build(
        stats: const [MockStatTotal(id: MockStatId.melee, value: 20)],
      ),
      mode: BuildsOptimizeMode.panel,
    );
    expect(c.combinations.first.estimatedStats[ArmorStatName.melee], 20);
    expect(c.combinations.last.estimatedStats[ArmorStatName.melee], 80);
  });

  test('Health target 30: kit at 30 ranks before overshoot 80', () async {
    final overshoot = ArmorCombination(
      pieces: const [],
      estimatedStats: const {ArmorStatName.health: 80},
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 80,
      meetsSoftThresholds: true,
    );
    final onTarget = ArmorCombination(
      pieces: const [],
      estimatedStats: const {ArmorStatName.health: 30},
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 30,
      meetsSoftThresholds: true,
    );
    final c = BuildsOptimizeController(
      loadArmorItems: () async => armorPool(),
      optimizeRunner: (_) async => ArmorOptimizeResponse(
        combinations: [overshoot, onTarget],
        truncated: false,
        evaluatedCount: 2,
      ),
    );
    await c.refreshArmorCsv();
    await c.runOptimize(
      build: build(
        stats: const [MockStatTotal(id: MockStatId.health, value: 30)],
      ),
      mode: BuildsOptimizeMode.panel,
    );
    expect(c.combinations.first.estimatedStats[ArmorStatName.health], 30);
    expect(c.combinations.last.estimatedStats[ArmorStatName.health], 80);
  });

  test('no preferred stats keeps runner order (regression)', () async {
    final first = ArmorCombination(
      pieces: const [],
      estimatedStats: const {ArmorStatName.weapons: 1},
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 1,
      meetsSoftThresholds: true,
    );
    final second = ArmorCombination(
      pieces: const [],
      estimatedStats: const {ArmorStatName.weapons: 99},
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 99,
      meetsSoftThresholds: true,
    );
    final c = BuildsOptimizeController(
      loadArmorItems: () async => armorPool(),
      optimizeRunner: (_) async => ArmorOptimizeResponse(
        combinations: [first, second],
        truncated: false,
        evaluatedCount: 2,
      ),
    );
    await c.refreshArmorCsv();
    await c.runOptimize(build: build(), mode: BuildsOptimizeMode.panel);
    expect(c.combinations.first.score, 1);
    expect(c.combinations.last.score, 99);
  });
}
