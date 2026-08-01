/// Global Jaspr styles for the web host (Matte Flap Ledger).
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:jaspr/dom.dart';

import 'flap_tokens_css.dart';

/// Accent / readiness lamp (CSS hex from shared tokens).
final Color flapAccentColor = Color(FlapCssTokens.accent);

/// Void canvas background.
final Color flapBackgroundColor = Color(FlapCssTokens.background);

/// Flap plate surface.
final Color flapSurfaceColor = Color(FlapCssTokens.surface);

/// Primary lettering.
final Color flapForegroundColor = Color(FlapCssTokens.foreground);

/// Dim lettering.
final Color flapMutedColor = Color(FlapCssTokens.muted);

/// Hairline rule.
final Color flapLineColor = Color(FlapCssTokens.line);

/// Global CSS for the host.
@css
List<StyleRule> get styles => [
      // CSS custom properties from pure ui_tokens (single source of truth).
      css(':root').styles(raw: flapDarkCssVariables()),
      css('html, body').styles(
        width: 100.percent,
        minHeight: 100.vh,
        padding: .zero,
        margin: .zero,
        fontFamily: .list([FontFamily(kFontBody), FontFamilies.sansSerif]),
        color: flapForegroundColor,
        backgroundColor: flapBackgroundColor,
      ),
      css('*, *::before, *::after').styles(
        boxSizing: .borderBox,
      ),
      css('a').styles(
        color: flapAccentColor,
        textDecoration: TextDecoration(line: .none),
      ),
      css('h1').styles(
        margin: .zero,
        fontFamily: .list([FontFamily(kFontDisplay), FontFamilies.sansSerif]),
        fontSize: 1.75.rem,
        fontWeight: .w600,
        letterSpacing: 0.04.em,
        color: flapForegroundColor,
      ),
      css('p').styles(
        margin: .zero,
        color: flapMutedColor,
      ),
    ];
