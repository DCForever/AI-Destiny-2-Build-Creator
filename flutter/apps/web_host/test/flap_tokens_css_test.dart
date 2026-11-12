import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:destiny2_web_host/theme/flap_tokens_css.dart';
import 'package:destiny2_web_host/theme/theme.dart'
    show kNeonNetworkFontsStylesheetHref;
import 'package:test/test.dart';

void main() {
  group('flapDarkCssVariables', () {
    test('maps dark neutral charcoal hexes from destiny2_ui_tokens', () {
      final vars = flapDarkCssVariables();
      expect(vars['--flap-background'], argbToCssHex(kFlapBackgroundDark));
      expect(vars['--flap-surface'], argbToCssHex(kFlapSurfaceDark));
      expect(vars['--flap-accent'], argbToCssHex(kFlapAccentDark));
      expect(vars['--flap-foreground'], argbToCssHex(kFlapForegroundDark));
      expect(vars['--flap-muted'], argbToCssHex(kFlapMutedDark));
      expect(vars['--flap-danger'], argbToCssHex(kFlapDangerDark));
      expect(vars['--flap-success'], argbToCssHex(kFlapSuccessDark));
      expect(vars['--flap-background'], '#121212');
      expect(vars['--flap-accent'], '#e0e0e0');
    });

    test('square board radius is 0px', () {
      expect(flapDarkCssVariables()['--flap-radius'], '0px');
      expect(kFlapRadius, 0);
    });

    test('board gap is 0px', () {
      expect(flapDarkCssVariables()['--flap-gap'], '0px');
      expect(kFlapGap, 0);
    });

    test('FlapCssTokens convenience matches map', () {
      expect(FlapCssTokens.background, argbToCssHex(kFlapBackgroundDark));
      expect(FlapCssTokens.surface, argbToCssHex(kFlapSurfaceDark));
      expect(FlapCssTokens.accent, argbToCssHex(kFlapAccentDark));
      expect(FlapCssTokens.radius, '0px');
    });

    test('uses argbToCssHex against package constants', () {
      expect(argbToCssHex(kFlapBackgroundDark), FlapCssTokens.background);
      expect(argbToCssHex(kFlapSurfaceDark), FlapCssTokens.surface);
      expect(argbToCssHex(kFlapAccentDark), FlapCssTokens.accent);
    });

    test('root block serializes custom properties', () {
      final block = flapDarkCssRootBlock();
      expect(block, startsWith(':root {'));
      expect(
        block,
        contains('--flap-background: ${argbToCssHex(kFlapBackgroundDark)};'),
      );
      expect(
        block,
        contains('--flap-accent: ${argbToCssHex(kFlapAccentDark)};'),
      );
      expect(block, contains('--flap-radius: 0px;'));
    });

    test('font stacks use display/body/mono families', () {
      final vars = flapDarkCssVariables();
      expect(vars['--flap-font-display'], contains('Orbitron'));
      expect(vars['--flap-font-body'], contains('Inter'));
      expect(vars['--flap-font-mono'], contains('JetBrains'));
    });

    test('Neon Google Fonts stylesheet href lists Orbitron Inter JetBrains', () {
      expect(kNeonNetworkFontsStylesheetHref, contains('Orbitron'));
      expect(kNeonNetworkFontsStylesheetHref, contains('Inter'));
      expect(kNeonNetworkFontsStylesheetHref, contains('JetBrains'));
      expect(kNeonNetworkFontsStylesheetHref, startsWith('https://fonts.googleapis.com/'));
    });
  });
}
