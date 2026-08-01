import 'dart:convert';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_web_host/catalog/entity_bundle_loader.dart';
import 'package:test/test.dart';

void main() {
  final prodFixture = {
    'manifestVersion': 'entity-bundle-prod-1',
    'builtAt': '2026-07-25T12:00:00.000Z',
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

  final channelJson = {
    'schemaVersion': 1,
    'channelId': 'prod',
    'bundleVersion': 'entity-bundle-prod-1',
    'distribution': 'hybrid',
    'shipInAppPath': '/entities/prod/bundle.json',
  };

  group('WebEntityBundleLoader (DART-059 channel)', () {
    test('loads prod channel ship-in-app JSON (non-fixture version)', () async {
      final loader = WebEntityBundleLoader(
        channelUrl: '/entities/channel.json',
        fetcher: (url) async {
          if (url.endsWith('channel.json')) return jsonEncode(channelJson);
          if (url.contains('/entities/prod/')) return jsonEncode(prodFixture);
          throw StateError('unexpected url $url');
        },
        includeLegacyPrebuiltFallback: false,
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.ready);
      expect(status.version, 'entity-bundle-prod-1');
      expect(status.version, isNot(contains('prebuilt-mvp')));
      expect(status.itemCount, 3);
      expect(status.loadSource, EntityBundleLoadSource.shipInApp);
      expect(status.channelId, 'prod');
      expect(status.distribution, 'hybrid');
      expect(status.summaryLine, contains('ship-in-app'));
      expect(status.summaryLine, contains('no raw rebuild'));

      final solar = loader.browse(
        CatalogClientFilters(
          elements: FacetFilter(include: const ['Solar']),
        ),
      );
      expect(solar.map((e) => e.name), ['Solar Rocket']);
    });

    test('CDN failure falls back to ship-in-app (hybrid)', () async {
      final hybridChannel = {
        ...channelJson,
        'cdnUrl': 'https://cdn.example/entities/prod/bundle.json',
      };
      final loader = WebEntityBundleLoader(
        channelUrl: '/entities/channel.json',
        fetcher: (url) async {
          if (url.endsWith('channel.json')) return jsonEncode(hybridChannel);
          if (url.startsWith('https://cdn.example')) {
            throw StateError('cdn offline');
          }
          if (url.contains('/entities/prod/')) return jsonEncode(prodFixture);
          throw StateError('unexpected url $url');
        },
        includeLegacyPrebuiltFallback: false,
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.ready);
      expect(status.loadSource, EntityBundleLoadSource.shipInApp);
      expect(status.version, 'entity-bundle-prod-1');
    });

    test('CDN success reports loadSource cdn', () async {
      final hybridChannel = {
        ...channelJson,
        'cdnUrl': 'https://cdn.example/entities/prod/bundle.json',
      };
      final loader = WebEntityBundleLoader(
        injectedChannel: EntityBundleChannel.fromJson(hybridChannel),
        channelUrl: '',
        fetcher: (url) async {
          if (url.startsWith('https://cdn.example')) {
            return jsonEncode(prodFixture);
          }
          throw StateError('should not fall back: $url');
        },
        includeLegacyPrebuiltFallback: false,
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.ready);
      expect(status.loadSource, EntityBundleLoadSource.cdn);
    });

    test('surfaces total failure without throwing out of load', () async {
      final loader = WebEntityBundleLoader(
        injectedChannel: EntityBundleChannel.defaultProd,
        channelUrl: '',
        fetcher: (_) async => throw StateError('network down'),
        includeLegacyPrebuiltFallback: false,
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.error);
      expect(status.error, contains('network down'));
    });

    test('empty stores → empty phase', () async {
      final loader = WebEntityBundleLoader(
        bundleUrl: '/entities/prod/bundle.json',
        channelUrl: '',
        injectedChannel: EntityBundleChannel.defaultProd,
        fetcher: (_) async => jsonEncode({
          'manifestVersion': 'entity-bundle-prod-empty',
          'builtAt': '2026-07-25T00:00:00.000Z',
          'stores': <String, dynamic>{},
        }),
        includeLegacyPrebuiltFallback: false,
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.empty);
      expect(status.version, 'entity-bundle-prod-empty');
    });

    test('single-url override still works (compat)', () async {
      final loader = WebEntityBundleLoader(
        fetcher: (_) async => jsonEncode(prodFixture),
        bundleUrl: kDefaultProdBundleUrl,
        channelUrl: '',
        injectedChannel: EntityBundleChannel.defaultProd,
        includeLegacyPrebuiltFallback: false,
      );
      final status = await loader.load();
      expect(status.phase, EntityBundleLoadPhase.ready);
      expect(status.itemCount, 3);
    });

    test('candidates never use Next manifest API paths', () {
      final candidates = resolveEntityBundleCandidates(
        EntityBundleChannel.defaultProd,
      );
      assertNoNextManifestEntityUrls(candidates);
      for (final c in candidates) {
        expect(isForbiddenNextManifestEntityUrl(c.url), isFalse);
        expect(c.url.contains('/api/'), isFalse);
      }
    });
  });
}
