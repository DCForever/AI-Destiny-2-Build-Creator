/// Pure designation display helpers for synergy library UI (DART-031).
///
/// Parity with domain [SynergyTypeDesignation.designationKey]:
/// `type` or `type::subType` when subtype is non-empty after trim.

/// Format a synergy designation key for list/detail display.
String formatSynergyDesignation(String type, [String? subType]) {
  final t = type.trim();
  final sub = subType?.trim() ?? '';
  if (sub.isEmpty) return t;
  return '$t::$sub';
}

/// Human label for a [SynergyLinkKind] wire name (fallback: wire itself).
String synergyLinkKindLabel(String kindWire) {
  switch (kindWire) {
    case 'weapon':
      return 'Weapon';
    case 'weapon_perk':
      return 'Weapon perk';
    case 'origin_trait':
      return 'Origin trait';
    case 'armor_set_bonus':
      return 'Armor set bonus';
    case 'exotic_armor':
      return 'Exotic armor';
    case 'artifact_perk':
      return 'Artifact perk';
    default:
      return kindWire;
  }
}
