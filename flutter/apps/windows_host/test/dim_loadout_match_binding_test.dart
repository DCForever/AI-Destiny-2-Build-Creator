import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_controller.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_page.dart';
import 'package:destiny2_windows_host/dim_loadouts/dim_loadout_details_panel.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CachedDimLoadout cached({
    required String shareId,
    required String name,
    required String notes,
  }) {
    return CachedDimLoadout(
      shareId: shareId,
      name: name,
      classType: 2,
      exotic: const CachedDimExotic(
        hash: 1,
        name: 'Contraverse Hold',
        description: 'Grants grenade energy.',
      ),
      items: const [],
      subclassPlugs: const [
        CachedDimNamedHash(hash: 2, name: 'Vortex Grenade'),
      ],
      mods: const [
        CachedDimNamedHash(hash: 3, name: 'Unique Mod For Share'),
      ],
      artifactPerks: const [],
      notes: notes,
    );
  }

  MockBuild mockBuild({
    required String name,
    String? dimLink,
  }) {
    return MockBuild(
      id: 'bind_01',
      name: name,
      subclass: 'Void',
      exoticArmor: 'Contraverse Hold',
      exoticWeapon: 'Osteo Striga',
      slots: const [
        MockSlotAssignment(
          slot: 'arms',
          setId: 'exotic',
          pieceName: 'Contraverse Hold',
          isExoticSlot: true,
        ),
      ],
      loop: 'test loop',
      artifact: const MockArtifact(name: 'Artifact', season: 'S27'),
      setBonuses: const [],
      stats: const [
        MockStatTotal(id: MockStatId.grenade, value: 100),
      ],
      dimLink: dimLink,
    );
  }

  BuildsMockFixture fixtureFor(MockBuild build) {
    return BuildsMockFixture(
      sets: const [MockArmorSet(id: 'set_x', name: 'X')],
      builds: [build],
      held: const [],
      swaps: const [],
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    BuildsMockController controller,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(body: BuildsMockPage(controller: controller)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  final twins = [
    cached(
      shareId: 'share-aaa',
      name: 'Grenade Core A',
      notes: 'NOTES_FOR_SHARE_AAA',
    ),
    cached(
      shareId: 'share-bbb',
      name: 'Grenade Core B',
      notes: 'NOTES_FOR_SHARE_BBB',
    ),
  ];

  testWidgets(
    'two loadouts share an exotic: shareId selects the correct card details',
    (tester) async {
      final build = mockBuild(
        name: 'Card Title',
        dimLink: 'https://dim.gg/share-bbb/Contraverse-Alt',
      );
      final controller = BuildsMockController(
        fixture: fixtureFor(build),
        dimStatus: DimLoadoutsPanelStatus.loaded,
        dimLoadouts: twins,
      );
      await pumpPage(tester, controller);

      // Browse defaults to grid; open the build detail to see DIM notes.
      await tester.tap(find.byKey(const Key('builds_mock_card_bind_01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('NOTES_FOR_SHARE_BBB'), findsOneWidget);
      expect(find.text('NOTES_FOR_SHARE_AAA'), findsNothing);
      expect(find.textContaining('ambiguous'), findsNothing);
      // Flat DIM LINK DETAILS panel is gone; notes render in the detail card.
      expect(find.text('DIM LINK DETAILS'), findsNothing);
    },
  );

  testWidgets(
    'two loadouts share an exotic: exact name selects the correct card',
    (tester) async {
      final build = mockBuild(name: 'Grenade Core A');
      final controller = BuildsMockController(
        fixture: fixtureFor(build),
        dimStatus: DimLoadoutsPanelStatus.loaded,
        dimLoadouts: twins,
      );
      await pumpPage(tester, controller);

      await tester.tap(find.byKey(const Key('builds_mock_card_bind_01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('NOTES_FOR_SHARE_AAA'), findsOneWidget);
      expect(find.text('NOTES_FOR_SHARE_BBB'), findsNothing);
    },
  );

  testWidgets(
    'exotic-only match shows ambiguous (2 loadouts) and never picks',
    (tester) async {
      final build = mockBuild(name: 'Unrelated Card Title');
      final controller = BuildsMockController(
        fixture: fixtureFor(build),
        dimStatus: DimLoadoutsPanelStatus.loaded,
        dimLoadouts: twins,
      );
      await pumpPage(tester, controller);

      await tester.tap(find.byKey(const Key('builds_mock_card_bind_01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('ambiguous (2 loadouts)'), findsOneWidget);
      expect(find.byKey(const Key('dim_loadout_details_ambiguous')), findsOneWidget);
      expect(find.text('NOTES_FOR_SHARE_AAA'), findsNothing);
      expect(find.text('NOTES_FOR_SHARE_BBB'), findsNothing);
    },
  );
}
