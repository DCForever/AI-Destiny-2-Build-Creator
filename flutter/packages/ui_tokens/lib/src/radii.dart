/// Radii — Neon Network (angular modular chrome).
///
/// Default radius **0**. Soft max **2px** (never exceed 4px). No consumer pills
/// on core chrome.
library;

/// Flap / panel / chip / control corner radius (always 0).
const double kFlapRadius = 0;

/// Soft maximum for rare non-core corners (Neon `--radius-max`).
const double kRadiusMax = 2;

/// Hard ceiling — never exceed (Neon anti-pattern).
const double kRadiusHardCap = 4;

/// Alias: container radius.
const double kContainerRadius = kFlapRadius;

/// Alias: control (button/chip/input) radius.
const double kControlRadius = kFlapRadius;

/// Grouped radii.
class FlapRadii {
  const FlapRadii._();

  static const double none = 0;
  static const double flap = kFlapRadius;
  static const double container = kContainerRadius;
  static const double control = kControlRadius;
  static const double max = kRadiusMax;
  static const double hardCap = kRadiusHardCap;
}
