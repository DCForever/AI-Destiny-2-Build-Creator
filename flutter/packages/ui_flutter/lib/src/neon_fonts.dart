/// Neon Network type faces via [google_fonts] (Orbitron · Inter · JetBrains Mono).
///
/// Token family names live in [destiny2_ui_tokens]; this file loads real faces
/// for Flutter hosts. Web/Jaspr loads the same stacks via Google Fonts CSS.
library;

import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Display / module titles (Orbitron).
TextStyle neonDisplay({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  FontStyle? fontStyle,
  TextDecoration? decoration,
  double? height,
}) {
  return GoogleFonts.orbitron(
    color: color,
    fontSize: fontSize ?? kTypeHeadline.fontSize,
    fontWeight: fontWeight ?? FontWeight.w600,
    letterSpacing: letterSpacing ?? kTypeHeadline.letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
    height: height,
  );
}

/// Body / UI (Inter).
TextStyle neonBody({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  FontStyle? fontStyle,
  TextDecoration? decoration,
  double? height,
}) {
  return GoogleFonts.inter(
    color: color,
    fontSize: fontSize ?? kTypeBody.fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
    height: height,
  );
}

/// Mono metrics / IDs (JetBrains Mono) with tabular figures by default.
TextStyle neonMono({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  FontStyle? fontStyle,
  TextDecoration? decoration,
  double? height,
  bool tabular = true,
}) {
  return GoogleFonts.jetBrainsMono(
    color: color,
    fontSize: fontSize ?? kTypeTally.fontSize,
    fontWeight: fontWeight ?? FontWeight.w400,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
    decoration: decoration,
    height: height,
    fontFeatures: tabular
        ? const [FontFeature.tabularFigures()]
        : null,
  );
}

/// Full Neon [TextTheme] over void/surface colors.
TextTheme neonTextTheme({
  required Color onSurface,
  required Color muted,
}) {
  return TextTheme(
    titleLarge: neonDisplay(
      color: onSurface,
      fontSize: kTypeHeadline.fontSize,
      letterSpacing: kTypeHeadline.letterSpacing,
    ),
    titleMedium: neonDisplay(
      color: onSurface,
      fontSize: kTypeTitle.fontSize,
      letterSpacing: kTypeTitle.letterSpacing,
    ),
    titleSmall: neonDisplay(
      color: onSurface,
      fontSize: kTypeLabel.fontSize,
      letterSpacing: kTypeLabel.letterSpacing,
    ),
    bodyLarge: neonBody(color: onSurface, fontSize: kTypeBody.fontSize),
    bodyMedium: neonBody(color: onSurface, fontSize: 14),
    bodySmall: neonBody(color: muted, fontSize: 12),
    labelLarge: neonDisplay(
      color: onSurface,
      fontSize: kTypeLabel.fontSize,
      letterSpacing: kTypeLabel.letterSpacing,
    ),
    labelMedium: neonBody(color: onSurface, fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: neonDisplay(
      color: muted,
      fontSize: kTypeLabelXs.fontSize,
      letterSpacing: kTypeLabelXs.letterSpacing,
    ),
  );
}

/// Resolved family names after Google Fonts registration (for ThemeData.fontFamily).
String get neonBodyFontFamily => GoogleFonts.inter().fontFamily ?? kFontBody;
String get neonDisplayFontFamily =>
    GoogleFonts.orbitron().fontFamily ?? kFontDisplay;
String get neonMonoFontFamily =>
    GoogleFonts.jetBrainsMono().fontFamily ?? kFontMono;
