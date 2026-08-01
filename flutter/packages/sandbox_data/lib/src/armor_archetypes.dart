import 'armor_stat_name.dart';

/// Armor 3.0 archetypes — original six + six added in 9.7.0.
/// Port of `src/data/rules/armorArchetypes.ts`.

class ArmorArchetype {
  const ArmorArchetype({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.addedIn970,
  });

  final String name;
  final ArmorStatName primary;
  final ArmorStatName secondary;
  final bool addedIn970;
}

const List<ArmorArchetype> armorArchetypes = [
  ArmorArchetype(
    name: 'Brawler',
    primary: ArmorStatName.melee,
    secondary: ArmorStatName.health,
    addedIn970: false,
  ),
  ArmorArchetype(
    name: 'Bulwark',
    primary: ArmorStatName.health,
    secondary: ArmorStatName.classStat,
    addedIn970: false,
  ),
  ArmorArchetype(
    name: 'Grenadier',
    primary: ArmorStatName.grenade,
    secondary: ArmorStatName.superStat,
    addedIn970: false,
  ),
  ArmorArchetype(
    name: 'Paragon',
    primary: ArmorStatName.superStat,
    secondary: ArmorStatName.melee,
    addedIn970: false,
  ),
  ArmorArchetype(
    name: 'Specialist',
    primary: ArmorStatName.classStat,
    secondary: ArmorStatName.weapons,
    addedIn970: false,
  ),
  ArmorArchetype(
    name: 'Gunner',
    primary: ArmorStatName.weapons,
    secondary: ArmorStatName.grenade,
    addedIn970: false,
  ),
  ArmorArchetype(
    name: 'Siegebreaker',
    primary: ArmorStatName.health,
    secondary: ArmorStatName.grenade,
    addedIn970: true,
  ),
  ArmorArchetype(
    name: 'Skirmisher',
    primary: ArmorStatName.melee,
    secondary: ArmorStatName.weapons,
    addedIn970: true,
  ),
  ArmorArchetype(
    name: 'Demolitionist',
    primary: ArmorStatName.grenade,
    secondary: ArmorStatName.classStat,
    addedIn970: true,
  ),
  ArmorArchetype(
    name: 'Colossus',
    primary: ArmorStatName.superStat,
    secondary: ArmorStatName.health,
    addedIn970: true,
  ),
  ArmorArchetype(
    name: 'Reaver',
    primary: ArmorStatName.classStat,
    secondary: ArmorStatName.melee,
    addedIn970: true,
  ),
  ArmorArchetype(
    name: 'Powerhouse',
    primary: ArmorStatName.weapons,
    secondary: ArmorStatName.superStat,
    addedIn970: true,
  ),
];

const List<String> armorSystemNotes = [
  'All 12 archetypes drop from every source of Armor 3.0 gear',
  'All Armor 3.0 exotics are Tier 5 with access to all tuning mods (9.7.0)',
  'Raid mod slots exist only on Armor 2.0 raid gear',
  'Armorer Ghost mods give ~1 in 2 odds of dropping the chosen archetype (9.7.0)',
];

ArmorArchetype? findArchetypeByName(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  for (final a in armorArchetypes) {
    if (a.name.toLowerCase() == normalized) return a;
  }
  return null;
}

/// Archetypes whose primary or secondary matches [stat].
List<ArmorArchetype> findArchetypesForStat(ArmorStatName stat) {
  return armorArchetypes
      .where((a) => a.primary == stat || a.secondary == stat)
      .toList(growable: false);
}
