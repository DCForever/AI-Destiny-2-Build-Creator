import 'catalog_item.dart';

/// Universal Catalog composition kinds (product `COMPOSITION_KINDS` subset).
///
/// DART-063 / GAP-UI-CATALOG-03: eligibility for Set / Synergy actions only
/// (never Build kit attach).
enum CompositionKind {
  weapon('weapon'),
  exoticWeapon('exotic_weapon'),
  armor('armor'),
  exoticArmor('exotic_armor'),
  mod('mod'),
  weaponPerk('weapon_perk'),
  originTrait('origin_trait'),
  armorSetBonus('armor_set_bonus'),
  artifactPerk('artifact_perk'),
  aspect('aspect'),
  fragment('fragment'),
  ability('ability');

  const CompositionKind(this.wireName);
  final String wireName;

  static CompositionKind? tryParse(String wire) {
    for (final v in values) {
      if (v.wireName == wire || v.name == wire) return v;
    }
    return null;
  }
}

const _labels = <CompositionKind, String>{
  CompositionKind.weapon: 'Weapon',
  CompositionKind.exoticWeapon: 'Exotic weapon',
  CompositionKind.armor: 'Armor',
  CompositionKind.exoticArmor: 'Exotic armor',
  CompositionKind.mod: 'Mod',
  CompositionKind.weaponPerk: 'Weapon perk',
  CompositionKind.originTrait: 'Origin trait',
  CompositionKind.armorSetBonus: 'Armor set bonus',
  CompositionKind.artifactPerk: 'Artifact perk',
  CompositionKind.aspect: 'Aspect',
  CompositionKind.fragment: 'Fragment',
  CompositionKind.ability: 'Ability',
};

const _setEligible = <CompositionKind>{
  CompositionKind.weapon,
  CompositionKind.exoticWeapon,
  CompositionKind.armor,
  CompositionKind.exoticArmor,
  CompositionKind.mod,
};

const _synergyEligible = <CompositionKind>{
  CompositionKind.weapon,
  CompositionKind.exoticWeapon,
  CompositionKind.weaponPerk,
  CompositionKind.originTrait,
  CompositionKind.armorSetBonus,
  CompositionKind.exoticArmor,
  CompositionKind.artifactPerk,
};

/// Human label for a composition kind.
String compositionKindLabel(CompositionKind kind) => _labels[kind]!;

/// Set / Synergy action eligibility for a hit kind (no Build attach).
({bool set, bool synergy}) hitActions(CompositionKind kind) {
  return (set: _setEligible.contains(kind), synergy: _synergyEligible.contains(kind));
}

/// Map catalog row → composition kind using sourceStore + isExotic.
CompositionKind? compositionKindFromCatalogItem(CatalogItem item) {
  final store = item.sourceStore;
  switch (store) {
    case 'weapons':
      return item.isExotic ? CompositionKind.exoticWeapon : CompositionKind.weapon;
    case 'exotic-weapons':
      return CompositionKind.exoticWeapon;
    case 'exotic-armor':
      return CompositionKind.exoticArmor;
    case 'legendary-armor':
      return CompositionKind.armor;
    case 'mods':
      return CompositionKind.mod;
    case 'aspects':
      return CompositionKind.aspect;
    case 'fragments':
      return CompositionKind.fragment;
    case 'abilities':
      return CompositionKind.ability;
  }

  // Heuristic for unannotated fixtures.
  final type = item.itemTypeName?.toLowerCase() ?? '';
  if (type == 'aspect') return CompositionKind.aspect;
  if (type == 'fragment') return CompositionKind.fragment;
  if (type == 'mod') return CompositionKind.mod;
  if (item.ammo != null ||
      item.slot == 'Kinetic' ||
      item.slot == 'Energy' ||
      item.slot == 'Power') {
    return item.isExotic ? CompositionKind.exoticWeapon : CompositionKind.weapon;
  }
  if (item.classType != null ||
      item.slot == 'Helmet' ||
      item.slot == 'Gauntlets' ||
      item.slot == 'Chest' ||
      item.slot == 'Legs' ||
      item.slot == 'ClassItem') {
    return item.isExotic ? CompositionKind.exoticArmor : CompositionKind.armor;
  }
  return null;
}

/// Preferred set type wire for a composition hit (`weapon` | `armor` | `mod`).
String? setTypeWireForKind(CompositionKind kind) {
  switch (kind) {
    case CompositionKind.weapon:
    case CompositionKind.exoticWeapon:
      return 'weapon';
    case CompositionKind.armor:
    case CompositionKind.exoticArmor:
      return 'armor';
    case CompositionKind.mod:
      return 'mod';
    default:
      return null;
  }
}

/// Synergy link kind wire for a catalog hit (itemHash targets).
String? synergyLinkKindWireForKind(CompositionKind kind) {
  switch (kind) {
    case CompositionKind.weapon:
    case CompositionKind.exoticWeapon:
      return 'weapon';
    case CompositionKind.exoticArmor:
      return 'exotic_armor';
    case CompositionKind.weaponPerk:
      return 'weapon_perk';
    case CompositionKind.originTrait:
      return 'origin_trait';
    case CompositionKind.armorSetBonus:
      return 'armor_set_bonus';
    case CompositionKind.artifactPerk:
      return 'artifact_perk';
    default:
      return null;
  }
}
