import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

const items = <CatalogItem>[
  CatalogItem(
    hash: 1,
    name: 'Zebra',
    slot: 'Energy',
    element: 'Void',
    ammo: 'Special',
    itemTypeName: 'Grenade Launcher',
    isExotic: false,
  ),
  CatalogItem(
    hash: 2,
    name: 'Alpha',
    slot: 'Power',
    element: 'Solar',
    ammo: 'Heavy',
    itemTypeName: 'Rocket Launcher',
    isExotic: true,
  ),
  CatalogItem(
    hash: 3,
    name: 'Beta',
    slot: 'Energy',
    element: 'Solar',
    ammo: 'Primary',
    itemTypeName: 'Auto Rifle',
    isExotic: false,
  ),
  CatalogItem(
    hash: 4,
    name: 'Synthoceps',
    slot: 'Gauntlets',
    classType: 'Titan',
    frame: 'Brawler',
    isExotic: true,
  ),
];

/// Weapons-only slice for slot → element nesting (armor has no element).
List<CatalogItem> get weapons =>
    items.where((i) => i.ammo != null).toList(growable: false);

int _leafCount(List<CatalogGroupNode> roots) {
  var n = 0;
  void walk(CatalogGroupNode node) {
    if (node.children.isEmpty) {
      n += node.items.length;
    } else {
      for (final c in node.children) {
        walk(c);
      }
    }
  }

  for (final r in roots) {
    walk(r);
  }
  return n;
}

void main() {
  group('groupCatalogItems', () {
    test('empty dimensions → single All results bucket, preserves input order',
        () {
      final groups = groupCatalogItems(items, const []);
      expect(groups, hasLength(1));
      expect(groups.single.key, '__all__');
      expect(groups.single.label, 'All results');
      // Input order (not alpha re-sort) so weapons sort survives group-by none.
      expect(
        groups.single.items.map((i) => i.name).toList(),
        ['Zebra', 'Alpha', 'Beta', 'Synthoceps'],
      );
    });

    test('group by element partitions without dropping items', () {
      final groups = groupCatalogItems(items, const [
        CatalogGroupDimension.element,
      ]);
      final total = groups.fold<int>(0, (n, g) => n + g.items.length);
      expect(total, items.length);
      final byLabel = {for (final g in groups) g.label: g.items};
      expect(byLabel.keys.toSet(), {
        'Solar',
        'Unknown element',
        'Void',
      });
      // Encounter order within Solar: Alpha (hash2) then Beta (hash3).
      expect(byLabel['Solar']!.map((i) => i.name), ['Alpha', 'Beta']);
    });

    test('multi-dim composite keys preserve filter membership', () {
      final groups = groupCatalogItems(items, const [
        CatalogGroupDimension.ammo,
        CatalogGroupDimension.archetype,
      ]);
      final total = groups.fold<int>(0, (n, g) => n + g.items.length);
      expect(total, items.length);
      expect(
        groups.any((g) => g.label == 'Heavy · Rocket Launcher'),
        isTrue,
      );
    });

    test('group labels are alpha-sorted', () {
      final groups = groupCatalogItems(items, const [
        CatalogGroupDimension.element,
      ]);
      final labels = groups.map((g) => g.label).toList();
      final sorted = List<String>.from(labels)
        ..sort((a, b) => compareDisplayName(a, b));
      expect(labels, sorted);
    });
  });

  group('groupCatalogItemsNested', () {
    test('empty dimensions → single All results root, preserves input order',
        () {
      final roots = groupCatalogItemsNested(items, const []);
      expect(roots, hasLength(1));
      final root = roots.single;
      expect(root.key, '__all__');
      expect(root.label, 'All results');
      expect(root.count, items.length);
      expect(root.children, isEmpty);
      expect(
        root.items.map((i) => i.name).toList(),
        ['Zebra', 'Alpha', 'Beta', 'Synthoceps'],
      );
    });

    test('single dim ≡ flat list shape (keys + leaf membership)', () {
      const dims = [CatalogGroupDimension.element];
      final flat = groupCatalogItems(items, dims);
      final nested = groupCatalogItemsNested(items, dims);

      expect(nested.map((n) => n.key).toList(), flat.map((g) => g.key).toList());
      expect(
        nested.map((n) => n.label).toList(),
        flat.map((g) => g.label).toList(),
      );
      for (var i = 0; i < flat.length; i++) {
        expect(nested[i].children, isEmpty);
        expect(nested[i].count, flat[i].items.length);
        expect(
          nested[i].items.map((e) => e.hash).toList(),
          flat[i].items.map((e) => e.hash).toList(),
        );
      }
    });

    test('nest by slot → element: path keys, rollups, children, leaf items', () {
      final roots = groupCatalogItemsNested(weapons, const [
        CatalogGroupDimension.slot,
        CatalogGroupDimension.element,
      ]);

      expect(_leafCount(roots), weapons.length);
      // Sibling roots alpha-sorted: Energy, Power
      expect(roots.map((r) => r.label).toList(), ['Energy', 'Power']);

      final energy = roots.firstWhere((r) => r.key == 'Energy');
      expect(energy.label, 'Energy');
      expect(energy.count, 2); // Zebra + Beta
      expect(energy.items, isEmpty);
      expect(energy.isExpandable, isTrue);
      // Children alpha: Solar, Void
      expect(energy.children.map((c) => c.label).toList(), ['Solar', 'Void']);

      final energySolar = energy.children.firstWhere((c) => c.label == 'Solar');
      expect(energySolar.key, 'Energy · Solar');
      expect(energySolar.count, 1);
      expect(energySolar.children, isEmpty);
      expect(energySolar.items.map((i) => i.name), ['Beta']);

      final energyVoid = energy.children.firstWhere((c) => c.label == 'Void');
      expect(energyVoid.key, 'Energy · Void');
      expect(energyVoid.items.map((i) => i.name), ['Zebra']);

      final power = roots.firstWhere((r) => r.key == 'Power');
      expect(power.count, 1);
      expect(power.children, hasLength(1));
      expect(power.children.single.key, 'Power · Solar');
      expect(power.children.single.items.map((i) => i.name), ['Alpha']);
    });

    test('reorder dimensions re-parents the tree (same membership)', () {
      final bySlotElement = groupCatalogItemsNested(weapons, const [
        CatalogGroupDimension.slot,
        CatalogGroupDimension.element,
      ]);
      final byElementSlot = groupCatalogItemsNested(weapons, const [
        CatalogGroupDimension.element,
        CatalogGroupDimension.slot,
      ]);

      expect(_leafCount(bySlotElement), weapons.length);
      expect(_leafCount(byElementSlot), weapons.length);

      // slot→element: Energy holds Solar+Void children
      expect(bySlotElement.map((r) => r.key).toSet(), {'Energy', 'Power'});
      expect(
        bySlotElement
            .firstWhere((r) => r.key == 'Energy')
            .children
            .map((c) => c.key)
            .toSet(),
        {'Energy · Solar', 'Energy · Void'},
      );

      // element→slot: Solar holds Energy+Power children (re-parented)
      expect(
        byElementSlot.map((r) => r.key).toSet(),
        {'Solar', 'Void'},
      );
      final solar = byElementSlot.firstWhere((r) => r.key == 'Solar');
      expect(solar.count, 2); // Alpha + Beta
      expect(
        solar.children.map((c) => c.key).toSet(),
        {'Solar · Energy', 'Solar · Power'},
      );
      expect(
        solar.children
            .firstWhere((c) => c.key == 'Solar · Energy')
            .items
            .map((i) => i.name),
        ['Beta'],
      );
      expect(
        solar.children
            .firstWhere((c) => c.key == 'Solar · Power')
            .items
            .map((i) => i.name),
        ['Alpha'],
      );
    });

    test('armor dims share the same nested API (class → slot)', () {
      final armor = items.where((i) => i.classType != null).toList();
      final roots = groupCatalogItemsNested(armor, const [
        CatalogGroupDimension.classType,
        CatalogGroupDimension.slot,
      ]);
      expect(roots, hasLength(1));
      expect(roots.single.key, 'Titan');
      expect(roots.single.count, 1);
      expect(roots.single.children.single.key, 'Titan · Gauntlets');
      expect(
        roots.single.children.single.items.map((i) => i.name),
        ['Synthoceps'],
      );
    });

    test('filters applied before group only — tree never re-filters', () {
      // Contract: caller filters first (BR-CAT-006); group sees only the slice.
      final solarOnly =
          items.where((i) => i.element == 'Solar').toList(growable: false);
      final roots = groupCatalogItemsNested(solarOnly, const [
        CatalogGroupDimension.slot,
        CatalogGroupDimension.element,
      ]);
      expect(_leafCount(roots), solarOnly.length);
      // No Void branch appears even though unfiltered set has Void items.
      final allKeys = <String>{};
      void collect(CatalogGroupNode n) {
        allKeys.add(n.key);
        for (final c in n.children) {
          collect(c);
        }
      }

      for (final r in roots) {
        collect(r);
      }
      expect(allKeys.any((k) => k.contains('Void')), isFalse);
      expect(
        roots.expand((r) => r.children).expand((c) => c.items).map((i) => i.hash),
        unorderedEquals(solarOnly.map((i) => i.hash)),
      );
    });

    test('catalogGroupPathKey matches flat composite separator', () {
      expect(
        catalogGroupPathKey(['Heavy', 'Rocket Launcher']),
        'Heavy · Rocket Launcher',
      );
      expect(catalogGroupPathSeparator, ' · ');
    });
  });

  group('collapse helpers (view-only BR-CAT-007)', () {
    late List<CatalogGroupNode> tree;

    setUp(() {
      tree = groupCatalogItemsNested(weapons, const [
        CatalogGroupDimension.slot,
        CatalogGroupDimension.element,
      ]);
    });

    test('expandableCatalogGroupKeys lists only non-leaf path keys', () {
      final keys = expandableCatalogGroupKeys(tree);
      expect(keys, {'Energy', 'Power'});
      expect(keys.contains('Energy · Solar'), isFalse);
    });

    test('collapsed parent hides descendants without rewriting membership', () {
      // Nothing expanded → only roots visible.
      final collapsed = flattenVisibleCatalogGroupNodes(tree, const {});
      expect(collapsed.map((e) => e.node.key).toList(), ['Energy', 'Power']);
      expect(collapsed.every((e) => e.depth == 0), isTrue);
      // Underlying tree still has children + rollups.
      expect(tree.firstWhere((r) => r.key == 'Energy').count, 2);
      expect(tree.firstWhere((r) => r.key == 'Energy').children, isNotEmpty);
    });

    test('expanding Energy reveals its children only', () {
      final visible = flattenVisibleCatalogGroupNodes(tree, {'Energy'});
      expect(
        visible.map((e) => (e.node.key, e.depth)).toList(),
        [
          ('Energy', 0),
          ('Energy · Solar', 1),
          ('Energy · Void', 1),
          ('Power', 0),
        ],
      );
    });

    test('isCatalogGroupExpanded is pure set membership', () {
      expect(isCatalogGroupExpanded('Energy', {'Energy'}), isTrue);
      expect(isCatalogGroupExpanded('Power', {'Energy'}), isFalse);
    });

    test('expand-all via expandable keys shows full outline', () {
      final all = expandableCatalogGroupKeys(tree);
      final visible = flattenVisibleCatalogGroupNodes(tree, all);
      expect(visible, hasLength(2 + 2 + 1)); // Energy, 2 kids, Power, 1 kid
    });
  });

  group('compareDisplayName', () {
    test('case-insensitive', () {
      expect(compareDisplayName('alpha', 'Beta'), lessThan(0));
      expect(compareDisplayName('BETA', 'alpha'), greaterThan(0));
      expect(compareDisplayName('Same', 'same'), 0);
    });
  });
}
