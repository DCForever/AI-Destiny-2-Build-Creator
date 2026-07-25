/// Matte Flap Ledger color tokens as ARGB ints (0xAARRGGBB).
///
/// Values match [DESIGN.md](../../../DESIGN.md) and product `src/app/globals.css`
/// dark (default) / light palettes. Hosts map with Flutter `Color(value)` or CSS
/// `#RRGGBB` via [argbToCssHex].
///
/// **Rules:** No brushed steel. Amber is a readiness lamp, not a brand flood.
/// Destiny element hexes stay sandbox-true on identity cells only.
library;

// ---------------------------------------------------------------------------
// Dark (default product / Windows stub)
// ---------------------------------------------------------------------------

/// Void canvas `#050608`.
const int kFlapBackgroundDark = 0xFF050608;

/// Flap surface `#0c0e12`.
const int kFlapSurfaceDark = 0xFF0C0E12;

/// Raised flap `#12151c`.
const int kFlapSurfaceRaisedDark = 0xFF12151C;

/// Hairline rule `#1c212c`.
const int kFlapLineDark = 0xFF1C212C;

/// Strong rule `#2a3140`.
const int kFlapLineStrongDark = 0xFF2A3140;

/// Lettering `#e8eaef`.
const int kFlapForegroundDark = 0xFFE8EAEF;

/// Dim lettering `#8a93a6`.
const int kFlapMutedDark = 0xFF8A93A6;

/// Readiness amber `#e6b35c`.
const int kFlapAccentDark = 0xFFE6B35C;

/// Stronger amber face `#f0c878`.
const int kFlapAccentStrongDark = 0xFFF0C878;

/// Amber wash `#e6b35c` @ ~14% alpha (`#e6b35c24`).
const int kFlapAccentDimDark = 0x24E6B35C;

/// Breach coral `#e2654f`.
const int kFlapDangerDark = 0xFFE2654F;

/// Signal green `#6fc28b`.
const int kFlapSuccessDark = 0xFF6FC28B;

/// Caution gold `#d9a93f`.
const int kFlapWarningDark = 0xFFD9A93F;

// ---------------------------------------------------------------------------
// Light ledger (constants for later ThemeToggle; not live Windows default)
// ---------------------------------------------------------------------------

/// Paper field `#e8e6e1`.
const int kFlapBackgroundLight = 0xFFE8E6E1;

/// Paper plate `#f4f2ec`.
const int kFlapSurfaceLight = 0xFFF4F2EC;

/// Raised paper `#ffffff`.
const int kFlapSurfaceRaisedLight = 0xFFFFFFFF;

/// Light rule `#c9c4b8`.
const int kFlapLineLight = 0xFFC9C4B8;

/// Strong light rule `#9a9488`.
const int kFlapLineStrongLight = 0xFF9A9488;

/// Ink on paper `#1a1c22`.
const int kFlapForegroundLight = 0xFF1A1C22;

/// Muted on paper `#5c6170`.
const int kFlapMutedLight = 0xFF5C6170;

/// Deepened amber on paper `#9a6b1f`.
const int kFlapAccentLight = 0xFF9A6B1F;

/// Strong amber on paper `#7a5214`.
const int kFlapAccentStrongLight = 0xFF7A5214;

/// Amber wash on paper `#9a6b1f1f`.
const int kFlapAccentDimLight = 0x1F9A6B1F;

/// Danger on paper `#b53a2a`.
const int kFlapDangerLight = 0xFFB53A2A;

/// Success on paper `#1f7a45`.
const int kFlapSuccessLight = 0xFF1F7A45;

/// Warning on paper `#9a6f12`.
const int kFlapWarningLight = 0xFF9A6F12;

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
// Destiny element ink (light board — higher contrast on paper)
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

/// Dark (default) Matte Flap Ledger palette.
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
  final int elementKinetic;
  final int elementArc;
  final int elementSolar;
  final int elementVoid;
  final int elementStasis;
  final int elementStrand;
  final int elementPrismatic;

  /// Product / Windows stub default.
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
    elementKinetic: kElementKineticDark,
    elementArc: kElementArcDark,
    elementSolar: kElementSolarDark,
    elementVoid: kElementVoidDark,
    elementStasis: kElementStasisDark,
    elementStrand: kElementStrandDark,
    elementPrismatic: kElementPrismaticDark,
  );

  /// Light ledger constants (ThemeToggle later).
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
