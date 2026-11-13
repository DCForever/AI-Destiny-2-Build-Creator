import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_controller.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_page.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_presentation.dart';
import 'package:destiny2_windows_host/dim_loadouts/dim_loadout_details_panel.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_cache_loader.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Skeptic blocker: enrichment cache keyed only by buildId+shareId stayed
/// stale after Fill In Apply/Undo (same ids, new MockBuild instances).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareId = 'syn-cache-fill';
  const loadout = CachedDimLoadout(
    shareId: shareId,
    name: 'Cache fill build',
    classType: 2,
    items: [
      CachedDimItem(
        hash: 7001,
        name: 'Swarmers',
        itemType: 'Leg Armor',
        tier: 'Exotic',
      ),
      // No kinetic in the DIM link — Fill In proposes Qua Nilus II.
    ],
    subclassPlugs: [],
    mods: [],
    artifactPerks: [],
    exotic: CachedDimExotic(
      hash: 7001,
      name: 'Swarmers',
      description: '',
    ),
  );

  const original = MockBuild(
    id: 'cache_fill',
    name: 'Cache fill build',
    subclass: 'Strand',
    exoticArmor: '',
    exoticWeapon: '',
    slots: [
      MockSlotAssignment(
        slot: 'primary',
        setId: 'exotic_weapon',
        pieceName: '',
        isExoticSlot: true,
      ),
    ],
    loop: 'loop',
    artifact: MockArtifact(name: '—', season: '—'),
    setBonuses: [],
    stats: [],
    dimLink: 'https://dim.gg/$shareId',
  );

  const inventory = [
    FillInInventoryItem(
      instanceId: 'qua-1',
      itemHash: 9101,
      name: 'Qua Nilus II',
      slot: EquipmentSlot.primary,
      isExotic: false,
      guardianClass: null,
      weaponType: 'Sidearm',
      damageType: 'Strand',
    ),
    FillInInventoryItem(
      instanceId: 'legs-1',
      itemHash: 7001,
      name: 'Swarmers',
      slot: EquipmentSlot.legs,
      isExotic: true,
      guardianClass: GuardianClass.warlock,
    ),
  ];

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
          body: BuildsMockPage(
            controller: controller,
            fillInCacheLoader: () async =>
                FillInCacheLoadResult.ok(inventory),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  test('enrichment cache hit requires identical source build', () {
    final cache = BuildsMockEnrichmentCache();
    final first = cache.enrich(original, loadout);
    expect(identical(cache.enrich(original, loadout), first), isTrue);

    final replaced = original.copyWith(
      slots: [
        const MockSlotAssignment(
          slot: 'primary',
          setId: 'exotic_weapon',
          pieceName: 'Qua Nilus II',
          isExoticSlot: true,
          filledIn: true,
        ),
      ],
    );
    // Same id + shareId, different instance — must not return the first hit.
    final second = cache.enrich(replaced, loadout);
    expect(identical(second, first), isFalse);
    expect(
      second.slots.singleWhere((s) => s.slot == 'primary').pieceName,
      'Qua Nilus II',
    );
    expect(
      second.slots.singleWhere((s) => s.slot == 'primary').filledIn,
      isTrue,
    );
  });

  testWidgets(
    'Fill In Apply refreshes detail+grid; Undo restores original',
    (tester) async {
      final fixture = BuildsMockFixture(
        sets: const [],
        builds: const [original],
        held: const [],
        swaps: const [],
      );
      final controller = BuildsMockController(
        fixture: fixture,
        dimStatus: DimLoadoutsPanelStatus.loaded,
        dimLoadouts: const [loadout],
      );
      await pumpPage(tester, controller: controller);

      // Warm enrichment cache with the original fixture object.
      await tester.tap(find.byKey(const Key('builds_mock_card_cache_fill')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('builds_mock_build_detail')), findsOneWidget);
      expect(
        find.byKey(const Key('builds_mock_not_filled_cache_fill')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('builds_mock_fill_in_cache_fill')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byKey(const Key('fill_in_dialog_cache_fill')), findsOneWidget);
      expect(
        find.textContaining('Similar pick: Qua Nilus II'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('fill_in_apply_to_build')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      // Detail under the dialog must show the filled pick (not stale cache).
      expect(
        find.byKey(const Key('builds_mock_filled_tag_cache_fill')),
        findsOneWidget,
      );
      expect(find.text('Filled in · Qua Nilus II'), findsWidgets);
      expect(find.text('Qua Nilus II'), findsWidgets);

      await tester.tap(find.byKey(const Key('fill_in_undo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        find.byKey(const Key('builds_mock_not_filled_cache_fill')),
        findsOneWidget,
      );
      expect(find.text('Filled in · Qua Nilus II'), findsNothing);

      // Re-Apply in the same dialog, then close and check the grid card.
      await tester.tap(find.byKey(const Key('fill_in_apply_to_build')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('Filled in · Qua Nilus II'), findsWidgets);

      await tester.tap(find.byKey(const Key('fill_in_close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fill_in_dialog_cache_fill')), findsNothing);
      expect(
        find.byKey(const Key('builds_mock_filled_tag_cache_fill')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('builds_mock_detail_back')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Browse cards omit the filled tag when filled; assert the pick name and
      // that the stale "Not filled in yet" chrome is gone.
      expect(
        find.byKey(const Key('builds_mock_not_filled_cache_fill')),
        findsNothing,
      );
      expect(find.text('Qua Nilus II'), findsWidgets);
      expect(find.text('Filled in'), findsWidgets);
    },
  );
}
