import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('destiny_official_icons', () {
    test('element maps include void official purple + CDN path', () {
      final v = officialElementVisual('void');
      expect(v, isNotNull);
      expect(v!.color.toARGB32(), 0xFFB184C5);
      expect(v.iconPath, contains('DestinyDamageTypeDefinition_'));
      expect(v.iconUrl, startsWith('https://www.bungie.net/'));
    });

    test('ammo heavy is official purple (shape differentiates from void)', () {
      final h = officialAmmoVisual('Heavy');
      expect(h, isNotNull);
      expect(h!.color.toARGB32(), 0xFFB184C5);
      expect(h.iconPath, isNotEmpty);
      expect(officialAmmoVisual('Special')!.color.toARGB32(), 0xFF7AC143);
    });

    test('weapon frame tolerates missing Frame suffix', () {
      expect(officialWeaponFrameVisual('Precision Frame'), isNotNull);
      expect(officialWeaponFrameVisual('precision'), isNotNull);
      expect(officialWeaponFrameVisual('Wave Frame')?.iconPath, isNotEmpty);
      expect(officialWeaponFrameVisual(null), isNull);
      expect(officialWeaponFrameVisual('Unknown Frame XYZ'), isNull);
    });

    test('case-insensitive element lookup', () {
      expect(officialElementVisual('Solar')?.color.toARGB32(), 0xFFF2721B);
      expect(officialElementVisual('ARC')?.color.toARGB32(), 0xFF85C5EC);
    });
  });
}
