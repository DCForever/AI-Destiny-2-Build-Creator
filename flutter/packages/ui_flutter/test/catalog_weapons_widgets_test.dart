import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildFlapThemeBase(),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NeonFacetChip', () {
    testWidgets('off → include → exclude → off visual/state', (tester) async {
      var facet = emptyFacet();
      late FacetChipState shown;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            shown = facetChipState(facet, 'Solar');
            return _wrap(
              NeonFacetChip(
                key: const Key('element_chip_Solar'),
                label: 'Solar',
                value: 'Solar',
                state: shown,
                onCycle: () {
                  setState(() {
                    facet = cycleFacetValue(facet, 'Solar');
                  });
                },
              ),
            );
          },
        ),
      );

      expect(shown, FacetChipState.off);
      await tester.tap(find.byKey(const Key('element_chip_Solar')));
      await tester.pump();
      expect(shown, FacetChipState.include);

      await tester.tap(find.byKey(const Key('element_chip_Solar')));
      await tester.pump();
      expect(shown, FacetChipState.exclude);

      await tester.tap(find.byKey(const Key('element_chip_Solar')));
      await tester.pump();
      expect(shown, FacetChipState.off);
    });

    testWidgets('official icon-only element/ammo chips resolve visuals',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              NeonFacetChip(
                key: const Key('icon_solar'),
                label: 'Solar',
                value: 'Solar',
                state: FacetChipState.include,
                iconOnly: true,
                onCycle: () {},
              ),
              NeonFacetChip(
                key: const Key('icon_heavy'),
                label: 'Heavy',
                value: 'Heavy',
                state: FacetChipState.off,
                iconOnly: true,
                onCycle: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('icon_solar')), findsOneWidget);
      expect(find.byKey(const Key('icon_heavy')), findsOneWidget);
      expect(officialElementVisual('Solar'), isNotNull);
      expect(officialAmmoVisual('Heavy'), isNotNull);
      // Icon-only: no primary text label widgets for element/ammo names.
      expect(find.text('Solar'), findsNothing);
      expect(find.text('Heavy'), findsNothing);
    });
  });

  group('CatalogFilterBar', () {
    testWidgets('More expands secondary; RESET clears facets+query',
        (tester) async {
      final query = TextEditingController(text: 'arc');
      var more = false;
      var elements = FacetFilter(include: const ['Solar']);
      var ammos = emptyFacet();
      var resetCount = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              SingleChildScrollView(
                child: CatalogFilterBar(
                  queryController: query,
                  onQueryChanged: (_) {},
                  activeFilterCount: 1 + (query.text.isEmpty ? 0 : 1),
                  moreExpanded: more,
                  onToggleMore: () => setState(() => more = !more),
                  onReset: () {
                    setState(() {
                      resetCount++;
                      elements = emptyFacet();
                      ammos = emptyFacet();
                      query.clear();
                    });
                  },
                  primaryGroups: [
                    CatalogFacetGroup(
                      id: 'element',
                      values: const ['Solar', 'Arc'],
                      facet: elements,
                      onCycle: (v) => setState(
                        () => elements = cycleFacetValue(elements, v),
                      ),
                    ),
                  ],
                  secondaryGroups: [
                    CatalogFacetGroup(
                      id: 'ammo',
                      values: const ['Primary', 'Special'],
                      facet: ammos,
                      onCycle: (v) =>
                          setState(() => ammos = cycleFacetValue(ammos, v)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.byKey(const Key('ammo_chip_Primary')), findsNothing);
      await tester.tap(find.byKey(const Key('catalog_more_filters_toggle')));
      await tester.pump();
      expect(find.byKey(const Key('ammo_chip_Primary')), findsOneWidget);

      await tester.tap(find.byKey(const Key('catalog_clear_filters')));
      await tester.pump();
      expect(resetCount, 1);
      expect(query.text, isEmpty);
      expect(isFacetEmpty(elements), isTrue);
    });
  });

  group('CatalogWeaponsGrid / CatalogWeaponCard', () {
    final items = [
      const CatalogItem(
        hash: 1,
        name: 'Edge Transit',
        slot: 'Energy',
        element: 'Void',
        ammo: 'Special',
        itemTypeName: 'Grenade Launcher',
        isExotic: false,
        owned: true,
        ownedCount: 2,
      ),
      const CatalogItem(
        hash: 2,
        name: "Dragon's Breath",
        slot: 'Power',
        element: 'Solar',
        ammo: 'Heavy',
        itemTypeName: 'Rocket Launcher',
        isExotic: true,
        owned: false,
        ownedCount: 0,
      ),
    ];

    testWidgets('cards render; selection highlight; identity-primary meta',
        (tester) async {
      int? selected;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              CatalogWeaponsGrid(
                items: items,
                selectedHash: selected,
                onSelect: (i) => setState(() => selected = i.hash),
              ),
            );
          },
        ),
      );

      expect(find.byKey(const Key('catalog_item_1')), findsOneWidget);
      expect(find.byKey(const Key('catalog_item_2')), findsOneWidget);
      expect(find.byKey(const Key('catalog_item_meta_1')), findsOneWidget);
      // Type-only body — weapon type text, not element/slot/ammo labels.
      expect(find.text('Grenade Launcher'), findsOneWidget);
      expect(find.text('Void'), findsNothing);
      expect(find.text('Energy'), findsNothing);

      await tester.tap(find.byKey(const Key('catalog_item_2')));
      await tester.pump();
      expect(selected, 2);
    });

    testWidgets('owned badge vs signed-out/not-owned; never fakes owned',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CatalogWeaponsGrid(
            items: items,
            showOwned: true,
          ),
        ),
      );
      expect(find.byKey(const Key('owned_badge_1')), findsOneWidget);
      expect(find.byKey(const Key('owned_badge_2')), findsNothing);

      await tester.pumpWidget(
        _wrap(
          CatalogWeaponsGrid(
            items: items,
            showOwned: false,
          ),
        ),
      );
      expect(find.byKey(const Key('owned_badge_1')), findsNothing);
      expect(find.byKey(const Key('owned_badge_2')), findsNothing);
    });
  });

  group('CatalogEmptyState', () {
    testWidgets('zero-match shows Clear filters only', (tester) async {
      var cleared = false;
      await tester.pumpWidget(
        _wrap(
          CatalogEmptyState(
            kind: CatalogEmptyKind.zeroMatch,
            message: 'No items match the current filters.',
            onClearFilters: () => cleared = true,
            onSync: () {},
            onOpenSettings: () {},
            onReload: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('catalog_empty_clear_filters')), findsOneWidget);
      expect(find.byKey(const Key('catalog_empty_sync')), findsNothing);
      await tester.tap(find.byKey(const Key('catalog_empty_clear_filters')));
      expect(cleared, isTrue);
    });

    testWidgets('owned empty Sync primary + Settings secondary; no invented rows',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CatalogEmptyState(
            kind: CatalogEmptyKind.ownedEmpty,
            message: 'No owned items in local inventory.',
            onSync: () {},
            onOpenSettings: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('catalog_empty_sync')), findsOneWidget);
      expect(find.byKey(const Key('catalog_empty_settings')), findsOneWidget);
      expect(find.byKey(const Key('catalog_list')), findsNothing);
    });

    testWidgets('missing manifest Reload + Settings actionable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CatalogEmptyState(
            kind: CatalogEmptyKind.missingManifest,
            message: 'No entity cache version.',
            onReload: () {},
            onOpenSettings: () {},
          ),
        ),
      );
      expect(find.byKey(const Key('catalog_empty_reload')), findsOneWidget);
      expect(find.byKey(const Key('catalog_empty_settings')), findsOneWidget);
    });
  });

  group('CatalogLoadingSkeleton', () {
    testWidgets('visible while loading; not empty-state CTAs', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CatalogLoadingSkeleton()),
      ));
      expect(find.byKey(const Key('catalog_loading')), findsOneWidget);
      expect(find.byKey(const Key('catalog_skeleton_0')), findsOneWidget);
      expect(find.byKey(const Key('catalog_empty_clear_filters')), findsNothing);
      expect(find.byKey(const Key('catalog_empty_sync')), findsNothing);
    });
  });

  group('NeonItemCard official chrome', () {
    testWidgets(
        'element/ammo/frame icons present; type-only body; rarity badge',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const NeonItemCard(
            name: 'Funnelweb',
            slot: 'Energy',
            element: 'Void',
            ammo: 'Heavy',
            frame: 'Precision Frame',
            typeLine: 'Submachine Gun',
            rarity: NeonItemRarity.legendary,
          ),
        ),
      );
      // Allow Image.network to settle / fail into fallback.
      await tester.pump();

      expect(find.byKey(const Key('neon_card_element_glyph')), findsOneWidget);
      expect(find.byKey(const Key('neon_card_foot_icons')), findsOneWidget);
      expect(find.byKey(const Key('neon_card_slot_icon')), findsOneWidget);
      expect(find.byKey(const Key('neon_card_ammo_icon')), findsOneWidget);
      expect(find.byKey(const Key('neon_card_frame_icon')), findsOneWidget);
      expect(find.byKey(const Key('neon_card_rarity_badge')), findsOneWidget);
      expect(find.text('◆'), findsOneWidget); // legendary chrome badge
      // Type-only body — no element/ammo text labels on card.
      expect(find.text('Submachine Gun'), findsOneWidget);
      expect(find.text('Void'), findsNothing);
      expect(find.text('Heavy'), findsNothing);
      // Official lookups resolve (mock Unicode not required).
      expect(officialElementVisual('Void')?.color.toARGB32(), 0xFFB184C5);
      expect(officialAmmoVisual('Heavy')?.color.toARGB32(), 0xFFB184C5);
      expect(officialWeaponFrameVisual('Precision Frame'), isNotNull);
    });
  });

  group('CatalogScopeControl', () {
    testWidgets('All / Owned cycle scope', (tester) async {
      var scope = CatalogScope.all;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              CatalogScopeControl(
                scope: scope,
                ownedLabel: 'Owned · 2',
                onChanged: (s) => setState(() => scope = s),
              ),
            );
          },
        ),
      );
      expect(find.byKey(const Key('catalog_scope_control')), findsOneWidget);
      await tester.tap(find.byKey(const Key('scope_chip_owned')));
      await tester.pump();
      expect(scope, CatalogScope.owned);
    });
  });

  group('CatalogWeaponsWorkspace', () {
    testWidgets('detail ~400px full-height beside main when selected',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 1200,
            height: 800,
            child: CatalogWeaponsWorkspace(
              main: ColoredBox(
                key: Key('main_pane'),
                color: Colors.red,
                child: SizedBox.expand(),
              ),
              detail: ColoredBox(
                key: Key('detail_content'),
                color: Colors.blue,
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
      );

      final pane = tester.getSize(find.byKey(const Key('catalog_detail_pane')));
      expect(pane.width, kCatalogWeaponsDetailWidth);
      expect(pane.height, greaterThan(700));
      expect(find.byKey(const Key('catalog_weapons_workspace')), findsOneWidget);
    });

    testWidgets('no detail pane when detail is null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CatalogWeaponsWorkspace(
            main: Text('main only'),
          ),
        ),
      );
      expect(find.byKey(const Key('catalog_detail_pane')), findsNothing);
    });
  });
}
