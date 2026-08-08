import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('canonical orders', () {
    test('slot Kinetic → Energy → Power', () {
      expect(
        [...['Power', 'Kinetic', 'Energy']
          ..sort((a, b) => compareCatalogDimensionLabels(
                CatalogGroupDimension.slot,
                a,
                b,
              ))],
        ['Kinetic', 'Energy', 'Power'],
      );
    });

    test('ammo Primary → Special → Heavy', () {
      expect(
        [...['Heavy', 'Primary', 'Special']
          ..sort((a, b) => compareCatalogDimensionLabels(
                CatalogGroupDimension.ammo,
                a,
                b,
              ))],
        ['Primary', 'Special', 'Heavy'],
      );
    });

    test('element Kinetic → Stasis → Strand → Arc → Solar → Void', () {
      expect(
        [
          ...[
            'Void',
            'Solar',
            'Arc',
            'Strand',
            'Stasis',
            'Kinetic',
          ]..sort((a, b) => compareCatalogDimensionLabels(
                CatalogGroupDimension.element,
                a,
                b,
              )),
        ],
        kCatalogElementOrder,
      );
    });

    test('Prismatic is not a filter option', () {
      expect(catalogElements.contains('Prismatic'), isFalse);
      expect(catalogElements, kCatalogElementOrder);
    });

    test('Rocket Launcher is last among weapon archetypes', () {
      expect(catalogWeaponArchetypes.last, 'Rocket Launcher');
      expect(
        compareCatalogDimensionLabels(
          CatalogGroupDimension.archetype,
          'Rocket Launcher',
          'Sword',
        ),
        greaterThan(0),
      );
      expect(
        compareCatalogDimensionLabels(
          CatalogGroupDimension.archetype,
          'Auto Rifle',
          'Rocket Launcher',
        ),
        lessThan(0),
      );
    });

    test('nested group siblings follow slot then element order', () {
      final roots = groupCatalogItemsNested(
        const [
          CatalogItem(
            hash: 1,
            name: 'A',
            slot: 'Power',
            element: 'Solar',
            itemTypeName: 'Rocket Launcher',
            isExotic: false,
          ),
          CatalogItem(
            hash: 2,
            name: 'B',
            slot: 'Kinetic',
            element: 'Kinetic',
            itemTypeName: 'Hand Cannon',
            isExotic: false,
          ),
          CatalogItem(
            hash: 3,
            name: 'C',
            slot: 'Energy',
            element: 'Void',
            itemTypeName: 'Auto Rifle',
            isExotic: false,
          ),
          CatalogItem(
            hash: 4,
            name: 'D',
            slot: 'Energy',
            element: 'Arc',
            itemTypeName: 'SMG',
            isExotic: false,
          ),
        ],
        const [CatalogGroupDimension.slot, CatalogGroupDimension.element],
      );
      expect(roots.map((r) => r.label).toList(), ['Kinetic', 'Energy', 'Power']);
      final energy = roots.firstWhere((r) => r.label == 'Energy');
      // Arc before Void (canonical element order)
      expect(
        energy.children.map((c) => c.label).toList(),
        ['Arc', 'Void'],
      );
    });

    test('archetype group puts Rocket Launcher last', () {
      final roots = groupCatalogItemsNested(
        const [
          CatalogItem(
            hash: 1,
            name: 'Gjallarhorn',
            slot: 'Power',
            element: 'Solar',
            itemTypeName: 'Rocket Launcher',
            isExotic: true,
          ),
          CatalogItem(
            hash: 2,
            name: 'Ace',
            slot: 'Kinetic',
            element: 'Kinetic',
            itemTypeName: 'Hand Cannon',
            isExotic: true,
          ),
          CatalogItem(
            hash: 3,
            name: 'Lament',
            slot: 'Power',
            element: 'Solar',
            itemTypeName: 'Sword',
            isExotic: true,
          ),
        ],
        const [CatalogGroupDimension.archetype],
      );
      expect(
        roots.map((r) => r.label).toList(),
        ['Hand Cannon', 'Sword', 'Rocket Launcher'],
      );
    });
  });
}
