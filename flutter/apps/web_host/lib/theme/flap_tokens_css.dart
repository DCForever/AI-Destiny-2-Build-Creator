/// CSS custom-property map derived from pure [destiny2_ui_tokens] (DART-042).
///
/// Single source of truth with Flutter hosts (DART-029). No hand-copied palette.
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';

/// Dark Matte Flap Ledger CSS variables (`--flap-*`) for `:root`.
///
/// Values are CSS hex/length strings ready for `var(--flap-background)`.
Map<String, String> flapDarkCssVariables() {
  final c = FlapColorTokens.dark;
  final accentHex = argbToCssHex(c.accent);
  return {
    '--flap-background': argbToCssHex(c.background),
    '--flap-surface': argbToCssHex(c.surface),
    '--flap-surface-raised': argbToCssHex(c.surfaceRaised),
    '--flap-line': argbToCssHex(c.line),
    '--flap-line-strong': argbToCssHex(c.lineStrong),
    '--flap-foreground': argbToCssHex(c.foreground),
    '--flap-muted': argbToCssHex(c.muted),
    '--flap-accent': accentHex,
    '--flap-accent-strong': argbToCssHex(c.accentStrong),
    '--flap-accent-secondary': argbToCssHex(c.accentSecondary),
    '--flap-danger': argbToCssHex(c.danger),
    '--flap-success': argbToCssHex(c.success),
    '--flap-warning': argbToCssHex(c.warning),
    '--flap-radius': '${kFlapRadius.toInt()}px',
    '--flap-gap': '${kFlapGap.toInt()}px',
    '--flap-space-8': '${kSpace8.toInt()}px',
    '--flap-space-12': '${kSpace12.toInt()}px',
    '--flap-space-16': '${kSpace16.toInt()}px',
    '--flap-space-24': '${kSpace24.toInt()}px',
    '--flap-page-x': '${kPageX.toInt()}px',
    '--flap-page-y': '${kPageY.toInt()}px',
    '--flap-rail-width': '${kFlapLibraryRailWidth.toInt()}px',
    '--flap-rule': '${kFlapRuleThickness.toInt()}px',
    '--flap-page-max': '${kPageFrameMaxWidth.toInt()}px',
    '--flap-font-display': kFontDisplayFallback,
    '--flap-font-body': kFontBodyFallback,
    '--flap-font-mono': kFontMonoFallback,
    // Neon atmosphere helpers (shell blooms / soft zones)
    '--flap-grad-zone':
        'linear-gradient(165deg, color-mix(in srgb, ${argbToCssHex(c.surface)} 96%, $accentHex 3%) 0%, color-mix(in srgb, ${argbToCssHex(c.surface)} 72%, ${argbToCssHex(c.background)}) 100%)',
    '--flap-grid-line': 'color-mix(in srgb, $accentHex 14%, transparent)',
  };
}

/// Serializes [flapDarkCssVariables] into a `:root { ... }` CSS block.
String flapDarkCssRootBlock() {
  final buf = StringBuffer(':root {\n');
  for (final e in flapDarkCssVariables().entries) {
    buf.writeln('  ${e.key}: ${e.value};');
  }
  buf.writeln('}');
  return buf.toString();
}

/// Convenience getters for tests and non-CSS consumers.
abstract final class FlapCssTokens {
  static String get background => flapDarkCssVariables()['--flap-background']!;
  static String get surface => flapDarkCssVariables()['--flap-surface']!;
  static String get accent => flapDarkCssVariables()['--flap-accent']!;
  static String get radius => flapDarkCssVariables()['--flap-radius']!;
  static String get foreground => flapDarkCssVariables()['--flap-foreground']!;
  static String get muted => flapDarkCssVariables()['--flap-muted']!;
  static String get line => flapDarkCssVariables()['--flap-line']!;
}
