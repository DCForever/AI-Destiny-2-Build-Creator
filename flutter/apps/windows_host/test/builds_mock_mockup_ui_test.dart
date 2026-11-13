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

  MockBuild build({
    required String id,
    String name = 'Source name',
    String loop =
        'A long loop line that should clamp with an ellipsis when shown on browse cards only when present',
    List<MockSetBonus> setBonuses = const [],
    bool withWeapons = true,
    String? dimLink,
  }) {
    return MockBuild(
      id: id,
      name: name,
      subclass: 'Strand',
      exoticArmor: 'Swarmers',
      exoticWeapon: 'Barrow-Dyad',
      slots: [
        const MockSlotAssignment(
          slot: 'helmet',
          setId: 'set_a',
          pieceName: 'Helmet A',
          statTotal: 68,
        ),
        const MockSlotAssignment(
          slot: 'legs',
          setId: 'exotic',
          pieceName: 'Swarmers',
          isExoticSlot: true,
          statTotal: 70,
        ),
        if (withWeapons)
          const MockSlotAssignment(
            slot: 'primary',
            setId: 'exotic_weapon',
            pieceName: 'Barrow-Dyad',
            isExoticSlot: true,
          ),
      ],
      loop: loop,
      artifact: const MockArtifact(name: 'Example artifact', season: 'S'),
      setBonuses: setBonuses,
      stats: const [
        MockStatTotal(id: MockStatId.grenade, value: 100),
        MockStatTotal(id: MockStatId.health, value: 70),
      ],
      dimLink: dimLink,
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

  testWidgets(
    'Not filled in yet tag; no mods on grid; loop clamped; combined 4pc',
    (tester) async {
      final fixture = BuildsMockFixture(
        sets: const [MockArmorSet(id: 'set_a', name: 'Set A')],
        builds: [
          build(
            id: 'u1',
            dimLink: 'https://dim.gg/syn-u1',
            setBonuses: const [
              MockSetBonus(
                setId: 'set_a',
                setName: "Apostate's Blade",
                pieces: 2,
                tier: '2pc',
                text: '2pc: Example 2-piece set bonus text.',
              ),
              MockSetBonus(
                setId: 'set_a',
                setName: "Apostate's Blade",
                pieces: 4,
                tier: '4pc',
                text: '4pc: Example 4-piece set bonus text.',
              ),
            ],
          ),
        ],
        held: const [],
        swaps: const [],
      );
      final controller = BuildsMockController(
        fixture: fixture,
        dimStatus: DimLoadoutsPanelStatus.loaded,
        dimLoadouts: const [
          CachedDimLoadout(
            shareId: 'syn-u1',
            name: 'Source name',
            classType: 2,
            items: [],
            subclassPlugs: [],
            mods: [
              CachedDimNamedHash(hash: 1, name: 'Harmonic Siphon'),
            ],
            artifactPerks: [],
            subclass: CachedDimSubclass(
              hash: 1,
              name: 'Strand',
              superName: 'Needlestorm',
            ),
          ),
        ],
      );

      await pumpPage(tester, controller: controller);

      expect(find.byKey(const Key('builds_mock_not_filled_u1')), findsWidgets);
      expect(find.text('Harmonic Siphon'), findsNothing);
      expect(find.byKey(const Key('builds_mock_loop_u1')), findsOneWidget);
      final loop =
          tester.widget<Text>(find.byKey(const Key('builds_mock_loop_u1')));
      expect(loop.maxLines, 1);
      expect(loop.overflow, TextOverflow.ellipsis);
      expect(find.text('None'), findsNothing);
      expect(find.text('0 artifact perks'), findsNothing);
      expect(
        find.byKey(const Key('builds_mock_set_bonus_set_a_4pc')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('builds_mock_set_bonus_set_a_2pc')),
        findsNothing,
      );
      expect(find.byKey(const Key('builds_mock_weapon_table')), findsWidgets);
      expect(find.byKey(const Key('builds_mock_armor_table')), findsWidgets);
      expect(find.byKey(const Key('builds_mock_derived_title')), findsWidgets);
    },
  );

  testWidgets('Optimize tabs disabled with coming with Optimize label',
      (tester) async {
    final controller = BuildsMockController(
      fixture: BuildsMockFixture(
        sets: const [],
        builds: [build(id: 't1', loop: '')],
        held: const [],
        swaps: const [],
      ),
    );
    await pumpPage(tester, controller: controller);
    expect(find.byKey(const Key('builds_mock_optimize_tabs')), findsOneWidget);
    expect(find.textContaining('coming with Optimize'), findsOneWidget);

    final tabs = tester.widget<SegmentedButton<String>>(
      find.byKey(const Key('builds_mock_optimize_tabs')),
    );
    final pool = tabs.segments.singleWhere((s) => s.value == 'pool');
    final reopt = tabs.segments.singleWhere((s) => s.value == 'reopt');
    expect(pool.enabled, isFalse);
    expect(reopt.enabled, isFalse);
  });

  testWidgets('detail shows mods; grid does not; flat DIM list gone',
      (tester) async {
    final fixture = BuildsMockFixture(
      sets: const [],
      builds: [
        build(id: 'd1', loop: 'short loop', dimLink: 'https://dim.gg/syn-d1'),
      ],
      held: const [],
      swaps: const [],
    );
    final controller = BuildsMockController(
      fixture: fixture,
      dimStatus: DimLoadoutsPanelStatus.loaded,
      dimLoadouts: const [
        CachedDimLoadout(
          shareId: 'syn-d1',
          name: 'Source name',
          classType: 2,
          items: [],
          subclassPlugs: [
            CachedDimNamedHash(hash: 1, name: 'Healing Rift'),
            CachedDimNamedHash(hash: 2, name: 'Burst Glide'),
            CachedDimNamedHash(hash: 3, name: 'Needlestorm'),
            CachedDimNamedHash(hash: 4, name: 'Arcane Needle'),
            CachedDimNamedHash(hash: 5, name: 'Threadling Grenade'),
            CachedDimNamedHash(hash: 6, name: "Weaver's Call"),
            CachedDimNamedHash(hash: 7, name: 'The Wanderer'),
          ],
          mods: [
            CachedDimNamedHash(hash: 9, name: 'Harmonic Siphon'),
          ],
          artifactPerks: [
            CachedDimNamedHash(hash: 10, name: 'Artifact Perk A'),
          ],
          notes: 'Strand notes',
          subclass: CachedDimSubclass(
            hash: 1,
            name: 'Strand',
            superName: 'Needlestorm',
          ),
        ),
      ],
    );

    await pumpPage(tester, controller: controller);
    expect(find.text('Harmonic Siphon'), findsNothing);

    await tester.tap(find.byKey(const Key('builds_mock_card_d1')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('builds_mock_build_detail')), findsOneWidget);
    expect(find.text('Harmonic Siphon'), findsWidgets);
    expect(find.text('Strand notes'), findsOneWidget);
    expect(find.text('DIM LINK DETAILS'), findsNothing);
    expect(find.text('Proposed swaps (dry-run — local UI only)'), findsNothing);
  });
}
