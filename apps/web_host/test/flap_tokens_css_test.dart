import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:destiny2_web_host/theme/flap_tokens_css.dart';
import 'package:test/test.dart';

void main() {
  group('flapDarkCssVariables', () {
    test('maps dark Matte Flap hexes from destiny2_ui_tokens', () {
      final vars = flapDarkCssVariables();
      expect(vars['--flap-background'], '#050608');
      expect(vars['--flap-surface'], '#0c0e12');
      expect(vars['--flap-accent'], '#e6b35c');
      expect(vars['--flap-foreground'], '#e8eaef');
      expect(vars['--flap-muted'], '#8a93a6');
      expect(vars['--flap-danger'], '#e2654f');
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
      expect(FlapCssTokens.background, '#050608');
      expect(FlapCssTokens.surface, '#0c0e12');
      expect(FlapCssTokens.accent, '#e6b35c');
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
      expect(block, contains('--flap-background: #050608;'));
      expect(block, contains('--flap-accent: #e6b35c;'));
      expect(block, contains('--flap-radius: 0px;'));
    });
  });
}
