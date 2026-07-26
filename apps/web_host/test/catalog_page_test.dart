import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_web_host/pages/catalog_page.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  final fixtures = [
    const CatalogItem(
      hash: 1,
      name: 'Void GL',
      slot: 'Energy',
      element: 'Void',
      ammo: 'Special',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 2,
      name: 'Solar Rocket',
      slot: 'Power',
      element: 'Solar',
      ammo: 'Heavy',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 3,
      name: 'Synthoceps',
      slot: 'Gauntlets',
      classType: 'Titan',
      isExotic: true,
    ),
  ];

  group('CatalogPage', () {
    testComponents('renders offline catalog rows from injected items', (
      tester,
    ) async {
      tester.pumpComponent(
        CatalogPage(
          initialItems: fixtures,
          initialVersion: 'fixture-1',
        ),
      );

      expect(find.text(CatalogPage.titleText), findsOneComponent);
      expect(find.textContaining('prebuilt'), findsComponents);
      expect(find.text('Void GL'), findsOneComponent);
      expect(find.text('Solar Rocket'), findsOneComponent);
      expect(find.text('Synthoceps'), findsOneComponent);
      expect(find.textContaining('3 result'), findsOneComponent);
      expect(find.textContaining('CLIENT_SECRET'), findsNothing);
      expect(find.textContaining('raw manifest rebuild'), findsOneComponent);
      expect(find.text('Owned'), findsOneComponent);
      expect(find.text('All'), findsOneComponent);
    });

    testComponents('empty injection shows empty state', (tester) async {
      tester.pumpComponent(
        const CatalogPage(
          initialItems: [],
          initialVersion: 'empty',
        ),
      );

      expect(find.text(CatalogPage.emptyText), findsOneComponent);
      expect(find.textContaining('0 result'), findsOneComponent);
    });

    testComponents('exotic facet include narrows list', (tester) async {
      tester.pumpComponent(
        CatalogPage(
          initialItems: fixtures,
          initialVersion: 'fixture-1',
        ),
      );

      expect(find.text('Void GL'), findsOneComponent);

      // First click → exotic only
      await tester.click(find.byKey(const ValueKey('facet-exotic')));
      await tester.pump();

      expect(find.text('Synthoceps'), findsOneComponent);
      expect(find.text('Void GL'), findsNothing);
      expect(find.textContaining('1 result'), findsOneComponent);
    });

    testComponents('slot and class facets (DART-062 GAP-UI-CATALOG-01)',
        (tester) async {
      tester.pumpComponent(
        CatalogPage(
          initialItems: fixtures,
          initialVersion: 'fixture-1',
        ),
      );

      await tester.click(find.byKey(const ValueKey('facet-slot-Power')));
      await tester.pump();
      expect(find.text('Solar Rocket'), findsOneComponent);
      expect(find.text('Void GL'), findsNothing);
      expect(find.text('Synthoceps'), findsNothing);

      // Cycle Power: include → exclude → off
      await tester.click(find.byKey(const ValueKey('facet-slot-Power')));
      await tester.pump();
      await tester.click(find.byKey(const ValueKey('facet-slot-Power')));
      await tester.pump();

      await tester.click(find.byKey(const ValueKey('facet-class-Titan')));
      await tester.pump();
      expect(find.text('Synthoceps'), findsOneComponent);
      expect(find.text('Void GL'), findsNothing);
      expect(find.textContaining('1 result'), findsOneComponent);
    });

    testComponents('group-by element shows headers without dropping rows',
        (tester) async {
      tester.pumpComponent(
        CatalogPage(
          initialItems: fixtures,
          initialVersion: 'fixture-1',
        ),
      );

      await tester.click(find.byKey(const ValueKey('group-chip-element')));
      await tester.pump();

      expect(find.textContaining('Solar (1)'), findsOneComponent);
      expect(find.textContaining('Void (1)'), findsOneComponent);
      expect(find.text('Solar Rocket'), findsOneComponent);
      expect(find.text('Void GL'), findsOneComponent);
      expect(find.text('Synthoceps'), findsOneComponent);
      expect(find.textContaining('3 result'), findsOneComponent);
    });
  });
}
