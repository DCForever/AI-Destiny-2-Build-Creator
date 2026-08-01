// Subclass display names by guardian class.
// Port of `SUBCLASSES_BY_CLASS` from `src/data/subclasses.ts`.
// Full `subclasses.meta` source packs are deferred.

enum GuardianClass {
  titan('Titan'),
  hunter('Hunter'),
  warlock('Warlock');

  const GuardianClass(this.wireName);
  final String wireName;

  static GuardianClass? tryParse(String wire) {
    for (final v in GuardianClass.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

const Map<GuardianClass, List<String>> subclassesByClass = {
  GuardianClass.titan: [
    'Sunbreaker',
    'Striker',
    'Behemoth',
    'Sentinel',
    'Berserker',
    'Prismatic Titan',
  ],
  GuardianClass.hunter: [
    'Gunslinger',
    'Arcstrider',
    'Revenant',
    'Nightstalker',
    'Threadrunner',
    'Prismatic Hunter',
  ],
  GuardianClass.warlock: [
    'Dawnblade',
    'Stormcaller',
    'Shadebinder',
    'Voidwalker',
    'Broodweaver',
    'Prismatic Warlock',
  ],
};

List<String> subclassesFor(GuardianClass classType) =>
    List.unmodifiable(subclassesByClass[classType] ?? const []);
