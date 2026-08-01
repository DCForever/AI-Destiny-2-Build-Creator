/// Pure identity display helpers for Builds library UI (DART-032).
///
/// Designation keys match domain [SynergyTypeDesignation.designationKey]:
/// `type` or `type::subType` when subtype is non-empty after trim.

/// Format a single synergy designation key for list/detail display.
String formatSynergyDesignationKey(String type, [String? subType]) {
  final t = type.trim();
  final sub = subType?.trim() ?? '';
  if (sub.isEmpty) return t;
  return '$t::$sub';
}

/// Join multiple designation keys with ", " (empty → empty string).
String formatSynergyDesignationList(
  Iterable<({String type, String? subType})> designations,
) {
  final keys = <String>[];
  for (final d in designations) {
    final key = formatSynergyDesignationKey(d.type, d.subType);
    if (key.isNotEmpty) keys.add(key);
  }
  return keys.join(', ');
}

/// Compact exotics summary for list column (armor / weapon names or hashes).
String formatExoticsSummary({
  String? exoticArmorName,
  int? exoticArmorHash,
  String? exoticWeaponName,
  int? exoticWeaponHash,
}) {
  final parts = <String>[];
  final armor = exoticArmorName?.trim();
  if (armor != null && armor.isNotEmpty) {
    parts.add(armor);
  } else if (exoticArmorHash != null) {
    parts.add('Armor $exoticArmorHash');
  }
  final weapon = exoticWeaponName?.trim();
  if (weapon != null && weapon.isNotEmpty) {
    parts.add(weapon);
  } else if (exoticWeaponHash != null) {
    parts.add('Weapon $exoticWeaponHash');
  }
  if (parts.isEmpty) return '—';
  return parts.join(' · ');
}

/// Identity column: guardian class (+ optional pinned Super short label).
String formatIdentitySummary({
  required String className,
  String? pinnedSuper,
}) {
  final c = className.trim();
  final superPin = pinnedSuper?.trim() ?? '';
  if (superPin.isEmpty) return c.isEmpty ? '—' : c;
  return '$c · $superPin';
}
