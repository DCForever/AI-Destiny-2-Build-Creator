import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

/// Full Neon Network roles that do not fit cleanly on [ColorScheme].
///
/// Attach via [ThemeData.extensions]. Prefer
/// `Theme.of(context).extension<FlapPalette>()` for status lamps and element ink.
@immutable
class FlapPalette extends ThemeExtension<FlapPalette> {
  const FlapPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.line,
    required this.lineStrong,
    required this.foreground,
    required this.muted,
    required this.accent,
    required this.accentStrong,
    required this.accentDim,
    required this.danger,
    required this.success,
    required this.warning,
    required this.elementKinetic,
    required this.elementArc,
    required this.elementSolar,
    required this.elementVoid,
    required this.elementStasis,
    required this.elementStrand,
    required this.elementPrismatic,
  });

  factory FlapPalette.fromTokens(FlapColorTokens tokens) {
    return FlapPalette(
      background: Color(tokens.background),
      surface: Color(tokens.surface),
      surfaceRaised: Color(tokens.surfaceRaised),
      line: Color(tokens.line),
      lineStrong: Color(tokens.lineStrong),
      foreground: Color(tokens.foreground),
      muted: Color(tokens.muted),
      accent: Color(tokens.accent),
      accentStrong: Color(tokens.accentStrong),
      accentDim: Color(tokens.accentDim),
      danger: Color(tokens.danger),
      success: Color(tokens.success),
      warning: Color(tokens.warning),
      elementKinetic: Color(tokens.elementKinetic),
      elementArc: Color(tokens.elementArc),
      elementSolar: Color(tokens.elementSolar),
      elementVoid: Color(tokens.elementVoid),
      elementStasis: Color(tokens.elementStasis),
      elementStrand: Color(tokens.elementStrand),
      elementPrismatic: Color(tokens.elementPrismatic),
    );
  }

  /// Brightness-aware factory (dark product default).
  factory FlapPalette.forBrightness(Brightness brightness) {
    final tokens =
        brightness == Brightness.dark ? FlapColorTokens.dark : FlapColorTokens.light;
    return FlapPalette.fromTokens(tokens);
  }

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color line;
  final Color lineStrong;
  final Color foreground;
  final Color muted;
  final Color accent;
  final Color accentStrong;
  final Color accentDim;
  final Color danger;
  final Color success;
  final Color warning;
  final Color elementKinetic;
  final Color elementArc;
  final Color elementSolar;
  final Color elementVoid;
  final Color elementStasis;
  final Color elementStrand;
  final Color elementPrismatic;

  /// Resolve palette from [context], falling back to dark tokens.
  static FlapPalette of(BuildContext context) {
    return Theme.of(context).extension<FlapPalette>() ??
        FlapPalette.forBrightness(Theme.of(context).brightness);
  }

  @override
  FlapPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? line,
    Color? lineStrong,
    Color? foreground,
    Color? muted,
    Color? accent,
    Color? accentStrong,
    Color? accentDim,
    Color? danger,
    Color? success,
    Color? warning,
    Color? elementKinetic,
    Color? elementArc,
    Color? elementSolar,
    Color? elementVoid,
    Color? elementStasis,
    Color? elementStrand,
    Color? elementPrismatic,
  }) {
    return FlapPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      foreground: foreground ?? this.foreground,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentDim: accentDim ?? this.accentDim,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      elementKinetic: elementKinetic ?? this.elementKinetic,
      elementArc: elementArc ?? this.elementArc,
      elementSolar: elementSolar ?? this.elementSolar,
      elementVoid: elementVoid ?? this.elementVoid,
      elementStasis: elementStasis ?? this.elementStasis,
      elementStrand: elementStrand ?? this.elementStrand,
      elementPrismatic: elementPrismatic ?? this.elementPrismatic,
    );
  }

  @override
  FlapPalette lerp(ThemeExtension<FlapPalette>? other, double t) {
    if (other is! FlapPalette) return this;
    return FlapPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentDim: Color.lerp(accentDim, other.accentDim, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      elementKinetic: Color.lerp(elementKinetic, other.elementKinetic, t)!,
      elementArc: Color.lerp(elementArc, other.elementArc, t)!,
      elementSolar: Color.lerp(elementSolar, other.elementSolar, t)!,
      elementVoid: Color.lerp(elementVoid, other.elementVoid, t)!,
      elementStasis: Color.lerp(elementStasis, other.elementStasis, t)!,
      elementStrand: Color.lerp(elementStrand, other.elementStrand, t)!,
      elementPrismatic: Color.lerp(elementPrismatic, other.elementPrismatic, t)!,
    );
  }
}
