/// Neutral readable color tokens as ARGB ints (0xAARRGGBB).
///
/// **Flutter dual-face (product choice):**
/// - Light default = **Neutral stage** (whites / greys / black ink, high contrast)
/// - Dark = **Neutral charcoal** (blacks / greys, high contrast)
///
/// Hosts map with Flutter `Color(value)` or CSS `#RRGGBB` via [argbToCssHex].
///
/// **Rules:** Soft spatial zoning (gap → tone → fade). White/grey structural
/// hairlines. Chrome accent is charcoal/near-black (light) or light grey (dark)
/// for selection/focus/CTA only — not body text decoration.
/// Keep semantic color only where it carries meaning: exotic gold, Destiny
/// element ink, and status warning (cap warn). Status success never aliases
/// ColorScheme.primary.
library;

// ---------------------------------------------------------------------------
// Dark — Neutral charcoal
// ---------------------------------------------------------------------------

/// Charcoal canvas `#121212`.
const int kFlapBackgroundDark = 0xFF121212;

/// Elevated content zone `#1e1e1e`.
const int kFlapSurfaceDark = 0xFF1E1E1E;

/// Nested / inset zone `#2a2a2a`.
const int kFlapSurfaceRaisedDark = 0xFF2A2A2A;

/// Structural hairline — white @ ~22%.
const int kFlapLineDark = 0x38FFFFFF;

/// Emphasized hairline @ ~38%.
const int kFlapLineStrongDark = 0x61FFFFFF;

/// Near-white text `#f5f5f5`.
const int kFlapForegroundDark = 0xFFF5F5F5;

/// Secondary grey text `#a3a3a3` (AA on charcoal).
const int kFlapMutedDark = 0xFFA3A3A3;

/// Light grey signal `#e0e0e0` (CTA / selection / focus only).
const int kFlapAccentDark = 0xFFE0E0E0;

/// Strong accent / pressed face `#ffffff`.
const int kFlapAccentStrongDark = 0xFFFFFFFF;

/// Soft accent wash `#e0e0e0` @ ~15%.
const int kFlapAccentDimDark = 0x26E0E0E0;

/// Critical / destructive only `#ff003c`.
const int kFlapDangerDark = 0xFFFF003C;

/// Status success `#2ee6a6` (distinct from accent).
const int kFlapSuccessDark = 0xFF2EE6A6;

/// Status warn `#f5c542` (cap warning).
const int kFlapWarningDark = 0xFFF5C542;

/// Secondary chrome (charts / rare emphasis) — neutral mid grey.
const int kFlapAccentSecondaryDark = 0xFF8A8A8A;

// ---------------------------------------------------------------------------
// Light — Neutral stage (ThemeMode.light default)
// ---------------------------------------------------------------------------

/// Neutral stage `#f5f5f5`.
const int kFlapBackgroundLight = 0xFFF5F5F5;

/// Elevated white zone `#ffffff`.
const int kFlapSurfaceLight = 0xFFFFFFFF;

/// Inset zone `#eeeeee`.
const int kFlapSurfaceRaisedLight = 0xFFEEEEEE;

/// Grey structure hairline @ ~16% on black.
const int kFlapLineLight = 0x29000000;

/// Strong structure hairline @ ~28%.
const int kFlapLineStrongLight = 0x47000000;

/// Near-black ink `#111111` (AA+ on white/stage).
const int kFlapForegroundLight = 0xFF111111;

/// Mid grey muted for AA body/secondary `#595959`.
const int kFlapMutedLight = 0xFF595959;

/// Charcoal chrome `#1a1a1a` — selection / focus / CTA (not body wash).
const int kFlapAccentLight = 0xFF1A1A1A;

/// Strong charcoal / pressed face `#000000`.
const int kFlapAccentStrongLight = 0xFF000000;

/// Soft accent wash on light @ ~12%.
const int kFlapAccentDimLight = 0x1F1A1A1A;

/// Critical on light (same danger signal).
const int kFlapDangerLight = 0xFFFF003C;

/// Success on light — darker green for WCAG AA (≥4.5:1) on stage/surface.
/// Dark face keeps `#2ee6a6`; light uses `#166534` (Held / ready ink).
const int kFlapSuccessLight = 0xFF166534;

/// Warn on light (cap warning).
const int kFlapWarningLight = 0xFFF5C542;

/// Secondary chrome — neutral mid grey.
const int kFlapAccentSecondaryLight = 0xFF6B6B6B;

// ---------------------------------------------------------------------------
// Rarity wash (catalog cards)
// ---------------------------------------------------------------------------

/// Exotic gold wash `#ceae33`.
const int kRarityExotic = 0xFFCEAE33;

/// Legendary purple core `#522f65`.
const int kRarityLegendary = 0xFF522F65;

/// Legendary purple edge `#a178c4`.
const int kRarityLegendaryEdge = 0xFFA178C4;

// ---------------------------------------------------------------------------
// Destiny element ink (dark board — full strength on icons / identity)
// ---------------------------------------------------------------------------

/// Kinetic `#ffffff`.
const int kElementKineticDark = 0xFFFFFFFF;

/// Arc `#85c5ec`.
const int kElementArcDark = 0xFF85C5EC;

/// Solar `#f2721b`.
const int kElementSolarDark = 0xFFF2721B;

/// Void `#b184c5`.
const int kElementVoidDark = 0xFFB184C5;

/// Stasis `#4d88ff`.
const int kElementStasisDark = 0xFF4D88FF;

/// Strand `#35e366`.
const int kElementStrandDark = 0xFF35E366;

/// Prismatic `#d67ee2`.
const int kElementPrismaticDark = 0xFFD67EE2;

// ---------------------------------------------------------------------------
// Destiny element ink (light board — higher contrast on neutral stage)
// ---------------------------------------------------------------------------

const int kElementKineticLight = 0xFF2A2D36;
const int kElementArcLight = 0xFF1A6F9C;
const int kElementSolarLight = 0xFFC45A12;
const int kElementVoidLight = 0xFF7A4D96;
const int kElementStasisLight = 0xFF2F5FC4;
const int kElementStrandLight = 0xFF1A9A42;
const int kElementPrismaticLight = 0xFF9A3FB0;

// ---------------------------------------------------------------------------
// Grouped views
// ---------------------------------------------------------------------------

/// Neutral charcoal (dark) / neutral stage (light) palettes.
///
/// API name [FlapColorTokens] retained for host compatibility.
class FlapColorTokens {
  const FlapColorTokens._({
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
    this.accentSecondary = kFlapAccentSecondaryDark,
  });

  final int background;
  final int surface;
  final int surfaceRaised;
  final int line;
  final int lineStrong;
  final int foreground;
  final int muted;
  final int accent;
  final int accentStrong;
  final int accentDim;
  final int danger;
  final int success;
  final int warning;
  final int accentSecondary;
  final int elementKinetic;
  final int elementArc;
  final int elementSolar;
  final int elementVoid;
  final int elementStasis;
  final int elementStrand;
  final int elementPrismatic;

  /// Neutral charcoal — dark ThemeMode face.
  static const dark = FlapColorTokens._(
    background: kFlapBackgroundDark,
    surface: kFlapSurfaceDark,
    surfaceRaised: kFlapSurfaceRaisedDark,
    line: kFlapLineDark,
    lineStrong: kFlapLineStrongDark,
    foreground: kFlapForegroundDark,
    muted: kFlapMutedDark,
    accent: kFlapAccentDark,
    accentStrong: kFlapAccentStrongDark,
    accentDim: kFlapAccentDimDark,
    danger: kFlapDangerDark,
    success: kFlapSuccessDark,
    warning: kFlapWarningDark,
    accentSecondary: kFlapAccentSecondaryDark,
    elementKinetic: kElementKineticDark,
    elementArc: kElementArcDark,
    elementSolar: kElementSolarDark,
    elementVoid: kElementVoidDark,
    elementStasis: kElementStasisDark,
    elementStrand: kElementStrandDark,
    elementPrismatic: kElementPrismaticDark,
  );

  /// Neutral stage — light ThemeMode face (product default).
  static const light = FlapColorTokens._(
    background: kFlapBackgroundLight,
    surface: kFlapSurfaceLight,
    surfaceRaised: kFlapSurfaceRaisedLight,
    line: kFlapLineLight,
    lineStrong: kFlapLineStrongLight,
    foreground: kFlapForegroundLight,
    muted: kFlapMutedLight,
    accent: kFlapAccentLight,
    accentStrong: kFlapAccentStrongLight,
    accentDim: kFlapAccentDimLight,
    danger: kFlapDangerLight,
    success: kFlapSuccessLight,
    warning: kFlapWarningLight,
    accentSecondary: kFlapAccentSecondaryLight,
    elementKinetic: kElementKineticLight,
    elementArc: kElementArcLight,
    elementSolar: kElementSolarLight,
    elementVoid: kElementVoidLight,
    elementStasis: kElementStasisLight,
    elementStrand: kElementStrandLight,
    elementPrismatic: kElementPrismaticLight,
  );
}

/// Formats an ARGB int as CSS hex (`#rrggbb` or `#rrggbbaa` when alpha ≠ FF).
String argbToCssHex(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  String hex2(int v) => v.toRadixString(16).padLeft(2, '0');
  if (a == 0xFF) {
    return '#${hex2(r)}${hex2(g)}${hex2(b)}';
  }
  return '#${hex2(r)}${hex2(g)}${hex2(b)}${hex2(a)}';
}
