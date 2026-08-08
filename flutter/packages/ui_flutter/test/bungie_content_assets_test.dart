import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bungieContentPackageAsset', () {
    test('resolves shipped damage-type basename', () {
      const path =
          '/common/destiny2_content/icons/DestinyDamageTypeDefinition_3385a924fd3ccb92c343ade19f19a370.png';
      expect(
        bungieContentPackageAsset(path),
        'assets/bungie-content/icons/DestinyDamageTypeDefinition_3385a924fd3ccb92c343ade19f19a370.png',
      );
      expect(
        bungieContentPackageAsset('https://www.bungie.net$path'),
        isNotNull,
      );
    });

    test('unknown basename returns null (network fallback)', () {
      expect(
        bungieContentPackageAsset(
          '/common/destiny2_content/icons/not_in_package_zzzz.png',
        ),
        isNull,
      );
    });
  });

  group('BungieContentIcon local asset', () {
    testWidgets('renders package PNG without network for local basename',
        (tester) async {
      const path =
          '/common/destiny2_content/icons/56761c8361e33a367c6fa94f397d8692.png';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BungieContentIcon(pathOrUrl: path, size: 24),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      // Should not fall through to empty fallback only.
      final img = tester.widget<Image>(find.byType(Image));
      expect(img.image, isA<AssetImage>());
    });
  });

  group('DestinyWeaponTypeIcon package SVG', () {
    testWidgets('loads hand cannon silhouette asset', (tester) async {
      final visual = officialWeaponTypeVisual('Hand Cannon');
      expect(visual, isNotNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DestinyWeaponTypeIcon(visual: visual!, size: 24),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DestinyWeaponTypeIcon), findsOneWidget);
    });
  });

  group('weapon item art JPG', () {
    test('Ace of Spades icon resolves to package asset', () {
      const path =
          '/common/destiny2_content/icons/cdfbfd3f098329a367294f191070f8c4.jpg';
      expect(
        bungieContentPackageAsset(path),
        'assets/bungie-content/icons/cdfbfd3f098329a367294f191070f8c4.jpg',
      );
    });

    testWidgets('renders weapon JPG via BungieContentIcon', (tester) async {
      const path =
          '/common/destiny2_content/icons/a16c0c62d2153cb59ca7dd5565d66d6a.jpg';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BungieContentIcon(pathOrUrl: path, size: 32),
          ),
        ),
      );
      await tester.pump();
      final img = tester.widget<Image>(find.byType(Image));
      expect(img.image, isA<AssetImage>());
    });
  });
}
