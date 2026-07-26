import 'package:destiny2_app/destiny2_app.dart';
import 'package:test/test.dart';

void main() {
  group('buildCatalogDenseMetaChips', () {
    test('includes exotic slot element ammo', () {
      final chips = buildCatalogDenseMetaChips(
        isExotic: true,
        slot: 'Chest',
        element: 'Solar',
        ammo: 'Primary',
        itemTypeName: 'Auto Rifle',
        frame: 'Precision',
      );
      expect(chips, containsAll(['Exotic', 'Chest', 'Solar', 'Primary']));
      expect(chips, isNot(contains('Instance')));
      expect(chips, isNot(contains('Wishlist')));
    });

    test('empty when no facets', () {
      expect(buildCatalogDenseMetaChips(), isEmpty);
    });
  });

  group('designation chrome', () {
    test('Verb and Element human labels', () {
      expect(formatDesignationChrome('verb', 'Scorch'), 'Verb: Scorch');
      expect(formatDesignationChrome('element', 'Solar'), 'Element: Solar');
      expect(designationWireKey('verb', 'Scorch'), 'verb::Scorch');
      expect(isVerbDesignation('Verb'), isTrue);
      expect(isElementDesignation('element'), isTrue);
      expect(elementChromeKey('element', 'Solar'), 'solar');
    });

    test('type alone when no subtype', () {
      expect(formatDesignationChrome('activity'), 'Activity');
    });
  });

  group('manifest readiness', () {
    test('labels', () {
      expect(
        manifestReadiness(hasEntityCache: false, isStale: true),
        ManifestReadiness.notDownloaded,
      );
      expect(
        manifestReadinessLabel(ManifestReadiness.notDownloaded),
        'NOT DOWNLOADED',
      );
      expect(
        manifestReadiness(hasEntityCache: true, isStale: true),
        ManifestReadiness.stale,
      );
      expect(manifestReadinessLabel(ManifestReadiness.stale), 'STALE');
      expect(
        manifestReadiness(hasEntityCache: true, isStale: false),
        ManifestReadiness.ready,
      );
      expect(manifestReadinessLabel(ManifestReadiness.ready), 'READY');
    });
  });
}
