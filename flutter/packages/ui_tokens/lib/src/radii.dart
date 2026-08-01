/// Square board radii — Matte Flap Ledger.
///
/// **The Square Board Rule.** Primary containers are square matte plates.
/// No notches. No large radii. No consumer pills on core chrome.
library;

/// Flap / panel / chip / control corner radius (always 0).
const double kFlapRadius = 0;

/// Alias: container radius.
const double kContainerRadius = kFlapRadius;

/// Alias: control (button/chip/input) radius.
const double kControlRadius = kFlapRadius;

/// Grouped radii (all zero by design).
class FlapRadii {
  const FlapRadii._();

  static const double none = 0;
  static const double flap = kFlapRadius;
  static const double container = kContainerRadius;
  static const double control = kControlRadius;
}
