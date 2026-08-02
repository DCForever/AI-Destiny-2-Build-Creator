import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:destiny2_web_host/theme/flap_tokens_css.dart';
import 'package:destiny2_web_host/theme/theme.dart'
    show kNeonNetworkFontsStylesheetHref;
import 'package:test/test.dart';

void main() {
  group('flapDarkCssVariables', () {
    test('maps dark Neon Network hexes from destiny2_ui_tokens', () {
      final vars = flapDarkCssVariables();
      expect(vars['--flap-background'], '#05050f');
      expect(vars['--flap-surface'], '#0a0a18');
      expect(vars['--flap-accent'], '#00e5ff');
      expect(vars['--flap-foreground'], '#f0fdff');
      expect(vars['--flap-muted'], '#7dd3e0');
      expect(vars['--flap-danger'], '#ff003c');
      expect(vars['--flap-success'], '#2ee6a6');
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
      expect(FlapCssTokens.background, '#05050f');
      expect(FlapCssTokens.surface, '#0a0a18');
      expect(FlapCssTokens.accent, '#00e5ff');
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
      expect(block, contains('--flap-background: #05050f;'));
      expect(block, contains('--flap-accent: #00e5ff;'));
      expect(block, contains('--flap-radius: 0px;'));
    });

    test('font stacks use Neon Network families', () {
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
