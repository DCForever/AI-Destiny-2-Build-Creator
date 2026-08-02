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
      // Soft zone panels (gap / tone / fade — not cyan cages).
      css('.neon-zone, .zone, .panel-soft').styles(
        raw: {
          'background': 'var(--flap-grad-zone)',
          'border-radius': 'var(--flap-radius)',
          'box-shadow': '0 12px 40px color-mix(in srgb, #000 28%, transparent)',
          'position': 'relative',
        },
      ),
      // Shell void + blooms under content.
      css('.neon-shell').styles(
        raw: {
          'min-height': '100vh',
          'background-color': 'var(--flap-background)',
          'background-image': [
            'radial-gradient(ellipse 42% 36% at 18% 72%, color-mix(in srgb, var(--flap-accent) 14%, transparent), transparent 70%)',
            'radial-gradient(ellipse 36% 32% at 82% 28%, color-mix(in srgb, var(--flap-accent-secondary) 10%, transparent), transparent 68%)',
            'radial-gradient(ellipse 50% 40% at 55% 100%, color-mix(in srgb, #3d7eff 10%, transparent), transparent 65%)',
          ].join(', '),
          'background-attachment': 'fixed',
        },
      ),
      css('.neon-shell-content').styles(
        raw: {
          'position': 'relative',
          'z-index': '1',
        },
      ),
    ];
