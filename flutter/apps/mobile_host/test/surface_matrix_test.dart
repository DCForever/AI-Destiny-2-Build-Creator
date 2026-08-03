import 'package:destiny2_mobile_host/surface_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mobile surface matrix (UX rebuild baseline)', () {
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

    test('bottom nav keys match matrix bottomNav rows (Settings only)', () {
      final navFromMatrix = kMobileSurfaceMatrix
          .where((e) => e.bottomNav)
          .map((e) => e.key)
          .toList();
      expect(navFromMatrix, kMobileBottomNavKeys);
      expect(kMobileBottomNavKeys, ['settings']);
      expect(kMobileBottomNavLabels, ['Settings']);
    });

    test('equip and dim product-marked N/A (not silent MISS)', () {
      expect(mobileSurfaceByKey('equip')!.status, MobileSurfaceStatus.na);
      expect(mobileSurfaceByKey('dim')!.status, MobileSurfaceStatus.na);
    });

    test('stripped product areas are deferred until UX rebuild', () {
      expect(mobileSurfaceByKey('build')!.status, MobileSurfaceStatus.deferred);
      expect(mobileSurfaceByKey('catalog')!.status, MobileSurfaceStatus.deferred);
      expect(
        mobileSurfaceByKey('optimizer')!.status,
        MobileSurfaceStatus.deferred,
      );
    });

    test('settings PARTIAL and is the only bottomNav', () {
      expect(
        mobileSurfaceByKey('settings')!.status,
        MobileSurfaceStatus.partial,
      );
      expect(mobileSurfaceByKey('settings')!.bottomNav, isTrue);
    });
  });
}
