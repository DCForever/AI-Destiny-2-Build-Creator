/// Synergy designation presentation chrome (DART-068 / GAP-UI-SYN-05).
///
/// Human Verb:/Element: labels preferred over raw `type::subType` wire keys.

/// Wire key for maps (existing): `type` or `type::subType`.
String designationWireKey(String type, [String? subType]) {
  final t = type.trim();
  final sub = subType?.trim() ?? '';
  if (sub.isEmpty) return t;
  return '$t::$sub';
}

/// Family label for a synergy type wire value.
String designationFamilyLabel(String type) {
  switch (type.trim().toLowerCase()) {
    case 'verb':
      return 'Verb';
    case 'element':
      return 'Element';
    case 'weapon':
    case 'weapon_type':
      return 'Weapon';
    case 'weapon_frame':
    case 'frame':
      return 'Frame';
    case 'armor':
    case 'armor_archetype':
      return 'Armor';
    case 'activity':
      return 'Activity';
    case 'ability':
    case 'ability_category':
      return 'Ability';
    default:
      final t = type.trim();
      if (t.isEmpty) return 'Designation';
      return t[0].toUpperCase() + (t.length > 1 ? t.substring(1) : '');
  }
}

/// Primary human label: `Verb: Scorch`, `Element: Solar`, or type alone.
String formatDesignationChrome(String type, [String? subType]) {
  final family = designationFamilyLabel(type);
  final sub = subType?.trim() ?? '';
  if (sub.isEmpty) return family;
  return '$family: $sub';
}

/// Whether this designation is an element family (color chrome).
bool isElementDesignation(String type) =>
    type.trim().toLowerCase() == 'element';

/// Whether this designation is a verb family.
bool isVerbDesignation(String type) => type.trim().toLowerCase() == 'verb';

/// Stable key for element color tokens (lowercase).
String? elementChromeKey(String type, [String? subType]) {
  if (!isElementDesignation(type)) return null;
  final sub = subType?.trim();
  if (sub == null || sub.isEmpty) return null;
  return sub.toLowerCase();
}
