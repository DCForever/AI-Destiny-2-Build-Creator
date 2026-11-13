import 'package:destiny2_windows_host/builds_mock/builds_mock_gear_tables.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_presentation.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MockBuild bareBuild({
    List<MockSlotAssignment> slots = const [],
    List<MockStatTotal> stats = const [],
    String exoticWeapon = '',
    String exoticArmor = '',
  }) {
    return MockBuild(
      id: 'b1',
      name: 'Source',
      subclass: 'Solar',
      exoticArmor: exoticArmor,
      exoticWeapon: exoticWeapon,
      slots: slots,
      loop: '',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: const [],
      stats: stats,
    );
  }

  test('MockSlotAssignment defaults to null statTotal (no fake 64)', () {
    const slot = MockSlotAssignment(
      slot: 'helmet',
      setId: 'dim_1',
      pieceName: 'Helmet A',
    );
    expect(slot.statTotal, isNull);
  });

  test('armor rows omit per-piece total when unknown', () {
    final rows = buildsMockArmorRows(
      build: bareBuild(
        slots: const [
          MockSlotAssignment(
            slot: 'helmet',
            setId: 'dim_1',
            pieceName: 'Helmet A',
          ),
          MockSlotAssignment(
            slot: 'arms',
            setId: 'dim_2',
            pieceName: 'Arms A',
            statTotal: 68,
          ),
        ],
      ),
    );
    expect(rows.singleWhere((r) => r.slotLabel == 'Helmet').statTotal, isNull);
    expect(rows.singleWhere((r) => r.slotLabel == 'Gauntlets').statTotal, 68);
  });

  testWidgets('STATS shows Stats unavailable when build has no totals',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: const Scaffold(
          body: BuildsMockStatsRow(stats: []),
        ),
      ),
    );
    expect(find.byKey(const Key('builds_mock_stats_unavailable')), findsOneWidget);
    expect(find.text('Stats unavailable'), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_stats_row')), findsNothing);
  });

  testWidgets('STATS renders six known armor totals', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: BuildsMockStatsRow(
            stats: [
              for (final id in kMockStatOrder) MockStatTotal(id: id, value: 70),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('builds_mock_stats_row')), findsOneWidget);
    expect(find.text('70'), findsNWidgets(6));
    expect(find.text('Stats unavailable'), findsNothing);
  });

  test('Fill In exotic Power substitute presents gold Exotic tag', () {
    final build = bareBuild(
      exoticWeapon: 'Gjallarhorn',
      slots: const [
        MockSlotAssignment(
          slot: 'heavy',
          setId: 'exotic_weapon',
          pieceName: 'Gjallarhorn',
          isExoticSlot: true,
          filledIn: true,
        ),
      ],
    );
    final rows = buildsMockWeaponRows(build: build);
    final power = rows.singleWhere((r) => r.slotLabel == 'Power');
    expect(power.itemName, 'Gjallarhorn');
    expect(power.isExotic, isTrue);
    expect(power.status, BuildsMockSlotStatus.filled);
  });

  test('exotic armor substitute presents Exotic set name', () {
    final build = bareBuild(
      exoticArmor: 'Briarbinds',
      slots: const [
        MockSlotAssignment(
          slot: 'arms',
          setId: 'exotic',
          pieceName: 'Briarbinds',
          isExoticSlot: true,
          filledIn: true,
        ),
      ],
    );
    final rows = buildsMockArmorRows(build: build);
    final arms = rows.singleWhere((r) => r.slotLabel == 'Gauntlets');
    expect(arms.isExotic, isTrue);
    expect(arms.setName, 'Exotic');
  });

  test('name match recovers exotic styling if isExoticSlot was dropped', () {
    final build = bareBuild(
      exoticWeapon: 'Gjallarhorn',
      slots: const [
        MockSlotAssignment(
          slot: 'heavy',
          setId: 'weapon',
          pieceName: 'Gjallarhorn',
          isExoticSlot: false,
        ),
      ],
    );
    final rows = buildsMockWeaponRows(build: build);
    expect(rows.singleWhere((r) => r.slotLabel == 'Power').isExotic, isTrue);
  });
}
