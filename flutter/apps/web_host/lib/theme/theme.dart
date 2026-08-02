/// Global Jaspr styles for the web host (Neon Network).
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:jaspr/dom.dart';

import 'flap_tokens_css.dart';

/// Accent / cyan signal (CSS hex from shared tokens).
final Color flapAccentColor = Color(FlapCssTokens.accent);

/// Void canvas background.
final Color flapBackgroundColor = Color(FlapCssTokens.background);

/// Elevated surface.
final Color flapSurfaceColor = Color(FlapCssTokens.surface);

/// Primary lettering.
final Color flapForegroundColor = Color(FlapCssTokens.foreground);

/// Dim / secondary lettering.
final Color flapMutedColor = Color(FlapCssTokens.muted);

/// Hairline rule.
final Color flapLineColor = Color(FlapCssTokens.line);

/// Google Fonts stylesheet URL for Orbitron · Inter · JetBrains Mono.
///
/// Inject from `main.client.dart` as `<link rel="stylesheet">` (Jaspr CSS
/// rules cannot host top-level `@import`). Same families as Flutter
/// `google_fonts`.
const String kNeonNetworkFontsStylesheetHref =
    'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500;600&family=Orbitron:wght@500;600;700&display=swap';

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
      css('h2, h3, .display').styles(
        fontFamily: .list([FontFamily(kFontDisplay), FontFamilies.sansSerif]),
        fontWeight: .w600,
        letterSpacing: 0.04.em,
        color: flapForegroundColor,
      ),
      css('code, kbd, pre, .mono, .tabular').styles(
        fontFamily: .list([FontFamily(kFontMono), FontFamilies.monospace]),
      ),
      css('p').styles(
        margin: .zero,
        color: flapMutedColor,
      ),
    ];
