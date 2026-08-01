/// Typography metrics + family names — Matte Flap Ledger.
///
/// Font **binaries are not shipped** in DART-029. Hosts may load Barlow Condensed /
/// IBM Plex later; until then system sans/mono fallbacks are acceptable for the
/// Windows theme stub.
library;

/// Board / display face (condensed uppercase chrome).
const String kFontDisplay = 'Barlow Condensed';

/// Body guidance (sentence case).
const String kFontBody = 'IBM Plex Sans';

/// Tallies / READY/HOLD stamps / counts.
const String kFontMono = 'IBM Plex Mono';

/// Fallback stack for Flutter `fontFamily` / CSS.
const String kFontDisplayFallback = 'Barlow Condensed, ui-sans-serif, system-ui, sans-serif';
const String kFontBodyFallback = 'IBM Plex Sans, ui-sans-serif, system-ui, sans-serif';
const String kFontMonoFallback = 'IBM Plex Mono, ui-monospace, monospace';

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

/// Display condensed title.
const FlapTypeRole kTypeDisplay = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 18,
  fontWeight: 600,
  letterSpacing: 0.04 * 18,
);

/// Page headline ~1.125rem.
const FlapTypeRole kTypeHeadline = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 18,
  fontWeight: 600,
);

/// Section title ~0.8125rem condensed tracking.
const FlapTypeRole kTypeTitle = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 13,
  fontWeight: 600,
  letterSpacing: 0.08 * 13,
);

/// Chrome label ~0.6875rem.
const FlapTypeRole kTypeLabel = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 11,
  fontWeight: 600,
  letterSpacing: 0.12 * 11,
);

/// Extra-small label ~0.625rem.
const FlapTypeRole kTypeLabelXs = FlapTypeRole(
  fontFamily: kFontDisplay,
  fontSize: 10,
  fontWeight: 600,
  letterSpacing: 0.1 * 10,
);

/// Body ~0.9375rem.
const FlapTypeRole kTypeBody = FlapTypeRole(
  fontFamily: kFontBody,
  fontSize: 15,
  fontWeight: 400,
);

/// Mono tally ~11px.
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
