import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_derived_name.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_derived_title.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_loadout_card.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vendored Bungie basenames (ui_flutter package assets) for offline icons.
const _kArcIcon =
    '/common/destiny2_content/icons/DestinyDamageTypeDefinition_092d066688b879c807c3b460afdd61e6.png';
const _kSuperIcon =
    '/common/destiny2_content/icons/967fb4abc6ab98f74639d6c08e5f56ee.png';
const _kArmorIcon =
    '/common/destiny2_content/icons/161a3f06196563345afeacb46e9df88d.jpg';
const _kWeaponIcon =
    '/common/destiny2_content/icons/04652b3f85434968340359f93de0520b.jpg';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const name = BuildsMockDerivedName(
    classLabel: 'Warlock',
    elementLabel: 'Stormcaller',
    superLabel: 'Chaos Reach',
    exoticArmor: 'Vesper of Radius',
    exoticWeapon: 'Barrow-Dyad',
    synergy: null,
    duplicateSuffix: null,
    sourceName: 'Equipped source',
  );

  Future<void> pumpTitle(
    WidgetTester tester, {
    required BuildsMockDerivedName derived,
    String? superIconPath,
    String? exoticArmorIconPath,
    String? exoticWeaponIconPath,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(brightness: Brightness.light),
        home: Scaffold(
          body: BuildsMockDerivedTitle(
            name: derived,
            superIconPath: superIconPath,
            exoticArmorIconPath: exoticArmorIconPath,
            exoticWeaponIconPath: exoticWeaponIconPath,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'grid name: subclass/super/exotics render icons — not Stormcaller text or star',
    (tester) async {
      await pumpTitle(
        tester,
        derived: name,
        superIconPath: _kSuperIcon,
        exoticArmorIconPath: _kArmorIcon,
        exoticWeaponIconPath: _kWeaponIcon,
      );

      expect(find.byKey(const Key('builds_mock_derived_title')), findsOneWidget);
      expect(find.text('Stormcaller'), findsNothing);
      expect(find.byType(DestinySuperGlyph), findsNothing);
      expect(
        find.byKey(const Key('builds_mock_title_element_icon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('builds_mock_title_super_icon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('builds_mock_title_exotic_armor_icon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('builds_mock_title_exotic_weapon_icon')),
        findsOneWidget,
      );
      // Name line uses tooltips — exotic names are not spelled out.
      expect(find.text('Vesper of Radius'), findsNothing);
      expect(find.text('Barrow-Dyad'), findsNothing);
      // Sanity: Arc element path is the Stormcaller alias target.
      expect(officialElementVisual('Stormcaller')?.iconPath, _kArcIcon);
    },
  );

  testWidgets('missing super icon omits the super segment (no star)', (
    tester,
  ) async {
    await pumpTitle(
      tester,
      derived: name,
      superIconPath: null,
      exoticArmorIconPath: _kArmorIcon,
      exoticWeaponIconPath: _kWeaponIcon,
    );

    expect(find.byType(DestinySuperGlyph), findsNothing);
    expect(find.byKey(const Key('builds_mock_title_super_icon')), findsNothing);
    expect(find.text('Chaos Reach'), findsNothing);
    expect(
      find.byKey(const Key('builds_mock_title_element_icon')),
      findsOneWidget,
    );
  });

  testWidgets(
    'hostile superIconPath never hits network Image; shows BungieContentIcon fallback',
    (tester) async {
      await pumpTitle(
        tester,
        derived: name,
        // Only Super is hostile — keep other segments empty so the tree has
        // no unrelated AssetImage→errorBuilder→NetworkImage noise.
        superIconPath: 'https://evil.example/x.png',
      );

      final superFinder = find.byKey(const Key('builds_mock_title_super_icon'));
      expect(superFinder, findsOneWidget);
      expect(
        BungieContentIcon.resolveUrl('https://evil.example/x.png'),
        isNull,
      );
      // resolveUrl rejected → default DecoratedBox fallback, never Image.network.
      expect(
        find.descendant(of: superFinder, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        find.descendant(of: superFinder, matching: find.byType(DecoratedBox)),
        findsWidgets,
      );
      final superImages = tester.widgetList<Image>(
        find.descendant(of: superFinder, matching: find.byType(Image)),
      );
      expect(superImages.any((i) => i.image is NetworkImage), isFalse);
    },
  );

  testWidgets(
    'loadout card name line uses icons; exotic boxes keep name beside icon',
    (tester) async {
      const build = MockBuild(
        id: 'icon-card',
        name: 'Equipped source',
        subclass: 'Stormcaller',
        exoticArmor: 'Vesper of Radius',
        exoticWeapon: 'Barrow-Dyad',
        slots: [],
        loop: '',
        artifact: MockArtifact(name: '—', season: '—'),
        setBonuses: [],
        stats: [],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapTheme(brightness: Brightness.light),
          home: Scaffold(
            body: BuildsMockLoadoutCard(
              loadout: build,
              derivedName: name,
              density: BuildsMockCardDensity.tile,
              superIconPath: _kSuperIcon,
              exoticArmorIconPath: _kArmorIcon,
              exoticWeaponIconPath: _kWeaponIcon,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Stormcaller'), findsNothing);
      expect(find.byType(DestinySuperGlyph), findsNothing);
      expect(
        find.byKey(const Key('builds_mock_title_element_icon')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('builds_mock_title_super_icon')),
        findsOneWidget,
      );
      // Boxes keep name text next to the icon.
      expect(
        find.byKey(const Key('builds_mock_exotic_tile_icon_EXOTIC ARMOR')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('builds_mock_exotic_tile_EXOTIC ARMOR')),
        findsOneWidget,
      );
      expect(find.text('Vesper of Radius'), findsOneWidget);
      expect(find.text('Barrow-Dyad'), findsOneWidget);
    },
  );
}
