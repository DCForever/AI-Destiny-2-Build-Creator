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

  group('catalogFilterCollectionsCanSave', () {
    test('empty defaults not savable', () {
      expect(
        catalogFilterCollectionsCanSave(
          hasNonDefaultScope: false,
          hasQuery: false,
          hasExoticConstraint: false,
          hasFacetCriteria: false,
          hasGroupBy: false,
        ),
        isFalse,
      );
    });

    test('any criteria savable', () {
      expect(
        catalogFilterCollectionsCanSave(
          hasNonDefaultScope: true,
          hasQuery: false,
          hasExoticConstraint: false,
          hasFacetCriteria: false,
          hasGroupBy: false,
        ),
        isTrue,
      );
    });
  });

  group('CatalogFilterBar trailing placement', () {
    testWidgets('Saved appears before More and Reset', (tester) async {
      final query = TextEditingController(text: 'void');
      addTearDown(query.dispose);

      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: CatalogFilterBar(
              queryController: query,
              onQueryChanged: (_) {},
              activeFilterCount: 2,
              moreExpanded: false,
              onToggleMore: () {},
              onReset: () {},
              trailing: const CatalogFilterCollectionsControl(
                key: Key('saved_control'),
                items: [],
                browseModeLabel: 'weapons',
                canSave: true,
              ),
              primaryGroups: [
                CatalogFacetGroup(
                  id: 'element',
                  values: const ['Solar'],
                  facet: const FacetFilter(include: ['Solar']),
                  onCycle: (_) {},
                ),
              ],
              secondaryGroups: [
                CatalogFacetGroup(
                  id: 'ammo',
                  values: const ['Primary'],
                  facet: emptyFacet(),
                  onCycle: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final saved = tester.getTopLeft(
        find.byKey(const Key('catalog_filter_collections_saved')),
      );
      final more = tester.getTopLeft(
        find.byKey(const Key('catalog_more_filters_toggle')),
      );
      final reset = tester.getTopLeft(
        find.byKey(const Key('catalog_clear_filters')),
      );
      expect(saved.dx, lessThan(more.dx));
      expect(more.dx, lessThan(reset.dx));
    });
  });

  group('CatalogFilterCollectionsControl', () {
    testWidgets('empty menu shows Save CTA; apply fires id', (tester) async {
      String? applied;
      await tester.pumpWidget(
        _wrap(
          Align(
            alignment: Alignment.topLeft,
            child: CatalogFilterCollectionsControl(
              items: const [
                CatalogFilterCollectionItem(
                  id: 'wc-1',
                  name: 'Void HC PvP',
                  summary: 'owned · element:void',
                ),
              ],
              browseModeLabel: 'weapons',
              canSave: true,
              signedIn: true,
              onApply: (id) => applied = id,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('catalog_filter_collections_saved')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('catalog_filter_collections_menu')), findsOneWidget);
      expect(find.byKey(const Key('catalog_filter_collections_save')), findsOneWidget);
      expect(find.text('Void HC PvP'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('catalog_filter_collection_row_wc-1')),
      );
      await tester.tap(find.byKey(const Key('catalog_filter_collection_row_wc-1')));
      await tester.pumpAndSettle();
      expect(applied, 'wc-1');
    });

    testWidgets('dirty dot and active name on trigger', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CatalogFilterCollectionsControl(
            items: [
              CatalogFilterCollectionItem(
                id: 'a',
                name: 'Solar Specials',
                summary: 'element:solar',
              ),
            ],
            browseModeLabel: 'weapons',
            activeId: 'a',
            activeName: 'Solar Specials',
            dirty: true,
            canSave: true,
          ),
        ),
      );

      expect(
        find.byKey(const Key('catalog_filter_collections_dirty_dot')),
        findsOneWidget,
      );
      expect(find.textContaining('SOLAR'), findsOneWidget);
    });

    testWidgets('signed-out honesty; no save', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Align(
            alignment: Alignment.topLeft,
            child: CatalogFilterCollectionsControl(
              items: [],
              browseModeLabel: 'weapons',
              signedIn: false,
              canSave: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('catalog_filter_collections_saved')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('catalog_filter_collections_signed_out')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('catalog_filter_collections_save')), findsNothing);
    });

    testWidgets('at-cap shows hint', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Align(
            alignment: Alignment.topLeft,
            child: CatalogFilterCollectionsControl(
              items: [
                for (var i = 0; i < 3; i++)
                  CatalogFilterCollectionItem(
                    id: 'c$i',
                    name: 'Preset $i',
                    summary: 'all',
                  ),
              ],
              browseModeLabel: 'weapons',
              atCap: true,
              canSave: true,
              signedIn: true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('catalog_filter_collections_saved')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('catalog_filter_collections_cap_hint')),
        findsOneWidget,
      );
    });

    testWidgets('sheet mode opens bottom sheet', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CatalogFilterCollectionsControl(
            items: [],
            browseModeLabel: 'weapons',
            preferSheet: true,
            canSave: false,
            signedIn: true,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('catalog_filter_collections_saved')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('catalog_filter_collections_sheet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('catalog_filter_collections_empty')),
        findsOneWidget,
      );
    });

    testWidgets('rename/delete callbacks fire', (tester) async {
      String? renamedId;
      String? deletedId;
      await tester.pumpWidget(
        _wrap(
          Align(
            alignment: Alignment.topLeft,
            child: CatalogFilterCollectionsControl(
              items: const [
                CatalogFilterCollectionItem(
                  id: 'x1',
                  name: 'Keep',
                  summary: 'owned',
                ),
              ],
              browseModeLabel: 'weapons',
              canSave: true,
              signedIn: true,
              onRename: (id, name) async {
                renamedId = id;
                return null;
              },
              onDelete: (id) async {
                deletedId = id;
                return null;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('catalog_filter_collections_saved')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('catalog_filter_collection_rename_x1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('catalog_filter_collection_name_dialog')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('catalog_filter_collection_name_field')),
        'Renamed',
      );
      await tester.tap(find.byKey(const Key('catalog_filter_collection_name_confirm')));
      await tester.pumpAndSettle();
      expect(renamedId, 'x1');

      await tester.tap(find.byKey(const Key('catalog_filter_collections_saved')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('catalog_filter_collection_delete_x1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('catalog_filter_collection_confirm_ok')));
      await tester.pumpAndSettle();
      expect(deletedId, 'x1');
    });
  });
}
