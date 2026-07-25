import 'dart:convert';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_web_host/catalog/entity_bundle_loader.dart';
import 'package:test/test.dart';

void main() {
  final fixture = {
    'manifestVersion': 'prebuilt-test-1',
    'builtAt': '2026-07-25T00:00:00.000Z',
    'counts': {'weapons': 2, 'exotic-armor': 1},
    'stores': {
      'weapons': [
        {
          'hash': 1,
          'name': 'Void GL',
          'searchName': 'void gl',
          'icon': null,
          'slot': 'Energy',
          'element': 'Void',
          'ammo': 'Special',
          'frame': 'Adaptive Frame',
          'itemTypeName': 'Grenade Launcher',
          'originTraitHashes': <int>[],
          'perkColumns': <Map<String, dynamic>>[],
        },
        {
          'hash': 2,
          'name': 'Solar Rocket',
          'searchName': 'solar rocket',
          'icon': null,
          'slot': 'Power',
          'element': 'Solar',
          'ammo': 'Heavy',
          'frame': 'Adaptive Frame',
          'itemTypeName': 'Rocket Launcher',
          'originTraitHashes': <int>[],
          'perkColumns': <Map<String, dynamic>>[],
        },
      ],
      'exotic-armor': [
        {
          'hash': 3,
          'name': 'Synthoceps',
          'searchName': 'synthoceps',
          'icon': null,
          'classType': 'Titan',
          'slot': 'Gauntlets',
          'intrinsic': {
            'name': 'Biotic Enhancements',
            'description': 'Improved melee.',
          },
          'archetype': 'Brawler',
          'flavorText': '',
        },
      ],
    },
  };

  group('WebEntityBundleLoader', () {
    test('loads prebuilt JSON via fetcher (no raw rebuild)', () async {
      final loader = WebEntityBundleLoader(
        fetcher: (_) async => jsonEncode(fixture),
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.ready);
      expect(status.version, 'prebuilt-test-1');
      expect(status.itemCount, 3);
      expect(status.summaryLine, contains('prebuilt'));
      expect(status.summaryLine, contains('no raw rebuild'));

      final solar = loader.browse(
        CatalogClientFilters(
          elements: FacetFilter(include: const ['Solar']),
        ),
      );
      expect(solar.map((e) => e.name), ['Solar Rocket']);
    });

    test('surfaces fetch error without throwing out of load', () async {
      final loader = WebEntityBundleLoader(
        fetcher: (_) async => throw StateError('network down'),
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.error);
      expect(status.error, contains('network down'));
    });

    test('empty stores → empty phase', () async {
      final loader = WebEntityBundleLoader(
        fetcher: (_) async => jsonEncode({
          'manifestVersion': 'empty-1',
          'builtAt': '2026-07-25T00:00:00.000Z',
          'stores': <String, dynamic>{},
        }),
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.empty);
      expect(status.version, 'empty-1');
    });
  });
}
