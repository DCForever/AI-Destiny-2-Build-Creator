// Armor 3.0 stat names (TS `ArmorStatName` in `src/data/rules/statBenefits.ts`).
//
// Wire names match product and `destiny2_domain` for future unification.
enum ArmorStatName {
  health('Health'),
  melee('Melee'),
  grenade('Grenade'),
  superStat('Super'),
  classStat('Class'),
  weapons('Weapons');

  const ArmorStatName(this.wireName);
  final String wireName;

  static const List<ArmorStatName> all = ArmorStatName.values;

  static ArmorStatName? tryParse(String wire) {
    for (final v in ArmorStatName.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}
