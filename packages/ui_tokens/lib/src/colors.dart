/// Matte Flap Ledger color tokens as ARGB ints (0xAARRGGBB).
///
/// **Flutter dual-face (product choice):**
/// - Dark default = **Cold Graphite** (blue-gray void, cyan-teal readiness lamp)
/// - Light = **Paper Ledger** (cream stock, rubber-stamp amber lamp)
///
/// Values match [DESIGN.md](../../../DESIGN.md). Hosts map with Flutter
/// `Color(value)` or CSS `#RRGGBB` via [argbToCssHex].
///
/// **Rules:** No brushed steel. One readiness lamp only (not every border).
/// Destiny element hexes stay sandbox-true on identity cells only.
/// Status success never aliases ColorScheme.primary.
library;

// ---------------------------------------------------------------------------
// Dark — Cold Graphite Board (default product / Windows + mobile)
// ---------------------------------------------------------------------------

/// Cold void canvas `#070b10`.
const int kFlapBackgroundDark = 0xFF070B10;

/// Graphite flap surface `#0e1319`.
const int kFlapSurfaceDark = 0xFF0E1319;

/// Raised graphite `#141a22`.
const int kFlapSurfaceRaisedDark = 0xFF141A22;

/// Hairline rule `#1f2733`.
const int kFlapLineDark = 0xFF1F2733;

/// Strong rule `#2a3342`.
const int kFlapLineStrongDark = 0xFF2A3342;

/// Lettering `#e4eaf2`.
const int kFlapForegroundDark = 0xFFE4EAF2;

/// Dim lettering `#8492a6`.
const int kFlapMutedDark = 0xFF8492A6;

/// Cyan-teal readiness lamp `#4ec4bc` (One Lamp — selection / CTA only).
const int kFlapAccentDark = 0xFF4EC4BC;

/// Stronger teal face `#6fd4cd`.
const int kFlapAccentStrongDark = 0xFF6FD4CD;

/// Teal wash `#4ec4bc` @ ~14% alpha (`#4ec4bc24`).
const int kFlapAccentDimDark = 0x244EC4BC;

/// Breach coral `#e05a52`.
const int kFlapDangerDark = 0xFFE05A52;

/// Signal green `#5cbc8e` (distinct from teal accent).
const int kFlapSuccessDark = 0xFF5CBC8E;

/// Caution gold `#c9a84a`.
const int kFlapWarningDark = 0xFFC9A84A;

// ---------------------------------------------------------------------------
// Light — Paper Ledger (ThemeMode.light / ThemeToggle)
// ---------------------------------------------------------------------------

/// Cream stock field `#ebe6db`.
const int kFlapBackgroundLight = 0xFFEBE6DB;

/// Paper plate `#f7f3ea`.
const int kFlapSurfaceLight = 0xFFF7F3EA;

/// Raised sheet `#fffdf7`.
const int kFlapSurfaceRaisedLight = 0xFFFFFDF7;

/// Paper rule `#c4bba8`.
const int kFlapLineLight = 0xFFC4BBA8;

/// Strong paper rule `#9a9488`.
const int kFlapLineStrongLight = 0xFF9A9488;

/// Carbon ink `#1a1b1f`.
const int kFlapForegroundLight = 0xFF1A1B1F;

/// Muted on paper `#5a5f6a`.
const int kFlapMutedLight = 0xFF5A5F6A;

/// Rubber-stamp amber `#9a6418` (One Lamp on paper).
const int kFlapAccentLight = 0xFF9A6418;

/// Strong stamp amber `#7a4e12`.
const int kFlapAccentStrongLight = 0xFF7A4E12;

/// Amber wash on paper `#9a64181f`.
const int kFlapAccentDimLight = 0x1F9A6418;

/// Danger on paper `#b53a2a`.
const int kFlapDangerLight = 0xFFB53A2A;

/// Success on paper `#1a6e3f`.
const int kFlapSuccessLight = 0xFF1A6E3F;

/// Warning on paper `#8f6510`.
const int kFlapWarningLight = 0xFF8F6510;

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

/// Cold Graphite (dark) / Paper Ledger (light) Matte Flap palettes.
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

  /// Cold Graphite — product dark default.
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

  /// Paper Ledger — light ThemeMode face.
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
