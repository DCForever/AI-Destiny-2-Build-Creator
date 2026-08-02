/// Neon Network / Vex Network Interface color tokens as ARGB ints (0xAARRGGBB).
///
/// **Flutter dual-face (product choice):**
/// - Dark default = **Neon void** (deep void canvas, cyan-neon signal accent)
/// - Light = **Cool technical stage** (cool greys, cyan signal chrome only)
///
/// Values match Open Design package `user:neon-network-design-system` and
/// repo root [DESIGN.md](../../../DESIGN.md). Hosts map with Flutter
/// `Color(value)` or CSS `#RRGGBB` via [argbToCssHex].
///
/// **Rules:** Soft spatial zoning (gap → tone → fade). White/grey structural
/// hairlines — not cyan cages. Cyan accent ≤ ~2 strong hits per region.
/// Destiny element hexes stay sandbox-true on identity cells only.
/// Status success never aliases ColorScheme.primary.
library;

// ---------------------------------------------------------------------------
// Dark — Neon Network void (default product / Windows + mobile + web)
// ---------------------------------------------------------------------------

/// Void canvas `#05050f`.
const int kFlapBackgroundDark = 0xFF05050F;

/// Elevated content zone `#0a0a18`.
const int kFlapSurfaceDark = 0xFF0A0A18;

/// Nested / inset zone `#101028`.
const int kFlapSurfaceRaisedDark = 0xFF101028;

/// Structural hairline — white/grey @ ~22% (`rgba(232,238,242,0.22)`).
const int kFlapLineDark = 0x38E8EEF2;

/// Emphasized hairline @ ~38% (`rgba(232,238,242,0.38)`).
const int kFlapLineStrongDark = 0x61E8EEF2;

/// Signal white text `#f0fdff`.
const int kFlapForegroundDark = 0xFFF0FDFF;

/// Secondary cyan text `#7dd3e0`.
const int kFlapMutedDark = 0xFF7DD3E0;

/// Primary cyan-neon signal `#00e5ff` (CTA / selection / focus only).
const int kFlapAccentDark = 0xFF00E5FF;

/// Deep accent / pressed face `#00b8d4`.
const int kFlapAccentStrongDark = 0xFF00B8D4;

/// Soft accent wash `#00e5ff` @ ~15% (`primary-soft`).
const int kFlapAccentDimDark = 0x2600E5FF;

/// Critical / destructive only `#ff003c`.
const int kFlapDangerDark = 0xFFFF003C;

/// Status success `#2ee6a6` (distinct from cyan accent).
const int kFlapSuccessDark = 0xFF2EE6A6;

/// Status warn `#f5c542`.
const int kFlapWarningDark = 0xFFF5C542;

/// Sparse magenta energy (secondary accent — charts, rare emphasis only).
const int kFlapAccentSecondaryDark = 0xFFFF1A8C;

// ---------------------------------------------------------------------------
// Light — Cool technical stage (ThemeMode.light / ThemeToggle)
// ---------------------------------------------------------------------------

/// Cool technical stage `#f4f7fb`.
const int kFlapBackgroundLight = 0xFFF4F7FB;

/// Elevated white zone `#ffffff`.
const int kFlapSurfaceLight = 0xFFFFFFFF;

/// Inset zone `#eef2f7`.
const int kFlapSurfaceRaisedLight = 0xFFEEF2F7;

/// Grey structure hairline @ ~14% on near-void ink.
const int kFlapLineLight = 0x240A0A18;

/// Strong structure hairline @ ~22%.
const int kFlapLineStrongLight = 0x380A0A18;

/// Near-void ink `#0a0a18`.
const int kFlapForegroundLight = 0xFF0A0A18;

/// Deepened cool muted for AA small text `#4a5a68`.
const int kFlapMutedLight = 0xFF4A5A68;

/// Signal chrome only `#00c4db` — not body text on white.
const int kFlapAccentLight = 0xFF00C4DB;

/// Prefer for text-on-white CTA if needed `#00a8bc`.
const int kFlapAccentStrongLight = 0xFF00A8BC;

/// Soft accent wash on light @ ~12%.
const int kFlapAccentDimLight = 0x1F00C4DB;

/// Critical on light (same danger signal).
const int kFlapDangerLight = 0xFFFF003C;

/// Success on light (same status green).
const int kFlapSuccessLight = 0xFF2EE6A6;

/// Warn on light.
const int kFlapWarningLight = 0xFFF5C542;

/// Sparse magenta (shared).
const int kFlapAccentSecondaryLight = 0xFFFF1A8C;

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
// Destiny element ink (light board — higher contrast on technical stage)
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

/// Neon void (dark) / cool technical (light) palettes.
///
/// API name [FlapColorTokens] retained for host compatibility; values are
/// Neon Network.
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

  /// Neon Network void — product dark default.
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

  /// Cool technical stage — light ThemeMode face.
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
