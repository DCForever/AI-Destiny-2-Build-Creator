/// Pure display helpers for web Builds list/detail (DART-046/068).

import 'package:destiny2_app/destiny2_app.dart';

/// Wire designation key: `type` or `type::subType` (filters/identity).
String formatSynergyDesignationKey(String type, [String? subType]) {
  return designationWireKey(type, subType);
}

/// Human chrome for library/detail (GAP-UI-SYN-05): Verb: Scorch, Element: Solar.
String formatSynergyDesignationDisplay(String type, [String? subType]) {
  return formatDesignationChrome(type, subType);
}

/// Join designation keys with ", " (human chrome).
String formatSynergyDesignationList(
  Iterable<({String type, String? subType})> designations,
) {
  final keys = <String>[];
  for (final d in designations) {
    final key = formatSynergyDesignationDisplay(d.type, d.subType);
    if (key.isNotEmpty) keys.add(key);
  }
  return keys.join(', ');
}


/// Compact exotics summary for list/detail.
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

/// Identity: guardian class (+ optional pinned Super).
String formatIdentitySummary({
  required String className,
  String? pinnedSuper,
}) {
  final c = className.trim();
  final superPin = pinnedSuper?.trim() ?? '';
  if (superPin.isEmpty) return c.isEmpty ? '—' : c;
  return '$c · $superPin';
}

/// List row title: name or fallback when blank.
String formatBuildListTitle(String? name, {String fallback = 'Untitled build'}) {
  final n = name?.trim() ?? '';
  if (n.isEmpty) return fallback;
  return n;
}
