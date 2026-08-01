import 'package:destiny2_app/destiny2_app.dart';

/// Pure designation display helpers for synergy library UI (DART-031/068).
///
/// Parity with domain [SynergyTypeDesignation.designationKey]:
/// `type` or `type::subType` when subtype is non-empty after trim.
/// Human chrome (GAP-UI-SYN-05): Verb:/Element: preferred for display.

/// Format a synergy designation key for list/detail display (human chrome).
String formatSynergyDesignation(String type, [String? subType]) {
  return formatDesignationChrome(type, subType);
}

/// Wire key still useful for filters/debug.
String formatSynergyDesignationWire(String type, [String? subType]) {
  return designationWireKey(type, subType);
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
