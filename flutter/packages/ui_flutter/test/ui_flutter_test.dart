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
      // Cold Graphite teal primary
      expect(kFlapAccentDark, 0xFF4EC4BC);

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
}
