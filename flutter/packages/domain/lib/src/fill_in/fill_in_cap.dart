/// Default copies kept per armor set per slot (Daniel Nov 11 rule).
const int kFillInDefaultInventoryCap = 2;

/// Inclusive lower bound for the inventory cap setting.
const int kFillInMinInventoryCap = 1;

/// Inclusive upper bound for the inventory cap setting.
const int kFillInMaxInventoryCap = 4;

/// Resolve the inventory cap for Fill In.
///
/// Effective cap is always in [[kFillInMinInventoryCap], [kFillInMaxInventoryCap]].
/// Null or any value outside that range falls back to
/// [kFillInDefaultInventoryCap] (2) — not snapped to the nearest bound.
int resolveFillInInventoryCap(int? raw) {
  if (raw == null) return kFillInDefaultInventoryCap;
  if (raw < kFillInMinInventoryCap || raw > kFillInMaxInventoryCap) {
    return kFillInDefaultInventoryCap;
  }
  return raw;
}

/// Review-only over-cap label. Never implies any inventory write action.
String moreThanHeldLabel(int cap) => 'More than $cap held';
