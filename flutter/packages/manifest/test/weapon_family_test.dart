import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('weaponVersionKindFromName / stripWeaponVersionSuffix', () {
    test('detects Adept and Holofoil; strips for clean name', () {
      expect(weaponVersionKindFromName('Midnight Coup'), WeaponVersionKind.base);
      expect(
        weaponVersionKindFromName('Midnight Coup (Adept)'),
        WeaponVersionKind.adept,
      );
      expect(
        weaponVersionKindFromName('Midnight Coup Adept'),
        WeaponVersionKind.adept,
      );
      expect(
        weaponVersionKindFromName('Midnight Coup Holofoil'),
        WeaponVersionKind.holofoil,
      );
      expect(stripWeaponVersionSuffix('Midnight Coup (Adept)'), 'Midnight Coup');
      expect(stripWeaponVersionSuffix('Midnight Coup Holofoil'), 'Midnight Coup');
    });
  });

  group('groupWeaponFamilies', () {
    test('one family per name+slot/element/type; Adept/Holofoil merge', () {
      final items = [
        const CatalogItem(
          hash: 1,
          name: 'Midnight Coup',
          slot: 'Kinetic',
          element: 'Kinetic',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
          owned: true,
          ownedCount: 2,
        ),
        const CatalogItem(
          hash: 2,
          name: 'Midnight Coup (Adept)',
          slot: 'Kinetic',
          element: 'Kinetic',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
        const CatalogItem(
          hash: 3,
          name: 'Midnight Coup Holofoil',
          slot: 'Kinetic',
          element: 'Kinetic',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
          owned: false,
          ownedCount: 0,
        ),
        const CatalogItem(
          hash: 4,
          name: 'Ace of Spades',
          slot: 'Kinetic',
          element: 'Kinetic',
          itemTypeName: 'Hand Cannon',
          isExotic: true,
          owned: true,
          ownedCount: 1,
        ),
        // Different slot → separate family (under-merge OK for wrong type)
        const CatalogItem(
          hash: 5,
          name: 'Midnight Coup',
          slot: 'Energy',
          element: 'Solar',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
        ),
      ];

      final families = groupWeaponFamilies(items);
      expect(families.length, 3);

      final coup = families.firstWhere((f) => f.displayName == 'Midnight Coup' && f.cardItem.slot == 'Kinetic');
      expect(coup.members.length, 3);
      expect(coup.ownedTotal, 3);
      expect(coup.cardItem.name, 'Midnight Coup');
      expect(coup.primaryMember.hash, 1);
      expect(coup.ownedMembers.map((m) => m.label).toList(), ['Base', 'Adept']);
      expect(
        coup.ownedVersionChipMembers.map((m) => m.label).toList(),
        ['Base', 'Adept'],
      );

      final ace = families.firstWhere((f) => f.displayName == 'Ace of Spades');
      expect(ace.members.length, 1);
    });

    test('multi-hash same kind collapses to one grid chip', () {
      // Ribbontail-style: several Base definitions, no Adept suffix.
      final items = [
        for (final h in [10, 20, 30, 40, 50])
          CatalogItem(
            hash: h,
            name: 'Ribbontail',
            slot: 'Kinetic',
            element: 'Strand',
            itemTypeName: 'Trace Rifle',
            isExotic: false,
            owned: h <= 30,
            ownedCount: h <= 30 ? 1 : 0,
          ),
      ];
      final family = groupWeaponFamilies(items).single;
      expect(family.members.length, 5);
      expect(family.ownedTotal, 3);
      expect(family.ownedMembers.length, 3);
      // Grid chips: one Base only (not Base Base Base).
      expect(
        family.ownedVersionChipMembers.map((m) => m.label).toList(),
        ['Base'],
      );
      expect(family.ownedVersionChipMembers.single.hash, 10);
      // Detail labels disambiguate colliding kinds without hashes (BUG-005).
      final labels = family.members
          .map((m) => family.versionSwitchLabel(m))
          .toList();
      expect(labels.toSet().length, 5);
      // Base implied: multi-base uses #n + owned, never hex tails.
      expect(labels.first, '#1 ×1');
      expect(labels.any((l) => RegExp(r'[0-9a-f]{3,}').hasMatch(l)), isFalse);
      expect(labels.every((l) => !l.contains('Base')), isTrue);
    });
  });

  group('openVersionForFamily', () {
    late WeaponFamily family;

    setUp(() {
      family = groupWeaponFamilies([
        const CatalogItem(
          hash: 10,
          name: 'Beloved',
          slot: 'Energy',
          element: 'Solar',
          itemTypeName: 'Sniper Rifle',
          isExotic: false,
          owned: false,
          ownedCount: 0,
        ),
        const CatalogItem(
          hash: 11,
          name: 'Beloved (Adept)',
          slot: 'Energy',
          element: 'Solar',
          itemTypeName: 'Sniper Rifle',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
        const CatalogItem(
          hash: 12,
          name: 'Beloved Holofoil',
          slot: 'Energy',
          element: 'Solar',
          itemTypeName: 'Sniper Rifle',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
      ]).single;
    });

    test('owned max-power wins when power map provided', () {
      final opened = openVersionForFamily(
        family,
        maxPowerByHash: const {11: 1800, 12: 1810},
      );
      expect(opened.hash, 12);
    });

    test('base when no power and base owned', () {
      final withBaseOwned = groupWeaponFamilies([
        const CatalogItem(
          hash: 10,
          name: 'Beloved',
          slot: 'Energy',
          element: 'Solar',
          itemTypeName: 'Sniper Rifle',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
        const CatalogItem(
          hash: 11,
          name: 'Beloved (Adept)',
          slot: 'Energy',
          element: 'Solar',
          itemTypeName: 'Sniper Rifle',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
      ]).single;
      final opened = openVersionForFamily(withBaseOwned);
      expect(opened.hash, 10);
    });

    test('filter single-match wins', () {
      final opened = openVersionForFamily(
        family,
        filters: const CatalogClientFilters(query: 'adept'),
      );
      expect(opened.hash, 11);
    });

    test('stable base when nothing owned', () {
      final unowned = groupWeaponFamilies([
        const CatalogItem(
          hash: 20,
          name: 'Weighted Plate',
          slot: 'Energy',
          element: 'Void',
          itemTypeName: 'Shotgun',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 21,
          name: 'Weighted Plate (Adept)',
          slot: 'Energy',
          element: 'Void',
          itemTypeName: 'Shotgun',
          isExotic: false,
        ),
      ]).single;
      expect(openVersionForFamily(unowned).hash, 20);
    });
  });

  group('groupWeaponFamilyBrowse', () {
    test('multi-dim priority changes composite keys (slot·element vs element·slot)',
        () {
      final families = groupWeaponFamilies([
        const CatalogItem(
          hash: 1,
          name: 'A',
          slot: 'Kinetic',
          element: 'Kinetic',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 2,
          name: 'B',
          slot: 'Energy',
          element: 'Solar',
          itemTypeName: 'Auto Rifle',
          isExotic: false,
        ),
      ]);

      final bySlotElement = groupWeaponFamilyBrowse(
        families,
        const [CatalogGroupDimension.slot, CatalogGroupDimension.element],
      );
      expect(bySlotElement.map((g) => g.key).toList(), containsAll([
        'Kinetic · Kinetic',
        'Energy · Solar',
      ]));

      final byElementSlot = groupWeaponFamilyBrowse(
        families,
        const [CatalogGroupDimension.element, CatalogGroupDimension.slot],
      );
      expect(byElementSlot.map((g) => g.key).toList(), containsAll([
        'Kinetic · Kinetic',
        'Solar · Energy',
      ]));
    });
  });

  group('groupWeaponFamilyBrowseNested', () {
    test('nested slot→element uses segment labels + path keys', () {
      final families = groupWeaponFamilies([
        const CatalogItem(
          hash: 1,
          name: 'A',
          slot: 'Energy',
          element: 'Solar',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 2,
          name: 'B',
          slot: 'Energy',
          element: 'Arc',
          itemTypeName: 'Auto Rifle',
          isExotic: false,
        ),
      ]);
      final tree = groupWeaponFamilyBrowseNested(
        families,
        const [CatalogGroupDimension.slot, CatalogGroupDimension.element],
      );
      expect(tree, hasLength(1));
      expect(tree.single.label, 'Energy');
      expect(tree.single.count, 2);
      expect(tree.single.children.map((c) => c.label).toSet(), {'Arc', 'Solar'});
      expect(
        tree.single.children.map((c) => c.key).toSet(),
        {'Energy · Arc', 'Energy · Solar'},
      );
    });
  });

  group('filterWeaponFamilies', () {
    test('family visible if any member matches; exclude-all drops', () {
      final families = groupWeaponFamilies([
        const CatalogItem(
          hash: 1,
          name: 'Forbearance',
          slot: 'Energy',
          element: 'Arc',
          itemTypeName: 'Grenade Launcher',
          isExotic: false,
          owned: true,
          ownedCount: 1,
        ),
        const CatalogItem(
          hash: 2,
          name: 'Forbearance (Adept)',
          slot: 'Energy',
          element: 'Arc',
          itemTypeName: 'Grenade Launcher',
          isExotic: false,
          owned: true,
          ownedCount: 2,
        ),
        const CatalogItem(
          hash: 3,
          name: 'Edge Transit',
          slot: 'Energy',
          element: 'Void',
          itemTypeName: 'Grenade Launcher',
          isExotic: false,
          owned: false,
          ownedCount: 0,
        ),
      ]);

      final arcOnly = filterWeaponFamilies(
        families,
        CatalogClientFilters(elements: FacetFilter(include: const ['Arc'])),
      );
      expect(arcOnly.length, 1);
      expect(arcOnly.single.members.length, 2); // full family retained
      expect(arcOnly.single.ownedTotal, 3);

      final excludeArc = filterWeaponFamilies(
        families,
        CatalogClientFilters(elements: FacetFilter(exclude: const ['Arc'])),
      );
      expect(excludeArc.length, 1);
      expect(excludeArc.single.cardItem.name, 'Edge Transit');

      final ownedScope = filterWeaponFamilies(
        families,
        const CatalogClientFilters(scope: CatalogScope.owned),
      );
      expect(ownedScope.length, 1);
      expect(ownedScope.single.displayName, 'Forbearance');
    });
  });
}
