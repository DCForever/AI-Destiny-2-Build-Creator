import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildFlapTheme (neutral readable)', () {
    test('defaults to light neutral stage from tokens', () {
      final theme = buildFlapTheme();
      expect(theme.scaffoldBackgroundColor, Color(kFlapBackgroundLight));
      expect(theme.cardColor, Color(kFlapSurfaceLight));
      expect(theme.colorScheme.primary, Color(kFlapAccentLight));
      expect(theme.colorScheme.error, Color(kFlapDangerLight));
      expect(theme.colorScheme.surface, Color(kFlapSurfaceLight));
      expect(theme.brightness, Brightness.light);
    });

    test('card theme is square, elevation 0 (no Material-card default)', () {
      final theme = buildFlapTheme();
      final card = theme.cardTheme;

      expect(card.elevation, 0);
      expect(card.color, Color(kFlapSurfaceLight));
      expect(card.shadowColor, Colors.transparent);
      expect(card.surfaceTintColor, Colors.transparent);

      final shape = card.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      final border = shape! as RoundedRectangleBorder;
      expect(border.borderRadius, BorderRadius.circular(kFlapRadius));
      expect(kFlapRadius, 0);
    });

    test('does not use seed-blue or cyan-neon ColorScheme primary', () {
      final theme = buildFlapTheme();
      // Old hosts used ColorScheme.fromSeed(seedColor: 0xFF1B4F72) / cyan neon.
      expect(theme.colorScheme.primary, isNot(const Color(0xFF1B4F72)));
      expect(theme.colorScheme.primary, isNot(const Color(0xFF00E5FF)));
      expect(theme.colorScheme.primary, Color(kFlapAccentLight));
    });

    test('dark face is neutral charcoal', () {
      final theme = buildFlapTheme(brightness: Brightness.dark);
      expect(theme.scaffoldBackgroundColor, Color(kFlapBackgroundDark));
      expect(theme.colorScheme.primary, Color(kFlapAccentDark));
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('Card under flap theme inherits flat square shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapTheme(),
          home: const Scaffold(
            body: Card(
              key: Key('sample_card'),
              child: SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byKey(const Key('sample_card')));
      // When elevation/shape not set on widget, Theme.cardTheme applies at paint;
      // resolve via Theme.of after pump.
      final context = tester.element(find.byKey(const Key('sample_card')));
      final themed = Theme.of(context).cardTheme;
      expect(themed.elevation, 0);
      expect(themed.shape, isA<RoundedRectangleBorder>());
      final r = (themed.shape! as RoundedRectangleBorder).borderRadius;
      expect(r, BorderRadius.zero);
      // Card still builds (settings widgets can keep Card without rewrite).
      expect(card, isNotNull);
    });
  });
}
