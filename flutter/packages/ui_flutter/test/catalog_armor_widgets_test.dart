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

const _helm = CatalogItem(
  hash: 101,
  name: 'Synthoceps',
  slot: 'Gauntlets',
  classType: 'Titan',
  isExotic: true,
  owned: true,
  ownedCount: 2,
);

const _chest = CatalogItem(
  hash: 102,
  name: 'Field-Tested Plate',
  slot: 'Chest',
  classType: 'Hunter',
  isExotic: false,
  owned: false,
  ownedCount: 0,
);

const _legs = CatalogItem(
  hash: 103,
  name: 'Stridehunt',
  slot: 'Legs',
  classType: 'Warlock',
  isExotic: false,
  owned: true,
  ownedCount: 1,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatalogArmorCard', () {
    testWidgets('no row stats; owned ×N only when showOwned', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              CatalogArmorCard(item: _helm, showOwned: true),
              CatalogArmorCard(
                key: const Key('signed_out_card'),
                item: _helm,
                showOwned: false,
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('catalog_item_101')), findsNWidgets(2));
      expect(find.byKey(const Key('owned_badge_101')), findsOneWidget);
      // No list-row stat numbers (Health/Melee/etc).
      expect(find.text('Health'), findsNothing);
      expect(find.text('Melee'), findsNothing);
      // Class/slot glyphs present.
      expect(find.byKey(const Key('armor_class_glyph_101')), findsWidgets);
      expect(find.byKey(const Key('armor_slot_glyph_101')), findsWidgets);
      expect(find.byKey(const Key('armor_exotic_badge_101')), findsWidgets);
    });

    testWidgets('signed-out never fakes owned', (tester) async {
      await tester.pumpWidget(
        _wrap(CatalogArmorCard(item: _helm, showOwned: false)),
      );
      expect(find.byKey(const Key('owned_badge_101')), findsNothing);
    });

    testWidgets('long titles do not wrap mid-word', (tester) async {
      const long = CatalogItem(
        hash: 999,
        name: 'An Insurmountable Skullfort',
        slot: 'Helmet',
        classType: 'Titan',
        isExotic: true,
      );
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 160,
            child: CatalogArmorCard(item: long),
          ),
        ),
      );
      final label = tester.widget<UnbrokenLabel>(
        find.byKey(const Key('catalog_item_name_999')),
      );
      expect(label.maxLines, 2);
      expect(label.text, 'An Insurmountable Skullfort');
      final painted = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('catalog_item_name_999')),
          matching: find.byType(Text),
        ),
      );
      expect(painted.semanticsLabel, 'An Insurmountable Skullfort');
      expect(painted.data, isNot(contains('Insurm\nountable')));
      expect(painted.data, contains('An'));
    });
  });

  group('CatalogArmorGrid', () {
    testWidgets('selection; one card per hash; sort fixture order',
        (tester) async {
      final sorted = sortCatalogArmor([_legs, _helm, _chest]);
      int? selected;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              SizedBox(
                width: 800,
                height: 600,
                child: CatalogArmorGrid(
                  items: sorted,
                  selectedHash: selected,
                  showOwned: true,
                  onSelect: (i) => setState(() => selected = i.hash),
                ),
              ),
            );
          },
        ),
      );

      // Grid keys present for each hash.
      expect(find.byKey(const Key('catalog_item_101')), findsOneWidget);
      expect(find.byKey(const Key('catalog_item_102')), findsOneWidget);
      expect(find.byKey(const Key('catalog_item_103')), findsOneWidget);
      // Sort: Gauntlets exotic (101) before Chest (102) before Legs (103).
      expect(sorted.map((i) => i.hash).toList(), [101, 102, 103]);

      await tester.tap(find.byKey(const Key('catalog_item_102')));
      await tester.pump();
      expect(selected, 102);
    });
  });

  group('facets + empty + loading', () {
    testWidgets('class/slot/exotic tri-state + zero-match Clear keys',
        (tester) async {
      var classFacet = emptyFacet();
      var slotFacet = emptyFacet();
      bool? exotic;
      var clearTapped = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return _wrap(
              Column(
                children: [
                  CatalogFilterBar(
                    queryController: TextEditingController(),
                    onQueryChanged: (_) {},
                    activeFilterCount: 1,
                    exotic: exotic,
                    onCycleExotic: () {
                      setState(() {
                        if (exotic == null) {
                          exotic = true;
                        } else if (exotic == true) {
                          exotic = false;
                        } else {
                          exotic = null;
                        }
                      });
                    },
                    onReset: () => setState(() => clearTapped = true),
                    primaryGroups: [
                      CatalogFacetGroup(
                        id: 'class',
                        values: catalogClassNames,
                        facet: classFacet,
                        onCycle: (v) => setState(
                          () => classFacet = cycleFacetValue(classFacet, v),
                        ),
                      ),
                      CatalogFacetGroup(
                        id: 'slot',
                        values: catalogArmorSlots,
                        facet: slotFacet,
                        onCycle: (v) => setState(
                          () => slotFacet = cycleFacetValue(slotFacet, v),
                        ),
                      ),
                    ],
                  ),
                  CatalogEmptyState(
                    kind: CatalogEmptyKind.zeroMatch,
                    message: 'No armor matches.',
                    onClearFilters: () => setState(() => clearTapped = true),
                  ),
                ],
              ),
            );
          },
        ),
      );

      expect(find.byKey(const Key('class_chip_Titan')), findsOneWidget);
      expect(find.byKey(const Key('slot_chip_Helmet')), findsOneWidget);
      expect(find.byKey(const Key('exotic_chip')), findsOneWidget);

      await tester.tap(find.byKey(const Key('class_chip_Titan')));
      await tester.pump();
      expect(facetChipState(classFacet, 'Titan'), FacetChipState.include);

      await tester.tap(find.byKey(const Key('exotic_chip')));
      await tester.pump();
      expect(exotic, isTrue);

      expect(find.byKey(const Key('catalog_empty_clear_filters')), findsOneWidget);
      await tester.tap(find.byKey(const Key('catalog_empty_clear_filters')));
      await tester.pump();
      expect(clearTapped, isTrue);
    });

    testWidgets('signed-out Owned sign-in; owned empty Sync+Settings; skeleton',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              SizedBox(
                height: 200,
                child: CatalogEmptyState(
                  kind: CatalogEmptyKind.ownedSignedOut,
                  message: 'Sign in to browse owned armor.',
                  onOpenSettings: () {},
                ),
              ),
              SizedBox(
                height: 200,
                child: CatalogEmptyState(
                  kind: CatalogEmptyKind.ownedEmpty,
                  message: 'No owned armor.',
                  onSync: () {},
                  onOpenSettings: () {},
                ),
              ),
              const SizedBox(
                height: 200,
                child: CatalogLoadingSkeleton(cellCount: 4),
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('catalog_empty_settings')), findsWidgets);
      expect(find.byKey(const Key('catalog_empty_sync')), findsOneWidget);
      expect(find.byKey(const Key('catalog_loading')), findsOneWidget);
      expect(find.byKey(const Key('catalog_skeleton_0')), findsOneWidget);
    });
  });
}
