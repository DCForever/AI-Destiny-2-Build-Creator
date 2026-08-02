/// Typography metrics + family names — Neon Network / Vex Network Interface.
///
/// Font **binaries are not shipped** here. Hosts may load Orbitron / Inter /
/// JetBrains Mono later; until then system sans/mono fallbacks are acceptable.
library;

/// Display face (module titles, section marks, construct IDs).
const String kFontDisplay = 'Orbitron';

/// Body / UI (labels, tables, forms, settings).
const String kFontBody = 'Inter';

/// Mono (IDs, hashes, metrics, endpoints).
const String kFontMono = 'JetBrains Mono';

/// Fallback stack for Flutter `fontFamily` / CSS.
const String kFontDisplayFallback =
    'Orbitron, Electrolize, Rajdhani, Exo 2, Chakra Petch, system-ui, sans-serif';
const String kFontBodyFallback =
    'Inter, system-ui, -apple-system, Segoe UI, Helvetica Neue, Arial, sans-serif';
const String kFontMonoFallback =
    'JetBrains Mono, Share Tech Mono, Fira Code, ui-monospace, Menlo, monospace';

/// Size / weight / tracking for board roles (logical px / unitless / em-like).
class FlapTypeRole {
  const FlapTypeRole({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    this.letterSpacing = 0,
  });

  final String fontFamily;
  final double fontSize;
  /// CSS/Flutter weight: 400 regular, 600 semi-bold, etc.
  final int fontWeight;
  final double letterSpacing;
}

/// Display title (~0.04em tracking).
const FlapTypeRole kTypeDisplay = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 18,
  fontWeight: 600,
  letterSpacing: 0.04 * 18,
);

/// Page headline.
const FlapTypeRole kTypeHeadline = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 18,
  fontWeight: 600,
  letterSpacing: 0.04 * 18,
);

/// Section title condensed tracking.
const FlapTypeRole kTypeTitle = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 13,
  fontWeight: 600,
  letterSpacing: 0.06 * 13,
);

/// Chrome label / mono kickers (~0.1–0.14em).
const FlapTypeRole kTypeLabel = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 11,
  fontWeight: 600,
  letterSpacing: 0.12 * 11,
);

/// Extra-small label.
const FlapTypeRole kTypeLabelXs = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 10,
  fontWeight: 600,
  letterSpacing: 0.1 * 10,
);

/// Dense UI body ~13px (Neon kit default).
const FlapTypeRole kTypeBody = FlapTypeRole(
  fontFamily: kFontBody,
  fontSize: 13,
  fontWeight: 400,
);

/// Mono tally / metric ~11px.
const FlapTypeRole kTypeTally = FlapTypeRole(
  fontFamily: kFontMono,
  fontSize: 11,
  fontWeight: 400,
);

class FlapTypography {
  const FlapTypography._();

  static const String displayFamily = kFontDisplay;
  static const String bodyFamily = kFontBody;
  static const String monoFamily = kFontMono;
  static const FlapTypeRole display = kTypeDisplay;
  static const FlapTypeRole headline = kTypeHeadline;
  static const FlapTypeRole title = kTypeTitle;
  static const FlapTypeRole label = kTypeLabel;
  static const FlapTypeRole labelXs = kTypeLabelXs;
  static const FlapTypeRole body = kTypeBody;
  static const FlapTypeRole tally = kTypeTally;
}
