/// Catalog browse performance harness (GAP-PERF-01 / GAP-PERF-02).
///
/// Always-on soft budgets for CI; set `PERF_ASSERT=1` for stricter local/CI jobs.
/// See docs/catalog-performance-tests.md.
library;

import 'dart:io' show Platform;

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

/// Synthetic weapon catalog for scale tests (no Destiny JSON).
List<CatalogItem> syntheticWeapons(int n) {
  const elements = [
    'Kinetic',
    'Arc',
    'Solar',
    'Void',
    'Stasis',
    'Strand',
  ];
  const slots = ['Kinetic', 'Energy', 'Power'];
  const ammos = ['Primary', 'Special', 'Heavy'];
  const types = [
    'Auto Rifle',
    'Hand Cannon',
    'Scout Rifle',
    'Pulse Rifle',
    'Rocket Launcher',
    'Shotgun',
  ];

  return [
    for (var i = 0; i < n; i++)
      CatalogItem(
        hash: 1000000 + i,
        name: i % 17 == 0 ? 'Rare Mark $i' : 'Weapon $i',
        slot: slots[i % slots.length],
        element: elements[i % elements.length],
        ammo: ammos[i % ammos.length],
        itemTypeName: types[i % types.length],
        isExotic: i % 40 == 0,
        owned: i % 5 == 0,
        ownedCount: i % 5 == 0 ? (i % 3) + 1 : 0,
      ),
  ];
}

bool get _strict =>
    Platform.environment['PERF_ASSERT'] == '1' ||
    Platform.environment['PERF_ASSERT'] == 'true';

void _expectUnder(
  String label,
  Duration elapsed, {
  required Duration softMax,
  required Duration strictMax,
}) {
  // Always log for baseline visibility in CI.
  // ignore: avoid_print
  print(
    'PERF $label: ${elapsed.inMilliseconds}ms '
    '(soft≤${softMax.inMilliseconds}ms'
    '${_strict ? ', strict≤${strictMax.inMilliseconds}ms' : ''})',
  );
  final max = _strict ? strictMax : softMax;
  expect(
    elapsed,
    lessThan(max),
    reason: '$label took ${elapsed.inMilliseconds}ms '
        '(budget ${max.inMilliseconds}ms; '
        'strict=$_strict via PERF_ASSERT)',
  );
}

void main() {
  group('catalog performance (GAP-PERF-01 filter)', () {
    late List<CatalogItem> items5k;

    setUpAll(() {
      items5k = syntheticWeapons(5000);
    });

    test('filter all (empty filters) preserves membership and budget', () {
      final sw = Stopwatch()..start();
      final out = filterCatalogClient(
        items5k,
        const CatalogClientFilters(),
      );
      sw.stop();

      expect(out, hasLength(items5k.length));
      _expectUnder(
        'filterCatalogClient empty n=5000',
        sw.elapsed,
        softMax: const Duration(seconds: 2),
        strictMax: const Duration(milliseconds: 250),
      );
    });

    test('filter query + facet include hits budget and non-empty', () {
      final filters = CatalogClientFilters(
        query: 'Rare',
        slots: const FacetFilter(include: ['Energy']),
        elements: const FacetFilter(include: ['Solar', 'Arc']),
      );
      final sw = Stopwatch()..start();
      final out = filterCatalogClient(items5k, filters);
      sw.stop();

      expect(out, isNotEmpty);
      expect(out.length, lessThan(items5k.length));
      for (final i in out) {
        expect(i.name.toLowerCase(), contains('rare'));
        expect(i.slot, 'Energy');
        expect(['Solar', 'Arc'], contains(i.element));
      }
      _expectUnder(
        'filterCatalogClient query+facet n=5000',
        sw.elapsed,
        softMax: const Duration(seconds: 2),
        strictMax: const Duration(milliseconds: 300),
      );
    });

    test('owned scope does not scan past annotate contract', () {
      final filters = const CatalogClientFilters(scope: CatalogScope.owned);
      final out = filterCatalogClient(items5k, filters);
      expect(out.every((i) => i.ownedCount > 0), isTrue);
      // 1/5 of synthetic are owned
      expect(out.length, closeTo(1000, 50));
    });

    test('scale: 4k vs 1k filter ratio is not super-linear explosion', () {
      final a = syntheticWeapons(1000);
      final b = syntheticWeapons(4000);
      final filters = CatalogClientFilters(
        query: 'Weapon',
        exotic: false,
      );

      Duration once(List<CatalogItem> items) {
        final sw = Stopwatch()..start();
        filterCatalogClient(items, filters);
        sw.stop();
        return sw.elapsed;
      }

      // Warm
      once(a);
      once(b);
      final t1 = once(a);
      final t4 = once(b);
      final ratio = t4.inMicroseconds / (t1.inMicroseconds == 0 ? 1 : t1.inMicroseconds);
      // ignore: avoid_print
      print(
        'PERF filter scale t1k=${t1.inMilliseconds}ms '
        't4k=${t4.inMilliseconds}ms ratio=${ratio.toStringAsFixed(2)}',
      );
      final maxRatio = _strict ? 6.0 : 12.0;
      expect(
        ratio,
        lessThan(maxRatio),
        reason: 'filter 4k/1k ratio $ratio exceeds $maxRatio '
            '(suggests worse than linear cost)',
      );
    });
  });

  group('catalog performance (GAP-PERF-02 nested group)', () {
    late List<CatalogItem> items5k;
    late List<CatalogGroupDimension> dims;

    setUpAll(() {
      items5k = syntheticWeapons(5000);
      dims = const [
        CatalogGroupDimension.slot,
        CatalogGroupDimension.element,
      ];
    });

    test('nested group slot→element preserves membership and budget', () {
      final sw = Stopwatch()..start();
      final roots = groupCatalogItemsNested(items5k, dims);
      sw.stop();

      var leaves = 0;
      void walk(CatalogGroupNode n) {
        if (n.children.isEmpty) {
          leaves += n.items.length;
        } else {
          for (final c in n.children) {
            walk(c);
          }
        }
      }

      for (final r in roots) {
        walk(r);
      }
      expect(leaves, items5k.length);
      expect(roots, isNotEmpty);
      _expectUnder(
        'groupCatalogItemsNested slot→element n=5000',
        sw.elapsed,
        softMax: const Duration(seconds: 3),
        strictMax: const Duration(milliseconds: 400),
      );
    });

    test('flatten visible all-expanded budget', () {
      final roots = groupCatalogItemsNested(items5k, dims);
      final expanded = expandableCatalogGroupKeys(roots);
      final sw = Stopwatch()..start();
      final flat = flattenVisibleCatalogGroupNodes(roots, expanded);
      sw.stop();

      expect(flat, isNotEmpty);
      _expectUnder(
        'flattenVisibleCatalogGroupNodes n=5000',
        sw.elapsed,
        softMax: const Duration(seconds: 1),
        strictMax: const Duration(milliseconds: 150),
      );
    });

    test('collapse root hides subtree without dropping pure membership', () {
      final roots = groupCatalogItemsNested(items5k, dims);
      final allKeys = expandableCatalogGroupKeys(roots);
      final none = <String>{};
      final collapsed = flattenVisibleCatalogGroupNodes(roots, none);
      final open = flattenVisibleCatalogGroupNodes(roots, allKeys);
      // Collapsed shows only top-level (or fewer leaves visible).
      expect(collapsed.length, lessThan(open.length));
      // All expanded still covers full item membership via leaf walk.
      var leafItems = 0;
      for (final row in open) {
        if (row.node.children.isEmpty) leafItems += row.node.items.length;
      }
      expect(leafItems, items5k.length);
    });
  });
}
