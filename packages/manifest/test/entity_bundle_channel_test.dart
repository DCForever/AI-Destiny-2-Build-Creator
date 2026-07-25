import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('EntityBundleChannel', () {
    test('parses hybrid channel with versioning fields', () {
      final channel = EntityBundleChannel.fromJson({
        'schemaVersion': 1,
        'channelId': 'prod',
        'bundleVersion': 'entity-bundle-prod-1',
        'distribution': 'hybrid',
        'shipInAppPath': '/entities/prod/bundle.json',
        'notes': 'test',
      });
      expect(channel.channelId, 'prod');
      expect(channel.bundleVersion, 'entity-bundle-prod-1');
      expect(channel.distribution, EntityBundleDistribution.hybrid);
      expect(channel.shipInAppPath, kDefaultProdEntityBundleUrl);
      expect(channel.hasCdn, isFalse);
      expect(channel.toJson()['distribution'], 'hybrid');
    });

    test('requires channelId and bundleVersion and shipInAppPath', () {
      expect(
        () => EntityBundleChannel.fromJson({'bundleVersion': 'v1'}),
        throwsA(isA<EntityBundleChannelException>()),
      );
      expect(
        () => EntityBundleChannel.fromJson({
          'channelId': 'prod',
          'shipInAppPath': '/x',
        }),
        throwsA(isA<EntityBundleChannelException>()),
      );
    });

    test('defaultProd matches published paths', () {
      expect(
        EntityBundleChannel.defaultProd.shipInAppPath,
        kDefaultProdEntityBundleUrl,
      );
      expect(
        EntityBundleChannel.defaultProd.distribution,
        EntityBundleDistribution.hybrid,
      );
      expect(
        EntityBundleChannel.defaultProd.bundleVersion,
        startsWith('entity-bundle-prod-'),
      );
    });
  });

  group('resolveEntityBundleCandidates', () {
    test('hybrid with CDN tries CDN then ship-in-app then legacy', () {
      final channel = EntityBundleChannel(
        schemaVersion: 1,
        channelId: 'prod',
        bundleVersion: 'entity-bundle-prod-1',
        distribution: EntityBundleDistribution.hybrid,
        shipInAppPath: '/entities/prod/bundle.json',
        cdnUrl: 'https://cdn.example/entities/prod/bundle.json',
      );
      final candidates = resolveEntityBundleCandidates(channel);
      expect(candidates.map((c) => c.source).toList(), [
        EntityBundleLoadSource.cdn,
        EntityBundleLoadSource.shipInApp,
        EntityBundleLoadSource.legacyPrebuilt,
      ]);
      expect(candidates.first.url, contains('cdn.example'));
      assertNoNextManifestEntityUrls(candidates);
    });

    test('ship-in-app only omits CDN even if url present', () {
      final channel = EntityBundleChannel(
        schemaVersion: 1,
        channelId: 'prod',
        bundleVersion: 'entity-bundle-prod-1',
        distribution: EntityBundleDistribution.shipInApp,
        shipInAppPath: '/entities/prod/bundle.json',
        cdnUrl: 'https://cdn.example/bundle.json',
      );
      final candidates = resolveEntityBundleCandidates(
        channel,
        includeLegacyPrebuiltFallback: false,
      );
      expect(candidates, hasLength(1));
      expect(candidates.single.source, EntityBundleLoadSource.shipInApp);
    });

    test('hybrid without CDN still has ship-in-app primary', () {
      final candidates = resolveEntityBundleCandidates(
        EntityBundleChannel.defaultProd,
        includeLegacyPrebuiltFallback: false,
      );
      expect(candidates.single.url, kDefaultProdEntityBundleUrl);
      expect(candidates.single.source, EntityBundleLoadSource.shipInApp);
    });
  });

  group('Next manifest API guard', () {
    test('detects forbidden Next API paths', () {
      expect(isForbiddenNextManifestEntityUrl('/api/manifest/entities'), isTrue);
      expect(isForbiddenNextManifestEntityUrl('/entities/prod/bundle.json'), isFalse);
      expect(
        () => assertNoNextManifestEntityUrls([
          const EntityBundleUrlCandidate(
            url: 'https://app.example/api/manifest',
            source: EntityBundleLoadSource.cdn,
          ),
        ]),
        throwsA(isA<EntityBundleChannelException>()),
      );
    });
  });
}
