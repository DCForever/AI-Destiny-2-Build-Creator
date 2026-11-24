/// Apply-to-character presentation helpers (shared by host Apply UI).
///
/// Obsolete Equip-panel CTA / step-report formatters were removed with the
/// Equip panel retirement; Apply uses [formatApplyOutcomeLabel] only.
library;

/// Apply outcome-row label: real item name, exotic annotated, never slot keys.
///
/// Never returns `primary`, `None`, empty, or a raw slot wire alone when a
/// readable fallback exists. Exotic weapons → `Name (Exotic weapon)`; exotic
/// armor → `Name (Exotic armor)`.
String formatApplyOutcomeLabel({
  required String rawLabel,
  String? slot,
  bool isExotic = false,
}) {
  final cleaned = _cleanApplyItemName(rawLabel);
  final exoticKind = _applyExoticKindLabel(slot, isExotic: isExotic);
  if (cleaned != null) {
    if (exoticKind != null) return '$cleaned ($exoticKind)';
    return cleaned;
  }
  final readable = readableApplySlotLabel(slot);
  if (exoticKind != null) return exoticKind;
  return readable;
}

/// Human slot name for Apply rows (never raw `primary` / `None`).
String readableApplySlotLabel(String? slot) {
  switch ((slot ?? '').trim().toLowerCase()) {
    case 'primary':
    case 'kinetic':
      return 'Kinetic';
    case 'special':
    case 'energy':
      return 'Energy';
    case 'heavy':
    case 'power':
      return 'Power';
    case 'helmet':
      return 'Helmet';
    case 'arms':
    case 'gauntlets':
      return 'Gauntlets';
    case 'chest':
      return 'Chest';
    case 'legs':
      return 'Legs';
    case 'class_item':
    case 'classitem':
      return 'Class Item';
    case 'exotic_weapon':
      return 'Exotic weapon';
    case 'exotic_armor':
      return 'Exotic armor';
    default:
      final trimmed = (slot ?? '').trim();
      if (trimmed.isEmpty ||
          trimmed.toLowerCase() == 'none' ||
          trimmed.toLowerCase() == 'primary') {
        return 'Item';
      }
      return trimmed;
  }
}

String? _cleanApplyItemName(String rawLabel) {
  var trimmed = rawLabel.trim();
  if (trimmed.isEmpty) return null;
  // Strip a prior exotic annotation so re-formatting stays idempotent.
  trimmed = trimmed
      .replaceFirst(RegExp(r'\s*\(Exotic weapon\)\s*$', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s*\(Exotic armor\)\s*$', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s*\(Exotic\)\s*$', caseSensitive: false), '')
      .trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower == 'none' || lower == 'null') return null;
  switch (lower) {
    case 'primary':
    case 'kinetic':
    case 'special':
    case 'energy':
    case 'heavy':
    case 'power':
    case 'helmet':
    case 'arms':
    case 'gauntlets':
    case 'chest':
    case 'legs':
    case 'class_item':
    case 'classitem':
    case 'exotic_weapon':
    case 'exotic_armor':
    case 'exotic weapon':
    case 'exotic armor':
      return null;
  }
  return trimmed;
}

String? _applyExoticKindLabel(String? slot, {required bool isExotic}) {
  final wire = (slot ?? '').trim().toLowerCase();
  if (wire == 'exotic_weapon') return 'Exotic weapon';
  if (wire == 'exotic_armor') return 'Exotic armor';
  if (!isExotic) return null;
  switch (wire) {
    case 'primary':
    case 'kinetic':
    case 'special':
    case 'energy':
    case 'heavy':
    case 'power':
      return 'Exotic weapon';
    case 'helmet':
    case 'arms':
    case 'gauntlets':
    case 'chest':
    case 'legs':
    case 'class_item':
    case 'classitem':
      return 'Exotic armor';
    default:
      return 'Exotic';
  }
}
