import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlapPalette', () {
    test('fromTokens maps dark success and element arc', () {
      final p = FlapPalette.fromTokens(FlapColorTokens.dark);
      expect(p.success.toARGB32(), kFlapSuccessDark);
      expect(p.elementArc.toARGB32(), kElementArcDark);
      expect(p.warning.toARGB32(), kFlapWarningDark);
    });
  });

  group('flapColumnFlexFactors', () {
    test('builds has five tracks matching cell roles', () {
      final f = flapColumnFlexFactors(kFlapColumnsBuilds);
      expect(f.length, kFlapColumnsBuilds.cellRoles.length);
      expect(f.every((x) => x >= 1), isTrue);
    });

    test('sets and synergy produce stable non-empty flex', () {
      expect(flapColumnFlexFactors(kFlapColumnsSets).length, 4);
      expect(flapColumnFlexFactors(kFlapColumnsSynergy).length, 4);
    });
  });

  group('buildFlapThemeBase', () {
    testWidgets('attaches FlapPalette and square card theme', (tester) async {
      final theme = buildFlapThemeBase();
      final palette = theme.extension<FlapPalette>();
      expect(palette, isNotNull);
      expect(palette!.success.toARGB32(), kFlapSuccessDark);
      expect(theme.cardTheme.elevation, 0);
      expect(theme.colorScheme.primary.toARGB32(), kFlapAccentDark);
      // Neon Network cyan-neon primary
      expect(kFlapAccentDark, 0xFF00E5FF);
      // google_fonts registers Orbitron / Inter faces on the theme.
      expect(theme.textTheme.titleLarge?.fontFamily, isNotNull);
      expect(
        theme.textTheme.titleLarge!.fontFamily!.toLowerCase(),
        anyOf(contains('orbitron'), contains('Orbitron')),
      );
      expect(
        theme.textTheme.bodyLarge?.fontFamily?.toLowerCase() ?? '',
        anyOf(contains('inter'), contains('Inter')),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              final tone = flapToneColor(context, kFlapToneSuccess);
              expect(tone.toARGB32(), kFlapSuccessDark);
              // One Lamp: success must not equal readiness primary (teal/amber).
              expect(
                tone.toARGB32(),
                isNot(Theme.of(context).colorScheme.primary.toARGB32()),
              );
              final arc = flapElementColor(context, 'arc');
              expect(arc!.toARGB32(), kElementArcDark);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('board widgets', () {
    testWidgets('FlapBoardHeader renders uppercase labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: const Scaffold(
            body: FlapBoardHeader(template: kFlapColumnsSets),
          ),
        ),
      );
      expect(find.text('NAME'), findsOneWidget);
      expect(find.text('TYPE'), findsOneWidget);
    });
  });

  group('Neon atmosphere', () {
    testWidgets('NeonShellBackground + NeonZone paint without error',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: const Scaffold(
            backgroundColor: Colors.transparent,
            body: NeonShellBackground(
              child: Center(
                child: NeonZone(
                  padding: EdgeInsets.all(12),
                  child: Text('zone-content', key: Key('zone_label')),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(NeonShellBackground), findsOneWidget);
      expect(find.byType(NeonZone), findsOneWidget);
      expect(find.byKey(const Key('zone_label')), findsOneWidget);
    });

    testWidgets('NeonLivePulse freezes under disableAnimations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: NeonLivePulse(
                child: Text('live', key: Key('pulse_child')),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('pulse_child')), findsOneWidget);
      // No animation controller ticks required — still mounted.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('pulse_child')), findsOneWidget);
    });

    test('neonZoneDecoration uses surface-based gradient', () {
      final p = FlapPalette.fromTokens(FlapColorTokens.dark);
      final d = neonZoneDecoration(p);
      expect(d.gradient, isNotNull);
      expect(d.borderRadius, BorderRadius.circular(kFlapRadius));
    });
  });

  group('NeonItemCard', () {
    test('neonItemRarity maps exotic and legendary labels', () {
      expect(neonItemRarity(isExotic: true), NeonItemRarity.exotic);
      expect(
        neonItemRarity(rarityLabel: 'Legendary'),
        NeonItemRarity.legendary,
      );
      expect(neonItemRarity(), NeonItemRarity.common);
    });

    testWidgets('renders name and rarity chrome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: Scaffold(
            body: NeonItemCard(
              name: 'Sunshot',
              slot: 'Energy',
              element: 'Solar',
              typeLine: 'Hand Cannon · Adaptive',
              rarity: NeonItemRarity.exotic,
              ownedLabel: '×1',
              nameKey: const Key('card_name'),
              ownedKey: const Key('card_owned'),
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('card_name')), findsOneWidget);
      expect(find.text('Sunshot'), findsOneWidget);
      expect(find.text('EXOTIC'), findsOneWidget);
      expect(find.byKey(const Key('card_owned')), findsOneWidget);
    });
  });

  group('Neon segmented + page header', () {
    testWidgets('NeonSegmentedTabs selects and NeonPageHeader renders',
        (tester) async {
      var selected = 'weapons';
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    const NeonPageHeader(
                      kicker: 'Module · Build Creator',
                      title: 'Catalog',
                      subtitle: 'Browse nodes.',
                      titleKey: Key('page_title'),
                    ),
                    NeonSegmentedTabs(
                      selectedId: selected,
                      onSelected: (id) => setState(() => selected = id),
                      options: const [
                        NeonSegmentOption(
                          id: 'weapons',
                          label: 'Weapons',
                          key: Key('seg_weapons'),
                        ),
                        NeonSegmentOption(
                          id: 'armor',
                          label: 'Armor',
                          key: Key('seg_armor'),
                        ),
                      ],
                    ),
                    Text('sel=$selected', key: const Key('sel_label')),
                  ],
                );
              },
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('page_title')), findsOneWidget);
      expect(find.text('BROWSE NODES.'), findsNothing); // body case from subtitle
      expect(find.textContaining('Browse nodes'), findsOneWidget);
      await tester.tap(find.byKey(const Key('seg_armor')));
      await tester.pumpAndSettle();
      expect(find.text('sel=armor'), findsOneWidget);
    });
  });

  group('Neon item detail', () {
    test('neonHeroMark classifies weapons and armor', () {
      expect(neonHeroMark(kindLabel: 'Weapon'), 'WPN');
      expect(neonHeroMark(kindLabel: 'Armor'), 'ARM');
      expect(neonHeroMark(slot: 'Helmet'), 'ARM');
      expect(neonHeroMark(slot: 'Energy'), 'WPN');
      expect(neonHeroMark(), 'ITM');
    });

    testWidgets('NeonDetailHeader + hero render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapThemeBase(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  NeonDetailHero(
                    key: Key('hero'),
                    mark: 'WPN',
                    rarity: NeonItemRarity.exotic,
                    element: 'Solar',
                  ),
                  NeonDetailHeader(
                    title: 'Sunshot',
                    kicker: 'Weapon · Energy · Exotic',
                    kickerKey: Key('kicker'),
                    subtitle: 'Hand Cannon · Adaptive',
                    pills: [
                      NeonMetaPill('Solar', tone: NeonPillTone.accent),
                      NeonMetaPill('Exotic', tone: NeonPillTone.exotic),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('hero')), findsOneWidget);
      expect(find.text('Sunshot'), findsOneWidget);
      expect(find.byKey(const Key('kicker')), findsOneWidget);
      expect(find.text('WPN'), findsOneWidget);
    });
  });
}
