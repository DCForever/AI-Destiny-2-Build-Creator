import 'package:destiny2_mobile_host/surface_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mobile surface matrix (DART-057 / GAP-MOB-01)', () {
    test('covers required AppShell + equip/DIM/optimizer keys', () {
      final keys = kMobileSurfaceMatrix.map((e) => e.key).toSet();
      for (final required in kMobileMatrixRequiredKeys) {
        expect(keys, contains(required), reason: 'missing matrix key $required');
      }
      expect(kMobileSurfaceMatrix.length, kMobileMatrixRequiredKeys.length);
    });

    test('each entry has PASS/PARTIAL/MISS/N/A/deferred label', () {
      for (final e in kMobileSurfaceMatrix) {
        expect(
          e.status.label,
          anyOf('PASS', 'PARTIAL', 'MISS', 'N/A', 'deferred'),
        );
        expect(e.note, isNotEmpty);
      }
    });

    test('bottom nav keys match matrix bottomNav rows (Builds|Settings)', () {
      final navFromMatrix = kMobileSurfaceMatrix
          .where((e) => e.bottomNav)
          .map((e) => e.key)
          .toList();
      expect(navFromMatrix, kMobileBottomNavKeys);
      expect(kMobileBottomNavKeys, ['build', 'settings']);
      expect(kMobileBottomNavLabels, ['Builds', 'Settings']);
    });

    test('equip, dim, catalog product-marked N/A (not silent MISS)', () {
      expect(mobileSurfaceByKey('equip')!.status, MobileSurfaceStatus.na);
      expect(mobileSurfaceByKey('dim')!.status, MobileSurfaceStatus.na);
      expect(mobileSurfaceByKey('catalog')!.status, MobileSurfaceStatus.na);
    });

    test('optimizer deferred (GAP-FEAT-01)', () {
      expect(
        mobileSurfaceByKey('optimizer')!.status,
        MobileSurfaceStatus.deferred,
      );
    });

    test('build PASS and settings PARTIAL', () {
      expect(mobileSurfaceByKey('build')!.status, MobileSurfaceStatus.pass);
      expect(
        mobileSurfaceByKey('settings')!.status,
        MobileSurfaceStatus.partial,
      );
    });
  });
}
