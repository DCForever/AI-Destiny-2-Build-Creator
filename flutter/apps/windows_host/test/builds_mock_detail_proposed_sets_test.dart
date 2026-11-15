import 'package:destiny2_windows_host/builds_mock/builds_mock_controller.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_page.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MockBuild build({
    required String id,
    List<MockSetBonus> setBonuses = const [],
    List<MockSlotAssignment> slots = const [],
  }) {
    return MockBuild(
      id: id,
      name: 'Source name',
      subclass: 'Strand',
      exoticArmor: 'Swarmers',
      exoticWeapon: '',
      slots: slots,
      loop: 'loop',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: setBonuses,
      stats: const [],
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required BuildsMockController controller,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: BuildsMockPage(controller: controller),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('detail shows proposed 4pc set boxes', (tester) async {
    final controller = BuildsMockController(
      fixture: BuildsMockFixture(
        sets: const [MockArmorSet(id: 'Techsec', name: 'Techsec')],
        builds: [
          build(
            id: 'with_sets',
            setBonuses: const [
              MockSetBonus(
                setId: 'Techsec',
                setName: 'Techsec',
                pieces: 2,
                tier: '2pc',
                text: '2pc: example',
              ),
              MockSetBonus(
                setId: 'Techsec',
                setName: 'Techsec',
                pieces: 4,
                tier: '4pc',
                text: '4pc: example',
              ),
            ],
          ),
        ],
        held: const [],
        swaps: const [],
      ),
    );
    await pumpPage(tester, controller: controller);
    await tester.tap(find.byKey(const Key('builds_mock_card_with_sets')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_build_detail')), findsOneWidget);
    expect(
      find.byKey(const Key('builds_mock_set_bonus_boxes')),
      findsWidgets,
    );
    expect(
      find.byKey(const Key('builds_mock_set_bonus_Techsec_4pc')),
      findsWidgets,
    );
    // Combined 4pc — no separate 2pc box.
    expect(
      find.byKey(const Key('builds_mock_set_bonus_Techsec_2pc')),
      findsNothing,
    );
  });

  testWidgets('detail with no proposed sets shows no set-bonus boxes',
      (tester) async {
    final controller = BuildsMockController(
      fixture: BuildsMockFixture(
        sets: const [],
        builds: [build(id: 'plain')],
        held: const [],
        swaps: const [],
      ),
    );
    await pumpPage(tester, controller: controller);
    await tester.tap(find.byKey(const Key('builds_mock_card_plain')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_build_detail')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_set_bonus_boxes')), findsNothing);
  });

  testWidgets('detail derives proposed 2+2 from slot setIds when setBonuses empty',
      (tester) async {
    final controller = BuildsMockController(
      fixture: BuildsMockFixture(
        sets: const [
          MockArmorSet(id: 'Alpha', name: 'Alpha'),
          MockArmorSet(id: 'Beta', name: 'Beta'),
        ],
        builds: [
          build(
            id: 'from_slots',
            slots: const [
              MockSlotAssignment(
                slot: 'helmet',
                setId: 'Alpha',
                pieceName: 'Alpha Helm',
              ),
              MockSlotAssignment(
                slot: 'arms',
                setId: 'Alpha',
                pieceName: 'Alpha Arms',
              ),
              MockSlotAssignment(
                slot: 'chest',
                setId: 'Beta',
                pieceName: 'Beta Chest',
              ),
              MockSlotAssignment(
                slot: 'legs',
                setId: 'Beta',
                pieceName: 'Beta Legs',
              ),
            ],
          ),
        ],
        held: const [],
        swaps: const [],
      ),
    );
    await pumpPage(tester, controller: controller);
    await tester.tap(find.byKey(const Key('builds_mock_card_from_slots')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_build_detail')), findsOneWidget);
    expect(find.byKey(const Key('builds_mock_set_bonus_boxes')), findsWidgets);
    expect(
      find.byKey(const Key('builds_mock_set_bonus_Alpha_2pc')),
      findsWidgets,
    );
    expect(
      find.byKey(const Key('builds_mock_set_bonus_Beta_2pc')),
      findsWidgets,
    );
  });
}
